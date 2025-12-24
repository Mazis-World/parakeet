#!/bin/bash
set -e

echo "📦 Installing Flutter for Vercel build..."

# Install Flutter SDK
FLUTTER_VERSION="3.24.0"
FLUTTER_SDK_PATH="$HOME/flutter"

# Create directory if it doesn't exist
mkdir -p "$FLUTTER_SDK_PATH"

if [ ! -f "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION..."
  cd /tmp
  curl -L -o flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" || {
    echo "Failed to download Flutter. Trying alternative method..."
    wget -O flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" || exit 1
  }
  tar xf flutter.tar.xz || tar -xJf flutter.tar.xz
  if [ -d "flutter" ]; then
    cp -r flutter/* "$FLUTTER_SDK_PATH/" 2>/dev/null || mv flutter/* "$FLUTTER_SDK_PATH/"
    rm -rf flutter
  fi
  rm -f flutter.tar.xz
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Make flutter executable
if [ -f "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  chmod +x "$FLUTTER_SDK_PATH/bin/flutter"
fi

# Verify installation
echo "Verifying Flutter installation..."
if [ -f "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  "$FLUTTER_SDK_PATH/bin/flutter" --version
else
  echo "❌ Flutter binary not found at $FLUTTER_SDK_PATH/bin/flutter"
  exit 1
fi

echo "✅ Flutter installation complete"

