::  %keep — v0
::
::  ---------------------------------------------------------------------------
::  ONE PRIMITIVE
::  ---------------------------------------------------------------------------
::  a list is a set of ships plus a salt. every list holds an index: a list of
::  pointers, grown one revision per entry, each revision carrying the whole
::  list so far.
::
::    %public   index lives at /index. the address is derivable from our @p,
::              so nobody needs to be told it. no members, no push.
::
::    anything  index lives at /list/[key], one path PER MEMBER, where
::    else      key = (shas salt [list ship]). unguessable, so the address is
::              the capability. we grow the same pointers to every member's
::              path separately.
::
::  bodies live once, hash-addressed at /item/[id], id = (sham [head page]).
::  one store for public and gated alike — a body address is a content hash,
::  so it cannot be found by anyone who was not handed a pointer to it. gating
::  is entirely a question of who receives pointers, never of who can decrypt.
::
::  each item is grown TWICE, as /item/[id]/head and /item/[id]/body. an index
::  entry names the prefix and is therefore NOT keenable as it stands: a reader
::  appends /head or /body. heads are fetched eagerly on arrival, bodies only
::  on %open, so tailing a writer costs the size of their titles rather than
::  the size of their prose.
::
::  ---------------------------------------------------------------------------
::  WHAT THIS BUYS
::  ---------------------------------------------------------------------------
::  revocation is free. evicting someone is not growing to their path again.
::  no re-keying, no new address for anyone else, nobody else notices.
::
::  leaks are attributable. every member reads a different address, so a
::  circulating subscription path names exactly one ship.
::
::  membership and publication are decoupled from the network. adding a member
::  is one poke, once, ever. after that, publishing to a thousand-member list
::  sends no messages at all — it is a thousand %grows into our own gall state,
::  and the members' parked keens do the rest.
::
::  the exposure this does NOT cover: a member who leaks a body address rather
::  than their index address. bodies are shared across members, so that leak is
::  anonymous. catching it would mean a copy per member per post.
::
::  ---------------------------------------------------------------------------
::  NO SUBSCRIPTION PROTOCOL
::  ---------------------------------------------------------------------------
::  a %keen for a revision that has not been grown yet parks in ames and fires
::  when it is. the outstanding keen IS the subscription: durable across
::  restarts, one @ud of state, nothing to negotiate. backfill and tailing are
::  the same code path — start at 0, existing revisions answer from cache, the
::  first one that does not parks, and you are subscribed.
::
::  ames carries exactly two things, both once per relationship and never per
::  post: %announce (are you running %keep) and %invite (here is your address
::  for my list). everything else is remote scry.
::
/-  keep
/+  default-agent, dbug, srv=server, ui=keep-ui
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
::  the record behind a lyst. not called `list` — that shadows the stdlib mold
::  in every arm of this file.
::
+$  roster
  $:  members=(set ship)
      salt=@uvH
      log=(list entry)                 ::  what we have grown here, newest last
  ==
::
+$  versioned-state  $%(state-0 state-1)
::
+$  state-0
  $:  %0
      posts=(map id item:keep)
      lists=(map lyst roster)
      subs=(map feed @ud)
      wall=(list [via=feed =entry])
      refs=(set entry)
      heads=(map entry head:keep)
      seen=(map entry page)
      off=(set ship)
  ==
::
+$  state-1
  $:  %1
      ::  ours
      posts=(map id item:keep)
      lists=(map lyst roster)
      ::  theirs
      subs=(map feed @ud)              ::  feed -> revision we are keened on
      wall=(list [via=feed =entry])    ::  newest first — via is the index we
                                       ::  read it from, not just the ship
      refs=(set entry)                 ::  every entry ever walled. every index
                                       ::  revision repeats the whole list, so
                                       ::  without this backfill duplicates it.
      heads=(map entry head:keep)      ::  fetched eagerly
      seen=(map entry page)            ::  fetched on %open. a cache: bodies
                                       ::  sit at permanent addresses, so
                                       ::  anything cold can be dropped.
      off=(set ship)                   ::  ships confirmed not running %keep
      ::  the clearnet side: url path -> the post published there. eyre holds
      ::  the rendered bytes; this is only what we need to know a slug is
      ::  taken and to show an author their own link.
      sites=(map @t id)
  ==
