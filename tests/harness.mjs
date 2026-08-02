//  harness.mjs — the whole rig: MCP client, fleet, sync, staleness guards.

import { readdirSync, statSync, copyFileSync, mkdirSync, rmSync, existsSync, readFileSync } from 'node:fs';
import { join, relative } from 'node:path';
import { execSync, spawn } from 'node:child_process';

export const ROOT = '/Users/user/solarsystem';
export const REPO = `${ROOT}/keep`;
export const FLEET = `${ROOT}/fleet/keep`;
export const DESK = 'keep';
export const AGENT = 'keep';

//  Ports are pinned, and deliberately not the marketplace suite's 8090-8092:
//  these are different @p, so ames will not collide either, and the two suites
//  can run at the same time.
//
//  `code` is each ship's +code, read from its dojo once and pasted here. A
//  fakeship's is stable for the life of the pier.
//  GALAXIES, not stars. Two stars under absent galaxies cannot route to each
//  other — measured: a clay remote scry of guaranteed content timed out, while
//  both ships were healthy locally. Galaxies route directly.
export const SHIPS = {
  '~dev': { name: 'dev', port: 8095, code: 'magsub-micsev-bacmug-moldex' },
  '~lex': { name: 'lex', port: 8096, code: 'tonhet-diltyd-dotsup-sabnum' },
  '~mun': { name: 'mun', port: 8097, code: 'batwed-fosdet-nidnet-tarlet' },
};

//  HOST publishes and judges; PEER reads, is gated, and runs the rogue.
//  WITNESS is a second member of the same list, never evicted — it is what
//  turns "the evicted member stopped receiving" into "and nobody else noticed".
export const HOST = '~dev';
export const PEER = '~lex';
export const WITNESS = '~mun';

const pier = (n) => `${FLEET}/run/${n}`;
const golden = (n) => `${FLEET}/golden/${n}`;
export const mountOf = (n) => `${pier(n)}/${DESK}`;
export const goldenMountOf = (n) => `${golden(n)}/${DESK}`;

//  ---------- MCP client ----------

export class Mcp {
  constructor(patp) {
    const s = SHIPS[patp];
    if (!s) throw new Error(`unknown ship ${patp}`);
    this.patp = patp;
    this.url = `http://localhost:${s.port}`;
    this.code = s.code;
    this.cookie = null;
    this.session = null;
    this.id = 0;
  }

