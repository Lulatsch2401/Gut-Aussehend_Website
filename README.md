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

Der Instagram-Kanal @gut_und_aussehend ist verlinkt im Kopf, im Aufmacher, in den Kennzahlen, in einem eigenen Abschnitt, bei den Sponsorenpaketen, im Kontakt und im Fuß. Die Followerzahl steht nur einmal in `assets/data/inhalte.js` (`instagram.follower`) und wird überall eingesetzt. Die Seite bettet nichts von Instagram ein, es sind reine Links (keine Cookies, kein Datenschutz-Hinweis nötig). Die Kacheln im Abschnitt sind eigene Fotos von der Seite und führen zum Profil.

## Termin eintragen

In `assets/data/inhalte.js` unter `termine`. `offen: true` zeigt den Hinweis "Termin folgt".

## Vor dem Livegang

Alle offenen Stellen sind auf der Seite pink markiert (Schalter "Platzhalter" unten links).

- [ ] Mitgliederzahl bestätigen (aktuell 38, aus dem Rechnungsportal)
- [ ] Texte gegenlesen, vor allem den Abschnitt Altstadttanz
- [ ] Ansprechpartner im Kontakt eintragen
- [ ] Gründer: Einverständnis von Oli, Richard, Robert und Toni einholen, Rollen und Text prüfen
- [ ] Termine der Session 2026/27 eintragen
- [ ] Texte zu den Mottos 2024 (Up) und 2025 (Work in Progress) prüfen
- [ ] Zuschauerzahlen ergänzen
- [ ] Instagram-Followerzahl ab und zu in `assets/data/inhalte.js` nachtragen (aktuell 800)
- [ ] Postfach `sponsoring@gut-aussehend.de` anlegen oder Adresse ändern
- [ ] Rechtsform klären: Impressum, Spendenquittungen
- [ ] Impressum und Datenschutzerklärung ausformulieren
- [ ] Einverständnis aller erkennbaren Personen auf den Fotos einholen
- [ ] Logo als Vektordatei besorgen (aktuell nur 420 px, daraus sind Kopf-Logo und Favicon geschnitten)
- [ ] Entwurfsmodus entfernen: in `index.html` den Block zwischen `<!-- ENTWURF -->` löschen, die Klasse `show-ph` streichen und die Zeile `<meta name="robots" content="noindex">` in allen drei Seiten entfernen
- [ ] Cloudflare Access wieder entfernen, sobald die Seite öffentlich sein soll
- [ ] Rechnungsportal absichern, bevor Namen von Mitgliedern öffentlich auf der Seite stehen

## Hosting auf dem Raspberry Pi

Die Seite läuft auf dem Pi in Docker: `nginx` liefert die Dateien aus, `cloudflared` macht sie über einen Cloudflare Tunnel unter gut-aussehend.de erreichbar. Am Router muss kein Port geöffnet werden. Alles dafür liegt in `deploy/`.

### Einmalig: Cloudflare Tunnel anlegen

1. Domain gut-aussehend.de bei Cloudflare hinzufügen (kostenloser Plan) und beim Domain-Anbieter die Nameserver auf die von Cloudflare umstellen.
2. Im Cloudflare-Dashboard: Zero Trust → Networks → Tunnels → Create a tunnel → Cloudflared → Name `gut-aussehend` → Umgebung Docker. Aus dem angezeigten Befehl nur den langen Token kopieren.
3. Im selben Tunnel unter „Public Hostname“ zwei Einträge anlegen: `gut-aussehend.de` und `www.gut-aussehend.de`, jeweils Typ HTTP, URL `web:80`.
4. Auf dem Pi die Datei `~/gut-aussehend/.env` anlegen (kommt nie ins Repo):

   ```bash
   ssh 192.168.178.40 "mkdir -p gut-aussehend && echo 'TUNNEL_TOKEN=HIER_DEN_TOKEN' > gut-aussehend/.env && chmod 600 gut-aussehend/.env"
   ```

5. Solange die Seite noch Entwurf ist: Zero Trust → Access → Applications → Self-hosted → gut-aussehend.de, Policy „Allow“ mit den E-Mail-Adressen der Mitglieder. Dann sehen nur die freigegebenen Leute die Seite (Anmeldung per Code an die E-Mail).

### Bei jeder Änderung

Auf dem Mac im Repo-Ordner:

```bash
./deploy/deploy.sh 192.168.178.40
```

Das Skript überträgt die Dateien per `rsync` nach `~/gut-aussehend/site` auf dem Pi und startet die Container neu. Ohne Token in `.env` läuft nur der Webserver, erreichbar im Heimnetz unter http://192.168.178.40:8080. Nach Änderungen an CSS oder JS vorher die `?v=...`-Nummer hochsetzen (siehe oben).

Das Rechnungsportal bleibt davon getrennt. Es kann später als eigener Public Hostname (z. B. `kasse.gut-aussehend.de`) in denselben Tunnel, aber erst, wenn der Login abgesichert ist.

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
| umzug-publikum | Faschingsumzüge 2026/IMG_8480.HEIC |
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
