import { createHash, createHmac, randomBytes, scrypt as scryptCb, timingSafeEqual } from 'node:crypto';
import { promisify } from 'node:util';

const scrypt = promisify(scryptCb) as (pw: string, salt: Buffer, len: number) => Promise<Buffer>;

export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16);
  const key = await scrypt(password, salt, 32);
  return ['scrypt', salt.toString('base64'), key.toString('base64')].join('$');
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  const [algo, saltB64, keyB64] = stored.split('$');
  if (algo !== 'scrypt' || !saltB64 || !keyB64) return false;
  const expected = Buffer.from(keyB64, 'base64');
  const key = await scrypt(password, Buffer.from(saltB64, 'base64'), expected.length);
  return timingSafeEqual(key, expected);
}

export const randomToken = (bytes = 32) => randomBytes(bytes).toString('base64url');
export const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');

export function hmac(keyHex: string, data: string): Buffer {
  return createHmac('sha256', Buffer.from(keyHex, 'hex')).update(data, 'utf8').digest();
}

export function safeEqual(a: string, b: string): boolean {
  const x = Buffer.from(a);
  const y = Buffer.from(b);
  return x.length === y.length && timingSafeEqual(x, y);
}

export type LockState = 'unlocked' | 'warning' | 'restricted' | 'locked';

/**
 * Signed desired state sent to the Android agent. The agent verifies the HMAC over the exact
 * payload string with the per-device command key it received at enrollment, and refuses any
 * payload whose seq is lower than the last one it applied (no replay of an old unlock).
 */
export function signState(commandKey: string, state: Record<string, unknown>): { payload: string; sig: string } {
  const payload = JSON.stringify(state);
  return { payload, sig: hmac(commandKey, payload).toString('base64url') };
}

export const SMS_CODES: Record<string, string> = {
  unlocked: 'U', warning: 'W', restricted: 'R', locked: 'L', released: 'X',
};

/**
 * Offline command for phones without internet: the shop sends this text by SMS to the customer's
 * SIM. Format: "HL1 <seq> <code> <sig>", sig = first 16 bytes of
 * HMAC-SHA256(key, "HL1|<deviceId>|<seq>|<code>") in base64url.
 */
export function smsCommand(commandKey: string, deviceId: string, seq: number, state: string): string {
  const code = SMS_CODES[state];
  if (!code) throw new Error('No SMS code for ' + state);
  const sig = hmac(commandKey, `HL1|${deviceId}|${seq}|${code}`).subarray(0, 16).toString('base64url');
  return `HL1 ${seq} ${code} ${sig}`;
}