--
::
%-  agent:dbug
=|  state-1
=*  state  -
^-  agent:gall
=<
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
    hc    ~(. +> bowl)
::
::  announce to every pal, and watch for later ones. no keens yet — we do not
::  know who is out there until they answer. an unbound scry path returns
::  silence, never a no, so probing by keen would never terminate; a poke gets
::  nacked, which is terminal and worth remembering.
::  (scrying an agent is fine here; it is +on-load where it is not.)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  ::  the cast matters: weld homogenizes on its first element, and a bare
  ::  list of two differently-shaped cards would demand a list of the first.
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
  =/  new=state-1
    ?-  -.old
      %1  old
    ::
        %0
      :*  %1
          posts.old  lists.old  subs.old  wall.old
          refs.old   heads.old  seen.old  off.old
          ~
      ==
    ==
  :_  this(state new)
  ::  the index is rebuilt here as well as on publish, so it exists from
  ::  install rather than only after the first post.
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
  ::  what we have published. local only — on-peek is not reachable over
  ::  ames, and this is the only way to see our own posts without +dbug.
    [%x %posts ~]  ``noun+!>(posts)
    [%x %lists ~]  ``noun+!>((members-of:hc lists))
  ::
  ::  a whole item, if we hold both halves of it
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
  ::  the mark IS the trust check: one test, not one per handler.
      %keep-action
    ?>  =(our.bowl src.bowl)
    =/  act  !<(action:keep vase)
    ?-    -.act
    ::
    ::  ---- publishing --------------------------------------------------------
    ::  grow the head and the body once each, then append the prefix to every
    ::  list named. no message leaves the ship.
        %post
      =/  hed=head:keep  [now.bowl terms.act title.act]
      =/  =item:keep     [hed page.act]
      =/  =id            (sham item)
      =/  spur=path      (item-spur:hc id)
      =/  =entry         [our.bowl (welp (base:hc 0) spur)]
      =^  cards  lists   (fan-out:hc entry ~(tap in to.act))
      =/  grows=(list card)
        :~  [%pass /grow %grow (welp spur /head) noun+hed]
            [%pass /grow %grow (welp spur /body) noun+page.act]
        ==
      ::  and, if it is public, a page on the open web and a fresh index
      =/  new-posts  (~(put by posts) id item)
      =/  url=@t
        ?.  (~(has in to.act) %public)  ''
        (site-path:hc title.act)
      ::  id:keep, not id — `=/ =id` above bound it as a face, so the bare
      ::  mold is shadowed for the rest of this branch.
      =/  new-sites=(map @t id:keep)
        ?:(=('' url) sites (~(put by sites) url id))
      =/  web=(list card)
        ?:  =('' url)  ~
        =/  art=card
          %+  cache:hc  url
          %-  manx-response:gen:srv
          (public-page:vw-bare [our.bowl entry `hed %.y %.n `url] page.act)
        ~[art (index-card:hc new-sites new-posts)]
      :_  this(posts new-posts, sites new-sites)
      :(weld grows cards web (give:hc [%posted id entry]))
    ::
    ::  syndicate someone else's pointer. same operation, no body moves — our
    ::  readers will resolve it at the ship the pointer names.
    ::
    ::  a pointer we read out of someone's private index is theirs to gate. we
    ::  will not push it to %public, because a body address is unguessable only
    ::  while nobody publishes it, and publishing it would be attributable to
    ::  us. crash rather than ack: an ack that did nothing reads as success.
        %keep
      ?:  =(our.bowl ship.entry.act)  `this
      ?:  ?&  (~(has in to.act) %public)
              !(from-public:hc entry.act)
          ==
        ~|(%keep-would-expose-gated-address !!)
      =^  cards  lists  (fan-out:hc entry.act ~(tap in to.act))
      [cards this]
    ::
    ::  ---- reading -----------------------------------------------------------
    ::  a body, on demand. if it is already cached this is just a re-gift to
    ::  whoever is watching that pane.
        %open
      ?^  got=(~(get by seen) entry.act)
        :_(this (give:hc [%body entry.act u.got]))
      :_(this ~[(fetch-body:hc entry.act)])
    ::
    ::  ---- lists -------------------------------------------------------------
    ::  upsert: create if new, then set membership to exactly what was named.
    ::  admits and evicts fall out of the diff.
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
    ::  admit: mint their address, grow them the backlog in one revision, and
    ::  tell them where it is. the only message membership ever costs.
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
    ::  evict: stop growing to their address. that is the whole operation —
    ::  no rekey, no new address for anyone else, nobody else notices. %tomb
    ::  their existing revisions too if you want the backlog gone as well.
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
      =/  at=@ud  (~(gut by subs) f 0)
      =/  ss      (~(put by subs) f at)
      :_  this(subs ss)
      :-  (tail:hc f at)
      (give:hc (peers-of:hc ss off))
    ::
        %unsub
      ?~  at=(~(get by subs) [who.act /index])  `this
      =/  ss  (~(del by subs) [who.act /index])
      :_  this(subs ss)
      :-  (halt:hc [who.act /index] u.at)
      (give:hc (peers-of:hc ss off))
    ==
  ::
  ::  ---- the interface -------------------------------------------------------
  ::  every screen and every button. the whole handler is state-free: reads
  ::  build a page, writes poke us back with the same action a dojo poke
  ::  would send, so there is exactly one implementation of each.
      %handle-http-request
    =+  !<([rid=@ta ir=inbound-request:eyre] vase)
    :_  this
    (serve:hc rid ir)
  ::
  ::  ---- network -------------------------------------------------------------
  ::  remote only, for the same structural reason.
      %keep-gossip
    ?>  !=(our.bowl src.bowl)
    =/  gos  !<(gossip:keep vase)
    ?-    -.gos
    ::
    ::  someone admitted us to one of their lists. tail it like any other
    ::  index — the address differs, nothing else does.
        %invite
      =/  f=feed  [src.bowl path.gos]
      ?:  (~(has by subs) f)  `this
      =/  ss  (~(put by subs) f 0)
      :_  this(subs ss)
      :-  (tail:hc f 0)
      (give:hc (peers-of:hc ss off))
    ::
    ::  someone just installed %keep. we ack by not crashing, which is what
    ::  tells them we are running it too. we tail their public index back only
    ::  if they are ours — it is public either way.
        %announce
      =/  f=feed  [src.bowl /index]
      ?.  &((~(has in targets:hc) src.bowl) !(~(has by subs) f))
        `this
      =/  ss  (~(put by subs) f 0)
      =/  oo  (~(del in off) src.bowl)
      :_  this(subs ss, off oo)
      :-  (tail:hc f 0)
      (give:hc (peers-of:hc ss oo))
    ==
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ?>  =(our.bowl src.bowl)
  ?+    path  (on-watch:def path)
  ::  eyre, waiting on a response we are about to give it
      [%http-response *]  `this
  ::  the firehose. consumers scry for initial state.
      [%updates ~]   `this
      [%ui %wall ~]   :_(this ~[(gift:hc wall-now:hc)])
      [%ui %lists ~]  :_(this ~[(gift:hc lists-now:hc)])
      [%ui %peers ~]  :_(this ~[(gift:hc peers-now:hc)])
  ::
  ::  the deliberate exception: nothing to gift means the keen is outstanding,
  ::  which is the honest state of a scry that may never resolve. do not fake
  ::  a loading value.
      [%ui %body @ *]
    =/  e=entry  [(slav %p i.t.t.path) t.t.t.path]
    ?~  got=(~(get by seen) e)  `this
    :_(this ~[(gift:hc [%body e u.got])])
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
  ::
  ::  an ack means %keep runs there; a nack means it does not, and that stays
  ::  true until they announce to us, so we record it and never ask again.
      [%hey @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    =/  who=ship  (slav %p i.t.wire)
    ?^  p.sign
      =/  oo  (~(put in off) who)
      :_  this(off oo)
      (give:hc (peers-of:hc subs oo))
    =/  f=feed  [who /index]
    =/  ss      (~(put by subs) f 0)
    :_  this(subs ss)
    :-  (tail:hc f 0)
    (give:hc (peers-of:hc ss off))
  ::
  ::  a poke we sent ourselves on behalf of a click. a nack is a refusal the
  ::  agent made on purpose, and the only place it can be reported is here.
      [%self ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep: refused" u.p.sign)
    `this
  ::
  ::  an invite they refused is theirs to refuse. we stay grown to their path.
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
  ?.  ?=([%ames %tune *] sign-arvo)  (on-arvo:def wire sign-arvo)
  =*  roar  roar.sign-arvo
  ?+    wire  `this
  ::
  ::  ---- a head --------------------------------------------------------------
  ::  the eager half. tens of bytes, and everything a shelf of titles needs.
      [%head @ *]
    ?:  |(?=(~ roar) ?=(~ q.dat.u.roar))  `this
    =/  e=entry        [(slav %p i.t.wire) t.t.wire]
    =/  hed=head:keep  ;;(head:keep q.u.q.dat.u.roar)
    :_  this(heads (~(put by heads) e hed))
    (give:hc [%head e hed])
  ::
  ::  ---- a body --------------------------------------------------------------
  ::  only ever because someone opened it.
      [%body @ *]
    ?:  |(?=(~ roar) ?=(~ q.dat.u.roar))  `this
    =/  e=entry     [(slav %p i.t.wire) t.t.wire]
    =/  bod=page    ;;(page q.u.q.dat.u.roar)
    :_  this(seen (~(put by seen) e bod))
    (give:hc [%body e bod])
  ::
  ::  ---- an index revision ---------------------------------------------------
  ::  identical whether this is a public index or a private one. the address
  ::  differs; nothing else does.
      [%feed @ @ *]
    =/  at=@ud    (slav %ud i.t.wire)
    =/  f=feed    [(slav %p i.t.t.wire) t.t.t.wire]
    ::  outer ~: ames gave up, or we yawned. %sub resumes from this cursor.
    ?~  roar  `this
    ::  inner ~: a signed proof of absence. that revision was tombstoned, so
    ::  step over it rather than reading it as the end of the feed.
    ?~  q.dat.u.roar
      :_  this(subs (~(put by subs) f +(at)))
      ~[(tail:hc f +(at))]
    =/  new=(list entry)
      (skip ;;((list entry) q.u.q.dat.u.roar) ~(has in refs))
    =/  fresh=(set entry)  (sy new)
    =/  fold=(list [via=feed =entry])
      (flop (turn new |=(e=entry [f e])))
    =/  fetches=(list card)   (turn new fetch-head:hc)
    =/  arrivals=(list card)
      (zing (turn new |=(e=entry (give:hc [%arrived f e]))))
    :_  %=  this
          subs  (~(put by subs) f +(at))
          refs  (~(uni in refs) fresh)
          wall  (weld fold wall)
        ==
    :(weld ~[(tail:hc f +(at))] fetches arrivals)
  ==
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
::  =========================================================================
|_  =bowl:gall
::
::  %pals is a dependency, not a requirement: without it we simply know
::  nobody. %gu says whether the agent is running, and unlike %gx it does not
::  crash the event when it is not.
::
++  targets
  ^-  (set ship)
  ?.  .^(? %gu /(scot %p our.bowl)/pals/(scot %da now.bowl)/$)  ~
  .^((set ship) %gx /(scot %p our.bowl)/pals/(scot %da now.bowl)/targets/noun)
