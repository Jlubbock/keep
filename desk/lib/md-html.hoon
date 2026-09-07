::  md-html — the tame subset of markdown into html, for mail bodies.
::
::    the web ui renders markdown in the browser; a mail body has no
::    browser on our side, so this walks lib/html-md's subset backwards.
::    it cannot fail: a line that matches nothing is a paragraph.
::
|%
++  convert
  |=  md=@t
  ^-  @t
  (crip (blocks (to-lines (trip md))))
::
::  ---- lines -----------------------------------------------------------------
::
++  to-lines
  |=  t=tape
  ^-  (list tape)
  =|  cur=tape                           ::  reversed
  |-  ^-  (list tape)
  ?~  t  [(flop cur) ~]
  ?:  =('\0a' i.t)  [(flop cur) $(t t.t, cur ~)]
  ?:  =('\0d' i.t)  $(t t.t)
  $(t t.t, cur [i.t cur])
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
  ?.  |(=(' ' i.t) =('\09' i.t))  t
  $(t t.t)
::
++  prefix
  |=  [p=tape t=tape]
  ^-  ?
  =(p (scag (lent p) t))
::
++  all-of
  |=  [c=@tD t=tape]
  ^-  ?
  ?:  (lth (lent t) 3)  %.n
  (levy t |=(x=@tD =(c x)))
::
::  ---- blocks ----------------------------------------------------------------
::
++  quoted    |=(t=tape ^-(? ?&(?=(^ t) =('>' i.t))))
++  bullety   |=(t=tape ^-(? |((prefix "- " t) (prefix "* " t))))
++  numbery   |=(t=tape ^-(? ?=(^ (after-digits t))))
::
++  after-digits
  |=  t=tape
  ^-  (unit tape)                        ::  what follows "1. ", if it led
  =/  n=@ud  0
  |-
  ?:  ?&(?=(^ t) (gte i.t '0') (lte i.t '9'))
    $(t t.t, n +(n))
  ?.  ?&((gth n 0) (prefix ". " t))  ~
  `(slag 2 `tape`t)
::
++  dequote
  |=  t=tape
  ^-  tape
  ?.  ?&(?=(^ t) =('>' i.t))  t
  ?:  (prefix "> " t)  (slag 2 `tape`t)
  (slag 1 `tape`t)
::
++  structural
  |=  s=tape
  ^-  ?
  ?|  =(~ s)
      (prefix "```" s)
      (prefix "# " s)
      (prefix "## " s)
      (prefix "### " s)
      (quoted s)
      (bullety s)
      (numbery s)
      (all-of '-' s)
      (all-of '*' s)
  ==
::
++  gather
  |=  [ls=(list tape) f=$-(tape ?)]
  ^-  [hits=(list tape) rest=(list tape)]
  ?~  ls  [~ ~]
  ?.  (f (strip i.ls))  [~ ls]
  =/  more  $(ls t.ls)
  [[(strip i.ls) hits.more] rest.more]
::
++  take-fence
  |=  ls=(list tape)
  ^-  [code=tape rest=(list tape)]
  =|  acc=tape
  |-  ^-  [code=tape rest=(list tape)]
  ?~  ls  [acc ~]
  ?:  (prefix "```" (strip i.ls))  [acc t.ls]
  $(ls t.ls, acc :(weld acc (escape i.ls) "\0a"))
::
++  join-sp
  |=  ls=(list tape)
  ^-  tape
  ?~  ls  ~
  ?~  t.ls  i.ls
  :(weld i.ls " " $(ls t.ls))
::
::  blank quote lines split the quote into paragraphs
++  paras-of
  |=  ls=(list tape)
  ^-  tape
  =|  cur=(list tape)                    ::  reversed
  |-  ^-  tape
  ?~  ls
    ?~  cur  ~
    :(weld "<p>" (inline (join-sp (flop cur))) "</p>")
  ?~  (strip i.ls)
    ?~  cur  $(ls t.ls)
    :(weld "<p>" (inline (join-sp (flop cur))) "</p>" $(ls t.ls, cur ~))
  $(ls t.ls, cur [(strip i.ls) cur])
::
++  items-of
  |=  ls=(list tape)
  ^-  tape
  ?~  ls  ~
  :(weld "<li>" (inline i.ls) "</li>" $(ls t.ls))
