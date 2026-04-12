# Frontend Payments Integration Handoff

This document is for the frontend team wiring Tycoon store payments and subscriptions to the current backend implementation.

It covers:

- Stripe one-time purchases
- PayPal one-time purchases
- Stripe subscriptions
- PayPal subscriptions
- Shared store and subscription status endpoints
- Auth, request/response contracts, and error handling
- Backend-managed webhook behavior the frontend should account for

This handoff is based on the current backend surface in `Tycoon.Backend.Api/Features/Store/StoreEndpoints.cs` and shared DTOs in `Tycoon.Shared.Contracts/Dtos/StoreDtos.cs`.

## Base assumptions

- Store routes are rooted at `/store`.
- Most payment creation/capture/subscription routes require `Authorization: Bearer <token>`.
- The backend validates that the authenticated player id from the JWT matches the `playerId` sent in the request body.
- Frontend should always send the logged-in player id, not an arbitrary id.
- Stripe and PayPal are feature-flagged in backend config. If not configured, the frontend will receive `503` errors such as `STRIPE_NOT_READY`, `PAYPAL_NOT_READY`, `STRIPE_PRICE_NOT_CONFIGURED`, or `PAYPAL_SUBSCRIPTION_PLAN_NOT_CONFIGURED`.

## Error envelope