::
::  ---- folds ------------------------------------------------------------
::  these two are spelled out rather than written with ~(run in ...) or
::  ~(run by ...). a feed and a roster both contain a path, which is a
::  recursive mold, and run is a wet gate whose product type is inferred:
::  feed that inference into a second wet gate — uni, or !> on the result —
::  and mint memes on it. an explicit fold is cast at every step.
::
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
++  known
  ^-  (set ship)
  =/  reached=(set ship)  (ships-of subs)
  (~(uni in reached) off)
::
++  unreached  |=(saw=(set ship) ~(tap in (~(dif in targets) saw)))
::
::  /g/x/[rev]/keep//1/[...] — the empty element means gall published it,
::  the 1 is the mandatory path-format version. %keep is the protocol's agent
::  name, ours and theirs alike, so it is a constant rather than dap.bowl.
::
::  both cast to path, and the cast earns its keep: %1 is a @ud constant, not
::  a term, so the path-format version has to be written (scot %ud 1) — the
::  knot '1'. spelled %1 it is the ATOM 1, a 0x01 byte in the path, which no
::  cast would catch and no keen would ever resolve.
::
::  concatenate these with welp, never weld: weld homogenizes on its first
::  element and would demand a (list %g).
::
++  base
  |=  rev=@ud
  ^-  path
  ~[%g %x (scot %ud rev) %keep %$ (scot %ud 1)]
