{
  description = "tmuxdesk — distributed terminal infrastructure for a 5-node fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit system;
      });
    in
    {
      packages = forAllSystems ({ pkgs, system }: let
        runtimeDeps = with pkgs; [ bash coreutils findutils gnused gnugrep gawk openssh tmux fzf git hostname ];

        tmuxdesk = pkgs.stdenv.mkDerivation {
          pname = "tmuxdesk";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          buildInputs = runtimeDeps;

          installPhase = ''
            mkdir -p $out/{bin,conf,presets}
            cp bin/*.sh $out/bin/
            cp conf/* $out/conf/
            cp presets/*.sh $out/presets/
            cp fleet.conf $out/

            # Fix shebangs for Nix
            for f in $out/bin/*.sh $out/presets/*.sh; do
              substituteInPlace "$f" \
                --replace-quiet '#!/usr/bin/env bash' '#!${pkgs.bash}/bin/bash'
            done

            chmod +x $out/bin/* $out/presets/*

            # Wrap scripts: set TMUXDESK_DIR and prepend runtime PATH
            for f in $out/bin/*.sh; do
              wrapProgram "$f" \
                --set TMUXDESK_DIR "$out" \
                --prefix PATH : "${pkgs.lib.makeBinPath runtimeDeps}"
            done
            for f in $out/presets/*.sh; do
              wrapProgram "$f" \
                --prefix PATH : "${pkgs.lib.makeBinPath runtimeDeps}"
            done
          '';
        };

        fleet-status-server = pkgs.rustPlatform.buildRustPackage {
          pname = "fleet-status-server";
          version = "0.1.0";
          src = ./fleet-status;
          cargoLock.lockFile = ./fleet-status/Cargo.lock;
        };
      in {
        default = tmuxdesk;
        scripts = tmuxdesk;
        fleet-status = fleet-status-server;
      });

      devShells = forAllSystems ({ pkgs, ... }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            tmux fzf git openssh
            rustc cargo clippy rustfmt
          ];
        };
      });

      # NixOS module — fleet-status-server systemd service
      nixosModules.fleet-status = { config, lib, pkgs, ... }:
        let
          cfg = config.services.tmuxdesk-fleet-status;
          inherit (lib) mkEnableOption mkOption types mkIf;
        in {
          options.services.tmuxdesk-fleet-status = {
            enable = mkEnableOption "tmuxdesk fleet-status HTTP server";

            bind = mkOption {
              type = types.str;
              default = "0.0.0.0:7600";
              description = "Address:port to bind";
            };

            dataDir = mkOption {
              type = types.path;
              default = self.packages.${pkgs.system}.default;
              description = "Path containing fleet.conf and state/";
            };

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.fleet-status;
            };
          };

          config = mkIf cfg.enable {
            systemd.services.fleet-status-server = {
              description = "tmuxdesk fleet status HTTP server";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                ExecStart = "${cfg.package}/bin/fleet-status-server --bind ${cfg.bind} --dir ${cfg.dataDir}";
                Restart = "on-failure";
                RestartSec = 5;
                DynamicUser = true;
                StateDirectory = "tmuxdesk";
                ReadOnlyPaths = [ cfg.dataDir ];
              };
            };
          };
        };

      # Home-manager module — tmux config + mesh scripts
      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.tmuxdesk;
          inherit (lib) mkEnableOption mkOption types mkIf;
        in {
          options.programs.tmuxdesk = {
            enable = mkEnableOption "tmuxdesk distributed terminal infrastructure";

            hostName = mkOption {
              type = types.str;
              description = "Fleet node name (must match fleet.conf)";
              example = "karlsruhe";
            };

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.default;
            };

            heartbeat.enable = mkEnableOption "mesh heartbeat timer (pushes state every 30s)";
          };

          config = mkIf cfg.enable {
            home.packages = [ cfg.package ];

            # Tmux config: set install dir, then source base + host layer
            programs.tmux = {
              enable = true;
              extraConfig = ''
                set -g @tmuxdesk_dir "${cfg.package}"
                source-file ${cfg.package}/conf/tmux.base.conf
                source-file ${cfg.package}/conf/host-${cfg.hostName}.conf
              '';
            };

            # Ensure mutable state dir exists
            home.activation.tmuxdeskState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              mkdir -p "$HOME/.tmux/tmuxdesk/state"
            '';

            # Heartbeat timer: push mesh state every 30s
            systemd.user.services = mkIf cfg.heartbeat.enable {
              tmuxdesk-heartbeat = {
                Unit.Description = "tmuxdesk mesh heartbeat";
                Service = {
                  Type = "oneshot";
                  ExecStart = "${cfg.package}/bin/mesh-heartbeat.sh";
                  Environment = "TMUXDESK_DIR=${cfg.package}";
                };
              };
            };

            systemd.user.timers = mkIf cfg.heartbeat.enable {
              tmuxdesk-heartbeat = {
                Unit.Description = "tmuxdesk mesh heartbeat timer";
                Timer = {
                  OnBootSec = "10s";
                  OnUnitActiveSec = "30s";
                };
                Install.WantedBy = [ "timers.target" ];
              };
            };
          };
        };
    };
}
