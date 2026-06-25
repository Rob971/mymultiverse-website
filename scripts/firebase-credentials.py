#!/usr/bin/env python3
"""Write and verify Firebase/Google service account JSON for CI and local deploy."""

from __future__ import annotations

import base64
import json
import os
import sys
import tempfile


def load_service_account_dict() -> dict:
    raw_b64 = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON_BASE64", "").strip()
    raw_json = os.environ.get("FIREBASE_SERVICE_ACCOUNT_JSON", "").strip()

    if raw_b64:
        raw = base64.b64decode(raw_b64).decode("utf-8")
    elif raw_json:
        raw = raw_json
    else:
        raise SystemExit(
            "Set FIREBASE_SERVICE_ACCOUNT_JSON (minified single-line JSON) "
            "or FIREBASE_SERVICE_ACCOUNT_JSON_BASE64."
        )

    try:
        data = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise SystemExit(
            "FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON. "
            "Minify the key file to one line before saving the GitHub secret."
        ) from exc

    for key in ("type", "project_id", "private_key", "client_email"):
        if key not in data:
            raise SystemExit(f"Service account JSON missing required field: {key}")

    return normalize_private_key(data)


def normalize_private_key(data: dict) -> dict:
    key = data.get("private_key", "")
    if "BEGIN PRIVATE KEY" in key and key.count("\n") < 2 and "\\n" in key:
        data = dict(data)
        data["private_key"] = key.replace("\\n", "\n")
    return data


def write_credentials(path: str | None = None) -> str:
    data = load_service_account_dict()
    target = path or os.environ.get("CREDENTIALS_PATH") or tempfile.mktemp(suffix=".json")
    with open(target, "w", encoding="utf-8") as handle:
        json.dump(data, handle)
    return target


def verify() -> None:
    data = load_service_account_dict()
    try:
        from google.auth.transport.requests import Request
        from google.oauth2 import service_account
    except ImportError as exc:
        raise SystemExit(
            "Install google-auth and requests to verify credentials "
            "(pip install google-auth requests)."
        ) from exc

    creds = service_account.Credentials.from_service_account_info(
        data,
        scopes=["https://www.googleapis.com/auth/cloud-platform"],
    )
    creds.refresh(Request())
    print(f"OAuth token OK for {data['client_email']}")


def access_token() -> str:
    data = load_service_account_dict()
    try:
        from google.auth.transport.requests import Request
        from google.oauth2 import service_account
    except ImportError as exc:
        raise SystemExit(
            "Install google-auth and requests to mint access tokens "
            "(pip install google-auth requests)."
        ) from exc

    creds = service_account.Credentials.from_service_account_info(
        data,
        scopes=["https://www.googleapis.com/auth/cloud-platform"],
    )
    creds.refresh(Request())
    return creds.token


def main() -> None:
    command = sys.argv[1] if len(sys.argv) > 1 else "write"
    if command == "write":
        print(write_credentials())
        return
    if command == "verify":
        verify()
        return
    if command == "token":
        print(access_token())
        return
    raise SystemExit(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
