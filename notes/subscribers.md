# subscribers: email claims over gossip

A Substack writer moving to keep holds a subscriber CSV. A reader booting a
fresh urbit holds nothing but their email address. Neither knows the other's
`@p`. This feature closes that gap with one broadcast and one match.

## the claim

A reader types their address into the sync tab. The ship keeps the raw
address locally (`enrolled`), and gossips only

    +$  claim  [hash=@ux who=ship wen=@da]     :: sur/keep.hoon

where `hash` is `(shax email)` over the trimmed, lowercased address. The
hash is deliberately unsalted: every ship must derive the same hash from
the same address or nothing ever matches. The raw address exists in exactly
two places — the reader's own ship, and the `crew` of any writer who
imported it from their CSV.

## distribution

`%keep` is wrapped in ~paldev's `/lib/gossip` (vendored, with `lib/pals`,
`sur/pals`, `mar/gossip/rumor`), configured `[hops=2 hear=%anybody
tell=%anybody pass=|]` — pals-of-pals reach, no proxy-passing since the
claim's origin is the point. Claims arrive in `+on-agent` on the
`/~/gossip/gossip` wire; `+on-watch` on `/~/gossip/source` seeds every new
gossip edge with our own claim, so a claim made before an edge existed
still crosses it later. Reach is the pals graph: a ship with no pals
broadcasts to nobody, so onboarding should say "add a pal or two".

## the match

The writer pastes their CSV into the sync tab. `%import` keeps every
token containing `@` (lowercased, hashed) in `crew=(map @ux @t)`. Every
claim heard is remembered in `claims=(map @ux ship)`, matched or not, so
import order and claim order do not matter: a new import sweeps old
claims, a new claim checks the existing crew.

A match admits the claimant into a `%subscribers` list through the normal
roster machinery (`+enlist` mints it on first use) — same salts, same
capability paths, same `+welcome` invite. On the reader's side, an
incoming `%invite` for a list named `%subscribers` while `enrolled` is set
is accepted without asking, and the inviter is followed. That is the whole
autofollow.

## deliberately optimistic — the verification seam

v1 trusts the claim. Anyone who knows (or guesses) a subscriber's address
can claim its hash and be admitted; gossip relays could even alter a
claim's `who` in flight. This is accepted for now. The gate to close it
later is exactly one place: `+matched` in `app/keep.hoon` admits on
`(~(has by cc) h)` — a verified flag beside the crew row (or on the claim)
turns that into `has && verified` and nothing else moves. Candidate
verifiers, in rising order of effort:

1. **code in the newsletter footer** — a rotating token published to real
   subscribers through the newsletter itself; claim carries it. Verifies
   "receives the newsletter", zero infra.
2. **magic-code email** — the writer's ship mails a nonce to the claimed
   address over a transactional API (iris, writer's key only); the reader
   pokes it back. Verifies inbox ownership; needs an API account.
3. **DKIM proof** — the reader presents a raw DKIM-signed newsletter email;
   the writer's ship verifies the signature (key via DNS-over-HTTPS,
   RSA-verify via `fo`). Truly no-host; a lib of its own.

## known limits

- `claims` grows with every distinct hash gossiped in reach; entries are
  ~40 bytes and pals-scoped, so unbounded is tolerated for now.
- The gossip mark validator hard-casts (`;;`); a malformed `%keep-claim`
  rumor crashes that delivery event and is dropped. Annoying, not fatal.
- `%unenroll` stops future auto-accepts and re-seeding, but rumors already
  relayed cannot be recalled.
