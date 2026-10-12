# StorePulse — Flutter iOS Push Notification Automation Hub

A production-grade personal e-commerce activity notification automation app inspired by real-time lock-screen store activity streams. StorePulse enables developers and merchants to generate, schedule, and receive randomized activity notifications on their iPhone with full interval controls, weighted random templates, rate limiting, and delivery diagnostics.

---

## 🌟 Key Features

- **iOS-Inspired Design System:** Material 3 blended with Cupertino aesthetics, supporting native light and dark modes, SF-style typography, and smooth transitions.
- **Dynamic Lock-Screen Stream Preview:** Interactive live stack replicating the notification behavior observed in e-commerce activity streams (e.g. `Order #6745 - $34.99, 1 item from Online Store · Paya Ecom`).
- **Flexible Template Engine:**
  - Create, edit, and delete templates.
  - Weight-based or uniform random selection.
  - Dynamic interpolation (`{{order_id}}`, `{{amount}}`, `{{items}}`, `{{store}}`, etc.).
  - Mandatory `SIMULATION` disclaimers to prevent deceptive representation.
- **Robust Automation Scheduler:**
  - Configurable minimum and maximum interval jitter.
  - Hourly and daily rate limiting caps.
  - Timezone-aware quiet hours with midnight wrapping (e.g., 22:00 to 07:00).
  - Global emergency stop.
- **Full Delivery Diagnostics:**
  - Strict tracking separating FCM gateway acceptance from confirmed physical delivery.
  - In-app token inspector and Apple Developer account limitation diagnostics.
  - Expandable diagnostic audit drawer for every notification.
- **Production Backend:**
  - Node.js & TypeScript service utilizing Firebase Admin SDK (FCM HTTP v1 API).
  - Standalone persistent runner loop surviving restarts.
  - Atomic Firestore rate-limit counters and security rules.

---

## 📁 Repository Structure

```
FakeShoipify/
├── flutter_app/                # Flutter application
│   ├── lib/
│   │   ├── core/
│   │   │   ├── models/        # Schedule, Template, Device, History models
│   │   │   ├── providers/     # Riverpod 3 Notifiers & State providers
│   │   │   ├── router/        # GoRouter navigation & bottom nav bar
│   │   │   ├── services/      # Local notification & Firebase services
│   │   │   └── theme/         # Custom iOS-inspired themes
│   │   ├── features/
│   │   │   ├── dashboard/     # Status banner, controls, KPI grid, live stack
│   │   │   ├── templates/     # Template manager & editor modal with preview
│   │   │   ├── scheduler/     # Interval sliders, quiet hours, emergency stop
│   │   │   ├── history/       # Search, filter chips, expandable diagnostic drawer
│   │   │   └── settings/      # Token inspector & APNs diagnostic checklist
│   │   └── main.dart          # App entrypoint
│   ├── ios/Runner/            # Configured Xcode runner, Info.plist, entitlements
│   └── test/                  # Unit and widget tests
│
├── backend/                    # TypeScript Node.js backend
│   ├── src/
│   │   ├── services/
│   │   │   ├── fcm-dispatcher.ts     # FCM HTTP v1 API with APNs headers
│   │   │   ├── firestore-repo.ts     # Atomic Firestore metrics & repository
│   │   │   ├── rate-limiter.ts       # Timezone quiet hours & cap enforcement
│   │   │   ├── scheduler-engine.ts   # Scheduling orchestration
│   │   │   └── template-selector.ts  # Weighted picker & variable interpolation
│   │   ├── tests/                    # Jest automated tests
│   │   ├── server.ts                 # Express REST API endpoints
│   │   ├── scheduler-runner.ts       # Persistent polling daemon
│   │   └── index.ts                  # Server entrypoint
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
│
├── firebase/
│   ├── firestore.rules        # Production user-scoped security rules
│   └── firestore.indexes.json # Composite indexes for history and devices
│
└── docs/
    ├── WINDOWS_SETUP_GUIDE.md
    ├── MAC_XCODE_IOS_BUILD_GUIDE.md
    ├── APNS_AND_FIREBASE_SETUP.md
    └── PHYSICAL_IPHONE_TESTING_CHECKLIST.md
```

---

## 🚀 Quick Start (Windows Local Dev)

### 1. Flutter App
```powershell
cd flutter_app
flutter pub get
flutter test
flutter run -d chrome    # Or flutter run -d windows
```

### 2. TypeScript Backend
```powershell
cd backend
npm install
npm test
npm run dev
```

---

## 🔒 Free Apple Account & APNs Prerequisites

Apple strictly enforces that **Free Apple Accounts cannot use the Apple Push Notification service (APNs)**:
- Sideloading apps with a free account works for UI and local audio/banner alerts.
- Sending remote background notifications from a server to an iPhone requires an **Apple Developer Program enrollment ($99/year)** to generate an APNs Auth Key (`.p8`).

StorePulse seamlessly handles this by providing **full local simulation & in-app alerts** when running on free accounts, while keeping 100% of the production APNs and FCM HTTP v1 architecture ready for instant deployment once enrolled.

See [APNS_AND_FIREBASE_SETUP.md](file:///d:/Softwear/OpenGithub/FakeShoipify/docs/APNS_AND_FIREBASE_SETUP.md) for full details.
