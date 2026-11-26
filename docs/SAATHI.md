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

## On-device AI (beta)
Settings (⚙ in the assistant) offers a small language model that runs on the phone's GPU through WebLLM
(`@mlc-ai/web-llm` 0.2.89, models Qwen2.5 0.5B/1.5B or Gemma 2 2B). It downloads once (0.4 to 1.6 GB), then answers coaching questions
without internet, using the same knowledge and the live catalogue as context. It can only advise. It cannot change data, so a wrong
answer cannot damage the shop. It needs Chrome with WebGPU (recent Android phones with enough memory). Small models are weaker in Hindi than
in English; the playbooks work without it and are the main source of advice.

## Voice
Typing always works. The microphone uses the browser's speech recognition (Hindi or English). On Android Chrome this normally goes
through Google's speech service and needs internet; Chrome's fully offline speech needs the Hindi language pack installed.
Replies can be read out loud (⚙, "जवाब बोलकर सुनाओ").

## Files
`site/admin/saathi/kb.js` knowledge, `saathi.js` commands and screen, `llm.js` optional model loader, `site/admin/manifest.webmanifest`
and `sw.js` for installing the panel as an app.
