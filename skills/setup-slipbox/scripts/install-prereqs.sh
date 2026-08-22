#!/usr/bin/env bash
# Install-only script for a single slipbox prerequisite.
# Performs no detection and no user-facing asking — the caller (the agent)
# must have already confirmed with the user before invoking this.
#
# Usage: install-prereqs.sh <youtube-transcript-api|defuddle|firecrawl>
#
# `firecrawl` installs the binary only — it still needs `firecrawl config`
# (interactive browser login or an API key) run separately; this script never
# handles credentials, same rule as everything else here.
#
# Every failure exits nonzero with a message naming the dependency: a missing
# installer, a failed install, and an install that reports success but leaves
# nothing usable behind are all reported, never passed off as done.

set -euo pipefail

dep="${1:-}"

die() { echo "install-prereqs.sh: $1" >&2; exit 1; }

require_installer() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required to install $dep, but it isn't on PATH"
}

case "$dep" in
  youtube-transcript-api)
    require_installer python3
    python3 -m pip --version >/dev/null 2>&1 || die "python3 has no usable pip module — install pip, then retry"
    python3 -m pip install youtube-transcript-api || die "pip install youtube-transcript-api failed"
    python3 -c "import youtube_transcript_api" >/dev/null 2>&1 ||
      die "pip reported success but 'import youtube_transcript_api' still fails — check which python3 pip installed into"
    ;;
  defuddle)
    require_installer npm
    npm install -g defuddle || die "npm install -g defuddle failed"
    command -v defuddle >/dev/null 2>&1 ||
      die "npm reported success but defuddle isn't on PATH — check npm's global bin directory (npm bin -g)"
    ;;
  firecrawl)
    require_installer npm
    npm install -g firecrawl-cli || die "npm install -g firecrawl-cli failed"
    command -v firecrawl >/dev/null 2>&1 ||
      die "npm reported success but firecrawl isn't on PATH — check npm's global bin directory (npm bin -g)"
    ;;
  "")
    echo "Usage: $0 <youtube-transcript-api|defuddle|firecrawl>" >&2
    exit 1
    ;;
  *)
    echo "Usage: $0 <youtube-transcript-api|defuddle|firecrawl>" >&2
    echo "install-prereqs.sh: unknown dependency: $dep" >&2
    exit 1
    ;;
esac
