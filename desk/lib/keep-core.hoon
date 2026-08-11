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
++  item-spur  |=(=id:keep ^-(path /item/[(scot %uv id)]))
++  talk-spur  |=(art=id:keep ^-(path /talk/[(scot %uv art)]))
::
++  member-spur
  |=  [=lyst:keep salt=@uvH who=ship]
  ^-  path
  ?:  =(%public lyst)  /index
  /list/[(scot %uv (shas salt (jam [lyst who])))]
::
::  never bunt a salt: a zero salt makes every member address derivable
++  mint  |=([eny=@uvJ =lyst:keep] ^-(@uvH (sham (mix eny (jam lyst)))))
::
++  last-of
  |=  p=path
  ^-  @ta
  ?~  p  ''
  ?~  t.p  i.p
  $(p t.p)
::
++  has-entry
  |=  [es=(list entry:keep) e=entry:keep]
  ^-  ?
  ?~  es  %.n
  ?:  =(i.es e)  %.y
  $(es t.es)
::
++  drop-entry
  |=  [es=(list entry:keep) e=entry:keep]
  ^-  (list entry:keep)
  ?~  es  ~
  ?:  =(i.es e)  $(es t.es)
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
