from __future__ import annotations

import json
from pathlib import Path

import requests


PROJECT_ROOT = Path(__file__).resolve().parents[1]
ENV_PATH = PROJECT_ROOT / ".env"


def load_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def post(endpoint: str, api_key: str, payload: dict) -> dict:
    response = requests.post(
        f"https://identitytoolkit.googleapis.com/v1/{endpoint}?key={api_key}",
        json=payload,
        timeout=30,
    )
    data = response.json()
    if response.ok:
        return data
    raise RuntimeError(data.get("error", {}).get("message", response.text))


env = load_env(ENV_PATH)
api_key = env.get("FIREBASE_WEB_API_KEY")
if not api_key:
    raise SystemExit("FIREBASE_WEB_API_KEY is missing from .env")


users = [
    {
        "email": "doctornerves@gmail.com",
        "password": "Passw0rd!",
    },
    {
        "email": "ponnusankar100@gmail.com",
        "password": "Passw0rd!",
    },
    {
        "email": "dr.ukzain@gmail.com",
        "password": "Passw0rd!",
    },
    {
        "email": "drphaniraj1965@gmail.com",
        "password": "Passw0rd!",
    },
]

results: list[dict[str, str]] = []

for entry in users:
    try:
        created = post(
            "accounts:signUp",
            api_key,
            {
                "email": entry["email"],
                "password": entry["password"],
                "returnSecureToken": True,
            },
        )
        results.append(
            {
                "email": entry["email"],
                "action": "created",
                "localId": created.get("localId", ""),
            }
        )
    except RuntimeError as error:
        message = str(error)
        if message == "EMAIL_EXISTS":
            signed_in = post(
                "accounts:signInWithPassword",
                api_key,
                {
                    "email": entry["email"],
                    "password": entry["password"],
                    "returnSecureToken": True,
                },
            )
            results.append(
                {
                    "email": entry["email"],
                    "action": "already_exists_and_password_verified",
                    "localId": signed_in.get("localId", ""),
                }
            )
        else:
            results.append(
                {
                    "email": entry["email"],
                    "action": f"failed:{message}",
                    "localId": "",
                }
            )

test_email = "codex.medicohub.test.20260501@example.com"
deleted_test_user = False
try:
    signed_in = post(
        "accounts:signInWithPassword",
        api_key,
        {
            "email": test_email,
            "password": "Passw0rd!",
            "returnSecureToken": True,
        },
    )
    post(
        "accounts:delete",
        api_key,
        {
            "idToken": signed_in["idToken"],
        },
    )
    deleted_test_user = True
except Exception:
    deleted_test_user = False

print(
    json.dumps(
        {
            "seeded_users": results,
            "deleted_test_user": deleted_test_user,
        },
        indent=2,
    )
)
