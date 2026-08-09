#!/usr/bin/env bash
# Install-only script for a single slipbox prerequisite.
# Performs no detection and no user-facing asking — the caller (the agent)
# must have already confirmed with the user before invoking this.
#
# Usage: install-prereqs.sh <youtube-transcript-api|defuddle>

set -euo pipefail

dep="${1:-}"

case "$dep" in
  youtube-transcript-api)
    pip install youtube-transcript-api
    ;;
  defuddle)
    npm install -g defuddle
    ;;
  *)
    echo "Usage: $0 <youtube-transcript-api|defuddle>" >&2
    exit 1
    ;;
esac
