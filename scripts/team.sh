#!/usr/bin/env bash
# Start / stop / inspect the three gateways (one process per profile, one bot token each).
# Usage: ./scripts/team.sh start|stop|restart|status|logs [agent]
set -euo pipefail
AGENTS=(coordinator researcher coder)
HERMES_ROOT="${HERMES_ROOT:-$HOME/.hermes}"
cmd="${1:-status}"

case "$cmd" in
  start|stop|restart|status)
    for a in "${AGENTS[@]}"; do
      echo "── $a: gateway $cmd"
      hermes -p "$a" gateway "$cmd" || true
    done ;;
  logs)
    a="${2:-coordinator}"
    tail -f "$HERMES_ROOT/profiles/$a/logs/gateway.log" ;;
  *)
    echo "usage: $0 start|stop|restart|status|logs [agent]"; exit 1 ;;
esac
