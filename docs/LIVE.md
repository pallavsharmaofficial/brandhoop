# The live storefront

What customers get from the QR code, the website and the APK. There is no
server yet, so this build is a **storefront**, not a shop with accounts:

- Customers browse the catalogue, add to a cart, and tap **Send order on
  WhatsApp**. The order goes to the shop's WhatsApp as a message. The shop
  confirms stock, price and offers and takes payment itself, at the shop or
  however it tells the customer.
- No sign-in, no online payment, no Autopay, no back office. Nothing pretends to
  take money.
- Hindi and English. Works on the phone's browser and as an Android app.

The full app (accounts, orders, EMI plans, counter sale, reports) is built and is
the **demo** build, `flutter run` with no flags. It needs the backend in
`docs/BACKEND.md` before real customers can use it.

## Where it lives

| What | Address |
|---|---|
| Site, QR and poster | `https://pallavsharmaofficial.github.io/brandhoop/` |
| Shop app in the browser | `.../brandhoop/app/` |
| Android APK | `.../brandhoop/download/brandhoop.apk` |
| The shop's data file | `.../brandhoop/live/shop.json` |

Everything is published by `.github/workflows/pages.yml` on every push to
`main`, and from the Actions tab with **Run workflow**. It needs two one-time
settings: the repository must be **public** (GitHub Pages is not available to
private repositories on a free account), and Settings, Pages, Source must be
**GitHub Actions**.

## Changing prices, products and offers (no rebuild of the app)

The shop owner does this from his phone with the **admin panel** (`docs/ADMIN.md`,
`.../brandhoop/admin/`). The rest of this section is the file format, for
anyone editing the file by hand.

Everything customers see about the shop comes from one file:
**`assets/live/shop.json`**. Edit it on GitHub (open the file, tap the pencil,
change, Commit). The site republishes in about four minutes, and every app
and browser picks it up the next time it opens. The Android app does not need
reinstalling.

The workflow refuses to publish a file that is not valid JSON, and the app
skips one product with a typo instead of failing, so a mistake costs one
product, not the shop.

### What the file holds

```json
{
  "settings": {
    "whatsapp": "98xxxxxxxx",
    "phone": "98xxxxxxxx",
    "emiRatesConfirmed": false,
    "hours": {
      "1": {"open": 600, "close": 1260}, "2": {"open": 600, "close": 1260},
      "3": {"open": 600, "close": 1260}, "4": {"open": 600, "close": 1260},
      "5": {"open": 600, "close": 1260}, "6": {"open": 600, "close": 1260},
      "7": {"open": 600, "close": 1260}
    }
  },
  "features": { "repair": false, "exchange": false, "delivery": false, "reserve": false },
  "offers": [
    { "id": "diwali", "kind": "banner",
      "title":    { "en": "Diwali Dhamaka", "hi": "दिवाली धमाका" },
      "subtitle": { "en": "Free gift with every phone", "hi": "हर फ़ोन के साथ उपहार" },
      "endsAt": "2026-11-15T23:59:00", "colorSeed": 1 }
  ],
  "products": [
    { "id": "phone-1",
      "name": { "en": "Brand Model 5G", "hi": "" },
      "brand": "Brand",
      "category": "smartphone",
      "featured": true,
      "highlights": [ { "en": "5000 mAh battery", "hi": "" } ],
      "specs": { "ram": "8 GB", "storage": "128 GB" },
      "imageUrls": [],
      "warrantyMonths": 12,
      "emiEligible": true,
      "variants": [
        { "id": "v1", "label": "8 GB + 128 GB", "color": "Black",
          "price": 15999, "mrp": 18999, "stock": 4 }
      ] }
  ]
}
```

- `category` is one of: smartphone, featurePhone, tablet, earphones, charger,
  cable, caseCover, screenGuard, powerBank, smartwatch, speaker, memory,
  protection.
- `price` is what the customer pays, `mrp` the printed price, whole rupees,
  GST included. `stock` of 0 shows "out of stock".
- `imageUrls` can hold photo links (https). With none, the app draws a phone
  or accessory in the brand's colours.
- `hours` is the opening hours. Until it is given, the app shows no "Open now"
  and no visit planner, so it never guesses. `open` and `close` are minutes from
  midnight (600 is 10:00, 1260 is 21:00). Days run 1 (Monday) to 7 (Sunday); a
  day left out is shown as closed.
- `warrantyMonths` shows a warranty line only when it is set.

### Call-for-price products, gifts, gallery

- A product with `"callForBest": true` shows a **reference price** (named by
  `refPriceLabel`, for example "Launch price (Dec 2025)") and a "Call to
  bargain" / "Ask offer on WhatsApp" bar. It is never added to a cart and never
  shown "in stock". A variant price of 0 shows "Price on call".
- Without `callForBest`, `price` is the shop's price and `mrp` the printed
  price; the app shows "You save" and a normal Add to cart / Buy now.
- `gift` (`{"en","hi"}`) and `giftValue` (rupees) show the gift and, with a
  saving, the total benefit.
- `gallery` is a list of `{"url", "caption": {"en","hi"}}` shown as a photo
  strip on the home screen; an offer's `imageUrl` puts a photo behind its text.
  Photo URLs are `https://raw.githubusercontent.com/pallavsharmaofficial/brandhoop/main/site/...`.
  The admin panel uploads them for you.

### Things the app shows only when this file turns them on

The storefront promises nothing that the shop has not said. Each of these is
off until you switch it on, and each is a promise to the customer, so switch
on only what is true.

| Setting | What it shows |
|---|---|
| `settings.whatsapp` | Orders go straight to this WhatsApp chat. Without it the customer is shown the order text to share or copy. |
| `settings.phone` | A Call button. |
| `settings.emiRatesConfirmed: true` | The EMI calculator and "EMI from ₹x a month" on phones. Set it only when `emiSchemes` carry the real Bajaj Finserv rates; until then the EMI tab says "ask at the shop". |
| `features.delivery` | The delivery panel on product pages (the wording says same-day home delivery in town; change the shop's `localPincodes` too). |
| `features.reserve` | "Reserve this phone for ₹1,000, held 72 hours". Orders are not paid in the app, so turn this on only if the shop will hold phones that way. |
| `features.repair`, `features.exchange` | The repair and exchange tiles; both send a WhatsApp message. |

## The QR code and poster

`site/qr/` holds `brandhoop-qr.png`, `brandhoop-qr.svg` and
`diwali-poster.png` (1080 x 1920 for a WhatsApp status). The QR opens the site
home page, which has the app, the APK and directions in one place, so Android
and iPhone customers both land somewhere that works.

To redraw after a change (a phone number, another address):

```bash
pip install segno
python3 tools/poster/make_poster.py --phone 98xxxxxxxx
node tools/poster/shoot.js        # needs playwright
```

## Android APK

Built in CI with `flutter build apk --release --dart-define=BRANDHOOP_DEMO=false`
and signed with a debug key that CI keeps between builds, so a new APK installs over the old
one. Customers must allow "install unknown apps" for their browser, and Play
Protect may ask for confirmation, because the app is not from the Play Store.
For the Play Store use `docs/LAUNCH.md` and a real signing key.

## What is still missing for a full shop

Payments, accounts, order tracking and the back office all need a server
(`docs/BACKEND.md`), a payment provider and a Bajaj Finserv dealer agreement
(`docs/PAYMENTS.md`). Until then, WhatsApp is the order desk.
