function env(name: string, fallback?: string): string {
  const v = process.env[name] ?? fallback;
  if (v === undefined) throw new Error(`Missing environment variable ${name}`);
  return v;
}

const production = process.env.NODE_ENV === 'production';

export const config = {
  production,
  port: Number(env('PORT', '8080')),
  databaseUrl: env('DATABASE_URL', 'postgres://hooplock:hooplock@localhost:5432/hooplock'),
  /** Secret for signing console login tokens. Must be long and random in production. */
  jwtSecret: env('JWT_SECRET', production ? undefined : 'dev-only-secret-change-me-0123456789abcdef'),
  /** Public base URL of this server, used in provisioning QR codes and agent config. */
  publicUrl: env('PUBLIC_URL', 'http://localhost:8080').replace(/\/$/, ''),
  /** base64url SHA-256 of the agent APK signing certificate (see agent-android/README.md). */
  agentSignatureChecksum: env('AGENT_SIGNATURE_CHECKSUM', ''),
  agentApkUrl: env('AGENT_APK_URL', ''),
  agentComponent: env('AGENT_COMPONENT', 'in.hooplock.agent/.admin.HoopAdminReceiver'),
  /** Folder with built console web app (Flutter build/web), served at / */
  webDir: env('WEB_DIR', ''),
  /** Folder with agent APK downloads, served at /agent */
  agentDir: env('AGENT_DIR', ''),
  /** Firebase service account JSON (for FCM push). Optional: without it phones sync by polling. */
  fcmServiceAccount: process.env.FCM_SERVICE_ACCOUNT ?? '',
  /** Firebase client config handed to agents at enrollment so they can register for push. */
  fcmClient: {
    projectId: process.env.FCM_PROJECT_ID ?? '',
    appId: process.env.FCM_APP_ID ?? '',
    apiKey: process.env.FCM_API_KEY ?? '',
    senderId: process.env.FCM_SENDER_ID ?? '',
  },
  razorpay: {
    keyId: process.env.RAZORPAY_KEY_ID ?? '',
    keySecret: process.env.RAZORPAY_KEY_SECRET ?? '',
    webhookSecret: process.env.RAZORPAY_WEBHOOK_SECRET ?? '',
  },
  sms: {
    provider: process.env.SMS_PROVIDER ?? 'log', // 'log' | 'msg91'
    msg91AuthKey: process.env.MSG91_AUTH_KEY ?? '',
    msg91TemplateId: process.env.MSG91_TEMPLATE_ID ?? '',
  },
  /** First super admin, created on boot if no super admin exists. */
  bootstrapAdmin: {
    phone: process.env.ADMIN_PHONE ?? '',
    password: process.env.ADMIN_PASSWORD ?? '',
    name: process.env.ADMIN_NAME ?? 'Super Admin',
  },
  runScheduler: (process.env.RUN_SCHEDULER ?? 'true') === 'true',
};
