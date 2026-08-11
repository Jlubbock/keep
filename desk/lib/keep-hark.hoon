::  cards for landscape's %hark, or none: a ship without landscape reads
::  no notifications and must not crash for it
::
/-  hark
|%
::  %gu not %gx: %gu says whether hark runs without crashing if it does not
++  live
  |=  =bowl:gall
  ^-  ?
  .^(? %gu /(scot %p our.bowl)/hark/(scot %da now.bowl)/$)
::
::  /desk/[desk], not a page path: landscape's notification click only
::  resolves /desk and /landscape prefixes; anything else is a dead link
++  notify
  |=  [=bowl:gall ted=path con=(list content:hark)]
  ^-  (list card:agent:gall)
  ?.  (live bowl)  ~
  =/  ny=new-yarn:hark
    [%.y %.y [~ ~ q.byk.bowl ted] con /desk/[q.byk.bowl] ~]
  :_  ~
  :^  %pass  /hark  %agent
  :^  [our.bowl %hark]  %poke  %hark-action-1
  !>(`action-1:hark`[%new-yarn ny])
--
