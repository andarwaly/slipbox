#!/usr/bin/env bash
# Detection-only prerequisite check for the slipbox family.
# Reports presence/absence of each dependency. Never installs anything.
# Exit code: 0 if all present, nonzero if anything is missing.
#
# A dependency that is installed but broken (present on PATH, fails to run)
# counts as missing — "present" here means usable, not merely findable.

set -u

missing=0

if command -v python3 >/dev/null 2>&1; then
  echo "python3: present ($(python3 --version 2>&1))"

  if python3 -c "import youtube_transcript_api" >/dev/null 2>&1; then
    echo "youtube_transcript_api: present"
  else
    echo "youtube_transcript_api: missing"
    missing=1
  fi
else
  # Without python3 the import check below can't distinguish "library missing"
  # from "no interpreter to import it with" — say which one it actually is.
  echo "python3: missing (required by the slipbox CLI and by youtube-transcript-api)"
  echo "youtube_transcript_api: unknown (no python3 to check with)"
  missing=1
fi

if command -v defuddle >/dev/null 2>&1; then
  if defuddle_version=$(defuddle --version 2>&1); then
    echo "defuddle: present ($defuddle_version)"
  else
    echo "defuddle: present on PATH but 'defuddle --version' failed — the install is broken: $defuddle_version"
    missing=1
  fi
else
  echo "defuddle: missing"
  missing=1
fi

# Optional — only used as clip-resource's fallback when a fetch is blocked by
# bot detection (e.g. some Medium articles). Never counts toward `missing`:
# the skill family works fully without it for the large majority of sources.
if command -v firecrawl >/dev/null 2>&1; then
  if firecrawl_status=$(firecrawl --status 2>&1); then
    if printf '%s' "$firecrawl_status" | grep -qi "Authenticated"; then
      echo "firecrawl: present, authenticated"
    else
      echo "firecrawl: present, not authenticated (optional — run 'firecrawl config' to enable the bot-detection fallback)"
    fi
  else
    # Distinguished from "not authenticated": the status command itself failed,
    # which `firecrawl --status | grep` would have reported as the same thing.
    echo "firecrawl: present on PATH but 'firecrawl --status' failed (optional): $firecrawl_status"
  fi
else
  echo "firecrawl: missing (optional — only needed for clip-resource's bot-detection fallback)"
fi

exit "$missing"
