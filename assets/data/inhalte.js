/* Inhalte, die sich regelmäßig ändern. Nur diese Datei anfassen, die Seite baut sich daraus.

   SPONSOREN
   Ein Eintrag pro Sponsor. Logo-Datei nach assets/img/sponsoren/ legen (SVG oder PNG mit
   transparentem Hintergrund). Ohne Logo wird der Name als Text gezeigt.
   paket: "wagen" | "kostuem" | "wurfmaterial"  (bestimmt die Reihenfolge)

     { name: "Musterfirma GmbH", logo: "assets/img/sponsoren/musterfirma.svg",
       url: "https://www.example.de", paket: "wagen" },

   TERMINE
   offen: true zeigt den Hinweis "Termin folgt".
*/
window.GA_INHALTE = {
  sponsoren: [],

  termine: [
    { wann: "11.11.2026", was: "Sessionsauftakt", wo: "", offen: false },
    { wann: "Februar 2027", was: "Karnevalsumzug Pegau", wo: "", offen: true },
    { wann: "Februar 2027", was: "Faschingsumzug Groitzsch", wo: "", offen: true },
    { wann: "September 2027", was: "Altstadttanz", wo: "", offen: true }
  ]
};
