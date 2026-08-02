::  layer B — the jael and crub assumptions app/keep.hoon rests on.
::
::    A THREAD, not test arms: mcp/run-tests fires arms inside +mule, whose
::    null scry gate blocks every .^, and this layer is nothing but scries.
::
::    Run:  dojo/run-thread  desk=keep  path=/ted/b-jael
::
/-  spider, keep
/+  strandio
=,  strand=strand:spider
|%
+$  chk  [id=@t ok=?]
::
++  render
  |=  cs=(list chk)
  ^-  @t
  =/  green  (lent (skip cs |=(c=chk !ok.c)))
  =/  lines=tape
    |-  ^-  tape
    ?~  cs  ""
    %+  weld
      "{?:(ok.i.cs "OK  " "FAIL")} {(trip id.i.cs)}\0a"
    $(cs t.cs)
  %-  crip
  (weld lines "layer-B: {(a-co:co green)}/{(a-co:co (lent cs))} green")
--
^-  thread:spider
|=  arg=vase
=/  m  (strand ,vase)
^-  form:m
;<  =bowl:spider  bind:m  get-bowl:strandio
=/  us=@ta   (scot %p our.bowl)
=/  wen=@ta  (scot %da now.bowl)
::
=/  lyf=@ud  .^(@ud %j /[us]/life/[wen]/[us])
=/  sec=@    .^(@ %j /[us]/vein/[wen]/(scot %ud lyf))
=/  ours     .^([@ud pas=@ *] %j /[us]/deed/[wen]/[us]/(scot %ud lyf))
::
=/  hash=@uvH  (sham [%md 'the body'])
=/  id=@uvH    (sain:keep our.bowl lyf now.bowl 'cc0' `'a title' hash)
=/  sig=@ux    (sigh:as:(nol:nu:crub:crypto sec) id)
::  the same signature against ids it no longer covers: body swapped, then title
=/  reboded=@uvH   (sain:keep our.bowl lyf now.bowl 'cc0' `'a title' (sham [%md 'other']))
=/  retitled=@uvH  (sain:keep our.bowl lyf now.bowl 'cc0' `'a lie' hash)
::
::  deliberately NOT a fleet ship: the peer gets contacted constantly by layer
::  C, and this must stay a ship we have never exchanged a packet with. %lyfe
::  is what +pass-of gates on, so if it answers then a stranger's head is
::  judgeable — and +sound returning ~ is the rare path, not the common one.
=/  they=@p     ~bus
=/  their-life  .^((unit @ud) %j /[us]/lyfe/[wen]/(scot %p they))
=/  theirs
  ?~  their-life  [0 pas=0 ~]
  .^([@ud pas=@ *] %j /[us]/deed/[wen]/(scot %p they)/(scot %ud u.their-life))
::
=/  ours-verifies   |=(i=@uvH (safe:as:(com:nu:crub:crypto pas.ours) sig i))
=/  checks=(list chk)
  :~  ['B1.1 our life resolves' (gth lyf 0)]
      ['B1.2 our signature verifies' (ours-verifies id)]
      ['B1.3 not over a swapped body' !(ours-verifies reboded)]
      ['B1.4 not over a swapped title' !(ours-verifies retitled)]
      ['B2.1 jael knows an uncontacted ship' ?=(^ their-life)]
      ['B2.2 and hands out its key' ?!(=(0 pas.theirs))]
      :-  'B2.3 our signature does not verify under it'
      ?~  their-life  %.n
      !(safe:as:(com:nu:crub:crypto pas.theirs) sig id)
  ==
(pure:m !>((render checks)))
