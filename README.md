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
| `assets/fonts/` | Schriften lokal eingebunden, Lizenzen in `LIZENZEN.txt` |

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

## Motto ergänzen

Im Abschnitt "Wagen" lässt sich zwischen den Mottos umschalten. Jedes Motto ist in `index.html` ein Block `<div class="motto" ...>`. Die Knöpfe entstehen automatisch aus `data-year` und `data-title`.

1. Den Block eines Mottos kopieren, `id`, `data-year`, `data-title` und den Inhalt anpassen. Der oberste Block wird zuerst gezeigt.
2. Eigene Optik: `data-motto="name"` vergeben und in `assets/css/site.css` unter "Wagen: Mottos zum Umschalten" eine Akzentfarbe setzen. Vorhanden sind `matrix` (grüner Code) und `wip` (Baustellenband).
3. Ein Link auf `#wagen-2024` öffnet direkt das passende Motto.

## Termin eintragen

In `assets/data/inhalte.js` unter `termine`. `offen: true` zeigt den Hinweis "Termin folgt".

## Vor dem Livegang

Alle offenen Stellen sind auf der Seite pink markiert (Schalter "Platzhalter" unten links).

- [ ] Mitgliederzahl bestätigen (aktuell 38, aus dem Rechnungsportal)
- [ ] Texte gegenlesen, vor allem den Abschnitt Altstadttanz
- [ ] Vorstand und Ansprechpartner eintragen, Fotos nur mit Einverständnis
- [ ] Termine der Session 2026/27 eintragen
- [ ] Motto 2024 (Work in Progress): Fotos und Beschreibung ergänzen, Motto 2025 nachtragen
- [ ] Sponsorenpakete und Beträge durch den Vorstand festlegen
- [ ] Zuschauerzahlen und Social-Media-Kanäle ergänzen
- [ ] Postfach `sponsoring@gut-aussehend.de` anlegen oder Adresse ändern
- [ ] Rechtsform klären: Impressum, Spendenquittungen
- [ ] Impressum und Datenschutzerklärung ausformulieren
- [ ] Einverständnis aller erkennbaren Personen auf den Fotos einholen
- [ ] Logo als Vektordatei besorgen (aktuell nur 420 px, daraus sind Kopf-Logo und Favicon geschnitten)
- [ ] Entwurfsmodus entfernen: in `index.html` den Block zwischen `<!-- ENTWURF -->` löschen, die Klasse `show-ph` streichen und die Zeile `<meta name="robots" content="noindex">` in allen drei Seiten entfernen
- [ ] Rechnungsportal absichern, bevor Namen von Mitgliedern öffentlich auf der Seite stehen

## Hosting

Die Seite läuft auf jedem statischen Webspace. Empfehlung: Cloudflare Pages oder Netlify mit der Domain gut-aussehend.de, das Rechnungsportal getrennt unter einer Subdomain.

## Herkunft der Fotos

Alle Fotos stammen aus dem Google-Drive-Ordner `Fasching` (Auswahl in `Fasching/Website-Auswahl`).

| Datei | Original |
|---|---|
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
