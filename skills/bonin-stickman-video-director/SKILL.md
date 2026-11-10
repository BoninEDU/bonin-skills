---
name: bonin-stickman-video-director
description: "Turn topics, requirements, articles or scripts into stickman videos. Director mode creates approved storyboards and standalone video prompts; Autopilot mode produces narrated, captioned illustration-and-micro-animation videos through configured generation tools and a local renderer. Use when the user asks for stickman video, 火柴人视频, storyboard-to-video, or autopilot video production."
---

# Bonin Stickman Video Director

This is the install entrypoint for the complete stickman video production package.
The package root contains `docs/`, `tests/` and the full operational skill under
[skills/directing-stickman-videos/SKILL.md](skills/directing-stickman-videos/SKILL.md).

Before handling any request, read that Skill file completely, then follow its
mode router:

- **A · Director (A1–A5)** — approved storyboards and standalone video prompts.
- **A6 · Amber Noir** — reference-guided execution, narration and finishing.
- **B · Autopilot (B1–B5)** — narrated, captioned, locally rendered videos.

Runtime dependencies and setup live in
[skills/directing-stickman-videos/package.json](skills/directing-stickman-videos/package.json)
and [README.md](README.md). Do not install or generate anything until the
user has confirmed the deliverable and paid-generation authorization.

## Provenance / 来源

Ported from the upstream open-source project **stickman-video-director**
(https://github.com/kaomei/stickman-video-director), MIT License, see
[LICENSE](LICENSE). Upstream skill identifier `directing-stickman-videos` is
kept inside the package for install-layout and regression-test compatibility;
the Bonin install entrypoint is this file.
