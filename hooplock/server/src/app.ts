import Fastify, { type FastifyInstance } from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import fastifyStatic from '@fastify/static';
import { existsSync } from 'node:fs';
import path from 'node:path';
import { ZodError } from 'zod';
import { config } from './config.js';
import { HttpError } from './errors.js';
import { authRoutes } from './routes/auth.js';
import { customerRoutes } from './routes/customers.js';
import { deviceRoutes } from './routes/devices.js';
import { agentRoutes } from './routes/agent.js';
import { merchantRoutes } from './routes/merchant.js';
import { paymentRoutes } from './routes/payments.js';
import { provisioningPayload } from './services/devices.js';

export async function buildApp(opts: { logger?: boolean } = {}): Promise<FastifyInstance> {
  const app = Fastify({
    logger: opts.logger === false ? false : { level: config.production ? 'info' : 'debug', redact: ['req.headers.authorization'] },
    trustProxy: true,
    bodyLimit: 1024 * 1024,
  });

  // Keep the raw body for webhook signature checks.
  app.addContentTypeParser('application/json', { parseAs: 'string' }, (req, body, done) => {
    (req as any).rawBody = body;
    if (!body) return done(null, undefined);
    try { done(null, JSON.parse(body as string)); } catch (e) { (e as any).statusCode = 400; done(e as Error, undefined); }
  });

  await app.register(cors, { origin: true, credentials: false });
  await app.register(rateLimit, { max: 300, timeWindow: '1 minute' });

  app.setErrorHandler((err: any, req, reply) => {
    if (err instanceof ZodError) {
      const first = err.issues[0];
      return reply.status(400).send({ error: 'bad_request', message: `${first.path.join('.') || 'input'}: ${first.message}`, issues: err.issues });
    }
    if (err instanceof HttpError) return reply.status(err.statusCode).send({ error: err.code, message: err.message });
    if (err.statusCode && err.statusCode < 500) return reply.status(err.statusCode).send({ error: 'error', message: err.message });
    req.log.error(err);
    return reply.status(500).send({ error: 'server_error', message: 'Something went wrong. Please try again.' });
  });

  app.get('/healthz', async () => ({ ok: true }));

  await app.register(authRoutes);
  await app.register(customerRoutes);
  await app.register(deviceRoutes);
  await app.register(merchantRoutes);
  await app.register(paymentRoutes);
  await app.register(agentRoutes);

  // Debug helper: what a provisioning QR looks like (no token).
  app.get('/agent/provisioning-example', async () => JSON.parse(provisioningPayload('EXAMPLE')));

  if (config.agentDir && existsSync(config.agentDir)) {
    await app.register(fastifyStatic, { root: path.resolve(config.agentDir), prefix: '/agent/', decorateReply: false });
  }
  if (config.webDir && existsSync(config.webDir)) {
    await app.register(fastifyStatic, { root: path.resolve(config.webDir), prefix: '/', wildcard: false });
    // Flutter web is a single-page app: unknown non-API paths serve index.html
    app.setNotFoundHandler((req, reply) => {
      if (req.url.startsWith('/api/') || req.url.startsWith('/agent/')) return reply.status(404).send({ error: 'not_found', message: 'Not found' });
      return reply.sendFile('index.html');
    });
  }
  return app;
}
