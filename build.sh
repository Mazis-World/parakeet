#!/bin/sh
set -eu

# Vercel may inherit a PATH that only contains the Flutter SDK, which makes
# bash, git, and other system tools exit 127 (command not found).
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin${PATH:+:$PATH}"

if [ -z "${HOME:-}" ]; then
  HOME="$(pwd)"
  export HOME
fi

echo "Starting Parakeet build in $(pwd)"

FLUTTER_SDK_PATH="${FLUTTER_SDK_PATH:-$HOME/flutter}"

if [ ! -x "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  echo "Installing Flutter into $FLUTTER_SDK_PATH"
  rm -rf "$FLUTTER_SDK_PATH"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_SDK_PATH"
fi

if ! command -v bash >/dev/null 2>&1; then
  echo "bash is required to run the Flutter tool but was not found"
  exit 1
fi

export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release

if [ ! -f build/web/index.html ] || [ ! -f build/web/main.dart.js ]; then
  echo "Flutter did not produce build/web"
  ls -la build 2>/dev/null || echo "build/ does not exist"
  exit 1
fi

# /build/ is gitignored, so publish the compiled site somewhere Vercel can use.
rm -rf dist
mkdir -p dist
cp -a build/web/. dist/

if [ ! -f dist/index.html ] || [ ! -f dist/main.dart.js ]; then
  echo "dist/ is missing compiled web assets"
  ls -la dist || true
  exit 1
fi

echo "Output directory ready: dist"
ls -la dist
