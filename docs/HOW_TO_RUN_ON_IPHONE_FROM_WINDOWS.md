# How to Run StorePulse on your Physical iPhone from Windows

This guide provides the complete solution for testing and installing StorePulse on your physical iPhone from your Windows machine.

---

## Part 1: Resolving the Backend "Project Id / Credentials" Notice

### Why did this happen?
The Firebase Admin SDK running on your Node.js server needs a **Service Account Private Key** to authenticate directly with Google Cloud Firestore and FCM gateways without a web browser.

### The 1-Minute Fix:
1. Open this link in your browser:
   **[Firebase Console — Service Accounts](https://console.firebase.google.com/project/ios-shopify-nofiy/settings/serviceaccounts/adminsdk)**
2. Click the **"Generate new private key"** button.
3. Confirm by clicking **"Generate key"**. A `.json` file will download to your computer.
4. Rename the downloaded file to:
   ```
   service-account.json
   ```
5. Move this file into your backend folder:
   ```
   d:\Softwear\OpenGithub\FakeShoipify\backend\service-account.json
   ```
6. Run the backend again:
   ```powershell
   cd d:\Softwear\OpenGithub\FakeShoipify\backend
   npm run dev
   ```
   The backend will detect the file and connect to Firebase Cloud Firestore and FCM.

---

## Part 2: How to Run the App on Your Physical iPhone from Windows

Since Apple's native compiler (Xcode) only runs on macOS, here are the two most effective ways Windows developers run their apps on physical iPhones:

### Method A: Instant Direct Testing on Your iPhone (Zero Mac needed, 60 Seconds)

Flutter Web supports PWAs and runs on Safari on iOS with full mobile gestures, sounds, and push stream visuals:

1. On your Windows PC, open PowerShell and run:
   ```powershell
   cd d:\Softwear\OpenGithub\FakeShoipify\flutter_app
   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
   ```
2. Make sure your iPhone is connected to the same Wi-Fi network as your PC.
3. Open **Safari** on your iPhone and visit your PC's IP address:
   ```
   http://192.168.1.14:8080
   ```
4. Tap the **Share icon** (square with an arrow pointing up) at the bottom of Safari.
5. Tap **"Add to Home Screen"** and press **Add**.
6. Open **StorePulse** from your iPhone home screen. It will launch full-screen like a native app, where you can start the scheduler and receive live notification simulations.

---

### Method B: Sideloading Native App to iPhone via USB on Windows (Sideloadly)

If you want the compiled native `.ipa` installed on your iPhone:

1. **Build the `.ipa` using free GitHub Actions:**
   - Commit and push this repo to GitHub.
   - The included workflow [`.github/workflows/build_ios.yml`](file:///d:/Softwear/OpenGithub/FakeShoipify/.github/workflows/build_ios.yml) will trigger on a free macOS runner and build `StorePulse_unsigned.ipa`.
   - Download the zip artifact from GitHub Actions.
2. **Install Sideloadly on Windows:**
   - Download **Sideloadly** (free tool for Windows: [sideloadly.io](https://sideloadly.io)).
   - Connect your iPhone 18 Pro to your PC with a USB cable.
   - Drag and drop `StorePulse_unsigned.ipa` into Sideloadly.
   - Enter your Apple ID email (free personal account).
   - Click **Start**. Sideloadly signs the app and installs it on your iPhone.
3. **Trust the Developer Profile on iPhone:**
   - On your iPhone, go to **Settings > General > VPN & Device Management**.
   - Tap your Apple ID and tap **Trust**.
   - Go to **Settings > Privacy & Security > Developer Mode** and toggle it **On** (restart when prompted).
   - Open StorePulse on your iPhone!
