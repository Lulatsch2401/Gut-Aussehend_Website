#!/usr/bin/env bash
# Website auf den Raspberry Pi bringen. Auf dem Mac im Repo-Ordner ausführen:
#   ./deploy/deploy.sh benutzer@IP-des-Pi                    normal (Passwortschutz bleibt, wie er ist)
#   ./deploy/deploy.sh benutzer@IP-des-Pi --neues-passwort   Benutzer/Passwort für die Seite neu setzen
#   ./deploy/deploy.sh benutzer@IP-des-Pi --ohne-passwort    Seite ohne Passwort, für den echten Start
# Beim ersten Mal fragt das Skript nach Benutzername und Passwort für die Seite.
# Optional: PI_DIR=anderer-ordner ./deploy/deploy.sh ...   (Standard: ~/gut-aussehend auf dem Pi)
#           WEB_PORT=8091 ./deploy/deploy.sh ...         (Port im Heimnetz, Standard 8090, wird auf dem Pi gemerkt)
set -euo pipefail

PI="${1:?Aufruf: ./deploy/deploy.sh benutzer@IP-des-Pi [--neues-passwort|--ohne-passwort]}"
MODUS="${2:-}"
case "$MODUS" in ""|--neues-passwort|--ohne-passwort) ;; *) echo "Unbekannte Option: $MODUS"; exit 1;; esac
DIR="${PI_DIR:-gut-aussehend}"
cd "$(dirname "$0")/.."

# Eine SSH-Verbindung für alle Schritte, damit das Passwort nur einmal abgefragt wird
mkdir -p "$HOME/.ssh"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-ga-%r@%h-%p -o ControlPersist=120"
ssh_pi() { ssh $SSH_OPTS "$PI" "$@"; }

echo "→ Docker auf dem Pi prüfen"
if ! ssh_pi "command -v docker >/dev/null && docker compose version >/dev/null 2>&1"; then
  echo "   Docker (mit compose) fehlt auf dem Pi oder dein Benutzer darf es nicht nutzen. Einmalig einrichten:"
  echo "     ssh -t $PI 'curl -fsSL https://get.docker.com | sudo sh && sudo usermod -aG docker \$USER'"
  echo "   Danach 2 Minuten warten (oder: ssh -O exit $SSH_OPTS $PI) und das Skript erneut starten."
  exit 1
fi

echo "→ Ordner auf dem Pi anlegen: ~/$DIR"
ssh_pi "mkdir -p '$DIR/site'"

echo "→ Website-Dateien übertragen"
rsync -az --delete -e "ssh $SSH_OPTS" \
  --exclude '.git' --exclude '.gitignore' --exclude '.vscode' --exclude '.DS_Store' \
  --exclude 'deploy' --exclude 'README.md' --exclude 'node_modules' \
  ./ "$PI:$DIR/site/"

echo "→ Konfiguration übertragen"
rsync -az -e "ssh $SSH_OPTS" deploy/docker-compose.yml deploy/nginx.conf "$PI:$DIR/"

echo "→ Passwortschutz"
# Zustand auf dem Pi: ga-auth.conf fehlt = erster Start (Passwort wird eingerichtet),
# leer = Schutz aus, mit auth_basic = Schutz an. Ohne Option bleibt der Zustand, wie er ist.
ZUSTAND=$(ssh_pi "cd '$DIR' && if [ ! -f ga-auth.conf ]; then echo neu; elif grep -q auth_basic ga-auth.conf && [ -s ga-htpasswd ]; then echo an; else echo aus; fi")
if [ "$MODUS" = "--ohne-passwort" ]; then
  ssh_pi "cd '$DIR' && : > ga-auth.conf && touch ga-htpasswd"
  echo "   aus: die Seite ist ohne Passwort erreichbar"
elif [ "$MODUS" = "--neues-passwort" ] || [ "$ZUSTAND" = "neu" ]; then
  ssh_pi "command -v openssl >/dev/null" || { echo "   openssl fehlt auf dem Pi: sudo apt install -y openssl"; exit 1; }
  read -rp "   Benutzername für die Seite [verein]: " WEB_USER; WEB_USER="${WEB_USER:-verein}"
  while true; do
    read -rsp "   Passwort für die Seite: " WEB_PW; echo
    read -rsp "   Passwort wiederholen: " WEB_PW2; echo
    [ -n "$WEB_PW" ] && [ "$WEB_PW" = "$WEB_PW2" ] && break
    echo "   Leer oder nicht gleich, bitte noch einmal."
  done
  HASH=$(printf '%s' "$WEB_PW" | ssh_pi "openssl passwd -apr1 -stdin")
  unset WEB_PW WEB_PW2
  printf '%s:%s\n' "$WEB_USER" "$HASH" | ssh_pi "cd '$DIR' && cat > ga-htpasswd && chmod 644 ga-htpasswd"
  ssh_pi "cd '$DIR' && printf 'auth_basic \"Gut und Aussehend\";\nauth_basic_user_file /etc/nginx/ga-htpasswd;\n' > ga-auth.conf"
  echo "   an: Benutzer \"$WEB_USER\" mit neuem Passwort"
else
  echo "   unverändert: $ZUSTAND (ändern mit --neues-passwort oder --ohne-passwort)"
fi

echo "→ Port prüfen"
if [ -n "${WEB_PORT:-}" ]; then
  ssh_pi "cd '$DIR' && touch .env && grep -v '^WEB_PORT=' .env > .env.neu || true; echo 'WEB_PORT=$WEB_PORT' >> .env.neu && mv .env.neu .env && chmod 600 .env"
fi
PORT=$(ssh_pi "cd '$DIR' && grep -s '^WEB_PORT=' .env | cut -d= -f2 || true")
PORT="${PORT:-8090}"
BELEGT=$(ssh_pi "if docker ps --format '{{.Names}}' | grep -qx ga-web; then echo frei; elif (ss -ltnH 2>/dev/null || netstat -ltn 2>/dev/null) | grep -qE '[:.]$PORT[[:space:]]'; then echo belegt; else echo frei; fi")
if [ "$BELEGT" = "belegt" ]; then
  echo "   Port $PORT ist auf dem Pi schon belegt. Laufende Container und ihre Ports:"
  ssh_pi "docker ps --format '   {{.Names}}  {{.Ports}}'"
  echo "   Anderen Port wählen, z. B.:  WEB_PORT=8091 ./deploy/deploy.sh $PI"
  exit 1
fi
echo "   Port $PORT"

echo "→ Container starten"
ssh_pi "cd '$DIR' && \
  if [ -f .env ] && grep -q '^TUNNEL_TOKEN=.' .env; then \
    docker compose --profile tunnel up -d --remove-orphans; \
  else \
    echo '   (kein TUNNEL_TOKEN in ~/$DIR/.env, starte nur den Webserver fürs Heimnetz)'; \
    docker compose up -d --remove-orphans; \
  fi && docker compose exec -T web nginx -t -q && docker compose exec -T web nginx -s reload && docker compose ps"

HOST="${PI#*@}"
echo
echo "Fertig. Im Heimnetz: http://$HOST:$PORT"
echo "Im Cloudflare-Tunnel als Service eintragen: HTTP  $HOST:$PORT"