  async login() {
    if (!this.code) {
      throw new Error(`${this.patp}: no +code in harness.mjs SHIPS — read it from the ship's dojo`);
    }
    const res = await fetch(`${this.url}/~/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ password: this.code }).toString(),
      redirect: 'manual',
    });
    const set = res.headers.get('set-cookie');
    if (!set) throw new Error(`${this.patp}: login gave no cookie (HTTP ${res.status})`);
    this.cookie = set.split(';')[0];
    return this.cookie;
  }

  //  the transport answers plain JSON or a single SSE frame, server's choice
  static #parse(text) {
    const t = text.trim();
    if (!t) return null;
    if (t.startsWith('{')) return JSON.parse(t);
    const line = t.split('\n').find((l) => l.startsWith('data:'));
    if (!line) throw new Error(`unparseable MCP response: ${t.slice(0, 300)}`);
    return JSON.parse(line.slice(5).trim());
  }

  //  timeout, because a .^ that BLOCKS never answers: spider does not crash,
  //  it waits, and an untimed fetch would wait with it forever.
  async rpc(method, params, { notify = false, timeout = 300000 } = {}) {
    const body = { jsonrpc: '2.0', method };
    if (params !== undefined) body.params = params;
    if (!notify) body.id = ++this.id;
    const headers = { 'Content-Type': 'application/json', Accept: 'application/json, text/event-stream' };
    if (this.cookie) headers.Cookie = this.cookie;
    if (this.session) headers['Mcp-Session-Id'] = this.session;
    const res = await fetch(`${this.url}/mcp`, {
      method: 'POST', headers, body: JSON.stringify(body), signal: AbortSignal.timeout(timeout),
    });
    const sid = res.headers.get('mcp-session-id');
    if (sid) this.session = sid;
    if (notify) return null;
    const text = await res.text();
    if (!res.ok) throw new Error(`${this.patp}: ${method} -> HTTP ${res.status}: ${text.slice(0, 300)}`);
    const out = Mcp.#parse(text);
    if (out?.error) throw new Error(`${this.patp}: ${method} -> ${JSON.stringify(out.error)}`);
    return out?.result;
  }

  async connect() {
    if (!this.cookie) await this.login();
    await this.rpc('initialize', {
      protocolVersion: '2025-06-18', capabilities: {},
      clientInfo: { name: 'keep-tests', version: '0.0.1' },
    });
    await this.rpc('notifications/initialized', {}, { notify: true });
    return this;
  }

  async call(name, args, opts) {
    const out = await this.rpc('tools/call', { name, arguments: args }, opts);
    const text = (out?.content ?? []).filter((c) => c.type === 'text').map((c) => c.text).join('\n');
    if (out?.isError) throw new Error(`${this.patp}: ${name} errored: ${text}`);
    return { text, raw: out };
  }

  //  GET a page the agent serves. Every /keep route but the eyre-cached
  //  public ones needs the session cookie.
  async get(path) {
    if (!this.cookie) await this.login();
    const res = await fetch(`${this.url}${path}`, { headers: { Cookie: this.cookie } });
    return { status: res.status, body: await res.text() };
  }
}

export const connect = (patp) => new Mcp(patp).connect();

//  ---------- driving the agent ----------

export const poke = (m, expr, mark = 'keep-action') =>
  m.call('mcp/poke-our-agent', { agent: AGENT, mark, data: expr });

//  keep's on-peek answers `noun` marks and its UI is server-rendered manx, so
//  eyre's /~/scry and channel API can render neither. The dojo can.
export const dojo = async (m, expr) => (await m.call('dojo/command', { command: expr })).text;

//  ---------- reading agent state ----------
//
//    All through the dojo, and all one-liners: `dojo/command` evaluates a
//    single hoon expression, which `=/` chains fine.

//  The address an item is served at. +base pins the AGENT, so a reader only
//  ever fetches from that agent on the author's ship — which is why a forgery
//  needs a peer running different code, not just a doctored pointer.
export const entryHoon = (ship, id, agent = 'keep') =>
  `[${ship} [%g %x '1' %${agent} %$ '1' %item '${id}' ~]]`;

const yes = (text) => /%\.y/.test(text);

//  (unit verdict) — ~ unjudged; else %good, %forged, or %cold (no key for
//  the life the head claims, so the signature was never checked at all)
export const checkedOf = (m, entry) =>
  dojo(m, `=/  c  .^((map [@p path] ?(%good %forged %cold)) %gx /=keep=/checked/noun)  (~(get by c) ${entry})`);

export const verified = async (m, entry) => /\[~ %good\]/.test(await checkedOf(m, entry));
export const forged = async (m, entry) => /\[~ %forged\]/.test(await checkedOf(m, entry));
export const uncheckable = async (m, entry) => /\[~ %cold\]/.test(await checkedOf(m, entry));

//  the head as SERVED — who it names and at what life, before any verdict.
//  a %cold entry is only interesting if the head really did claim someone else.
export const claimsOf = (m, entry) =>
  dojo(m, `=/  hs  .^((map [@p path] [wen=@da who=@p lyfe=@ud *]) %gx /=keep=/heads/noun)  (~(get by hs) ${entry})`);

export const claims = async (m, entry, who, lyfe) => {
  const out = await claimsOf(m, entry);
  return out.includes(who) && new RegExp(`\\b${lyfe}\\b`).test(out);
};

export const tails = async (m, who) =>
  yes(await dojo(m, `(~(has by .^((map [@p path] @ud) %gx /=keep=/subs/noun)) [${who} /index])`));

export const follows = async (m, who) =>
  yes(await dojo(m, `(~(has in .^((set @p) %gx /=keep=/follows/noun)) ${who})`));

export const holds = async (m, id) =>
  yes(await dojo(m, `(~(has by .^((map @uvH *) %gx /=keep=/posts/noun)) ${id})`));

//  Poll to convergence. Never sleep a fixed delay: remote scry is async with
//  no completion signal, and fixed sleeps are what make a cross-ship suite flaky.
export async function until(label, fn, { timeout = 40000, every = 500 } = {}) {
  const deadline = Date.now() + timeout;
  for (;;) {
    const got = await fn();
    if (got) return got;
    if (Date.now() > deadline) throw new Error(`timed out waiting for: ${label}`);
    await new Promise((r) => setTimeout(r, every));
  }
}

//  Hold a condition, for asserting something did NOT happen. Absence at t=0
//  only means the packet is still in flight.
export async function stays(label, fn, { hold = 10000, every = 1000 } = {}) {
  const deadline = Date.now() + hold;
  while (Date.now() < deadline) {
    if (!(await fn())) throw new Error(`condition broke while holding: ${label}`);
    await new Promise((r) => setTimeout(r, every));
  }
  return true;
}

//  Resolve a check to a boolean. A timed-out `until` must FAIL that check, not
//  throw: an uncaught rejection kills the scenario before its sheet prints, so
//  every assertion that already passed is lost with it.
export const got = (p) => Promise.resolve(p).then(() => true, () => false);

export function sheet(name) {
  const rows = [];
  return {
    check(id, ok, note = '') {
      rows.push({ id, ok });
      console.log(`${ok ? 'OK  ' : 'FAIL'} ${id}${note ? '  ' + note : ''}`);
    },
    done() {
      const bad = rows.filter((r) => !r.ok).length;
      console.log(`${name}: ${rows.length - bad}/${rows.length} green`);
      return bad;
    },
  };
}

//  ---------- the fleet ----------

//  Ask eyre, not the filesystem. A hard-killed pier leaves .http.ports behind,
//  so a file check reports a dead ship as up and boot() never runs.
export async function isUp(n) {
  const { port } = Object.values(SHIPS).find((s) => s.name === n) ?? {};
  if (!port) return false;
  try {
    const res = await fetch(`http://localhost:${port}/~/login`, { signal: AbortSignal.timeout(1500) });
    return res.status < 500;
  } catch { return false; }
}

//  Match the pier PATH, not `<pier>/.run`: the serf's argv[0] is whatever the
//  launcher used — often relative — but its --snap-dir is always absolute.
export function kill(n) {
  try { execSync(`pkill -f '${pier(n)}' 2>/dev/null || true`); } catch {}
}

//  cp -c is an APFS clone: ~0.1s for a 1GB pier. Boot (~40s) is the only cost.
export function clone(n) {
  kill(n);
  //  pkill returns before the serf does, and a dying ship recreates its pier —
  //  cp -cR into that leftover directory nests golden/<n> inside run/<n>
  execSync('sleep 2');
  if (existsSync(pier(n))) rmSync(pier(n), { recursive: true, force: true });
  if (!existsSync(golden(n))) throw new Error(`no golden pier at ${golden(n)}`);
  //  cp does not create intermediate directories, and run/ does not exist
  //  until the first clone
  mkdirSync(`${FLEET}/run`, { recursive: true });
  execSync(`cp -cR ${golden(n)} ${pier(n)}`);
}

export async function boot(n, { timeout = 180000 } = {}) {
  const { port } = Object.values(SHIPS).find((s) => s.name === n) ?? {};
  if (!port) throw new Error(`unknown ship ~${n}`);
  spawn(`${pier(n)}/.run`, ['-d', '-L', '--http-port', String(port), pier(n)],
        { detached: true, stdio: 'ignore' }).unref();
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    if (await isUp(n)) return port;
    await new Promise((r) => setTimeout(r, 1500));
  }
  throw new Error(`~${n} did not come up on ${port} within ${timeout}ms`);
}