Protected and validation failures use this JSON shape:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable summary",
    "details": {}
  }
}
```

Frontend should branch on `error.code`, not just HTTP status.

Common codes for payment flows:

- `UNAUTHORIZED`: missing or invalid bearer token
- `FORBIDDEN`: `playerId` in body does not match authenticated user, or ownership check failed
- `VALIDATION_ERROR`: missing/invalid request fields
- `NOT_FOUND`: store item or Stripe customer not found
- `PURCHASE_LIMIT`: player exceeded `MaxPerPlayer`
- `STRIPE_NOT_READY`
- `STRIPE_PRICE_NOT_CONFIGURED`
- `STRIPE_SUBSCRIPTION_PLAN_NOT_CONFIGURED`
- `STRIPE_REDIRECT_URL_NOT_CONFIGURED`
- `PAYPAL_NOT_READY`
- `PAYPAL_PRICE_NOT_CONFIGURED`
- `PAYPAL_SUBSCRIPTION_PLAN_NOT_CONFIGURED`
- `PAYPAL_REDIRECT_URL_NOT_CONFIGURED`
- `STORE_DISABLED`
- `PAYMENTS_DISABLED`
- `STRIPE_DISABLED`
- `PAYPAL_DISABLED`

## Route summary

| Purpose | Method | Route | Auth |
|---|---|---|---|
| Read store catalog | `GET` | `/store/catalog` | No |
| Read one catalog item | `GET` | `/store/catalog/{sku}` | No |
| Read store/payment system status | `GET` | `/store/system/status` | No |
| Read player inventory | `GET` | `/store/inventory/{playerId}` | Yes |
| Read current subscription status | `GET` | `/store/subscription/status/{playerId}` | Yes |
| Manual subscription activation fallback | `POST` | `/store/subscription/activate` | Yes |
| Create Stripe subscription Checkout Session | `POST` | `/store/subscription/checkout/session` | Yes |
| Create Stripe Billing Portal session | `POST` | `/store/subscription/portal/session` | Yes |
| Create PayPal subscription | `POST` | `/store/subscription/paypal/create` | Yes |
| Cancel PayPal subscription | `POST` | `/store/subscription/paypal/cancel` | Yes |
| Virtual currency store purchase | `POST` | `/store/purchase` | Yes |
| Create Stripe one-time Checkout Session | `POST` | `/store/payments/checkout/session` | Yes |
| Create PayPal one-time order | `POST` | `/store/payments/paypal/order` | Yes |
| Capture PayPal one-time order | `POST` | `/store/payments/paypal/capture` | Yes |
| Stripe webhook endpoint | `POST` | `/store/payments/webhook` | Provider only |
| PayPal webhook endpoint | `POST` | `/store/payments/paypal/webhook` | Provider only |

## Store/payment availability toggle

The backend now exposes a frontend-readable status endpoint plus admin-only toggle routes.

### Frontend-readable status

`GET /store/system/status`

This endpoint does not require auth and should be used to decide whether to render payment CTAs.

Example response:

```json
{
  "storeEnabled": true,
  "paymentsEnabled": true,
  "stripeConfigured": true,
  "stripeEnabled": true,
  "payPalConfigured": true,
  "payPalEnabled": false,
  "message": "Stripe payments are available. PayPal is unavailable."
}
```

Field meanings:

- `storeEnabled`: global store transaction toggle
- `paymentsEnabled`: global external-payments toggle
- `stripeConfigured`: whether Stripe is enabled in backend configuration
- `stripeEnabled`: effective Stripe availability after config plus runtime toggles are applied
- `payPalConfigured`: whether PayPal is enabled in backend configuration
- `payPalEnabled`: effective PayPal availability after config plus runtime toggles are applied
- `message`: backend-generated status text for UI/debug surfaces

Suggested frontend behavior:

- Call `/store/system/status` on store page load.
- Disable or hide Stripe checkout/subscription buttons when `stripeEnabled = false`.
- Disable or hide PayPal checkout/subscription buttons when `payPalEnabled = false`.
- If `storeEnabled = false`, show store maintenance/unavailable messaging.

### Admin-only toggle routes

These are intended for internal operations tools:

- `GET /admin/store/system/status`
- `PATCH /admin/store/system/status`

Example `PATCH` body:

```json
{
  "storeEnabled": true,
  "paymentsEnabled": true,
  "stripeEnabled": false,
  "payPalEnabled": true
}
```

Example `PATCH` response:

```json
{
  "status": {
    "storeEnabled": true,
    "paymentsEnabled": true,
    "stripeConfigured": true,
    "stripeEnabled": false,
    "payPalConfigured": true,
    "payPalEnabled": true,
    "message": "PayPal payments are available. Stripe is unavailable."
  },
  "updatedAtUtc": "2026-04-12T12:34:56.0000000+00:00"
}
```

## Shared frontend rules

### Authentication

Send bearer auth for every protected route:

```http
Authorization: Bearer <access-token>
Content-Type: application/json
```

### `playerId` ownership rule

For all protected payment routes, the backend compares:

- `playerId` in the request body
- the authenticated player id in JWT `sub` or `nameidentifier`

If they do not match, the backend returns `403 FORBIDDEN`.

### Redirect URLs

Stripe and PayPal create endpoints accept optional frontend URLs. If omitted, the backend falls back to configured defaults.

Frontend can override these per environment:

- Stripe one-time: `successUrl`, `cancelUrl`
- Stripe subscription: `successUrl`, `cancelUrl`
- Stripe billing portal: `returnUrl`
- PayPal one-time: `returnUrl`, `cancelUrl`
- PayPal subscription: `returnUrl`, `cancelUrl`

All must be absolute `http` or `https` URLs.

### Disabled-system feedback

When a commerce action is disabled, the backend returns `503 Service Unavailable` with the standard error envelope and current system status in `error.details`.

Example:

```json
{
  "error": {
    "code": "STRIPE_DISABLED",
    "message": "Stripe payments are currently unavailable.",
    "details": {
      "storeEnabled": true,
      "paymentsEnabled": true,
      "stripeConfigured": true,
      "stripeEnabled": false,
      "payPalConfigured": true,
      "payPalEnabled": true,
      "message": "PayPal payments are available. Stripe is unavailable."
    }
  }
}
```

Recommended frontend behavior:

- Show a friendly unavailable message instead of a generic error toast.
- Refresh `/store/system/status` if the user stays on the page.
- Avoid blind auto-retry loops for `STORE_DISABLED`, `PAYMENTS_DISABLED`, `STRIPE_DISABLED`, and `PAYPAL_DISABLED`.

## Catalog and player state

### `GET /store/catalog`

Optional query:

- `itemType`

Example:

```http
GET /store/catalog?itemType=powerup
```

Response:

```json
{
  "items": [
    {
      "id": "00000000-0000-0000-0000-000000000000",
      "sku": "powerup:skip",
      "name": "Skip Powerup",
      "description": "Skip one question",
      "itemType": "powerup",
      "priceCoins": 0,
      "priceDiamonds": 0,
      "grantQuantity": 1,
      "maxPerPlayer": 0,
      "mediaKey": null,
      "sortOrder": 0
    }
  ],
  "count": 1
}
```

Use this to drive store UI. Payment-specific pricing for Stripe and PayPal is configured in backend settings, not returned directly by this catalog endpoint.

### `GET /store/catalog/{sku}`

Reads a single item.

### `GET /store/inventory/{playerId}`

Returns inventory derived from applied player transactions. Use this to refresh owned cosmetics/powerups after a completed purchase.

### `GET /store/subscription/status/{playerId}`

Returns the latest known subscription state for the player across Stripe, PayPal, or manual activation.

If no subscription exists:

```json
{
  "playerId": "guid",
  "isActive": false,
  "tier": null,
  "billingPeriod": null,
  "activatedAtUtc": null,
  "provider": null,
  "providerSubscriptionId": null,
  "providerCustomerId": null,
  "providerStatus": null,
  "stripeSubscriptionId": null,
  "stripeCustomerId": null,
  "stripeStatus": null,
  "currentPeriodEndUtc": null,
  "cancelAtPeriodEnd": false
}
```

If a subscription exists, expect values like:

- `provider`: `stripe`, `paypal`, or `manual`
- `tier`: `premium` or `elite`
- `billingPeriod`: `monthly` or `seasonal`
- `providerSubscriptionId`
- `providerCustomerId`
- `providerStatus`
- `currentPeriodEndUtc`
- `cancelAtPeriodEnd`

Frontend should use this endpoint after returning from provider approval/cancel routes and when rendering account/subscription management UI.

## Stripe one-time purchases

### Backend flow

1. Frontend calls `POST /store/payments/checkout/session`.
2. Backend validates auth, ownership, SKU, quantity, purchase limits, configured Stripe catalog price, and redirect URLs.
3. Backend returns a hosted Stripe Checkout URL.
4. Frontend redirects the browser/app webview to that URL.
5. Stripe completes payment and calls backend webhook.
6. Backend writes the applied purchase on `checkout.session.completed`.
7. Frontend should refresh inventory and optionally purchase history after the user returns.

### Request

`POST /store/payments/checkout/session`

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "sku": "powerup:skip",
  "quantity": 1,
  "successUrl": "https://app.example.com/store/success?provider=stripe",
  "cancelUrl": "https://app.example.com/store/cancel?provider=stripe"
}
```

