/* Card Studio: draws every card style on a canvas (1050 x 600) from the shared details and colours. */
(function () {
  'use strict';
  var W = 1050, H = 600, FONT = '"Montserrat","Noto Sans Devanagari",system-ui,sans-serif';
  var $ = function (id) { return document.getElementById(id); };
  var DEF = {
    hi: { name: 'नरेश सैनी', role: 'मालिक', tagline: 'नए फ़ोन और एक्सेसरी, एक ही दुकान पर', address: 'गेट नं. 5, कमला मोदी मार्केट, नीम का थाना, राजस्थान 332713', services: 'मोबाइल · एक्सेसरी · रिपेयर · स्किन कटिंग · EMI' },
    en: { name: 'Naresh Saini', role: 'Owner', tagline: 'New phones and accessories, one shop', address: 'Gate No. 5, Kamla Modi Market, Neem Ka Thana, Rajasthan 332713', services: 'Mobiles · Accessories · Repair · Skin cutting · EMI' }
  };
  var COMMON = { phone: '86197 67291', wa: '86197 67291', web: 'pallavsharmaofficial.github.io/brandhoop' };
  var MAPS = 'https://www.google.com/maps/place/Brandhoop+Mobile+Point/@27.7415504,75.7817561,17z/data=!3m1!4b1!4m6!3m5!1s0x396d275817d19c4f:0x92f9965c781103ad!8m2!3d27.7415504!4d75.7817561!16s%2Fg%2F11g1lxn9kc';
  var KEY = 'brandhoopCardStudio1';
  var S = { lang: 'hi', style: 'phonewall', f: {}, primary: '#1F2744', accent: '#D8662A', qrt: 'wa', artAll: false };
  var photos = {}; // style id or '_all' -> Image
  var logos = {}, lineart = new Image(); lineart.onload = queue; lineart.src = 'lineart.png';
  ['brandhoop-logo', 'brandhoop-logo-on-dark', 'brandhoop-logo-horizontal', 'brandhoop-logo-horizontal-on-dark', 'brandhoop-mark', 'brandhoop-mark-white'].forEach(function (n) {
    var i = new Image(); i.onload = queue; i.src = '../logo/' + n + '.svg'; logos[n] = i;
  });

  function load() { try { var j = JSON.parse(localStorage.getItem(KEY) || 'null'); if (j) { S.lang = j.lang || S.lang; S.style = j.style || S.style; S.f = j.f || {}; S.primary = j.primary || S.primary; S.accent = j.accent || S.accent; S.qrt = j.qrt || S.qrt; S.artAll = !!j.artAll; } } catch (e) { } }
  function save() { try { localStorage.setItem(KEY, JSON.stringify(S)); } catch (e) { } }
  function val(k) { return S.f[k] !== undefined ? S.f[k] : (DEF[S.lang][k] !== undefined ? DEF[S.lang][k] : COMMON[k]); }

  function shade(hex, k) { var n = parseInt(hex.slice(1), 16); function f(v) { return Math.max(0, Math.min(255, Math.round(v * k))); } return '#' + [n >> 16, (n >> 8) & 255, n & 255].map(function (v) { return f(v).toString(16).padStart(2, '0'); }).join(''); }
  function pal() { return { P: S.primary, D: shade(S.primary, 0.66), P2: shade(S.primary, 1.25), A: S.accent, Ad: shade(S.accent, 0.7), Al: shade(S.accent, 1.2), W: '#FFFFFF', L: '#F6F6F6', S: '#566170', K: '#14182B', As: '#FBE3D2' }; }
  function tok(P, t) { return P[t] || t; }
  function rr(g, x, y, w, h, r) { g.beginPath(); g.moveTo(x + r, y); g.arcTo(x + w, y, x + w, y + h, r); g.arcTo(x + w, y + h, x, y + h, r); g.arcTo(x, y + h, x, y, r); g.arcTo(x, y, x + w, y, r); g.closePath(); }
  function cover(g, im, x, y, w, h) { var k = Math.max(w / im.width, h / im.height), dw = im.width * k, dh = im.height * k; g.drawImage(im, x + (w - dw) / 2, y + (h - dh) / 2, dw, dh); }
  function wrap(g, text, maxW) { var out = [], line = ''; String(text).split(/\s+/).forEach(function (w) { var t = line ? line + ' ' + w : w; if (g.measureText(t).width > maxW && line) { out.push(line); line = w; } else line = t; }); if (line) out.push(line); return out; }
  function T(g, s, x, y, size, wt, color, align, maxW) { g.font = wt + ' ' + size + 'px ' + FONT; g.fillStyle = color; g.textAlign = align || 'left'; g.textBaseline = 'top'; if (maxW) g.fillText(s, x, y, maxW); else g.fillText(s, x, y); }
  function logoImg(name) { return logos['brandhoop-' + name]; }
  function drawLogo(g, name, x, y, h, align) { var im = logoImg(name); if (!im || !im.complete || !im.naturalWidth) return 0; var w = h * im.naturalWidth / im.naturalHeight, dx = align === 'center' ? x - w / 2 : (align === 'right' ? x - w : x); g.drawImage(im, dx, y, w, h); return w; }

  function placeholder(g, P, st, x, y, w, h) {
    var gr = g.createLinearGradient(x, y, x + w, y + h); gr.addColorStop(0, shade(S.primary, 1.35)); gr.addColorStop(1, shade(S.primary, 0.6));
    g.fillStyle = gr; g.fillRect(x, y, w, h);
    g.save(); g.beginPath(); g.rect(x, y, w, h); g.clip(); g.globalAlpha = 0.14; var im = logoImg('mark-white'); if (im && im.naturalWidth) { var s = Math.min(w, h) * 0.8; g.drawImage(im, x + (w - s * im.naturalWidth / im.naturalHeight) / 2, y + (h - s) / 2, s * im.naturalWidth / im.naturalHeight, s); } g.restore();
  }
  function photoOr(g, P, st, x, y, w, h) { var im = photos[st.id] || photos._all; if (im) { g.save(); g.beginPath(); g.rect(x, y, w, h); g.clip(); cover(g, im, x, y, w, h); g.restore(); return true; } placeholder(g, P, st, x, y, w, h); return false; }

  function bgFill(g, P, st) {
    var a = tok(P, st.bg[0]), b = tok(P, st.bg[1]), gr = g.createLinearGradient(0, 0, W * 0.5, H); gr.addColorStop(0, a); gr.addColorStop(1, b); g.fillStyle = gr; g.fillRect(0, 0, W, H);
    var inkA = st.dark ? '255,255,255' : '20,24,43';
    if (st.deco === 'grid') { g.strokeStyle = 'rgba(' + inkA + ',.06)'; g.lineWidth = 1; for (var x = 0; x <= W; x += 42) { g.beginPath(); g.moveTo(x, 0); g.lineTo(x, H); g.stroke(); } for (var y = 0; y <= H; y += 42) { g.beginPath(); g.moveTo(0, y); g.lineTo(W, y); g.stroke(); } }
    if (st.deco === 'dots') { g.fillStyle = 'rgba(' + inkA + ',.07)'; for (var i = 0; i < W; i += 30) for (var j = 0; j < H; j += 30) { g.beginPath(); g.arc(i, j, 2, 0, 7); g.fill(); } }
    if (st.deco === 'rings') { g.strokeStyle = 'rgba(' + inkA + ',.07)'; g.lineWidth = 2; for (var r = 120; r < 700; r += 70) { g.beginPath(); g.arc(W + 40, -40, r, 0, 7); g.stroke(); } }
    if (st.deco === 'glow') { var rg = g.createRadialGradient(W * 0.85, H * 0.85, 10, W * 0.85, H * 0.85, 460); rg.addColorStop(0, P.A + 'CC'); rg.addColorStop(1, P.A + '00'); g.fillStyle = rg; g.fillRect(0, 0, W, H); }
    if (st.deco === 'watermark') { var im = logoImg('mark-white'); if (im && im.naturalWidth) { g.save(); g.globalAlpha = 0.07; var hh = 640, ww = hh * im.naturalWidth / im.naturalHeight; g.drawImage(im, W - ww + 60, -20, ww, hh); g.restore(); } }
  }
  function bgPhoto(g, P, st) { var im = photos[st.id] || photos._all; if (!im || !st.bgPhoto) return; cover(g, im, 0, 0, W, H); g.fillStyle = st.dark ? tokA(P.D, st.ov) : 'rgba(255,255,255,' + st.ov + ')'; g.fillRect(0, 0, W, H); }
  function tokA(hex, a) { var n = parseInt(hex.slice(1), 16); return 'rgba(' + (n >> 16) + ',' + ((n >> 8) & 255) + ',' + (n & 255) + ',' + a + ')'; }

  // Phone-accessory line art, white at 5%, on the front of centred and framed cards (always on Tech Grid, optional on other dark ones)
  function art(g, st) {
    if (!(st.art || (S.artAll && st.dark)) || (st.layout !== 'center' && st.layout !== 'frame') || !lineart.naturalWidth) return;
    g.save(); g.globalAlpha = 0.05; var k = W / lineart.naturalWidth, h = lineart.naturalHeight * k; g.drawImage(lineart, 0, (H - h) / 2, W, h); g.restore();
  }
  function ink(st) { return st.dark ? '#FFFFFF' : '#14182B'; }
  function sub(st) { return st.dark ? 'rgba(255,255,255,.82)' : '#566170'; }
  function accentOn(st, P) { return st.dark && st.bg[0] === 'A' ? '#FFFFFF' : P.A; }
  function logoName(st, horiz) { return (horiz ? 'logo-horizontal' : 'logo') + (st.dark ? '-on-dark' : ''); }

  function nameBlock(g, P, st, x, y, w) {
    T(g, val('name'), x, y, 46, 800, ink(st), 'left', w); T(g, val('role'), x, y + 56, 24, 700, accentOn(st, P), 'left', w); return y + 96;
  }
  function contacts(g, P, st, x, y, w, size, lines) {
    var same = String(val('phone')).replace(/\D/g, '') === String(val('wa')).replace(/\D/g, ''), items = lines || [['Call', val('phone') + (same ? '  (Call + WhatsApp)' : '')], ['WhatsApp', same ? '' : val('wa')], ['Web', val('web')]];
    items.forEach(function (it) { if (!it[1]) return; g.fillStyle = accentOn(st, P); g.beginPath(); g.arc(x + 6, y + size * 0.55, 5, 0, 7); g.fill(); T(g, it[1], x + 24, y, size, 700, ink(st), 'left', w - 24); y += size * 1.7; });
    return y;
  }
  function addr(g, P, st, x, y, w, size) { g.font = '600 ' + size + 'px ' + FONT; wrap(g, val('address'), w).slice(0, 3).forEach(function (l) { T(g, l, x, y, size, 600, sub(st), 'left'); y += size * 1.45; }); return y; }

  function front(g, P, st) {
    bgFill(g, P, st); bgPhoto(g, P, st); art(g, st);
    var L = st.layout, ik = ink(st);
    if (L === 'center') {
      drawLogo(g, logoName(st, false), W / 2, 36, 410, 'center'); g.font = '600 24px ' + FONT;
      T(g, val('tagline'), W / 2, 500, 24, 600, sub(st), 'center', W - 120);
    } else if (L === 'full') {
      if (!(photos[st.id] || photos._all)) placeholder(g, P, st, 0, 0, W, H); else cover(g, photos[st.id] || photos._all, 0, 0, W, H);
      var gr = g.createLinearGradient(0, 0, W, H), c0 = tokA(tok(P, st.bg[1]), Math.min(.92, st.ov + .3)), c1 = tokA(tok(P, st.bg[1]), st.ov * 0.25); gr.addColorStop(0, c0); gr.addColorStop(1, c1); g.fillStyle = gr; g.fillRect(0, 0, W, H);
      var bt = g.createLinearGradient(0, H * 0.4, 0, H); bt.addColorStop(0, 'rgba(0,0,0,0)'); bt.addColorStop(1, 'rgba(0,0,0,.55)'); g.fillStyle = bt; g.fillRect(0, 0, W, H);
      if (st.deco === 'glow') { var rg = g.createRadialGradient(W * 0.85, H * 0.9, 10, W * 0.85, H * 0.9, 420); rg.addColorStop(0, P.A + '99'); rg.addColorStop(1, P.A + '00'); g.fillStyle = rg; g.fillRect(0, 0, W, H); }
      drawLogo(g, 'logo-horizontal-on-dark', 52, 40, 100);
      T(g, val('name'), 56, 372, 52, 800, '#FFFFFF', 'left', 640); T(g, val('role'), 56, 434, 26, 700, '#FFB486', 'left', 640);
      T(g, val('phone'), 56, 486, 36, 800, '#FFFFFF', 'left', 640); T(g, val('tagline'), 56, 534, 20, 600, 'rgba(255,255,255,.85)', 'left', 940);
    } else if (L === 'left' || L === 'right') {
      var pw = 400, px = L === 'left' ? 0 : W - pw, cx = L === 'left' ? pw + 56 : 56, cw = W - pw - 112;
      photoOr(g, P, st, px, 0, pw, H);
      g.fillStyle = P.A; g.fillRect(L === 'left' ? pw : px - 8, 0, 8, H);
      drawLogo(g, logoName(st, true), cx, 40, 86); var y = nameBlock(g, P, st, cx, 168, cw); y = contacts(g, P, st, cx, y + 12, cw, 24); addr(g, P, st, cx, y + 4, cw, 18);
    } else if (L === 'top') {
      photoOr(g, P, st, 0, 0, W, 232);
      g.fillStyle = P.A; g.fillRect(0, 232, W, 8);
      g.fillStyle = '#FFFFFF'; g.beginPath(); g.arc(106, 232, 70, 0, 7); g.fill(); drawLogo(g, 'mark', 106, 176, 112, 'center');
      var x0 = 210, y0 = 262; T(g, val('name'), x0, y0, 42, 800, ik, 'left', W - x0 - 40); T(g, val('role'), x0, y0 + 50, 22, 700, accentOn(st, P), 'left');
      contacts(g, P, st, 60, 392, 420, 24); addr(g, P, st, 560, 396, 430, 19);
    } else if (L === 'circle') {
      var cxr = 790, cyr = 300, r = 200; g.fillStyle = P.A; g.beginPath(); g.arc(cxr, cyr, r + 10, 0, 7); g.fill();
      g.save(); g.beginPath(); g.arc(cxr, cyr, r, 0, 7); g.clip(); photoOr(g, P, st, cxr - r, cyr - r, 2 * r, 2 * r); g.restore();
      drawLogo(g, logoName(st, true), 56, 40, 86); var y2 = nameBlock(g, P, st, 56, 176, 440); y2 = contacts(g, P, st, 56, y2 + 10, 440, 23); addr(g, P, st, 56, y2 + 4, 420, 17);
    } else if (L === 'frame') {
      g.strokeStyle = P.A; g.lineWidth = 3; g.strokeRect(26, 26, W - 52, H - 52); g.strokeStyle = st.dark ? 'rgba(255,255,255,.25)' : 'rgba(20,24,43,.18)'; g.lineWidth = 1; g.strokeRect(40, 40, W - 80, H - 80);
      drawLogo(g, logoName(st, true), W / 2, 64, 118, 'center');
      T(g, val('name'), W / 2, 214, 46, 800, ik, 'center', W - 160); T(g, val('role'), W / 2, 270, 22, 700, accentOn(st, P), 'center');
      g.fillStyle = P.A; g.fillRect(W / 2 - 40, 318, 80, 3);
      T(g, val('phone') + '   ·   ' + val('web'), W / 2, 346, 24, 700, ik, 'center', W - 140); g.font = '600 20px ' + FONT;
      var ly = 396; wrap(g, val('address'), W - 220).slice(0, 2).forEach(function (l) { T(g, l, W / 2, ly, 20, 600, sub(st), 'center'); ly += 30; });
      T(g, val('tagline'), W / 2, 484, 20, 600, sub(st), 'center', W - 160);
    } else if (L === 'stripe') {
      g.fillStyle = P.A; g.fillRect(0, 0, 110, H); g.save(); g.translate(70, H - 40); g.rotate(-Math.PI / 2); T(g, 'BRANDHOOP · MOBILE POINT', 0, 0, 26, 800, '#FFFFFF', 'left', H - 80); g.restore();
      photoOr(g, P, st, W - 300, 0, 300, H);
      drawLogo(g, logoName(st, true), 160, 40, 86); var y3 = nameBlock(g, P, st, 160, 166, 540); y3 = contacts(g, P, st, 160, y3 + 12, 540, 24); addr(g, P, st, 160, y3 + 4, 540, 18);
    } else if (L === 'diagonal') {
      photoOr(g, P, st, 0, 0, W, H);
      g.fillStyle = tokA(P.A, st.ov); g.fillRect(0, 0, W, H);
      g.beginPath(); g.moveTo(0, 0); g.lineTo(650, 0); g.lineTo(500, H); g.lineTo(0, H); g.closePath();
      var gr2 = g.createLinearGradient(0, 0, 600, H); gr2.addColorStop(0, tok(P, st.bg[0])); gr2.addColorStop(1, tok(P, st.bg[1])); g.fillStyle = gr2; g.fill();
      g.strokeStyle = P.A; g.lineWidth = 12; g.beginPath(); g.moveTo(650, 0); g.lineTo(500, H); g.stroke();
      drawLogo(g, 'logo-horizontal-on-dark', 52, 40, 86); var y4 = nameBlock(g, P, st, 56, 168, 400); y4 = contacts(g, P, st, 56, y4 + 12, 420, 23); addr(g, P, st, 56, y4 + 4, 380, 17);
    }
  }

  var qrCache = {};
  function qrTarget() {
    var wa = (val('wa') || '').replace(/\D/g, ''); if (wa.length === 10) wa = '91' + wa;
    return S.qrt === 'maps' ? MAPS : S.qrt === 'web' ? 'https://' + val('web').replace(/^https?:\/\//, '') : 'https://wa.me/' + wa + '?text=' + encodeURIComponent('Hi Brandhoop, I saw your card');
  }
  function drawQR(g, x, y, size, dark, light) {
    if (typeof qrcode === 'undefined') return;
    var url = qrTarget(), q = qrCache[url]; if (!q) { q = qrcode(0, 'M'); q.addData(url); q.make(); qrCache[url] = q; }
    var n = q.getModuleCount(), m = size / (n + 4), x0 = x + m * 2, y0 = y + m * 2; g.fillStyle = light; g.fillRect(x, y, size, size); g.fillStyle = dark;
    for (var r = 0; r < n; r++) for (var c = 0; c < n; c++) if (q.isDark(r, c)) g.fillRect(x0 + c * m, y0 + r * m, Math.ceil(m), Math.ceil(m));
  }
  function back(g, P, st) {
    bgFill(g, P, st); bgPhoto(g, P, st); var ik = ink(st);
    g.fillStyle = P.A; g.fillRect(0, H - 14, W, 14);
    drawLogo(g, logoName(st, true), 56, 44, 96);
    var y = 190;
    if (st.layout === 'center') { T(g, val('name'), 56, y, 42, 800, ik, 'left', 600); T(g, val('role'), 56, y + 50, 22, 700, accentOn(st, P), 'left'); y = contacts(g, P, st, 56, y + 96, 600, 24, [['Call', val('phone') + (String(val('phone')).replace(/\D/g, '') === String(val('wa')).replace(/\D/g, '') ? '  (Call + WhatsApp)' : '')], ['WhatsApp', String(val('phone')).replace(/\D/g, '') === String(val('wa')).replace(/\D/g, '') ? '' : val('wa')]]); }
    else { g.font = '700 26px ' + FONT; wrap(g, val('tagline'), 560).slice(0, 3).forEach(function (l) { T(g, l, 56, y, 26, 700, ik, 'left'); y += 38; }); y += 10; }
    y = addr(g, P, st, 56, y + 4, 560, 19);
    T(g, val('services'), 56, Math.min(y + 20, H - 80), 18, 700, accentOn(st, P), 'left', 600);
    if (S.qrt !== 'none') {
      var qs = 250, qx = W - qs - 86, qy = 150; g.save(); g.shadowColor = 'rgba(0,0,0,.25)'; g.shadowBlur = 24; g.fillStyle = '#FFFFFF'; rr(g, qx - 16, qy - 16, qs + 32, qs + 74, 20); g.fill(); g.restore();
      drawQR(g, qx, qy, qs, '#14182B', '#FFFFFF');
      T(g, S.qrt === 'maps' ? 'Find us on Maps' : S.qrt === 'web' ? 'See our phones' : 'Scan to WhatsApp', qx + qs / 2, qy + qs + 12, 20, 800, '#14182B', 'center', qs + 20);
    }
  }
  function render(c, st, side, sc) { var g = c.getContext('2d'); c.width = Math.round(W * sc); c.height = Math.round(H * sc); g.setTransform(sc, 0, 0, sc, 0, 0); g.clearRect(0, 0, W, H); var P = pal(); if (side === 'front') front(g, P, st); else back(g, P, st); }

  var grid = $('grid'), thumbs = {}, timer = 0;
  function cur() { return STYLES.filter(function (s) { return s.id === S.style; })[0] || STYLES[0]; }
  function fullPrompt(st) { return st.prompt + PROMPT_SUFFIX + '\nAspect ratio: ' + st.ratio + '.\nNegative prompt: ' + PROMPT_NEGATIVE; }
  function toast(m) { var t = $('toast'); t.textContent = m; t.style.opacity = 1; setTimeout(function () { t.style.opacity = 0; }, 1600); }
  function copy(txt) { if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(txt).then(function () { toast('Prompt copied'); }, function () { prompt('Copy this prompt', txt); }); else prompt('Copy this prompt', txt); }
  function build() {
    STYLES.forEach(function (st, i) {
      var d = document.createElement('div'); d.className = 'st'; d.id = 'st_' + st.id;
      d.innerHTML = '<canvas></canvas><div class="t"><span>' + (i + 1) + '. ' + st.n + '<br><small>' + st.hi + '</small></span></div><div class="b"><button class="sm alt" data-a="photo">Add photo</button><button class="sm or" data-a="copy">Copy prompt</button></div>';
      d.addEventListener('click', function (e) { var a = e.target.getAttribute && e.target.getAttribute('data-a'); S.style = st.id; save(); if (a === 'copy') copy(fullPrompt(st)); if (a === 'photo') $('file').click(); refresh(); });
      grid.appendChild(d); thumbs[st.id] = d.querySelector('canvas');
    });
  }
  function refresh() {
    var st = cur(); STYLES.forEach(function (s) { $('st_' + s.id).classList.toggle('on', s.id === st.id); });
    $('selTitle').textContent = (STYLES.indexOf(st) + 1) + '. ' + st.n + ' · ' + st.hi;
    render($('pf'), st, 'front', 1); render($('pb'), st, 'back', 1);
    STYLES.forEach(function (s) { render(thumbs[s.id], s, 'front', 0.34); });
    var p = $('prompt'); p.innerHTML = ''; var h = document.createElement('div'); h.textContent = fullPrompt(st); p.appendChild(h);
    var m = document.createElement('div'); m.className = 'm'; m.textContent = 'Photo goes here: ' + st.slot + ' · ask for ' + st.ratio; p.appendChild(m);
    var b = document.createElement('button'); b.className = 'sm or'; b.style.marginTop = '8px'; b.textContent = 'Copy prompt'; b.onclick = function () { copy(fullPrompt(st)); }; p.appendChild(b);
  }
  function queue() { clearTimeout(timer); timer = setTimeout(refresh, 120); }

  function fill() { ['name', 'role', 'phone', 'wa', 'web', 'address', 'tagline', 'services'].forEach(function (k) { $('f_' + k).value = val(k); }); $('lang').value = S.lang; $('c_primary').value = S.primary; $('c_accent').value = S.accent; $('qrt').value = S.qrt; $('artAll').checked = S.artAll; }
  function bind() {
    ['name', 'role', 'phone', 'wa', 'web', 'address', 'tagline', 'services'].forEach(function (k) { $('f_' + k).addEventListener('input', function () { S.f[k] = $('f_' + k).value; save(); queue(); }); });
    $('lang').onchange = function () { S.lang = $('lang').value; ['name', 'role', 'tagline', 'address', 'services'].forEach(function (k) { delete S.f[k]; }); save(); fill(); queue(); };
    $('c_primary').oninput = function () { S.primary = $('c_primary').value; save(); queue(); };
    $('c_accent').oninput = function () { S.accent = $('c_accent').value; save(); queue(); };
    $('artAll').onchange = function () { S.artAll = $('artAll').checked; save(); queue(); };
    $('qrt').onchange = function () { S.qrt = $('qrt').value; save(); queue(); };
    $('reset').onclick = function () { S.f = {}; S.primary = '#1F2744'; S.accent = '#D8662A'; S.qrt = 'wa'; S.artAll = false; save(); fill(); queue(); };
    function setPhoto(file, all) { var u = URL.createObjectURL(file), im = new Image(); im.onload = function () { photos[all ? '_all' : S.style] = im; queue(); }; im.src = u; }
    var all = false; $('addPhoto').onclick = function () { all = false; $('file').click(); }; $('addAll').onclick = function () { all = true; $('file').click(); };
    $('file').onchange = function (e) { if (e.target.files[0]) setPhoto(e.target.files[0], all); e.target.value = ''; all = false; };
    $('clrPhoto').onclick = function () { photos = {}; queue(); };
    function quick(src, label) { var im = new Image(); im.onload = function () { photos[S.style] = im; queue(); toast(label); }; im.onerror = function () { toast('Photo not found'); }; im.src = src; }
    $('qShop').onclick = function () { quick('../../gallery/shop-front.jpg', 'Shop front photo added'); };
    $('qWall').onclick = function () { quick('../../gallery/shop-phone-wall.jpg', 'Phone wall photo added'); };
    function dl(side) { var st = cur(), c = document.createElement('canvas'); render(c, st, side, 1); c.toBlob(function (b) { var a = document.createElement('a'); a.href = URL.createObjectURL(b); a.download = 'brandhoop-card-' + st.id + '-' + side + '.png'; a.click(); setTimeout(function () { URL.revokeObjectURL(a.href); }, 4000); }, 'image/png'); }
    $('dlF').onclick = function () { dl('front'); }; $('dlB').onclick = function () { dl('back'); };
  }
  load(); build(); bind(); fill();
  (document.fonts && document.fonts.load ? Promise.all([document.fonts.load('800 40px Montserrat'), document.fonts.load('700 20px Montserrat'), document.fonts.load('700 20px "Noto Sans Devanagari"'), document.fonts.load('800 40px "Noto Sans Devanagari"')]).catch(function () { }) : Promise.resolve()).then(refresh);
  refresh();
})();
