/-  keep, kt=keep-talk, ks=keep-sync, km=keep-mail, hark
/+  default-agent, dbug, srv=server, ui=keep-ui, kc=keep-core, kh=keep-hark
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
      log=(list entry)                 ::  what we have grown here, newest last
  ==
::
::  frozen: lists before %8 addressed each member by a salted spur
+$  roster-7
  $:  members=(set ship)
      salt=@uvH
      log=(list entry)
  ==
::
::  frozen: what was actually written to disk. never change these.
+$  head-0  [wen=@da terms=@t title=(unit @t)]
+$  item-0  [head=head-0 =page]
::
+$  versioned-state
  $%(state-0 state-1 state-2 state-3 state-4 state-5 state-6 state-7 state-8 state-9)
::
+$  state-0
  $:  %0
      posts=(map id item-0)
      lists=(map lyst roster-7)
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
      lists=(map lyst roster-7)
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
      lists=(map lyst roster-7)
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
      lists=(map lyst roster-7)
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
      lists=(map lyst roster-7)
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
      lists=(map lyst roster-7)
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
      lists=(map lyst roster-7)
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
::
+$  state-7
  $:  %7
      posts=(map id item:keep)
      lists=(map lyst roster-7)
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
      fans=(set ship)                  ::  ships that sent %follow
  ==
::
+$  state-8
  $:  %8
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
      fans=(set ship)
  ==
::
+$  state-9
  $:  %9
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
      fans=(set ship)
      nonce=@uv                        ::  this install's addresses
      refollow=@da                     ::  the next daily re-%follow, to heal stalled tails
  ==
--
::
%-  agent:dbug
=|  state-9
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
  =:  nonce     (end 5 eny.bowl)
      refollow  (add now.bowl ~d1)
    ==
  :_  this
  =/  boot=(list card)
    :~  [%pass /bind %arvo %e %connect [~ /keep] dap.bowl]
        [%pass /pals %agent [our.bowl %pals] %watch /targets]
        (index-card:hc ~ ~)
        (linkmap-card:hc ~)
    ==
  ;:  weld
    boot
    assets:hc
    (turn (unreached:hc known:hc) announce:hc)
    ~[(refollow-timer:hc refollow)]
  ==
