/* Phone Doctor screen (admin app). Talks to the bridge that runs in Termux on the owner's phone (tools/doctor/bridge.py).
   Flow: set-up once, connect the customer's phone over Wi-Fi with Wireless debugging, run checks by complaint, fix with consent,
   print or send a report, and record the job and the money earned (kept on this phone only). */
(function () {
  'use strict';
  const P = window.DoctorParse; if (!P) return;
  const $ = (id) => document.getElementById(id);
  const h = (tag, props = {}, ...kids) => { const e = document.createElement(tag); for (const k of Object.keys(props)) { if (k === 'class') e.className = props[k]; else if (k.startsWith('on')) e[k] = props[k]; else e.setAttribute(k, props[k]); } for (const c of kids) { if (c == null) continue; e.append(c.nodeType ? c : document.createTextNode(String(c))); } return e; };
  const LS = { get: (k, d) => { try { const v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }, set: (k, v) => { try { localStorage.setItem(k, v); } catch (e) { } } };
  const SITE = 'https://pallavsharmaofficial.github.io/brandhoop';
  const EMOJI = { ok: '🟢', warn: '🟡', bad: '🔴', info: 'ℹ️' };

  /* ---------- the 22 tools ---------- */
  const TOOLS = [
    { id: 'info', ic: '📱', t: 'फ़ोन की पहचान', d: 'मॉडल, Android, RAM, कितने दिन से रीस्टार्ट नहीं हुआ', cmd: 'info', p: 'info' },
    { id: 'battery', ic: '🔋', t: 'बैटरी की सेहत', d: 'कितनी घिसी है, चार्ज साइकिल, तापमान', cmd: 'battery', p: 'battery', svc: 'बैटरी जाँच / बदलना' },
    { id: 'battery_apps', ic: '🪫', t: 'बैटरी खाने वाले ऐप', d: 'कौन-सा ऐप कितनी बैटरी खा रहा है', cmd: 'battery_apps', p: 'battery_apps', svc: 'फ़ालतू ऐप हटाना' },
    { id: 'ram', ic: '🧠', t: 'RAM की हालत', d: 'फ़ोन हैंग क्यों होता है', cmd: 'ram', p: 'ram', svc: 'फ़ोन स्पीड-अप' },
    { id: 'storage', ic: '💾', t: 'स्टोरेज की हालत', d: 'कितना भरा, कितना खाली', cmd: 'storage', p: 'storage', svc: 'स्टोरेज सफ़ाई और बैकअप' },
    { id: 'cpu', ic: '⚙️', t: 'लैग / CPU जाँच', d: 'कौन-सा ऐप फ़ोन को धीमा कर रहा है', cmd: 'cpu', p: 'cpu', svc: 'फ़ोन स्पीड-अप' },
    { id: 'heat', ic: '🌡️', t: 'फ़ोन गरम क्यों', d: 'CPU, बैटरी और सतह का तापमान', cmd: 'heat', p: 'heat', svc: 'हार्डवेयर जाँच रिपोर्ट' },
    { id: 'apps', ic: '📦', t: 'इंस्टॉल ऐप की जाँच', d: 'बाहर से आए और नकली क्लीनर ऐप', cmd: 'apps', p: 'apps', svc: 'फ़ालतू ऐप हटाना' },
    { id: 'bloat', ic: '🧹', t: 'फ़ालतू ऐप हटाओ', d: 'पहले से डले विज्ञापन/बेकार ऐप पहचानो, बंद करो', cmd: 'bloat', p: 'bloat', svc: 'फ़ालतू ऐप हटाना' },
    { id: 'audit', ic: '🛡️', t: 'ठगी वाले ऐप की जाँच', d: 'एक्सेसिबिलिटी, डिवाइस-एडमिन, बाहर से आए ऐप', cmd: 'audit', p: 'audit', svc: 'सुरक्षा जाँच' },
    { id: 'sensors', ic: '🧭', t: 'सेंसर जाँच', d: 'रोटेट, कंपास, प्रॉक्सिमिटी, लाइट', cmd: 'sensors', p: 'sensors', svc: 'हार्डवेयर जाँच रिपोर्ट' },
    { id: 'display', ic: '🖥️', t: 'स्क्रीन की जानकारी', d: 'रेज़ोल्यूशन और रिफ्रेश रेट', cmd: 'display', p: 'display' },
    { id: 'network', ic: '📶', t: 'वाई-फ़ाई / इंटरनेट जाँच', d: 'सिग्नल, स्पीड, देरी, पैकेट खोना', cmd: 'network', p: 'network' },
    { id: 'crashes', ic: '💥', t: 'क्रैश / हैंग लॉग', d: 'कौन-से ऐप बार-बार अटकते हैं', cmd: 'crashes', p: 'crashes', svc: 'फ़ोन स्पीड-अप' },
    { id: 'anim', ic: '⏩', t: 'एनिमेशन तेज़ करो', d: 'बिना कुछ हटाए फ़ोन तेज़ महसूस होता है', fix: true },
    { id: 'cache', ic: '🧽', t: 'कैश साफ़ करो', d: 'सारे ऐप का कचरा (फ़ोटो/डेटा नहीं हटता)', fix: true },
    { id: 'dexopt', ic: '🚀', t: 'ऐप तेज़ करो (ऑप्टिमाइज़)', d: 'ऐप को दोबारा कंपाइल करता है, कुछ मिनट लगते हैं', fix: true },
    { id: 'perms', ic: '🔑', t: 'ऐप की अनुमतियाँ', d: 'किसी ऐप को क्या-क्या इजाज़त मिली, रद्द करो', fix: true },
    { id: 'stop', ic: '⛔', t: 'ऐप ज़बरदस्ती बंद करो', d: 'बैकग्राउंड में चल रहे ऐप को रोको', fix: true },
    { id: 'install', ic: '🛒', t: 'Brandhoop ऐप डालो', d: 'ग्राहक के फ़ोन में दुकान का ऐप लगाओ', fix: true },
    { id: 'shot', ic: '📸', t: 'स्क्रीनशॉट (सबूत)', d: 'रिपोर्ट के लिए फ़ोन की स्क्रीन की फ़ोटो', fix: true },
    { id: 'reboot', ic: '🔄', t: 'फ़ोन रीस्टार्ट', d: 'सफ़ाई के बाद रीस्टार्ट', fix: true }
  ];
  const BUNDLES = [
    ['फ़ोन हैंग / लैग करता है', ['info', 'ram', 'storage', 'cpu', 'bloat', 'crashes']],
    ['बैटरी जल्दी ख़त्म', ['battery', 'battery_apps', 'heat', 'cpu', 'audit']],
    ['फ़ोन बहुत गरम', ['heat', 'battery', 'cpu', 'battery_apps']],
    ['स्टोरेज फुल', ['storage', 'apps', 'bloat']],
    ['विज्ञापन / अजीब ऐप / ठगी का शक', ['audit', 'apps', 'bloat', 'crashes']],
    ['हार्डवेयर का शक', ['info', 'battery', 'sensors', 'display', 'heat', 'network']],
    ['इंटरनेट धीमा', ['network', 'audit', 'ram']],
    ['पूरा हेल्थ चेक', ['info', 'battery', 'battery_apps', 'ram', 'storage', 'cpu', 'heat', 'apps', 'bloat', 'audit', 'sensors', 'display', 'network', 'crashes']]
  ];
  const SERVICES = ['बैटरी जाँच / बदलना', 'फ़ोन स्पीड-अप', 'फ़ालतू ऐप हटाना', 'स्टोरेज सफ़ाई और बैकअप', 'सुरक्षा जाँच', 'हार्डवेयर जाँच रिपोर्ट', 'Brandhoop ऐप डालना'];

  /* ---------- state and the bridge ---------- */
  const S = { url: LS.get('bhBridgeUrl', 'http://127.0.0.1:8765'), token: LS.get('bhBridgeToken', ''), up: false, device: null, model: '', consent: false, results: {}, done: [], busy: false };
  async function api(path, body) {
    const r = await fetch(S.url + path, { method: body ? 'POST' : 'GET', headers: { 'content-type': 'application/json', 'x-bridge-token': S.token }, body: body ? JSON.stringify(body) : undefined });
    return r.json();
  }
  async function ping() { try { const j = await fetch(S.url + '/health').then((r) => r.json()); S.up = !!j.ok; S.adb = j.adb; } catch (e) { S.up = false; } return S.up; }

  /* ---------- screen skeleton ---------- */
  let dlg, body, status, logBox;
  const money = (n) => '₹' + Math.round(n).toLocaleString('en-IN');
  function jobs() { try { return JSON.parse(LS.get('bhDoctorJobs', '[]')); } catch (e) { return []; } }
  function build() {
    const css = h('style'); css.textContent = `
      #docDlg{padding:0;border:0;width:100vw;max-width:100vw;height:100dvh;max-height:100dvh;background:var(--paper);color:var(--ink)}
      #docDlg .dw{max-width:720px;margin:0 auto;height:100dvh;display:flex;flex-direction:column}
      .dh{display:flex;align-items:center;gap:8px;padding:12px 14px;background:linear-gradient(160deg,var(--deep),#2B3558);color:#fff}.dh b{flex:1;line-height:1.2}.dh small{display:block;font-weight:400;opacity:.8;font-size:12px}.dh button{background:transparent;color:#fff;padding:6px 10px}
      .db2{flex:1;overflow:auto;padding:10px 12px 40px}.dc{background:var(--soft);border:1px solid var(--line);border-radius:14px;padding:12px;margin:10px 0}.dc h3{margin:0 0 6px;font-size:17px;color:var(--brand)}
      .dpill{display:inline-block;border-radius:99px;padding:2px 10px;font-size:13px;font-weight:700;color:#fff;margin-right:6px}.dgrid{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:8px}
      .dt{background:var(--paper);border:1.5px solid var(--line);border-radius:12px;padding:10px;text-align:left;color:var(--ink);font-weight:600;font-size:14px;line-height:1.3}.dt small{display:block;font-weight:400;color:#6b6b73;font-size:12px;margin-top:2px}.dt.fix{border-color:var(--accent)}
      .dchips{display:flex;gap:6px;flex-wrap:wrap}.dchips button{padding:8px 12px;font-size:14px;border-radius:99px;background:var(--paper);color:var(--brand);border:1.5px solid var(--brand)}
      .dres{border-left:6px solid var(--line)}.dres.ok{border-color:#2E7D32}.dres.warn{border-color:#EF6C00}.dres.bad{border-color:#C62828}.dres ul{margin:6px 0;padding-left:18px;font-size:15px}.dres .adv{background:rgba(216,102,42,.12);border-radius:10px;padding:8px 10px;margin:6px 0;font-size:15px}
      .drow{display:flex;gap:8px;flex-wrap:wrap;margin-top:8px}.dsm{padding:6px 10px;font-size:14px}.dcode{background:#0F1322;color:#e8e8f0;border-radius:10px;padding:8px 10px;font:13px/1.4 ui-monospace,monospace;word-break:break-all;white-space:pre-wrap}
      #docDlg input[type=text],#docDlg input[type=number],#docDlg select{width:100%}.dmini{font-size:13px;color:#6b6b73}.dcheck{display:flex;gap:10px;align-items:flex-start;margin:8px 0;font-weight:600}
      #docBar{position:sticky;bottom:0;background:var(--paper);border-top:1px solid var(--line);padding:8px 12px;font-size:14px}`;
    document.head.append(css);
    status = h('div', { class: 'dc' }); body = h('div', { class: 'db2' }); logBox = h('div');
    dlg = h('dialog', { id: 'docDlg' }, h('div', { class: 'dw' },
      h('div', { class: 'dh' }, h('b', {}, '🩺 फ़ोन डॉक्टर', h('small', {}, 'ग्राहक का फ़ोन जाँचिए और सुधारिए, कंप्यूटर के बिना')), h('button', { type: 'button', onclick: () => dlg.close() }, '✕')), body, h('div', { id: 'docBar' }, 'तैयार')));
    document.body.append(dlg);
    const btn = $('docBtn'); if (btn) btn.onclick = open;
  }
  function msg(t) { const b = $('docBar'); if (b) b.textContent = t; }
  async function open() { dlg.showModal(); await ping(); render(); if (S.up && S.token) refreshDevices(); }

  /* ---------- rendering ---------- */
  function render() {
    body.textContent = '';
    body.append(statusCard(), S.up ? (S.device ? toolsCard() : connectCard()) : setupCard(), resultsCard(), reportCard(), earnCard(), settingsCard());
  }
  function statusCard() {
    return h('div', { class: 'dc' }, h('span', { class: 'dpill', style: 'background:' + (S.up ? '#2E7D32' : '#C62828') }, S.up ? 'पुल चालू' : 'पुल बंद'), h('span', { class: 'dpill', style: 'background:' + (S.device ? '#2E7D32' : '#566170') }, S.device ? ('ग्राहक का फ़ोन: ' + (S.model || 'जुड़ा')) : 'ग्राहक का फ़ोन नहीं जुड़ा'),
      S.up && S.device ? h('div', { class: 'drow' }, h('button', { class: 'alt dsm', type: 'button', onclick: disconnect }, 'फ़ोन अलग करें')) : null);
  }
  function setupCard() {
    const cmd = `pkg update -y && pkg install -y python android-tools curl && curl -fsSL ${SITE}/doctor/install.sh | sh`;
    return h('div', { class: 'dc' }, h('h3', {}, 'पहली बार सेटअप (एक बार, 5 मिनट)'),
      h('div', {}, '1) F-Droid से ', h('b', {}, 'Termux'), ' इंस्टॉल कीजिए (f-droid.org/packages/com.termux)। Play Store वाला पुराना है, उसे मत लीजिए।'),
      h('div', { style: 'margin-top:6px' }, '2) Termux खोलकर नीचे वाला एक आदेश चिपकाइए और Enter दबाइए:'), h('div', { class: 'dcode' }, cmd),
      h('div', { class: 'drow' }, h('button', { class: 'dsm', type: 'button', onclick: () => { navigator.clipboard && navigator.clipboard.writeText(cmd); msg('आदेश कॉपी हो गया'); } }, 'आदेश कॉपी करें')),
      h('div', { style: 'margin-top:8px' }, '3) फिर Termux में लिखिए: ', h('b', {}, 'bhdoctor'), ' । एक टोकन छपेगा। Termux को खुला रहने दीजिए (नोटिफ़िकेशन में "Acquire wakelock" दबा दीजिए)।'),
      h('div', { style: 'margin-top:6px' }, '4) नीचे सेटिंग में टोकन डालकर "जाँचें" दबाइए।'),
      h('div', { class: 'dmini', style: 'margin-top:6px' }, 'Chrome एक बार पूछ सकता है "स्थानीय नेटवर्क की अनुमति": "अनुमति दें" दबाइए, यह सिर्फ़ आपके अपने फ़ोन के Termux से बात करने के लिए है।'),
      h('div', { class: 'drow' }, h('button', { class: 'alt dsm', type: 'button', onclick: async () => { msg('जाँच रहे हैं…'); await ping(); render(); msg(S.up ? 'पुल चालू है' : 'पुल नहीं मिला: Termux में bhdoctor चल रहा है?'); } }, 'फिर से जाँचें')));
  }
  function connectCard() {
    const c = h('div', { class: 'dc' }, h('h3', {}, 'ग्राहक का फ़ोन जोड़िए'));
    const consent = h('input', { type: 'checkbox' }); consent.checked = S.consent; consent.onchange = () => { S.consent = consent.checked; };
    c.append(h('label', { class: 'dcheck' }, consent, h('span', {}, 'ग्राहक ने फ़ोन की जाँच और ज़रूरी सुधार की इजाज़त दी है। उसकी फ़ोटो, मैसेज और फ़ाइलें बिना पूछे नहीं देखनी हैं।')));
    c.append(h('div', { class: 'dmini' }, 'दोनों फ़ोन एक ही वाई-फ़ाई पर हों। ग्राहक के फ़ोन पर (Android 11 या नया): सेटिंग > फ़ोन के बारे में > "बिल्ड नंबर" 7 बार दबाएँ > डेवलपर विकल्प > "Wireless debugging" चालू करें।'));
    const hp1 = h('input', { type: 'text', placeholder: 'पेयरिंग का IP:पोर्ट, जैसे 192.168.1.5:41234', inputmode: 'text' }), code = h('input', { type: 'text', placeholder: '6 अंक का पेयरिंग कोड', inputmode: 'numeric', maxlength: 6 }), hp2 = h('input', { type: 'text', placeholder: 'जुड़ने का IP:पोर्ट (Wireless debugging की मुख्य स्क्रीन पर)' });
    c.append(h('div', { style: 'margin-top:8px;font-weight:700' }, 'चरण 1: जोड़ी बनाएँ'), h('div', { class: 'dmini' }, '"Pair device with pairing code" दबाने पर IP:पोर्ट और कोड दिखेगा।'), hp1, code,
      h('div', { class: 'drow' }, h('button', { class: 'dsm', type: 'button', onclick: async () => { if (!S.consent) return msg('पहले ग्राहक की सहमति वाला डिब्बा चुनिए'); msg('जोड़ी बना रहे हैं…'); const j = await api('/pair', { hostport: hp1.value.trim(), code: code.value.trim() }).catch(() => ({ ok: false, out: 'पुल से बात नहीं हुई' })); msg(j.ok ? '✓ जोड़ी बन गई, अब चरण 2' : 'नहीं हुआ: ' + (j.out || j.err)); } }, 'जोड़ी बनाओ')),
      h('div', { style: 'margin-top:8px;font-weight:700' }, 'चरण 2: जुड़ें'), hp2,
      h('div', { class: 'drow' }, h('button', { class: 'dsm', type: 'button', onclick: async () => { if (!S.consent) return msg('पहले ग्राहक की सहमति वाला डिब्बा चुनिए'); msg('जुड़ रहे हैं…'); const j = await api('/connect', { hostport: hp2.value.trim() }).catch(() => ({ ok: false, out: 'पुल से बात नहीं हुई' })); if (j.ok) { pickDevice(j.devices); } else msg('नहीं जुड़ा: ' + (j.out || j.err)); } }, 'जुड़ो')));
    return c;
  }
  async function refreshDevices() { const j = await api('/devices').catch(() => null); if (j && j.ok) pickDevice(j.devices); else if (j && j.err) msg(j.err); }
  function pickDevice(list) { const d = (list || []).find((x) => x.state === 'device'); if (d) { S.device = d.serial; S.model = d.model; msg('✓ जुड़ गया: ' + d.model); } else if ((list || []).some((x) => x.state === 'unauthorized')) msg('फ़ोन पर "USB/वायरलेस डीबगिंग की अनुमति" वाला संदेश आया होगा, "Allow" दबवाइए'); render(); }
  async function disconnect() { await api('/disconnect', {}).catch(() => { }); S.device = null; S.model = ''; render(); }

  function toolsCard() {
    const c = h('div', { class: 'dc' }, h('h3', {}, 'शिकायत चुनिए'), h('div', { class: 'dchips' }, ...BUNDLES.map((b) => h('button', { type: 'button', onclick: () => runBundle(b[1], b[0]) }, b[0]))));
    const g = h('div', { class: 'dgrid', style: 'margin-top:10px' });
    TOOLS.forEach((t) => g.append(h('button', { class: 'dt' + (t.fix ? ' fix' : ''), type: 'button', onclick: () => runOne(t) }, t.ic + ' ' + t.t, h('small', {}, t.d))));
    return h('div', {}, c, h('div', { class: 'dc' }, h('h3', {}, 'सारे 22 औज़ार'), h('div', { class: 'dmini' }, 'हरे किनारे वाले: सिर्फ़ देखते हैं। नारंगी किनारे वाले: फ़ोन में बदलाव करते हैं, पहले सहमति पूछेंगे।'), g));
  }

  /* ---------- running things ---------- */
  async function run(id, args, confirm) {
    if (!S.device) throw new Error('फ़ोन जुड़ा नहीं है');
    const j = await api('/run', { id, device: S.device, args: args || {}, confirm: !!confirm });
    if (j.needsConfirm) { const e = new Error(j.err); e.needsConfirm = true; throw e; }
    return j;
  }
  function addResult(tool, parsed, raw) { S.results[tool.id] = { tool, parsed, raw, at: Date.now() }; render(); }
  async function runRead(tool) {
    msg(tool.ic + ' ' + tool.t + '…'); const j = await run(tool.cmd, {}); if (!j.ok && !j.out) { addResult(tool, { v: 'info', head: 'जवाब नहीं मिला', lines: [j.err || 'फ़ोन ने जवाब नहीं दिया'], advice: [], data: {} }, j.err || ''); return; }
    const parsed = P.parse[tool.p](j.out); if (tool.id === 'info' && parsed.data && parsed.data.model) S.model = parsed.data.model; addResult(tool, parsed, j.out);
  }
  async function runOne(tool) {
    if (S.busy) return msg('एक काम चल रहा है, रुकिए'); S.busy = true;
    try { if (tool.fix) await runFix(tool); else await runRead(tool); } catch (e) { msg(e.message); } finally { S.busy = false; }
  }
  async function runBundle(ids, name) {
    if (S.busy) return msg('एक काम चल रहा है, रुकिए'); S.busy = true; S.bundle = name;
    try { for (const id of ids) { const t = TOOLS.find((x) => x.id === id); await runRead(t); } const bad = ids.filter((i) => S.results[i] && S.results[i].parsed.v === 'bad').length, warn = ids.filter((i) => S.results[i] && S.results[i].parsed.v === 'warn').length; msg('पूरा: ' + bad + ' 🔴, ' + warn + ' 🟡। नीचे रिपोर्ट देखिए।'); setTimeout(() => { const r = $('docRes'); if (r) r.scrollIntoView({ behavior: 'smooth' }); }, 100); }
    catch (e) { msg(e.message); } finally { S.busy = false; }
  }
  function confirmDialog(text, ok) {
    const cb = h('input', { type: 'checkbox' }), go = h('button', { type: 'button', disabled: 'true' }, 'पक्का, कर दो'), d = h('dialog', { style: 'border-radius:14px;padding:16px;max-width:420px;background:var(--paper);color:var(--ink)' },
      h('div', { style: 'font-weight:700;margin-bottom:8px' }, text), h('label', { class: 'dcheck' }, cb, h('span', {}, 'ग्राहक को बता दिया है और उसने इजाज़त दी है')),
      h('div', { class: 'drow' }, go, h('button', { class: 'alt', type: 'button', onclick: () => d.close() }, 'रहने दो')));
    cb.onchange = () => { go.disabled = !cb.checked; }; go.onclick = () => { d.close(); ok(); }; d.addEventListener('close', () => d.remove()); document.body.append(d); d.showModal();
  }
  async function apply(id, args, label) { msg(label + '…'); try { const j = await run(id, args, true); msg(j.ok ? '✓ ' + label + ' हो गया' : label + ' नहीं हुआ: ' + (j.err || j.out)); S.done.push(label); return j; } catch (e) { msg(e.message); } }
  function askPkg(title, fn) { const i = h('input', { type: 'text', placeholder: 'पैकेज का नाम, जैसे com.facebook.katana' }), d = h('dialog', { style: 'border-radius:14px;padding:16px;max-width:420px;background:var(--paper);color:var(--ink)' }, h('div', { style: 'font-weight:700;margin-bottom:6px' }, title), i, h('div', { class: 'drow' }, h('button', { type: 'button', onclick: () => { const v = i.value.trim(); d.close(); if (v) fn(v); } }, 'आगे'), h('button', { class: 'alt', type: 'button', onclick: () => d.close() }, 'रद्द'))); d.addEventListener('close', () => d.remove()); document.body.append(d); d.showModal(); }
  async function runFix(tool) {
    const guard = (text, fn) => confirmDialog(text, fn);
    if (tool.id === 'anim') return guard('एनिमेशन की गति 0.5 करें? (वापस 1 करना भी यहीं से हो सकता है)', () => apply('anim_set', { value: '0.5' }, 'एनिमेशन तेज़'));
    if (tool.id === 'cache') return guard('सारे ऐप का कैश साफ़ करें? (फ़ोटो, चैट और लॉगिन नहीं हटते)', () => apply('cache', {}, 'कैश साफ़'));
    if (tool.id === 'dexopt') return guard('ऐप ऑप्टिमाइज़ करें? इसमें कुछ मिनट लगते हैं और फ़ोन गरम हो सकता है।', () => apply('dexopt', {}, 'ऐप ऑप्टिमाइज़'));
    if (tool.id === 'reboot') return guard('फ़ोन रीस्टार्ट करें? कनेक्शन टूटेगा, दोबारा जोड़ना पड़ेगा।', async () => { await apply('reboot', {}, 'रीस्टार्ट'); S.device = null; render(); });
    if (tool.id === 'install') return guard('इस फ़ोन में Brandhoop ऐप इंस्टॉल करें?', () => apply('install_brandhoop', {}, 'Brandhoop ऐप इंस्टॉल'));
    if (tool.id === 'stop') return askPkg('किस ऐप को बंद करें?', (pkg) => guard(pkg + ' को बंद करें?', () => apply('stop', { pkg }, pkg + ' बंद')));
    if (tool.id === 'perms') return askPkg('किस ऐप की अनुमतियाँ देखनी हैं?', async (pkg) => { const j = await run('perms', { pkg }); const parsed = P.parse.perms(j.out); parsed.data.pkg = pkg; addResult({ id: 'perms:' + pkg, ic: '🔑', t: 'अनुमतियाँ: ' + pkg }, parsed, j.out); });
    if (tool.id === 'shot') { msg('स्क्रीनशॉट ले रहे हैं…'); const j = await run('screenshot', {}, true).catch((e) => ({ ok: false, err: e.message })); if (j.ok) { S.shot = 'data:image/png;base64,' + j.png; render(); msg('✓ स्क्रीनशॉट लिया (रिपोर्ट में जुड़ेगा)'); } else msg('नहीं हुआ: ' + j.err); }
  }

  /* ---------- results, with the fix buttons that belong to each finding ---------- */
  function actionsFor(id, parsed) {
    const row = h('div', { class: 'drow' }), d = parsed.data || {};
    const stopBtn = (pkg) => h('button', { class: 'alt dsm', type: 'button', onclick: () => confirmDialog(pkg + ' को बंद करें?', () => apply('stop', { pkg }, pkg + ' बंद')) }, 'रोको: ' + pkg.split('.').slice(-2).join('.'));
    const rm = (pkg) => h('button', { class: 'alt dsm', type: 'button', onclick: () => confirmDialog(pkg + ' को हटाएँ?', () => apply('uninstall', { pkg }, pkg + ' हटाया')) }, 'हटाओ: ' + pkg.split('.').slice(-2).join('.'));
    if (id === 'battery_apps' || id === 'cpu') (d.rows || []).slice(0, 3).filter((r) => r.pkg && /^[A-Za-z][\w]*(\.\w+)+$/.test(r.pkg || r.name || '')).forEach((r) => row.append(stopBtn(r.pkg)));
    if (id === 'cpu') (d.rows || []).slice(0, 3).forEach((r) => { if (r.name && /^[A-Za-z][\w]*(\.\w+)+$/.test(r.name)) row.append(stopBtn(r.name)); });
    if (id === 'audit') (d.sus || []).forEach((p) => row.append(rm(p)));
    if (id === 'ram' || id === 'storage') row.append(h('button', { class: 'alt dsm', type: 'button', onclick: () => confirmDialog('सारे ऐप का कैश साफ़ करें?', () => apply('cache', {}, 'कैश साफ़')) }, 'कैश साफ़ करो'));
    if (id === 'ram' || id === 'cpu') row.append(h('button', { class: 'alt dsm', type: 'button', onclick: () => confirmDialog('एनिमेशन 0.5 करें?', () => apply('anim_set', { value: '0.5' }, 'एनिमेशन तेज़')) }, 'एनिमेशन तेज़'));
    if (id === 'bloat' && (d.actions || []).length) {
      const boxes = (d.actions || []).map((a) => { const cb = h('input', { type: 'checkbox' }); cb.checked = a.kind === 'disable'; return { a, cb }; });
      const wrap = h('div', {}, ...boxes.map((b) => h('label', { class: 'dcheck', style: 'font-weight:500' }, b.cb, h('span', {}, (b.a.kind === 'disable' ? 'बंद: ' : 'हटाओ: ') + b.a.pkg))));
      row.append(wrap, h('button', { class: 'dsm', type: 'button', onclick: () => { const sel = boxes.filter((b) => b.cb.checked).map((b) => b.a); if (!sel.length) return msg('कुछ चुनिए'); confirmDialog(sel.length + ' ऐप पर काम होगा (बंद किए ऐप बाद में वापस चालू हो सकते हैं)।', async () => { for (const a of sel) await apply(a.kind === 'disable' ? 'disable' : 'uninstall', { pkg: a.pkg }, (a.kind === 'disable' ? 'बंद: ' : 'हटाया: ') + a.pkg); }); } }, 'चुने हुए करो'));
    }
    if (id.indexOf('perms:') === 0 && (d.risky || []).length) (d.risky || []).forEach((p) => row.append(h('button', { class: 'alt dsm', type: 'button', onclick: () => confirmDialog(d.pkg + ' की ' + p.replace('android.permission.', '') + ' अनुमति रद्द करें?', () => apply('revoke', { pkg: d.pkg, perm: p }, p.replace('android.permission.', '') + ' रद्द')) }, 'रद्द: ' + p.replace('android.permission.', ''))));
    return row.children.length ? row : null;
  }
  function resultsCard() {
    const ids = Object.keys(S.results); if (!ids.length && !S.shot) return h('div');
    const c = h('div', { id: 'docRes' });
    ids.forEach((id) => { const r = S.results[id], p = r.parsed; c.append(h('div', { class: 'dc dres ' + p.v }, h('h3', {}, EMOJI[p.v] + ' ' + r.tool.ic + ' ' + r.tool.t), h('div', { style: 'font-weight:700' }, p.head), p.lines.length ? h('ul', {}, ...p.lines.map((l) => h('li', {}, l))) : null, ...p.advice.map((a) => h('div', { class: 'adv' }, '➜ ' + a)), actionsFor(id, p), h('details', { style: 'margin-top:6px' }, h('summary', { class: 'dmini' }, 'फ़ोन का असली जवाब'), h('div', { class: 'dcode' }, String(r.raw || '').slice(0, 3000))))); });
    if (S.shot) c.append(h('div', { class: 'dc' }, h('h3', {}, '📸 स्क्रीनशॉट'), h('img', { src: S.shot, style: 'max-width:60%;border-radius:8px' })));
    return c;
  }

  /* ---------- report, WhatsApp text, price list and earnings ---------- */
  function prices() { try { return JSON.parse(LS.get('bhDoctorPrices', '{}')); } catch (e) { return {}; } }
  function suggestions() { const set = {}; Object.keys(S.results).forEach((id) => { const r = S.results[id]; if (r.tool.svc && (r.parsed.v === 'bad' || r.parsed.v === 'warn')) set[r.tool.svc] = 1; }); S.done.forEach((d) => { if (/Brandhoop/.test(d)) set['Brandhoop ऐप डालना'] = 1; }); return Object.keys(set); }
  function summaryText() {
    const ids = Object.keys(S.results).filter((i) => S.results[i].tool.p), L = ['*Brandhoop Mobile Point · फ़ोन जाँच रिपोर्ट*', 'फ़ोन: ' + (S.model || '-'), new Date().toLocaleDateString('hi-IN'), ''];
    ids.forEach((i) => { const r = S.results[i]; L.push(EMOJI[r.parsed.v] + ' ' + r.tool.t + ': ' + r.parsed.head); });
    const adv = []; ids.forEach((i) => S.results[i].parsed.advice.forEach((a) => adv.push(a))); if (adv.length) { L.push('', '*सुझाव*'); adv.slice(0, 8).forEach((a) => L.push('• ' + a)); }
    if (S.done.length) { L.push('', '*किए गए काम*'); S.done.forEach((d) => L.push('✓ ' + d)); }
    L.push('', 'गेट नं. 5, कमला मोदी मार्केट, नीम का थाना · 86197 67291 · 72399 38540'); return L.join('\n');
  }
  function reportHtml(customer) {
    const ids = Object.keys(S.results).filter((i) => S.results[i].tool.p), sug = suggestions(), pr = prices(), total = sug.reduce((a, s) => a + (+pr[s] || 0), 0);
    const esc = (t) => String(t).replace(/[&<>]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
    return `<!doctype html><meta charset="utf-8"><title>फ़ोन जाँच रिपोर्ट</title><style>body{font:15px/1.5 system-ui,"Noto Sans Devanagari",sans-serif;margin:24px;color:#14182B}h1{color:#1F2744;margin:0}h2{font-size:16px;margin:14px 0 4px}.s{border-left:6px solid #ccc;padding:4px 10px;margin:8px 0;background:#f6f6f6}.ok{border-color:#2E7D32}.warn{border-color:#EF6C00}.bad{border-color:#C62828}ul{margin:4px 0;padding-left:20px}.a{color:#A9481C}header{display:flex;justify-content:space-between;border-bottom:3px solid #D8662A;padding-bottom:8px;margin-bottom:10px}footer{margin-top:18px;border-top:1px solid #ccc;padding-top:6px;font-size:13px}@media print{button{display:none}}</style>
<header><div><h1>Brandhoop Mobile Point</h1><div>गेट नं. 5, कमला मोदी मार्केट, नीम का थाना, राजस्थान 332713</div><div>86197 67291 · 72399 38540</div></div><div style="text-align:right"><b>फ़ोन जाँच रिपोर्ट</b><div>${esc(new Date().toLocaleDateString('hi-IN'))}</div></div></header>
<div><b>फ़ोन:</b> ${esc(S.model || '-')}${customer ? ' &nbsp; <b>ग्राहक:</b> ' + esc(customer) : ''}</div>
${ids.map((i) => { const r = S.results[i], p = r.parsed; return `<div class="s ${p.v}"><h2>${EMOJI[p.v]} ${esc(r.tool.t)}: ${esc(p.head)}</h2><ul>${p.lines.map((l) => '<li>' + esc(l) + '</li>').join('')}</ul>${p.advice.map((a) => '<div class="a">➜ ' + esc(a) + '</div>').join('')}</div>`; }).join('')}
${S.done.length ? '<h2>किए गए काम</h2><ul>' + S.done.map((d) => '<li>✓ ' + esc(d) + '</li>').join('') + '</ul>' : ''}
${sug.length ? '<h2>सुझाई गई सेवाएँ</h2><ul>' + sug.map((s) => '<li>' + esc(s) + (pr[s] ? ' — ₹' + pr[s] : '') + '</li>').join('') + '</ul>' + (total ? '<b>कुल: ₹' + total + '</b>' : '') : ''}
<footer>यह जाँच ग्राहक की सहमति से की गई। ग्राहक की फ़ोटो, मैसेज या फ़ाइलें नहीं देखी गईं। ये रिपोर्ट फ़ोन की अपनी जानकारी पर आधारित है।</footer><p><button onclick="print()">प्रिंट करें</button></p>`;
  }
  function reportCard() {
    const c = h('div', { class: 'dc' }, h('h3', {}, '📄 रिपोर्ट और बिल'));
    const has = Object.keys(S.results).some((i) => S.results[i].tool.p);
    if (!has) { c.append(h('div', { class: 'dmini' }, 'कोई जाँच चलाइए, फिर यहाँ रिपोर्ट बनेगी।')); return c; }
    const cust = h('input', { type: 'text', placeholder: 'ग्राहक का नाम' }), ph = h('input', { type: 'text', placeholder: 'ग्राहक का फ़ोन (ज़रूरी नहीं)', inputmode: 'numeric' }), amt = h('input', { type: 'number', placeholder: 'ग्राहक से कितने रुपये लिए', inputmode: 'numeric' });
    const sug = suggestions(); if (sug.length) c.append(h('div', {}, h('b', {}, 'सुझाई गई सेवाएँ: '), sug.join(', ')));
    c.append(cust, ph, amt, h('div', { class: 'drow' },
      h('button', { class: 'dsm', type: 'button', onclick: () => { const w = window.open('', '_blank'); if (w) { w.document.write(reportHtml(cust.value.trim())); w.document.close(); } else msg('पॉप-अप रोका गया है, अनुमति दीजिए'); } }, 'रिपोर्ट खोलो / प्रिंट'),
      h('button', { class: 'dsm', type: 'button', onclick: () => { const t = summaryText(), n = ph.value.replace(/\D/g, ''), to = n.length === 10 ? '91' + n : ''; window.open('https://wa.me/' + to + '?text=' + encodeURIComponent(t), '_blank'); } }, 'WhatsApp पर भेजो'),
      h('button', { class: 'dsm', type: 'button', onclick: () => { const list = jobs(); list.unshift({ t: Date.now(), model: S.model, customer: cust.value.trim(), phone: ph.value.trim(), services: suggestions().concat(S.done), amount: +amt.value || 0 }); LS.set('bhDoctorJobs', JSON.stringify(list.slice(0, 500))); msg('✓ काम दर्ज हुआ'); S.results = {}; S.done = []; S.shot = null; render(); } }, 'काम दर्ज करो (कमाई में जोड़ो)')));
    return c;
  }
  function earnCard() {
    const list = jobs(), now = new Date(), d0 = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime(), sum = (from) => list.filter((j) => j.t >= from).reduce((a, j) => a + (j.amount || 0), 0), cnt = (from) => list.filter((j) => j.t >= from).length;
    const week = d0 - 6 * 864e5, month = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
    const c = h('div', { class: 'dc' }, h('h3', {}, '💰 कमाई का हिसाब'), h('div', {}, 'आज: ' + money(sum(d0)) + ' (' + cnt(d0) + ' काम) · 7 दिन: ' + money(sum(week)) + ' (' + cnt(week) + ') · इस महीने: ' + money(sum(month)) + ' (' + cnt(month) + ')'), h('div', { class: 'dmini' }, 'ये सिर्फ़ इसी फ़ोन में रहता है।'));
    const pr = prices(), det = h('details', { style: 'margin-top:8px' }, h('summary', {}, 'सेवा की दरें (आप तय करें)'));
    SERVICES.forEach((s) => { const i = h('input', { type: 'number', placeholder: '₹', value: pr[s] || '', inputmode: 'numeric', style: 'width:110px' }); i.onchange = () => { const p = prices(); p[s] = +i.value || 0; LS.set('bhDoctorPrices', JSON.stringify(p)); }; det.append(h('div', { class: 'drow', style: 'align-items:center' }, h('span', { style: 'flex:1' }, s), i)); });
    det.append(h('div', { class: 'dmini' }, 'दरें अपने इलाके और मेहनत के हिसाब से रखिए। रिपोर्ट में यही दिखेंगी।'));
    c.append(det);
    if (list.length) c.append(h('details', {}, h('summary', {}, 'पिछले काम'), ...list.slice(0, 15).map((j) => h('div', { class: 'dmini' }, new Date(j.t).toLocaleDateString('hi-IN') + ' · ' + (j.model || '-') + ' · ' + (j.customer || '-') + ' · ' + money(j.amount)))));
    return c;
  }
  function settingsCard() {
    const url = h('input', { type: 'text', value: S.url }), tok = h('input', { type: 'text', value: S.token, placeholder: 'Termux में छपा टोकन', autocapitalize: 'characters' });
    return h('div', { class: 'dc' }, h('details', { open: S.up ? undefined : 'true' }, h('summary', { style: 'font-weight:700' }, '⚙ पुल की सेटिंग'), h('div', { class: 'dmini' }, 'पुल का पता'), url, h('div', { class: 'dmini', style: 'margin-top:6px' }, 'टोकन'), tok,
      h('div', { class: 'drow' }, h('button', { class: 'dsm', type: 'button', onclick: async () => { S.url = url.value.trim().replace(/\/$/, ''); S.token = tok.value.trim(); LS.set('bhBridgeUrl', S.url); LS.set('bhBridgeToken', S.token); msg('जाँच रहे हैं…'); await ping(); render(); msg(S.up ? 'पुल चालू है' : 'पुल नहीं मिला'); if (S.up && S.token) refreshDevices(); } }, 'सेव करो और जाँचो'))));
  }

  window.PhoneDoctor = { open: open, state: S, tools: TOOLS, bundles: BUNDLES };
  build();
})();
