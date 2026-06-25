# mymultiverse.app

Public website for **MyMultiverse** (company) and **Ammò** (product): marketing pages, legal/trust URLs, and App Links hosting on [mymultiverse.app](https://mymultiverse.app).

The mobile app lives in [MyMultiverseApp](https://github.com/Rob971/MyMultiverseApp) (Kotlin Multiplatform). This repo is static HTML/CSS only.

## What is hosted here

| Path | Purpose |
|------|---------|
| `/` | MyMultiverse company home |
| `/about/`, `/work/`, `/contact/` | Company pages |
| `/products/ammo/` | Ammò product page |
| `/privacy/`, `/terms/` | Legal (Play Console, OAuth) |
| `/invite` | App Link fallback for household invites |
| `/.well-known/*` | Android App Links + iOS Universal Links |

## Deploy

**Prerequisites**

1. Firebase project `mymultiverseapp` with Hosting + custom domain `mymultiverse.app`
2. `FIREBASE_SERVICE_ACCOUNT_JSON` (GitHub secret or local file)
3. `ANDROID_SHA256_FINGERPRINT` — from the distributed Ammò APK (see app repo below)

**CI (recommended)**

1. Add GitHub secrets: `FIREBASE_SERVICE_ACCOUNT_JSON`, `ANDROID_SHA256_FINGERPRINT`
2. Actions → **Deploy hosting** → Run workflow  
   Pushes to `main` that touch `public/` also deploy automatically (fingerprint from secret).

**Local**

```bash
# Fingerprint from app repo:
# cd ../MyMultiverseApp && ./scripts/print-android-apk-fingerprint.sh composeApp/build/outputs/apk/debug/composeApp-debug.apk

export ANDROID_SHA256_FINGERPRINT="<colon-free-sha256>"
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
./scripts/deploy.sh
```

## Verify

```bash
./scripts/verify-hosting.sh
```

## App coupling

`public/.well-known/assetlinks.json` must match the **signing certificate** of the Ammò Android app (`app.mymultiverse.kmp`). When you change debug/release keystores:

1. Re-run `print-android-apk-fingerprint.sh` in **MyMultiverseApp**
2. Update `ANDROID_SHA256_FINGERPRINT` secret here (or pass to workflow_dispatch)
3. Redeploy this repo

## Add a product page

1. Copy `public/products/ammo/` → `public/products/<slug>/`
2. Add cards on `public/index.html` and `public/work/index.html`