::
++  on-save   !>(state)
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  ::  every load re-asks whoever we follow where their index is now: an
  ::  address stalled by a reinstall on either side heals on the next OTA
  ?:  ?=(%9 -.old)
    =.  state  old
    :_  this
    :(weld retail-all:hc refollow-all:hc (boot:hc sites posts))
  ?:  ?=(%8 -.old)
    =.  state  (nine:hc old)
    =^  moved  lists  republish:hc
    :_  this
    ;:  weld
      moved
      (turn ~(tap in fans) probe:hc)
      (turn ~(tap in targets:hc) announce:hc)
      retail-all:hc
      refollow-all:hc
      ~[(refollow-timer:hc refollow)]
      (boot:hc sites posts)
    ==
  ::
  =/  seven=state-7
    ?:  ?=(%7 -.old)  old
    =/  six=state-6
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
    :*  %7
        posts.six  lists.six  subs.six
        wall.six  refs.six  heads.six  seen.six
        off.six  sites.six  follows.six
        checked.six  keeping.six  pending.six
        ~                                ::  fans
    ==
  ::  follows from before %7 never said so; tell them once
  =/  told=(list card)
    ?:  ?=(%7 -.old)  ~
    (turn ~(tap in follows.seven) |=(w=ship (tell:hc w [%follow ~])))
  =.  state
    %-  nine:hc
    :*  %8
        posts.seven  (unsalt:hc lists.seven)  subs.seven
        wall.seven  refs.seven  heads.seven  seen.seven
        off.seven  sites.seven  follows.seven
        checked.seven  keeping.seven  pending.seven  fans.seven
    ==
  ::  every gated list moves under its coop: the log re-addressed, its posts
  ::  tended there, and each member re-invited to the list's one address
  =^  moved  lists  recoop:hc
  =^  regrown  lists  republish:hc
  ::  invites that arrived from a writer who moved first are re-addresses,
  ::  not offers: take them, and stop tailing the addresses they replace
  =/  sw  sweep:hc
  =:  subs     subs.sw
      follows  follows.sw
      pending  pending.sw
    ==
  :_  this
  ;:  weld
    told  moved  regrown  cards.sw
    (turn ~(tap in fans) probe:hc)
    (turn ~(tap in targets:hc) announce:hc)
    retail-all:hc
    refollow-all:hc
    ~[(refollow-timer:hc refollow)]
    (give:hc [%pending (wait-of:hc pending)])
    (boot:hc sites posts)
  ==
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
    [%x %fans ~]     ``noun+!>(fans)
    [%x %pending ~]  ``noun+!>(pending)
    [%x %nonce ~]    ``noun+!>(nonce)
  ::
  ::  gall asks this on every remote read under a coop: is the reader in?
      [%c %list @ @ ~]
    =/  l=(unit @tas)  (slaw %tas i.t.t.path)
    =/  w=(unit ship)  (slaw %p i.t.t.t.path)
    =/  in=?
      ?~  l  %.n
      ?~  w  %.n
      ?~  got=(~(get by lists) u.l)  %.n
      (~(has in members.u.got) u.w)
    ``noun+!>(in)
  ::
  ::  for %keep-mail: which lists a post of ours fanned to, so the mailer
  ::  sends %public posts only
      [%x %audience @ ~]
    =/  art=id  (slav %uv i.t.t.path)
    ?.  (~(has by posts) art)  ``noun+!>(*(unit (set lyst)))
    ``noun+!>(`(unit (set lyst))``(fanned:hc art))
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
        ?(%post %mailpost %backpost)
      =/  [wen=@da =page tit=(unit @t) trm=@t to=(set lyst)]
        ?-  -.act
          %post      [now.bowl page.act title.act terms.act to.act]
          %mailpost  [now.bowl page.act title.act terms.act to.act]
          %backpost  [wen.act page.act title.act terms.act to.act]
        ==
      =/  hash=@uvH      (sham page)
      =/  lyfe=@ud       our-life:hc
      =/  =id
        (sain:keep our.bowl lyfe wen trm tit hash)
      =/  hed=head:keep
        :*  wen  our.bowl  lyfe  trm  tit  hash
            (sign-id:hc lyfe id)
        ==
      =/  =item:keep     [hed page]
      =/  =entry         [our.bowl (welp (base:hc first:hc) (item-spur:hc id))]
      =^  cards  lists   (fan-out:hc id ~(tap in to))
      =/  grows=(list card)  (publish:hc id hed page ~(tap in to))
      =/  new-posts  (~(put by posts) id item)
      =/  url=@t
        ?.  (~(has in to) %public)  ''
        (site-path:hc tit)
      ::  id:keep, not id: `=/ =id` above shadows the bare mold here
      =/  new-sites=(map @t id:keep)
        ?:(=('' url) sites (~(put by sites) url id))
      =/  web=(list card)
        ?:  =('' url)  ~
        =/  art=card
          %+  cache:hc  url
          %-  manx-response:gen:srv
          (public-page:vw-bare [our.bowl entry `hed %.y %.n `url ~ ~] page ~)
        ~[art (index-card:hc new-sites new-posts) (linkmap-card:hc new-sites)]
      =/  mail=(list card)
        ?.  ?=(%mailpost -.act)  ~
        (mail-self:hc [%send id %.n])
      :_  this(posts new-posts, sites new-sites)
      %-  zing
      :~  grows  cards  web
          (give:hc [%posted id entry])
          mail
          (talk-self:hc [%open id])
      ==
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
      =/  =entry         [our.bowl (welp (base:hc first:hc) (item-spur:hc id.act))]
      =/  on=(list lyst)  ~(tap in (fanned:hc id.act))
      =^  cards  lists   (unfan:hc id.act)
      =/  new-posts      (~(del by posts) id.act)
      =/  url=(unit @t)  (site-of:hc entry)
      =/  new-sites      ?~(url sites (~(del by sites) u.url))
      =/  web=(list card)
        ?~  url  ~
        :~  (uncache:hc u.url)
            (index-card:hc new-sites new-posts)
            (linkmap-card:hc new-sites)
        ==
      ::  a reposter re-grew our bytes under their own /item, so tombing ours
      ::  ends our copy and not theirs
      =/  buries=(list card)  (bury:hc id.act on)
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
      =/  hed=(list card)
        ?:  =(our.bowl ship.entry.act)  ~
        ?:  (~(has by heads) entry.act)  ~
        ~[(fetch-head:hc entry.act)]
      :_(this (weld hed ~[(fetch-body:hc entry.act)]))
    ::
    ::  ---- lists -------------------------------------------------------------
        %list
      ?:  =(%public lyst.act)  ~|(%keep-public-has-no-members !!)
      =/  had=(unit roster)  (~(get by lists) lyst.act)
      =/  lst=roster  ?^(had u.had [~ ~])
      =/  new=(list ship)  ~(tap in (~(dif in members.act) members.lst))
      =/  gone=?  !=(~ (~(dif in members.lst) members.act))
      =/  all  (~(put by lists) lyst.act lst(members members.act))
      =/  keyed=(list card)
        ?~  had  (found:hc lyst.act)
        ?.(gone ~ (rekey:hc lyst.act members.act))
      =/  hail=(list card)
        ?:  gone  ~
        (turn new |=(w=ship (welcome:hc lyst.act w)))
      :_  this(lists all)
      :(weld keyed hail (give:hc (lists-of:hc all)))
    ::
        %admit
      ?:  =(%public lyst.act)  ~|(%keep-public-has-no-members !!)
      ?~  got=(~(get by lists) lyst.act)  ~|([%keep-no-such-list lyst.act] !!)
      =/  new=(list ship)  ~(tap in (~(dif in who.act) members.u.got))
      =/  all
        %+  ~(put by lists)  lyst.act
        u.got(members (~(uni in members.u.got) who.act))
      =/  hail=(list card)  (turn new |=(w=ship (welcome:hc lyst.act w)))
      :_  this(lists all)
      (weld hail (give:hc (lists-of:hc all)))
    ::
        %evict
      ?:  =(%public lyst.act)  ~|(%keep-public-has-no-members !!)
      ?~  got=(~(get by lists) lyst.act)  ~|([%keep-no-such-list lyst.act] !!)
      =/  left=(set ship)  (~(dif in members.u.got) who.act)
      =/  all  (~(put by lists) lyst.act u.got(members left))
      :_  this(lists all)
      (weld (rekey:hc lyst.act left) (give:hc (lists-of:hc all)))
    ::
    ::  the coop stays; with no roster behind it, on-peek admits nobody
        %unlist
      ?:  =(%public lyst.act)  ~|(%keep-cannot-unlist-public !!)
      ?.  (~(has by lists) lyst.act)  `this
      =/  all  (~(del by lists) lyst.act)
      :_  this(lists all)
      (give:hc (lists-of:hc all))
    ::
    ::  ---- following ---------------------------------------------------------
    ::  the index address is theirs to tell: %follow is answered with it
        %sub
      =/  ff  (~(put in follows) who.act)
      :_  this(follows ff)
      :-  (tell:hc who.act [%follow ~])
      (give:hc (peers-of:hc subs off))
    ::
        %unsub
      =/  ff  (~(del in follows) who.act)
      :_  this(follows ff)
      :-  (tell:hc who.act [%unfollow ~])
      (give:hc (peers-of:hc subs off))
    ::
    ::  ---- invites -----------------------------------------------------------
        %accept
      ?.  (~(has by pending) feed.act)  `this
      =/  pp  (~(del by pending) feed.act)
      =/  ss  (~(put by subs) feed.act first:hc)
      =/  ff  (~(put in follows) ship.feed.act)
      :_  this(subs ss, follows ff, pending pp)
      :+  (tail:hc feed.act first:hc)
        (tell:hc ship.feed.act [%follow ~])
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
      ::  to a member it is "ask again": a revision gall refused while we
      ::  were out is keened from where it stalled
      ?^  at=(~(get by subs) f)
        :_  this
        ~[(tail:hc f u.at)]
      ?:  (~(has by pending) f)  `this
      ::  the same list at a new address — a reinstall, or the move under
      ::  its coop — is a re-address, not an offer
      ?:  (has-kind:hc f)
        =/  r  (readdress:hc f)
        :_  this(subs subs.r, follows follows.r)
        (weld cards.r (give:hc (peers-of:hc subs.r off)))
      ::  any ship may invite us, so bound what one of them can park here
      ?:  (gte (waiting:hc src.bowl) 8)  `this
      =/  pp  (~(put by pending) f lyst.gos)
      :_  this(pending pp)
      (give:hc [%pending (wait-of:hc pp)])
    ::
    ::  where their index is: taken from a pal, from anyone we asked with
    ::  %follow, or from a writer we already tail, whose address it replaces
        %announce
      =/  f=feed  [src.bowl path.gos]
      ?.  (index-kind:kc path.gos)  `this
      ::  an address we hold is "ask again": the keen is re-issued from
      ::  where it stalled, which a reload or a refused read may have left
      ?^  at=(~(get by subs) f)
        :_  this
        ~[(tail:hc f u.at)]
      ?.  ?|  (~(has in targets:hc) src.bowl)
              (~(has in follows) src.bowl)
              (has-kind:hc f)
          ==
        `this
      =/  r  (readdress:hc f)
      =/  oo  (~(del in off) src.bowl)
      :_  this(subs subs.r, follows follows.r, off oo)
      (weld cards.r (give:hc (peers-of:hc subs.r oo)))
    ::
    ::  every %follow is answered with our address; the mutual %follow once,
    ::  so a follow that crossed an upgrade lands both ways
        %follow
      =/  new=?  !(~(has in fans) src.bowl)
      =/  ff  (~(put in fans) src.bowl)
      :_  this(fans ff)
      ;:  weld
        ~[(tell:hc src.bowl [%announce (feed-spur:kc %public nonce)])]
        ?.(new ~ (give:hc [%fans ff]))
        ?.  &(new (~(has in follows) src.bowl))  ~
        ~[(tell:hc src.bowl [%follow ~])]
      ==
    ::
        %unfollow
      =/  ff  (~(del in fans) src.bowl)
      :_(this(fans ff) (give:hc [%fans ff]))
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
      [%ui %peers ~]  :_(this ~[(gift:hc peers-now:hc) (gift:hc [%fans fans])])
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
    ::  they run %keep; their address comes back with their %announce
    =/  oo  (~(del in off) who)
    =/  ff  ?:(?=(%hey i.wire) (~(put in follows) who) follows)
    :_  this(follows ff, off oo)
    %+  weld
      ?.(?=(%hey i.wire) ~ ~[(tell:hc who [%follow ~])])
    (give:hc (peers-of:hc subs oo))
  ::
  ::  unacked on purpose — see %follow in /sur/keep
      [%fan @ ~]  `this
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
      [%sync ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep: keep-sync refused" u.p.sign)
    `this
  ::
      [%mail ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep: keep-mail refused" u.p.sign)
    `this
  ::
      [%hark ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep: hark refused" u.p.sign)
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
  ::  a wake for any timer but the current one is a leftover from an
  ::  earlier load; only the current one re-arms
  ?:  ?=([%behn %wake *] sign-arvo)
    ?.  ?=([%refollow @ ~] wire)  `this
    ?.  =(refollow (slav %da i.t.wire))  `this
    =.  refollow  (add now.bowl ~d1)
    :_  this
    (weld refollow-all:hc ~[(refollow-timer:hc refollow)])
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
    ::  a fresh head on a foreign address claiming our authorship is a repost
    =/  toast=(list card)
      ?.  ?&  !(~(has by heads) e)
              !=(our.bowl ship.e)
              =(our.bowl who.hed)
          ==
        ~
      %^  notify:kh  bowl  /repost/[(last-of:hc path.e)]
      ^-  (list content:hark)
      :~  [%ship ship.e]
          ' reposted '
          [%emph ?~(title.hed 'your post' u.title.hed)]
      ==
    :_  %=  this
          heads    (~(put by heads) e hed)
          checked  ?~(late checked (~(put by checked) e u.late))
          lists    ?~(done lists lists.u.done)
          posts    ?~(done posts posts.u.done)
          keeping  ?:(|((settled:hc vote) ?=(^ done)) (~(del by keeping) e) keeping)
        ==
    ;:  weld
      toast
      (give:hc [%head e hed])
      ?~(done ~ cards.u.done)
    ==
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
    ::  it rather than stall forever on a revision that will never come.
    ::  under a coop an empty answer is gall refusing us: stay put, and
    ::  the writer's next invite re-keens this revision
    ?:  ?=(~ q.sage)
      ?:  (gated:kc path.f)  `this
      :_  this(subs (~(put by subs) f +(at)))
      ~[(tail:hc f +(at))]
    =/  got  (mule |.(;;((list entry) q.q.sage)))
    ?:  ?=(%| -.got)
      %-  (slog leaf+"keep: unreadable index from {<ship.f>}" ~)
      :_  this(subs (~(put by subs) f +(at)))
      ~[(tail:hc f +(at))]
    ::  a list that moved under its coop re-addresses every post it holds;
    ::  the id says it is the same post
    =/  known=(set [ship id])  (ids-of:hc refs)
    =/  new=(list entry)
      %+  skip  p.got
      |=  e=entry
      ?:  (~(has in refs) e)  %.y
      =/  i  (id-of:kc path.e)
      &(?=(^ i) (~(has in known) [ship.e u.i]))
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
  |=  m=(map lyst roster-7)
  ^-  (map lyst roster-7)
  =/  ls=(list [p=lyst q=roster-7])  ~(tap by m)
  |-  ^-  (map lyst roster-7)
  ?~  ls  ~
  (~(put by $(ls t.ls)) p.i.ls q.i.ls(log ~))
::
++  unsalt
  |=  m=(map lyst roster-7)
  ^-  (map lyst roster)
  =/  ls=(list [p=lyst q=roster-7])  ~(tap by m)
  |-  ^-  (map lyst roster)
  ?~  ls  ~
  (~(put by $(ls t.ls)) p.i.ls [members.q.i.ls log.q.i.ls])
::
++  ids-of
  |=  s=(set entry)
  ^-  (set [ship id])
  =/  es=(list entry)  ~(tap in s)
  |-  ^-  (set [ship id])
  ?~  es  ~
  =/  more  $(es t.es)
  ?~  i=(id-of:kc path.i.es)  more
  (~(put in more) [ship.i.es u.i])
::
++  boot
  |=  [sites=(map @t id) posts=(map id item:keep)]
  ^-  (list card)
  :^    [%pass /bind %arvo %e %connect [~ /keep] dap.bowl]
      (index-card sites posts)
    (linkmap-card sites)
  assets
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
::
++  entry-in
  |=  [=lyst =id]
  ^-  entry
  [our.bowl (welp (base first) (post-spur:kc lyst id))]
::
::  %germ makes a coop's key, or turns it over if the coop already has one
++  rotate  |=(=lyst ^-(card [%pass /germ %germ (coop:kc lyst)]))
::
::  a turned key answers no keen parked under the old one, the evicted
::  ship's or anyone's: every member left is told to ask again
++  rekey
  |=  [=lyst members=(set ship)]
  ^-  (list card)
  [(rotate lyst) (turn ~(tap in members) |=(w=ship (welcome lyst w)))]
::
::  a new gated list: its key, and revision 1 so a member's first keen answers
++  found
  |=  =lyst
  ^-  (list card)
  ~[(rotate lyst) (spread lyst ~)]
::
++  spread
  |=  [=lyst es=(list entry)]
  ^-  card
  =/  spur=path  (feed-spur:kc lyst nonce)
  ?:  =(%public lyst)
    [%pass /grow %grow spur noun+es]
  [%pass /grow %tend (coop:kc lyst) (slag 2 spur) noun+es]
::
::  a copy per list, not per member: the coop, not the address, is what
::  keeps a body from a non-member
++  publish
  |=  [=id hed=head:keep bod=page to=(list lyst)]
  ^-  (list card)
  =/  spur=path  (item-spur id)
  %-  zing
  %+  turn  to
  |=  l=lyst
  ^-  (list card)
  ?:  =(%public l)
    :~  [%pass /grow %grow (welp spur /head) noun+hed]
        [%pass /grow %grow (welp spur /body) noun+bod]
    ==
  :~  [%pass /grow %tend (coop:kc l) (welp spur /head) noun+hed]
      [%pass /grow %tend (coop:kc l) (welp spur /body) noun+bod]
  ==
::
++  bury
  |=  [=id on=(list lyst)]
  ^-  (list card)
  %-  zing
  %+  turn  on
  |=  l=lyst
  ^-  (list card)
  =/  spur=path  (post-spur:kc l id)
  :~  [%pass /tomb %tomb [%ud first] (welp spur /head)]
      [%pass /tomb %tomb [%ud first] (welp spur /body)]
  ==
::
++  fan-out
  |=  [=id to=(list lyst)]
  ^-  [(list card) (map lyst roster)]
  =/  lsts  lists
  |-  ^-  [(list card) (map lyst roster)]
  ?~  to  [~ lsts]
  =/  had=(unit roster)  (~(get by lsts) i.to)
  =/  lst=roster  ?^(had u.had [~ ~])
  =/  new=(list entry)  (snoc log.lst (entry-in i.to id))
  ::  a list first named by a post needs its key before its first %tend
  =/  keyed=(list card)
    ?:  |(?=(^ had) =(%public i.to))  ~
    ~[(rotate i.to)]
  =^  more  lsts  $(to t.to, lsts (~(put by lsts) i.to lst(log new)))
  [:(weld keyed ~[(spread i.to new)] more) lsts]
::
++  unfan
  |=  =id
  ^-  [(list card) (map lyst roster)]
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  =/  lsts  lists
  |-  ^-  [(list card) (map lyst roster)]
  ?~  ls  [~ lsts]
  =/  new=(list entry)  (drop-id:kc log.q.i.ls id)
  ?:  =(new log.q.i.ls)  $(ls t.ls)
  =^  more  lsts  $(ls t.ls, lsts (~(put by lsts) p.i.ls q.i.ls(log new)))
  [[(spread p.i.ls new) more] lsts]
::
::  the %7 -> %8 move: every gated log re-addressed under its coop, the
::  posts it names tended there, and each member told the new address
++  recoop
  ^-  [(list card) (map lyst roster)]
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  =|  cs=(list card)
  =/  out  lists
  |-  ^-  [(list card) (map lyst roster)]
  ?~  ls  [cs out]
  ?:  =(%public p.i.ls)  $(ls t.ls)
  =/  ids=(list id)
    =/  es=(list entry)  log.q.i.ls
    |-  ^-  (list id)
    ?~  es  ~
    ?~  i=(id-of:kc path.i.es)  $(es t.es)
    [u.i $(es t.es)]
  =/  log=(list entry)  (turn ids |=(i=id (entry-in p.i.ls i)))
  =/  tends=(list card)
    %-  zing
    %+  turn  ids
    |=  i=id
    ^-  (list card)
    ?~  got=(~(get by posts) i)  ~
    (publish i head.u.got page.u.got ~[p.i.ls])
  =/  hail=(list card)
    (turn ~(tap in members.q.i.ls) |=(w=ship (welcome p.i.ls w)))
  %=  $
    ls   t.ls
    out  (~(put by out) p.i.ls q.i.ls(log log))
    cs   :(weld cs ~[(rotate p.i.ls)] tends ~[(spread p.i.ls log)] hail)
  ==
::
::  ---- a list's address moved -------------------------------------------
::
::  do we already tail this writer for the same thing, at any address
++  has-kind
  |=  f=feed
  ^-  ?
  =/  fs=(list [p=feed q=@ud])  ~(tap by subs)
  |-  ^-  ?
  ?~  fs  %.n
  ?:  &(=(ship.f ship.p.i.fs) (same-kind:kc path.p.i.fs path.f))  %.y
  $(fs t.fs)
::
::  take an address in place of every one of the same kind from that writer
++  readdress
  |=  f=feed
  ^-  [cards=(list card) subs=(map feed @ud) follows=(set ship)]
  =/  fs=(list [p=feed q=@ud])  ~(tap by subs)
  =/  ss  (~(put by subs) f first)
  =|  cs=(list card)
  |-  ^-  [cards=(list card) subs=(map feed @ud) follows=(set ship)]
  ?~  fs
    :*  :+  (tail f first)  (tell ship.f [%follow ~])  cs
        ss
        (~(put in follows) ship.f)
    ==
  ?:  =(f p.i.fs)  $(fs t.fs)
  ?.  &(=(ship.f ship.p.i.fs) (same-kind:kc path.p.i.fs path.f))  $(fs t.fs)
  $(fs t.fs, ss (~(del by ss) p.i.fs), cs [(halt p.i.fs q.i.fs) cs])
::
++  refollow-all
  ^-  (list card)
  (turn ~(tap in follows) |=(w=ship (tell w [%follow ~])))
::
::  a parked keen does not survive the agent being reloaded; every tail is
::  re-issued from where it was, and a duplicate parks beside the original
++  retail-all
  ^-  (list card)
  =/  fs=(list [p=feed q=@ud])  ~(tap by subs)
  |-  ^-  (list card)
  ?~  fs  ~
  [(tail p.i.fs q.i.fs) $(fs t.fs)]
::
++  refollow-timer
  |=  at=@da
  ^-  card
  [%pass /refollow/(scot %da at) %arvo %b %wait at]
::
++  nine
  |=  eight=state-8
  ^-  state-9
  :*  %9
      posts.eight  lists.eight  subs.eight
      wall.eight  refs.eight  heads.eight  seen.eight
      off.eight  sites.eight  follows.eight
      checked.eight  keeping.eight  pending.eight  fans.eight
      (end 5 eny.bowl)
      (add now.bowl ~d1)
  ==
::
::  a new nonce: every index regrown at its new address, every gated list
::  re-keyed and its members re-invited there
++  republish
  ^-  [(list card) (map lyst roster)]
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  =|  cs=(list card)
  |-  ^-  [(list card) (map lyst roster)]
  ?~  ls  [cs lists]
  =/  more=(list card)
    ?:  =(%public p.i.ls)  ~[(spread p.i.ls log.q.i.ls)]
    [(spread p.i.ls log.q.i.ls) (rekey p.i.ls members.q.i.ls)]
  $(ls t.ls, cs (weld cs more))
::
++  sweep
  ^-  [cards=(list card) subs=(map feed @ud) follows=(set ship) pending=(map feed lyst)]
  =/  ps=(list [p=feed q=lyst])  ~(tap by pending)
  =|  cs=(list card)
  |-  ^-  [cards=(list card) subs=(map feed @ud) follows=(set ship) pending=(map feed lyst)]
  ?~  ps  [cs subs follows pending]
  ?.  (has-kind p.i.ps)  $(ps t.ps)
  =/  r  (readdress p.i.ps)
  %=  $
    ps       t.ps
    cs       (weld cs cards.r)
    subs     subs.r
    follows  follows.r
    pending  (~(del by pending) p.i.ps)
  ==
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
  |=  [=lyst who=ship]
  ^-  card
  :^  %pass  /poke/(scot %p who)  %agent
  :+  [who %keep]  %poke
  keep-gossip+!>(`gossip:keep`[%invite lyst (feed-spur:kc lyst nonce)])
::
++  from-public
  |=  e=entry
  ^-  ?
  =/  w  wall
  |-  ^-  ?
  ?~  w  %.n
  ?:  &(=(e entry.i.w) (index-kind:kc path.via.i.w))  %.y
  $(w t.w)
::
++  announce  (hail /hey)
++  probe     (hail /ask)
::
++  tell
  |=  [who=ship gos=gossip:keep]
  ^-  card
  :^  %pass  /fan/(scot %p who)  %agent
  [[who %keep] %poke %keep-gossip !>(gos)]
::
++  hail
  |=  pre=path
  |=  who=ship
  ^-  card
  :^  %pass  (welp pre /(scot %p who))  %agent
  :+  [who %keep]  %poke
  keep-gossip+!>(`gossip:keep`[%announce (feed-spur:kc %public nonce)])
::
::  secret=& is the coop key exchange: gall fetches the list's key from the
::  writer first, and a non-member gets an empty %sage instead
++  tail
  |=  [f=feed at=@ud]
  ^-  card
  :^  %pass  [%feed (scot %ud at) (scot %p ship.f) path.f]  %keen
  [(gated:kc path.f) ship.f (welp (base at) path.f)]
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
  [(gated:kc path.e) ship.e (welp path.e /head)]
::
++  fetch-body
  |=  e=entry
  ^-  card
  :^  %pass  [%body (scot %p ship.e) path.e]  %keen
  [(gated:kc path.e) ship.e (welp path.e /body)]
::
::  a direct link names an id and a ship. a walled copy is the address;
::  failing that, a gated post is read through a list of theirs we hold
::  an invite to, taken or not — where a member could have been sent it
++  resolve
  |=  [who=ship =id]
  ^-  entry
  =/  open=entry  [who (welp (base first) (item-spur id))]
  ?:  =(our.bowl who)  open
  =/  es=(list entry)  (weld ~(tap in refs) ~(tap in ~(key by heads)))
  |-  ^-  entry
  ?^  es
    ?:  &(=(who ship.i.es) =(`id (id-of:kc path.i.es)))  i.es
    $(es t.es)
  =/  fs=(list feed)
    (weld ~(tap in ~(key by subs)) ~(tap in ~(key by pending)))
  |-  ^-  entry
  ?~  fs  open
  ?.  &(=(who ship.i.fs) ?=(^ (list-of:kc path.i.fs)))  $(fs t.fs)
  [who :(welp (base first) (scag 2 `path`path.i.fs) (item-spur id))]
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
  =^  cards  lists  (fan-out id to)
  [(weld (publish id hed bod to) cards) lists (~(put by posts) id [hed bod])]
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
  =/  fanned-on=(set lyst)  (fanned art)
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
++  mail-live
  ^-  ?
  .^(? %gu /(scot %p our.bowl)/keep-mail/(scot %da now.bowl)/$)
::
++  mail-self
  |=  act=action:km
  ^-  (list card)
  ?.  mail-live  ~
  ~[[%pass /mail %agent [our.bowl %keep-mail] %poke %keep-mail-action !>(act)]]
::
++  mail-status
  ^-  status:km
  .^  status:km  %gx
  /(scot %p our.bowl)/keep-mail/(scot %da now.bowl)/status/noun
  ==
::
::  ~ is "no control at all": foreign, gated, or the mailer is not running
++  mail-of
  |=  e=entry
  ^-  (unit mailv:ui)
  ?.  =(our.bowl ship.e)  ~
  ?.  mail-live  ~
  ?~  i=(slaw %uv (last-of path.e))  ~
  ?.  (~(has by posts) u.i)  ~
  ?.  (~(has in (fanned u.i)) %public)  ~
  =/  st  mail-status
  `[set-up.st readers.st (~(get by stat.st) u.i)]
::
::  every reader on the ship, marked by whether the relay holds their consent
++  mail-roll
  ^-  (list [addr:km @da ?])
  =/  us  (scot %p our.bowl)
  =/  wen  (scot %da now.bowl)
  =/  ss  .^((map addr:km @da) %gx /[us]/keep-mail/[wen]/subs/noun)
  =/  vw  .^((unit readers:km) %gx /[us]/keep-mail/[wen]/view/noun)
  =/  ok  ?~(vw *(set addr:km) confirmed.u.vw)
  %+  sort
    (turn ~(tap by ss) |=([a=addr:km w=@da] [a w (~(has in ok) a)]))
  |=([a=[addr:km @da ?] b=[addr:km @da ?]] (aor -.a -.b))
::
::  the editor's email box: the confirmed count, once mail is set up
++  mail-readers
  ^-  (unit @ud)
  ?.  mail-live  ~
  =/  st  mail-status
  ?.  set-up.st  ~
  `readers.st
::
++  mailed-now
  ^-  (map id:keep @da)
  =/  xs  ~(tap by stat:mail-status)
  |-  ^-  (map id:keep @da)
  ?~  xs  ~
  ?.  ?=(%sent -.q.i.xs)  $(xs t.xs)
  (~(put by $(xs t.xs)) p.i.xs wen.q.i.xs)
::
++  sync-live
  ^-  ?
  .^(? %gu /(scot %p our.bowl)/keep-sync/(scot %da now.bowl)/$)
::
++  sync-self
  |=  act=action:ks
  ^-  (list card)
  ?.  sync-live  ~
  ~[[%pass /sync %agent [our.bowl %keep-sync] %poke %keep-sync-action !>(act)]]
::
++  sync-rows
  ^-  (list syncrow:ui)
  ?.  sync-live  ~
  =/  m
    .^  (map @tas sub:ks)  %gx
    /(scot %p our.bowl)/keep-sync/(scot %da now.bowl)/subs/noun
    ==
  =/  bs  (badges-of our.bowl)
  %+  turn  ~(tap by m)
  |=  [name=@tas s=sub:ks]
  ^-  syncrow:ui
  [name url.s last.s next.s ~(wyt in seen.s) ?=(^ tid.s) (proof-of bs url.s)]
::
++  badges-of
  |=  who=ship
  ^-  (list [url=@t badge:ks])
  ?.  sync-live  ~
  =/  m
    .^  (map claim:ks badge:ks)  %gx
    /(scot %p our.bowl)/keep-sync/(scot %da now.bowl)/badges/noun
    ==
  %+  sort
    %+  murn  ~(tap by m)
    |=  [c=claim:ks b=badge:ks]
    ?.(=(who who.c) ~ `[url.c b])
  |=([a=[url=@t *] b=[url=@t *]] (aor url.a url.b))
::
++  proof-of
  |=  [bs=(list [url=@t badge:ks]) url=@t]
  ^-  (unit proof:ks)
  ?~  bs  ~
  ?:  =(url url.i.bs)  `proof.i.bs
  $(bs t.bs)
::
++  sync-previews
  ^-  (list prevrow:ui)
  ?.  sync-live  ~
  =/  m
    .^  (map @tas prev:ks)  %gx
    /(scot %p our.bowl)/keep-sync/(scot %da now.bowl)/previews/noun
    ==
  =/  bs  (badges-of our.bowl)
  %+  turn  ~(tap by m)
  |=  [name=@tas p=prev:ks]
  ^-  prevrow:ui
  [name url.p got.p fail.p (proof-of bs url.p)]
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
::  no-cache, or a ui update takes a hard refresh or a week: these urls are
::  mutable, and eyre matches its cache on the exact url, so ?v= cannot bust
++  fresh-asset
  |=  [typ=@t =octs]
  ^-  simple-payload:http
  :_  `octs
  [200 ~[['content-type' typ] ['cache-control' 'no-cache']]]
::
++  assets
  ^-  (list card)
  :~  (cache '/keep/style.css' (fresh-asset 'text/css' (as-octs:mimes:html style-css)))
      (cache '/keep/app.js' (fresh-asset 'text/javascript' (as-octs:mimes:html app-js)))
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
::  sites inverted — id to slug, public posts only, so it hands a clearnet
::  reader nothing the public index does not already
++  linkmap-card
  |=  ss=(map @t id)
  ^-  card
  =/  ls=(list [p=@t q=id])  ~(tap by ss)
  =/  o=(map @t json)
    |-  ^-  (map @t json)
    ?~  ls  ~
    (~(put by $(ls t.ls)) `@t`(scot %uv q.i.ls) s+p.i.ls)
  (cache '/keep/linkmap' (json-response:gen:srv o+o))
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
++  vw-bare  ~(. ui `view:ui`[our.bowl now.bowl ~ ~ ~ ~ ~ ~ ~])
::
++  view-now
  ^-  view:ui
  :*  our.bowl
      now.bowl
      live-pals
      (ships-of subs)
      follows
      fans
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
  ?~  i=(id-of:kc path.e)  %.n
  (~(has by posts) u.i)
::
++  fanned
  |=  =id
  ^-  (set lyst)
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  |-  ^-  (set lyst)
  ?~  ls  ~
  =/  more  $(ls t.ls)
  ?:((has-id:kc log.q.i.ls id) (~(put in more) p.i.ls) more)
::
::  ours: every list we fanned it to. theirs: the list we were handed it
::  under, which its coop address names
++  on-of
  |=  e=entry
  ^-  (list lyst)
  ?.  =(our.bowl ship.e)
    ?~  l=(list-of:kc path.e)  ~
    ~[u.l]
  ?~  i=(id-of:kc path.e)  ~
  ~(tap in (fanned u.i))
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
::  what the editor's [[ picker may cite: our posts, then walled posts whose
::  head has landed — the head is the only place a title lives
++  cands
  ^-  (list cand:ui)
  =/  out=(list cand:ui)
    =/  ps=(list [p=id:keep q=item:keep])  ~(tap by posts)
    %+  turn  ps
    |=  [p=id:keep q=item:keep]
    ^-  cand:ui
    :*  wen.head.q
        (fall title.head.q 'untitled')
        our.bowl  p
        (~(has in (fanned p)) %public)
    ==
  =/  known=(set id:keep)  (sy (turn out |=(c=cand:ui id.c)))
  =/  w  wall
  |-  ^-  (list cand:ui)
  ?~  w
    %+  sort  out
    |=([a=cand:ui b=cand:ui] (gth wen.a wen.b))
  ?:  =(our.bowl ship.entry.i.w)  $(w t.w)
  ?~  hed=(~(get by heads) entry.i.w)  $(w t.w)
  ?~  i=(slaw %uv (last-of path.entry.i.w))  $(w t.w)
  ?:  (~(has in known) u.i)  $(w t.w)
  %=  $
    w      t.w
    known  (~(put in known) u.i)
    out    :_  out
           :*  wen.u.hed
               (fall title.u.hed 'untitled')
               ship.entry.i.w  u.i
               (from-public entry.i.w)
           ==
  ==
::
::  ---- http ------------------------------------------------------------------
::
++  serve
  |=  [rid=@ta ir=inbound-request:eyre]
  ^-  (list card)
  =*  req  request.ir
  ?.  authenticated.ir
    (paint rid (login-redirect:gen:srv req))
  ?:  =('POST' method.req)
    ?.  (same-origin:kc header-list.req)  (paint rid [[403 ~] ~])
    (writes rid req)
  ::  yquy keeps the '?' on the first key
  =/  [=pork:eyre quay=(list [@t @t])]
    (rash url.req ;~(plug apat:de-purl:html yquy:de-purl:html))
  =.  quay  (unwut quay)
  =/  ext=(unit @ta)  -.pork
  =/  seg=path        +.pork
  ?+    seg  (paint rid not-found:gen:srv)
  ::
      [%keep %style ~]
    ?.  =([~ %css] ext)  (paint rid not-found:gen:srv)
    (paint rid (fresh-asset 'text/css' (as-octs:mimes:html style-css)))
  ::
      [%keep %app ~]
    ?.  =([~ %js] ext)  (paint rid not-found:gen:srv)
    (paint rid (fresh-asset 'text/javascript' (as-octs:mimes:html app-js)))
  ::
      [%keep ~]        (render rid (feed-page:vw feed-rows))
      [%keep %follows ~]  (render rid follows-page:vw)
      [%keep %write ~]  (render rid (write-page:vw ~ cands mail-readers))
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
    =/  on=(set lyst)  (fanned u.i)
    =/  aud=tape
      ?:  (~(has in on) %public)  "everyone"
      =/  to=(list lyst)  ~(tap in on)
      ?~(to "everyone" (trip i.to))
    (render rid (write-page:vw `[(trip (scot %uv u.i)) src aud] cands mail-readers))
  ::
      [%keep %comments ~]  (render rid (comments-page:vw talk-rules))
  ::
      [%keep %lists ~]  (render rid (lists-page:vw ~))
      [%keep %lists @ ~]
    (render rid (lists-page:vw (slaw %tas i.t.t.seg)))
  ::
      [%keep %sync ~]  (render rid (sync-page:vw sync-rows sync-previews))
  ::
      [%keep %mail ~]
    ?.  mail-live  (render rid (mail-page:vw ~ ~))
    =/  st  mail-status
    =/  small=?  (lte (add readers.st waiting.st) 200)
    %+  weld  (mail-self [%refresh ~])
    (render rid (mail-page:vw `st ?.(small ~ `mail-roll)))
  ::
  ::  the full address list, only on request: it can be thousands of rows
      [%keep %mail %readers ~]
    ?.  mail-live  (render rid (mail-page:vw ~ ~))
    (render rid (mail-page:vw `mail-status `mail-roll))
  ::
      [%keep %ship @ ~]
    ?~  who=(slaw %p i.t.t.seg)  (paint rid not-found:gen:srv)
    ::  reading a page is what asks after its substack, and re-asks daily
    %+  weld  (sync-self [%look u.who %.n])
    %+  render  rid
    %:  user-page:vw
      u.who
      (user-rows u.who)
      ?.(&(=(our.bowl u.who) mail-live) ~ mailed-now)
      (badges-of u.who)
      (slaw %tas (arg quay 'list'))
    ==
  ::
      [%keep %read @ @ ~]
    ?~  who=(slaw %p i.t.t.t.seg)  (paint rid not-found:gen:srv)
    ?~  art=(slaw %uv i.t.t.seg)  (paint rid not-found:gen:srv)
    =/  e=entry  (resolve u.who u.art)
    =/  bod=(unit page)  (body-of e)
    ;:  weld
      ?^  bod  ~
      ?:  =(our.bowl u.who)  ~
      ~[(fetch-body e)]
    ::
    ::  a direct link may be this item's only path: with no index revision
    ::  behind it, nothing else ever fetches the head, and an unjudged body
    ::  renders with no warning
      ?:  =(our.bowl u.who)  ~
      ?:  (~(has by heads) e)  ~
      ~[(fetch-head e)]
    ::
      ?:  =(our.bowl u.who)  ~
      ?~  i=(slaw %uv i.t.t.seg)  ~
      (talk-self [%read u.who u.i])
    ::
      (render rid (read-page:vw (row-of u.who e) bod (talk-view e) talk-live (mail-of e)))
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
++  unwut
  |=  q=(list [@t @t])
  ^-  (list [@t @t])
  ?~  q  ~
  =/  k=tape  (trip -.i.q)
  ?~  k  q
  ?.  =(63 i.k)  q                   ::  63: '?'
  [[(crip t.k) +.i.q] t.q]
