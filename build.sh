#!/bin/bash
set -e

echo "🚀 Starting Parakeet build on Vercel..."

# Set Flutter path (should be installed by install.sh)
FLUTTER_SDK_PATH="$HOME/flutter"
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"

# Verify Flutter is available
if [ ! -f "$FLUTTER_SDK_PATH/bin/flutter" ]; then
  echo "❌ Flutter not found at $FLUTTER_SDK_PATH/bin/flutter"
  echo "Listing $HOME contents:"
  ls -la "$HOME" || true
  exit 1
fi

# Verify Flutter installation
echo "✅ Flutter version:"
"$FLUTTER_SDK_PATH/bin/flutter" --version

# Get dependencies
echo "📚 Getting Flutter dependencies..."
"$FLUTTER_SDK_PATH/bin/flutter" pub get

# Build for web
echo "🏗️ Building Flutter web app..."
"$FLUTTER_SDK_PATH/bin/flutter" build web --release

echo "✅ Build complete! Output in build/web"
echo "Listing build/web contents:"
ls -la build/web/ || echo "Build directory not found"