export async function up(patps, { fresh = false } = {}) {
  const names = patps.map((p) => SHIPS[p].name);
  for (const n of names) if (fresh || !existsSync(pier(n))) clone(n);
  const live = await Promise.all(names.map(isUp));
  await Promise.all(names.filter((_, i) => !live[i]).map((n) => boot(n)));
  return names;
}

export const down = (patps) => patps.forEach((p) => kill(SHIPS[p].name));

//  ---------- sync ----------

function filesUnder(dir, base = dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).flatMap((e) => {
    const full = join(dir, e);
    return statSync(full).isDirectory() ? filesUnder(full, base) : [relative(base, full)];
  });
}

//  Mirror the hoon layers into a desk mount. Test arms may live anywhere, but
//  threads must sit at /ted and agents at /app or nothing can build them.
//
//    tests/pure  ->  tests/pure    arms, run by mcp/run-tests
//    tests/ted   ->  ted           threads, run by dojo/run-thread
//    tests/app   ->  app           the rogue peer, started by |rein
export const SYNC = [['pure', 'tests/pure'], ['ted', 'ted'], ['app', 'app']];

//  Empty a desk mount without unmounting it. Clay mirrors the directory, so a
//  file left behind here is a file committed into the baseline — and the
//  staleness guard, which only checks that dist/ files MATCH, would not see it.
export function clearMount(mount) {
  for (const e of readdirSync(mount)) rmSync(join(mount, e), { recursive: true, force: true });
}

