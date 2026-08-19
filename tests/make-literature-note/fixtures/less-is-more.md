---
title: Less is more, more or less
url: https://jakubkrehel.com/less-is-more-more-or-less
author: Jakub Krehel
publisher: jakubkrehel.com
date: 2024-11-02
type: article
---

# Less is more, more or less

I've been building things with AI tools for long enough now that a pattern has settled
in my head, and it's the opposite of what I expected going in. I thought that as
production got cheaper, the person's own judgment would matter less — the model does the
thinking, I just approve it. What's actually happened is the reverse. AI makes human
understanding, judgment, and taste more important, not less, precisely because the
cost of producing something has collapsed and the cost of deciding whether it should
exist at all has not.

This shows up everywhere I look, once I started looking. Take product features. A model
will happily generate ten variations of a feature, all technically fine, and the entire
job left for a human is deciding which one actually deserves to ship — which is a
judgment call about what to keep and what to cut, not a production task. The same is
true one layer down, in code: an agent will produce a working implementation, several
of them if you ask, and the real value someone adds is knowing which lines earn their
place and which ones are accidental complexity that happened to compile. Zoom out again
and it's the same move on agent output generally — transcripts, drafts, summaries — the
skill isn't writing it, it's reading it critically and deciding what survives. Standards
and tools carry this same judgment baked in ahead of time; a style guide or a linter
config is really just somebody's prior decision about what to keep and cut, applied
automatically so you don't have to re-litigate it every time. And it's the same
principle behind what makes a product great in the first place — not that it does more,
but that someone decided, correctly, what it should refuse to do.

There's a second thread running alongside all this, about simplicity. A feature that
does less is easier to reason about — cutting scope isn't just a taste preference, it
measurably reduces how much a person has to hold in their head to use the thing
correctly. I keep rediscovering this same fact in a different room: the same reduction
in cognitive load that makes a simple feature easier to use also makes a simple
interface, or a simple API, easier to build on top of. It's one idea wearing two
outfits.

Standards and tools deserve a second mention too, because I don't think I said it
strongly enough the first time: a good linter config, a style guide, a well-chosen
default in a framework — these aren't neutral. They encode someone's judgment about
what good looks like, and once they exist, they do the judging for you, every time,
without asking. That's the whole value proposition of a standard.

None of this is an argument against using agents — I use them constantly. It's an
argument for being deliberate about how. I put together a short list of things that I
generally follow when working with agents:

- Give the agent a narrow, explicit constraint before asking it to produce anything —
  vague asks get vague, sprawling output.
- Read everything it hands back critically, on the assumption that it's plausible and
  wrong until checked, not correct until proven otherwise.
- Prefer asking it to cut something over asking it to add something, when a piece of
  output feels bloated.
- Keep a standing style or config file it can be pointed at, so judgment gets applied
  consistently instead of re-decided from scratch each session.
- Treat a first draft from an agent as a rough cut, never as a finished decision.
- Ask it to explain its reasoning before accepting a nontrivial suggestion, so the
  judgment call stays visible instead of hidden inside the output.
- Revisit the list itself occasionally — it's a living set of habits, not a fixed rulebook.

If there's one thing I'd want someone to take from all this, it's that cheaper
production doesn't shrink the human's job. It just relocates it — from making the thing
to deciding what the thing should be.
