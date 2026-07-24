/* ============================================================
   Shared site behavior: theme toggle, mobile nav, project card
   rendering. Include this after projects-data.js on any page
   that renders project cards.
   ============================================================ */

(function () {
  "use strict";

  /* ---------- Theme toggle ---------- */
  function initTheme() {
    const stored = window.localStorage ? localStorage.getItem("theme") : null;
    const prefersDark = window.matchMedia && window.matchMedia("(prefers-color-scheme: dark)").matches;
    const theme = stored || (prefersDark ? "dark" : "light");
    document.documentElement.setAttribute("data-theme", theme);

    document.querySelectorAll("[data-theme-toggle]").forEach((btn) => {
      btn.addEventListener("click", () => {
        const current = document.documentElement.getAttribute("data-theme");
        const next = current === "dark" ? "light" : "dark";
        document.documentElement.setAttribute("data-theme", next);
        try { localStorage.setItem("theme", next); } catch (e) { /* ignore */ }
      });
    });
  }

  /* ---------- Mobile nav ---------- */
  function initNav() {
    const toggle = document.querySelector("[data-nav-toggle]");
    const links = document.querySelector("[data-nav-links]");
    if (toggle && links) {
      toggle.addEventListener("click", () => links.classList.toggle("open"));
    }
  }

  /* ---------- Project card rendering ---------- */
  function domainTag(project) {
    const span = document.createElement("span");
    span.className = "tag domain-" + project.domain;
    const dot = document.createElement("span");
    dot.className = "tag-dot";
    span.appendChild(dot);
    span.appendChild(document.createTextNode(project.domainLabel));
    return span;
  }

  function buildCard(project, opts) {
    opts = opts || {};
    const pathPrefix = opts.pathPrefix || ""; // "" at root, "" inside projects/ needs "../"
    const isSoon = project.status === "soon";

    const card = document.createElement("article");
    card.className = "card" + (isSoon ? " is-soon" : "");
    card.dataset.domain = project.domain;

    const thumbWrap = document.createElement("div");
    thumbWrap.className = "card-thumb";
    const img = document.createElement("img");
    img.src = pathPrefix + project.thumbFromRoot;
    img.alt = project.title + " dashboard preview";
    img.loading = "lazy";
    img.onerror = function () {
      thumbWrap.innerHTML = "";
      const ph = document.createElement("div");
      ph.className = "placeholder";
      ph.textContent = isSoon ? "Preview coming soon" : project.title;
      thumbWrap.appendChild(ph);
    };
    thumbWrap.appendChild(img);
    card.appendChild(thumbWrap);

    const body = document.createElement("div");
    body.className = "card-body";

    const tagsRow = document.createElement("div");
    tagsRow.className = "card-tags";
    tagsRow.appendChild(domainTag(project));
    if (isSoon) {
      const soon = document.createElement("span");
      soon.className = "tag status-soon";
      soon.textContent = "Case study coming soon";
      tagsRow.appendChild(soon);
    }
    body.appendChild(tagsRow);

    const h3 = document.createElement("h3");
    h3.textContent = project.title;
    body.appendChild(h3);

    const p = document.createElement("p");
    p.textContent = project.summary;
    body.appendChild(p);

    const tools = document.createElement("div");
    tools.className = "card-tools";
    project.tools.forEach((t) => {
      const chip = document.createElement("span");
      chip.className = "tool-chip";
      chip.textContent = t;
      tools.appendChild(chip);
    });
    body.appendChild(tools);

    const link = document.createElement("a");
    link.className = "card-link";
    if (isSoon) {
      link.href = pathPrefix + project.caseStudy;
      link.textContent = "Preview →";
    } else {
      link.href = pathPrefix + project.caseStudy;
      link.textContent = "View case study →";
    }
    body.appendChild(link);

    card.appendChild(body);
    return card;
  }

  function renderProjectGrid(containerId, opts) {
    const container = document.getElementById(containerId);
    if (!container || typeof PROJECTS === "undefined") return;
    opts = opts || {};
    let list = PROJECTS.slice();
    if (opts.limit) list = list.slice(0, opts.limit);
    if (opts.domain && opts.domain !== "all") list = list.filter((p) => p.domain === opts.domain);
    container.innerHTML = "";
    list.forEach((p) => container.appendChild(buildCard(p, { pathPrefix: opts.pathPrefix })));
    if (list.length === 0) {
      const empty = document.createElement("p");
      empty.className = "muted";
      empty.textContent = "No projects in this category yet.";
      container.appendChild(empty);
    }
  }

  function initFilterBar(containerId, gridId, pathPrefix) {
    const bar = document.getElementById(containerId);
    if (!bar) return;
    bar.addEventListener("click", (e) => {
      const chip = e.target.closest("[data-filter]");
      if (!chip) return;
      bar.querySelectorAll(".filter-chip").forEach((c) => c.classList.remove("active"));
      chip.classList.add("active");
      renderProjectGrid(gridId, { domain: chip.dataset.filter, pathPrefix: pathPrefix });
    });
  }

  window.Portfolio = { renderProjectGrid, initFilterBar };

  document.addEventListener("DOMContentLoaded", function () {
    initTheme();
    initNav();
  });
})();
