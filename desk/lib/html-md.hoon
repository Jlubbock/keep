::  html-md — a tame subset of html into markdown. images do not survive.
::
|%
++  convert
  |=  raw=@t
  ^-  (unit @t)
  =/  x=(unit manx)  (de-xml:html (clean raw))
  ?~  x  ~
  `(crip (render-blocks c.u.x))
::
::  de-xml is strict xml: close the void tags, feed it the named entities
::  it does not know, give the fragment one root
++  clean
  |=  raw=@t
  ^-  @t
  =/  t  (trip raw)
  =.  t  (close-voids t)
  =.  t  (subst "&nbsp;" " " t)
  =.  t  (subst "&mdash;" "—" t)
  =.  t  (subst "&ndash;" "–" t)
  =.  t  (subst "&hellip;" "…" t)
  =.  t  (subst "&lsquo;" "‘" t)
  =.  t  (subst "&rsquo;" "’" t)
  =.  t  (subst "&ldquo;" "“" t)
  =.  t  (subst "&rdquo;" "”" t)
  =.  t  (gap-fix t)
  (crip :(weld "<div>" t "</div>"))
::
::  html leaves its void elements open; xml will not have that
++  close-voids
  |=  t=tape
  ^-  tape
  |-  ^-  tape
  ?~  t  ~
  ?.  =('<' i.t)  [i.t $(t t.t)]
  ?.  (void-next `tape`t.t)  [i.t $(t t.t)]
  =/  [tag=tape rest=tape]  (take-tag `tape`t)
  (weld (close-one tag) $(t rest))
::
++  void-next
  |=  t=tape
  ^-  ?
  %+  lien
    ^-  (list tape)
    ~["img" "br" "hr" "source" "input" "embed" "wbr" "track" "area" "col"]
  |=  name=tape
  =/  n  (lent name)
  ?.  =(name (cass (scag n `tape`t)))  %.n
  =/  nxt  (slag n t)
  ?~  nxt  %.n
  ?|(=(' ' i.nxt) =('>' i.nxt) =('/' i.nxt) =(9 i.nxt) =(10 i.nxt))
::
::  the whole tag through its '>', honoring quotes around attribute values
++  take-tag
  |=  t=tape
  ^-  [tag=tape rest=tape]
  =|  acc=tape
  =|  q=@tD
  |-  ^-  [tag=tape rest=tape]
  ?~  t  [(flop acc) ~]
  ?:  &(=(0 q) =('>' i.t))
    [(flop [i.t acc]) `tape`t.t]
  =/  nq=@tD
    ?:  =(0 q)
      ?:(?|(=('"' i.t) =('\'' i.t)) i.t `@tD`0)
    ?:(=(q i.t) `@tD`0 q)
  ::  a raw angle inside a quoted value is fine html and fatal xml
  =/  nc=tape
    ?.  !=(0 q)  [i.t ~]
    ?:  =('>' i.t)  "&gt;"
    ?:  =('<' i.t)  "&lt;"
    [i.t ~]
  $(t t.t, acc (weld (flop nc) acc), q nq)
::
++  close-one
  |=  tag=tape
  ^-  tape
  =/  n  (lent tag)
  ?:  (lth n 2)  tag
  ?:  =('/' (snag (sub n 2) `tape`tag))  tag
  (weld (snip `tape`tag) " />")
::
::  de-xml drops a text node that is only whitespace, gluing the words of
::  adjacent inline elements; an entity forces the node to survive
++  gap-fix
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?.  =('>' i.t)  [i.t $(t t.t)]
  =/  [run=@ud rest=tape]  (eat-ws `tape`t.t)
  ?:  &((gth run 0) ?=([%'<' *] rest))
    (weld ">&#32;" $(t rest))
  [i.t $(t t.t)]
::
++  eat-ws
  |=  t=tape
  ^-  [@ud tape]
  =/  n=@ud  0
  |-  ^-  [@ud tape]
  ?~  t  [n ~]
  ?:  ?|(=(32 i.t) =(10 i.t) =(9 i.t) =(13 i.t))
    $(t t.t, n +(n))
  [n `tape`t]
::
++  subst
  |=  [find=tape put=tape t=tape]
  ^-  tape
  =/  n  (lent find)
  |-  ^-  tape
  ?~  t  ~
  ?:  =(find (scag n `tape`t))
    (weld put $(t (slag n `tape`t)))
  [i.t $(t t.t)]
::
::  ---- blocks ----------------------------------------------------------------
::
++  render-blocks
  |=  c=marl
  ^-  tape
  (join-blocks (murn c block))
::
++  block
  |=  x=manx
  ^-  (unit tape)
  ?:  ?=(%$ n.g.x)
    =/  t  (strip (escape (text-of x)))
    ?:((blank t) ~ `t)
  ?:  (dropped x)  ~
  ?+    n.g.x
    =/  r  (render-blocks c.x)
    ?:((blank r) ~ `r)
  ::
      %p
    =/  r  (strip (inline c.x))
    ?:((blank r) ~ `r)
  ::
      %h1  (hed 1 c.x)
      %h2  (hed 2 c.x)
      %h3  (hed 3 c.x)
      %h4  (hed 4 c.x)
      %h5  (hed 5 c.x)
      %h6  (hed 6 c.x)
  ::
      %ul
    =/  r  (render-list c.x "" ~)
    ?:((blank r) ~ `r)
  ::
      %ol
    =/  r  (render-list c.x "" `1)
    ?:((blank r) ~ `r)
  ::
      %blockquote
    =/  r  (render-blocks c.x)
    ?:((blank r) ~ `(prefix-lines "> " r))
  ::
      %pre
    `(fence (strip (raw-text c.x)))
  ::
      %hr
    `"---"
  ==
