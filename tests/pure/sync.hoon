::  layer A — the substack pipeline: html to markdown, json to posts.
::
::    Exact-output assertions throughout: each is its own positive control
::    (a converter that produced nothing would fail every one of them).
::
/-  ks=keep-sync
/+  *test, hm=html-md, sk=substack
|%
::  ---- html -> markdown ------------------------------------------------------
::
++  test-md-paragraphs
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'one\0a\0atwo')
  !>((convert:hm '<p>one</p><p>two</p>'))
::
++  test-md-inline
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'a **b** *c* `d`')
  !>((convert:hm '<p>a <strong>b</strong> <em>c</em> <code>d</code></p>'))
::
++  test-md-link
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'[z](https://x.y/p)')
  !>((convert:hm '<p><a href="https://x.y/p">z</a></p>'))
::
++  test-md-heading
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'## t\0a\0ab')
  !>((convert:hm '<h2>t</h2><p>b</p>'))
::
++  test-md-ul
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'- a\0a- b')
  !>((convert:hm '<ul><li>a</li><li>b</li></ul>'))
::
++  test-md-ol
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'1. a\0a2. b')
  !>((convert:hm '<ol><li>a</li><li>b</li></ol>'))
::
++  test-md-nested-list
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'- a\0a  - b\0a- c')
  !>((convert:hm '<ul><li>a<ul><li>b</li></ul></li><li>c</li></ul>'))
::
++  test-md-blockquote
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'> a\0a> \0a> b')
  !>((convert:hm '<blockquote><p>a</p><p>b</p></blockquote>'))
::
++  test-md-pre
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'```\0ax = 1\0a```')
  !>((convert:hm '<pre>x = 1</pre>'))
::
++  test-md-hr
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'a\0a\0a---\0a\0ab')
  !>((convert:hm '<p>a</p><hr /><p>b</p>'))
::
++  test-md-void-br-hr
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'a\0ab\0a\0a---')
  !>((convert:hm '<p>a<br>b</p><hr>'))
::
::  substack html leaves img/source/input open, and de-xml is strict xml
++  test-md-closes-voids
  ^-  tang
  =/  r
    %-  convert:hm
    '<figure><img src="https://cdn/x.png"></figure><p>a<br>b</p><hr>'
  (expect-eq !>(`(unit @t)``'a\0ab\0a\0a---') !>(r))
::
::  a '>' inside a quoted attribute must not end the tag early
++  test-md-void-quoted-gt
  ^-  tang
  =/  r
    %-  convert:hm
    '<p>a<img alt="x>y">b</p>'
  (expect-eq !>(`(unit @t)``'ab') !>(r))
::
++  test-md-nbsp
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'a b')
  !>((convert:hm '<p>a&nbsp;b</p>'))
::
++  test-md-escapes
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'a\\*b\\_c')
  !>((convert:hm '<p>a*b_c</p>'))
::
::  the survivor paragraph is the control: the drop is targeted, not total
++  test-md-drops-images
  ^-  tang
  =/  r
    %-  convert:hm
    '<div class="captioned-image-container"><figure><img src="x" /></figure></div><p>t</p>'
  (expect-eq !>(`(unit @t)``'t') !>(r))
::
++  test-md-drops-subscribe
  ^-  tang
  =/  r
    %-  convert:hm
    '<p class="button-wrapper"><a class="button" href="https://s">Subscribe now</a></p><p>t</p>'
  (expect-eq !>(`(unit @t)``'t') !>(r))
::
++  test-md-unwraps-unknown
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)``'t')
  !>((convert:hm '<section><p>t</p></section>'))
::
++  test-md-refuses-malformed
  ^-  tang
  %+  expect-eq
    !>(`(unit @t)`~)
  !>((convert:hm '<p>unclosed'))
::
::  ---- iso dates -------------------------------------------------------------
::
++  test-iso-parses
  ^-  tang
  %+  expect-eq
    !>(`(unit @da)``~2026.8.27..17.59.17)
  !>((iso-da:sk '2026-08-27T17:59:17.583Z'))
::
++  test-iso-no-fraction
  ^-  tang
  %+  expect-eq
    !>(`(unit @da)``~2026.1.2..3.4.5)
  !>((iso-da:sk '2026-01-02T03:04:05Z'))
