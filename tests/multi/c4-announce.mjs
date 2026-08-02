//  C4 — %announce: the only ames traffic keep sends that is not an invite.
//
//    Adding a pal, or installing keep on a ship that already has one, should
//    wire subscriptions in BOTH directions with no %sub from anybody. The
//    sender learns from its own poke-ack (/hey), the receiver from the poke.
//
//    DESTRUCTIVE, and it runs last: it nukes %keep on both ships to clear the
//    subscriptions the earlier scenarios built, which would otherwise make
//    every assertion here vacuously true.

import * as h from '../harness.mjs';

const s = h.sheet('c4-announce');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);

const pals = (m, expr) => m.call('mcp/poke-our-agent', { agent: 'pals', mark: 'pals-command', data: expr });

//  |nuke clears state, |rein starts it again — so on-init runs for real
const reinstall = async (m) => {
  await h.dojo(m, '|nuke %keep, =desk %keep');
  await h.dojo(m, '|rein %keep [& %keep] [& %rogue]');
  await h.until('keep to answer again',
    () => h.dojo(m, '.^(* %gx /=keep=/subs/noun)').then(() => true).catch(() => false));
};

await pals(host, `[%part ${h.PEER} ~]`).catch(() => {});
await pals(peer, `[%part ${h.HOST} ~]`).catch(() => {});
await reinstall(host);
await reinstall(peer);

//  with no pals there is nothing to announce to, so nothing should appear
s.check('C4.1 no pals, no subscriptions',
  await h.stays('host to stay unsubscribed from peer', async () => !(await h.tails(host, h.PEER)))
    .then(() => true).catch(() => false));

//  mutual: the receiver's %announce handler ignores a ship not in its targets
await pals(host, `[%meet ${h.PEER} ~]`);
await pals(peer, `[%meet ${h.HOST} ~]`);

s.check('C4.2 meeting a pal opens a subscription',
  await h.until('host to tail peer', () => h.tails(host, h.PEER), { timeout: 60000 })
    .then(() => true).catch(() => false));

s.check('C4.3 and the far side subscribes back',
  await h.until('peer to tail host', () => h.tails(peer, h.HOST), { timeout: 60000 })
    .then(() => true).catch(() => false));

//  tailing is mechanical; following is what puts them in your feed
s.check('C4.4 an announced peer is followed, not merely tailed',
  await h.until('host to follow peer', () => h.follows(host, h.PEER))
    .then(() => true).catch(() => false));

//  the on-init claim: install onto a ship that already has pals and it wires
//  itself up, with no fact and no poke from anybody
await reinstall(host);

s.check('C4.5 a fresh install announces to existing pals',
  await h.until('host to tail peer again from a cleared state', () => h.tails(host, h.PEER), { timeout: 60000 })
    .then(() => true).catch(() => false));

process.exit(s.done() ? 1 : 0);
