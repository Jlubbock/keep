::  keep-mail — sieving addresses, subjects, the relay's urls and answers.
::  no bowl, no scry.
::
/-  km=keep-mail
|%
++  lower
  |=  t=tape
  ^-  tape
  %+  turn  t
  |=(c=@tD ?:(&((gte c 'A') (lte c 'Z')) (add c 32) c))
::
++  strip
  |=  t=tape
  ^-  tape
  (flop (lead (flop (lead t))))
::
++  lead
  |=  t=tape
  ^-  tape
  |-
  ?~  t  ~
  ?.  |(=(' ' i.t) =('\09' i.t) =('\0d' i.t))  t
  $(t t.t)
::
++  to-lines
  |=  t=tape
  ^-  (list tape)
  =|  cur=tape                           ::  reversed
  |-  ^-  (list tape)
  ?~  t  [(flop cur) ~]
  ?:  =('\0a' i.t)  [(flop cur) $(t t.t, cur ~)]
  $(t t.t, cur [i.t cur])
::
++  cells-of
  |=  l=tape
  ^-  (list tape)
  =|  cur=tape                           ::  reversed
  |-  ^-  (list tape)
  ?~  l  [(flop cur) ~]
  ?:  =(',' i.l)  [(flop cur) $(l t.l, cur ~)]
  $(l t.l, cur [i.l cur])
::
++  clean-cell
  |=  c=tape
  ^-  tape
  =.  c  (strip c)
  =.  c
    ?.  ?&  ?=(^ c)
            =('"' i.c)
            (gte (lent c) 2)
            =('"' (rear c))
        ==
      c
    (snip `tape`t.c)
  (lower (strip c))
::
::  one @ with something before it, a dot after it, no spaces.
::  the relay revalidates anyway.
++  valid
  |=  t=tape
  ^-  ?
  ?^  (find " " t)  %.n
  =/  i  (find "@" t)
  ?~  i  %.n
  ?:  =(0 u.i)  %.n
  =/  dom=tape  (slag +(u.i) t)
  ?^  (find "@" dom)  %.n
  ?=(^ (find "." dom))