::
++  test-iso-refuses-junk
  ^-  tang
  ;:  weld
    (expect-eq !>(`(unit @da)`~) !>((iso-da:sk 'yesterday')))
    (expect-eq !>(`(unit @da)`~) !>((iso-da:sk '2026-13-02T03:04:05Z')))
    (expect-eq !>(`(unit @da)`~) !>((iso-da:sk '2026-01-02 03:04:05')))
  ==
::
::  ---- the about check -------------------------------------------------------
::
++  test-mentions
  ^-  tang
  %+  expect-eq
    !>(%.y)
  !>((mentions:sk ~dev '<p>I\'m ~dev on Keep.</p>'))
::
::  the wrong ship is the control: a page can name someone and still fail
++  test-mentions-other-ship
  ^-  tang
  %+  expect-eq
    !>(%.n)
  !>((mentions:sk ~lex '<p>I\'m ~dev on Keep.</p>'))
::
::  a galaxy is a prefix of a great many ships
++  test-mentions-whole-word
  ^-  tang
  ;:  weld
    (expect-eq !>(%.n) !>((mentions:sk ~dev 'see ~devrem')))
    (expect-eq !>(%.n) !>((mentions:sk ~dev 'see ~dev-moon')))
    (expect-eq !>(%.y) !>((mentions:sk ~dev 'see ~devrem and ~dev.')))
    (expect-eq !>(%.y) !>((mentions:sk ~dev '~dev')))
  ==
::
::  ---- json reshaping --------------------------------------------------------
::
++  test-arch-reshape
  ^-  tang
  =/  aj=json
    %-  need  %-  de:json:html
    '''
    [{"slug":"b","post_date":"2026-08-27T17:59:17.583Z","audience":"only_paid"},
     {"slug":"a","post_date":"2026-08-26T15:59:59.411Z","audience":"everyone"},
     {"slug":"broken","post_date":null,"audience":"everyone"}]
    '''
  %+  expect-eq
    !>  ^-  (list [slug=@t wen=@da aud=@t])
        :~  ['b' ~2026.8.27..17.59.17 'only_paid']
            ['a' ~2026.8.26..15.59.59 'everyone']
        ==
  !>((arch:sk aj))
::
++  test-post-md-free
  ^-  tang
  =/  pj=json
    %-  need  %-  de:json:html
    '''
    {"slug":"s","post_date":"2026-01-02T03:04:05.000Z","title":"T",
     "audience":"everyone","canonical_url":"https://x/p/s",
     "body_html":"<p>hi</p>"}
    '''
  %+  expect-eq
    !>(`(unit post:ks)``['s' ~2026.1.2..3.4.5 'T' 'hi'])
  !>((post-md:sk pj))
::
++  test-post-md-paid-teaser
  ^-  tang
  =/  pj=json
    %-  need  %-  de:json:html
    '''
    {"slug":"s","post_date":"2026-01-02T03:04:05.000Z","title":"T",
     "audience":"only_paid","canonical_url":"https://x/p/s",
     "body_html":"<p>tease</p>"}
    '''
  %+  expect-eq
    !>  ^-  (unit post:ks)
        `['s' ~2026.1.2..3.4.5 'T' 'tease\0a\0a[Read the full post](https://x/p/s)']
  !>((post-md:sk pj))
::
::  a post that will not render still lands, as a pointer to itself
++  test-post-md-unrenderable
  ^-  tang
  =/  pj=json
    %-  need  %-  de:json:html
    '''
    {"slug":"s","post_date":"2026-01-02T03:04:05.000Z","title":"T",
     "audience":"everyone","canonical_url":"https://x/p/s",
     "body_html":"<p>broken"}
    '''
  %+  expect-eq
    !>(`(unit post:ks)``['s' ~2026.1.2..3.4.5 'T' '[Read the full post](https://x/p/s)'])
  !>((post-md:sk pj))
--
