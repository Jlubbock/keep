/-  keep
|%
::  ---- what the publication serves ----------------------------------------
+$  meta                                 ::  one archive entry, no body
  $:  slug=@t
      wen=@da                            ::  substack's post_date
      aud=@t                             ::  'everyone' or a paid tier
  ==
::
+$  post                                 ::  a pulled post, ready to file
  $:  slug=@t
      wen=@da
      title=@t
      md=@t
  ==
::
+$  scan                                 ::  what a whole archive holds
  $:  n=@ud
      free=@ud                           ::  arrive as full text
      paid=@ud                           ::  arrive as teasers
      old=@da
      new=@da
  ==
::
::  ---- agent state ---------------------------------------------------------
+$  sub
  $:  url=@t                             ::  base, no trailing slash
      every=@dr
      terms=@t
      to=(set lyst:keep)
      last=@da                           ::  newest imported post_date
      next=@da                           ::  a wake before this is a stale chain
      seen=(set @t)                      ::  slugs already posted
      tid=(unit @ta)                     ::  the pull in flight, if any
  ==
::
+$  prev                                 ::  a scan pending, shown, or failed
  $:  url=@t
      got=(unit scan)
      fail=?
  ==
::
::  ---- substack identity ---------------------------------------------------
::
::  the publications a ship syncs are the ones it claims, grown as a
::  (set @t) at /substack. whoever reads its page fetches each one's /about
::  and looks for the ship's own @p there. there is no verifier: every
::  reader judges alone and keeps its answer
+$  proof  ?(%wait %yes %no %down)      ::  %down: /about did not answer
::
+$  badge                                ::  one claim, as we last judged it
  $:  =proof
      wen=@da                            ::  when we last read /about
  ==
::
+$  claim  [who=ship url=@t]
::
::  ---- writes: poke %keep-sync-action --------------------------------------
::
+$  action
  $%  [%preview name=@tas url=@t]        ::  scan first: what would a track do
      [%cancel name=@tas]                ::  drop a preview
      [%track name=@tas url=@t every=@dr terms=@t to=(set lyst:keep)]
      [%untrack name=@tas]
      [%pull name=@tas]                  ::  poll now, off the clock
      [%ingest name=@tas p=post]         ::  from our own pull thread, one by one
      ::
      [%look who=ship force=?]           ::  a page is being read: keen, then judge
  ==
--
