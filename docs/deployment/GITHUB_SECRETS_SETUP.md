# GitHub Secrets Setup Guide

This guide explains how to configure GitHub Secrets for CI/CD builds and deployments.

## Overview

GitHub Secrets securely store sensitive configuration values (API keys, certificates, etc.) that are used during CI/CD builds. They are:
- Encrypted at rest
- Only decrypted in GitHub Actions workflows
- Never printed in logs
- Accessible only to repository maintainers

## Setup Instructions

### 1. Navigate to Repository Secrets

1. Go to your GitHub repository
2. Click **Settings** (top navigation)
3. Expand **Secrets and variables** (left sidebar)
4. Click **Actions**

### 2. Add Production Secrets

Add the following secrets for production builds:

#### `PROD_API_URL`
- **Value**: `https://api.synaptixplay.com`
- **Purpose**: Production backend API base URL
- **Used in**: Release builds and production deployments

#### `PROD_STRIPE_KEY`
- **Value**: `pk_live_YOUR_STRIPE_LIVE_KEY`
- **Purpose**: Stripe Identity publishable key for production
- **Source**: Stripe Dashboard → Developers → API Keys
- **Note**: Must start with `pk_live_` for production

#### `PROD_COMPLIANCE_URL`
- **Value**: `https://compliance.synaptixplay.com`
- **Purpose**: Production compliance microservice URL
- **Used in**: Regulatory checks, KYC, COPPA, CCPA enforcement

#### `ANDROID_KEYSTORE_BASE64`
- **Value**: Base64-encoded Android keystore file
- **Purpose**: APK signing certificate for Play Store uploads
- **Generate**: See "Generate Android Keystore" section below
- **Note**: Must be Base64-encoded due to GitHub Secrets format limitations

#### `ANDROID_KEY_PROPERTIES`
- **Value**: Content of `android/key.properties`
- **Purpose**: Keystore configuration for gradle
- **Format**: Plain text properties file

#### `PLAY_STORE_SERVICE_ACCOUNT`
- **Value**: JSON service account key from Google Play Console
- **Purpose**: Authenticates uploads to Google Play
- **Generate**: See "Generate Google Play Service Account" section below

### 3. Add Staging Secrets

Add staging variants for testing before production:

#### `STAGING_API_URL`
- **Value**: `https://staging-api.synaptixplay.com`

#### `STAGING_STRIPE_KEY`
- **Value**: `pk_test_YOUR_STRIPE_TEST_KEY`
- **Note**: Test keys start with `pk_test_`

#### `STAGING_COMPLIANCE_URL`
- **Value**: `https://staging-compliance.synaptixplay.com`

### 4. Add Notification Secrets (Optional)

For build notifications:

#### `SLACK_WEBHOOK_URL`
- **Value**: Your Slack webhook URL
- **Purpose**: Post build success/failure notifications
- **Generate**: See "Setup Slack Notifications" section below

## Generate Android Keystore

### Create Signing Key

```bash
# Generate keystore (one-time, then back it up securely)
keytool -genkey -v -keystore ~/synaptix-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias synaptix_key \
  -storepass YOUR_SECURE_STORE_PASSWORD \
  -keypass YOUR_SECURE_KEY_PASSWORD

# Verify keystore was created
keytool -list -v -keystore ~/synaptix-keystore.jks -storepass YOUR_SECURE_STORE_PASSWORD
```

### Encode to Base64

```bash
# Create Base64 version for GitHub Secrets
base64 ~/synaptix-keystore.jks > keystore-base64.txt

# Copy content and add as ANDROID_KEYSTORE_BASE64 secret
cat keystore-base64.txt | pbcopy  # macOS
# or
cat keystore-base64.txt | xclip -selection clipboard  # Linux
```

### Create key.properties

Create `android/key.properties` (DO NOT COMMIT):

```properties
storeFile=synaptix-keystore.jks
storePassword=YOUR_SECURE_STORE_PASSWORD
keyAlias=synaptix_key
keyPassword=YOUR_SECURE_KEY_PASSWORD
```

### Backup Keystore Securely

```bash
# Encrypt and store in secure location
gpg -c ~/synaptix-keystore.jks  # Creates synaptix-keystore.jks.gpg
# or
openssl enc -aes-256-cbc -salt -in ~/synaptix-keystore.jks \
  -out ~/synaptix-keystore.jks.enc

# Store encrypted file safely (e.g., 1Password, LastPass, etc.)
# Delete original: rm ~/synaptix-keystore.jks
```

## Generate Google Play Service Account

### Create Service Account

1. Go to **Google Play Console** → **Setup** → **API access**
2. Click **Create Service Account**
3. Follow the link to Google Cloud Console
4. Click **Create Service Account**
5. Fill in service account details:
   - Name: `trivia-tycoon-ci`
   - Description: `CI/CD automation for Synaptix`
6. Click **Create and Continue**
7. Grant roles: **Editor**
8. Click **Continue** and **Done**

### Create JSON Key

