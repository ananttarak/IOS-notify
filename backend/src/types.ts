export type SchedulerStatus = 'running' | 'paused' | 'stopped';

export interface ScheduleConfig {
  uid: string;
  status: SchedulerStatus;
  minIntervalSeconds: number;
  maxIntervalSeconds: number;
  maxPerHour: number;
  maxPerDay: number;
  allowedDays: number[]; // 1 = Monday ... 7 = Sunday
  timezone: string;
  quietHoursStart: string; // "HH:mm" e.g. "22:00"
  quietHoursEnd: string; // "HH:mm" e.g. "07:00"
  duplicatePreventionMinutes: number;
  emergencyStop: boolean;
  selectionStrategy: 'weighted' | 'uniform';
  nextRunAt?: string;
  lastRunAt?: string;
  updatedAt: string;
}

export interface Template {
  id: string;
  uid: string;
  title: string;
  body: string;
  weight: number;
  isEnabled: boolean;
  isSimulated: boolean;
  defaultVariables?: Record<string, string>;
  createdAt: string;
}

export interface Device {
  deviceId: string;
  uid: string;
  fcmToken?: string;
  apnsToken?: string;
  platform: 'ios' | 'android' | 'web' | 'windows';
  deviceModel: string;
  osVersion: string;
  isPermissionGranted: boolean;
  isValid: boolean;
  lastSeenAt: string;
}

export type DeliveryStatus =
  | 'scheduled'
  | 'submitted'
  | 'delivered'
  | 'failed'
  | 'skippedRateLimited'
  | 'skippedQuietHours'
  | 'emergencyStopped';

export interface NotificationLog {
  id: string;
  uid: string;
  templateId: string;
  title: string;
  body: string;
  status: DeliveryStatus;
  fcmMessageId?: string;
  scheduledAt: string;
  fcmSubmittedAt?: string;
  confirmedDeliveredAt?: string;
  serverResponse?: string;
  errorMessage?: string;
  diagnostics?: Record<string, unknown>;
  isSimulated: boolean;
}

export interface DailyMetrics {
  date: string; // "YYYY-MM-DD"
  uid: string;
  dailyTotal: number;
  hourlyCounts: Record<string, number>; // "00" through "23"
  lastUpdated: string;
}
