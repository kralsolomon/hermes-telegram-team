#!/usr/bin/env bash
# Creates/updates three Hermes profiles (coordinator, researcher, coder) from this repo.
# Usage: ./scripts/setup.sh        (run from the repo root, after filling .env)
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
AGENTS=(coordinator researcher coder)

command -v hermes >/dev/null || { echo "❌ hermes not found. Install: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"; exit 1; }
[[ -f "$REPO/.env" ]] || { echo "❌ $REPO/.env missing. cp .env.example .env and fill it in."; exit 1; }

set -a; source <(sed 's/\r$//' "$REPO/.env"); set +a
[[ -n "${ANTHROPIC_API_KEY:-}" || -n "${OPENROUTER_API_KEY:-}" ]] || { echo "❌ set ANTHROPIC_API_KEY (or OPENROUTER_API_KEY) in .env"; exit 1; }
for v in TELEGRAM_ALLOWED_USERS TELEGRAM_GROUP_CHAT_ID \
         COORDINATOR_BOT_TOKEN COORDINATOR_BOT_USERNAME \
         RESEARCHER_BOT_TOKEN RESEARCHER_BOT_USERNAME \
         CODER_BOT_TOKEN CODER_BOT_USERNAME; do
  [[ -n "${!v:-}" ]] || { echo "❌ $v is empty in .env"; exit 1; }
done
# tolerate "@name" in .env
COORDINATOR_BOT_USERNAME="${COORDINATOR_BOT_USERNAME#@}"
RESEARCHER_BOT_USERNAME="${RESEARCHER_BOT_USERNAME#@}"
CODER_BOT_USERNAME="${CODER_BOT_USERNAME#@}"
if [[ "$COORDINATOR_BOT_USERNAME" == "$RESEARCHER_BOT_USERNAME" || "$COORDINATOR_BOT_USERNAME" == "$CODER_BOT_USERNAME" || "$RESEARCHER_BOT_USERNAME" == "$CODER_BOT_USERNAME" ]]; then
  echo "❌ two bots have the same username in .env — each agent needs its own bot"; exit 1
fi
echo "Usernames: coordinator=@$COORDINATOR_BOT_USERNAME researcher=@$RESEARCHER_BOT_USERNAME coder=@$CODER_BOT_USERNAME"

declare -A DESC=(
  [coordinator]="Plans requests, delegates to researcher/coder via @mentions, writes the final answer."
  [researcher]="Searches the web and returns short sourced briefs."
  [coder]="Writes and runs Python for calculations and charts."
)
declare -A TOKEN=(
  [coordinator]="$COORDINATOR_BOT_TOKEN"
  [researcher]="$RESEARCHER_BOT_TOKEN"
  [coder]="$CODER_BOT_TOKEN"
)

WORKSPACE="$HOME/hermes-team-workspace"
mkdir -p "$WORKSPACE/coder/out"

for a in "${AGENTS[@]}"; do
  home="$HERMES_ROOT/profiles/$a"
  echo "── $a → $home"

  if [[ ! -d "$home" ]]; then
    hermes profile create "$a" --description "${DESC[$a]}"
  fi
  mkdir -p "$home/skills"

  # config.yaml (back up whatever was there)
  [[ -f "$home/config.yaml" ]] && cp "$home/config.yaml" "$home/config.yaml.bak.$(date +%s)"
  sed "s#~/hermes-team-workspace#$WORKSPACE#g" "$REPO/agents/$a/config.yaml" > "$home/config.yaml"

  # SOUL.md with real bot usernames
  sed -e "s/{{COORDINATOR}}/$COORDINATOR_BOT_USERNAME/g" \
      -e "s/{{RESEARCHER}}/$RESEARCHER_BOT_USERNAME/g" \
      -e "s/{{CODER}}/$CODER_BOT_USERNAME/g" \
      "$REPO/agents/$a/SOUL.md" > "$home/SOUL.md"

  # skills
  cp -R "$REPO/agents/$a/skills/." "$home/skills/"

  # per-profile secrets
  umask 077
  cat > "$home/.env" <<EOF
TELEGRAM_BOT_TOKEN=${TOKEN[$a]}
TELEGRAM_ALLOWED_USERS=$TELEGRAM_ALLOWED_USERS
TELEGRAM_GROUP_ALLOWED_CHATS=$TELEGRAM_GROUP_CHAT_ID
TELEGRAM_ALLOW_BOTS=mentions
TELEGRAM_BOTS_REQUIRE_MENTION=true
TELEGRAM_REQUIRE_MENTION=true
TELEGRAM_EXCLUSIVE_BOT_MENTIONS=true
EOF
  [[ "$a" == "researcher" && -n "${TAVILY_API_KEY:-}" ]] && echo "TAVILY_API_KEY=$TAVILY_API_KEY" >> "$home/.env"
  [[ -n "${ANTHROPIC_API_KEY:-}" ]] && echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> "$home/.env"
  [[ -n "${OPENROUTER_API_KEY:-}" ]] && echo "OPENROUTER_API_KEY=$OPENROUTER_API_KEY" >> "$home/.env"
  umask 022
done

echo
echo "✅ Profiles ready. Next:"
echo "   hermes -p researcher tools   # pick a web search backend (Tavily works keyless)"
echo "   ./scripts/team.sh start"
