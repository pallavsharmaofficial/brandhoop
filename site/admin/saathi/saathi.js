/* Saathi: the shop assistant inside the admin panel.
   It understands typed or spoken Hindi / English / Hinglish commands, shows what it is about to change and waits for a yes,
   and keeps an undo list. Changes only go live when the owner presses "प्रकाशित करें" (the panel's own publish button).
   Nothing here talks to a server. An optional on-device language model (llm.js) can answer coaching questions; it never changes data. */
(function () {
  'use strict';
  var KB = window.SAATHI_KB, A = window.AdminAPI;
  if (!KB || !A) return;
  var $ = function (id) { return document.getElementById(id); };
  function h(tag, props) {
    var e = document.createElement(tag); props = props || {};
    Object.keys(props).forEach(function (k) { if (k === 'class') e.className = props[k]; else if (k.slice(0, 2) === 'on') e[k] = props[k]; else e.setAttribute(k, props[k]); });
    for (var i = 2; i < arguments.length; i++) { var c = arguments[i]; if (c == null) continue; e.append(c.nodeType ? c : document.createTextNode(String(c))); }
    return e;
  }
  var MON_EN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  var MON_HI = ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
  var rupee = function (n) { return '₹' + Number(n).toLocaleString('en-IN'); };

  /* ---------- reading what was said ---------- */
  var BRANDS = [['ओप्पो', 'oppo'], ['ऑप्पो', 'oppo'], ['ओपो', 'oppo'], ['विवो', 'vivo'], ['वीवो', 'vivo'], ['सैमसंग', 'samsung'], ['सेमसंग', 'samsung'], ['रेडमी', 'redmi'], ['रियलमी', 'realme'], ['रीयलमी', 'realme'], ['पोको', 'poco'], ['आईकू', 'iqoo'], ['आईफोन', 'iphone'], ['आईफ़ोन', 'iphone'], ['वनप्लस', 'oneplus'], ['मोटोरोला', 'motorola'], ['नथिंग', 'nothing'], ['टेक्नो', 'tecno'], ['इनफिनिक्स', 'infinix'], ['नोकिया', 'nokia'], ['पिक्सल', 'pixel'], ['रेनो', 'reno'], ['गैलेक्सी', 'galaxy'], ['नार्ज़ो', 'narzo'], ['प्रो', 'pro'], ['प्लस', 'plus'], ['पावर', 'power'], ['लाइट', 'lite']];
  var LETTER = { 'ए': 'a', 'एफ़': 'f', 'एफ': 'f', 'के': 'k', 'वाई': 'y', 'वी': 'v', 'एस': 's', 'एम': 'm', 'एक्स': 'x', 'आर': 'r', 'सी': 'c', 'ई': 'e', 'बी': 'b', 'पी': 'p' };
  var NUMW = { 'सिक्सटीन': 16, 'फिफ्टीन': 15, 'फोर्टीन': 14, 'थर्टीन': 13, 'ट्वेल्व': 12, 'सेवेंटीन': 17, 'एटीन': 18, 'सोलह': 16, 'पंद्रह': 15, 'चौदह': 14, 'तेरह': 13, 'बारह': 12, 'ग्यारह': 11, 'सत्रह': 17, 'अट्ठारह': 18, 'दस': 10, 'नौ': 9, 'आठ': 8, 'सात': 7, 'छह': 6, 'छः': 6, 'छे': 6, 'सिक्स': 6, 'पांच': 5, 'पाँच': 5, 'फाइव': 5, 'चार': 4, 'फोर': 4, 'तीन': 3, 'थ्री': 3, 'दो': 2, 'टू': 2, 'एक': 1, 'वन': 1, 'सेवन': 7, 'एट': 8, 'नाइन': 9, 'टेन': 10 };
  var STOP = {};
  ('ka ki ke ko rate price kar karo do de dena daam kimat kya hai hain ab se me mein par pe wala wali phone mobile model set change badlo badal update karna kijiye please plz bhai sir ji the is to of for rs rupaye rupees gb ram storage variant ye woh aur ya naya nayi add new jodo ' +
    'का की के को रेट कीमत दाम कर करो दो दे क्या है हैं अब से में पर नया नई वाला वाली फोन मोबाइल मॉडल बदलो बदल अपडेट कीजिए भाई सर जी रुपये रुपए जीबी रैम स्टोरेज वेरिएंट ये वो और या जोड़ो जोड़ दो हटा हटाओ छुपा छुपाओ दिखाओ')
    .split(/\s+/).forEach(function (w) { STOP[w] = 1; });

  function norm(text) {
    var t = String(text || '').toLowerCase();
    t = t.replace(/[०-९]/g, function (d) { return '०१२३४५६७८९'.indexOf(d); }).replace(/(\d),(\d{3})/g, '$1$2').replace(/(\d),(\d{3})/g, '$1$2').replace(/₹/g, ' ');
    BRANDS.slice().sort(function (a, b) { return b[0].length - a[0].length; }).forEach(function (b) { t = t.split(b[0]).join(' ' + b[1] + ' '); });
    var keys = Object.keys(LETTER).sort(function (a, b) { return b.length - a.length; }).join('|');
    t = t.replace(new RegExp('(^|\\s)(' + keys + ')\\s*(?=\\d)', 'g'), function (m, s, k) { return s + LETTER[k]; });
    Object.keys(NUMW).sort(function (a, b) { return b.length - a.length; }).forEach(function (w) {
      t = t.replace(new RegExp('(^|\\s)([a-z]|reno)\\s*' + w + '(?=\\s|$)', 'g'), function (m, s, p) { return s + p + NUMW[w]; });
    });
    t = t.replace(/(\d)\s*(एक्स|एस|सी|ई)(?=\s|$)/g, function (m, d, k) { return d + LETTER[k]; });
    t = t.replace(/\b([a-z])\s+(\d{1,2})\b/g, '$1$2').replace(/(\b[a-z]\d{1,2})\s+(x|c|s|e)\b/g, '$1$2').replace(/(\d)\s+(g)\b/g, '$1$2').replace(/(\b\d{1,2})\s+(c|x|s|e)\b/g, '$1$2');
    return t;
  }
  function toks(t) { return String(t).toLowerCase().split(/[^a-z0-9]+/).filter(Boolean); }
  function has(t, words) { var s = String(t).toLowerCase(); return words.some(function (w) { return s.indexOf(w) !== -1; }); }

  // "4/128", "6 + 128", "4 128 gb" -> { ram: 4, rom: 128 }
  function variantSpec(t, after) {
    var m = /(?:^|\D)(\d{1,2})\s*(?:gb)?\s*[\/+x\-]\s*(\d{2,4})\s*(?:gb)?(?!\d)/.exec(t) || /(?:^|\D)(\d{1,2})\s+(32|64|128|256|512|1024)(?!\d)/.exec(t);
    if (!m) return null;
    var ram = +m[1], rom = +m[2]; if (ram > 24 || rom < 16) return null;
    return { ram: ram, rom: rom, text: m[0], index: m.index, label: ram + ' GB + ' + rom + ' GB' };
  }
  function labelNums(label) { var m = /(\d+)\s*GB\s*\+\s*(\d+)\s*GB/i.exec(label || ''); return m ? { ram: +m[1], rom: +m[2] } : null; }
  function singleRom(label) { var m = /^(\d+)\s*GB$/i.exec((label || '').trim()); return m ? +m[1] : null; }
  function pricesIn(t) {
    var out = []; var s = t.replace(/(\d+(?:\.\d+)?)\s*(?:हज़ार|हजार|hazar|hazaar|k)(?![a-z0-9])/g, function (m, n) { return ' ' + Math.round(parseFloat(n) * 1000) + ' '; });
    (s.match(/\d{3,6}/g) || []).forEach(function (n) { n = +n; if (n >= 500 && n <= 999999) out.push(n); });
    return out;
  }

  /* ---------- finding the product ---------- */
  function shopProducts() { return A.shop().products || []; }
  function pname(p) { return (p.name && p.name.en) || p.id; }
  function matchProducts(text) {
    var qs = {}; toks(text).forEach(function (t) { if (!STOP[t] && !/^\d+$/.test(t) || /^\d{1,2}$/.test(t) && false) qs[t] = 1; });
    var raw = {}; toks(text).forEach(function (t) { raw[t] = 1; });
    var out = [];
    shopProducts().forEach(function (p) {
      var pt = toks(pname(p) + ' ' + (p.brand || '')), score = 0, hit = 0;
      pt.forEach(function (t) {
        var mixed = /\d/.test(t) && /[a-z]/.test(t) && !/^\d[gG]$/.test(t), pure = /^\d{1,2}$/.test(t), isModel = mixed || pure;
        if (raw[t] && !STOP[t]) { score += isModel ? 3 : 1; if (isModel) hit++; }
      });
      Object.keys(qs).forEach(function (t) { if (/\d/.test(t) && /[a-z]/.test(t) && !/^\d[gG]$/.test(t) && !/^\d+(gb)$/.test(t) && pt.indexOf(t) === -1) score -= 2; });
      if (score > 0) out.push({ p: p, score: score, hit: hit });
    });
    out.sort(function (a, b) { return b.score - a.score; });
    return out;
  }
  function bestProducts(text) {
    var m = matchProducts(text); if (!m.length) return [];
    var top = m[0].score, close = m.filter(function (x) { return x.score >= top - 0 && x.score === top; });
    if (close.length === 1 && (m[0].hit > 0 || m.length === 1 || m[0].score >= (m[1] ? m[1].score + 2 : 99))) return [close[0].p];
    return close.map(function (x) { return x.p; }).slice(0, 8);
  }

  /* ---------- the conversation ---------- */
  var S = { pending: null, choose: null, adding: null, history: [], quiz: null, lang: 'hi-IN', speak: false, rec: null };
  var prefs = {}; try { prefs = JSON.parse(localStorage.getItem('saathiPrefs') || '{}'); } catch (e) { }
  if (prefs.lang) S.lang = prefs.lang; if (prefs.speak) S.speak = true; if (!prefs.mode) prefs.mode = 'auto'; if (!prefs.cloudModel) prefs.cloudModel = 'claude-haiku-5-5';
  function savePrefs() { prefs.lang = S.lang; prefs.speak = S.speak; try { localStorage.setItem('saathiPrefs', JSON.stringify(prefs)); } catch (e) { } }

  var log, input, dlg;
  function scroll() { log.scrollTop = log.scrollHeight; }
  function bot(text, extras) {
    var box = h('div', { class: 'sa-m sa-bot' }); String(text).split('\n').forEach(function (l, i) { if (i) box.append(h('br')); box.append(l); });
    (extras || []).forEach(function (x) { box.append(x); });
    log.append(box); scroll(); if (S.speak && 'speechSynthesis' in window) { try { var u = new SpeechSynthesisUtterance(String(text).replace(/[✓✅🧭▶🔎💡📷•]/g, ' ')); u.lang = S.lang === 'en-IN' ? 'en-IN' : 'hi-IN'; speechSynthesis.cancel(); speechSynthesis.speak(u); } catch (e) { } }
    return box;
  }
  function me(text) { log.append(h('div', { class: 'sa-m sa-me' }, text)); scroll(); }
  function btn(label, fn, cls) { return h('button', { class: 'sa-b ' + (cls || ''), type: 'button', onclick: fn }, label); }
  function row() { var r = h('div', { class: 'sa-row' }); for (var i = 0; i < arguments.length; i++) r.append(arguments[i]); return r; }

  function ask(lines, yes, label) {
    S.pending = { yes: yes };
    var r = row(btn('✓ हाँ, कर दो', function () { respond('हाँ'); }, 'ok'), btn('✗ रहने दो', function () { respond('नहीं'); }));
    bot((label || 'ये करने जा रहा हूँ:') + '\n' + lines.join('\n') + '\nसही है?', [r]);
  }
  function choose(title, items, pick) {
    S.choose = { items: items, pick: pick };
    var r = row(); items.forEach(function (it, i) { r.append(btn((i + 1) + '. ' + it.label, function () { respond(String(i + 1)); })); });
    bot(title, [r]);
  }
  function publishRow() { return row(btn('प्रकाशित करें', function () { A.publish(); }, 'ok'), btn('↶ वापस करो', function () { respond('undo'); })); }
  function commit(label, fn, msg) {
    var snap = A.mutate(fn); S.history.push({ label: label, snap: snap });
    bot('✓ ' + msg + '\nऐप और वेबसाइट पर दिखाने के लिए "प्रकाशित करें" दबाइए।', [publishRow()]);
  }
  function stamp(p) {
    var d = new Date(), en = d.getDate() + ' ' + MON_EN[d.getMonth()] + ' ' + d.getFullYear(), hi = d.getDate() + ' ' + MON_HI[d.getMonth()] + ' ' + d.getFullYear();
    p.refPriceLabel = { en: 'Shop price, updated ' + en, hi: 'दुकान की कीमत, ' + hi + ' तक' };
    p.description = { en: 'Shop price as of ' + en + '. Prices can change, so call or WhatsApp to confirm today’s price, gifts, offers and EMI.', hi: hi + ' तक की दुकान की कीमत। कीमत बदल सकती है, इसलिए आज की कीमत, गिफ़्ट, ऑफ़र और EMI के लिए कॉल या WhatsApp करें।' };
  }

  /* ----- actions ----- */
  function findVariant(p, spec) {
    var vs = p.variants || [];
    if (spec) { var hit = vs.filter(function (v) { var n = labelNums(v.label); return n && n.ram === spec.ram && n.rom === spec.rom; }); if (hit.length) return { v: hit[0] }; return { none: true }; }
    if (vs.length === 1) return { v: vs[0] };
    return { many: vs };
  }
  function doSetPrice(p, v, price) {
    var old = v.price || 0, lines = [pname(p) + ' · ' + (v.label || 'Standard') + ': ' + rupee(old) + ' → ' + rupee(price), 'तारीख़ आज की लगेगी।'];
    if (old && Math.abs(price - old) / old > 0.3) lines.push('⚠ ये पुराने रेट से ' + Math.round(Math.abs(price - old) / old * 100) + '% अलग है। एक बार जाँच लीजिए, कहीं एक अंक ग़लत तो नहीं?');
    ask(lines, function () {
      commit('रेट ' + pname(p), function () { v.price = price; v.mrp = price; stamp(p); }, pname(p) + ' ' + (v.label || '') + ' का रेट ' + rupee(price) + ' हो गया।');
    });
  }
  function actPrice(text, t) {
    var spec = variantSpec(t), prices = pricesIn(spec ? t.replace(spec.text, ' ') : t), cand = bestProducts(spec ? t.replace(spec.text, ' ') : t);
    var relMatch = /(\d+)\s*(?:रुपये|रुपए|rs|rupaye)?\s*(?:बढ़ा|badha|increase|कम कर|ghata|घटा|decrease|कम)/.exec(t), up = /बढ़ा|badha|increase|\+/.test(t), down = /कम कर|ghata|घटा|decrease|कम/.test(t);
    var base = spec ? t.replace(spec.text, ' ') : t;
    if (!cand.length) return bot('कौन-सा फ़ोन? मॉडल का नाम बोलिए, जैसे "ओप्पो A6x 4/128 का रेट 22999 कर दो"।');
    if (cand.length > 1) return choose('कौन-सा फ़ोन?', cand.map(function (p) { return { label: pname(p), p: p }; }), function (it) { actPrice(pname(it.p) + ' ' + text.replace(/[^\d\/+ ]/g, ' '), norm(pname(it.p) + ' ' + text)); });
    var p = cand[0];
    // relative change on every variant
    if (relMatch && (up || down) && !(prices.length && !(prices[0] === +relMatch[1] && prices.length === 1))) {
      var amt = +relMatch[1] * (down && !up ? -1 : 1), vs = spec ? (findVariant(p, spec).v ? [findVariant(p, spec).v] : []) : (p.variants || []);
      if (!vs.length) return bot('वो वेरिएंट ' + pname(p) + ' में नहीं है।');
      return ask(vs.map(function (v) { return pname(p) + ' · ' + (v.label || 'Standard') + ': ' + rupee(v.price || 0) + ' → ' + rupee(Math.max(0, (v.price || 0) + amt)); }), function () {
        commit('रेट ' + pname(p), function () { vs.forEach(function (v) { v.price = Math.max(0, (v.price || 0) + amt); v.mrp = v.price; }); stamp(p); }, pname(p) + ' के रेट बदल गए।');
      });
    }
    if (!prices.length) return bot('नया रेट बोलिए, जैसे "' + pname(p) + ' ' + (spec ? spec.ram + '/' + spec.rom : '4/128') + ' का रेट 22999"।');
    var price = prices[prices.length - 1], fv = findVariant(p, spec);
    if (fv.none) return bot(pname(p) + ' में ' + spec.label + ' वेरिएंट नहीं है। ये हैं: ' + (p.variants || []).map(function (v) { return v.label; }).join(', ') + '।\nनया वेरिएंट जोड़ना हो तो बोलिए "' + pname(p) + ' में ' + spec.ram + '/' + spec.rom + ' ' + price + ' जोड़ो"।');
    if (fv.many) return choose(pname(p) + ': किस वेरिएंट का रेट ' + rupee(price) + ' करना है?', fv.many.map(function (v) { return { label: v.label || 'Standard', v: v }; }), function (it) { doSetPrice(p, it.v, price); });
    doSetPrice(p, fv.v, price);
  }
  function actVisibility(t, mode) { // hide | show | remove
    var cand = bestProducts(t);
    if (!cand.length) return bot('कौन-सा फ़ोन या सामान? नाम बोलिए, जैसे "K14 5G ऐप से छुपा दो"।');
    var go = function (p) {
      if (mode === 'remove') return ask([pname(p) + ' को हमेशा के लिए मिटाना है। (सिर्फ़ छुपाना हो तो "छुपा दो" बोलिए)'], function () { commit('मिटाया ' + pname(p), function (shop) { shop.products = shop.products.filter(function (x) { return x !== p; }); }, pname(p) + ' मिटा दिया।'); });
      var on = mode === 'show';
      ask([pname(p) + (on ? ' ऐप में फिर से दिखेगा।' : ' ऐप से छुप जाएगा (मिटेगा नहीं, कभी भी वापस ला सकते हैं)।')], function () { commit((on ? 'दिखाया ' : 'छुपाया ') + pname(p), function () { p.active = on; }, pname(p) + (on ? ' अब ऐप में दिखेगा।' : ' अब ऐप में नहीं दिखेगा।')); });
    };
    if (cand.length > 1) return choose('कौन-सा?', cand.map(function (p) { return { label: pname(p), p: p }; }), function (it) { go(it.p); });
    go(cand[0]);
  }
  var CATS = [[['चार्जर', 'charger'], 'charger'], [['केबल', 'cable'], 'cable'], [['कवर', 'cover', 'केस', 'case'], 'caseCover'], [['ग्लास', 'glass', 'गार्ड', 'guard'], 'screenGuard'], [['ईयरफोन', 'earphone', 'ईयरबड', 'earbud', 'एयरपॉड'], 'earphones'], [['पावर बैंक', 'power bank', 'powerbank'], 'powerBank'], [['वॉच', 'watch'], 'smartwatch'], [['स्पीकर', 'speaker'], 'speaker'], [['मेमोरी', 'memory', 'पेन ड्राइव'], 'memory']];
  function parseNewProduct(raw) {
    var t = norm(raw), vs = [], re = /(\d{1,2})\s*(?:gb)?\s*[\/+x\-]\s*(\d{2,4})\D{0,14}?(\d{4,6})/g, m, firstIdx = t.length;
    while ((m = re.exec(t))) { var ram = +m[1], rom = +m[2]; if (ram <= 24 && rom >= 16) { vs.push({ label: ram + ' GB + ' + rom + ' GB', price: +m[3] }); firstIdx = Math.min(firstIdx, m.index); } }
    var name = t.slice(0, firstIdx).split(/\s+/).filter(function (w) { return w && !STOP[w] && !/^\d{4,}$/.test(w) && !/^(naya|nayi|new|add|jodo|जोड़ो|नया|नई|फोन|phone)$/.test(w) && !/^[ऀ-ॿ]+$/.test(w); });
    var cat = 'smartphone'; CATS.forEach(function (c) { if (has(raw, c[0])) cat = c[1]; });
    var pretty = name.map(function (w) { if (w === '5g' || w === '4g') return w.toUpperCase(); if (/^[a-z]\d/.test(w)) return w[0].toUpperCase() + w.slice(1); if (w === 'oppo' || w === 'vivo' || w === 'iqoo') return w === 'iqoo' ? 'iQOO' : w.toUpperCase().replace('VIVO', 'vivo'); return w[0].toUpperCase() + w.slice(1); });
    var brand = pretty[0] || '';
    return { name: pretty.join(' '), brand: brand, variants: vs, cat: cat };
  }
  function actAdd(raw) {
    var d = parseNewProduct(raw);
    if (S.adding && S.adding.name && !d.name) d.name = S.adding.name, d.brand = S.adding.brand, d.cat = S.adding.cat;
    if (!d.name) { S.adding = {}; return bot('नए फ़ोन का नाम और रेट बोलिए, जैसे:\n"ओप्पो A7 5G 6/128 29999 और 8/128 32999"'); }
    if (!d.variants.length && d.cat === 'smartphone') { S.adding = { name: d.name, brand: d.brand, cat: d.cat }; return bot(d.name + ' के वेरिएंट और रेट बोलिए, जैसे "6/128 29999 और 8/128 32999"।'); }
    var price = pricesIn(norm(raw)).pop();
    if (d.cat !== 'smartphone' && !d.variants.length) { if (!price) { S.adding = { name: d.name, brand: d.brand, cat: d.cat }; return bot(d.name + ' का रेट बोलिए।'); } d.variants = [{ label: 'Standard', price: price }]; }
    S.adding = null;
    var lines = [d.name + ' (' + d.brand + ')'].concat(d.variants.map(function (v) { return '• ' + v.label + ': ' + rupee(v.price); }));
    ask(lines, function () {
      var id = A.slug(d.brand + '-' + d.name) + '-' + A.rid();
      var p = { id: id, name: { en: d.name, hi: '' }, brand: d.brand, category: d.cat, callForBest: true, featured: true, emiEligible: true, active: true,
        variants: d.variants.map(function (v, i) { return { id: 'v' + (i + 1), label: v.label, color: '', price: v.price, mrp: v.price, stock: 1 }; }) };
      stamp(p); commit('नया ' + d.name, function (shop) { shop.products.unshift(p); }, d.name + ' जुड़ गया।\nस्पेसिफिकेशन और फ़ोटो जोड़ने के लिए सूची में उस पर "बदलें" दबाइए, या बोलिए "' + d.name + ' की फ़ोटो"।');
    }, 'ये नया जोड़ना है:');
  }
  function actOffer(raw) {
    var title = raw.replace(/ऑफर|ऑफ़र|offer|स्कीम|scheme|लगाओ|लगा दो|जोड़ो|नया|नई|add|new|[:：]/gi, ' ').replace(/\s+/g, ' ').trim();
    if (title.length < 4) return bot('ऑफ़र का शीर्षक बोलिए, जैसे "ऑफ़र लगाओ: हर फ़ोन के साथ कवर मुफ़्त"। (सच में जो दे सकें वही)');
    ask(['शीर्षक: ' + title, 'ये होम स्क्रीन के बैनर में दिखेगा।'], function () {
      commit('ऑफ़र', function (shop) { shop.offers.unshift({ id: 'offer-' + Date.now().toString(36), kind: 'banner', title: { en: title, hi: title }, subtitle: { en: '', hi: '' }, colorSeed: 1, active: true }); }, 'ऑफ़र लग गया।');
    }, 'ये ऑफ़र लगाना है:');
  }
  function actHours(raw) {
    var t = raw.replace(/[०-९]/g, function (d) { return '०१२३४५६७८९'.indexOf(d); }), nums = (t.match(/\d{1,2}(?::\d{2})?/g) || []).map(function (n) { return parseFloat(n.replace(':', '.')); });
    if (nums.length < 2) return bot('खुलने और बंद होने का समय बोलिए, जैसे "दुकान का समय सुबह 10 से रात 9, रविवार बंद"।');
    var o = nums[0], c = nums[1]; if (c <= o) c += 12; if (c <= 12 && /रात|शाम|pm|night|evening/i.test(t)) c += 12;
    var days = [['सोमवार', 'monday', 'mon'], ['मंगलवार', 'tuesday', 'tue'], ['बुधवार', 'wednesday', 'wed'], ['गुरुवार', 'thursday', 'thu'], ['शुक्रवार', 'friday', 'fri'], ['शनिवार', 'saturday', 'sat'], ['रविवार', 'sunday', 'sun']], off = 0;
    days.forEach(function (d, i) { if (has(t, d) && /बंद|छुट्टी|off|closed/i.test(t)) off = i + 1; });
    ask(['समय: ' + o + ':00 से ' + c + ':00', 'हफ़्ते की छुट्टी: ' + (off ? days[off - 1][0] : 'कोई नहीं')], function () {
      commit('समय', function (shop) { var hh = {}; for (var d = 1; d <= 7; d++) hh[d] = d === off ? { open: 600, close: 1260, closed: true } : { open: Math.round(o * 60), close: Math.round(c * 60), closed: false }; shop.settings.hours = hh; }, 'दुकान का समय बदल गया।');
    });
  }
  function actPhoto(t) {
    var cand = bestProducts(t); if (!cand.length) return bot('किस फ़ोन की फ़ोटो? जैसे "A6x की फ़ोटो"।');
    var go = function (p) {
      var f = h('input', { type: 'file', accept: 'image/*', style: 'display:none' });
      f.onchange = function () { if (!f.files[0]) return; A.addPhoto(f.files[0], pname(p)).then(function (url) { commit('फ़ोटो ' + pname(p), function () { p.imageUrls = [url].concat(p.imageUrls || []); }, pname(p) + ' की फ़ोटो जुड़ गई।'); }, function () { bot('ये फ़ोटो नहीं खुली, दूसरी चुनिए।'); }); };
      bot(pname(p) + ' की फ़ोटो: कैमरे से खींचिए या गैलरी से चुनिए।\n(सफ़ेद काउंटर पर, डिब्बे के साथ, साफ़ रोशनी में)', [row(btn('📷 फ़ोटो चुनें', function () { f.click(); }, 'ok'), f)]);
    };
    if (cand.length > 1) return choose('किसकी फ़ोटो?', cand.map(function (p) { return { label: pname(p), p: p }; }), function (it) { go(it.p); });
    go(cand[0]);
  }
  function actUndo() {
    var last = S.history.pop(); if (!last) return bot('वापस करने के लिए कोई बदलाव नहीं है।');
    A.restore(last.snap); bot('↶ "' + last.label + '" वापस कर दिया।');
  }
  /* ----- questions about the shop ----- */
  function phones() { return shopProducts().filter(function (p) { return p.category === 'smartphone' || p.category === 'featurePhone'; }); }
  function minPrice(p) { var a = (p.variants || []).map(function (v) { return v.price || 0; }).filter(Boolean); return a.length ? Math.min.apply(null, a) : 0; }
  function describe(p) {
    var l = [pname(p) + (p.active === false ? '  (ऐप में छुपा है)' : '')]; (p.variants || []).forEach(function (v) { l.push('• ' + (v.label || 'Standard') + ': ' + (v.price ? rupee(v.price) : 'कीमत नहीं डाली')); });
    var s = p.specs || {}; ['battery', 'display', 'chip', 'camera'].forEach(function (k) { if (s[k]) l.push('  ' + k + ': ' + s[k]); }); return l.join('\n');
  }
  function actQuery(raw, t) {
    var cand = bestProducts(t);
    if (cand.length && cand.length <= 3 && matchProducts(t)[0].hit > 0) return bot(cand.map(describe).join('\n\n'));
    var ph = phones(), live = ph.filter(function (p) { return p.active !== false; });
    if (has(raw, ['सबसे सस्ता', 'sasta', 'cheapest', 'सस्ता'])) { var s = live.slice().sort(function (a, b) { return minPrice(a) - minPrice(b); })[0]; return bot('सबसे सस्ता: ' + pname(s) + ' (' + rupee(minPrice(s)) + ' से शुरू)।'); }
    if (has(raw, ['सबसे महंगा', 'mehenga', 'costliest', 'महंगा'])) { var e = live.slice().sort(function (a, b) { return minPrice(b) - minPrice(a); })[0]; return bot('सबसे महंगा: ' + pname(e) + ' (' + rupee(minPrice(e)) + ' से शुरू)।'); }
    var brand = KnownBrand(t);
    if (brand) { var l = live.filter(function (p) { return (p.brand || '').toLowerCase() === brand; }); return bot(brand.toUpperCase() + ' के ' + l.length + ' फ़ोन:\n' + l.map(function (p) { return '• ' + pname(p) + ' — ' + rupee(minPrice(p)) + ' से'; }).join('\n')); }
    var hidden = shopProducts().filter(function (p) { return p.active === false; }).length;
    bot('दुकान में अभी ' + live.length + ' फ़ोन ऐप में दिख रहे हैं, ' + (shopProducts().length - ph.length) + ' एक्सेसरी, और ' + hidden + ' छुपे हुए हैं।\nकिसी फ़ोन का नाम बोलिए तो उसके रेट बताऊँगा।');
  }
  function KnownBrand(t) { var bs = {}; shopProducts().forEach(function (p) { if (p.brand) bs[p.brand.toLowerCase()] = 1; }); var tk = toks(t); for (var i = 0; i < tk.length; i++) if (bs[tk[i]]) return tk[i]; return ''; }
  /* ----- bulk price list ----- */
  function actBulk() {
    var ta = h('textarea', { rows: 6, placeholder: 'हर लाइन में एक: A6x 4/64 19999\nA6x 4/128 23999\nReno 16 8/256 72999', style: 'width:100%;font:inherit' });
    var out = h('div', { class: 'sa-prev' });
    var go = btn('जाँचो', function () {
      var rows = ta.value.split('\n').map(function (l) { return l.trim(); }).filter(Boolean).map(function (line) {
        var t = norm(line), spec = variantSpec(t), cand = bestProducts(spec ? t.replace(spec.text, ' ') : t), pr = pricesIn(spec ? t.replace(spec.text, ' ') : t).pop();
        if (cand.length !== 1 || !pr) return { line: line, bad: cand.length > 1 ? 'कौन-सा फ़ोन साफ़ नहीं' : (!cand.length ? 'फ़ोन नहीं मिला' : 'रेट नहीं मिला') };
        var fv = findVariant(cand[0], spec); if (!fv.v) return { line: line, bad: fv.none ? 'वेरिएंट नहीं मिला' : 'वेरिएंट नहीं लिखा' };
        return { line: line, p: cand[0], v: fv.v, price: pr };
      });
      out.textContent = ''; var ok = rows.filter(function (r) { return r.v; });
      rows.forEach(function (r) { out.append(h('div', { class: r.v ? 'sa-ok' : 'sa-no' }, r.v ? ('✓ ' + pname(r.p) + ' · ' + r.v.label + ': ' + rupee(r.v.price || 0) + ' → ' + rupee(r.price)) : ('✗ ' + r.line + ' — ' + r.bad))); });
      if (ok.length) out.append(btn(ok.length + ' रेट बदलो', function () { commit('सूची से रेट', function () { ok.forEach(function (r) { r.v.price = r.price; r.v.mrp = r.price; stamp(r.p); }); }, ok.length + ' रेट बदल गए।'); out.textContent = ''; }, 'ok'));
    }, 'ok');
    bot('रेट की सूची यहाँ चिपकाइए (डिस्ट्रीब्यूटर की सूची से कॉपी करके):', [ta, row(go), out]);
  }
  /* ----- coaching ----- */
  function stale() { var n = 0, cut = Date.now() - 7 * 864e5; phones().forEach(function (p) { var m = /updated (\d+) (\w{3}) (\d{4})/.exec((p.refPriceLabel && p.refPriceLabel.en) || ''); if (m) { var d = new Date(m[3] + '-' + (MON_EN.indexOf(m[2]) + 1) + '-' + m[1]); if (!isNaN(d) && +d < cut) n++; } }); return n; }
  function actPlan() {
    var d = new Date(), ph = phones(), noPhoto = ph.filter(function (p) { return p.active !== false && !(p.imageUrls && p.imageUrls.length); }), lines = [];
    lines.push('🧭 आज का प्लान (' + d.getDate() + ' ' + MON_HI[d.getMonth()] + ')');
    lines.push('सुबह के तीन काम: 1) शोकेस और काउंटर साफ़, डेमो फ़ोन चार्ज 2) आज की एक बिक्री का लक्ष्य लिखिए 3) WhatsApp स्टेटस पर एक फ़ोन।');
    lines.push('आज का फ़ोकस: ' + KB.weekdayFocus[d.getDay()]);
    var s = stale(); if (s) lines.push('⚠ ' + s + ' फ़ोन का रेट सात दिन से पुराना है। डिस्ट्रीब्यूटर से मिलाकर बदलिए।');
    if (noPhoto.length) lines.push('📷 ' + noPhoto.length + ' फ़ोन की असली फ़ोटो बाकी है (पहले: ' + pname(noPhoto[0]) + ')।');
    if (A.dirty()) lines.push('📤 कुछ बदलाव प्रकाशित होना बाकी है।');
    lines.push('💡 ' + KB.principles[d.getDate() % KB.principles.length].ask);
    bot(lines.join('\n'), A.dirty() ? [row(btn('प्रकाशित करें', function () { A.publish(); }, 'ok'))] : []);
  }
  function coach(pb) {
    var pr = KB.principles.filter(function (x) { return x.id === pb.principle; })[0] || KB.principles[0];
    bot('🧭 ' + pb.title + '\n' + pb.understand + '\n\n✅ तीन कदम:\n' + pb.steps.map(function (s, i) { return (i + 1) + ') ' + s; }).join('\n') + '\n\n▶ आज का पहला कदम: ' + pb.first + '\n🔎 जाँच: ' + pb.check + '\n\n💡 ' + pr.hi + ': ' + pr.idea + '\nसवाल: ' + pr.ask);
  }
  function findPlaybook(raw) { var r = findPlaybookScored(raw); return r ? r.pb : null; }
  function findPlaybookScored(raw) {
    var best = null, sc = 0, s = raw.toLowerCase(); KB.playbooks.forEach(function (pb) { var n = 0; pb.kw.forEach(function (k) { k = k.toLowerCase(); if (s.indexOf(k) === -1) return; n += (k.length > 3 || (/^[a-z]+$/.test(k) && new RegExp('(^|[^a-z])' + k + '(?![a-z])').test(s))) ? 2 : 1; }); if (n > sc) { sc = n; best = pb; } });
    return sc >= 2 ? { pb: best, score: sc } : null;
  }
  function actQuiz(answer) {
    if (S.quiz && answer != null) {
      var nums = (answer.match(/\d[\d,]*/g) || []).map(function (x) { return +x.replace(/,/g, ''); }), q = S.quiz; S.quiz = null;
      if (nums.length && Math.abs(nums[0] - q.ans) <= q.tol) return bot('✓ सही! ' + q.say + '\nएक और? बोलिए "क्विज़"।');
      return bot('अभी नहीं। सही जवाब: ' + q.say + '\nफ़ोन के बारे में रोज़ दो सवाल सीखिए, ग्राहक के सामने भरोसा बढ़ेगा।');
    }
    var pool = phones().filter(function (p) { return p.active !== false && p.specs && /\d/.test(p.specs.battery || ''); });
    if (!pool.length) return bot('क्विज़ के लिए स्पेसिफिकेशन वाले फ़ोन चाहिए।');
    var p = pool[Math.floor(Math.random() * pool.length)], kind = Math.random() < 0.5 ? 'battery' : 'price';
    if (kind === 'battery') { var b = +(/([\d,]{4,6})\s*mAh/i.exec(p.specs.battery) || [0, '0'])[1].replace(/,/g, ''); if (b) { S.quiz = { ans: b, tol: 100, say: pname(p) + ' की बैटरी ' + p.specs.battery }; return bot('❓ ' + pname(p) + ' की बैटरी कितने mAh की है? (सिर्फ़ संख्या बोलिए)'); } }
    var v = (p.variants || [])[0]; S.quiz = { ans: v.price, tol: 1000, say: pname(p) + ' ' + v.label + ' का रेट ' + rupee(v.price) }; bot('❓ ' + pname(p) + ' ' + v.label + ' का दुकान का रेट कितना है? (लगभग)');
  }
  function help() {
    bot('मैं ये कर सकता हूँ (बोलकर या लिखकर):\n\n• रेट: "A6x 4/128 का रेट 22999 कर दो"\n• सब वेरिएंट में बदलाव: "K14x के रेट 500 बढ़ा दो"\n• नया फ़ोन: "नया फ़ोन ओप्पो A7 5G 6/128 29999"\n• छुपाना: "K14 5G ऐप से छुपा दो" / दिखाना: "K14 दिखा दो"\n• मिटाना: "... हमेशा के लिए हटा दो"\n• ऑफ़र: "ऑफ़र लगाओ: ..."\n• समय: "दुकान का समय सुबह 10 से रात 9, रविवार बंद"\n• फ़ोटो: "A6x की फ़ोटो"\n• पूछना: "ओप्पो के कितने फ़ोन हैं", "सबसे सस्ता कौन-सा"\n• रेट की सूची चिपकाना, क्विज़, आज का प्लान\n• सलाह: "ग्राहक का बजट कम है", "रील क्या बनाऊँ", "शाम का हिसाब"\n\nहर बदलाव पहले मैं दिखाता हूँ, आप "हाँ" बोलते हैं, फिर होता है। गलती हो तो "वापस करो"।');
  }

  /* ---------- deciding what a message means ---------- */
  var W = {
    yes: ['हाँ', 'हां', 'haan', 'han', 'yes', 'ok', 'okay', 'ठीक', 'theek', 'कर दो', 'kar do', 'सही', 'confirm', 'जी', 'करो', 'हो जाने दो'],
    no: ['नहीं', 'nahi', 'no', 'रहने दो', 'cancel', 'रुको', 'ruko', 'छोड़ो', 'मत', 'रद्द'],
    price: ['रेट', 'कीमत', 'दाम', 'price', 'rate', 'daam', 'kimat', 'भाव', 'bhav'],
    hide: ['छुपा', 'छिपा', 'hide', 'chhupa', 'chupa', 'बंद करो', 'band karo', 'नहीं है', 'nahi hai', 'ख़त्म', 'खत्म', 'khatam', 'उपलब्ध नहीं', 'out of stock', 'हटा दो ऐप से'],
    remove: ['हमेशा के लिए', 'permanent', 'मिटा', 'हटा', 'delete', 'remove'],
    show: ['दिखा दो', 'दिखाओ ऐप', 'चालू', 'unhide', 'वापस लगा', 'फिर से दिखा', 'dikha do', 'chalu', 'show karo'],
    add: ['नया', 'नई', 'जोड़', 'add', 'new', 'naya', 'nayi', 'jodo', 'जुड़वा'],
    offer: ['ऑफर', 'ऑफ़र', 'offer', 'scheme', 'स्कीम'],
    photo: ['फोटो', 'फ़ोटो', 'photo', 'pic', 'तस्वीर'],
    hours: ['दुकान का समय', 'टाइमिंग', 'timing', 'खुलने का', 'बंद होने का', 'opening hours', 'दुकान खुलती', 'दुकान बंद'],
    undo: ['वापस करो', 'undo', 'पलटो', 'गलत हो गया', 'ग़लत हो गया', 'पिछला बदलाव'],
    publish: ['प्रकाशित', 'publish', 'लाइव करो', 'save karo', 'सेव करो', 'ऐप में डालो'],
    help: ['मदद', 'help', 'क्या कर सकते', 'कमांड', 'commands', 'शॉर्टकट'],
    plan: ['आज का प्लान', 'आज का काम', 'aaj ka plan', 'aaj kya', 'today', 'आज क्या', 'प्लान'],
    quiz: ['क्विज़', 'quiz', 'सवाल पूछो'],
    bulk: ['सूची', 'list paste', 'bulk', 'लिस्ट चिपका', 'paste']
  };
  function pickFromText(c, t) {
    var spec = variantSpec(t);
    if (spec) { var hit = c.items.filter(function (i) { var n = i.v && labelNums(i.v.label); return n && n.ram === spec.ram && n.rom === spec.rom; }); if (hit.length === 1) return hit[0]; }
    var q = toks(t).filter(function (w) { return !STOP[w] && !/^\d{4,}$/.test(w); }); if (!q.length) return null;
    var m = c.items.filter(function (i) { var lt = toks(i.label); return q.every(function (w) { return lt.indexOf(w) !== -1; }); });
    return m.length === 1 ? m[0] : null;
  }
  function isShort(t) { return t.trim().split(/\s+/).length <= 4; }
  function respond(raw) {
    raw = String(raw || '').trim(); if (!raw) return; me(raw);
    try { handle(raw); } catch (e) { bot('माफ़ कीजिए, मैं ये समझ नहीं पाया। "मदद" बोलिए तो बताऊँगा कि क्या-क्या कर सकता हूँ।'); if (window.console) console.error(e); }
  }
  function handle(raw) {
    var low = raw.toLowerCase(), t = norm(raw);
    if (S.pending) { var p = S.pending; if (isShort(low) && has(low, W.no)) { S.pending = null; return bot('ठीक है, रहने दिया।'); } if (isShort(low) && has(low, W.yes)) { S.pending = null; return p.yes(); } S.pending = null; }
    if (S.choose) {
      var c = S.choose, n = parseInt(t.replace(/\D/g, ''), 10), ord = { 'पहला': 1, 'पहले': 1, 'दूसरा': 2, 'तीसरा': 3, 'चौथा': 4 };
      Object.keys(ord).forEach(function (w) { if (low.indexOf(w) !== -1) n = ord[w]; });
      if (n >= 1 && n <= c.items.length && isShort(low)) { S.choose = null; return c.pick(c.items[n - 1]); }
      var byText = pickFromText(c, t); if (byText) { S.choose = null; return c.pick(byText); }
      if (isShort(low) && has(low, W.no)) { S.choose = null; return bot('ठीक है।'); }
      if (isShort(low) && !has(low, W.help.concat(W.plan, W.undo, W.quiz))) return bot('नंबर बोलिए (1 से ' + c.items.length + ') या नाम बोलिए। रहने देना हो तो "नहीं" बोलिए।');
      S.choose = null;
    }
    if (S.quiz && /\d/.test(t) && isShort(low)) return actQuiz(raw);
    if (S.adding && !has(low, W.help.concat(W.plan))) { if (parseNewProduct(raw).variants.length) return actAdd(raw); if (isShort(low) && has(low, W.no)) { S.adding = null; return bot('ठीक है।'); } S.adding = null; }
    var spec = variantSpec(t), base = spec ? t.replace(spec.text, ' ') : t, prices = pricesIn(base), pm = matchProducts(base), hasProd = !!(pm.length && (pm[0].hit > 0 || pm.length === 1));
    var bump = /बढ़ा|badha|increase|घटा|ghata|कम कर|decrease/.test(low);
    if (has(low, W.undo)) return actUndo();
    if (has(low, W.publish) && isShort(low)) return A.publish();
    if (has(low, W.help) && isShort(low)) return help();
    if (has(low, W.plan)) return actPlan();
    if (has(low, W.quiz)) return actQuiz();
    if (has(low, W.bulk) && has(low, W.price.concat(['चिपका', 'paste']))) return actBulk();
    if (has(low, W.photo) && hasProd) return actPhoto(t);
    if (has(low, W.hours)) return actHours(raw);
    if (has(low, W.offer) && has(low, ['लगाओ', 'लगा दो', 'जोड़ो', 'जोड़ दो', 'बनाओ', 'add', 'create', 'नया ऑफ', 'नई ऑफ', 'new offer', ':'])) return actOffer(raw);
    if (has(low, W.add) && has(low, ['फोन', 'फ़ोन', 'phone', 'mobile', 'मोबाइल', 'सामान', 'product', 'एक्सेसरी', 'चार्जर', 'कवर', 'केबल', 'ग्लास', 'charger', 'cover', 'cable']) && !hasProd) return actAdd(raw);
    if (spec && !hasProd && prices.length && !has(low, W.price)) return actAdd(raw);
    if (hasProd && has(low, ['हमेशा के लिए', 'permanent', 'मिटा', 'delete'])) return actVisibility(t, 'remove');
    if (hasProd && has(low, W.hide) && !has(low, W.show)) return actVisibility(t, 'hide');
    if (hasProd && has(low, W.show)) return actVisibility(t, 'show');
    if (hasProd && has(low, ['हटा', 'remove'])) return actVisibility(t, 'hide');
    if (hasProd && (prices.length || bump) && (has(low, W.price) || bump || spec)) return actPrice(raw, t);
    if (pm.length > 1 && prices.length && has(low, W.price) && !hasProd) return actPrice(raw, t);
    if (has(low, ['सबसे सस्ता', 'सबसे महंगा', 'cheapest', 'costliest', 'sabse sasta', 'sabse mehenga'])) return actQuery(raw, t);
    var listing = has(low, ['कितने', 'kitne', 'सबसे', 'list', 'लिस्ट', 'दिखाओ', 'बताओ', 'show', 'batao', 'dikhao']);
    if (hasProd && (has(low, W.price) || isShort(low) || listing)) return actQuery(raw, t);
    var pbs = findPlaybookScored(raw);
    if (pbs) { if (pbs.score >= 4 || !engines().length) return coach(pbs.pb); return advise(raw); }   // a clear playbook is the fastest and most relevant answer
    if (listing || has(low, W.price)) return actQuery(raw, t);
    if (engines().length) return advise(raw);
    bot('मुझे पूरी बात समझ नहीं आई। आप चाहें तो ऐसे बोल सकते हैं:\n• "A6x 4/128 का रेट 22999 कर दो"\n• "आज का प्लान"\n• "ग्राहक का बजट कम है, क्या करूँ?"\n\nया "मदद" बोलिए। सलाह के लिए तीन बातें बताइए: क्या हुआ? कितना? आप क्या चाहते हैं?');
  }
  /* ----- the brain switch: cloud AI when the signal is good, on-device AI when it is not, whichever is faster and more useful.
     Both only give advice. They never change shop data; changes always go through the commands above and a "हाँ". ----- */
  var ST = { cloud: { q: 0.8, ms: 2500, down: 0 }, device: { q: 0.6, ms: 7000, down: 0 } };
  try { var saved = JSON.parse(localStorage.getItem('saathiStats') || 'null'); if (saved) { ['cloud', 'device'].forEach(function (k) { if (saved[k]) { ST[k].q = saved[k].q; ST[k].ms = saved[k].ms; } }); } } catch (e) { }
  function saveStats() { try { localStorage.setItem('saathiStats', JSON.stringify({ cloud: { q: ST.cloud.q, ms: ST.cloud.ms }, device: { q: ST.device.q, ms: ST.device.ms } })); } catch (e) { } }
  var utility = function (n) { return ST[n].q - 0.04 * ST[n].ms / 1000; };
  function engines() {
    var c = [];
    if (prefs.mode !== 'device' && navigator.onLine && A.cloudKey() && Date.now() > ST.cloud.down && window.SaathiCloud) c.push('cloud');
    if (prefs.mode !== 'cloud' && window.SaathiLLM && window.SaathiLLM.ready()) c.push('device');
    return c.sort(function (x, y) { return utility(y) - utility(x); });
  }
  var turns = [];
  function digest() {
    return phones().filter(function (p) { return p.active !== false; }).slice(0, 24).map(function (p) { return pname(p) + ': ' + (p.variants || []).map(function (v) { return v.label + ' ' + rupee(v.price || 0); }).join(', ') + (p.specs && p.specs.battery ? ' (' + p.specs.battery + ')' : ''); }).join('\n');
  }
  function systemPrompt(q) {
    var pb = findPlaybook(q), pr = KB.principles.map(function (x) { return '- ' + x.hi + ': ' + x.idea; }).join('\n'), s = KB.shop;
    return 'You are Saathi, the shop coach for Naresh Saini, owner of ' + s.name + ' in Neem Ka Thana, Rajasthan. Reply in simple Hindi (Devanagari), short, practical and respectful. ' +
      'Coach in the spirit of Shiv Khera: positive attitude, integrity, written goals, planning, customer service and win-win. You are not Shiv Khera. ' +
      'Always answer as: 1) one-line understanding, 2) three concrete steps, 3) the first step for today, 4) how to check tonight. ' +
      'Never invent prices, discounts, ratings, stock or EMI promises. You cannot change shop data; if the owner wants a change, tell him the exact words to say, like "A6x 4/128 का रेट 22999 कर दो".\n' +
      'Shop rules:\n' + KB.rules.join('\n') + '\nPrinciples:\n' + pr + '\nServices: ' + s.servicesHi + '\nEMI: ' + s.emiHi + '\nPhones in the app now:\n' + digest() + (pb ? '\nRelevant playbook: ' + pb.title + ': ' + pb.steps.join(' ') : '');
  }
  function context(q) { // the last few turns, always starting with the owner's turn
    var t = turns.slice(-6).concat([{ role: 'user', content: q }]); while (t.length && t[0].role !== 'user') t.shift(); return t;
  }
  function advise(raw) {
    var list = engines(), box = bot('…'), acc = '';
    var next = function () {
      var e = list.shift();
      if (!e) { var pb = findPlaybook(raw); box.remove(); return pb ? coach(pb) : bot('अभी AI से जवाब नहीं मिल पाया। "मदद" बोलिए या "आज का प्लान" देखिए।'); }
      var t0 = performance.now(), first = 0; acc = ''; box.textContent = e === 'cloud' ? '☁ सोच रहा हूँ…' : '📱 फ़ोन पर सोच रहा हूँ…';
      var on = function (tok) { if (!first) first = performance.now() - t0; acc += tok; box.textContent = acc; scroll(); };
      var run = e === 'cloud'
        ? window.SaathiCloud.ask({ key: A.cloudKey(), model: prefs.cloudModel, system: systemPrompt(raw), messages: context(raw), onToken: on, timeoutMs: 9000 })
        : window.SaathiLLM.ask([{ role: 'system', content: systemPrompt(raw) }].concat(context(raw)), on);
      run.then(function () {
        if (!acc) throw new Error('खाली जवाब');
        ST[e].ms = 0.5 * ST[e].ms + 0.5 * (first || (performance.now() - t0)); saveStats(); turns.push({ role: 'user', content: raw }, { role: 'assistant', content: acc });
        box.append(h('div', { class: 'sa-tag' }, (e === 'cloud' ? '☁ क्लाउड AI · ' : '📱 फ़ोन पर AI · ') + ((first || 0) / 1000).toFixed(1) + ' सेकंड में शुरू'), row(btn('👍 काम का', function () { rate(e, 1, box); }), btn('👎 ठीक नहीं', function () { rate(e, 0, box); })));
        if (S.speak && 'speechSynthesis' in window) { try { var u = new SpeechSynthesisUtterance(acc); u.lang = 'hi-IN'; speechSynthesis.cancel(); speechSynthesis.speak(u); } catch (x) { } }
      }).catch(function () {
        if (e === 'cloud') ST.cloud.down = Date.now() + 5 * 60 * 1000;     // rest the cloud for five minutes after a failure or a slow start
        next();
      });
    };
    next();
  }
  function rate(e, v, box) { ST[e].q = 0.7 * ST[e].q + 0.3 * v; saveStats(); box.querySelectorAll('.sa-row').forEach(function (r) { r.remove(); }); box.append(h('div', { class: 'sa-tag' }, v ? 'धन्यवाद, अगली बार इसे और पसंद करूँगा।' : 'ठीक है, अगली बार दूसरे तरीके को मौका दूँगा।')); }

  /* ---------- the screen ---------- */
  function build() {
    var css = h('style'); css.textContent = [
      '#saathiFab{position:fixed;right:14px;bottom:88px;z-index:6;border-radius:99px;padding:12px 18px;background:var(--accent);color:#fff;font-weight:800;box-shadow:0 4px 16px rgba(0,0,0,.3)}',
      '#saathiDlg{padding:0;border:0;width:100vw;max-width:100vw;height:100dvh;max-height:100dvh;background:var(--paper);color:var(--ink)}',
      '#saathiDlg .sa-w{display:flex;flex-direction:column;height:100dvh;max-width:720px;margin:0 auto}',
      '.sa-h{display:flex;align-items:center;gap:8px;padding:12px 14px;background:linear-gradient(160deg,var(--deep),#2B3558);color:#fff}.sa-h b{flex:1;line-height:1.2}.sa-h small{display:block;font-weight:400;opacity:.8;font-size:12px}',
      '.sa-h button{background:transparent;color:#fff;padding:6px 10px}',
      '.sa-l{flex:1;overflow:auto;padding:12px 12px 4px}',
      '.sa-m{max-width:88%;padding:10px 12px;border-radius:14px;margin:8px 0;font-size:16px;line-height:1.45;white-space:normal;word-wrap:break-word}',
      '.sa-bot{background:var(--soft);border:1px solid var(--line)}.sa-me{margin-left:auto;background:var(--brand);color:var(--paper)}',
      '.sa-row{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}.sa-b{padding:8px 12px;font-size:15px;border-radius:99px;background:var(--paper);color:var(--brand);border:1.5px solid var(--brand)}.sa-b.ok{background:var(--accent);color:#fff;border-color:var(--accent)}',
      '.sa-chips{display:flex;gap:6px;overflow-x:auto;padding:6px 12px}.sa-chips button{flex:none;padding:7px 12px;font-size:14px;border-radius:99px;background:var(--soft);color:var(--ink);border:1px solid var(--line);font-weight:600}',
      '.sa-in{display:flex;gap:8px;padding:10px 12px calc(10px + env(safe-area-inset-bottom));border-top:1px solid var(--line);background:var(--paper)}',
      '.sa-in input{flex:1;font-size:17px}.sa-in button{padding:10px 14px}.sa-mic.on{background:#c62828;color:#fff}',
      '.sa-ok{color:var(--ok);margin:4px 0}.sa-no{color:var(--bad);margin:4px 0}.sa-set{padding:10px 14px;border-bottom:1px solid var(--line);background:var(--soft);font-size:14px}.sa-set label{display:flex;gap:8px;align-items:center;margin:6px 0;font-weight:600}.sa-set select{width:auto}',
      '.sa-prev{margin-top:8px}', '.sa-tag{font-size:12px;color:var(--muted);margin-top:6px}'
    ].join('\n'); document.head.append(css);
    var fab = $('saathiFab'); if (!fab) { fab = h('button', { id: 'saathiFab', class: 'hide', type: 'button' }, '🎙️ सहायक'); document.body.append(fab); }
    log = h('div', { class: 'sa-l' }); input = h('input', { type: 'text', placeholder: 'बोलिए या लिखिए…', enterkeyhint: 'send', autocomplete: 'off' });
    var mic = h('button', { class: 'sa-mic', type: 'button', 'aria-label': 'बोलिए' }, '🎙️'), send = h('button', { type: 'button' }, 'भेजें');
    var settings = h('div', { class: 'sa-set hide' });
    var langSel = h('select', {}, h('option', { value: 'hi-IN' }, 'हिंदी'), h('option', { value: 'en-IN' }, 'English')); langSel.value = S.lang; langSel.onchange = function () { S.lang = langSel.value; savePrefs(); };
    var spk = h('input', { type: 'checkbox' }); spk.checked = S.speak; spk.onchange = function () { S.speak = spk.checked; savePrefs(); };
    var aiBox = h('div'); settings.append(h('label', {}, 'बोलने की भाषा ', langSel), h('label', {}, spk, 'जवाब बोलकर सुनाओ'), aiBox);
    var chips = h('div', { class: 'sa-chips' });
    [['आज का प्लान', 1], ['रेट बदलो', 'A6x 4/128 का रेट '], ['नया फ़ोन', 'नया फ़ोन '], ['छुपाओ', ' ऐप से छुपा दो'], ['ऑफ़र लगाओ', 'ऑफ़र लगाओ: '], ['सूची चिपकाओ', 'रेट की सूची चिपकानी है'], ['फ़ोटो', ' की फ़ोटो'], ['शाम का हिसाब', 1], ['क्विज़', 1], ['मदद', 1]].forEach(function (c) {
      chips.append(h('button', { type: 'button', onclick: function () { if (c[1] === 1) respond(c[0]); else { input.value = c[1]; input.focus(); if (c[1][0] === ' ') input.setSelectionRange(0, 0); } } }, c[0]));
    });
    var head = h('div', { class: 'sa-h' }, h('b', {}, 'सहायक · Saathi', h('small', {}, 'नरेश जी की दुकान का साथी · शिव खेड़ा के विचारों से प्रेरित कोच')), h('button', { type: 'button', onclick: function () { settings.classList.toggle('hide'); } }, '⚙'), h('button', { type: 'button', onclick: function () { dlg.close(); } }, '✕'));
    dlg = h('dialog', { id: 'saathiDlg' }, h('div', { class: 'sa-w' }, head, settings, log, chips, h('div', { class: 'sa-in' }, mic, input, send)));
    document.body.append(dlg);
    var go = function () { var v = input.value; input.value = ''; respond(v); }; send.onclick = go; input.onkeydown = function (e) { if (e.key === 'Enter') go(); };
    fab.onclick = function () { dlg.showModal(); if (prefs.loaded && window.SaathiLLM && SaathiLLM.supported() && !SaathiLLM.ready() && !S.loading) { S.loading = true; SaathiLLM.load(prefs.model, function () { }).catch(function () { }).then(function () { S.loading = false; }); } if (!log.children.length) { var d = new Date(), g = d.getHours() < 12 ? 'सुप्रभात' : d.getHours() < 17 ? 'नमस्ते' : 'शुभ संध्या'; bot(g + ' नरेश जी! मैं आपका सहायक हूँ। बोलकर या लिखकर बताइए क्या करना है, रेट बदलना, फ़ोन जोड़ना, छुपाना, ऑफ़र लगाना, या दुकान बढ़ाने की सलाह।\n"मदद" बोलिए तो सारे आदेश बताऊँगा।'); actPlan(); } };
    voice(mic, input);
    aiSettings(aiBox);
  }
  function voice(mic, input) {
    var R = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (!R) { mic.disabled = true; mic.title = 'इस ब्राउज़र में बोलना नहीं चलता, Chrome इस्तेमाल कीजिए'; return; }
    mic.onclick = function () {
      if (S.rec) { S.rec.stop(); return; }
      var r = new R(); r.lang = S.lang; r.interimResults = true; r.maxAlternatives = 1; S.rec = r;
      try { if ('processLocally' in r) r.processLocally = !navigator.onLine; } catch (e) { }   // offline: use the phone's own speech engine if its language pack is installed
      r.onresult = function (ev) { var t = ''; for (var i = ev.resultIndex; i < ev.results.length; i++) t += ev.results[i][0].transcript; input.value = t; if (ev.results[ev.results.length - 1].isFinal) { var v = input.value; input.value = ''; respond(v); } };
      r.onerror = function (e) { bot(e.error === 'not-allowed' ? 'माइक की इजाज़त चाहिए। ब्राउज़र की सेटिंग में माइक चालू कीजिए।' : e.error === 'language-not-supported' ? 'बिना नेट के बोलने के लिए ⚙ में "हिंदी आवाज़-पैक डाउनलोड" कीजिए। अभी टाइप करके काम चलाइए।' : 'बोला हुआ सुनाई नहीं दिया, फिर कोशिश कीजिए।'); };
      r.onend = function () { mic.classList.remove('on'); S.rec = null; };
      mic.classList.add('on'); try { r.start(); } catch (e) { mic.classList.remove('on'); S.rec = null; }
    };
  }
  function aiSettings(box) {
    var L = window.SaathiLLM, status = h('div', { style: 'font-weight:400;margin-top:4px' }), mode = h('select', {}, h('option', { value: 'auto' }, 'अपने-आप (तेज़ और काम का जो हो)'), h('option', { value: 'cloud' }, 'सिर्फ़ क्लाउड AI'), h('option', { value: 'device' }, 'सिर्फ़ फ़ोन पर (ऑफ़लाइन)'));
    mode.value = prefs.mode; mode.onchange = function () { prefs.mode = mode.value; savePrefs(); };
    box.append(h('div', { style: 'margin-top:8px;font-weight:700' }, 'AI कैसे जवाब दे'), mode);
    var key = h('input', { type: 'password', placeholder: 'क्लाउड AI की (API) कुंजी, खाली = बंद', autocomplete: 'off', style: 'width:100%' }), cm = h('input', { type: 'text', value: prefs.cloudModel, style: 'width:100%' });
    var cstat = h('div', { style: 'font-weight:400;margin-top:4px' }, A.cloudKey() ? '✓ कुंजी इस फ़ोन में सेव है (PIN से बंद)।' : 'कुंजी नहीं डाली, इसलिए क्लाउड AI बंद है।');
    var save = btn('कुंजी सेव करें', function () { prefs.cloudModel = cm.value.trim() || 'claude-haiku-5-5'; savePrefs(); A.setCloudKey(key.value.trim()).then(function () { key.value = ''; cstat.textContent = A.cloudKey() ? '✓ कुंजी इस फ़ोन में सेव है (PIN से बंद)।' : 'कुंजी हटा दी।'; }, function (e) { cstat.textContent = e.message; }); }, 'ok');
    box.append(h('div', { style: 'margin-top:8px;font-weight:700' }, '☁ क्लाउड AI (इंटरनेट पर, ज़्यादा समझदार)'), h('div', { style: 'font-weight:400' }, 'चालू रहने पर आपका सवाल और फ़ोन की सूची Anthropic को जाती है। कुंजी कम खर्च-सीमा वाली अलग बनाइए। ऑफ़लाइन मोड में कुछ बाहर नहीं जाता।'), key, cm, row(save), cstat);
    if (!L || !L.supported()) { box.append(h('div', { style: 'margin-top:8px' }, '📱 फ़ोन पर AI: इस ब्राउज़र में WebGPU नहीं है, इसलिए अभी चालू नहीं हो सकता। Chrome अपडेट कीजिए।')); }
    else {
      var sel = h('select', {}, h('option', { value: 'gemma-2-2b-it-q4f16_1-MLC' }, 'सबसे अच्छा (Gemma 2B, ~1.6 GB) · सुझाया हुआ'), h('option', { value: 'Qwen2.5-1.5B-Instruct-q4f16_1-MLC' }, 'तेज़ (Qwen 1.5B, ~1 GB)'), h('option', { value: 'Qwen2.5-0.5B-Instruct-q4f16_1-MLC' }, 'हल्का (Qwen 0.5B, ~0.4 GB)'));
      if (prefs.model) sel.value = prefs.model;
      var b = btn(L.ready() ? '✓ चालू है' : 'डाउनलोड करके चालू करें', function () {
        prefs.model = sel.value; savePrefs(); b.disabled = true; status.textContent = 'डाउनलोड हो रहा है… (वाई-फ़ाई पर करें, एक ही बार लगेगा)';
        L.load(sel.value, function (p) { status.textContent = p; }).then(function () { prefs.loaded = true; savePrefs(); status.textContent = '✓ फ़ोन पर AI चालू है। बिना नेट के भी सलाह देगा; डेटा नहीं बदलेगा।'; }, function (e) { b.disabled = false; status.textContent = 'चालू नहीं हो पाया: ' + (e && e.message || e); });
      }, 'ok');
      box.append(h('div', { style: 'margin-top:8px;font-weight:700' }, '📱 फ़ोन पर AI (ऑफ़लाइन चलता है)'), sel, row(b), status);
    }
    var R = window.SpeechRecognition || window.webkitSpeechRecognition;
    if (R && R.install) { var vs = h('div', { style: 'font-weight:400;margin-top:4px' }); box.append(h('div', { style: 'margin-top:8px;font-weight:700' }, '🎙️ बिना नेट के बोलना'), row(btn('हिंदी आवाज़-पैक डाउनलोड करें', function () { vs.textContent = 'डाउनलोड हो रहा है…'; Promise.resolve(R.install({ langs: ['hi-IN'], processLocally: true })).then(function (ok) { vs.textContent = ok === false ? 'चालू नहीं हो पाया।' : '✓ अब बिना नेट के भी बोलकर लिख सकेंगे।'; }, function (e) { vs.textContent = 'चालू नहीं हो पाया: ' + (e && e.message || e); }); })), vs); }
  }
  window.Saathi = { respond: respond, matchProducts: matchProducts, norm: norm, parse: parseNewProduct, variantSpec: variantSpec, pricesIn: pricesIn, open: function () { $('saathiFab').click(); } };
  build();
})();
