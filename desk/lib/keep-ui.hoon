/-  keep
::
|%
::
+$  row
  $:  via=ship
      =entry:keep
      hed=(unit head:keep)
      kept=?                             ::  have we syndicated it
      pub=?                              ::  did it reach us publicly
      site=(unit @t)                     ::  its url on the open web, if ours
      okay=(unit verdict:keep)
      re=(unit @t)                       ::  the quoted title, once we hold the body
      ::  a list name is a capability hint — empty on every clearnet row
      on=(list lyst:keep)                ::  where we fanned it, ours only
  ==
::
::  a body parsed for rendering: one %body leaf per prose layer, one %quote
::  per hosted response layer, each layer judged on its own signature
+$  bloc
  $%  [%body =page]
      [%quote hed=head:keep okay=verdict:keep quoted=bloc after=bloc]
  ==
::
+$  view
  $:  our=ship
      now=@da
      pals=(list ship)
      subs=(set ship)                    ::  whose index we tail: mechanical
      follows=(set ship)                 ::  who we follow: the feed
      off=(set ship)                     ::  confirmed not running %keep
      rolls=(list [=lyst:keep members=(set ship)])
      pending=(list [=feed:keep =lyst:keep])
  ==
--
::
|_  v=view
::  ---- bits ----------------------------------------------------------------
::
++  last                                 ::  the id at the end of an entry
  |=  p=path
  ^-  @ta
  ?~  p  ''
  ?~  t.p  i.p
  $(p t.p)
::
++  day
  |=  wen=@da
  ^-  tape
  =/  d  (yore wen)
  "~{(a-co:co y.d)}.{(a-co:co m.d)}.{(a-co:co d.t.d)}"
::
++  pp  |=(who=ship ^-(tape (scow %p who)))
++  id-of  |=(e=entry:keep ^-(tape (trip (last path.e))))
::
++  author
  |=  r=row
  ^-  ship
  ?~(hed.r ship.entry.r who.u.hed.r)
::
::  id first, ship last: eyre splits the LAST segment on its final dot to
::  make pork's ext, and a @uv id is full of dots
++  read-url
  |=  e=entry:keep
  ^-  tape
  "/keep/read/{(id-of e)}/{(pp ship.e)}"
::
++  titled
  |=  hed=(unit head:keep)
  ^-  tape
  ?~  hed  "—"
  ?~  title.u.hed  "untitled"
  (trip u.title.u.hed)
::
::  a quoted article's address falls out of its head — no pointer is stored
++  orig-entry
  |=  hed=head:keep
  ^-  entry:keep
  =/  =id:keep
    (sain:keep who.hed lyfe.hed wen.hed terms.hed title.hed hash.hed)
  [who.hed /item/[(scot %uv id)]]
::
++  aud-name
  |=  l=lyst:keep
  ^-  tape
  ?:(=(%public l) "everyone" (trip l))
::
++  dotted
  |=  ls=(list tape)
  ^-  tape
  ?~  ls  ""
  ?~  t.ls  i.ls
  "{i.ls} · {$(ls t.ls)}"
::
++  on-tag
  |=  [r=row pre=tape]
  ^-  (list manx)
  ?~  on.r  ~
  :_  ~
  ;span.k-on: {pre}{(dotted (turn on.r aud-name))}
::
++  nowt  ;/("")                         ::  an element that must not self-close
::
++  hidden
  |=  [name=tape val=tape]
  ^-  manx
  ;input(type "hidden", name "{name}", value "{val}");
::
::  ---- shell ---------------------------------------------------------------
::
++  shell
  |=  [nav=@tas main=manx]
  ^-  manx
  =/  cls=tape  ?:(=(%read nav) "k-shell k-reading" "k-shell")
  ;html
    ;head
      ;title: keep
      ;meta(charset "utf-8");
      ;meta(name "viewport", content "width=device-width, initial-scale=1");
      ;link(rel "preconnect", href "https://fonts.googleapis.com");
      ;link(rel "stylesheet", href "https://fonts.googleapis.com/css2?family=Spectral:ital,wght@0,300;0,400;0,500;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap");
      ;link(rel "stylesheet", href "/keep/style.css");
      ;script(src "/keep/app.js", defer "")
        ;+  nowt
      ==
    ==
    ;body
      ;div(class "{cls}")
        ;+  (side nav)
        ;main.k-main
          ;+  main
        ==
      ==
    ==
  ==
