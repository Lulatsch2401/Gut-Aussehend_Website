#!/usr/bin/env bash
# Website auf den Raspberry Pi bringen (nginx direkt auf dem Pi, ohne Docker).
# Auf dem Mac im Repo-Ordner ausführen:
#   ./deploy/deploy.sh [benutzer@]IP-des-Pi                    normal (Passwortschutz bleibt, wie er ist)
#   ./deploy/deploy.sh [benutzer@]IP-des-Pi --neues-passwort   Benutzer/Passwort für die Seite neu setzen
#   ./deploy/deploy.sh [benutzer@]IP-des-Pi --ohne-passwort    Seite ohne Passwort, für den echten Start
# Optional: WEB_PORT=8091 ./deploy/deploy.sh ...   Port im Heimnetz (Standard 8090, wird auf dem Pi gemerkt)
#
# Beim ersten Mal richtet das Skript den Pi ein (fragt dafür nach dem sudo-Passwort):
# nginx installieren, Ordner /var/www/gut-aussehend anlegen und erlauben, dass nginx
# danach ohne Passwort neu geladen werden darf. Danach braucht es kein sudo-Passwort mehr.
set -euo pipefail

PI="${1:?Aufruf: ./deploy/deploy.sh [benutzer@]IP-des-Pi [--neues-passwort|--ohne-passwort]}"
MODUS="${2:-}"
case "$MODUS" in ""|--neues-passwort|--ohne-passwort) ;; *) echo "Unbekannte Option: $MODUS"; exit 1;; esac
BASE="${GA_BASE:-/var/www/gut-aussehend}"          # auf dem Pi
NGINX_ETC="${GA_NGINX_ETC:-/etc/nginx}"            # auf dem Pi
cd "$(dirname "$0")/.."

# Eine SSH-Verbindung für alle Schritte, damit das SSH-Passwort nur einmal abgefragt wird
mkdir -p "$HOME/.ssh"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-ga-%r@%h-%p -o ControlPersist=120"
ssh_pi()     { ssh $SSH_OPTS "$PI" "$@"; }
ssh_pi_tty() { ssh -t $SSH_OPTS "$PI" "$@"; }

