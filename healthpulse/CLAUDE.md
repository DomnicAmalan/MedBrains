# CLAUDE.md — HealthPulse Blog Platform

## Project Overview

HealthPulse is a healthcare-focused blog and content marketing platform for MedBrains HMS. It serves hospital administrators, clinicians, and patients with evidence-based health content. The frontend is an Astro static site; the backend is a Rust CMS API.

---

## Tech Stack (LOCKED — no substitutions)

### Frontend (Astro Site)

| Layer | Technology | Version |
|-------|-----------|---------|
| Framework | **Astro** | 5.x (static output ONLY) |
| Styling | **Tailwind CSS v4** via `@tailwindcss/vite` | 4.x |
| Typography | `@tailwindcss/typography` | 0.5.x |
| Sitemap | `@astrojs/sitemap` | 3.x |
| RSS | `@astrojs/rss` | 4.x |
| Linting/Formatting | **Biome** | 1.9.x |
| Package Manager | **pnpm** | 9.x |
| Build Orchestration | **Turborepo** | 2.x |

### Backend (CMS API)

| Layer | Technology |
|-------|-----------|
| Language | Rust (edition 2024, MSRV 1.85) |
| Web framework | Axum 0.8 + Tower 0.5 |
| Database | PostgreSQL 16+ with SQLx 0.8 |
| Auth | JWT (jsonwebtoken 9) + Argon2 |
| Logging | tracing + tracing-subscriber (JSON) |

### What is NOT in this stack

Do **NOT** introduce any of the following. If you think you need one, you are wrong:

- React, Vue, Svelte, Solid, Qwik, or any other SPA framework
- Next.js, Nuxt, SvelteKit, Remix, or any SSR meta-framework
- SCSS, CSS-in-JS, styled-components, Emotion, CSS Modules
- Webpack, Rollup, esbuild (Vite handles bundling via Astro)
- ESLint, Prettier (Biome replaces both)
- npm, yarn (pnpm only)
- Express, Fastify, Actix-web, Rocket (Axum only)
- ORMs like Diesel or SeaORM (SQLx runtime queries only)
- Ghost CMS, WordPress, Strapi, Contentful, Sanity, or any external CMS
- jQuery, Lodash, Moment.js, or any utility mega-library
- Shadcn/UI, Mantine, MUI, Chakra (this is Astro + Tailwind, not a component library app)
- AI/ML packages, LLM SDKs (no AI features in the blog)
- Analytics SDKs beyond Plausible (no Google Analytics, no Segment)

---

## Architecture Rules

### Astro — Static First, JavaScript Last

1. **Output mode is `static`**. Every page is pre-rendered at build time. Do NOT change to `server` or `hybrid` output.
2. **Zero client JS by default**. Astro components ship 0 bytes of JavaScript. This is a feature, not a limitation.
3. **No `client:*` directives** unless there is a genuine interactive requirement (search, mobile menu toggle). If you add one, justify it in a code comment.
4. **No React/Vue/Svelte islands**. All interactivity is vanilla `<script>` tags inside `.astro` files. Keep it minimal.
5. **No API calls at runtime**. All data fetching happens at build time in component frontmatter (`---` blocks). The deployed site is pure HTML/CSS.
6. **Content collections** for local content (posts, authors). Schema validated via Zod in `content.config.ts`.
7. **When the CMS API is live**, fetch at build time via `fetch()` in frontmatter, never on the client.

### Tailwind CSS v4

1. **Use Tailwind utility classes**. Do not write custom CSS unless Tailwind genuinely cannot express the design.
2. **Theme tokens** are defined in `src/styles/global.css` under `@theme`. Use them — do not hardcode hex colors.
3. **Category colors** use semantic tokens: `cat-leadership`, `cat-patient`, `cat-clinical`, `cat-operations`, `cat-technology`, `cat-regulatory`. Never raw hex in templates.
4. **Typography plugin** (`prose` / `prose-healthcare`) for article body content. Do not manually style article text.
5. **No `@apply`** in component `<style>` blocks. Use classes directly in markup.
6. **No Tailwind config file** — v4 uses CSS-first configuration via `@theme` in `global.css`.

### TypeScript