::
++  side
  |=  nav=@tas
  ^-  manx
  =/  sel  |=(a=@tas ^-(tape ?:(=(a nav) "on" "")))
  ;nav.k-side
    ;div.k-mark: keep
    ;div.k-nav
      ;a(href "/keep", class "{(sel %feed)}"): feed
      ;a(href "/keep/ship/{(pp our.v)}", class "mono {(sel %mine)}"): {(pp our.v)}
      ;a(href "/keep/write", class "{(sel %write)}"): write
      ;a(href "/keep/lists", class "{(sel %lists)}"): lists
    ==
    ;div.k-pals
      ;form(method "post", action "/keep", class "k-one k-find-form")
        ;+  (hidden "what" "go")
        ;+  (hidden "back" "/keep")
        ;input(type "text", name "who", class "k-find", placeholder "~sampel-palnet", autocomplete "off");
      ==
      ;div.k-pals-label: pals
      ;*  %+  turn  pals.v
          |=  who=ship
          ;a(href "/keep/ship/{(pp who)}"): {(pp who)}
    ==
    ;div.k-clock: {(day now.v)}
  ==
::
::  ---- bodies --------------------------------------------------------------
::
::  the browser renders prose (see app.js): each %body leaf ships its raw
::  source next to the div it is painted into
++  bloc-manx
  |=  b=bloc
  ^-  (list manx)
  ?-    -.b
      %body
    :~  ;div(class "k-src", hidden "", data-mark "{(trip p.page.b)}"): {?:(?=(@ q.page.b) (trip q.page.b) "")}
        ;div.k-body
          ;+  nowt
        ==
    ==
  ::
      %quote
    %+  weld  (bloc-manx after.b)
    :_  ~
    ;section.k-quote
      ;div.k-quote-line
        ;span.k-reply-mark: ↩
        ;a(href "{(read-url (orig-entry hed.b))}", class "k-quote-title"): {(titled `hed.b)}
        ;a(href "/keep/ship/{(pp who.hed.b)}", class "k-quote-who"): {(pp who.hed.b)}
        ;span.k-quote-when: {(day wen.hed.b)}
      ==
      ;*  (layer-warn who.hed.b okay.b)
      ;*  (bloc-manx quoted.b)
    ==
  ==
::
++  layer-warn
  |=  [who=ship okay=verdict:keep]
  ^-  (list manx)
  ?:  ?=(%good okay)  ~
  ?:  ?=(%forged okay)
    :_  ~
    ;div.k-warn: ⚠ this quotation does not match {(pp who)}'s signature — it may have been altered by whoever embedded it
  :_  ~
  ;div.k-warn: ⚠ nothing here shows {(pp who)} wrote this — it claims a key life we cannot fetch, so anyone could have embedded it
::
++  reply-tag
  |=  r=row
  ^-  (list manx)
  ?~  re.r  ~
  :_  ~
  ;div.k-reply-tag: ↩ {(trip u.re.r)}
::
::  ---- rows ----------------------------------------------------------------
::
++  repost-control
  |=  [r=row back=tape label=tape]
  ^-  manx
  ?:  |(kept.r =(our.v ship.entry.r))
    ;span(class "k-re on"): {label}
  ?.  pub.r
    ;span(class "k-re"): {label}
  ;form(method "post", action "/keep", style "display:inline")
    ;+  (hidden "what" "repost")
    ;+  (hidden "who" (pp ship.entry.r))
    ;+  (hidden "id" (id-of entry.r))
    ;+  (hidden "back" back)
    ;button(type "submit", class "k-link k-re"): {label}
  ==
::
++  edit-control
  |=  [r=row label=tape]
  ^-  (list manx)
  ?.  =(our.v ship.entry.r)  ~
  :_  ~
  ;a(href "/keep/edit/{(id-of entry.r)}/{(pp our.v)}", class "k-edit"): {label}
::
++  delete-control
  |=  [r=row back=tape label=tape]
  ^-  (list manx)
  ?.  =(our.v ship.entry.r)  ~
  :_  ~
  ;form(method "post", action "/keep", class "k-del-form", style "display:inline")
    ;+  (hidden "what" "delete")
    ;+  (hidden "id" (id-of entry.r))
    ;+  (hidden "back" back)
    ;button(type "submit", class "k-link k-del"): {label}
  ==
::
++  feed-row
  |=  [r=row back=tape]
  ^-  manx
  ;div.k-row
    ;*  ?:  =(via.r ship.entry.r)  ~
        :_  ~
        ;div.k-via: ↻ {(pp via.r)}
    ;*  (reply-tag r)
    ;div.k-row-in
      ;a(href "{(read-url entry.r)}", class "k-title {?~(hed.r "pending" "")}"): {(titled hed.r)}
      ;a(href "/keep/ship/{(pp (author r))}", class "k-who"): {(pp (author r))}
      ;div.k-when: {?~(hed.r "" (day wen.u.hed.r))}
      ;+  (repost-control r back "↻")
    ==
  ==
::
++  user-row
  |=  [r=row back=tape]
  ^-  manx
  ;div.k-row
    ;*  ?:  =(via.r ship.entry.r)  ~
        :_  ~
        ;div.k-via: ↻ {(pp (author r))}
    ;*  (reply-tag r)
    ;div.k-row-in
      ;a(href "{(read-url entry.r)}", class "k-title {?~(hed.r "pending" "")}"): {(titled hed.r)}
      ;*  (on-tag r "")
      ;div.k-when: {?~(hed.r "" (day wen.u.hed.r))}
      ;*  (delete-control r back "×")
    ==
  ==
::
::  ---- screens -------------------------------------------------------------
::
++  feed-page
  |=  rows=(list row)
  ^-  manx
  %+  shell  %feed
  ;div.k-col
    ;div.k-rows
      ;*  %+  turn  rows
          |=(r=row (feed-row r "/keep"))
    ==
  ==
::
++  user-page
  |=  [who=ship rows=(list row)]
  ^-  manx
  =/  back=tape  "/keep/ship/{(pp who)}"
  =/  following  (~(has in follows.v) who)
  %+  shell  ?:(=(who our.v) %mine %feed)
  ;div.k-col
    ;div.k-head
      ;div.k-ship: {(pp who)}
      ;*  ?:  =(who our.v)  ~
          :_  ~
          ;form(method "post", action "/keep", style "display:inline")
            ;+  (hidden "what" ?:(following "unfollow" "follow"))
            ;+  (hidden "who" (pp who))
            ;+  (hidden "back" back)
            ;button(type "submit", class "k-link k-follow"): {?:(following "following" "follow")}
          ==
    ==
    ;div.k-rows
      ;*  %+  turn  rows
          |=(r=row (user-row r back))
    ==
    ;*  ?:  ?=(^ rows)  ~
        ?:  =(who our.v)  ~
        ?:  (~(has in off.v) who)
          :_  ~
          ;div(class "k-note", data-state "off"): no keep
        ?:  (~(has in subs.v) who)
          :_  ~
          ;div(class "k-note", data-state "read"): nothing yet
        :_  ~
        ;form(method "post", action "/keep", class "k-note k-check", data-state "unknown")
          ;+  (hidden "what" "check")
          ;+  (hidden "who" (pp who))
          ;+  (hidden "back" back)
          ;button(type "submit", class "k-link"): check
        ==
  ==
::
++  read-page
  |=  [r=row bod=(unit bloc)]
  ^-  manx
  %+  shell  %read
  ;article.k-read
    ;a(href "/keep", class "k-back"): ←
    ;h1.k-art-title: {(titled hed.r)}
    ;*  ?.  ?=([~ %quote *] bod)  ~
        :_  ~
        ;div.k-reply
          ;span.k-reply-mark: ↩ in response to
          ;a(href "{(read-url (orig-entry hed.u.bod))}"): {(titled `hed.u.bod)}
        ==
    ;*  ?:  =(`%forged okay.r)
          :_  ~
          ;div.k-warn: ⚠ this does not match {(pp (author r))}'s signature — it may have been altered by whoever served it
        ?.  =(`%cold okay.r)  ~
        :_  ~
        ;div.k-warn: ⚠ nothing here shows {(pp (author r))} wrote this — it claims a key life we cannot fetch, so anyone could have served it
    ;div.k-meta
      ;a(href "/keep/ship/{(pp (author r))}"): {(pp (author r))}
      ;span.when: {?~(hed.r "" (day wen.u.hed.r))}
      ;+  %^  repost-control  r  (read-url entry.r)
          ?:(kept.r "↻ reposted" "↻ repost")
      ;a(href "/keep/respond/{(id-of entry.r)}/{(pp ship.entry.r)}", class "k-respond"): ↩ respond
      ;*  ?~  site.r  ~
          :_  ~
          ;a(href "{(trip u.site.r)}", class "k-site"): {(trip u.site.r)}
      ;*  (on-tag r "to ")
      ;*  (edit-control r "edit")
      ;*  (delete-control r "/keep/ship/{(pp our.v)}" "delete")
    ==
    ;*  ?~  bod
          :_  ~
          ;div.k-body
            ;+  nowt
          ==
        (bloc-manx u.bod)
  ==
