::  %keep-talk-gossip — what ames carries for comments. see /sur/keep-talk.hoon.
::
::  the agent refuses this mark from ourselves, as it refuses
::  %keep-talk-action from anyone else. same structure as %keep-gossip.
::
/-  kt=keep-talk
|_  gos=gossip:kt
++  grab
  |%
  ++  noun  gossip:kt
  --
++  grow
  |%
  ++  noun  gos
  --
++  grad  %noun
--
