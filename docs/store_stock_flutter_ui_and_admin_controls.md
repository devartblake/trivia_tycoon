# Store Stock System — Flutter UI Widgets + Admin Dashboard Controls

## Purpose

This document defines the frontend implementation plan for:

1. Flutter UI widgets for player-facing stock display and reset timers
2. Admin dashboard controls for stock tuning, reset configuration, visibility rules, and live overrides

It is designed to pair with the backend stock system plan and assumes the backend will expose player-scoped stock-aware store responses.

---

# Part 1 — Flutter UI Widgets for Stock Display + Timers

## Frontend Goals

The store UI should communicate four things clearly for every relevant item:

- how many units the player can still buy or claim
- when the stock resets
- whether the item is limited, one-time, unlimited, or expired
- whether the player is blocked because of stock, entitlement, or availability windows

The UX should create urgency without confusion.

---

## Expected Backend Response Shape

The Flutter UI should prefer a player-scoped endpoint such as:

```http
GET /store/catalog/{playerId}
```

Each returned item should already be personalized.

Example response payload:

```json
{
  "sku": "powerup_double_points",
  "title": "Double Points",
  "description": "Doubles your score for one round.",
  "type": "powerup",
  "price": 250,
  "currency": "coins",
  "stock": {
    "policyType": "per_user",
    "maxQuantity": 3,
    "usedQuantity": 1,
    "remainingQuantity": 2,
    "resetInterval": "daily",
    "lastResetAt": "2026-04-22T00:00:00Z",
    "nextResetAt": "2026-04-23T00:00:00Z",
    "isSoldOut": false,
    "isUnlimited": false,
    "isOneTimePurchase": false,
    "expiresAt": null
  },
  "availability": {
    "isVisible": true,
    "isPurchasable": true,
    "requiresPremium": false,
    "isFlashSale": false,
    "saleEndsAt": null
  }
}
```

The UI should avoid re-deriving business logic if the server already provides it.

---

## Recommended Flutter File Structure

```text
lib/
  features/store/
    models/
      store_stock_ui_model.dart
      stock_badge_state.dart
    services/
      store_stock_timer_service.dart
    providers/
      player_store_catalog_provider.dart
      stock_countdown_provider.dart
      stock_admin_preview_provider.dart
    widgets/
      stock_badge.dart
      stock_reset_timer.dart
      stock_meter_bar.dart
      store_item_stock_panel.dart
      store_purchase_button.dart
      limited_offer_chip.dart
      sold_out_overlay.dart
      stock_status_row.dart
      reward_claim_status_card.dart
    screens/
      store_hub_screen.dart
      premium_store_screen.dart
      gifts_screen.dart
      offers_screen.dart
```

---

## Widget Set

## 1. `StockBadge`

### Purpose
A compact badge showing the item’s current stock state.

### States
- `Unlimited`
- `1 Left`
- `2 Left`
- `Sold Out`
- `One-Time`
- `Claimed`
- `Resets Daily`
- `Ends Soon`

### Suggested Use
- top-right corner of a store card
- inline beside the item title
- overlay for mobile compact mode

### Example UI labels
- `2 left`
- `Sold out`
- `1 claim today`
- `Weekly item`
- `Owned`

### Widget API

```dart
class StockBadge extends StatelessWidget {
  final String label;
  final bool isUrgent;
  final bool isSoldOut;
  final bool isUnlimited;
  final bool isOwned;

  const StockBadge({
    super.key,
    required this.label,
    this.isUrgent = false,
    this.isSoldOut = false,
    this.isUnlimited = false,
    this.isOwned = false,
  });
}
```

### Behavior Notes
- sold-out state should visually dominate
- urgent state should be used when remaining quantity is 1 or the reset/expiry is within a short threshold
- owned state should replace stock language for one-time cosmetics already purchased

---

## 2. `StockResetTimer`

### Purpose
A live countdown showing when stock resets or when a flash sale expires.

### Display Variants
- `Resets in 5h 12m`
- `Refreshes tomorrow`
- `Ends in 00:17:24`
- `Expired`

