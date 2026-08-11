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

  // " and ' too, not just the tag characters: a link url is interpolated
  // into href="…", where an unescaped quote closes the attribute and the
  // rest of the url becomes markup — an onmouseover= on our own origin
  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  }

  // browsers strip control characters and whitespace before reading the
  // scheme, so `java\tscript:` is javascript: — strip them here as well
  var SCHEME = /^([a-z][a-z0-9+.\-]*):/i;
  var ALLOWED = { 'http': 1, 'https': 1, 'mailto': 1 };

  // null for a url we will not link: an unknown scheme renders as plain
  // text rather than a dead href, which would swallow the click
  function href(url) {
    // esc() ran first, so a raw < here is injected markup, never author text
    if (/[<>]/.test(url)) return null;
    var bare = url.replace(/[\u0000-\u0020]/g, '');
    var got = SCHEME.exec(bare);
    if (!got) return url;
    return ALLOWED[got[1].toLowerCase()] ? url : null;
  }

  // passes run in binding order — code, escapes, links, emphasis — and each
  // resolved piece parks in a NUL-fenced slot no later pass can re-enter
  function inline(s) {
    var NUL = String.fromCharCode(0);
    var slots = [];
    function keep(html) { slots.push(html); return NUL + (slots.length - 1) + NUL; }
    s = s.split(NUL).join('');
    s = s.replace(/`([^`]+)`/g, function (_, code) {
      return keep('<code>' + esc(code) + '</code>');
    });
    s = s.replace(/\\([!-\/:-@\[-`{-~])/g, function (_, c) { return keep(esc(c)); });
    s = esc(s);
    s = s.replace(
      /!?\[([^\[\]]+)\]\(\s*((?:[^\s()]|\([^\s()]*\))*)(?:\s+(?:&quot;(.*?)&quot;|&#39;(.*?)&#39;))?\s*\)/g,
      function (_, text, url, dq, sq) {
        var to = href(url);
        if (to === null) return text;
        var title = dq || sq || '';
        return keep('<a href="' + to + '"' + (title ? ' title="' + title + '"' : '') + '>') +
          text + keep('</a>');
      });
    s = s.replace(/\*\*\*(\S(?:.*?\S)?)\*\*\*/g, '<em><strong>$1</strong></em>');
    s = s.replace(/\*\*(\S(?:.*?\S)?)\*\*/g, '<strong>$1</strong>');
    s = s.replace(/(^|[^*])\*([^\s*](?:[^*]*?[^\s*])?)\*/g, '$1<em>$2</em>');
    while (s.indexOf(NUL) !== -1) {
      s = s.replace(new RegExp(NUL + '(\\d+)' + NUL, 'g'), function (_, i) { return slots[+i]; });
    }
    return s;
  }

  // standard breaks: consecutive lines are one paragraph with line breaks
  // inside it; a blank line ends the paragraph and yields the paragraph gap
  function md(src) {
    var out = [], ul = false, para = [];
    function close() {
      if (ul) { out.push('</ul>'); ul = false; }
      if (para.length) { out.push('<p>' + para.join('<br>') + '</p>'); para = []; }
    }
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
        if (para.length) close();
        if (!ul) { out.push('<ul>'); ul = true; }
        out.push('<li>' + inline(t.slice(2)) + '</li>');
        return;
      }
      if (ul) close();
      para.push(inline(t));
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

  // ---- comments -----------------------------------------------------------
  //
  // note bodies are markdown and render here, like the article body: the
  // source ships in a hidden .k-note-src beside its .k-note-body target.
  // a submitted comment lands asynchronously — locally in the next event,
  // remotely when the host's next /talk revision keens back — so posting
  // polls this page's own HTML and swaps the section in when it grows.

  function talkPaint() {
    Array.prototype.slice.call(document.querySelectorAll('.k-cmt-src')).forEach(function (s) {
      var t = s.nextElementSibling;
      if (t && t.classList.contains('k-cmt-body')) t.innerHTML = md(s.textContent);
    });
  }

  function talkSwap(section) {
    var mine = document.querySelector('section.k-talk');
    if (!mine) return;
    mine.parentNode.replaceChild(document.importNode(section, true), mine);
    talk();
  }

  function talkWait(had, tries) {
    if (tries > 40) return;
    setTimeout(function () {
      fetch(window.location.pathname, { credentials: 'same-origin' })
        .then(function (r) { return r.text(); })
        .then(function (html) {
          var doc = new DOMParser().parseFromString(html, 'text/html');
          var got = doc.querySelector('section.k-talk');
          if (got && got.querySelectorAll('.k-cmt').length > had) { talkSwap(got); return; }
          talkWait(had, tries + 1);
        })
        .catch(function () { talkWait(had, tries + 1); });
    }, 900);
  }

  function talk() {
    talkPaint();
    Array.prototype.slice.call(document.querySelectorAll('form.k-snip-form')).forEach(function (f) {
      f.addEventListener('submit', function (e) {
        if (!window.confirm('delete this comment?')) e.preventDefault();
      });
    });
    Array.prototype.slice.call(document.querySelectorAll('form.k-ban-form')).forEach(function (f) {
      f.addEventListener('submit', function (e) {
        var who = f.querySelector('[name=who]').value;
        if (!window.confirm('ban ' + who + ' from commenting? their comments stay until deleted.')) e.preventDefault();
      });
    });
    Array.prototype.slice.call(document.querySelectorAll('form.k-say')).forEach(function (f) {
      f.addEventListener('submit', function (e) {
        e.preventDefault();
        var body = f.querySelector('[name=body]');
        if (!body || !body.value.trim()) return;
        var btn = f.querySelector('button');
        btn.textContent = '…';
        var fields = {};
        Array.prototype.slice.call(f.elements).forEach(function (el) {
          if (el.name) fields[el.name] = el.value;
        });
        var had = document.querySelectorAll('.k-cmt').length;
        fetch('/keep', {
          method: 'POST',
          credentials: 'same-origin',
          headers: { 'content-type': 'application/x-www-form-urlencoded' },
          body: form(fields)
        }).then(function (r) {
          if (!r.ok) { btn.textContent = 'failed'; return; }
          talkWait(had, 0);
        }).catch(function () { btn.textContent = 'failed'; });
      });
    });
  }

  // ---- editor -----------------------------------------------------------

  var TOKEN = /^(#{1,3} |> ?|[-*] )/;

  // the DOM is the source of truth: hidden .tok spans hold real raw chars
  // (count them), the bullet glyph does not (skip it). a merge from a
  // deleted neighbour line then reads back correctly with no stale cache.
  function textOf(n) {
    // no element children means no BRs, toks, or bullets to special-case,
    // and native textContent beats the walk — most lines take this path
    if (!n.firstElementChild) return n.textContent;
    var out = '';
    Array.prototype.slice.call(n.childNodes).forEach(function (c) {
      if (c.nodeType === 3) out += c.textContent;
      else if (c.nodeName === 'BR') out += '\n';
      else if (c.classList && c.classList.contains('bullet')) return;
      else out += textOf(c);
    });
    return out;
  }

  // an empty line is <div><br></div>: one trailing break, not a new line
  function rawOf(n) {
    return textOf(n).replace(/\n$/, '').replace(/​/g, '');
  }

  // decorated lines keep every raw char in the DOM — markers in hidden .tok
  // spans — so counting hidden text (but not the bullet glyph, which is not
  // raw) turns the caret's visible position into an exact raw offset
  function rawCaret(n) {
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
      if (node.nodeName === 'BR') { off += 1; return; }
      if (node.nodeType === 1 && node.classList.contains('bullet')) return;
      Array.prototype.slice.call(node.childNodes).forEach(walk);
    }
    Array.prototype.slice.call(n.childNodes).forEach(walk);
    return done ? off : null;
  }

  // inverse of rawCaret: the visible text node holding raw offset `target`,
  // counting hidden marker text without ever landing the caret inside it
  function setCaretRaw(n, target) {
    var node = null, off = 0, last = null, acc = 0;
    function walk(c) {
      if (node) return;
      if (c.nodeType === 3) {
        last = c;
        if (acc + c.textContent.length >= target) { node = c; off = target - acc; }
        else acc += c.textContent.length;
        return;
      }
      if (c.nodeType !== 1) return;
      if (c.classList.contains('bullet')) return;
      if (c.classList.contains('tok')) { acc += c.textContent.length; return; }
      Array.prototype.slice.call(c.childNodes).forEach(walk);
    }
    Array.prototype.slice.call(n.childNodes).forEach(walk);
    var r = document.createRange();
    if (node) r.setStart(node, Math.max(0, Math.min(off, node.textContent.length)));
    else if (last) r.setStart(last, last.textContent.length);
    else r.setStart(n, 0);
    r.collapse(true);
    var sel = window.getSelection();
    sel.removeAllRanges();
    sel.addRange(r);
  }

  // a cleared canvas takes typed text as a bare node beside the line divs,
  // and a bare node cannot carry a line class — box it before styling
  function normalize(el) {
    var sel = window.getSelection();
    var focus = sel && sel.anchorNode;
    var focusOff = sel ? sel.anchorOffset : 0;
    var moved = false;
    Array.prototype.slice.call(el.childNodes).forEach(function (n) {
      if (n.nodeType !== 3 && n.nodeName !== 'BR') return;
      var d = document.createElement('div');
      el.replaceChild(d, n);
      d.appendChild(n);
      if (n === focus) moved = true;
    });
    if (moved) {
      var r = document.createRange();
      r.setStart(focus, focusOff);
      r.collapse(true);
      sel.removeAllRanges();
      sel.addRange(r);
    }
    // pasted text can land as one div with <br>s inside; give each source
    // line its own div, or several lines style, break, and publish as one
    Array.prototype.slice.call(el.children).forEach(function (n) {
      if (!n.firstElementChild) return;
      if (!n.querySelector('br')) return;
      var raw = rawOf(n);
      if (raw.indexOf('\n') === -1) return;
      var at = rawCaret(n);
      var caretDiv = null, caretOff = 0, seen = 0;
      raw.split('\n').forEach(function (part) {
        var d = document.createElement('div');
        if (part) d.textContent = part;
        else d.innerHTML = '<br>';
        el.insertBefore(d, n);
        if (at !== null && !caretDiv && at <= seen + part.length) {
          caretDiv = d;
          caretOff = at - seen;
        }
        seen += part.length + 1;
      });
      el.removeChild(n);
      if (caretDiv) setCaretRaw(caretDiv, caretOff);
    });
  }

  function tok(s) {
    var h = document.createElement('span');
    h.className = 'tok';
    h.textContent = s;
    return h;
  }

  // inline tokens in the reader's binding order: code, escapes, links,
  // emphasis. `open` is the leading marker length; s..e span the raw text.
  function scanInline(raw) {
    var segs = [], i = 0, from = 0, prev = '';
    function text(end) { if (from < end) segs.push({ kind: 'text', s: from, e: end }); }
    while (i < raw.length) {
      var rest = raw.slice(i), m = null, seg = null;
      if ((m = /^`([^`]+)`/.exec(rest))) seg = { kind: 'code', body: m[1], open: 1 };
      else if ((m = /^\\([!-\/:-@\[-`{-~])/.exec(rest))) seg = { kind: 'esc', body: m[1], open: 1 };
      else if ((m = /^!?\[([^\[\]]+)\]\((?:[^\s()]|\([^\s()]*\))*(?:\s+(?:"[^"]*"|'[^']*'))?\)/.exec(rest)))
        seg = { kind: 'link', body: m[1], open: m[0].indexOf('[') + 1 };
      else if ((m = /^\*\*\*(\S(?:.*?\S)?)\*\*\*/.exec(rest))) seg = { kind: 'bi', body: m[1], open: 3 };
      else if ((m = /^\*\*(\S(?:.*?\S)?)\*\*/.exec(rest))) seg = { kind: 'b', body: m[1], open: 2 };
      else if (prev !== '*' && (m = /^\*([^\s*](?:[^*]*?[^\s*])?)\*/.exec(rest)))
        seg = { kind: 'i', body: m[1], open: 1 };
      if (!seg) { prev = raw[i]; i += 1; continue; }
      text(i);
      seg.s = i;
      seg.e = i + m[0].length;
      segs.push(seg);
      prev = '';
      from = i = seg.e;
    }
    text(raw.length);
    return segs;
  }

  var INLINE_CLASS = { code: 'ed-code', b: 'ed-b', i: 'ed-i', bi: 'ed-bi', link: 'ed-link' };

  // caret is a raw offset or null: the token enclosing it (boundaries
  // inclusive, so approaching from either side reveals first) renders as
  // raw source — the obsidian reveal. every raw char lands in the output,
  // markers hidden never dropped, or rawCaret's offsets go wrong.
  function buildInline(parent, raw, caret) {
    scanInline(raw).forEach(function (seg) {
      var src = raw.slice(seg.s, seg.e);
      if (seg.kind === 'text' || (caret !== null && caret >= seg.s && caret <= seg.e)) {
        parent.appendChild(document.createTextNode(src));
        return;
      }
      parent.appendChild(tok(src.slice(0, seg.open)));
      if (seg.kind === 'esc') {
        parent.appendChild(document.createTextNode(seg.body));
      } else if (seg.kind === 'code') {
        // literal, never recursed: marks inside a code span are not marks
        var c = document.createElement('span');
        c.className = 'ed-code';
        c.textContent = seg.body;
        parent.appendChild(c);
      } else {
        var s = document.createElement('span');
        s.className = INLINE_CLASS[seg.kind];
        buildInline(s, seg.body, null);
        parent.appendChild(s);
      }
      var tail = src.slice(seg.open + seg.body.length);
      if (tail) parent.appendChild(tok(tail));
    });
  }

  function buildLine(n, raw, prefix, active, caret) {
    n.innerHTML = '';
    if (!raw) { n.innerHTML = '<br>'; return; }
    if (prefix) {
      if (active) {
        n.appendChild(document.createTextNode(prefix));
      } else {
        if (/^[-*] /.test(prefix)) {
          var b = document.createElement('span');
          b.contentEditable = 'false';
          b.className = 'bullet';
          b.textContent = '•';
          n.appendChild(b);
        }
        n.appendChild(tok(prefix));
      }
    }
    var rest = raw.slice(prefix.length);
    if (rest) buildInline(n, rest, caret);
    else if (!active) n.appendChild(document.createTextNode('​'));
  }

  function lineClass(raw) {
    var t = raw.trim();
    if (!t) return 'blank';
    if (/^###\s/.test(t)) return 'h3';
    if (/^##\s/.test(t)) return 'h2';
    if (/^#\s/.test(t)) return 'h1';
    if (/^>/.test(t)) return 'quote';
    if (/^[-*]\s/.test(t)) return 'item';
    return '';
  }

  // a WeakMap, not a data attribute: the browser clones attributes when
  // enter splits a line, and a cloned signature would skip the rebuild
  var lineSig = new WeakMap();

  // one pass serves styling, the source text, and the undo snapshot's
  // caret, so nothing downstream re-reads the line DOM
  function styleLines(el) {
    var sel = window.getSelection();
    var raws = [], caretLine = 0, caretOff = 0;
    Array.prototype.slice.call(el.children).forEach(function (n, idx) {
      var raw = rawOf(n);
      raws.push(raw);
      var pm = raw.match(TOKEN);
      var prefix = pm ? pm[1] : '';
      var active = !!(sel && sel.anchorNode && n.contains(sel.anchorNode));
      var caret = active ? rawCaret(n) : null;
      var cRel = caret === null ? null : Math.max(0, caret - prefix.length);
      if (active) {
        caretLine = idx;
        caretOff = caret === null ? 0 : caret;
      }

      var segs = null, hole = '';
      if (cRel !== null) {
        segs = scanInline(raw.slice(prefix.length));
        for (var j = 0; j < segs.length; j++) {
          if (segs[j].kind !== 'text' && cRel >= segs[j].s && cRel <= segs[j].e) {
            hole = segs[j].s + '-' + segs[j].e;
            break;
          }
        }
      }

      var sig = (active ? 'a|' : 'n|') + hole + '|' + raw;
      if (lineSig.get(n) !== sig) {
        lineSig.set(n, sig);
        // the hot path is typing plain prose: an active line with no marks
        // is already the single text run a build would produce, and
        // skipping the rebuild also leaves the browser's caret untouched
        var plain = active && hole === '' && !n.firstElementChild && n.firstChild &&
          segs !== null && segs.every(function (g) { return g.kind === 'text'; });
        if (!plain) {
          buildLine(n, raw, prefix, active, cRel);
          if (caret !== null) setCaretRaw(n, caret);
        }
      }
      var lc = lineClass(raw);
      if (n.className !== lc) n.className = lc;
    });
    return { raws: raws, line: caretLine, off: caretOff };
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
      // md() trims each line before matching, so an indented `# x` renders
      // as an h1 — match it here too or it styles as a title and isn't one
      var m = lines[i].trim().match(/^#\s+(.*\S)/);
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
    setCaretRaw(d, 2);
  }

  // an edit opens on the post's raw markdown: one div per source line, the
  // same shape restore() builds, with the caret parked at the end
  function fill(el, src) {
    el.innerHTML = '';
    src.split('\n').forEach(function (t) {
      var d = document.createElement('div');
      if (t) d.textContent = t;
      else d.innerHTML = '<br>';
      el.appendChild(d);
    });
    el.focus();
    var last = el.lastElementChild;
    if (last) setCaretRaw(last, rawOf(last).length);
  }

  function editor() {
    var el = document.getElementById('k-ed');
    if (!el) return;

    var init = document.getElementById('k-ed-src');
    var editId = document.getElementById('k-edit-id');
    if (!el.children.length) {
      if (init) fill(el, init.textContent);
      else seed(el);
    }

    var count = document.getElementById('k-words');
    var send = document.getElementById('k-send');
    var audience = document.getElementById('k-audience');

    // rebuilding a line mid-IME-composition cancels the composition
    var composing = false;
    el.addEventListener('compositionstart', function () { composing = true; });
    el.addEventListener('compositionend', function () { composing = false; refresh(); });

    // where the last refresh left the caret: a selectionchange that merely
    // echoes it (every keystroke fires one) must not trigger a second full
    // pass — that doubles the per-key work for nothing
    var seenSel = { node: null, off: -1 };

    // the count is display-only; four full-text regexes per keystroke is
    // latency spent on a number nobody reads at keystroke speed
    var countTimer = 0;
    function scheduleCount(src) {
      clearTimeout(countTimer);
      countTimer = setTimeout(function () {
        var n = words(src);
        count.textContent = n === 1 ? '1 word' : n + ' words';
      }, 250);
    }

    var refresh = function () {
      if (composing) return;
      normalize(el);
      var got = styleLines(el);
      var src = got.raws.join('\n');
      if (count) scheduleCount(src);
      current = { src: src, line: got.line, off: got.off };
      var sel = window.getSelection();
      seenSel.node = sel ? sel.anchorNode : null;
      seenSel.off = sel ? sel.anchorOffset : -1;
    };

    // scripted line rebuilds invalidate the browser's undo stack, so the
    // editor keeps its own: source text plus caret, rebuilt via restore()
    var undoStack = [], redoStack = [], current = null;
    var lastPush = 0, lastType = '';

    function restore(s) {
      el.innerHTML = '';
      s.src.split('\n').forEach(function (t) {
        var d = document.createElement('div');
        if (t) d.textContent = t;
        else d.innerHTML = '<br>';
        el.appendChild(d);
      });
      el.focus();
      var target = el.children[Math.min(s.line, el.children.length - 1)];
      if (target) setCaretRaw(target, s.off);
      lastType = '';
      refresh();
    }

    function undo() {
      if (!undoStack.length) return;
      redoStack.push(current);
      restore(undoStack.pop());
    }

    function redo() {
      if (!redoStack.length) return;
      undoStack.push(current);
      restore(redoStack.pop());
    }

    // push the pre-edit state, coalescing runs of one input type so an
    // undo step is a burst of typing, not a single character
    el.addEventListener('beforeinput', function (e) {
      if (e.inputType === 'historyUndo') { e.preventDefault(); undo(); return; }
      if (e.inputType === 'historyRedo') { e.preventDefault(); redo(); return; }
      if (!current) return;
      var boundary = e.inputType !== lastType ||
        Date.now() - lastPush > 900 ||
        e.inputType === 'insertParagraph' ||
        e.inputType === 'insertFromPaste';
      if (!boundary) return;
      undoStack.push(current);
      if (undoStack.length > 200) undoStack.shift();
      redoStack.length = 0;
      lastPush = Date.now();
      lastType = e.inputType;
    });

    // the model is markdown text; rich clipboard HTML would land as markup
    // the line machine cannot classify, so force text/plain through the
    // browser's own inserter (which keeps it on the undo stack)
    el.addEventListener('paste', function (e) {
      e.preventDefault();
      var text = e.clipboardData ? e.clipboardData.getData('text/plain') : '';
      if (text) document.execCommand('insertText', false, text);
    });

    // native cmd-b inserts <b> nodes source() cannot see — bold that shows
    // in the editor and vanishes on publish. write the markdown instead.
    // ctrl-b on a mac is emacs caret movement, not bold — cmd only there
    var chord = /Mac|iP/.test(navigator.platform)
      ? function (e) { return e.metaKey && !e.ctrlKey; }
      : function (e) { return e.ctrlKey && !e.metaKey; };
    el.addEventListener('keydown', function (e) {
      if (!chord(e) || e.altKey) return;
      var k = e.key.toLowerCase();
      if (k === 'z') {
        e.preventDefault();
        if (e.shiftKey) redo(); else undo();
        return;
      }
      if (k === 'y') { e.preventDefault(); redo(); return; }
      if (k !== 'b' && k !== 'i' && k !== 'u') return;
      e.preventDefault();
      if (k === 'u') return;
      var mark = k === 'b' ? '**' : '*';
      var sel = window.getSelection();
      var text = sel ? sel.toString() : '';
      document.execCommand('insertText', false, mark + text + mark);
      if (!text && sel && sel.modify) {
        sel.modify('move', 'backward', 'character');
        if (k === 'b') sel.modify('move', 'backward', 'character');
      }
    });

    el.addEventListener('input', refresh);
    document.addEventListener('selectionchange', function () {
      if (document.activeElement !== el) return;
      var sel = window.getSelection();
      var node = sel ? sel.anchorNode : null;
      var off = sel ? sel.anchorOffset : -1;
      if (node === seenSel.node && off === seenSel.off) return;
      refresh();
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
        var fields = {
          what: editId ? 'edit' : 'publish',
          body: parts.body,
          title: parts.title,
          to: audience.value
        };
        if (editId) fields.id = editId.value;
        fetch('/keep/write', {
          method: 'POST',
          credentials: 'same-origin',
          headers: { 'content-type': 'application/x-www-form-urlencoded' },
          body: form(fields)
        }).then(function (r) {
          send.textContent = r.ok ? 'sent' : 'failed';
          if (!r.ok) return;
          if (editId) {
            // the replacement has a new id, so there is no read page to
            // return to yet; the ship page shows it once the pokes land
            var mine = document.querySelector('.k-nav a.mono');
            setTimeout(function () {
              window.location = mine ? mine.getAttribute('href') : '/keep';
            }, 600);
            return;
          }
          seed(el);
          undoStack.length = 0;
          redoStack.length = 0;
          refresh();
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

  // ---- delete -----------------------------------------------------------

  function deletes() {
    Array.prototype.slice.call(document.querySelectorAll('form.k-del-form')).forEach(function (f) {
      f.addEventListener('submit', function (e) {
        if (!window.confirm('delete this post? reposts of it stay up.')) e.preventDefault();
      });
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    reader();
    talk();
    editor();
    checker();
    lists();
    deletes();
  });
})();
