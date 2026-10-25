#!/usr/bin/env python3
"""Kontaktformular für gut-aussehend.de – läuft auf dem Pi, nur mit Python-Standardbibliothek.

nginx leitet POST /api/kontakt an diesen Dienst weiter (nur 127.0.0.1). Er prüft die Eingaben,
bremst Spam und schickt die Nachricht per SMTP (IONOS) an das Vereinspostfach.
Gespeichert wird nichts, die Nachricht existiert danach nur als E-Mail.

  python3 kontakt.py               Dienst starten (so startet ihn systemd)
  python3 kontakt.py --konfig      Zugangsdaten von stdin lesen (je Zeile: Benutzer, Passwort, Empfänger, Server)
  python3 kontakt.py --test        Testmail an den Empfänger schicken
"""
import json, os, re, smtplib, ssl, sys, time, threading
from collections import defaultdict, deque
from email.message import EmailMessage
from email.utils import formataddr, make_msgid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

HIER = os.path.dirname(os.path.abspath(__file__))
KONFIG = os.path.join(HIER, "kontakt.json")
PORT = int(os.environ.get("KONTAKT_PORT", "8095"))
ANLIEGEN = {"sponsoring": "Sponsoring", "frage": "Frage zum Verein", "sonstiges": "Sonstiges"}
MAIL_RE = re.compile(r"^[^@\s<>\"',;]{1,64}@[^@\s<>\"',;]{1,190}\.[A-Za-z]{2,}$")
PRO_IP_STUNDE, PRO_TAG = 5, 100

_lock = threading.Lock()
_pro_ip = defaultdict(deque)
_alle = deque()


def konfig():
    try:
        with open(KONFIG, encoding="utf-8") as f:
            k = json.load(f)
        return k if k.get("user") and k.get("passwort") else None
    except (OSError, ValueError):
        return None


def senden(k, betreff, text, antwort_an=None):
    msg = EmailMessage()
    msg["From"] = formataddr(("Website Gut und Aussehend", k["user"]))
    msg["To"] = k.get("an") or k["user"]
    msg["Subject"] = betreff
    msg["Message-ID"] = make_msgid(domain="gut-aussehend.de")
    if antwort_an:
        msg["Reply-To"] = antwort_an
    msg.set_content(text)
    host, port = k.get("server") or "smtp.ionos.de", int(k.get("port") or 587)
    ctx = ssl.create_default_context()
    if port == 465:
        with smtplib.SMTP_SSL(host, port, context=ctx, timeout=20) as s:
            s.login(k["user"], k["passwort"]); s.send_message(msg)
    else:
        with smtplib.SMTP(host, port, timeout=20) as s:
            s.starttls(context=ctx); s.login(k["user"], k["passwort"]); s.send_message(msg)


def gebremst(ip):
    jetzt = time.time()
    with _lock:
        q = _pro_ip[ip]
        while q and jetzt - q[0] > 3600: q.popleft()
        while _alle and jetzt - _alle[0] > 86400: _alle.popleft()
        if len(q) >= PRO_IP_STUNDE or len(_alle) >= PRO_TAG:
            return True
        q.append(jetzt); _alle.append(jetzt)
        if len(_pro_ip) > 5000:  # Speicher begrenzen
            for alt in [i for i, d in _pro_ip.items() if not d][:1000]: del _pro_ip[alt]
        return False


def pruefen(d):
    f = {k: (d.get(k) or "").strip() for k in ("name", "email", "nachricht", "anliegen", "firma", "ts", "einwilligung")}
    fehler = []
    if not 1 <= len(f["name"]) <= 100 or "\n" in f["name"] or "\r" in f["name"]: fehler.append("name")
    if len(f["email"]) > 200 or not MAIL_RE.match(f["email"]): fehler.append("email")
    if not 10 <= len(f["nachricht"]) <= 5000: fehler.append("nachricht")
    if f["anliegen"] not in ANLIEGEN: f["anliegen"] = "sonstiges"
    if f["einwilligung"] not in ("1", "true", "on", "ja"): fehler.append("einwilligung")
    return f, fehler


