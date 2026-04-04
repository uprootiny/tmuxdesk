{
  description = "tmuxdesk — distributed terminal infrastructure for a 5-node fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        fleet-status-server = pkgs.rustPlatform.buildRustPackage {
          pname = "fleet-status-server";
          version = "0.1.0";
          src = ./fleet-status;
          cargoLock.lockFile = ./fleet-status/Cargo.lock;
        };

        tmuxdesk-scripts = pkgs.stdenv.mkDerivation {
          pname = "tmuxdesk";
          version = "0.1.0";
          src = ./.;
          installPhase = ''
            mkdir -p $out/{bin,conf,presets}
            cp bin/*.sh $out/bin/
            cp conf/* $out/conf/
            cp presets/*.sh $out/presets/
            cp fleet.conf $out/
            chmod +x $out/bin/* $out/presets/*

            # Patch shebangs
            for f in $out/bin/*.sh $out/presets/*.sh; do
              substituteInPlace "$f" \
                --replace-quiet '#!/usr/bin/env bash' '#!${pkgs.bash}/bin/bash'
            done
          '';
        };
      in
      {
        packages = {
          default = tmuxdesk-scripts;
          fleet-status = fleet-status-server;
          scripts = tmuxdesk-scripts;
        };

        apps = {
          fleet-status = flake-utils.lib.mkApp {
            drv = fleet-status-server;
          };
        };
      }
    ) // {
      # Home-manager module
      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.tmuxdesk;
          inherit (lib) mkEnableOption mkOption types mkIf;
        in
        {
          options.programs.tmuxdesk = {
            enable = mkEnableOption "tmuxdesk distributed terminal infrastructure";

            hostName = mkOption {
              type = types.str;
              description = "Fleet node name (must match fleet.conf)";
              example = "karlsruhe";
            };

            fleetStatusServer = {
              enable = mkEnableOption "fleet-status HTTP server";
              bind = mkOption {
                type = types.str;
                default = "0.0.0.0:7600";
                description = "Address to bind the fleet status server";
              };
            };

            package = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.default;
              description = "The tmuxdesk package to use";
            };

            fleetStatusPackage = mkOption {
              type = types.package;
              default = self.packages.${pkgs.system}.fleet-status;
              description = "The fleet-status-server package to use";
            };
          };

          config = mkIf cfg.enable {
            home.packages = [ cfg.package ]
              ++ lib.optional cfg.fleetStatusServer.enable cfg.fleetStatusPackage;

            # Link tmuxdesk into ~/.tmux/tmuxdesk
            xdg.configFile."tmux/tmuxdesk".source = cfg.package;

            # Generate ~/.tmux.conf that sources base + host config
            programs.tmux = {
              enable = true;
              extraConfig = ''
                # tmuxdesk: base + host layer
                source-file ${cfg.package}/conf/tmux.base.conf
                source-file ${cfg.package}/conf/host-${cfg.hostName}.conf
              '';
            };

            # Systemd user service for fleet-status-server
            systemd.user.services = mkIf cfg.fleetStatusServer.enable {
              fleet-status-server = {
                Unit = {
                  Description = "tmuxdesk fleet status HTTP server";
                  After = [ "network.target" ];
                };
                Service = {
                  ExecStart = "${cfg.fleetStatusPackage}/bin/fleet-status-server --bind ${cfg.fleetStatusServer.bind} --dir ${cfg.package}";
                  Restart = "on-failure";
                  RestartSec = 5;
                };
                Install.WantedBy = [ "default.target" ];
              };
            };
          };
        };
    };
}