//  Every path a baked golden should contain, and nothing else.
export function expectedFiles() {
  const out = new Set(filesUnder(`${REPO}/dist`));
  for (const [src, dst] of SYNC) {
    for (const rel of filesUnder(`${REPO}/tests/${src}`)) out.add(`${dst}/${rel}`);
  }
  return out;
}

export function syncTests(mount) {
  //  mirror, not merge: a file deleted from the repo must leave the desk too,
  //  or a stale test keeps running and reporting green after its source is gone
  rmSync(join(mount, 'tests'), { recursive: true, force: true });
  const pushed = [];
  for (const [src, dst] of SYNC) {
    for (const rel of filesUnder(`${REPO}/tests/${src}`)) {
      const to = join(mount, dst, rel);
      mkdirSync(join(to, '..'), { recursive: true });
      copyFileSync(`${REPO}/tests/${src}/${rel}`, to);
      pushed.push(`${dst}/${rel}`);
    }
  }
  return pushed;
}

//  `no-changes-to-commit` is SUCCESS. And a lost response is not a lost write:
//  eyre drops responses on slow commits, so re-drive and read the retry.
export async function commit(m) {
  try {
    return (await m.call('mcp/commit-desk', { desk: DESK })).text;
  } catch (e) {
    if (/no-changes-to-commit/.test(e.message)) return 'no-changes-to-commit';
    if (!/terminated|socket|ECONNRESET|HTTPParser/i.test(e.message)) throw e;
    try { return `${(await m.call('mcp/commit-desk', { desk: DESK })).text} (after abort)`; }
    catch (e2) {
      if (!/no-changes-to-commit/.test(e2.message)) throw e2;
      return 'committed on first attempt; response lost';
    }
  }
}

//  run-tests prints a failing arm's status line twice, so dedupe by path or
//  every failure double-counts.
export function parseResults(text) {
  const rows = new Map();
  for (const line of text.split('\n')) {
    const m = /^(OK|FAILED|CRASHED)\s+(\S+)/.exec(line);
    if (m) rows.set(m[2], m[1]);
  }
  return [...rows].map(([path, status]) => ({ path, status }));
}

//  ---------- staleness ----------
//
//    Two hops separate an edit from what a test ship runs, and skipping either
//    gives a fully green run against code you no longer have.
//
//      desk/ + ui/  --./build.sh-->  dist/  --bake.mjs-->  golden/<n>/keep/

function diffTree(from, to, label) {
  const bad = [];
  for (const rel of filesUnder(from)) {
    const a = join(from, rel), b = join(to, rel);
    if (!existsSync(b)) bad.push(`${label}  MISSING  ${rel}`);
    else if (readFileSync(a).compare(readFileSync(b)) !== 0) bad.push(`${label}  DIFFERS  ${rel}`);
  }
  return bad;
}

export const checkBuilt = () => [
  ...diffTree(`${REPO}/desk`, `${REPO}/dist`, 'dist'),
  ...diffTree(`${REPO}/ui`, `${REPO}/dist/ui`, 'dist'),
];

export function checkBaked(patps = Object.keys(SHIPS)) {
  const bad = [];
  const expected = expectedFiles();
  for (const p of patps) {
    const mount = goldenMountOf(SHIPS[p].name);
    if (!existsSync(mount)) { bad.push(`${p}  NO %keep DESK in golden — run: node tests/bake.mjs`); continue; }
    bad.push(...diffTree(`${REPO}/dist`, mount, p));
    //  extras matter as much as mismatches: a file from some earlier desk that
    //  dist/ no longer has still compiles, still commits, and still runs
    for (const rel of filesUnder(mount)) {
      if (!expected.has(rel)) bad.push(`${p}  EXTRA    ${rel}`);
    }
  }
  return bad;
}
