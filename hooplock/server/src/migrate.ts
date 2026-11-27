import { readdir, readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import { pool } from './db.js';

const here = path.dirname(fileURLToPath(import.meta.url));

function migrationsDir() {
  // works from src/ (tsx) and dist/src/ (compiled)
  return here.includes(`${path.sep}dist${path.sep}`)
    ? path.resolve(here, '../../migrations')
    : path.resolve(here, '../migrations');
}

export async function migrate(): Promise<string[]> {
  await pool.query('create table if not exists schema_migrations (name text primary key, applied_at timestamptz not null default now())');
  await pool.query('select pg_advisory_lock(424242)');
  try {
    const done = new Set((await pool.query('select name from schema_migrations')).rows.map((r) => r.name));
    const files = (await readdir(migrationsDir())).filter((f) => f.endsWith('.sql')).sort();
    const applied: string[] = [];
    for (const f of files) {
      if (done.has(f)) continue;
      const sql = await readFile(path.join(migrationsDir(), f), 'utf8');
      const c = await pool.connect();
      try {
        await c.query('begin');
        await c.query(sql);
        await c.query('insert into schema_migrations(name) values ($1)', [f]);
        await c.query('commit');
        applied.push(f);
      } catch (e) {
        await c.query('rollback');
        throw new Error(`Migration ${f} failed: ${(e as Error).message}`);
      } finally {
        c.release();
      }
    }
    return applied;
  } finally {
    await pool.query('select pg_advisory_unlock(424242)');
  }
}

if (process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1])) {
  migrate()
    .then((a) => { console.log(a.length ? `Applied: ${a.join(', ')}` : 'Up to date'); return pool.end(); })
    .catch((e) => { console.error(e); process.exit(1); });
}
