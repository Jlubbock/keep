//  C8 — the send state machine, against a relay stub.
//
//    The stub is this process: an http server the ship's iris reaches over
//    loopback, answering whatever verdict the scenario scripts next and
//    keeping every request it saw. So each assertion about the ship — what
//    was pruned, what was queued, what settled — has the relay's view of the
//    same round beside it as the control.
//
//    Retries are asserted at the queue, not across the behn wake: the wait is
//    thirty minutes by design and this suite does not wait it out.

import { createServer } from 'node:http';
import * as h from '../harness.mjs';

const TAG = Date.now();
const PORT = 8099;
const KEY = `k-${TAG}`;
const s = h.sheet('c8-mail');
const host = await h.connect(h.HOST);

//  ---- the stub -------------------------------------------------------------

const seen = [];                  //  every POST, parsed
let answer = (chunk) => ({ status: 200, body: { sent: chunk.to, dropped: [], retry: [] } });
const relay = createServer((req, res) => {
  let raw = '';
  req.on('data', (c) => { raw += c; });
  req.on('end', () => {
    const body = JSON.parse(raw);
    seen.push({ auth: req.headers.authorization, ...body });
    const a = answer(body);
    res.writeHead(a.status, { 'Content-Type': 'application/json', ...(a.headers ?? {}) });
    res.end(JSON.stringify(a.body ?? { detail: 'nope' }));
  });
});
await new Promise((r) => relay.listen(PORT, '127.0.0.1', r));
const since = () => seen.length;
const arrived = (n, count) => h.until(`${count} relay calls`, () => seen.length - n >= count);

//  ---- driving the mailer ---------------------------------------------------

const mail = (expr) =>
  host.call('mcp/poke-our-agent', { agent: 'keep-mail', mark: 'keep-mail-action', data: expr });
const scry = (expr) => h.dojo(host, expr);
const yes = (t) => /%\.y/.test(t);
//  the value under the echoed prompt
const val = (t) => { try { return JSON.parse(t)['dojo-output'].split('\n').slice(1).join('\n').trim(); } catch { return t.trim(); } };

const hasSub = async (a) =>
  yes(await scry(`(~(has by .^((map @t @da) %gx /=keep-mail=/subs/noun)) '${a}')`));
const isSent = async (id) =>
  yes(await scry(`(~(has by .^((map @uvH @da) %gx /=keep-mail=/sent/noun)) ${id})`));
//  [(lent left) tries] per queued post, or ~
const queued = async (id) =>
  val(await scry(`=/  q  .^((list [id=@uvH left=(list @t) tries=@ud]) %gx /=keep-mail=/queue/noun)  (turn (skim q |=([i=@uvH * *] =(i ${id}))) |=([* l=(list @t) t=@ud] [(lent l) t]))`));
//  what the writer sees on the read page
const tag = async (id) => (await host.get(`/keep/read/${id}/${h.HOST}`)).body;

const post = async (title, lists) => {
  await h.poke(host, `[%post md+'c8 body ${TAG}' \`'${title}' 'cc0' (sy ~[${lists}])]`);
  return h.until(`host to publish ${title}`, async () =>
    new RegExp(`/keep/read/(0v[^/"]+)/${h.HOST}"[^>]*>${title}<`).exec((await host.get(`/keep/ship/${h.HOST}`)).body)?.[1]);
};

const readers = Array.from({ length: 120 }, (_, i) => `r${i}-${TAG}@x.test`);
const DROP = readers[7], RETRY = readers[60];

//  self-prepare: the fleet is shared, and chunk counts assume this list alone.
//  a list of cords prints as <|a b c|>
for (let pass = 0; pass < 5; pass++) {
  const out = val(await scry('~(tap in ~(key by .^((map @t @da) %gx /=keep-mail=/subs/noun)))'));
  const left = (/<\|([\s\S]*)\|>/.exec(out)?.[1] ?? '').split(/\s+/).filter(Boolean);
  if (!left.length) break;
  for (const a of left) await mail(`[%remove '${a}']`);
}
await mail(`[%config ['http://127.0.0.1:${PORT}/send' '${KEY}']]`);
await mail(`[%import '${readers.join('\\0a')}']`);
s.check('C8.0 the list imports', await h.got(h.until('120 readers', async () =>
  (await host.get('/keep/mail')).body.includes('120 readers'))));

//  ---- a clean send ---------------------------------------------------------

