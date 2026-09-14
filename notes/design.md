# keep — design

The conceptual model, moved out of `app/keep.hoon` when the inline prose was
stripped. Updated for signed authorship (`%4`); see git history for the v0 text.

## One Primitive

a list is a set of ships. every list holds an index: a list of pointers,
grown one revision per entry, each revision carrying the whole list so far.

    %public   index lives at /[nonce]/index. no members, no push.

    anything  index lives at /list/[name]/[nonce]/index, ONE address, inside
    else      a gall coop (%germ). gall serves everything under the coop encrypted
              with the coop's key, and before answering any remote read it
              asks our on-peek (care %c, /list/[name]/[ship]) whether that
              ship is on the roster. the coop, not the address, is the
              capability.

a public body lives once, hash-addressed at /item/[id], id = (sham [head
page]). a gated post is tended into each list's coop as a copy at
/list/[name]/item/[id] — a copy per LIST, never per member — so a member of
one list cannot name the address another list reads, and the bytes of a
gated post never travel in the clear.

each copy is grown or tended twice, as .../head and .../body. an index entry
names the prefix and is therefore NOT keenable as it stands: a reader
appends /head or /body. heads are fetched eagerly on arrival, bodies only
on %open, so tailing a writer costs the size of their titles rather than
the size of their prose.

a reader keens secret exactly when the path is under /list: gall fetches
the coop key from the writer (a plea, answered by the writer's gall after
the %c peek) and then reads. a non-member gets an empty %sage, the same
answer as "nothing there".

the nonce is minted once per install of %keep. gall keeps a nuked agent's
revision counters forever, so a reinstalled writer that grew /index again
would start at N+1 while every reader starts at 1 and waits for a
revision that never comes. a fresh nonce is a fresh path with fresh
counters. the price is that no address is derivable any more: a reader is
TOLD where a writer's index is, and never guesses.

## What This Buys

the wire carries ciphertext. a forwarding star, a galaxy or anyone on the
route sees which ship read from which, and nothing else — not the list,
not the post, not the address. before coops every one of those was
readable in flight, and an observed address could be fetched by anyone.

publishing to a list is one %tend, whatever its size. adding a member is
one poke, once, ever. the member's parked keen does the rest.

revocation is a roster change plus a %germ, and a %germ is not free for
the members who stay: a keen parked under the old key is never answered,
so every remaining member is re-invited and re-keens from where it was.
the evicted ship's keen stalls the same way and nobody re-invites it; a
later %admit does, which is how re-admission backfills.

the costs, named so nobody rediscovers them: gall does not cache coop keys,
so every secret keen is a plea to the writer first. a list of N readers
costs the writer N acked pleas per revision, where the old per-member
addresses cost it none. and every member holds the same key, so a leaked
key opens the list until the next %germ, where a leaked per-member address
used to name exactly one ship.

## Deletion

deleting is growing every index the post was in again, without it, and
tombing every copy: `/item/[id]` if it was public, `/list/[name]/item/[id]`
in each list it went to.
a revision carries the whole log, so a reader diffs the one that lands against
what it walled from that feed and drops what is missing. no delete message, no
per-post state, nothing to negotiate — a follower that is offline for a week
learns about the deletion from the next revision it reads.

what that reaches, and what it does not:

- our own index, our own copy, our own url on the open web: all gone.
- a follower's feed: the row goes when the next revision lands.
- a follower's cached head and body: kept. they read it already, and a reader's
  cache is not ours to empty.
- a REPOST: untouched, by construction. `+mirror` re-grew the bytes under the
  reposter's own `/item/[id]`, so their copy is a second original with a second
  address. deleting ours cannot reach it, and a reader who follows them keeps
  seeing it — attributed, still signed by us, still verifying.

that last one is the whole trade. hosting means the author cannot unpublish
what someone else chose to keep; the same property that survives the author
going offline survives the author changing their mind.

## No Subscription Protocol

a %keen for a revision that has not been grown yet parks in ames and fires
when it is. the outstanding keen IS the subscription: durable across
restarts, one @ud of state, nothing to negotiate. backfill and tailing are
the same code path — start at revision 1, existing revisions answer from
cache, the first one that does not parks, and you are subscribed.

ames carries four things once per relationship: %announce (I run %keep,
and my index is at this address), %invite (here is the address of my
list), and %follow / %unfollow (I read your index — so the author can see
who follows, which remote scry never tells them). everything else is
remote scry, plus the coop key plea gall makes before each secret keen.

every %follow is answered with an %announce, so following is: tell the
writer, and tail whatever address comes back. an %announce or %invite
whose address replaces one of the same kind from the same writer — its
index, or the same list — is taken in place of the old one, no %accept.
that is how a reinstall on the writer's side heals: readers re-send
%follow to everyone they follow on every load and once a day, and the
writer's fresh install answers with its new address. until then a reader
parked on the old address simply sees nothing new.

a parked keen does not survive the reader's own agent being reloaded
either, so every load re-issues every tail from the revision it holds,
and an %announce for an address already held re-issues that one. a
duplicate keen parks beside the original and costs nothing.

an %invite for a list we already read is "ask again": the reader re-keens
the revision it is on. that is how re-admission after an eviction resumes.
an %invite whose address is under a coop, from a writer we still read at a
per-member address, is a re-address from before %8: taken without an
%accept, and the old addresses are dropped.

%follow and %unfollow ride an unacked wire. a %keep older than 2026-09 nacks
them, and a nack from those must not read as "not running %keep". a ship
answers a new follower it already follows with its own %follow, once, so a
pair that upgraded in either order ends up knowing about each other.

both are pokes any ship can send, so neither may subscribe us on its own.
%announce is ignored unless the sender is a pals target. %invite parks in
`pending` and does nothing until %accept: without that, an invite is an
unbounded write into a stranger's feed, and comets are free. %accept is
where the keen starts and where the sender enters `follows`; %reject just
drops the offer, and a re-invite may be sent.

## Substack identity

The publications a ship syncs are the ones it claims. `%keep-sync` grows
their urls as a set at `/substack` — the same remote-scry shape as an index,
so a reader who opens the ship's page keens revision 1 and tails from there.
What the reader does with a url is its own business: it fetches `<url>/about`
and looks for the claiming ship's `@p` in the page, as a whole word. The
verdict is cached per claim for a day, rechecked on the next page view after
that, or on demand.

There is no verifier because there is nothing to verify centrally: the about
page is public, and every reader can fetch it. A ship that trusts a friend's
verdict over its own can ask them; the agent never will. Untracking regrows
the set without that url, which drops the badge on every reader whose keen is
parked.

Verification gates nothing. The scan that precedes a track also reads the
about page, and a publication that does not name the ship is offered "sync
anyway" beside the line to paste; a ship that was already syncing when this
arrived is claimed on upgrade, and checked, without anyone re-entering it.

What this proves is control of the publication's about page, not authorship
of its posts, and only for as long as the line stays there.

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
