/* Phone Doctor: turns the raw text an Android phone prints (dumpsys, df, pm ...) into a verdict a customer can understand.
   Plain functions with no screen code, so they can be tested with sample output. Each parser returns
   { v: 'ok' | 'warn' | 'bad' | 'info', head: one-line summary, lines: [facts], advice: [what to do], data: {...} }.
   Anything that could not be read says so; a parser never invents a number. */
(function (root) {
  'use strict';
  var KB = 1024;
  function sections(out) { var o = { _: [] }, cur = '_'; String(out || '').split('\n').forEach(function (l) { var m = /^===([A-Z]+)===\s*$/.exec(l.trim()); if (m) { cur = m[1]; o[cur] = []; } else o[cur].push(l); }); Object.keys(o).forEach(function (k) { o[k] = o[k].join('\n'); }); return o; }
  function num(s) { var n = parseFloat(String(s).replace(/,/g, '')); return isNaN(n) ? null : n; }
  function gb(kb) { return (kb / KB / KB).toFixed(1) + ' GB'; }
  function pkgs(text) { var o = []; String(text).split('\n').forEach(function (l) { var m = /^package:([A-Za-z0-9_.]+)/.exec(l.trim()); if (m) o.push(m[1]); }); return o; }
  function res(v, head, lines, advice, data) { return { v: v, head: head, lines: lines || [], advice: advice || [], data: data || {} }; }

  /* Apps that usually slow a phone or drain its battery: pretend "cleaners", boosters, and well-known preloaded junk. */
  var JUNK_USER = /(cleaner|booster|speedup|speed\.up|phonemaster|junk|antivirus\.free|batterysaver|battery\.saver|ramclean|cpucooler|cooler)/i;
  var SAFE_DISABLE = [
    ['com.facebook.appmanager', 'Facebook App Manager (पहले से डला, अपने-आप अपडेट करता रहता है)'],
    ['com.facebook.services', 'Facebook Services (पहले से डला)'],
    ['com.facebook.system', 'Facebook System (पहले से डला)'],
    ['com.netflix.partner.activation', 'Netflix Partner (पहले से डला)'],
    ['com.miui.analytics', 'MIUI Analytics (आपका इस्तेमाल रिकॉर्ड करने वाला)'],
    ['com.miui.msa.global', 'MIUI विज्ञापन सेवा (विज्ञापन दिखाती है)'],
    ['com.xiaomi.mipicks', 'GetApps (विज्ञापन और सुझाव वाला स्टोर)'],
    ['com.miui.hybrid', 'Quick Apps (पहले से डला, ज़्यादातर बेकार)'],
    ['com.samsung.android.bixby.agent', 'Bixby (अगर इस्तेमाल नहीं होता)'],
    ['com.samsung.android.game.gamehome', 'Game Launcher (अगर इस्तेमाल नहीं होता)'],
    ['com.hihonor.hnoffice', 'पहले से डला ऑफ़िस ऐप'],
    ['com.heytap.browser', 'पहले से डला ब्राउज़र (अगर Chrome चलता है)'],
    ['com.oppo.market', 'पहले से डला ऐप स्टोर (अगर Play Store चलता है)'],
    ['com.vivo.browser', 'पहले से डला ब्राउज़र (अगर Chrome चलता है)'],
    ['com.vivo.appstore', 'पहले से डला ऐप स्टोर (अगर Play Store चलता है)']
  ];
  var TRUSTED_ACCESS = /^(com\.google\.android\.marvin\.talkback|com\.google\.android\.accessibility\.|com\.android\.|com\.samsung\.|com\.miui\.|com\.xiaomi\.|com\.oneplus\.|com\.heytap\.|com\.vivo\.|com\.coloros\.|com\.google\.android\.apps\.accessibility)/;

  function name(pkg) { return pkg; }

  /* ---------- the parsers ---------- */
  function info(out) {
    var kv = {}; String(out).split('\n').forEach(function (l) { var m = /^([a-z.]+)=(.*)$/.exec(l.trim()); if (m) kv[m[1]] = m[2].trim(); });
    var mem = /MemTotal:\s+(\d+)\s*kB/.exec(out), up = /up\s+(?:(\d+)\s+days?,\s+)?(?:(\d+):(\d+)|(\d+)\s+min)/.exec(out), size = /Physical size:\s*(\S+)/.exec(out), dens = /Physical density:\s*(\d+)/.exec(out);
    var days = up && up[1] ? +up[1] : 0, lines = [], advice = [], v = 'info', patch = kv['ro.build.version.security_patch'], sdk = +kv['ro.build.version.sdk'] || 0;
    var model = ((kv['ro.product.manufacturer'] || '') + ' ' + (kv['ro.product.model'] || '')).trim() || 'अज्ञात फ़ोन';
    lines.push('फ़ोन: ' + model); if (kv['ro.build.version.release']) lines.push('Android ' + kv['ro.build.version.release'] + ' (API ' + sdk + ')');
    if (mem) lines.push('RAM: ' + gb(+mem[1]) + ' कुल');
    if (size) lines.push('स्क्रीन: ' + size[1] + (dens ? ' · घनत्व ' + dens[1] : ''));
    if (days) lines.push('बिना रीस्टार्ट चल रहा: ' + days + ' दिन');
    if (days >= 10) { v = 'warn'; advice.push('फ़ोन ' + days + ' दिन से रीस्टार्ट नहीं हुआ। रीस्टार्ट से अक्सर लैग कम हो जाता है।'); }
    if (patch) { var d = new Date(patch), months = isNaN(d) ? 0 : Math.floor((Date.now() - d) / (30.4 * 864e5)); lines.push('सुरक्षा अपडेट की तारीख़: ' + patch + (months >= 12 ? ' (' + months + ' महीने पुराना)' : '')); if (months >= 12) { v = 'warn'; advice.push('सुरक्षा अपडेट एक साल से पुराना है। अपडेट आ सकता हो तो करवाइए।'); } }
    if (sdk && sdk < 30) { advice.push('Android 11 से पुराना फ़ोन है: वायरलेस डीबगिंग सीधे नहीं चलेगी (USB से एक बार चालू करनी पड़ती है)।'); }
    return res(v, model, lines, advice, { model: model, sdk: sdk, ramKb: mem ? +mem[1] : 0, days: days });
  }

  function battery(out) {
    var s = sections(out), t = s._ || '', get = function (k) { var m = new RegExp('^\\s*' + k + ':\\s*(\\S+)', 'm').exec(t); return m ? m[1] : null; };
    var level = num(get('level')), health = num(get('health')), status = num(get('status')), temp = num(get('temperature')), volt = num(get('voltage'));
    var cycles = num((s.CYCLE || '').trim()), full = num((s.FULL || '').trim()), design = num((s.DESIGN || '').trim()), cap = /Capacity:\s*([\d.]+)/.exec(s.CAP || '');
    var pct = full && design ? Math.round(full / design * 100) : null, lines = [], advice = [], v = 'ok';
    var HEALTH = { 1: 'अज्ञात', 2: 'ठीक', 3: 'ज़्यादा गरम', 4: 'ख़राब (dead)', 5: 'ज़्यादा वोल्टेज', 6: 'गड़बड़', 7: 'ठंडी' }, STATUS = { 2: 'चार्ज हो रही है', 3: 'डिस्चार्ज हो रही है', 4: 'चार्ज नहीं हो रही', 5: 'भरी हुई' };
    if (level != null) lines.push('अभी चार्ज: ' + level + '%' + (status && STATUS[status] ? ' · ' + STATUS[status] : ''));
    if (pct != null) lines.push('बैटरी की सेहत: ' + pct + '% (नई बैटरी के मुकाबले, फ़ोन की अपनी गिनती से)'); else lines.push('बैटरी की सेहत का प्रतिशत इस फ़ोन से पढ़ा नहीं जा सका' + (cap ? ' (कंपनी की क्षमता ' + Math.round(+cap[1]) + ' mAh)' : ''));
    if (cycles != null) lines.push('चार्ज साइकिल: ' + cycles);
    if (temp != null) lines.push('तापमान: ' + (temp / 10).toFixed(1) + '°C');
    if (volt != null) lines.push('वोल्टेज: ' + volt + ' mV');
    if (health && HEALTH[health]) lines.push('फ़ोन की रिपोर्ट: बैटरी ' + HEALTH[health]);
    if (health && [3, 4, 5, 6].indexOf(health) !== -1) { v = 'bad'; advice.push('फ़ोन ख़ुद बैटरी में गड़बड़ बता रहा है। बैटरी जाँच कर बदलवाइए, ऐसे फ़ोन को रात भर चार्ज पर न छोड़ें।'); }
    if (pct != null && pct < 70) { v = 'bad'; advice.push('बैटरी काफ़ी घिस चुकी है (' + pct + '%)। बैटरी बदलना ही असली इलाज है।'); }
    else if (pct != null && pct < 80) { if (v === 'ok') v = 'warn'; advice.push('बैटरी कुछ घिस चुकी है (' + pct + '%)। बैकअप कम चले तो बैटरी बदलवाने का सोचिए।'); }
    if (temp != null && temp >= 450) { v = 'bad'; advice.push('बैटरी बहुत गरम है। भारी ऐप या चार्जिंग के समय उपयोग से बचें।'); }
    else if (temp != null && temp >= 400 && v === 'ok') { v = 'warn'; advice.push('बैटरी थोड़ी गरम है। चार्ज करते समय कवर हटाइए।'); }
    if (cycles != null && cycles > 800 && v === 'ok') { v = 'warn'; advice.push('चार्ज साइकिल बहुत हो चुके हैं (' + cycles + ')।'); }
    var head = pct != null ? 'बैटरी सेहत ' + pct + '%' : 'बैटरी जाँची';
    return res(v, head, lines, advice, { pct: pct, cycles: cycles, level: level, temp: temp != null ? temp / 10 : null, designMah: cap ? Math.round(+cap[1]) : null });
  }

  function batteryApps(out) {
    var s = sections(out), uidMap = {}, tot = null;
    String(s.PKGS || '').split('\n').forEach(function (l) { var m = /^package:(\S+)\s+uid:(\d+)/.exec(l.trim()); if (m) uidMap[m[2]] = m[1]; });
    var cap = /Computed drain:\s*([\d.]+)/.exec(s._ || ''); tot = cap ? +cap[1] : null;
    var rows = []; String(s._ || '').split('\n').forEach(function (l) { var m = /Uid\s+(\S+):\s+([\d.]+)/.exec(l); if (!m) return; var uid = m[1], mah = +m[2], app = null;
      var u = /^u(\d+)a(\d+)$/.exec(uid); if (u) app = uidMap[String(10000 + +u[2])]; else if (/^\d+$/.test(uid)) app = uidMap[uid] || (uid === '1000' ? 'Android सिस्टम' : 'uid ' + uid);
      rows.push({ pkg: app || ('uid ' + uid), mah: mah }); });
    rows.sort(function (a, b) { return b.mah - a.mah; }); var top = rows.slice(0, 6), lines = [], advice = [], v = 'ok';
    top.forEach(function (r) { var p = tot ? Math.round(r.mah / tot * 100) : null; lines.push(r.pkg + ': ' + Math.round(r.mah) + ' mAh' + (p != null ? ' (' + p + '%)' : '') + (JUNK_USER.test(r.pkg) ? '  ⚠ नकली क्लीनर/बूस्टर जैसा' : '')); });
    top.forEach(function (r) { var p = tot ? r.mah / tot : 0; if (JUNK_USER.test(r.pkg)) { v = 'bad'; advice.push(r.pkg + ' बैटरी खाता है और आम तौर पर फ़ायदे की जगह नुकसान करता है। हटाइए।'); } else if (p >= 0.15 && !/^Android/.test(r.pkg) && r.pkg.indexOf('uid') !== 0 && r.pkg !== 'com.android.systemui') { if (v === 'ok') v = 'warn'; advice.push(r.pkg + ' अकेला ' + Math.round(p * 100) + '% बैटरी खा रहा है। इसे बैकग्राउंड में रोकिए या ज़रूरत न हो तो हटाइए।'); } });
    if (!rows.length) return res('info', 'बैटरी-खपत की सूची नहीं मिली', ['इस फ़ोन से ऐप-वार बैटरी की गिनती नहीं मिली (नया रीस्टार्ट हुआ हो सकता है)।'], [], { rows: [] });
    return res(v, 'सबसे ज़्यादा बैटरी: ' + top[0].pkg, lines, advice, { rows: top });
  }

  function ram(out) {
    var s = sections(out), t = s._ || '', K = function (re) { var m = re.exec(t); return m ? num(m[1]) : null; };
    var total = K(/Total RAM:\s*([\d,]+)K/), free = K(/Free RAM:\s*([\d,]+)K/), used = K(/Used RAM:\s*([\d,]+)K/);
    if (!total) return res('info', 'RAM की जानकारी नहीं मिली', [], [], {});
    var pct = Math.round(free / total * 100), lines = ['कुल RAM: ' + gb(total), 'खाली RAM: ' + gb(free) + ' (' + pct + '%)', used ? 'इस्तेमाल में: ' + gb(used) : ''].filter(Boolean), advice = [], v = 'ok';
    var procs = []; String(s.PSS || '').split('\n').forEach(function (l) { var m = /^\s*([\d,]+)K:\s+(\S+)/.exec(l); if (m) procs.push({ kb: num(m[1]), name: m[2] }); });
    procs.slice(0, 4).forEach(function (p) { lines.push('  ' + p.name + ': ' + Math.round(p.kb / KB) + ' MB'); });
    if (pct < 10) { v = 'bad'; advice.push('RAM लगभग भरी है, इसी से फ़ोन हैंग होता है। भारी और फ़ालतू ऐप हटाइए या बंद कीजिए।'); }
    else if (pct < 20) { v = 'warn'; advice.push('RAM कम बची है। बैकग्राउंड में चलने वाले ऐप घटाइए।'); }
    if (total < 3.2 * KB * KB && v === 'ok') { v = 'warn'; advice.push('फ़ोन में RAM कम है (' + gb(total) + '), भारी ऐप चलाने पर लैग रहेगा।'); }
    procs.forEach(function (p) { if (JUNK_USER.test(p.name)) advice.push(p.name + ' RAM घेर रहा है और नकली क्लीनर जैसा है, हटाइए।'); });
    return res(v, 'खाली RAM ' + pct + '%', lines, advice, { pct: pct, totalKb: total, procs: procs.slice(0, 6) });
  }

  function storage(out) {
    var s = sections(out), m = /^\S+\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)%\s+(\S+)/m.exec((s._ || '').split('\n').slice(1).join('\n'));
    if (!m) return res('info', 'स्टोरेज की जानकारी नहीं मिली', [], [], {});
    var size = +m[1], used = +m[2], avail = +m[3], pct = +m[4], v = 'ok', advice = [];
    var lines = ['कुल: ' + gb(size), 'भरा: ' + pct + '% (' + gb(used) + ')', 'खाली: ' + gb(avail)];
    if (pct >= 95 || avail < 3 * KB * KB) { v = 'bad'; advice.push('स्टोरेज लगभग पूरा भरा है। इसी से फ़ोन धीमा, कैमरा बंद और अपडेट फ़ेल होते हैं। फ़ोटो-वीडियो का बैकअप लेकर फ़ाइलें हटाइए।'); }
    else if (pct >= 85) { v = 'warn'; advice.push('स्टोरेज भरने वाला है (' + pct + '%)। जल्द सफ़ाई कीजिए।'); }
    return res(v, 'स्टोरेज ' + pct + '% भरा', lines, advice, { pct: pct, availKb: avail });
  }

  function cpu(out) {
    var load = /Load:\s*([\d.]+)\s*\/\s*([\d.]+)\s*\/\s*([\d.]+)/.exec(out), rows = [];
    String(out).split('\n').forEach(function (l) { var m = /^\s*([\d.]+)%\s+(\d+)\/([^:]+):\s*([\d.]+)%\s+user\s+\+\s+([\d.]+)%\s+kernel/.exec(l); if (m && m[3] !== 'TOTAL') rows.push({ pct: +m[1], name: m[3] }); });
    if (!rows.length) return res('info', 'CPU की जानकारी नहीं मिली', [], [], {});
    rows.sort(function (a, b) { return b.pct - a.pct; }); var lines = [], advice = [], v = 'ok';
    if (load) lines.push('औसत भार (1/5/15 मिनट): ' + load[1] + ' / ' + load[2] + ' / ' + load[3]);
    rows.slice(0, 5).forEach(function (r) { lines.push(r.name + ': ' + r.pct + '% CPU' + (JUNK_USER.test(r.name) ? '  ⚠ नकली क्लीनर जैसा' : '')); });
    var top = rows[0]; if (top.pct >= 40 && !/system_server|surfaceflinger/.test(top.name)) { v = 'bad'; advice.push(top.name + ' अकेला ' + top.pct + '% CPU खा रहा है, इसी से फ़ोन गरम और धीमा है। इसे रोकिए, अपडेट कीजिए या हटाइए।'); }
    else if (top.pct >= 20 && !/system_server|surfaceflinger/.test(top.name)) { v = 'warn'; advice.push(top.name + ' ' + top.pct + '% CPU ले रहा है।'); }
    rows.forEach(function (r) { if (JUNK_USER.test(r.name)) { v = 'bad'; advice.push(r.name + ' चुपचाप CPU चला रहा है। हटाइए।'); } });
    return res(v, 'सबसे भारी: ' + top.name + ' (' + top.pct + '%)', lines, advice, { rows: rows.slice(0, 6) });
  }

  function heat(out) {
    var s = sections(out), t = s._ || '', cur = t.indexOf('Current temperatures from HAL') !== -1 ? t.slice(t.indexOf('Current temperatures from HAL')) : t, TYPE = { 0: 'CPU', 1: 'GPU', 2: 'बैटरी', 3: 'बाहरी सतह' }, found = [], re = /Temperature\{mValue=([\d.-]+), mType=(\d+), mName=([^,]+), mStatus=(\d+)\}/g, m;
    while ((m = re.exec(cur))) found.push({ val: +m[1], type: +m[2], name: m[3] });
    var st = /Thermal Status:\s*(\d)/.exec(t), status = st ? +st[1] : null, STAT = ['सामान्य', 'हल्की गरमी', 'मध्यम गरमी', 'ज़्यादा गरमी', 'गंभीर गरमी', 'ख़तरनाक गरमी', 'शटडाउन का ख़तरा'];
    var bt = /temperature:\s*(\d+)/.exec(s.BATT || ''), lines = [], advice = [], v = 'ok', skin = null;
    found.forEach(function (f) { if (TYPE[f.type]) lines.push(TYPE[f.type] + ' (' + f.name + '): ' + f.val.toFixed(1) + '°C'); if (f.type === 3) skin = f.val; });
    if (status != null) lines.unshift('फ़ोन की गरमी की स्थिति: ' + STAT[status]);
    if (!found.length && bt) lines.push('बैटरी का तापमान: ' + (+bt[1] / 10).toFixed(1) + '°C');
    if (!found.length && !bt && status == null) return res('info', 'तापमान की जानकारी नहीं मिली', [], [], {});
    if ((status != null && status >= 3) || (skin != null && skin >= 48)) { v = 'bad'; advice.push('फ़ोन बहुत गरम है। चार्जिंग और भारी ऐप रोकिए, कवर हटाइए, छाँव में रखिए। बार-बार हो तो भीतर की जाँच करवाइए।'); }
    else if ((status != null && status >= 2) || (skin != null && skin >= 43)) { v = 'warn'; advice.push('फ़ोन गरम है। देखिए कोई ऐप बैकग्राउंड में CPU तो नहीं खा रहा (CPU जाँच चलाइए)।'); }
    return res(v, status != null ? 'गरमी: ' + STAT[status] : 'तापमान जाँचा', lines, advice, { status: status, skin: skin });
  }

  function apps(out) {
    var rows = []; String(out).split('\n').forEach(function (l) { var m = /^package:(\S+)\s+installer=(\S+)/.exec(l.trim()); if (m) rows.push({ pkg: m[1], inst: m[2] }); });
    var STORE = /^(com\.android\.vending|com\.sec\.android\.app\.samsungapps|com\.xiaomi\.mipicks|com\.heytap\.market|com\.oppo\.market|com\.vivo\.appstore|com\.amazon\.venezia)$/;
    var side = rows.filter(function (r) { return !STORE.test(r.inst); }), junk = rows.filter(function (r) { return JUNK_USER.test(r.pkg); });
    var lines = [rows.length + ' ऐप खुद इंस्टॉल किए हुए हैं', side.length + ' ऐप Play Store के बाहर से (APK) आए'], advice = [], v = 'ok';
    side.slice(0, 8).forEach(function (r) { lines.push('  बाहर से: ' + r.pkg); }); junk.forEach(function (r) { lines.push('  ⚠ क्लीनर/बूस्टर जैसा: ' + r.pkg); });
    if (junk.length) { v = 'bad'; advice.push('नकली क्लीनर/बूस्टर ऐप हटाइए, ये फ़ोन को धीमा करते और विज्ञापन दिखाते हैं।'); }
    if (side.length >= 3 && v === 'ok') { v = 'warn'; advice.push('कई ऐप Play Store के बाहर से आए हैं। जिन्हें ग्राहक पहचानता नहीं, उन्हें हटाइए।'); }
    return res(v, rows.length + ' ऐप, ' + side.length + ' बाहर से', lines, advice, { rows: rows, side: side, junk: junk });
  }

  function bloat(out) {
    var s = sections(out), sys = pkgs(s._ || ''), user = pkgs(s.USER || ''), dis = pkgs(s.DISABLED || '');
    var cands = SAFE_DISABLE.filter(function (c) { return sys.indexOf(c[0]) !== -1 && dis.indexOf(c[0]) === -1; }).map(function (c) { return { pkg: c[0], why: c[1], kind: 'disable' }; });
    var junk = user.filter(function (p) { return JUNK_USER.test(p); }).map(function (p) { return { pkg: p, why: 'नकली क्लीनर/बूस्टर जैसा ऐप', kind: 'uninstall' }; });
    var lines = [cands.length + ' पहले से डले फ़ालतू ऐप बंद किए जा सकते हैं', junk.length + ' नकली क्लीनर/बूस्टर जैसे ऐप मिले'], advice = [];
    cands.concat(junk).forEach(function (c) { lines.push('  ' + c.pkg + ' — ' + c.why); });
    if (cands.length || junk.length) advice.push('नीचे से चुनकर बंद या हटाएँ। बंद किया ऐप बाद में वापस चालू हो सकता है।');
    return res(junk.length ? 'bad' : cands.length ? 'warn' : 'ok', cands.length + junk.length ? (cands.length + junk.length) + ' फ़ालतू ऐप मिले' : 'कोई जाना-पहचाना फ़ालतू ऐप नहीं', lines, advice, { actions: cands.concat(junk) });
  }

  function audit(out) {
    var s = sections(out), acc = String(s.ACCESS || '').trim(), accPk = acc && acc !== 'null' ? acc.split(':').map(function (c) { return c.split('/')[0]; }).filter(Boolean) : [];
    var admins = []; String(s.ADMINS || '').split('\n').forEach(function (l) { var m = /ComponentInfo\{([^/}]+)\//.exec(l); if (m && admins.indexOf(m[1]) === -1) admins.push(m[1]); });
    var overlay = pkgs(String(s.OVERLAY || '').split('\n').map(function (l) { return 'package:' + l.trim(); }).join('\n')), lst = String(s.LISTENERS || '').trim(), lstPk = lst && lst !== 'null' ? lst.split(':').map(function (c) { return c.split('/')[0]; }) : [];
    var side = []; String(s.INSTALLERS || '').split('\n').forEach(function (l) { var m = /^package:(\S+)\s+installer=(\S+)/.exec(l.trim()); if (m && !/^(com\.android\.vending|com\.sec\.android\.app\.samsungapps|com\.xiaomi\.mipicks|com\.heytap\.market|com\.vivo\.appstore)$/.test(m[2])) side.push(m[1]); });
    var sus = accPk.filter(function (p) { return !TRUSTED_ACCESS.test(p); }), susAdm = admins.filter(function (p) { return !/^(com\.android\.|com\.google\.|android)/.test(p); }), lines = [], advice = [], v = 'ok';
    lines.push('एक्सेसिबिलिटी सेवाएँ चालू: ' + (accPk.length ? accPk.join(', ') : 'कोई नहीं')); lines.push('डिवाइस-एडमिन ऐप: ' + (admins.length ? admins.join(', ') : 'कोई नहीं')); lines.push('दूसरे ऐप के ऊपर दिखने की अनुमति वाले: ' + (overlay.length ? overlay.join(', ') : 'कोई नहीं'));
    lines.push('नोटिफ़िकेशन पढ़ने वाले: ' + (lstPk.length ? lstPk.join(', ') : 'कोई नहीं')); lines.push('Play Store के बाहर से आए: ' + (side.length ? side.join(', ') : 'कोई नहीं'));
    if (sus.length) { v = 'bad'; advice.push('इन ऐप को एक्सेसिबिलिटी की ताक़त मिली है: ' + sus.join(', ') + '। ये स्क्रीन पढ़ और बटन दबा सकते हैं, ठगी वाले ऐप अक्सर यही माँगते हैं। ग्राहक से पूछकर हटाइए।'); }
    if (susAdm.length) { v = 'bad'; advice.push('अनजान डिवाइस-एडमिन ऐप: ' + susAdm.join(', ') + '। ये ख़ुद हटने नहीं देते और फ़ोन लॉक कर सकते हैं।'); }
    if (v === 'ok' && (side.length || overlay.some(function (p) { return !/^(com\.android\.|com\.google\.|com\.facebook\.orca|com\.whatsapp)/.test(p); }))) { v = 'warn'; advice.push('कुछ ऐप Play Store के बाहर से हैं या दूसरे ऐप के ऊपर दिखते हैं। ग्राहक से पूछिए कि पहचानता है या नहीं।'); }
    return res(v, v === 'ok' ? 'कोई ख़तरे वाली चीज़ नहीं दिखी' : 'शक वाली चीज़ें मिलीं', lines, advice, { sus: sus, admins: admins, side: side });
  }

  function perms(out) {
    var list = []; String(out).split('\n').forEach(function (l) { var m = /(android\.permission\.[A-Z0-9_]+|com\.android\.[A-Za-z0-9_.]+):\s*granted=true/.exec(l); if (m) list.push(m[1]); });
    var RISKY = { 'android.permission.READ_SMS': 'SMS पढ़ सकता है', 'android.permission.RECEIVE_SMS': 'SMS पा सकता है', 'android.permission.SEND_SMS': 'SMS भेज सकता है', 'android.permission.READ_CONTACTS': 'संपर्क पढ़ सकता है', 'android.permission.RECORD_AUDIO': 'माइक चला सकता है', 'android.permission.CAMERA': 'कैमरा चला सकता है', 'android.permission.ACCESS_FINE_LOCATION': 'सटीक लोकेशन जानता है', 'android.permission.READ_CALL_LOG': 'कॉल-लॉग पढ़ सकता है' };
    return res(list.some(function (p) { return /SMS|CALL_LOG/.test(p); }) ? 'warn' : 'info', list.length + ' अनुमतियाँ मिली हैं', list.map(function (p) { return p.replace('android.permission.', '') + (RISKY[p] ? ' — ' + RISKY[p] : ''); }), [], { list: list, risky: list.filter(function (p) { return RISKY[p]; }) });
  }

  function sensors(out) {
    var types = {}; String(out).split('\n').forEach(function (l) { var m = /type:\s*android\.sensor\.([a-z_]+)/.exec(l); if (m) types[m[1]] = 1; });
    var need = [['accelerometer', 'एक्सेलेरोमीटर (ऑटो-रोटेट)'], ['gyroscope', 'जायरोस्कोप (गेम, कैमरा स्थिरता)'], ['magnetic_field', 'कंपास (मैप की दिशा)'], ['light', 'लाइट सेंसर (ऑटो-ब्राइटनेस)'], ['proximity', 'प्रॉक्सिमिटी (कॉल में स्क्रीन बंद होना)']], lines = [], advice = [], v = 'ok', missing = [];
    if (!Object.keys(types).length) return res('info', 'सेंसर की सूची नहीं मिली', [], [], {});
    need.forEach(function (n) { var has = !!types[n[0]]; lines.push((has ? '✓ ' : '✗ ') + n[1]); if (!has) missing.push(n[0]); });
    if (missing.length) { v = missing.indexOf('accelerometer') !== -1 || missing.indexOf('proximity') !== -1 ? 'bad' : 'warn'; advice.push('फ़ोन में ये सेंसर दिख नहीं रहे: ' + missing.join(', ') + '। सेंसर या बोर्ड की जाँच चाहिए (कुछ सस्ते फ़ोन में ये होते ही नहीं)।'); }
    return res(v, missing.length ? missing.length + ' सेंसर नहीं मिले' : 'सारे ज़रूरी सेंसर मौजूद', lines, advice, { missing: missing });
  }

  function display(out) {
    var size = /Physical size:\s*(\S+)/.exec(out), dens = /Physical density:\s*(\d+)/.exec(out), fps = /([\d.]+)\s*fps/.exec(out), lines = [];
    if (size) lines.push('रेज़ोल्यूशन: ' + size[1]); if (dens) lines.push('घनत्व: ' + dens[1] + ' dpi'); if (fps) lines.push('रिफ्रेश रेट: ' + Math.round(+fps[1]) + ' Hz');
    return res('info', size ? 'स्क्रीन ' + size[1] + (fps ? ' · ' + Math.round(+fps[1]) + ' Hz' : '') : 'स्क्रीन की जानकारी नहीं मिली', lines, ['डेड पिक्सल, टच और रंग की जाँच के लिए ग्राहक के फ़ोन पर "फ़ोन चेक" पेज खोलिए।'], {});
  }

  function network(out) {
    var s = sections(out), t = s._ || '', rssi = /RSSI:\s*(-?\d+)/i.exec(t), link = /Link speed:\s*(\d+)/i.exec(t) || /linkSpeed=(\d+)/.exec(t), freq = /Frequency:\s*(\d+)/i.exec(t) || /frequency=(\d+)/.exec(t);
    var loss = /(\d+)% packet loss/.exec(s.PING || ''), rtt = /=\s*[\d.]+\/([\d.]+)\//.exec(s.PING || ''), lines = [], advice = [], v = 'ok';
    if (rssi) lines.push('वाई-फ़ाई सिग्नल: ' + rssi[1] + ' dBm'); if (link) lines.push('लिंक स्पीड: ' + link[1] + ' Mbps'); if (freq) lines.push('बैंड: ' + (+freq[1] > 4000 ? '5 GHz' : '2.4 GHz')); if (rtt) lines.push('इंटरनेट की देरी: ' + Math.round(+rtt[1]) + ' ms'); if (loss) lines.push('पैकेट खोना: ' + loss[1] + '%');
    if (!lines.length) return res('info', 'नेटवर्क की जानकारी नहीं मिली', [], [], {});
    if (rssi && +rssi[1] <= -80) { v = 'bad'; advice.push('वाई-फ़ाई सिग्नल बहुत कमज़ोर है। राउटर के पास जाकर जाँचिए।'); } else if (rssi && +rssi[1] <= -70) { v = 'warn'; advice.push('सिग्नल कमज़ोर है।'); }
    if (loss && +loss[1] > 0) { if (v === 'ok') v = 'warn'; advice.push('कुछ पैकेट खो रहे हैं, कनेक्शन ख़राब है।'); }
    if (rtt && +rtt[1] > 150) { if (v === 'ok') v = 'warn'; advice.push('इंटरनेट धीमा जवाब दे रहा है (' + Math.round(+rtt[1]) + ' ms)।'); }
    if (link && +link[1] < 100 && v === 'ok') { v = 'warn'; advice.push('वाई-फ़ाई की लिंक स्पीड कम है, 5 GHz बैंड आज़माइए।'); }
    return res(v, rssi ? 'वाई-फ़ाई ' + rssi[1] + ' dBm' : 'नेटवर्क जाँचा', lines, advice, { rssi: rssi ? +rssi[1] : null });
  }

  function crashes(out) {
    var s = sections(out), c = {}, anr = {}; String(s._ || '').split('\n').forEach(function (l) { var m = /Process:\s*([A-Za-z0-9_.:]+),\s*PID/.exec(l); if (m) c[m[1]] = (c[m[1]] || 0) + 1; });
    String(s.ANR || '').split('\n').forEach(function (l) { var m = /ANR in ([A-Za-z0-9_.:]+)/.exec(l); if (m) anr[m[1]] = (anr[m[1]] || 0) + 1; });
    var all = {}; Object.keys(c).forEach(function (k) { all[k] = (all[k] || 0) + c[k]; }); Object.keys(anr).forEach(function (k) { all[k] = (all[k] || 0) + anr[k]; });
    var rows = Object.keys(all).map(function (k) { return { pkg: k, n: all[k] }; }).sort(function (a, b) { return b.n - a.n; }), lines = [], advice = [], v = 'ok';
    rows.slice(0, 6).forEach(function (r) { lines.push(r.pkg + ': ' + r.n + ' बार अटका/बंद हुआ' + (anr[r.pkg] ? ' (हैंग ' + anr[r.pkg] + ')' : '')); });
    if (rows.length) { var top = rows[0]; v = top.n >= 3 ? 'bad' : 'warn'; advice.push(top.pkg + ' बार-बार क्रैश/हैंग हो रहा है। उसे अपडेट कीजिए, कैश साफ़ कीजिए या हटाकर दोबारा डालिए।'); }
    return res(rows.length ? v : 'ok', rows.length ? 'सबसे ज़्यादा क्रैश: ' + rows[0].pkg : 'हाल में कोई क्रैश नहीं', lines.length ? lines : ['पिछले लॉग में कोई ऐप क्रैश या हैंग नहीं दिखा।'], advice, { rows: rows });
  }

  function anim(out) {
    var v = String(out).trim().split('\n').map(function (x) { return x.trim(); }), cur = v[0] || 'null';
    return res('info', 'एनिमेशन की गति: ' + (cur === 'null' ? '1.0 (सामान्य)' : cur), ['window: ' + v[0], 'transition: ' + v[1], 'animator: ' + v[2]], ['एनिमेशन 0.5 करने से फ़ोन तुरंत तेज़ महसूस होता है, बिना कुछ हटाए।'], { cur: cur });
  }

  var PARSE = { info: info, battery: battery, battery_apps: batteryApps, ram: ram, storage: storage, cpu: cpu, heat: heat, apps: apps, bloat: bloat, audit: audit, perms: perms, sensors: sensors, display: display, network: network, crashes: crashes, anim_get: anim };
  var api = { parse: PARSE, sections: sections, JUNK_USER: JUNK_USER, SAFE_DISABLE: SAFE_DISABLE };
  if (typeof module !== 'undefined' && module.exports) module.exports = api; else root.DoctorParse = api;
})(typeof window !== 'undefined' ? window : this);
