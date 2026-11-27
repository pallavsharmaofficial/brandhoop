import { q, type Db, pool } from '../db.js';

export async function audit(
  e: { merchantId: string | null; userId: string | null; action: string; target?: string; data?: unknown },
  db: Db = pool,
) {
  await q(
    'insert into audit_log(merchant_id, user_id, action, target, data) values ($1,$2,$3,$4,$5)',
    [e.merchantId, e.userId, e.action, e.target ?? '', JSON.stringify(e.data ?? {})],
    db,
  );
}
