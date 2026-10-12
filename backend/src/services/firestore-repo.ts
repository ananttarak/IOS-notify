import * as admin from 'firebase-admin';
import { DailyMetrics, Device, NotificationLog, ScheduleConfig, Template } from '../types';

export class FirestoreRepo {
  private _db?: admin.firestore.Firestore;

  get db(): admin.firestore.Firestore {
    if (!this._db) {
      if (!admin.apps.length) {
        admin.initializeApp({
          projectId: process.env.FIREBASE_PROJECT_ID || 'ios-shopify-nofiy',
        });
      }
      this._db = admin.firestore();
    }
    return this._db;
  }

  async getSchedule(uid: string): Promise<ScheduleConfig | null> {
    const doc = await this.db.collection('schedules').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data() as ScheduleConfig;
  }

  async updateSchedule(uid: string, updates: Partial<ScheduleConfig>): Promise<void> {
    await this.db.collection('schedules').doc(uid).set(
      {
        ...updates,
        updatedAt: new Date().toISOString(),
      },
      { merge: true }
    );
  }

  async getTemplates(uid: string): Promise<Template[]> {
    const snapshot = await this.db.collection('templates').where('uid', '==', uid).get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as Template));
  }

  async getValidDevices(uid: string): Promise<Device[]> {
    const snapshot = await this.db
      .collection('devices')
      .where('uid', '==', uid)
      .where('isValid', '==', true)
      .get();
    return snapshot.docs.map((doc) => ({ deviceId: doc.id, ...doc.data() } as Device));
  }

  async markDeviceInvalid(deviceId: string): Promise<void> {
    await this.db.collection('devices').doc(deviceId).update({
      isValid: false,
      invalidatedAt: new Date().toISOString(),
    });
  }

  async logNotification(log: NotificationLog): Promise<void> {
    await this.db.collection('history').doc(log.id).set(log);
  }

  async getDailyMetrics(uid: string, date: string): Promise<DailyMetrics> {
    const docId = `${uid}_${date}`;
    const doc = await this.db.collection('metrics').doc(docId).get();
    if (doc.exists) {
      return doc.data() as DailyMetrics;
    }
    return {
      date,
      uid,
      dailyTotal: 0,
      hourlyCounts: {},
      lastUpdated: new Date().toISOString(),
    };
  }

  async incrementDailyMetrics(uid: string, date: string, hourKey: string): Promise<void> {
    const docId = `${uid}_${date}`;
    const ref = this.db.collection('metrics').doc(docId);

    await this.db.runTransaction(async (transaction) => {
      const snap = await transaction.get(ref);
      if (!snap.exists) {
        transaction.set(ref, {
          date,
          uid,
          dailyTotal: 1,
          hourlyCounts: { [hourKey]: 1 },
          lastUpdated: new Date().toISOString(),
        });
      } else {
        const data = snap.data() as DailyMetrics;
        const currentDaily = data.dailyTotal || 0;
        const currentHourly = data.hourlyCounts?.[hourKey] || 0;

        transaction.update(ref, {
          dailyTotal: currentDaily + 1,
          [`hourlyCounts.${hourKey}`]: currentHourly + 1,
          lastUpdated: new Date().toISOString(),
        });
      }
    });
  }
}