### Widget API

```dart
class StockResetTimer extends ConsumerWidget {
  final DateTime? nextResetAt;
  final DateTime? expiresAt;
  final bool preferExpiry;
  final TextStyle? style;

  const StockResetTimer({
    super.key,
    this.nextResetAt,
    this.expiresAt,
    this.preferExpiry = false,
    this.style,
  });
}
```

### Timing Strategy
Use a shared ticker or `StreamProvider` rather than a `Timer.periodic` per card.

Recommended approach:
- one app-wide timer tick every second for visible countdowns
- card widgets compute remaining duration from the shared `DateTime.now()` provider

### Provider Example

```dart
final stockCountdownProvider = StreamProvider<DateTime>((ref) async* {
  while (true) {
    yield DateTime.now().toUtc();
    await Future.delayed(const Duration(seconds: 1));
  }
});
```

### UX Rules
- if more than 24 hours remain, show `Xd Yh`
- if less than 24 hours remain, show `Hh Mm`
- if less than 1 hour remains, show `Mm Ss`
- if expired, trigger refresh of the catalog provider

---

## 3. `StockMeterBar`

### Purpose
A visual meter showing remaining stock compared with total stock.

### Best For
- power-ups
- daily claims
- limited bundles
- event items

### Example
- `2 / 5 remaining`
- progress bar filled to 40%

### Widget API

```dart
class StockMeterBar extends StatelessWidget {
  final int remaining;
  final int max;
  final String? caption;

  const StockMeterBar({
    super.key,
    required this.remaining,
    required this.max,
    this.caption,
  });
}
```

### Rules
- hide for unlimited items
- hide for owned one-time items
- show urgency when remaining is 1 or 0

---

## 4. `StoreItemStockPanel`

### Purpose
A composed block that centralizes all stock information for a single store item.

### Contains
- `StockBadge`
- `StockMeterBar`
- `StockResetTimer`
- purchase eligibility note
- premium or requirement lock note

### Widget API

```dart
class StoreItemStockPanel extends StatelessWidget {
  final PlayerStoreItem item;

  const StoreItemStockPanel({
    super.key,
    required this.item,
  });
}
```

### Example Layout
- badge row
- stock meter
- reset timer line
- optional restriction note

### Restriction Notes
Examples:
- `Premium required`
- `Already owned`
- `Daily limit reached`
- `Available at level 8`
- `Offer ends tonight`

---

## 5. `StorePurchaseButton`

### Purpose
A purchase/claim CTA that reacts to stock state automatically.

### States
- `Buy`
- `Claim`
- `Claimed`
- `Sold Out`
- `Owned`
- `Premium Only`
- `Unavailable`

### Widget API

```dart
class StorePurchaseButton extends ConsumerWidget {
  final PlayerStoreItem item;
  final Future<void> Function()? onPressed;

  const StorePurchaseButton({
    super.key,
    required this.item,
    this.onPressed,
  });
}
```

### Disable Conditions
- remaining quantity is 0
- item expired
- item hidden from purchase logic
- one-time item already owned
- premium entitlement missing
- backend returned not purchasable

### UX Notes
- use optimistic loading carefully
- after successful purchase, refresh item stock and wallet balance together

---

## 6. `LimitedOfferChip`

### Purpose
Visually call out rotating inventory, seasonal promotions, flash offers, and expiring premium bundles.

### Labels
- `Flash Sale`
- `Weekend Offer`
- `Seasonal`
- `Limited Bundle`

Use this separately from stock count to distinguish scarcity from promotion.

---

## 7. `SoldOutOverlay`

### Purpose
A visual overlay for cards that should remain visible but cannot currently be bought.

### Recommended Behavior
- grey or dim the card
- keep title and item art visible
- keep timer visible if stock will reset soon
- show `Sold Out` or `Resets Tomorrow`

Do not fully remove sold-out items if they are meant to create urgency or habit loops.

---

## 8. `RewardClaimStatusCard`

### Purpose
A specialized widget for free claim or ad-reward flows.

