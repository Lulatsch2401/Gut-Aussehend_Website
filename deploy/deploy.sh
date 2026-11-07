#!/usr/bin/env bash
# Website auf den Raspberry Pi bringen (nginx direkt auf dem Pi, ohne Docker).
# Auf dem Mac im Repo-Ordner ausführen:
#   ./deploy/deploy.sh [benutzer@]IP-des-Pi                    normal (Passwortschutz bleibt, wie er ist)
#   ./deploy/deploy.sh [benutzer@]IP-des-Pi --neues-passwort   Benutzer/Passwort für die Seite neu setzen
#   ./deploy/deploy.sh [benutzer@]IP-des-Pi --ohne-passwort    Seite ohne Passwort, für den echten Start
#   ./deploy/deploy.sh [benutzer@]IP-des-Pi --kontakt-einrichten  E-Mail-Zugang fürs Kontaktformular (neu) setzen
# Optional: WEB_PORT=8091 ./deploy/deploy.sh ...   Port im Heimnetz (Standard 8090, wird auf dem Pi gemerkt)
#
# Beim ersten Mal richtet das Skript den Pi ein (fragt dafür nach dem sudo-Passwort):
# nginx installieren, Ordner /var/www/gut-aussehend anlegen und erlauben, dass nginx
# danach ohne Passwort neu geladen werden darf. Danach braucht es kein sudo-Passwort mehr.
set -euo pipefail

PI="${1:?Aufruf: ./deploy/deploy.sh [benutzer@]IP-des-Pi [--neues-passwort|--ohne-passwort|--kontakt-einrichten]}"
MODUS="${2:-}"
case "$MODUS" in ""|--neues-passwort|--ohne-passwort|--kontakt-einrichten) ;; *) echo "Unbekannte Option: $MODUS"; exit 1;; esac
BASE="${GA_BASE:-/var/www/gut-aussehend}"          # auf dem Pi
NGINX_ETC="${GA_NGINX_ETC:-/etc/nginx}"            # auf dem Pi
KONTAKT_PORT=8095                                  # Kontaktformular, nur intern (127.0.0.1)
cd "$(dirname "$0")/.."

# Eine SSH-Verbindung für alle Schritte, damit das SSH-Passwort nur einmal abgefragt wird
mkdir -p "$HOME/.ssh"
SSH_OPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-ga-%r@%h-%p -o ControlPersist=120"
ssh_pi()     { ssh $SSH_OPTS "$PI" "$@"; }
ssh_pi_tty() { ssh -t $SSH_OPTS "$PI" "$@"; }

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

echo "→ Pi prüfen"
EINGERICHTET=$(ssh_pi "[ -L '$NGINX_ETC/sites-enabled/gut-aussehend' ] && [ -d '$BASE/site' ] && [ -w '$BASE' ] && [ -f /etc/systemd/system/ga-kontakt.service ] && sudo -n -l /usr/bin/systemctl reload-or-restart nginx >/dev/null 2>&1 && sudo -n -l /usr/bin/systemctl restart ga-kontakt >/dev/null 2>&1 && echo ja || echo nein")
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
    # nginx prüfen und (neu) starten ohne Passwort erlauben, sonst nichts
    printf '%s ALL=(root) NOPASSWD: /usr/sbin/nginx -t, /usr/bin/systemctl reload-or-restart nginx, /usr/bin/systemctl restart ga-kontakt\n' \"\$U\" | sudo tee /etc/sudoers.d/gut-aussehend >/dev/null
    sudo chmod 440 /etc/sudoers.d/gut-aussehend
    sudo visudo -cf /etc/sudoers.d/gut-aussehend >/dev/null
    sudo systemctl enable nginx >/dev/null 2>&1 || true
    # Dienst fürs Kontaktformular (läuft als dein Benutzer, darf nur lesen, hört nur auf 127.0.0.1)
    [ -f '$BASE/kontakt.py' ] || echo 'import time; time.sleep(3600)' > '$BASE/kontakt.py'
    printf '%s\n' '[Unit]' 'Description=Gut und Aussehend Kontaktformular' 'After=network-online.target' 'Wants=network-online.target' '' \
      '[Service]' \"User=\$U\" 'Environment=KONTAKT_PORT=$KONTAKT_PORT' 'ExecStart=/usr/bin/python3 $BASE/kontakt.py' 'Restart=on-failure' 'RestartSec=5' \
      'NoNewPrivileges=true' 'ProtectSystem=strict' 'ProtectHome=true' 'PrivateTmp=true' 'ReadOnlyPaths=$BASE' '' \
      '[Install]' 'WantedBy=multi-user.target' | sudo tee /etc/systemd/system/ga-kontakt.service >/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable ga-kontakt >/dev/null 2>&1
    # Firewall (ufw): Port im Heimnetz freigeben, damit die Seite dort im Browser erreichbar ist
    if command -v ufw >/dev/null && sudo ufw status | grep -q 'Status: active'; then
      NETZ=\$(ip -4 route | awk '/proto kernel/ && /scope link/ {print \$1; exit}')
      sudo ufw allow from \"\${NETZ:-192.168.0.0/16}\" to any port $PORT proto tcp >/dev/null && echo \"   Firewall: Port $PORT für \${NETZ:-192.168.0.0/16} freigegeben\"
    fi
    echo '   eingerichtet'"
