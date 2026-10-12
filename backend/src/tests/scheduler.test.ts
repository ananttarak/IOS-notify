import { DateTime } from 'luxon';
import { TemplateSelector } from '../services/template-selector';
import { RateLimiter } from '../services/rate-limiter';
import { ScheduleConfig, Template, DailyMetrics } from '../types';

describe('StorePulse Backend Test Suite', () => {
  describe('TemplateSelector', () => {
    test('generateRandomDelay generates numbers within bounds', () => {
      for (let i = 0; i < 50; i++) {
        const delay = TemplateSelector.generateRandomDelay(30, 90);
        expect(delay).toBeGreaterThanOrEqual(30);
        expect(delay).toBeLessThanOrEqual(90);
      }
    });

    test('selectTemplate picks only enabled templates and respects weights', () => {
      const templates: Template[] = [
        {
          id: 't1',
          uid: 'u1',
          title: 'Order A',
          body: 'Body A',
          weight: 90,
          isEnabled: true,
          isSimulated: true,
          createdAt: new Date().toISOString(),
        },
        {
          id: 't2',
          uid: 'u1',
          title: 'Order B',
          body: 'Body B',
          weight: 10,
          isEnabled: true,
          isSimulated: true,
          createdAt: new Date().toISOString(),
        },
        {
          id: 't3',
          uid: 'u1',
          title: 'Disabled Order',
          body: 'Disabled Body',
          weight: 100,
          isEnabled: false,
          isSimulated: true,
          createdAt: new Date().toISOString(),
        },
      ];

      const counts: Record<string, number> = { t1: 0, t2: 0, t3: 0 };
      for (let i = 0; i < 500; i++) {
        const chosen = TemplateSelector.selectTemplate(templates, 'weighted');
        if (chosen) counts[chosen.id]++;
      }

      expect(counts.t3).toBe(0); // Disabled template never picked
      expect(counts.t1).toBeGreaterThan(counts.t2); // Weight 90 picked significantly more than 10
    });

    test('render interpolates placeholders properly', () => {
      const template: Template = {
        id: 'tmpl_order',
        uid: 'user_1',
        title: 'Order #{{order_id}}',
        body: '{{amount}}, {{items}} items from {{store}}',
        weight: 10,
        isEnabled: true,
        isSimulated: true,
        defaultVariables: { store: 'Custom Boutique' },
        createdAt: new Date().toISOString(),
      };

      const rendered = TemplateSelector.render(template, {
        order_id: '7890',
        amount: '$99.50',
        items: '3',
      });

      expect(rendered.title).toBe('Order #7890');
      expect(rendered.body).toBe('$99.50, 3 items from Custom Boutique');
      expect(rendered.isSimulated).toBe(true);
    });
  });

  describe('RateLimiter & Quiet Hours', () => {
    test('isQuietHours detects overnight quiet hours accurately', () => {
      // 23:30 (should be quiet)
      const lateNight = DateTime.fromISO('2026-10-12T23:30:00', { zone: 'UTC' });
      expect(RateLimiter.isQuietHours('UTC', '22:00', '07:00', lateNight)).toBe(true);

      // 03:15 (should be quiet)
      const earlyMorning = DateTime.fromISO('2026-10-12T03:15:00', { zone: 'UTC' });
      expect(RateLimiter.isQuietHours('UTC', '22:00', '07:00', earlyMorning)).toBe(true);

      // 14:00 (daytime, should NOT be quiet)
      const afternoon = DateTime.fromISO('2026-10-12T14:00:00', { zone: 'UTC' });
      expect(RateLimiter.isQuietHours('UTC', '22:00', '07:00', afternoon)).toBe(false);
    });

    test('evaluateLimits halts on emergency stop', () => {
      const config: ScheduleConfig = {
        uid: 'u1',
        status: 'running',
        minIntervalSeconds: 30,
        maxIntervalSeconds: 60,
        maxPerHour: 10,
        maxPerDay: 50,
        allowedDays: [1, 2, 3, 4, 5, 6, 7],
        timezone: 'UTC',
        quietHoursStart: '22:00',
        quietHoursEnd: '07:00',
        duplicatePreventionMinutes: 5,
        emergencyStop: true,
        selectionStrategy: 'weighted',
        updatedAt: new Date().toISOString(),
      };

      const result = RateLimiter.evaluateLimits(config);
      expect(result.allowed).toBe(false);
      expect(result.reason).toBe('emergency_stop');
    });

    test('evaluateLimits enforces hourly and daily caps', () => {
      const config: ScheduleConfig = {
        uid: 'u1',
        status: 'running',
        minIntervalSeconds: 30,
        maxIntervalSeconds: 60,
        maxPerHour: 5,
        maxPerDay: 20,
        allowedDays: [1, 2, 3, 4, 5, 6, 7],
        timezone: 'UTC',
        quietHoursStart: '23:00',
        quietHoursEnd: '06:00',
        duplicatePreventionMinutes: 5,
        emergencyStop: false,
        selectionStrategy: 'weighted',
        updatedAt: new Date().toISOString(),
      };

      const afternoon = DateTime.fromISO('2026-10-12T15:00:00', { zone: 'UTC' });

      // Within limit
      const metricsNormal: DailyMetrics = {
        date: '2026-10-12',
        uid: 'u1',
        dailyTotal: 10,
        hourlyCounts: { '15': 3 },
        lastUpdated: new Date().toISOString(),
      };
      expect(RateLimiter.evaluateLimits(config, metricsNormal, afternoon).allowed).toBe(true);

      // Hourly exceeded
      const metricsHourlyMaxed: DailyMetrics = {
        date: '2026-10-12',
        uid: 'u1',
        dailyTotal: 10,
        hourlyCounts: { '15': 5 },
        lastUpdated: new Date().toISOString(),
      };
      const hourlyRes = RateLimiter.evaluateLimits(config, metricsHourlyMaxed, afternoon);
      expect(hourlyRes.allowed).toBe(false);
      expect(hourlyRes.reason).toBe('hourly_cap_exceeded');

      // Daily exceeded
      const metricsDailyMaxed: DailyMetrics = {
        date: '2026-10-12',
        uid: 'u1',
        dailyTotal: 20,
        hourlyCounts: { '15': 1 },
        lastUpdated: new Date().toISOString(),
      };
      const dailyRes = RateLimiter.evaluateLimits(config, metricsDailyMaxed, afternoon);
      expect(dailyRes.allowed).toBe(false);
      expect(dailyRes.reason).toBe('daily_cap_exceeded');
    });
  });
});
