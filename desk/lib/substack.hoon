::  substack — the json a publication serves, reshaped for %keep-sync.
::
::    two unauthenticated endpoints:
::      /api/v1/archive?sort=new&offset=N&limit=M   metadata, no bodies
::      /api/v1/posts/[slug]                        body_html: whole when
::                                                  audience is 'everyone',
::                                                  a teaser otherwise
::    and one page: /about, whose text an owner can put their @p in
::
/-  ks=keep-sync
/+  hm=html-md
|%
++  field
  |=  [j=json k=@t]
  ^-  (unit json)
  ?.  ?=([%o *] j)  ~
  (~(get by p.j) k)
::
++  str
  |=  ju=(unit json)
  ^-  (unit @t)
  ?~  ju  ~
  ?.  ?=([%s *] u.ju)  ~
  `p.u.ju
::
::  the archive, newest first, entries it cannot read left out
++  arch
  |=  j=json
  ^-  (list [slug=@t wen=@da aud=@t])
  ?.  ?=([%a *] j)  ~
  %+  murn  p.j
  |=  i=json
  ^-  (unit [slug=@t wen=@da aud=@t])
  =/  slug  (str (field i 'slug'))
  =/  wen   (biff (str (field i 'post_date')) iso-da)
  ?~  slug  ~
  ?~  wen   ~
  `[u.slug u.wen (fall (str (field i 'audience')) 'everyone')]
::
++  post-md
  |=  j=json
  ^-  (unit post:ks)
  =/  slug  (str (field j 'slug'))
  =/  wen   (biff (str (field j 'post_date')) iso-da)
  ?~  slug  ~
  ?~  wen   ~
  =/  title=@t  (fall (str (field j 'title')) u.slug)
  =/  canon=@t  (fall (str (field j 'canonical_url')) '')
  =/  aud=@t    (fall (str (field j 'audience')) 'everyone')
  =/  raw=@t    (fall (str (field j 'body_html')) '')
  =/  body=(unit @t)
    ?:  =('' raw)  ~
    =/  conv  (convert:hm raw)
    ?~  conv  ~
    ?:(=('' u.conv) ~ conv)
  =/  pointer=@t
    ?:  =('' canon)  ''
    (rap 3 '[Read the full post](' canon ')' ~)
  ::  a post that will not render still lands, as a pointer to itself
  =/  md=@t
    ?~  body  pointer
    ?:  =('everyone' aud)  u.body
    ?:  =('' pointer)  u.body
    (rap 3 u.body '\0a\0a' pointer ~)
  ?:  =('' md)  ~
  `[u.slug u.wen title md]
::
::  the @p as a whole word: ~dev must not match ~devrem or ~dev-moon
++  mentions
  |=  [who=ship text=@t]
  ^-  ?
  =/  pat=tape  (scow %p who)
  =/  t=tape    (trip text)
  |-  ^-  ?
  ?~  at=(find pat t)  %.n
  =/  rest=tape  (slag (add u.at (lent pat)) t)
  ?~  rest  %.y
  ?.  ?|  &((gte i.rest 'a') (lte i.rest 'z'))
          =('-' i.rest)
      ==
    %.y
  $(t rest)
::
::  substack dates: 2026-08-27T17:59:17.583Z. fractions dropped — both
::  sides of every gth/gte in the agent are truncated the same way
++  iso-da
  |=  t=@t
  ^-  (unit @da)
  =/  d4  (bass 10 (stun [4 4] dit))
  =/  d2  (bass 10 (stun [2 2] dit))
  =/  res
    %+  rust  (trip t)
    ;~  plug
      d4
      ;~(pfix hep d2)
      ;~(pfix hep d2)
      ;~(pfix (jest 'T') d2)
      ;~(pfix col d2)
      ;~(pfix col d2)
      ;~(sfix (punt ;~(pfix dot (plus dit))) (jest 'Z'))
    ==
  ?~  res  ~
  =/  [y=@ud mo=@ud dd=@ud hh=@ud mi=@ud ss=@ud fs=*]  u.res
  ?.  ?&  (gte mo 1)   (lte mo 12)
          (gte dd 1)   (lte dd 31)
          (lte hh 23)  (lte mi 59)  (lte ss 60)
      ==
    ~
  `(year [[%.y y] mo [dd hh mi ss ~]])
--
