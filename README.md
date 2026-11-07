# Website Gut und Aussehend

Statische Website für gut-aussehend.de. Kein Build-Schritt, keine Abhängigkeiten, keine externen Dienste.
Stand: Entwurf vom 07.10.2026.

## Ansehen

```bash
cd gut-aussehend-website
python3 -m http.server 8000
# dann http://localhost:8000 öffnen
```

Ein Doppelklick auf `index.html` funktioniert auch.

## Aufbau

| Pfad | Inhalt |
|---|---|
| `index.html` | Startseite mit allen Abschnitten |
| `impressum.html`, `datenschutz.html` | Platzhalter, noch nicht rechtsgültig |
| `assets/data/inhalte.js` | Sponsoren und Termine. Nur diese Datei ändern, die Seite baut sich daraus. |
| `assets/css/site.css` | Gestaltung. Farben und Schriften stehen oben als Variablen. |
| `assets/js/site.js` | Menü, Termine, Sponsorenwand, Großansicht der Fotos |
| `assets/img/` | Fotos als WebP in zwei Größen (`-s` 800 px, `-l` groß), ohne EXIF- und GPS-Daten |
| `assets/fonts/` | Schriften lokal eingebunden (je Motto eine eigene Überschriftenschrift), Lizenzen in `LIZENZEN.txt` |

## Nach Änderungen an CSS oder JS

In `index.html`, `impressum.html` und `datenschutz.html` hängt an `site.css`, `site.js` und `inhalte.js` ein `?v=...`. Nach einer Änderung an diesen Dateien die Zahl hochsetzen (z. B. Datum), sonst zeigen Browser oft noch die alte Version aus dem Cache.

## Sponsor eintragen

1. Logo nach `assets/img/sponsoren/` legen (SVG oder PNG mit transparentem Hintergrund).
2. In `assets/data/inhalte.js` einen Eintrag ergänzen:

```js
sponsoren: [
  { name: "Musterfirma GmbH", logo: "assets/img/sponsoren/musterfirma.svg",
    url: "https://www.example.de", paket: "wagen" }
],
```

Sobald ein Sponsor eingetragen ist, verschwinden die leeren Felder und der Hinweis "Hier ist noch Platz".

## Sessions und Mottos

Ganz oben im Kopf wählt man die Session (2026 Matrix, 2025 Work in Progress, 2024 Up). Die ganze Seite übernimmt dann den Look dieses Mottos: Farben, Überschriftenschrift, Deko (grüner Code, Baustellenband, Ballons), das Foto im Aufmacher und den Wagen-Abschnitt. Die Wahl bleibt im Browser gespeichert. Ein Link wie `#wagen-2024` öffnet direkt die passende Session.

Der Abschnitt Altstadttanz hängt an derselben Auswahl: Session 2026 zeigt die Fotos vom Altstadttanz 2026, 2025 die von 2025, 2024 die von 2024. Jedes Jahr hat eigene Fotos in einem Block `<div class="year-panel" data-for="...">`. Ein Link wie `#altstadttanz-2024` öffnet direkt die Session 2024. Für ein neues Jahr den Block kopieren und `data-for` auf das neue Motto setzen.

Neues Motto ergänzen:

1. In `index.html` einen Block `<div class="motto" ...>` im Abschnitt "Wagen" kopieren und `id`, `data-motto`, `data-year`, `data-title` und den Inhalt anpassen.
2. Im Kopf (`#motto-bar`) einen Knopf mit demselben `data-motto` ergänzen.
3. Im Aufmacher ein Foto und einen Auszeichnungs-Link mit `data-for="neues-motto"` und `hidden` ergänzen.
4. In `assets/css/site.css` unter "Mottos" einen Block `:root[data-motto="neues-motto"] { ... }` mit Farben und Schrift anlegen, in `assets/js/site.js` die Farbe in `themeColors` und im kleinen Skript oben in den HTML-Seiten den Namen in der Liste ergänzen.

## Instagram

Der Instagram-Kanal @gut_und_aussehend ist verlinkt im Kopf, im Aufmacher, in den Kennzahlen, in einem eigenen Abschnitt, bei den Sponsorenpaketen, im Kontakt und im Fuß. Die Followerzahl erscheint nur einmal als „Über … Follower“ im Instagram-Abschnitt und steht in `assets/data/inhalte.js` (`instagram.follower`). Die Seite bettet nichts von Instagram ein, es sind reine Links (keine Cookies, kein Datenschutz-Hinweis nötig). Die Kacheln im Abschnitt sind eigene Fotos von der Seite und führen zum Profil.

## Termin eintragen

In `assets/data/inhalte.js` unter `termine`. `offen: true` zeigt den Hinweis "Termin folgt".

## Vor dem Livegang

Die Liste aller offenen Punkte steht in [OFFENE-PUNKTE.md](OFFENE-PUNKTE.md).

