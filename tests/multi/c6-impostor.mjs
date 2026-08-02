//  C6 — a head that names someone else, at a life nobody can look up.
//
//    +pass-of gates on jael's %lyfe before it touches %deed, because %deed
//    BLOCKS on a life jael does not hold. So an author who claims a life
//    jael cannot resolve hands us no key at all, and the signature is never
//    checked. That is %cold, and the whole point is that %cold is not a
//    weaker %good: the attacker chooses it, so it must buy nothing.
//
//    The PEER runs `rogue`, which plants a head naming the WITNESS at life
//    99. Nothing about it is malformed — the hash matches the body it
//    serves, and the id matches the head — so every clause of +sound before
//    the key lookup passes. Only the signature is unverifiable.

import * as h from '../harness.mjs';

const TAG = Date.now();
const s = h.sheet('c6-impostor');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);

const LIFE = 99;

const last = async () => {
  const out = await h.dojo(peer, '.^(@uv %gx /=rogue=/last/noun)');
  return /(0v[a-z0-9.]+)/.exec(out)?.[1];
};

const plant = async (title, body) => {
  await peer.call('mcp/poke-our-agent', {
    agent: 'rogue', mark: 'noun', data: `[%plant %.y '${title}' '${body}']`,
  });
  return last();
};

const forge = async (who, lyfe, title, body) => {
  await peer.call('mcp/poke-our-agent', {
    agent: 'rogue', mark: 'noun', data: `[%forge ${who} ${lyfe} '${title}' '${body}']`,
  });
  return last();
};

//  %probe, not %public: syndicating to %public trips the gated-address guard,
//  which is a different test
const syndicate = (entry) => h.poke(host, `[%keep ${entry} (sy ~[%probe])]`);

const good = await plant(`c6 honest ${TAG}`, `c6 honest body ${TAG}`);
const cold = await forge(h.WITNESS, LIFE, `c6 impostor ${TAG}`, `c6 impostor body ${TAG}`);

s.check('C6.0 the rogue planted both pairs',
  !!good && !!cold && good !== cold, `${good} ${cold}`);

if (good && cold && good !== cold) {
  const goodEntry = h.entryHoon(h.PEER, good, 'rogue');
  const coldEntry = h.entryHoon(h.PEER, cold, 'rogue');

  await syndicate(goodEntry);
  await syndicate(coldEntry);

  //  the positive control: same ship, same path shape, same fetch. without it
  //  every assertion below passes just as well when nothing was delivered.
  s.check('C6.1 a matching pair from the same peer still verifies',
    await h.until('host to verify the honest pair', () => h.verified(host, goodEntry))
      .then(() => true, () => false));

  //  a verdict, not an absence: %cold in `checked` proves head AND body
  //  arrived and were judged, which is what makes C6.4 mean anything
  s.check('C6.2 the impostor is judged %cold, not left unjudged',
    await h.until('host to judge the impostor', () => h.uncheckable(host, coldEntry))
      .then(() => true, () => false));

  //  and the impersonation is real: the head names the witness, not the peer
  //  that served it. otherwise C6.2 could be passing for some other reason.
  s.check(`C6.3 the head claims ${h.WITNESS} at life ${LIFE}`,
    await h.claims(host, coldEntry, h.WITNESS, LIFE),
    await h.claimsOf(host, coldEntry));

  //  the whole point: an unchecked signature must not put someone else's name
  //  on something you are serving to everyone who reads your shop
  s.check('C6.4 and is never re-hosted under our own name',
    await h.stays('host to keep refusing to mirror the impostor',
      async () => !(await h.holds(host, cold)), { hold: 10000 })
      .then(() => true, () => false));
}

process.exit(s.done() ? 1 : 0);
