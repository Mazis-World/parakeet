#!/usr/bin/env bash
set -e

echo "🚀 Starting Parakeet build on Vercel..."

# Install Flutter SDK
FLUTTER_VERSION="3.24.0"
FLUTTER_SDK_PATH="$HOME/flutter"

echo "📦 Installing Flutter SDK..."

# Create directory if it doesn't exist
mkdir -p "$FLUTTER_SDK_PATH"

if [ ! -f "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  echo "Downloading Flutter $FLUTTER_VERSION..."
  cd /tmp
  curl -L -o flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" || {
    echo "curl failed, trying wget..."
    wget -O flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" || exit 1
  }
  
  echo "Extracting Flutter..."
  tar xf flutter.tar.xz 2>/dev/null || tar -xJf flutter.tar.xz || exit 1
  
  if [ -d "flutter" ]; then
    echo "Moving Flutter to $FLUTTER_SDK_PATH..."
    cp -r flutter/* "$FLUTTER_SDK_PATH/" 2>/dev/null || {
      find flutter -type f -exec cp --parents {} "$FLUTTER_SDK_PATH/" \;
    }
    rm -rf flutter
  fi
  rm -f flutter.tar.xz
fi

# Add Flutter to PATH
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Make flutter executable
if [ -f "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  chmod +x "$FLUTTER_SDK_PATH/bin/flutter"
else
  echo "❌ Flutter binary not found after installation"
  exit 1
fi

# Verify Flutter installation
echo "✅ Verifying Flutter installation..."
"$FLUTTER_SDK_PATH/bin/flutter" --version

# Get dependencies
echo "📚 Getting Flutter dependencies..."
cd "$VERCEL_SOURCE_DIR" || cd "$(pwd)"
"$FLUTTER_SDK_PATH/bin/flutter" pub get

# Build for web
echo "🏗️ Building Flutter web app..."
"$FLUTTER_SDK_PATH/bin/flutter" build web --release

# Verify build output
if [ ! -d "build/web" ]; then
  echo "❌ Build output not found in build/web"
  exit 1
fi

echo "✅ Build complete! Output in build/web"
ls -la build/web/ | head -10

