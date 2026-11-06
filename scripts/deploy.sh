#!/bin/sh
# One-command deploy of the whole project (web app + API) to ONE Vercel project.
# Run from the project root:  sh scripts/deploy.sh
set -e
cd "$(dirname "$0")/.."

command -v node >/dev/null 2>&1 || { echo "Install Node.js 22+ first: https://nodejs.org"; exit 1; }
command -v vercel >/dev/null 2>&1 || npm install --global vercel@latest

sh scripts/preflight.sh

echo "== Vercel login (opens a browser if needed) =="
vercel whoami >/dev/null 2>&1 || vercel login

echo "== Linking this folder to a Vercel project (accept the defaults, Framework: Other) =="
[ -f .vercel/project.json ] || vercel link

if [ -z "$SUPABASE_DB_URL" ]; then
  echo "Paste your Supabase TRANSACTION POOLER connection string (port 6543, starts with postgresql://):"
  read -r SUPABASE_DB_URL
fi
case "$SUPABASE_DB_URL" in postgresql://*|postgres://*) ;; *) echo "SUPABASE_DB_URL must start with postgresql://"; exit 1;; esac

JWT_SECRET="${JWT_SECRET:-$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")}"

setenv() { # name value  (replaces an existing value)
  vercel env rm "$1" production --yes >/dev/null 2>&1 || true
  printf '%s' "$2" | vercel env add "$1" production >/dev/null
  echo "set $1"
}
setenv SUPABASE_DB_URL "$SUPABASE_DB_URL"
setenv JWT_SECRET "$JWT_SECRET"
[ -n "$AI_API_KEY" ]  && setenv AI_API_KEY "$AI_API_KEY"
[ -n "$AI_MODEL" ]    && setenv AI_MODEL "$AI_MODEL"
[ -n "$AI_BASE_URL" ] && setenv AI_BASE_URL "$AI_BASE_URL"

echo "== Deploying to production =="
vercel deploy --prod
echo
echo "Done. Open <your-url>/api/health  -> should show {\"status\":\"ok\",\"db\":true,...}"
echo "(Run backend/schema.sql once in the Supabase SQL Editor if db is false or login fails.)"
