import pg from 'pg';
import { config } from './config.js';

// numeric -> JS number (amounts are rupees with 2 decimals, well within double precision)
pg.types.setTypeParser(1700, (v) => Number(v));
// date -> 'YYYY-MM-DD' string, never shifted by time zone
pg.types.setTypeParser(1082, (v) => v);
// int8 (counts) -> number
pg.types.setTypeParser(20, (v) => Number(v));

export type Db = pg.Pool | pg.PoolClient;

export let pool = new pg.Pool({ connectionString: config.databaseUrl, max: 10 });

export function setPool(p: pg.Pool) {
  pool = p;
}

export async function q<T = any>(sql: string, params: unknown[] = [], db: Db = pool): Promise<T[]> {
  const r = await db.query(sql, params as any[]);
  return r.rows as T[];
}

export async function one<T = any>(sql: string, params: unknown[] = [], db: Db = pool): Promise<T | undefined> {
  const rows = await q<T>(sql, params, db);
  return rows[0];
}

export async function tx<T>(fn: (c: pg.PoolClient) => Promise<T>): Promise<T> {
  const c = await pool.connect();
  try {
    await c.query('begin');
    const r = await fn(c);
    await c.query('commit');
    return r;
  } catch (e) {
    await c.query('rollback');
    throw e;
  } finally {
    c.release();
  }
}
