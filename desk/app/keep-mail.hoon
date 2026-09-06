::  keep-mail — mails a post to the ship's readers, on a click and never
::  otherwise. recipients are imported from a substack csv, on the ship.
::
::    one POST per recipient, not the relay's 50-a-call batching: the
::    unsubscribe token is per-address, and a shared body cannot carry it.
::
/-  keep, km=keep-mail
/+  default-agent, dbug, srv=server, kml=keep-mail, mh=md-html
|%
+$  card  card:agent:gall
+$  addr  addr:km
::
+$  state-0
  $:  %0
      config=(unit config:km)
      subs=(map addr @da)
      salt=@uvH                          ::  tokens derive from it; per-ship
      sent=(map id:keep @da)
      flight=(map id:keep [waiting=@ud tries=@ud fails=(list addr)])
      queue=(list [id=id:keep left=(list addr) tries=@ud])
      dead=(set id:keep)                 ::  gave up; the verb comes back
      imported=(unit [added=@ud dropped=@ud])
  ==
::
++  retry-wait  ~m30
++  max-tries   5
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
++  on-init
  ^-  (quip card _this)
  ::  never bunt a salt: a zero salt makes every unsubscribe token derivable
  :_  this(salt (sham eny.bowl))
  ~[[%pass /bind %arvo %e %connect [~ /keep-mail] dap.bowl]]
::
++  on-save  !>(state)
++  on-load
  |=  =vase
  ^-  (quip card _this)
  `this(state !<(state-0 vase))
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
        %unsubscribe
      =/  hit=(unit addr)
        =/  as  ~(tap in ~(key by subs))
        |-  ^-  (unit addr)
        ?~  as  ~
        ?:  =(tok.act (token:kml i.as salt))  `i.as
        $(as t.as)
      ?~  hit  `this
      `this(subs (~(del by subs) u.hit))
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
      :_  %=  this
            flight  (~(put by flight) id.act [(lent `(list addr)`to) 0 ~])
            sent    (~(del by sent) id.act)
            dead    (~(del in dead) id.act)
          ==
      (turn `(list addr)`to |=(a=addr (send-one:hc u.config id.act u.pay a)))
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
  ::  eyre watches as its GUEST identity for a cookie-less request, and the
  ::  unsubscribe link arrives with no session: gate on the path, not on src
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
    :_  %=  this
          queue   nq
          flight  (~(put by flight) i [(lent `(list addr)`live) tries.u.got ~])
        ==
    (turn `(list addr)`live |=(a=addr (send-one:hc u.config i u.pay a)))
  ::
  ?.  ?=([%iris %http-response *] sign-arvo)  (on-arvo:def wire sign-arvo)
  ?.  ?=([%send @ @ ~] wire)  `this
  =/  i=id:keep  (slav %uv i.t.wire)
  =/  a=addr     `@t`(slav %uv i.t.t.wire)
  =/  res  client-response.sign-arvo
  ?:  ?=(%progress -.res)  `this
  ?~  got=(~(get by flight) i)  `this
  =/  code=@ud
    ?:(?=(%finished -.res) status-code.response-header.res 0)
  ?:  |(=(401 code) =(403 code))
    ::  the key is wrong or claims another ship: no retry can fix config
    %-  (slog leaf+"keep-mail: relay refused our key ({(a-co:co code)}) — check config" ~)
    `this(flight (~(del by flight) i), dead (~(put in dead) i))
  ::  0 is a %cancel; those, 429 and 5xx retry. 400 names a bad address:
  ::  drop it. everything else 2xx-ish is done.
  =/  retryable=?  |(=(0 code) =(429 code) (gte code 500))
  =/  bad-addr=?   =(400 code)
  ~?  bad-addr  [%keep-mail-relay-rejected-address a]
  =/  fails=(list addr)
    ?:(retryable [a fails.u.got] fails.u.got)
  =/  ss=(map addr @da)
    ?.(bad-addr subs (~(del by subs) a))
  =/  n=@ud  (dec waiting.u.got)
  ?.  =(0 n)
    :-  ~
    %=  this
      subs    ss
      flight  (~(put by flight) i u.got(waiting n, fails fails))
    ==
  ::  the last response landed: settle the post
  ?~  fails
    :-  ~
    %=  this
      subs    ss
      flight  (~(del by flight) i)
      sent    (~(put by sent) i now.bowl)
    ==
  =/  tries=@ud  +(tries.u.got)
  ?:  (gte tries max-tries)
    =/  lost  (lent `(list addr)`fails)
    %-  (slog leaf+"keep-mail: giving up on {(scow %uv i)}: {(a-co:co lost)} unreached after {(a-co:co tries)} tries" ~)
    :-  ~
    %=  this
      subs    ss
      flight  (~(del by flight) i)
      dead    (~(put in dead) i)
    ==
  :_  %=  this
        subs    ss
        flight  (~(del by flight) i)
        queue   [[i fails tries] queue]
      ==
  ~[[%pass /retry/(scot %uv i) %arvo %b %wait (add now.bowl retry-wait)]]
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
++  send-one
  |=  [c=config:km i=id:keep pay=[sub=@t txt=@t htm=@t] a=addr]
  ^-  card
  =/  unsub=@t
    %+  rap  3
    ~[site.c '/keep-mail/unsubscribe/' (scot %uv (token:kml a salt))]
  =/  jon=json
    %-  pairs:enjs:format
    :~  ['patp' s+(scot %p our.bowl)]
        ['to' s+a]
        ['subject' s+sub.pay]
        ['text' s+(rap 3 ~[txt.pay '\0a\0a--\0aunsubscribe: ' unsub '\0a'])]
        :-  'html'
        :-  %s
        %+  rap  3
        :~  htm.pay
            '<hr/><p style="font-size:12px;color:#8a857c"><a href="'
            unsub  '">unsubscribe</a></p>'
        ==
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
      /send/(scot %uv i)/(scot %uv `@uv`a)
    %arvo
  [%i %request request *outbound-config:iris]
