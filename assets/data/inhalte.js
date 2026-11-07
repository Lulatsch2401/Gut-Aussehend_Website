/* Inhalte, die sich regelmäßig ändern. Nur diese Datei anfassen, die Seite baut sich daraus.

   SPONSOREN
   Ein Eintrag pro Sponsor. Logo-Datei nach assets/img/sponsoren/ legen (SVG oder PNG mit
   transparentem Hintergrund). Ohne Logo wird der Name als Text gezeigt.
   paket: "wagen" | "kostuem" | "wurfmaterial"  (bestimmt die Reihenfolge)

     { name: "Musterfirma GmbH", logo: "assets/img/sponsoren/musterfirma.svg",
       url: "https://www.example.de", paket: "wagen" },

   INSTAGRAM
   follower: gerundete Zahl für den Satz „Über … Follower“ im Instagram-Abschnitt. Nur selten nachtragen.
   Ab und zu nachtragen, eine gerundete Zahl reicht.

   TERMINE
   offen: true zeigt den Hinweis "Termin folgt".
*/
window.GA_INHALTE = {
  instagram: { handle: "gut_und_aussehend", url: "https://www.instagram.com/gut_und_aussehend/", follower: 800 },

  sponsoren: [],

  termine: [
    { wann: "11.11.2026", was: "Sessionsauftakt", wo: "", offen: false },
    // Pegau: Datum aus dem PKK-Kalender (Bunter Fasching am 6. Februar folgt direkt auf den Umzug), Uhrzeit noch nicht veröffentlicht
    { wann: "Sa, 6. Februar 2027", was: "Großer Karnevalsumzug Pegau", wo: "Innenstadt Pegau, Uhrzeit folgt", offen: false },
    // Groitzsch: laut GCC und Stadt Groitzsch, Umzug ab 14:30 Uhr, Markttreiben ab 12 Uhr
    { wann: "So, 7. Februar 2027", was: "Karnevalsumzug Groitzsch", wo: "Start am Markt, 14:30 Uhr", offen: false },
    // Altstadttanz beim Pegauer Altstadtfest, bisher jeweils am ersten Septemberwochenende
    { wann: "September 2027", was: "Altstadttanz Pegau", wo: "voraussichtlich Anfang September", offen: true }
  ]
};
