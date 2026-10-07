/* Gut und Aussehend – kleine Helfer für Menü, Termine, Sponsoren, Motto-Umschalter und Großansicht. */
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

  /* ---- Mottos im Wagen-Abschnitt umschalten ---- */
  var mottoSection = doc.querySelector(".section--motto");
  var switcher = doc.getElementById("motto-switch");
  if (mottoSection && switcher) {
    var panels = Array.prototype.slice.call(mottoSection.querySelectorAll(".motto"));
    if (panels.length > 1) {
      var tabs = [];
      var tablist = el("div", "motto-switch__tabs");
      tablist.setAttribute("role", "tablist");
      tablist.setAttribute("aria-labelledby", "motto-switch-label");
      var selectMotto = function (index, focus) {
        panels.forEach(function (panel, i) {
          var active = i === index;
          panel.hidden = !active;
          tabs[i].setAttribute("aria-selected", String(active));
          tabs[i].tabIndex = active ? 0 : -1;
        });
        mottoSection.setAttribute("data-motto", panels[index].getAttribute("data-motto") || "");
        if (focus) tabs[index].focus();
      };
      panels.forEach(function (panel, i) {
        var tab = el("button");
        tab.type = "button";
        tab.id = "tab-" + panel.id;
        tab.setAttribute("role", "tab");
        tab.setAttribute("aria-controls", panel.id);
        tab.appendChild(el("span", "", panel.getAttribute("data-year")));
        tab.appendChild(doc.createTextNode(panel.getAttribute("data-title")));
        tab.addEventListener("click", function () { selectMotto(i, false); });
        tab.addEventListener("keydown", function (event) {
          if (event.key === "ArrowRight") selectMotto((i + 1) % panels.length, true);
          if (event.key === "ArrowLeft") selectMotto((i - 1 + panels.length) % panels.length, true);
        });
        panel.setAttribute("role", "tabpanel");
        panel.setAttribute("aria-labelledby", tab.id);
        tabs.push(tab);
        tablist.appendChild(tab);
      });
      switcher.appendChild(tablist);
      switcher.hidden = false;
      /* Ein Link wie #wagen-2024 öffnet direkt das passende Motto. */
      var wanted = panels.map(function (p) { return "#" + p.id; }).indexOf(window.location.hash);
      selectMotto(wanted > -1 ? wanted : 0, false);
    }
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

  /* ---- Matrix-Band im Wagen-Abschnitt: der Code besteht wie am Wagen aus G, & und A ---- */
  var code = doc.querySelector(".code");
  if (code) {
    var glyphs = "G&A23G&A0G&A@";
    var columns = Math.min(46, Math.max(14, Math.round(window.innerWidth / 30)));
    for (var c = 0; c < columns; c++) {
      var line = "";
      for (var g = 0; g < 44; g++) line += glyphs.charAt(Math.floor(Math.random() * glyphs.length));
      var span = el("span", "", line);
      span.style.animationDuration = (11 + Math.random() * 12).toFixed(1) + "s";
      span.style.animationDelay = (-Math.random() * 12).toFixed(1) + "s";
      span.style.opacity = (0.45 + Math.random() * 0.55).toFixed(2);
      code.appendChild(span);
    }
  }

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