### Response

```json
{
  "sessionId": "cs_test_123",
  "checkoutUrl": "https://checkout.stripe.com/c/pay/cs_test_123",
  "currency": "usd",
  "unitAmount": 299,
  "totalAmount": 299,
  "sku": "powerup:skip",
  "quantity": 1,
  "publishableKey": "pk_test_123"
}
```

### Frontend implementation notes

- This flow uses Stripe-hosted Checkout, not a custom card form.
- Redirect directly to `checkoutUrl`.
- `publishableKey` is returned but is not required for a simple full-page redirect flow.
- Do not mark the purchase complete on the frontend only because session creation succeeded.
- Final entitlement is created by the webhook, so after the return page loads, poll or refetch:
  - `GET /store/inventory/{playerId}`
- If you add a success page, show a pending state until inventory refresh reflects the grant.

## PayPal one-time purchases

### Backend flow

1. Frontend calls `POST /store/payments/paypal/order`.
2. Backend returns a PayPal `orderId`, optional `approveUrl`, amount details, and `clientId`.
3. Frontend sends the buyer to PayPal approval.
4. After approval, frontend calls `POST /store/payments/paypal/capture`.
5. Backend captures the order server-side, validates ownership from PayPal `custom_id`, writes the purchase transaction, and returns a `transactionId`.
6. A PayPal webhook may also arrive; backend de-duplicates using deterministic event ids.

### Create order request

`POST /store/payments/paypal/order`

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "sku": "powerup:skip",
  "quantity": 1,
  "returnUrl": "https://app.example.com/store/paypal/return",
  "cancelUrl": "https://app.example.com/store/paypal/cancel"
}
```

### Create order response

```json
{
  "orderId": "5O190127TN364715T",
  "status": "CREATED",
  "approveUrl": "https://www.paypal.com/checkoutnow?token=5O190127TN364715T",
  "currency": "USD",
  "unitAmount": 2.99,
  "totalAmount": 2.99,
  "sku": "powerup:skip",
  "quantity": 1,
  "clientId": "paypal-client-id"
}
```

### Capture request

`POST /store/payments/paypal/capture`

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "orderId": "5O190127TN364715T"
}
```

### Capture response

