/* Gut und Aussehend – kleine Helfer für Menü, Termine, Sponsoren, Session-Auswahl und Großansicht. */
(function () {
  "use strict";
  var doc = document;
  doc.documentElement.classList.add("js");
  var data = window.GA_INHALTE || { sponsoren: [], termine: [] };

  function el(tag, cls, text) {
    var node = doc.createElement(tag);
    if (cls) node.className = cls;
    if (text) node.textContent = text;
    return node;
  }

  /* ---- Menü auf dem Handy ---- */
  var toggle = doc.querySelector(".nav-toggle");
  var nav = doc.getElementById("hauptnav");
  if (toggle && nav) {
    toggle.addEventListener("click", function () {
      var open = nav.classList.toggle("is-open");
      toggle.setAttribute("aria-expanded", String(open));
    });
    nav.addEventListener("click", function (event) {
      if (event.target.closest("a")) {
        nav.classList.remove("is-open");
        toggle.setAttribute("aria-expanded", "false");
      }
    });
  }

  /* ---- Instagram: Followerzahl aus inhalte.js ---- */
  if (data.instagram && data.instagram.follower) {
    var follower = Number(data.instagram.follower).toLocaleString("de-DE");
    Array.prototype.slice.call(doc.querySelectorAll("[data-ig-follower]")).forEach(function (node) { node.textContent = follower; });
  }

  /* ---- Termine ---- */
  var dates = doc.getElementById("termine-liste");
  if (dates && data.termine && data.termine.length) {
    dates.textContent = "";
    data.termine.forEach(function (t) {
      var li = el("li");
      li.appendChild(el("span", "dates__when", t.wann));
      var what = el("div", "dates__what");
      what.appendChild(el("strong", "", t.was));
      if (t.wo) what.appendChild(el("span", "", t.wo));
      li.appendChild(what);
      if (t.offen) li.appendChild(el("span", "chip", "Termin folgt"));
      dates.appendChild(li);
    });
  }

  /* ---- Sponsoren ---- */
  var wall = doc.getElementById("sponsoren-wand");
  var empty = doc.getElementById("sponsoren-leer");
  var order = { wagen: 0, kostuem: 1, wurfmaterial: 2 };
  if (wall && data.sponsoren && data.sponsoren.length) {
    wall.textContent = "";
    data.sponsoren.slice().sort(function (a, b) {
      return (order[a.paket] || 0) - (order[b.paket] || 0);
    }).forEach(function (s) {
      var tile = el(s.url ? "a" : "div", "sponsors__tile");
      if (s.url) { tile.href = s.url; tile.rel = "noopener"; tile.target = "_blank"; }
      if (s.logo) {
        var img = el("img");
        img.src = s.logo; img.alt = s.name; img.loading = "lazy";
        tile.appendChild(img);
      } else {
        tile.textContent = s.name;
      }
      wall.appendChild(tile);
    });
    if (empty) empty.hidden = true;
  }

  /* ---- Session-Auswahl: das Motto färbt die ganze Seite ----
     data-motto am <html>-Element steuert Farben, Schrift und Deko (site.css, Abschnitt "Mottos").
     Elemente mit data-for="..." erscheinen nur beim passenden Motto, z. B. das Bild im Aufmacher
     und die Altstadttanz-Fotos desselben Jahres. */
  var root = doc.documentElement;
  var bar = doc.getElementById("motto-bar");
  var mottoButtons = bar ? Array.prototype.slice.call(bar.querySelectorAll("button[data-motto]")) : [];
  var mottoKeys = mottoButtons.map(function (b) { return b.getAttribute("data-motto"); });
  var panels = Array.prototype.slice.call(doc.querySelectorAll(".motto"));
  var themed = Array.prototype.slice.call(doc.querySelectorAll("[data-for]"));
  var wagen = doc.querySelector(".section--motto");
  var themeMeta = doc.querySelector('meta[name="theme-color"]');
  var themeColors = { matrix: "#030a06", wip: "#151513", up: "#0e2b4f" };

  var applyMotto = function (key, remember) {
    if (mottoKeys.indexOf(key) < 0) key = mottoKeys[0];
    if (!key) return;
    root.setAttribute("data-motto", key);
    if (wagen) wagen.setAttribute("data-motto", key);
    mottoButtons.forEach(function (b) { b.setAttribute("aria-pressed", String(b.getAttribute("data-motto") === key)); });
    themed.forEach(function (node) { node.hidden = node.getAttribute("data-for").split(" ").indexOf(key) < 0; });
    panels.forEach(function (panel) { panel.hidden = panel.getAttribute("data-motto") !== key; });
    if (themeMeta && themeColors[key]) themeMeta.setAttribute("content", themeColors[key]);
    if (remember) { try { localStorage.setItem("ga-motto", key); } catch (err) {} }
  };

  if (mottoButtons.length) {
    mottoButtons.forEach(function (b) {
      b.addEventListener("click", function () { applyMotto(b.getAttribute("data-motto"), true); });
    });
    /* Start: Link wie #wagen-2024 oder #2024, sonst die zuletzt gewählte Session, sonst die neueste. */
    var start = root.getAttribute("data-motto");
    var hash = window.location.hash.replace("#", "");
    panels.forEach(function (panel) {
      if (hash && (panel.id === hash || panel.getAttribute("data-year") === hash)) start = panel.getAttribute("data-motto");
    });
    /* Auch #altstadttanz-2024 wählt die passende Session (Altstadttanz-Jahr = Session-Jahr). */
    themed.forEach(function (node) {
      if (hash && node.id === hash) start = node.getAttribute("data-for").split(" ")[0];
    });
    applyMotto(start, false);
  }

  /* ---- Großansicht der Fotos ---- */
  var shots = Array.prototype.slice.call(doc.querySelectorAll("a.shot"));
  var box = doc.getElementById("lightbox");
  if (box && typeof box.showModal === "function" && shots.length) {
    var boxImg = box.querySelector("img");
    var boxCap = box.querySelector("figcaption");
    var visible = shots;
    var current = 0;
    var show = function (index) {
      current = (index + visible.length) % visible.length;
      var shot = visible[current];
      var thumb = shot.querySelector("img");
      boxImg.src = shot.getAttribute("href");
      boxImg.alt = thumb ? thumb.alt : "";
      boxCap.textContent = shot.getAttribute("data-caption") || (thumb ? thumb.alt : "");
    };
    shots.forEach(function (shot) {
      shot.addEventListener("click", function (event) {
        event.preventDefault();
        /* Nur Fotos aus sichtbaren Bereichen durchblättern, nicht aus ausgeblendeten Mottos. */
        visible = shots.filter(function (s) { return !s.closest("[hidden]"); });
        show(visible.indexOf(shot));
        if (!box.open) box.showModal();
      });
    });
    box.querySelector("[data-prev]").addEventListener("click", function () { show(current - 1); });
    box.querySelector("[data-next]").addEventListener("click", function () { show(current + 1); });
    box.querySelector("[data-close]").addEventListener("click", function () { box.close(); });
    box.addEventListener("click", function (event) { if (event.target === box) box.close(); });
    box.addEventListener("keydown", function (event) {
      if (event.key === "ArrowLeft") show(current - 1);
      if (event.key === "ArrowRight") show(current + 1);
    });
  }

  /* ---- E-Mail-Adresse kopieren ---- */
  var copy = doc.getElementById("mail-kopieren");
  var mail = doc.getElementById("mail-adresse");
  if (copy && mail) {
    copy.addEventListener("click", function () {
      var text = mail.textContent.trim();
      var done = function () {
        copy.textContent = "Kopiert";
        setTimeout(function () { copy.textContent = "Adresse kopieren"; }, 2000);
      };
      var select = function () {
        var range = doc.createRange();
        range.selectNodeContents(mail);
        var sel = window.getSelection();
        sel.removeAllRanges();
        sel.addRange(range);
        copy.textContent = "Markiert, jetzt kopieren";
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, select);
      } else {
        select();
      }
    });
  }

  /* ---- Matrix-Code: besteht wie am Wagen aus G, & und A ---- */
  Array.prototype.slice.call(doc.querySelectorAll(".code")).forEach(function (code) {
    var glyphs = "G&A23G&A0G&A@";
    var width = code.parentNode.getBoundingClientRect().width || window.innerWidth;
    var columns = Math.min(40, Math.max(10, Math.round(width / 30)));
    for (var c = 0; c < columns; c++) {
      var line = "";
      for (var g = 0; g < 44; g++) line += glyphs.charAt(Math.floor(Math.random() * glyphs.length));
      var span = el("span", "", line);
      span.style.animationDuration = (11 + Math.random() * 12).toFixed(1) + "s";
      span.style.animationDelay = (-Math.random() * 12).toFixed(1) + "s";
      span.style.opacity = (0.45 + Math.random() * 0.55).toFixed(2);
      code.appendChild(span);
    }
  });

  /* ---- Ballons für das Motto Up ---- */
  Array.prototype.slice.call(doc.querySelectorAll(".balloons")).forEach(function (balloons) {
    var colors = ["#ff5d73", "#ffd21f", "#4fc3f7", "#7ed957", "#c77dff", "#ff9f43"];
    var count = balloons.parentNode.classList.contains("hero__deco") ? 12 : 14;
    for (var b = 0; b < count; b++) {
      var ball = el("span");
      var size = 1.3 + Math.random() * 1.3;
      ball.style.left = (3 + Math.random() * 94).toFixed(1) + "%";
      ball.style.width = size.toFixed(2) + "rem";
      ball.style.height = (size * 1.22).toFixed(2) + "rem";
      ball.style.background = colors[b % colors.length];
      ball.style.animationDuration = (14 + Math.random() * 12).toFixed(1) + "s";
      ball.style.animationDelay = (-Math.random() * 20).toFixed(1) + "s";
      balloons.appendChild(ball);
    }
  });

  /* ---- Entwurfsmodus: Platzhalter ein- und ausblenden ---- */
  var page = doc.querySelector(".page");
  var phToggle = doc.getElementById("ph-toggle");
  if (page && phToggle) {
    phToggle.addEventListener("click", function () {
      var on = page.classList.toggle("show-ph");
      phToggle.setAttribute("aria-pressed", String(on));
      phToggle.textContent = on ? "Platzhalter ausblenden" : "Platzhalter anzeigen";
    });
  }
})();
