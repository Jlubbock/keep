::  %keep-action — local writes. see /sur/keep.hoon.
::
::  no %json arm on purpose: the frontend renders manx server-side, so there
::  is no JSON boundary to cross. a page is [mark noun] and there is no
::  general noun->json, so adding one would mean picking marks to privilege.
::
/-  keep
|_  act=action:keep
++  grab
  |%
  ++  noun  action:keep
  --
++  grow
  |%
  ++  noun  act
  --
++  grad  %noun
--
