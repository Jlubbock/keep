# keep — internal linking

Linking from one keep post to another, in prose: pick a post while writing,
get a link a reader can follow — in the app, across ships, and on the
clearnet copy.

## What the protocol already gives us

An internal link needs no new protocol. A post is addressed by
`/keep/read/[id]/[ship]`, and that URL already does the whole job on the
reader's side:

- local post: served from `posts`
- remote post already seen: served from `seen`
- remote post never seen: the handler emits `fetch-body` and the page
  polls until the keen lands

So a link is just a relative markdown link whose href is a read URL. The
renderer (`href()` in `app.js`) already passes scheme-less URLs through
untouched. **The stored markdown stays 100% standard** — no wikilink syntax
in published bodies, no new mark, no `sur` change, no state migration,
nothing new over ames.

## Constraints that shape the design

1. **The agent is content-blind, by rule.** "The agent never parses content
   — it does not know what a `page` contains and must not learn"
   (HANDOFF, do-not-change list). So the agent can neither resolve links,
   extract backlinks, nor police what a post links to. Everything about
   links happens in the editor and the renderer, i.e. in `app.js`.

2. **A pointer to a gated post IS the capability.** Gating is unguessable
   addresses, not encryption; remote scry is unauthenticated. Writing
   `/keep/read/[id]/[ship]` of a gated post into a public post hands every
   reader the address, and the body answers to anyone who has it. The
   agent cannot check this (see 1) — the *editor* must warn.

3. **Edit changes the id.** Edit is delete + repost; the old `/item/[id]`
   is tombed. So an id-addressed link breaks when its target is edited.
   The public *slug* is stable across edits that keep the title (delete
   frees the slug, the re-post reclaims it), so clearnet links routed
   through slugs survive edits; in-app id links do not. This is the same
   revision semantics as reposts and deletion — accepted, not fixed.

## Design

### Authoring: `[[` picker, standard link out

In the editor, typing `[[` opens an autocomplete over linkable posts.
Picking one **inserts a finished markdown link** into the source:

    [The title](/keep/read/0v3.abc../~sampel-palnet)

No wikilink survives into the stored body. This sidesteps the resolution
problem entirely: if `[[Title]]` were published raw, a *reader's* renderer
would have to map title→id and can't. Compiling at insert time also kills
title-ambiguity bugs (two posts, same title) — the author picked a concrete
target and the source records it.

Fallback: any `[[...]]` still present at publish is compiled best-effort by
title lookup against the same candidate set (most recent wins); an
unresolvable one publishes as literal text. Manual typists are served,
nothing is silently dropped.

**Candidates** are embedded in the write page by the agent (which knows its
own `posts` and the `heads` it has fetched — metadata it already holds, not
content parsing):

- own posts: title, id, our ship, `pub` = fanned on `%public`
- walled posts with a head: title, id, `ship.entry` (the ship that serves
  it, not the author — that is the address we know answers), `pub` =
  `from-public`

Emitted as hidden nodes with data attributes (sail-friendly, no JSON in
hoon needed on this page), date-descending.

### The leak guard

When the post's audience is `everyone` and the source contains a read URL
whose target candidate is non-public — or a read URL for an id we can't
classify — publish stops on a `confirm()` naming the risk: *"this post is
public and links a gated address; everyone who reads it can fetch that
post. publish anyway?"* Mirrors the server-side
`%keep-would-expose-gated-address` stance for `%keep`, enforced in the only
place that can see content. It is a warning, not a wall: the author may
know better (e.g. the target is someone else's public post we only ever
received privately).

### Rendering

`md()`/`inline()` need no parsing changes. After paint, one pass over the
anchors:

- any href matching `^/keep/read/` gets a `k-internal` class, styled apart
  from web links.
- the href is rewritten against the page's actual mount. The stored form is
  canonical (`/keep/read/[id]/[ship]` — identity only, no mount), because
  the same body paints at different depths: under hawk the app lives at
  `/hawk/keep/...`, on a bare ship at `/keep/...`, and the clearnet slug
  page at `/keep/[slug]`. A baked-in relative href cannot serve all three.
  The mount is `location.pathname` up to and including the first `keep`
  segment; internal links become `<mount>/read/[id]/[ship]`. Stored bytes
  stay client-agnostic; resolution is a paint-time concern.

### Cold reads must fetch the head

