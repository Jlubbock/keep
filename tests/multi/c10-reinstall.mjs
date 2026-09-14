//  C10 — a writer that nukes and reinstalls %keep keeps its readers and can
//  still gain new ones.
//
//    gall keeps a nuked agent's revision counters, so a reinstalled writer
//    that grew /index again would start at N+1 and a reader tailing from 1
//    would wait forever. Every install publishes under its own nonce, and
//    readers are told the address (%announce answers %follow) rather than
//    deriving it. A NEW follower after the reinstall is the assertion; the
//    old follower healing on its next %follow is the second.

import * as h from '../harness.mjs';

const TAG = Date.now();
const BEFORE = `c10 before ${TAG}`;
const AFTER = `c10 after ${TAG}`;

const s = h.sheet('c10-reinstall');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);
const witness = await h.connect(h.WITNESS);

const post = (title) =>
  h.poke(host, `[%post md+'${title}' \`'${title}' 'cc0' (sy ~[%public])]`);
const sees = (m, title) =>
  m.get(`/keep/ship/${h.HOST}`).then((r) => r.body.includes(title));

await post(BEFORE);
await h.poke(peer, `[%sub ${h.HOST}]`);
s.check('C10.0 a follower receives the pre-reinstall post (control)',
  await h.got(h.until('peer to wall the first post', () => sees(peer, BEFORE), { timeout: 60000 })));

//  the reinstall: state, farm and fans gone; revision counters kept by gall
await h.dojo(host, '|nuke %keep, =hard &');
await h.dojo(host, '|rein %keep [& %keep] [& %rogue]');
await h.until('host to answer again',
  () => h.dojo(host, '.^(* %gx /=keep=/subs/noun)').then(() => true, () => false));
await post(AFTER);

await h.poke(witness, `[%sub ${h.HOST}]`);
s.check('C10.1 a NEW follower after the reinstall receives the new post',
  await h.got(h.until('witness to wall the post-reinstall post', () => sees(witness, AFTER), { timeout: 60000 })));

//  the old follower's keen is parked on an address the writer will never
//  grow again; its daily re-%follow (here: a %sub) gets the new one
s.check('C10.2 the old follower is stalled until it asks again',
  await h.got(h.stays('peer to miss the new post on its old address', async () => !(await sees(peer, AFTER)), { hold: 10000 })));
await h.poke(peer, `[%sub ${h.HOST}]`);
s.check('C10.3 and re-following heals it',
  await h.got(h.until('peer to wall the post-reinstall post', () => sees(peer, AFTER), { timeout: 60000 })));

process.exit(s.done() ? 1 : 0);
