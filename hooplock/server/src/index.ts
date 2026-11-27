import { buildApp } from './app.js';
import { config } from './config.js';
import { one, q } from './db.js';
import { migrate } from './migrate.js';
import { hashPassword } from './security.js';
import { startScheduler } from './services/scheduler.js';

async function bootstrapAdmin(log: any) {
  const exists = await one("select 1 from users where role = 'super_admin'");
  if (exists) return;
  const { phone, password, name } = config.bootstrapAdmin;
  if (!phone || !password) {
    log.warn('No super admin yet. Set ADMIN_PHONE and ADMIN_PASSWORD and restart to create one.');
    return;
  }
  await q("insert into users(role, name, phone, password_hash) values ('super_admin',$1,$2,$3)", [name, phone, await hashPassword(password)]);
  log.info({ phone }, 'Super admin created');
}

const app = await buildApp();
const applied = await migrate();
if (applied.length) app.log.info({ applied }, 'migrations applied');
await bootstrapAdmin(app.log);
if (config.runScheduler) startScheduler(app.log);
await app.listen({ port: config.port, host: '0.0.0.0' });
