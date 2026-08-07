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
  ;a(href "/keep/edit/{(id-of entry.r)}", class "k-edit"): {label}
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
    ;div.k-row-in
      ;a(href "{(read-url entry.r)}", class "k-title {?~(hed.r "pending" "")}"): {(titled hed.r)}
      ;div.k-when: {?~(hed.r "" (day wen.u.hed.r))}
      ;*  (edit-control r "✎")
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
  |=  [r=row bod=(unit page)]
  ^-  manx
  %+  shell  %read
  ;article.k-read
    ;a(href "/keep", class "k-back"): ←
    ;h1.k-art-title: {(titled hed.r)}
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
      ;*  ?~  site.r  ~
          :_  ~
          ;a(href "{(trip u.site.r)}", class "k-site"): {(trip u.site.r)}
      ;*  (edit-control r "edit")
      ;*  (delete-control r "/keep/ship/{(pp our.v)}" "delete")
    ==
    ;*  ?~  bod  ~
        :_  ~
        ;div(id "k-src", hidden "", data-mark "{(trip p.u.bod)}"): {?:(?=(@ q.u.bod) (trip q.u.bod) "")}
    ;div(id "k-body", class "k-body")
      ;+  nowt
    ==
  ==
::
++  public-page
  |=  [r=row bod=page]
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
          ;div.k-meta
            ;span: {(pp (author r))}
            ;span.when: {?~(hed.r "" (day wen.u.hed.r))}
          ==
          ;div(id "k-src", hidden "", data-mark "{(trip p.bod)}"): {?:(?=(@ q.bod) (trip q.bod) "")}
          ;div(id "k-body", class "k-body")
            ;+  nowt
          ==
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
  |=  pre=(unit [id=tape src=tape to=tape])
  ^-  manx
  =/  aud=tape  ?~(pre "everyone" to.u.pre)
  %+  shell  %write
  ;div.k-read
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