```json
{
  "orderId": "5O190127TN364715T",
  "status": "COMPLETED",
  "captureId": "3GG279541U471931P",
  "transactionId": "11111111-1111-1111-1111-111111111111"
}
```

### Frontend implementation notes

- The capture step is required. Do not stop after `create`.
- The frontend must call capture only for the authenticated player that created the order.
- After capture succeeds, refresh:
  - `GET /store/inventory/{playerId}`
- If PayPal returns the user before capture is complete, the return page should execute the capture call, then refresh inventory.

## Stripe subscriptions

### Supported values

- `tier`: `premium` or `elite`
- `billingPeriod`: `monthly` or `seasonal`

### Backend flow

1. Frontend calls `POST /store/subscription/checkout/session`.
2. Backend validates auth, ownership, tier, billing period, configured Stripe plan, and redirect URLs.
3. Backend returns a Stripe Checkout Session URL for subscription mode.
4. Frontend redirects the user to Stripe Checkout.
5. Stripe calls backend webhook on completion and subscription lifecycle changes.
6. Frontend refreshes subscription status after the user returns.
7. To manage an existing Stripe subscription, frontend calls `POST /store/subscription/portal/session` and redirects to the returned portal URL.

### Create subscription checkout request

`POST /store/subscription/checkout/session`

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "tier": "premium",
  "billingPeriod": "monthly",
  "successUrl": "https://app.example.com/store/subscription/success",
  "cancelUrl": "https://app.example.com/store/subscription/cancel"
}
```

### Create subscription checkout response

```json
{
  "sessionId": "cs_test_123",
  "checkoutUrl": "https://checkout.stripe.com/c/pay/cs_test_123",
  "priceId": "price_123",
  "tier": "premium",
  "billingPeriod": "monthly",
  "publishableKey": "pk_test_123"
}
```

### Billing portal request

`POST /store/subscription/portal/session`

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "returnUrl": "https://app.example.com/store/subscription"
}
```

### Billing portal response

```json
{
  "sessionId": "bps_123",
  "url": "https://billing.stripe.com/p/session/..."
}
```

### Frontend implementation notes

- The frontend should not attempt to cancel Stripe subscriptions directly through a backend cancel endpoint because one does not currently exist.
- Use the Stripe billing portal session endpoint for self-service management.
- After the buyer returns from Checkout or the billing portal, refresh:
  - `GET /store/subscription/status/{playerId}`
- Treat the subscription as authoritative only after backend status reflects it.

## PayPal subscriptions

### Supported values

- `tier`: `premium` or `elite`
- `billingPeriod`: `monthly` or `seasonal`

### Backend flow

1. Frontend calls `POST /store/subscription/paypal/create`.
2. Backend validates auth, ownership, tier, billing period, configured PayPal plan, and redirect URLs.
3. Backend returns a PayPal subscription id and approval URL.
4. Frontend redirects the buyer to PayPal approval.
5. PayPal webhook updates backend subscription state.
6. Frontend polls/refetches subscription status after the return page loads.
7. To cancel, frontend calls `POST /store/subscription/paypal/cancel`.

### Create PayPal subscription request

`POST /store/subscription/paypal/create`

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "tier": "elite",
  "billingPeriod": "seasonal",
  "returnUrl": "https://app.example.com/store/paypal/subscription/return",
  "cancelUrl": "https://app.example.com/store/paypal/subscription/cancel"
}
```

### Create PayPal subscription response

```json
{
  "subscriptionId": "I-BW452GLLEP1G",
  "status": "APPROVAL_PENDING",
  "approveUrl": "https://www.paypal.com/webapps/billing/subscriptions?ba_token=...",
  "planId": "P-123",
  "tier": "elite",
  "billingPeriod": "seasonal",
  "clientId": "paypal-client-id"
}
```

### Cancel PayPal subscription request

`POST /store/subscription/paypal/cancel`

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "subscriptionId": "I-BW452GLLEP1G",
  "reason": "Canceled by customer"
}
```

### Cancel response

```json
{
  "subscriptionId": "I-BW452GLLEP1G",
  "canceled": true
}
```

### Frontend implementation notes

- There is no dedicated frontend confirmation endpoint after PayPal subscription approval.
- The backend relies on PayPal webhooks to create or update subscription state.
- After return from PayPal, the frontend should poll or refetch:
  - `GET /store/subscription/status/{playerId}`
