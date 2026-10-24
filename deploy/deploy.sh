#!/usr/bin/env bash
# Website auf den Raspberry Pi bringen. Auf dem Mac im Repo-Ordner ausführen:
#   ./deploy/deploy.sh benutzer@IP-des-Pi
# Optional: PI_DIR=anderer-ordner ./deploy/deploy.sh ...   (Standard: ~/gut-aussehend auf dem Pi)
set -euo pipefail

PI="${1:?Aufruf: ./deploy/deploy.sh benutzer@IP-des-Pi}"
DIR="${PI_DIR:-gut-aussehend}"
cd "$(dirname "$0")/.."

echo "→ Ordner auf dem Pi anlegen: ~/$DIR"
ssh "$PI" "mkdir -p '$DIR/site'"

echo "→ Website-Dateien übertragen"
rsync -az --delete \
  --exclude '.git' --exclude '.gitignore' --exclude '.vscode' --exclude '.DS_Store' \
  --exclude 'deploy' --exclude 'README.md' --exclude 'node_modules' \
  ./ "$PI:$DIR/site/"

echo "→ Konfiguration übertragen"
rsync -az deploy/docker-compose.yml deploy/nginx.conf "$PI:$DIR/"

echo "→ Container starten"
ssh "$PI" "cd '$DIR' && \
  if [ -f .env ] && grep -q '^TUNNEL_TOKEN=.' .env; then \
    docker compose --profile tunnel up -d --remove-orphans; \
  else \
    echo '   (kein TUNNEL_TOKEN in ~/$DIR/.env, starte nur den Webserver fürs Heimnetz)'; \
    docker compose up -d --remove-orphans; \
  fi && docker compose ps"

HOST="${PI#*@}"
echo
echo "Fertig. Im Heimnetz: http://$HOST:8080"
