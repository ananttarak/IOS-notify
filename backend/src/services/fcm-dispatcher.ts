import * as admin from 'firebase-admin';
import { DeliveryStatus } from '../types';

export interface DispatchResult {
  status: DeliveryStatus;
  fcmMessageId?: string;
  error?: string;
  invalidToken?: boolean;
  diagnostics: Record<string, unknown>;
}

export class FcmDispatcher {
  /**
   * Dispatches push notification to an APNs/FCM target token via Firebase Admin HTTP v1.
   */
  static async sendPush(params: {
    token: string;
    title: string;
    body: string;
    historyId: string;
    templateId: string;
    isSimulated?: boolean;
  }): Promise<DispatchResult> {
    const { token, title, body, historyId, templateId, isSimulated = true } = params;

    const message: admin.messaging.Message = {
      token,
      notification: {
        title,
        body,
      },
      data: {
        historyId,
        templateId,
        isSimulated: isSimulated ? 'true' : 'false',
        timestamp: new Date().toISOString(),
      },
      apns: {
        headers: {
          'apns-priority': '10',
          'apns-push-type': 'alert',
        },
        payload: {
          aps: {
            alert: {
              title,
              body,
            },
            sound: 'default',
            badge: 1,
            contentAvailable: true,
          },
        },
      },
    };

    try {
      const response = await admin.messaging().send(message);
      return {
        status: 'submitted',
        fcmMessageId: response,
        diagnostics: {
          fcmApi: 'HTTP v1',
          apnsPriority: 10,
          sound: 'default',
          acceptedAt: new Date().toISOString(),
        },
      };
    } catch (err: unknown) {
      const errorObj = err as { code?: string; message?: string };
      const errorCode = errorObj.code || 'unknown';
      const errorMessage = errorObj.message || String(err);

      const isInvalidToken =
        errorCode === 'messaging/registration-token-not-registered' ||
        errorCode === 'messaging/invalid-registration-token' ||
        errorCode === 'messaging/invalid-argument';

      return {
        status: 'failed',
        error: `[${errorCode}] ${errorMessage}`,
        invalidToken: isInvalidToken,
        diagnostics: {
          fcmApi: 'HTTP v1',
          failedAt: new Date().toISOString(),
          errorCode,
        },
      };
    }
  }
}
