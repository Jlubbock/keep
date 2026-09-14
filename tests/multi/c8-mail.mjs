//  C8 — the send state machine, against a relay stub.
//
//    The stub is this process: an http server the ship's iris reaches over
//    loopback, answering whatever the scenario scripts next and keeping
//    every request it saw. So each assertion about the ship — what was
//    merged, what was pruned, what was queued, what settled — has the
//    relay's view of the same round beside it as the control.
//
//    Retries are asserted at the queue, not across the behn wake: the wait is
//    thirty minutes by design and this suite does not wait it out.

import { createServer } from 'node:http';
import * as h from '../harness.mjs';

const TAG = Date.now();
const PORT = 8099;
const KEY = `k-${TAG}`;
const BASE = `http://127.0.0.1:${PORT}`;
const s = h.sheet('c8-mail');
const host = await h.connect(h.HOST);

//  ---- the stub -------------------------------------------------------------

const readers = Array.from({ length: 120 }, (_, i) => `r${i}-${TAG}@x.test`);
const DROP = readers[7], UNCONFIRMED = readers[60], FORMED = `formed-${TAG}@x.test`;
const TOKEN = `keep-verify-${TAG}`;
const SOURCE = 'https://c8.substack.com/about';

const seen = [];                  //  every request: {method, url, auth, ...body}
let jobs = 0;
let active = [];                  //  who the relay says confirmed
let verified = null;
let answer = (body) => {
  const dropped = body.to.filter((a) => a === DROP).map((a) => ({ to: a, reason: 'unsubscribed' }));
  const unconfirmed = body.to.filter((a) => !active.includes(a) && a !== DROP);
  return { status: 202, body: { job: `j${++jobs}`, status: 'queued', recipients: body.to.length - dropped.length - unconfirmed.length, dropped, unconfirmed } };
};
let jobAnswer = (id) => ({ status: 200, body: { job: id, status: 'done', requested: 2, sent: 2, failed: 0, queued: 0, error: null } });
const relay = createServer((req, res) => {
  let raw = '';
  req.on('data', (c) => { raw += c; });
  req.on('end', () => {
    const body = raw ? JSON.parse(raw) : {};
    seen.push({ method: req.method, url: req.url, auth: req.headers.authorization, ...body });
    let a;
    if (req.method === 'POST' && req.url === '/api/mail/send') a = answer(body);
    else if (req.method === 'GET' && req.url.startsWith('/api/mail/jobs/')) a = jobAnswer(req.url.split('/').pop());
    else if (req.method === 'GET' && req.url === '/api/mail/readers') a = { status: 200, body: { active, pending: 1, subscribe_url: `${BASE}/subscribe/${h.HOST}`, manage_url: `${BASE}/readers` } };
    else if (req.method === 'GET' && req.url === '/api/mail/import/token') a = { status: 200, body: { token: TOKEN, verified_url: verified, verified_at: verified ? 1 : null } };
    else if (req.method === 'POST' && req.url === '/api/mail/import/verify') { verified = body.source_url === SOURCE ? SOURCE : null; a = { status: 200, body: { ok: !!verified, token: TOKEN, verified_url: verified } }; }
    else if (req.method === 'POST' && req.url === '/api/mail/import') a = { status: 200, body: { import_id: 'imp1', rows: 121, pending: 118, dropped: { inactive: 2, suppressed: 1 }, verified: body.source_url === SOURCE } };
    else if (req.method === 'POST' && req.url === '/api/mail/profile') a = { status: 200, body: { name: body.name } };
    else a = { status: 404, body: { detail: 'no such route' } };
    res.writeHead(a.status, { 'Content-Type': 'application/json', ...(a.headers ?? {}) });
    res.end(JSON.stringify(a.body ?? { detail: 'nope' }));
  });
});
await new Promise((r) => relay.listen(PORT, '127.0.0.1', r));
const since = () => seen.length;
const at = (n, url) => seen.slice(n).filter((r) => r.url === url);
const sends = (n) => at(n, '/api/mail/send');
const polls = (n) => seen.slice(n).filter((r) => r.url.startsWith('/api/mail/jobs/'));
const arrivedSends = (n, count) => h.until(`${count} send call(s)`, () => sends(n).length >= count);

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
  yes(await scry(`(~(has by .^((map @uvH [@da @ud @ud]) %gx /=keep-mail=/sent/noun)) ${id})`));