- Suggested UX:
  - show `Processing subscription...`
  - poll every few seconds for a short window
  - stop when `isActive = true`, or when `providerStatus` reaches a terminal non-active value

## Webhooks

These are backend/provider endpoints. The frontend should not call them directly.

### Stripe webhook

`POST /store/payments/webhook`

Backend handles:

- `checkout.session.completed`
- `customer.subscription.updated`
- `customer.subscription.deleted`

Behavior:

- One-time Stripe purchase grants inventory on successful `checkout.session.completed`
- Stripe subscription checkout writes activation on subscription-mode checkout completion
- Stripe subscription lifecycle updates write latest status receipts
- Duplicate webhook events are ignored idempotently

### PayPal webhook

`POST /store/payments/paypal/webhook`

Backend verifies the PayPal transmission headers and webhook signature before applying changes.

Relevant event families:

- `PAYMENT.CAPTURE.COMPLETED`
- `BILLING.SUBSCRIPTION.*`

Behavior:

- One-time PayPal capture webhooks can apply granted items
- PayPal subscription webhooks update subscription state
- Duplicate webhook events are ignored idempotently

## Recommended frontend flows

### Stripe one-time

1. Load store catalog.
2. User selects item and quantity.
3. Call `POST /store/payments/checkout/session`.
4. Redirect to `checkoutUrl`.
5. On success page, refetch inventory until grant appears.

### PayPal one-time

1. Load store catalog.
2. Call `POST /store/payments/paypal/order`.
3. Redirect to `approveUrl`.
4. On return page, call `POST /store/payments/paypal/capture`.
5. Refetch inventory.

### Stripe subscription

1. Show tier and billing options.
2. Call `POST /store/subscription/checkout/session`.
3. Redirect to `checkoutUrl`.
4. On return page, refetch `GET /store/subscription/status/{playerId}`.
5. For manage/cancel/update payment method, call `POST /store/subscription/portal/session` and redirect to the returned `url`.

### PayPal subscription

1. Show tier and billing options.
2. Call `POST /store/subscription/paypal/create`.
3. Redirect to `approveUrl`.
4. On return page, poll `GET /store/subscription/status/{playerId}`.
5. For cancel, call `POST /store/subscription/paypal/cancel`.

## Important implementation gaps to account for

- Store catalog does not currently expose Stripe or PayPal display prices directly. Backend maps provider prices from config by SKU or plan.
- Stripe success does not mean entitlement has been granted yet; webhook processing is the source of truth.
- PayPal subscription success also depends on webhook processing; the return page should be treated as pending until status updates.
- Stripe subscription management is available through billing portal creation, not a direct cancel endpoint.
- PayPal one-time purchase requires an explicit capture call from frontend after approval return.
- Store and provider availability can change at runtime through admin toggles, so frontend should not hardcode checkout availability.

## Environment/config values frontend should expect backend to supply or require

Backend config currently supports:

- Stripe:
  - `Enabled`
  - `PublishableKey`
  - `SuccessUrl`
  - `CancelUrl`
  - `PortalReturnUrl`
  - configured `Catalog` by SKU
  - configured `SubscriptionPlans` by `tier` + `billingPeriod`
- PayPal:
  - `Enabled`
  - `ClientId`
  - `ReturnUrl`
  - `CancelUrl`
  - configured `Catalog` by SKU
  - configured `SubscriptionPlans` by `tier` + `billingPeriod`

The frontend receives these provider-facing keys opportunistically in create responses:

- Stripe:
  - `publishableKey`
- PayPal:
  - `clientId`

## Minimal frontend checklist

- Centralize bearer token injection for all protected store routes.
- Read `/store/system/status` before rendering payment CTAs.
- Always send the authenticated `playerId`.
- Handle the standard backend error envelope.
- Treat provider redirects as intermediate state, not final state.
- Refresh inventory after one-time purchase completion.
- Refresh subscription status after subscription return/cancel/manage flows.
- Add pending UI for webhook-driven completion states.
- Do not call webhook endpoints from the frontend.

## Suggested QA scenarios

- Stripe one-time purchase success
- Stripe one-time cancel
- Stripe item over purchase limit
- Stripe subscription create and portal open
- PayPal one-time create, approve, capture
- PayPal one-time cancel before capture
- PayPal subscription create and status polling
- PayPal subscription cancel
- Unauthorized and wrong-player-id `403` scenarios
- Provider disabled or unconfigured `503` scenarios