fi

echo "→ Website-Dateien übertragen"
rsync -az --delete -e "ssh $SSH_OPTS" \
  --exclude '.git' --exclude '.gitignore' --exclude '.vscode' --exclude '.DS_Store' \
  --exclude 'deploy' --exclude '*.md' --exclude 'node_modules' \
  ./ "$PI:$BASE/site/"
ssh_pi "find '$BASE/site' -type d -exec chmod 755 {} + && find '$BASE/site' -type f -exec chmod 644 {} +"
rsync -a -e "ssh $SSH_OPTS" deploy/kontakt.py "$PI:$BASE/kontakt.py"

echo "→ nginx-Konfiguration übertragen"
sed -e "s|__PORT__|$PORT|g" -e "s|__BASE__|$BASE|g" -e "s|__KONTAKT_PORT__|$KONTAKT_PORT|g" deploy/nginx.conf \
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

echo "→ Kontaktformular"
# Zugangsdaten fürs Versenden (IONOS-Postfach). Liegen nur auf dem Pi in kontakt.json (nur für dich lesbar).
K_ZUSTAND=$(ssh_pi "cd '$BASE' && if [ -s kontakt.json ]; then echo da; elif [ -f kontakt.spaeter ]; then echo spaeter; else echo neu; fi")
K_TEST=nein
if [ "$MODUS" = "--kontakt-einrichten" ] || [ "$K_ZUSTAND" = "neu" ]; then
  echo "   Das Formular verschickt Nachrichten über ein E-Mail-Postfach bei IONOS."
  read -rp "   Absender-Postfach (z. B. sponsoring@gut-aussehend.de, Enter = später): " K_USER
  if [ -z "$K_USER" ]; then
    ssh_pi "touch '$BASE/kontakt.spaeter'"
    echo "   übersprungen: das Formular zeigt bis dahin die E-Mail-Adresse an. Später: $0 $PI --kontakt-einrichten"
  else
    read -rsp "   Passwort dieses Postfachs: " K_PW; echo
    read -rp "   Nachrichten zustellen an [$K_USER]: " K_AN; K_AN="${K_AN:-$K_USER}"
    read -rp "   SMTP-Server [smtp.ionos.de:587]: " K_SRV; K_SRV="${K_SRV:-smtp.ionos.de:587}"
    printf '%s\n%s\n%s\n%s\n' "$K_USER" "$K_PW" "$K_AN" "$K_SRV" | ssh_pi "cd '$BASE' && python3 kontakt.py --konfig && rm -f kontakt.spaeter"
    unset K_PW
    K_TEST=ja
  fi
else
  echo "   unverändert: $K_ZUSTAND (ändern mit --kontakt-einrichten)"
fi

echo "→ nginx neu laden"
# Neue Konfiguration erst übernehmen, wenn nginx sie für gültig hält, sonst die alte behalten
ssh_pi "cd '$BASE' && cp nginx.conf nginx.conf.alt 2>/dev/null || true; mv nginx.conf.neu nginx.conf && \
  if sudo -n nginx -t >/dev/null 2>&1; then sudo -n systemctl reload-or-restart nginx && echo '   ok'; \
  else echo '   Fehler in der nginx-Konfiguration:'; sudo -n nginx -t || true; \
    [ -f nginx.conf.alt ] && mv nginx.conf.alt nginx.conf; exit 1; fi"

echo "→ Kontaktformular starten"
ssh_pi "sudo -n systemctl restart ga-kontakt && sleep 1 && systemctl is-active --quiet ga-kontakt && echo '   läuft' || { echo '   startet nicht:'; journalctl -u ga-kontakt -n 15 --no-pager 2>/dev/null || true; }"
if [ "$K_TEST" = ja ]; then
  ssh_pi "cd '$BASE' && python3 kontakt.py --test" || echo "   Bitte Postfach und Passwort prüfen: $0 $PI --kontakt-einrichten"
fi

HOST="${PI#*@}"
echo
echo "Fertig. Im Heimnetz: http://$HOST:$PORT"
echo "Im Cloudflare-Tunnel als Service eintragen: HTTP  $HOST:$PORT"
