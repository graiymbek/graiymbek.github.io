# Portfolio site

Static site (plain HTML/CSS/JS, no build step) for Gulzhan Raiymbek's data analytics portfolio.

## Structure

```
index.html            Home page
projects.html          Filterable grid of all dashboard projects
about.html              Bio, experience timeline, skills
resume.html              Résumé embed + contact section
certificates.html         Certifications grid
projects/
  supply-chain.html      Full case study (complete)
  finance.html            Placeholder — needs real content
  healthcare.html          Placeholder — needs real content
dashboards/
  supply-chain-dashboard.html   Self-contained interactive dashboard, embedded via iframe
css/style.css            Shared design system (same palette as the dashboards)
js/projects-data.js       *** Edit this file to add/update projects — every grid on the site reads from it ***
js/main.js                Card rendering, nav, theme toggle
assets/img/                Screenshots and thumbnails
assets/docs/                Put resume.pdf here
assets/sql/                 SQL reference queries per project
```

## To add a new project (e.g. HR or Insurance Claims)

1. Open `js/projects-data.js` and add a new object to the `PROJECTS` array (there's a
   commented example at the bottom of the file already sketched out for HR).
2. Add a thumbnail image to `assets/img/`.
3. Build the interactive dashboard as a single self-contained HTML file (inline all CSS/JS)
   and drop it in `dashboards/<slug>-dashboard.html`.
4. Copy `projects/supply-chain.html` to `projects/<slug>.html` and edit the content —
   problem statement, data model notes, key findings, and the iframe `src`.
5. Set `status: "live"` in the project object once the case study page exists. Until then,
   leave it as `"soon"` and the card will show a "Case study coming soon" badge automatically.

## Still needs your input (marked `TODO` in the code)

- Real headshot photo (`assets/img/headshot.jpg`)
- LinkedIn and GitHub URLs (currently `#` placeholders in every page's nav/footer/contact section)
- Supply Chain case study report-page screenshots (`projects/supply-chain.html` — the "From the
  Power BI report" section currently shows a placeholder until real screenshots are added)
- Finance and Healthcare case study write-ups (`projects/finance.html`, `projects/healthcare.html`)
  — the real .pbix files are already wired up for download on both pages; still need the full
  write-up (data model, DAX measures, findings, SQL) the same way as the Supply Chain one.
- Per-project GitHub repo links (each case study page has a "View on GitHub" button pointing at `#`)

## Already done

- Résumé PDF (`assets/docs/resume.pdf`) — embedded and downloadable on `resume.html`
- Real certificates on `certificates.html` (PL-300, plus DP-600 in progress)
- Real dates and details in the `about.html` experience timeline and bio
- Real `.pbix` downloads on the Supply Chain, Finance, and Healthcare project pages

## Deploying to GitHub Pages

1. Create a new GitHub repo (e.g. `yourusername.github.io` for a root domain, or any name for
   a project site).
2. Push everything in this folder to the repo's default branch.
3. In the repo's Settings → Pages, set the source to the default branch, root folder.
4. The site will be live at `https://yourusername.github.io/` (or `/reponame/` for a project site).

## SQL

Each project's `assets/sql/*.sql` file is a reference set of queries mirroring the DAX measures
used in that project's Power BI model — a starting point to adapt once you connect it to a real
database, not extracted from a live database.
