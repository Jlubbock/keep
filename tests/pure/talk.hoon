::  layer A — comments: the note id, and the tree the renderer builds from a
::  flat list. a note id is the dedupe key AND what the signature is over, so
::  every field has to move it; the tree has to survive a pruned parent.
::
/-  keep, kt=keep-talk
/+  *test, ui=keep-ui
|%
++  vw   ~(. ui `view:ui`[~zod ~2026.1.1 ~ ~ ~ ~ ~ ~])
++  art  `id:keep`0v5
::
++  note-at
  |=  [who=@p wen=@da parent=(unit id:keep) body=@t]
  ^-  note:kt
  [wen who 1 parent body 0x1]
::
++  nid-of  |=(n=note:kt (nid:vw art n))
::
++  j  |=(n=note:kt ^-(judged:kt [n `%good]))
::
::  a base thread: two roots, one reply under the first
++  n1  (note-at ~bus ~2026.1.1 ~ 'first')
++  n2  (note-at ~wes ~2026.1.2 `(nid-of n1) 'a reply')
++  n3  (note-at ~zod ~2026.1.3 ~ 'second root')
++  all  ~[(j n1) (j n2) (j n3)]
::
::  ---- the id ----------------------------------------------------------------
::
++  test-id-is-stable
  ^-  tang
  (expect-eq !>((nid-of n1)) !>((nid-of n1)))
::
::  art is inside the id, so a note cannot be replayed into another thread
++  test-id-moves-with-art
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((nid:vw art (note-at ~bus ~2026.1.1 ~ 'x')) (nid:vw `id:keep`0v6 (note-at ~bus ~2026.1.1 ~ 'x'))))
::
++  test-id-moves-with-who
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((nid-of (note-at ~bus ~2026.1.1 ~ 'x')) (nid-of (note-at ~wes ~2026.1.1 ~ 'x'))))
::
++  test-id-moves-with-wen
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((nid-of (note-at ~bus ~2026.1.1 ~ 'x')) (nid-of (note-at ~bus ~2026.1.2 ~ 'x'))))
::
++  test-id-moves-with-parent
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((nid-of (note-at ~bus ~2026.1.1 ~ 'x')) (nid-of (note-at ~bus ~2026.1.1 `0v7 'x'))))
::
++  test-id-moves-with-body
  ^-  tang
  %+  expect-eq  !>(%.n)
  !>(=((nid-of (note-at ~bus ~2026.1.1 ~ 'x')) (nid-of (note-at ~bus ~2026.1.1 ~ 'y'))))
::
::  lyfe is signed too: a re-signed copy under a new key is a different note
++  test-id-moves-with-lyfe
  ^-  tang
  =/  a=note:kt  [~2026.1.1 ~bus 1 ~ 'x' 0x1]
  =/  b=note:kt  [~2026.1.1 ~bus 2 ~ 'x' 0x1]
  (expect-eq !>(%.n) !>(=((nid-of a) (nid-of b))))
::
::  the sig is NOT in the id: the id is what the sig is taken over
++  test-id-ignores-sig
  ^-  tang
  =/  a=note:kt  [~2026.1.1 ~bus 1 ~ 'x' 0x1]
  =/  b=note:kt  [~2026.1.1 ~bus 1 ~ 'x' 0x2]
  (expect-eq !>((nid-of a)) !>((nid-of b)))
::
::  ---- the tree ---------------------------------------------------------------
::
++  test-roots-are-parentless
  ^-  tang
  %+  expect-eq  !>(~[(j n1) (j n3)])
  !>((roots-of:vw art all))
::
++  test-kids-sit-under-their-parent
  ^-  tang
  %+  expect-eq  !>(~[(j n2)])
  !>((kids-of:vw art all (nid-of n1)))
::
++  test-a-root-has-no-kids
  ^-  tang
  (expect-eq !>(`(list judged:kt)`~) !>((kids-of:vw art all (nid-of n3))))
::
::  a parent missing from the thread promotes its children to the top rather
::  than losing them: the host prunes, the reader still reads
++  test-orphan-promotes-to-root
  ^-  tang
  =/  orphan  (note-at ~wes ~2026.1.4 [~ 0vdead] 'my parent is gone')
  %+  expect-eq  !>(~[(j n1) (j n3) (j orphan)])
  !>((roots-of:vw art ~[(j n1) (j n3) (j orphan)]))
::
::  arrival order is render order: a claimed wen cannot jump the queue
++  test-siblings-keep-arrival-order
  ^-  tang
  =/  late   (note-at ~wes ~2020.1.1 ~ 'backdated')
  %+  expect-eq  !>(~[(j n1) (j n3) (j late)])
  !>((roots-of:vw art ~[(j n1) (j n3) (j late)]))
--
