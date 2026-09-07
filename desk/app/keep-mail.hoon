::  keep-mail — mails a post to the ship's readers, on a click and never
::  otherwise. recipients are imported from a substack csv, on the ship.
::
::    one POST per 50 readers: the relay fans out one mail per address,
::    each with its own unsubscribe footer, and answers with a verdict per
::    address. a chunk in flight is keyed by its index in the round.
::    unsubscribes live at the relay and come back in `dropped`.
::
/-  keep, km=keep-mail
/+  default-agent, dbug, srv=server, kml=keep-mail, mh=md-html, kc=keep-core
|%
+$  card  card:agent:gall
+$  addr  addr:km
::  from and site were never read; the relay derives From from the key
+$  config-2  [relay=@t key=@t from=@t site=@t]
::
::  wait: the largest Retry-After the relay sent this round; 0 is "none"
+$  flite-1  [waiting=@ud tries=@ud fails=(list addr) wait=@dr]
::  round: the event that fired the requests; a response from any other is stale
+$  flite
  $:  round=@da
      tries=@ud
      fails=(list addr)
      wait=@dr
      open=(map @ud (list addr))         ::  chunks still unanswered
  ==
::
+$  state-0
  $:  %0
      config=(unit config-2)
      subs=(map addr @da)
      salt=@uvH                          ::  tokens derive from it; per-ship
      sent=(map id:keep @da)
      flight=(map id:keep [waiting=@ud tries=@ud fails=(list addr)])
      queue=(list [id=id:keep left=(list addr) tries=@ud])
      dead=(set id:keep)                 ::  gave up; the verb comes back
      imported=(unit [added=@ud dropped=@ud])
  ==
::
+$  state-1
  $:  %1
      config=(unit config-2)
      subs=(map addr @da)
      salt=@uvH
      sent=(map id:keep @da)
      flight=(map id:keep flite-1)
      queue=(list [id=id:keep left=(list addr) tries=@ud])
      dead=(set id:keep)
      imported=(unit [added=@ud dropped=@ud])
  ==
::
+$  state-2
  $:  %2
      config=(unit config-2)
      subs=(map addr @da)
      sent=(map id:keep @da)
      flight=(map id:keep flite)
      queue=(list [id=id:keep left=(list addr) tries=@ud])
      dead=(set id:keep)
      imported=(unit [added=@ud dropped=@ud])
  ==
::
+$  state-3
  $:  %3
      config=(unit config:km)
      subs=(map addr @da)
      sent=(map id:keep @da)
      flight=(map id:keep flite)
      queue=(list [id=id:keep left=(list addr) tries=@ud])
      dead=(set id:keep)
      imported=(unit [added=@ud dropped=@ud])
  ==
::
+$  versioned-state  $%(state-0 state-1 state-2 state-3)
::
++  retry-wait  ~m30
++  max-tries   5
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
++  on-init
  ^-  (quip card _this)
  :_  this
  ~[[%pass /bind %arvo %e %connect [~ /keep-mail] dap.bowl]]
