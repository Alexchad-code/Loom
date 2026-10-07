// Shared Rojo-compatible source tree walker.
// Mirrors Rojo's rules: a folder containing init.luau becomes a ModuleScript
// that owns its sibling files; everything else is a Folder of children.
import fs from "node:fs";
import path from "node:path";

const LUA_EXT = /\.(lua|luau)$/;

/**
 * @typedef {{ name: string, className: string, filePath?: string, children: Node[] }} Node
 */

/** @param {string} dir absolute dir @param {string} name instance name @returns {Node | null} */
function walk(dir, name) {
  const initLuau = ["init.luau", "init.lua"].find((f) => fs.existsSync(path.join(dir, f)));
  const entries = fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name));

  /** @type {Node} */
  const node = {
    name,
    className: initLuau ? "ModuleScript" : "Folder",
    children: [],
  };
  if (initLuau) node.filePath = path.join(dir, initLuau);

  for (const entry of entries) {
    if (entry.name.startsWith(".")) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      const child = walk(full, entry.name);
      if (child) node.children.push(child);
      continue;
    }
    if (!LUA_EXT.test(entry.name)) continue;
    if (entry.name === initLuau) continue;
    const base = entry.name.replace(LUA_EXT, "");
    node.children.push({ name: base, className: "ModuleScript", filePath: full, children: [] });
  }
  return node;
}

/**
 * Builds the tree for a source directory.
 * @param {string} srcDir project-relative source dir, e.g. "src"
 * @param {string} rootName name of the root instance
 * @returns {{ tree: Node, modules: Map<string, { id: string, filePath: string, childrenIds: string[] }> }}
 */
export function buildTree(srcDir, rootName) {
  const abs = path.resolve(srcDir);
  if (!fs.existsSync(abs)) throw new Error(`source dir not found: ${srcDir}`);
  const tree = walk(abs, rootName);

  // Flatten into an id -> module registry. Ids are "/"-joined instance paths.
  const modules = new Map();

  /** @param {Node} node @param {string[]} trail */
  function index(node, trail) {
    const id = [...trail, node.name].join("/");
    if (node.className === "ModuleScript") {
      if (!node.filePath) throw new Error(`ModuleScript without file: ${id}`);
      modules.set(id, { id, filePath: node.filePath, childrenIds: [] });
    }
    const childTrail = [...trail, node.name];
    for (const child of node.children) index(child, childTrail);
  }
  index(tree, []);

  // Record child ids (any child, folder or module) so navigation resolves.
  /** @param {Node} node @param {string[]} trail */
  function link(node, trail) {
    const id = [...trail, node.name].join("/");
    const self = modules.get(id);
    if (self) {
      self.childrenIds = node.children.map((c) => [...trail, node.name, c.name].join("/"));
    }
    const childTrail = [...trail, node.name];
    for (const child of node.children) link(child, childTrail);
  }
  link(tree, []);

  // name -> child node lookup per id, for `script.Parent.X.Y` navigation
  const nodeById = new Map();
  /** @param {Node} node @param {string[]} trail */
  function indexNodes(node, trail) {
    const id = [...trail, node.name].join("/");
    nodeById.set(id, node);
    const childTrail = [...trail, node.name];
    for (const child of node.children) indexNodes(child, childTrail);
  }
  indexNodes(tree, []);

  return { tree, modules, nodeById };
}