::
::  a substack csv, a bare list, or a comma-separated paste: per line, keep
::  every cell that reads as an address. dropped counts lines holding none —
::  except blanks and the header, which name no reader
++  sieve
  |=  raw=@t
  ^-  [good=(list addr:km) dropped=@ud]
  =/  ls=(list tape)  (to-lines (trip raw))
  =|  seen=(set addr:km)
  =|  good=(list addr:km)                ::  reversed
  =|  dropped=@ud
  |-  ^-  [(list addr:km) @ud]
  ?~  ls  [(flop good) dropped]
  =/  cells=(list tape)  (turn (cells-of i.ls) clean-cell)
  =/  hits=(list addr:km)
    (murn cells |=(c=tape ?.((valid c) ~ `(crip c))))
  ?~  hits
    =/  blank=?   (levy cells |=(c=tape =(~ c)))
    =/  header=?  ?&(?=(^ cells) =("email" i.cells))
    $(ls t.ls, dropped ?:(|(blank header) dropped +(dropped)))
  =/  [g=(list addr:km) s=(set addr:km)]
    =/  hs=(list addr:km)  hits
    =/  g=(list addr:km)   good
    =/  s=(set addr:km)    seen
    |-  ^-  [(list addr:km) (set addr:km)]
    ?~  hs  [g s]
    ?:  (~(has in s) i.hs)  $(hs t.hs)
    $(hs t.hs, g [i.hs g], s (~(put in s) i.hs))
  $(ls t.ls, good g, seen s)
::
++  subject
  |=  [title=(unit @t) md=@t]
  ^-  @t
  ?^  title  u.title
  =/  ls  (to-lines (trip md))
  |-  ^-  @t
  ?~  ls  'a new post'
  =/  s=tape  (strip i.ls)
  =/  bare=tape
    (strip |-(?:(&(?=(^ s) =('#' i.s)) $(s t.s) s)))
  ?~  bare  $(ls t.ls)
  ?.  (gth (lent bare) 78)  (crip bare)
  (crip (weld (scag 75 `tape`bare) "..."))
::
::  ---- the relay ------------------------------------------------------------
::
::  the relay ships with the desk; config carries a url only to override it
++  default-relay  'https://keep-posting.com'
::
++  conf-defaults
  |=  c=config:km
  ^-  config:km
  =?  relay.c  =('' relay.c)  default-relay
  c(relay (clean-url relay.c))
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
::  a config saved when relay meant the send endpoint itself
++  base-of
  |=  url=@t
  ^-  @t
  =/  t  (trip url)
  =/  suf  "/api/mail/send"
  =/  n  (lent suf)
  ?.  (gte (lent t) n)  url
  ?.  =(suf (slag (sub (lent t) n) t))  url
  (crip (scag (sub (lent t) n) t))
::
++  send-url       |=(base=@t ^-(@t (cat 3 base '/api/mail/send')))
++  readers-url    |=(base=@t ^-(@t (cat 3 base '/api/mail/readers')))
++  token-url      |=(base=@t ^-(@t (cat 3 base '/api/mail/import/token')))
++  verify-url     |=(base=@t ^-(@t (cat 3 base '/api/mail/import/verify')))
++  import-url     |=(base=@t ^-(@t (cat 3 base '/api/mail/import')))
++  profile-url    |=(base=@t ^-(@t (cat 3 base '/api/mail/profile')))
++  job-url        |=([base=@t job=@t] ^-(@t (rap 3 base '/api/mail/jobs/' job ~)))
++  subscribe-url  |=([base=@t our=@p] ^-(@t (rap 3 base '/subscribe/' (scot %p our) ~)))
::
++  obj
  |=  body=@t
  ^-  (unit (map @t json))
  ?~  jon=(de:json:html body)  ~
  ?.  ?=([%o *] u.jon)  ~
  `p.u.jon
::
++  num
  |=  [m=(map @t json) k=@t]
  ^-  @ud
  ?~  v=(~(get by m) k)  0
  ?.  ?=([%n *] u.v)  0
  (fall (rush p.u.v dem) 0)
::
++  str
  |=  [m=(map @t json) k=@t]
  ^-  (unit @t)
  ?~  v=(~(get by m) k)  ~
  ?.  ?=([%s *] u.v)  ~
  `p.u.v
::
::  a list of addresses, given bare or as {"to": ...} objects
++  addrs
  |=  [m=(map @t json) k=@t]
  ^-  (list addr:km)
  ?~  arr=(~(get by m) k)  ~
  ?.  ?=([%a *] u.arr)  ~
  %+  murn  p.u.arr
  |=  j=json
  ^-  (unit addr:km)
  ?:  ?=([%s *] j)  `p.j
  ?.  ?=([%o *] j)  ~
  ?~  t=(~(get by p.j) 'to')  ~
  ?.  ?=([%s *] u.t)  ~
  `p.u.t
::
::  what the relay says of a request that did not go through
++  detail-of
  |=  body=@t
  ^-  @t
  ?~  m=(obj body)  body
  (fall (str u.m 'detail') body)
::
::  the 202 a send gets: the job to poll, who it reaches, who to prune,
::  who is still waiting on a confirmation
++  job-of
  |=  body=@t
  ^-  (unit [job=@t recipients=@ud dropped=(list addr:km) unconfirmed=(list addr:km)])
  ?~  m=(obj body)  ~
  ?~  j=(str u.m 'job')  ~
  `[u.j (num u.m 'recipients') (addrs u.m 'dropped') (addrs u.m 'unconfirmed')]
::
::  what a job poll says
++  job-state
  |=  body=@t
  ^-  (unit [status=@t sent=@ud failed=@ud queued=@ud error=(unit @t)])
  ?~  m=(obj body)  ~
  ?~  s=(str u.m 'status')  ~
  `[u.s (num u.m 'sent') (num u.m 'failed') (num u.m 'queued') (str u.m 'error')]
::
::  the relay's confirmed readers for this writer
++  readers-of
  |=  body=@t
  ^-  (unit [active=(list addr:km) pending=@ud])
  ?~  m=(obj body)  ~
  ?.  (~(has by u.m) 'active')  ~
  `[(addrs u.m 'active') (num u.m 'pending')]
::
++  proof-of
  |=  body=@t
  ^-  (unit proof:km)
  ?~  m=(obj body)  ~
  ?~  t=(str u.m 'token')  ~
  `[u.t (str u.m 'verified_url')]
::
::  an accepted import: how many the relay will ask
++  import-of
  |=  body=@t
  ^-  (unit @ud)
  ?~  m=(obj body)  ~
  ?.  (~(has by u.m) 'pending')  ~
  `(num u.m 'pending')
::
::  the relay's refusals, as a sentence a writer can act on
++  why-of
  |=  [code=@ud body=@t]
  ^-  @t
  =/  d=@t  (detail-of body)
  ?:  =(401 code)  'Keep doesn\'t recognize this ship\'s email key — nothing went out'
  ?:  ?=(^ (find "suspend" (trip d)))
    'Keep paused your sending for review — nothing went out'
  ?:  ?=(^ (find "no writer" (trip d)))
    'This ship isn\'t attached to a Keep account — nothing went out'
  ?:  =(0 code)  d
  (crip "Keep answered {(a-co:co code)}: {(trip d)}")
--
