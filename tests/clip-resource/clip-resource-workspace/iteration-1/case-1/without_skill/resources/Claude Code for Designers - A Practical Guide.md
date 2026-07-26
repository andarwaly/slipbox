---
title: "Claude Code for Designers: A Practical Guide"
source: https://nervegna.substack.com/p/claude-code-for-designers-a-practical
author: Tommaso Nervegna
publication: Sorted Pixels
published: 2026-01-26
clipped: 2026-07-27
tags:
  - clippings
  - claude-code
  - design
  - ai-tools
---

# Claude Code for Designers: A Practical Guide

*A Step-by-Step Guide to Designing and Shipping with Claude Code*

By [Tommaso Nervegna](https://substack.com/@nervegna), Jan 26, 2026 — Sorted Pixels

Source: https://nervegna.substack.com/p/claude-code-for-designers-a-practical

## Summary

The author, a former full-stack "webmaster" turned design leader, argues that Claude Code removes the "translation layer" between design intent and working code. Rather than requiring designers to "learn to code," it lets them describe outcomes in design vocabulary and iterate on behavior/interactions instead of fighting syntax. The piece walks through a practical Figma-first development workflow (using a tool called GSD — a phased discuss/plan/execute methodology) for turning Figma designs into functional, deployed products, and includes real examples (a dashboard prototype built in 2 days, a personal AI agent for vintage-watch hunting).

## The Translation Problem

For years the standard advice to designers was "learn to code." The author already knew how — JavaScript, React, Node, databases — from an earlier career building production systems at creative agencies. But as they moved into design leadership, the gap between *knowing* how to code and *actually* coding widened, not from forgetting, but because of overhead: build tools, dependency management, webpack debugging, framework churn. The real problem wasn't capability but the translation layer between design intent and implementation — mentally switching between "designer brain" and "developer brain."

Claude Code, in the author's framing, understands design intent and translates it directly into working software: describe what to build in designer vocabulary plus developer intuition, it writes the code, and iteration happens through feedback on outcomes rather than syntax debugging.

## What This Looks Like in Practice

**Personal AI Agent for Vintage Watch Hunting** — Trying to find a vintage Cartier Tank watch for his wife, the author built a personal AI-powered agent over a weekend to search, monitor, and bid across multiple vintage watch marketplaces. He described the desired outcome (how the agent should search, evaluate listings, surface opportunities); Claude helped design the system architecture, integrate marketplace data, and translate product/UX thinking into functional code. Iteration was on behavior and logic, not syntax. What would normally take weeks became a focused design-and-build sprint, producing a genuinely useful tool.

## My Workflow for Client Projects

Describes how the author applies Claude Code to real client work (Accenture Song), leading into the Figma-first workflow detailed below.

## The Figma-First Development Workflow

Uses a phased approach (referred to as "GSD" — discuss/plan/execute per phase) driven from Figma designs via Figma MCP integration.

### Step 3: Build Your First Project (The GSD Way)

Start a new project:

```bash
cd Desktop
mkdir my-portfolio
cd my-portfolio
claude --dangerously-skip-permissions
```

Then inside Claude Code:

```
/gsd:new-project
```

### Step 5: Build Screens from Figma Layouts

For layout phases, run `/gsd:discuss-phase 3`. GSD asks clarifying implementation questions (responsive behavior, Figma Auto Layout spacing, content strategy) before generating code. Example exchange:

GSD detects layout structure (hero, features grid, CTA, footer) and asks about responsive breakpoints, gap/padding scaling, and whether content should come from Figma as static defaults or be dynamic/props-driven.

After answering, run:

```
/gsd:plan-phase 3
/gsd:execute-phase 3
```

GSD then uses the Figma MCP to:
1. Read layout structure (sections, spacing, alignment)
2. Extract text content and image sources
3. Generate responsive React components
4. Apply design tokens from Phase 1
5. Reuse Button/Card components from Phase 2

**Result:** a landing page matching the Figma layout exactly, fully responsive, built from the existing component library.

### Step 6: Execute the Phase (Parallel Execution + Atomic Commits)

Once plans are ready:

```
/gsd:execute-phase 2
```

This runs the build with parallel execution and atomic commits per unit of work.

### Real Example: Dashboard Prototype in 2 Days

**Day 1 morning** — Design a 6-screen dashboard in Figma (Overview, Analytics, Settings, Users, Reports, Profile) with a component library (Buttons, Cards, Tables, Forms, Navigation) and a design system (colors, typography, spacing).

**Day 1 afternoon** — Initialize with GSD:

```
/gsd:new-project
> "Build a dashboard matching this Figma design: [URL]"

/gsd:discuss-phase 1   # Design tokens
/gsd:plan-phase 1
/gsd:execute-phase 1   # Extracts all tokens from Figma

/gsd:discuss-phase 2   # Component library
/gsd:plan-phase 2
/gsd:execute-phase 2   # Builds all components matching Figma
```

**Day 2 morning** — Build screens:

```
/gsd:discuss-phase 3   # Overview screen
/gsd:plan-phase 3
/gsd:execute-phase 3

/gsd:discuss-phase 4   # Analytics screen
/gsd:plan-phase 4
/gsd:execute-phase 4
```

**Day 2 afternoon** — Polish and deploy:

```
/gsd:verify-work 3
/gsd:verify-work 4
> Deploy to Vercel
```

**Result:** a fully functional dashboard matching Figma pixel-perfect — reusable React components, design tokens in Tailwind config, responsive layouts, interactive states matching prototypes, deployed and shareable with stakeholders.

**Time saved:** what would normally take 1–2 weeks with a traditional dev handoff was built in 2 days by one designer.

### Why This Figma + GSD Workflow Works

(Section explains the underlying rationale for driving development directly from Figma with a phased discuss/plan/execute loop — keeping design tokens, components, and layouts traceable back to source design files.)

## Final Thoughts

The shift from "designing interfaces" to "designing systems that work" is already underway. For the author, it isn't really a new shift so much as a return — back in the "webmaster" era, designers/developers had to think in complete systems: design, code, deployment, maintenance, all together, before that work became siloed into separate roles.

---
*Clipped manually — no clipping skill was available in this session. Full article content (all sections in detail) can be re-fetched from the source URL above if a more complete capture is needed.*
