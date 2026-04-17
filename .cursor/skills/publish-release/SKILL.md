---
name: publish-release
description: Publish a new LiteEdit release to GitHub — commit code, bump version, write changelog, create GitHub release, and update the landing page. Use when the user says publish, release, ship, or deploy a new version.
---

# Publish LiteEdit Release

## Prerequisites

- Working directory: project root of lite-edit
- `gh` CLI authenticated (`gh auth status`)
- All changes built and tested locally (per `local-build.mdc` rule)

## Workflow

### Step 1 — Commit outstanding changes

```bash
git status
git diff --stat
```

Stage and commit all modified source files with a descriptive message covering every change since the last tag. Use `git log $(git describe --tags --abbrev=0)..HEAD --oneline` to review what's new.

### Step 2 — Determine the version

```bash
git tag --sort=-creatordate | head -5
```

- **Patch** (v1.1.2 → v1.1.3): bug fixes only
- **Minor** (v1.1.2 → v1.2.0): new features or enhancements
- **Major** (v1.1.2 → v2.0.0): breaking changes

Ask only if ambiguous.

### Step 3 — Tag and push

```bash
git tag vX.Y.Z
git push origin main --tags
```

### Step 4 — Write release notes

Write notes to `.release-notes.md` using these sections (omit empty ones):

- **Editor Enhancements** — new editing features
- **Bug Fixes** — things that were broken and are now fixed
- **Performance** — speed, memory, or responsiveness improvements
- **Landing Page & Community** — docs, website, badges

End with: `**Full Changelog**: https://github.com/arietan/lite-edit/compare/vOLD...vNEW`

### Step 5 — Create GitHub release

```bash
gh release create vX.Y.Z --title "vX.Y.Z" --notes-file .release-notes.md
rm .release-notes.md
```

### Step 6 — Update landing page (`docs/index.html`)

Check what needs updating:

- **Features grid** — add a card if a major capability was added
- **Shortcuts table** — add rows for new keyboard shortcuts
- **Use Cases** — update if the editor's scope expanded
- **Download links** — use `/releases/latest` (auto-resolves, no version needed)

Commit and push landing page changes **separately** for a clean diff:

```bash
git add docs/index.html
git commit -m "Update landing page for vX.Y.Z"
git push origin main
```

### Step 7 — Update MEMORY.md

Record the release version, date, and a one-line summary in Recent Changes.

### Step 8 — Build locally

Per the `local-build.mdc` rule, always build and launch after everything is pushed:

```bash
swift build -c release 2>&1
ls -lh .build/release/LiteEdit | awk '{print $5}'
cp .build/release/LiteEdit LiteEdit.app/Contents/MacOS/LiteEdit
open LiteEdit.app
```

Binary must stay under 1 MB.
