::  layer A — lib/keep-core: the addresses. A gated list is one address under
::  its coop, so the derivation is the whole story of where a reader looks.
::
/-  keep
/+  *test, kc=keep-core, ui=keep-ui
|%
++  head-at
  |=  wen=@da
  ^-  head:keep
  [wen ~zod 1 'cc0' `'a title' 0v9 0x1]
::
++  row-at
  |=  wen=@da
  ^-  row:ui
  [~zod [~zod /item/0v5] `(head-at wen) %.n %.n ~ ~ ~]
::
::  ---- addresses -------------------------------------------------------------
::
::  every install publishes under its own nonce, so a nuked and reinstalled
::  writer never asks gall for a revision number it has already given out
++  test-public-index-carries-the-install-nonce
  ^-  tang
  (expect-eq !>(`path`/0v5/index) !>((feed-spur:kc %public 0v5)))
::
::  a gated list has one address, under its coop; the coop is the capability
++  test-gated-feed-lives-under-its-coop
  ^-  tang
  (expect-eq !>(`path`/list/inner/0v5/index) !>((feed-spur:kc %inner 0v5)))
::
++  test-index-kind
  ^-  tang
  %+  expect-eq  !>(~[%.y %.y %.n %.n])
  !>  :~  (index-kind:kc /index)
          (index-kind:kc /0v5/index)
          (index-kind:kc /list/inner/0v5/index)
          (index-kind:kc /item/0v5)
      ==
::
::  a reader swaps an address only for one of the same kind from the same writer
++  test-same-kind
  ^-  tang
  %+  expect-eq  !>(~[%.y %.y %.y %.n %.n])
  !>  :~  (same-kind:kc /index /0v5/index)
          (same-kind:kc /list/inner/index /list/inner/0v5/index)
          (same-kind:kc /list/0v1.23456 /list/inner/0v5/index)
          (same-kind:kc /list/inner/0v5/index /list/outer/0v5/index)
          (same-kind:kc /0v5/index /list/inner/0v5/index)
      ==
::
++  test-lists-get-different-coops
  ^-  tang
  (expect-eq !>(%.n) !>(=((coop:kc %inner) (coop:kc %outer))))
::
::  a gated post is a copy per list, so a member of one list cannot name
::  the address another list reads
++  test-gated-post-is-per-list
  ^-  tang
  %+  expect-eq  !>(~[/item/0v5 /list/inner/item/0v5])
  !>(~[(post-spur:kc %public 0v5) (post-spur:kc %inner 0v5)])
::
::  the reader keens secret exactly when the path is under a coop
++  test-gated-is-by-prefix
  ^-  tang
  %+  expect-eq  !>(~[%.n %.y %.y %.n])
  !>  :~  (gated:kc (welp (base:kc 1) /index))
          (gated:kc (welp (base:kc 1) /list/inner/index))
          (gated:kc (welp (base:kc 1) /list/inner/item/0v5))
          (gated:kc (welp (base:kc 1) /item/0v5))
      ==
::
++  test-old-member-address-is-recognized
  ^-  tang
  %+  expect-eq  !>(~[%.y %.n %.n])
  !>  :~  (old-member:kc /list/0v1.23456)
          (old-member:kc /list/inner/index)
          (old-member:kc /index)
      ==
::
::  (scot %ud 1) not %1: %1 is the atom 1, an 0x01 byte in the path
++  test-base-numbers-in-text
  ^-  tang
  %+  expect-eq  !>(`path`~[%g %x '3' %keep %$ '1'])
  !>((base:kc 3))
::
++  test-item-spur
  ^-  tang
  (expect-eq !>(`path`/item/0v5) !>((item-spur:kc 0v5)))
::
++  test-last-of-is-the-id
  ^-  tang
  (expect-eq !>('0v5') !>((last-of:kc (item-spur:kc 0v5))))
