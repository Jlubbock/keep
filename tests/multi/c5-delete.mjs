//  C5 — deleting a post, and what a repost is worth.
//
//    Deleting grows the index again without one pointer and tombs the item.
//    A reposter re-grew the same bytes under their OWN /item, so their copy is
//    a second original, not a reference: the author's delete must take the
//    author's row out of a follower's feed and leave the reposter's standing.
//
//    The witness is what makes that testable. It follows both ships, so the
//    surviving repost and the vanished original are read by the same reader,
//    in the same window, off the same fleet — without it, "the row went away"
//    and "the fleet stopped delivering" score identically.
//
//    Two posts, because a tomb can only be observed on a body NOBODY has
//    fetched. The reposted one had to be read to be mirrored, so anything
//    along that path may answer from cache; the quiet one is only ever
//    pointed at, and its head is the control that says the pointer arrived.

import * as h from '../harness.mjs';

const TAG = Date.now();
const TITLE = `c5 ${TAG}`;
const SLUG = `/keep/c5-${TAG}`;
const BODY = `c5 body ${TAG}`;
//  published, walled, head fetched — and never opened by anyone
const QUIET = `c5q ${TAG}`;
const QUIET_BODY = `c5 quiet body ${TAG}`;

const s = h.sheet('c5-delete');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);
const witness = await h.connect(h.WITNESS);

//  the rows of one feed, on a reader: user-rows keys on the FEED, so the
//  author's copy and the reposter's copy sit on different pages
const sees = (m, who, title) =>
  m.get(`/keep/ship/${who}`).then((r) => r.body.includes(title));

//  the GET is the fetch: a body is keened on click, never on arrival
const reads = (m, id, who, text) =>
  m.get(`/keep/read/${id}/${who}`).then((r) => r.body.includes(text));

//  by TITLE, not by position: two posts means the first read link on the page
//  is whichever sorted newest, which is not the one a given check means
const idOf = (html, title) =>
  new RegExp(`/keep/read/(0v[^/"]+)/${h.HOST}"[^>]*>${title}<`).exec(html)?.[1] ?? null;

const published = (title) =>
  h.until(`host to publish ${title}`, async () =>
    idOf((await host.get(`/keep/ship/${h.HOST}`)).body, title));

const post = (title, body) =>
  h.poke(host, `[%post md+'${body}' \`'${title}' 'cc0' (sy ~[%public])]`);

await post(TITLE, BODY);
const own = await published(TITLE);

await h.poke(peer, `[%sub ${h.HOST}]`);
s.check('C5.0 the reposter receives it',
  await h.got(h.until('peer to wall the post', () => sees(peer, h.HOST, TITLE), { timeout: 60000 })));

//  %keep fetches head and body first, so the mirror is byte-identical and the
//  id — (sham +sain) over the head — comes out the same at the new address
await h.poke(peer, `[%keep ${h.entryHoon(h.HOST, own)} (sy ~[%public])]`);
s.check('C5.0b and re-hosts it under its own name',
  await h.got(h.until('peer to hold the mirror', () => h.holds(peer, own), { timeout: 60000 })));

await h.poke(witness, `[%sub ${h.HOST}]`);
await h.poke(witness, `[%sub ${h.PEER}]`);

s.check('C5.1 a follower sees the original',
  await h.got(h.until('witness to wall the author copy', () => sees(witness, h.HOST, TITLE), { timeout: 60000 })));

s.check('C5.2 and the repost',
  await h.got(h.until('witness to wall the reposted copy', () => sees(witness, h.PEER, TITLE), { timeout: 60000 })));

await post(QUIET, QUIET_BODY);
const quiet = await published(QUIET);

//  the control for C5.8: the pointer and head crossed the wire, so the body
//  address is live and reachable — what follows is the tomb, not a dead fleet
s.check('C5.2b and a post whose body nobody has opened',
  await h.got(h.until('witness to wall the quiet post', () => sees(witness, h.HOST, QUIET), { timeout: 60000 })));

//  ---- the delete ----------------------------------------------------------

await h.poke(host, `[%delete ${own}]`);
await h.poke(host, `[%delete ${quiet}]`);

s.check('C5.3 the author drops it',
  await h.got(h.until('host to forget both posts',
    async () => !(await h.holds(host, own)) && !(await h.holds(host, quiet)))));

s.check('C5.4 and stops serving it on the open web',
  await h.got(h.until('host to unbind the url', async () => {
    const gone = !(await host.get(SLUG)).body.includes(BODY);
    const unlisted = !(await host.get('/keep/index')).body.includes(TITLE);
    return gone && unlisted;
  })));

s.check('C5.5 a follower loses the rows',
  await h.got(h.until('witness to prune the author copies',
    async () => !(await sees(witness, h.HOST, TITLE)) && !(await sees(witness, h.HOST, QUIET)),
    { timeout: 60000 })));

//  the whole point: one index revision removed one pointer, not the post
s.check('C5.6 the repost is untouched',
  await h.got(h.stays('witness to keep the reposted row',
    () => sees(witness, h.PEER, TITLE), { hold: 15000 })));

//  C5.7 is the positive control for C5.8 — same reader, same window, same
//  fleet, one body that must arrive and one that must not
s.check('C5.7 and still serves the body',
  await h.got(h.until('witness to read the body off the reposter',
    () => reads(witness, own, h.PEER, BODY), { timeout: 60000 })));

//  the quiet post, so no cache anywhere can be answering in the tomb's place
s.check('C5.8 the author stops serving what nobody had fetched',
  await h.got(h.stays('the author address to answer nothing',
    async () => !(await reads(witness, quiet, h.HOST, QUIET_BODY)), { hold: 15000 })));

process.exit(s.done() ? 1 : 0);
