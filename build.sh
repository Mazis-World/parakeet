#!/bin/sh
set -eu

# Vercel may inherit a PATH that only contains the Flutter SDK.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin${PATH:+:$PATH}"

if [ -z "${HOME:-}" ]; then
  HOME="$(pwd)"
  export HOME
fi

START_DIR=$(pwd)
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
cd "$SCRIPT_DIR"

echo "Vercel working directory: $START_DIR"
echo "Flutter project directory: $SCRIPT_DIR"

git config --global --add safe.directory "$SCRIPT_DIR" || true

FLUTTER_SDK_PATH="${FLUTTER_SDK_PATH:-$HOME/flutter}"

if [ ! -x "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  echo "Installing Flutter into $FLUTTER_SDK_PATH"
  rm -rf "$FLUTTER_SDK_PATH"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_SDK_PATH"
fi

git config --global --add safe.directory "$FLUTTER_SDK_PATH" || true
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

flutter --version
flutter pub get
flutter build web --release

if [ ! -f build/web/index.html ] || [ ! -f build/web/main.dart.js ]; then
  echo "Flutter did not produce build/web"
  ls -la build 2>/dev/null || echo "build/ does not exist"
  exit 1
fi

publish() {
  dest=$1
  mkdir -p "$dest"
  cp -a build/web/. "$dest/"
}

# Normal case: Vercel root is the repository root and outputDirectory is dist.
publish "$SCRIPT_DIR/dist"

# The Vercel project root is currently build/web. That folder is gitignored,
# so the build starts there and cannot see this script until we walk upward.
# Publish dist relative to that directory as well.
if [ "$START_DIR" != "$SCRIPT_DIR" ]; then
  publish "$START_DIR/dist"
fi

if [ ! -f "$SCRIPT_DIR/dist/index.html" ] || [ ! -f "$SCRIPT_DIR/dist/main.dart.js" ]; then
  echo "dist/ is missing compiled web assets"
  exit 1
fi

echo "Output directory ready: $SCRIPT_DIR/dist"
ls -la "$SCRIPT_DIR/dist"
