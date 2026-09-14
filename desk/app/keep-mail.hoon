::  keep-mail — mails a post to the ship's readers, on a click and never
::  otherwise. recipients are imported from a substack csv, on the ship;
::  the relay holds the consent record for each and mails only those who
::  confirmed, reporting the rest back.
::
::    a send is three hops on one round: ask the relay who confirmed (and
::    merge them in), POST the post with the whole list, then poll the job
::    it answers with until it settles. a round stamps its event time into
::    the flight and every wire, so a response from an earlier round
::    cannot touch the post — it can only still prune an address the
::    relay dropped.
::
/-  keep, km=keep-mail, ks=keep-sync
/+  default-agent, dbug, srv=server, kml=keep-mail, mh=md-html, kc=keep-core
|%
+$  card  card:agent:gall
+$  addr  addr:km
::  from and site were never read; the relay derives From from the key
+$  config-2  [relay=@t key=@t from=@t site=@t]
::
+$  flite-1  [waiting=@ud tries=@ud fails=(list addr) wait=@dr]
+$  flite-2
  $:  round=@da
      tries=@ud
      fails=(list addr)
      wait=@dr
      open=(map @ud (list addr))
  ==
+$  flite-5  [round=@da tries=@ud job=(unit @t) again=?]
::  round: the event that fired the send; job: what the relay gave back;
::  again: the writer re-mailing a sent post, which the relay must be told;
::  sent/of: progress, for the page
+$  flite  [round=@da tries=@ud job=(unit @t) again=? sent=@ud of=@ud]
+$  readers-4  [active=@ud pending=@ud as-of=@da]
::
+$  state-0
  $:  %0
      config=(unit config-2)
      subs=(map addr @da)
      salt=@uvH
      sent=(map id:keep @da)
      flight=(map id:keep [waiting=@ud tries=@ud fails=(list addr)])
      queue=(list [id=id:keep left=(list addr) tries=@ud])
      dead=(set id:keep)
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
      flight=(map id:keep flite-2)
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
      flight=(map id:keep flite-2)
      queue=(list [id=id:keep left=(list addr) tries=@ud])
      dead=(set id:keep)
      imported=(unit [added=@ud dropped=@ud])
  ==
::
::  a day's build that held no list at all, briefly on the test fleet
+$  state-4
  $:  %4
      config=(unit config:km)
      readers=(unit readers-4)
      sent=(map id:keep @da)
      flight=(map id:keep [round=@da tries=@ud job=(unit @t)])
      queue=(list [id=id:keep tries=@ud])
      dead=(set id:keep)
  ==
::
+$  state-5
  $:  %5
      config=(unit config:km)
      subs=(map addr @da)
      view=(unit readers:km)
      imported=(unit [added=@ud dropped=@ud])
      relayed=(unit @t)
      proof=(unit proof:km)
      sent=(map id:keep @da)
      flight=(map id:keep flite-5)
      queue=(list [id=id:keep tries=@ud again=?])
      dead=(set id:keep)
  ==
::
+$  state-6
  $:  %6
      config=(unit config:km)
      name=@t
      subs=(map addr @da)
      view=(unit readers:km)
      asked=(unit @ud)
      relayed=(unit @t)
      proof=(unit proof:km)
      staged=(unit [raw=@t url=@t])
      sent=(map id:keep [wen=@da n=@ud lost=@ud])
      flight=(map id:keep flite)
      queue=(list [id=id:keep tries=@ud again=?])
      dead=(map id:keep @t)
  ==
::
+$  state-7
  $:  %7
      config=(unit config:km)
      name=@t                            ::  the sender readers see; '' is the ship's name
      subs=(map addr @da)
      view=(unit readers:km)             ::  the relay's confirmed set, last we asked
      asked=(unit @ud)                   ::  the last import: how many the relay will ask
      relayed=(unit @t)                  ::  or why it refused
      proof=(unit proof:km)              ::  the optional substack badge
      checked=(unit @t)                  ::  what the last ownership check said, if it failed
      trouble=(unit @t)                  ::  the relay rejected our key, or could not be reached
      sent=(map id:keep [wen=@da n=@ud lost=@ud])
      flight=(map id:keep flite)
      queue=(list [id=id:keep tries=@ud again=?])
      dead=(map id:keep @t)              ::  gave up, and why; the verb comes back
  ==
