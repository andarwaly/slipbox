#!/usr/bin/env bash
# Install-only script for a single slipbox prerequisite.
# Performs no detection and no user-facing asking — the caller (the agent)
# must have already confirmed with the user before invoking this.
#
# Usage: install-prereqs.sh <sqlite3|youtube-transcript-api|defuddle>

set -euo pipefail

dep="${1:-}"

case "$dep" in
  sqlite3)
    if command -v brew >/dev/null 2>&1; then
      brew install sqlite3
    elif command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update && sudo apt-get install -y sqlite3
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y sqlite
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y sqlite
    elif command -v pacman >/dev/null 2>&1; then
      sudo pacman -S --noconfirm sqlite
    elif command -v apk >/dev/null 2>&1; then
      sudo apk add sqlite
    else
      echo "No supported package manager found (tried brew, apt-get, dnf, yum, pacman, apk). Install sqlite3 manually." >&2
      exit 1
    fi
    ;;
  youtube-transcript-api)
    pip install youtube-transcript-api
    ;;
  defuddle)
    npm install -g defuddle
    ;;
  *)
    echo "Usage: $0 <sqlite3|youtube-transcript-api|defuddle>" >&2
    exit 1
    ;;
esac
