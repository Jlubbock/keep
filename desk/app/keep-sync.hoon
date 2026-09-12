::  keep-sync — substack publications into %keep, on a timer.
::
::    the fetching is threads (ted/keep-sync-scan, ted/keep-sync-pull); this
::    agent only keeps the schedule, holds scan previews, dedupes on slug,
::    and pokes %keep with what the pull thread sends back one %ingest at a
::    time — so a pull that dies keeps what it reached.
::
::    the publications it syncs are the ones this ship claims, grown at
::    /substack; it also keeps every other ship's claims as it judged them
::    (ted/keep-sync-about).
::
/-  keep, ks=keep-sync, spider
/+  default-agent, dbug, kc=keep-core
|%
+$  card  card:agent:gall
::
+$  versioned-state  $%(state-0 state-1 state-2 state-3)
+$  state-0  [%0 subs=(map @tas sub:ks)]
+$  state-1
  $:  %1
      subs=(map @tas sub:ks)
      previews=(map @tas prev:ks)
  ==
+$  state-2
  $:  %2
      subs=(map @tas sub:ks)
      previews=(map @tas prev:ks)
      mine=(unit @t)
      badges=(map ship [url=@t =proof:ks wen=@da])
      keens=(map ship @ud)
  ==
+$  state-3
  $:  %3
      subs=(map @tas sub:ks)
      previews=(map @tas prev:ks)
      badges=(map claim:ks badge:ks)     ::  claims we have judged, ours included
      keens=(map ship @ud)               ::  /substack revision keened, per ship
  ==
