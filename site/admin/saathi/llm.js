/* The two AI helpers Saathi can use for advice. Both only talk; neither can change shop data.
   SaathiLLM: a small model that runs on the phone's GPU (WebLLM). It is loaded only when the owner taps the button in Saathi's settings.
              The model files (0.4 to 1.6 GB) download once and stay in the browser's storage. Works with no internet. Needs WebGPU.
   SaathiCloud: the Claude API, called straight from the phone with a key the owner types in (kept on the phone, sealed with the PIN).
              Used only when there is internet, and rested for five minutes after a failure or slow start. */
(function () {
  'use strict';
  var URL_ = 'https://cdn.jsdelivr.net/npm/@mlc-ai/web-llm@0.2.89/+esm', engine = null, loading = null;
  window.SaathiLLM = {
    supported: function () { return !!navigator.gpu; },
    ready: function () { return !!engine; },
    load: function (modelId, onProgress) {
      if (loading) return loading;
      loading = import(URL_).then(function (webllm) {
        return webllm.CreateMLCEngine(modelId, { initProgressCallback: function (p) { if (onProgress) onProgress((p && p.text) || 'डाउनलोड हो रहा है…'); } });
      }).then(function (e) { engine = e; loading = null; }, function (err) { loading = null; throw err; });
      return loading;
    },
    ask: function (messages, onToken) {
      if (!engine) return Promise.reject(new Error('मॉडल चालू नहीं है'));
      return engine.chat.completions.create({ messages: messages, stream: true, temperature: 0.4, max_tokens: 450 }).then(async function (stream) {
        for await (var chunk of stream) { var d = chunk.choices[0] && chunk.choices[0].delta && chunk.choices[0].delta.content; if (d) onToken(d); }
      });
    }
  };
  window.SaathiCloud = {
    ask: async function (o) {
      var ctl = new AbortController(), got = false, to = setTimeout(function () { if (!got) ctl.abort(); }, o.timeoutMs || 9000), r;
      try {
        r = await fetch('https://api.anthropic.com/v1/messages', {
          method: 'POST', signal: ctl.signal,
          headers: { 'content-type': 'application/json', 'x-api-key': o.key, 'anthropic-version': '2023-06-01', 'anthropic-dangerous-direct-browser-access': 'true' },
          body: JSON.stringify({ model: o.model, max_tokens: 500, system: o.system, messages: o.messages, stream: true })
        });
        if (!r.ok) { var j = null; try { j = await r.json(); } catch (e) { } var err = new Error((j && j.error && j.error.message) || r.statusText); err.status = r.status; throw err; }
        var rd = r.body.getReader(), dec = new TextDecoder(), buf = '';
        for (;;) {
          var x = await rd.read(); if (x.done) break; buf += dec.decode(x.value, { stream: true });
          var parts = buf.split('\n\n'); buf = parts.pop();
          parts.forEach(function (p) {
            p.split('\n').forEach(function (line) {
              if (line.indexOf('data:') !== 0) return;
              try { var ev = JSON.parse(line.slice(5)); if (ev.type === 'content_block_delta' && ev.delta && ev.delta.type === 'text_delta') { if (!got) { got = true; clearTimeout(to); } o.onToken(ev.delta.text); } } catch (e) { }
            });
          });
        }
      } finally { clearTimeout(to); }
    }
  };
})();
