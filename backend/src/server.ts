import express, { Request, Response } from 'express';
import { randomUUID } from 'crypto';
import { FirestoreRepo } from './services/firestore-repo';
import { SchedulerEngine } from './services/scheduler-engine';
import { FcmDispatcher } from './services/fcm-dispatcher';
import { TemplateSelector } from './services/template-selector';

export function createServer(repo?: FirestoreRepo, engine?: SchedulerEngine) {
  const app = express();
  app.use(express.json());

  const firestoreRepo = repo ?? new FirestoreRepo();
  const schedulerEngine = engine ?? new SchedulerEngine(firestoreRepo);

  // Health and Diagnostics
  app.get('/api/health', (_req: Request, res: Response) => {
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'storepulse-backend',
    });
  });

  // Device Registration
  app.post('/api/devices/register', async (req: Request, res: Response) => {
    try {
      const { deviceId, uid, fcmToken, apnsToken, platform, deviceModel, osVersion } = req.body;
      if (!deviceId || !uid) {
        return res.status(400).json({ error: 'deviceId and uid are required' });
      }

      await firestoreRepo['db'].collection('devices').doc(deviceId).set(
        {
          deviceId,
          uid,
          fcmToken,
          apnsToken,
          platform: platform || 'ios',
          deviceModel: deviceModel || 'iPhone 18 Pro',
          osVersion: osVersion || '18.0',
          isValid: true,
          lastSeenAt: new Date().toISOString(),
        },
        { merge: true }
      );

      res.json({ success: true, deviceId });
    } catch (err: unknown) {
      res.status(500).json({ error: String(err) });
    }
  });

  // Trigger Immediate Test Push
  app.post('/api/push/test', async (req: Request, res: Response) => {
    try {
      const { uid, title, body } = req.body;
      if (!uid) return res.status(400).json({ error: 'uid is required' });

      const devices = await firestoreRepo.getValidDevices(uid);
      if (devices.length === 0) {
        return res.status(404).json({ error: 'No registered devices found for user' });
      }

      const historyId = randomUUID();
      const sendTitle = title || 'Order #6745';
      const sendBody = body || '$34.99, 1 item from Online Store · Paya Ecom';

      const results = [];
      for (const dev of devices) {
        if (!dev.fcmToken) continue;
        const result = await FcmDispatcher.sendPush({
          token: dev.fcmToken,
          title: sendTitle,
          body: sendBody,
          historyId,
          templateId: 'manual_test',
          isSimulated: true,
        });

        await firestoreRepo.logNotification({
          id: historyId,
          uid,
          templateId: 'manual_test',
          title: sendTitle,
          body: sendBody,
          status: result.status,
          fcmMessageId: result.fcmMessageId,
          scheduledAt: new Date().toISOString(),
          fcmSubmittedAt: new Date().toISOString(),
          serverResponse: result.status === 'submitted' ? 'HTTP 200 - Accepted' : result.error,
          errorMessage: result.error,
          diagnostics: result.diagnostics,
          isSimulated: true,
        });

        results.push({ deviceId: dev.deviceId, ...result });
      }

      res.json({ success: true, historyId, results });
    } catch (err: unknown) {
      res.status(500).json({ error: String(err) });
    }
  });

  // Scheduler Evaluation Tick (Called by Cloud Scheduler or local daemon)
  app.post('/api/scheduler/tick', async (req: Request, res: Response) => {
    try {
      const { uid } = req.body;
      if (!uid) return res.status(400).json({ error: 'uid is required' });

      const outcome = await schedulerEngine.processUserSchedule(uid);
      res.json(outcome);
    } catch (err: unknown) {
      res.status(500).json({ error: String(err) });
    }
  });

  return app;
}