//  tries for a queued post, or ~
const queued = async (id) =>
  val(await scry(`=/  q  .^((list [id=@uvH tries=@ud again=?]) %gx /=keep-mail=/queue/noun)  (turn (skim q |=([i=@uvH * *] =(i ${id}))) |=([* t=@ud *] t))`));
//  what the writer sees on the read page
const tag = async (id) => (await host.get(`/keep/read/${id}/${h.HOST}`)).body;
const page = async () => (await host.get('/keep/mail')).body;

const post = async (title, lists) => {
  await h.poke(host, `[%post md+'c8 body ${TAG}' \`'${title}' 'cc0' (sy ~[${lists}])]`);
  return h.until(`host to publish ${title}`, async () =>
    new RegExp(`/keep/read/(0v[^/"]+)/${h.HOST}"[^>]*>${title}<`).exec((await host.get(`/keep/ship/${h.HOST}`)).body)?.[1]);
};

//  self-prepare: the fleet is shared, and the counts assume this list alone.
//  a list of cords prints as <|a b c|>
for (let pass = 0; pass < 5; pass++) {
  const out = val(await scry('~(tap in ~(key by .^((map @t @da) %gx /=keep-mail=/subs/noun)))'));
  const left = (/<\|([\s\S]*)\|>/.exec(out)?.[1] ?? '').split(/\s+/).filter(Boolean);
  if (!left.length) break;
  for (const a of left) await mail(`[%remove '${a}']`);
}
await mail(`[%reset ~]`);

//  ---- setup: the key, the name, the proof token --------------------------------

let n = since();
await mail(`[%config ['${BASE}' '${KEY}']]`);
s.check('C8.0 saving the key asks the relay who confirmed and for the proof token', await h.got(h.until('two calls', () =>
  at(n, '/api/mail/readers').some((r) => r.auth === `Bearer ${KEY}`) && at(n, '/api/mail/import/token').length >= 1)));
s.check('C8.0b the mail page hides the key, shows no token, and sends the writer to the sync page to claim a Substack',
  await h.got(h.until('proof fetched', async () => (await page()).includes('/keep/sync')))
  && (await page()).includes(`data-key="${KEY}"`) && !(await page()).includes(`key: ${KEY}`) && !(await page()).includes(TOKEN));
s.check('C8.0c the writer\'s public page carries no subscribe form',
  !(await host.get(`/keep/ship/${h.HOST}`)).body.includes('/subscribe/'));
n = since();
await mail(`[%name 'C8 Writer']`);
s.check('C8.0d the name goes to the relay', await h.got(h.until('profile call', () => at(n, '/api/mail/profile').some((r) => r.name === 'C8 Writer')))
  && (await page()).includes('value="C8 Writer"'));

//  ---- the import: one form, three states ----------------------------------

n = since();
await mail(`[%import '${readers.join('\\0a')}' '']`);
s.check('C8.1 the list lands on the ship as waiting readers', await h.got(h.until('120 waiting', async () => (await page()).includes('120 waiting'))));
s.check('C8.1b and is handed to the relay in the same click, no proof needed',
  await h.got(h.until('import call', () => at(n, '/api/mail/import').length === 1))
    && at(n, '/api/mail/import')[0].source_url === '' && at(n, '/api/mail/import')[0].csv.includes(readers[3]));
s.check('C8.1c the card says done, in days', await h.got(h.until('done', async () => (await page()).includes('118 readers will be asked to re-confirm over the next 1 day'))));
s.check('C8.1d proof is required: with no Substack claimed the page points at sync and shows no token',
  (await page()).includes('/keep/sync') && (await page()).includes('Nothing can be imported') && !(await page()).includes(TOKEN));
n = since();
await mail(`[%import 'solo-${TAG}@x.test' '']`);
s.check('C8.1e a single address is added the same way and handed to the relay',
  await h.got(h.until('added', () => hasSub(`solo-${TAG}@x.test`)))
    && await h.got(h.until('import call', () => at(n, '/api/mail/import').some((r) => r.csv === `solo-${TAG}@x.test`))));
