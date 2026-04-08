# LiteEdit Promotion Kit

Ready-to-use drafts, submission targets, and metrics playbook.

---

## 1. Show HN Post

**Title:** `Show HN: LiteEdit – A native macOS code editor under 1 MB (no Electron)`

**Body:**

```
I built a code editor for macOS that compiles to a single binary under 1 MB.

The problem: I kept opening VS Code just to read a file, tweak a config, or
browse a repo. Every time, I waited for a 400 MB Electron app to bootstrap,
allocate 200+ MB of RAM, and spin up a runtime — for a 5-second edit.

LiteEdit is the opposite of that. It's built with Swift and AppKit (no SwiftUI,
no web views, no third-party frameworks). The entire app — syntax highlighting
for 20+ languages, tabbed editor, file tree, find & replace, session persistence,
quick open — compiles from ~3,000 lines of Swift into a single sub-megabyte binary.

Comparison:
  - LiteEdit: < 1 MB app, ~20 MB RAM at idle
  - Sublime Text: ~40 MB app, ~90-140 MB RAM
  - VS Code: ~400 MB app, ~226+ MB RAM

It launches in milliseconds, remembers your session across restarts, and
supports multi-cursor editing.

It is NOT a VS Code replacement. It's the editor you reach for when you want to
open, read, edit, and close — in seconds.

Website: https://arietan.github.io/lite-edit/
Source: https://github.com/arietan/lite-edit
Download: https://github.com/arietan/lite-edit/releases/latest

Built with: Swift 5.9, AppKit, TextKit. MIT licensed. macOS 13+.
```

**Posting tips:**
- Best times: weekday mornings US time (9-11 AM ET / Tuesday-Thursday)
- Do NOT ask for upvotes
- Reply to every comment in the first 2 hours — engagement drives ranking
- Be honest about limitations (no LSP, no extensions, no terminal)

---

## 2. Reddit Posts

### r/macapps — Discovery post

**Title:** `LiteEdit — a free, open-source code editor for macOS under 1 MB`

**Body:**

```
I made a lightweight code editor for macOS. It's built natively with Swift
and AppKit — no Electron, no web views. The whole app is under 1 MB and
launches instantly.

Features:
- Syntax highlighting for 20+ languages
- Tabbed editing, file explorer, find & replace with regex
- Quick Open (Cmd+P), multi-cursor editing (Cmd+Shift+L)
- Session persistence (remembers your folder, tabs, cursor positions)
- Line numbers, status bar, keyboard shortcuts

It's not trying to replace VS Code — it's for when you want to open a project,
make a quick edit, and move on without waiting for a heavy app to load.

Free, MIT licensed, open source.

Website: https://arietan.github.io/lite-edit/
GitHub: https://github.com/arietan/lite-edit
Download: https://github.com/arietan/lite-edit/releases/latest
```

### r/swift — Technical build story

**Title:** `I built a full code editor in ~3,000 lines of Swift using only AppKit`

**Body:**

```
Wanted to share a project: LiteEdit is a native macOS code editor built
entirely with Swift and AppKit. No SwiftUI, no third-party dependencies,
no SPM packages. Just swift build.

The whole app compiles to a single binary under 1 MB and includes:
- Regex-based syntax highlighting for 20+ languages
- Tabbed document interface with session persistence
- NSOutlineView-based file tree sidebar
- NSTextView with custom line number gutter, find/replace bar, and multi-cursor editing
- Cmd+P quick open with fuzzy matching

I chose AppKit over SwiftUI because I wanted full control over the text editing
pipeline (TextKit, custom gutters, precise cursor management). The result is an
editor that launches in milliseconds and idles at ~20 MB of RAM.

Happy to answer questions about the AppKit/TextKit approach or trade-offs.

Source: https://github.com/arietan/lite-edit
```

### r/programming — Contrarian angle

**Title:** `Your code editor doesn't need to be 400 MB`

**Body:**

