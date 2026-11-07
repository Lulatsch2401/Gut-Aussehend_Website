# Offene Punkte – Website Gut und Aussehend

Stand: 7. November 2026. Die Seite läuft als passwortgeschützte Vorzeigeversion auf dem Pi.
Pink markierte Stellen auf der Seite lassen sich unten links über „Platzhalter anzeigen“ einblenden.

## Bewusst zurückgestellt

| Punkt | Stand | Was zu tun ist, wenn es weitergeht |
|---|---|---|
| Pokal 2025 | Auf den Fotos 2025 ist ein Pokal zu sehen, Platzierung unbekannt | Platz, Kategorie und Umzug (Pegau oder Groitzsch) klären, dann wie bei 2026 als Auszeichnung im Wagen-Abschnitt 2025 ergänzen |
| Rollen der Gründer | Unter Oli, Richard, Robert und Toni steht „Gründer“ | Bleibt so, bis jemand Rollen nennen möchte |
| Ansprechpartner im Kontakt | „Ansprechpartner: Name folgt“ | Name und ggf. Rolle in `index.html` im Abschnitt Kontakt eintragen |
| Spendenquittungen | Hinweis von der Seite entfernt | Erst wieder aufnehmen, wenn die Rechtsform (e. V., gemeinnützig?) geklärt ist |

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

## Vor dem öffentlichen Start

- [ ] Impressum ausformulieren (verantwortliche Person, Anschrift, ggf. Vereinsregister)
- [ ] Datenschutzerklärung ausformulieren und den Abschnitt zum Kontaktformular prüfen lassen
- [ ] Rechtsform klären
- [ ] Einverständnis der Gründer und aller gut erkennbaren Personen auf den Fotos
- [ ] Mitgliederzahl bestätigen (aktuell 38)
- [ ] IONOS-Postfach `sponsoring@gut-aussehend.de` anlegen und mit `./deploy/deploy.sh 192.168.178.25 --kontakt-einrichten` hinterlegen
- [ ] Logo als Vektordatei besorgen
- [ ] Entwurfsleiste und `noindex` entfernen, Passwortschutz abschalten (`--ohne-passwort`)
- [ ] Rechnungsportal (auslagen.gut-aussehend.de) absichern, Portal-Repo auf privat stellen

## Später

- Texte durch Mitglieder pflegbar machen (Redaktionssystem, ca. 1½–2 Tage)
- Bei Cloudflare `autodiscover`, `_dmarc`, `_domainconnect` auf „DNS only“ stellen
- Nicht verwendete Bilder `at26-laser2-*`, `at26-nebel2-*` löschen oder einbauen
