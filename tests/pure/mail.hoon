::  layer A — the mail pipeline: csv to addresses, subjects, the relay's
::  urls and answers, markdown to html.
::
::    Exact-output assertions throughout: each is its own positive control
::    (a sieve, parser or renderer that produced nothing would fail every one).
::
/+  *test, kml=keep-mail, mh=md-html
|%
::  ---- the sieve -------------------------------------------------------------
::
++  test-sieve-bare-list
  ^-  tang
  %+  expect-eq
    !>(`[(list @t) @ud]`[~['a@x.com' 'b@y.com'] 0])
  !>((sieve:kml 'a@x.com\0aB@Y.com\0aa@x.com'))
::
++  test-sieve-substack-csv
  ^-  tang
  ::  the header names no reader and is not junk; the junk line is
  %+  expect-eq
    !>(`[(list @t) @ud]`[~['a@x.com'] 1])
  !>((sieve:kml 'email,active_subscription\0aA@x.com,true\0ajunk,true'))
::
++  test-sieve-comma-paste
  ^-  tang
  %+  expect-eq
    !>(`[(list @t) @ud]`[~['a@x.com' 'b@y.com'] 0])
  !>((sieve:kml 'a@x.com, b@y.com'))
::
++  test-sieve-quoted-and-crlf
  ^-  tang
  %+  expect-eq
    !>(`[(list @t) @ud]`[~['a@x.com' 'b@y.com'] 0])
  !>((sieve:kml '"a@x.com",true\0d\0ab@y.com\0d\0a'))
::
++  test-sieve-blank-lines-are-not-junk
  ^-  tang
  %+  expect-eq
    !>(`[(list @t) @ud]`[~['a@x.com'] 0])
  !>((sieve:kml 'a@x.com\0a\0a'))
::
++  test-valid-shapes
  ^-  tang
  ;:  weld
    (expect !>((valid:kml "a@x.com")))
    (expect !>(!(valid:kml "a@b")))          ::  no dot after the @
    (expect !>(!(valid:kml "a.b@c")))
    (expect !>(!(valid:kml "@x.com")))
    (expect !>(!(valid:kml "a b@x.com")))
    (expect !>(!(valid:kml "a@b@x.com")))
  ==