::
++  poll-floor     ~m15                ::  substack is not ours to hammer
++  recheck-after  ~d1                 ::  a badge older than this is re-read
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
++  on-init  `this
++  on-save  !>(state)
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  ?:  ?=(%3 -.old)  `this(state old)
  ::  a ship already syncing has been claiming all along; say so now
  =.  state
    ?-  -.old
      %2  [%3 subs.old previews.old ~ ~]
      %1  [%3 subs.old previews.old ~ ~]
      %0  [%3 subs.old ~ ~ ~]
    ==
  =^  cs  state  grow-mine:hc
  [cs this]
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %subs ~]      ``noun+!>(subs)
    [%x %previews ~]  ``noun+!>(previews)
    [%x %mine ~]      ``noun+!>(mine:hc)
    [%x %badges ~]    ``noun+!>(badges)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %keep-sync-action
    ?>  =(our.bowl src.bowl)
    =/  act  !<(action:ks vase)
    ?-    -.act
        %preview
      ::  a scan already running for this name keeps running
      =/  was  (~(get by previews) name.act)
      ?:  &(?=(^ was) ?=(~ got.u.was) !fail.u.was)  `this
      =/  url  (clean-url:hc url.act)
      ?:  =('' url)  `this
      =/  tid=@ta  (mk-tid:hc name.act)
      =^  cs  state  (check:hc [our.bowl url] %.n)
      :_  this(previews (~(put by previews) name.act [url ~ %.n]))
      (weld (scan-start:hc name.act tid url) cs)
    ::
        %cancel
      `this(previews (~(del by previews) name.act))
    ::
        %track
      =/  url    (clean-url:hc url.act)
      =/  every  (max poll-floor every.act)
      =/  was=(unit sub:ks)  (~(get by subs) name.act)
      =/  fresh=?  |(?=(~ was) !=(url url.u.was))
      ::  a re-track with the same url keeps what was already imported
      =/  base=sub:ks
        ?:  fresh  [url every terms.act to.act *@da *@da ~ ~]
        (need was)
      ::  a url change orphans any pull in flight: stop listening to it
      =/  orphan=(list card)
        ?:  &(fresh ?=(^ was) ?=(^ tid.u.was))
          ~[(leave:hc /thread/[name.act])]
        ~
      =/  tid=@ta  (mk-tid:hc name.act)
      =/  new=sub:ks
        %=  base
          every  every
          terms  terms.act
          to     to.act
          next   (add now.bowl every)
          tid    ?:(?=(^ tid.base) tid.base `tid)
        ==
      =/  before  mine:hc
      =.  subs      (~(put by subs) name.act new)
      =.  previews  (~(del by previews) name.act)
      =^  grown  state  (regrow:hc before)
      :_  this
      ;:  weld
        ~[(wait:hc name.act every)]
        orphan
        ?^(tid.base ~ (start:hc name.act tid url last.base))
        grown
      ==
    ::
        %untrack
      ::  the timer chain ends itself: a wake for an unknown name stops
      =/  before  mine:hc
      =.  subs  (~(del by subs) name.act)
      =^  grown  state  (regrow:hc before)
      [grown this]
    ::
        %pull
      ?~  got=(~(get by subs) name.act)  ~|(%sync-no-such-sub !!)
      ?^  tid.u.got  `this
      =/  tid=@ta  (mk-tid:hc name.act)
      :_  this(subs (~(put by subs) name.act u.got(tid `tid)))
      (start:hc name.act tid url.u.got last.u.got)
    ::
        %ingest
      ?~  got=(~(get by subs) name.act)  `this
      ?:  (~(has in seen.u.got) slug.p.act)  `this
      =/  sub=sub:ks
        %=  u.got
          seen  (~(put in seen.u.got) slug.p.act)
          last  ?:((gth wen.p.act last.u.got) wen.p.act last.u.got)
        ==
      :_  this(subs (~(put by subs) name.act sub))
      ~[(upload:hc name.act p.act terms.u.got to.u.got)]
    ::
        %look
      ::  our own claims never cross the network
      =/  hear=(list card)
        ?:  |(=(our.bowl who.act) (~(has by keens) who.act))  ~
        ~[(keen-badge:hc who.act first:kc)]
      =?  keens  ?=(^ hear)  (~(put by keens) who.act first:kc)
      =^  cs  state  (check-all:hc who.act force.act)
      [(weld hear cs) this]
    ==
  ==
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?+    wire  (on-agent:def wire sign)
      [%post @ ~]
    ?.  ?=(%poke-ack -.sign)  `this
    ?~  p.sign  `this
    %-  (slog leaf+"keep-sync: %keep refused a post from {(trip i.t.wire)}" u.p.sign)
    `this
  ::
      [%scan @ ~]
    =/  name  `@tas`i.t.wire
    ?-    -.sign
        %poke-ack
      ?~  p.sign  `this
      %-  (slog leaf+"keep-sync: spider refused a scan of {(trip name)}" u.p.sign)
      :-  ~[(leave:hc wire)]
      this(previews (scan-failed:hc name))
    ::
        %watch-ack
      ?~  p.sign  `this
      %-  (slog leaf+"keep-sync: no scan result for {(trip name)}" u.p.sign)
      [~ this(previews (scan-failed:hc name))]
    ::
        %kick
      `this
    ::
        %fact
      ?+    p.cage.sign  [~[(leave:hc wire)] this]
          %thread-fail
        =/  err  !<((pair term tang) q.cage.sign)
        %-  (slog leaf+"keep-sync: scan failed for {(trip name)}: {(trip p.err)}" q.err)
        :-  ~[(leave:hc wire)]
        this(previews (scan-failed:hc name))
      ::
          %thread-done
        =/  sc  !<(scan:ks q.cage.sign)
        :-  ~[(leave:hc wire)]
        ?~  got=(~(get by previews) name)  this
        this(previews (~(put by previews) name u.got(got `sc, fail %.n)))
      ==
    ==
  ::
      [%about @ @ ~]
    ?~  c=(claim-of:hc wire)  [~[(leave:hc wire)] this]
    ?-    -.sign
        %poke-ack
      ?~  p.sign  `this
      %-  (slog leaf+"keep-sync: spider refused the about check of {<who.u.c>}" u.p.sign)
      [~[(leave:hc wire)] this(badges (judge:hc u.c %down))]
    ::
        %watch-ack
      ?~  p.sign  `this
      [~ this(badges (judge:hc u.c %down))]
    ::
        %kick
      [~ this(badges (judge:hc u.c %down))]
    ::
        %fact
      ?+    p.cage.sign  [~[(leave:hc wire)] this]
          %thread-fail
        =/  err  !<((pair term tang) q.cage.sign)
        %-  (slog leaf+"keep-sync: about check of {<who.u.c>} failed: {(trip p.err)}" q.err)
        [~[(leave:hc wire)] this(badges (judge:hc u.c %down))]
      ::
          %thread-done
        =/  ok  !<(? q.cage.sign)
        [~[(leave:hc wire)] this(badges (judge:hc u.c ?:(ok %yes %no)))]
      ==
    ==
  ::
      [%thread @ ~]
    =/  name  `@tas`i.t.wire
    ?-    -.sign
        %poke-ack
      ?~  p.sign  `this
      %-  (slog leaf+"keep-sync: spider refused {(trip name)}" u.p.sign)
      :-  ~[(leave:hc wire)]
      this(subs (clear:hc name))
    ::
        %watch-ack
      ?~  p.sign  `this
      %-  (slog leaf+"keep-sync: no thread-result for {(trip name)}" u.p.sign)
      [~ this(subs (clear:hc name))]
    ::
        %kick
      [~ this(subs (clear:hc name))]
    ::
        %fact
      ?+    p.cage.sign  [~[(leave:hc wire)] this]
          %thread-fail
        =/  err  !<((pair term tang) q.cage.sign)
        %-  (slog leaf+"keep-sync: pull failed for {(trip name)}: {(trip p.err)}" q.err)
        :-  ~[(leave:hc wire)]
        this(subs (clear:hc name))
      ::
          %thread-done
        =/  n  !<(@ud q.cage.sign)
        %-  (slog leaf+"keep-sync: {(trip name)}: {(a-co:co n)} posts landed" ~)
        :-  ~[(leave:hc wire)]
        this(subs (clear:hc name))
      ==
    ==
  ==
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%ames %sage *] sign-arvo)
    ?.  ?=([%badge @ @ ~] wire)  `this
    =^  cs  state  (on-badge:hc wire sage.sign-arvo)
    [cs this]
  ?.  ?=([%behn %wake *] sign-arvo)  (on-arvo:def wire sign-arvo)
  ?.  ?=([%poll @ ~] wire)  `this
  =/  name  `@tas`i.t.wire
  ?~  got=(~(get by subs) name)  `this
  ::  a second chain — an old timer surviving a re-track — fires early: drop it
  ?:  (lth now.bowl next.u.got)  `this
  =/  sub  u.got(next (add now.bowl every.u.got))
  ?^  error.sign-arvo
    %-  (slog leaf+"keep-sync: wake failed for {(trip name)}" u.error.sign-arvo)
    :_  this(subs (~(put by subs) name sub))
    ~[(wait:hc name every.sub)]
  ?^  tid.sub                          ::  still pulling; just re-arm
    :_  this(subs (~(put by subs) name sub))
    ~[(wait:hc name every.sub)]
  =/  tid=@ta  (mk-tid:hc name)
  :_  this(subs (~(put by subs) name sub(tid `tid)))
  [(wait:hc name every.sub) (start:hc name tid url.sub last.sub)]
