#!/usr/bin/env bash
# Website auf den Raspberry Pi bringen. Auf dem Mac im Repo-Ordner ausführen:
#   ./deploy/deploy.sh benutzer@IP-des-Pi
# Optional: PI_DIR=anderer-ordner ./deploy/deploy.sh ...   (Standard: ~/gut-aussehend auf dem Pi)
set -euo pipefail

PI="${1:?Aufruf: ./deploy/deploy.sh benutzer@IP-des-Pi}"
DIR="${PI_DIR:-gut-aussehend}"
cd "$(dirname "$0")/.."

# Eine SSH-Verbindung für alle Schritte, damit das Passwort nur einmal abgefragt wird
mkdir -p "$HOME/.ssh"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-ga-%r@%h-%p -o ControlPersist=120"
ssh_pi() { ssh $SSH_OPTS "$PI" "$@"; }

echo "→ Ordner auf dem Pi anlegen: ~/$DIR"
ssh_pi "mkdir -p '$DIR/site'"

echo "→ Website-Dateien übertragen"
rsync -az --delete -e "ssh $SSH_OPTS" \
  --exclude '.git' --exclude '.gitignore' --exclude '.vscode' --exclude '.DS_Store' \
  --exclude 'deploy' --exclude 'README.md' --exclude 'node_modules' \
  ./ "$PI:$DIR/site/"

echo "→ Konfiguration übertragen"
rsync -az -e "ssh $SSH_OPTS" deploy/docker-compose.yml deploy/nginx.conf "$PI:$DIR/"

echo "→ Container starten"
ssh_pi "cd '$DIR' && \
  if [ -f .env ] && grep -q '^TUNNEL_TOKEN=.' .env; then \
    docker compose --profile tunnel up -d --remove-orphans; \
  else \
    echo '   (kein TUNNEL_TOKEN in ~/$DIR/.env, starte nur den Webserver fürs Heimnetz)'; \
    docker compose up -d --remove-orphans; \
  fi && docker compose ps"

HOST="${PI#*@}"
echo
echo "Fertig. Im Heimnetz: http://$HOST:8080"
