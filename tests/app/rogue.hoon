::  a hostile peer, for C3.
::
::    An honest %keep cannot be made to distribute a bad pointer — +fan-out and
::    +mirror only ever publish `[our (base first) item-spur]`. So the only
::    forgery worth testing is a peer running different code, which is this.
::
::    It grows head/body pairs at the same namespace shape app/keep.hoon reads:
::
::      %plant  a real signature over a head whose `hash` names a body other
::              than the one served, or an honest pair as the control.
::      %forge  a head naming ANOTHER ship, at a life jael cannot resolve, so
::              +pass-of returns ~ and the signature is never checked. For C6.
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
  =/  act
    ;;  $%  [%plant honest=? title=@t body=@t]
            [%forge who=@p lyfe=@ud title=@t body=@t]
        ==
    q.vase
  =/  ours=@ud
    .^(@ud %j /(scot %p our.bowl)/life/(scot %da now.bowl)/(scot %p our.bowl))
  ::  who and lyfe are what the head CLAIMS; the key is always ours
  =/  plan=[who=@p lyfe=@ud tit=@t signed=page served=page]
    ?-    -.act
        %plant
      :*  our.bowl  ours  title.act  [%md body.act]
          ?:  honest.act  [%md body.act]
          [%md (cat 3 body.act ' (tampered in transit)')]
      ==
    ::
        %forge
      [who.act lyfe.act title.act [%md body.act] [%md body.act]]
    ==
  =/  hash=@uvH  (sham signed.plan)
  =/  =id:keep   (sain:keep who.plan lyfe.plan now.bowl 'cc0' `tit.plan hash)
  =/  sec=@
    .^(@ %j /(scot %p our.bowl)/vein/(scot %da now.bowl)/(scot %ud ours))
  =/  hed=head:keep
    :*  now.bowl  who.plan  lyfe.plan  'cc0'  `tit.plan  hash
        (sigh:as:(nol:nu:crub:crypto sec) id)
    ==
  =/  served=page  served.plan
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