await mail(`[%remove 'solo-${TAG}@x.test']`);
await mail(`[%reset ~]`);
n = since();
await mail(`[%verify 'https://wrong.example/about']`);
s.check('C8.2 a wrong page is checked and refused',
  await h.got(h.until('verify call', () => at(n, '/api/mail/import/verify').length === 1))
    && await h.got(h.until('refusal shown', async () => (await page()).includes('name on the About page yet'))));
await mail(`[%verify '${SOURCE}']`);
s.check('C8.2b the right page earns the badge', await h.got(h.until('badge', async () => (await page()).includes('verified on Substack'))));

//  ---- a clean send: sync, then the post with the whole list -----------------

active = readers.filter((a) => a !== DROP && a !== UNCONFIRMED).concat([FORMED]);
const p1 = await post(`c8 one ${TAG}`, '%public');
n = since();
await mail(`[%send ${p1} %.n]`);
s.check('C8.3 the send asks the relay who confirmed first', await h.got(arrivedSends(n, 1))
  && at(n, '/api/mail/readers').length === 1 && seen.slice(n).findIndex((r) => r.url === '/api/mail/readers') < seen.slice(n).findIndex((r) => r.url === '/api/mail/send'));
const call = sends(n)[0];
s.check('C8.3b a reader who confirmed through the form is merged in and mailed', await hasSub(FORMED) && call.to.includes(FORMED));
s.check('C8.3c bearer key, full patp, post id, the whole list, title as subject, markdown as text, html',
  call.auth === `Bearer ${KEY}` && call.patp === h.HOST && call.id === p1 && call.again === false && call.to.length === 121
    && call.subject === `c8 one ${TAG}` && call.text === `c8 body ${TAG}` && /<p>c8 body/.test(call.html),
  JSON.stringify({ auth: call.auth, patp: call.patp, id: call.id, n: call.to?.length, subject: call.subject }));
s.check('C8.4 a dropped address leaves the list', await h.got(h.until('pruned', async () => !(await hasSub(DROP)))));
s.check('C8.4b an unconfirmed one stays', await hasSub(UNCONFIRMED));
s.check('C8.4c the page shows readers and waiting', await h.got(h.until('counts', async () => (await page()).includes('119 readers · 1 waiting'))));
s.check('C8.5 the job is polled and a done job settles the post', await h.got(h.until('post sent', () => isSent(p1))));
s.check('C8.5b the poll carried the key', polls(n).length >= 1 && polls(n)[0].auth === `Bearer ${KEY}` && polls(n)[0].url.endsWith('/j1'));
s.check('C8.5c and the page says who it reached', (await tag(p1)).includes('✉ sent to 2 readers'));

n = since();
await mail(`[%send ${p1} %.n]`);
s.check('C8.6 sending a sent post again is a no-op', await h.got(h.stays('no send call', () => sends(n).length === 0, { hold: 6000 })));
await mail(`[%send ${p1} %.y]`);
s.check('C8.6b unless the writer says again, which the relay is told', await h.got(arrivedSends(n, 1)) && sends(n)[0].again === true);
await h.until('resent', () => isSent(p1));

//  ---- publish and mail in one click ------------------------------------------

n = since();
await h.poke(host, `[%mailpost md+'c8 body ${TAG}' \`'c8 mailpost ${TAG}' 'cc0' (sy ~[%public])]`);
s.check('C8.7 a mailpost publishes and sends without a second click',
  await h.got(arrivedSends(n, 1)) && sends(n)[0].subject === `c8 mailpost ${TAG}`);
const pm = sends(n)[0].id;
await h.until('mailpost sent', () => isSent(pm));

//  ---- the job fails: surfaced in the writer's words --------------------------

jobAnswer = (id) => ({ status: 200, body: { job: id, status: 'failed', requested: 2, sent: 0, failed: 0, queued: 2, error: 'sending is suspended pending review' } });
const p2 = await post(`c8 two ${TAG}`, '%public');
await mail(`[%send ${p2} %.n]`);
s.check('C8.8 a failed job says why, in plain words', await h.got(h.until('failed', async () => (await tag(p2)).includes('Keep paused your sending for review'))));
s.check('C8.8b without marking it sent or queuing it, and the verb is back', !(await isSent(p2)) && (await queued(p2)) === '~' && (await tag(p2)).includes('email this'), await queued(p2));
jobAnswer = (id) => ({ status: 200, body: { job: id, status: 'done', requested: 2, sent: 2, failed: 0, queued: 0, error: null } });