### Example Uses
- daily check-in reward
- watch-ad reward
- streak reward
- event token reward

### Display Elements
- reward title
- current claim count
- remaining daily claims
- next reset time
- claim button

---

# Screen-Level Behavior

## Store Hub

### Show
- mixed categories
- featured items
- limited offers
- daily claim section
- stock-aware cards everywhere

### Recommended Card Treatment
- featured rows should show stock badge and timer
- standard catalog cards should show stock badge and purchase state

---

## Premium Store

### Show
- premium subscription tile
- premium-only bundles
- rotating VIP cosmetics
- exclusive offer timers

### Extra States
- `Included in Premium`
- `Premium Exclusive`
- `Already Subscribed`

---

## Gifts Screen

### Show
- claimable gifts
- event gifts
- social gifts
- limited daily gift sends and receives

### Add
- daily send/receive stock meter if gifts are capped per day

---

## Offers Screen

### Show
- flash sale items
- discounted bundles
- time-limited boosts

### Priority UI
- expiry timer should be more prominent than reset timer
- show original and discounted price if present

---

# Riverpod State Management Plan

## Recommended Providers

### 1. `playerStoreCatalogProvider`
Fetches player-scoped catalog.

```dart
final playerStoreCatalogProvider = FutureProvider.family<List<PlayerStoreItem>, String>((ref, playerId) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.fetchPlayerCatalog(playerId);
});
```

### 2. `playerRewardsProvider`
Fetches reward-specific stock and claims.

```dart
final playerRewardsProvider = FutureProvider.family<List<PlayerRewardItem>, String>((ref, playerId) async {
  final repo = ref.watch(storeRepositoryProvider);
  return repo.fetchPlayerRewards(playerId);
});
```

### 3. `stockCountdownProvider`
Provides shared clock ticks.

### 4. `walletBalanceProvider`
Refresh after purchase or claim.

### 5. `premiumStatusProvider`
Controls entitlement states.

---

# Client Refresh Rules

## Refresh on These Events
- app resumes
- store screen enters foreground
- successful purchase
- successful reward claim
- countdown crosses expiry or reset boundary
- admin preview mode toggled

## Avoid
- polling each item individually
- separate timers per card
- keeping stale countdowns after expiration

---

# Error and Edge Cases

## Edge Case Handling

### 1. Item sold out between render and purchase
- button tap sends request
- server rejects with stock error
- client refreshes item state
- toast: `This item just sold out.`

### 2. Reset passed while screen open
- countdown reaches zero
- invalidate catalog provider
- refetch automatically

### 3. One-time item already owned
- replace purchase button with `Owned`
- optionally move card to owned section

### 4. Flash sale expired
- hide from offers page after refresh
- or show disabled card briefly with `Expired`

### 5. Premium requirement not met
- lock icon + CTA to upgrade

---

# Sample Frontend Model

```dart
class PlayerStoreItem {
  final String sku;
  final String title;
  final String description;
  final String type;
  final int price;
  final String currency;
  final StoreStockState stock;
  final StoreAvailabilityState availability;

  const PlayerStoreItem({
    required this.sku,
    required this.title,
    required this.description,
    required this.type,
    required this.price,
    required this.currency,
    required this.stock,
    required this.availability,
  });
}

class StoreStockState {
  final String policyType;
  final int? maxQuantity;
  final int usedQuantity;
  final int? remainingQuantity;
  final String? resetInterval;
  final DateTime? lastResetAt;
  final DateTime? nextResetAt;
  final bool isSoldOut;
  final bool isUnlimited;
  final bool isOneTimePurchase;
  final DateTime? expiresAt;

  const StoreStockState({
    required this.policyType,
    required this.maxQuantity,
    required this.usedQuantity,
    required this.remainingQuantity,
    required this.resetInterval,
    required this.lastResetAt,
    required this.nextResetAt,
    required this.isSoldOut,
    required this.isUnlimited,
    required this.isOneTimePurchase,
    required this.expiresAt,
  });
}
```

---

