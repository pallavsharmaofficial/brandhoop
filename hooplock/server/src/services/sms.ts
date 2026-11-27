import { config } from '../config.js';

/**
 * Outgoing SMS for EMI reminders. India requires DLT-registered templates for business SMS, so
 * the MSG91 path sends one approved template with the message as a variable. Until the shop has
 * a DLT template, provider "log" just records the reminder (shown in the console) and the
 * on-phone notice still reaches the customer through the agent.
 */
export async function sendSms(to: string, text: string): Promise<'sent' | 'logged' | 'failed'> {
  if (config.sms.provider !== 'msg91' || !config.sms.msg91AuthKey) return 'logged';
  try {
    const r = await fetch('https://control.msg91.com/api/v5/flow', {
      method: 'POST',
      headers: { authkey: config.sms.msg91AuthKey, 'content-type': 'application/json' },
      body: JSON.stringify({ template_id: config.sms.msg91TemplateId, recipients: [{ mobiles: '91' + to.slice(-10), message: text }] }),
    });
    return r.ok ? 'sent' : 'failed';
  } catch {
    return 'failed';
  }
}
