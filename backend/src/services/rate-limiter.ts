import { DateTime } from 'luxon';
import { DailyMetrics, ScheduleConfig } from '../types';

export interface RateLimitCheckResult {
  allowed: boolean;
  reason?: 'emergency_stop' | 'quiet_hours' | 'day_not_allowed' | 'hourly_cap_exceeded' | 'daily_cap_exceeded';
  details?: string;
}

export class RateLimiter {
  /**
   * Checks if current time is within quiet hours window for the given timezone.
   * Quiet hours format: "HH:mm" (e.g. "22:00" to "07:00")
   */
  static isQuietHours(
    timezone: string,
    quietStart: string,
    quietEnd: string,
    now?: DateTime
  ): boolean {
    const current = (now ?? DateTime.now()).setZone(timezone);
    if (!current.isValid) return false;

    const [startH, startM] = quietStart.split(':').map(Number);
    const [endH, endM] = quietEnd.split(':').map(Number);

    const currentMinutes = current.hour * 60 + current.minute;
    const startMinutes = startH * 60 + startM;
    const endMinutes = endH * 60 + endM;

    if (startMinutes <= endMinutes) {
      // e.g. 01:00 to 05:00 on the same day
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    } else {
      // Overnight e.g. 22:00 to 07:00
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    }
  }

  /**
   * Validates if notification is permitted under current schedule config & metrics.
   */
  static evaluateLimits(
    config: ScheduleConfig,
    metrics?: DailyMetrics,
    now?: DateTime
  ): RateLimitCheckResult {
    if (config.emergencyStop) {
      return {
        allowed: false,
        reason: 'emergency_stop',
        details: 'Global emergency stop is enabled.',
      };
    }

    const current = (now ?? DateTime.now()).setZone(config.timezone);

    // Day of week check (1 = Monday ... 7 = Sunday)
    if (config.allowedDays && config.allowedDays.length > 0) {
      if (!config.allowedDays.includes(current.weekday)) {
        return {
          allowed: false,
          reason: 'day_not_allowed',
          details: `Day ${current.weekday} is not in allowed days list.`,
        };
      }
    }

    // Quiet hours check
    if (this.isQuietHours(config.timezone, config.quietHoursStart, config.quietHoursEnd, current)) {
      return {
        allowed: false,
        reason: 'quiet_hours',
        details: `Quiet hours active (${config.quietHoursStart} - ${config.quietHoursEnd} in ${config.timezone}).`,
      };
    }

    // Metrics check
    if (metrics) {
      if (metrics.dailyTotal >= config.maxPerDay) {
        return {
          allowed: false,
          reason: 'daily_cap_exceeded',
          details: `Daily cap of ${config.maxPerDay} notifications reached.`,
        };
      }

      const hourKey = current.toFormat('HH');
      const hourCount = metrics.hourlyCounts[hourKey] || 0;
      if (hourCount >= config.maxPerHour) {
        return {
          allowed: false,
          reason: 'hourly_cap_exceeded',
          details: `Hourly cap of ${config.maxPerHour} reached for hour ${hourKey}.`,
        };
      }
    }

    return { allowed: true };
  }
}
