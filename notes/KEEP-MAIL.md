# %keep-mail — ship-side email, minimal scope

One new agent on the keep desk. It holds the ship's email config and its
subscriber list (imported from the writer's Substack CSV export, on the
ship), and mails a public post to that list **when the writer clicks mail
on it — never automatically**. Nothing else.

Status: BUILT (2026-09-05). Everything below matches the implementation;
where it differs from the original sketch, the difference is called out.

## Footprint

- `desk/sur/keep-mail.hoon` — types
- `desk/app/keep-mail.hoon` — the agent
- `desk/lib/keep-mail.hoon` — csv sieve, subjects (pure; layer-A tested)
- `desk/lib/md-html.hoon` — the tame markdown subset into html, for bodies
- `desk/mar/keep-mail-action.hoon` — noun mark, desk convention
- `desk/desk.bill` — `%keep-mail` added
- `%keep`: one `on-peek` arm `[%x %audience @uv ~]` → `(unit (set lyst))`,
  plus the UI below
- `tests/pure/mail.hoon` — sieve/subject/renderer arms
- `tests/multi/c8-mail.mjs` — the send state machine against a relay stub

## Types

    +$  addr    @t                        ::  lowercased email address
    +$  config  [relay=@t key=@t]

The relay url is BAKED INTO THE DESK (`default-relay` in /lib/keep-mail):
a config with `relay=''` means keep-posting.com. Only the key is required;
an explicit relay is an override (which is how `c8-mail` points the ship
at its stub). `from` and `site` are gone (2026-09-07): the relay derives
From from the key, and the footer `site` was for no longer exists.
    +$  action
      $%  [%config =config]
          [%import raw=@t]                ::  a substack csv, or bare addresses
          [%remove =addr]
          [%send =id:keep again=?]        ::  the click
      ==

    state: config=(unit config), subs=(map addr @da),
           sent=(map id:keep @da), flight, queue, dead, imported

## Behavior

- **No watch on `%keep` `/updates`, no trigger of any kind.** The sketch
  had the agent mail every `%posted`; that made a Substack archive import
  (`%backpost` → `%posted` each) a mass-mail, and made publishing itself
  irreversible. Mailing is now `[%send id]`, poked by the writer.
- On `%send`: configured? subs non-empty? id not sent/in-flight/queued?
  Scries `%keep` `/audience` (must hold `%public` — a gated post mailed to
  an Earth list is a leak) and `/posts` for the item. Subject from `title`,
  falling back to the first line; text = the `%md` page; html via
  `/lib/md-html`; unsubscribe footer per recipient.
- **One POST per 50 readers** (batched 2026-09-07; the relay fans out one
  personalized mail per address and answers with a verdict per address).
  A round stamps its event time into the flight and into every wire, so a
  response from an earlier round cannot touch the post's accounting — it
  can only still prune an address the relay dropped. The queue holds
  *addresses still unsent*; a `sent` address is never re-sent.
- Responses: a batch is 200 with `sent` / `dropped` / `retry` lists —
  `dropped` leaves subs forever (malformed, unsubscribed at the relay,
  hard-bounced: the entire suppression sync), `retry` joins the queue ·
  429/5xx/%cancel queue the whole call, behn retry in ~m30 — except a
  quota 429, whose `Retry-After` (seconds to the UTC-midnight reset, capped
  at ~d1) sets the timer instead · **everything else (400, 401 bad key,
  422 systemic, any surprise) hard-fails and is surfaced to the writer** —
  nothing was delivered and no recipient is at fault, so a post must never
  read `%sent` off one. Give up after 5 failing rounds. A retry
  re-intersects with current subs, so removals between tries stick.
- **No unsubscribe on the ship, at all** (removed 2026-09-07). The relay
  appends its own footer pointing at `keep-posting.com/unsubscribe/<token>`
  with RFC-8058 one-click headers, so the ship sends the bare body. The
  ship's old `/keep-mail/unsubscribe/[tok]` endpoint, `%unsubscribe`
  action, token arm and `salt` are gone: an unauthenticated GET that walked
  every subscriber hashing each one was a CPU sink anyone could hit, and
  no mail ever carried its link. A relay-unsubscribed address comes back
  in `dropped` on the next batch naming it, which prunes it here;
  deliberate re-subscribes need the relay's side for now.
- keep-onboard **acks its config POST by reading the key back off
  `/keep/mail`** — coordinate with the Earth side before hiding or moving
  the key on that page. Key rotation is relay-side; the old key's 401
  hard-stop is the writer's cue to paste the new one.
- `GET /api/mail/quota` (same bearer key) reports quota/used/remaining —
  unused by the desk today; a candidate for the mail page later.
- Size limits (422 past any): subject ≤500 chars (ours caps at 78),
  text ≤512KB, html ≤1MB.
- `%send` with `again=%.n` on an already-sent id is a no-op — a stale tab
  re-POSTing the form cannot double-mail. `again=%.y` (dojo-only, on
  purpose) re-mails.
- `%import` takes the raw file: per line, split on commas, unquote, trim,
  lowercase, keep every cell that reads as an address. One parser covers
  the Substack CSV, a bare list, and a comma paste; the header line is
  skipped silently, junk lines are counted and reported.
