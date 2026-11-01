<h1 align="center">bonin-book-to-skill</h1>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.ru.md"><strong>Русский</strong></a> ·
  <a href="README.zh-CN.md">简体中文</a>
</p>


> **Актуальность перевода.** Источник истины — [английский README](README.md). Этот перевод может отставать от `master`.  
> Синхронизирован с EN на коммите [`903d102`](https://github.com/BoninEDU/bonin-skills/commit/903d102fe8f67ea0fe3db7bea85eec7d8b505967) (2026-08-14).  
> Чтобы увидеть drift: `git log 903d102..master -- README.md`

<p align="center">
<strong>Превратите любую техническую книгу, папку документов или набор источников в единый agent skill — чтобы изучать, ссылаться и использовать в GitHub Copilot CLI, Amp, Claude Code, Hermes Agent или OpenCode, OpenClaw.</strong></p>

<p align="center">
  <a href="https://github.com/BoninEDU/bonin-skills/releases"><img src="https://img.shields.io/github/v/release/BoninEDU/bonin-skills?style=for-the-badge&color=blueviolet" alt="Latest release"></a>
  <img src="https://img.shields.io/badge/Agent_Skills-Open_Standard-blueviolet?style=for-the-badge" alt="Agent Skills standard">
  <img src="https://img.shields.io/badge/PDF%20%E2%80%A2%20EPUB%20%E2%80%A2%20DOCX%20%E2%80%A2%20MD%20%E2%80%A2%20HTML%20%E2%80%A2%20RTF%20%E2%80%A2%20MOBI-supported-green?style=for-the-badge" alt="Formats supported">
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" alt="MIT License">
  <a href="https://www.boninaigc.top"><img src="https://img.shields.io/badge/Bonin-AIGC-6c5ce7?style=for-the-badge" alt="Bonin AIGC"></a>
</p>

<p align="center">
  <a href="#-зачем">Зачем</a> ·
  <a href="#-что-получается">Что получается</a> ·
  <a href="#-не-только-книги">Не только книги</a> ·
  <a href="docs/how-it-works.md">How it works</a> ·
  <a href="docs/usage.md">Usage</a> ·
  <a href="docs/install.md">Install</a> ·
  <a href="docs/faq.md">FAQ</a> ·
  <a href="docs/performance.md">Performance</a> ·
  <a href="docs/architecture.md">Architecture</a> ·
  <a href="CHANGELOG.md">Changelog</a>
</p>

<p align="center">
  <strong>В 24×–51× меньше токенов</strong>, чем «залить книгу в контекст», чтобы ответить на один вопрос — на реальных книгах (<a href="docs/performance.md#the-discovery-loop-tax">как меряли</a>).
</p>

**Как это работает, в 3 шага:**

1. **Укажите** файл, папку или glob — `/bonin-book-to-skill ./my-book.pdf`
2. **Дистилляция** в skill — frameworks, decision rules, anti-patterns, per-chapter files. Структура, не «краткий пересказ».
3. **Агент грузит on demand** — `/my-book replication` читает нужную главу и отвечает по реальному содержимому, без галлюцинаций.

---

## 🤔 Зачем

Купили отличную книгу. Прочитали. Через три месяца глава 7 будто не существовала.

Обычные обходы не помогают:
- 📄 «Поищу в PDF» → список страниц, не ответы
- 🧠 «Спрошу агента про книгу» → галлюцинации или «нет содержимого»
- 📝 «Заметки по ходу» → 200-строчный файл, который больше не открываете

**bonin-book-to-skill превращает книгу в structured skill, который агент подгружает по запросу.**

После установки: `/your-book-slug replication` — агент читает нужную главу и отвечает из текста. Без галлюцинаций и копания в PDF.

Работает с хостами open [Agent Skills](https://github.com/agentskills/agentskills) — GitHub Copilot CLI, Amp, Claude Code, Hermes Agent и OpenCode, OpenClaw (общий формат `SKILL.md`).
---

## 📦 Что получается

`/bonin-book-to-skill your-book.pdf` (или путь к папке, шаблон файлов либо их список) по умолчанию создаёт одну копию skill в общей пользовательской директории `~/.agents/skills/<slug>/`. Её напрямую находят Copilot CLI, Amp, Codex, OpenCode и OpenClaw с каталогом состояния по умолчанию. OpenCode также читает собственную директорию `~/.config/opencode/skills/<slug>/`; если задан нестандартный `OPENCLAW_STATE_DIR`, для OpenClaw следует использовать `skills/` в активном каталоге состояния. При запуске в Claude Code конвертер пытается создать символьную ссылку `~/.claude/skills/<slug>/` и проверяет её чтением: если проверка не прошла, об этом сообщается в отчёте. Hermes Agent не сканирует общую директорию; его личные skills размещаются по категориям в `${HERMES_HOME:-$HOME/.hermes}/skills/<category>/<slug>/`. Управляемые директории OpenClaw и OpenCode, а также директории проекта можно выбрать явно:

| File | Purpose | Size |
|------|---------|------|
| `SKILL.md` | Core mental models + chapter index | ~4,000 tokens |
| `chapters/ch01-*.md` … | Одна глава on-demand | ~1,000 tokens each |
| `glossary.md` | Ключевые термины + refs | ~1,500 tokens |
| `patterns.md` | Techniques, algorithms, patterns | ~2,000 tokens |
| `cheatsheet.md` | Decision tables / quick rules | ~1,000 tokens |

**Chapter files on-demand** — не жрут skill budget, пока не спросите тему.

---

## 🏢 Не только книги

Имя «book», вход — любой structured prose:

- **Internal docs** — ADR, runbooks, onboarding
- **Brand & design systems** — voice, tone, principles
- **Research clusters** — papers + notes (см. update/fold-in)
- **Specs & standards** — RFCs, API contracts, compliance

Если документ часто переоткрываете — кандидат.

---

## 🧾 Цена цикла поиска

PDF-агент не просто читает — *навигирует*: ToC, backtrack, re-process каждый ход. bonin-book-to-skill платит structuring cost **один раз** при конверсии — **24×–51×** меньше токенов.

📊 **Методика → [docs/performance.md](docs/performance.md#the-discovery-loop-tax)**

---

## ⚙️ Как это работает

Две половины: deterministic Python **extractor** и spec-driven **generator** (агент следует `SKILL.md`). On-demand chapters держат loaded skill маленьким.

🔧 **Полный walkthrough → [docs/how-it-works.md](docs/how-it-works.md)**

---

## 🚀 Использование

`/bonin-book-to-skill <path|folder|glob> [skill-name]` — plus analyze-only, generate-from-analysis, and update/fold-in modes. После конверсии converter может опубликовать skill на GitHub (по умолчанию private), чтобы любой host ставил его через `npx skills add`.

▶️ **Все режимы и примеры → [docs/usage.md](docs/usage.md)**

💬 **На практике → [use cases](https://github.com/BoninEDU/bonin-skills-use-cases)** — DevEx-книга превратилась в survey 300+ инженеров; scanned PDF, который «завис», стал [#130](https://github.com/BoninEDU/bonin-skills/pull/130). Добавьте свой кейс: account в вашем Gist, index — one-line PR.


---

## 📥 Установка

```bash
# One command, any host:
npx skills add BoninEDU/bonin-skills

# Or manually:
git clone https://github.com/BoninEDU/bonin-skills.git ~/.claude/skills/bonin-book-to-skill
# (Copilot: ~/.copilot/skills/ · Amp: ~/.agents/skills/)
# (Hermes Agent: ${HERMES_HOME:-$HOME/.hermes}/skills/<category>/)
# (OpenClaw: ${OPENCLAW_STATE_DIR:-$HOME/.openclaw}/skills/; ~/.agents/skills/ только в состоянии по умолчанию)
# (OpenCode: ~/.agents/skills/ — также читает ~/.config/opencode/skills/)
```

📥 **Все хосты → [docs/install.md](docs/install.md)**

---

## ❓ Частые вопросы

❓ **Ответы → [docs/faq.md](docs/faq.md)**

---

<details>
<summary>🔧 <strong>Requirements</strong></summary>

Extractor пробует tools по порядку. Check: `python3 scripts/extract.py --check`

**PDF — по типу книги:**

| Book type | Tool | Install | Speed |
|-----------|------|---------|-------|
| Text-heavy | `pdftotext` (poppler) | `sudo apt install poppler-utils` | ⚡ |
| Text-heavy fallback | `pypdf` | `pip3 install pypdf` | ⚡ |
| Text-heavy fallback | `pdfminer.six` | `pip3 install pdfminer.six` | ⚡ |
| **Technical** | **`docling`** | `pip3 install docling` | ~1.5s/page |

> **Scanned PDFs** — сначала OCR (`ocrmypdf`), иначе пустой skill.

**EPUB / DOCX / HTML / RTF / MOBI** — см. English README tables; зависимости через pip / Calibre.

</details>

<details>
<summary>📁 <strong>Repository structure</strong></summary>

См. English README — дерево `SKILL.md`, `scripts/extractor/`, `tools/`, `docs/` без изменений.

</details>

---

## ⚖️ Авторское право и добросовестное использование

bonin-book-to-skill **не** содержит книг. Converter для файлов, которые вы уже имеете право читать.

- Processing **local**
- Своя копия / company docs
- Output = structured notes, не reproduction
- **Не** redistributе skills чужих copyrighted books

---

## 💖 Спонсоры

Часть коллекции навыков [Bonin AIGC](https://www.boninaigc.top) — 成就超级个体和团队 / Empower Super-Individuals and Super-Teams.

**[Explore more Bonin skills → https://www.boninaigc.top](https://www.boninaigc.top)**

## Лицензия

MIT — на converter в этом репо, **не** на книги/документы, которые вы обрабатываете.

## История звёзд

<a href="https://www.star-history.com/?repos=BoninEDU%2Fbonin-book-to-skill&type=date&legend=top-left">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=BoninEDU/bonin-skills&type=date&theme=dark&legend=top-left" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=BoninEDU/bonin-skills&type=date&legend=top-left" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=BoninEDU/bonin-skills&type=date&legend=top-left" />
 </picture>
</a>

---

<!-- translation-meta: source=README.md@c108d25b0cb58e1bdc361f3de02ed9f37075152f date=2026-10-01 scope=destination-policy -->
<sub>Destination policy synced to English README at commit <code>c108d25</code> · English remains canonical</sub>
