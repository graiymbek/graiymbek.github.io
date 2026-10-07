/* ============================================================
   Central blog post list. This is the ONLY file you need to touch
   to add a new blog post. The blog listing page (blog.html) and the
   "Latest posts" section wherever it's embedded render from this array.

   To add a new post:
   1. Copy one of the objects below and edit its fields.
   2. Write the post itself as blog/<slug>.html (copy an existing post
      in blog/ as a starting template, it already has the right
      header/footer/nav and .post-body styling).
   3. Optionally drop a cover image in assets/img/blog/ and point
      `cover` at it. If you skip this, a clean placeholder is shown
      automatically, no broken images.
   ============================================================ */

const POSTS = [
  {
    slug: "from-the-bench-to-the-dashboard",
    title: "How My Journey Into Data Analytics Actually Started",
    topic: "career",
    topicLabel: "Career Journey",
    excerpt: "It didn't start with a certification or a bootcamp. It started with a professor asking if I knew Linux, three months to learn Bash and Python, and a dataset of cancer mutations I couldn't put down.",
    date: "2026-10-07",
    dateLabel: "October 7, 2026",
    readTime: "4 min read",
    cover: "assets/img/blog/bench-to-dashboard-cover.png",
    url: "blog/from-the-bench-to-the-dashboard.html",
  },
  /* Not published yet. Gulzhan is writing these herself, Claude will edit,
     then they get un-commented here. Draft HTML already exists at the
     paths below as a starting point/reference.
  {
    slug: "pl-300-certification-journey",
    title: "Why I Got Microsoft Certified (PL-300): What I'd Do Differently",
    topic: "career",
    topicLabel: "Career Journey",
    excerpt: "The honest timeline of preparing for the Power BI Data Analyst Associate exam while working full-time: what I studied, what I skipped, and what actually showed up on the exam.",
    date: "2026-10-07",
    dateLabel: "October 7, 2026",
    readTime: "7 min read",
    cover: "assets/img/blog/pl-300-cover.png",
    url: "blog/pl-300-certification-journey.html",
  },
  {
    slug: "lessons-first-year-data-analyst",
    title: "5 Things I Wish I Knew Starting Out as a Data Analyst",
    topic: "career",
    topicLabel: "Career Journey",
    excerpt: "From trusting a dataset too quickly to learning that a dashboard nobody opens isn't a finished project: lessons from my first year doing this for real.",
    date: "2026-10-07",
    dateLabel: "October 7, 2026",
    readTime: "5 min read",
    cover: "assets/img/blog/lessons-first-year-cover.png",
    url: "blog/lessons-first-year-data-analyst.html",
  },
  */
];

const TOPIC_LABELS = {
  "career": "Career Journey",
  "tools": "Tools & Tutorials",
  "industry": "Industry Trends",
  "projects": "Project Deep-Dives",
};