::
++  item-spur  |=(=id ^-(path /item/[(scot %uv id)]))
::
::  one address per member. the salt is per-list, so holding one member's
::  address for one list tells you nothing about any other address anywhere.
::
++  member-spur
  |=  [=lyst salt=@uvH who=ship]
  ^-  path
  ?:  =(%public lyst)  /index
  /list/[(scot %uv (shas salt (jam [lyst who])))]
::
::  minting on first use, so posting to a new list is one poke. never bunt a
::  salt — a zero salt makes every member address derivable by anyone who
::  knows the scheme, which is the whole gate gone.
::
++  mint  |=(=lyst ^-(@uvH (sham (mix eny.bowl (jam lyst)))))
::
::  the sample is e, not =entry: a =mold face shadows that mold for the whole
::  arm, and this body needs `entry` as a mold, in (list entry).
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
  =/  cs=(list card)
    ?:  =(%public i.to)
      ~[[%pass /grow %grow /index noun+new]]
    %+  turn  ~(tap in members.lst)
    |=  w=ship
    [%pass /grow %grow (member-spur i.to salt.lst w) noun+new]
  =^  more  lsts  $(to t.to, lsts (~(put by lsts) i.to lst(log new)))
  [(weld cs more) lsts]
::
::  a new member's whole cost: one revision at their address carrying the
::  backlog, and one poke telling them where to read it.
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
::  did this pointer reach us through a public index? only then is it ours
::  to put in front of everyone.
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
++  announce
  |=  who=ship
  ^-  card
  :^  %pass  /hey/(scot %p who)  %agent
  [[who %keep] %poke %keep-gossip !>(`gossip:keep`[%announce ~])]
