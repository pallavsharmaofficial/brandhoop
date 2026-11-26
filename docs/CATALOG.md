# The starting catalogue

`assets/live/shop.json` ships with **127 items**: 74 phones (72 smartphones and
2 keypad phones) and 53 accessory types. It is a starting point the owner
edits in the admin panel (`docs/ADMIN.md`): change names, add real prices, gifts
and photos, hide what the shop does not stock, add what is missing.

## What is in it

- **Phones**: popular models in India across the price bands, from under ₹10,000
  to the iPhone 17 Pro. Each shows its **launch price** where the Indian press
  agreed on one, with "Call for best price" and "Call to bargain". Where
  reports disagreed or none was found, it shows "Price on call". These are
  references, not the shop's prices; several models have changed price since
  launch. Sources are in `docs/CREDITS.md`.
- **Accessories**: earphones, headphones, chargers, cables, power banks, cases,
  screen guards, smartwatches and bands, speakers, memory cards and pen drives,
  stands, holders and tripods. These are item *types* with "Price on call"
  and a "tell us your phone model" hint where fit matters. Nothing here is a
  branded product the shop is claimed to stock.
- **Photos**: the shop's own box photos, free-licence photos of real phone
  models from Wikimedia Commons (credited on `site/credits.html`), and free
  Pexels photos of each accessory type marked "Photo for illustration". A
  phone with no photo shows a drawn phone with the brand name.

## Regenerating or extending

`tools/catalog/phones.py` and `tools/catalog/accessories.py` hold the lists;
`python3 tools/catalog/build_catalog.py` rewrites the products in
`shop.json` from them (settings, offers, gallery and features are kept). Do
this only before the owner starts editing in the panel, because it replaces
the products.

## Before selling

1. Replace launch prices with the shop's real prices where it quotes a fixed
   price (untick "call for price" in the panel), and add gifts.
2. Hide or delete what the shop does not stock.
3. Add real photos of what is on the counter.

## Models added from the owner's list (Nov 2026)

vivo Y11, Y21, Y31t, Y51 Pro, S2, S2 FE, V70 FE and V80; OPPO A6, K14x, K14,
F35, F35 Pro, Reno 16c and Reno 16 (A6x was already there); Nothing Phone (4a)
and (4b). The list said "V8", which is read as the V80, the only matching
model. Prices are launch prices from Indian press reports. Where the press
reported a later rise (memory-chip costs), the app says "raised since, call for
today's price" next to the launch price, so an old figure never looks current.
Those models are listed in `RAISED` in `tools/catalog/phones.py`.

## Printable shop kit (Nov 2026)

`site/shop-kit/` has A4 PDFs the owner prints: price strips for every phone and
accessory (price left blank to write by hand, with a WhatsApp QR that names the
model), counter signs (combo offer, price-lock draft, services, pre-owned,
payments and EMI, app QR), a shop plan and a Hindi checklist. Rebuild with
`python3 tools/shopkit/make_kit.py && node tools/shopkit/shoot.js`. The strips
come from the same lists as the app, so re-run after the catalogue changes.

## Shop prices and the OPPO range (26 Nov 2026)

`tools/catalog/shop_data.py` holds the prices the owner gave for each model (every RAM + storage variant), plus highlights and specs for the product page. A model listed there shows the shop's price, dated, with the "Shop price, updated <date>" label. The phone still opens WhatsApp ("ask availability"), because the live storefront has no checkout and the shop's real stock is not known.

`ONLY_SHOP_PHONES = True` leaves every phone without owner pricing out of `assets/live/shop.json` (they stay in `phones.py`). Set it to `False` to show the old launch-price list again. Run `python3 tools/catalog/build_catalog.py` after any change.

Specs were checked against Indian news and price-list pages (91mobiles, Beebom, FoneArena, GSMArena, Digit, Gizmochina, Smartprix, OPPO India). Where sources disagreed the spec was left out: F35 and F35 Pro chipset, the F35 series display refresh rate, and the Reno 16c battery and charging. Free-licence photos (Wikimedia Commons) do not exist for these 2025-26 models, so they use the drawn placeholder until the shop adds its own photos in the admin panel.