1. **Strict mode** — extends `astro/tsconfigs/strict`. No `any` types (Biome warns).
2. **Path alias** `@/*` maps to `src/*`. Use it for all imports.
3. **Shared types** live in `packages/types/src/index.ts`. Astro app imports from `@healthpulse/types`.
4. **Zod schemas** in `content.config.ts` are the single source of truth for content shape.
5. **No `as` type assertions** unless absolutely necessary. Prefer type narrowing.

### Biome (Linting & Formatting)

1. **Tabs** for indentation (not spaces).
2. **Double quotes** for strings.
3. **Always semicolons**.
4. **100-character line width**.
5. **Import organization** enabled — Biome auto-sorts imports.
6. **Run `pnpm lint` before every commit**. Zero warnings policy.
7. **No `biome-ignore` comments** without a genuine, documented reason.

### Rust Backend

1. **Edition 2024**, MSRV 1.85. `unsafe` is **forbidden**.
2. **Runtime SQL** — `sqlx::query_as::<_, T>()`, not compile-time macros.
3. **Row-Level Security** — every tenant-scoped table uses `tenant_id` + RLS policies. Set context per request.
4. **Error handling** — `thiserror` for library crates, `anyhow` at HTTP handler boundaries. No `unwrap()`, no `expect()`, no `panic!()`.
5. **Strict clippy** — `clippy::all` denied. No warnings allowed.
6. **No `dbg!()`, `println!()`, `eprintln!()`** — use `tracing` macros only.
7. **API keys** — SHA-256 hashed, never stored in plaintext. Prefix visible, secret masked.
8. **Post workflow enforcement** — backend must reject publish if status is not `approved`. No frontend-only guards.

---

## Content & Medical Compliance Rules

### Medical Content

1. **Patient-facing content MUST have medical review**. The `patient-education` category has `requiresMedicalReview: true`. Posts in this category without `medicalReviewer` + `medicalReviewDate` must not be published.
2. **Medical disclaimers** are mandatory on patient-facing content. Use `MedicalDisclaimer` component with appropriate variant (`patient`, `drug`, `global`).
3. **Drug information** must cite generic names (INN), not brand names.
4. **No medical advice**. All content must include "consult your doctor" language.
5. **Medical reviewer credentials** must be real qualifications from the `AuthorCredential` type (`MD`, `MBBS`, `MS`, `MCh`, `DM`, `DNB`, `PhD`, `MPH`, `RN`, `BSN`).

### SEO

1. **Every page** must use `SEOHead` component with title, description, and OG image.
2. **Article pages** must include `ArticleSchema` (Schema.org JSON-LD) — `Article` type for general content, `MedicalWebPage` for patient-education.
3. **Breadcrumbs** on all pages except homepage — use `BreadcrumbSchema`.
4. **Canonical URLs** — set for every page. No duplicate content.
5. **Image alt text** is mandatory. No empty `alt=""` except for decorative images.
6. **RSS feed** (`/rss.xml`) must include all published posts.
7. **Sitemap** auto-generated via `@astrojs/sitemap`.

### Accessibility

1. **Semantic HTML** — use `<article>`, `<nav>`, `<main>`, `<section>`, `<aside>`, `<header>`, `<footer>`. No `<div>` soup.
2. **Skip-to-content link** on every page (already in BaseLayout).
3. **Color contrast** — all text must meet WCAG 2.1 AA (4.5:1 for normal text, 3:1 for large text).
4. **Focus indicators** — all interactive elements must have visible focus styles.
5. **No `outline: none`** without a replacement focus indicator.
6. **ARIA labels** on icon-only buttons and links.

---

## File & Directory Conventions

```
healthpulse/
├── apps/web/src/
│   ├── components/     # .astro components (PascalCase filenames)
│   ├── layouts/        # Page layouts (BaseLayout, ArticleLayout, CategoryLayout)
│   ├── pages/          # File-based routing (lowercase-kebab-case)
│   ├── content/        # Astro content collections (posts/*.md, authors/*.json)
│   ├── data/           # Static data (categories.ts)
│   ├── lib/            # Utility functions (seo.ts, utils.ts)
│   └── styles/         # Global CSS (global.css with @theme)
├── packages/types/     # Shared TypeScript types
└── crates/             # Rust CMS backend
    ├── cms-core/       # Domain types
    ├── cms-db/         # SQLx migrations & queries
    └── cms-server/     # Axum HTTP handlers
```

### Naming Rules

