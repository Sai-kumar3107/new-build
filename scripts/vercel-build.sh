#!/bin/sh
# Single-project build: exports the Expo web app to frontend/dist.
# The frontend is installed and built in a temp folder so node_modules never sits inside the project
# directory (keeps the Python API function small). Only the finished dist/ is copied back.
# EXPO_PUBLIC_BACKEND_URL is embedded at build time; if unset it defaults to this project's own URL.
set -e
ROOT="$(pwd)"
if [ -z "$EXPO_PUBLIC_BACKEND_URL" ]; then
  if [ "$VERCEL_ENV" = "production" ] && [ -n "$VERCEL_PROJECT_PRODUCTION_URL" ]; then
    export EXPO_PUBLIC_BACKEND_URL="https://$VERCEL_PROJECT_PRODUCTION_URL"
  elif [ -n "$VERCEL_URL" ]; then
    export EXPO_PUBLIC_BACKEND_URL="https://$VERCEL_URL"
  fi
fi
echo "Building web app with EXPO_PUBLIC_BACKEND_URL=${EXPO_PUBLIC_BACKEND_URL:-<not set>}"
BUILD_DIR="$(mktemp -d)"
cp -R frontend/. "$BUILD_DIR"/
cd "$BUILD_DIR"
yarn install
npx expo export --platform web
rm -rf "$ROOT/frontend/dist"
cp -R dist "$ROOT/frontend/dist"
echo "Web build copied to frontend/dist"