::
::  ---- subjects --------------------------------------------------------------
::
++  test-subject-title-wins
  ^-  tang
  (expect-eq !>('T') !>((subject:kml `'T' '# not this\0abody')))
::
++  test-subject-first-line-unhashed
  ^-  tang
  (expect-eq !>('Hello') !>((subject:kml ~ '# Hello\0a\0abody')))
::
++  test-subject-skips-blank-lead
  ^-  tang
  (expect-eq !>('first line') !>((subject:kml ~ '\0a\0afirst line\0amore')))
::
++  test-subject-empty-body
  ^-  tang
  (expect-eq !>('a new post') !>((subject:kml ~ '')))
::
::  ---- the relay's urls ------------------------------------------------------
::
++  test-clean-url
  ^-  tang
  ;:  weld
    (expect-eq !>('https://example.com') !>((clean-url:kml 'example.com/')))
    (expect-eq !>('https://x.y') !>((clean-url:kml 'https://x.y/')))
    (expect-eq !>('http://127.0.0.1:8090') !>((clean-url:kml 'http://127.0.0.1:8090')))
  ==
::
::  the relay ships with the desk: an empty url means keep-posting.com,
::  a given one is the override
++  test-conf-defaults
  ^-  tang
  ;:  weld
    (expect-eq !>('https://keep-posting.com') !>(relay:(conf-defaults:kml ['' 'k'])))
    (expect-eq !>('k') !>(key:(conf-defaults:kml ['' 'k'])))
    (expect-eq !>('https://127.0.0.1:8099') !>(relay:(conf-defaults:kml ['127.0.0.1:8099' 'k'])))
  ==
::
::  a %3 config held the send endpoint itself; the base is what survives
++  test-base-of
  ^-  tang
  ;:  weld
    (expect-eq !>('https://keep-posting.com') !>((base-of:kml 'https://keep-posting.com/api/mail/send')))
    (expect-eq !>('http://127.0.0.1:8099') !>((base-of:kml 'http://127.0.0.1:8099')))
    (expect-eq !>('http://x/send') !>((base-of:kml 'http://x/send')))
  ==
::
++  test-urls
  ^-  tang
  ;:  weld
    (expect-eq !>('https://k.com/api/mail/send') !>((send-url:kml 'https://k.com')))
    (expect-eq !>('https://k.com/api/mail/readers') !>((readers-url:kml 'https://k.com')))
    (expect-eq !>('https://k.com/api/mail/import') !>((import-url:kml 'https://k.com')))
    (expect-eq !>('https://k.com/api/mail/import/verify') !>((verify-url:kml 'https://k.com')))
    (expect-eq !>('https://k.com/api/mail/import/token') !>((token-url:kml 'https://k.com')))
    (expect-eq !>('https://k.com/api/mail/profile') !>((profile-url:kml 'https://k.com')))
    (expect-eq !>('https://k.com/api/mail/jobs/j1') !>((job-url:kml 'https://k.com' 'j1')))
    (expect-eq !>('https://k.com/subscribe/~zod') !>((subscribe-url:kml 'https://k.com' ~zod)))
  ==
::
::  ---- the relay's answers ---------------------------------------------------
::
++  test-job-of
  ^-  tang
  =/  want=(unit [@t @ud (list @t) (list @t)])
    `['ab12' 40 ~['c@x.com' 'd@x.com'] ~['e@x.com']]
  ;:  weld
    %+  expect-eq
      !>(want)
    !>  %-  job-of:kml
        '''
        {"job": "ab12", "status": "queued", "recipients": 40,
         "dropped": [{"to": "c@x.com", "reason": "unsubscribed"}, {"to": "d@x.com", "reason": "invalid"}],
         "unconfirmed": ["e@x.com"], "quota": 500}
        '''
    (expect-eq !>(*(unit [@t @ud (list @t) (list @t)])) !>((job-of:kml '{"detail": "missing or unknown email key"}')))
    (expect-eq !>(*(unit [@t @ud (list @t) (list @t)])) !>((job-of:kml 'not json')))
  ==
::
++  test-job-state
  ^-  tang
  ;:  weld
    %+  expect-eq
      !>(`(unit [@t @ud @ud @ud (unit @t)])``['done' 39 1 0 ~])
    !>((job-state:kml '{"job": "ab12", "status": "done", "requested": 40, "sent": 39, "failed": 1, "queued": 0, "error": null}'))
    %+  expect-eq
      !>(`(unit [@t @ud @ud @ud (unit @t)])``['failed' 0 0 0 `'ship released'])
    !>((job-state:kml '{"status": "failed", "error": "ship released"}'))
    (expect-eq !>(*(unit [@t @ud @ud @ud (unit @t)])) !>((job-state:kml '{"ok": true}')))
  ==
::
++  test-readers-of
  ^-  tang
  ;:  weld
    %+  expect-eq
      !>(`(unit [(list @t) @ud])``[~['a@x.com' 'b@x.com'] 3])
    !>((readers-of:kml '{"active": ["a@x.com", "b@x.com"], "pending": 3, "subscribe_url": "x", "manage_url": "y"}'))
    (expect-eq !>(*(unit [(list @t) @ud])) !>((readers-of:kml '{"detail": "nope"}')))
  ==
::
++  test-proof-of
  ^-  tang
  ;:  weld
    %+  expect-eq
      !>(`(unit [@t (unit @t)])``['keep-verify-abc' `'https://x.substack.com/about'])
    !>((proof-of:kml '{"token": "keep-verify-abc", "verified_url": "https://x.substack.com/about", "verified_at": 1.0}'))
    %+  expect-eq
      !>(`(unit [@t (unit @t)])``['keep-verify-abc' ~])
    !>((proof-of:kml '{"token": "keep-verify-abc", "verified_url": null, "verified_at": null}'))
    (expect-eq !>(*(unit [@t (unit @t)])) !>((proof-of:kml '{"detail": "no"}')))
  ==
::
++  test-import-of
  ^-  tang
  ;:  weld
    (expect-eq !>(`(unit @ud)``405) !>((import-of:kml '{"import_id": "x", "rows": 7009, "pending": 405, "dropped": {"inactive": 6595}}')))
    (expect-eq !>(*(unit @ud)) !>((import-of:kml '{"detail": "not a Substack subscriber export"}')))
  ==
::
::  a refusal becomes a sentence the writer can act on
++  test-why-of
  ^-  tang
  ;:  weld
    %+  expect-eq
      !>('Keep doesn\'t recognize this ship\'s email key — nothing went out')
    !>((why-of:kml 401 '{"detail": "missing or unknown email key"}'))
    %+  expect-eq
      !>('Keep paused your sending for review — nothing went out')
    !>((why-of:kml 403 '{"detail": "sending is suspended pending review (writer suspended: bounce 6%)"}'))
    %+  expect-eq
      !>('Keep paused your sending for review — nothing went out')
    !>((why-of:kml 0 'sending is suspended pending review'))
    %+  expect-eq
      !>('Keep answered 422: subject and text are required')
    !>((why-of:kml 422 '{"detail": "subject and text are required"}'))
  ==
::
++  test-detail-of
  ^-  tang
  ;:  weld
    (expect-eq !>('bad key') !>((detail-of:kml '{"detail": "bad key"}')))
    (expect-eq !>('<html>') !>((detail-of:kml '<html>')))
  ==
::
::  ---- markdown -> html ------------------------------------------------------
::
++  test-html-paragraphs
  ^-  tang
  %+  expect-eq
    !>('<p>one</p>\0a<p>two</p>\0a')
  !>((convert:mh 'one\0a\0atwo'))
::
++  test-html-heading
  ^-  tang
  %+  expect-eq
    !>('<h1>T</h1>\0a<p>b</p>\0a')
  !>((convert:mh '# T\0a\0ab'))
::
++  test-html-inline
  ^-  tang
  %+  expect-eq
    !>('<p>a <strong>b</strong> and <em>c</em></p>\0a')
  !>((convert:mh 'a **b** and *c*'))
::
++  test-html-link
  ^-  tang
  %+  expect-eq
    !>('<p><a href="https://x.y/p">z</a></p>\0a')
  !>((convert:mh '[z](https://x.y/p)'))
::
++  test-html-code-escapes
  ^-  tang
  %+  expect-eq
    !>('<p><code>x &lt; y</code></p>\0a')
  !>((convert:mh '`x < y`'))
::
++  test-html-blockquote
  ^-  tang
  %+  expect-eq
    !>('<blockquote><p>a b</p></blockquote>\0a')
  !>((convert:mh '> a\0a> b'))
::
++  test-html-lists
  ^-  tang
  ;:  weld
    %+  expect-eq
      !>('<ul><li>a</li><li>b</li></ul>\0a')
    !>((convert:mh '- a\0a- b'))
    %+  expect-eq
      !>('<ol><li>a</li><li>b</li></ol>\0a')
    !>((convert:mh '1. a\0a2. b'))
  ==
::
++  test-html-rule-and-fence
  ^-  tang
  ;:  weld
    (expect-eq !>('<hr/>\0a') !>((convert:mh '---')))
    %+  expect-eq
      !>('<pre><code>x &lt; y\0a</code></pre>\0a')
    !>((convert:mh '```\0ax < y\0a```'))
  ==
::
++  test-html-image-leaves-alt
  ^-  tang
  %+  expect-eq
    !>('<p>see alt here</p>\0a')
  !>((convert:mh 'see ![alt](https://x.y/i.png) here'))
--
