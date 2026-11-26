# Saathi: the shop assistant in the admin panel

Naresh opens `/admin/` on his phone (Chrome, "Install" button, or Share then Add to Home Screen on iPhone). After the one-time
token and PIN setup, a **🎙️ सहायक** button floats on every screen. He can type or speak (Hindi, English or Hinglish).

## What it does
| Say | What happens |
|---|---|
| "A6x 4/128 का रेट 22999 कर दो" | shows old and new price, waits for "हाँ", changes it, stamps today's date |
| "K14x के रेट 500 बढ़ा दो" | changes every variant of that phone by 500 |
| "नया फ़ोन ओप्पो A7 5G 6/128 29999 और 8/128 32999" | adds a phone with those variants |
| "K14 5G ऐप से छुपा दो" / "K14 दिखा दो" | hides or shows it (nothing is deleted) |
| "... हमेशा के लिए हटा दो" | deletes it, after a separate confirmation |
| "ऑफ़र लगाओ: ..." | adds a home-screen banner |
| "दुकान का समय सुबह 10 से रात 9, रविवार बंद" | sets opening hours and the weekly off day |
| "A6x की फ़ोटो" | opens the camera or gallery and attaches the photo |
| "रेट की सूची चिपकानी है" | paste the distributor's list, check it line by line, apply all |
| "ओप्पो के कितने फ़ोन हैं", "सबसे सस्ता कौन-सा" | answers from the live catalogue |
| "आज का प्लान", "शाम का हिसाब", "क्विज़" | the daily routine, with nudges from real data (old prices, missing photos, unpublished changes) |
| "ग्राहक का बजट कम है", "रील क्या बनाऊँ", "EMI कैसे बताऊँ" | coaching playbooks |
| "वापस करो" | undoes the last change |

## Safety rules built in
* Every change is shown first and needs a "हाँ". A price that moves by more than 30% gets a warning.
* Nothing goes live until the existing **प्रकाशित करें** button is pressed (the assistant offers that button after each change).
* Hide is the default for "remove". Deleting needs its own confirmation. Undo works for the whole session.
* The assistant follows the shop's rules in `saathi/kb.js`: no invented stock, discounts, ratings or EMI promises.
* No server is involved. The token never leaves the phone except to talk to GitHub, as before.

## The coaching model
`saathi/kb.js` holds the shop facts, the rules, nine principles and 21 playbooks. Each coaching answer has the same shape:
understanding, three steps, the first step for today, how to check tonight, one principle and one question to ask yourself.
The principles are paraphrased in our own words, inspired by what Shiv Khera teaches (attitude, values and integrity, goals, planning,
customer service, win-win). They are not quotations from his books, and the assistant is not him and is not endorsed by him.
The catalogue is not stored in the knowledge file. The assistant reads the live `shop.json` each time, so prices and specs are always current.

To teach it something new, add a playbook to `kb.js` (title, keywords, three steps, first step, check) and publish.

## Offline first
* The panel opens with no signal (the page, the assistant and the last shop file are stored on the phone).
* Every change is saved on the phone as a draft, photos included. Closing the app or losing signal loses nothing; the draft comes back at the next open.
* "प्रकाशित करें" with no signal is queued. When the signal returns it is sent by itself (an "online" event, and a check every 30 seconds).
* If the file on GitHub changed meanwhile (for example the catalogue was rebuilt), the owner's changes are merged into the newer file product by product, offer by offer, setting by setting. If both sides changed the same field, the owner's value is kept and a note is shown.
* The light in the header shows the state: ● online, ○ offline with changes saved, ⏳ queued to publish.
* `tools/catalog/build_catalog.py` keeps the owner's edits: a product changed from the panel after the date in `shop_data.UPDATED`, and any product the owner added, are not overwritten by a rebuild.
* Code: `site/admin/sync.js` (draft, cache, merge, queued publish), `sw.js` (offline shell).

## Which brain answers (cloud, on-device, playbook)
Commands (rates, adding, hiding, offers, hours, photos) never need an AI and work offline and instantly. For advice:
1. A clear playbook match is answered at once from `kb.js`. That is the fastest and most relevant answer.
2. Otherwise the assistant picks between the **cloud AI** (Claude API, internet and a key the owner types in) and the **on-device AI** (WebLLM on the phone's GPU).
   Each has a score: quality (starts 0.8 cloud, 0.6 on-device; moves with the owner's 👍 and 👎) minus 0.04 per second of time to first word.
   The higher score is tried first. A cloud failure or a start slower than 9 seconds rests the cloud for five minutes and the next one answers.
   With no signal only the on-device AI and the playbooks are available.
3. If no AI is available the playbook is used. Settings (⚙) let the owner force cloud only, on-device only, or automatic.

Neither AI can change shop data. They only advise, so a wrong answer cannot damage the shop.

**Cloud AI and privacy.** The key is entered in ⚙, kept on the phone sealed with the owner's PIN (same method as the GitHub token) and sent only to
`api.anthropic.com`. In cloud mode the question, the recent chat and a short list of phones with rates go to Anthropic. In offline mode nothing leaves the phone.
Use a separate key with a low spending limit. The default model is `claude-haiku-5-5` and can be changed in ⚙.

**On-device AI.** `@mlc-ai/web-llm` 0.2.89 with Gemma 2 2B (recommended), Qwen2.5 1.5B or 0.5B. It downloads once (0.4 to 1.6 GB), is kept in the
browser's storage (the panel asks Chrome to keep it) and loads in the background the next time the assistant is opened. It needs Chrome with WebGPU.
Small models are weaker in Hindi than in English, so the playbooks stay the main source of advice.

## Voice
Typing always works. The microphone uses the browser's speech recognition (Hindi or English). Online it normally goes through Google's speech service.
With no signal the assistant asks Chrome for on-device recognition; that needs the Hindi voice pack, which ⚙ can download once while online.
Replies can be read out loud (⚙, "जवाब बोलकर सुनाओ").

## Files
`site/admin/saathi/kb.js` knowledge, `saathi.js` commands, brain switch and screen, `llm.js` on-device and cloud AI loaders, `site/admin/sync.js` offline layer,
`site/admin/manifest.webmanifest` and `sw.js` for installing the panel as an app.
