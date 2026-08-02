# keep — design

The conceptual model, moved out of `app/keep.hoon` when the inline prose was
stripped. Updated for signed authorship (`%4`); see git history for the v0 text.

## One Primitive

a list is a set of ships plus a salt. every list holds an index: a list of
pointers, grown one revision per entry, each revision carrying the whole
list so far.

    %public   index lives at /index. the address is derivable from our @p,
              so nobody needs to be told it. no members, no push.

    anything  index lives at /list/[key], one path PER MEMBER, where
    else      key = (shas salt [list ship]). unguessable, so the address is
              the capability. we grow the same pointers to every member's
              path separately.

bodies live once, hash-addressed at /item/[id], id = (sham [head page]).
one store for public and gated alike — a body address is a content hash,
so it cannot be found by anyone who was not handed a pointer to it. gating
is entirely a question of who receives pointers, never of who can decrypt.

each item is grown TWICE, as /item/[id]/head and /item/[id]/body. an index
entry names the prefix and is therefore NOT keenable as it stands: a reader
appends /head or /body. heads are fetched eagerly on arrival, bodies only
on %open, so tailing a writer costs the size of their titles rather than
the size of their prose.

## What This Buys

revocation is free. evicting someone is not growing to their path again.
no re-keying, no new address for anyone else, nobody else notices.

leaks are attributable. every member reads a different address, so a
circulating subscription path names exactly one ship.

membership and publication are decoupled from the network. adding a member
is one poke, once, ever. after that, publishing to a thousand-member list
sends no messages at all — it is a thousand %grows into our own gall state,
and the members' parked keens do the rest.

the exposure this does NOT cover: a member who leaks a body address rather
than their index address. bodies are shared across members, so that leak is
anonymous. catching it would mean a copy per member per post.

## No Subscription Protocol

a %keen for a revision that has not been grown yet parks in ames and fires
when it is. the outstanding keen IS the subscription: durable across
restarts, one @ud of state, nothing to negotiate. backfill and tailing are
the same code path — start at revision 1, existing revisions answer from
cache, the first one that does not parks, and you are subscribed.

ames carries exactly two things, both once per relationship and never per
post: %announce (are you running %keep) and %invite (here is your address
for my list). everything else is remote scry.

## Signed authorship

`head` carries `who`, `lyfe`, `hash` and `sig`. `id` is `(sham +sain)` over the
head's other fields, and `sig` signs that id, so:

- a head verifies alone — `hash` commits to the body, so a mirror cannot pair a
 genuine signature with a fabricated title
- one signature covers title and body; two independent ones would let a mirror
 splice head-A onto body-B, each validly signed
- the id no longer depends on the address, so a hosted copy is the *same*
 object at a second location

Verification runs when a body lands — i.e. on click — not per head on arrival.
A forged title costs a click to discover; the alternative is a jael scry per
headline on every index revision.

`%keep` hosts rather than points: it fetches, verifies, and re-grows the head
and body byte-identical under our own `/item/[id]`. That is what survives the
author going offline, since relays forward packets but do not answer from cache.
