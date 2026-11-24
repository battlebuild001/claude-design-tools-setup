#!/usr/bin/env bash
# Installs the five design tools for Claude Code, skipping anything already present.
# Usage: bash setup.sh [--global] [--design <site>]
#   --global        install skills into ~/.claude/skills (all projects) instead of ./.claude/skills
#   --design <site> which DESIGN.md to fetch from awesome-design-md (default: linear.app)
set -u
GLOBAL=""; SITE="linear.app"
while [ $# -gt 0 ]; do
  case "$1" in
    --global) GLOBAL="--global" ;;
    --design) shift; SITE="${1:-linear.app}" ;;
  esac
  shift
done
if [ -n "$GLOBAL" ]; then DIR="$HOME/.claude/skills"; else DIR=".claude/skills"; fi
FAIL=0
say() { printf '%s\n' "$*"; }

# 1. Node 22.20+
NODE=$(node --version 2>/dev/null || true)
MAJOR=$(printf '%s' "$NODE" | sed 's/^v//' | cut -d. -f1)
MINOR=$(printf '%s' "$NODE" | cut -d. -f2)
if [ -z "$NODE" ] || [ "$MAJOR" -lt 22 ] || { [ "$MAJOR" -eq 22 ] && [ "$MINOR" -lt 20 ]; }; then
  say "FAIL node: need 22.20+, found '${NODE:-none}'"; exit 1
fi
say "OK   node $NODE"

# 2. Skills (name|source). image-to-code moved from taste-skill to imagegen-skills.
for item in \
  "design-taste-frontend|https://github.com/Leonxlnx/taste-skill" \
  "image-to-code|https://github.com/Leonxlnx/imagegen-skills" \
  "web-design-guidelines|vercel-labs/agent-skills" \
  "agent-browser|vercel-labs/agent-browser"; do
  NAME=${item%%|*}; SRC=${item#*|}
  if [ -d "$DIR/$NAME" ]; then say "SKIP $NAME (already installed)"; continue; fi
  npx --yes skills@latest add "$SRC" --skill "$NAME" --agent claude-code $GLOBAL --yes --copy >/dev/null 2>&1
  if [ -d "$DIR/$NAME" ]; then say "OK   $NAME installed"; else say "FAIL $NAME (source: $SRC)"; FAIL=1; fi
done

# 3. agent-browser CLI
if command -v agent-browser >/dev/null 2>&1; then
  say "SKIP agent-browser CLI (already installed)"
else
  npm install -g agent-browser >/dev/null 2>&1
fi
if VER=$(agent-browser --version 2>/dev/null); then say "OK   $VER"; else say "FAIL agent-browser CLI (npm install -g agent-browser)"; FAIL=1; fi

# 4. Browser: reuse an existing Chromium/Chrome if there is one, else download Chrome.
FOUND=""
if [ -n "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ] && [ -e "$AGENT_BROWSER_EXECUTABLE_PATH" ]; then
  FOUND="$AGENT_BROWSER_EXECUTABLE_PATH"
else
  for c in /opt/pw-browsers/chromium \
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    "$(command -v google-chrome 2>/dev/null)" "$(command -v chromium 2>/dev/null)" \
    "$(command -v chromium-browser 2>/dev/null)"; do
    if [ -n "$c" ] && [ -e "$c" ]; then FOUND="$c"; break; fi
  done
fi
if [ -n "$FOUND" ]; then
  say "OK   browser: using existing $FOUND"
  if [ -z "${AGENT_BROWSER_EXECUTABLE_PATH:-}" ]; then
    say "NOTE set AGENT_BROWSER_EXECUTABLE_PATH=\"$FOUND\" (add AGENT_BROWSER_ARGS=--no-sandbox when running as root)"
  fi
elif agent-browser install >/dev/null 2>&1; then
  say "OK   browser: Chrome downloaded"
else
  say "FAIL browser: no Chrome found and download failed (network may block googlechromelabs.github.io)"; FAIL=1
fi

# 5. DESIGN.md (never overwrite an existing one)
if [ -e DESIGN.md ]; then
  say "SKIP DESIGN.md (already exists, not overwritten)"
elif curl -fsS -o DESIGN.md "https://raw.githubusercontent.com/VoltAgent/awesome-design-md/main/design-md/$SITE/DESIGN.md"; then
  say "OK   DESIGN.md downloaded ($SITE)"
else
  rm -f DESIGN.md; say "FAIL DESIGN.md (site '$SITE' not found or network blocked)"; FAIL=1
fi

if [ "$FAIL" -eq 0 ]; then say "RESULT: all five ready"; else say "RESULT: incomplete - see FAIL lines"; fi
exit "$FAIL"
