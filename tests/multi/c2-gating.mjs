//  C2 — a gated list, and what eviction actually costs.
//
//    Revocation is not re-keying: it is declining to grow to that member's
//    path again. So the test is three beats — delivered, withheld, delivered
//    again — because "withheld" on its own is what a broken fleet looks like.

import * as h from '../harness.mjs';

const TAG = Date.now();
const LYST = 'inner';
const BEFORE = `c2 before ${TAG}`;
const AFTER = `c2 after ${TAG}`;

const s = h.sheet('c2-gating');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);

const post = (title, body) =>
  h.poke(host, `[%post md+'${body}' \`'${title}' 'cc0' (sy ~[%${LYST}])]`);

//  the host's own page on the peer: every row whose feed is the host's
const sees = (title) => peer.get(`/keep/ship/${h.HOST}`).then((r) => r.body.includes(title));

await h.poke(host, `[%list %${LYST} (sy ~[${h.PEER}])]`);
await post(BEFORE, 'members only');

s.check('C2.1 a member receives the list',
  await h.got(h.until('peer to see the gated post', () => sees(BEFORE), { timeout: 60000 })));

await h.poke(host, `[%evict %${LYST} (sy ~[${h.PEER}])]`);
await post(AFTER, 'after the eviction');

//  the in-window control: if BEFORE vanished we are reading an error page and
//  the absence of AFTER would mean nothing
s.check('C2.2 an evicted member receives nothing',
  await h.stays('peer to keep the old post and not the new one',
    async () => (await sees(BEFORE)) && !(await sees(AFTER)), { hold: 15000 })
    .then(() => true).catch(() => false));

//  the positive control: the channel was never broken, only unfed
await h.poke(host, `[%admit %${LYST} (sy ~[${h.PEER}])]`);

s.check('C2.3 re-admission backfills what was withheld',
  await h.got(h.until('peer to receive the withheld post', () => sees(AFTER), { timeout: 60000 })));

process.exit(s.done() ? 1 : 0);
