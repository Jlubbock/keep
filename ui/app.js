// keep — the only client-side code in the app.
//
// two jobs, both of which have to happen in the browser:
//   1. rendering markdown. the agent must not learn what a page contains,
//      so the reader ships raw source and it is rendered here.
//   2. the live-styled editor. contenteditable has no server-side analogue.
//
// everything else — repost, follow, list membership — is a plain form POST.

(function () {
  'use strict';

  // ---- markdown ---------------------------------------------------------

  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function inline(s) {
    return esc(s)
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/(^|[^*])\*([^*]+)\*/g, '$1<em>$2</em>')
      .replace(/`(.+?)`/g, '<code>$1</code>')
      .replace(/\[(.+?)\]\((.+?)\)/g, '<a href="$2">$1</a>');
  }

  function md(src) {
    var out = [], ul = false;
    function close() { if (ul) { out.push('</ul>'); ul = false; } }
    src.split('\n').forEach(function (line) {
      var t = line.trim();
      if (!t) { close(); return; }
      if (/^###\s/.test(t)) { close(); out.push('<h3>' + inline(t.slice(4)) + '</h3>'); return; }
      if (/^##\s/.test(t)) { close(); out.push('<h2>' + inline(t.slice(3)) + '</h2>'); return; }
      if (/^#\s/.test(t)) { close(); out.push('<h1>' + inline(t.slice(2)) + '</h1>'); return; }
      if (/^>\s?/.test(t)) {
        close();
        out.push('<blockquote>' + inline(t.replace(/^>\s?/, '')) + '</blockquote>');
        return;
      }
      if (/^[-*]\s/.test(t)) {
        if (!ul) { out.push('<ul>'); ul = true; }
        out.push('<li>' + inline(t.slice(2)) + '</li>');
        return;
      }
      close();
      out.push('<p>' + inline(t) + '</p>');
    });
    close();
    return out.join('');
  }

  // ---- reader -----------------------------------------------------------
  //
  // a body that is not in `seen` yet means the keen is still outstanding.
  // the page renders blank rather than faking a loading state; this re-asks
  // until it lands, then fills it in without a visible reload.

  // default to markdown: if data-mark never made it through sail, falling
  // back to <pre> would render every article flat, which is worse than
  // rendering an unexpected mark as prose.
  function paint(target, src, mark) {
    var m = mark || 'md';
    target.innerHTML = (m === 'md') ? md(src) : '<pre>' + esc(src) + '</pre>';
  }

  function reader() {
    var target = document.getElementById('k-body');
    if (!target) return;
    var src = document.getElementById('k-src');
    if (src) { paint(target, src.textContent, src.dataset.mark); return; }

    var tries = 0;
    var tick = function () {
      if (++tries > 40) return;
      fetch(window.location.pathname, { credentials: 'same-origin' })
        .then(function (r) { return r.text(); })
        .then(function (html) {
          var doc = new DOMParser().parseFromString(html, 'text/html');
          var got = doc.getElementById('k-src');
          if (!got) { setTimeout(tick, 900); return; }
          paint(target, got.textContent, got.dataset.mark);
        })
        .catch(function () { setTimeout(tick, 1800); });
    };
    setTimeout(tick, 600);
  }

  // ---- editor -----------------------------------------------------------

  var TOKEN = /^(#{1,3} |> ?|[-*] )/;

  // textContent drops <br>, so a line the browser kept as `a<br>b` would
  // arrive as one line and render as one flat paragraph. walk it instead.
  function textOf(n) {
    var out = '';
    Array.prototype.slice.call(n.childNodes).forEach(function (c) {
      if (c.nodeType === 3) out += c.textContent;
      else if (c.nodeName === 'BR') out += '\n';
      else if (c.dataset && c.dataset.hide === '1') return;
      else out += textOf(c);
    });
    return out;
  }

  function rawOf(n) {
    if (n.dataset && n.dataset.decor) return n.dataset.raw || '';
    // an empty line is <div><br></div>: one trailing break, not a new line
    return textOf(n).replace(/\n$/, '');
  }

  function visibleOffset(n) {
    var sel = window.getSelection();
    if (!sel || !sel.anchorNode || !n.contains(sel.anchorNode)) return null;
    var off = 0, done = false;
    function walk(node) {
      if (done) return;
      if (node.nodeType === 3) {
        if (node === sel.anchorNode) { off += sel.anchorOffset; done = true; }
        else off += node.textContent.length;
        return;
      }
      if (node.nodeType === 1 && node.dataset.hide === '1') return;
      Array.prototype.slice.call(node.childNodes).forEach(walk);
    }
    Array.prototype.slice.call(n.childNodes).forEach(walk);
    return done ? off : null;
  }

  function setCaret(n, offset) {
    var t = n.firstChild;
    if (!t || t.nodeType !== 3) return;
    var r = document.createRange();
    r.setStart(t, Math.max(0, Math.min(offset, t.textContent.length)));
    r.collapse(true);
    var sel = window.getSelection();
    sel.removeAllRanges();
    sel.addRange(r);
  }

  function lineClass(raw) {
    var t = raw.trim();
    if (/^###\s/.test(t)) return 'h3';
    if (/^##\s/.test(t)) return 'h2';
    if (/^#\s/.test(t)) return 'h1';
    if (/^>/.test(t)) return 'quote';
    if (/^[-*]\s/.test(t)) return 'item';
    return '';
  }

  function styleLines(el) {
    var sel = window.getSelection();
    Array.prototype.slice.call(el.children).forEach(function (n) {
      var raw = rawOf(n);
      var pm = raw.match(TOKEN);
      var prefix = pm ? pm[1] : '';
      var active = !!(sel && sel.anchorNode && n.contains(sel.anchorNode));

      if (active && n.dataset.decor) {
        var vis = visibleOffset(n);
        var plen = n.dataset.plen ? +n.dataset.plen : 0;
        delete n.dataset.decor;
        n.textContent = raw;
        if (!raw) n.innerHTML = '<br>';
        if (vis !== null) setCaret(n, vis + plen);
        delete n.dataset.plen;
      } else if (!active && prefix && !n.dataset.decor) {
        var rest = raw.slice(prefix.length);
        n.dataset.raw = raw;
        n.dataset.decor = '1';
        n.dataset.plen = String(prefix.length);
        n.innerHTML = '';
        if (/^[-*] /.test(prefix)) {
          var b = document.createElement('span');
          b.contentEditable = 'false';
          b.dataset.hide = '1';
          b.className = 'bullet';
          b.textContent = '•';
          n.appendChild(b);
        }
        var h = document.createElement('span');
        h.dataset.hide = '1';
        h.className = 'tok';
        h.textContent = prefix;
        n.appendChild(h);
        n.appendChild(document.createTextNode(rest || '​'));
      } else if (!active && !prefix && n.dataset.decor) {
        delete n.dataset.decor;
        delete n.dataset.plen;
        n.textContent = raw;
        if (!raw) n.innerHTML = '<br>';
      }

      n.className = lineClass(raw);
    });
  }

  // childNodes, not children: a browser may leave typed text as a bare text
  // node beside the line divs, and .children would silently drop it.
  function source(el) {
    var out = [];
    Array.prototype.slice.call(el.childNodes).forEach(function (n) {
      if (n.nodeType === 3) { out.push(n.textContent); return; }
      if (n.nodeName === 'BR') { out.push(''); return; }
      out.push(rawOf(n));
    });
    return out.join('\n').replace(/​/g, '');
  }

  function words(src) {
    var bare = src.replace(TOKEN, ' ')
      .replace(/^(#{1,3} |> ?|[-*] )/gm, ' ')
      .replace(/[•​]/g, ' ');
    var m = bare.match(/\S+/g);
    return m ? m.length : 0;
  }

  // the title is the LEADING h1 and it is lifted out of the body, so the
  // reader shows it once. a # further down is a real heading and stays put;
  // prose before any heading means the post has no title.
  function split(src) {
    var lines = src.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var m = lines[i].match(/^#\s+(.*\S)/);
      if (m) {
        var rest = lines.slice(0, i).concat(lines.slice(i + 1));
        while (rest.length && !rest[0].trim()) rest.shift();
        var body = rest.join('\n').trim();
        return { title: m[1], body: body || lines[i] };
      }
      if (lines[i].trim()) break;
    }
    return { title: '', body: src.trim() };
  }

  function form(fields) {
    return Object.keys(fields).map(function (k) {
      return encodeURIComponent(k) + '=' + encodeURIComponent(fields[k]);
    }).join('&');
  }

  // the canvas opens on an empty h1, so the first line you type is the
  // title and looks like one before you have typed it. this is the only
  // place titles come from — there is no title field, by design.
  function seed(el) {
    el.innerHTML = '';
    var d = document.createElement('div');
    d.textContent = '# ';
    d.className = 'h1';
    el.appendChild(d);
    el.focus();
    setCaret(d, 2);
  }

  function editor() {
    var el = document.getElementById('k-ed');
    if (!el) return;

    if (!el.children.length) seed(el);

    var count = document.getElementById('k-words');
    var send = document.getElementById('k-send');
    var audience = document.getElementById('k-audience');

    var refresh = function () {
      styleLines(el);
      if (count) {
        var n = words(source(el));
        count.textContent = n === 1 ? '1 word' : n + ' words';
      }
    };

    el.addEventListener('input', refresh);
    document.addEventListener('selectionchange', function () {
      if (document.activeElement === el) refresh();
    });

    Array.prototype.slice.call(document.querySelectorAll('.k-to a')).forEach(function (a) {
      a.addEventListener('click', function (e) {
        e.preventDefault();
        audience.value = a.dataset.to;
        Array.prototype.slice.call(document.querySelectorAll('.k-to a'))
          .forEach(function (o) { o.classList.remove('on'); });
        a.classList.add('on');
      });
    });

    if (send) {
      send.addEventListener('click', function (e) {
        e.preventDefault();
        var src = source(el).trim();
        if (!src) return;
        var parts = split(src);
        send.textContent = '…';
        fetch('/keep/write', {
          method: 'POST',
          credentials: 'same-origin',
          headers: { 'content-type': 'application/x-www-form-urlencoded' },
          body: form({
            what: 'publish',
            body: parts.body,
            title: parts.title,
            to: audience.value
          })
        }).then(function (r) {
          send.textContent = r.ok ? 'sent' : 'failed';
          if (r.ok) { seed(el); refresh(); }
        }).catch(function () { send.textContent = 'failed'; });
      });
    }

    refresh();
  }

  // ---- check ------------------------------------------------------------
  //
  // whether a ship runs %keep can only be answered by a poke, and the ack
  // lands in a later event. so: send it, then re-ask this page until the
  // rendered state stops saying `unknown`, and show the answer. no reload
  // by hand, and no fake result while we wait.

  function checker() {
    var f = document.querySelector('form.k-check');
    if (!f) return;
    var btn = f.querySelector('button');
    var who = f.querySelector('[name=who]').value;
    var tries = 0;

    function settled(doc) {
      var note = doc.querySelector('.k-note');
      return !note || note.dataset.state !== 'unknown';
    }

    function wait() {
      if (++tries > 20) { btn.textContent = 'asked'; return; }
      setTimeout(function () {
        fetch(window.location.pathname, { credentials: 'same-origin' })
          .then(function (r) { return r.text(); })
          .then(function (html) {
            var doc = new DOMParser().parseFromString(html, 'text/html');
            if (settled(doc)) { window.location.reload(); return; }
            wait();
          })
          .catch(wait);
      }, 900);
    }

    f.addEventListener('submit', function (e) {
      e.preventDefault();
      btn.textContent = 'checking';
      fetch('/keep', {
        method: 'POST',
        credentials: 'same-origin',
        headers: { 'content-type': 'application/x-www-form-urlencoded' },
        body: form({ what: 'check', who: who, back: '' })
      }).then(wait).catch(function () { btn.textContent = 'failed'; });
    });
  }

  // ---- lists ------------------------------------------------------------
  // single-input forms submit on Enter natively; this only stops the empty
  // submit that would otherwise nack.

  function lists() {
    Array.prototype.slice.call(document.querySelectorAll('form.k-one')).forEach(function (f) {
      f.addEventListener('submit', function (e) {
        var input = f.querySelector('input[type=text]');
        if (input && !input.value.trim()) e.preventDefault();
      });
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    reader();
    editor();
    checker();
    lists();
  });
})();
