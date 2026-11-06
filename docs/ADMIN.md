# Shop admin panel

The shop owner manages products, prices, stock, photos, offers, hours and
contact details from his phone, at:

**`https://pallavsharmaofficial.github.io/brandhoop/admin/`**

There is no server. The panel edits `assets/live/shop.json` and uploads photos
to `site/products/` in this repository through the GitHub API, using an access
token that lives only on the owner's phone, encrypted with his PIN. The shop
app and website read that file each time they open, so changes appear in one to
five minutes with nothing to install.

## One-time setup (Pallav, about 3 minutes, in a browser)

1. GitHub, profile photo, **Settings**, **Developer settings**, **Personal
   access tokens**, **Fine-grained tokens**, **Generate new token**.
2. Name: `brandhoop-shop-panel`. Expiration: 90 days is fine for the festival;
   make a new one when it ends.
3. **Repository access**: Only select repositories, then `brandhoop`.
4. **Permissions**, Repository permissions, **Contents: Read and write**.
   Nothing else.
5. Generate, copy the `github_pat_...` token, send it privately to the shop
   owner. He pastes it into the panel once and chooses a PIN.

The token can write this one repository's files and nothing else. If the phone
is lost, delete the token on the same GitHub page and make a new one.

## Using it

- **Sabhi baatein Hindi mein**: the panel is in Hindi with English hints.
- **Products**: add or change name, brand, category, each variant's price, MRP
  and stock, EMI tick, photos from the camera or gallery. "ऐप में दिखाएँ" off
  hides a product without deleting it.
- **Offers**: the Diwali cards on the home screen. Title, line below, last date, and an optional photo behind the text.
- **Call-for-price products**: tick "कीमत कॉल पर" and the app shows only a reference price (name it, for example "Launch price") with a "Call to bargain" button. Untick it and fill the price and MRP to sell at a fixed price; the app then shows how much the customer saves. Add a gift and its worth and the app shows the total benefit.
- **Photo gallery**: festival and gift photos shown in a strip on the home screen.
- **Shop details**: WhatsApp and phone numbers (customers' orders go to the
  WhatsApp number), opening hours and weekly off day.
- **Features**: delivery, phone reservation, repair, exchange. Each is a
  promise to customers, so switch on only what is true.
- **Publish**: nothing reaches customers until "प्रकाशित करें" is pressed.
- **Advanced**: the whole file as text, for backup or a bulk edit.

EMI rates stay "ask at the shop" in the app until the real Bajaj Finserv
schemes are put in the file by a developer (`docs/LIVE.md`).

## Message for the shop owner (Hindi, send on WhatsApp)

```
नमस्ते! ब्रांडहूप ऐप 15 मिनट में तैयार करें:

1) यह खोलें: https://pallavsharmaofficial.github.io/brandhoop/admin/
2) पहली बार: Pallav जी से मिला टोकन चिपकाएँ और अपना PIN बनाएँ। आगे सिर्फ़ PIN।
3) "+ नया सामान" दबाकर हर फ़ोन/एक्सेसरी डालें: नाम, ब्रांड, कीमत, MRP, स्टॉक और फ़ोटो (कैमरे से)।
4) "+ नया ऑफ़र" में दिवाली का ऑफ़र/गिफ़्ट और आख़िरी तारीख़ लिखें।
5) "दुकान की जानकारी" में समय डालें। डिलीवरी, रिपेयर आदि सिर्फ़ तभी चालू करें जब सच में करते हों।
6) सबसे नीचे "प्रकाशित करें" दबाएँ। 2-5 मिनट में ऐप में दिखेगा।
7) ऐप खोलकर देखें: https://pallavsharmaofficial.github.io/brandhoop/app/
8) फिर दिवाली पोस्टर/QR स्टेटस में लगाएँ।

ग्राहक का ऑर्डर आपके WhatsApp 86197 67291 पर आएगा। पैसा दुकान पर ही लें।
```
