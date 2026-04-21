# Trivia Tycoon Backend Gap Checklist for Frontend Team
_Date: 2026-04-21_

## Purpose

This document tells the frontend team which backend API dependencies are safe to keep, which ones need deployment verification, which ones still need backend implementation, and which frontend assumptions should be removed.

It is based on the current `TycoonTycoon_Backend` repository state and the four backend handoff documents:
- `notifications_backend_handoff_2026-04-20.md`
- `messaging_backend_handoff_2026-04-20.md`
- `premium_store_backend_handoff_2026-04-20.md`
- `premium_store_growth_plan_2026-04-19.md`

---

## Action Labels

- **KEEP** = endpoint exists in current backend and frontend may depend on it.
- **VERIFY DEPLOYMENT** = endpoint exists in repo, but runtime behavior suggests deployment, gateway, or environment drift.
- **ADD** = backend endpoint is still needed if frontend wants to keep that contract.
- **REMOVE FRONTEND DEPENDENCY** = current backend does not expose this route; frontend should stop depending on it unless backend work is approved.
- **WIRE FRONTEND** = backend exists; Flutter still needs to call it and update state properly.

---

# 1) Backend Files and Route Families

## A. `Tycoon.Backend.Api/Program.cs`

### What to check
This file registers the route families at startup.

### Current status
The backend currently maps these relevant endpoint groups:
- `StoreEndpoints`
- `MessagesEndpoints`
- `PlayerNotificationsEndpoints`
- `MlScoringEndpoints`

### Frontend action
- **KEEP** all client integrations that target these mapped feature groups.
- **VERIFY DEPLOYMENT** if any of these routes return 404 in a live environment, because the repo indicates the groups are registered.

### Why this matters
If a mapped route returns 404 in production, the issue is likely one of:
- old deployment image
- wrong base URL
- gateway/reverse proxy mismatch
- route prefix mismatch
- service not included in deployed build

---

## B. `Tycoon.Backend.Api/Features/Store/StoreEndpoints.cs`

This is the main source of truth for store-related APIs in current `main`.

### Confirmed routes in repo
- `GET /store/catalog`
- `GET /store/catalog/{sku}`
- `GET /store/premium`
- `GET /store/rewards/{playerId}`
- `POST /store/rewards/{playerId}/claim/{rewardId}`
- `GET /store/system/status`
- `GET /store/inventory/{playerId}`
- `GET /store/subscription/status/{playerId}`
- `POST /store/subscription/{playerId}/checkout`
- `POST /store/subscription/{playerId}/paypal-order`

### Endpoint-by-endpoint action

#### `GET /store/catalog`
- **KEEP**
- **VERIFY DEPLOYMENT**
- Frontend may call this.
- Because the repo maps this route, a client-side 404 means the deployed environment is probably behind the repo or misrouted.

#### `GET /store/catalog/{sku}`
- **KEEP**
- Safe for item detail pages, deep links, and single-item fetches.

#### `GET /store/premium`
- **KEEP**
- Use this for premium store screen data.
- This should remain the authoritative premium surface.

#### `GET /store/rewards/{playerId}`
- **KEEP**
- **WIRE FRONTEND**
- Split this into a dedicated player rewards provider instead of relying on static defaults embedded in premium payloads.

#### `POST /store/rewards/{playerId}/claim/{rewardId}`
- **KEEP**
- **WIRE FRONTEND**
- Reward claim button should call this directly.
- On success, frontend should refresh:
  - rewards provider
  - wallet/coin balance provider
  - premium screen state if needed

#### `GET /store/system/status`
- **KEEP**
- Optional for feature flags, outage banners, store availability checks.

#### `GET /store/inventory/{playerId}`
- **KEEP**
- Use for owned cosmetics, purchased boosts, consumables, ad-removal state, and future avatar inventory.

#### `GET /store/subscription/status/{playerId}`
- **KEEP**
- Use as the single source of truth for premium entitlement status.

#### `POST /store/subscription/{playerId}/checkout`
- **KEEP**
- Frontend should use for paid checkout creation if Stripe path is active.

#### `POST /store/subscription/{playerId}/paypal-order`
- **KEEP**
- Frontend should use for PayPal path if enabled.

---

### Missing routes the frontend mentioned

