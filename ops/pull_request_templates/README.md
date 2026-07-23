# Pull request templates

Type-specific PR body templates for `trivia_tycoon`. Pick the one that matches
your change and fill it in — every template keeps the same spine (**Why → What
changed → Testing**) plus a couple of type-specific sections.

| File | Use for |
|------|---------|
| `default.md` | Anything that doesn't fit a specific type, or a mixed PR. |
| `feature.md` | New user-facing capability or system (UI + providers + services + routes). |
| `bugfix.md` | Correcting a defect — crash, wrong behavior, regression. Leads with symptom → root cause → fix. |
| `backend_api.md` | Client changes that track a backend contract (new endpoint, DTO shape, auth/route migration). |
| `chore_ci.md` | Tests, CI workflows, scripts, dependency bumps, behavior-preserving refactors. |
| `docs.md` | Documentation, status/triage notes, plans, changelog-only changes. |

## How to use

- **Manually:** copy the relevant file's contents into the PR description and
  fill in the placeholders (the `<!-- comments -->` are prompts — delete them).

## Making them active on GitHub (optional)

GitHub only auto-discovers PR templates in `.github/`, the repo root, or
`docs/` — **not** in `ops/`. To surface these in the PR-create UI, mirror them:

- Put the general one at `.github/pull_request_template.md` (used by default).
- Put the type-specific ones in `.github/PULL_REQUEST_TEMPLATE/` (note the
  singular, upper-case directory name). GitHub then lets you pick one by
  appending a query param to the compare URL, e.g.
  `?template=bugfix.md`.

Keep this `ops/` copy as the source of truth and copy changes into `.github/`,
or replace the `.github/` files with symlinks to these.
