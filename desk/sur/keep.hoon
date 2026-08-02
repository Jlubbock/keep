|%
::  ---- core types ------------------------------------------------------------
+$  id     @uvH                      ::  (sham +sain of head)
+$  lyst   @tas                      ::  %public, or any name you like
::
+$  entry  spar:ames                 ::  [ship path] — an address, not a copy
+$  feed   [=ship =path]             ::  a subscribable index, by its spur
::
+$  head
  $:  wen=@da
      who=@p                           ::  author, asserted and signed
      lyfe=@ud                         ::  their key life at signing
      terms=@t
      title=(unit @t)
      hash=@uvH                        ::  (sham page)
      sig=@ux                          ::  over id
  ==
::
++  sain
  |=  [who=@p lyfe=@ud wen=@da terms=@t title=(unit @t) hash=@uvH]
  ^-  @uvH
  (sham [who lyfe wen terms title hash])
::
+$  item   [=head =page]             ::  page is [mark noun]; prose is md+'...'
::
::  ---- writes: poke %keep-action ---------------------------------------------
::
+$  action
  $%  [%post =page title=(unit @t) terms=@t to=(set lyst)]
      [%keep =entry to=(set lyst)]
      [%open =entry]
      ::
      [%list =lyst members=(set ship)]
      [%admit =lyst who=(set ship)]
      [%evict =lyst who=(set ship)]
      ::
      [%sub who=ship]
      [%unsub who=ship]
      ::
      [%accept =feed]
      [%reject =feed]
  ==
::
::  ---- network: poke %keep-gossip --------------------------------------------
::
+$  gossip
  $%  [%announce ~]                  ::  i have %keep installed
      [%invite =lyst =path]          ::  here is your address for my list
  ==
::
::  ---- reads: watch %keep-update, or scry ------------------------------------
::
+$  update
  $%  [%wall entries=(list [via=feed =entry]) heads=(map entry head)]
      [%posted =id =entry]
      [%arrived via=feed =entry]
      [%head =entry =head]
      [%body =entry =page okay=(unit ?)]
      [%lists lists=(map lyst (set ship))]
      [%peers subs=(set ship) off=(set ship)]
      [%pending invites=(list [=feed =lyst])]
  ==
--
