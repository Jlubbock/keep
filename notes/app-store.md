# keep on the iOS App Store — checklist

Written 2026-08-03.

## Where the desk stands today

- the frontend is server-rendered hoon: `lib/keep-ui.hoon` emits manx, `+serve`
  in `app/keep.hoon` binds `/keep`, the docket carries `site+/keep` and no glob.
  `ui/app.js` is markdown rendering and the editor, nothing else.
- every route is authenticated except the `%set-response` public-post cache.
  gated lists never reach that path, so a gated list cannot leak through it.
- no JSON anywhere. `on-peek` returns `noun` cages and `mar/keep/action.hoon`
  records the omission as deliberate. a native client cannot read state over
  eyre scry or the channel API as things stand.
- writes ARE already an HTTP API: `POST /keep` with `what=publish&body=…`,
  `what=follow&who=…`, and the rest of `+act-of`. a native client needs no new
  write surface.

## The blocker is onboarding, not code

an app store user has no ship. the shippable answer is log-into-an-existing-ship
(url + `+code`, as Tlon and Pocket do) and leave identity acquisition on the web.

do NOT sell or mint azimuth IDs in the app — that pulls in 3.1.5(b) and the NFT
rules for no benefit.

## Review requirements

- [ ] **native client, not a webview.** a shell around eyre draws 4.2 (minimum
      functionality) and plausibly 4.7 (executing code apple did not review — a
      ship serves arbitrary HTML/JS). the `view` and `row` types at the top of
      `lib/keep-ui.hoon` are the view model to mirror natively.
- [ ] **1.2, user-generated content.** the one that bites federated apps. needs
      content filtering, in-app report, block-user, an EULA, published contact
      info, and removal within 24h of a report. we cannot moderate other ships,
      so all of it is client-side: local blocklist, hide-on-report, and a report
      endpoint someone actually staffs.
- [ ] **demo account.** a permanently-up hosted review ship with content on it.
- [ ] **5.1.1(v)** in-app account deletion.
- [ ] privacy nutrition label.
- [ ] `ITSAppUsesNonExemptEncryption` — urbit crypto, standard exemption, but
      declare it.
- [ ] push has no urbit-native path. needs a service holding a channel
      subscription per user, fanning out to APNs.

## The JSON surface — a second desk, not this one

a `%keep-api` agent on the same ship:

- `%watch`es `/ui/wall`, `/ui/lists`, `/ui/peers`. `on-watch` only requires
  `=(our.bowl src.bowl)`, which a local agent satisfies, and each path gives
  full current state on subscribe.
- binds its own eyre path, serves JSON, reuses eyre cookie auth.
- writes stay on the existing form POSTs.

zero changes to keep. the cost is re-deriving `row`, since `feed-rows` and
`row-of` live in the agent's helper core rather than the lib.

prefer the subscription to `.^ %gx` — same result, and it sidesteps the gall
re-entrancy question entirely.

the alternative is `++json` grow arms plus a `/keep/api` route: ~150 lines here,
but it reverses the decision recorded in `mar/keep/action.hoon`.

## Sequence

1. `%keep-api` desk (read JSON) — unblocks everything, keep untouched.
2. native ios client, 1.2 compliance from day one.

## Sources

- <https://developer.apple.com/app-store/review/guidelines/>
- <https://nickarner.com/projects_and_work/work/tlon-pocket/>