::
::  ---- http ------------------------------------------------------------------
::
++  serve
  |=  [rid=@ta ir=inbound-request:eyre]
  ^-  (list card)
  =*  req  request.ir
  =/  =pork:eyre
    (rash url.req ;~(sfix apat:de-purl:html yquy:de-purl:html))
  =/  seg=path  q.pork
  ?:  ?=([%keep-mail %unsubscribe @ ~] seg)
    ::  eyre split the token's last dot into pork's ext; put it back
    =/  raw=@t
      ?~  p.pork  i.t.t.seg
      (rap 3 ~[i.t.t.seg '.' u.p.pork])
    ::  one page whether or not the token matched: tokens are not probes
    %+  weld
      ?~  tok=(slaw %uv raw)  ~
      ~[(poke-self [%unsubscribe u.tok])]
    (paint rid (manx-response:gen:srv unsub-page))
  ?.  authenticated.ir
    (paint rid (login-redirect:gen:srv req))
  ?.  =('POST' method.req)
    (paint rid not-found:gen:srv)
  =/  q=(list [@t @t])
    ?~  body.req  ~
    =/  got  (rush q.u.body.req yquy:de-purl:html)
    ?~(got ~ u.got)
  ?.  =('config' (arg q 'what'))
    (paint rid not-found:gen:srv)
  ::  only the key is required: the relay is baked in, and the footer's
  ::  base url can come from where the writer is browsing right now
  =/  site=@t
    =/  given  (arg q 'site')
    ?.  =('' given)  given
    ?~  host=(get-header:http 'host' header-list.req)  ''
    (cat 3 ?:(secure.ir 'https://' 'http://') u.host)
  =/  c=config:km
    [(arg q 'relay') (arg q 'key') (arg q 'from') site]
  ?:  =('' key.c)
    (paint rid [[400 ~] ~])
  %+  weld  ~[(poke-self [%config c])]
  =/  back=@t  (arg q 'back')
  ?:  =('' back)  (paint rid [[200 ~] ~])
  ::  303 not 307: 307 preserves the method and re-POSTs the form on refresh
  (paint rid [[303 ['location' back]~] ~])
::
++  unsub-page
  ^-  manx
  ;html
    ;head
      ;title: unsubscribed
      ;meta(charset "utf-8");
      ;meta(name "viewport", content "width=device-width, initial-scale=1");
    ==
    ;body(style "font-family:Georgia,serif;background:#fbfaf8;color:#171614;padding:64px 24px")
      ;p(style "max-width:52ch;margin:0 auto"): you're unsubscribed — this address gets no more posts from this ship.
    ==
  ==
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
