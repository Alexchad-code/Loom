#!/usr/bin/env node
// Runs the bundled library headlessly on the official Luau CLI, once per executor
// capability set. That interpreter has no require of string paths and no Roblox
// globals, so the shim, the bundle and the assertions are concatenated into one
// chunk per run and executed together.
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";

const ROOT_CALL = 'return __require("Loom")';
const BUNDLE = "dist/loom.lua";
const BIN = path.join("tools", "bin", process.platform === "win32" ? "luau.exe" : "luau");

// `profile` is what the mock pretends this executor offers; the assertions grade
// that capability set. `full` also gets the long element-by-element suite.
const SCENARIOS = [
  { name: "full", profile: "full", assertions: "tools/smoke.luau" },
  { name: "env-full", profile: "full", assertions: "tools/smoke-env.luau" },
  { name: "aliases", profile: "aliases", assertions: "tools/smoke-env.luau" },
  { name: "bare", profile: "bare", assertions: "tools/smoke-env.luau" },
  { name: "locked", profile: "locked", assertions: "tools/smoke-env.luau" },
  { name: "styles", profile: "full", assertions: "tools/smoke-styles.luau" },
  { name: "api", profile: "full", assertions: "tools/smoke-api.luau" },
  { name: "adapters", profile: "full", assertions: "tools/smoke-adapters.luau" },
];

if (!fs.existsSync(BUNDLE)) {
  console.error(`${BUNDLE} is missing; run \`node tools/bundle.mjs\` first`);
  process.exit(1);
}

let bundle = fs.readFileSync(BUNDLE, "utf8");
if (!bundle.includes(ROOT_CALL)) {
  console.error(`${BUNDLE} does not end by returning the Loom module; rebuild it`);
  process.exit(1);
}
bundle = bundle.replace(ROOT_CALL, 'local Loom = __require("Loom")');

const mock = fs.readFileSync("tools/mock.luau", "utf8");
fs.mkdirSync("build", { recursive: true });

let failed = 0;
for (const scenario of SCENARIOS) {
  const assertions = fs.readFileSync(scenario.assertions, "utf8");
  const out = path.join("build", `smoke-${scenario.name}.luau`);
  const source = [`MOCK_PROFILE = "${scenario.profile}"`, mock, bundle, assertions].join("\n");
  fs.writeFileSync(out, source);

  const result = spawnSync(BIN, [out], { stdio: "inherit" });
  if (result.error) {
    console.error(`scenario ${scenario.name}: could not run ${BIN}: ${result.error.message}`);
  }

  const status = result.error ? 1 : (result.status ?? 1);
  if (status !== 0) {
    failed += 1;
  }
  console.log(`scenario ${scenario.name}: exit ${status}`);
}

console.log(`SMOKE SCENARIOS: ${SCENARIOS.length - failed}/${SCENARIOS.length} passed`);
process.exit(failed === 0 ? 0 : 1);