#### `GET /store/hub`
- **REMOVE FRONTEND DEPENDENCY** unless backend team explicitly adds it
- I could not verify this route in the current backend file.
- If product wants a separate “hub” response shape, backend needs to implement it intentionally.

#### `GET /store/offers`
- **REMOVE FRONTEND DEPENDENCY**
- Current premium-store handoff does not require this route for purchase flows.
- Replace usage with:
  - `GET /store/catalog`
  - `GET /store/premium`
  - optional client-side grouping/filtering

#### `GET /store/gifts`
- **REMOVE FRONTEND DEPENDENCY** unless backend team approves this as a separate API
- Current backend file does not expose it.
- If gifts are just catalog subsets or premium reward bundles, frontend should derive them from existing store payloads unless product requires a dedicated endpoint.

---

### Store recommendation for frontend team

#### Use this stable contract
- Store grid / catalog browsing → `GET /store/catalog`
- Premium screen / membership / benefits → `GET /store/premium`
- Reward list → `GET /store/rewards/{playerId}`
- Claim reward → `POST /store/rewards/{playerId}/claim/{rewardId}`
- Wallet and ownership sync → `GET /store/inventory/{playerId}` + coin balance provider
- Premium entitlement → `GET /store/subscription/status/{playerId}`

#### Do not assume these exist
- `/store/hub`
- `/store/offers`
- `/store/gifts`

---

## C. `Tycoon.Backend.Api/Features/Messages/MessagesEndpoints.cs`

### Confirmed direct-message endpoints
- `GET /messages/conversations`
- `POST /messages/direct-conversation`
- `GET /messages/conversations/{conversationId}/messages`
- `POST /messages/conversations/{conversationId}/messages`
- `POST /messages/conversations/{conversationId}/read`
- `GET /messages/unread-count`

### Frontend action
All of these are:
- **KEEP**
- **WIRE FRONTEND** if screens are still in-memory only

### Notes for frontend
- Messaging screens can now be converted from mock/in-memory state to real REST integration.
- The thread history route appears to be a full-history fetch, so frontend should be cautious about large threads until pagination is added.
- If product wants realtime sync, frontend should treat WebSocket or SignalR work as a separate integration layer on top of these REST routes, not a replacement for them.

### Suggested frontend sequence
1. conversation list
2. message history
3. send message
4. mark read
5. unread badge
6. realtime refresh

---

## D. `Tycoon.Backend.Api/Features/PlayerNotifications/PlayerNotificationsEndpoints.cs`

### Confirmed notification endpoints
- `GET /notifications/inbox`
- `GET /notifications/unread-count`
- `POST /notifications/{notificationId}/read`
- `POST /notifications/read-all`
- `DELETE /notifications/{notificationId}`

### Frontend action
All of these are:
- **KEEP**
- **WIRE FRONTEND** where still UI-only or mock-backed

### Notes for frontend
- Player inbox views can be moved to real backend data.
- Notification badge state should be driven from `GET /notifications/unread-count`.
- Read / delete actions should optimistically update local UI, then reconcile with backend.

### Admin note
If there are admin-only notification compose and scheduling screens, those are likely a different backend surface and should not assume these player inbox routes are enough.

---

## E. `Tycoon.Backend.Api/Features/Ml/MlScoringEndpoints.cs`

### Confirmed ML routes
- `POST /ml/churn-risk`
- `POST /ml/match-quality`

### Frontend action
- **KEEP**
- **WIRE FRONTEND** only where product actually needs adaptive UI, retention nudges, or recommendation logic

### Recommendation
`POST /ml/churn-risk` is backend-ready and can be consumed by Flutter if you want:
- retention prompts
- premium upsell timing
- personalized reminder timing
- difficulty/support interventions

If there is no immediate product use, keep this behind a feature flag.

---

# 2) Frontend Dependency Decisions

## Safe to keep immediately
These route dependencies align with the backend as checked:
- `/store/catalog`
- `/store/catalog/{sku}`
- `/store/premium`
- `/store/rewards/{playerId}`
- `/store/rewards/{playerId}/claim/{rewardId}`
- `/store/system/status`
- `/store/inventory/{playerId}`
- `/store/subscription/status/{playerId}`
- `/store/subscription/{playerId}/checkout`
- `/store/subscription/{playerId}/paypal-order`
- `/messages/conversations`
- `/messages/direct-conversation`
- `/messages/conversations/{conversationId}/messages`
- `/messages/conversations/{conversationId}/read`
- `/messages/unread-count`
- `/notifications/inbox`
- `/notifications/unread-count`
- `/notifications/{notificationId}/read`
- `/notifications/read-all`
- `/notifications/{notificationId}`
- `/ml/churn-risk`
- `/ml/match-quality`

