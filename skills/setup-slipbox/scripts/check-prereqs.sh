#!/usr/bin/env bash
# Detection-only prerequisite check for the slipbox family.
# Reports presence/absence of each dependency. Never installs anything.
# Exit code: 0 if all present, nonzero if anything is missing.

set -u

missing=0

if command -v sqlite3 >/dev/null 2>&1; then
  echo "sqlite3: present ($(command -v sqlite3))"
else
  echo "sqlite3: missing"
  missing=1
fi

if python3 -c "import youtube_transcript_api" >/dev/null 2>&1; then
  echo "youtube_transcript_api: present"
else
  echo "youtube_transcript_api: missing"
  missing=1
fi

if command -v defuddle >/dev/null 2>&1; then
  echo "defuddle: present ($(defuddle --version))"
else
  echo "defuddle: missing"
  missing=1
fi

exit "$missing"
