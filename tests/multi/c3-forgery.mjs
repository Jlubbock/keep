//  C3 — a spliced head, and the two things that must follow from it.
//
//    The PEER runs `rogue` (tests/app/rogue.hoon), which grows head/body pairs at
//    the same namespace shape a real %keep serves. One pair matches; the other
//    carries a genuine peer signature over a head whose `hash` names a body
//    other than the one served.
//
//    The HOST reaches both with %keep — the syndicate action, which takes an
//    arbitrary entry. So this tests +judge's verdict AND what the agent does
//    with it: a forgery must not be re-hosted under our own name.

import * as h from '../harness.mjs';

const TAG = Date.now();
const s = h.sheet('c3-forgery');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);

//  the rogue keeps the last id it planted; there is no other way to learn it
const plant = async (honest, title, body) => {
  await peer.call('mcp/poke-our-agent', {
    agent: 'rogue', mark: 'noun',
    data: `[%plant ${honest ? '%.y' : '%.n'} '${title}' '${body}']`,
  });
  const out = await h.dojo(peer, '.^(@uv %gx /=rogue=/last/noun)');
  return /(0v[a-z0-9.]+)/.exec(out)?.[1];
};

//  %probe, not %public: syndicating to %public would trip the guard against
//  exposing a gated address, which is a different test
const syndicate = (entry) => h.poke(host, `[%keep ${entry} (sy ~[%probe])]`);

const good = await plant(true, `c3 honest ${TAG}`, `c3 honest body ${TAG}`);
const bad = await plant(false, `c3 forged ${TAG}`, `c3 forged body ${TAG}`);
//  distinct ids, or `last` never moved and both reads returned the same stale 0v0
s.check('C3.0 the rogue planted both pairs', !!good && !!bad && good !== bad, `${good} ${bad}`);

if (good && bad && good !== bad) {
  const goodEntry = h.entryHoon(h.PEER, good, 'rogue');
  const badEntry = h.entryHoon(h.PEER, bad, 'rogue');

  await syndicate(goodEntry);
  await syndicate(badEntry);

  //  the positive control: same ship, same path shape, same fetch
  s.check('C3.1 a matching pair verifies',
    await h.until('host to verify the honest pair', () => h.verified(host, goodEntry))
      .then(() => true, () => false));

  s.check('C3.2 and is re-hosted under our own name',
    await h.until('host to mirror the honest item', () => h.holds(host, good))
      .then(() => true, () => false));

  s.check('C3.3 a spliced pair is caught',
    await h.until('host to reject the forged pair', () => h.forged(host, badEntry))
      .then(() => true, () => false));

  //  the whole point: a forgery that merely fails to render is still a forgery
  //  you are serving to everyone who reads your shop
  s.check('C3.4 and is never re-hosted',
    await h.stays('host to keep refusing to mirror the forgery',
      async () => !(await h.holds(host, bad)), { hold: 10000 })
      .then(() => true, () => false));
}

process.exit(s.done() ? 1 : 0);
