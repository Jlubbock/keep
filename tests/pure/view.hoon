::  layer A — lib/keep-ui, the parts that are a contract rather than a look.
::
/-  keep
/+  *test, ui=keep-ui
|%
++  vw  ~(. ui `view:ui`[~zod ~2026.1.1 ~ ~ ~ ~ ~ ~ ~])
::  ~zod follows ~wes; ~bus follows ~zod; ~wes is a pal on keep, not followed
++  vw-peopled
  ~(. ui `view:ui`[~zod ~2026.1.1 ~[~wes] (sy ~[~wes ~bus]) (sy ~[~wes]) (sy ~[~bus]) ~ ~ ~])
::
++  has  |=([m=manx t=tape] ^-(? ?=(^ (find t (en-xml:html m)))))
::
++  hed
  ^-  head:keep
  [~2026.1.1 ~wes 1 'cc0' `'a title' (sham [%md 'the body']) 0x1]
::
++  row-of
  |=  [via=ship e=entry:keep h=(unit head:keep)]
  ^-  row:ui
  [via e h %.n %.y ~ ~ ~]
::
::  ~bus's hosted copy of ~wes's post, as it lands in ~zod's feed
++  copy  (row-of ~bus [~bus /item/0v5] `hed)
++  orig  (row-of ~wes [~wes /item/0v5] `hed)
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
  =/  out=tape  (en-xml:html (write-page:vw ~ ~[cnd] ~))
  (expect-eq !>(%.y) !>(?=(^ (find "data-id=\"0v5\"" out))))
::
::  a gated candidate says so — the leak guard reads this flag
++  test-candidate-marks-gated
  ^-  tang
  =/  out=tape  (en-xml:html (write-page:vw ~ ~[cnd] ~))
  (expect-eq !>(%.y) !>(?=(^ (find "data-pub=\"n\"" out))))
::
::  ---- reposts read as words -------------------------------------------------
::
::  a copy is told apart from an original by the head's author, not by size
++  test-feed-row-names-the-reposter
  ^-  tang
  =/  out=manx  (feed-row:vw copy "/keep")
  ;:  weld
    (expect-eq !>(%.y) !>((has out "reposted by")))
    (expect-eq !>(%.y) !>((has out "/keep/ship/~bus")))
  ==
::
++  test-feed-row-original-is-not-a-repost
  ^-  tang
  =/  out=manx  (feed-row:vw orig "/keep")
  ;:  weld
    (expect-eq !>(%.n) !>((has out "reposted")))
  ==
::
++  test-feed-row-offers-repost-as-a-verb
  ^-  tang
  (expect-eq !>(%.y) !>((has (feed-row:vw orig "/keep") ">↻ repost<")))
::
++  test-feed-row-states-repost-as-a-fact
  ^-  tang
  =/  r=row:ui  orig
  =/  out=manx  (feed-row:vw r(kept %.y) "/keep")
  ;:  weld
    (expect-eq !>(%.y) !>((has out ">↻ reposted<")))
    (expect-eq !>(%.n) !>((has out ">↻ repost<")))
  ==
::
::  the reader's own writing is never offered back to them
++  test-own-post-has-no-repost-control
  ^-  tang
  =/  h=head:keep  hed
  =/  mine=row:ui  (row-of ~zod [~zod /item/0v5] `h(who ~zod))
  (expect-eq !>(%.n) !>((has (feed-row:vw mine "/keep") "↻")))
::
++  test-user-row-names-the-author
  ^-  tang
  =/  out=manx  (user-row:vw copy "/keep/ship/~bus" ~)
  ;:  weld
    (expect-eq !>(%.y) !>((has out "reposted from")))
    (expect-eq !>(%.y) !>((has out "/keep/ship/~wes")))
  ==
::
::  ---- follows are visible, both ways ----------------------------------------
::
++  test-sidebar-carries-no-roll
  ^-  tang
  =/  out=manx  (feed-page:vw-peopled ~)
  ;:  weld
    (expect-eq !>(%.y) !>((has out "/keep/follows")))
    (expect-eq !>(%.n) !>((has out "/keep/ship/~wes")))
    (expect-eq !>(%.n) !>((has out "follows you")))
  ==
::
++  test-follows-page-counts-both-directions
  ^-  tang
  =/  out=manx  follows-page:vw-peopled
  ;:  weld
    (expect-eq !>(%.y) !>((has out "following · 1")))
    (expect-eq !>(%.y) !>((has out "followers · 1")))
    (expect-eq !>(%.y) !>((has out "follow back")))
    (expect-eq !>(%.y) !>((has out ">unfollow<")))
    (expect-eq !>(%.n) !>((has out "pals on keep")))
  ==
::
::  a count of zero still renders: the fold is how you learn the row exists
++  test-follows-page-counts-nobody
  ^-  tang
  (expect-eq !>(%.y) !>((has follows-page:vw "followers · 0")))
::
++  test-follows-page-suggests-unfollowed-pals
  ^-  tang
  =/  v=view:ui  [~zod ~2026.1.1 ~[~wes ~bus] (sy ~[~wes ~bus]) (sy ~[~wes]) ~ ~ ~ ~]
  =/  w  ~(. ui v)
  (expect-eq !>(%.y) !>((has follows-page:w "pals on keep · 1")))
::
++  test-ship-page-says-follows-you
  ^-  tang
  =/  out=manx  (user-page:vw-peopled ~bus ~ ~)
  ;:  weld
    (expect-eq !>(%.y) !>((has out ">follows you<")))
    (expect-eq !>(%.y) !>((has out ">follow<")))
    (expect-eq !>(%.n) !>((has out ">unfollow<")))
  ==
::
++  test-ship-page-offers-unfollow-once-followed
  ^-  tang
  =/  out=manx  (user-page:vw-peopled ~wes ~ ~)
  ;:  weld
    (expect-eq !>(%.y) !>((has out "✓ following")))
    (expect-eq !>(%.y) !>((has out ">unfollow<")))
    (expect-eq !>(%.n) !>((has out ">follows you<")))
  ==
::
--
