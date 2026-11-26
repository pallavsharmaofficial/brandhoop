/* Brandhoop Phone Care: a free page for customers. Everything runs on the customer's own phone; nothing is uploaded.
   It measures what a browser can really measure, walks through hardware tests, and guides the manual clean-up that actually speeds a phone up. */
(function () {
  'use strict';
  var $ = function (id) { return document.getElementById(id); };
  function h(tag, props) { var e = document.createElement(tag); props = props || {}; Object.keys(props).forEach(function (k) { if (k === 'class') e.className = props[k]; else if (k.slice(0, 2) === 'on') e[k] = props[k]; else e.setAttribute(k, props[k]); }); (function add(list) { for (var i = 0; i < list.length; i++) { var c = list[i]; if (c == null) continue; if (Array.isArray(c)) add(c); else e.append(c.nodeType ? c : document.createTextNode(String(c))); } })(Array.prototype.slice.call(arguments, 2)); return e; }
  var LS = { get: function (k, d) { try { var v = localStorage.getItem(k); return v == null ? d : v; } catch (e) { return d; } }, set: function (k, v) { try { localStorage.setItem(k, v); } catch (e) { } } };
  var SHOP_WA = '918619767291';
  var R = { quick: null, hw: {} };       // results: quick = { score, verdict, ... }, hw[id] = 'ok' | 'bad'
  var ICON = { ok: '🟢', warn: '🟡', bad: '🔴', info: 'ℹ️' };
  var ua = navigator.userAgent, android = (/Android\s([\d.]+)/.exec(ua) || [])[1], vendor = /SM-|Samsung/i.test(ua) ? 'samsung' : /Xiaomi|Redmi|POCO|MI\s/i.test(ua) ? 'xiaomi' : /OPPO|CPH/i.test(ua) ? 'oppo' : /vivo|V\d{4}/i.test(ua) ? 'vivo' : /realme|RMX/i.test(ua) ? 'realme' : /moto/i.test(ua) ? 'moto' : /Pixel/i.test(ua) ? 'pixel' : 'other';

  /* ---------- 1. the quick check ---------- */
  function cpuMs() { var t = performance.now(), s = 0; for (var i = 1; i < 3500000; i++) { s += Math.sqrt(i) * Math.sin(i); } if (s === 12345.678) console.log(s); return performance.now() - t; }
  function frames() {
    return new Promise(function (ok) {
      var c = h('canvas', { width: 300, height: 300, style: 'position:fixed;left:-9999px' }); document.body.append(c); var g = c.getContext('2d'), last = performance.now(), n = 0, long = 0, sum = 0;
      (function tick(now) {
        var d = now - last; last = now; if (n > 0) { sum += d; if (d > 40) long++; } n++;
        for (var i = 0; i < 400; i++) { g.fillStyle = 'hsl(' + ((i * 7 + n * 5) % 360) + ',70%,50%)'; g.fillRect((i * 13 + n) % 300, (i * 29) % 300, 40, 40); }
        if (n < 70) requestAnimationFrame(tick); else { c.remove(); ok({ avg: sum / (n - 1), long: long }); }
      })(performance.now());
    });
  }
  function net() {
    var t0 = performance.now();
    return fetch('speedtest.bin?x=' + Date.now(), { cache: 'no-store' }).then(function (r) { return r.arrayBuffer(); }).then(function (b) { var s = (performance.now() - t0) / 1000; return { mbps: b.byteLength * 8 / s / 1e6, ok: true }; }).catch(function () { return { ok: false }; });
  }
  function batt() {
    if (!navigator.getBattery) return Promise.resolve(null);
    return navigator.getBattery().then(function (b) { return { level: Math.round(b.level * 100), charging: b.charging }; }).catch(function () { return null; });
  }
  function card(v, head, text) { return h('div', { class: 'res' }, h('div', {}, ICON[v]), h('div', {}, h('b', {}, head), text)); }
  function runQuick() {
    var out = $('quickOut'), btn = $('runQuick'); btn.disabled = true; btn.textContent = 'जाँच चल रही है… फ़ोन को छुइए मत'; out.textContent = '';
    var cpu = cpuMs(); // first, with the page idle
    frames().then(function (f) { return Promise.all([net(), batt()]).then(function (x) { return { f: f, n: x[0], b: x[1] }; }); }).then(function (x) {
      var f = x.f, n = x.n, b = x.b, mem = navigator.deviceMemory, cores = navigator.hardwareConcurrency;
      var cv = cpu <= 150 ? 'ok' : cpu <= 350 ? 'warn' : 'bad', fv = f.long <= 3 ? 'ok' : f.long <= 12 ? 'warn' : 'bad', rank = { ok: 0, warn: 1, bad: 2 }, worst = rank[cv] >= rank[fv] ? cv : fv;
      var score = Math.max(5, Math.min(99, Math.round(100 - cpu / 9 - f.long * 1.5)));
      R.quick = { score: score, verdict: worst, cpu: Math.round(cpu), jank: f.long, mbps: n.ok ? +n.mbps.toFixed(1) : null, battery: b, mem: mem || null, cores: cores || null };
      out.append(h('div', { style: 'margin-top:10px' }, h('div', { class: 'score' }, score + ' / 100'), h('div', { class: 'bar2' }, h('i', { style: 'width:' + score + '%' })), h('div', { class: 'muted' }, 'रफ़्तार का अंदाज़ा (ब्राउज़र में जाँचकर, मोटा नतीजा)')));
      out.append(card(cv, 'प्रोसेसर की गति: ' + Math.round(cpu) + ' ms', cv === 'ok' ? 'तेज़ है।' : cv === 'warn' ? 'ठीक-ठाक, भारी काम में धीमा पड़ सकता है।' : 'धीमा है। फ़ोन पर बोझ ज़्यादा है या फ़ोन पुराना है।'));
      out.append(card(fv, 'स्क्रीन की स्मूथनेस: ' + f.long + ' अटकाव', fv === 'ok' ? 'स्क्रीन आराम से चल रही है।' : 'स्क्रीन अटक-अटक कर चलती है (लैग)। नीचे की सफ़ाई वाले चरण करके देखिए।'));
      if (b) out.append(card(b.level < 20 && !b.charging ? 'warn' : 'info', 'बैटरी: ' + b.level + '%' + (b.charging ? ' (चार्ज हो रही है)' : ''), 'पिछली जाँच से तुलना नीचे दिखेगी।'));
      if (mem) out.append(card(mem <= 2 ? 'warn' : 'info', 'RAM (लगभग): ' + (mem >= 8 ? '8 GB या ज़्यादा' : mem + ' GB'), mem <= 2 ? 'कम RAM है, भारी ऐप और गेम लैग करेंगे।' : 'ठीक है।'));
      if (n.ok) out.append(card(n.mbps < 3 ? 'bad' : n.mbps < 10 ? 'warn' : 'ok', 'इंटरनेट की स्पीड: ' + n.mbps.toFixed(1) + ' Mbps', n.mbps < 3 ? 'बहुत धीमा, सिग्नल या प्लान देखिए।' : n.mbps < 10 ? 'चलने लायक है।' : 'अच्छी है।')); else out.append(card('info', 'इंटरनेट की स्पीड', 'अभी नापी नहीं जा सकी (नेट बंद है?)।'));
      out.append(card('info', 'फ़ोन', 'Android ' + (android || '?') + ' · ' + (cores ? cores + ' कोर' : '') + ' · स्क्रीन ' + screen.width + '×' + screen.height));
      // battery drain since the last visit
      if (b) { var last = null; try { last = JSON.parse(LS.get('bhCareBatt', 'null')); } catch (e) { } if (last && !last.charging && !b.charging && b.level < last.level) { var hrs = (Date.now() - last.t) / 36e5; if (hrs >= 0.5 && hrs < 72) out.append(card(b.level - last.level < -8 * hrs ? 'warn' : 'info', 'बैटरी की खपत पिछली जाँच से: ' + ((last.level - b.level) / hrs).toFixed(1) + '% प्रति घंटा', '(' + hrs.toFixed(1) + ' घंटे में ' + last.level + '% से ' + b.level + '%)। 8% प्रति घंटे से ऊपर हो तो ज़्यादा है।')); } LS.set('bhCareBatt', JSON.stringify({ level: b.level, charging: b.charging, t: Date.now() })); }
      btn.disabled = false; btn.textContent = '▶ दोबारा जाँचें'; tips(); report();
    });
  }

  /* ---------- 2. hardware tests ---------- */
  var TESTS = [
    ['screen', '🖥️ स्क्रीन के रंग', screenTest], ['touch', '👆 टच', touchTest], ['ghost', '👻 अपने-आप टच', ghostTest], ['speaker', '🔊 स्पीकर', speakerTest], ['mic', '🎙️ माइक', micTest],
    ['camera', '📷 कैमरा', cameraTest], ['vibrate', '📳 वाइब्रेशन', vibrateTest], ['sensor', '🧭 सेंसर', sensorTest], ['gps', '📍 GPS', gpsTest], ['lock', '🔐 स्क्रीन-लॉक/फ़िंगरप्रिंट', lockTest]
  ];
  function overlay(title, body, onClose) {
    var o = h('div', { class: 'ov' }); var done = function (v) { o.remove(); if (onClose) onClose(); if (v) { R.hw[v.id] = v.r; hwList(); tips(); report(); } };
    return { el: o, done: done, mount: function (bar) { o.append(body, h('div', { class: 'bar' }, bar)); document.body.append(o); } };
  }
  function passFail(id, o, extra) { return [h('b', { style: 'width:100%;text-align:center' }, extra || ''), h('button', { class: 'or', type: 'button', onclick: function () { o.done({ id: id, r: 'ok' }); } }, '✓ सब ठीक है'), h('button', { type: 'button', style: 'background:#C62828', onclick: function () { o.done({ id: id, r: 'bad' }); } }, '✗ गड़बड़ है'), h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { o.done(); } }, 'छोड़ें')]; }
  function screenTest() { var cols = ['#000', '#fff', '#f00', '#0f0', '#00f'], i = 0, b = h('div', { style: 'flex:1;background:#000' }); var o = overlay('', b); b.onclick = function () { i = (i + 1) % cols.length; b.style.background = cols[i]; }; o.mount(passFail('screen', o, 'स्क्रीन पर टैप करके रंग बदलिए। कोई बिंदु, लाइन, धब्बा या रंग का फ़र्क़ दिखे तो ✗')); }
  function touchTest() { var g = h('div', { class: 'grid' }), n = 60, left = new Set(), maxT = 0, info = h('b', { style: 'width:100%;text-align:center' }, 'हर खाने पर उँगली फिराइए। सारे हरे होने चाहिए।'); for (var i = 0; i < n; i++) { g.append(h('div', { 'data-i': i })); left.add(i); }
    var o = overlay('', g); function hit(ev) { maxT = Math.max(maxT, (ev.touches || []).length); Array.prototype.forEach.call(ev.touches || [], function (t) { var el = document.elementFromPoint(t.clientX, t.clientY); if (el && el.dataset && el.dataset.i != null) { el.classList.add('on'); left.delete(+el.dataset.i); } }); info.textContent = 'बचे खाने: ' + left.size + ' · एक साथ उँगलियाँ: ' + maxT; ev.preventDefault(); }
    g.addEventListener('touchstart', hit, { passive: false }); g.addEventListener('touchmove', hit, { passive: false });
    o.mount([info, h('button', { class: 'or', type: 'button', onclick: function () { o.done({ id: 'touch', r: left.size === 0 ? 'ok' : 'bad' }); } }, left.size === 0 ? '✓ पूरा' : 'खत्म करें'), h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { o.done(); } }, 'छोड़ें')]); }
  function ghostTest() { var n = 0, t = 12, lbl = h('div', { style: 'flex:1;display:flex;align-items:center;justify-content:center;font-size:22px;text-align:center;padding:20px' }), o = overlay('', lbl); lbl.textContent = 'फ़ोन को मेज़ पर रखकर हाथ हटा लीजिए। 12 सेकंड तक बिना छुए कोई टच नहीं आना चाहिए।'; document.addEventListener('touchstart', cnt, true); function cnt() { n++; }
    var iv = setInterval(function () { t--; lbl.textContent = 'हाथ हटाकर रुकिए… ' + t + ' सेकंड · आए हुए टच: ' + n; if (t <= 0) { clearInterval(iv); document.removeEventListener('touchstart', cnt, true); lbl.textContent = n === 0 ? '✓ कोई अपने-आप टच नहीं आया' : '✗ ' + n + ' बार बिना छुए टच आया'; o.mount([h('button', { class: 'or', type: 'button', onclick: function () { o.done({ id: 'ghost', r: n === 0 ? 'ok' : 'bad' }); } }, 'ठीक है')]); } }, 1000); o.mount([h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { clearInterval(iv); document.removeEventListener('touchstart', cnt, true); o.done(); } }, 'छोड़ें')]); }
  function speakerTest() { var AC = window.AudioContext || window.webkitAudioContext; if (!AC) return alert('इस ब्राउज़र में आवाज़ की जाँच नहीं चलती'); var ctx = new AC(), lbl = h('div', { style: 'flex:1;display:flex;align-items:center;justify-content:center;font-size:22px;text-align:center;padding:20px' }, 'आवाज़ बढ़ाइए और सुनिए: पहले बाईं, फिर दाईं, फिर दोनों।'), o = overlay('', lbl);
    function tone(freq, pan, at, dur) { var os = ctx.createOscillator(), g = ctx.createGain(), p = ctx.createStereoPanner ? ctx.createStereoPanner() : null; os.frequency.value = freq; g.gain.value = 0.3; os.connect(g); if (p) { p.pan.value = pan; g.connect(p); p.connect(ctx.destination); } else g.connect(ctx.destination); os.start(ctx.currentTime + at); os.stop(ctx.currentTime + at + dur); }
    tone(440, -1, 0.2, 0.8); tone(660, 1, 1.4, 0.8); tone(880, 0, 2.6, 0.8); o.mount(passFail('speaker', o, 'आवाज़ साफ़ और बिना खरखराहट आई?').concat([h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { speakerTest(); o.el.remove(); } }, '↻ फिर बजाओ')])); }
  function micTest() { if (!navigator.mediaDevices) return alert('इस ब्राउज़र में माइक की जाँच नहीं चलती'); var bar = h('div', { style: 'height:30px;background:#2E7D32;width:0%;transition:width .08s' }), lbl = h('div', { style: 'padding:20px;font-size:20px;text-align:center' }, 'कुछ बोलिए। हरी पट्टी बढ़नी चाहिए।'), box = h('div', { style: 'flex:1;display:flex;flex-direction:column;justify-content:center' }, lbl, bar), o = overlay('', box), peak = 0, stream, ctx2;
    navigator.mediaDevices.getUserMedia({ audio: true }).then(function (s) { stream = s; var AC = window.AudioContext || window.webkitAudioContext; ctx2 = new AC(); var src = ctx2.createMediaStreamSource(s), an = ctx2.createAnalyser(); an.fftSize = 512; src.connect(an); var d = new Uint8Array(an.fftSize); (function loop() { if (!o.el.isConnected) return; an.getByteTimeDomainData(d); var m = 0; for (var i = 0; i < d.length; i++) m = Math.max(m, Math.abs(d[i] - 128)); peak = Math.max(peak, m); bar.style.width = Math.min(100, m * 2.2) + '%'; requestAnimationFrame(loop); })(); }).catch(function () { lbl.textContent = 'माइक की अनुमति नहीं मिली या माइक नहीं चला।'; });
    var close = function () { if (stream) stream.getTracks().forEach(function (t) { t.stop(); }); if (ctx2) ctx2.close(); };
    o.mount(passFail('mic', { done: function (v) { close(); o.done(v); } }, 'पट्टी हिली?')); }
  function cameraTest() { if (!navigator.mediaDevices) return alert('इस ब्राउज़र में कैमरा जाँच नहीं चलती'); var v = h('video', { autoplay: '', playsinline: '', muted: '' }), face = 'user', stream, o = overlay('', v); function start() { if (stream) stream.getTracks().forEach(function (t) { t.stop(); }); navigator.mediaDevices.getUserMedia({ video: { facingMode: face } }).then(function (s) { stream = s; v.srcObject = s; v.play(); }).catch(function () { }); } start();
    var fin = function (r) { if (stream) stream.getTracks().forEach(function (t) { t.stop(); }); o.done(r); };
    o.mount([h('b', { style: 'width:100%;text-align:center' }, 'आगे और पीछे दोनों कैमरे देखिए: साफ़, बिना धब्बे?'), h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { face = face === 'user' ? 'environment' : 'user'; start(); } }, '🔄 कैमरा बदलो'), h('button', { class: 'or', type: 'button', onclick: function () { fin({ id: 'camera', r: 'ok' }); } }, '✓ ठीक'), h('button', { type: 'button', style: 'background:#C62828', onclick: function () { fin({ id: 'camera', r: 'bad' }); } }, '✗ गड़बड़'), h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { fin(); } }, 'छोड़ें')]); }
  function vibrateTest() { if (!navigator.vibrate) return alert('इस ब्राउज़र में वाइब्रेशन की जाँच नहीं चलती'); var lbl = h('div', { style: 'flex:1;display:flex;align-items:center;justify-content:center;font-size:22px;text-align:center;padding:20px' }, 'फ़ोन तीन बार काँपेगा। साइलेंट/वाइब्रेशन चालू रखिए।'), o = overlay('', lbl); navigator.vibrate([300, 150, 300, 150, 300]); o.mount(passFail('vibrate', o, 'काँपा?').concat([h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { navigator.vibrate([300, 150, 300]); } }, '↻ फिर')])); }
  function sensorTest() { var lbl = h('div', { style: 'flex:1;display:flex;align-items:center;justify-content:center;font:20px monospace;text-align:center;padding:20px;white-space:pre' }, 'फ़ोन को हिलाइए और घुमाइए…'), o = overlay('', lbl), min = 99, max = -99, gy = 0, ori = 0, seen = { a: false, g: false, o: false }, a0 = null;
    function mot(e) { var a = e.accelerationIncludingGravity || {}, r = e.rotationRate || {}; if (a.x != null) { seen.a = true; var m = Math.abs(a.x) + Math.abs(a.y) + Math.abs(a.z); min = Math.min(min, m); max = Math.max(max, m); } if (r.alpha != null) { seen.g = true; gy = Math.max(gy, Math.abs(r.alpha) + Math.abs(r.beta) + Math.abs(r.gamma)); } lbl.textContent = 'एक्सेलेरोमीटर: ' + (seen.a ? (max - min > 1 ? '✓ बदल रहा है' : 'हिलाइए') : 'नहीं मिला') + '\nजायरोस्कोप: ' + (seen.g ? (gy > 20 ? '✓ बदल रहा है' : 'घुमाइए') : 'नहीं मिला') + '\nकंपास: ' + (seen.o ? (ori > 30 ? '✓ बदल रहा है' : 'घुमाइए') : 'नहीं मिला'); }
    function orient(e) { if (e.alpha != null) { seen.o = true; if (a0 == null) a0 = e.alpha; ori = Math.max(ori, Math.abs(e.alpha - a0)); } }
    window.addEventListener('devicemotion', mot); window.addEventListener('deviceorientation', orient);
    var fin = function (r) { window.removeEventListener('devicemotion', mot); window.removeEventListener('deviceorientation', orient); var ok = seen.a && max - min > 1 && seen.g && gy > 20; o.done(r ? { id: 'sensor', r: r === 'auto' ? (ok ? 'ok' : 'bad') : r } : undefined); };
    o.mount([h('b', { style: 'width:100%;text-align:center' }, 'तीनों जगह ✓ आना चाहिए (कंपास कुछ फ़ोन में नहीं होता)'), h('button', { class: 'or', type: 'button', onclick: function () { fin('auto'); } }, 'नतीजा लो'), h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { fin(); } }, 'छोड़ें')]); }
  function gpsTest() { if (!navigator.geolocation) return alert('इस ब्राउज़र में GPS जाँच नहीं चलती'); var lbl = h('div', { style: 'flex:1;display:flex;align-items:center;justify-content:center;font-size:22px;text-align:center;padding:20px' }, 'लोकेशन ढूँढ रहे हैं… खुले में जाइए, अनुमति दीजिए।'), o = overlay('', lbl), t0 = Date.now();
    navigator.geolocation.getCurrentPosition(function (p) { var acc = Math.round(p.coords.accuracy), ok = acc <= 100; lbl.textContent = (ok ? '✓ ' : '✗ ') + 'सटीकता ' + acc + ' मीटर, ' + Math.round((Date.now() - t0) / 1000) + ' सेकंड में'; o.mount([h('button', { class: 'or', type: 'button', onclick: function () { o.done({ id: 'gps', r: ok ? 'ok' : 'bad' }); } }, 'ठीक है')]); }, function () { lbl.textContent = '✗ लोकेशन नहीं मिली (अनुमति नहीं दी या GPS बंद)'; o.mount([h('button', { class: 'or', type: 'button', onclick: function () { o.done({ id: 'gps', r: 'bad' }); } }, 'ठीक है')]); }, { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 });
    o.mount([h('button', { class: 'alt', type: 'button', style: 'color:#fff;border-color:#fff', onclick: function () { o.done(); } }, 'छोड़ें')]); }
  function lockTest() { var ok = window.PublicKeyCredential && PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable; if (!ok) { R.hw.lock = 'bad'; hwList(); report(); return alert('इस ब्राउज़र से पता नहीं चला'); } PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable().then(function (v) { R.hw.lock = v ? 'ok' : 'bad'; hwList(); tips(); report(); alert(v ? '✓ फ़ोन में स्क्रीन-लॉक/फ़िंगरप्रिंट सुरक्षा चालू है' : '✗ स्क्रीन-लॉक या फ़िंगरप्रिंट चालू नहीं दिखता। सेटिंग में लॉक लगाइए, फ़ोन चोरी या ठगी से बचेगा।'); }); }
  function hwList() { var box = $('hwOut'); box.textContent = ''; TESTS.forEach(function (t) { if (R.hw[t.id || t[0]]) box.append(card(R.hw[t[0]] === 'ok' ? 'ok' : 'bad', t[1].replace(/^\S+\s/, ''), R.hw[t[0]] === 'ok' ? 'ठीक है' : 'गड़बड़ मिली, दुकान पर दिखाइए')); }); }
  TESTS.forEach(function (t) { $('hwBtns').append(h('button', { class: 'alt sm', type: 'button', onclick: t[2] }, t[1])); });

  /* ---------- 3. the clean-up steps ---------- */
  var VENDOR = { samsung: 'Samsung: सेटिंग > बैटरी और डिवाइस केयर > स्टोरेज / मेमोरी', xiaomi: 'Xiaomi/Redmi/POCO: सेटिंग > ऐप > ऐप मैनेज करें; स्टोरेज: सेटिंग > अतिरिक्त सेटिंग > स्टोरेज', oppo: 'OPPO/realme: सेटिंग > ऐप मैनेजमेंट; स्टोरेज: सेटिंग > अतिरिक्त सेटिंग > स्टोरेज', realme: 'realme: सेटिंग > ऐप मैनेजमेंट; स्टोरेज: सेटिंग > अतिरिक्त सेटिंग > स्टोरेज', vivo: 'vivo: सेटिंग > ऐप्स और अनुमतियाँ > ऐप्स; स्टोरेज: सेटिंग > स्टोरेज', moto: 'Motorola: सेटिंग > ऐप्स; स्टोरेज: सेटिंग > स्टोरेज', pixel: 'Pixel: सेटिंग > ऐप्स; स्टोरेज: सेटिंग > स्टोरेज', other: 'सेटिंग > ऐप्स और सेटिंग > स्टोरेज' };
  function intent(a) { return 'intent:#Intent;action=android.settings.' + a + ';end'; }
  var STEPS = [
    ['restart', 'फ़ोन रीस्टार्ट कीजिए', 'पावर बटन दबाकर "रीस्टार्ट"। हफ़्ते में एक बार करने से लैग और हीटिंग अक्सर कम हो जाते हैं।'],
    ['storage', 'स्टोरेज देखिए और 15 से 20% खाली कीजिए', 'सबसे पहले फ़ोटो-वीडियो का बैकअप (Google Photos या कंप्यूटर), फिर पुरानी फ़ाइलें और WhatsApp का पुराना मीडिया हटाइए। ' + (VENDOR[vendor] || ''), intent('INTERNAL_STORAGE_SETTINGS')],
    ['apps', 'वो ऐप हटाइए जो आप इस्तेमाल नहीं करते', 'सेटिंग > ऐप्स में जाकर बड़े और पुराने ऐप हटाइए। हर ऐप बैकग्राउंड में बैटरी और RAM लेता है।', intent('MANAGE_ALL_APPLICATIONS_SETTINGS')],
    ['cache', 'भारी ऐप का कैश साफ़ कीजिए', 'सेटिंग > ऐप्स > (WhatsApp, Instagram, Chrome, YouTube वगैरह) > स्टोरेज > "Clear cache"। इससे चैट, फ़ोटो या लॉगिन नहीं हटते, सिर्फ़ कचरा हटता है। "Clear data" मत दबाइए।', intent('MANAGE_ALL_APPLICATIONS_SETTINGS')],
    ['chrome', 'Chrome का कचरा साफ़ कीजिए', 'Chrome खोलिए > तीन बिंदु > इतिहास > "ब्राउज़िंग डेटा मिटाएँ" > सिर्फ़ "कैश्ड इमेज और फ़ाइलें" चुनिए (पासवर्ड/कुकीज़ को छोड़ दीजिए, नहीं तो लॉगिन हट जाएँगे)।'],
    ['update', 'ऐप और फ़ोन के अपडेट कीजिए', 'Play Store > प्रोफ़ाइल > ऐप और डिवाइस मैनेज करें > अपडेट। फ़ोन का अपडेट: सेटिंग > सिस्टम अपडेट। पुराने ऐप में बग से फ़ोन अटकता है।', intent('DEVICE_INFO_SETTINGS')],
    ['battery', 'बैटरी में बेकार ऐप देखिए', 'सेटिंग > बैटरी > ऐप-वार इस्तेमाल। जो ऐप ज़्यादा बैटरी खाए और काम का न हो, उसे हटाइए या "प्रतिबंधित" कीजिए।', intent('BATTERY_SAVER_SETTINGS')],
    ['widgets', 'होम स्क्रीन हल्की कीजिए', 'लाइव वॉलपेपर, ज़्यादा विजेट और हर ऐप की नोटिफ़िकेशन बंद कीजिए। फ़ोन हल्का चलेगा।', intent('DISPLAY_SETTINGS')],
    ['anim', 'एनिमेशन तेज़ कीजिए (वैकल्पिक)', 'फ़ोन के बारे में > "बिल्ड नंबर" 7 बार दबाइए > डेवलपर विकल्प > "Window/Transition/Animator animation scale" को 0.5x कीजिए। फ़ोन तुरंत तेज़ लगता है।', intent('APPLICATION_DEVELOPMENT_SETTINGS')]
  ];
  var doneSteps = {}; try { doneSteps = JSON.parse(LS.get('bhCareSteps', '{}')); } catch (e) { }
  function stepList() { var box = $('stepList'); box.textContent = ''; STEPS.forEach(function (s, i) { var cb = h('input', { type: 'checkbox' }); cb.checked = !!doneSteps[s[0]]; cb.onchange = function () { doneSteps[s[0]] = cb.checked ? Date.now() : 0; LS.set('bhCareSteps', JSON.stringify(doneSteps)); streak(); tips(); };
      var row = h('div', { class: 'step' }, cb, h('div', {}, h('b', {}, (i + 1) + '. ' + s[1]), h('small', {}, s[2]), s[3] ? h('div', { class: 'row', style: 'margin-top:6px' }, h('a', { class: 'btn alt sm', href: s[3] }, 'सेटिंग खोलने की कोशिश करें')) : null)); box.append(row); }); streak(); }
  function streak() { var n = STEPS.filter(function (s) { return doneSteps[s[0]]; }).length, last = LS.get('bhCareLast', ''); if (n === STEPS.length) { var wk = LS.get('bhCareWeeks', '0'); if (LS.get('bhCareCounted', '') !== new Date().toDateString()) { LS.set('bhCareWeeks', String(+wk + 1)); LS.set('bhCareCounted', new Date().toDateString()); } } $('streak').textContent = n + ' / ' + STEPS.length + ' चरण पूरे' + (+LS.get('bhCareWeeks', '0') ? ' · अब तक ' + LS.get('bhCareWeeks', '0') + ' बार पूरी सफ़ाई' : '') + '. हफ़्ते में एक बार दोहराइए।'; }
  $('resetSteps').onclick = function () { doneSteps = {}; LS.set('bhCareSteps', '{}'); stepList(); };
  $('ics').onclick = function () { var d = new Date(); d.setDate(d.getDate() + ((7 - d.getDay()) % 7 || 7)); var p = function (n) { return String(n).padStart(2, '0'); }, dt = d.getFullYear() + p(d.getMonth() + 1) + p(d.getDate()) + 'T100000';
    var ics = ['BEGIN:VCALENDAR', 'VERSION:2.0', 'PRODID:-//Brandhoop//Phone Care//HI', 'BEGIN:VEVENT', 'UID:phone-care-weekly@brandhoop', 'DTSTAMP:' + new Date().toISOString().replace(/[-:]/g, '').slice(0, 15) + 'Z', 'DTSTART:' + dt, 'RRULE:FREQ=WEEKLY', 'SUMMARY:फ़ोन की साप्ताहिक सफ़ाई (Brandhoop)', 'DESCRIPTION:रीस्टार्ट, कैश साफ़, स्टोरेज जाँच। ' + location.href.split('#')[0], 'BEGIN:VALARM', 'TRIGGER:PT0M', 'ACTION:DISPLAY', 'DESCRIPTION:फ़ोन की सफ़ाई का समय', 'END:VALARM', 'END:VEVENT', 'END:VCALENDAR'].join('\r\n');
    var a = h('a', { href: URL.createObjectURL(new Blob([ics], { type: 'text/calendar' })), download: 'phone-care-weekly.ics' }); document.body.append(a); a.click(); a.remove(); };

  /* ---------- suggestions from the shop, shown where they fit ---------- */
  function tipBox(id, items) { var box = $(id); box.textContent = ''; items.forEach(function (t) { box.append(h('div', { class: 'tip' }, h('b', {}, t.h), h('div', {}, t.b), h('div', { class: 'row' }, t.links.map(function (l) { return h('a', { class: 'btn ' + (l.or ? 'or' : 'alt') + ' sm', href: l.href }, l.t); })))); }); }
  var ASK = function (txt) { return 'https://wa.me/' + SHOP_WA + '?text=' + encodeURIComponent(txt); };
  function tips() {
    var q = R.quick, bad = function (id) { return R.hw[id] === 'bad'; }, A = [], B = [], C = [];
    if (q && (q.verdict !== 'ok' || q.score < 60)) A.push({ h: 'फ़ोन बहुत धीमा लगे तो', b: 'सफ़ाई के बाद भी स्कोर कम रहे तो फ़ोन पुराना हो चुका है। बजट बताइए, दुकान से सही नया फ़ोन चुनने में मदद मिलेगी।', links: [{ t: 'Brandhoop ऐप में फ़ोन देखें', href: '../app/#/shop?cat=smartphone', or: 1 }, { t: 'दुकान से पूछें', href: ASK('नमस्ते, मेरा फ़ोन धीमा है। मेरा बजट ___ है। कौन-सा फ़ोन ठीक रहेगा?') }] });
    if (q && q.battery && !q.battery.charging && q.battery.level < 30) A.push({ h: 'बैटरी जल्दी उतरती हो तो', b: 'पुरानी बैटरी या खराब चार्जर बड़ा कारण होते हैं। दुकान पर बैटरी की जाँच करवाइए और असली केबल/चार्जर इस्तेमाल कीजिए।', links: [{ t: 'चार्जर और पावर बैंक देखें', href: '../app/#/shop?cat=charger', or: 1 }, { t: 'दुकान से पूछें', href: ASK('नमस्ते, मेरे फ़ोन की बैटरी जल्दी उतरती है। जाँच के लिए क्या करना होगा?') }] });
    if (bad('screen') || bad('touch') || bad('ghost')) B.push({ h: 'स्क्रीन या टच में गड़बड़ मिली', b: 'चटकी स्क्रीन या अपने-आप टच आना अक्सर स्क्रीन या स्क्रीन-गार्ड की समस्या होती है। फ़ोन दुकान पर दिखाइए, जाँचकर बताया जाएगा।', links: [{ t: 'स्क्रीन गार्ड और कवर', href: '../app/#/shop?cat=screenGuard', or: 1 }, { t: 'दुकान से पूछें', href: ASK('नमस्ते, मेरे फ़ोन की स्क्रीन/टच में दिक्कत है। दिखाने कब आऊँ?') }] });
    if (bad('speaker') || bad('mic') || bad('camera') || bad('vibrate') || bad('sensor') || bad('gps')) B.push({ h: 'हार्डवेयर की गड़बड़ मिली', b: 'स्पीकर, माइक, कैमरा या सेंसर की दिक्कत ज़्यादातर रिपेयर से ठीक होती है। पहले दुकान पर जाँच करवाइए।', links: [{ t: 'दुकान से पूछें', href: ASK('नमस्ते, मेरे फ़ोन में हार्डवेयर की दिक्कत है (जाँच रिपोर्ट के साथ)। क्या ठीक हो सकता है?'), or: 1 }] });
    C.push({ h: 'फ़ोन की आगे की सुरक्षा', b: 'स्क्रीन-गार्ड और अच्छा कवर फ़ोन को चटकने से बचाते हैं। ऐप में सारे एक्सेसरी और रेट देखिए।', links: [{ t: 'एक्सेसरी देखें', href: '../app/#/shop?cat=caseCover', or: 1 }, { t: 'WhatsApp पर पूछें', href: ASK('नमस्ते, मुझे फ़ोन के लिए एक्सेसरी चाहिए। आज की कीमत बताइए।') }] });
    if (doneSteps.storage && q && q.verdict !== 'ok') C.unshift({ h: 'स्टोरेज भरता रहे तो', b: 'मेमोरी कार्ड या पेन ड्राइव में फ़ोटो-वीडियो का बैकअप रखने से फ़ोन हल्का रहता है। दुकान से पूछिए कि आपके फ़ोन में क्या चलेगा।', links: [{ t: 'मेमोरी कार्ड/पेन ड्राइव', href: '../app/#/shop?cat=memory', or: 1 }] });
    tipBox('tipA', A); tipBox('tipB', B); tipBox('tipC', C);
  }

  /* ---------- the report and the message to the shop ---------- */
  function report() {
    var out = $('repOut'), L = [], q = R.quick; out.textContent = ''; var any = !!q || Object.keys(R.hw).length; if (!any) { out.textContent = 'ऊपर की जाँचें चलाइए, फिर यहाँ रिपोर्ट बनेगी।'; $('wa').classList.add('hide'); return; }
    if (q) { out.append(card(q.verdict, 'रफ़्तार स्कोर ' + q.score + '/100', 'प्रोसेसर ' + q.cpu + ' ms · अटकाव ' + q.jank)); L.push('रफ़्तार स्कोर ' + q.score + '/100 (प्रोसेसर ' + q.cpu + ' ms, अटकाव ' + q.jank + ')'); if (q.mbps) L.push('इंटरनेट ' + q.mbps + ' Mbps'); if (q.battery) L.push('बैटरी ' + q.battery.level + '%'); }
    TESTS.forEach(function (t) { if (R.hw[t[0]]) { out.append(card(R.hw[t[0]] === 'ok' ? 'ok' : 'bad', t[1].replace(/^\S+\s/, ''), R.hw[t[0]] === 'ok' ? 'ठीक' : 'गड़बड़')); L.push(t[1].replace(/^\S+\s/, '') + ': ' + (R.hw[t[0]] === 'ok' ? 'ठीक' : 'गड़बड़')); } });
    var done = STEPS.filter(function (s) { return doneSteps[s[0]]; }).length; L.push('सफ़ाई के चरण: ' + done + '/' + STEPS.length);
    var wa = $('wa'); wa.classList.remove('hide'); wa.onclick = function () { window.open(ASK('नमस्ते Brandhoop, मैंने फ़ोन केयर पेज पर जाँच की:\n' + (android ? 'Android ' + android + '\n' : '') + L.join('\n') + '\n\nकृपया बताइए आगे क्या करना चाहिए।'), '_blank'); };
  }

  /* ---------- install this page as an app ---------- */
  var ev = null; window.addEventListener('beforeinstallprompt', function (e) { e.preventDefault(); ev = e; $('install').style.display = ''; });
  $('install').onclick = function () { if (ev) { ev.prompt(); ev = null; $('install').style.display = 'none'; } };
  if ('serviceWorker' in navigator) navigator.serviceWorker.register('sw.js').catch(function () { });
  $('runQuick').onclick = runQuick; stepList(); tips(); report();
  window.PhoneCare = { R: R, runQuick: runQuick, tips: tips, STEPS: STEPS };
})();
