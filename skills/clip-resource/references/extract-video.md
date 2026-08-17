# Video extraction

Don't fetch the page HTML for the transcript. Use the **`youtube-transcript-api`** Python library directly (not the `ytt` CLI wrapper) to pull the transcript. Pass `languages` from `slipbox config get transcript_languages` in order.

Failure taxonomy. These are not interchangeable:

- **`VideoUnavailable`, `TranscriptsDisabled`, `NoTranscriptFound`**: a clean failure. Treat exactly like a paywall or login wall: report it, write nothing, stop.
- **`RequestBlocked`, `IpBlocked`**: a distinct message. This is an environment or rate-limit problem, not "no transcript exists for this video." Say so explicitly; don't conflate the two failure kinds in the report.
- **`import` fails / library not installed**: a third, distinct case, different from both of the above. This isn't about the video at all; it's a missing dependency. `setup-slipbox`'s prerequisite check should have caught this already. If it's still missing: same shared shape as `SKILL.md`'s Prerequisite check, except don't attempt `pip install`.

No Whisper fallback, or any other transcription workaround, under any failure condition.
