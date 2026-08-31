::  keep-sync — substack publications into %keep, on a timer.
::
::    the fetching is threads (ted/keep-sync-scan, ted/keep-sync-pull); this
::    agent only keeps the schedule, holds scan previews, dedupes on slug,
::    and pokes %keep with what the pull thread sends back one %ingest at a
::    time — so a pull that dies keeps what it reached.
::
/-  keep, ks=keep-sync, spider
/+  default-agent, dbug
|%
+$  card  card:agent:gall
::
+$  versioned-state  $%(state-0 state-1)
+$  state-0  [%0 subs=(map @tas sub:ks)]
+$  state-1
  $:  %1
      subs=(map @tas sub:ks)
      previews=(map @tas prev:ks)
  ==
::
++  poll-floor  ~m15                   ::  substack is not ours to hammer
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
++  on-init  `this
++  on-save  !>(state)
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  ?-  -.old
    %1  `this(state old)
    %0  `this(state [%1 subs.old ~])
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %subs ~]      ``noun+!>(subs)
    [%x %previews ~]  ``noun+!>(previews)
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
      :_  this(previews (~(put by previews) name.act [url ~ %.n]))
      (scan-start:hc name.act tid url)
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
      :_  %=  this
            subs      (~(put by subs) name.act new)
            previews  (~(del by previews) name.act)
          ==
      :-  (wait:hc name.act every)
      %+  weld  orphan
      ?^  tid.base  ~                  ::  a pull is already in flight
      (start:hc name.act tid url last.base)
    ::
        %untrack
      ::  the timer chain ends itself: a wake for an unknown name stops
      `this(subs (~(del by subs) name.act))
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
  |=  name=@tas
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
--
