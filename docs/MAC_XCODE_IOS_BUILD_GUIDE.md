# StorePulse — Mac & Xcode iOS Build Guide

## 1. Prerequisites
To build a signed iOS `.ipa` or run the app on a physical iPhone 18 Pro:
- A Mac computer running macOS Sonoma or later (or cloud macOS runner such as Codemagic / GitHub Actions).
- Xcode 15 or later.
- A physical iPhone running iOS 17+.
- USB-C cable or wireless debugging enabled on the iPhone.

---

## 2. Transferring the Project to Mac

Clone or transfer `flutter_app` to your Mac:
```bash
cd storepulse/flutter_app
flutter pub get
```

---

## 3. Configuring Xcode

1. Open the iOS project in Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. In the left project navigator, select the top-level **Runner** project.
3. Select the **Runner** target, then open the **Signing & Capabilities** tab.
4. **Team:** Select your Apple ID or Developer Team.
5. **Bundle Identifier:** Confirm `com.storepulse.notifications` (or your unique identifier).
6. Verify capabilities:
   - **Push Notifications** (Requires paid Apple Developer Program).
   - **Background Modes** (Ensure `Remote notifications` and `Background fetch` are checked).
7. Copy your `GoogleService-Info.plist` (downloaded from Firebase Console) into `ios/Runner/` in Xcode (select "Copy items if needed").

---

## 4. Building and Deploying to Physical iPhone

1. Connect your physical iPhone via cable to the Mac.
2. In Xcode, select your connected iPhone as the active run destination.
3. If this is the first time running on this device:
   - On the iPhone, navigate to **Settings > Privacy & Security > Developer Mode** and enable it.
   - If using a personal team certificate, go to **Settings > General > VPN & Device Management** and tap **Trust [Your Name]**.
4. In terminal or Xcode, execute:
   ```bash
   flutter run -d [Your-iPhone-Device-ID] --release
   ```