::
++  tail
  |=  [f=feed at=@ud]
  ^-  card
  :^  %pass  [%feed (scot %ud at) (scot %p ship.f) path.f]  %keen
  [%.n ship.f (welp (base at) path.f)]
::
::  %yawn needs the same wire the keen went out on
++  halt
  |=  [f=feed at=@ud]
  ^-  card
  :^  %pass  [%feed (scot %ud at) (scot %p ship.f) path.f]  %arvo
  [%a %yawn ship.f (welp (base at) path.f)]
::
::  an entry is a prefix. the two halves are separate publications and are
::  fetched on separate wires, at different times, for different reasons.
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
::  ---- clearnet --------------------------------------------------------------
::  a public post is rendered once, at publish, and handed to eyre with its
::  auth flag off. eyre serves those bytes to anyone who has the link and
::  never wakes this agent to do it. nothing here is a route.
::
::  only %public reaches clearnet. a post to a private list has no url, which
::  is the same gate as everything else in this agent: who gets the pointer.
::
++  cache
  |=  [url=@t pay=simple-payload:http]
  ^-  card
  [%pass /eyre/cache %arvo %e %set-response url `[%.n %payload pay]]
::
::  these are the same urls the private app already references. caching them
::  unauthenticated means one copy serves both, and the agent stops being
::  woken for its own stylesheet.
::
++  assets
  ^-  (list card)
  :~  (cache '/keep/style.css' (css-response:gen:srv (as-octs:mimes:html style-css)))
      (cache '/keep/app.js' (js-response:gen:srv (as-octs:mimes:html app-js)))
  ==
::
::  a cached url shadows the %connect binding, so a slug that collides with
::  an app route would take it over. the index is reserved for the same
::  reason: it is a page, not a post.
::
++  reserved
  ^-  (set @t)
  %-  sy
  :~  '/keep/index'  '/keep/write'  '/keep/lists'  '/keep/read'
      '/keep/ship'   '/keep/style.css'  '/keep/app.js'
  ==
::
::  the title, lowercased, everything else collapsed to one hyphen. the
::  agent is allowed to touch a title — it is asserted metadata, not prose.
::
++  slugify
  |=  t=@t
  ^-  @t
  =/  cs=tape  (trip t)
  =|  acc=tape                         ::  reversed
  =/  gap=?  %.y                       ::  suppress leading hyphens
  |-  ^-  @t
  ?~  cs
    =/  s=tape  (flop ?:(?&(?=(^ acc) =('-' i.acc)) t.acc acc))
    ?~(s 'untitled' (crip s))
  =/  c=@tD  i.cs
  =/  low=@tD  ?:(&((gte c 'A') (lte c 'Z')) (add c 32) c)
  ?:  ?|  &((gte low 'a') (lte low 'z'))
          &((gte low '0') (lte low '9'))
      ==
    $(cs t.cs, acc [low acc], gap %.n)
  ?:  gap  $(cs t.cs)
  $(cs t.cs, acc ['-' acc], gap %.y)
::
++  site-path
  |=  tit=(unit @t)
  ^-  @t
  =/  base=tape  (trip ?~(tit 'untitled' (slugify u.tit)))
  =|  n=@ud
  |-  ^-  @t
  =/  try=@t
    ?:  =(0 n)  (crip "/keep/{base}")
    (crip "/keep/{base}-{(a-co:co n)}")
  ?.  |((~(has by sites) try) (~(has in reserved) try))  try
  $(n +(n))
::
::  the index, newest first, built from whatever has a url. it is rebuilt
::  whole on every publish — it is a list of titles, and deltas would be
::  noise. both maps are passed in because at publish time state holds
::  neither the new post nor its url yet.
::
++  public-rows
  |=  [ss=(map @t id) ps=(map id item:keep)]
  ^-  (list row:ui)
  =/  ls=(list [p=@t q=id])  ~(tap by ss)
  =/  rs=(list row:ui)
    |-  ^-  (list row:ui)
    ?~  ls  ~
    ?~  got=(~(get by ps) q.i.ls)  $(ls t.ls)
    =/  e=entry  [our.bowl (welp (base 0) (item-spur q.i.ls))]
    [[our.bowl e `head.u.got %.y %.n `p.i.ls] $(ls t.ls)]
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
::  a projection of state, flat, with the joins done. the ui library gets
::  this and nothing else — no bowl, no cards, no state.
::
++  vw  ~(. ui view-now)
::
::  for rendering outside a request. +view-now scries %pals to build the
::  sidebar, and a publish must not depend on another agent being up — a
::  failed scry would nack the poke and lose the post. the clearnet page
::  has no sidebar, so it needs none of it.
::
++  vw-bare  ~(. ui `view:ui`[our.bowl now.bowl ~ ~ ~ ~])
::
++  view-now
  ^-  view:ui
  :*  our.bowl
      now.bowl
      ~(tap in targets)
      (ships-of subs)
      off
      roll-list
  ==
::
::  %public is a list in state, because posting to it mints it like any
::  other. it is not a list in the interface: it is the word `everyone`,
::  and it has no members to show.
::
++  roll-list
  ^-  (list [=lyst members=(set ship)])
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  |-  ^-  (list [=lyst members=(set ship)])
  ?~  ls  ~
  ?:  =(%public p.i.ls)  $(ls t.ls)
  [[p.i.ls members.q.i.ls] $(ls t.ls)]
::
++  last-of
  |=  p=path
  ^-  @ta
  ?~  p  ''
  ?~  t.p  i.p
  $(p t.p)
::
::  have we syndicated this entry to any list of ours
++  kept
  |=  e=entry
  ^-  ?
  =/  ls=(list [p=lyst q=roster])  ~(tap by lists)
  |-  ^-  ?
  ?~  ls  %.n
  ?:  (has-entry log.q.i.ls e)  %.y
  $(ls t.ls)
::
++  has-entry
  |=  [es=(list entry) e=entry]
  ^-  ?
  ?~  es  %.n
  ?:  =(i.es e)  %.y
  $(es t.es)
::
::  heads holds what we fetched from other people. our own head never went
::  through a keen — it is in posts, next to the body — so both lookups have
::  to fork on whose entry it is.
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
  [via e (head-of e) (kept e) (from-public e) (site-of e)]
::
++  feed-rows
  ^-  (list row:ui)
  =/  w  wall
  |-  ^-  (list row:ui)
  ?~  w  ~
  [(row-of ship.via.i.w entry.i.w) $(w t.w)]
::
::  a ship's feed IS their index as we have read it: their own posts and
::  whatever they syndicated, in the order it arrived.
::
++  user-rows
  |=  who=ship
  ^-  (list row:ui)
  ?:  =(who our.bowl)  own-rows
  =/  w  wall
  |-  ^-  (list row:ui)
  ?~  w  ~
  ?.  =(who ship.via.i.w)  $(w t.w)
  [(row-of ship.via.i.w entry.i.w) $(w t.w)]
::
::  ours is the one feed we cannot read off the wall — we never tail
::  ourselves. it is what we wrote plus what we passed on.
::
++  own-rows
  ^-  (list row:ui)
  =/  ps=(list [p=id q=item:keep])  ~(tap by posts)
  =/  mine=(list row:ui)
    |-  ^-  (list row:ui)
    ?~  ps  ~
    =/  e=entry  [our.bowl (welp (base 0) (item-spur p.i.ps))]
    [[our.bowl e `head.q.i.ps %.y %.n (site-of e)] $(ps t.ps)]
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
::  insertion sort, newest first. spelled out rather than +sort so nothing
::  wet is inferring a type over a row.
::
++  by-date
  |=  rs=(list row:ui)
  ^-  (list row:ui)
  =|  out=(list row:ui)
  |-  ^-  (list row:ui)
  ?~  rs  out
  $(rs t.rs, out (insert-row out i.rs))
