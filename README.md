# Home Network Security & Monitoring Stack

A Docker-Compose stack that gives any home network **DNS-level ad/tracker blocking** and a **live monitoring dashboard** — in two commands.

Five containers work together:

| Service | Role | Default URL |
| --- | --- | --- |
| **Pi-hole** | DNS sinkhole — blocks ads & trackers for every device on your network | `http://localhost:8081` |
| **Telegraf** | Collects system metrics every 10 s (CPU, memory, disk, net) | *(internal)* |
| **Prometheus** | Time-series database — stores metrics with 30-day retention | `http://localhost:9090` |
| **Grafana** | Dashboards — auto-provisioned "System Overview" panel out of the box | `http://localhost:3000` |
| **Portainer** | Container management UI — start/stop/inspect from the browser | `http://localhost:9000` |

Works on **Linux, macOS, Windows (WSL2), and Raspberry Pi**.

---

## Quick start — three steps

```bash
git clone https://github.com/MRALPHA20/Home-Network-Security.git
cd Home-Network-Security
./run.sh
```

The first run creates `.env` from the template and asks you to set your passwords. Edit it:

```bash
nano .env   # change PIHOLE_PASSWORD and GRAFANA_PASSWORD at minimum
./run.sh    # starts the stack
```

Give it ~20 seconds, then open **http://localhost:3000** in your browser. Log into Grafana with the credentials you set, click **Dashboards → System Overview**, and you'll see live CPU/memory/system-load graphs of the host.

---

## What each service does

### Pi-hole — network-wide ad blocking
Any device that uses it for DNS resolution gets ads and trackers blocked at the lookup layer. No browser extensions, no per-device setup. Point your router's DNS at your host and every phone, laptop, smart TV, and IoT device on the network is protected.

### Telegraf → Prometheus → Grafana — the monitoring pipeline
- **Telegraf** reads the host's `/proc` and `/sys` filesystems every 10 seconds and exposes CPU, memory, disk, and network stats on port 9273 in Prometheus format.
- **Prometheus** scrapes Telegraf every 15 seconds and stores everything in its time-series database. Data survives container restarts via a named volume. Keeps 30 days by default.
- **Grafana** is pre-configured to query Prometheus. The "System Overview" dashboard is provisioned from `grafana/provisioning/dashboards/` on first boot.

### Portainer — Docker from your browser
Visual control plane for all your containers. Start, stop, restart, read logs, inspect resources — click, don't type.

---

## Repository layout

```
.
├── docker-compose.yml                # The whole stack in one file
├── run.sh                            # Bootstrap script (first-run safe)
├── .env.example                      # Template with sensible defaults
├── prometheus/
│   └── prometheus.yml                # Scrape config
├── telegraf/
│   └── telegraf.conf                 # System metrics inputs + Prometheus output
└── grafana/
    └── provisioning/
        ├── datasources/prometheus.yml
        └── dashboards/
            ├── dashboards.yml
            └── system-overview.json
```

Nothing is clicked through at setup time. Datasources, dashboards, and scrape targets are all in version control — a fresh clone on a new machine behaves identically.

---

## Common operations

```bash
# Status of all containers
docker compose ps

# Live logs from one service
docker compose logs -f grafana

# Restart one service after editing its config
docker compose restart prometheus

# Stop everything (keeps data)
docker compose down

# Nuke everything including stored metrics
docker compose down -v
```

---

## Changing ports

If port 53, 3000, 8081, 9000, or 9090 is already taken on your host, override in `.env`:

```bash
PIHOLE_DNS_PORT=5353
GRAFANA_PORT=3030
```

Then re-run `./run.sh`.

---

## Protecting your whole network

Once Pi-hole is running, you have two options:

1. **Per-device:** Set each device's DNS to the IP of this host.
2. **Whole network (recommended):** Set your router's DNS to the IP of this host. Every device the router hands an address to inherits ad blocking automatically.

Open the Pi-hole admin at `http://localhost:8081/admin/` and go to **Query Log** to see every DNS lookup on your network in real time — including which domains are being blocked.

---

## Troubleshooting

**Pi-hole won't start because port 53 is already in use**
Linux systems running `systemd-resolved` bind port 53 by default. Either:
```bash
sudo systemctl stop systemd-resolved         # one-time
sudo systemctl disable systemd-resolved      # permanent
```
Or change `PIHOLE_DNS_PORT` in `.env` to something unused.

**Telegraf logs show "permission denied" on /var/run/docker.sock**
Set `DOCKER_GID` in `.env` to your host's Docker group ID:
```bash
getent group docker | cut -d: -f3
```

**Grafana shows "No data"**
Check that Prometheus is scraping Telegraf: open `http://localhost:9090/targets` — both jobs should be `UP`.

---

## License

MIT. Use it, fork it, run it on your home network.