::
++  blocks
  |=  ls=(list tape)
  ^-  tape
  |-  ^-  tape
  ?~  ls  ~
  =/  s=tape  (strip i.ls)
  ?:  =(~ s)  $(ls t.ls)
  ?:  (prefix "```" s)
    =/  f  (take-fence t.ls)
    :(weld "<pre><code>" code.f "</code></pre>\0a" $(ls rest.f))
  ?:  (prefix "### " s)
    :(weld "<h3>" (inline (slag 4 s)) "</h3>\0a" $(ls t.ls))
  ?:  (prefix "## " s)
    :(weld "<h2>" (inline (slag 3 s)) "</h2>\0a" $(ls t.ls))
  ?:  (prefix "# " s)
    :(weld "<h1>" (inline (slag 2 s)) "</h1>\0a" $(ls t.ls))
  ?:  |((all-of '-' s) (all-of '*' s))
    (weld "<hr/>\0a" $(ls t.ls))
  ?:  (quoted s)
    =/  g  (gather ls quoted)
    %+  weld
      :(weld "<blockquote>" (paras-of (turn hits.g dequote)) "</blockquote>\0a")
    $(ls rest.g)
  ?:  (bullety s)
    =/  g  (gather ls bullety)
    %+  weld
      :(weld "<ul>" (items-of (turn hits.g |=(t=tape (slag 2 t)))) "</ul>\0a")
    $(ls rest.g)
  ?:  (numbery s)
    =/  g  (gather ls numbery)
    %+  weld
      :(weld "<ol>" (items-of (turn hits.g |=(t=tape (need (after-digits t))))) "</ol>\0a")
    $(ls rest.g)
  =/  g  (gather ls |=(t=tape !(structural t)))
  %+  weld
    :(weld "<p>" (inline (join-sp hits.g)) "</p>\0a")
  $(ls rest.g)
::
::  ---- inline ----------------------------------------------------------------
::
++  inline  |=(t=tape ^-(tape (marks (escape t))))
::
++  escape
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?:  =('&' i.t)  (weld "&amp;" $(t t.t))
  ?:  =('<' i.t)  (weld "&lt;" $(t t.t))
  ?:  =('>' i.t)  (weld "&gt;" $(t t.t))
  ?:  =('"' i.t)  (weld "&quot;" $(t t.t))
  [i.t $(t t.t)]
::
++  cut-on
  |=  [sep=tape t=tape]
  ^-  (unit [pre=tape post=tape])
  =/  i  (find sep t)
  ?~  i  ~
  `[(scag u.i t) (slag (add u.i (lent sep)) t)]
::
++  take-link
  |=  t=tape                             ::  starting at '['
  ^-  (unit [txt=tape url=tape rest=tape])
  ?~  t  ~
  ?~  c=(cut-on "](" t.t)  ~
  ?~  d=(cut-on ")" post.u.c)  ~
  `[pre.u.c pre.u.d post.u.d]
::
++  marks
  |=  t=tape
  ^-  tape
  ?~  t  ~
  ?:  =('`' i.t)
    ?~  c=(cut-on "`" t.t)  [i.t $(t t.t)]
    :(weld "<code>" pre.u.c "</code>" $(t post.u.c))
  ?:  (prefix "**" t)
    ?~  c=(cut-on "**" (slag 2 `tape`t))  [i.t $(t t.t)]
    :(weld "<strong>" (marks pre.u.c) "</strong>" $(t post.u.c))
  ?:  =('*' i.t)
    ?~  c=(cut-on "*" t.t)  [i.t $(t t.t)]
    :(weld "<em>" (marks pre.u.c) "</em>" $(t post.u.c))
  ?:  =('_' i.t)
    ?~  c=(cut-on "_" t.t)  [i.t $(t t.t)]
    :(weld "<em>" (marks pre.u.c) "</em>" $(t post.u.c))
  ?:  (prefix "![" t)
    ::  images do not survive; their alt text does
    ?~  l=(take-link (slag 1 `tape`t))  [i.t $(t t.t)]
    (weld (marks txt.u.l) $(t rest.u.l))
  ?:  =('[' i.t)
    ?~  l=(take-link t)  [i.t $(t t.t)]
    :(weld "<a href=\"" url.u.l "\">" (marks txt.u.l) "</a>" $(t rest.u.l))
  [i.t $(t t.t)]
--
