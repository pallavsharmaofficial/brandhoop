/* Offline-first layer for the admin panel.
   * The last shop file from GitHub is kept on the phone, so the panel opens with no signal.
   * Every change is saved on the phone as a draft (IndexedDB), photos included, so closing the app or losing signal loses nothing.
   * "प्रकाशित करें" with no signal is queued; when the signal returns it is sent by itself.
   * If the file on GitHub changed in the meantime, the owner's changes are merged into the newer file item by item
   * (a three-way merge); if both sides changed the same field, the owner's value is kept and a note says so. */
(function () {
  'use strict';
  var A = window.AdminAPI; if (!A) return;
  var $ = function (id) { return document.getElementById(id); };
  var S = { queued: false, busy: false, timer: 0 };

  /* ---------- tiny IndexedDB key-value store ---------- */
  var dbp = null;
  function db() {
    if (dbp) return dbp;
    dbp = new Promise(function (ok, no) {
      var r = indexedDB.open('brandhoopAdmin', 1);
      r.onupgradeneeded = function () { r.result.createObjectStore('kv'); };
      r.onsuccess = function () { ok(r.result); }; r.onerror = function () { no(r.error); };
    });
    return dbp;
  }
  function kv(mode, fn) { return db().then(function (d) { return new Promise(function (ok, no) { var t = d.transaction('kv', mode), s = t.objectStore('kv'), q = fn(s); t.oncomplete = function () { ok(q && q.result); }; t.onerror = function () { no(t.error); }; }); }); }
  var get = function (k) { return kv('readonly', function (s) { return s.get(k); }).catch(function () { return undefined; }); };
  var put = function (k, v) { return kv('readwrite', function (s) { return s.put(v, k); }).catch(function () { }); };
  var del = function (k) { return kv('readwrite', function (s) { return s.delete(k); }).catch(function () { }); };

  /* ---------- three-way merge ---------- */
  var eq = function (a, b) { return JSON.stringify(a) === JSON.stringify(b); };
  function mergeObj(base, mine, theirs, notes, label) {
    var out = Object.assign({}, theirs), keys = {};
    [base, mine, theirs].forEach(function (o) { Object.keys(o || {}).forEach(function (k) { keys[k] = 1; }); });
    Object.keys(keys).forEach(function (k) {
      var b = base && base[k], m = mine && mine[k], t = theirs && theirs[k];
      if (eq(m, b)) { if (t === undefined) delete out[k]; else out[k] = t; }
      else if (eq(t, b)) { if (m === undefined) delete out[k]; else out[k] = m; }
      else { if (!eq(m, t)) notes.push(label + ': “' + k + '” दोनों जगह बदला था, आपका वाला रखा'); if (m === undefined) delete out[k]; else out[k] = m; }
    });
    return out;
  }
  function mergeList(base, mine, theirs, keyOf, nameOf, notes) {
    var B = {}, M = {}, T = {}, out = [];
    (base || []).forEach(function (x) { B[keyOf(x)] = x; }); (mine || []).forEach(function (x) { M[keyOf(x)] = x; }); (theirs || []).forEach(function (x) { T[keyOf(x)] = x; });
    (mine || []).forEach(function (x) { var k = keyOf(x); if (!(k in B) && !(k in T)) out.push(x); });                       // added by the owner
    (theirs || []).forEach(function (x) {
      var k = keyOf(x), b = B[k], m = M[k];
      if (!(k in B)) { if (k in M && !eq(m, x)) { notes.push(nameOf(x) + ': दोनों ने जोड़ा, आपका वाला रखा'); out.push(m); } else out.push(x); return; }
      if (!(k in M)) { if (eq(x, b)) return; notes.push(nameOf(x) + ': आपने हटाया था पर किसी और ने बदला था, इसलिए रखा'); out.push(x); return; }
      if (eq(m, b)) { out.push(x); return; }
      if (eq(x, b)) { out.push(m); return; }
      out.push(mergeObj(b, m, x, notes, nameOf(x)));
    });
    (mine || []).forEach(function (x) { var k = keyOf(x); if (k in B && !(k in T) && !eq(x, B[k])) { notes.push(nameOf(x) + ': किसी ने हटाया था पर आपने बदला था, इसलिए रखा'); out.push(x); } });
    return out;
  }
  function merge(base, mine, theirs) {
    var notes = [], out = Object.assign({}, theirs), done = { products: 1, offers: 1, gallery: 1 };
    out.products = mergeList(base.products, mine.products, theirs.products, function (p) { return p.id; }, function (p) { return (p.name && p.name.en) || p.id; }, notes);
    out.offers = mergeList(base.offers, mine.offers, theirs.offers, function (o) { return o.id; }, function (o) { return (o.title && o.title.en) || o.id; }, notes);
    out.gallery = mergeList(base.gallery, mine.gallery, theirs.gallery, function (g) { return g.url; }, function (g) { return g.url.split('/').pop(); }, notes);
    var keys = {}; [base, mine, theirs].forEach(function (o) { Object.keys(o || {}).forEach(function (k) { keys[k] = 1; }); });
    Object.keys(keys).forEach(function (k) {
      if (done[k]) return; var b = base[k], m = mine[k], t = theirs[k], isObj = function (x) { return x && typeof x === 'object' && !Array.isArray(x); };
      if (isObj(m) || isObj(t) || isObj(b)) out[k] = mergeObj(b || {}, m || {}, t || {}, notes, k);
      else if (eq(m, b)) { if (t === undefined) delete out[k]; else out[k] = t; } else { if (m === undefined) delete out[k]; else out[k] = m; }
    });
    return { shop: out, notes: notes };
  }

  /* ---------- draft and cache ---------- */
  function saveCache(f) { return put('cache', { sha: f.sha, text: f.text, at: Date.now() }); }
  function loadCache() { return get('cache'); }
  function draftNow() {
    var st = A.state();
    return put('draft', { shop: st.shop, baseSha: st.baseSha, baseText: st.baseText, dirty: A.dirty(), queued: S.queued, photos: Array.from(st.pending.entries()), at: Date.now() });
  }
  function changed() { clearTimeout(S.timer); S.timer = setTimeout(function () { if (A.dirty() || S.queued) draftNow(); else del('draft'); badge(); }, 250); badge(); }
  function restoreDraft() {
    return get('draft').then(function (d) {
      if (!d || !d.dirty) return { restored: false, notes: [] };
      var st = A.state(), notes = [], shop = d.shop;
      if (d.baseSha !== st.baseSha) { var r = merge(JSON.parse(d.baseText), d.shop, st.shop); shop = r.shop; notes = r.notes; }
      (d.photos || []).forEach(function (e) { st.pending.set(e[0], e[1]); });
      A.setShop(shop); S.queued = !!d.queued; return { restored: true, notes: notes };
    });
  }

  /* ---------- sending ---------- */
  function usedFiles(shop) {
    var u = new Set([].concat(shop.products.map(function (p) { return p.imageUrls || []; }).reduce(function (a, b) { return a.concat(b); }, []), (shop.gallery || []).map(function (g) { return g.url; }), shop.offers.map(function (o) { return o.imageUrl; }), (shop.designs || []).map(function (d) { return d.photoUrl; })).filter(Boolean).map(function (x) { return x.split('/').pop(); }));
    return u;
  }
  async function publish() {
    A.readShop(); var bad = A.problems(); if (bad.length) return A.say('पहले ठीक करें: ' + bad.join(' · '), 'bad');
    if (!navigator.onLine) { S.queued = true; await draftNow(); badge(); return A.say('अभी इंटरनेट नहीं है। बदलाव फ़ोन में सुरक्षित हैं, नेट आते ही अपने-आप प्रकाशित हो जाएँगे।', 'info'); }
    if (S.busy) return; S.busy = true; $('publish').disabled = true; var notes = [];
    try {
      for (var attempt = 0; attempt < 3; attempt++) {
        A.say('जाँच रहे हैं…'); var st = A.state(), latest = await A.fetchShop();
        if (latest.sha !== st.baseSha) { var r = merge(JSON.parse(st.baseText), st.shop, JSON.parse(latest.text)); notes = notes.concat(r.notes); A.setShop(r.shop); A.setBase(latest.sha, latest.text); }
        st = A.state(); var used = usedFiles(st.shop), n = 0, total = Array.from(st.pending.keys()).filter(function (k) { return used.has(k); }).length;
        for (var entry of Array.from(st.pending.entries())) {
          var name = entry[0], img = entry[1];
          if (!used.has(name)) { st.pending.delete(name); continue; }
          A.say('फ़ोटो भेज रहे हैं… ' + (++n) + '/' + total); await A.gh('PUT', (img.dir || A.IMG_DIR) + '/' + name, { message: 'Shop photo (admin panel)', content: img.b64, branch: A.BRANCH }); st.pending.delete(name);
        }
        A.say('प्रकाशित हो रहा है…'); var text = JSON.stringify(st.shop, null, 2) + '\n';
        try { var res = await A.gh('PUT', A.FILE, { message: 'Shop update (admin panel)', content: A.utf8ToB64(text), sha: st.baseSha, branch: A.BRANCH }); A.setBase(res.content.sha, text); break; }
        catch (e) { if ((e.status === 409 || e.status === 422) && attempt < 2) continue; throw e; }
      }
      S.queued = false; A.clean(); await del('draft'); var fin = A.state(); await saveCache({ sha: fin.baseSha, text: fin.baseText });
      A.say('✓ प्रकाशित हो गया। ऐप में 1–5 मिनट में दिखेगा (ऐप दोबारा खोलें)।' + (notes.length ? ' ध्यान दें: ' + notes.join('; ') : ''), 'ok');
    } catch (e) {
      if (!e.status) { S.queued = true; await draftNow(); A.say('नेट चला गया। बदलाव फ़ोन में सुरक्षित हैं, नेट आते ही फिर से भेज दूँगा।', 'info'); }
      else A.say('प्रकाशित नहीं हुआ: ' + A.explain(e), 'bad');
    } finally { S.busy = false; $('publish').disabled = !A.dirty(); badge(); }
  }

  /* ---------- the little status light in the header ---------- */
  function badge() {
    var b = $('netBadge'); if (!b) return; var on = navigator.onLine, d = A.dirty();
    var t = S.queued ? '⏳ नेट आते ही प्रकाशित होगा' : on ? (d ? '● ऑनलाइन · प्रकाशित करना बाकी' : '● ऑनलाइन') : (d ? '○ ऑफ़लाइन · बदलाव फ़ोन में सेव' : '○ ऑफ़लाइन');
    b.textContent = t; b.style.background = S.queued ? '#EF6C00' : on ? '#2E7D32' : '#566170';
  }
  function tick() { badge(); if (S.queued && navigator.onLine && !S.busy && A.signedIn()) publish(); }
  window.addEventListener('online', tick); window.addEventListener('offline', badge);
  setInterval(tick, 30000);

  window.Sync = { merge: merge, saveCache: saveCache, loadCache: loadCache, restoreDraft: restoreDraft, changed: changed, publish: publish, badge: badge, queued: function () { return S.queued; }, tick: tick };
  badge();
})();