::
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
++  clear
  |=  name=@tas
  ^-  _subs
  ?~  got=(~(get by subs) name)  subs
  (~(put by subs) name u.got(tid ~))
::
++  scan-failed
  |=  name=@tas
  ^-  _previews
  ?~  got=(~(get by previews) name)  previews
  (~(put by previews) name u.got(fail %.y))
::
::  iris parks forever on a scheme-less url: no response, no error
++  clean-url
  |=  url=@t
  ^-  @t
  =/  t  (trip url)
  ?~  t  url
  =/  s=tape  ?:(=('/' (rear t)) (snip `tape`t) t)
  =/  u  (crip s)
  ?:  ?|  =('http://' (end [3 7] u))
          =('https://' (end [3 8] u))
      ==
    u
  (cat 3 'https://' u)
::
++  mk-tid
  |=  name=@ta
  ^-  @ta
  (cat 3 'keep-sync--' (cat 3 name (scot %uv (sham eny.bowl))))
::
++  wait
  |=  [name=@tas every=@dr]
  ^-  card
  [%pass /poll/[name] %arvo %b %wait (add now.bowl every)]
::
++  thread-cards
  |=  [wir=wire tid=@ta file=term arg=vase]
  ^-  (list card)
  :~  [%pass wir %agent [our.bowl %spider] %watch /thread-result/[tid]]
      :^  %pass  wir  %agent
      :+  [our.bowl %spider]  %poke
      :-  %spider-start
      !>(`start-args:spider`[~ `tid byk.bowl(r da+now.bowl) file arg])
  ==
::
++  start
  |=  [name=@tas tid=@ta url=@t last=@da]
  ^-  (list card)
  (thread-cards /thread/[name] tid %keep-sync-pull !>(`[name url last]))
::
++  scan-start
  |=  [name=@tas tid=@ta url=@t]
  ^-  (list card)
  (thread-cards /scan/[name] tid %keep-sync-scan !>(`url))
::
++  leave
  |=  wir=wire
  ^-  card
  [%pass wir %agent [our.bowl %spider] %leave ~]
::
++  upload
  |=  [name=@tas p=post:ks terms=@t to=(set lyst:keep)]
  ^-  card
  :^  %pass  /post/[name]  %agent
  :+  [our.bowl %keep]  %poke
  keep-action+!>(`action:keep`[%backpost md+md.p `title.p terms to wen.p])
::
::  ---- substack identity ---------------------------------------------------
::
++  mine
  ^-  (set @t)
  (sy (turn ~(tap by subs) |=([* s=sub:ks] url.s)))
