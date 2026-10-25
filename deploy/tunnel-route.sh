#!/usr/bin/env bash
# Hängt gut-aussehend.de und www.gut-aussehend.de an den vorhandenen, lokal verwalteten
# Cloudflare Tunnel auf dem Pi (der Tunnel, über den auch auslagen.gut-aussehend.de läuft).
# Auf dem Mac im Repo-Ordner ausführen:
#   ./deploy/tunnel-route.sh [benutzer@]IP-des-Pi
# Optional: WEB_PORT=8091 ./deploy/tunnel-route.sh ...   (Standard 8090, wie bei deploy.sh)
set -euo pipefail
PI="${1:?Aufruf: ./deploy/tunnel-route.sh [benutzer@]IP-des-Pi}"
PORT="${WEB_PORT:-8090}"

SSH_OPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-ga-%r@%h-%p -o ControlPersist=120"
mkdir -p "$HOME/.ssh"
SKRIPT=$(mktemp)
trap 'rm -f "$SKRIPT"' EXIT
cat > "$SKRIPT" <<'REMOTE'
set -euo pipefail
command -v cloudflared >/dev/null || { echo "cloudflared ist auf diesem Pi nicht installiert. Läuft der Tunnel auf einem anderen Gerät?"; exit 1; }

# Konfigurationsdatei des laufenden Tunnels finden
CONF=$(systemctl cat cloudflared 2>/dev/null | grep -o -- '--config[= ][^ ]*' | head -1 | sed 's/--config[= ]//' || true)
for c in "$CONF" /etc/cloudflared/config.yml /etc/cloudflared/config.yaml "$HOME/.cloudflared/config.yml" "$HOME/.cloudflared/config.yaml"; do
  if [ -n "$c" ] && sudo test -f "$c"; then CONF="$c"; break; fi; CONF=""
done
[ -n "$CONF" ] || { echo "Keine config.yml von cloudflared gefunden."; systemctl cat cloudflared 2>/dev/null | grep ExecStart || true; exit 1; }
echo "→ Konfiguration: $CONF"
sudo cat "$CONF"; echo "-----"

if sudo grep -qE 'hostname:[[:space:]]*gut-aussehend\.de' "$CONF"; then
  echo "→ gut-aussehend.de ist schon eingetragen, keine Änderung."
else
  TMP=$(mktemp)
  sudo cat "$CONF" | PORT="$PORT" python3 -c '
import sys, os, re
port = os.environ["PORT"]
lines = sys.stdin.read().splitlines()
# Letzte Regel ohne hostname (Auffangregel, z. B. "- service: http_status:404") suchen
idx = None
for i, l in enumerate(lines):
    if re.match(r"^\s*-\s*service:\s*", l):
        idx = i
if idx is None:
    sys.exit("Keine Auffangregel (- service: ...) unter ingress gefunden, bitte Datei prüfen.")
ind = re.match(r"^(\s*)-", lines[idx]).group(1)
new = []
for h in ("gut-aussehend.de", "www.gut-aussehend.de"):
    new += [f"{ind}- hostname: {h}", f"{ind}  service: http://localhost:{port}"]
print("\n".join(lines[:idx] + new + lines[idx:]))
' > "$TMP"
  echo "→ Neue Regeln:"; diff <(sudo cat "$CONF") "$TMP" || true
  sudo cp "$CONF" "$CONF.vor-website"
  sudo cp "$TMP" "$CONF"; rm -f "$TMP"
  if ! sudo cloudflared tunnel --config "$CONF" ingress validate; then
    echo "→ Konfiguration ungültig, stelle die alte wieder her."; sudo cp "$CONF.vor-website" "$CONF"; exit 1
  fi
  echo "→ Tunnel neu starten"
  sudo systemctl restart cloudflared
  sleep 3
  if ! systemctl is-active --quiet cloudflared; then
    echo "→ Tunnel startet nicht, stelle die alte Konfiguration wieder her."; sudo cp "$CONF.vor-website" "$CONF"; sudo systemctl restart cloudflared; exit 1
  fi
  echo "   läuft (Sicherung: $CONF.vor-website)"
fi

# DNS-Einträge: geht nur mit dem Cloudflare-Zertifikat (cert.pem) vom Einrichten des Tunnels
TUNNEL=$(sudo grep -E '^tunnel:' "$CONF" | awk '{print $2}')
CERT=""
for c in "$HOME/.cloudflared/cert.pem" /etc/cloudflared/cert.pem /root/.cloudflared/cert.pem; do sudo test -f "$c" && CERT="$c" && break; done
if [ -n "$CERT" ]; then
  for h in gut-aussehend.de www.gut-aussehend.de; do
    sudo cloudflared tunnel --origincert "$CERT" route dns "$TUNNEL" "$h" || true
  done
else
  echo
  echo "→ DNS bitte im Cloudflare-Dashboard anlegen (DNS → Records → Add record), zwei Einträge:"
  echo "     Typ CNAME   Name @     Ziel $TUNNEL.cfargotunnel.com   Proxy an (orange)"
  echo "     Typ CNAME   Name www   Ziel $TUNNEL.cfargotunnel.com   Proxy an (orange)"
fi
echo
echo "Fertig. Test: curl -sI http://localhost:$PORT | head -1 (sollte 401 zeigen, wegen Passwort)"
curl -sI "http://localhost:$PORT" | head -1 || true
REMOTE

# Skript auf den Pi kopieren und dort mit Terminal ausführen (falls sudo nach dem Passwort fragt)
scp -q $SSH_OPTS "$SKRIPT" "$PI:/tmp/ga-tunnel-route.sh"
ssh -t $SSH_OPTS "$PI" "PORT=$PORT bash /tmp/ga-tunnel-route.sh; rm -f /tmp/ga-tunnel-route.sh"