| What | Convention | Example |
|------|-----------|---------|
| Astro components | PascalCase `.astro` | `StoryCard.astro` |
| Pages | lowercase kebab-case | `editorial-standards.astro` |
| TypeScript files | camelCase `.ts` | `categories.ts`, `seo.ts` |
| CSS classes | Tailwind utilities (kebab-case for custom) | `prose-healthcare` |
| Rust modules | snake_case | `cms_core`, `post_handlers` |
| SQL tables | snake_case, plural | `posts`, `post_tags`, `api_keys` |
| SQL enums | snake_case | `post_status`, `content_type` |
| ENV vars | SCREAMING_SNAKE_CASE | `GHOST_API_KEY`, `SITE_URL` |

### 6 Fixed Categories

These are the content verticals. Do not add or rename without a content strategy review:

1. `hospital-leadership` — C-suite strategy, governance
2. `patient-education` — Evidence-based health info (requires medical review)
3. `clinical-excellence` — Clinical protocols, best practices
4. `operations` — Hospital ops, efficiency, supply chain
5. `technology` — Health IT, digital transformation
6. `regulatory` — NABH, JCI, compliance, legal

---

## Build & Verification

### Commands

```bash
# From healthpulse/ root
pnpm dev          # Start Astro dev server
pnpm build        # Build static site + typecheck
pnpm typecheck    # TypeScript checking only
pnpm lint         # Biome lint
pnpm check        # Biome check + auto-fix
pnpm format       # Biome format

# Rust backend
cargo clippy      # Lint — 0 warnings required
cargo build       # Compile
cargo test        # Run tests
```

### Pre-commit Checklist

Before every commit, ALL must pass:

1. `pnpm lint` — zero Biome errors/warnings
2. `pnpm typecheck` — zero TypeScript errors
3. `pnpm build` — successful static build
4. `cargo clippy` — zero warnings (when backend exists)

### What NOT to Commit

- `node_modules/`, `dist/`, `.astro/`, `.turbo/`
- `.env` (use `.env.example` for templates)
- `*.log`, `.DS_Store`, `.vscode/`, `.idea/`
- Large binary files (images >500KB should be optimized first)
- Draft content not ready for review

---

## Dead Code & Cleanup Rules

- **Remove dead code immediately** — no unused imports, variables, functions, types, or commented-out code.
- **No backwards-compatibility shims** — if something is removed, delete it completely.
- **No speculative code** — do not add "for later" features.
- **No TODO comments** — either implement it now or track it in the feature spreadsheet.
- **No console.log / console.warn** in committed code — use Astro's built-in logging or remove.

---

## Performance Budgets

| Metric | Target |
|--------|--------|
| Lighthouse Performance | 95+ |
| First Contentful Paint | < 1.0s |
| Largest Contentful Paint | < 1.5s |
| Total Blocking Time | 0ms (static site) |
| Cumulative Layout Shift | < 0.1 |
| Total JS shipped (homepage) | < 10KB |
| Total CSS (critical path) | < 50KB |

### Image Rules

- All images must use `<img loading="lazy" decoding="async">` (except above-the-fold hero images).
- Feature images: max 1200x630px, WebP format preferred, < 200KB.
- Author avatars: max 200x200px, < 50KB.
- Always provide `width` and `height` attributes to prevent CLS.

---

## Dependency Policy

### Adding New Dependencies

Before adding ANY new package (npm or Cargo):

1. **Check if Astro/Tailwind/Biome already handles it.** Most things are covered.
2. **Check bundle size.** No dependency that adds >20KB to the client bundle.
3. **Check maintenance status.** No packages with 0 releases in the last 12 months.
4. **Prefer Astro integrations** (`@astrojs/*`) over generic packages.
5. **No duplicate functionality.** Don't add a date library when `Date` + `Intl` suffice.

### Pinned Versions

Major versions are pinned. Do NOT upgrade major versions without testing:

- `astro` — 5.x
- `tailwindcss` — 4.x
- `@biomejs/biome` — 1.x
- `sqlx` — 0.8.x
- `axum` — 0.8.x

---

## Git & Workflow

- **Branch naming**: `feat/cms-*`, `fix/blog-*`, `chore/healthpulse-*`
- **Commit messages**: imperative mood, lowercase, < 72 chars. Prefix with scope: `cms: add post workflow`, `blog: fix category layout`
- **No force pushes** to `main` or `master`.
- **PR required** for any production content or code changes.