- Eyre at `/keep-mail`: nothing is served unauthenticated; the single
  route is `POST what=config`, keep-onboard's provisioning hook.
  It takes `key` ONLY: a forged cross-site POST must not be able to
  repoint the relay at an address collector. `relay` is set from the dojo
  and survives a key re-POST:
  `:keep-mail &keep-mail-action [%config [relay key]]`.
  Every form POST on the desk (`/keep` and `/keep-mail`) also passes
  `same-origin` in /lib/keep-core: eyre's cookie carries no `SameSite`
  (measured 2026-09-07: `Path=/; Max-Age=2592000`, nothing else), so
  Firefox and Safari would send it on a cross-site form. A browser header
  (`origin`, else `referer`) naming another host is a 403; no browser
  header at all is not a browser, and keep-onboard's POST still lands.
  Peeks: `/x/status` (what the UI renders), `/x/subs`, `/x/sent`,
  `/x/queue`, `/x/config`. The key is readable on purpose — shown on
  `/keep/mail` too. A leaked key gets revoked at the relay, not hidden
  on the ship.

## The UI (in %keep)

- The verb lives on the writer's own read page, with edit/delete: `✉ mail`
  (form → `what=mail`), with a confirm stating the count — "mail this to
  N readers? it cannot be recalled." Once sent it is a tag, not a control:
  `✉ mailed ~2026.9.5`. In flight: `✉ sending…` / `✉ retrying`. Dead:
  `✉ failed` + a `mail again` verb. Not configured, no readers, gated, or
  the agent absent: nothing renders.
- The writer's own post list tags mailed posts with a small `✉`.
- `/keep/mail` (nav: mail): three labeled sections — relay, readers,
  remove — sentences in the serif, one action per row. The CSV import
  (app.js reads the file client-side and posts it as an ordinary form
  field — no multipart), last-import receipt, remove-by-address.
- The full address list renders only on `/keep/mail/readers` ("show the
  list"), sorted, each row dated with a × remove — the lists-page idiom:
  expanded by URL, so thousands of rows never ride along on the settings
  page.
- Unconfigured, the page says "get one at keep-posting.com, then paste it
  here" with a key input POSTing straight to `/keep-mail`. The relay
  defaults, so pasting a key is the whole setup.

## The relay contract (this is live today)

    POST https://keep-posting.com/api/mail/send
    Authorization: Bearer <key from config>      (the ship's email key)
    Content-Type: application/json

    {
      "patp":    "~santyv-lapryt-pasreg-danduc--diflup-socsec-witdus-binzod",
      "to":      ["reader@example.com", ...],    // always a list here, max 50
      "subject": "Post title",
      "text":    "plain-text body",              // required
      "html":    "<div>...</div>"                // optional
    }

- `patp` is the ship's **full** name, `~` optional. It must match the ship
  the key belongs to or the call is refused — send it always.
- The **From address is derived server-side** from the key
  (`~full-patp <post@<the ship's email domain>>`). The ship cannot set
  From; do not include one.
- A batch (a `to` list) answers `200` once processed, with per-recipient
  verdicts (relay handoff 2026-09-07):

      {"requested": 50, "sent": [...],
       "dropped": [{"to": "...", "reason": "invalid" | "unsubscribed"}, ...],
       "retry":   [{"to": "...", "reason": "..."}, ...],
       "quota_remaining": 150, "ok": true}

  Quota is checked up front against the sendable count (dropped cost
  nothing); over-quota is still a whole-call 429 with `Retry-After`.
  The single-recipient form (`to` a string) still answers as before:

      {"ok": true, "from": "~... <post@name.keep-posting.com>",
       "patp": "~...", "recipients": 1, "quota_remaining": 190,
       "message_id": "01000..."}

- Errors, all JSON `{"detail": "..."}` (revised 2026-09-07):
  - `422` — request malformed, no recipient at fault (missing field,
    oversized body, over 50 addresses). Systemic: hard-fail the send.
    The 50 is the relay's `MAX_RECIPIENTS` and `batch` in /lib/keep-mail;
    `GET /api/mail/quota` reports it as `max_recipients`.
  - `401`/`403` — bad or rotated key, or `patp` mismatch. Hard-fail.
  - `429` — quota or rate; carries `Retry-After` (seconds to the
    UTC-midnight reset). **200 recipients per ship per day.**
  - `502` — SES refused on the relay's end. Retryable, bounded.
- No idempotency key: a retried batch re-sends. Only retry recipients that
  returned 429/5xx, never 2xx.
- No per-key call-rate cap; a 300-reader send is 6 calls. SES throttling
  on the relay's side comes back per address in `retry`.

## Provisioning (context, not desk work)

Earth already holds a per-ship key and domain. After the desk installs,
keep-onboard logs in with `+code`, learns the ship's real name off the
authenticated `/~/name`, and POSTs `what=config&key=` to `/keep-mail`
(relay is baked in; nothing else is a form field). A domain rename is
relay-side only (From derives from the key) and does not touch the ship.
Or the writer skips onboard entirely and pastes the key at `/keep/mail`.
**The CSV import is not keep-onboard's job**: the writer uploads it
themselves at `/keep/mail`.
