#!/usr/bin/env bash
# One-command bootstrap for the Home Network Security Stack.
# Works on any Linux/macOS host with Docker + Docker Compose.
set -euo pipefail

cd "$(dirname "$0")"

# Step 1: create .env from template on first run
if [[ ! -f .env ]]; then
  echo "[*] First run detected — creating .env from .env.example"
  cp .env.example .env
  echo "[!] IMPORTANT: edit .env and change the default passwords, then re-run."
  echo "    nano .env"
  exit 0
fi

# Step 2: auto-detect Docker group ID so Telegraf can read docker.sock
if command -v getent &>/dev/null; then
  DOCKER_GID="$(getent group docker | cut -d: -f3 || echo 999)"
  export DOCKER_GID
  echo "[*] DOCKER_GID=${DOCKER_GID}"
fi

# Step 3: pick the right compose command
if docker compose version &>/dev/null; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  echo "[!] Docker Compose not found. Install it first: https://docs.docker.com/compose/install/"
  exit 1
fi

echo "[*] Starting stack with: ${COMPOSE} up -d"
${COMPOSE} up -d

echo ""
echo "[+] Stack is starting. Give it ~20 seconds, then open:"
echo ""
# shellcheck disable=SC1091
source .env
echo "    Grafana      http://localhost:${GRAFANA_PORT:-3000}       (login: ${GRAFANA_USER:-admin} / <see .env>)"
echo "    Pi-hole      http://localhost:${PIHOLE_WEB_PORT:-8081}    (login: <see .env>)"
echo "    Prometheus   http://localhost:${PROMETHEUS_PORT:-9090}"
echo "    Portainer    http://localhost:${PORTAINER_PORT:-9000}     (set password on first visit)"
echo ""
echo "[*] To stop:   ${COMPOSE} down"
echo "[*] To purge:  ${COMPOSE} down -v   (also deletes stored metrics)"
