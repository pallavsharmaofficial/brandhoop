# HoopLock

EMI device locking for phones sold on credit by Brandhoop Mobile Point (and
later other shops). Android and iPhone, managed from a website and a phone app.
Built from scratch as its own project; it will merge into the Brandhoop app
and website later.

**Status: research and plan only. No code yet.**

| Read | What it covers |
|---|---|
| `docs/RESEARCH.md` | How the market works, what keys cost, how Android and iPhone locking actually works, Google/Apple/RBI rules |
| `docs/PLAN.md` | Architecture, key system, lock stages, phases, costs, risks |

Planned folders: `agent-android/` (Kotlin Device Owner app), `server/`
(TypeScript API), `mdm-ios/` (NanoMDM), `console/` (Flutter web + phone app),
`infra/`.
