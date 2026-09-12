//  C9 — substack identity, against a stub publication.
//
//    Tracking a publication is the claim. The host tracks a url; the peer
//    opens the host's page and judges the claim by reading <url>/about
//    ITSELF — there is no verifier to ask, so the stub must see one read
//    per judging ship. The stub is this process, serving an about page that
//    names the host, one that names the peer (the control: a page that
//    names a ship still fails for the wrong one), and a path that errors.
//    Its archive is empty, so the sync itself imports nothing.

import { createServer } from 'node:http';
import * as h from '../harness.mjs';

const PORT = 8098;
const BASE = `http://127.0.0.1:${PORT}`;
const NAME = `c9-${Date.now() % 100000}`;
const s = h.sheet('c9-substack');
const host = await h.connect(h.HOST);
const peer = await h.connect(h.PEER);

//  ---- the stub -------------------------------------------------------------

const seen = [];                  //  every request: {url, ua}
const pages = {
  '/good/about': `<html><body><p>Hello. I'm ${h.HOST} on Keep.</p></body></html>`,
  '/wrong/about': `<html><body><p>Hello. I'm ${h.PEER} on Keep.</p></body></html>`,
};
const stub = createServer((req, res) => {
  seen.push({ url: req.url, ua: req.headers['user-agent'] });
  const path = req.url.split('?')[0];
  if (path.endsWith('/api/v1/archive')) {
    res.writeHead(200, { 'Content-Type': 'application/json' }); res.end('[]'); return;
  }
  const body = pages[path];
  if (!body) { res.writeHead(500, { 'Content-Type': 'text/html' }); res.end('nope'); return; }
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end(body);
});
await new Promise((r) => stub.listen(PORT, '127.0.0.1', r));
const reads = (path) => seen.filter((r) => r.url === path).length;

//  ---- driving keep-sync ----------------------------------------------------

const sync = (m, expr) =>
  m.call('mcp/poke-our-agent', { agent: 'keep-sync', mark: 'keep-sync-action', data: expr });
const track = (url) => sync(host, `[%track %${NAME} '${url}' ~h1 '' (sy ~[%public])]`);
const untrack = () => sync(host, `[%untrack %${NAME}]`);
//  the value under the echoed prompt
const val = (t) => { try { return JSON.parse(t)['dojo-output'].split('\n').slice(1).join('\n').trim(); } catch { return t.trim(); } };
//  what `m` holds about `who`'s claim of `url`: ~, or [proof wen]
const badgeOf = async (m, who, url) =>
  val(await h.dojo(m, `(~(get by .^((map [@p @t] [proof=?(%wait %yes %no %down) wen=@da]) %gx /=keep-sync=/badges/noun)) [${who} '${url}'])`));
const proofIs = async (m, url, p) => new RegExp(`%${p}\\b`).test(await badgeOf(m, h.HOST, url));
const noBadge = async (m, url) => (await badgeOf(m, h.HOST, url)) === '~';
const page = async (m, who) => (await m.get(`/keep/ship/${who}`)).body;
const line = new RegExp(`This publication is also on Keep \\(keep-posting\\.com\\), as ${h.HOST}\\.`);

//  ---- a claim the about page backs --------------------------------------------

const GOOD = `${BASE}/good`;
await track(GOOD);
s.check('C9.1 tracking is claiming: the host judges its own publication',
  await h.got(h.until('host to read /good/about', () => proofIs(host, GOOD, 'yes'))));
s.check('C9.1b as keep-sync, from the about page',
  seen.some((r) => r.url === '/good/about' && r.ua === 'keep-sync'));
s.check('C9.1c a verified row shows no line to paste',
  !line.test((await host.get('/keep/sync')).body));

const before = reads('/good/about');
await page(peer, h.HOST);
s.check('C9.2 the peer reads the claim off the host and judges it',
  await h.got(h.until('peer to judge the claim', () => proofIs(peer, GOOD, 'yes'))));
s.check('C9.2b by reading the about page itself',
  reads('/good/about') > before, `${reads('/good/about') - before} peer read(s)`);
s.check('C9.2c and says so on the page',
  await h.got(h.until('the page to render the badge', async () => (await page(peer, h.HOST)).includes('✓ Verified'))));

//  ---- the cache ---------------------------------------------------------------

const cached = reads('/good/about');
await page(peer, h.HOST);
s.check('C9.3 another look inside a day answers from the cache',
  await h.got(h.stays('no new about read', () => reads('/good/about') === cached, { hold: 5000 })));
await sync(peer, `[%look ${h.HOST} %.y]`);
s.check('C9.3b a forced check reads it again',
  await h.got(h.until('a fresh about read', () => reads('/good/about') > cached)));

//  ---- the control: a page that names the wrong ship -------------------------------

const WRONG = `${BASE}/wrong`;
await track(WRONG);
s.check('C9.4 the host sees its own claim fail',
  await h.got(h.until('host to judge /wrong', () => proofIs(host, WRONG, 'no'))));
s.check('C9.4b and the sync page now shows the line to paste',
  line.test((await host.get('/keep/sync')).body));
s.check('C9.5 the peer\'s parked keen fires on the new claim, and it fails there too',
  await h.got(h.until('peer to judge /wrong', () => proofIs(peer, WRONG, 'no'))));
s.check('C9.5b the old claim is gone from the peer',
  await h.got(h.until('peer to drop /good', () => noBadge(peer, GOOD))));
s.check('C9.5c and the page says so',
  (await page(peer, h.HOST)).includes('Unverified'));

//  ---- an about page that does not answer ---------------------------------------

const DOWN = `${BASE}/down`;
await track(DOWN);
s.check('C9.6 an unreachable about page is %down, not %no',
  await h.got(h.until('peer to give up on /down', () => proofIs(peer, DOWN, 'down'))));

//  ---- withdrawal ----------------------------------------------------------------

await untrack();
s.check('C9.7 untracking drops the host\'s own badge',
  await h.got(h.until('host badge to go', () => noBadge(host, DOWN))));
s.check('C9.8 and the peer\'s', await h.got(h.until('peer badge to go', () => noBadge(peer, DOWN))));
s.check('C9.8b the page no longer shows one', !(await page(peer, h.HOST)).includes('k-badge'));

stub.close();
process.exit(s.done() ? 1 : 0);
