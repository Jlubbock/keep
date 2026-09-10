# %keep-mail — ship-side email, minimal scope

One agent on the keep desk. It holds the ship's relay key and its reader
list (imported from the writer's Substack CSV export, on the ship), and
mails a public post to that list **when the writer clicks mail on it —
never automatically**. The relay (keep-posting.com) holds the consent
record for every address under `solarsystem/keep-email-sending-policy.md`
and gates each send on it: a reader is mailed only after clicking a
confirmation link the relay sent them. The ship never decides who is
mailed; the relay never holds the list.

Status: BUILT (2026-09-05); consent gating and the one-click UX 2026-09-09.
Everything below matches the implementation.

## Footprint

- `desk/sur/keep-mail.hoon` — types
- `desk/app/keep-mail.hoon` — the agent
- `desk/lib/keep-mail.hoon` — csv sieve, subjects, the relay's urls and answers (pure; layer-A tested)
- `desk/lib/md-html.hoon` — the tame markdown subset into html, for bodies
- `desk/mar/keep-mail-action.hoon` — noun mark, desk convention
- `desk/desk.bill` — `%keep-mail` added
- `%keep`: one `on-peek` arm `[%x %audience @uv ~]` → `(unit (set lyst))`,
  plus the UI below
- `tests/pure/mail.hoon` — sieve/subject/url/answer/renderer arms
- `tests/multi/c8-mail.mjs` — the send state machine against a relay stub

## Types

    +$  addr     @t                        ::  lowercased email address
    +$  config   [relay=@t key=@t]         ::  relay is the BASE url; '' = keep-posting.com
    +$  readers  [confirmed=(set addr) pending=@ud as-of=@da]   ::  the relay's view
    +$  proof    [token=@t verified=(unit @t)]                  ::  ownership of the source publication
    +$  action
      $%  [%config =config]
          [%name name=@t]                  ::  the sender readers see
          [%import raw=@t url=@t]          ::  a substack csv, and the page holding our token
          [%remove =addr]
          [%send =id:keep again=?]         ::  the click
          [%refresh ~]                     ::  ask the relay who confirmed (when stale)
          [%verify url=@t]                 ::  ask the relay to find our token at url (the badge)
          [%reset ~]                       ::  reopen the import card
      ==

    state: config, name, subs=(map addr @da), view=(unit readers), asked=(unit @ud),
           relayed=(unit @t), proof=(unit proof), checked=(unit @t), trouble=(unit @t),
           sent=(map id [wen n lost]), flight=(map id [round tries job again sent of]),
           queue=(list [id tries again]), dead=(map id why)

The relay url is BAKED INTO THE DESK (`default-relay` in /lib/keep-mail);
only the key is required. An explicit relay is an override (which is how
`c8-mail` points the ship at its stub). A `%3` state whose relay was the
send endpoint itself is migrated by stripping `/api/mail/send`.

## Behavior

- **No watch on `%keep` `/updates`, no trigger of any kind.** Mailing is
  `[%send id]`, poked by the writer.
- On `%send`: configured? id not sent/in-flight/queued? Scries `%keep`
  `/audience` (must hold `%public` — a gated post mailed to an Earth list
  is a leak) and `/posts` for the item. Then three hops on one round:
  1. `GET /api/mail/readers` — who confirmed. Every confirmed address the
     ship lacks is **merged into subs**: a reader who confirmed through
     the subscribe form on our page is on our list from this moment.
  2. `POST /api/mail/send` with `patp`, the post `id`, `again`, subject,
     text, html, and **`to` = the whole list**. The relay answers `202`
     with a `job`, `recipients` (how many it will mail), `dropped`
     (malformed, unsubscribed, bounced: **pruned from subs forever**) and
     `unconfirmed` (no consent record yet: kept, not mailed).
  3. A behn tick polls `GET /api/mail/jobs/<job>` (~s10, then every ~m2)
     until `done` (settles `sent`) or `failed` (the relay's reason is
     surfaced and the post marked `dead`). `recipients: 0` is not a
     mailing: the flight is dropped and the verb stays.
- A round stamps its event time into the flight and into every wire, so a
  response from an earlier round cannot touch the post's accounting — it
  can only still prune an address the relay dropped.
- On the send call: 0 (%cancel), 429 and 5xx queue the post for a behn
  retry in ~m30 — except a 429/503 with `Retry-After` (seconds; capped at
  ~d1), which sets the timer instead. A retry starts again from hop 1.
  **Everything else (401 bad key, 403 the writer may not send, 422
  systemic, any surprise) hard-fails and is surfaced to the writer** —
  nothing was delivered, so a post must never read `%sent` off one. Give
  up after 5 failing rounds. `again` rides in the flight and the queue so
  a retried re-mail is still a re-mail at the relay.
- `%send` with `again=%.n` on an already-sent id is a no-op — a stale tab
  re-POSTing the form cannot double-mail. `again=%.y` (dojo-only, on
  purpose) re-mails, and tells the relay so (its jobs are otherwise
  idempotent on the post id).
- `%import raw url` takes the raw file: per line, split on commas,
  unquote, trim, lowercase, keep every cell that reads as an address —
  that is the ship's list. In the same click the file is **handed to the
  relay** as `POST /api/mail/import {source_url, csv}`; the relay only
  accepts Substack's own export and mails each accepted address exactly
  once, 500 a day. `asked` holds its count and the card reads "Done. N
  readers will be asked over the next D days"; a refusal lands in
  `relayed`. Addresses the relay refuses stay on the ship and are simply
  never mailed. `%reset` reopens the card. A single address typed into
  the "add" box on the mail page goes down the same path: onto the ship's
  list, and to the relay, which accepts a bare list as a `manual` import
  and asks each address once (2026-09-10).
- **Ownership proof is a badge, not a gate** (2026-09-10). The relay
  records whether the source was verified but does not require it
  (`REQUIRE_PROOF` in the relay's `imports.py` flips that back on).
  `%verify url` asks the relay to find the ship's token at that page; the
  page shows "✓ verified on Substack" or the reason it could not, in
  `checked`. An import given a url runs the check beside it, not ahead of
  it.
- **A relay that rejects the key** (401/403 on the readers or token
  fetch) puts a sentence in `trouble`, which the email section shows in
  place of "Email is set up"; a 2xx clears it.
- `%name` sets the sender readers see and tells the relay
  (`POST /api/mail/profile`). `%refresh` fetches who confirmed and the
  proof token, but only when the view is older than a minute: the mail
  page fires it on every load, so there is no refresh button. There is no
  manual "add a reader": an address nobody confirmed is inert anyway.
- **No unsubscribe on the ship.** The relay appends its own footer and
  RFC-8058 headers per recipient; an unsubscribed or bounced address comes
  back in `dropped` on the next send naming it, which prunes it here.
- keep-onboard **acks its config POST by reading the key back off
  `/keep/mail`** — it rides in a hidden `data-key` attribute, never shown;
  keep it there. The writer never sees a key: keep-onboard pushes it at
  claim time and retries every ten minutes until the page shows it. Key
  rotation is relay-side and admin-only.
- Eyre at `/keep-mail`: nothing is served unauthenticated; the single
  route is `POST what=config`, keep-onboard's provisioning hook. It takes
  `key` ONLY: a forged cross-site POST must not be able to repoint the
  relay at an address collector. `relay` is set from the dojo and survives
  a key re-POST: `:keep-mail &keep-mail-action [%config [relay key]]`.
  Every form POST on the desk also passes `same-origin` in /lib/keep-core.
  Peeks: `/x/status` (what the UI renders), `/x/subs`, `/x/view`,
  `/x/sent`, `/x/queue`, `/x/flight`, `/x/proof`, `/x/config`. The key is
  readable on purpose. A leaked key gets revoked at the relay, not hidden
  on the ship.

## The UI (in %keep)

- **Mail on publish.** The editor shows "email this to N readers"
  (unchecked) once mail is set up and N > 0; publishing with it checked
  pokes `%mailpost`, which is `%post` plus the `%send`. The read page
  keeps the verb for older posts: `✉ email this`, with a confirm stating
  the count. Once sent it is a tag: `✉ sent to 41 readers · 1 bounced`.
  In flight: `✉ sending to 42 readers · 12 sent`; queued: `Keep is busy —
  will send shortly`; failed: the relay's reason in the writer's words
  (`why-of` in /lib/keep-mail) and the verb back as `email this`. Not
  configured, nobody confirmed, gated, or the agent absent: nothing renders.
- The writer's own post list tags mailed posts with a small `✉`.
- The public page carries no subscribe form (removed 2026-09-10). The
  relay's own page at `<relay>/subscribe/<patp>` still takes readers;
  `subscribe` in the status is the url to link to.
- `/keep/mail` (nav: mail): three sections — email ("Email is set up" or
  "connects on its own once your ship is claimed", plus the name readers
  see, or the relay's complaint about the key); readers ("N readers · M
  waiting", one line on how a reader gets in, the list inline with a ×
  per row when under 200, else a link to `/keep/mail/readers`); moving
  from substack (upload, or done; the optional "verified on Substack"
  badge beside it). No key, no paste box, no refresh button, no
  add-by-hand.

## The relay contract (this is live today)

    POST <relay>/api/mail/send
    Authorization: Bearer <key from config>
    {"patp": "~full-name", "id": "0v...", "again": false,
     "to": ["reader@example.com", ...],          // the whole list, up to 20000
     "subject": "Post title", "text": "markdown", "html": "<div>...</div>"}

- `202 {"job", "recipients", "dropped": [{"to","reason"}], "unconfirmed": [...]}`.
  A repeated `id` returns the job already made unless `again` is true.
- `GET <relay>/api/mail/jobs/<job>` → `{"status": "queued"|"sending"|"done"|
  "failed", "requested", "sent", "failed", "queued", "error"}`. A job held
  by the writer's daily quota stays `sending` across days; keep polling.
- `GET <relay>/api/mail/readers` → `{"active": [...], "pending", "subscribe_url", "manage_url"}`.
- `GET <relay>/api/mail/import/token` → `{"token", "verified_url", "verified_at"}`;
  `POST .../import/verify {"source_url"}` → `{"ok", "token", "verified_url"}`;
  `POST .../import {"source_url", "csv"}` → `{"import_id", "rows", "pending", "dropped": {...}}` or `422 {detail}`.
- Errors, all JSON `{"detail": "..."}`:
  - `422` — malformed (missing field, oversized, `to` not a list). Hard-fail.
  - `401`/`403` — bad or rotated key, `patp` mismatch, no writer account
    behind the ship, or the writer suspended for bounce/complaint rates.
    Hard-fail; the detail says which.
  - `503` + `Retry-After` — the relay's kill switch or an account freeze.
  - `429` — rate; carries `Retry-After`.
- The From address (`"Writer Name" <post@<sub>.keep-posting.com>`, any
  name the writer publishes under), the Reply-To (the address the writer
  signs in to keep-posting.com with), the fixed footer ("You subscribed
  to [Writer] on Keep" + unsubscribe) and the List-Unsubscribe headers are
  all the relay's. The ship sends the bare body.
- Size limits (422 past any): subject ≤500 chars (ours caps at 78),
  text ≤512KB, html ≤1MB.

## Provisioning (context, not desk work)

Earth already holds a per-ship key and domain. After the desk installs,
keep-onboard logs in with `+code`, learns the ship's real name off the
authenticated `/~/name`, and POSTs `what=config&key=` to `/keep-mail`
(relay is baked in; nothing else is a form field). A domain rename is
relay-side only and does not touch the ship. Or the writer skips onboard
entirely and pastes the key at `/keep/mail`. **The CSV import is not
keep-onboard's job**: the writer uploads it at `/keep/mail`, and the ship
hands it on.