const p1 = await post(`c8 one ${TAG}`, '%public');
let n = since();
await mail(`[%send ${p1} %.n]`);
s.check('C8.1 three calls for 120 readers', await h.got(arrived(n, 3)));
const round = seen.slice(n);
const all = round.flatMap((r) => r.to);
s.check('C8.2 each call is a chunk of at most 50, every reader once',
  round.every((r) => Array.isArray(r.to) && r.to.length <= 50) && all.length === 120 && new Set(all).size === 120,
  round.map((r) => r.to.length).join('/'));
s.check('C8.3 bearer key, full patp, title as subject, markdown as text',
  round.every((r) => r.auth === `Bearer ${KEY}` && r.patp === h.HOST && r.subject === `c8 one ${TAG}` && r.text === `c8 body ${TAG}`),
  JSON.stringify({ auth: round[0].auth, patp: round[0].patp, subject: round[0].subject }));
s.check('C8.4 all verdicts sent settles the post', await h.got(h.until('post sent', () => isSent(p1))));
s.check('C8.4b and the page says so', (await tag(p1)).includes('✉ mailed'));

n = since();
await mail(`[%send ${p1} %.n]`);
s.check('C8.5 sending a sent post again is a no-op', await h.got(h.stays('no relay call', () => seen.length === n, { hold: 6000 })));
await mail(`[%send ${p1} %.y]`);
s.check('C8.6 unless the writer says again', await h.got(arrived(n, 3)));

//  ---- verdicts: dropped prunes, retry queues ------------------------------

answer = (b) => ({ status: 200, body: {
  sent: b.to.filter((a) => a !== DROP && a !== RETRY),
  dropped: b.to.includes(DROP) ? [{ to: DROP, reason: 'unsubscribed' }] : [],
  retry: b.to.includes(RETRY) ? [{ to: RETRY, reason: 'throttle' }] : [],
} });
const p2 = await post(`c8 two ${TAG}`, '%public');
n = since();
await mail(`[%send ${p2} %.n]`);
await arrived(n, 3);
s.check('C8.7 a dropped address leaves the list', await h.got(h.until('pruned', async () => !(await hasSub(DROP)))));
s.check('C8.7b and only that one', (await hasSub(readers[8])) && (await hasSub(RETRY)));
s.check('C8.8 a retry address is queued alone, first try counted',
  await h.got(h.until('queued', async () => /\[1 1\]/.test(await queued(p2)))), await queued(p2));
s.check('C8.8b and the post is not sent', !(await isSent(p2)) && (await tag(p2)).includes('✉ retrying'));

//  ---- a bad key: hard fail, nothing marked -------------------------------

answer = () => ({ status: 401, body: { detail: 'missing or unknown email key' } });
const p3 = await post(`c8 three ${TAG}`, '%public');
n = since();
await mail(`[%send ${p3} %.n]`);
await arrived(n, 3);
s.check('C8.9 a 401 fails the post', await h.got(h.until('failed', async () => (await tag(p3)).includes('✉ failed'))));
s.check('C8.9b without marking it sent or queuing it', !(await isSent(p3)) && (await queued(p3)) === '~', await queued(p3));
s.check('C8.9c and without a retry call', await h.got(h.stays('no more calls', () => seen.length === n + 3, { hold: 6000 })));

//  ---- the leak guard ------------------------------------------------------

answer = (b) => ({ status: 200, body: { sent: b.to, dropped: [], retry: [] } });
await h.poke(host, `[%list %c8gated (sy ~[${h.PEER}])]`);
const p4 = await post(`c8 gated ${TAG}`, '%c8gated');
n = since();
await mail(`[%send ${p4} %.n]`).catch(() => {});
s.check('C8.10 a gated post never reaches the relay', await h.got(h.stays('no call', () => seen.length === n, { hold: 6000 })));
//  the control: the same list, a public post, goes out
const p5 = await post(`c8 five ${TAG}`, '%public');
await mail(`[%send ${p5} %.n]`);
s.check('C8.10b while a public one still does', await h.got(arrived(n, 3)));

//  leave the fleet as found: a gated list with the peer in it changes what
//  the peer may re-host from this ship, and c2 and c5 read that
await h.poke(host, `[%unlist %c8gated]`);
for (const id of [p1, p2, p3, p4, p5]) await h.poke(host, `[%delete ${id}]`);

relay.close();
process.exit(s.done() ? 1 : 0);
