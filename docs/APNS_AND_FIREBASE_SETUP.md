# StorePulse — APNs & Firebase Setup Guide

## 1. Apple Developer Program vs. Free Apple Account (Crucial Blocker Analysis)

> [!IMPORTANT]
> **Free Personal Apple Accounts CANNOT send remote push notifications.**
> 
> Apple restricts the **Apple Push Notification service (APNs)** strictly to members enrolled in the paid **Apple Developer Program ($99/year)**:
> 1. Free accounts cannot check the **Push Notifications capability** without Xcode throwing a provisioning error.
> 2. Free accounts cannot access the **Keys** section on [developer.apple.com](https://developer.apple.com) to generate the `.p8` APNs Auth Key.
> 
> **How StorePulse handles this gracefully:**
> While you are on a free account, StorePulse runs in full **Local Simulation & In-App Alerts mode**. All UI features, interval timers, rate-limiting, variable substitution, audio feedback, and lock-screen card stacks operate 100% on your device. Once you enroll in the Developer Program, no code changes are required—simply upload your `.p8` key to Firebase.

---

## 2. Generating APNs Auth Key (.p8)

When enrolled in the Apple Developer Program:
1. Log into [Apple Developer Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list).
2. Go to **Keys** and click the **+** (Add) button.
3. Enter Key Name: `StorePulse APNs Key`.
4. Select the checkbox for **Apple Push Notifications service (APNs)**.
5. Click **Continue** and then **Register**.
6. Download the key file (named `AuthKey_XXXXXXXXXX.p8`). *Note: You can only download this file once.*
7. Note down the **Key ID** (10-character string) and your **Team ID** (found in Membership details).

---

## 3. Configuring Firebase Cloud Messaging

1. Open the [Firebase Console](https://console.firebase.google.com).
2. Create or open your project.
3. Add an **iOS App** with Bundle ID `com.storepulse.notifications`.
4. Download `GoogleService-Info.plist` and place it in `flutter_app/ios/Runner/`.
5. Go to **Project Settings > Cloud Messaging > Apple app configuration**.
6. Under **APNs Authentication Key**, click **Upload**:
   - Upload your `AuthKey_XXXXXXXXXX.p8` file.
   - Enter your **Key ID**.
   - Enter your **Team ID**.
7. Click **Save**. Firebase is now linked directly to Apple's APNs production gateway.

---

## 4. Backend Service Account Setup

1. In Firebase Console, go to **Project Settings > Service accounts**.
2. Click **Generate new private key** and download the JSON file.
3. In `backend/.env`:
   - Either set `GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json`
   - Or paste the minified JSON into `FIREBASE_SERVICE_ACCOUNT_KEY`.
