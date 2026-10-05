#!/usr/bin/env bash
# Hermes >= 0.21 runs ONE host gateway (default profile) that multiplexes every
# profile; each profile still polls with its own bot token and its own config.
# Usage: ./scripts/team.sh start|stop|restart|status|logs
set -euo pipefail
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
cmd="${1:-status}"

case "$cmd" in
  start|restart)
    hermes config set gateway.multiplex_profiles true >/dev/null
    hermes gateway install >/dev/null 2>&1 || true
    hermes gateway "$cmd"
    sleep 5; hermes gateway status ;;
  stop|status)
    hermes gateway "$cmd" ;;
  logs)
    tail -n 50 -f "$HERMES_ROOT"/logs/gateway.log "$HERMES_ROOT"/profiles/*/logs/gateway.log ;;
  *)
    echo "usage: $0 start|stop|restart|status|logs"; exit 1 ;;
esac