::
+$  versioned-state  $%(state-0 state-1 state-2 state-3 state-4 state-5 state-6 state-7)
::
++  retry-wait  ~m30
++  max-tries   5
++  poll-first  ~s10
++  poll-wait   ~m2
++  view-fresh  ~m1
--
::
%-  agent:dbug
=|  state-7
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
      %7  `this(state old)
  ::
      %6
    :-  ?~(config.old ~ (ask:hc u.config.old))
    %=  this
      state
        ^-  state-7
        :*  %7  config.old  name.old  subs.old  view.old  asked.old  relayed.old
            proof.old  ~  ~  sent.old  flight.old  queue.old  dead.old
        ==
    ==
  ::
      %5
    =/  back=(map id:keep @t)
      =/  ids  ~(tap in (~(uni in dead.old) ~(key by flight.old)))
      =/  qs   (turn queue.old |=([i=id:keep *] i))
      %-  ~(gas by *(map id:keep @t))
      (turn (weld ids qs) |=(i=id:keep [i 'this post was mid-send during an upgrade — mail it again']))
    =/  sn=(map id:keep [wen=@da n=@ud lost=@ud])
      (~(run by sent.old) |=(w=@da [w 0 0]))
    %=  $
      old
        ^-  state-6
        [%6 config.old '' subs.old ~ ~ relayed.old proof.old ~ sn ~ ~ back]
    ==
  ::
      %4
    =/  back=(set id:keep)
      %-  ~(uni in dead.old)
      %-  ~(uni in ~(key by flight.old))
      (~(gas in *(set id:keep)) (turn queue.old |=([i=id:keep *] i)))
    %=  $
      old
        ^-  state-5
        [%5 config.old ~ ~ ~ ~ ~ sent.old ~ ~ back]
    ==
  ::
      %3
    =/  conf=(unit config:km)
      ?~  config.old  ~
      `(conf-defaults:kml [(base-of:kml relay.u.config.old) key.u.config.old])
    =/  back=(set id:keep)
      %-  ~(uni in dead.old)
      %-  ~(uni in ~(key by flight.old))
      (~(gas in *(set id:keep)) (turn queue.old |=([i=id:keep *] i)))
    %=  $
      old
        ^-  state-5
        [%5 conf subs.old ~ imported.old ~ ~ sent.old ~ ~ back]
    ==
  ::
      %2
    %=  $
      old
        ^-  state-3
        :*  %3
            ?~(config.old ~ `[relay.u.config.old key.u.config.old])
            subs.old  sent.old  flight.old  queue.old  dead.old  imported.old
        ==
    ==
  ::
      %1
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
    [%x %status ~]   ``noun+!>(status:hc)
    [%x %subs ~]     ``noun+!>(subs)
    [%x %view ~]     ``noun+!>(view)
    [%x %sent ~]     ``noun+!>(sent)
    [%x %queue ~]    ``noun+!>(queue)
    [%x %flight ~]   ``noun+!>(flight)
    [%x %dead ~]     ``noun+!>(dead)
    [%x %proof ~]    ``noun+!>(proof)
  ::  the key is readable on purpose: a leaked key is revoked at the relay
    [%x %config ~]   ``noun+!>(config)
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
      =/  c  (conf-defaults:kml config.act)
      :_  this(config `c)
      %+  weld  (ask:hc c)
      ?:(=('' name) ~ ~[(tell-name:hc c name)])
    ::
        %name
      =/  n=@t  (crip (strip:kml (trip name.act)))
      :_  this(name n)
      ?~(config ~ ~[(tell-name:hc u.config n)])
    ::
    ::  only when the view is stale: the page asks on every load
        %refresh
      ?~  config  `this
      ?:  ?&  ?=(^ view)
              ?=(^ proof)
              (lth (sub now.bowl as-of.u.view) view-fresh)
          ==
        `this
      :_  this
      (ask:hc u.config)
    ::
        %verify
      ?~  config  ~|(%keep-mail-not-configured !!)
      :_  this
      ~[(verify:hc u.config url.act)]
    ::
    ::  the csv is the list, here and now, and the relay gets it in the
    ::  same click. a page address given alongside is checked for the
    ::  badge; the import does not wait on it
        %import
      =/  [good=(list addr) dropped=@ud]  (sieve:kml raw.act)
      =/  new=(list addr)  (skip good ~(has by subs))
      =/  ss=(map addr @da)
        =/  as  new
        |-  ^-  (map addr @da)
        ?~  as  subs
        (~(put by $(as t.as)) i.as now.bowl)
      =/  url=@t  (crip (strip:kml (trip url.act)))
      =/  proven=(unit @t)  ?~(proof ~ verified.u.proof)
      ?~  config
        `this(subs ss, asked ~, relayed `'email isn\'t connected to this ship yet')
      :_  this(subs ss, asked ~, relayed ~, checked ?:(=('' url) checked ~))
      :-  (hand-import:hc u.config raw.act (fall proven url))
      ?:  |(=('' url) =(`url proven))  ~
      ~[(verify:hc u.config url)]
    ::
        %remove
      =/  a=addr  (crip (lower:kml (trip addr.act)))
      `this(subs (~(del by subs) a))
    ::
        %reset
      `this(asked ~, relayed ~)
    ::
        %send
      ?~  config  ~|(%keep-mail-not-configured !!)
      ?:  &(!again.act (~(has by sent) id.act))  `this
      ?:  (~(has by flight) id.act)  `this
      ?:  (queued:hc id.act)  `this
      =/  pay  (payload:hc id.act)
      ?~  pay  ~|(%keep-mail-not-a-public-post !!)
      :_  %=  this
            flight  (~(put by flight) id.act [now.bowl 0 ~ again.act 0 0])
            sent    (~(del by sent) id.act)
            dead    (~(del by dead) id.act)
          ==
      ~[(sync:hc u.config id.act now.bowl)]
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
    ?+    wire  `this
        [%retry @ ~]
      =/  i=id:keep  (slav %uv i.t.wire)
      ?~  got=(find-queued:hc i)  `this
      =/  [tries=@ud again=?]  u.got
      ?^  error.sign-arvo
        ::  behn hiccuped; re-arm rather than lose the send
        :_  this
        ~[[%pass /retry/(scot %uv i) %arvo %b %wait (add now.bowl retry-wait)]]
      =/  nq  (drop-queued:hc i)
      ?~  config  `this(queue nq)
      ?~  (payload:hc i)
        %-  (slog leaf+"keep-mail: post gone; dropping its mail retry" ~)
        `this(queue nq)
      :_  %=  this
            queue   nq
            flight  (~(put by flight) i [now.bowl tries ~ again 0 0])
          ==
      ~[(sync:hc u.config i now.bowl)]
    ::
        [%tick @ @ ~]
      =/  i=id:keep   (slav %uv i.t.wire)
      =/  round=@da   (slav %da i.t.t.wire)
      ?~  got=(~(get by flight) i)  `this
      ?.  =(round round.u.got)  `this
      ?~  job.u.got  `this
      ?~  config  `this
      :_  this
      ~[(poll-job:hc u.config i round u.job.u.got)]
    ==
  ::
  ?.  ?=([%iris %http-response *] sign-arvo)  (on-arvo:def wire sign-arvo)
  =/  res  client-response.sign-arvo
  ?:  ?=(%progress -.res)  `this
  =/  code=@ud
    ?:(?=(%finished -.res) status-code.response-header.res 0)
  =/  body=@t
    ?.  ?=(%finished -.res)  ''
    ?~  full-file.res  ''
    q.data.u.full-file.res
  =/  ok=?  &((gte code 200) (lth code 300))
  ?+    wire  `this
      [%readers ~]
    `this(state (merge:hc code body), trouble (trouble-of:hc code body))
  ::
      [%proof ~]
    =.  trouble  (trouble-of:hc code body)
    ?.  ok  `this
    =.  proof  (proof-of:kml body)
    ?~  config  `this
    ?:  &(?=(^ proof) ?=(^ verified.u.proof))  `this
    =/  c  claim:hc
    ?~  c  `this
    ?.  ?=(%yes proof.u.c)  `this
    :_  this
    ~[(verify:hc u.config url.u.c)]
  ::
      [%profile ~]
    ~?  !ok  [%keep-mail-name-not-taken code]
    `this
  ::
  ::  the ownership check answers: a badge, or a sentence about why not
      [%verify ~]
    =/  p  ?.(ok ~ (proof-of:kml body))
    =/  found=?  &(?=(^ p) ?=(^ verified.u.p))
    =/  np=(unit proof:km)  ?~(p proof p)
    ?:  found  `this(proof np, checked ~)
    `this(proof np, checked `'Keep couldn\'t find your ship\'s name on the About page yet — try Check again in a minute')
  ::
      [%import ~]
    =/  n  ?.(ok ~ (import-of:kml body))
    ?~  n
      `this(asked ~, relayed `(detail-of:kml body))
    `this(asked n, relayed ~)
  ::
  ::  who confirmed, merged in; then the post goes with the whole list.
  ::  a relay that cannot answer here still gets the send: it gates anyway
      [%sync @ @ ~]
    =/  i=id:keep   (slav %uv i.t.wire)
    =/  round=@da   (slav %da i.t.t.wire)
    =.  state  (merge:hc code body)
    ?~  got=(~(get by flight) i)  `this
    ?.  =(round round.u.got)  `this
    ?~  config  `this
    ?~  pay=(payload:hc i)
      `this(flight (~(del by flight) i))
    :_  this
    ~[(send-post:hc u.config i round again.u.got u.pay ~(tap in ~(key by subs)))]
  ::
  ::  the send: 202 carries the job to poll and the verdict on each address
  ::  the relay will not mail. 0 (%cancel), 429 and 5xx retry the whole
  ::  call; everything else — 401 bad key, 403 the writer may not send, 422
  ::  systemic — means nothing was delivered: fail hard, say why, never mark
  ::  a post %sent on it
      [%send @ @ ~]
    =/  i=id:keep   (slav %uv i.t.wire)
    =/  round=@da   (slav %da i.t.t.wire)
    =/  ans  ?.(ok ~ (job-of:kml body))
    ::  a stale round's verdict on an address still stands; on the post it does not
    =?  subs  ?=(^ ans)  (prune:hc dropped.u.ans)
    ~?  &(?=(^ ans) ?=(^ dropped.u.ans))  [%keep-mail-relay-dropped dropped.u.ans]
    ?~  got=(~(get by flight) i)  `this
    ?.  =(round round.u.got)  `this
    ?^  ans
      ?:  =(0 recipients.u.ans)
        %-  (slog leaf+"keep-mail: none of your readers has confirmed yet — nothing was sent" ~)
        `this(flight (~(del by flight) i))
      :_  this(flight (~(put by flight) i u.got(job `job.u.ans, of recipients.u.ans)))
      ~[(tick:hc i round poll-first)]
    =^  cards  state
      ?:  |(=(0 code) =(429 code) (gte code 500))
        (defer:hc i +(tries.u.got) again.u.got (retry-after:hc res))
      (give-up:hc i (why-of:kml code body))
    [cards this]
  ::
  ::  the job: done settles the post; failed surfaces the relay's reason;
  ::  anything still moving updates the count and is asked again in a while
      [%poll @ @ ~]
    =/  i=id:keep   (slav %uv i.t.wire)
    =/  round=@da   (slav %da i.t.t.wire)
    ?~  got=(~(get by flight) i)  `this
    ?.  =(round round.u.got)  `this
    ?:  |(=(401 code) =(403 code) =(404 code))
      =^  cards  state  (give-up:hc i (why-of:kml code body))
      [cards this]
    =/  st  ?.(=(200 code) ~ (job-state:kml body))
    ?~  st
      :_  this
      ~[(tick:hc i round poll-wait)]
    ?:  =('failed' status.u.st)
      =^  cards  state  (give-up:hc i (why-of:kml 0 (fall error.u.st 'Keep gave up on this send')))
      [cards this]
    ?.  =('done' status.u.st)
      :_  this(flight (~(put by flight) i u.got(sent sent.u.st)))
      ~[(tick:hc i round poll-wait)]
    =/  reached  [now.bowl sent.u.st failed.u.st]
    `this(flight (~(del by flight) i), sent (~(put by sent) i reached))
  ==
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
    =/  xs  ~(tap by dead)
    |-  ^-  (map id:keep mstat:km)
    ?~  xs  m
    (~(put by $(xs t.xs)) p.i.xs [%failed q.i.xs])
  =.  m
    =/  xs  queue
    |-  ^-  (map id:keep mstat:km)
    ?~  xs  m
    (~(put by $(xs t.xs)) id.i.xs [%queued tries.i.xs])
  =.  m
    =/  xs  ~(tap by flight)
    |-  ^-  (map id:keep mstat:km)
    ?~  xs  m
    (~(put by $(xs t.xs)) p.i.xs [%sending sent.q.i.xs of.q.i.xs])
  =/  conf=@ud  confirmed
  :*  ?=(^ config)
      ?~(config '' key.u.config)
      name
      conf
      (sub ~(wyt by subs) conf)
      ?~(view ~ `as-of.u.view)
      asked
      relayed
      proof
      checked
      claim
      trouble
      ?~(config '' (subscribe-url:kml relay.u.config our.bowl))
      m
  ==
::
::  a look at the relay that came back wrong, in the writer's words
++  trouble-of
  |=  [code=@ud body=@t]
  ^-  (unit @t)
  ?:  &((gte code 200) (lth code 300))  ~
  ?:  |(=(401 code) =(403 code))  `(why-of:kml code body)
  `'Keep couldn\'t be reached just now — this page will try again'

::
::  readers on the ship the relay would actually mail
++  confirmed
  ^-  @ud
  ?~  view  0
  %-  lent
  (skim ~(tap in ~(key by subs)) ~(has in confirmed.u.view))
::
::  the relay's confirmed set becomes ours: a reader who confirmed through
::  the form on our page is on our list from the next look
++  merge
  |=  [code=@ud body=@t]
  ^+  state
  ?.  &((gte code 200) (lth code 300))  state
  ?~  r=(readers-of:kml body)  state
  =/  ss=(map addr @da)
    =/  as  active.u.r
    |-  ^-  (map addr @da)
    ?~  as  subs
    =/  m  $(as t.as)
    ?:((~(has by m) i.as) m (~(put by m) i.as now.bowl))
  %=  state
    subs  ss
    view  `[(~(gas in *(set addr)) active.u.r) pending.u.r now.bowl]
  ==
::
++  prune
  |=  as=(list addr)
  ^-  (map addr @da)
  =/  m  subs
  |-  ^-  (map addr @da)
  ?~  as  m
  $(as t.as, m (~(del by m) i.as))
::
++  queued
  |=  i=id:keep
  ^-  ?
  (lien queue |=([q=id:keep *] =(q i)))
::
++  find-queued
  |=  i=id:keep
  ^-  (unit [tries=@ud again=?])
  =/  qs  queue
  |-  ^-  (unit [tries=@ud again=?])
  ?~  qs  ~
  ?:  =(id.i.qs i)  `[tries.i.qs again.i.qs]
  $(qs t.qs)
::
++  drop-queued
  |=  i=id:keep
  ^-  _queue
  (skip queue |=([q=id:keep *] =(q i)))
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
::  the send failed for now: back off, then try again from the top
++  defer
  |=  [i=id:keep tries=@ud again=? wait=@dr]
  ^-  (quip card _state)
  ?:  (gte tries max-tries)
    =/  why  'Keep couldn\'t be reached — nothing went out'
    %-  (slog leaf+"keep-mail: giving up on {(scow %uv i)} after {(a-co:co tries)} tries" ~)
    `state(flight (~(del by flight) i), dead (~(put by dead) i why))
  =/  pause=@dr  ?:(=(~s0 wait) retry-wait (add wait ~m2))
  :_  state(flight (~(del by flight) i), queue [[i tries again] queue])
  ~[[%pass /retry/(scot %uv i) %arvo %b %wait (add now.bowl pause)]]
::
++  give-up
  |=  [i=id:keep why=@t]
  ^-  (quip card _state)
  %-  (slog leaf+"keep-mail: {(trip why)}" ~)
  `state(flight (~(del by flight) i), dead (~(put by dead) i why))
::
++  tick
  |=  [i=id:keep round=@da wait=@dr]
  ^-  card
  [%pass /tick/(scot %uv i)/(scot %da round) %arvo %b %wait (add now.bowl wait)]
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
++  fetch
  |=  [=wire =request:http]
  ^-  card
  [%pass wire %arvo %i %request request *outbound-config:iris]
::
++  bearer
  |=  c=config:km
  ^-  header-list:http
  ~[['authorization' (cat 3 'Bearer ' key.c)]]
::
++  post-json
  |=  [=wire c=config:km url=@t jon=json]
  ^-  card
  %+  fetch  wire
  :*  %'POST'
      url
      [['content-type' 'application/json'] (bearer c)]
      `(as-octs:mimes:html (en:json:html jon))
  ==
::
::  no footer: the relay appends its own unsubscribe footer and RFC-8058
::  headers per recipient, and drops whoever has no consent record
++  send-post
  |=  [c=config:km i=id:keep round=@da again=? pay=[sub=@t txt=@t htm=@t] to=(list addr)]
  ^-  card
  %-  post-json
  :^    /send/(scot %uv i)/(scot %da round)
      c
    (send-url:kml relay.c)
  %-  pairs:enjs:format
  :~  ['patp' s+(scot %p our.bowl)]
      ['id' s+(scot %uv i)]
      ['again' b+again]
      ['to' a+(turn to |=(a=addr ^-(json s+a)))]
      ['subject' s+sub.pay]
      ['text' s+txt.pay]
      ['html' s+htm.pay]
  ==
::
++  sync
  |=  [c=config:km i=id:keep round=@da]
  ^-  card
  (fetch /sync/(scot %uv i)/(scot %da round) [%'GET' (readers-url:kml relay.c) (bearer c) ~])
::
++  poll-job
  |=  [c=config:km i=id:keep round=@da job=@t]
  ^-  card
  (fetch /poll/(scot %uv i)/(scot %da round) [%'GET' (job-url:kml relay.c job) (bearer c) ~])
::
::  the ship's own substack claim, a %yes first: the relay proves the same page
++  claim
  ^-  (unit [url=@t =proof:ks])
  ?.  .^(? %gu /(scot %p our.bowl)/keep-sync/(scot %da now.bowl)/$)  ~
  =/  urls=(list @t)
    ~(tap in .^((set @t) %gx /(scot %p our.bowl)/keep-sync/(scot %da now.bowl)/mine/noun))
  ?~  urls  ~
  =/  bs=(map claim:ks badge:ks)
    .^((map claim:ks badge:ks) %gx /(scot %p our.bowl)/keep-sync/(scot %da now.bowl)/badges/noun)
  =/  judged=(list [url=@t =proof:ks])
    %+  turn  urls
    |=  url=@t
    =/  b  (~(get by bs) [our.bowl url])
    [url ?~(b %wait proof.u.b)]
  =/  yes  (skim judged |=([* p=proof:ks] ?=(%yes p)))
  ?^  yes  `i.yes
  ?~  judged  ~
  `i.judged
::
::  what a look at the relay fetches: who confirmed, and our proof token
++  ask
  |=  c=config:km
  ^-  (list card)
  :~  (fetch /readers [%'GET' (readers-url:kml relay.c) (bearer c) ~])
      (fetch /proof [%'GET' (token-url:kml relay.c) (bearer c) ~])
  ==
::
++  tell-name
  |=  [c=config:km n=@t]
  ^-  card
  (post-json /profile c (profile-url:kml relay.c) (pairs:enjs:format ~[['name' s+n]]))
::
++  verify
  |=  [c=config:km url=@t]
  ^-  card
  (post-json /verify c (verify-url:kml relay.c) (pairs:enjs:format ~[['source_url' s+url]]))
::
::  the same file the sieve read, for the relay to re-confirm under its
::  own rules: substack's format, a proven source, one mail per address
++  hand-import
  |=  [c=config:km raw=@t src=@t]
  ^-  card
  (post-json /import c (import-url:kml relay.c) (pairs:enjs:format ~[['source_url' s+src] ['csv' s+raw]]))
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
