import { randomUUID } from 'crypto';
import { DateTime } from 'luxon';
import { FirestoreRepo } from './firestore-repo';
import { RateLimiter } from './rate-limiter';
import { TemplateSelector } from './template-selector';
import { FcmDispatcher } from './fcm-dispatcher';
import { NotificationLog } from '../types';

export class SchedulerEngine {
  private repo: FirestoreRepo;

  constructor(repo?: FirestoreRepo) {
    this.repo = repo ?? new FirestoreRepo();
  }

  /**
   * Executes a single evaluation tick for a user's schedule.
   */
  async processUserSchedule(uid: string): Promise<{
    executed: boolean;
    reason?: string;
    nextDelaySeconds?: number;
  }> {
    const schedule = await this.repo.getSchedule(uid);
    if (!schedule) {
      return { executed: false, reason: 'schedule_not_found' };
    }

    if (schedule.status !== 'running') {
      return { executed: false, reason: `schedule_${schedule.status}` };
    }

    if (schedule.emergencyStop) {
      return { executed: false, reason: 'emergency_stop_active' };
    }

    const todayDate = DateTime.now().setZone(schedule.timezone).toFormat('yyyy-MM-dd');
    const currentHourKey = DateTime.now().setZone(schedule.timezone).toFormat('HH');
    const metrics = await this.repo.getDailyMetrics(uid, todayDate);

    // 1. Evaluate rate limits & quiet hours
    const limitCheck = RateLimiter.evaluateLimits(schedule, metrics);
    if (!limitCheck.allowed) {
      const logId = randomUUID();
      const skippedLog: NotificationLog = {
        id: logId,
        uid,
        templateId: 'system_limiter',
        title: 'Send Skipped by Limiter',
        body: limitCheck.details || 'Rate limit or quiet hours active',
        status:
          limitCheck.reason === 'quiet_hours'
            ? 'skippedQuietHours'
            : 'skippedRateLimited',
        scheduledAt: new Date().toISOString(),
        serverResponse: limitCheck.details,
        isSimulated: true,
      };
      await this.repo.logNotification(skippedLog);

      // Re-schedule next run with jitter
      const nextDelay = TemplateSelector.generateRandomDelay(
        schedule.minIntervalSeconds,
        schedule.maxIntervalSeconds
      );
      const nextRunTime = DateTime.now().plus({ seconds: nextDelay }).toISO()!;
      await this.repo.updateSchedule(uid, { nextRunAt: nextRunTime });

      return {
        executed: false,
        reason: limitCheck.reason,
        nextDelaySeconds: nextDelay,
      };
    }

    // 2. Select template
    const templates = await this.repo.getTemplates(uid);
    const selectedTemplate = TemplateSelector.selectTemplate(
      templates,
      schedule.selectionStrategy
    );

    if (!selectedTemplate) {
      return { executed: false, reason: 'no_eligible_templates' };
    }

    // 3. Render content
    const rendered = TemplateSelector.render(selectedTemplate);

    // 4. Retrieve devices
    const devices = await this.repo.getValidDevices(uid);
    if (devices.length === 0) {
      return { executed: false, reason: 'no_registered_devices' };
    }

    // 5. Dispatch to devices
    const historyId = randomUUID();
    let sentCount = 0;

    for (const device of devices) {
      if (!device.fcmToken) continue;

      const result = await FcmDispatcher.sendPush({
        token: device.fcmToken,
        title: rendered.title,
        body: rendered.body,
        historyId,
        templateId: selectedTemplate.id,
        isSimulated: rendered.isSimulated,
      });

      if (result.invalidToken) {
        await this.repo.markDeviceInvalid(device.deviceId);
      }

      const log: NotificationLog = {
        id: historyId,
        uid,
        templateId: selectedTemplate.id,
        title: rendered.title,
        body: rendered.body,
        status: result.status,
        fcmMessageId: result.fcmMessageId,
        scheduledAt: new Date().toISOString(),
        fcmSubmittedAt: new Date().toISOString(),
        serverResponse: result.status === 'submitted' ? 'HTTP 200 - Accepted' : result.error,
        errorMessage: result.error,
        diagnostics: result.diagnostics,
        isSimulated: rendered.isSimulated,
      };
      await this.repo.logNotification(log);
      if (result.status === 'submitted') sentCount++;
    }

    // 6. Increment metrics
    if (sentCount > 0) {
      await this.repo.incrementDailyMetrics(uid, todayDate, currentHourKey);
    }

    // 7. Calculate next random delay and update schedule state
    const nextDelay = TemplateSelector.generateRandomDelay(
      schedule.minIntervalSeconds,
      schedule.maxIntervalSeconds
    );
    const nextRunTime = DateTime.now().plus({ seconds: nextDelay }).toISO()!;

    await this.repo.updateSchedule(uid, {
      nextRunAt: nextRunTime,
      lastRunAt: new Date().toISOString(),
    });

    return { executed: true, nextDelaySeconds: nextDelay };
  }
}