```
Most popular code editors today ship with an embedded web browser (Electron)
that weighs hundreds of megabytes — before you even open a file. I built a
native macOS editor to see how small a useful code editor could actually be.

LiteEdit: < 1 MB, ~20 MB RAM, launches in milliseconds. Built with Swift and
AppKit. Supports syntax highlighting for 20+ languages, tabbed editing, file
tree, quick open, find & replace, session persistence, and multi-cursor editing.

It's not a VS Code replacement. It's for quick edits: open a repo, change a
config, browse some code, and close. The kind of task that doesn't need an
embedded Chromium browser and Node.js runtime.

Open source (MIT): https://github.com/arietan/lite-edit
```

**Subreddit posting tips:**
- r/macapps: straightforward product showcase, be responsive to feature requests
- r/swift: focus on technical decisions, code architecture, AppKit vs SwiftUI trade-offs
- r/programming: provocative angle works well, but be genuine — acknowledge limitations
- Space posts 3-5 days apart to avoid looking spammy

---

## 3. Benchmark / Comparison Article

**Title:** `Why I built a code editor without Electron — and how it fits in under 1 MB`

**Outline:**

```markdown
## The problem
- I open VS Code 20+ times a day for tasks that take under 30 seconds
- Each launch: 400 MB app, 200+ MB RAM, multi-second startup
- For quick edits, the tool is orders of magnitude heavier than the task

## What I built
- LiteEdit: native macOS editor, Swift + AppKit, < 1 MB
- Screenshot / demo GIF here

## The numbers
- Table: LiteEdit vs Sublime vs VS Code (app size, RAM, cold start time)
- Cold start benchmark method: `time open -W LiteEdit.app` vs same for others
- Idle RAM: Activity Monitor readings after opening a medium project (~500 files)

## How it stays small
- No third-party dependencies — zero SPM packages
- AppKit + TextKit for text rendering — the OS already has a world-class text engine
- Regex-based syntax highlighting instead of TextMate grammars or Tree-sitter
- ~3,000 lines of Swift compiles to a single binary
- No embedded runtimes, no bundled Node.js, no Chromium

## Trade-offs
- No LSP / code intelligence — this is intentional, not a shortcoming
- No extension system — keeps scope and binary small
- No integrated terminal — use Terminal.app, it's right there
- macOS only — AppKit is the point, not a limitation

## Who it's for
- Developers who already use a heavy IDE but want a fast companion for quick tasks
- Anyone who opens code files more often than they write long sessions

## Try it
- Link to download, website, source
```

**Publishing options:**
- Personal blog / dev.to / Hashnode
- Cross-post summary to Hacker News and Reddit
- Can also publish on Medium (but dev.to has better SEO for technical content)

---

## 4. Short-Form Social Posts

### X (Twitter) thread

```
I built a code editor for macOS that's under 1 MB.

Most editors today ship 400 MB+ of Electron, Chromium, and Node.js.
LiteEdit ships a single native binary.

Thread: what I learned building a real editor with just Swift and AppKit 🧵

---

1/ The motivation was simple: I open VS Code 20+ times a day for tasks
that take under 30 seconds. That's a 400 MB app for a 5-second edit.

---

2/ LiteEdit is built with Swift + AppKit. No SwiftUI, no web views,
no third-party frameworks. Zero dependencies. Just `swift build`.

< 1 MB app size. ~20 MB RAM at idle. Launches in milliseconds.

---

3/ Features that fit in under 1 MB:
- Syntax highlighting (20+ languages)
- Tabbed editing + file explorer
- Quick Open (Cmd+P)
- Find & Replace with regex
- Multi-cursor editing
- Full session persistence

---

4/ The key insight: macOS already has a world-class text engine (TextKit).
Most of the heavy lifting is done by the OS. You don't need to ship your
own rendering pipeline.

---

5/ Trade-offs I chose intentionally:
- No LSP (this is a quick-edit tool, not an IDE)
- No extensions (keeps binary small)
- No terminal (Terminal.app is already open)
- macOS only (AppKit is the point)

---

6/ Try it:
🔗 https://arietan.github.io/lite-edit/
📦 https://github.com/arietan/lite-edit

Free, MIT licensed, open source.
```

### LinkedIn post

