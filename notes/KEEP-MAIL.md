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
- `desk/lib/keep-mail.hoon` — csv sieve, tokens, subjects (pure; layer-A tested)
- `desk/lib/md-html.hoon` — the tame markdown subset into html, for bodies
- `desk/mar/keep-mail-action.hoon` — noun mark, desk convention
- `desk/desk.bill` — `%keep-mail` added
- `%keep`: one `on-peek` arm `[%x %audience @uv ~]` → `(unit (set lyst))`,
  plus the UI below
- `tests/pure/mail.hoon` — sieve/token/subject/renderer arms

## Types

    +$  addr    @t                        ::  lowercased email address
    +$  config  [relay=@t key=@t from=@t site=@t]

The relay url is BAKED INTO THE DESK (`default-relay` in /lib/keep-mail):
a config with `relay=''` means keep-posting.com. Only the key is required;
an explicit relay is an override (which is how the test stub drives it).
    +$  action
      $%  [%config =config]
          [%import raw=@t]                ::  a substack csv, or bare addresses
          [%remove =addr]
          [%unsubscribe tok=@uvH]         ::  footer links land here
          [%send =id:keep again=?]        ::  the click
      ==

    state: config=(unit config), subs=(map addr @da), salt=@uvH,
           sent=(map id:keep @da), flight, queue, dead, imported

`site` was added to the sketch's config: the unsubscribe footer needs an
absolute URL for the ship's own eyre, and nothing else in state knows it.

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
- **One POST per recipient, not the relay's 50-a-call batching.** The
  unsubscribe token is per-address (`(sham [addr salt])`) and a shared
  body cannot carry it. Quota counts recipients, not calls, so nothing is
  lost. The queue therefore holds *addresses still unsent*, and a 2xx'd
  recipient is never re-sent (there is no idempotency key).
- Responses: 2xx done · 400 drops that address from subs (the relay named
  it malformed) · 401/403 kills the send and marks it `%failed` — config
  is wrong, retry can't help · 429/5xx/%cancel queue the remainder, behn
  retry in ~m30, give up after 5 tries. A retry re-intersects with current
  subs, so removals and unsubscribes between tries stick.
- `%send` with `again=%.n` on an already-sent id is a no-op — a stale tab
  re-POSTing the form cannot double-mail. `again=%.y` (dojo-only, on
  purpose) re-mails.
- `%import` takes the raw file: per line, split on commas, unquote, trim,
  lowercase, keep every cell that reads as an address. One parser covers
  the Substack CSV, a bare list, and a comma paste; the header line is
  skipped silently, junk lines are counted and reported.
- Eyre at `/keep-mail`: `GET /keep-mail/unsubscribe/[tok]` is
  unauthenticated and always serves the same page (tokens are not probes);
  authenticated `POST what=config` is keep-onboard's provisioning hook.
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
  defaults; `site` defaults to the Host header the writer is browsing on
  (scheme from eyre's `secure`), so pasting a key is the whole setup.

## The relay contract (this is live today)

    POST https://keep-posting.com/api/mail/send
    Authorization: Bearer <key from config>      (the ship's email key)
    Content-Type: application/json

    {
      "patp":    "~santyv-lapryt-pasreg-danduc--diflup-socsec-witdus-binzod",
      "to":      ["reader@example.com", ...],    // string or list, max 50
      "subject": "Post title",
      "text":    "plain-text body",              // required
      "html":    "<div>...</div>"                // optional
    }

- `patp` is the ship's **full** name, `~` optional. It must match the ship
  the key belongs to or the call is refused — send it always.
- The **From address is derived server-side** from the key
  (`~full-patp <post@<the ship's email domain>>`). The ship cannot set
  From; do not include one.
- Success `200`:

      {"ok": true, "from": "~... <post@name.keep-posting.com>",
       "patp": "~...", "recipients": 2, "quota_remaining": 190,
       "message_id": "01000..."}

- Errors, all JSON `{"detail": "..."}`:
  - `401` — missing/unknown key. Config is wrong; stop and surface it.
  - `403` — key belongs to an unclaimed ship, or `patp` mismatch.
  - `400` — missing to/subject/text, >50 recipients, or a malformed
    address (the detail names it). Drop the bad address and retry.
  - `429` — daily quota spent (**200 recipients per ship per day**, resets
    midnight UTC). Queue and retry after the reset; `quota_remaining` on
    successes lets the agent pace itself.
  - `502` — the upstream mail service refused (detail says why; while the
    relay's AWS account is in sandbox, unverified recipients do this).
    Treat as per-batch retryable, bounded.
- No idempotency key: a retried batch re-sends. Only retry batches that
  returned 429/5xx, never 2xx.

## Provisioning (context, not desk work)

Earth already holds a per-ship key and domain. After the desk installs,
keep-onboard logs in with `+code` and POSTs `what=config` to `/keep-mail`
with the key (relay is baked in; `from` and `site` optional — site falls
back to the request host) — and re-POSTs it if the writer renames their
domain. Or the writer skips onboard entirely and pastes the key at
`/keep/mail`. **The CSV import is not keep-onboard's job**: the writer
uploads it themselves at `/keep/mail`.