1. Go to **Service Accounts** in Google Cloud Console
2. Click the created service account
3. Go to **Keys** tab
4. Click **Add Key** → **Create new key**
5. Choose **JSON**
6. Click **Create** (downloads JSON file)

### Add to GitHub Secrets

1. Open the downloaded JSON file
2. Copy entire content
3. Go to GitHub Secrets
4. Add `PLAY_STORE_SERVICE_ACCOUNT` secret
5. Paste the JSON content
6. Save secret

### Verify Service Account Permissions

In Google Play Console:
1. Go **Setup** → **API access**
2. Find the service account
3. Click **Manage permissions**
4. Grant required roles:
   - ✓ Release management
   - ✓ Account access
   - ✓ Monetization
   - ✓ Analytics

## Setup Slack Notifications

### Create Slack Webhook

1. Go to your Slack workspace
2. Open **Manage Apps** or visit https://api.slack.com/apps
3. Click **Create New App** → **From scratch**
4. Name: `Synaptix CI/CD`
5. Workspace: Select your workspace
6. Click **Create App**
7. Go to **Incoming Webhooks**
8. Toggle **Activate Incoming Webhooks** to On
9. Click **Add New Webhook to Workspace**
10. Select channel (e.g., #deployments)
11. Click **Allow**
12. Copy the Webhook URL

### Add to GitHub Secrets

1. Go to GitHub Secrets
2. Add `SLACK_WEBHOOK_URL` secret
3. Paste the webhook URL
4. Save

### Test Webhook

```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message from GitHub Actions"}' \
  YOUR_WEBHOOK_URL
```

## Secrets Checklist

Before running builds, verify all required secrets are set:

```bash
# List all secrets (note: doesn't show values)
gh secret list -R your-username/trivia-tycoon
```

### Required for All Builds
- [ ] `PROD_API_URL`
- [ ] `PROD_STRIPE_KEY`
- [ ] `PROD_COMPLIANCE_URL`

### Required for Google Play Uploads
- [ ] `PLAY_STORE_SERVICE_ACCOUNT`
- [ ] `ANDROID_KEYSTORE_BASE64`
- [ ] `ANDROID_KEY_PROPERTIES`

### Optional
- [ ] `SLACK_WEBHOOK_URL` (for notifications)
- [ ] `STAGING_API_URL`
- [ ] `STAGING_STRIPE_KEY`
- [ ] `STAGING_COMPLIANCE_URL`

## Using Secrets in Workflows

Secrets are accessed in GitHub Actions workflows using `${{ secrets.SECRET_NAME }}` syntax:

```yaml
- name: Build Release APK
  env:
    API_BASE_URL: ${{ secrets.PROD_API_URL }}
    STRIPE_KEY: ${{ secrets.PROD_STRIPE_KEY }}
  run: |
    flutter build apk --release \
      --dart-define=API_BASE_URL="$API_BASE_URL" \
      --dart-define=STRIPE_PUBLISHABLE_KEY="$STRIPE_KEY"
```

## Security Best Practices

1. **Minimize Secret Exposure**
   - Only pass secrets to necessary steps
   - Use environment variables, not command-line arguments
   - Never commit secrets to git

2. **Rotate Secrets Regularly**
   - Update API keys every 90 days
   - Update Stripe keys on provider rotation
   - Rotate Android keystore every 2 years

3. **Audit Secret Access**
   - Review GitHub Actions workflow runs
   - Check logs for accidental secret exposure
   - Monitor for unauthorized access

4. **Separate Environments**
   - Use different secrets for staging vs. production
   - Test with staging secrets before promoting to production
   - Never reuse production credentials across environments

5. **Secure Backup**
   - Keep encrypted backup of Android keystore
   - Store Google Play service account JSON in secure vault
   - Use password manager for API credentials

6. **Restrict Access**
   - Limit secret access to necessary team members
   - Use branch protection rules
   - Require reviews before sensitive builds

## Troubleshooting

### "Secret not found" error

**Cause**: Secret name misspelled or not created

**Solution**:
```bash
# Verify secret exists
gh secret list -R your-username/trivia-tycoon | grep SECRET_NAME

# Recreate if missing
gh secret set SECRET_NAME -R your-username/trivia-tycoon
```

### Build fails with authentication error

**Cause**: Wrong service account credentials or insufficient permissions

**Solution**:
1. Verify service account email in Google Play Console
2. Confirm API access is enabled
3. Check granted roles/permissions
4. Re-download JSON key and update secret

### Slack notifications not working

**Cause**: Invalid webhook URL or webhook revoked

**Solution**:
```bash
# Test webhook manually
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' $SLACK_WEBHOOK_URL

# If fails, regenerate webhook in Slack
```

## Related Documentation

- `BUILD_AND_DEPLOY.md` - Build and deployment instructions
- `ENV_SETUP.md` - Environment configuration guide
- `.github/workflows/release.yml` - CI/CD workflow file
- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Google Play API Documentation](https://developer.android.com/google-play/api)
- [Stripe API Documentation](https://stripe.com/docs/api)
