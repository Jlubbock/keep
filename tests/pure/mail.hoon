::  layer A — the mail pipeline: csv to addresses, markdown to html.
::
::    Exact-output assertions throughout: each is its own positive control
::    (a sieve or renderer that produced nothing would fail every one).
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
::  ---- tokens ----------------------------------------------------------------
::
++  test-token-is-salted-sham
  ^-  tang
  %+  expect-eq
    !>((sham ['a@x.com' 0v3]))
  !>((token:kml 'a@x.com' 0v3))
::
++  test-token-differs-by-salt
  ^-  tang
  (expect !>(!=((token:kml 'a@x.com' 0v3) (token:kml 'a@x.com' 0v4))))
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
::  ---- urls ------------------------------------------------------------------
::
++  test-clean-url
  ^-  tang
  ;:  weld
    (expect-eq !>('https://example.com') !>((clean-url:kml 'example.com/')))
    (expect-eq !>('https://x.y') !>((clean-url:kml 'https://x.y/')))
    (expect-eq !>('http://127.0.0.1:8090') !>((clean-url:kml 'http://127.0.0.1:8090')))
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
