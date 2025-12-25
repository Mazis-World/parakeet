# 🚀 Deployment Guide - Parakeet App

## Current Status

The app is configured for Vercel deployment with an inline build command that installs Flutter and builds the web app.

## Vercel Deployment

### Automatic (via vercel.json)
The `vercel.json` file is configured with an inline build command. Just:
1. Connect your GitHub repo to Vercel
2. Vercel will automatically detect the configuration
3. Deploy!

### Manual Configuration
If you need to set it up manually in Vercel dashboard:

**Build Settings:**
- **Framework Preset:** Other
- **Build Command:** (Already in vercel.json, but if needed):
  ```bash
  FLUTTER_VERSION=3.24.0 && FLUTTER_SDK=$HOME/flutter && mkdir -p $FLUTTER_SDK && cd /tmp && curl -L https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -o flutter.tar.xz && tar xf flutter.tar.xz && mv flutter/* $FLUTTER_SDK/ && rm -rf flutter flutter.tar.xz && export PATH=$FLUTTER_SDK/bin:$PATH && cd $VERCEL_SOURCE_DIR && $FLUTTER_SDK/bin/flutter pub get && $FLUTTER_SDK/bin/flutter build web --release
  ```
- **Output Directory:** `build/web`
- **Install Command:** (Leave empty or use: `echo 'Installing during build'`)

## Alternative: Firebase Hosting (Recommended)

Since you're already using Firebase, Firebase Hosting is simpler and more reliable:

### Setup (One-time)

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize hosting (if not done)
firebase init hosting
```

When prompted:
- **Select:** Use an existing project → Choose your Firebase project
- **Public directory:** `build/web`
- **Single-page app:** Yes
- **Set up automatic builds:** No (we'll build manually)

### Deploy

```bash
# Build the Flutter web app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

Your app will be live at: `https://[your-project].web.app`

### Benefits of Firebase Hosting
✅ No Flutter installation needed (build locally)  
✅ Works seamlessly with Firebase services  
✅ Free tier with generous limits  
✅ Fast global CDN  
✅ Automatic SSL certificates  
✅ Easy custom domain setup  
✅ Better for Flutter web apps  

## GitHub Pages (Alternative)

If you want to use GitHub Pages:

1. Build locally:
   ```bash
   flutter build web --release
   ```

2. Push build folder to `gh-pages` branch:
   ```bash
   git subtree push --prefix build/web origin gh-pages
   ```

3. Enable GitHub Pages in repo settings

## Netlify (Alternative)

Netlify has better Flutter support than Vercel:

1. Go to https://netlify.com
2. Connect GitHub repo
3. Build settings:
   - **Build command:** `flutter build web --release`
   - **Publish directory:** `build/web`
   - **Environment variables:** `FLUTTER_VERSION=3.24.0`

## Troubleshooting

### Vercel Build Fails
- Check build logs for specific errors
- Ensure `firebase_options.dart` is committed (or use env vars)
- Try Firebase Hosting instead (recommended)

### Firebase Hosting Issues
- Make sure you're logged in: `firebase login`
- Check Firebase project is active: `firebase projects:list`
- Verify build output exists: `ls -la build/web`

### Build Output Not Found
- Run `flutter build web --release` locally first
- Check `build/web` directory exists
- Verify no build errors

## Recommended Approach

**For Production:** Use **Firebase Hosting**
- Most reliable for Flutter
- Already using Firebase
- Better performance
- Easier to manage

**For Quick Testing:** Use **Vercel**
- Fast setup
- Good for demos
- Automatic deployments

---

**Current Configuration:** Inline build command in `vercel.json`  
**Status:** Ready for deployment ✅

