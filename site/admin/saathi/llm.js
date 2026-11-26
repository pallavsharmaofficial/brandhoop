/* Optional on-device language model for Saathi's coaching answers (WebLLM, runs in the browser on the phone's GPU).
   It is loaded only when the owner taps the button in Saathi's settings. The model files (about 0.4 to 1.6 GB) download once and are
   kept in the browser's storage. Nothing the owner types is sent to a server by this code. It needs a browser with WebGPU. */
(function () {
  'use strict';
  var URL_ = 'https://cdn.jsdelivr.net/npm/@mlc-ai/web-llm@0.2.89/+esm', engine = null;
  window.SaathiLLM = {
    supported: function () { return !!navigator.gpu; },
    ready: function () { return !!engine; },
    load: function (modelId, onProgress) {
      return import(URL_).then(function (webllm) {
        return webllm.CreateMLCEngine(modelId, { initProgressCallback: function (p) { if (onProgress) onProgress((p && p.text) || 'डाउनलोड हो रहा है…'); } });
      }).then(function (e) { engine = e; });
    },
    ask: function (messages, onToken) {
      if (!engine) return Promise.reject(new Error('मॉडल चालू नहीं है'));
      return engine.chat.completions.create({ messages: messages, stream: true, temperature: 0.4, max_tokens: 400 }).then(async function (stream) {
        for await (var chunk of stream) { var d = chunk.choices[0] && chunk.choices[0].delta && chunk.choices[0].delta.content; if (d) onToken(d); }
      });
    }
  };
})();