::
++  hed
  |=  [n=@ud c=marl]
  ^-  (unit tape)
  =/  r  (strip (inline c))
  ?:  (blank r)  ~
  `:(weld (trip (fil 3 n '#')) " " r)
::
++  render-list
  |=  [c=marl ind=tape num=(unit @ud)]
  ^-  tape
  =/  n=@ud  ?~(num 1 u.num)
  =|  out=(list tape)
  |-  ^-  tape
  ?~  c  (join-nl (flop out))
  ?.  ?=(%li n.g.i.c)  $(c t.c)
  =/  bullet=tape  ?~(num "- " (weld (scow %ud n) ". "))
  =/  body  (strip (inline (skip c.i.c list-kid)))
  =/  kids=(list tape)
    %+  murn  (skim c.i.c list-kid)
    |=  x=manx
    ^-  (unit tape)
    =/  r  (render-list c.x (weld "  " ind) ?:(?=(%ol n.g.x) `1 ~))
    ?:((blank r) ~ `r)
  =/  chunk  (join-nl [:(weld ind bullet body) kids])
  $(c t.c, n +(n), out [chunk out])
::
++  list-kid
  |=  x=manx
  ?=(?(%ul %ol) n.g.x)
::
::  ---- inline ----------------------------------------------------------------
::
++  inline
  |=  c=marl
  ^-  tape
  %-  zing
  %+  turn  c
  |=  x=manx
  ^-  tape
  ?:  ?=(%$ n.g.x)  (escape (text-of x))
  ?:  (dropped x)  ~
  ?+    n.g.x  (inline c.x)
      ?(%strong %b)
    =/  r  (inline c.x)
    ?:((blank r) ~ :(weld "**" r "**"))
  ::
      ?(%em %i)
    =/  r  (inline c.x)
    ?:((blank r) ~ :(weld "*" r "*"))
  ::
      ?(%s %del)
    =/  r  (inline c.x)
    ?:((blank r) ~ :(weld "~~" r "~~"))
  ::
      %code
    =/  r  (raw-text c.x)
    ?:((blank r) ~ :(weld "`" r "`"))
  ::
      %br  "\0a"
      %a   (link x)
  ==
::
++  link
  |=  x=manx
  ^-  tape
  =/  r  (inline c.x)
  ?:  (blank r)  ~
  ?~  u=(attr a.g.x %href)  r
  :(weld "[" r "](" u.u ")")
::
::  ---- the axe ---------------------------------------------------------------
::
++  dropped
  |=  x=manx
  ^-  ?
  ?:  ?=  $?  %img  %figure  %picture  %figcaption  %iframe  %audio
              %video  %svg  %source  %input  %style  %script  %form
              %button
          ==
        n.g.x
    %.y
  ?~  cl=(attr a.g.x %class)  %.n
  ?|  (has-in u.cl "button")
      (has-in u.cl "subscription-widget")
      (has-in u.cl "footnote-anchor")
      (has-in u.cl "image-link")
  ==
::
::  ---- small tools -----------------------------------------------------------
::
++  text-of
  |=  x=manx
  ^-  tape
  ?~  a.g.x  ~
  v.i.a.g.x
::
++  raw-text
  |=  c=marl
  ^-  tape
  %-  zing
  %+  turn  c
  |=  x=manx
  ^-  tape
  ?:  ?=(%$ n.g.x)  (text-of x)
  ?:  ?=(%br n.g.x)  "\0a"
  (raw-text c.x)
::
++  attr
  |=  [a=mart nom=mane]
  ^-  (unit tape)
  ?~  a  ~
  ?:  =(nom n.i.a)  `v.i.a
  $(a t.a)
::
++  has-in
  |=  [hay=tape pin=tape]
  ^-  ?
  =/  n  (lent pin)
  |-  ^-  ?
  ?:  =(pin (scag n hay))  %.y
  ?~  hay  %.n
  $(hay t.hay)
::
++  blank
  |=  t=tape
  ^-  ?
  ?~  t  %.y
  ?:((gth i.t 32) %.n $(t t.t))
::
++  lstrip
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?:((lte i.t 32) $(t t.t) t)
::
++  strip
  |=  t=tape
  ^-  tape
  (flop (lstrip (flop (lstrip t))))
::
++  escape
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?:  ?|  =('*' i.t)  =('_' i.t)  =('`' i.t)
          =('[' i.t)  =(']' i.t)  =('\\' i.t)
      ==
    :(weld "\\" [i.t ~] $(t t.t))
  [i.t $(t t.t)]
::
++  prefix-lines
  |=  [p=tape t=tape]
  ^-  tape
  %+  weld  p
  |-  ^-  tape
  ?~  t  ~
  ?.  =(10 i.t)  [i.t $(t t.t)]
  [i.t (weld p $(t t.t))]
::
++  fence
  |=  t=tape
  ^-  tape
  :(weld "```\0a" t "\0a```")
::
++  join-blocks
  |=  bs=(list tape)
  ^-  tape
  ?~  bs  ~
  ?~  t.bs  i.bs
  :(weld i.bs "\0a\0a" $(bs t.bs))
::
++  join-nl
  |=  ls=(list tape)
  ^-  tape
  ?~  ls  ~
  ?~  t.ls  i.ls
  :(weld i.ls "\0a" $(ls t.ls))
--