# Part 2 — Admin Dashboard Controls for Stock Tuning

## Admin Goals

The admin dashboard needs to support live control over:

- stock policy per item
- reset intervals
- visibility windows
- per-user caps
- flash sale timing
- premium gating
- dynamic overrides for special cohorts or campaigns

It should be safe, auditable, and previewable.

---

## Recommended Admin Areas

```text
AdminDashboard
  ├── Store Inventory Control
  ├── Stock Policy Editor
  ├── Offer Rotation Manager
  ├── Reward Limits Manager
  ├── Flash Sale Scheduler
  ├── Premium Gating Manager
  ├── User Override Inspector
  └── Stock Analytics Panel
```

---

## Admin Control 1 — Stock Policy Editor

### Purpose
Edit the default stock behavior for a catalog SKU.

### Fields
- SKU
- item title
- item type
- stock policy type
- max quantity per user
- reset interval
- one-time purchase flag
- unlimited flag
- expiry date
- premium-only toggle
- minimum player level
- visible toggle
- purchasable toggle

### UI Components
- segmented buttons for stock policy type
- numeric field for max quantity
- dropdown for interval
- datetime picker for expiry
- switches for visibility rules

### Supported Policy Types
- unlimited
- per_user
- one_time_purchase
- time_limited
- event_limited

### Validation Rules
- unlimited cannot also have max quantity
- one-time purchase should clamp max quantity to 1
- expired items cannot be marked active without changing expiry

---

## Admin Control 2 — Reward Limits Manager

### Purpose
Tune daily claim rewards without editing catalog definitions manually.

### Editable Fields
- reward id
- max claims per interval
- interval
- coin/gem payout
- ad requirement toggle
- streak requirement
- active/inactive status

### Example Use Cases
- increase `watch-ad` from 5 claims/day to 8
- reduce daily check-in payout during an event cooldown
- enable double-claim weekend

---

## Admin Control 3 — Offer Rotation Manager

### Purpose
Manage rotating offers and featured inventory windows.

### Actions
- assign SKUs to offer groups
- define start and end windows
- control priority ordering
- mark offer as featured
- set per-user quantity overrides during campaign

### Example Sections
- Today’s Featured
- Weekend Flash Sale
- Seasonal Cosmetics
- Premium Spotlight

---

## Admin Control 4 — Flash Sale Scheduler

### Purpose
Create limited-time sale windows with purchase caps and expiration timers.

### Fields
- sale id
- title
- linked sku
- start time
- end time
- purchase cap per user
- discount amount or percent
- eligible cohort
- active flag

### Safety Controls
- conflict warning for overlapping sales on same SKU
- preview countdown before publishing
- automatic unpublish at end time

---

## Admin Control 5 — Premium Gating Manager

### Purpose
Tune premium-only behavior for premium bundles, bonus claims, and cosmetics.

### Fields
- requires premium
- premium bonus stock multiplier
- included with subscription
- visible to non-premium users as locked item
- upgrade CTA label

### Example Use Cases
- premium players get 2x daily claim cap
- premium-exclusive avatar bundle is visible but locked
- premium subscribers see exclusive rotating items

---

## Admin Control 6 — User Override Inspector

### Purpose
Inspect and override stock rules for a specific player, cohort, or experiment.

### Use Cases
- support compensation
- churn-risk rescue offers
- QA testing
- creator/influencer promotional grants
- VIP user override

### Fields
- player id
- sku
- override max quantity
- override expiry
- grant free item
- reset stock now
- notes/reason code

### Guardrails
- require admin role or ops key
- write audit log for every override
- show expiration of override

---

## Admin Control 7 — Stock Analytics Panel

### Purpose
Give operators visibility into inventory behavior and offer performance.

### Metrics
- purchases per SKU
- sold-out rate
- reset usage rate
- average time-to-sellout
- daily reward claim volume
- unclaimed inventory by category
- premium conversion from locked items
- flash sale conversion

### Filters
- date range
- category
- item type
- premium vs non-premium
- region
- cohort

