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
  curl -L -o flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  tar xf flutter.tar.xz
  mv flutter/* "$FLUTTER_SDK_PATH/" || cp -r flutter/* "$FLUTTER_SDK_PATH/"
  rm -rf flutter flutter.tar.xz
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Make flutter executable
chmod +x "$FLUTTER_SDK_PATH/bin/flutter"

# Verify installation
echo "Verifying Flutter installation..."
"$FLUTTER_SDK_PATH/bin/flutter" --version || flutter --version

echo "✅ Flutter installation complete"