::
++  on-save  !>(state)
++  on-load
  |=  =vase
  ^-  (quip card _this)
  =/  old  !<(versioned-state vase)
  |-
  ?-    -.old
      %3  `this(state old)
      %2
    :-  ~
    %=  this
      state
        :*  %3
            ?~(config.old ~ `[relay.u.config.old key.u.config.old])
            subs.old  sent.old  flight.old  queue.old  dead.old  imported.old
        ==
    ==
  ::
      %1
    ::  a round in flight answers on the old wire shape and would never settle
    %=  $
      old
        ^-  state-2
        :*  %2  config.old  subs.old  sent.old
            ~  queue.old  (~(uni in dead.old) ~(key by flight.old))  imported.old
        ==
    ==
  ::
      %0
    =/  ff=(map id:keep flite-1)
      =/  fs  ~(tap by flight.old)
      |-  ^-  (map id:keep flite-1)
      ?~  fs  ~
      (~(put by $(fs t.fs)) p.i.fs [waiting.q.i.fs tries.q.i.fs fails.q.i.fs ~s0])
    %=  $
      old
        ^-  state-1
        :*  %1  config.old  subs.old  salt.old  sent.old
            ff  queue.old  dead.old  imported.old
        ==
    ==
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %status ~]  ``noun+!>(status:hc)
    [%x %subs ~]    ``noun+!>(subs)
    [%x %sent ~]    ``noun+!>(sent)
    [%x %queue ~]   ``noun+!>(queue)
  ::  the key is readable on purpose: a leaked key is revoked at the relay
    [%x %config ~]  ``noun+!>(config)
  ==
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?+    mark  (on-poke:def mark vase)
      %keep-mail-action
    ?>  =(our.bowl src.bowl)
    =/  act  !<(action:km vase)
    ?-    -.act
        %config
      `this(config `(conf-defaults:kml config.act))
    ::
        %import
      =/  [good=(list addr) dropped=@ud]  (sieve:kml raw.act)
      =/  new=(list addr)  (skip good ~(has by subs))
      =/  ss=(map addr @da)
        =/  as  new
        |-  ^-  (map addr @da)
        ?~  as  subs
        (~(put by $(as t.as)) i.as now.bowl)
      `this(subs ss, imported `[(lent new) dropped])
    ::
        %remove
      =/  a=addr  (crip (lower:kml (trip addr.act)))
      `this(subs (~(del by subs) a))
    ::
        %send
      ?~  config  ~|(%keep-mail-not-configured !!)
      ?:  &(!again.act (~(has by sent) id.act))  `this
      ?:  (~(has by flight) id.act)  `this
      ?:  (queued:hc id.act)  `this
      =/  to=(list addr)  ~(tap in ~(key by subs))
      ?~  to  ~|(%keep-mail-no-readers !!)
      =/  pay  (payload:hc id.act)
      ?~  pay  ~|(%keep-mail-not-a-public-post !!)
      =/  open  (opened:hc to)
      :_  %=  this
            flight  (~(put by flight) id.act [now.bowl 0 ~ ~s0 open])
            sent    (~(del by sent) id.act)
            dead    (~(del in dead) id.act)
          ==
      (fire:hc u.config id.act now.bowl u.pay open)
    ==
  ::
      %handle-http-request
    =+  !<([rid=@ta ir=inbound-request:eyre] vase)
    :_  this
    (serve:hc rid ir)
  ==
::
++  on-watch
  |=  =path
  ^-  (quip card _this)
  ::  eyre watches as its GUEST identity for a cookie-less request — even
  ::  the login redirect rides that watch: gate on the path, not on src
  ?:  ?=([%http-response *] path)  `this
  ?>  =(our.bowl src.bowl)
  (on-watch:def path)
::
++  on-agent
  |=  [=wire =sign:agent:gall]
  ^-  (quip card _this)
  ?.  ?=([%self ~] wire)  (on-agent:def wire sign)
  ?.  ?=(%poke-ack -.sign)  `this
  ?~  p.sign  `this
  %-  (slog leaf+"keep-mail: refused" u.p.sign)
  `this
