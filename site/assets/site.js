/* Brandhoop website: the shop file drives the phones, the offers banner and the hero model. */
(function () {
  'use strict';
  var ASK = 'https://wa.me/918619767291?text=';
  var reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  var $ = function (id) { return document.getElementById(id); };
  function el(tag, cls, text) { var e = document.createElement(tag); if (cls) e.className = cls; if (text != null) e.textContent = text; return e; }
  function safeUrl(u) { try { var x = new URL(u, location.href); return /^https?:$/.test(x.protocol) ? x.href : ''; } catch (e) { return ''; } }

  // ---- header shadow once the page has moved
  var top = $('top');
  function onScroll() { top.classList.toggle('scrolled', scrollY > 6); }
  addEventListener('scroll', onScroll, { passive: true }); onScroll();

  // ---- reveal on scroll (the page is complete if this never runs: .anim is only set when it can)
  var revealIO = null;
  function watch(nodes) {
    if (!document.documentElement.classList.contains('anim')) return;
    if (!revealIO) {
      revealIO = new IntersectionObserver(function (es) {
        es.forEach(function (e) { if (e.isIntersecting) { e.target.classList.add('in'); revealIO.unobserve(e.target); } });
      }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 });
      setTimeout(function () { document.querySelectorAll('.rv:not(.in)').forEach(function (n) { n.classList.add('in'); }); }, 5000);
    }
    nodes.forEach(function (n) { revealIO.observe(n); });
  }
  watch([].slice.call(document.querySelectorAll('.rv')));

  // ---- search button in the header
  $('searchBtn').addEventListener('click', function () {
    $('phones').scrollIntoView({ behavior: reduce ? 'auto' : 'smooth', block: 'start' });
    setTimeout(function () { $('q').focus({ preventScroll: true }); }, reduce ? 0 : 450);
  });

  // ---- phones: brand chips, live search, cards
  var phones = [], brandSel = '', query = '';
  var PAIRS = [['var(--navy-500)', 'var(--navy-300)'], ['var(--saffron-600)', 'var(--saffron-300)'], ['var(--slate-600)', 'var(--slate-400)'], ['var(--navy-700)', 'var(--saffron-400)']];
  var GLYPH = '<svg viewBox="0 0 70 130" aria-hidden="true"><rect x="2" y="2" width="66" height="126" rx="13" fill="#14182B"/><rect x="6" y="6" width="58" height="118" rx="10" fill="#2B3558"/><rect x="11" y="22" width="48" height="30" rx="7" fill="#D8662A"/><rect x="11" y="58" width="22" height="24" rx="6" fill="#fff" opacity=".2"/><rect x="37" y="58" width="22" height="24" rx="6" fill="#fff" opacity=".9"/><rect x="11" y="100" width="48" height="12" rx="6" fill="#F08A45"/><circle cx="35" cy="12" r="2.4" fill="#0B0F20"/></svg>';
  function minPrice(p) { var v = (p.variants || []).map(function (x) { return x.price; }).filter(function (n) { return n > 0; }); return v.length ? Math.min.apply(null, v) : 0; }
  function inr(n) { return '₹' + n.toLocaleString('en-IN'); }
  function text(p) { return [p.name.en, p.brand, (p.highlights || []).map(function (h) { return h.en; }).join(' '), Object.keys(p.specs || {}).map(function (k) { return p.specs[k]; }).join(' ')].join(' ').toLowerCase(); }

  function card(p, i) {
    var c = el('div', 'card pop'); c.style.setProperty('--d', Math.min(i, 8) * 0.04 + 's');
    var ph = el('div', 'ph'), photo = p.imageUrls && p.imageUrls[0] && safeUrl(p.imageUrls[0]);
    if (photo) { var img = el('img'); img.src = photo; img.alt = p.name.en; img.loading = 'lazy'; ph.appendChild(img); }
    else if (p.model3d && safeUrl(p.model3d.poster)) { var im = el('img'); im.src = safeUrl(p.model3d.poster); im.alt = p.name.en + ' in 3D'; im.loading = 'lazy'; im.style.objectFit = 'contain'; ph.appendChild(im); }
    else {
      var pair = PAIRS[(p.brand || '').split('').reduce(function (a, ch) { return a + ch.charCodeAt(0); }, 0) % PAIRS.length];
      ph.className = 'ph art'; ph.style.setProperty('--a', pair[0]); ph.style.setProperty('--b', pair[1]); ph.innerHTML = GLYPH;
    }
    if (p.specs && p.specs.chip) ph.appendChild(el('span', 'sp', p.specs.chip));
    if (p.model3d) ph.appendChild(el('span', 'three', p.model3d.generated ? '360° 3D · illustrative' : '360° 3D'));
    c.appendChild(ph);
    var b = el('div', 'b'); b.appendChild(el('div', 'brand', p.brand)); b.appendChild(el('div', 'name', p.name.en));
    var hl = (p.highlights || []).slice(0, 2).map(function (h) { return h.en; }).join(' · ');
    if (hl) b.appendChild(el('div', 'spec', hl));
    var mp = minPrice(p);
    if (mp) {
      var pr = el('div', 'price', 'From ' + inr(mp));
      pr.appendChild(el('small', '', (p.refPriceLabel && p.refPriceLabel.en) || 'Shop price'));
      b.appendChild(pr);
    }
    b.appendChild(el('span', 'tag', 'Call for best price'));
    var row = el('div', 'row');
    var w = el('a', 'btn primary sm', 'WhatsApp'); w.href = ASK + encodeURIComponent('Hi Brandhoop, I want today’s best price and offers for ' + p.name.en);
    var v = el('a', 'btn ghost sm', 'View'); v.href = 'app/#/product/' + encodeURIComponent(p.id);
    row.appendChild(w); row.appendChild(v); b.appendChild(row); c.appendChild(b); return c;
  }
  function render() {
    var grid = $('grid'); grid.textContent = '';
    var q = query.trim().toLowerCase();
    var list = phones.filter(function (p) { return (!brandSel || p.brand === brandSel) && (!q || text(p).indexOf(q) >= 0); });
    list.forEach(function (p, i) { grid.appendChild(card(p, i)); });
    if (!list.length) grid.appendChild(el('p', 'empty', 'No phone matches. Clear the search, or WhatsApp us and we will find it.'));
    $('count').textContent = list.length + (list.length === 1 ? ' phone' : ' phones') + (brandSel ? ' · ' + brandSel : '') + (q ? ' · “' + query.trim() + '”' : '');
  }
  $('q').addEventListener('input', function (e) { query = e.target.value; render(); });

  // ---- offers banner
  function banner(offers) {
    if (!offers.length) return;
    $('offers').hidden = false;
    var slides = $('slides'), dots = $('dots'), cur = 0, timer = null;
    offers.forEach(function (o, i) {
      var s = el('div', 'slide'); s.setAttribute('role', 'group'); s.setAttribute('aria-label', (i + 1) + ' of ' + offers.length);
      var img = o.imageUrl && safeUrl(o.imageUrl); if (img) { s.classList.add('img'); s.style.backgroundImage = 'url("' + img.replace(/"/g, '%22') + '")'; }
      s.appendChild(el('div', 't', (o.title && o.title.en) || '')); if (o.subtitle && o.subtitle.en) s.appendChild(el('div', 's', o.subtitle.en));
      var a = el('a', 'btn primary sm', 'Ask today’s price'); a.href = ASK + encodeURIComponent('Hi Brandhoop, I want today’s best price and offers'); s.appendChild(a);
      slides.appendChild(s);
      var d = el('button'); d.type = 'button'; d.setAttribute('aria-label', 'Offer ' + (i + 1)); d.addEventListener('click', function () { go(i, true); }); dots.appendChild(d);
    });
    function go(i, user) { cur = (i + offers.length) % offers.length; slides.style.transform = 'translateX(' + (-100 * cur) + '%)'; [].forEach.call(dots.children, function (d, k) { d.setAttribute('aria-current', k === cur ? 'true' : 'false'); }); if (user) restart(); }
    function restart() { clearInterval(timer); if (!reduce && offers.length > 1) timer = setInterval(function () { go(cur + 1); }, 6000); }
    var bn = $('banner'); bn.addEventListener('mouseenter', function () { clearInterval(timer); }); bn.addEventListener('mouseleave', restart); bn.addEventListener('focusin', function () { clearInterval(timer); });
    var x0 = null; bn.addEventListener('touchstart', function (e) { x0 = e.touches[0].clientX; clearInterval(timer); }, { passive: true });
    bn.addEventListener('touchend', function (e) { if (x0 != null) { var dx = e.changedTouches[0].clientX - x0; if (Math.abs(dx) > 40) go(cur + (dx < 0 ? 1 : -1), true); else restart(); x0 = null; } }, { passive: true });
    if (offers.length < 2) dots.hidden = true;
    go(0); restart();
  }

  // ---- hero: the shop's 3D model if it has one (poster first, the model only when the browser is idle)
  function hero(m) {
    var poster = safeUrl(m.poster), glb = safeUrl(m.glb), art = $('heroArt');
    if (!poster || !glb) return;
    var img = el('img', 'poster'); img.onerror = function () { img.onerror = null; img.src = poster; }; img.src = poster.replace(/\.webp$/, '-hero.webp'); img.alt = 'A phone from the shop, shown in 3D'; img.fetchPriority = 'high';
    art.replaceWith(img);
    var cap = $('heroCap');
    cap.appendChild(document.createTextNode('Drag to turn it · '));
    if (m.attributionRequired && m.title) { var a = el('a', '', '3D model by ' + (m.author || 'its author') + ', ' + m.license); a.href = safeUrl(m.sourceUrl) || '#'; a.rel = 'noopener'; cap.appendChild(a); }
    var credit = $('modelCredit'); if (credit && m.title) { credit.textContent = ''; var l = el('a', '', m.title + ' by ' + m.author + ', ' + m.license); l.href = safeUrl(m.sourceUrl) || 'credits.html'; credit.appendChild(l); }
    var gl = false; try { var cv = document.createElement('canvas'); gl = !!(cv.getContext('webgl2') || cv.getContext('webgl')); } catch (e) {}
    var saver = navigator.connection && navigator.connection.saveData;
    if (!gl || saver || reduce) return;
    function load() {
      var s = document.createElement('script'); s.type = 'module'; s.src = 'vendor/model-viewer.min.js';
      s.onload = function () {
        try { customElements.get('model-viewer').dracoDecoderLocation = new URL('vendor/draco/', location.href).href; } catch (e) {}
        var mv = document.createElement('model-viewer');
        ['camera-controls', 'auto-rotate', 'disable-zoom', 'interaction-prompt="none"'].forEach(function (a) { mv.setAttribute(a.split('=')[0], ''); });
        mv.setAttribute('environment-image', 'neutral'); mv.setAttribute('shadow-intensity', '1'); mv.setAttribute('alt', 'A phone from the shop, shown in 3D');
        mv.setAttribute('min-camera-orbit', 'auto 70deg auto'); mv.setAttribute('max-camera-orbit', 'auto 100deg auto'); mv.setAttribute('camera-orbit', '150deg 80deg auto');
        mv.setAttribute('src', glb);
        mv.addEventListener('load', function () { mv.classList.add('on'); setTimeout(function () { img.style.opacity = 0; img.style.transition = 'opacity .6s'; }, 300); });
        img.after(mv);
      };
      document.head.appendChild(s);
    }
    (window.requestIdleCallback || function (f) { setTimeout(f, 1200); })(load, { timeout: 3000 });
  }

  fetch('live/shop.json', { cache: 'no-cache' }).then(function (r) { return r.json(); }).then(function (shop) {
    // Brand colours and tagline set from the admin panel's Design Studio.
    var br = shop.brand, hex = /^#[0-9a-fA-F]{6}$/;
    if (br && hex.test(br.accent || '')) document.documentElement.style.setProperty('--accent', br.accent);
    if (br && br.tagline) { var tg = $('brandTag'); var t = br.tagline.en || br.tagline.hi; if (tg && t) tg.textContent = br.tagline.hi && br.tagline.en ? br.tagline.en + ' · ' + br.tagline.hi : t; }
    phones = (shop.products || []).filter(function (p) { return p.category === 'smartphone' && p.active !== false; });
    var real = function (p) { return p.model3d && !p.model3d.generated ? 1 : 0; };
    phones.sort(function (a, b) { return real(b) - real(a) || (b.featured ? 1 : 0) - (a.featured ? 1 : 0); });
    var count = {}; phones.forEach(function (p) { if (p.brand) count[p.brand] = (count[p.brand] || 0) + 1; });
    var brands = Object.keys(count).sort(function (a, b) { return count[b] - count[a] || a.localeCompare(b); });
    var chips = $('brandChips');
    function chip(label, val) {
      var b = el('button', 'chip', label); b.type = 'button'; b.setAttribute('aria-pressed', val === brandSel ? 'true' : 'false');
      b.addEventListener('click', function () { brandSel = val; [].forEach.call(chips.children, function (c) { c.setAttribute('aria-pressed', c === b ? 'true' : 'false'); }); render(); });
      chips.appendChild(b);
    }
    chip('All (' + phones.length + ')', ''); brands.forEach(function (b) { chip(b + ' (' + count[b] + ')', b); });
    render();
    banner((shop.offers || []).filter(function (o) { return o.kind === 'banner' && o.title; }));
    var withModel = phones.filter(real)[0]; if (withModel) hero(withModel.model3d);
  }).catch(function () {
    $('grid').appendChild(el('p', 'empty', 'Open the shop app to see all phones.'));
  });
})();
