import { z } from 'zod';

/** Per-shop rules. Defaults follow the RBI device-loan directions (gradual, notices first). */
export const merchantSettingsSchema = z.object({
  /** Days before the due date to send the first reminder. */
  remindDaysBefore: z.number().int().min(0).max(15).default(3),
  /** Show the full-screen (dismissable) warning after this many days overdue. null = off. */
  autoWarnDays: z.number().int().min(0).max(365).nullable().default(3),
  /** Restrict apps (calls still work) after this many days overdue. null = off. */
  autoRestrictDays: z.number().int().min(1).max(365).nullable().default(30),
  /** Full lock automatically after this many days overdue. null = manual only. */
  autoLockDays: z.number().int().min(1).max(365).nullable().default(null),
  /** A manual lock needs the loan to be overdue (theft/tamper reason overrides). */
  lockRequiresOverdue: z.boolean().default(true),
  /** Unlock as soon as all overdue instalments are paid. */
  autoUnlockOnPayment: z.boolean().default(true),
  /** If the phone does not reach the server for this many days while an EMI is due, it restricts itself. */
  noContactDays: z.number().int().min(3).max(90).default(15),
  /** Only owners can full-lock (staff can warn and restrict). */
  lockNeedsOwner: z.boolean().default(false),
  /**
   * Google account IDs (numeric, from the shop's Google account) allowed to set the phone up after a
   * forced reset. Turns on Factory Reset Protection on Android 11+. Empty = off.
   */
  frpAccountIds: z.array(z.string().regex(/^\d{5,30}$/)).max(3).default([]),
});
export type MerchantSettings = z.infer<typeof merchantSettingsSchema>;

export function settingsOf(raw: unknown): MerchantSettings {
  const r = merchantSettingsSchema.safeParse(raw ?? {});
  return r.success ? r.data : merchantSettingsSchema.parse({});
}