::
++  public-page
  |=  [r=row bod=bloc]
  ^-  manx
  ;html
    ;head
      ;title: {(titled hed.r)}
      ;meta(charset "utf-8");
      ;meta(name "viewport", content "width=device-width, initial-scale=1");
      ;link(rel "preconnect", href "https://fonts.googleapis.com");
      ;link(rel "stylesheet", href "https://fonts.googleapis.com/css2?family=Spectral:ital,wght@0,300;0,400;0,500;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap");
      ;link(rel "stylesheet", href "/keep/style.css");
      ;script(src "/keep/app.js", defer "")
        ;+  nowt
      ==
    ==
    ;body
      ;main.k-solo
        ;article.k-read
          ;a(href "/keep/index", class "k-back"): ←
          ;h1.k-art-title: {(titled hed.r)}
          ;*  ?.  ?=(%quote -.bod)  ~
              :_  ~
              ;div.k-reply
                ;span.k-reply-mark: ↩ in response to
                ;span: {(titled `hed.bod)}
              ==
          ;div.k-meta
            ;span: {(pp (author r))}
            ;span.when: {?~(hed.r "" (day wen.u.hed.r))}
          ==
          ;*  (bloc-manx bod)
        ==
      ==
    ==
  ==
::
++  public-index
  |=  rows=(list row)
  ^-  manx
  ;html
    ;head
      ;title: {(pp our.v)}
      ;meta(charset "utf-8");
      ;meta(name "viewport", content "width=device-width, initial-scale=1");
      ;link(rel "preconnect", href "https://fonts.googleapis.com");
      ;link(rel "stylesheet", href "https://fonts.googleapis.com/css2?family=Spectral:ital,wght@0,300;0,400;0,500;0,600;1,400&family=IBM+Plex+Mono:wght@400;500&display=swap");
      ;link(rel "stylesheet", href "/keep/style.css");
    ==
    ;body
      ;main.k-solo
        ;div.k-col
          ;div.k-index-head: {(pp our.v)}
          ;div.k-rows
            ;*  %+  turn  rows
                |=  r=row
                ;div.k-row
                  ;*  (reply-tag r)
                  ;div.k-row-in
                    ;a(href "{?~(site.r "" (trip u.site.r))}", class "k-title"): {(titled hed.r)}
                    ;div.k-date: {?~(hed.r "" (day wen.u.hed.r))}
                  ==
                ==
          ==
        ==
      ==
    ==
  ==
::
++  write-page
  |=  [pre=(unit [id=tape src=tape to=tape]) re=(unit [e=entry:keep hed=head:keep])]
  ^-  manx
  =/  aud=tape  ?~(pre "everyone" to.u.pre)
  %+  shell  %write
  ;div.k-read
    ;*  ?~  re  ~
        :_  ~
        ;div.k-reply
          ;span.k-reply-mark: ↩ responding to
          ;a(href "{(read-url e.u.re)}"): {(titled `hed.u.re)}
          ;span.k-reply-who: {(pp who.hed.u.re)}
        ==
    ;div.k-ed-meta
      ;div.k-to
        ;span.lbl: to
        ;a(href "#", class "{?:(=("everyone" aud) "on" "")}", data-to "everyone"): everyone
        ;*  %+  turn  rolls.v
            |=  [=lyst:keep members=(set ship)]
            =/  nom=tape  (trip lyst)
            ;a(href "#", class "{?:(=(nom aud) "on" "")}", data-to "{nom}"): {nom}
      ==
      ;div.k-pub
        ;span(id "k-words", class "k-words"): 0 words
        ;a(href "#", id "k-send", class "k-send"): publish
      ==
    ==
    ;input(type "hidden", id "k-audience", value "{aud}");
    ;*  ?~  re  ~
        :~  ;input(type "hidden", id "k-re-who", value "{(pp ship.e.u.re)}");
            ;input(type "hidden", id "k-re-id", value "{(id-of e.u.re)}");
        ==
    ;*  ?~  pre  ~
        :~  ;input(type "hidden", id "k-edit-id", value "{id.u.pre}");
            ;div(id "k-ed-src", hidden ""): {src.u.pre}
        ==
    ;div(id "k-ed", class "k-ed", contenteditable "true", spellcheck "false")
      ;+  nowt
    ==
  ==
