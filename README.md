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
2. GitHub secret for Firebase auth (see **GitHub secrets** below)
3. `ANDROID_SHA256_FINGERPRINT` — from the distributed Ammò APK (see app repo below)

### GitHub secrets (important)

Refreshing the key is not enough if the secret is pasted incorrectly. GitHub often corrupts **multiline** JSON.

**Recommended — minified JSON**

```bash
python3 -c "import json; print(json.dumps(json.load(open('mymultiverseapp-firebase-adminsdk.json'))))"
```

Copy the **single line** output into `FIREBASE_SERVICE_ACCOUNT_JSON` (no surrounding quotes).

**Alternative — base64**

```bash
base64 -i mymultiverseapp-firebase-adminsdk.json | tr -d '\n'
```

Save as secret `FIREBASE_SERVICE_ACCOUNT_JSON_BASE64`.

**Alternative — CI token**

```bash
firebase login:ci
```

Save the token as `FIREBASE_TOKEN` (works for hosting deploy only).

The deploy workflow runs `python3 scripts/firebase-credentials.py verify` before deploy. If that step fails, the secret is still malformed or the key is revoked.

Use the **same** secret value in **MyMultiverseApp** and **mymultiverse-website**.

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
