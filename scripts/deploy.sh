#!/usr/bin/env bash
# Generate public/.well-known/* and deploy public/ to Firebase Hosting (mymultiverse.app).
#
# Required env:
#   ANDROID_SHA256_FINGERPRINT — from MyMultiverseApp APK fingerprint script
#   GOOGLE_APPLICATION_CREDENTIALS — path to Firebase service account JSON
#     OR FIREBASE_SERVICE_ACCOUNT_JSON — inline JSON (written to a temp file)
#
# Optional:
#   IOS_TEAM_ID — Apple Team ID for iOS Universal Links
#   FIREBASE_PROJECT_ID (default mymultiverseapp)
#   FIREBASE_TOOLS_VERSION (default 13.29.1)
#   SKIP_VERIFY=1 — skip post-deploy curl checks

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

ANDROID_SHA256="${ANDROID_SHA256_FINGERPRINT:-${ANDROID_RELEASE_SHA256:-}}"
IOS_TEAM_ID="${IOS_TEAM_ID:-}"
FIREBASE_PROJECT="${FIREBASE_PROJECT_ID:-mymultiverseapp}"
FIREBASE_TOOLS_VERSION="${FIREBASE_TOOLS_VERSION:-13.29.1}"
CREDS_TEMP=""

cleanup() {
  if [[ -n "${CREDS_TEMP}" && -f "${CREDS_TEMP}" ]]; then
    rm -f "${CREDS_TEMP}"
  fi
}
trap cleanup EXIT

if [[ -z "${ANDROID_SHA256}" ]]; then
  echo "ERROR: set ANDROID_SHA256_FINGERPRINT" >&2
  echo "  From MyMultiverseApp: scripts/print-android-apk-fingerprint.sh <apk>" >&2
  exit 1
fi

if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]]; then
  if [[ -n "${FIREBASE_SERVICE_ACCOUNT_JSON:-}" || -n "${FIREBASE_SERVICE_ACCOUNT_JSON_BASE64:-}" ]]; then
    CREDS_TEMP="$(python3 ./scripts/firebase-credentials.py write)"
    export GOOGLE_APPLICATION_CREDENTIALS="${CREDS_TEMP}"
  else
    echo "ERROR: set GOOGLE_APPLICATION_CREDENTIALS, FIREBASE_SERVICE_ACCOUNT_JSON, or FIREBASE_TOKEN" >&2
    exit 1
  fi
fi

chmod +x ./scripts/generate-well-known.sh ./scripts/verify-hosting.sh
export ANDROID_SHA256_FINGERPRINT="${ANDROID_SHA256}"
if [[ -n "${IOS_TEAM_ID}" ]]; then
  export IOS_TEAM_ID
  export VERIFY_IOS_UNIVERSAL_LINKS=1
fi
./scripts/generate-well-known.sh

echo "==> Deploying Firebase Hosting (project ${FIREBASE_PROJECT})"
if [[ -n "${FIREBASE_TOKEN:-}" ]]; then
  export FIREBASE_TOKEN
fi
npx -y "firebase-tools@${FIREBASE_TOOLS_VERSION}" deploy --only hosting --project "${FIREBASE_PROJECT}"

if [[ "${SKIP_VERIFY:-0}" != "1" ]]; then
  ./scripts/verify-hosting.sh
fi

echo "Hosting deploy complete."