::
++  test-id-of-reads-through-a-coop
  ^-  tang
  (expect-eq !>(`(unit @uvH)``0v5) !>((id-of:kc (post-spur:kc %inner 0v5))))
::
::  ---- the open web ----------------------------------------------------------
::
++  test-slugify-lowercases
  ^-  tang
  (expect-eq !>('a-title') !>((slugify:kc 'A Title')))
::
++  test-slugify-collapses-runs
  ^-  tang
  (expect-eq !>('a-title') !>((slugify:kc 'a  ///  title')))
::
++  test-slugify-trims-edges
  ^-  tang
  (expect-eq !>('a-title') !>((slugify:kc '  a title!  ')))
::
++  test-slugify-never-empty
  ^-  tang
  (expect-eq !>('untitled') !>((slugify:kc '!!!')))
::
++  test-site-path-of-a-title
  ^-  tang
  (expect-eq !>('/keep/a-title') !>((site-path:kc ~ `'A Title')))
::
++  test-site-path-avoids-a-taken-one
  ^-  tang
  %+  expect-eq  !>('/keep/a-title-1')
  !>((site-path:kc (my ~[['/keep/a-title' 0v5]]) `'A Title'))
::
::  a post titled "index" must not take the index's own url
++  test-site-path-avoids-reserved
  ^-  tang
  (expect-eq !>('/keep/index-1') !>((site-path:kc ~ `'index')))
::
++  test-site-path-of-no-title
  ^-  tang
  (expect-eq !>('/keep/untitled') !>((site-path:kc ~ ~)))
::
::  ---- ordering --------------------------------------------------------------
::
++  test-by-date-is-newest-first
  ^-  tang
  =/  rs  ~[(row-at ~2026.1.1) (row-at ~2026.3.3) (row-at ~2026.2.2)]
  %+  expect-eq  !>(~[~2026.3.3 ~2026.2.2 ~2026.1.1])
  !>((turn (by-date:kc rs) |=(r=row:ui ?~(hed.r *@da wen.u.hed.r))))
::
::  a log holds only our own addresses, so an id names one entry in it,
::  whichever coop that copy lives under
++  test-has-id
  ^-  tang
  =/  es  ~[[~zod /item/0v1] [~zod /list/inner/item/0v2]]
  %+  expect-eq  !>(~[%.y %.y %.n])
  !>  :~  (has-id:kc es 0v1)
          (has-id:kc es 0v2)
          (has-id:kc es 0v3)
      ==
::
::  ---- deletion --------------------------------------------------------------
::
::  a revision carries the whole index, so deleting is growing the log again
::  without one pointer — the order of what remains is what a reader diffs
++  test-drop-id-keeps-the-order
  ^-  tang
  =/  es  ~[[~zod /item/0v1] [~zod /item/0v2] [~zod /item/0v3]]
  %+  expect-eq  !>(~[[~zod /item/0v1] [~zod /item/0v3]])
  !>((drop-id:kc es 0v2))
::
++  test-drop-id-of-a-stranger-changes-nothing
  ^-  tang
  =/  es  ~[[~zod /item/0v1] [~zod /item/0v2]]
  (expect-eq !>(es) !>((drop-id:kc es 0v9)))
::
::  ---- same-origin: the csrf gate on every form POST ------------------------
::
++  test-origin-match
  ^-  tang
  ;:  weld
    (expect !>((same-origin:kc ~[['host' 'x.y:8080'] ['origin' 'http://x.y:8080']])))
    (expect !>((same-origin:kc ~[['host' 'X.y'] ['origin' 'https://x.Y']])))
    (expect !>((same-origin:kc ~[['host' 'x.y'] ['referer' 'https://x.y/keep/mail']])))
  ==
::
++  test-origin-mismatch
  ^-  tang
  ;:  weld
    (expect !>(!(same-origin:kc ~[['host' 'x.y'] ['origin' 'https://evil.z']])))
    (expect !>(!(same-origin:kc ~[['host' 'x.y'] ['origin' 'null']])))
    (expect !>(!(same-origin:kc ~[['host' 'x.y:8080'] ['origin' 'http://x.y']])))
    (expect !>(!(same-origin:kc ~[['host' 'x.y'] ['referer' 'https://evil.z/x.y']])))
    (expect !>(!(same-origin:kc ~[['origin' 'https://x.y']])))
  ==
::
::  origin wins over referer; no browser header at all is not a browser
++  test-origin-precedence
  ^-  tang
  ;:  weld
    (expect !>(!(same-origin:kc ~[['host' 'x.y'] ['referer' 'https://x.y/'] ['origin' 'https://evil.z']])))
    (expect !>((same-origin:kc ~[['host' 'x.y']])))
    (expect !>((same-origin:kc ~)))
  ==
--
