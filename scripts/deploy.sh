#!/usr/bin/env bash
# Generate public/.well-known/* and deploy public/ to Firebase Hosting (mymultiverse.app).
#
# Required env:
#   ANDROID_SHA256_FINGERPRINT — from MyMultiverseApp APK fingerprint script
#
# Auth (one of):
#   FIREBASE_TOKEN — from `firebase login:ci`
#   FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 — mints a short-lived token
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

if [[ -z "${ANDROID_SHA256}" ]]; then
  echo "ERROR: set ANDROID_SHA256_FINGERPRINT" >&2
  echo "  From MyMultiverseApp: scripts/print-android-apk-fingerprint.sh <apk>" >&2
  exit 1
fi

chmod +x ./scripts/generate-well-known.sh ./scripts/verify-hosting.sh
export ANDROID_SHA256_FINGERPRINT="${ANDROID_SHA256}"
if [[ -n "${IOS_TEAM_ID}" ]]; then
  export IOS_TEAM_ID
  export VERIFY_IOS_UNIVERSAL_LINKS=1
fi
./scripts/generate-well-known.sh

echo "==> Deploying Firebase Hosting (project ${FIREBASE_PROJECT})"
firebase_token="${FIREBASE_TOKEN:-}"
if [[ -z "${firebase_token}" && ( -n "${FIREBASE_SERVICE_ACCOUNT_JSON:-}" || -n "${FIREBASE_SERVICE_ACCOUNT_JSON_BASE64:-}" ) ]]; then
  pip install -q google-auth requests
  firebase_token="$(python3 ./scripts/firebase-credentials.py token)"
fi
if [[ -z "${firebase_token}" ]]; then
  echo "ERROR: set FIREBASE_TOKEN or a service account JSON secret" >&2
  exit 1
fi

npx -y "firebase-tools@${FIREBASE_TOOLS_VERSION}" deploy \
  --only hosting \
  --project "${FIREBASE_PROJECT}" \
  --token "${firebase_token}"

if [[ "${SKIP_VERIFY:-0}" != "1" ]]; then
  ./scripts/verify-hosting.sh
fi

echo "Hosting deploy complete."
