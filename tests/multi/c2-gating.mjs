//  C2 — a gated list, and what eviction actually costs.
//
//    Revocation is not re-keying: it is declining to grow to one member's
//    path again. Two members are what make that testable. One %post, published
//    after the eviction, must reach the witness and not the evicted peer — so
//    the withheld half is controlled by the delivered half, in the same
//    window, over the same list, from the same post.
//
//    With one member, "withheld" is indistinguishable from a fleet that cannot
//    deliver — which is exactly what an earlier broken fleet scored green.

import * as h from '../harness.mjs';

const TAG = Date.now();
const LYST = 'inner';
const BEFORE = `c2 before ${TAG}`;
const AFTER = `c2 after ${TAG}`;

const s = h.sheet('c2-gating');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);
const witness = await h.connect(h.WITNESS);

const post = (title, body) =>
  h.poke(host, `[%post md+'${body}' \`'${title}' 'cc0' (sy ~[%${LYST}])]`);

//  the host's own page on a reader: every row whose feed is the host's
const sees = (m, title) =>
  m.get(`/keep/ship/${h.HOST}`).then((r) => r.body.includes(title));

//  the per-member spur IS the capability, and it exists nowhere on the reader
//  but its own pending map — so the test reads it back rather than deriving it
const invitePath = async (m, from) => {
  const out = await h.dojo(m, `~(tap by .^((map [@p path] @tas) %gx /=keep=/pending/noun))`);
  return new RegExp(`\\[${from} (/\\S+)\\]`).exec(out)?.[1] ?? null;
};

const accept = async (m, from) => {
  const p = await h.until(`${m.patp} to be offered an invite`, () => invitePath(m, from));
  return h.poke(m, `[%accept [${from} ${p}]]`);
};

await h.poke(host, `[%list %${LYST} (sy ~[${h.PEER} ${h.WITNESS}])]`);
await post(BEFORE, 'members only');

//  an invite is an offer, not a subscription: nothing may arrive before accept.
//  C2.1 is this check's positive control — the same post, same list, same
//  window, once the invite is taken.
s.check('C2.0 an unaccepted invite delivers nothing',
  await h.got(h.stays('peer to stay empty while the invite is pending',
    async () => !(await sees(peer, BEFORE)), { hold: 15000 })));

await accept(peer, h.HOST);
await accept(witness, h.HOST);

s.check('C2.1 a member receives the list',
  await h.got(h.until('peer to see the gated post', () => sees(peer, BEFORE), { timeout: 60000 })));

s.check('C2.2 so does every other member',
  await h.got(h.until('witness to see the gated post', () => sees(witness, BEFORE), { timeout: 60000 })));

await h.poke(host, `[%evict %${LYST} (sy ~[${h.PEER}])]`);
await post(AFTER, 'after the eviction');

//  concurrent control: the same post reaching the witness is what makes the
//  peer's silence mean eviction rather than a dead fleet
s.check('C2.3 an unevicted member is undisturbed',
  await h.got(h.until('witness to receive the post-eviction one', () => sees(witness, AFTER), { timeout: 60000 })));

s.check('C2.4 the evicted member receives nothing',
  await h.got(h.stays('peer to keep the old post and never see the new one',
    async () => (await sees(peer, BEFORE)) && !(await sees(peer, AFTER)), { hold: 15000 })));

//  re-admission re-grows the whole log to the same address: no re-key, and the
//  withheld post arrives late rather than never
await h.poke(host, `[%admit %${LYST} (sy ~[${h.PEER}])]`);

s.check('C2.5 re-admission backfills what was withheld',
  await h.got(h.until('peer to receive the withheld post', () => sees(peer, AFTER), { timeout: 60000 })));

process.exit(s.done() ? 1 : 0);
