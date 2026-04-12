# App Links / Universal Links Deployment Notes

These files are the hosted-domain artifacts for the Synaptix payment return flow.

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
