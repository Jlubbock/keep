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
/+  default-agent, dbug
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
+$  state-0
  $:  %0
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
  ==
--
::
%-  agent:dbug
=|  state-0
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
  :-  [%pass /pals %agent [our.bowl %pals] %watch /targets]
  (turn (unreached:hc known:hc) announce:hc)
::
++  on-save   !>(state)
++  on-load   |=(=vase `this(state !<(state-0 vase)))
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+    path  (on-peek:def path)
    [%x %wall ~]   ``noun+!>(wall)
    [%x %heads ~]  ``noun+!>(heads)
    [%x %subs ~]   ``noun+!>(subs)
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
      :_  this(posts (~(put by posts) id item))
      :(weld grows cards (give:hc [%posted id entry]))
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
