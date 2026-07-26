/* ============================================================
   Central project list — this is the ONLY file you need to touch
   to add a new dashboard to the site. Every grid (Home "featured"
   and the full Projects page) renders from this array.

   To add a new project:
   1. Copy one of the objects below and edit its fields.
   2. Set status to "live" once its case-study page + dashboard exist,
      or "soon" to show it as a "Case study coming soon" card.
   3. Drop a thumbnail image in assets/img/ and point `thumb` at it.
   4. If status is "live", create projects/<slug>.html (copy
      projects/supply-chain.html as a starting template) and a
      dashboards/<slug>-dashboard.html interactive build.
   ============================================================ */

const PROJECTS = [
  {
    slug: "supply-chain",
    title: "Supply Chain Analytics",
    domain: "supply-chain",
    domainLabel: "Supply Chain",
    summary: "End-to-end order & fulfillment analysis on 180K+ orders — sales trends, shipping performance, and late-delivery risk by mode.",
    tools: ["Power BI", "DAX", "SQL", "Python"],
    thumb: "../assets/img/supply-chain-thumb.png",
    thumbFromRoot: "assets/img/supply-chain-thumb.png",
    status: "live",
    caseStudy: "projects/supply-chain.html",
    dashboard: "dashboards/supply-chain-dashboard.html",
  },
  {
    slug: "retail",
    title: "Retail Sales Analytics",
    domain: "retail",
    domainLabel: "Retail",
    summary: "Revenue, profit, and customer/product performance analysis across $24.9M in sales and 25K+ orders.",
    tools: ["Power BI", "DAX", "SQL"],
    thumb: "../assets/img/retail-thumb.png",
    thumbFromRoot: "assets/img/retail-thumb.png",
    status: "live",
    caseStudy: "projects/retail.html",
    dashboard: null,
  },
  {
    slug: "healthcare",
    title: "Healthcare Analytics Dashboard",
    domain: "healthcare",
    domainLabel: "Healthcare",
    summary: "Patient, admissions, and outcomes analysis dashboard built in Power BI.",
    tools: ["Power BI", "DAX", "SQL"],
    thumb: "../assets/img/healthcare-thumb.png",
    thumbFromRoot: "assets/img/healthcare-thumb.png",
    status: "live",
    caseStudy: "projects/healthcare.html",
    dashboard: null,
  },
  {
    slug: "hr-analytics",
    title: "HR Analytics Dashboard",
    domain: "hr",
    domainLabel: "HR",
    summary: "Workforce analytics dashboard covering headcount, turnover, and hiring metrics — currently in progress.",
    tools: ["Power BI", "DAX", "SQL"],
    thumb: "../assets/img/hr-thumb.png",
    thumbFromRoot: "assets/img/hr-thumb.png",
    status: "soon",
    caseStudy: "projects/hr-analytics.html",
    dashboard: null,
  },
  {
    slug: "insurance-claims",
    title: "Insurance Claims Analytics",
    domain: "insurance",
    domainLabel: "Insurance",
    summary: "Claims and policy performance analytics dashboard — currently in progress.",
    tools: ["Power BI", "DAX", "SQL"],
    thumb: "../assets/img/insurance-thumb.png",
    thumbFromRoot: "assets/img/insurance-thumb.png",
    status: "soon",
    caseStudy: "projects/insurance-claims.html",
    dashboard: null,
  },
];

const DOMAIN_LABELS = {
  "retail": "Retail",
  "supply-chain": "Supply Chain",
  "healthcare": "Healthcare",
  "hr": "HR",
  "insurance": "Insurance",
};