::
++  insert-row
  |=  [rs=(list row:ui) r=row:ui]
  ^-  (list row:ui)
  ?~  rs  ~[r]
  ?:  (gth (stamp r) (stamp i.rs))  [r rs]
  [i.rs $(rs t.rs)]
::
++  stamp
  |=  r=row:ui
  ^-  @da
  ?~  hed.r  *@da
  wen.u.hed.r
::
::  our own bodies never went through a keen, so they are in posts, not in
::  seen. everyone else's are in seen or nowhere yet.
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
      [%keep %write ~]  (render rid write-page:vw)
      [%keep %lists ~]  (render rid (lists-page:vw ~))
      [%keep %lists @ ~]
    (render rid (lists-page:vw (slaw %tas i.t.t.seg)))
  ::
      [%keep %ship @ ~]
    ?~  who=(slaw %p i.t.t.seg)  (paint rid not-found:gen:srv)
    (render rid (user-page:vw u.who (user-rows u.who)))
  ::
  ::  opening an article is what asks for the body. the page renders either
  ::  way; the keen lands later or never.
  ::  /keep/read/[id]/[ship] — the id is dotted, so it cannot be the last
  ::  segment or eyre reads its tail as a file extension.
      [%keep %read @ @ ~]
    ?~  who=(slaw %p i.t.t.t.seg)  (paint rid not-found:gen:srv)
    =/  e=entry  [u.who (welp (base 0) /item/[i.t.t.seg])]
    =/  bod=(unit page)  (body-of e)
    %+  weld
      ?^  bod  ~
      ?:  =(our.bowl u.who)  ~
      ~[(fetch-body e)]
    (render rid (read-page:vw (row-of u.who e) bod))
  ==
