//  C1 — a public post reaches a follower, and its body survives the trip.
//
//    The host grows /index, the peer's parked keen fires, the head arrives
//    eagerly and the body only on click. Nothing here is a poke: the two ships
//    exchange one index revision and two remote scries.

import * as h from '../harness.mjs';

//  layer C shares one mutating fleet, so nothing may collide with a past run
const TAG = Date.now();
const TITLE = `c1 ${TAG}`;
const SLUG = `/keep/c1-${TAG}`;
const BODY = `c1 body ${TAG}`;

const s = h.sheet('c1-follow');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);

const has = (m, url, text) => m.get(url).then((r) => r.body.includes(text));

await h.poke(host, `[%post md+'${BODY}' \`'${TITLE}' 'cc0' (sy ~[%public])]`);

s.check('C1.1 the author holds it',
  await h.got(h.until('host to index the post', () => has(host, '/keep/index', TITLE))));

s.check('C1.2 and serves it on the open web',
  await has(host, SLUG, BODY), SLUG);

await h.poke(peer, `[%sub ${h.HOST}]`);

//  the title is rendered from the HEAD, so this is head delivery too
s.check('C1.3 a follower sees the headline',
  await h.got(h.until('peer to wall the entry', () => has(peer, '/keep', TITLE), { timeout: 60000 })));

const feed = (await peer.get('/keep')).body;
const id = new RegExp(`/keep/read/(0v[^/"]+)/${h.HOST}`).exec(feed)?.[1];
s.check('C1.4 addressed by content hash', !!id, id ?? 'no read link on the feed');

if (id) {
  //  bodies are fetched on click, not on arrival — the GET issues the keen
  const read = `/keep/read/${id}/${h.HOST}`;
  const got = await h.until('peer to fetch the body', async () => {
    const r = await peer.get(read);
    return r.body.includes(BODY) ? r.body : null;
  }).catch(() => null);
  s.check('C1.5 the body arrives on demand', !!got);

  //  %.y, not "no warning rendered": ~ (unjudged) also renders no warning
  s.check('C1.6 and verifies against the author key',
    await h.until('peer to judge the body', () => h.verified(peer, h.entryHoon(h.HOST, id)))
      .then(() => true, () => false));
}

process.exit(s.done() ? 1 : 0);
