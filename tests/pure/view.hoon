::  layer A — lib/keep-ui, the parts that are a contract rather than a look.
::
/-  keep
/+  *test, ui=keep-ui
|%
++  vw  ~(. ui `view:ui`[~zod ~2026.1.1 ~ ~ ~ ~ ~ ~])
::
++  hed
  ^-  head:keep
  [~2026.1.1 ~wes 1 'cc0' `'a title' (sham [%md 'the body']) 0x1]
::
++  row-of
  |=  [via=ship e=entry:keep h=(unit head:keep)]
  ^-  row:ui
  [via e h %.n %.n ~ ~ ~]
::
++  test-last-of-empty
  ^-  tang
  (expect-eq !>('') !>((last:vw ~)))
::
++  test-last-is-the-id
  ^-  tang
  (expect-eq !>('0v5') !>((last:vw /item/0v5)))
::
::  id first, ship last: eyre splits the LAST segment on its final dot to make
::  pork's ext, and a @uv id is full of dots
++  test-read-url-puts-id-first
  ^-  tang
  (expect-eq !>("/keep/read/0v5/~bus") !>((read-url:vw [~bus /item/0v5])))
::
++  test-author-defaults-to-server
  ^-  tang
  (expect-eq !>(~bus) !>((author:vw (row-of ~zod [~bus /item/0v5] ~))))
::
::  a hosted copy names its author, not whoever served it
++  test-author-is-the-signer
  ^-  tang
  (expect-eq !>(~wes) !>((author:vw (row-of ~zod [~bus /item/0v5] `hed))))
::
++  test-day
  ^-  tang
  (expect-eq !>("~2026.1.1") !>((day:vw ~2026.1.1)))
::
++  cnd
  ^-  cand:ui
  [~2026.1.1 'a title' ~wes 0v5 %.n]
::
::  the write page ships the picker's candidates as data attributes
++  test-write-page-carries-candidates
  ^-  tang
  =/  out=tape  (en-xml:html (write-page:vw ~ ~[cnd]))
  (expect-eq !>(%.y) !>(?=(^ (find "data-id=\"0v5\"" out))))
::
::  a gated candidate says so — the leak guard reads this flag
++  test-candidate-marks-gated
  ^-  tang
  =/  out=tape  (en-xml:html (write-page:vw ~ ~[cnd]))
  (expect-eq !>(%.y) !>(?=(^ (find "data-pub=\"n\"" out))))
--
