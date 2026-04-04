use serde::Serialize;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};
use tiny_http::{Header, Response, Server};

#[derive(Debug, Serialize)]
struct Session {
    name: String,
    attached: bool,
    windows: u32,
}

#[derive(Debug, Serialize)]
struct NodeStatus {
    name: String,
    sigil: String,
    ip: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    sessions: Option<Vec<Session>>,
    liveness: &'static str,
    #[serde(skip_serializing_if = "Option::is_none")]
    age_secs: Option<u64>,
    total_sessions: u32,
    attached_sessions: u32,
}

#[derive(Debug, Serialize)]
struct FleetStatus {
    timestamp: u64,
    compact: String,
    nodes: Vec<NodeStatus>,
}

struct FleetNode {
    name: String,
    sigil: String,
    ip: String,
}

const STALE_WARN: u64 = 60;
const STALE_DEAD: u64 = 120;

fn parse_fleet_conf(path: &Path) -> Vec<FleetNode> {
    let content = match fs::read_to_string(path) {
        Ok(c) => c,
        Err(_) => return Vec::new(),
    };
    content
        .lines()
        .filter(|l| !l.starts_with('#') && !l.trim().is_empty())
        .filter_map(|l| {
            let parts: Vec<&str> = l.split_whitespace().collect();
            if parts.len() >= 4 {
                Some(FleetNode {
                    name: parts[0].to_string(),
                    sigil: parts[2].to_string(),
                    ip: parts[3].to_string(),
                })
            } else {
                None
            }
        })
        .collect()
}

fn parse_sessions(content: &str) -> Vec<Session> {
    content
        .lines()
        .filter(|l| !l.trim().is_empty())
        .filter_map(|l| {
            let parts: Vec<&str> = l.split('|').collect();
            if parts.len() >= 3 {
                Some(Session {
                    name: parts[0].to_string(),
                    attached: parts[1] == "1",
                    windows: parts[2].parse().unwrap_or(0),
                })
            } else {
                None
            }
        })
        .collect()
}

fn file_age_secs(path: &Path) -> Option<u64> {
    let meta = fs::metadata(path).ok()?;
    let modified = meta.modified().ok()?;
    SystemTime::now().duration_since(modified).ok().map(|d| d.as_secs())
}

fn now_epoch() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs()
}

fn build_status(base_dir: &Path) -> FleetStatus {
    let fleet_conf = base_dir.join("fleet.conf");
    let state_dir = base_dir.join("state");
    let nodes_def = parse_fleet_conf(&fleet_conf);

    let mut nodes = Vec::new();
    let mut compact = String::new();

    for node in &nodes_def {
        let state_file = state_dir.join(format!("{}.sessions", node.name));

        let (age, sessions, liveness) = if state_file.exists() {
            let age = file_age_secs(&state_file);
            match age {
                Some(a) if a <= STALE_DEAD => {
                    let content = fs::read_to_string(&state_file).unwrap_or_default();
                    let sess = parse_sessions(&content);
                    let liv = if a <= STALE_WARN { "fresh" } else { "stale" };
                    (age, Some(sess), liv)
                }
                _ => (age, None, "offline"),
            }
        } else {
            (None, None, "offline")
        };

        let total = sessions.as_ref().map_or(0, |s| s.len() as u32);
        let attached = sessions
            .as_ref()
            .map_or(0, |s| s.iter().filter(|s| s.attached).count() as u32);

        let indicator = match liveness {
            "fresh" if attached > 0 => format!("●{}", total),
            "fresh" => format!("○{}", total),
            "stale" => format!("◌{}", total),
            _ => "✕".to_string(),
        };
        compact.push_str(&node.sigil);
        compact.push_str(&indicator);

        nodes.push(NodeStatus {
            name: node.name.clone(),
            sigil: node.sigil.clone(),
            ip: node.ip.clone(),
            sessions,
            liveness,
            age_secs: age,
            total_sessions: total,
            attached_sessions: attached,
        });
    }

    FleetStatus {
        timestamp: now_epoch(),
        compact,
        nodes,
    }
}

fn collect_projects(base_dir: &Path) -> Vec<serde_json::Value> {
    let state_dir = base_dir.join("state");
    let mut projects = Vec::new();

    let pattern = state_dir.join("*.projects");
    let pattern_str = pattern.to_string_lossy();

    // Read all .projects files in state dir
    if let Ok(entries) = fs::read_dir(&state_dir) {
        for entry in entries.flatten() {
            let path = entry.path();
            if path.extension().and_then(|e| e.to_str()) == Some("projects") {
                if let Ok(content) = fs::read_to_string(&path) {
                    for line in content.lines() {
                        if let Ok(val) = serde_json::from_str::<serde_json::Value>(line) {
                            projects.push(val);
                        }
                    }
                }
            }
        }
    }

    // Sort by last_commit_epoch descending (most recent first)
    projects.sort_by(|a, b| {
        let ea = a.get("last_commit_epoch").and_then(|v| v.as_i64()).unwrap_or(0);
        let eb = b.get("last_commit_epoch").and_then(|v| v.as_i64()).unwrap_or(0);
        eb.cmp(&ea)
    });

    let _ = pattern_str; // suppress unused warning
    projects
}

fn main() {
    let args: Vec<String> = std::env::args().collect();

    let bind = args
        .iter()
        .position(|a| a == "--bind" || a == "-b")
        .and_then(|i| args.get(i + 1))
        .map(|s| s.as_str())
        .unwrap_or("0.0.0.0:7600");

    let base_dir = args
        .iter()
        .position(|a| a == "--dir" || a == "-d")
        .and_then(|i| args.get(i + 1))
        .map(PathBuf::from)
        .unwrap_or_else(|| {
            let home = std::env::var("HOME")
                .map(PathBuf::from)
                .unwrap_or_else(|_| PathBuf::from("/tmp"));
            let home_tmux = home.join(".tmux/tmuxdesk");
            if home_tmux.join("fleet.conf").exists() {
                home_tmux
            } else {
                PathBuf::from(".")
            }
        });

    eprintln!(
        "fleet-status-server listening on {} (dir: {})",
        bind,
        base_dir.display()
    );

    let server = Server::http(bind).expect("failed to bind");
    let json_ct =
        Header::from_bytes(&b"Content-Type"[..], &b"application/json; charset=utf-8"[..]).unwrap();
    let cors =
        Header::from_bytes(&b"Access-Control-Allow-Origin"[..], &b"*"[..]).unwrap();

    for request in server.incoming_requests() {
        match request.url() {
            "/" | "/status" => {
                let status = build_status(&base_dir);
                let body = serde_json::to_string_pretty(&status).unwrap_or_default();
                let resp = Response::from_string(body)
                    .with_header(json_ct.clone())
                    .with_header(cors.clone());
                let _ = request.respond(resp);
            }
            "/compact" => {
                let status = build_status(&base_dir);
                let resp = Response::from_string(status.compact);
                let _ = request.respond(resp);
            }
            "/projects" => {
                let projects = collect_projects(&base_dir);
                let body = serde_json::to_string_pretty(&projects).unwrap_or_default();
                let resp = Response::from_string(body)
                    .with_header(json_ct.clone())
                    .with_header(cors.clone());
                let _ = request.respond(resp);
            }
            "/health" => {
                let resp = Response::from_string("ok");
                let _ = request.respond(resp);
            }
            _ => {
                let resp = Response::from_string("not found").with_status_code(404);
                let _ = request.respond(resp);
            }
        }
    }
}