class H(BaseHTTPRequestHandler):
    server_version = "ga-kontakt"
    sys_version = ""

    def log_message(self, fmt, *args):  # keine Inhalte, keine IPs ins Log
        pass

    def antwort(self, code, daten, formular):
        if formular:  # ohne JavaScript abgeschickt: kleine Antwortseite
            if daten.get("ok"):
                titel, text = "Danke!", "Ihre Nachricht ist angekommen. Wir melden uns bald."
            elif daten.get("fehler") == "eingabe":
                titel, text = "Bitte prüfen", "Name, E-Mail, eine Nachricht (mindestens 10 Zeichen) und das Häkchen beim Datenschutz werden gebraucht."
            else:
                titel, text = "Das hat nicht geklappt", "Bitte schreiben Sie uns direkt an sponsoring@gut-aussehend.de."
            body = (f'<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">'
                    f'<title>{titel} – Gut und Aussehend</title><link rel="stylesheet" href="/assets/css/site.css">'
                    f'<body><main class="wrap legal"><h1 class="neon">{titel}</h1><p>{text}</p>'
                    f'<p><a class="btn" href="/#kontakt">Zurück zur Seite</a></p></main></body></html>').encode()
            self.send_response(code if code != 200 else 200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers(); self.wfile.write(body); return
        body = json.dumps(daten).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers(); self.wfile.write(body)

    def do_GET(self):
        if urlsplit(self.path).path == "/api/kontakt":
            return self.antwort(200, {"ok": True, "bereit": konfig() is not None}, False)
        self.antwort(404, {"ok": False, "fehler": "unbekannt"}, False)

    def do_POST(self):
        if urlsplit(self.path).path != "/api/kontakt":
            return self.antwort(404, {"ok": False, "fehler": "unbekannt"}, False)
        typ = (self.headers.get("Content-Type") or "").split(";")[0].strip().lower()
        formular = typ == "application/x-www-form-urlencoded"
        # Nur Anfragen von der eigenen Seite annehmen
        herkunft = self.headers.get("Origin")
        host = (self.headers.get("Host") or "").lower().rsplit(":", 1)[0]
        if herkunft and (urlsplit(herkunft).hostname or "").lower() != host:
            return self.antwort(403, {"ok": False, "fehler": "herkunft"}, formular)
        try:
            laenge = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            laenge = -1
        if not 0 < laenge <= 20000:
            return self.antwort(413, {"ok": False, "fehler": "groesse"}, formular)
        roh = self.rfile.read(laenge).decode("utf-8", "replace")
        try:
            if typ == "application/json":
                d = json.loads(roh); d = {k: str(v) for k, v in d.items()} if isinstance(d, dict) else {}
            elif formular:
                d = {k: v[0] for k, v in parse_qs(roh).items()}
            else:
                return self.antwort(415, {"ok": False, "fehler": "format"}, False)
        except ValueError:
            return self.antwort(400, {"ok": False, "fehler": "format"}, formular)

        f, fehler = pruefen(d)
        # Spam: verstecktes Feld ausgefüllt oder Formular in unter 3 Sekunden abgeschickt -> still verwerfen
        try:
            zu_schnell = f["ts"] and (time.time() * 1000 - float(f["ts"])) < 3000
        except ValueError:
            zu_schnell = False
        if f["firma"] or zu_schnell:
            return self.antwort(200, {"ok": True}, formular)
        if fehler:
            return self.antwort(422, {"ok": False, "fehler": "eingabe", "felder": fehler}, formular)
        ip = self.headers.get("CF-Connecting-IP") or self.headers.get("X-Real-IP") or self.client_address[0]
        if gebremst(ip):
            return self.antwort(429, {"ok": False, "fehler": "zu_viele"}, formular)
        k = konfig()
        if not k:
            return self.antwort(503, {"ok": False, "fehler": "nicht_eingerichtet"}, formular)
        anliegen = ANLIEGEN[f["anliegen"]]
        text = (f"Neue Nachricht über das Kontaktformular auf gut-aussehend.de\n\n"
                f"Anliegen: {anliegen}\nName:     {f['name']}\nE-Mail:   {f['email']}\n\n"
                f"{f['nachricht']}\n\n--\nAuf „Antworten“ klicken, um direkt zu antworten.\n")
        try:
            senden(k, f"[Website] {anliegen}: {f['name']}", text, antwort_an=f["email"])
        except Exception as e:  # noqa: BLE001
            print(f"Versand fehlgeschlagen: {type(e).__name__}: {e}", file=sys.stderr, flush=True)
            return self.antwort(502, {"ok": False, "fehler": "versand"}, formular)
        print("Nachricht verschickt", flush=True)
        self.antwort(200, {"ok": True}, formular)


def main():
    if "--konfig" in sys.argv:
        zeilen = [z.rstrip("\n") for z in sys.stdin]
        zeilen += [""] * (4 - len(zeilen))
        user, pw, an, server = zeilen[:4]
        host, _, port = (server or "smtp.ionos.de:587").partition(":")
        alt = os.umask(0o077)
        with open(KONFIG, "w", encoding="utf-8") as fh:
            json.dump({"user": user, "passwort": pw, "an": an or user, "server": host, "port": int(port or 587)}, fh)
        os.umask(alt); os.chmod(KONFIG, 0o600)
        print("   gespeichert"); return
    if "--test" in sys.argv:
        k = konfig()
        if not k:
            print("   noch keine Zugangsdaten (deploy.sh ... --kontakt-einrichten)"); sys.exit(1)
        try:
            senden(k, "[Website] Testnachricht", "Das Kontaktformular von gut-aussehend.de kann E-Mails verschicken.\n")
        except Exception as e:  # noqa: BLE001
            print(f"   Testmail fehlgeschlagen: {type(e).__name__}: {e}"); sys.exit(1)
        print(f"   Testmail an {k.get('an') or k['user']} verschickt"); return
    srv = ThreadingHTTPServer(("127.0.0.1", PORT), H)
    srv.daemon_threads = True
    print(f"Kontaktformular hört auf 127.0.0.1:{PORT}", flush=True)
    srv.serve_forever()


if __name__ == "__main__":
    main()
