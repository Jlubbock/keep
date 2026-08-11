/-  keep
|%
::  comments are a different trust model from items: unsigned by the HOST,
::  signed by the COMMENTER. the host can withhold a note, never write one.
+$  note
  $:  wen=@da
      who=@p                           ::  commenter, asserted and signed
      lyfe=@ud                         ::  their key life at signing
      parent=(unit id:keep)            ::  ~ is top-level
      body=@t                          ::  md prose
      sig=@ux                          ::  over (sain-note art ...)
  ==
::
::  art is inside the id, so a note cannot be replayed into another thread;
::  the id is also the dedupe key
++  sain-note
  |=  [art=id:keep who=@p lyfe=@ud wen=@da parent=(unit id:keep) body=@t]
  ^-  @uvH
  (sham [art who lyfe wen parent body])
::
+$  talk    [open=? notes=(list note)]  ::  what is grown at /talk/[art]
+$  thread  [rev=@ud =talk]             ::  host side; rev counts grows, for tombing
::
::  absent is not %forged: unjudged and judged-bad are different answers
+$  judged  [=note okay=(unit verdict:keep)]
::
::  ---- writes: poke %keep-talk-action ----------------------------------------
::
+$  action
  $%  [%open art=id:keep]               ::  host a thread on our own article
      [%shut art=id:keep]               ::  freeze: stop accepting, keep serving
      [%say host=ship art=id:keep parent=(unit id:keep) body=@t]
      [%read host=ship art=id:keep]     ::  tail a remote thread
      [%drop art=id:keep]               ::  from %keep on %delete: tomb + forget
    ::
      [%snip art=id:keep note=id:keep]  ::  the host removes one note
      [%ban who=ship]                   ::  refuse future comments; keeps existing
      [%unban who=ship]
      [%tier =rank:title]               ::  smallest ship class that may comment
  ==
::
::  ---- network: poke %keep-talk-gossip ---------------------------------------
::
+$  gossip
  $%  [%say art=id:keep =note]
  ==
--
