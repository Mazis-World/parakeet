#!/bin/bash
set -e

echo "🚀 Starting Parakeet build on Vercel..."

# Set Flutter path (should be installed by install.sh)
FLUTTER_SDK_PATH="$HOME/flutter"
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Verify Flutter is available
if [ ! -f "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  echo "❌ Flutter not found. Running install script..."
  chmod +x install.sh
  ./install.sh
fi

# Verify Flutter installation
echo "✅ Flutter version:"
flutter --version || "$FLUTTER_SDK_PATH/bin/flutter" --version

# Get dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get || "$FLUTTER_SDK_PATH/bin/flutter" pub get

# Build for web
echo "🏗️ Building Flutter web app..."
flutter build web --release || "$FLUTTER_SDK_PATH/bin/flutter" build web --release

echo "✅ Build complete! Output in build/web"

