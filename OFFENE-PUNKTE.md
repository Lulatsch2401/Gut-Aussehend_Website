# Offene Punkte – Website Gut und Aussehend

Stand: 10. November 2026. Die Seite ist eine reine Vorstellungsseite der Gruppe: kein Sponsoring, keine Werbung, kein Impressum.

## Entscheidung vom 10. November 2026: ohne Impressum online

- Alles zu Sponsoren ist entfernt (Abschnitte „Unsere Sponsoren“ und „Sponsor werden“, Menüpunkt, Knopf im Aufmacher, Anliegen „Sponsoring“ im Formular, Sponsorenwand im Skript).
- `impressum.html` ist von der Seite genommen und liegt als Vorlage unter `deploy/impressum-vorlage.html` (wird nicht hochgeladen).
- Datenschutz nennt als Verantwortlichen „Gut und Aussehend“ mit der Gmail-Adresse.
- Bewusst in Kauf genommen: § 18 Abs. 1 MStV verlangt auch für nicht-geschäftliche, öffentliche Seiten Name und Anschrift. Das Risiko (Abmahnung, Bußgeld) bleibt klein, aber nicht null.
- Sobald wieder Sponsoren auf die Seite sollen oder eine Adresse geklärt ist (c/o-Adresse oder Impressum-Service): Vorlage zurück nach `impressum.html`, ausfüllen, im Fuß von `index.html` und `datenschutz.html` verlinken, in `sitemap.xml` eintragen. Die alten Sponsoren-Abschnitte stehen in der Git-Historie (Commit d057c76).

## Bewusst zurückgestellt

| Punkt | Stand | Was zu tun ist, wenn es weitergeht |
|---|---|---|
| Pokal 2025 | Auf den Fotos 2025 ist ein Pokal zu sehen, Platzierung unbekannt | Platz, Kategorie und Umzug (Pegau oder Groitzsch) klären, dann wie bei 2026 als Auszeichnung im Wagen-Abschnitt 2025 ergänzen |
| Rollen der Gründer | Unter Oli, Richard, Robert und Toni steht „Gründer“ | Bleibt so, bis jemand Rollen nennen möchte |
| Ansprechpartner im Kontakt | Zeile vorerst entfernt | Bei Bedarf Name und Rolle im Abschnitt Kontakt ergänzen |
| Sponsoring | Vorerst ganz von der Seite genommen | Siehe Entscheidung oben. Spendenquittungen gibt es ohnehin nicht, da kein e. V. |

## Termine 2027 (recherchiert am 7. November 2026)

| Termin | Quelle | Offen |
|---|---|---|
| Sa, 6. Februar 2027: Großer Karnevalsumzug Pegau | Kalender des Pegauer Karneval-Klubs: „Bunter Fasching“ am 6. Februar, der laut Stadt Pegau direkt nach dem Umzug stattfindet | Datum ist abgeleitet, nicht ausdrücklich angekündigt. Uhrzeit fehlt (2023 war es gegen 14:30 Uhr) |
| So, 7. Februar 2027: Karnevalsumzug Groitzsch | GCC Groitzsch und Stadt Groitzsch: ab 12 Uhr Markttreiben, 14:30 Uhr Umzug ab Markt | – |
| September 2027: Altstadttanz | Pegauer Altstadtfest war 2025 am 6. September und 2026 am 4./5. September | Termin 2027 noch nicht veröffentlicht, bei stadt-pegau.de nachsehen |
| 11.11.2026: Sessionsauftakt | stand schon im Entwurf | Prüfen, ob und wo ihr als Verein auftretet (PKK Pegau 11:10 Uhr, GCC Groitzsch 17:11 Uhr, jeweils Marktplatz) |

Termine stehen in `assets/data/inhalte.js` unter `termine`.

Quellen:
- https://gcc-groitzsch.de/oeffentlich.html
- https://groitzsch.de/component/jem/event/57:karnevalsumzug-mit-umzugsveranstaltung
- https://karneval-in-pegau.de/klub/pegauer-karneval-klub-e-v/sider/veranstaltungen
- https://www.stadt-pegau.de/veranstaltungen/grosser-karnevalsumzug/
- https://www.festivalsindeutschland.de/festival/pegauer-altstadtfest

## Online gehen

- [x] Sponsoring und Impressum entfernt, Seite ist reine Vorstellung der Gruppe (siehe oben)
- [x] Datenschutzerklärung ausformuliert, Verantwortlicher ohne Impressum (Server-Logs, Cloudflare, Kontaktformular, Gmail, localStorage, Instagram-Link, Fotos, Rechte, Aufsicht Sachsen). Vor dem Start einmal gegenlesen lassen, keine Rechtsberatung
- [ ] Passwortschutz abschalten: `./deploy/deploy.sh 192.168.178.25 --ohne-passwort`
- [ ] Google Search Console: Domain-Property `gut-aussehend.de` anlegen, Bestätigung per DNS-TXT in Cloudflare, Sitemap `https://gut-aussehend.de/sitemap.xml` einreichen
- [ ] Cloudflare DNS: `_dmarc`, `autodiscover`, `_domainconnect` auf „DNS only“ (graue Wolke), sonst leidet die E-Mail-Zustellung
- [ ] Cloudflare SSL/TLS → Edge Certificates: „Minimum TLS Version“ 1.2, „Automatic HTTPS Rewrites“ an. HSTS erst nach ein paar Wochen stabilem Betrieb einschalten
- [ ] Für `gut.aussehend.fasching@gmail.com` ein Gmail-App-Passwort anlegen und mit `./deploy/deploy.sh 192.168.178.25 --kontakt-einrichten` hinterlegen
- [x] Rechtsform geklärt: kein eingetragener Verein, keine Spendenquittungen
- [ ] Einverständnis der Gründer und aller gut erkennbaren Personen auf den Fotos
- [ ] Mitgliederzahl bestätigen (aktuell 38)
- [ ] Logo als Vektordatei besorgen
- [ ] Rechnungsportal (auslagen.gut-aussehend.de) absichern, Portal-Repo auf privat stellen

## Später

- Texte durch Mitglieder pflegbar machen (Redaktionssystem, ca. 1½–2 Tage)
- Bei Cloudflare `autodiscover`, `_dmarc`, `_domainconnect` auf „DNS only“ stellen
- Nicht verwendete Bilder `at26-laser2-*`, `at26-nebel2-*` löschen oder einbauen
