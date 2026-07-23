<!-- Backend / API contract PR — client changes that track a backend contract
     (new endpoint, changed DTO shape, auth/route migration). -->

## Why

<!-- The contract change and what motivated it. Link the issue: Closes #___ -->

## Contract

<!-- The exact endpoint(s), method, and payload shape, before → after. -->
- Endpoint(s):
- Request shape:
- Response shape / DTO:
- Auth / gating:

## Client changes

<!-- Clients, services, DTOs, providers updated to match. -->
-

## Backend coordination

- Companion backend branch / PR:
- Verified against backend source? (yes/no — how)
- Backwards compatible with the deployed backend? (yes/no)
- Rollout order (client-first vs backend-first):

## Testing

- [ ] DTO round-trip / contract tests updated
- [ ] `flutter analyze` clean
- [ ] `flutter test` (affected suites) pass
- [ ] Exercised against a running backend where possible
