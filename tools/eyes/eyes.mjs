#!/usr/bin/env node
// eyes.mjs: let a cloud Claude session see and drive the running game through godot-mcp-runtime.
// Usage (from the game repo root, under a display):
//   xvfb-run -a node tools/eyes/eyes.mjs steps.json      # or pass the JSON inline as the argument
// steps.json is a list of steps, run in order:
//   {"ui": true}                       list visible buttons/labels (name, text, rect)
//   {"click": "PLAY"}                  click the visible Button whose text or node name matches
//   {"key": "Escape"}                  tap a key (Godot KEY_* name without the prefix)
//   {"action": "ui_accept"}            tap an input-map action
//   {"wait": 800}                      wait N milliseconds
//   {"shot": "title"}                  save a screenshot to docs/renders/eyes/<name>.png
//   {"allowErrors": true}            don't fail the run on game errors (they still print)
//   {"gd": "return scene_tree.current_scene.name"}   run GDScript (body of execute(scene_tree)), print result
// Prints one line per step and ends with EYES PASS, or EYES FAIL <reason> (exit 1).
import { Client } from '@modelcontextprotocol/client';
import { StdioClientTransport } from '@modelcontextprotocol/client/stdio';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const project = path.resolve(here, '../..');  // repo root, wherever it's run from
const arg = process.argv[2];
if (!arg) { console.log('EYES FAIL no steps given'); process.exit(1); }
let steps;
try { steps = JSON.parse(fs.existsSync(arg) ? fs.readFileSync(arg, 'utf8') : arg); }
catch (e) { console.log(`EYES FAIL bad steps JSON: ${e.message}`); process.exit(1); }
const outDir = path.join(project, 'docs/renders/eyes');
fs.mkdirSync(outDir, { recursive: true });

const server = path.join(here, 'node_modules/godot-mcp-runtime/dist/index.js');
const client = new Client({ name: 'eyes', version: '1.0.0' });
try {
await client.connect(new StdioClientTransport({
  command: 'node', args: [server], stderr: 'ignore',
  env: { ...process.env, GODOT_PATH: process.env.GODOT_PATH || '/usr/local/bin/godot', GODOT_MCP_DISABLE_ELICITATION: 'true' },
}));
} catch (e) { console.log(`EYES FAIL server did not start (run tools/eyes/setup.sh): ${e.message}`); process.exit(1); }

const text = (r) => (r.content || []).filter((c) => c.type === 'text').map((c) => c.text).join('\n');
async function call(name, args) {
  const r = await client.callTool({ name, arguments: args }, undefined, { timeout: 120000 });
  if (r.isError) throw new Error(`${name}: ${text(r).slice(0, 400)}`);
  return r;
}
function parse(r) { try { return JSON.parse(text(r)); } catch { return text(r); } }

let failed = null;
try {
  await call('run_project', { projectPath: project });
  await new Promise((res) => setTimeout(res, 2500));
  for (const s of steps) {
    if ('wait' in s) { await call('simulate_input', { actions: [{ type: 'wait', ms: s.wait }] }); console.log(`wait ${s.wait}`); }
    else if ('ui' in s) {
      const ui = parse(await call('get_ui_elements', { visibleOnly: true }));
      const els = (ui.elements || ui || []).filter?.((e) => e.text) ?? [];
      console.log(`ui ${els.length} with text: ` + els.map((e) => `[${e.type || e.class}] ${String(e.text).replace(/\s+/g, ' ').slice(0, 30)}`).join(' | '));
    }
    else if (s.click) {
      // Retry for up to 3 s: screens animate in. {"click": "X", "optional": true} skips if X never shows.
      const want = s.click.toLowerCase();
      let hit = null, list = [];
      for (let i = 0; i < 6 && !hit; i++) {
        if (i) await new Promise((res) => setTimeout(res, 500));
        const ui = parse(await call('get_ui_elements', { visibleOnly: true, filter: 'BaseButton' }));
        list = ui.elements || ui || [];
        hit = list.find((e) => String(e.text || '').toLowerCase().trim() === want)
          || list.find((e) => String(e.text || '').toLowerCase().includes(want))
          || list.find((e) => String(e.name || '').toLowerCase().includes(want));
      }
      if (!hit && s.optional) { console.log(`click ${s.click} skipped (not shown)`); continue; }
      if (!hit) throw new Error(`no visible button "${s.click}" (have: ${list.map((e) => e.text || e.name).join(', ')})`);
      await call('simulate_input', { actions: [{ type: 'click_element', element: hit.path || hit.name }] });
      console.log(`click ${s.click} -> ${hit.path || hit.name}`);
    }
    else if ('allowErrors' in s) { /* marker only */ }
    else if (s.key) { await call('simulate_input', { actions: [{ type: 'key', key: s.key }] }); console.log(`key ${s.key}`); }
    else if (s.action) { await call('simulate_input', { actions: [{ type: 'action', action: s.action }] }); console.log(`action ${s.action}`); }
    else if (s.shot) {
      const r = await call('take_screenshot', { responseMode: 'path_only' });
      const src = (text(r).match(/(\/[^\s"']+\.png)/) || [])[1];
      if (!src || !fs.existsSync(src)) throw new Error(`screenshot had no file: ${text(r).slice(0, 200)}`);
      const dst = path.join(outDir, `${s.shot}.png`);
      fs.copyFileSync(src, dst);
      console.log(`shot ${path.relative(project, dst)}`);
    }
    else if (s.gd) {
      const body = s.gd.split('\n').map((l) => `\t${l}`).join('\n');
      const src = `extends RefCounted\nfunc execute(scene_tree: SceneTree) -> Variant:\n${body}\n`;
      const out = parse(await call('run_script', { script: src }));
      const result = typeof out === 'object' && out && 'result' in out ? out.result : out;
      console.log(`gd ${JSON.stringify(result).slice(0, 300)}`);
    }
    else throw new Error(`unknown step ${JSON.stringify(s)}`);
  }
  const out = parse(await call('get_debug_output', { limit: 200 }));
  // Sandbox noise (no sound card, no vsync under xvfb) is not a game bug.
  const noise = /ObjectDB|resources still in use|ALSA|V-Sync|set_use_vsync|All audio drivers failed|Condition "status < 0"|^\s*at: /;
  const errs = (out.errors || []).filter((e) => !noise.test(e));
  // Game errors fail the run unless a step list opts out with {"allowErrors": true}.
  if (errs.length) {
    const msg = `game errors (${errs.length}): ` + errs.slice(0, 5).join(' || ').slice(0, 600);
    if (steps.some((s) => s.allowErrors)) console.log(`${msg} (allowed)`);
    else failed = msg;
  }
} catch (e) { failed = e.message; }
try { await call('stop_project', {}); } catch {}
await client.close();
if (failed) { console.log(`EYES FAIL ${failed.replace(/\s+/g, ' ').slice(0, 500)}`); process.exit(1); }
console.log('EYES PASS');