### Visualization Ideas
- top-selling items
- most frequently sold-out items
- least effective offers
- claims by reset interval

---

# Admin Flutter Widget Recommendations

## Suggested File Structure

```text
lib/
  features/admin/store/
    models/
      stock_policy_form_model.dart
      stock_override_form_model.dart
    providers/
      admin_store_policy_provider.dart
      admin_store_analytics_provider.dart
      admin_flash_sale_provider.dart
    widgets/
      stock_policy_editor_card.dart
      stock_interval_selector.dart
      stock_override_panel.dart
      stock_preview_card.dart
      flash_sale_scheduler_form.dart
      reward_limit_editor.dart
      premium_gating_panel.dart
      stock_analytics_summary.dart
    screens/
      admin_store_inventory_screen.dart
      admin_stock_policy_screen.dart
      admin_flash_sales_screen.dart
      admin_reward_limits_screen.dart
      admin_stock_analytics_screen.dart
```

---

## Example Admin Widgets

### `StockPolicyEditorCard`
Used to edit default stock policy for an item.

### `StockIntervalSelector`
Dropdown or segmented control for:
- hourly
- daily
- weekly
- seasonal
- none

### `StockOverridePanel`
Used for user-specific or cohort-specific overrides.

### `StockPreviewCard`
Renders the same card the player sees, but in preview mode using draft policy values.

### `FlashSaleSchedulerForm`
Form to create, edit, and schedule flash sale windows.

### `RewardLimitEditor`
Simple panel to adjust daily reward caps.

### `PremiumGatingPanel`
Edit premium visibility and bonus rules.

---

# Admin Preview Mode

This is strongly recommended.

## Purpose
Let admins preview how an item will appear to a player before publishing stock changes.

## Preview Inputs
- player tier
- premium status
- level
- locale
- current stock usage
- churn-risk segment
- event eligibility

## Output
- player card preview
- button state preview
- timer preview
- visibility result

This reduces mistakes when tuning live offers.

---

# Backend Endpoints the Admin UI Will Need

Recommended admin APIs:

```http
GET    /admin/store/policies
GET    /admin/store/policies/{sku}
PUT    /admin/store/policies/{sku}
POST   /admin/store/policies/{sku}/reset
GET    /admin/store/overrides/{playerId}
POST   /admin/store/overrides
DELETE /admin/store/overrides/{overrideId}
GET    /admin/store/flash-sales
POST   /admin/store/flash-sales
PUT    /admin/store/flash-sales/{saleId}
DELETE /admin/store/flash-sales/{saleId}
GET    /admin/store/reward-limits
PUT    /admin/store/reward-limits/{rewardId}
GET    /admin/store/analytics/summary
```

These should sit behind admin auth and ops-key protection where appropriate.

---

# Rollout Plan

## Phase 1 — Player UI Basics
- implement `StockBadge`
- implement `StockResetTimer`
- implement `StorePurchaseButton`
- wire `playerStoreCatalogProvider`
- refresh store on purchase and claim

## Phase 2 — Rich Store Cards
- add `StockMeterBar`
- add `StoreItemStockPanel`
- add `SoldOutOverlay`
- add `LimitedOfferChip`

## Phase 3 — Reward and Offer Specialization
- add `RewardClaimStatusCard`
- specialize Offers and Gifts pages
- show expiry-first countdown for flash sales

## Phase 4 — Admin Controls
- build `StockPolicyEditorCard`
- build `RewardLimitEditor`
- build `FlashSaleSchedulerForm`
- add analytics summary

## Phase 5 — Advanced Controls
- add user override inspector
- add preview mode
- add cohort testing support

---

# Final Recommendation

On the player side, stock UI should feel lightweight and obvious:
- clear stock count
- clear reset time
- clear purchase state

On the admin side, stock tuning should feel controlled and auditable:
- easy to edit
- hard to break
- easy to preview
- easy to monitor

The most important implementation rule is this:

**Do not let Flutter own the stock logic. Let Flutter render server-derived stock state.**

That keeps timers visually live while ensuring the purchase truth stays on the backend.

