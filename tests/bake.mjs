//  bake.mjs — put the current desk + tests INTO the golden piers.
//
//    Clones of golden/ boot with %keep already installed and committed, so a
//    scenario pays boot (~40s) and nothing else. Re-bake after ANY change to
//    desk/ or tests/ — a clone runs what was baked, not what is in the repo.
//
//    This is the only script that writes to golden/, and it only ever touches
//    the %keep desk there. %shop, %mcp and %pals belong to the marketplace
//    suite and are left alone.
//
//    node tests/bake.mjs           both ships
//    node tests/bake.mjs zod       one

import { existsSync, cpSync } from 'node:fs';
import { execSync } from 'node:child_process';
import * as h from './harness.mjs';

const want = process.argv.slice(2).filter((a) => !a.startsWith('--'));
const ships = Object.entries(h.SHIPS)
  .map(([patp, s]) => ({ patp, ...s }))
  .filter((s) => want.length === 0 || want.includes(s.name));

const built = h.checkBuilt();
if (built.length) {
  console.error('dist/ does not match desk/ — run ./build.sh first:\n');
  for (const l of built.slice(0, 20)) console.error(`    ${l}`);
  process.exit(2);
}

let bad = 0;
for (const s of ships) {
  const pier = `${h.FLEET}/golden/${s.name}`;
  const mount = h.goldenMountOf(s.name);
  console.log(`\n=== ~${s.name} ===`);

  //  the golden must be the only thing on its port
  h.kill(s.name);
  execSync(`pkill -f '${h.FLEET}/golden/${s.name}/.run' 2>/dev/null || true`);
  await new Promise((r) => setTimeout(r, 2000));

  execSync(`${pier}/.run -d -L --http-port ${s.port} ${pier} >/dev/null 2>&1 &`);
  //  ask eyre, not .http.ports — a hard-killed pier leaves that file behind.
  //  Generous: these piers replay their log before serving anything.
  const deadline = Date.now() + 300000;
  let live = false;
  while (Date.now() < deadline && !(live = await h.isUp(s.name))) {
    await new Promise((r) => setTimeout(r, 3000));
  }
  if (!live) { console.log('  never came up'); bad++; continue; }
  console.log(`  booted on ${s.port}`);

  const m = await h.connect(s.patp);

  //  first bake only: the desk does not exist yet. Both are no-ops afterwards
  //  and both report the failure as an error, so neither is fatal here.
  for (const [tool, label] of [['dojo/new-desk', 'new-desk'], ['dojo/mount-desk', 'mount-desk']]) {
    try { await m.call(tool, { desk: h.DESK }); console.log(`  ${label}`); }
    catch { console.log(`  ${label} (already)`); }
  }
  const waited = Date.now() + 30000;
  while (Date.now() < waited && !existsSync(mount)) await new Promise((r) => setTimeout(r, 1000));
  if (!existsSync(mount)) { console.log(`  %keep never mounted at ${mount}`); bad++; continue; }

  //  clear first. Copying over the top MERGES: anything the desk held that
  //  dist/ does not — a file from an earlier version, or from whoever this
  //  desk was installed from — would survive and get committed.
  h.clearMount(mount);
  cpSync(`${h.REPO}/dist`, mount, { recursive: true });
  const pushed = h.syncTests(mount);
  console.log(`  cleared, synced dist/ + ${pushed.length} test files`);

  console.log(`  commit: ${(await h.commit(m)).slice(0, 60)}`);

  try { await m.call('mcp/install-app', { ship: s.patp, desk: h.DESK }); console.log('  installed'); }
  catch (e) { console.log(`  install: ${e.message.slice(0, 90)}`); }

  //  %rogue is a test agent and is deliberately NOT in desk.bill, so nothing
  //  starts it on install. C3 needs it running on the peer.
  try { await h.dojo(m, '|rein %keep [& %keep] [& %rogue]'); console.log('  rogue started'); }
  catch (e) { console.log(`  rein: ${e.message.slice(0, 90)}`); }

  //  a baseline nobody can build is worse than none: the staleness guard would
  //  then certify it as fresh.
  for (const p of ['/app/keep/hoon', '/app/rogue/hoon', '/lib/keep-core/hoon', '/ted/b-jael/hoon',
                   '/tests/pure/sain/hoon', '/tests/pure/view/hoon', '/tests/pure/core/hoon']) {
    try { await m.call('mcp/test-build', { desk: h.DESK, path: p }); console.log(`  ok   ${p}`); }
    catch (e) { console.log(`  FAIL ${p}: ${e.message.slice(0, 120)}`); bad++; }
  }

  //  clean shutdown: a hard kill leaves the pier owing a replay on next boot
  try { await m.call('dojo/exit', {}); } catch {}
  const gone = Date.now() + 60000;
  while (Date.now() < gone && existsSync(`${pier}/.http.ports`)) {
    await new Promise((r) => setTimeout(r, 1500));
  }
  console.log('  shut down');
}

console.log(bad ? `\n${bad} problem(s) — do not rely on this baseline.` : '\nBaked.');
process.exit(bad ? 1 : 0);
