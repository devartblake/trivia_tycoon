# Web Companion App — Documentation

This directory contains planning and reference documents for the Synaptix / Synaptix web companion app — a React + TypeScript web product built alongside the existing Flutter mobile app.

## Documents

| File | Description |
|---|---|
| [WEB_COMPANION_DEVELOPMENT_PLAN.md](./WEB_COMPANION_DEVELOPMENT_PLAN.md) | Full development plan: strategy, tech stack, feature scope, phase-by-phase build plan, timeline, risks, and post-launch roadmap |

## Key Decisions at a Glance

- **Framework**: React 18 + TypeScript + Vite
- **State**: Zustand (global) + TanStack Query (server state)
- **Styling**: Tailwind CSS + shadcn/ui
- **Payments**: Stripe (direct — no App Store cut)
- **Real-time**: @microsoft/signalr (JS SDK)
- **Timeline**: ~24 weeks with AI-assisted solo development
- **Launch target**: December 2026

## Skill Tree Architecture Decision

The full skill tree planning UI moves to web (the primary interface). The Flutter mobile app is simplified to an **Active Skills Panel** — shows what's unlocked and on cooldown, with a deep link to the web companion for full planning. This reduces Flutter complexity and gives the web app its most compelling anchor feature.

## Scope Philosophy

The web companion is not a port of the mobile app. It serves the same user base at a different moment:
- **Mobile**: quick play, on-the-go sessions
- **Web**: deep engagement — plan, compete, create, manage

Web-exclusive features (leagues, study mode, knowledge graph, build planner) create deliberate reasons to use both platforms.
