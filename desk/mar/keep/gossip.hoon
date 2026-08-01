::  %keep-gossip — what ames carries, ever. see /sur/keep.hoon.
::
::  the agent refuses this mark from ourselves, as it refuses %keep-action
::  from anyone else. that is the whole trust model, and it is structural.
::
/-  keep
|_  gos=gossip:keep
++  grab
  |%
  ++  noun  gossip:keep
  --
++  grow
  |%
  ++  noun  gos
  --
++  grad  %noun
--
