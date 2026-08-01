::  /sur/keep.hoon — the whole integration surface
::
::  a desk that wants to read %keep needs none of this: scry with a /noun
::  suffix and ;; the result into your own types. this file is for desks that
::  want to write, or to hold a live subscription.
::
|%
::  ---- core types ------------------------------------------------------------
+$  id     @uvH                      ::  (sham [head page]) — also the address
+$  lyst   @tas                      ::  %public, or any name you like
::
::  an entry is a PREFIX, not a resolvable address. a reader appends /head or
::  /body to it before keening. the body is grown separately from the head so
::  that tailing forty writers costs forty streams of tens-of-bytes headers
::  rather than everything all of them ever wrote.
::
+$  entry  spar:ames                 ::  [ship path] — an address, not a copy
+$  feed   [=ship =path]             ::  a subscribable index, by its spur
::
::  the head is what a shelf of titles is made of, and the whole of what a
::  tailing ship fetches eagerly. the title is asserted by the publisher: the
::  agent never parses a page and must not learn how.
::
+$  head   [wen=@da terms=@t title=(unit @t)]
+$  item   [=head =page]             ::  page is [mark noun]; prose is md+'...'
::
::  ---- writes: poke %keep-action ---------------------------------------------
::  local only. the agent refuses this mark from anyone but us.
::
+$  action
  $%  ::  create a body and publish it to every list named. two %grows, no
      ::  packets: the members' parked keens do the rest.
      [%post =page title=(unit @t) terms=@t to=(set lyst)]
      ::  syndicate someone else's address. no body moves; our readers resolve
      ::  it at the ship it names. crashes on %public unless we read it from a
      ::  public index, since that would expose a gated address as us.
      [%keep =entry to=(set lyst)]
      ::  fetch a body we hold a pointer to. heads arrive on their own; a page
      ::  is only ever fetched because someone asked to read it.
      [%open =entry]
      ::
      ::  upsert. creates the list if it is new and sets membership either way,
      ::  so a caller never has to check first or handle "already exists".
      [%list =lyst members=(set ship)]
      [%admit =lyst who=(set ship)]
      [%evict =lyst who=(set ship)]
      ::
      ::  follow or drop someone's public index
      [%sub who=ship]
      [%unsub who=ship]
  ==
::
::  ---- network: poke %keep-gossip --------------------------------------------
::  remote only. a separate mark so the trust check is structural: nothing
::  local can forge an invite, and no handler has to remember to test src.
::
+$  gossip
  $%  [%announce ~]                  ::  i have %keep installed
      [%invite =lyst =path]          ::  here is your address for my list
  ==
::
::  ---- reads: watch %keep-update, or scry ------------------------------------
::  ONE update type. every path is a filter on it, so nothing is maintained
::  twice and a new consumer needs no new plumbing.
::
::    /updates             everything. the easy one for other agents.
::    /ui/wall             %wall, %posted, %arrived, %head
::    /ui/lists            %lists
::    /ui/peers            %peers
::    /ui/body/[ship]/...  %body for that one entry
::
::  every path gifts current state to a joining duct before any broadcast, and
::  no fact is ever empty. the exception is /ui/body, which gifts nothing while
::  its keen is outstanding — there, blank means "still fetching", which is the
::  only honest thing to say about a scry that may never resolve.
::
+$  update
  $%  ::  whole state. this is what +on-watch gifts a joining duct, so a late
      ::  subscriber folds its own burst rather than picking up someone else's
      ::  mid-stream delta. every delta case below has to have one of these.
      ::  heads ride along because a wall without them is a list of hashes.
      [%wall entries=(list [via=feed =entry]) heads=(map entry head)]
      ::  we published. carries the id, because a poke cannot return one.
      [%posted =id =entry]
      ::  a pointer turned up in an index we tail
      [%arrived via=feed =entry]
      ::  a head resolved — title, date, terms. arrives unasked.
      [%head =entry =head]
      ::  a body finished resolving. only ever after an %open.
      [%body =entry =page]
      ::  whole state — both are small enough that deltas would be noise
      [%lists lists=(map lyst (set ship))]
      [%peers subs=(set ship) off=(set ship)]
  ==
::
::  ---- scry ------------------------------------------------------------------
::
::    /x/wall/noun               (list [via=feed =entry])
::    /x/heads/noun              (map entry head)   — theirs, fetched
::    /x/posts/noun              (map id item)      — ours, local only
::    /x/lists/noun              (map lyst (set ship))
::    /x/subs/noun               (map feed @ud)
::    /x/item/[ship]/[path]/noun (unit item)  — head and body both resolved
::
--