//  ---- a bad key: hard fail, nothing marked, no retry -----------------------

const good = answer;
answer = () => ({ status: 401, body: { detail: 'missing or unknown email key' } });
const p3 = await post(`c8 three ${TAG}`, '%public');
n = since();
await mail(`[%send ${p3} %.n]`);
await arrivedSends(n, 1);
s.check('C8.9 a 401 fails the post and names the key', await h.got(h.until('failed', async () => (await tag(p3)).includes('recognize this ship'))));
s.check('C8.9b without marking it sent or queuing it', !(await isSent(p3)) && (await queued(p3)) === '~', await queued(p3));
s.check('C8.9c and without another call', await h.got(h.stays('no more calls', () => sends(n).length === 1 && polls(n).length === 0, { hold: 6000 })));

//  ---- the relay is paused: queued for later --------------------------------

answer = () => ({ status: 503, headers: { 'Retry-After': '1800' }, body: { detail: 'sending is paused platform-wide (kill switch)' } });
const p4 = await post(`c8 four ${TAG}`, '%public');
n = since();
await mail(`[%send ${p4} %.n]`);
await arrivedSends(n, 1);
s.check('C8.10 a 503 queues the post, first try counted',
  await h.got(h.until('queued', async () => /^~\[1\]$/.test(await queued(p4)))), await queued(p4));
s.check('C8.10b and the page says so', !(await isSent(p4)) && (await tag(p4)).includes('will send shortly'));

//  ---- nobody confirmed: not a send -----------------------------------------

answer = (body) => ({ status: 202, body: { job: `j${++jobs}`, status: 'done', recipients: 0, dropped: [], unconfirmed: body.to } });
const p5 = await post(`c8 five ${TAG}`, '%public');
n = since();
await mail(`[%send ${p5} %.n]`);
await arrivedSends(n, 1);
s.check('C8.11 a job with no recipients is not a mailing', await h.got(h.stays('never sent, never polled', async () =>
  !(await isSent(p5)) && polls(n).length === 0, { hold: 12000 })));
s.check('C8.11b the verb stays', (await tag(p5)).includes('✉ email this') && !(await tag(p5)).includes('sent to'));
answer = good;

//  ---- the leak guard ------------------------------------------------------

await h.poke(host, `[%list %c8gated (sy ~[${h.PEER}])]`);
const p6 = await post(`c8 gated ${TAG}`, '%c8gated');
n = since();
await mail(`[%send ${p6} %.n]`).catch(() => {});
s.check('C8.12 a gated post never reaches the relay', await h.got(h.stays('no call', () => sends(n).length === 0, { hold: 6000 })));
//  the control: a public post goes out
const p7 = await post(`c8 seven ${TAG}`, '%public');
await mail(`[%send ${p7} %.n]`);
s.check('C8.12b while a public one still does', await h.got(arrivedSends(n, 1)));
await h.until('control sent', () => isSent(p7));

//  ---- remove -----------------------------------------------------------------

await mail(`[%remove '${readers[1]}']`);
s.check('C8.13 remove takes a reader off the ship', await h.got(h.until('gone', async () => !(await hasSub(readers[1])))));

//  leave the fleet as found: a gated list with the peer in it changes what
//  the peer may re-host from this ship, and c2 and c5 read that. a queued
//  post would fire its retry into a dead stub in thirty minutes; deleting
//  the post makes that retry a no-op.
await h.poke(host, `[%unlist %c8gated]`);
for (const id of [p1, pm, p2, p3, p4, p5, p6, p7]) await h.poke(host, `[%delete ${id}]`);
for (const a of readers.concat([FORMED])) await mail(`[%remove '${a}']`);
await mail(`[%reset ~]`);
await mail(`[%name '']`);

relay.close();
process.exit(s.done() ? 1 : 0);
