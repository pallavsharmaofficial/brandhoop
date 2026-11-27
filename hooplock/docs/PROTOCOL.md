# Phone ↔ server protocol

## Enrollment

1. Console creates a sale and a single-use enrollment token (30 minutes).
2. The provisioning QR names the admin receiver `in.hooplock.agent/.admin.HoopAdminReceiver`, the APK
   URL, the APK signing-certificate SHA-256 (base64url) and an extras bundle `{server, token}`.
3. The agent calls `POST /agent/v1/enroll` with the token and device info (IMEI, serial, model, SIMs).
   The server consumes one Android key and returns `deviceId`, `apiToken` (stored hashed on the server),
   `commandKey` (32 random bytes, hex) and the first signed state.
4. Customer accepts the agreement on the phone → `POST /agent/v1/consent`.

## Signed state

Every sync returns `{ payload, sig }` where `payload` is a JSON string and
`sig = base64url(HMAC-SHA256(commandKey, payload))`. Fields:

| Key | Meaning |
|---|---|
| `d` | device id (must match) |
| `s` | sequence; phone ignores anything lower than the last applied |
| `st` | `unlocked` / `warning` / `restricted` / `locked` |
| `rel` | release: remove everything |
| `msg` | shop message |
| `shop` | `{name, phone}` |
| `calls` | numbers a locked phone may call |
| `dues` | `{amount, overdueDays, next, balance}` |
| `upi` | `upi://pay?...` link shown as QR |
| `ncl` | epoch seconds: restrict if no contact by then (null = never) |
| `loc` | send location on next sync |
| `frp` | Google account IDs for factory-reset protection |
| `t` | issued at |

Push (FCM) carries only `{t: "sync"}`; the phone then calls `POST /agent/v1/sync`.
Without FCM the phone syncs every 15 minutes (WorkManager).

## Offline SMS

`HL1 <seq> <code> <sig>` with code `U W R L X` (unlock, warning, restrict, lock, release) and
`sig = base64url(first 16 bytes of HMAC-SHA256(commandKey, "HL1|<deviceId>|<seq>|<code>"))`.
The server bumps `seq` when it makes the code, so the phone and server stay in step when it comes
back online. Codes cannot be reused (sequence) or used on another phone (device id + key).