## Needs deployment verification
These routes appear in repo and should not 404 if the deployed environment matches `main`:
- `/store/catalog`
- `/store/premium`
- `/messages/*`
- `/notifications/*`
- `/ml/*`

If any still 404:
1. verify backend service version
2. verify gateway path forwarding
3. verify environment base URL
4. verify auth and route-group prefix rules
5. verify the API host is the same one the Flutter app is calling

## Remove or pause from frontend assumptions
Until backend team confirms implementation, the frontend should not require:
- `/store/hub`
- `/store/offers`
- `/store/gifts`

---

# 3) Immediate Frontend Refactor Checklist

## Store
- [ ] Change store screens to rely on `/store/catalog` as the catalog source of truth
- [ ] Keep local asset fallback for resiliency
- [ ] Add a deployment warning/log when remote `/store/catalog` returns 404
- [ ] Split player rewards into a dedicated provider using `GET /store/rewards/{playerId}`
- [ ] Wire reward claim button to `POST /store/rewards/{playerId}/claim/{rewardId}`
- [ ] Refresh coin balance provider after reward claim
- [ ] Refresh premium/rewards UI after reward claim
- [ ] Replace any remaining `/store/hub`, `/store/offers`, `/store/gifts` assumptions unless backend adds them
- [ ] Use `GET /store/subscription/status/{playerId}` for entitlement truth
- [ ] Use `GET /store/inventory/{playerId}` for owned items/cosmetics

## Messaging
- [ ] Replace in-memory conversation list with `GET /messages/conversations`
- [ ] Replace in-memory thread screen with `GET /messages/conversations/{conversationId}/messages`
- [ ] Wire send message to `POST /messages/conversations/{conversationId}/messages`
- [ ] Wire mark-read behavior to `POST /messages/conversations/{conversationId}/read`
- [ ] Use `GET /messages/unread-count` for badges
- [ ] Add polling or realtime refresh layer later

## Notifications
- [ ] Replace mock inbox with `GET /notifications/inbox`
- [ ] Use `GET /notifications/unread-count` for badge state
- [ ] Wire tap-to-read with `POST /notifications/{notificationId}/read`
- [ ] Wire read-all action with `POST /notifications/read-all`
- [ ] Wire delete action with `DELETE /notifications/{notificationId}`

## ML
- [ ] Decide whether churn-risk is needed in current sprint
- [ ] If yes, add a typed client for `POST /ml/churn-risk`
- [ ] Gate any ML-driven UI behind a feature flag

---

# 4) What the Frontend Team Should Escalate to Backend Team

Escalate these only if product requires them as dedicated server contracts:

## Store API additions
- [ ] `GET /store/hub`
- [ ] `GET /store/offers`
- [ ] `GET /store/gifts`

If requested, backend should define:
- payload schema
- caching strategy
- whether they are derived views of catalog/premium or separate business objects
- whether gateway and tests will cover them

## Nice-to-have backend improvements
- [ ] pagination for conversation message history
- [ ] admin notification compose/schedule APIs if not already on a separate admin surface
- [ ] richer gift / cosmetic / avatar purchase contracts if the 3D avatar purchase flow becomes a real feature
- [ ] stronger store feature flags via `/store/system/status`

---

# 5) Bottom Line for Frontend Team

## Green-light integrations
Proceed with these backend areas now:
- messaging
- player notifications
- premium store rewards
- subscription status
- ML scoring only if needed

## Treat as environment issue, not necessarily code issue
- `/store/catalog` returning 404

The repository indicates that route exists. Investigate deployment and routing first.

## Do not block the app on these routes unless backend explicitly adds them
- `/store/hub`
- `/store/offers`
- `/store/gifts`

The safest frontend approach right now is:
- catalog = `/store/catalog`
- premium = `/store/premium`
- rewards = `/store/rewards/{playerId}`
- claims = `POST /store/rewards/{playerId}/claim/{rewardId}`

That contract is the clearest current alignment point between backend and frontend.
