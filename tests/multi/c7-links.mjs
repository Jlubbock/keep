//  C7 — internal linking: the linkmap serves public slugs to the clearnet,
//  and a direct read link cold-fetches the HEAD with the body, so a linked
//  post arrives titled and judged.
//
//    The gated post's invite is never accepted, so no keen ever walls it on
//    the peer: the direct link is its only path — which is exactly what an
//    internal link in someone's prose is.

import * as h from '../harness.mjs';

//  layer C shares one mutating fleet, so nothing may collide with a past run
const TAG = Date.now();
const PUB = `c7 pub ${TAG}`;
const GATED = `c7 gated ${TAG}`;
const BODY = `c7 body ${TAG}`;
const SLUG = `/keep/c7-pub-${TAG}`;

const s = h.sheet('c7-links');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);

//  the public post is the positive control for "the gated one is absent"
await h.poke(host, `[%post md+'${BODY}' \`'${PUB}' 'cc0' (sy ~[%public])]`);
await h.poke(host, `[%list %c7paid (sy ~[${h.PEER}])]`);
await h.poke(host, `[%post md+'${BODY}' \`'${GATED}' 'cc0' (sy ~[%c7paid])]`);

//  own rows carry the read link; the title is the anchor's text
const idOf = (page, title) =>
  new RegExp(`/keep/read/(0v[^/"]+)/${h.HOST}" class="k-title[^"]*">${title}<`).exec(page)?.[1];

let idPub = null, idGated = null;
await h.until('host to list both posts', async () => {
  const page = (await host.get(`/keep/ship/${h.HOST}`)).body;
  idPub = idOf(page, PUB);
  idGated = idOf(page, GATED);
  return idPub && idGated;
});

const linkmap = async () => JSON.parse((await host.get('/keep/linkmap')).body);

s.check('C7.1 the linkmap maps the public id to its slug',
  await h.got(h.until('linkmap to carry the post', async () => (await linkmap())[idPub] === SLUG)));

s.check('C7.2 and does not carry the gated one',
  !((await linkmap())[idGated]), idGated);

//  bodies are fetched on click; C7.3-5 say the head comes along on a COLD
//  read — without it the body renders untitled and, silently, unverified
const read = `/keep/read/${idGated}/${h.HOST}`;
s.check('C7.3 a cold direct link fetches the body',
  await h.got(h.until('peer to fetch the body', async () =>
    (await peer.get(read)).body.includes(BODY), { timeout: 60000 })));

s.check('C7.4 and the head arrives with it',
  await h.got(h.until('peer to fetch the head', async () =>
    (await peer.get(read)).body.includes(`>${GATED}<`))));

s.check('C7.5 so the verdict forms',
  await h.got(h.until('peer to judge the body', () =>
    h.verified(peer, h.entryHoon(h.HOST, idGated)))));

await h.poke(host, `[%delete ${idPub}]`);
s.check('C7.6 deletion prunes the linkmap',
  await h.got(h.until('linkmap to drop the post', async () => !((await linkmap())[idPub]))));

process.exit(s.done() ? 1 : 0);
