# App Links / Universal Links Deployment Notes

These files are the hosted-domain artifacts for the Synaptix payment return flow.

## Status update (2026-04-12)

Completed in the app codebase:

- Android manifest intent filters added for hosted payment/subscription return URLs
- iOS associated-domains entitlements wired into the Runner target
- `APP_REDIRECT_BASE_URL` environment support added for return URL generation
- Incoming-link handling added in app startup via `app_links`
- GoRouter payment/subscription return routes added

Still required outside the app repo:

- Host the `assetlinks.json` file on the production domain
- Host the `apple-app-site-association` file on the production domain
- Replace placeholder signing/team identifiers with production values
- Perform a clean native rebuild/reinstall after adding the plugin

Known issue:

- If Android is launched from an old installed APK that predates the `app_links`
  dependency, the app can log:
  `MissingPluginException(No implementation found for method listen on channel com.llfbandit.app_links/events)`.
  Fix by uninstalling the app and doing a full rebuild/reinstall rather than hot restart.

## Domain

This repo is currently wired to:

- `https://app.synaptixgame.com/store/payment-return`
- `https://app.synaptixgame.com/store/subscription-return`

## Android

Host [assetlinks.json](./assetlinks.json) at:

- `https://app.synaptixgame.com/.well-known/assetlinks.json`

Before deploying, replace:

- `YOUR_RELEASE_CERT_SHA256_FINGERPRINT`

with the SHA-256 fingerprint from the Android release signing certificate for
`com.theoreticalmindstech.trivia_tycoon`.

## iOS

Host [apple-app-site-association](./apple-app-site-association) at either:

- `https://app.synaptixgame.com/.well-known/apple-app-site-association`
- or `https://app.synaptixgame.com/apple-app-site-association`

Before deploying, replace:

- `YOUR_TEAM_ID`

in the `appID` value for bundle id `com.theoreticalmindstech.triviaTycoon`.

## App Configuration

The app currently expects this environment variable:

```env
APP_REDIRECT_BASE_URL=https://app.synaptixgame.com
```

This value is now consumed by the frontend return URL builder and should stay in
sync with the hosted verification domain above.
