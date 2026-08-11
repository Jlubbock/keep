/-  keep, kt=keep-talk
/+  default-agent, dbug, kc=keep-core
::
|%
+$  card  card:agent:gall
+$  id    id:keep
::
::  frozen: what was actually written to disk. never change this.
+$  thread-2  [rev=@ud =talk:kt]
::
+$  versioned-state  $%(state-0 state-1 state-2 state-3)
::
+$  state-0
  $:  %0
      ours=(map id thread-2)
      tails=(map [host=ship art=id] @ud)
      heard=(map [host=ship art=id] talk:kt)
      checked=(map id verdict:keep)
  ==
::
+$  state-1
  $:  %1
      ours=(map id thread-2)
      tails=(map [host=ship art=id] @ud)
      heard=(map [host=ship art=id] talk:kt)
      checked=(map id verdict:keep)
      banned=(set ship)
      tier=rank:title
  ==
::
+$  state-2
  $:  %2
      ours=(map id thread-2)
      tails=(map [host=ship art=id] @ud)
      heard=(map [host=ship art=id] talk:kt)
      checked=(map id verdict:keep)
      banned=(set ship)
      tier=rank:title
  ==
::
+$  state-3
  $:  %3
      ours=(map id thread:kt)             ::  threads we host
      tails=(map [host=ship art=id] @ud)  ::  next /talk-at marker keened
      pulls=(map [host=ship art=id] [want=@ud done=@ud])
      heard=(map [host=ship art=id] talk:kt)
      checked=(map id verdict:keep)       ::  by note id, judged once each
      banned=(set ship)                   ::  refused everywhere, on sight
      tier=rank:title                     ::  smallest class admitted; %pawn is all
  ==
