#!/bin/bash
set -e

echo "🚀 Starting Parakeet build on Vercel..."

# Install Flutter
echo "📦 Installing Flutter SDK..."
FLUTTER_VERSION="3.24.0"
FLUTTER_SDK_PATH="/tmp/flutter"

# Download Flutter if not already present
if [ ! -d "$FLUTTER_SDK_PATH" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION..."
  cd /tmp
  curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz | tar xJ
  mv flutter $FLUTTER_SDK_PATH
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Verify Flutter installation
echo "✅ Flutter version:"
flutter --version

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Build for web
echo "🏗️ Building Flutter web app..."
flutter build web --release

echo "✅ Build complete! Output in build/web"

