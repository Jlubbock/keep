::  layer A — +sain, the id every signature covers.
::
::    A head verifies alone because the id commits to all of it. Each arm here
::    removes one field from that claim and shows the id moves.
::
/-  keep
/+  *test
|%
++  base
  ^-  [who=@p lyfe=@ud wen=@da terms=@t title=(unit @t) hash=@uvH]
  [~zod 1 ~2026.1.1 'cc0' `'a title' (sham [%md 'the body'])]
::
::  the positive control the six negatives below are worth nothing without
++  test-sain-agrees
  ^-  tang
  =/  b  base
  (expect-eq !>(%.y) !>(=((sain:keep b) (sain:keep b))))
::
++  test-sain-binds-author
  ^-  tang
  =/  b  base
  (expect-eq !>(%.n) !>(=((sain:keep b) (sain:keep b(who ~bus)))))
::
++  test-sain-binds-life
  ^-  tang
  =/  b  base
  (expect-eq !>(%.n) !>(=((sain:keep b) (sain:keep b(lyfe 2)))))
::
++  test-sain-binds-time
  ^-  tang
  =/  b  base
  (expect-eq !>(%.n) !>(=((sain:keep b) (sain:keep b(wen ~2026.1.2)))))
::
++  test-sain-binds-terms
  ^-  tang
  =/  b  base
  (expect-eq !>(%.n) !>(=((sain:keep b) (sain:keep b(terms 'all rights reserved')))))
::
++  test-sain-binds-title
  ^-  tang
  =/  b  base
  (expect-eq !>(%.n) !>(=((sain:keep b) (sain:keep b(title `'another title')))))
::
::  the one that stops a mirror pairing a real signature with a fabricated body
++  test-sain-binds-body-hash
  ^-  tang
  =/  b  base
  =/  other  (sham [%md 'a different body'])
  (expect-eq !>(%.n) !>(=((sain:keep b) (sain:keep b(hash other)))))
::
::  an absent title is not an empty one
++  test-sain-untitled-differs
  ^-  tang
  =/  b  base
  (expect-eq !>(%.n) !>(=((sain:keep b(title ~)) (sain:keep b(title `'')))))
--
