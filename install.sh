#!/bin/bash
set -e

echo "📦 Installing Flutter for Vercel build..."

# Install Flutter SDK
FLUTTER_VERSION="3.24.0"
FLUTTER_SDK_PATH="/tmp/flutter"

if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION..."
  cd /tmp
  curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz | tar xJ
  mv flutter $FLUTTER_SDK_PATH
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Verify installation
flutter --version

# Accept licenses
yes | flutter doctor --android-licenses || true

echo "✅ Flutter installation complete"

