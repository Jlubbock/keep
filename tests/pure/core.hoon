::  layer A — lib/keep-core: the addresses. Gating is entirely a question of
::  who receives a pointer, so the pointer's derivation is the whole story.
::
/-  keep
/+  *test, kc=keep-core, ui=keep-ui
|%
++  salt  0v1.23456
::
++  head-at
  |=  wen=@da
  ^-  head:keep
  [wen ~zod 1 'cc0' `'a title' 0v9 0x1]
::
++  row-at
  |=  wen=@da
  ^-  row:ui
  [~zod [~zod /item/0v5] `(head-at wen) %.n %.n ~ ~]
::
::  ---- addresses -------------------------------------------------------------
::
::  %public is derivable from the @p, so nobody has to be told it
++  test-public-index-is-shared
  ^-  tang
  %+  expect-eq  !>(`path`/index)
  !>((member-spur:kc %public salt ~bus))
::
::  every member reads a different address, so a leaked path names one ship
++  test-members-get-different-addresses
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((member-spur:kc %inner salt ~bus) (member-spur:kc %inner salt ~wes)))
::
++  test-lists-get-different-addresses
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((member-spur:kc %inner salt ~bus) (member-spur:kc %outer salt ~bus)))
::
::  the salt is the capability: without it the address is derivable
++  test-salt-changes-the-address
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((member-spur:kc %inner salt ~bus) (member-spur:kc %inner 0v6.78901 ~bus)))
::
++  test-member-address-is-stable
  ^-  tang
  %+  expect-eq  !>(%.y)
  !>(=((member-spur:kc %inner salt ~bus) (member-spur:kc %inner salt ~bus)))
::
++  test-mint-salts-with-entropy
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((mint:kc 0v1 %inner) (mint:kc 0v2 %inner)))
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
++  test-has-entry
  ^-  tang
  =/  es  ~[[~zod /item/0v1] [~bus /item/0v2]]
  %+  expect-eq  !>(~[%.y %.n])
  !>  :~  (has-entry:kc es [~bus /item/0v2])
          (has-entry:kc es [~bus /item/0v3])
      ==
--