- [ ] Mitgliederzahl bestätigen (aktuell 38, aus dem Rechnungsportal)
- [ ] Ansprechpartner im Kontakt eintragen
- [ ] IONOS-Postfach für das Kontaktformular anlegen und mit `--kontakt-einrichten` hinterlegen
- [ ] Gründer: Einverständnis von Oli, Richard, Robert und Toni einholen
- [ ] Termine 2027 prüfen: Uhrzeit Pegau, Datum Altstadttanz
- [ ] Postfach `sponsoring@gut-aussehend.de` anlegen oder Adresse ändern
- [ ] Rechtsform klären (fürs Impressum)
- [ ] Impressum ausfüllen, Datenschutzerklärung gegenlesen lassen
- [ ] Einverständnis aller erkennbaren Personen auf den Fotos einholen
- [ ] Logo als Vektordatei besorgen (aktuell nur 420 px, daraus sind Kopf-Logo und Favicon geschnitten)
- [ ] Passwortschutz abschalten: `./deploy/deploy.sh 192.168.178.25 --ohne-passwort`
- [ ] Rechnungsportal absichern, bevor Namen von Mitgliedern öffentlich auf der Seite stehen

## Google und Zertifikate

- `robots.txt` und `sitemap.xml` liegen im Hauptordner. Beim Hinzufügen neuer Seiten die Sitemap ergänzen.
- `index.html` hat Beschreibung, Canonical-Link, Open-Graph-Angaben und strukturierte Daten (schema.org Organization).
- `www.gut-aussehend.de` leitet per 301 auf `gut-aussehend.de` um (nginx).
- Das HTTPS-Zertifikat stellt Cloudflare bereit und verlängert es automatisch. Auf dem Pi ist kein Zertifikat nötig, der Tunnel ist selbst verschlüsselt.
- Google sieht die Seite erst, wenn der Passwortschutz aus ist.

## Hosting auf dem Raspberry Pi

Die Seite läuft auf dem Pi 192.168.178.25 direkt mit nginx (ohne Docker) unter `/var/www/gut-aussehend`, im Heimnetz auf Port 8090. Öffentlich erreichbar ist sie über den Cloudflare Tunnel, der dort schon für `auslagen.gut-aussehend.de` läuft. Alles für den Pi liegt in `deploy/`: `deploy.sh` und die nginx-Vorlage `nginx.conf`.

### Einmalig: Domain im Tunnel eintragen

Der Tunnel `gutundaussehend-auslagen` wird lokal verwaltet (config.yml auf dem Pi), deshalb geht das nicht im Dashboard, sondern per Skript:

```bash
./deploy/tunnel-route.sh pi@192.168.178.25
```

Es sucht die config.yml von cloudflared, fügt `gut-aussehend.de` und `www.gut-aussehend.de` → `http://localhost:8090` vor der Auffangregel ein, prüft die Datei, startet den Tunnel neu und stellt bei einem Fehler die alte Datei wieder her (Sicherung `config.yml.vor-website`). Die DNS-Einträge legt es an, wenn auf dem Pi das Cloudflare-Zertifikat liegt. Sonst nennt es die zwei CNAME-Einträge, die im Dashboard unter DNS anzulegen sind. Der Eintrag für `auslagen` bleibt unverändert.

Unter SSL/TLS → Edge Certificates „Always Use HTTPS“ einschalten. In der FritzBox dem Pi eine feste IP geben.

### Passwortschutz

Solange die Seite Entwurf ist, fragt sie beim Aufruf nach Benutzername und Passwort (ein gemeinsames für alle). Das macht nginx auf dem Pi, Cloudflare speichert dabei nichts zwischen.

- Beim ersten `deploy.sh` fragt das Skript nach Benutzername (Standard `verein`) und Passwort.
- Passwort ändern: `./deploy/deploy.sh 192.168.178.25 --neues-passwort`
- Für den echten Start abschalten: `./deploy/deploy.sh 192.168.178.25 --ohne-passwort`
- Ohne Option bleibt es, wie es ist.

Auf dem Pi liegt nur ein Hash des Passworts (`/var/www/gut-aussehend/htpasswd`, außerhalb der ausgelieferten Seite), nie im Repo. In Cloudflare unter SSL/TLS „Always Use HTTPS“ einschalten, damit das Passwort nur verschlüsselt übertragen wird.

### Kontaktformular

Das Formular im Abschnitt Kontakt schickt an `/api/kontakt`. nginx reicht das an `deploy/kontakt.py` weiter, einen kleinen Python-Dienst auf dem Pi (`ga-kontakt`, nur Standardbibliothek, hört nur auf 127.0.0.1:8095). Er prüft die Eingaben, bremst Spam (unsichtbares Fallenfeld, Mindestzeit, höchstens 5 Nachrichten pro Stunde und Absender, 100 pro Tag) und verschickt die Nachricht per SMTP über ein IONOS-Postfach. Antworten gehen per „Antworten“ direkt an den Absender. Auf dem Pi wird nichts gespeichert.

