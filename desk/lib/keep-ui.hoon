::  /lib/keep-ui.hoon — every screen, server-rendered.
::
::  the agent hands this a +view: a flat projection of state with the joins
::  already done. nothing in here touches gall, and nothing in here parses a
::  page — markdown is rendered in the browser, because the agent is not
::  allowed to learn what a body contains and neither is its renderer.
::
::  the stylesheet and the client script live in /ui at the repo root and are
::  copied to /ui in the desk by build.sh. this file has to sit in /lib
::  instead, because /+ resolves there and nowhere else.
::
/-  keep
::
|%
::  one feed line. via is the ship whose index we read it from, which is the
::  reposter when it differs from the ship the entry names.
::
+$  row
  $:  via=ship
      =entry:keep
      hed=(unit head:keep)
      kept=?                             ::  have we syndicated it
      pub=?                              ::  did it reach us publicly
  ==
::
+$  view
  $:  our=ship
      now=@da
      pals=(list ship)
      subs=(set ship)                    ::  whose index we tail
      off=(set ship)                     ::  confirmed not running %keep
      rolls=(list [=lyst:keep members=(set ship)])
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
++  pad
  |=  n=@ud
  ^-  tape
  ?:((lth n 10) "0{(a-co:co n)}" (a-co:co n))
::
++  day
  |=  wen=@da
  ^-  tape
  =/  d  (yore wen)
  "~{(a-co:co y.d)}.{(a-co:co m.d)}.{(a-co:co d.t.d)}"
::
::  the design's short forms: 11:04 today, yest, 3d, then a date.
::
++  when
  |=  wen=@da
  ^-  tape
  =/  gap=@dr  ?:((gth wen now.v) *@dr (sub now.v wen))
  =/  d  (yore wen)
  ?:  (lth gap ~d1)  "{(pad h.t.d)}:{(pad m.t.d)}"
  ?:  (lth gap ~d2)  "yest"
  ?:  (lth gap ~d30)  "{(a-co:co (div gap ~d1))}d"
  (day wen)
::
++  pp  |=(who=ship ^-(tape (scow %p who)))
++  id-of  |=(e=entry:keep ^-(tape (trip (last path.e))))
::
::  id first, ship last. eyre splits the LAST path segment on its final dot
::  to make pork's ext — which is how /keep/style.css works — and a @uv id
::  is full of dots. a @p never has one, so it is safe at the end.
::
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
      ::  go to any ship's feed. slaw does the validating; nothing is sent.
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
::  repost. the protocol has no un-keep — an index only grows — so this is a
::  latch, not a toggle: once syndicated the glyph is lit and inert.
::
::  a pointer we read out of someone's private list is theirs to gate, and
::  the agent crashes rather than republish it. no control is offered for
::  one, because a button that is always refused is worse than no button.
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
++  feed-row
  |=  [r=row back=tape]
  ^-  manx
  ;div.k-row
    ;*  ?:  =(via.r ship.entry.r)  ~
        :_  ~
        ;div.k-via: ↻ {(pp via.r)}
    ;div.k-row-in
      ;a(href "{(read-url entry.r)}", class "k-title {?~(hed.r "pending" "")}"): {(titled hed.r)}
      ;a(href "/keep/ship/{(pp ship.entry.r)}", class "k-who"): {(pp ship.entry.r)}
      ;div.k-when: {?~(hed.r "" (when wen.u.hed.r))}
      ;+  (repost-control r back "↻")
    ==
  ==
::
::  the author column is dropped on a user feed: the author is the page. a
::  repost keeps its attribution line, pointing at whoever wrote it.
::
++  user-row
  |=  [r=row back=tape]
  ^-  manx
  ;div.k-row
    ;*  ?:  =(via.r ship.entry.r)  ~
        :_  ~
        ;div.k-via: ↻ {(pp ship.entry.r)}
    ;div.k-row-in
      ;a(href "{(read-url entry.r)}", class "k-title {?~(hed.r "pending" "")}"): {(titled hed.r)}
      ;div.k-when: {?~(hed.r "" (when wen.u.hed.r))}
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
  =/  following  (~(has in subs.v) who)
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
    ::  an empty feed means one of three things and they are not the same.
    ::  following: the keen is parked, so blank is the truth. off: we asked
    ::  and they nacked. otherwise nobody has ever asked — offer to, since
    ::  a scry cannot answer it and only a poke can.
    ;*  ?:  ?=(^ rows)  ~
        ?:  |(following =(who our.v))  ~
        ?:  (~(has in off.v) who)
          :_  ~
          ;div(class "k-note", data-state "off"): no keep
        ::  data-state is what the client watches: the answer lands in a
        ::  later event, so it re-asks this page until the state moves off
        ::  `unknown` and then shows it.
        :_  ~
        ;form(method "post", action "/keep", class "k-note k-check", data-state "unknown")
          ;+  (hidden "what" "check")
          ;+  (hidden "who" (pp who))
          ;+  (hidden "back" back)
          ;button(type "submit", class "k-link"): check
        ==
  ==
::
::  the body arrives on its own schedule. when it is not here yet the article
::  renders without one — blank is the honest state of an outstanding keen —
::  and the client asks again until it lands.
::
++  read-page
  |=  [r=row bod=(unit page)]
  ^-  manx
  %+  shell  %read
  ;article.k-read
    ;a(href "/keep", class "k-back"): ←
    ;h1.k-art-title: {(titled hed.r)}
    ;div.k-meta
      ;a(href "/keep/ship/{(pp ship.entry.r)}"): {(pp ship.entry.r)}
      ;span.when: {?~(hed.r "" (when wen.u.hed.r))}
      ;+  %^  repost-control  r  (read-url entry.r)
          ?:(kept.r "↻ reposted" "↻ repost")
    ==
    ;*  ?~  bod  ~
        :_  ~
        ;div(id "k-src", hidden "", data-mark "{(trip p.u.bod)}"): {?:(?=(@ q.u.bod) (trip q.u.bod) "")}
    ;div(id "k-body", class "k-body")
      ;+  nowt
    ==
  ==
::
++  write-page
  ^-  manx
  %+  shell  %write
  ;div.k-read
    ;div.k-ed-meta
      ;div.k-to
        ;span.lbl: to
        ;a(href "#", class "on", data-to "everyone"): everyone
        ;*  %+  turn  rolls.v
            |=  [=lyst:keep members=(set ship)]
            ;a(href "#", data-to "{(trip lyst)}"): {(trip lyst)}
      ==
      ;div.k-pub
        ;span(id "k-words", class "k-words"): 0 words
        ;a(href "#", id "k-send", class "k-send"): publish
      ==
    ==
    ;input(type "hidden", id "k-audience", value "everyone");
    ;div(id "k-ed", class "k-ed", contenteditable "true", spellcheck "false")
      ;+  nowt
    ==
  ==
::
::  a list name is a @tas — the protocol's, not the design's, so `close
::  readers` is `close-readers`. expansion is a url rather than local state.
::
++  lists-page
  |=  open=(unit lyst:keep)
  ^-  manx
  %+  shell  %lists
  ;div.k-col
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