::
++  invite-form
  |=  [f=feed:keep what=tape label=tape cls=tape]
  ^-  manx
  ;form(method "post", action "/keep", style "display:inline")
    ;+  (hidden "what" what)
    ;+  (hidden "who" (pp ship.f))
    ;+  (hidden "path" (spud path.f))
    ;+  (hidden "back" "/keep/lists")
    ;button(type "submit", class "k-link {cls}"): {label}
  ==
::
++  pending-block
  ^-  (list manx)
  ?~  pending.v  ~
  :_  ~
  ;div.k-pending
    ;div.k-pending-head: pending
    ::  spelled out, not turn: feed holds a path, and turn is a wet gate
    ::  re-widened: the ?~ above narrowed it, and the loop rebinds to a tail
    ;*  =/  ps=(list [=feed:keep =lyst:keep])  pending.v
        |-  ^-  (list manx)
        ?~  ps  ~
        :_  $(ps t.ps)
        =/  f=feed:keep  feed.i.ps
        ;div.k-invite
          ;a(href "/keep/ship/{(pp ship.f)}", class "k-invite-who"): {(pp ship.f)}
          ;span.k-invite-list: {(trip lyst.i.ps)}
          ;+  (invite-form f "accept" "accept" "k-yes")
          ;+  (invite-form f "reject" "reject" "k-no")
        ==
  ==