echo "→ Pi prüfen"
EINGERICHTET=$(ssh_pi "[ -L '$NGINX_ETC/sites-enabled/gut-aussehend' ] && [ -d '$BASE/site' ] && [ -w '$BASE' ] && sudo -n nginx -t >/dev/null 2>&1 && echo ja || echo nein")
if [ "$EINGERICHTET" != "ja" ]; then
  echo "   Erste Einrichtung (fragt nach dem sudo-Passwort des Pi)"
  ssh_pi_tty "set -e
    U=\$(id -un)
    FRISCH=nein
    if ! command -v nginx >/dev/null; then
      FRISCH=ja
      sudo apt-get update -q
      sudo apt-get install -y -q nginx || true
    fi
    # Die Standardseite von nginx (Port 80) nur bei einer frischen Installation abschalten
    if [ \"\$FRISCH\" = ja ]; then sudo rm -f '$NGINX_ETC/sites-enabled/default'; sudo dpkg --configure -a; fi
    sudo mkdir -p '$BASE/site'
    sudo chown -R \"\$U\": '$BASE'
    sudo chmod 755 '$BASE' '$BASE/site'
    [ -f '$BASE/auth.conf' ] || : > '$BASE/auth.conf'
    [ -f '$BASE/htpasswd' ] || : > '$BASE/htpasswd'
    [ -f '$BASE/nginx.conf' ] || echo '# wird von deploy.sh geschrieben' > '$BASE/nginx.conf'
    sudo ln -sfn '$BASE/nginx.conf' '$NGINX_ETC/sites-enabled/gut-aussehend'
    # nginx prüfen und neu laden ohne Passwort erlauben, sonst nichts
    printf '%s ALL=(root) NOPASSWD: /usr/sbin/nginx -t, /usr/bin/systemctl reload nginx\n' \"\$U\" | sudo tee /etc/sudoers.d/gut-aussehend >/dev/null
    sudo chmod 440 /etc/sudoers.d/gut-aussehend
    sudo visudo -cf /etc/sudoers.d/gut-aussehend >/dev/null
    sudo systemctl enable --now nginx >/dev/null 2>&1 || true
    echo '   eingerichtet'"
fi

echo "→ Port prüfen"
ALT_PORT=$(ssh_pi "cat '$BASE/port' 2>/dev/null || true")
PORT="${WEB_PORT:-${ALT_PORT:-8090}}"
if [ "$PORT" != "$ALT_PORT" ]; then
  BELEGT=$(ssh_pi "(ss -ltnH 2>/dev/null || netstat -ltn 2>/dev/null) | grep -qE '[:.]$PORT[[:space:]]' && echo belegt || echo frei")
  if [ "$BELEGT" = "belegt" ]; then
    echo "   Port $PORT ist auf dem Pi schon belegt. Belegte Ports:"
    ssh_pi "(ss -ltnH 2>/dev/null || netstat -ltn 2>/dev/null) | awk '{print \"   \" \$4}' | sort -u"
    echo "   Anderen Port wählen, z. B.:  WEB_PORT=8091 ./deploy/deploy.sh $PI"
    exit 1
  fi
fi
echo "   Port $PORT"

echo "→ Website-Dateien übertragen"
rsync -az --delete --chmod=D755,F644 -e "ssh $SSH_OPTS" \
  --exclude '.git' --exclude '.gitignore' --exclude '.vscode' --exclude '.DS_Store' \
  --exclude 'deploy' --exclude 'README.md' --exclude 'node_modules' \
  ./ "$PI:$BASE/site/"

echo "→ nginx-Konfiguration übertragen"
sed -e "s|__PORT__|$PORT|g" -e "s|__BASE__|$BASE|g" deploy/nginx.conf \
  | ssh_pi "cat > '$BASE/nginx.conf.neu' && echo '$PORT' > '$BASE/port'"

echo "→ Passwortschutz"
# auth.conf leer = Schutz aus, mit auth_basic = Schutz an. Beim ersten Mal wird ein Passwort eingerichtet.
ZUSTAND=$(ssh_pi "cd '$BASE' && if grep -q auth_basic auth.conf 2>/dev/null && [ -s htpasswd ]; then echo an; elif [ -f auth.aus ]; then echo aus; else echo neu; fi")
if [ "$MODUS" = "--ohne-passwort" ]; then
  ssh_pi "cd '$BASE' && : > auth.conf && touch auth.aus"
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
  printf '%s:%s\n' "$WEB_USER" "$HASH" | ssh_pi "cd '$BASE' && cat > htpasswd && chmod 644 htpasswd && rm -f auth.aus"
  ssh_pi "cd '$BASE' && printf 'auth_basic \"Gut und Aussehend\";\nauth_basic_user_file $BASE/htpasswd;\n' > auth.conf"
  echo "   an: Benutzer \"$WEB_USER\" mit neuem Passwort"
else
  echo "   unverändert: $ZUSTAND (ändern mit --neues-passwort oder --ohne-passwort)"
fi

echo "→ nginx neu laden"
# Neue Konfiguration erst übernehmen, wenn nginx sie für gültig hält, sonst die alte behalten
ssh_pi "cd '$BASE' && cp nginx.conf nginx.conf.alt 2>/dev/null || true; mv nginx.conf.neu nginx.conf && \
  if sudo -n nginx -t >/dev/null 2>&1; then sudo -n systemctl reload nginx && echo '   ok'; \
  else echo '   Fehler in der nginx-Konfiguration:'; sudo -n nginx -t || true; \
    [ -f nginx.conf.alt ] && mv nginx.conf.alt nginx.conf; exit 1; fi"

HOST="${PI#*@}"
echo
echo "Fertig. Im Heimnetz: http://$HOST:$PORT"
echo "Im Cloudflare-Tunnel als Service eintragen: HTTP  $HOST:$PORT"