::
++  arg
  |=  [q=(list [@t @t]) key=@t]
  ^-  @t
  ?~  q  ''
  ?:  =(key -.i.q)  +.i.q
  $(q t.q)
::
::  a typed name coerced toward a term: lowercased, spaces hyphenated.
::  a leading digit still fails — the input's pattern says so up front
++  as-term
  |=  t=@t
  ^-  (unit @tas)
  %+  slaw  %tas
  %-  crip
  %+  turn  (trip t)
  |=  c=@tD
  ?:  &((gte c 'A') (lte c 'Z'))  (add c 32)
  ?:(=(' ' c) '-' c)
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
    ::  the email box on the editor: only a public post can be mailed
    =/  mail=?  &(=('on' (arg q 'mail')) =(%public u.aud))
    =/  title=(unit @t)  ?:(=('' tit) ~ `tit)
    %-  self
    ^-  action:keep
    ?:  mail
      [%mailpost [%md bod] title '' (sy ~[u.aud])]
    [%post [%md bod] title '' (sy ~[u.aud])]
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
    ?~  nom=(as-term (arg q 'name'))  ~
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
  ::
  ?:  =('unlist' what)
    ?~  nom=(slaw %tas (arg q 'list'))  ~
    ?:  =(%public u.nom)  ~
    (self [%unlist u.nom])
  ::
  ?:  =('sync-scan' what)
    ?~  nom=(as-term (arg q 'name'))  ~
    =/  url=@t  (arg q 'url')
    ?:  =('' url)  ~
    (sync-self [%preview u.nom url])
  ::
  ?:  =('sync-cancel' what)
    ?~  nom=(slaw %tas (arg q 'name'))  ~
    (sync-self [%cancel u.nom])
  ::
  ?:  =('sync-track' what)
    ?~  nom=(slaw %tas (arg q 'name'))  ~
    =/  url=@t  (arg q 'url')
    ?:  =('' url)  ~
    (sync-self [%track u.nom url ~h1 '' (sy ~[%public])])
  ::
  ?:  =('sync-pull' what)
    ?~  nom=(slaw %tas (arg q 'name'))  ~
    (sync-self [%pull u.nom])
  ::
  ?:  =('sync-untrack' what)
    ?~  nom=(slaw %tas (arg q 'name'))  ~
    (sync-self [%untrack u.nom])
  ::
  ?:  =('substack-check' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    (sync-self [%look u.who %.y])
  ::
  ?:  =('mail' what)
    ?~  i=(slaw %uv (arg q 'id'))  ~
    (mail-self [%send u.i %.n])
  ::
  ?:  =('mail-refresh' what)
    (mail-self [%refresh ~])
  ::
  ?:  =('mail-name' what)
    (mail-self [%name (arg q 'name')])
  ::
  ?:  =('mail-reset' what)
    (mail-self [%reset ~])
  ::
  ?:  =('mail-import' what)
    =/  raw=@t  (arg q 'emails')
    ?:  =('' raw)  ~
    (mail-self [%import raw (arg q 'url')])
  ::
  ?:  =('mail-remove' what)
    =/  a=@t  (arg q 'addr')
    ?:  =('' a)  ~
    (mail-self [%remove a])
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
    %fans     /ui/peers
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
