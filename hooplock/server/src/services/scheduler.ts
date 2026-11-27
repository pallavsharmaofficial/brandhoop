import { q, one } from '../db.js';
import { loanSummary, todayIST, daysBetween } from './loans.js';
import { setLockState } from './devices.js';
import { settingsOf } from './settings.js';
import { sendSms } from './sms.js';
import { pushSync } from './fcm.js';
import type { LockState } from '../security.js';

const rank: Record<LockState, number> = { unlocked: 0, warning: 1, restricted: 2, locked: 3 };

/**
 * Daily run (and safe to run more often): reminders before and on the due date, then the gradual
 * steps per shop settings: warning -> restricted -> (optional) locked. Never touches a phone a
 * person locked or unlocked by hand on purpose unless the automatic step is stronger, and never
 * downgrades: unlocking happens on payment.
 */
export async function runDaily(log?: any, today = todayIST()) {
  const devices = await q<any>(
    `select d.id, d.merchant_id, d.lock_state, d.lock_reason, d.fcm_token, c.name, c.mobile, m.name as shop, m.phone as shop_phone, m.settings
     from devices d join customers c on c.id = d.customer_id join merchants m on m.id = d.merchant_id
     join loans l on l.device_id = d.id
     where d.status = 'active' and d.platform = 'android' and l.status = 'open' and m.active`);
  let reminders = 0, steps = 0;
  for (const d of devices) {
    const s = settingsOf(d.settings);
    const sum = await loanSummary(d.id, undefined, today);
    if (!sum) continue;

    // Reminders: once per kind per day.
    let kind: string | null = null; let text = '';
    if (sum.overdueDays > 0) {
      if ([1, 3, 7, 15, 25, 30].includes(sum.overdueDays) || sum.overdueDays % 7 === 0) {
        kind = 'overdue';
        text = `Dear ${d.name}, your EMI of Rs ${sum.overdueAmount} is overdue by ${sum.overdueDays} days. Please pay at ${d.shop} (${d.shop_phone}).`;
      }
    } else if (sum.nextDueDate) {
      const until = daysBetween(today, sum.nextDueDate);
      if (until === s.remindDaysBefore || until === 0) {
        kind = until === 0 ? 'due_today' : 'due_soon';
        text = until === 0
          ? `Dear ${d.name}, your EMI of Rs ${sum.nextDueAmount} is due today. ${d.shop} ${d.shop_phone}`
          : `Dear ${d.name}, your EMI of Rs ${sum.nextDueAmount} is due on ${sum.nextDueDate}. ${d.shop} ${d.shop_phone}`;
      }
    }
    if (kind) {
      const sent = await one("select 1 from reminders where device_id = $1 and kind = $2 and created_at::date = $3::date", [d.id, kind, today]);
      if (!sent) {
        const st = await sendSms(d.mobile, text);
        await q('insert into reminders(device_id, kind, channel, message, status) values ($1,$2,$3,$4,$5)', [d.id, kind, 'sms', text, st]);
        await q("insert into reminders(device_id, kind, channel, message, status) values ($1,$2,'device',$3,'queued')", [d.id, kind, text]);
        void pushSync(d.fcm_token, log);
        reminders++;
      }
    }

    // Gradual steps.
    let target: LockState = 'unlocked';
    if (s.autoWarnDays !== null && sum.overdueDays >= Math.max(1, s.autoWarnDays)) target = 'warning';
    if (s.autoRestrictDays !== null && sum.overdueDays >= s.autoRestrictDays) target = 'restricted';
    if (s.autoLockDays !== null && sum.overdueDays >= s.autoLockDays) target = 'locked';
    if (rank[target] > rank[d.lock_state as LockState]) {
      await setLockState(d.id, d.merchant_id, target, { user: null, reason: 'auto', skipRules: true, log });
      steps++;
    }
  }
  return { checked: devices.length, reminders, steps };
}

export function startScheduler(log: any) {
  const tick = () => runDaily(log).then((r) => log.info(r, 'scheduler run')).catch((e) => log.error(e, 'scheduler failed'));
  // every hour; work is idempotent per day
  setTimeout(tick, 15_000);
  return setInterval(tick, 3600_000);
}
