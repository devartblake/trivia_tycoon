# Figma Responsive Dashboard Intake

Use this checklist when a Figma file or MCP tool becomes available for the
responsive dashboard rollout.

## Capture
- Record the Figma file URL, page, frame names, and target device widths.
- Export or inspect desktop, tablet, and mobile frames for the same route.
- Note reusable navigation patterns: persistent rail, drawer, top bar, footer,
  card density, and module order.

## Translate
- Map Figma breakpoints to `AppBreakpoints` before implementation.
- Prefer existing app data/providers and route constants over mock Figma text.
- Treat Figma as visual direction; do not copy generated code directly.

## Validate
- Add or update responsive widget tests for `390`, `900`, `1280`, and `1440`
  widths.
- Check for overflow at `320`, `360`, and browser-resized web widths.
- Run `flutter analyze`, targeted widget tests, and `git diff --check`.
