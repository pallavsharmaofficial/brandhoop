# The road to ₹5 lakh a month

**Read this first.** Everything below is arithmetic on stated assumptions, not a
forecast and not a promise. The numbers marked *assumption* are guesses for a
Rajasthan town shop and must be replaced with the shop's real figures (the app's
owner dashboard and reports will show them once it is used). "Profit" here means
margin after GST on margin, payment fees and no-cost EMI subvention, **before**
rent, salaries and electricity, as the dashboard shows it.

## Where the shop is
The owner's current monthly profit goes in Store settings (Admin, More, Store settings) so the dashboard can show progress against it. It is deliberately not written in this repository.

## One way to reach ₹5 lakh (illustrative end state)

| Lever | Volume per month | Margin each (*assumption*) | Monthly profit |
|---|---:|---:|---:|
| Phones | 220 | ₹1,200 | ₹2,64,000 |
| Accessories sold with phones (70% attach) | 154 | ₹250 | ₹38,500 |
| Other accessories, chargers, cases | walk-in and online | | ₹50,000 |
| Protection plans (40% of phones) | 88 | ₹300 | ₹26,400 |
| Repairs | 220 | ₹350 | ₹77,000 |
| Old-phone exchange, finance and recharge commissions | | | ₹44,100 |
| **Total** | | | **₹5,00,000** |

These are the targets in `GrowthTargets` (`lib/services/analytics.dart`): 220 phones,
70% accessory attach, 40% protection, 220 repairs, 35% lead conversion, 40% repeat.

**The hard line is 220 phones a month**, about seven a day. At roughly
₹1,200 a phone, even 120 phones gives only ₹1.4 lakh. Reaching 220 needs buyers
from the villages around Neem Ka Thana and from nearby towns, not just the
town. That reach is what the app is for: a trusted shop, visible prices, EMI that
removes the "I cannot pay all at once" barrier, and a reservation that costs
the buyer nothing to try. Whether that volume exists is the one thing no plan
can settle in advance. Test it stage by stage.

## Stages and what to check at each

| Stage | Months | Aim (profit/month) | What has to be true to move on |
|---|---|---:|---|
| 1. Switch on | 1–2 | up to ₹60k | App live with real stock, prices, photos. Every walk-in customer is shown the QR and installed. Phones about 60 a month. |
| 2. EMI and trust | 3–5 | ₹60k–1.5L | Bajaj dealer agreement live. Half of phone buyers ask about EMI. Reviews and shop photos on Google. Phones about 100–130. |
| 3. Reach | 6–9 | ₹1.5–3L | Buyers from surrounding villages. Reserve-and-visit converts. Repairs and exchange are steady. Phones 150–180. |
| 4. Scale | 10–12 | ₹3–5L | Repeat and referral buyers are 40%. Accessories attach 70%. Phones near 220. |

If a stage misses by more than a third for two months, stop and find out why
before spending more (price, stock, trust, reach), instead of waiting for the
next stage to fix it. The goal may still be reachable later, or the shop's real
ceiling may be lower; both are useful to know.

## What the app does for each lever

- **Phones:** online catalogue, reserve with token, EMI everywhere in the
  buying flow, exchange estimate, "visit the shop" planner, offers and coupons.
- **Accessories:** the dashboard measures the attach rate and the shop sells accessories online and at the counter. Accessory suggestions at checkout and at the POS, and bundles, are not built yet (`docs/ROADMAP.md`, stage 2); they are the first thing to add because attach is the cheapest lever.
- **Repairs:** online booking and status updates, which also bring people in.
- **Repeat:** wishlist, referral code, EMI reminders, loyalty coins.
- **Control:** the owner dashboard shows today's sales, profit, the gap to ₹5 lakh,
  stock alerts and the growth scorecard so the numbers above are measured, not guessed.

## Cautions

- Check margins on real invoices. A phone that earns ₹600, not ₹1,200, doubles the
  volume needed.
- EMI offers that cost the shop (no-cost EMI subvention) can wipe out the margin.
  The app shows that cost per plan; keep it in view.
- Take advice on GST, and on whether to sell finance, before advertising it.