::
++  on-arvo
  |=  [=wire =sign-arvo]
  ^-  (quip card _this)
  ?:  ?=([%eyre %bound *] sign-arvo)
    ~?  !accepted.sign-arvo  %keep-mail-eyre-rejected-binding
    `this
  ::
  ?:  ?=([%behn %wake *] sign-arvo)
    ?.  ?=([%retry @ ~] wire)  `this
    =/  i=id:keep  (slav %uv i.t.wire)
    ?~  got=(find-queued:hc i)  `this
    =/  nq  (drop-queued:hc i)
    ?^  error.sign-arvo
      ::  behn hiccuped; re-arm rather than lose the batch
      :_  this
      ~[[%pass /retry/(scot %uv i) %arvo %b %wait (add now.bowl retry-wait)]]
    ?~  config  `this(queue nq)
    =/  live=(list addr)  (skim left.u.got ~(has by subs))
    ?~  live  `this(queue nq)
    =/  pay  (payload:hc i)
    ?~  pay
      %-  (slog leaf+"keep-mail: post gone; dropping its mail retry" ~)
      `this(queue nq)
    =/  open  (opened:hc live)
    :_  %=  this
          queue   nq
          flight  (~(put by flight) i [now.bowl tries.u.got ~ ~s0 open])
        ==
    (fire:hc u.config i now.bowl u.pay open)
  ::
  ?.  ?=([%iris %http-response *] sign-arvo)  (on-arvo:def wire sign-arvo)
  ?.  ?=([%send @ @ @ ~] wire)  `this
  =/  i=id:keep   (slav %uv i.t.wire)
  =/  round=@da   (slav %da i.t.t.wire)
  =/  k=@ud       (slav %ud i.t.t.t.wire)
  =/  res  client-response.sign-arvo
  ?:  ?=(%progress -.res)  `this
  =/  code=@ud
    ?:(?=(%finished -.res) status-code.response-header.res 0)
  ::  the relay's contract: a batch is 200 with per-recipient verdicts; 0
  ::  (%cancel), 429 and 5xx retry the whole call. everything else — 401
  ::  bad key, 422 systemic — means nothing was delivered and no recipient
  ::  is at fault: fail hard, never mark a post %sent on it.
  =/  done=?       &((gte code 200) (lth code 300))
  =/  retryable=?  |(=(0 code) =(429 code) (gte code 500))
  =/  ver=(unit [sent=(list addr) dropped=(list addr) retry=(list addr)])
    ?.  &(done ?=(%finished -.res))  ~
    ?~  full-file.res  ~
    (verdicts:kml q.data.u.full-file.res)
  ::  a stale round's verdict on an address still stands; on the post it does not
  =/  dropped=(list addr)  ?~(ver ~ dropped.u.ver)
  =.  subs  (prune:hc dropped)
  ?~  got=(~(get by flight) i)  `this
  ?.  =(round round.u.got)  `this
  ?~  chunk=(~(get by open.u.got) k)  `this
  ?.  |(done retryable)
    %-  (slog leaf+"keep-mail: relay refused ({(a-co:co code)}) — check the key at /keep/mail" ~)
    `this(flight (~(del by flight) i), dead (~(put in dead) i))
  ~?  ?=(^ dropped)  [%keep-mail-relay-dropped dropped]
  ::  a quota 429 carries Retry-After: seconds to the utc-midnight reset
  =/  wait=@dr
    %+  max  wait.u.got
    ?.(=(429 code) ~s0 (retry-after:hc res))
  =/  retry=(list addr)
    ?:  retryable  u.chunk
    ?~  ver  ~
    retry.u.ver
  =/  fails=(list addr)  (weld retry fails.u.got)
  =/  open  (~(del by open.u.got) k)
  ?.  =(~ open)
    `this(flight (~(put by flight) i u.got(fails fails, wait wait, open open)))
  ::  the last call landed: settle the post
  ?~  fails
    `this(flight (~(del by flight) i), sent (~(put by sent) i now.bowl))
  =/  tries=@ud  +(tries.u.got)
  ?:  (gte tries max-tries)
    =/  lost  (lent `(list addr)`fails)
    %-  (slog leaf+"keep-mail: giving up on {(scow %uv i)}: {(a-co:co lost)} unreached after {(a-co:co tries)} tries" ~)
    `this(flight (~(del by flight) i), dead (~(put in dead) i))
  =/  pause=@dr  ?:(=(~s0 wait) retry-wait (add wait ~m2))
  :_  this(flight (~(del by flight) i), queue [[i fails tries] queue])
  ~[[%pass /retry/(scot %uv i) %arvo %b %wait (add now.bowl pause)]]
::
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
::
|_  =bowl:gall
::
++  status
  ^-  status:km
  =/  m=(map id:keep mstat:km)
    =/  xs  ~(tap by sent)
    |-  ^-  (map id:keep mstat:km)
    ?~  xs  ~
    (~(put by $(xs t.xs)) p.i.xs [%sent q.i.xs])
  =.  m
    =/  xs  ~(tap in dead)
    |-  ^-  (map id:keep mstat:km)
    ?~  xs  m
    (~(put by $(xs t.xs)) i.xs [%failed ~])
  =.  m
    =/  xs  queue
    |-  ^-  (map id:keep mstat:km)
    ?~  xs  m
    (~(put by $(xs t.xs)) id.i.xs [%queued tries.i.xs])
  =.  m
    =/  xs  ~(tap by flight)
    |-  ^-  (map id:keep mstat:km)
    ?~  xs  m
    (~(put by $(xs t.xs)) p.i.xs [%sending ~])
  [?=(^ config) ?~(config '' key.u.config) ~(wyt by subs) imported m]
::
++  opened
  |=  as=(list addr)
  ^-  (map @ud (list addr))
  =/  cs  (chunks:kml as)
  =|  k=@ud
  |-  ^-  (map @ud (list addr))
  ?~  cs  ~
  (~(put by $(cs t.cs, k +(k))) k i.cs)
::
++  fire
  |=  [c=config:km i=id:keep round=@da pay=[sub=@t txt=@t htm=@t] open=(map @ud (list addr))]
  ^-  (list card)
  %+  turn  ~(tap by open)
  |=([k=@ud as=(list addr)] (send-one c i round k pay as))
::
++  prune
  |=  as=(list addr)
  ^-  (map addr @da)
  =/  m  subs
  |-  ^-  (map addr @da)
  ?~  as  m
  $(as t.as, m (~(del by m) i.as))
::
++  retry-after
  |=  res=client-response:iris
  ^-  @dr
  ?.  ?=(%finished -.res)  ~s0
  ?~  v=(get-header:http 'retry-after' headers.response-header.res)  ~s0
  ?~  s=(rush u.v dem)  ~s0
  ::  a day is the longest anything resets on; a bigger claim is a bug
  ?:  (gth u.s 86.400)  ~d1
  (mul u.s ~s1)
::
++  queued
  |=  i=id:keep
  ^-  ?
  (lien queue |=([q=id:keep * *] =(q i)))
::
++  find-queued
  |=  i=id:keep
  ^-  (unit [left=(list addr) tries=@ud])
  =/  qs  queue
  |-  ^-  (unit [left=(list addr) tries=@ud])
  ?~  qs  ~
  ?:  =(id.i.qs i)  `[left.i.qs tries.i.qs]
  $(qs t.qs)
