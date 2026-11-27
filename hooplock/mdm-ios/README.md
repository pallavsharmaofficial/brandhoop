# iPhone locking (Apple MDM)

The HoopLock server already speaks to an MDM server (`server/src/services/mdm.ts`, tested against a
fake NanoMDM in `server/test/ios.test.ts`). What remains is Apple paperwork and running NanoMDM.

## What happens

| Shop action | iPhone command |
|---|---|
| Phone finishes setup | profile that blocks "Erase All Content and Settings"; one iOS key used |
| Lock | `EnableLostMode`: full-screen message, shop phone, emergency calls only |
| Unlock / EMI paid | `DisableLostMode` |
| Locate (only while locked) | `DeviceLocation` → map in the console |
| Release | `RemoveProfile`, then release the serial in Apple Business Manager |
| Customer removes management | console shows Uninstalled + tamper alert (cannot happen on ADE-enrolled phones) |

Warning and app restriction do not exist on iPhone; reminders are sent instead.

## One-time setup (your side)

1. **D-U-N-S number** (free, dnb.com) for the business.
2. **Apple Business Manager** account (business.apple.com) with the D-U-N-S number.
3. **APNs MDM push certificate**: create a CSR, get it signed by an MDM vendor CSR service
   (e.g. mdmcert.download) or by your own Apple Developer Enterprise account, then upload it at
   identity.apple.com/pushcert. Renew every year with the same Apple ID.
4. **Run NanoMDM**: `deploy/docker-compose.yml`, profile `ios`, on a domain like `mdm.yourdomain.in`.
   Upload the push certificate with `PUT /v1/pushcert`.
5. **Enrollment profile**: create an MDM enrollment profile (`/mdm` URL of NanoMDM, SCEP or
   identity) and an ADE profile that is **supervised** and **not removable**. Assign NanoMDM as the
   MDM server in ABM (Preferences → Your MDM Servers) and as the default for iPhones.
6. Set `NANOMDM_URL`, `NANOMDM_API_KEY`, `MDM_WEBHOOK_SECRET` on the HoopLock server.

## Per iPhone at the counter

1. In the console: iPhone → new sale with the serial number.
2. Add the iPhone to ABM: your distributor adds it with your Organisation ID, or staff use the
   free **Apple Configurator** app on a shop iPhone (new phones only; 30-day removable window).
3. Turn the iPhone on and finish setup. It enrolls and shows **Active** in the console.

See `docs/RESEARCH.md` for the risks (30-day window, ABM terms, hire-purchase ownership).