```
I built a code editor that's under 1 MB.

Most popular code editors today ship with an embedded web browser and
JavaScript runtime. They weigh 400+ MB before you open a single file.

I wanted something different: a fast, native macOS editor for quick edits.
Open a project, change a config, browse some code, and close — in seconds.

LiteEdit is:
→ Built with Swift and AppKit (no Electron, no web views)
→ Under 1 MB total app size
→ ~20 MB RAM at idle (vs 200+ MB for VS Code)
→ Launches in milliseconds
→ Supports 20+ languages, tabbed editing, quick open, multi-cursor

It's open source (MIT) and free to download:
https://arietan.github.io/lite-edit/

Sometimes the best tool is the smallest one.
```

---

## 5. App Directory Submissions

Submit LiteEdit to these directories and lists. Most accept free submissions.

| Directory | URL | Notes |
|---|---|---|
| AlternativeTo | https://alternativeto.net/software/submit/ | List as alternative to VS Code, Sublime, TextEdit |
| MacUpdate | https://www.macupdate.com/developers | Free listing for Mac apps |
| Slant | https://www.slant.co/ | Answer "What are the best code editors for macOS?" and mention LiteEdit |
| Awesome macOS | https://github.com/jaywcjlove/awesome-mac | Submit PR to Editors section |
| Awesome Open Source | https://github.com/corneliusio/awesome-open-source-apps | Submit PR |
| Open Source macOS Apps | https://github.com/serhii-londar/open-source-mac-os-apps | Submit PR to Text Editors section |
| Product Hunt | https://www.producthunt.com/ | Schedule a launch day, prepare visuals |
| dev.to | https://dev.to/ | Publish the benchmark article, tag with #swift #macos #opensource |
| Hacker News | https://news.ycombinator.com/submit | Show HN post (see draft above) |

**Awesome-list PR tips:**
- Follow each list's contribution guidelines exactly
- Keep the description to one line
- Include the app icon if the list uses them
- Link to the GitHub repo, not the website

---

## 6. Metrics Tracking Guide

### What to track

Track a simple funnel: **Awareness → Interest → Download → Retention**

| Stage | Metric | Where to find it |
|---|---|---|
| Awareness | Repo page views, unique visitors | GitHub → Insights → Traffic |
| Awareness | Social impressions | X Analytics, Reddit post views, HN rank |
| Interest | Repo stars, forks, watchers | GitHub repo page |
| Interest | Website visits | See analytics setup below |
| Download | Release download count | GitHub → Releases (download count per asset) |
| Download | Clone count | GitHub → Insights → Traffic → Clones |
| Retention | Returning contributors | GitHub → Issues, PRs, Discussions |
| Retention | Repeat release downloads | Compare download counts across releases |

### GitHub built-in metrics

GitHub already tracks these without any setup:
- **Traffic:** Insights → Traffic shows page views, unique visitors, top referrers, and popular content (last 14 days)
- **Release downloads:** each release asset shows a download count
- **Clones:** Insights → Traffic → Clones
- **Stars over time:** visible on the repo Insights page

Check these weekly to see which channels drive the most traffic.

### Website analytics (optional)

To track website visitors without adding heavy scripts, consider one of these
privacy-friendly, lightweight options:

**Option A: GoatCounter (recommended — free for open source)**
Add this before `</body>` in `docs/index.html`:
```html
<script data-goatcounter="https://YOURSITE.goatcounter.com/count"
        async src="//gc.zgo.at/count.js"></script>
```
Sign up at https://www.goatcounter.com/ (free, no cookies, GDPR-friendly).

**Option B: Plausible (self-hosted or paid cloud)**
```html
<script defer data-domain="arietan.github.io" src="https://plausible.io/js/script.js"></script>
```

**Option C: GitHub Pages traffic only**
If you don't want any external scripts, just rely on GitHub's built-in traffic
data for the repo + releases. This is the simplest approach.

### Weekly review checklist

Every Friday or Monday, spend 5 minutes checking:
- [ ] GitHub Traffic page — note unique visitors and top referrers
- [ ] Release download counts — track week-over-week change
- [ ] Star count — note growth rate
- [ ] Open issues / PRs — signal of engaged users
- [ ] Social post performance — which posts drove traffic?

Record these in a simple spreadsheet or note to spot trends over time.