::
++  cap-body   65.536                     ::  bytes; every grow carries the thread
++  cap-notes  500
--
::
%-  agent:dbug
=|  state-3
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    hc    ~(. +> bowl)
::
::  %pawn, not the bunt: a bunted rank is %czar, which is "galaxies only"
++  on-init  `this(tier %pawn)
++  on-save  !>(state)
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  ?-    -.old
      %3  `this(state old)
  ::
      %2
    =/  i  (induct:hc ours.old %.y)
    =/  r  (rewalk:hc tails.old)
    :_  %=  this
          state  [%3 ours.i tails.r ~ heard.old checked.old banned.old tier.old]
        ==
    (weld cards.i cards.r)
  ::
      %1
    =/  i  (induct:hc ours.old %.n)
    =/  r  (rewalk:hc tails.old)
    :_  %=  this
          state  [%3 ours.i tails.r ~ heard.old checked.old banned.old tier.old]
        ==
    (weld cards.i cards.r)
  ::
      %0
    =/  i  (induct:hc ours.old %.n)
    =/  r  (rewalk:hc tails.old)
    :_  this(state [%3 ours.i tails.r ~ heard.old checked.old ~ %pawn])
    (weld cards.i cards.r)
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
      [%x %ours ~]   ``noun+!>(ours)
      [%x %tails ~]  ``noun+!>(tails)
      [%x %rules ~]  ``noun+!>([banned tier])
  ::
  ::  ours and heard answer in one shape, so the renderer has one code path
      [%x %thread @ ~]
    =/  art=id  (slav %uv i.t.t.path)
    =/  res=(unit [open=? notes=(list judged:kt)])
      ?~  got=(~(get by ours) art)  ~
      `[open.talk.u.got (judge-all:hc art notes.talk.u.got)]
    ``noun+!>(res)
  ::
      [%x %heard @ @ ~]
    =/  host=ship  (slav %p i.t.t.path)
    =/  art=id     (slav %uv i.t.t.t.path)
    =/  res=(unit [open=? notes=(list judged:kt)])
      ?~  got=(~(get by heard) [host art])  ~
      `[open.u.got (judge-all:hc art notes.u.got)]
    ``noun+!>(res)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
  ::
  ::  ---- local ---------------------------------------------------------------
      %keep-talk-action
    ?>  =(our.bowl src.bowl)
    =/  act  !<(action:kt vase)
    ?-    -.act
        %open
      ?^  got=(~(get by ours) art.act)
        ?:  open.talk.u.got  `this
        =/  b  (bump:hc art.act u.got [%.y notes.talk.u.got])
        :_  this(ours (~(put by ours) art.act new.b))
        cards.b
      ?.  (~(has by our-posts:hc) art.act)  ~|(%talk-no-such-post !!)
      =/  b  (bump:hc art.act [0 1 *talk:kt] [%.y ~])
      :_  this(ours (~(put by ours) art.act new.b))
      cards.b
    ::
        %shut
      ?~  got=(~(get by ours) art.act)  `this
      ?.  open.talk.u.got  `this
      =/  b  (bump:hc art.act u.got [%.n notes.talk.u.got])
      :_  this(ours (~(put by ours) art.act new.b))
      cards.b
    ::
        %say
      ?:  =('' body.act)  ~|(%talk-empty !!)
      =/  n=note:kt  (make-note:hc art.act parent.act body.act)
      ?:  =(our.bowl host.act)
        =/  m  (hear:hc art.act n our.bowl)
        [cards.m this(ours ours.m, checked checked.m)]
      :_  this
      :~  :^  %pass  /say/(scot %p host.act)  %agent
          :^  [host.act %keep-talk]  %poke  %keep-talk-gossip
          !>(`gossip:kt`[%say art.act n])
      ==
    ::
        %read
      ?:  =(our.bowl host.act)  `this
      ?:  (~(has by tails) [host.act art.act])  `this
      :_  this(tails (~(put by tails) [host.act art.act] first:kc))
      ~[(seen:hc host.act art.act first:kc)]
    ::
        %drop
      ?~  got=(~(get by ours) art.act)  `this
      :_  this(ours (~(del by ours) art.act))
      %+  weld
        (span:hc (talk-spur:kc art.act) low.u.got rev.u.got)
      (span:hc (talk-at-spur:kc art.act) 1 rev.u.got)
    ::
        %snip
      ?~  got=(~(get by ours) art.act)  `this
      =/  rest=(list note:kt)
        %+  skip  notes.talk.u.got
        |=(n=note:kt =(note.act (nid:hc art.act n)))
      ?:  =(rest notes.talk.u.got)  `this
      =/  b  (bump:hc art.act u.got [open.talk.u.got rest])
      :_  this(ours (~(put by ours) art.act new.b))
      cards.b
    ::
        %ban
      ?:  =(our.bowl who.act)  ~|(%talk-ban-self !!)
      `this(banned (~(put in banned) who.act))
    ::
        %unban
      `this(banned (~(del in banned) who.act))
    ::
        %tier
      `this(tier rank.act)
    ==
  ::
  ::  ---- network -------------------------------------------------------------
      %keep-talk-gossip
    ?>  !=(our.bowl src.bowl)
    =/  gos  !<(gossip:kt vase)
    ?-    -.gos
        %say
      ?.  =(src.bowl who.note.gos)  ~|(%talk-not-yours !!)
      =/  m  (hear:hc art.gos note.gos src.bowl)
      [cards.m this(ours ours.m, checked checked.m)]
    ==
  ==
::
++  on-watch  on-watch:def
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%say @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep-talk: {<(slav %p i.t.wire)>} refused the comment" u.p.sign)
    `this
  ::
      [%refresh ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep-talk: %keep refused a refresh" u.p.sign)
    `this
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ::  the debounce fired: pull the newest snapshot we have heard of, once
  ?:  ?=([%behn %wake *] sign-arvo)
    ?.  ?=([%pull @ @ ~] wire)  `this
    =/  host=ship  (slav %p i.t.wire)
    =/  art=id     (slav %uv i.t.t.wire)
    ?~  got=(~(get by pulls) [host art])  `this
    ?:  (lte want.u.got done.u.got)  `this
    :_  this(pulls (~(put by pulls) [host art] [want.u.got want.u.got]))
    ~[(pull:hc host art want.u.got)]
  ::  a keen returns %sage, not %tune; the value is q.q.sage
  ?.  ?=([%ames %sage *] sign-arvo)  (on-arvo:def wire sign-arvo)
  =/  =sage:mess:ames  sage.sign-arvo
  ?+    wire  `this
  ::
  ::  ---- a /talk-at marker: the thread moved -----------------------------------
      [%seen @ @ @ ~]
    =/  at=@ud     (slav %ud i.t.wire)
    =/  host=ship  (slav %p i.t.t.wire)
    =/  art=id     (slav %uv i.t.t.t.wire)
    ::  markers are never tombed while the thread lives, so an empty sage
    ::  here is the tomb of a dropped thread: stop following
    ?:  ?=(~ q.sage)
      :-  ~
      %=  this
        tails  (~(del by tails) [host art])
        pulls  (~(del by pulls) [host art])
        heard  (~(del by heard) [host art])
      ==
    ::  a burst of markers coalesces into one pull at the newest revision:
    ::  each marker raises want and arms a timer, the first wake pulls
    =/  w=(unit [want=@ud done=@ud])  (~(get by pulls) [host art])
    :_  %=  this
          tails  (~(put by tails) [host art] +(at))
          pulls  (~(put by pulls) [host art] [at ?~(w 0 done.u.w)])
        ==
    ~[(seen:hc host art +(at)) (hold:hc host art)]
  ::
  ::  ---- a /talk snapshot -------------------------------------------------------
      [%snap @ @ @ ~]
    =/  host=ship  (slav %p i.t.t.wire)
    =/  art=id     (slav %uv i.t.t.t.wire)
    ::  empty means the pull lost the grow/tomb race; the next marker re-pulls
    ?:  ?=(~ q.sage)  `this
    ::  ;; is a hard cast; +mule installs a null scry gate, nothing inside may .^
    =/  res  (mule |.(;;(talk:kt q.q.sage)))
    ?:  ?=(%| -.res)
      %-  (slog leaf+"keep-talk: unreadable thread from {<host>}" ~)
      `this
    =/  t=talk:kt  p.res
    :-  ~
    %=  this
      heard    (~(put by heard) [host art] t)
      checked  (judge-new:hc art notes.t)
    ==
  ::
  ::  pre-%3 subscriptions keened /talk directly; they fire as the host
  ::  grows, and the rewalked /talk-at tail already covers them
      [%tail @ @ @ ~]  `this
  ==
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
::
++  nid
  |=  [art=id:keep n=note:kt]
  ^-  id:keep
  (sain-note:kt art who.n lyfe.n wen.n parent.n body.n)
::
++  has-note
  |=  [art=id:keep ns=(list note:kt) i=id:keep]
  ^-  ?
  ?~  ns  %.n
  ?:  =(i (nid art i.ns))  %.y
  $(ns t.ns)
::
::  ---- hosting ---------------------------------------------------------------
::
::  every write lands here: local %say and remote gossip take the same door,
::  so the host's own notes are held to the same verdict as a stranger's
++  hear
  |=  [art=id:keep n=note:kt from=ship]
  ^-  $:  cards=(list card)
          ours=(map id:keep thread:kt)
          checked=(map id:keep verdict:keep)
      ==
  ?~  got=(~(get by ours) art)  ~|(%talk-closed !!)
  ?.  open.talk.u.got  ~|(%talk-closed !!)
  ::  the host is never banned or under-tiered on its own thread
  ?:  &(!=(our.bowl from) (~(has in banned) from))  ~|(%talk-banned !!)
  ?.  |(=(our.bowl from) (may-tier:kc tier from))  ~|(%talk-tier !!)
  ?.  (may-read art from)  ~|(%talk-not-allowed !!)
  ?:  =('' body.n)  ~|(%talk-empty !!)
  ?:  (gth (met 3 body.n) cap-body)  ~|(%talk-too-long !!)
  ?:  (gte (lent notes.talk.u.got) cap-notes)  ~|(%talk-full !!)
  =/  i=id:keep  (nid art n)
  ?:  (has-note art notes.talk.u.got i)  [~ ours checked]
  ?.  ?|  ?=(~ parent.n)
          (has-note art notes.talk.u.got u.parent.n)
      ==
    ~|(%talk-no-parent !!)
  ?.  =(%good (sound-note art n))  ~|(%talk-bad-signature !!)
  =/  b  (bump art u.got [%.y (snoc notes.talk.u.got n)])
  :+  cards.b
    (~(put by ours) art new.b)
  (~(put by checked) i %good)
::
::  ---- growing and tombing ----------------------------------------------------
::
::  the index pattern, split in two: /talk-at is a permanent trail of tiny
::  markers readers tail, /talk holds the prose and keeps only a two-revision
::  live window. a keen sent to an already-tombed revision is never answered
::  (C5.8 measures exactly that), so readers are never pointed below the window
++  bump
  |=  [art=id:keep t=thread:kt new-talk=talk:kt]
  ^-  [new=thread:kt cards=(list card)]
  =/  n=@ud  +(rev.t)
  =/  new=thread:kt  [n ?:((lte n 1) 1 (dec n)) new-talk]
  :-  new
  ;:  weld
    ~[(grow-at art n) (grow art new-talk) (refresh art)]
    ?:  (lte n 2)  ~
    (span (talk-spur:kc art) low.t (sub n 2))
  ==
::
++  grow
  |=  [art=id:keep t=talk:kt]
  ^-  card
  [%pass /grow %grow (talk-spur:kc art) noun+t]
::
++  grow-at
  |=  [art=id:keep rev=@ud]
  ^-  card
  [%pass /grow %grow (talk-at-spur:kc art) noun+rev]
::
++  span
  |=  [spur=path from=@ud to=@ud]
  ^-  (list card)
  ?:  =(0 to)  ~
  =/  n=@ud  from
  |-  ^-  (list card)
  ?:  (gth n to)  ~
  [[%pass /tomb %tomb [%ud n] spur] $(n +(n))]
::
++  refresh
  |=  art=id:keep
  ^-  card
  :^  %pass  /refresh  %agent
  [[our.bowl %keep] %poke %keep-talk-refresh !>(art)]
::
::  ---- reading ----------------------------------------------------------------
::
++  seen
  |=  [host=ship art=id:keep at=@ud]
  ^-  card
  :^  %pass  /seen/(scot %ud at)/(scot %p host)/(scot %uv art)  %keen
  [%.n host (welp (base-of:kc %keep-talk at) (talk-at-spur:kc art))]
::
++  pull
  |=  [host=ship art=id:keep at=@ud]
  ^-  card
  :^  %pass  /snap/(scot %ud at)/(scot %p host)/(scot %uv art)  %keen
  [%.n host (welp (base-of:kc %keep-talk at) (talk-spur:kc art))]
::
++  hold
  |=  [host=ship art=id:keep]
  ^-  card
  [%pass /pull/(scot %p host)/(scot %uv art) %arvo %b %wait (add now.bowl ~s1)]
::
::  ---- migration --------------------------------------------------------------
::
::  one-time, from on-load: pre-%3 threads hold every /talk revision live and
::  no /talk-at trail. tomb down to the head (unless an earlier load already
::  swept — re-tombing is not known to be safe), then lay the trail
++  induct
  |=  [m=(map id:keep thread-2) swept=?]
  ^-  [cards=(list card) ours=(map id:keep thread:kt)]
  =/  ls=(list [art=id:keep t=thread-2])  ~(tap by m)
  =|  ours=(map id:keep thread:kt)
  =|  cards=(list card)
  |-  ^-  [cards=(list card) ours=(map id:keep thread:kt)]
  ?~  ls  [cards ours]
  =/  art  art.i.ls
  =/  t    t.i.ls
  %=  $
    ls    t.ls
    ours  (~(put by ours) art [rev.t rev.t talk.t])
    cards
      ;:  weld
        =/  n=@ud  1
        |-  ^-  (list card)
        ?:  (gth n rev.t)  ~
        [(grow-at art n) $(n +(n))]
      ::
        ?:  swept  ~
        (span (talk-spur:kc art) 1 ?:((lte rev.t 1) 0 (dec rev.t)))
      ::
        cards
      ==
  ==
::
::  pre-%3 tails counted /talk revisions; under %3 they count /talk-at
::  markers, so every follow restarts at marker 1 and walks the new trail
++  rewalk
  |=  m=(map [host=ship art=id:keep] @ud)
  ^-  [cards=(list card) tails=(map [host=ship art=id:keep] @ud)]
  =/  ls=(list [p=[host=ship art=id:keep] q=@ud])  ~(tap by m)
  =|  out=(map [host=ship art=id:keep] @ud)
  =|  cards=(list card)
  |-  ^-  [cards=(list card) tails=(map [host=ship art=id:keep] @ud)]
  ?~  ls  [cards out]
  %=  $
    ls     t.ls
    out    (~(put by out) p.i.ls 1)
    cards  [(seen host.p.i.ls art.p.i.ls 1) cards]
  ==
::
::  ---- what %keep knows ------------------------------------------------------
::
++  our-posts
  ^-  (map id:keep item:keep)
  .^  (map id:keep item:keep)  %gx
  /(scot %p our.bowl)/keep/(scot %da now.bowl)/posts/noun
  ==
::
++  may-read
  |=  [art=id:keep who=ship]
  ^-  ?
  .^  ?  %gx
  /(scot %p our.bowl)/keep/(scot %da now.bowl)/may-read/(scot %uv art)/(scot %p who)/noun
  ==
::
::  ---- provenance ------------------------------------------------------------
::
++  our-life
  ^-  @ud
  .^(@ud %j /(scot %p our.bowl)/life/(scot %da now.bowl)/(scot %p our.bowl))
::
++  sign-id
  |=  [lyfe=@ud =id:keep]
  ^-  @ux
  =/  sec=@
    .^(@ %j /(scot %p our.bowl)/vein/(scot %da now.bowl)/(scot %ud lyfe))
  (sigh:as:(nol:nu:crub:crypto sec) id)
::
::  jael's %deed BLOCKS for an unknown ship, a life ahead of theirs, or an
::  old life it no longer keeps — and who/lyfe come from a stranger's note.
::  %lyfe answers for anybody, so gate on that first.
++  pass-of
  |=  [who=@p lyfe=@ud]
  ^-  (unit @)
  =/  us=@ta   (scot %p our.bowl)
  =/  wen=@ta  (scot %da now.bowl)
  =/  him=@ta  (scot %p who)
  =/  lyf=(unit @ud)  .^((unit @ud) %j /[us]/lyfe/[wen]/[him])
  ?~  lyf  ~
  ?.  =(lyfe u.lyf)  ~
  =/  ded  .^([@ud pas=@ *] %j /[us]/deed/[wen]/[him]/(scot %ud lyfe))
  `pas.ded
::
++  make-note
  |=  [art=id:keep parent=(unit id:keep) body=@t]
  ^-  note:kt
  =/  lyfe=@ud  our-life
  =/  n=note:kt  [now.bowl our.bowl lyfe parent body 0x0]
  n(sig (sign-id lyfe (nid art n)))
::
++  sound-note
  |=  [art=id:keep n=note:kt]
  ^-  verdict:keep
  ?~  pas=(pass-of who.n lyfe.n)  %cold
  ?:((safe:as:(com:nu:crub:crypto u.pas) sig.n (nid art n)) %good %forged)
::
::  ---- verdicts --------------------------------------------------------------
::
::  from `checked` only, never a fresh judgment: this runs inside on-peek,
::  where a jael scry is not a place we want to be
++  judge-all
  |=  [art=id:keep ns=(list note:kt)]
  ^-  (list judged:kt)
  ?~  ns  ~
  :_  $(ns t.ns)
  [i.ns (~(get by checked) (nid art i.ns))]
::
::  judged once each: a verdict is over immutable bytes, and pass-of costs
::  two jael scries per note
++  judge-new
  |=  [art=id:keep ns=(list note:kt)]
  ^-  (map id:keep verdict:keep)
  =/  ck  checked
  |-  ^-  (map id:keep verdict:keep)
  ?~  ns  ck
  =/  i=id:keep  (nid art i.ns)
  ?:  (~(has by ck) i)  $(ns t.ns)
  $(ns t.ns, ck (~(put by ck) i (sound-note art i.ns)))
--