::
++  paint
  |=  [rid=@ta pay=simple-payload:http]
  ^-  (list card)
  (give-simple-payload:app:srv rid pay)
::
::  not +html: that name shadows zuse's html core, and this file asks it
::  for de-purl and mimes a few lines up.
::
++  render
  |=  [rid=@ta man=manx]
  ^-  (list card)
  (paint rid (manx-response:gen:srv man))
::
::  positional, not k= and v=: quay's faces are p and q, and a bare pair
::  nests either way.
::
++  arg
  |=  [q=(list [@t @t]) key=@t]
  ^-  @t
  ?~  q  ''
  ?:  =(key -.i.q)  +.i.q
  $(q t.q)
::
::  every write is the same action a dojo poke would send, sent to
::  ourselves. the guard on %keep-action is =(our src), which a self-poke
::  satisfies, and a refusal nacks in +on-agent rather than here.
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
  ::  search. purely navigational — slaw validates the name and we go look
  ::  at whatever we already hold. no packet leaves the ship.
  ?:  =('go' what)
    %+  paint  rid
    %-  bounce
    ?~  who=(slaw %p (arg q 'who'))  ?:(=('' back) '/keep' back)
    (crip "/keep/ship/{(scow %p u.who)}")
  %+  weld  (act-of q what)
  ?:  =('publish' what)
    (paint rid [[200 ~] ~])
  (paint rid (bounce ?:(=('' back) '/keep' back)))
