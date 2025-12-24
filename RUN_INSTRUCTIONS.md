# 🚀 How to Run Parakeet App

## Prerequisites

### 1. Install Flutter SDK
If Flutter is not installed:

1. **Download Flutter:**
   - Visit: https://flutter.dev/docs/get-started/install
   - Download Flutter SDK for Windows
   - Extract to a location (e.g., `C:\src\flutter`)

2. **Add Flutter to PATH:**
   - Open System Environment Variables
   - Add `C:\src\flutter\bin` to your PATH
   - Restart your terminal/PowerShell

3. **Verify Installation:**
   ```bash
   flutter doctor
   ```

### 2. Install Required Tools
- **Android Studio** (for Android development)
- **VS Code** or **Android Studio** (for code editing)
- **Chrome** (for web development)

## Setup Steps

### Step 1: Install Dependencies
```bash
cd "C:\Users\ADMIN\Projections\Parakeet"
flutter pub get
```

### Step 2: Configure Firebase

**Option A: If you already have Firebase configured:**
- Make sure `lib/firebase_options.dart` exists
- If it doesn't exist, you need to set up Firebase

**Option B: Set up Firebase (if not done):**

1. **Install FlutterFire CLI:**
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Login to Firebase:**
   ```bash
   firebase login
   ```

3. **Configure Firebase for your project:**
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project (or create a new one)
   - Select platforms: web, android, ios, windows, macos, linux
   - This will generate `lib/firebase_options.dart`

4. **Enable Firebase Services:**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Enable **Authentication** (Email/Password)
   - Enable **Cloud Firestore** (create database in test mode)
   - Enable **Storage** (set up default rules)

### Step 3: Run the Application

#### For Web (Easiest to start):
```bash
flutter run -d chrome
```

#### For Windows Desktop:
```bash
flutter run -d windows
```

#### For Android:
```bash
flutter run -d android
```
(Requires Android emulator or connected device)

#### For iOS (Mac only):
```bash
flutter run -d ios
```

#### List Available Devices:
```bash
flutter devices
```

## Quick Start (If Everything is Set Up)

```bash
# Navigate to project
cd "C:\Users\ADMIN\Projections\Parakeet"

# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome
```

## Troubleshooting

### Issue: "flutter: command not found"
**Solution:** Flutter is not in your PATH. Add Flutter bin directory to PATH and restart terminal.

### Issue: "firebase_options.dart not found"
**Solution:** Run `flutterfire configure` to generate the file.

### Issue: "No devices found"
**Solution:** 
- For web: Make sure Chrome is installed
- For Android: Start an emulator or connect a device
- For Windows: Make sure Windows desktop development is enabled

### Issue: Firebase connection errors
**Solution:**
- Check Firebase project is active
- Verify `firebase_options.dart` has correct configuration
- Ensure Firebase services are enabled in console

## Development Tips

### Hot Reload
While the app is running:
- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Debug Mode
The app runs in debug mode by default with:
- Hot reload enabled
- Debug banner (already disabled in code)
- Performance overlay available

### Build for Production
```bash
# Web
flutter build web

# Windows
flutter build windows

# Android
flutter build apk
```

## Project Structure

```
Parakeet/
├── lib/
│   ├── main.dart          # Entry point
│   ├── dash.dart          # Dashboard/Home screen
│   ├── companions.dart    # Pet detail screen
│   ├── booking.dart       # Booking flow
│   ├── payments.dart      # Payment screen
│   └── ...               # Other screens
├── assets/               # Images and resources
├── pubspec.yaml          # Dependencies
└── firebase_options.dart # Firebase config (generated)
```

## Next Steps After Running

1. **Create an account** - Register a new user
2. **Create a listing** - Add a pet listing
3. **Browse listings** - View available pets
4. **Make a booking** - Test the booking flow
5. **Test payments** - Try the payment system (simulated)

---

**Need Help?** Check the [VISION.md](./VISION.md) for detailed project documentation.

