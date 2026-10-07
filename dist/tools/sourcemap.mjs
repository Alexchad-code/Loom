#!/usr/bin/env node
// Writes a Rojo-compatible sourcemap.json so luau-lsp can resolve `script` and
// `require(script.Parent.X)` without Rojo being installed.
import fs from "node:fs";
import path from "node:path";
import { buildTree } from "./tree.mjs";

const srcDir = process.argv[2] ?? "src";
const rootName = process.argv[3] ?? "Loom";
const out = process.argv[4] ?? "sourcemap.json";

const { tree } = buildTree(srcDir, rootName);
const root = path.resolve(".");

// luau-lsp expects file paths relative to the working directory.
function relativize(node) {
  const copy = { name: node.name, className: node.className, children: node.children.map(relativize) };
  if (node.filePath) copy.filePath = path.relative(root, node.filePath).split(path.sep).join("/");
  return copy;
}

fs.writeFileSync(out, JSON.stringify(relativize(tree), null, 2));
console.log(`wrote ${out}`);
