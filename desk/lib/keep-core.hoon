::  address derivation and ordering. no bowl, no state, no scry.
::
/-  keep
/+  ui=keep-ui
|%
::  gall numbers the first %grow at a path 1; revision 0 is unbound
++  first  1
::
++  base-of
  |=  [dap=@tas rev=@ud]
  ^-  path
  ::  welp not weld: weld homogenizes on its first element
  ::  (scot %ud 1) not %1: %1 is the atom 1, an 0x01 byte in the path
  ~[%g %x (scot %ud rev) dap %$ (scot %ud 1)]
::
++  base  |=(rev=@ud (base-of %keep rev))
::
::  a browser names its origin (or at least a referer) on every form POST,
::  and a cross-site one names the wrong host. neither header is not a browser
++  same-origin
  |=  hs=header-list:http
  ^-  ?
  =/  from=(unit @t)
    ?^  o=(get-header:http 'origin' hs)  o
    (get-header:http 'referer' hs)
  ?~  from  %.y
  ?~  host=(get-header:http 'host' hs)  %.n
  =((cass (trip u.host)) (cass (trip (host-of u.from))))
::
++  host-of
  |=  url=@t
  ^-  @t
  =/  t  (trip url)
  =/  s=tape
    ?:  =("https://" (scag 8 t))  (slag 8 t)
    ?:  =("http://" (scag 7 t))  (slag 7 t)
    t
  =/  i  (find "/" s)
  (crip ?~(i s (scag u.i s)))
::
++  item-spur  |=(=id:keep ^-(path /item/[(scot %uv id)]))
++  talk-spur  |=(art=id:keep ^-(path /talk/[(scot %uv art)]))
++  talk-at-spur  |=(art=id:keep ^-(path /talk-at/[(scot %uv art)]))
::
::  a gated list is a coop: gall serves everything under it encrypted, and
::  asks on-peek per request whether the reader is a member
++  coop  |=(=lyst:keep ^-(path /list/[lyst]))
::
::  the install nonce keeps every address fresh across a nuke: gall never
::  serves a revision number twice, so a reinstalled agent starts elsewhere
++  feed-spur
  |=  [=lyst:keep nonce=@uv]
  ^-  path
  =/  tail=path  /[(scot %uv nonce)]/index
  ?:(=(%public lyst) tail (welp (coop lyst) tail))
::
++  index-kind  |=(p=path ^-(? |(?=([%index ~] p) ?=([@ %index ~] p))))
::
::  two addresses from one writer for the same thing: its index, or one of
::  its lists. an old per-member address names no list, so it matches any
++  same-kind
  |=  [a=path b=path]
  ^-  ?
  ?:  &((index-kind a) (index-kind b))  %.y
  ?:  &((old-member a) (gated b))  %.y
  =/  la  (list-of a)
  =/  lb  (list-of b)
  &(?=(^ la) ?=(^ lb) =(u.la u.lb))
::
++  post-spur
  |=  [=lyst:keep =id:keep]
  ^-  path
  ?:(=(%public lyst) (item-spur id) (welp (coop lyst) (item-spur id)))
::
++  gated  |=(p=path ^-(? ?=(^ (find /list p))))
::
::  the list a coop address is under: what a reader was handed the post as
++  list-of
  |=  p=path
  ^-  (unit @tas)
  ?~  p  ~
  ?~  t.p  ~
  ?:  =(%list i.p)  (slaw %tas i.t.p)
  $(p t.p)
::
::  the per-member address lists had before coops; only a migration meets one
++  old-member  |=(p=path ^-(? ?=([%list @ ~] p)))
::
++  last-of
  |=  p=path
  ^-  @ta
  ?~  p  ''
  ?~  t.p  i.p
  $(p t.p)
::
++  id-of  |=(p=path ^-((unit id:keep) (slaw %uv (last-of p))))
::
++  has-id
  |=  [es=(list entry:keep) =id:keep]
  ^-  ?
  ?~  es  %.n
  ?:  =(`id (id-of path.i.es))  %.y
  $(es t.es)
::
++  drop-id
  |=  [es=(list entry:keep) =id:keep]
  ^-  (list entry:keep)
  ?~  es  ~
  ?:  =(`id (id-of path.i.es))  $(es t.es)
  [i.es $(es t.es)]
::
::  ---- commenting tiers -------------------------------------------------------
::
::  czar outranks pawn: a tier admits its own rank and everything above it
++  grade
  |=  r=rank:title
  ^-  @ud
  ?-  r
    %czar  0
    %king  1
    %duke  2
    %earl  3
    %pawn  4
  ==
::
++  may-tier
  |=  [min=rank:title who=ship]
  ^-  ?
  (lte (grade (clan:title who)) (grade min))
::
::  ---- clearnet --------------------------------------------------------------
::
++  reserved
  ^-  (set @t)
  %-  sy
  :~  '/keep/index'  '/keep/write'  '/keep/lists'  '/keep/read'
      '/keep/ship'   '/keep/comments'  '/keep/style.css'  '/keep/app.js'
      '/keep/linkmap'
  ==
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
  |=  [taken=(map @t id:keep) tit=(unit @t)]
  ^-  @t
  =/  stem=tape  (trip ?~(tit 'untitled' (slugify u.tit)))
  =|  n=@ud
  |-  ^-  @t
  =/  try=@t
    ?:  =(0 n)  (crip "/keep/{stem}")
    (crip "/keep/{stem}-{(a-co:co n)}")
  ?.  |((~(has by taken) try) (~(has in reserved) try))  try
  $(n +(n))
::
::  ---- ordering --------------------------------------------------------------
::
++  stamp
  |=  r=row:ui
  ^-  @da
  ?~  hed.r  *@da
  wen.u.hed.r
::
++  insert-row
  |=  [rs=(list row:ui) r=row:ui]
  ^-  (list row:ui)
  ?~  rs  ~[r]
  ?:  (gth (stamp r) (stamp i.rs))  [r rs]
  [i.rs $(rs t.rs)]
::
++  by-date
  |=  rs=(list row:ui)
  ^-  (list row:ui)
  =|  out=(list row:ui)
  |-  ^-  (list row:ui)
  ?~  rs  out
  $(rs t.rs, out (insert-row out i.rs))
--
