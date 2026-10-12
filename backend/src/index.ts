import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import * as fs from 'fs';
import * as path from 'path';
import { createServer } from './server';
import { startSchedulerDaemon } from './scheduler-runner';

dotenv.config();

const projectId = process.env.FIREBASE_PROJECT_ID || 'ios-shopify-nofiy';

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  let initialized = false;

  // 1. Check direct JSON string in env
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    try {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId,
      });
      console.log('[Firebase Admin] Initialized with FIREBASE_SERVICE_ACCOUNT_KEY.');
      initialized = true;
    } catch (e) {
      console.error('[Firebase Admin] Error parsing FIREBASE_SERVICE_ACCOUNT_KEY:', e);
    }
  }

  // 2. Check local file (service-account.json or env path)
  if (!initialized) {
    const defaultKeyPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || path.resolve(process.cwd(), 'service-account.json');
    if (fs.existsSync(defaultKeyPath)) {
      try {
        const fileContent = JSON.parse(fs.readFileSync(defaultKeyPath, 'utf8'));
        admin.initializeApp({
          credential: admin.credential.cert(fileContent),
          projectId,
        });
        console.log(`[Firebase Admin] Initialized with service account from ${defaultKeyPath}.`);
        initialized = true;
      } catch (e) {
        console.error(`[Firebase Admin] Error reading key file from ${defaultKeyPath}:`, e);
      }
    }
  }

  // 3. Fallback: Initialize with Project ID
  if (!initialized) {
    admin.initializeApp({
      projectId,
    });
    console.log(`[Firebase Admin] Initialized with Project ID: "${projectId}".`);
    console.log(`[Firebase Admin Notice] For Firestore & FCM cloud access, place "service-account.json" in this directory or set FIREBASE_SERVICE_ACCOUNT_PATH in .env`);
  }
}

const PORT = process.env.PORT || 3000;
const app = createServer();

app.listen(PORT, () => {
  console.log(`[StorePulse Server] REST API listening on port ${PORT}`);
  console.log(`[StorePulse Server] Health check available at http://localhost:${PORT}/api/health`);

  // Auto-start scheduler daemon if enabled
  if (process.env.AUTO_START_SCHEDULER === 'true') {
    startSchedulerDaemon();
  }
});
