# Fleet Fallback Compute

Free-tier compute that can serve as backup or overflow nodes for the fleet. Criteria: must support SSH access or persistent processes, not just web hosting.

## Always-free VMs (SSH-capable)

### Oracle Cloud — best free tier for fleet use
- **4 ARM cores + 24 GB RAM** (Ampere A1) — split into up to 4 VMs
- **2 AMD VMs** (1/8 OCPU, 1 GB each)
- 200 GB block storage, 10 TB egress/month
- 2 public IPv4 addresses
- Caveat: idle instances get reclaimed — run a heartbeat
- https://www.oracle.com/cloud/free/

### Google Cloud — 1 micro VM
- **e2-micro** in us-west1/us-central1/us-east1 (always free)
- 30 GB standard disk, 1 GB egress
- Cloud Shell: 5 GB persistent, 60h/week (not SSH-able externally)
- https://cloud.google.com/free

### Azure — 12-month free then limited
- **B1S Linux VM** (1 vCPU, 1 GB, 12 months)
- After 12 months: no free compute
- https://azure.microsoft.com/free

### AWS — 12-month free then limited
- **t2.micro/t3.micro** (750h/month, 12 months)
- After 12 months: Lambda only (1M requests/month)
- https://aws.amazon.com/free

## Persistent process hosting (non-VM)

### Fly.io
- 3 shared-cpu-1x VMs, 256 MB each (always free)
- Persistent volumes, WireGuard-based private networking
- Can run fleet-status-server or heartbeat relays
- https://fly.io/docs/about/pricing/

### Railway
- $5/month free credit, sleep after 10 min inactivity
- Not ideal for fleet — processes sleep

### Render
- Static sites and web services (free tier sleeps after 15 min)
- Not suitable for persistent fleet nodes

## Tunneling / mesh fallbacks

### Cloudflare Tunnel (cloudflared)
- Free, exposes local services without public IP
- Good for: fleet-status-server behind NAT
- https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

### Tailscale
- Free for personal use, 100 devices
- WireGuard mesh VPN — every node reachable without public IPs
- Replaces SSH port forwarding for fleet mesh
- https://tailscale.com/pricing

### Ngrok
- Free tier: 1 tunnel, random URL
- Not suitable for fleet (no persistent hostname)

## Recommended fallback setup

For fleet resilience, the cheapest path:

1. **Oracle Cloud** (2 always-free ARM VMs) as backup nodes
2. **Tailscale** mesh so all nodes (including Oracle) see each other without public IPs
3. **Cloudflare Tunnel** to expose fleet-status-server without opening ports

This gives 7 reachable nodes (5 current + 2 Oracle) with zero ongoing cost.

## Source

Curated from [free-for-dev](https://github.com/ripienaar/free-for-dev) — 1365 entries covering SaaS/PaaS/IaaS free tiers.
