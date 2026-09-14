//  C2 — a gated list, and what eviction actually costs.
//
//    A gated list is a coop: one encrypted address, and gall asks %keep on
//    every read whether the reader is still a member. Eviction is a roster
//    change plus a key rotation. Two members are what make that testable. One
//    %post, published after the eviction, must reach the witness and not the
//    evicted peer — so the withheld half is controlled by the delivered half,
//    in the same window, over the same list, from the same post.
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

//  the invite carries the list's address; read it back off the page the way a
//  writer would, rather than deriving it
const invitePath = async (m, from) => {
  const b = (await m.get('/keep/lists')).body;
  const at = b.indexOf(`class="k-invite-who">${from}<`);
  if (at < 0) return null;
  return /name="path" value="([^"]+)"/.exec(b.slice(at))?.[1] ?? null;
};

//  the button, not the action: a poke would skip +invite-of, where the spur
//  arrives as a form field and is parsed back into a path
const submit = (m, fields) =>
  fetch(`${m.url}/keep`, {
    method: 'POST',
    headers: { Cookie: m.cookie, 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(fields).toString(),
    redirect: 'manual',
  });

const accept = async (m, from) => {
  const p = await h.until(`${m.patp} to be offered an invite`, () => invitePath(m, from));
  return submit(m, { what: 'accept', who: from, path: p, back: '/keep/lists' });
};

//  the sidebar names ships too, so anchor on the invite's own class
const offered = (m, from) =>
  m.get('/keep/lists').then((r) =>
    r.body.includes('k-pending') && r.body.includes(`class="k-invite-who">${from}<`));

await h.poke(host, `[%list %${LYST} (sy ~[${h.PEER} ${h.WITNESS}])]`);
await post(BEFORE, 'members only');

//  an invite is an offer, not a subscription: nothing may arrive before accept.
//  C2.1 is this check's positive control — the same post, same list, same
//  window, once the invite is taken.
s.check('C2.0 an unaccepted invite delivers nothing',
  await h.got(h.stays('peer to stay empty while the invite is pending',
    async () => !(await sees(peer, BEFORE)), { hold: 15000 })));

//  an offer nobody can see is not an offer: this is the only check that
//  renders the pending block, and a bad manx there 500s the whole page
s.check('C2.0b and is offered on the lists page',
  await h.got(h.until('peer lists page to show the invite', () => offered(peer, h.HOST))));

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

//  the address is no secret any more: the coop is. a direct link to the
//  withheld post resolves, on the evicted peer, to the list's coop, and gall
//  on the host refuses the key — so the body never lands. C2.5 is the control:
//  the same link fills in once the peer is back on the roster.
const idOf = (page, title) =>
  new RegExp(`/keep/read/(0v[^/"]+)/${h.HOST}"[^>]*>${title}<`).exec(page)?.[1];
const idAfter = await h.until('host to list the post-eviction post', async () =>
  idOf((await host.get(`/keep/ship/${h.HOST}`)).body, AFTER));
const readAfter = `/keep/read/${idAfter}/${h.HOST}`;
s.check('C2.4b nor can it read the post by direct link',
  await h.got(h.stays('evicted peer to get no body on a cold read',
    async () => !(await peer.get(readAfter)).body.includes('after the eviction'), { hold: 15000 })));

//  re-admission re-invites: the peer keens the revision gall refused from
//  where it stalled, and the withheld post arrives late rather than never
await h.poke(host, `[%admit %${LYST} (sy ~[${h.PEER}])]`);

s.check('C2.5 re-admission backfills what was withheld',
  await h.got(h.until('peer to receive the withheld post', () => sees(peer, AFTER), { timeout: 60000 })));

s.check('C2.5b and the direct link now reads',
  await h.got(h.until('re-admitted peer to fetch the body', async () =>
    (await peer.get(readAfter)).body.includes('after the eviction'), { timeout: 60000 })));

process.exit(s.done() ? 1 : 0);
