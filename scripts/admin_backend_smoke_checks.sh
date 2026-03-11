#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${ADMIN_API_BASE_URL:-}"
ACCESS_TOKEN="${ADMIN_ACCESS_TOKEN:-}"
REFRESH_TOKEN="${ADMIN_REFRESH_TOKEN:-}"
OTP_CODE="${ADMIN_OTP_CODE:-}"
LOGIN_EMAIL="${ADMIN_LOGIN_EMAIL:-}"
LOGIN_PASSWORD="${ADMIN_LOGIN_PASSWORD:-}"
DRY_RUN="${DRY_RUN:-0}"

if [[ -z "$BASE_URL" ]]; then
  echo "[smoke] ADMIN_API_BASE_URL is required (example: https://api.example.com/api/v1)"
  exit 2
fi

if [[ "$DRY_RUN" == "1" ]]; then
  echo "[smoke] DRY_RUN enabled. Commands will be printed, not executed."
fi

run_curl() {
  local label="$1"
  shift

  echo
  echo "[smoke] >>> $label"

  if [[ "$DRY_RUN" == "1" ]]; then
    printf '[smoke] curl'; printf ' %q' "$@"; echo
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  local status
  status=$(curl -sS -o "$tmp" -w "%{http_code}" "$@") || {
    echo "[smoke] curl failed for $label"
    rm -f "$tmp"
    return 1
  }

  echo "[smoke] HTTP $status"
  head -c 500 "$tmp" || true
  echo
  rm -f "$tmp"

  if [[ "$status" -ge 400 ]]; then
    return 1
  fi
}

auth_header=()
if [[ -n "$ACCESS_TOKEN" ]]; then
  auth_header=(-H "Authorization: Bearer $ACCESS_TOKEN")
fi

# 1) optional login + otp flow
if [[ -n "$LOGIN_EMAIL" && -n "$LOGIN_PASSWORD" ]]; then
  run_curl "POST /admin/auth/login" \
    -X POST "$BASE_URL/admin/auth/login" \
    -H 'Content-Type: application/json' \
    -d "{\"email\":\"$LOGIN_EMAIL\",\"password\":\"$LOGIN_PASSWORD\"${OTP_CODE:+,\"otp\":\"$OTP_CODE\"}}"
fi

# 2) claims endpoint
run_curl "GET /admin/auth/me" \
  "$BASE_URL/admin/auth/me" \
  -H 'Content-Type: application/json' \
  "${auth_header[@]}"

# 3) refresh endpoint contract check
if [[ -n "$REFRESH_TOKEN" ]]; then
  run_curl "POST /admin/auth/refresh" \
    -X POST "$BASE_URL/admin/auth/refresh" \
    -H 'Content-Type: application/json' \
    -d "{\"refreshToken\":\"$REFRESH_TOKEN\",\"refresh_token\":\"$REFRESH_TOKEN\"}"

  run_curl "POST /auth/refresh" \
    -X POST "$BASE_URL/auth/refresh" \
    -H 'Content-Type: application/json' \
    -d "{\"refreshToken\":\"$REFRESH_TOKEN\",\"refresh_token\":\"$REFRESH_TOKEN\"}"
else
  echo "[smoke] Skipping refresh checks (set ADMIN_REFRESH_TOKEN)."
fi

# 4) users/questions list endpoints (read-only)
run_curl "GET /admin/users?page=1&pageSize=1" \
  "$BASE_URL/admin/users?page=1&pageSize=1" \
  -H 'Content-Type: application/json' \
  "${auth_header[@]}"

run_curl "GET /admin/questions?page=1&pageSize=1" \
  "$BASE_URL/admin/questions?page=1&pageSize=1" \
  -H 'Content-Type: application/json' \
  "${auth_header[@]}"

# 5) event queue upload noop payload
run_curl "POST /admin/event-queue/upload" \
  -X POST "$BASE_URL/admin/event-queue/upload" \
  -H 'Content-Type: application/json' \
  "${auth_header[@]}" \
  -d '{"events":[]}'

echo
echo "[smoke] Completed smoke checks."
