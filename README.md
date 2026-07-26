# Gulzhan Raiymbek — Data Analyst Portfolio

Personal portfolio site showcasing my Power BI dashboards and SQL data modeling work.
Built as a static HTML/CSS/JavaScript site with no build process, deployed via GitHub Pages.

🔗 **Live site:** [graiymbek.github.io](https://graiymbek.github.io)

## About

I'm a Data Analyst / Power BI Developer, Microsoft Certified: Power BI Data Analyst
Associate (PL-300). This site walks through three dashboard projects, each paired with
a SQL data model: the problem being solved, the data model behind it, key DAX-driven
findings, and the report itself.

## Projects

- **Supply Chain Analytics** — order & fulfillment analysis on 180K+ orders: sales
  trends, shipping performance, and late-delivery risk by mode.
- **Retail Sales Analytics** — revenue, profit, and customer/product performance
  across $24.9M in sales and 25K+ orders.
- **Healthcare Analytics** — patient demographics, department workload, and
  revenue-cycle performance across 60K+ patients and 70K+ encounters.

Each case study page includes the data model, key findings, dashboard screenshots,
and a link to the underlying SQL queries.

## Built with

Power BI · DAX · SQL · HTML/CSS/JavaScript

## Structure

- `index.html`, `about.html`, `projects.html`, `resume.html`, `certificates.html` — main pages
- `projects/` — individual case study pages
- `assets/sql/` — SQL queries mirroring each project's Power BI data model
- `assets/img/` — dashboard screenshots and images
- `js/projects-data.js` — single source of truth for the project grid
