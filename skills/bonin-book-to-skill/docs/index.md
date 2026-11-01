---
description: "Turn any book, PDF or EPUB into a structured agent skill for Claude Code, GitHub Copilot CLI, Amp, Codex, Hermes Agent, OpenCode, and OpenClaw. Named frameworks and decision rules, loaded on demand."seo_title: "bonin-book-to-skill - Turn Any Book Into an AI Agent Skill"
hide:
  - navigation
  - toc
---

<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "bonin-book-to-skill",
  "applicationCategory": "DeveloperApplication",
  "operatingSystem": "Linux, macOS, Windows",
"description": "Converts books and documents (PDF, EPUB, DOCX, HTML, Markdown, RTF, MOBI/AZW) into structured, on-demand agent skills for Claude Code, GitHub Copilot CLI, Amp, Codex, Hermes Agent, OpenCode, and OpenClaw.",  "url": "https://www.boninaigc.top",
  "codeRepository": "https://github.com/BoninEDU/bonin-skills",
  "license": "https://opensource.org/licenses/MIT",
  "offers": { "@type": "Offer", "price": "0", "priceCurrency": "USD" },
  "author": { "@type": "Person", "name": "BoninEDU", "url": "https://github.com/BoninEDU" }
}
</script>

# bonin-book-to-skill

<p style="font-size: 1.25rem; max-width: 42rem;">
Turn any book or document into a structured, on-demand agent skill — named frameworks, decision rules, and anti-patterns. <strong>Structure, not a summary.</strong>
</p>

[Get started](guide.md){ .md-button .md-button--primary }
[Skill reference](skill-reference.md){ .md-button }
[GitHub](https://github.com/BoninEDU/bonin-skills){ .md-button }

---

## Why bonin-book-to-skill

<div class="grid cards" markdown>

-   :material-file-document-multiple:{ .lg .middle } __Multi-format__

    ---

    PDF, EPUB, DOCX, HTML, Markdown, RTF, MOBI/AZW (via Calibre). Extraction runs
    locally with graceful stdlib fallbacks — no upload, no lock-in.

-   :material-brain:{ .lg .middle } __Structure, not summaries__

    ---

    Named frameworks, mental models, decision rules, and anti-patterns — the
    author's toolkit, captured with their exact terms, not a book report.

-   :material-flash:{ .lg .middle } __On-demand chapters__

    ---

    Per-chapter files load only when the topic is relevant, so a 200-page book
    costs tokens proportional to the question, not the page count.

-   :material-robot-happy:{ .lg .middle } __Multi-agent__

    ---

One `SKILL.md` runs on Claude Code, GitHub Copilot CLI, Amp, Codex, Hermes Agent, OpenCode, and OpenClaw through the open Agent Skills standard.

</div>

## Install

**As an agent skill** (gives you the `/bonin-book-to-skill` command in Claude Code, Copilot CLI, Amp, Codex, Hermes Agent, OpenCode, or OpenClaw):
```bash
npx skills add BoninEDU/bonin-skills
# or manually:
git clone https://github.com/BoninEDU/bonin-skills.git ~/.claude/skills/bonin-book-to-skill
# then, in your agent session:
/bonin-book-to-skill /path/to/book.pdf [skill-name]
```

**As a standalone CLI** (just the text extractor, optional):

```bash
# not on PyPI yet — pip takes it from the repository
pip install "bonin-book-to-skill[pdf,epub,docx] @ git+https://github.com/BoninEDU/bonin-skills.git"
bonin-book-to-skill /path/to/book.pdf --mode text
```

## Learn more

<div class="grid cards" markdown>

-   :material-sitemap:{ .lg .middle } __[Architecture](architecture.md)__

    ---

    How the deterministic extractor and the spec-driven generator fit together.

-   :material-speedometer:{ .lg .middle } __[Performance](performance.md)__

    ---

    The measured Discovery Loop Tax and real per-conversion token cost.

-   :material-book-open-page-variant:{ .lg .middle } __[Skill Reference](skill-reference.md)__

    ---

    The full `SKILL.md` spec: every step, depth budget, and quality rule.

-   :material-heart:{ .lg .middle } __[Bonin AIGC](https://www.boninaigc.top)__

    ---

    Part of the Bonin AIGC skills collection — 成就超级个体和团队 / Empower Super-Individuals and Super-Teams.

</div>
