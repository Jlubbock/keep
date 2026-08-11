/-  keep, kt=keep-talk
::
|%
::
+$  tv  [open=? notes=(list judged:kt)]   ::  a thread as the renderer sees it
::
+$  row
  $:  via=ship
      =entry:keep
      hed=(unit head:keep)
      kept=?                             ::  have we syndicated it
      pub=?                              ::  did it reach us publicly
      site=(unit @t)                     ::  its url on the open web, if ours
      okay=(unit verdict:keep)
      ::  a list name is a capability hint — empty on every clearnet row
      on=(list lyst:keep)                ::  where we fanned it, ours only
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
      ;a(href "/keep/comments", class "{(sel %comments)}"): comments
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
      ;*  (on-tag r "")
      ;div.k-when: {?~(hed.r "" (day wen.u.hed.r))}
      ;*  (delete-control r back "×")
    ==
  ==
::
::  ---- comments --------------------------------------------------------------
::
++  nid
  |=  [art=id:keep n=note:kt]
  ^-  id:keep
  (sain-note:kt art who.n lyfe.n wen.n parent.n body.n)
::
++  note-ids
  |=  [art=id:keep all=(list judged:kt)]
  ^-  (set id:keep)
  ?~  all  ~
  (~(put in $(all t.all)) (nid art note.i.all))
::
::  a parent missing from the thread promotes its children to the top rather
::  than losing them: the host prunes, the reader still reads
++  roots-of
  |=  [art=id:keep all=(list judged:kt)]
  ^-  (list judged:kt)
  =/  ids  (note-ids art all)
  %+  skim  all
  |=  j=judged:kt
  ?~  parent.note.j  %.y
  !(~(has in ids) u.parent.note.j)
