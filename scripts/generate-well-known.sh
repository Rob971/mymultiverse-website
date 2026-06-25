#!/usr/bin/env bash
# Generate public/.well-known/* for mymultiverse.app App Links / Universal Links.
#
# Required env:
#   ANDROID_SHA256_FINGERPRINT — colon-free SHA-256 from the Ammò APK
#     (MyMultiverseApp: scripts/print-android-apk-fingerprint.sh)
#
# Optional:
#   IOS_TEAM_ID — Apple Team ID for iOS Universal Links
#   ANDROID_PACKAGE_NAME (default app.mymultiverse.kmp)
#   IOS_BUNDLE_ID (default app.mymultiverse.kmp)

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${ROOT_DIR}/public/.well-known"

ANDROID_SHA256="${ANDROID_SHA256_FINGERPRINT:-${ANDROID_RELEASE_SHA256:-}}"
IOS_TEAM_ID="${IOS_TEAM_ID:-}"
ANDROID_PACKAGE="${ANDROID_PACKAGE_NAME:-app.mymultiverse.kmp}"
IOS_BUNDLE="${IOS_BUNDLE_ID:-app.mymultiverse.kmp}"

if [[ -z "${ANDROID_SHA256}" ]]; then
  echo "ERROR: set ANDROID_SHA256_FINGERPRINT" >&2
  exit 1
fi

ANDROID_SHA256="${ANDROID_SHA256//:/}"
ANDROID_SHA256="$(echo "${ANDROID_SHA256}" | tr '[:lower:]' '[:upper:]')"

mkdir -p "${OUT_DIR}"

cat > "${OUT_DIR}/assetlinks.json" <<EOF
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "${ANDROID_PACKAGE}",
      "sha256_cert_fingerprints": [
        "${ANDROID_SHA256}"
      ]
    }
  }
]
EOF

echo "Wrote ${OUT_DIR}/assetlinks.json"

if [[ -n "${IOS_TEAM_ID}" ]]; then
  cat > "${OUT_DIR}/apple-app-site-association" <<EOF
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "${IOS_TEAM_ID}.${IOS_BUNDLE}",
        "paths": ["/invite", "/invite/*"]
      }
    ]
  }
}
EOF
  echo "Wrote ${OUT_DIR}/apple-app-site-association"
else
  rm -f "${OUT_DIR}/apple-app-site-association"
  echo "Skipped apple-app-site-association (set IOS_TEAM_ID for iOS)"
fi