::
::  303, not the 307 that +redirect:gen gives: 307 preserves the method, so
::  the browser re-POSTs the same form to the target and the write happens
::  again, and again. 303 sends it back as a GET.
::
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
    ::  cast, or the two branches stay a fork of two different unit types
    ::  and u.aud has no single type to resolve in.
    =/  aud=(unit lyst)
      ?:(=('everyone' to) `%public (slaw %tas to))
    ?~  aud  ~
    %-  self
    :^  %post  [%md bod]
      ?:(=('' tit) ~ `tit)
    ['' (sy ~[u.aud])]
  ::
  ?:  =('repost' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    =/  e=entry  [u.who (welp (base 0) /item/[(arg q 'id')])]
    (self [%keep e (sy ~[%public])])
  ::
  ::  the one place a click sends a packet to a stranger, and it is the only
  ::  thing that can answer "do they run %keep": a scry returns silence for
  ::  an unbound path, a poke nacks. the ack lands in +on-agent on /hey and
  ::  files them in subs or off.
  ?:  =('check' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    ?:  =(our.bowl u.who)  ~
    ~[(announce u.who)]
  ::
  ?:  =('follow' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    (self [%sub u.who])
  ::
  ?:  =('unfollow' what)
    ?~  who=(slaw %p (arg q 'who'))  ~
    (self [%unsub u.who])
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
::  state changes in three unrelated places. one router, so none of them has
::  to know who is listening.
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
    %head     /ui/wall
    %lists    /ui/lists
    %peers    /ui/peers
    %body     (welp /ui/body/[(scot %p ship.entry.u)] path.entry.u)
  ==
::
::  the whole-state cases, each the answer to "what does a duct joining this
::  path need before it can render anything at all". the -of arms take the
::  state explicitly, because a handler broadcasting a change has the new
::  value in hand and hc still holds the old one.
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
++  wall-now   ^-(update:keep [%wall wall heads])
++  lists-now  (lists-of lists)
++  peers-now  (peers-of subs off)
--
