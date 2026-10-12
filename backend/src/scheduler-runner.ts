import * as admin from 'firebase-admin';
import { SchedulerEngine } from './services/scheduler-engine';
import { FirestoreRepo } from './services/firestore-repo';

/**
 * Self-contained persistent background runner daemon.
 * Polls active schedules and triggers execution ticks when nextRunAt is reached.
 */
export async function startSchedulerDaemon(pollIntervalMs: number = 5000) {
  console.log('[Scheduler Daemon] Starting persistent scheduler loop...');
  const repo = new FirestoreRepo();
  const engine = new SchedulerEngine(repo);

  let isRunning = true;
  let hasLoggedCredentialNotice = false;

  const loop = async () => {
    while (isRunning) {
      let currentWaitMs = pollIntervalMs;

      try {
        const db = admin.firestore();
        const activeSchedules = await db
          .collection('schedules')
          .where('status', '==', 'running')
          .where('emergencyStop', '==', false)
          .get();

        const now = new Date();

        for (const doc of activeSchedules.docs) {
          const schedule = doc.data();
          const uid = doc.id;
          const nextRunAt = schedule.nextRunAt ? new Date(schedule.nextRunAt) : null;

          if (!nextRunAt || nextRunAt <= now) {
            console.log(`[Scheduler Daemon] Processing tick for user ${uid}...`);
            const result = await engine.processUserSchedule(uid);
            console.log(`[Scheduler Daemon] Result for ${uid}:`, result);
          }
        }
      } catch (err: unknown) {
        const errMsg = String(err);
        if (errMsg.includes('credentials') || errMsg.includes('Project Id') || errMsg.includes('auth')) {
          if (!hasLoggedCredentialNotice) {
            console.warn(
              '\n[Scheduler Daemon Notice] Waiting for Firebase Service Account Credentials.\n' +
              'To connect to Firestore on the cloud:\n' +
              '1. Go to: https://console.firebase.google.com/project/ios-shopify-nofiy/settings/serviceaccounts/adminsdk\n' +
              '2. Click "Generate new private key"\n' +
              '3. Save the downloaded file as "service-account.json" inside the backend folder: d:\\Softwear\\OpenGithub\\FakeShoipify\\backend\\service-account.json\n' +
              'The scheduler daemon will automatically detect it and start processing.\n'
            );
            hasLoggedCredentialNotice = true;
          }
          currentWaitMs = 15000; // Backoff while waiting for key
        } else {
          console.error('[Scheduler Daemon] Error in loop tick:', err);
        }
      }

      await new Promise((resolve) => setTimeout(resolve, currentWaitMs));
    }
  };

  loop();

  return () => {
    console.log('[Scheduler Daemon] Stopping loop...');
    isRunning = false;
  };
}

if (require.main === module) {
  // If run directly via ts-node
  if (!admin.apps.length) {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID || 'ios-shopify-nofiy',
    });
  }
  startSchedulerDaemon();
}