::
++  drop-queued
  |=  i=id:keep
  ^-  _queue
  (skip queue |=([q=id:keep * *] =(q i)))
::
::  ~ is "not mailable": no such post, not %public, or not prose
++  payload
  |=  i=id:keep
  ^-  (unit [sub=@t txt=@t htm=@t])
  =/  us=@ta   (scot %p our.bowl)
  =/  wen=@ta  (scot %da now.bowl)
  =/  aud
    .^  (unit (set lyst:keep))  %gx
    /[us]/keep/[wen]/audience/(scot %uv i)/noun
    ==
  ?~  aud  ~
  ?.  (~(has in u.aud) %public)  ~
  =/  ps  .^((map id:keep item:keep) %gx /[us]/keep/[wen]/posts/noun)
  ?~  got=(~(get by ps) i)  ~
  ?.  ?=([%md @] page.u.got)  ~
  =/  md=@t  `@t`q.page.u.got
  `[(subject:kml title.head.u.got md) md (convert:mh md)]
::
::  no footer: the relay appends its own unsubscribe footer and RFC-8058
::  headers per recipient
++  send-one
  |=  [c=config:km i=id:keep round=@da k=@ud pay=[sub=@t txt=@t htm=@t] to=(list addr)]
  ^-  card
  =/  jon=json
    %-  pairs:enjs:format
    :~  ['patp' s+(scot %p our.bowl)]
        ['to' a+(turn to |=(a=addr ^-(json s+a)))]
        ['subject' s+sub.pay]
        ['text' s+txt.pay]
        ['html' s+htm.pay]
    ==
  =/  =request:http
    :*  %'POST'
        relay.c
        :~  ['content-type' 'application/json']
            ['authorization' (cat 3 'Bearer ' key.c)]
        ==
        `(as-octs:mimes:html (en:json:html jon))
    ==
  :^    %pass
      /send/(scot %uv i)/(scot %da round)/(scot %ud k)
    %arvo
  [%i %request request *outbound-config:iris]
::
::  ---- http ------------------------------------------------------------------
::
++  serve
  |=  [rid=@ta ir=inbound-request:eyre]
  ^-  (list card)
  =*  req  request.ir
  ?.  authenticated.ir
    (paint rid (login-redirect:gen:srv req))
  ?.  =('POST' method.req)
    (paint rid not-found:gen:srv)
  ?.  (same-origin:kc header-list.req)
    (paint rid [[403 ~] ~])
  =/  q=(list [@t @t])
    ?~  body.req  ~
    =/  got  (rush q.u.body.req yquy:de-purl:html)
    ?~(got ~ u.got)
  ?.  =('config' (arg q 'what'))
    (paint rid not-found:gen:srv)
  ::  the form takes the key only: a forged POST must not be able to
  ::  repoint the relay. relay is set from the dojo, and survives
  =/  c=config:km
    =/  old=config:km  ?~(config *config:km u.config)
    old(key (arg q 'key'))
  ?:  =('' key.c)
    (paint rid [[400 ~] ~])
  %+  weld  ~[(poke-self [%config c])]
  =/  back=@t  (arg q 'back')
  ?:  =('' back)  (paint rid [[200 ~] ~])
  ::  303 not 307: 307 preserves the method and re-POSTs the form on refresh
  (paint rid [[303 ['location' back]~] ~])
::
++  paint
  |=  [rid=@ta pay=simple-payload:http]
  ^-  (list card)
  (give-simple-payload:app:srv rid pay)
::
++  poke-self
  |=  act=action:km
  ^-  card
  [%pass /self %agent [our.bowl dap.bowl] %poke %keep-mail-action !>(act)]
::
::  positional, not k= and v=: quay's faces are p and q
++  arg
  |=  [q=(list [@t @t]) key=@t]
  ^-  @t
  ?~  q  ''
  ?:  =(key -.i.q)  +.i.q
  $(q t.q)
--
