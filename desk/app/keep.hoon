/-  keep, kt=keep-talk
/+  default-agent, dbug, srv=server, ui=keep-ui, kc=keep-core
/*  style-css  %css  /ui/style/css
/*  app-js     %js   /ui/app/js
::
|%
+$  card   card:agent:gall
+$  id     id:keep
+$  lyst   lyst:keep
+$  entry  entry:keep
+$  feed   feed:keep
::
::  not `list`: that shadows the stdlib mold in every arm of this file
+$  roster
  $:  members=(set ship)
      salt=@uvH
      log=(list entry)                 ::  what we have grown here, newest last
  ==
::
::  frozen: what was actually written to disk. never change these.
+$  head-0  [wen=@da terms=@t title=(unit @t)]
+$  item-0  [head=head-0 =page]
::
+$  versioned-state
  $%(state-0 state-1 state-2 state-3 state-4 state-5 state-6)
::
+$  state-0
  $:  %0
      posts=(map id item-0)
      lists=(map lyst roster)
      subs=(map feed @ud)
      wall=(list [via=feed =entry])
      refs=(set entry)
      heads=(map entry head-0)
      seen=(map entry page)
      off=(set ship)
  ==
::
+$  state-1
  $:  %1
      posts=(map id item-0)
      lists=(map lyst roster)
      subs=(map feed @ud)
      wall=(list [via=feed =entry])
      refs=(set entry)
      heads=(map entry head-0)
      seen=(map entry page)
      off=(set ship)
      sites=(map @t id)
  ==
::
+$  state-2
  $:  %2
      posts=(map id item-0)
      lists=(map lyst roster)
      subs=(map feed @ud)              ::  feed -> revision we are keened on
      wall=(list [via=feed =entry])    ::  newest first
      refs=(set entry)                 ::  every entry now walled
      heads=(map entry head-0)         ::  fetched eagerly
      seen=(map entry page)            ::  fetched on %open
      off=(set ship)                   ::  ships confirmed not running %keep
      sites=(map @t id)
      follows=(set ship)
  ==
::
+$  state-3
  $:  %3
      posts=(map id item:keep)
      lists=(map lyst roster)
      subs=(map feed @ud)
      wall=(list [via=feed =entry])
      refs=(set entry)
      heads=(map entry head:keep)
      seen=(map entry page)
      off=(set ship)
      sites=(map @t id)
      follows=(set ship)
      checked=(map entry ?)
      keeping=(map entry (set lyst))
  ==
::
+$  state-4
  $:  %4
      posts=(map id item:keep)
      lists=(map lyst roster)
      subs=(map feed @ud)
      wall=(list [via=feed =entry])
      refs=(set entry)
      heads=(map entry head:keep)
      seen=(map entry page)
      off=(set ship)
      sites=(map @t id)
      follows=(set ship)
      checked=(map entry ?)
      keeping=(map entry (set lyst))
  ==
::
+$  state-5
  $:  %5
      posts=(map id item:keep)
      lists=(map lyst roster)
      subs=(map feed @ud)
      wall=(list [via=feed =entry])
      refs=(set entry)
      heads=(map entry head:keep)
      seen=(map entry page)
      off=(set ship)
      sites=(map @t id)
      follows=(set ship)
      checked=(map entry ?)
      keeping=(map entry (set lyst))
      pending=(map feed lyst)          ::  invites awaiting %accept
  ==
::
+$  state-6
  $:  %6
      posts=(map id item:keep)
      lists=(map lyst roster)
      subs=(map feed @ud)
      wall=(list [via=feed =entry])
      refs=(set entry)
      heads=(map entry head:keep)
      seen=(map entry page)
      off=(set ship)
      sites=(map @t id)
      follows=(set ship)
      checked=(map entry verdict:keep)
      keeping=(map entry (set lyst))
      pending=(map feed lyst)
  ==
--
::
%-  agent:dbug
=|  state-6
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    hc    ~(. +> bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  =/  boot=(list card)
    :~  [%pass /bind %arvo %e %connect [~ /keep] dap.bowl]
        [%pass /pals %agent [our.bowl %pals] %watch /targets]
        (index-card:hc ~ ~)
    ==
  ;:  weld
    boot
    assets:hc
    (turn (unreached:hc known:hc) announce:hc)
  ==
::
++  on-save   !>(state)
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  ::
  =/  new=state-6
    ?-  -.old
      %6  old
    ::
        %5
      :*  %6
          posts.old
          lists.old
          subs.old
          wall.old  refs.old  heads.old  seen.old
          off.old  sites.old  follows.old
          (recheck:hc checked.old)
          keeping.old  pending.old
      ==
    ::
        %4
      :*  %6
          posts.old
          lists.old
          subs.old
          wall.old  refs.old  heads.old  seen.old
          off.old  sites.old  follows.old
          (recheck:hc checked.old)  keeping.old
          ~                              ::  pending
      ==
    ::
        %3
      :*  %6
          posts.old
          (wipe-logs:hc lists.old)
          subs.old
          ~                              ::  wall
          ~                              ::  refs
          ~                              ::  heads
          ~                              ::  seen
          off.old  sites.old  follows.old
          ~                              ::  checked
          keeping.old
          ~                              ::  pending
      ==
    ::
        %2
      :*  %6
          ~                              ::  posts   — old heads
          (wipe-logs:hc lists.old)       ::  logs    — pointed at those posts
          subs.old
          ~                              ::  wall    — refills from subs
          ~                              ::  refs
          ~                              ::  heads   — old shape
          ~                              ::  seen    — unjudgeable without heads
          off.old
          ~                              ::  sites   — pointed at dropped posts
          follows.old
          ~                              ::  checked
          ~                              ::  keeping
          ~                              ::  pending
      ==
    ::
        %1
      :*  %6
          ~  (wipe-logs:hc lists.old)  subs.old  ~  ~  ~  ~  off.old  ~
          (ships-of:hc subs.old)
          ~  ~  ~
      ==
    ::
        %0
      :*  %6
          ~  (wipe-logs:hc lists.old)  subs.old  ~  ~  ~  ~  off.old  ~
          (ships-of:hc subs.old)
          ~  ~  ~
      ==
    ==
  :_  this(state new)
  :+  [%pass /bind %arvo %e %connect [~ /keep] dap.bowl]
    (index-card:hc sites.new posts.new)
  assets:hc
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
    [%x %wall ~]   ``noun+!>(wall)
    [%x %heads ~]  ``noun+!>(heads)
    [%x %subs ~]   ``noun+!>(subs)
    [%x %posts ~]  ``noun+!>(posts)
    [%x %lists ~]  ``noun+!>((members-of:hc lists))
  ::  absent is not %forged: unjudged and judged-bad are different answers
    [%x %checked ~]  ``noun+!>(checked)
  ::  subs is who we tail, mechanically; follows is whose posts we asked for
    [%x %follows ~]  ``noun+!>(follows)
    [%x %pending ~]  ``noun+!>(pending)
  ::
  ::  for %keep-talk: may `who` be handed this article's pointer at all
      [%x %may-read @ @ ~]
    =/  art=id  (slav %uv i.t.t.path)
    =/  who=ship  (slav %p i.t.t.t.path)
    ``noun+!>((may-read:hc art who))
  ::
      [%x %item @ *]
    =/  e=entry  [(slav %p i.t.t.path) t.t.t.path]
    =/  res=(unit item:keep)
      =/  hed  (~(get by heads) e)
      =/  bod  (~(get by seen) e)
      ?~  hed  ~
      ?~  bod  ~
      `[u.hed u.bod]
    ``noun+!>(res)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
  ::
  ::  ---- local ---------------------------------------------------------------
      %keep-action
    ?>  =(our.bowl src.bowl)
    =/  act  !<(action:keep vase)
    ?-    -.act
    ::
    ::  ---- publishing --------------------------------------------------------
        %post
      =/  hash=@uvH      (sham page.act)
      =/  lyfe=@ud       our-life:hc
      =/  =id
        (sain:keep our.bowl lyfe now.bowl terms.act title.act hash)
      =/  hed=head:keep
        :*  now.bowl  our.bowl  lyfe  terms.act  title.act  hash
            (sign-id:hc lyfe id)
        ==
      =/  =item:keep     [hed page.act]
      =/  spur=path      (item-spur:hc id)
      =/  =entry         [our.bowl (welp (base:hc first:hc) spur)]
      =^  cards  lists   (fan-out:hc entry ~(tap in to.act))
      =/  grows=(list card)
        :~  [%pass /grow %grow (welp spur /head) noun+hed]
            [%pass /grow %grow (welp spur /body) noun+page.act]
        ==
      =/  new-posts  (~(put by posts) id item)
      =/  url=@t
        ?.  (~(has in to.act) %public)  ''
        (site-path:hc title.act)
      ::  id:keep, not id: `=/ =id` above shadows the bare mold here
      =/  new-sites=(map @t id:keep)
        ?:(=('' url) sites (~(put by sites) url id))
      =/  web=(list card)
        ?:  =('' url)  ~
        =/  art=card
          %+  cache:hc  url
          %-  manx-response:gen:srv
          (public-page:vw-bare [our.bowl entry `hed %.y %.n `url ~ ~] page.act ~)
        ~[art (index-card:hc new-sites new-posts)]
      :_  this(posts new-posts, sites new-sites)
      :(weld grows cards web (give:hc [%posted id entry]))
    ::
        %keep
      ?:  =(our.bowl ship.entry.act)  `this
      ?:  ?&  (~(has in to.act) %public)
              !(from-public:hc entry.act)
          ==
        ~|(%keep-would-expose-gated-address !!)
      ?:  =(`%forged (~(get by checked) entry.act))
        ~|(%keep-would-syndicate-forgery !!)
      ?:  =(`%cold (~(get by checked) entry.act))
        ~|(%keep-would-syndicate-unverified !!)
      ?~  bod=(~(get by seen) entry.act)
        =/  more=(list card)
          ?:((~(has by heads) entry.act) ~ ~[(fetch-head:hc entry.act)])
        :_  this(keeping (~(put by keeping) entry.act to.act))
        (weld more ~[(fetch-body:hc entry.act)])
      ?~  hed=(~(get by heads) entry.act)
        :_  this(keeping (~(put by keeping) entry.act to.act))
        ~[(fetch-head:hc entry.act)]
      =/  m  (mirror:hc u.hed u.bod ~(tap in to.act))
      :-  cards.m
      %=  this
        lists    lists.m
        posts    posts.m
        keeping  (~(del by keeping) entry.act)
      ==
    ::
    ::  ---- unpublishing ------------------------------------------------------
        %delete
      ?.  (~(has by posts) id.act)  `this
      =/  spur=path      (item-spur:hc id.act)
      =/  =entry         [our.bowl (welp (base:hc first:hc) spur)]
      =^  cards  lists   (unfan:hc entry)
      =/  new-posts      (~(del by posts) id.act)
      =/  url=(unit @t)  (site-of:hc entry)
      =/  new-sites      ?~(url sites (~(del by sites) u.url))
      =/  web=(list card)
        ?~  url  ~
        ~[(uncache:hc u.url) (index-card:hc new-sites new-posts)]
      ::  a reposter re-grew our bytes under their own /item, so tombing ours
      ::  ends our copy and not theirs
      =/  buries=(list card)
        :~  [%pass /tomb %tomb [%ud first:hc] (welp spur /head)]
            [%pass /tomb %tomb [%ud first:hc] (welp spur /body)]
        ==
      :_  this(posts new-posts, sites new-sites)
      %-  zing
      :~  cards  buries  web
          (talk-self:hc [%drop id.act])
          (give:hc [%deleted entry])
      ==
    ::
    ::  ---- reading -----------------------------------------------------------
        %open
      ?^  got=(~(get by seen) entry.act)
        :_  this
        (give:hc [%body entry.act u.got (~(get by checked) entry.act)])
      :_(this ~[(fetch-body:hc entry.act)])
    ::
    ::  ---- lists -------------------------------------------------------------
        %list
      ?:  =(%public lyst.act)  ~|(%keep-public-has-no-members !!)
      =/  lst=roster
        ?^  got=(~(get by lists) lyst.act)  u.got
        [~ (mint:hc lyst.act) ~]
      =/  new=(list ship)  ~(tap in (~(dif in members.act) members.lst))
      =/  all  (~(put by lists) lyst.act lst(members members.act))
      =/  hail=(list card)
        %-  zing
        %+  turn  new
        |=(w=ship (welcome:hc lyst.act salt.lst log.lst w))
      :_  this(lists all)
      (weld hail (give:hc (lists-of:hc all)))
    ::
        %admit
      ?:  =(%public lyst.act)  ~|(%keep-public-has-no-members !!)
      ?~  got=(~(get by lists) lyst.act)  ~|([%keep-no-such-list lyst.act] !!)
      =/  new=(list ship)  ~(tap in (~(dif in who.act) members.u.got))
      =/  all
        %+  ~(put by lists)  lyst.act
        u.got(members (~(uni in members.u.got) who.act))
      =/  hail=(list card)
        %-  zing
        %+  turn  new
        |=(w=ship (welcome:hc lyst.act salt.u.got log.u.got w))
      :_  this(lists all)
      (weld hail (give:hc (lists-of:hc all)))
    ::
        %evict
      ?:  =(%public lyst.act)  ~|(%keep-public-has-no-members !!)
      ?~  got=(~(get by lists) lyst.act)  ~|([%keep-no-such-list lyst.act] !!)
      =/  all
        %+  ~(put by lists)  lyst.act
        u.got(members (~(dif in members.u.got) who.act))
      :_  this(lists all)
      (give:hc (lists-of:hc all))
    ::
    ::  ---- following ---------------------------------------------------------
        %sub
      =/  f=feed  [who.act /index]
      =/  at=@ud  (~(gut by subs) f first)
      =/  ss      (~(put by subs) f at)
      =/  ff      (~(put in follows) who.act)
      :_  this(subs ss, follows ff)
      :-  (tail:hc f at)
      (give:hc (peers-of:hc ss off))
    ::
        %unsub
      =/  ff  (~(del in follows) who.act)
      :_  this(follows ff)
      (give:hc (peers-of:hc subs off))
    ::
    ::  ---- invites -----------------------------------------------------------
        %accept
      ?.  (~(has by pending) feed.act)  `this
      =/  pp  (~(del by pending) feed.act)
      =/  ss  (~(put by subs) feed.act first:hc)
      =/  ff  (~(put in follows) ship.feed.act)
      :_  this(subs ss, follows ff, pending pp)
      :-  (tail:hc feed.act first:hc)
      %+  weld
        (give:hc (peers-of:hc ss off))
      (give:hc [%pending (wait-of:hc pp)])
    ::
        %reject
      ?.  (~(has by pending) feed.act)  `this
      =/  pp  (~(del by pending) feed.act)
      :_  this(pending pp)
      (give:hc [%pending (wait-of:hc pp)])
    ==
  ::
  ::  ---- a hosted thread changed: re-cache its clearnet page -------------------
      %keep-talk-refresh
    ?>  =(our.bowl src.bowl)
    =/  art  !<(id vase)
    :_(this (recache:hc art))
  ::
  ::  ---- the interface -------------------------------------------------------
      %handle-http-request
    =+  !<([rid=@ta ir=inbound-request:eyre] vase)
    :_  this
    (serve:hc rid ir)
  ::
  ::  ---- network -------------------------------------------------------------
      %keep-gossip
    ?>  !=(our.bowl src.bowl)
    =/  gos  !<(gossip:keep vase)
    ?-    -.gos
    ::
        %invite
      =/  f=feed  [src.bowl path.gos]
      ?:  (~(has by subs) f)  `this
      ?:  (~(has by pending) f)  `this
      ::  any ship may invite us, so bound what one of them can park here
      ?:  (gte (waiting:hc src.bowl) 8)  `this
      =/  pp  (~(put by pending) f lyst.gos)
      :_  this(pending pp)
      (give:hc [%pending (wait-of:hc pp)])
    ::
        %announce
      =/  f=feed  [src.bowl /index]
      ?.  &((~(has in targets:hc) src.bowl) !(~(has by subs) f))
        `this
      =/  ss  (~(put by subs) f first)
      =/  oo  (~(del in off) src.bowl)
      :_  this(subs ss, off oo)
      :-  (tail:hc f first)
      (give:hc (peers-of:hc ss oo))
    ==
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  =(our.bowl src.bowl)
  ?+    path  (on-watch:def path)
      [%http-response *]  `this
      [%updates ~]   `this
      [%ui %wall ~]   :_(this ~[(gift:hc wall-now:hc)])
      [%ui %lists ~]  :_(this ~[(gift:hc lists-now:hc) (gift:hc pending-now:hc)])
      [%ui %peers ~]  :_(this ~[(gift:hc peers-now:hc)])
  ::
      [%ui %body @ *]
    =/  e=entry  [(slav %p i.t.t.path) t.t.t.path]
    ?~  got=(~(get by seen) e)  `this
    :_(this ~[(gift:hc [%body e u.got (~(get by checked) e)])])
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
  ::
      [?(%hey %ask) @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    =/  who=ship  (slav %p i.t.wire)
    ?^  p.sign
      =/  oo  (~(put in off) who)
      :_  this(off oo)
      (give:hc (peers-of:hc subs oo))
    =/  f=feed  [who /index]
    =/  ss      (~(put by subs) f first)
    =/  ff      ?:(?=(%hey i.wire) (~(put in follows) who) follows)
    :_  this(subs ss, follows ff)
    :-  (tail:hc f first)
    (give:hc (peers-of:hc ss off))
  ::
      [%self ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep: refused" u.p.sign)
    `this
  ::
      [%talk ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep: keep-talk refused" u.p.sign)
    `this
  ::
      [%poke @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep: {<(slav %p i.t.wire)>} refused an invite" u.p.sign)
    `this
  ::
      [%pals ~]
    ?+    -.sign  `this
        %kick
      :_  this
      ~[[%pass /pals %agent [our.bowl %pals] %watch /targets]]
    ::
        %fact
      :_  this
      (turn (unreached:hc known:hc) announce:hc)
    ==
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%eyre %bound *] sign-arvo)
    ~?  !accepted.sign-arvo  %keep-eyre-rejected-binding
    `this
  ::  a keen returns %sage, not %tune; the value is q.q.sage
  ?.  ?=([%ames %sage *] sign-arvo)  (on-arvo:def wire sign-arvo)
  =/  =sage:mess:ames  sage.sign-arvo
  ?+    wire  `this
  ::
  ::  ---- a head --------------------------------------------------------------
  ::
      [%head @ *]
    ?:  ?=(~ q.sage)  `this
    =/  e=entry  [(slav %p i.t.wire) t.t.wire]
    ::  ;; is a hard cast; +mule installs a null scry gate, nothing inside may .^
    =/  res  (mule |.(;;(head:keep q.q.sage)))
    ?:  ?=(%| -.res)
      %-  (slog leaf+"keep: unreadable head from {<ship.e>}" ~)
      `this
    =/  hed=head:keep  p.res
    =/  late=(unit verdict:keep)
      ?:  (~(has by checked) e)  ~
      ?~  bod=(~(get by seen) e)  ~
      ?~  want=(slaw %uv (last-of:hc path.e))  `%forged
      `(sound:hc hed u.bod u.want)
    =/  vote=(unit verdict:keep)  ?^(late late (~(get by checked) e))
    =/  done
      ?.  =(`%good vote)  ~
      ?~  bod=(~(get by seen) e)  ~
      (finish:hc e hed u.bod)
    :_  %=  this
          heads    (~(put by heads) e hed)
          checked  ?~(late checked (~(put by checked) e u.late))
          lists    ?~(done lists lists.u.done)
          posts    ?~(done posts posts.u.done)
          keeping  ?:(|((settled:hc vote) ?=(^ done)) (~(del by keeping) e) keeping)
        ==
    %+  weld  (give:hc [%head e hed])
    ?~(done ~ cards.u.done)
  ::
  ::  ---- a body --------------------------------------------------------------
      [%body @ *]
    ?:  ?=(~ q.sage)  `this
    =/  e=entry  [(slav %p i.t.wire) t.t.wire]
    =/  res  (mule |.(;;(page q.q.sage)))
    ?:  ?=(%| -.res)
      %-  (slog leaf+"keep: unreadable body from {<ship.e>}" ~)
      `this
    =/  bod=page  p.res
    =/  okay=(unit verdict:keep)  (judge:hc e bod)
    =/  done
      ?.  =(`%good okay)  ~
      ?~  hed=(~(get by heads) e)  ~
      (finish:hc e u.hed bod)
    :_  %=  this
          seen     (~(put by seen) e bod)
          checked  ?~(okay checked (~(put by checked) e u.okay))
          lists    ?~(done lists lists.u.done)
          posts    ?~(done posts posts.u.done)
          keeping  ?:(|((settled:hc okay) ?=(^ done)) (~(del by keeping) e) keeping)
        ==
    %+  weld  (give:hc [%body e bod okay])
    ?~(done ~ cards.u.done)
  ::
  ::  ---- an index revision ---------------------------------------------------
      [%feed @ @ *]
    =/  at=@ud    (slav %ud i.t.wire)
    =/  f=feed    [(slav %p i.t.t.wire) t.t.t.wire]
    ::  %sage collapses tombstone and failure into one empty q; step over
    ::  it rather than stall forever on a revision that will never come
    ?:  ?=(~ q.sage)
      :_  this(subs (~(put by subs) f +(at)))
      ~[(tail:hc f +(at))]
    =/  got  (mule |.(;;((list entry) q.q.sage)))
    ?:  ?=(%| -.got)
      %-  (slog leaf+"keep: unreadable index from {<ship.f>}" ~)
      :_  this(subs (~(put by subs) f +(at)))
      ~[(tail:hc f +(at))]
    =/  new=(list entry)  (skip p.got ~(has in refs))
    =/  fresh=(set entry)  (sy new)
    ::  a revision carries the whole index, so what it omits, the author deleted
    =/  cut  (prune:hc f p.got)
    =/  fold=(list [via=feed =entry])
      (flop (turn new |=(e=entry [f e])))
    =/  fetches=(list card)   (turn new fetch-head:hc)
    =/  arrivals=(list card)
      (zing (turn new |=(e=entry (give:hc [%arrived f e]))))
    =/  departures=(list card)
      (zing (turn gone.cut |=(e=entry (give:hc [%deleted e]))))
    :_  %=  this
          subs  (~(put by subs) f +(at))
          refs  (~(dif in (~(uni in refs) fresh)) (sy gone.cut))
          wall  (weld fold rest.cut)
        ==
    :(weld ~[(tail:hc f +(at))] fetches arrivals departures)
  ==
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
::
::  %gu not %gx: %gu says whether pals runs without crashing if it does not
++  targets
  ^-  (set ship)
  ?.  .^(? %gu /(scot %p our.bowl)/pals/(scot %da now.bowl)/$)  ~
  .^((set ship) %gx /(scot %p our.bowl)/pals/(scot %da now.bowl)/targets/noun)
::
::  ---- folds ------------------------------------------------------------
::
::  spelled out, not ~(run by ...): feed/roster hold a path, which is
::  recursive, and run is a wet gate whose product type is inferred over it
++  ships-of
  |=  s=(map feed @ud)
  ^-  (set ship)
  =/  fs=(list [p=feed q=@ud])  ~(tap by s)
  |-  ^-  (set ship)
  ?~  fs  ~
  (~(put in $(fs t.fs)) ship.p.i.fs)
::
++  members-of
  |=  m=(map lyst roster)
  ^-  (map lyst (set ship))
  =/  ls=(list [p=lyst q=roster])  ~(tap by m)
  |-  ^-  (map lyst (set ship))
  ?~  ls  ~
  (~(put by $(ls t.ls)) p.i.ls members.q.i.ls)
::
++  wait-of
  |=  m=(map feed lyst)
  ^-  (list [=feed =lyst])
  =/  fs=(list [p=feed q=lyst])  ~(tap by m)
  |-  ^-  (list [=feed =lyst])
  ?~  fs  ~
  [[p.i.fs q.i.fs] $(fs t.fs)]
::
++  waiting
  |=  who=ship
  ^-  @ud
  =/  fs=(list [p=feed q=lyst])  ~(tap by pending)
  |-  ^-  @ud
  ?~  fs  0
  ?.  =(who ship.p.i.fs)  $(fs t.fs)
  +($(fs t.fs))
::
::  a %keep waiting on this entry will never fire: judged, and not %good
++  settled
  |=  v=(unit verdict:keep)
  ^-  ?
  ?~  v  %.n
  ?!(=(%good u.v))
::
++  recheck
  |=  m=(map entry ?)
  ^-  (map entry verdict:keep)
  =/  es=(list [p=entry q=?])  ~(tap by m)
  |-  ^-  (map entry verdict:keep)
  ?~  es  ~
  (~(put by $(es t.es)) p.i.es ?:(q.i.es %good %forged))
::
++  wipe-logs
  |=  m=(map lyst roster)
  ^-  (map lyst roster)
  =/  ls=(list [p=lyst q=roster])  ~(tap by m)
  |-  ^-  (map lyst roster)
  ?~  ls  ~
  (~(put by $(ls t.ls)) p.i.ls q.i.ls(log ~))
::
++  known
  ^-  (set ship)
  =/  reached=(set ship)  (ships-of subs)
  (~(uni in reached) off)
::
++  unreached  |=(saw=(set ship) ~(tap in (~(dif in targets) saw)))
::
++  first        first:kc
++  base         base:kc
++  item-spur    item-spur:kc
++  member-spur  member-spur:kc
++  mint         |=(=lyst ^-(@uvH (mint:kc eny.bowl lyst)))
::
++  spread
  |=  [=lyst lst=roster es=(list entry)]
  ^-  (list card)
  ?:  =(%public lyst)
    ~[[%pass /grow %grow /index noun+es]]
  %+  turn  ~(tap in members.lst)
  |=  w=ship
  [%pass /grow %grow (member-spur lyst salt.lst w) noun+es]
::
++  fan-out
  |=  [e=entry to=(list lyst)]
  ^-  [(list card) (map lyst roster)]
  =/  lsts  lists
  |-  ^-  [(list card) (map lyst roster)]
  ?~  to  [~ lsts]
  =/  lst=roster
    ?^  got=(~(get by lsts) i.to)  u.got
    [~ (mint i.to) ~]
  =/  new=(list entry)
    =/  old=(list entry)  log.lst
    |-  ^-  (list entry)
    ?~  old  ~[e]
    [i.old $(old t.old)]
  =/  cs=(list card)  (spread i.to lst new)
  =^  more  lsts  $(to t.to, lsts (~(put by lsts) i.to lst(log new)))
  [(weld cs more) lsts]
::
++  unfan
  |=  e=entry
  ^-  [(list card) (map lyst roster)]
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  =/  lsts  lists
  |-  ^-  [(list card) (map lyst roster)]
  ?~  ls  [~ lsts]
  =/  new=(list entry)  (drop-entry log.q.i.ls e)
  ?:  =(new log.q.i.ls)  $(ls t.ls)
  =/  cs=(list card)  (spread p.i.ls q.i.ls new)
  =^  more  lsts  $(ls t.ls, lsts (~(put by lsts) p.i.ls q.i.ls(log new)))
  [(weld cs more) lsts]
::
++  prune
  |=  [f=feed es=(list entry)]
  ^-  [gone=(list entry) rest=(list [via=feed =entry])]
  =/  have=(set entry)  (sy es)
  =/  w  wall
  |-  ^-  [gone=(list entry) rest=(list [via=feed =entry])]
  ?~  w  [~ ~]
  =/  more  $(w t.w)
  ?.  &(=(f via.i.w) !(~(has in have) entry.i.w))
    [gone.more [i.w rest.more]]
  [[entry.i.w gone.more] rest.more]
::
++  welcome
  |=  [=lyst salt=@uvH log=(list entry) who=ship]
  ^-  (list card)
  =/  spur  (member-spur lyst salt who)
  :~  [%pass /grow %grow spur noun+log]
      :^  %pass  /poke/(scot %p who)  %agent
      [[who %keep] %poke %keep-gossip !>(`gossip:keep`[%invite lyst spur])]
  ==
::
++  from-public
  |=  e=entry
  ^-  ?
  =/  w  wall
  |-  ^-  ?
  ?~  w  %.n
  ?:  &(=(e entry.i.w) =(/index path.via.i.w))  %.y
  $(w t.w)
::
++  announce  (hail /hey)
++  probe     (hail /ask)
::
++  hail
  |=  pre=path
  |=  who=ship
  ^-  card
  :^  %pass  (welp pre /(scot %p who))  %agent
  [[who %keep] %poke %keep-gossip !>(`gossip:keep`[%announce ~])]
::
++  tail
  |=  [f=feed at=@ud]
  ^-  card
  :^  %pass  [%feed (scot %ud at) (scot %p ship.f) path.f]  %keen
  [%.n ship.f (welp (base at) path.f)]
::
++  halt
  |=  [f=feed at=@ud]
  ^-  card
  :^  %pass  [%feed (scot %ud at) (scot %p ship.f) path.f]  %arvo
  [%a %yawn ship.f (welp (base at) path.f)]
::
++  fetch-head
  |=  e=entry
  ^-  card
  :^  %pass  [%head (scot %p ship.e) path.e]  %keen
  [%.n ship.e (welp path.e /head)]
::
++  fetch-body
  |=  e=entry
  ^-  card
  :^  %pass  [%body (scot %p ship.e) path.e]  %keen
  [%.n ship.e (welp path.e /body)]
::
::  ---- provenance ------------------------------------------------------------
::
++  our-life
  ^-  @ud
  .^(@ud %j /(scot %p our.bowl)/life/(scot %da now.bowl)/(scot %p our.bowl))
::
++  sign-id
  |=  [lyfe=@ud =id]
  ^-  @ux
  =/  sec=@
    .^(@ %j /(scot %p our.bowl)/vein/(scot %da now.bowl)/(scot %ud lyfe))
  (sigh:as:(nol:nu:crub:crypto sec) id)
::
::  jael's %deed BLOCKS for an unknown ship, a life ahead of theirs, or an
::  old life it no longer keeps — and who/lyfe come from a stranger's head.
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
::  ~ is "not yet": ours, or the head has not landed. every other answer
::  is a verdict we are done forming.
++  judge
  |=  [e=entry bod=page]
  ^-  (unit verdict:keep)
  ?:  =(our.bowl ship.e)  ~
  ?~  hed=(~(get by heads) e)  ~
  ?~  want=(slaw %uv (last-of path.e))  `%forged
  `(sound u.hed bod u.want)
::
++  sound
  |=  [hed=head:keep bod=page want=@uvH]
  ^-  verdict:keep
  ?.  =(hash.hed (sham bod))  %forged
  =/  =id:keep
    (sain:keep who.hed lyfe.hed wen.hed terms.hed title.hed hash.hed)
  ?.  =(id want)  %forged
  ?~  pas=(pass-of who.hed lyfe.hed)  %cold
  ?:((safe:as:(com:nu:crub:crypto u.pas) sig.hed id) %good %forged)
::
::  ---- hosting ---------------------------------------------------------------
::
++  mirror
  |=  [hed=head:keep bod=page to=(list lyst)]
  ^-  [cards=(list card) lists=(map lyst roster) posts=(map id item:keep)]
  =/  =id:keep
    (sain:keep who.hed lyfe.hed wen.hed terms.hed title.hed hash.hed)
  =/  spur=path   (item-spur id)
  =/  mine=entry  [our.bowl (welp (base first) spur)]
  =^  cards  lists  (fan-out mine to)
  =/  grows=(list card)
    :~  [%pass /grow %grow (welp spur /head) noun+hed]
        [%pass /grow %grow (welp spur /body) noun+bod]
    ==
  [(weld grows cards) lists (~(put by posts) id [hed bod])]
::
++  finish
  |=  [e=entry hed=head:keep bod=page]
  ^-  (unit [cards=(list card) lists=(map lyst roster) posts=(map id item:keep)])
  ?~  to=(~(get by keeping) e)  ~
  `(mirror hed bod ~(tap in u.to))
::
::  ---- comments --------------------------------------------------------------
::
::  the gate %keep-talk asks before accepting a comment: could this ship have
::  been handed the article's pointer
++  may-read
  |=  [art=id who=ship]
  ^-  ?
  ?:  =(our.bowl who)  %.y
  =/  e=entry  [our.bowl (welp (base first) (item-spur art))]
  =/  fanned-on=(set lyst)  (fanned e)
  ?:  (~(has in fanned-on) %public)  %.y
  =/  on=(list lyst)  ~(tap in fanned-on)
  |-  ^-  ?
  ?~  on  %.n
  ?~  got=(~(get by lists) i.on)  $(on t.on)
  ?:  (~(has in members.u.got) who)  %.y
  $(on t.on)
::
::  %gu not %gx: %gu says whether keep-talk runs without crashing if it does not
++  talk-live
  ^-  ?
  .^(? %gu /(scot %p our.bowl)/keep-talk/(scot %da now.bowl)/$)
::
++  talk-self
  |=  act=action:kt
  ^-  (list card)
  ?.  talk-live  ~
  ~[[%pass /talk %agent [our.bowl %keep-talk] %poke %keep-talk-action !>(act)]]
::
++  talk-rules
  ^-  (unit [banned=(set ship) tier=rank:title])
  ?.  talk-live  ~
  :-  ~
  .^  [(set ship) rank:title]  %gx
  /(scot %p our.bowl)/keep-talk/(scot %da now.bowl)/rules/noun
  ==
::
++  talk-view
  |=  e=entry
  ^-  (unit tv:ui)
  ?.  talk-live  ~
  ?~  i=(slaw %uv (last-of path.e))  ~
  =/  us=@ta   (scot %p our.bowl)
  =/  wen=@ta  (scot %da now.bowl)
  ?:  =(our.bowl ship.e)
    .^  (unit tv:ui)  %gx
    /[us]/keep-talk/[wen]/thread/(scot %uv u.i)/noun
    ==
  .^  (unit tv:ui)  %gx
  /[us]/keep-talk/[wen]/heard/(scot %p ship.e)/(scot %uv u.i)/noun
  ==
::
++  recache
  |=  art=id
  ^-  (list card)
  ?~  got=(~(get by posts) art)  ~
  =/  e=entry  [our.bowl (welp (base first) (item-spur art))]
  ?~  url=(site-of e)  ~
  :_  ~
  %+  cache  u.url
  %-  manx-response:gen:srv
  %^    public-page:vw-bare
      [our.bowl e `head.u.got %.y %.n url ~ ~]
    page.u.got
  (talk-view e)
::
::  ---- clearnet --------------------------------------------------------------
::
++  cache
  |=  [url=@t pay=simple-payload:http]
  ^-  card
  [%pass /eyre/cache %arvo %e %set-response url `[%.n %payload pay]]
::
++  uncache
  |=  url=@t
  ^-  card
  [%pass /eyre/cache %arvo %e %set-response url ~]
::
++  assets
  ^-  (list card)
  :~  (cache '/keep/style.css' (css-response:gen:srv (as-octs:mimes:html style-css)))
      (cache '/keep/app.js' (js-response:gen:srv (as-octs:mimes:html app-js)))
  ==
::
++  slugify    slugify:kc
++  site-path  |=(tit=(unit @t) ^-(@t (site-path:kc sites tit)))
::
++  public-rows
  |=  [ss=(map @t id) ps=(map id item:keep)]
  ^-  (list row:ui)
  =/  ls=(list [p=@t q=id])  ~(tap by ss)
  =/  rs=(list row:ui)
    |-  ^-  (list row:ui)
    ?~  ls  ~
    ?~  got=(~(get by ps) q.i.ls)  $(ls t.ls)
    =/  e=entry  [our.bowl (welp (base first) (item-spur q.i.ls))]
    [[our.bowl e `head.u.got %.y %.n `p.i.ls ~ ~] $(ls t.ls)]
  (by-date rs)
::
++  index-card
  |=  [ss=(map @t id) ps=(map id item:keep)]
  ^-  card
  %+  cache  '/keep/index'
  (manx-response:gen:srv (public-index:vw-bare (public-rows ss ps)))
::
++  site-of
  |=  e=entry
  ^-  (unit @t)
  ?.  =(our.bowl ship.e)  ~
  ?~  i=(slaw %uv (last-of path.e))  ~
  =/  ls=(list [p=@t q=id])  ~(tap by sites)
  |-  ^-  (unit @t)
  ?~  ls  ~
  ?:  =(u.i q.i.ls)  `p.i.ls
  $(ls t.ls)
::
::  ---- the interface ---------------------------------------------------------
::
++  vw  ~(. ui view-now)
::
++  vw-bare  ~(. ui `view:ui`[our.bowl now.bowl ~ ~ ~ ~ ~ ~])
::
++  view-now
  ^-  view:ui
  :*  our.bowl
      now.bowl
      live-pals
      (ships-of subs)
      follows
      off
      roll-list
      (wait-of pending)
  ==
::
++  live-pals
  ^-  (list ship)
  =/  on-keep=(set ship)  (ships-of subs)
  =/  ps=(list ship)  ~(tap in targets)
  |-  ^-  (list ship)
  ?~  ps  ~
  ?.  (~(has in on-keep) i.ps)  $(ps t.ps)
  [i.ps $(ps t.ps)]
::
++  roll-list
  ^-  (list [=lyst members=(set ship)])
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  |-  ^-  (list [=lyst members=(set ship)])
  ?~  ls  ~
  ?:  =(%public p.i.ls)  $(ls t.ls)
  [[p.i.ls members.q.i.ls] $(ls t.ls)]
::
++  last-of  last-of:kc
::
++  kept
  |=  e=entry
  ^-  ?
  =/  mine=?
    ?~  i=(slaw %uv (last-of path.e))  %.n
    (~(has by posts) u.i)
  ?:  mine  %.y
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  |-  ^-  ?
  ?~  ls  %.n
  ?:  (has-entry log.q.i.ls e)  %.y
  $(ls t.ls)
::
++  has-entry   has-entry:kc
++  drop-entry  drop-entry:kc
::
++  fanned
  |=  e=entry
  ^-  (set lyst)
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  |-  ^-  (set lyst)
  ?~  ls  ~
  =/  more  $(ls t.ls)
  ?:((has-entry log.q.i.ls e) (~(put in more) p.i.ls) more)
::
++  on-of
  |=  e=entry
  ^-  (list lyst)
  ?.  =(our.bowl ship.e)  ~
  ~(tap in (fanned e))
::
++  head-of
  |=  e=entry
  ^-  (unit head:keep)
  ?.  =(our.bowl ship.e)  (~(get by heads) e)
  ?~  i=(slaw %uv (last-of path.e))  ~
  ?~  got=(~(get by posts) u.i)  ~
  `head.u.got
::
++  row-of
  |=  [via=ship e=entry]
  ^-  row:ui
  [via e (head-of e) (kept e) (from-public e) (site-of e) (~(get by checked) e) (on-of e)]
::
++  feed-rows
  ^-  (list row:ui)
  %-  by-date
  =/  w  wall
  |-  ^-  (list row:ui)
  ?~  w  ~
  ?.  ?|  (~(has in follows) ship.via.i.w)
          (~(has in follows) ship.entry.i.w)
      ==
    $(w t.w)
  [(row-of ship.via.i.w entry.i.w) $(w t.w)]
::
++  user-rows
  |=  who=ship
  ^-  (list row:ui)
  ?:  =(who our.bowl)  own-rows
  %-  by-date
  =/  w  wall
  |-  ^-  (list row:ui)
  ?~  w  ~
  ?.  =(who ship.via.i.w)  $(w t.w)
  [(row-of ship.via.i.w entry.i.w) $(w t.w)]
::
++  own-rows
  ^-  (list row:ui)
  =/  ps=(list [p=id q=item:keep])  ~(tap by posts)
  =/  mine=(list row:ui)
    |-  ^-  (list row:ui)
    ?~  ps  ~
    =/  e=entry  [our.bowl (welp (base first) (item-spur p.i.ps))]
    [[our.bowl e `head.q.i.ps %.y %.n (site-of e) ~ (on-of e)] $(ps t.ps)]
  =/  theirs=(list row:ui)
    =/  es=(list entry)  ~(tap in kept-entries)
    |-  ^-  (list row:ui)
    ?~  es  ~
    ?:  =(our.bowl ship.i.es)  $(es t.es)
    [(row-of our.bowl i.es) $(es t.es)]
  (by-date (weld mine theirs))
::
++  kept-entries
  ^-  (set entry)
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  |-  ^-  (set entry)
  ?~  ls  ~
  =/  rest=(set entry)  $(ls t.ls)
  =/  es=(list entry)  log.q.i.ls
  |-  ^-  (set entry)
  ?~  es  rest
  (~(put in $(es t.es)) i.es)
::
++  by-date  by-date:kc
::
++  body-of
  |=  e=entry
  ^-  (unit page)
  ?.  =(our.bowl ship.e)  (~(get by seen) e)
  ?~  i=(slaw %uv (last-of path.e))  ~
  ?~  got=(~(get by posts) u.i)  ~
  `page.u.got
::
::  ---- http ------------------------------------------------------------------
::
++  serve
  |=  [rid=@ta ir=inbound-request:eyre]
  ^-  (list card)
  =*  req  request.ir
  ?.  authenticated.ir
    (paint rid (login-redirect:gen:srv req))
  ?:  =('POST' method.req)  (writes rid req)
  =/  =pork:eyre
    (rash url.req ;~(sfix apat:de-purl:html yquy:de-purl:html))
  =/  ext=(unit @ta)  -.pork
  =/  seg=path        +.pork
  ?+    seg  (paint rid not-found:gen:srv)
  ::
      [%keep %style ~]
    ?.  =([~ %css] ext)  (paint rid not-found:gen:srv)
    (paint rid (css-response:gen:srv (as-octs:mimes:html style-css)))
  ::
      [%keep %app ~]
    ?.  =([~ %js] ext)  (paint rid not-found:gen:srv)
    (paint rid (js-response:gen:srv (as-octs:mimes:html app-js)))
  ::
      [%keep ~]        (render rid (feed-page:vw feed-rows))
      [%keep %write ~]  (render rid (write-page:vw ~))
  ::
  ::  id first, ship last, like /keep/read: eyre makes its ext from the
  ::  final dot of the LAST segment, and a @uv id is full of dots
      [%keep %edit @ @ ~]
    ?~  i=(slaw %uv i.t.t.seg)  (paint rid not-found:gen:srv)
    ?~  got=(~(get by posts) u.i)  (paint rid not-found:gen:srv)
    ?.  =(%md p.page.u.got)  (paint rid not-found:gen:srv)
    =/  bod=tape  ?:(?=(@ q.page.u.got) (trip q.page.u.got) "")
    =/  src=tape
      ?~  title.head.u.got  bod
      "# {(trip u.title.head.u.got)}\0a\0a{bod}"
    =/  on=(set lyst)
      (fanned [our.bowl (welp (base first) (item-spur u.i))])
    =/  aud=tape
      ?:  (~(has in on) %public)  "everyone"
      =/  to=(list lyst)  ~(tap in on)
      ?~(to "everyone" (trip i.to))
    (render rid (write-page:vw `[(trip (scot %uv u.i)) src aud]))
  ::
      [%keep %comments ~]  (render rid (comments-page:vw talk-rules))
  ::
      [%keep %lists ~]  (render rid (lists-page:vw ~))
      [%keep %lists @ ~]
    (render rid (lists-page:vw (slaw %tas i.t.t.seg)))
  ::
      [%keep %ship @ ~]
    ?~  who=(slaw %p i.t.t.seg)  (paint rid not-found:gen:srv)
    (render rid (user-page:vw u.who (user-rows u.who)))
  ::
      [%keep %read @ @ ~]
    ?~  who=(slaw %p i.t.t.t.seg)  (paint rid not-found:gen:srv)
    =/  e=entry  [u.who (welp (base first) /item/[i.t.t.seg])]
    =/  bod=(unit page)  (body-of e)
    ;:  weld
      ?^  bod  ~
      ?:  =(our.bowl u.who)  ~
      ~[(fetch-body e)]
    ::
      ?:  =(our.bowl u.who)  ~
      ?~  i=(slaw %uv i.t.t.seg)  ~
      (talk-self [%read u.who u.i])
    ::
      (render rid (read-page:vw (row-of u.who e) bod (talk-view e) talk-live))
    ==
  ==
::
++  paint
  |=  [rid=@ta pay=simple-payload:http]
  ^-  (list card)
  (give-simple-payload:app:srv rid pay)
::
::  not +html: that name shadows zuse's html core, used for de-purl below
++  render
  |=  [rid=@ta man=manx]
  ^-  (list card)
  (paint rid (manx-response:gen:srv man))
::
::  positional, not k= and v=: quay's faces are p and q
++  arg
  |=  [q=(list [@t @t]) key=@t]
  ^-  @t
  ?~  q  ''
  ?:  =(key -.i.q)  +.i.q
  $(q t.q)
::
::  rush not stab: stab crashes on anything that is not a path, and this one
::  arrives from a form field
++  invite-of
  |=  q=(list [@t @t])
  ^-  (unit feed)
  ?~  who=(slaw %p (arg q 'who'))  ~
  ?~  pat=(rush (arg q 'path') stap)  ~
  `[u.who u.pat]
::
++  self
  |=  act=action:keep
  ^-  (list card)
  ~[[%pass /self %agent [our.bowl %keep] %poke %keep-action !>(act)]]
::
++  writes
  |=  [rid=@ta req=request:http]
  ^-  (list card)
  =/  q=(list [@t @t])
    ?~  body.req  ~
    =/  got  (rush q.u.body.req yquy:de-purl:html)
    ?~(got ~ u.got)
  =/  what=@t  (arg q 'what')
  =/  back=@t  (arg q 'back')
  ?:  =('go' what)
    %+  paint  rid
    %-  bounce
    ?~  who=(slaw %p (arg q 'who'))  ?:(=('' back) '/keep' back)
    (crip "/keep/ship/{(scow %p u.who)}")
  %+  weld  (act-of q what)
  ?:  |(=('publish' what) =('edit' what))
    (paint rid [[200 ~] ~])
  (paint rid (bounce ?:(=('' back) '/keep' back)))
::
::  303 not 307: 307 preserves the method and re-POSTs the form on refresh
++  bounce
  |=  url=@t
  ^-  simple-payload:http
  [[303 ['location' url]~] ~]
::
++  act-of
  |=  [q=(list [@t @t]) what=@t]
  ^-  (list card)
  ?:  =('publish' what)
    =/  bod=@t  (arg q 'body')
    ?:  =('' bod)  ~
    =/  tit=@t  (arg q 'title')
    =/  to=@t   (arg q 'to')
    =/  aud=(unit lyst)
      ?:(=('everyone' to) `%public (slaw %tas to))
    ?~  aud  ~
    %-  self
    :^  %post  [%md bod]
      ?:(=('' tit) ~ `tit)
    ['' (sy ~[u.aud])]
  ::
  ?:  =('edit' what)
    ?~  i=(slaw %uv (arg q 'id'))  ~
    ?~  old=(~(get by posts) u.i)  ~
    =/  bod=@t  (arg q 'body')
    ?:  =('' bod)  ~
    =/  tit=@t  (arg q 'title')
    =/  to=@t   (arg q 'to')
    =/  aud=(unit lyst)
      ?:(=('everyone' to) `%public (slaw %tas to))
    ?~  aud  ~
    ::  two pokes, not one branch: %post reads the freed slug and the
    ::  pruned list logs only after %delete's event has committed
    %+  weld  (self [%delete u.i])
    %-  self
    :^  %post  [%md bod]
      ?:(=('' tit) ~ `tit)
    [terms.head.u.old (sy ~[u.aud])]
  ::
  ?:  =('repost' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    =/  e=entry  [u.who (welp (base first) /item/[(arg q 'id')])]
    (self [%keep e (sy ~[%public])])
  ::
  ?:  =('delete' what)
    ?~  i=(slaw %uv (arg q 'id'))  ~
    (self [%delete u.i])
  ::
  ?:  =('comment' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    ?~  art=(slaw %uv (arg q 'id'))  ~
    =/  bod=@t  (arg q 'body')
    ?:  =('' bod)  ~
    (talk-self [%say u.who u.art (slaw %uv (arg q 'parent')) bod])
  ::
  ?:  =('talk' what)
    ?~  art=(slaw %uv (arg q 'id'))  ~
    ?:  =('on' (arg q 'on'))   (talk-self [%open u.art])
    ?:  =('off' (arg q 'on'))  (talk-self [%shut u.art])
    ~
  ::
  ?:  =('snip' what)
    ?~  art=(slaw %uv (arg q 'id'))  ~
    ?~  n=(slaw %uv (arg q 'note'))  ~
    (talk-self [%snip u.art u.n])
  ::
  ?:  =('ban' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    (talk-self [%ban u.who])
  ::
  ?:  =('unban' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    (talk-self [%unban u.who])
  ::
  ?:  =('tier' what)
    =/  r=(unit rank:title)
      ?+  (arg q 'rank')  ~
        %pawn  `%pawn
        %earl  `%earl
        %duke  `%duke
        %king  `%king
        %czar  `%czar
      ==
    ?~  r  ~
    (talk-self [%tier u.r])
  ::
  ?:  =('check' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    ?:  =(our.bowl u.who)  ~
    ~[(probe u.who)]
  ::
  ?:  =('follow' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    (self [%sub u.who])
  ::
  ?:  =('unfollow' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    (self [%unsub u.who])
  ::
  ?:  =('accept' what)
    ?~  f=(invite-of q)  ~
    (self [%accept u.f])
  ::
  ?:  =('reject' what)
    ?~  f=(invite-of q)  ~
    (self [%reject u.f])
  ::
  ?:  =('make' what)
    ?~  nom=(slaw %tas (arg q 'name'))  ~
    ?:  =(%public u.nom)  ~
    (self [%list u.nom ~])
  ::
  ?:  =('admit' what)
    ?~  nom=(slaw %tas (arg q 'list'))  ~
    ?~  who=(slaw %p (arg q 'who'))  ~
    (self [%admit u.nom (sy ~[u.who])])
  ::
  ?:  =('evict' what)
    ?~  nom=(slaw %tas (arg q 'list'))  ~
    ?~  who=(slaw %p (arg q 'who'))  ~
    (self [%evict u.nom (sy ~[u.who])])
  ~
::
::  ---- telling the local ship ------------------------------------------------
::
++  give
  |=  u=update:keep
  ^-  (list card)
  ~[[%give %fact ~[/updates (route u)] %keep-update !>(u)]]
::
++  gift  |=(u=update:keep ^-(card [%give %fact ~ %keep-update !>(u)]))
::
++  route
  |=  u=update:keep
  ^-  path
  ?-  -.u
    %wall     /ui/wall
    %posted   /ui/wall
    %arrived  /ui/wall
    %deleted  /ui/wall
    %head     /ui/wall
    %lists    /ui/lists
    %pending  /ui/lists
    %peers    /ui/peers
    %body     (welp /ui/body/[(scot %p ship.entry.u)] path.entry.u)
  ==
::
++  lists-of
  |=  m=(map lyst roster)
  ^-  update:keep
  [%lists (members-of m)]
::
++  peers-of
  |=  [s=(map feed @ud) o=(set ship)]
  ^-  update:keep
  [%peers (ships-of s) o]
::
++  wall-now     ^-(update:keep [%wall wall heads])
++  lists-now    (lists-of lists)
++  peers-now    (peers-of subs off)
++  pending-now  ^-(update:keep [%pending (wait-of pending)])
--
