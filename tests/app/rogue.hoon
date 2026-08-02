::  a hostile peer, for C3.
::
::    An honest %keep cannot be made to distribute a bad pointer — +fan-out and
::    +mirror only ever publish `[our (base first) item-spur]`. So the only
::    forgery worth testing is a peer running different code, which is this.
::
::    It grows head/body pairs at the same namespace shape app/keep.hoon reads,
::    either matching or spliced: a real signature over a head whose `hash`
::    names a body other than the one served.
::
::    Test-only. Never in desk.bill — bake.mjs starts it with |rein.
::
/-  keep
/+  default-agent, dbug
|%
+$  card  card:agent:gall
+$  state-0  [%0 last=@uvH]
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init  `this
++  on-save  !>(state)
++  on-load  |=(=vase `this(state !<(state-0 vase)))
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  ?.  ?=(%noun mark)  (on-poke:def mark vase)
  ::  ;; not !<: the %noun mark grabs to `*`, which nests under nothing
  =/  act  ;;([%plant honest=? title=@t body=@t] q.vase)
  =/  signed=page  [%md body.act]
  =/  hash=@uvH    (sham signed)
  =/  lyfe=@ud
    .^(@ud %j /(scot %p our.bowl)/life/(scot %da now.bowl)/(scot %p our.bowl))
  =/  =id:keep  (sain:keep our.bowl lyfe now.bowl 'cc0' `title.act hash)
  =/  sec=@
    .^(@ %j /(scot %p our.bowl)/vein/(scot %da now.bowl)/(scot %ud lyfe))
  =/  hed=head:keep
    :*  now.bowl  our.bowl  lyfe  'cc0'  `title.act  hash
        (sigh:as:(nol:nu:crub:crypto sec) id)
    ==
  =/  served=page
    ?:  honest.act  signed
    [%md (cat 3 body.act ' (tampered in transit)')]
  =/  spur=path  /item/[(scot %uv id)]
  :_  this(last id)
  :~  [%pass /grow %grow (welp spur /head) noun+hed]
      [%pass /grow %grow (welp spur /body) noun+served]
  ==
::
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:def path)
    [%x %last ~]  ``noun+!>(last)
  ==
::
++  on-watch  on-watch:def
++  on-agent  on-agent:def
++  on-arvo   on-arvo:def
++  on-leave  on-leave:def
++  on-fail   on-fail:def
--
