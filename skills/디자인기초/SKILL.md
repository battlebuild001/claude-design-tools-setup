---
name: 디자인기초
description: 디자인 도구 5개(design-taste-frontend, image-to-code, web-design-guidelines, agent-browser, DESIGN.md)를 한 번에 설치하고 검증합니다. Use when the user asks to set up, install, or verify the Claude Code design tools in one go, or when a design task starts and these skills or DESIGN.md are missing.
---

# Design Tools Setup

Installs and verifies five design tools with one script. It skips anything already
installed and never overwrites an existing `DESIGN.md`.

## Run

Run it from the project folder (files land in the current directory). The script is in
the `scripts` folder next to this file:

```bash
bash scripts/setup.sh   # use the full path to this skill's folder
```

Needs Node 22.20+ and network access. Safe to re-run at any time.

| Option | Effect |
|---|---|
| (none) | Skills go to `./.claude/skills` (this project only) |
| `--global` | Skills go to `~/.claude/skills` (every project on this machine) |
| `--design <site>` | Which DESIGN.md to fetch, e.g. `stripe.com` (default `linear.app`) |

If the user has not said project-only or global, use project-only and say so.

## Read the output

Each line starts with `OK`, `SKIP` (already there), `NOTE` (non-blocking), or `FAIL`.
It also writes `skills-lock.json` (the installer's record; keep it).
Report done only when the last line is `RESULT: all five ready` (exit code 0).
On any `FAIL`, report the failed line, its cause, and the next step. Do not claim success.

| FAIL line | Cause and next step |
|---|---|
| `node` | Node below 22.20. Ask the user to update Node. |
| a skill name | Repo moved or network blocked. The line prints the source; run `npx --yes skills@latest add <source> --list` to see current skill names. |
| `browser` | Chrome download blocked. Point `AGENT_BROWSER_EXECUTABLE_PATH` at any installed Chrome/Chromium. |
| `DESIGN.md` | Site name not in github.com/VoltAgent/awesome-design-md (folder `design-md/`), or network blocked. |

On a `NOTE` line, prefix every later `agent-browser` command with the printed variables
(shell state does not persist between commands), and tell the user about it.

## Known pitfalls

- `image-to-code` is in `Leonxlnx/imagegen-skills`, not `Leonxlnx/taste-skill`. Older guides give the wrong repo.
- `agent-browser install` fails on restricted networks; the script reuses an existing browser first.
- Claude Code cloud sessions are wiped when they end. To persist there, put the install lines in the environment's setup script with `--global`.
- Newly installed skills may only appear in the next session.

## After setup: order of use

1. `DESIGN.md` - read first as the colour, type, and spacing reference.
2. `design-taste-frontend` - build the screen.
3. `image-to-code` - when working from a reference image.
4. `agent-browser` - open the result and check a screenshot.
5. `web-design-guidelines` - final accessibility and usability review.