Today the `/keep/read` handler emits `fetch-body` only; heads arrive via
index revisions. A post reached *only* by direct link has no index behind
it, so its head never arrives: no title, and — worse — `+judge` returns `~`
without a head, so the body renders **unverified with no warning**, and
nothing ever upgrades it. Once links make cold reads a first-class arrival
path, the read handler (and the `%open` poke) must emit `fetch-head`
alongside `fetch-body` when the head is missing; the existing `%head` arm
in `+on-arvo` already runs the late-verdict logic from there.

Comments render through the same `md()`, so internal links in comments
work with zero extra code (no picker in the comment box for now).

### Clearnet: the linkmap

A clearnet visitor who clicks `/keep/read/...` hits the login redirect.
Fix for the resolvable case: the agent maintains one more cached asset,

    /keep/linkmap        →  JSON { "0v3.abc..": "/keep/some-slug", ... }

covering exactly the public posts — the same `sites` map inverted, so it
leaks nothing (those ids already sit in the public index). It is cached
and uncached in the same three places as `index-card`: public `%post`,
`%delete`, `+on-load`.

On solo/public pages (detected by the absence of the app shell), `app.js`
fetches the linkmap after paint and rewrites matching `k-internal` hrefs
to their slugs. Result: same-ship public→public links work for anonymous
readers **and** survive edits (slugs are stable; the linkmap always maps
the *current* id, and the rewrite happens at read time). Links to other
ships' posts, or to gated posts, stay as read URLs — a login wall for
urbit-having readers, a dead end otherwise. That degradation is honest and
unfixable from our side: a ship's clearnet domain is not discoverable from
its `@p`, and its slugs live only in its own `sites` map.

`'/keep/linkmap'` joins `reserved` in `keep-core` so no slug can shadow it.

## Explicitly out of scope

- **Backlinks / linked mentions.** Requires parsing every body — the agent
  must not, and a client-side version over `seen` would be partial and
  misleading. Revisit only as a pure-client nicety if wanted.
- **Heading anchors** (`[[Title#section]]`).
- **Link-rot repair across edits.** An edited target orphans inbound id
  links, in-app. Same trade as deletion-vs-reposts; documented, not
  patched.
- **Decompiling `[Title](/keep/read/...)` back to `[[Title]]` when editing.**
  The editor already styles markdown links; round-tripping the sugar is
  cosmetic. Cheap to add later.

## Changes, by file

| file | change |
|---|---|
| `ui/app.js` | `[[` picker (input detection on active line, dropdown from candidate nodes, insert markdown link); publish-time `[[...]]` fallback compile; leak-guard confirm in the send handler; `k-internal` classing + mount rewrite after `paint()`/`talkPaint()`; linkmap fetch + slug rewrite on solo pages |
| `ui/style.css` | picker dropdown; `.k-internal` link style |
| `desk/lib/keep-ui.hoon` | `write-page` takes and emits the candidate list (hidden nodes, data attrs) |
| `desk/app/keep.hoon` | build candidates for `write-page` (from `posts`, `heads`, `from-public`, `fanned`); `linkmap-card` (enjs + `json-response:gen:srv`) cached beside `index-card` on public post, delete, and load; `fetch-head` on head-less cold reads in the `/keep/read` handler and `%open` |
| `desk/lib/keep-core.hoon` | add `'/keep/linkmap'` to `reserved` |
| `desk/sur/keep.hoon` | **no change** |
| marks, state, network | **no change** |

## Tests

- `multi/c7-linkmap.mjs`: publish public post on zod → unauthenticated
  GET `/keep/linkmap` contains id→slug; publish gated post → linkmap does
  NOT contain it (the negative needs the public one as its positive
  control); delete → entry gone; edit with same title → same slug, new id.
- cold-read verification: bus, following nobody, GETs zod's read URL for a
  post it has never walled → head and body both land, `checked` gains a
  `%good` verdict (positive control for the fetch-head change; today this
  path leaves the entry unjudged forever).
- `pure/view.hoon`: write-page renders candidate nodes; a gated own post
  carries `data-pub` false.
- The renderer/editor sides are JS and the suite has no JS runner; they
  stay covered by hand. (If that itches, the `md()` pipeline is the one
  piece worth extracting into a testable unit later.)

Re-bake (`node tests/bake.mjs`) after the desk changes, per the ledger.
