# keep — tests

    node tests/run.mjs              everything: A, B, C
    node tests/run.mjs pure         one layer (pure | single | multi)
    node tests/run.mjs --list       the manifest
    node tests/bake.mjs             RE-BAKE after any change to desk/ or tests/

Nothing runs off-ship. Even the pure tests execute inside a booted pier, via
`mcp/run-tests`.

## The three layers

**A — `pure/`.** Test arms, run by `mcp/run-tests`. No bowl, no scry, no
network.

- `sain.hoon` — `+sain`, the id every signature is taken over. One arm per
  field, each showing the id move, because a head has to verify alone.
- `core.hoon` — `lib/keep-core`: the salted per-member spur, the public index
  address, slug derivation and collision avoidance, `by-date`. Gating is
  entirely a question of who receives a pointer, so the pointer's derivation is
  the whole story.
- `view.hoon` — the parts of `lib/keep-ui` that are a contract rather than a
  look: read-url segment order, author attribution on a hosted copy.

**B — `ted/b-jael.hoon`.** One thread, run by `dojo/run-thread`. A thread gets
a real bowl, so `our`, `now` and every `.^` work. It signs with our own vein
key, verifies against our own `%deed` pass, then shows the same signature
failing over a swapped body and a swapped title — and that jael answers for a
ship we have never contacted, which is what makes a stranger's head judgeable
at all.

**C — `multi/`.** Earth-side scenarios driving two ships over MCP.

- `c1-follow` — the public path: grow `/index`, keen, head eagerly, body on
  click, verdict `%.y`.
- `c2-gating` — a gated list, and eviction as three beats: delivered,
  withheld, delivered again.
- `c3-forgery` — a spliced head from a peer running different code.
- `c4-announce` — installing keep next to `%pals` wires both directions with
  no `%sub` from anybody. **Destructive, and runs last.**

## Why forgery needs a rogue agent

An honest `%keep` cannot be made to distribute a bad pointer: `+fan-out` and
`+mirror` only ever publish `[our (base first) item-spur]`, and `+base` pins
the agent name, so a reader only ever fetches from `%keep` on the author's
ship. The only forgery worth testing is therefore a peer running different
code.

`tests/app/rogue.hoon` is that peer — a small agent that grows head/body pairs
at the same namespace shape, either matching or spliced (a real signature over
a head whose `hash` names a body other than the one served). It is deliberately
absent from `desk.bill`; `bake.mjs` starts it with `|rein`.

`~zod` reaches it through `%keep`, the syndicate action, which takes an
arbitrary entry. So C3 asserts both halves: the verdict, and that a forgery is
never re-hosted under our own name.

## Constraints — do not rediscover these

- **`+mule` has a null scry gate.** `mcp/run-tests` fires arms inside `+mule`,
  so no test arm can `.^`. That is why layer B is a thread, and why
  `mcp/scry-agent` never works at all.
- **A thread is a gall agent**, and gall cannot re-enter itself: no `.^ %gx` on
  an agent from inside a thread.
- **Eyre cannot read keep's state.** `on-peek` answers `noun` marks and
  `%keep-update` has no `+json` arm, so neither `/~/scry` nor the channel API
  can render either one. Assertions go through the dojo — `harness.mjs` wraps
  the common reads as `verified`, `forged`, `tails`, `follows`, `holds`.
- **A blocking `.^` does not crash, it waits.** Jael's `%deed` blocks for an
  unknown ship or a life it does not hold, and spider will sit there. Hence the
  5-minute timeout on every MCP call: a hang surfaces as `B ERROR` rather than
  a suite that never ends.
- **Never sleep a fixed delay.** Remote scry is async with no completion
  signal. Poll to convergence (`until`), and hold a window when asserting that
  something did *not* arrive (`stays`).
- **A lost response is not a lost write.** Eyre drops responses on slow
  commits; `commit()` re-drives and reads the truth from the retry.
- **Layer C shares one mutating fleet.** Scenarios tag their fixtures with
  `Date.now()` rather than assuming an empty ship, and `run.mjs` declares an
  order rather than globbing.

## What the desk had to expose

Two `on-peek` paths were added for the suite, both read-only views of state the
agent already held:

- `/x/checked` — the `(unit ?)` verdict. Without it a test can only see
  `read-page`'s warning, which renders for `%.n` and not for `~` — so "no
  warning" proves *not forged*, never *verified*.
- `/x/follows` — tailing is mechanical, following is what puts a ship in your
  feed. C4.4 is the difference.

## Staleness

Two hops separate an edit from what a test ship runs, and skipping either gives
a green run against code you no longer have:

    desk/ + ui/  --./build.sh-->  dist/  --node tests/bake.mjs-->  golden/*/keep

`run.mjs` checks both before it starts and refuses to run. `--stale-ok`
overrides the second; there is no override for the first.

## The fleet

Its own, at `~/solarsystem/fleet/keep` — not the marketplace suite's piers.
Different `@p`, different ports, so both suites can run at once.

    fleet/keep/golden/{dev,lex}    baked by tests/bake.mjs, never by a run
    fleet/keep/run/{dev,lex}       disposable CoW clones, ports 8095/8096

`~dev` is the HOST — it publishes, owns lists, and judges. `~lex` is the PEER —
it reads, gets gated, and runs the rogue. Scenarios name them by role
(`h.HOST`, `h.PEER`), so re-pointing the fleet is one edit in `harness.mjs`.

**They must be GALAXIES.** A star routes to another ship via its sponsor, so
two stars under sponsors that are not themselves running cannot reach each
other at all — measured on an earlier `~marzod`/`~pindul` fleet, where a Clay
remote scry of guaranteed-present content timed out while both ships were
perfectly healthy locally. Galaxies route to each other directly.

Both ships need `%mcp` (the suite drives everything through it) and `%pals`
(`on-init` watches `[our %pals]`, `+targets` scries `%gu pals`, and C4 is
nothing but that path).

**Each ship's `+code` goes in `SHIPS` in `harness.mjs`.** Unlike the galaxies
the marketplace suite uses, these are not codes anyone has memorised — read
`+code` from each dojo once and paste it in. Login fails with a named error
until you do.

## Gaps

- `+sign-id`, `+pass-of`, `+sound` and `+judge` are still inside
  `app/keep.hoon`, so layer B tests the primitives they are built from rather
  than the arms themselves. C3 covers their behaviour end to end; a unit-level
  test of `+sound`'s four clauses would need them lifted into the lib too.
- C3's forgery is the hash-mismatch clause. A head whose *signature* is wrong,
  or whose claimed `lyfe` does not match, takes a different path through
  `+sound` and is not separately exercised.
- `+probe` (`/ask`) subscribes without following, the counterpart to C4.4's
  `/hey`. Nothing drives it.
