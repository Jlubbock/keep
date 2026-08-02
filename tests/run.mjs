//  run.mjs — one invocation, three layers, one count.
//
//    node tests/run.mjs              everything
//    node tests/run.mjs pure         layer A only  (pure | single | multi)
//    node tests/run.mjs --list       the manifest
//    node tests/run.mjs --stale-ok   run against stale goldens anyway
//    node tests/run.mjs --fresh      re-clone run/ from golden/ first

import { execSync } from 'node:child_process';
import * as h from './harness.mjs';

//  Declared, not globbed. Layer C shares one mutating fleet, so order is part
//  of the suite; `ships` says who must be up.
const SCENARIOS = [
  { file: 'c1-follow.mjs', ships: [h.HOST, h.PEER] },
  { file: 'c2-gating.mjs', ships: [h.HOST, h.PEER, h.WITNESS],
    note: 'needs a second member — one member cannot show eviction is targeted' },
  { file: 'c3-forgery.mjs', ships: [h.HOST, h.PEER], note: 'needs %rogue running on the peer' },
  //  LAST, and it must stay last: it nukes %keep on both ships to clear the
  //  subscriptions the scenarios above build, which would otherwise make its
  //  own assertions vacuously true.
  { file: 'c4-announce.mjs', ships: [h.HOST, h.PEER], note: 'DESTRUCTIVE: nukes %keep on both ships' },
];

const args = process.argv.slice(2);
const fresh = args.includes('--fresh');
const layers = args.filter((a) => !a.startsWith('--'));
const want = (l) => layers.length === 0 || layers.includes(l);

if (args.includes('--list')) {
  console.log('A  tests/pure/*.hoon        test arms via mcp/run-tests');
  console.log('B  tests/ted/b-jael.hoon    thread via dojo/run-thread');
  for (const s of SCENARIOS) {
    console.log(`C  multi/${s.file.padEnd(20)} ${s.ships.join(' ')}${s.note ? '  — ' + s.note : ''}`);
  }
  process.exit(0);
}

const built = h.checkBuilt();
if (built.length) {
  console.error('\nUNBUILT — dist/ does not match desk/. Refusing to run.\n');
  for (const l of built.slice(0, 20)) console.error(`    ${l}`);
  console.error('\n  Fix: ./build.sh\n');
  process.exit(2);
}

const stale = h.checkBaked();
if (stale.length && !args.includes('--stale-ok')) {
  console.error('\nSTALE GOLDEN PIERS — refusing to run.\n');
  console.error('  A clone runs whatever bake.mjs last committed, so running now');
  console.error('  would test OLD desk source, pass, and tell you nothing.\n');
  for (const l of stale.slice(0, 20)) console.error(`    ${l}`);
  if (stale.length > 20) console.error(`    … and ${stale.length - 20} more`);
  console.error('\n  Fix:      node tests/bake.mjs');
  console.error('  Override: node tests/run.mjs --stale-ok\n');
  process.exit(2);
}
if (stale.length) console.log(`\n!! ${stale.length} STALE file(s) — --stale-ok given\n`);

const totals = { pass: 0, fail: 0 };
const report = [];

//  ---------- A and B: one sync, one commit, both on the host ----------
if (want('pure') || want('single')) {
  console.log('\n=== layers A + B ===');
  await h.up([h.HOST], { fresh });
  const host = await h.connect(h.HOST);
  console.log(`  synced ${h.syncTests(h.mountOf(h.SHIPS[h.HOST].name)).length} files`);
  console.log(`  commit: ${(await h.commit(host)).slice(0, 70)}`);

  if (want('pure')) {
    const out = await host.call('mcp/run-tests', { desk: h.DESK, path: '/tests/pure' });
    const rows = h.parseResults(out.text);
    const bad = rows.filter((r) => r.status !== 'OK');
    totals.pass += rows.length - bad.length;
    totals.fail += bad.length;
    report.push(`  A  ${rows.length - bad.length}/${rows.length}  tests/pure`);
    for (const b of bad) console.log(`     ${b.status} ${b.path}`);
  }

  if (want('single')) {
    //  a THREAD, not test arms: mcp/run-tests fires arms inside +mule, whose
    //  null scry gate blocks every .^ — and layer B is nothing but scries.
    const out = await host.call('dojo/run-thread', { desk: h.DESK, path: '/ted/b-jael', arg: '~' });
    const text = out.text.replace(/\\n/g, '\n');
    const m = /layer-B: (\d+)\/(\d+) green/.exec(text);
    if (m) {
      totals.pass += +m[1]; totals.fail += +m[2] - +m[1];
      report.push(`  B  ${m[1]}/${m[2]}  ted/b-jael`);
      for (const l of text.split('\n').filter((l) => l.startsWith('FAIL'))) console.log(`     ${l}`);
    } else {
      totals.fail += 1;
      report.push(`  B  ERROR  ted/b-jael`);
      console.log(`     ${text.slice(0, 300)}`);
    }
  }
}

//  ---------- C: declared order, shared fleet ----------
if (want('multi')) {
  console.log('\n=== layer C ===');
  for (const sc of SCENARIOS) {
    await h.up(sc.ships, { fresh });
    const t0 = Date.now();
    let code = 0, out = '';
    try { out = execSync(`node ${import.meta.dirname}/multi/${sc.file}`, { encoding: 'utf8' }); }
    catch (e) { code = e.status ?? 1; out = (e.stdout ?? '') + (e.stderr ?? ''); }
    const m = /: (\d+)\/(\d+) green/.exec(out);
    const secs = ((Date.now() - t0) / 1000).toFixed(0);
    if (m) {
      totals.pass += +m[1]; totals.fail += +m[2] - +m[1];
      report.push(`  C  ${m[1]}/${m[2]}  ${sc.file}  (${secs}s)`);
      console.log(`  ${code ? 'FAIL' : 'ok  '} ${sc.file.padEnd(20)} ${m[1]}/${m[2]}  ${secs}s`);
      for (const l of out.split('\n').filter((l) => l.startsWith('FAIL'))) console.log(`     ${l}`);
    } else {
      totals.fail += 1;
      report.push(`  C  ERROR  ${sc.file}`);
      console.log(`  ERR  ${sc.file}: ${out.trim().split('\n').pop()?.slice(0, 120)}`);
    }
  }
}

console.log('\n=== summary ===');
for (const l of report) console.log(l);
console.log(`\n${totals.pass} passed, ${totals.fail} failed`);
process.exit(totals.fail ? 1 : 0);
