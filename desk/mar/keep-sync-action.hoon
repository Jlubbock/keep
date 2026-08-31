::  %keep-sync-action — local writes. see /sur/keep-sync.hoon.
::
/-  ks=keep-sync
|_  act=action:ks
++  grab
  |%
  ++  noun  action:ks
  --
++  grow
  |%
  ++  noun  act
  --
++  grad  %noun
--
