#!/usr/bin/env bash
set -euo pipefail

echo "Starting Parakeet build..."

FLUTTER_SDK_PATH="${FLUTTER_SDK_PATH:-$HOME/flutter}"
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

if [ ! -x "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  echo "Flutter not found at $FLUTTER_SDK_PATH/bin/flutter"
  exit 1
fi

echo "Flutter version:"
flutter --version

echo "Getting dependencies..."
flutter pub get

echo "Building Flutter web..."
flutter build web --release

if [ ! -f "build/web/index.html" ] || [ ! -f "build/web/main.dart.js" ]; then
  echo "Flutter did not produce build/web"
  ls -la build 2>/dev/null || echo "build/ does not exist"
  exit 1
fi

# /build/ is gitignored. Vercel hides gitignored paths and then reports
# the missing folder using only the last path segment ("web").
# Publish the compiled site to dist/, which is not ignored.
echo "Publishing compiled site to dist/..."
rm -rf dist
mkdir -p dist
cp -a build/web/. dist/

if [ ! -f "dist/index.html" ] || [ ! -f "dist/main.dart.js" ]; then
  echo "dist/ is missing compiled web assets"
  ls -la dist || true
  exit 1
fi

echo "Output directory ready: dist"
ls -la dist | head -20
