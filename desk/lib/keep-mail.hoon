::  keep-mail — sieving addresses, tokens, subjects. no bowl, no scry.
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
++  token
  |=  [a=addr:km salt=@uvH]
  ^-  @uvH
  (sham [a salt])
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
::  the relay ships with the desk; config carries a url only to override it
++  default-relay  'https://keep-posting.com/api/mail/send'
::
++  conf-defaults
  |=  c=config:km
  ^-  config:km
  =?  relay.c  =('' relay.c)  default-relay
  c(relay (clean-url relay.c), site (clean-url site.c))
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
--
