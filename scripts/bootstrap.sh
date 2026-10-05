#!/usr/bin/env bash
# One-shot installer for WSL / Linux / macOS:
#   installs Hermes if missing, copies the project into the Linux home (if it sits on C:),
#   asks for .env, creates the 3 profiles, sets up web search and starts the team.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$HOME/hermes-telegram-team"
export PATH="$HOME/.local/bin:$HOME/.hermes/bin:$PATH"

say() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*"; }

# 1. Work from the Linux filesystem (Windows drives break chmod and are slow)
if [[ "$SRC" == /mnt/* ]]; then
  say "Copying project to $DEST"
  mkdir -p "$DEST"
  # keep an existing .env in DEST, otherwise take the one from Windows (if any)
  tar -C "$SRC" --exclude=.git -cf - . | tar -C "$DEST" -xf - --skip-old-files 2>/dev/null \
    || tar -C "$SRC" --exclude=.git -cf - . | tar -C "$DEST" -xf -
  cd "$DEST"
else
  cd "$SRC"
fi
# Windows editors may add CRLF line endings — strip them
find . -type f \( -name '*.sh' -o -name '*.md' -o -name '*.yaml' -o -name '.env*' \) -not -path './.git/*' \
  -exec sed -i 's/\r$//' {} +
chmod +x scripts/*.sh

# 2. Basic tools
for t in curl git; do
  command -v "$t" >/dev/null || { say "Installing $t"; sudo apt-get update -y && sudo apt-get install -y "$t"; }
done

# 3. Hermes
if ! command -v hermes >/dev/null; then
  say "Installing Hermes Agent"
  curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
  hash -r
  command -v hermes >/dev/null || { echo "Hermes installed but not on PATH. Close this window, open Ubuntu again and re-run."; exit 1; }
fi
hermes --version || true

# 4. .env
if [[ ! -f .env ]] || grep -q '^ANTHROPIC_API_KEY=sk-ant-\.\.\.$' .env; then
  [[ -f .env ]] || cp .env.example .env
  say "Fill in .env (Anthropic key, your id, group id, 3 tokens, 3 usernames). Ctrl+O Enter to save, Ctrl+X to exit."
  read -rp "Press Enter to open the editor..." _
  nano .env
fi

# 5. Profiles
say "Creating Hermes profiles"
./scripts/setup.sh

# 6. Web search for the researcher
say "Choose a web search backend for the researcher (Tavily works without a key)"
read -rp "Press Enter to open the tools menu (or type 's' to skip): " ans
[[ "$ans" == "s" ]] || hermes -p researcher tools

# 7. Smoke test
say "Smoke test: coder"
hermes -p coder chat -q "Run python to compute 2**100 and print only the number" || echo "⚠ coder test failed — check ANTHROPIC_API_KEY / model name (hermes -p coder model)"

# 8. Start
say "Starting the team"
./scripts/team.sh start
./scripts/team.sh status
echo
echo "✅ Done. Write in the Telegram group: @<coordinator_bot> <your request>"
echo "   Logs:  ~/hermes-telegram-team/scripts/team.sh logs"