::
++  lists-page
  |=  open=(unit lyst:keep)
  ^-  manx
  %+  shell  %lists
  ;div.k-col
    ;*  pending-block
    ;div.k-rows
      ;*  %+  turn  rolls.v
          |=  [=lyst:keep members=(set ship)]
          =/  nm=tape  (trip lyst)
          =/  up  &(?=(^ open) =(lyst u.open))
          =/  href=tape  ?:(up "/keep/lists" "/keep/lists/{nm}")
          ;div.k-list
            ;div.k-list-head
              ;a(href "{href}", class "k-list-name"): {nm}
              ;div.k-count: {(a-co:co ~(wyt in members))}
            ==
            ;*  ?.  up  ~
                :_  ~
                ;div.k-members
                  ;*  %+  turn  ~(tap in members)
                      |=  who=ship
                      ;div.k-member
                        ;span: {(pp who)}
                        ;form(method "post", action "/keep", style "display:inline")
                          ;+  (hidden "what" "evict")
                          ;+  (hidden "list" nm)
                          ;+  (hidden "who" (pp who))
                          ;+  (hidden "back" "/keep/lists/{nm}")
                          ;button(type "submit", class "k-link k-x"): ×
                        ==
                      ==
                  ;form(method "post", action "/keep", class "k-one")
                    ;+  (hidden "what" "admit")
                    ;+  (hidden "list" nm)
                    ;+  (hidden "back" "/keep/lists/{nm}")
                    ;input(type "text", name "who", class "k-add", placeholder "~sampel-palnet", autocomplete "off");
                  ==
                ==
          ==
    ==
    ;div.k-new-wrap
      ;form(method "post", action "/keep", class "k-one")
        ;+  (hidden "what" "make")
        ;+  (hidden "back" "/keep/lists")
        ;input(type "text", name "name", class "k-new", placeholder "new list", autocomplete "off");
      ==
    ==
  ==
--
