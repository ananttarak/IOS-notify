# StorePulse — Windows Local Development Guide

## 1. Overview
The StorePulse Flutter client and TypeScript backend are fully configured to run, build, and test locally on Windows 11 without requiring a Mac during development.

---

## 2. Running the Flutter App on Windows

You can run StorePulse in interactive mode using either **Windows Desktop** or **Chrome / Edge Web**:

### Running on Windows Desktop:
```powershell
cd d:\Softwear\OpenGithub\FakeShoipify\flutter_app
flutter run -d windows
```

### Running in Chrome / Web:
```powershell
cd d:\Softwear\OpenGithub\FakeShoipify\flutter_app
flutter run -d chrome
```

### Running Tests:
```powershell
flutter test
```

---

## 3. Running the TypeScript Backend on Windows

The backend contains both an Express REST API and a persistent Scheduler Daemon.

### Install Dependencies & Build:
```powershell
cd d:\Softwear\OpenGithub\FakeShoipify\backend
npm install
npm run build
```

### Running the Backend Server:
```powershell
# Copy the environment file
copy .env.example .env

# Run in development mode with live ts-node:
npm run dev
```

### Running Backend Unit & Rate-Limiter Tests:
```powershell
npm test
```

---

## 4. Local Simulator & In-App Alerts
When running locally on Windows:
- The app operates in **Local Diagnostic & In-App Simulation Mode**.
- Tapping **"Start"** triggers the scheduler loop with randomized intervals.
- Tapping **"Send Test"** sends an immediate notification and logs the event in the History drawer.
- The **Live Lock-Screen Stack** mirrors the visual behavior observed in the reference video (`Instagram(9).mp4`), including dynamic order numbers, randomized pricing, and items breakdown.