::
++  kids-of
  |=  [art=id:keep all=(list judged:kt) i=id:keep]
  ^-  (list judged:kt)
  %+  skim  all
  |=  j=judged:kt
  =(`i parent.note.j)
::
++  say-form
  |=  [host=ship art=tape parent=tape back=tape]
  ^-  manx
  ;form(method "post", action "/keep", class "k-say")
    ;+  (hidden "what" "comment")
    ;+  (hidden "who" (pp host))
    ;+  (hidden "id" art)
    ;+  (hidden "parent" parent)
    ;+  (hidden "back" back)
    ;textarea(name "body", class "k-say-body", rows "5", placeholder "reply — markdown welcome")
      ;+  nowt
    ==
    ;div.k-say-foot
      ;button(type "submit", class "k-link k-say-send"): post
    ==
  ==
::
++  note-tree
  |=  $:  host=ship
          art=id:keep
          art-str=tape
          back=tape
          live=?
          say=?
          all=(list judged:kt)
          j=judged:kt
          depth=@ud
      ==
  ^-  manx
  =/  i=id:keep  (nid art note.j)
  =/  kids=(list judged:kt)  (kids-of art all i)
  ;div.k-cmt
    ;div.k-cmt-head
      ;+  ?.  live
            ;span.k-cmt-who: {(pp who.note.j)}
          ;a(href "/keep/ship/{(pp who.note.j)}", class "k-cmt-who"): {(pp who.note.j)}
      ;span.k-cmt-when: {(day wen.note.j)}
      ;*  ?.  &(live =(our.v host))  ~
          :_  ~
          ;form(method "post", action "/keep", class "k-snip-form", style "display:inline")
            ;+  (hidden "what" "snip")
            ;+  (hidden "id" art-str)
            ;+  (hidden "note" (trip (scot %uv i)))
            ;+  (hidden "back" back)
            ;button(type "submit", class "k-link k-del"): ×
          ==
      ;*  ?.  ?&  live
                  =(our.v host)
                  !=(our.v who.note.j)
              ==
            ~
          :_  ~
          ;form(method "post", action "/keep", class "k-ban-form", style "display:inline")
            ;+  (hidden "what" "ban")
            ;+  (hidden "who" (pp who.note.j))
            ;+  (hidden "back" back)
            ;button(type "submit", class "k-link k-ban"): ban
          ==
    ==
    ;*  ?:  =(`%forged okay.j)
          :_  ~
          ;div.k-warn: ⚠ this does not match {(pp who.note.j)}'s signature — it may have been altered by whoever served it
        ?.  =(`%cold okay.j)  ~
        :_  ~
        ;div.k-warn: ⚠ nothing here shows {(pp who.note.j)} wrote this — it claims a key life we cannot fetch
    ;div(class "k-cmt-src", hidden ""): {(trip body.note.j)}
    ;div.k-cmt-body
      ;+  nowt
    ==
    ;*  ?.  say  ~
        :_  ~
        ;details.k-reply
          ;summary: reply
          ;+  (say-form host art-str (trip (scot %uv i)) back)
        ==
    ;*  ?~  kids  ~
        :_  ~
        ;div(class "k-cmt-kids {?:((lth depth 3) "indent" "")}")
          ;*  %+  turn  kids
              |=  k=judged:kt
              (note-tree host art art-str back live say all k +(depth))
        ==
  ==
::
++  talk-block
  |=  [r=row tlk=(unit tv) live=?]
  ^-  (list manx)
  ?~  tlk  ~
  =/  art-str=tape  (id-of entry.r)
  ?~  art=(slaw %uv (crip art-str))  ~
  =/  back=tape  (read-url entry.r)
  =/  say=?  &(live open.u.tlk)
  =/  all=(list judged:kt)  notes.u.tlk
  :_  ~
  ;section.k-talk
    ;div.k-talk-head: comments
    ;*  %+  turn  (roots-of u.art all)
        |=  j=judged:kt
        (note-tree ship.entry.r u.art art-str back live say all j 0)
    ;*  ?:  say  ~[(say-form ship.entry.r art-str "" back)]
        ?:  open.u.tlk  ~
        :_  ~
        ;div.k-talk-closed: comments closed
  ==
::
++  talk-toggle
  |=  [r=row tlk=(unit tv) back=tape]
  ^-  (list manx)
  ?.  =(our.v ship.entry.r)  ~
  =/  on=?  ?~(tlk %.n open.u.tlk)
  =/  label=tape
    ?:  on  "close comments"
    ?~  tlk  "enable comments"
    "reopen comments"
  :_  ~
  ;form(method "post", action "/keep", style "display:inline")
    ;+  (hidden "what" "talk")
    ;+  (hidden "id" (id-of entry.r))
    ;+  (hidden "on" ?:(on "off" "on"))
    ;+  (hidden "back" back)
    ;button(type "submit", class "k-link k-talk-toggle"): {label}
  ==
::
++  tier-name
  |=  r=rank:title
  ^-  tape
  ?-  r
    %pawn  "everyone"
    %earl  "moons & up"
    %duke  "planets & up"
    %king  "stars & up"
    %czar  "galaxies"
  ==
::
++  tier-form
  |=  [r=rank:title cur=rank:title]
  ^-  manx
  ;form(method "post", action "/keep", style "display:inline")
    ;+  (hidden "what" "tier")
    ;+  (hidden "rank" (trip r))
    ;+  (hidden "back" "/keep/comments")
    ;button(type "submit", class "k-link k-tier {?:(=(r cur) "on" "")}"): {(tier-name r)}
  ==
::
++  comments-page
  |=  rules=(unit [banned=(set ship) tier=rank:title])
  ^-  manx
  %+  shell  %comments
  ;div.k-col
    ;*  ?^  rules  ~
        :_  ~
        ;div(class "k-note", data-state "off"): %keep-talk is not running
    ;*  ?~  rules  ~
        :~  ;div.k-rules
              ;div.k-rules-head: who may comment
              ;div.k-tiers
                ;*  %+  turn  `(list rank:title)`~[%pawn %earl %duke %king %czar]
                    |=(r=rank:title (tier-form r tier.u.rules))
              ==
            ==
            ;div.k-rules
              ;div.k-rules-head: banned
              ;div.k-members
                ;*  %+  turn  ~(tap in banned.u.rules)
                    |=  who=ship
                    ;div.k-member
                      ;span: {(pp who)}
                      ;form(method "post", action "/keep", style "display:inline")
                        ;+  (hidden "what" "unban")
                        ;+  (hidden "who" (pp who))
                        ;+  (hidden "back" "/keep/comments")
                        ;button(type "submit", class "k-link k-x"): ×
                      ==
                    ==
                ;form(method "post", action "/keep", class "k-one")
                  ;+  (hidden "what" "ban")
                  ;+  (hidden "back" "/keep/comments")
                  ;input(type "text", name "who", class "k-add", placeholder "~sampel-palnet", autocomplete "off");
                ==
              ==
            ==
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
  |=  [r=row bod=(unit page) tlk=(unit tv) talky=?]
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
      ;*  ?:  =(our.v ship.entry.r)  ~
          :_  ~
          %^  repost-control  r  (read-url entry.r)
          ?:(kept.r "↻ reposted" "↻ repost")
      ;*  ?~  site.r  ~
          :_  ~
          ;a(href "{(trip u.site.r)}", class "k-site"): {(trip u.site.r)}
      ;*  (on-tag r "to ")
      ;*  (edit-control r "edit")
      ;*  (delete-control r "/keep/ship/{(pp our.v)}" "delete")
      ;*  ?.(talky ~ (talk-toggle r tlk (read-url entry.r)))
    ==
    ;*  ?~  bod  ~
        :_  ~
        ;div(id "k-src", hidden "", data-mark "{(trip p.u.bod)}"): {?:(?=(@ q.u.bod) (trip q.u.bod) "")}
    ;div(id "k-body", class "k-body")
      ;+  nowt
    ==
    ;*  (talk-block r tlk %.y)
  ==
::
++  public-page
  |=  [r=row bod=page tlk=(unit tv)]
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
          ;*  (talk-block r tlk %.n)
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
                  ;form(method "post", action "/keep", class "k-one")
                    ;+  (hidden "what" "unlist")
                    ;+  (hidden "list" nm)
                    ;+  (hidden "back" "/keep/lists")
                    ;button(type "submit", class "k-link k-del"): delete list
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
