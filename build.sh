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

DART_DEFINES=""
for name in FIREBASE_API_KEY FIREBASE_APP_ID FIREBASE_MESSAGING_SENDER_ID FIREBASE_PROJECT_ID FIREBASE_AUTH_DOMAIN FIREBASE_STORAGE_BUCKET; do
  eval "value=\${$name:-}"
  if [ -n "$value" ]; then
    DART_DEFINES="$DART_DEFINES --dart-define=$name=$value"
  fi
done

flutter build web --release $DART_DEFINES

if [ ! -f build/web/index.html ] || [ ! -f build/web/main.dart.js ]; then
  echo "Flutter did not produce build/web"
  ls -la build 2>/dev/null || echo "build/ does not exist"
  exit 1
fi

# Stage outside build/web. Copying build/web into build/web/dist fails because
# that destination is inside the source tree. Vercel currently uses build/web
# as the project root and expects the site in build/web/dist.
STAGE=$(mktemp -d)
cp -a build/web/. "$STAGE/"
rm -rf "$STAGE/dist"

publish() {
  dest=$1
  mkdir -p "$dest"
  cp -a "$STAGE/." "$dest/"
}

publish "$SCRIPT_DIR/dist"

if [ "$START_DIR" != "$SCRIPT_DIR" ]; then
  publish "$START_DIR/dist"
  OUTPUT_DIR=$START_DIR/dist
else
  OUTPUT_DIR=$SCRIPT_DIR/dist
fi

rm -rf "$STAGE"

if [ ! -f "$OUTPUT_DIR/index.html" ] || [ ! -f "$OUTPUT_DIR/main.dart.js" ]; then
  echo "dist/ is missing compiled web assets"
  exit 1
fi

echo "Output directory ready: $OUTPUT_DIR"
ls -la "$OUTPUT_DIR"