- Beim ersten `deploy.sh` fragt das Skript nach Postfach, Passwort und Empfänger und schickt eine Testmail. Mit Enter lässt sich das überspringen, das Formular verweist dann auf die E-Mail-Adresse.
- Zugang ändern: `./deploy/deploy.sh 192.168.178.25 --kontakt-einrichten`
- Die Zugangsdaten liegen nur auf dem Pi in `/var/www/gut-aussehend/kontakt.json` (nur für den Pi-Benutzer lesbar).
- Fehler beim Versand: `ssh pi@192.168.178.25 journalctl -u ga-kontakt -n 30`

### Bei jeder Änderung

Auf dem Mac im Repo-Ordner:

```bash
./deploy/deploy.sh 192.168.178.25
```

Beim ersten Mal richtet das Skript den Pi ein und fragt dafür nach dem sudo-Passwort: nginx installieren, `/var/www/gut-aussehend` anlegen und erlauben, dass nginx ohne Passwort neu geladen wird. Danach überträgt es die Dateien per `rsync`, prüft die nginx-Konfiguration und lädt nginx neu. Ist die Konfiguration fehlerhaft, bleibt die alte aktiv. Port ändern: `WEB_PORT=8091 ./deploy/deploy.sh 192.168.178.25` (wird gemerkt). Nach Änderungen an CSS oder JS vorher die `?v=...`-Nummer hochsetzen (siehe oben).

Das Rechnungsportal bleibt davon getrennt.

## Herkunft der Fotos

Alle Fotos stammen aus dem Google-Drive-Ordner `Fasching` (Auswahl in `Fasching/Website-Auswahl`).

| Datei | Original |
|---|---|
| gruender-* | Fasching/Gründerbilder (Oli, Richard, Robert, Toni), auf 4:5 zugeschnitten |
| hero | Faschingsumzüge 2026/IMG_20260215_173848904.jpg |
| wagen-seite | Faschingsumzüge 2026/IMG_20260214_105958340.jpg |
| wagen-heck | Faschingsumzüge 2026/IMG_8608.HEIC |
| wagen-sonne | Faschingsumzüge 2026/IMG_8597.HEIC |
| wagen-front | Faschingsumzüge 2026/IMG_8594.HEIC |
| wagen-abend | Faschingsumzüge 2026/IMG_8533.HEIC |
| wagen-nacht | Faschingsumzüge 2026/IMG_8545.HEIC |
| wagen-umzug | Faschingsumzüge 2026/IMG_8449.HEIC |
| umzug-gruppe | Faschingsumzüge 2026/IMG_8515.HEIC |
| gruppe-wagen | Faschingsumzüge 2026/IMG_0314.HEIC (Ausschnitt) |
| umzug-strasse | Faschingsumzüge 2026/591-DSC_7633.jpg (Ausschnitt 4:3) |
| fahne-wagen | Faschingsumzüge 2026/IMG_8490.HEIC |
| fahne | Faschingsumzüge 2026/IMG_8651.HEIC (Ausschnitt) |
| pokal | Faschingsumzüge 2026/IMG_8564.HEIC (Ausschnitt) |
| pegau-teppich | Faschingsumzüge 2026/IMG_8551.HEIC |
| at-buehne | Altstadt Tanz 2025/dji_mimo_20250906_144734_0_1757439512016_photo.jpg |
| at-bar | Altstadt Tanz 2025/dji_mimo_20250906_144718_0_1757439522322_photo.jpg |
| at-abend | Altstadt Tanz 2024/IMG_0274.HEIC |
| at-pult | Altstadt Tanz 2024/IMG_5440.JPG |
| at-nacht | Altstadt Tanz 2024/IMG_0299.HEIC |
| at-team | Altstadt Tanz 2025/IMG_5789.HEIC |
| aufbau-krug | Altstadt Tanz 2025/IMG_5759.HEIC |
| aufbau-heuballen | Altstadt Tanz 2025/IMG_5879.HEIC |
| aufbau-deko | Altstadt Tanz 2025/IMG_5756.HEIC |
| aufbau-stapler | Altstadt Tanz 2025/IMG_5892.HEIC |
| at26-* | Altstadt Tanz 2026/DSC_3757 bis DSC_4521 (Fotograf, Bühne bei Nacht u. a.) |
| at25-drohne, at25-drohne2 | Altstadt Tanz 2025/118-DJI_0415.jpg, 119-DJI_0423.jpg |
| at25-menge, at25-blasen, at25-pult, at25-dj, at25-buehne-nacht | Altstadt Tanz 2025/160-DSC_0632, 166-DSC_0653, 150-DSC_0612, 222-DSC_0805, 79-DSC_0478 |
| at24-* | Altstadt Tanz 2024/Pegau Altstadt Tanz 2024.zip (DSC_0623 bis DSC_1016) |