::
++  claims-of
  |=  who=ship
  ^-  (list claim:ks)
  (skim ~(tap in ~(key by badges)) |=(c=claim:ks =(who who.c)))
::
++  grow-mine
  ^-  (quip card _state)
  =/  urls  mine
  =^  cs  state  (learn our.bowl urls)
  [[[%pass /grow %grow /substack noun+urls] cs] state]
::
++  regrow
  |=  before=(set @t)
  ^-  (quip card _state)
  ?:  =(before mine)  [~ state]
  grow-mine
::
++  keen-badge
  |=  [who=ship at=@ud]
  ^-  card
  :^  %pass  /badge/(scot %ud at)/(scot %p who)  %keen
  [%.n who (welp (base-of:kc %keep-sync at) /substack)]
::
++  about-wire
  |=  c=claim:ks
  ^-  wire
  /about/(scot %p who.c)/(scot %uv (sham url.c))
::
++  claim-of
  |=  =wire
  ^-  (unit claim:ks)
  ?.  ?=([%about @ @ ~] wire)  ~
  =/  cs  (claims-of (slav %p i.t.wire))
  |-  ^-  (unit claim:ks)
  ?~  cs  ~
  ?:  =(wire (about-wire i.cs))  `i.cs
  $(cs t.cs)
::
++  about-start
  |=  c=claim:ks
  ^-  (list card)
  =/  tid=@ta  (mk-tid (cat 3 (scot %p who.c) (scot %uv (sham url.c))))
  (thread-cards (about-wire c) tid %keep-sync-about !>(`c))
::
::  a verdict for a claim that is gone, or no longer waiting, is stale
++  judge
  |=  [c=claim:ks =proof:ks]
  ^-  _badges
  ?~  got=(~(get by badges) c)  badges
  ?.  ?=(%wait proof.u.got)  badges
  (~(put by badges) c [proof now.bowl])
::
++  check
  |=  [c=claim:ks force=?]
  ^-  (quip card _state)
  =/  was=(unit badge:ks)  (~(get by badges) c)
  =/  due=?
    ?~  was  %.y
    ?:  ?=(%wait proof.u.was)  %.n
    |(force (gth now.bowl (add wen.u.was recheck-after)))
  ?.  due  [~ state]
  :-  (about-start c)
  state(badges (~(put by badges) c [%wait now.bowl]))
::
++  check-all
  |=  [who=ship force=?]
  ^-  (quip card _state)
  =/  cs  (claims-of who)
  =|  out=(list card)
  |-  ^-  (quip card _state)
  ?~  cs  [out state]
  =^  a  state  (check i.cs force)
  $(cs t.cs, out (weld out a))
::
++  learn
  |=  [who=ship urls=(set @t)]
  ^-  (quip card _state)
  =^  gone  state  (forget who urls)
  =/  new=(list @t)  ~(tap in urls)
  =|  out=(list card)
  |-  ^-  (quip card _state)
  ?~  new  [(weld gone out) state]
  =^  a  state  (check [who i.new] %.n)
  $(new t.new, out (weld out a))
::
::  a claim withdrawn while its check is in flight: stop listening too
++  forget
  |=  [who=ship still=(set @t)]
  ^-  (quip card _state)
  =/  had  (claims-of who)
  =|  out=(list card)
  |-  ^-  (quip card _state)
  ?~  had  [out state]
  ?:  (~(has in still) url.i.had)  $(had t.had)
  =/  was=badge:ks  (~(got by badges) i.had)
  %=  $
    had     t.had
    badges  (~(del by badges) i.had)
    out     ?.(?=(%wait proof.was) out [(leave (about-wire i.had)) out])
  ==
::
++  on-badge
  |=  [=wire =sage:mess:ames]
  ^-  (quip card _state)
  ?>  ?=([%badge @ @ ~] wire)
  =/  at=@ud    (slav %ud i.t.wire)
  =/  who=ship  (slav %p i.t.t.wire)
  ::  an old chain — a keen surviving a reinstall — answers late: drop it
  ?.  =(`at (~(get by keens) who))  [~ state]
  =/  next=(list card)  ~[(keen-badge who +(at))]
  =.  keens  (~(put by keens) who +(at))
  ::  %sage collapses tombstone and failure into one empty q; step over it
  ?:  ?=(~ q.sage)  [next state]
  ::  ;; is a hard cast; +mule installs a null scry gate, nothing inside may .^
  =/  got  (mule |.(;;((set @t) q.q.sage)))
  ?:  ?=(%| -.got)
    %-  (slog leaf+"keep-sync: unreadable substack claim from {<who>}" ~)
    [next state]
  =^  cs  state  (learn who p.got)
  [(weld next cs) state]
--
