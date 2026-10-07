#!/usr/bin/env node
// Converts a curated set of Lucide icons into Luau geometry. Lucide draws with
// strokes on a 24x24 grid, so every shape flattens into polylines that Roblox
// can draw with thin rotated frames -- no hosted assets, nothing to upload.
//
//   node tools/icons.mjs
//
// Reads node_modules/lucide-static/icons/*.svg, writes src/Core/Icons/Data.luau.
// A shape that fails to parse is a hard error: silently dropping geometry is how
// an icon ends up invisible.
import fs from "node:fs";
import path from "node:path";

const SOURCE = "node_modules/lucide-static/icons";
const TARGET = "src/Core/Icons/Data.luau";
const EPSILON = 0.06;

// Loom icon name -> Lucide file. The names on the left are the ones the library
// and its examples use; anything missing falls back to a text glyph.
const ICONS = {
  home: "home",
  settings: "settings",
  sliders: "sliders-horizontal",
  search: "search",
  bell: "bell",
  star: "star",
  heart: "heart",
  shield: "shield",
  shieldCheck: "shield-check",
  zap: "zap",
  info: "info",
  warning: "triangle-alert",
  close: "x",
  check: "check",
  plus: "plus",
  minus: "minus",
  chevron: "chevron-down",
  chevronDown: "chevron-down",
  chevronUp: "chevron-up",
  chevronLeft: "chevron-left",
  chevronRight: "chevron-right",
  arrow: "arrow-right",
  arrowRight: "arrow-right",
  arrowLeft: "arrow-left",
  arrowUp: "arrow-up",
  arrowDown: "arrow-down",
  arrowUpDown: "arrow-up-down",
  lock: "lock",
  unlock: "lock-open",
  key: "key",
  cart: "shopping-cart",
  book: "book",
  wrench: "wrench",
  tool: "hammer",
  hammer: "hammer",
  target: "target",
  crosshair: "crosshair",
  globe: "globe",
  compass: "compass",
  map: "map",
  music: "music",
  volume: "volume-2",
  mic: "mic",
  video: "video",
  camera: "camera",
  image: "image",
  code: "code",
  terminal: "terminal",
  folder: "folder",
  file: "file",
  clipboard: "clipboard",
  trash: "trash-2",
  play: "play",
  pause: "pause",
  refresh: "refresh-cw",
  rotate: "rotate-cw",
  undo: "undo-2",
  redo: "redo-2",
  chat: "message-square",
  mail: "mail",
  send: "send",
  inbox: "inbox",
  flag: "flag",
  gift: "gift",
  flame: "flame",
  sparkles: "sparkles",
  wand: "wand-2",
  sun: "sun",
  moon: "moon",
  cloud: "cloud",
  droplet: "droplet",
  eye: "eye",
  eyeOff: "eye-off",
  user: "user",
  users: "users",
  puzzle: "puzzle",
  rocket: "rocket",
  clock: "clock",
  alarm: "alarm-clock",
  hourglass: "hourglass",
  history: "history",
  calendar: "calendar",
  chart: "chart-line",
  activity: "activity",
  dice: "dices",
  grid: "grid-3x3",
  list: "list",
  menu: "menu",
  link: "link",
  externalLink: "external-link",
  download: "download",
  upload: "upload",
  copy: "copy",
  edit: "pencil",
  save: "save",
  database: "database",
  server: "server",
  cpu: "cpu",
  wifi: "wifi",
  phone: "smartphone",
  monitor: "monitor",
  mousePointer: "mouse-pointer",
  keyboard: "keyboard",
  gamepad: "gamepad-2",
  palette: "palette",
  brush: "brush",
  layers: "layers",
  package: "package",
  box: "box",
  gauge: "gauge",
  timer: "timer",
  tag: "tag",
  bookmark: "bookmark",
  filter: "filter",
  wallet: "wallet",
  creditCard: "credit-card",
  plug: "plug",
  power: "power",
  battery: "battery-full",
  bug: "bug",
  hash: "hash",
  at: "at-sign",
  percent: "percent",
  trophy: "trophy",
  medal: "medal",
  crown: "crown",
  gem: "gem",
  coins: "coins",
  dollar: "dollar-sign",
  pin: "pin",
  scissors: "scissors",
  ruler: "ruler",
  maximize: "maximize-2",
  minimize: "minimize-2",
  archive: "archive",
  construction: "construction",
};

const attribute = (tag, name) => {
  const match = tag.match(new RegExp(`${name}\\s*=\\s*"([^"]*)"`));
  return match ? match[1] : null;
};

// How many straight pieces a curve needs at this size. A two-unit corner is
// indistinguishable from a line, a twenty-unit arc needs a dozen.
function stepsFor(...coordinates) {
  const xs = [];
  const ys = [];
  for (let index = 0; index + 1 < coordinates.length; index += 2) {
    xs.push(coordinates[index]);
    ys.push(coordinates[index + 1]);
  }
  const extent = Math.max(
    Math.max(...xs) - Math.min(...xs),
    Math.max(...ys) - Math.min(...ys)
  );
  return Math.max(3, Math.min(16, Math.ceil(extent * 1.1)));
}

function cubicPoints(x0, y0, cx1, cy1, cx2, cy2, x1, y1) {
  const steps = stepsFor(x0, y0, cx1, cy1, cx2, cy2, x1, y1);
  const out = [];
  for (let index = 1; index <= steps; index += 1) {
    const t = index / steps;
    const u = 1 - t;
    out.push([
      u * u * u * x0 + 3 * u * u * t * cx1 + 3 * u * t * t * cx2 + t * t * t * x1,
      u * u * u * y0 + 3 * u * u * t * cy1 + 3 * u * t * t * cy2 + t * t * t * y1,
    ]);
  }
  return out;
}

function quadPoints(x0, y0, cx, cy, x1, y1) {
  const steps = stepsFor(x0, y0, cx, cy, x1, y1);
  const out = [];
  for (let index = 1; index <= steps; index += 1) {
    const t = index / steps;
    const u = 1 - t;
    out.push([u * u * x0 + 2 * u * t * cx + t * t * x1, u * u * y0 + 2 * u * t * cy + t * t * y1]);
  }
  return out;
}

// SVG elliptical arc, endpoint form, to a run of cubic beziers.
function arcToCubics(x0, y0, rx, ry, rotation, largeArc, sweep, x1, y1) {
  if (rx === 0 || ry === 0 || (x0 === x1 && y0 === y1)) {
    return [];
  }

  const phi = (rotation * Math.PI) / 180;
  const cos = Math.cos(phi);
  const sin = Math.sin(phi);

  const dx = (x0 - x1) / 2;
  const dy = (y0 - y1) / 2;
  const px = cos * dx + sin * dy;
  const py = -sin * dx + cos * dy;

  let rxAbs = Math.abs(rx);
  let ryAbs = Math.abs(ry);
  const scale = (px * px) / (rxAbs * rxAbs) + (py * py) / (ryAbs * ryAbs);
  if (scale > 1) {
    const grow = Math.sqrt(scale);
    rxAbs *= grow;
    ryAbs *= grow;
  }

  const sign = largeArc === sweep ? -1 : 1;
  const numerator =
    rxAbs * rxAbs * ryAbs * ryAbs - rxAbs * rxAbs * py * py - ryAbs * ryAbs * px * px;
  const denominator = rxAbs * rxAbs * py * py + ryAbs * ryAbs * px * px;
  const factor = sign * Math.sqrt(Math.max(0, numerator / denominator));
  const cx1 = (factor * rxAbs * py) / ryAbs;
  const cy1 = (-factor * ryAbs * px) / rxAbs;
  const cx = cos * cx1 - sin * cy1 + (x0 + x1) / 2;
  const cy = sin * cx1 + cos * cy1 + (y0 + y1) / 2;

  const angleBetween = (ux, uy, vx, vy) => {
    const dot = ux * vx + uy * vy;
    const length = Math.sqrt(ux * ux + uy * uy) * Math.sqrt(vx * vx + vy * vy);
    const value = Math.acos(Math.min(1, Math.max(-1, dot / length)));
    return ux * vy - uy * vx < 0 ? -value : value;
  };

  const startUx = (px - cx1) / rxAbs;
  const startUy = (py - cy1) / ryAbs;
  const endUx = (-px - cx1) / rxAbs;
  const endUy = (-py - cy1) / ryAbs;
  const start = angleBetween(1, 0, startUx, startUy);
  let span = angleBetween(startUx, startUy, endUx, endUy);
  if (!sweep && span > 0) {
    span -= 2 * Math.PI;
  } else if (sweep && span < 0) {
    span += 2 * Math.PI;
  }

  const pieces = Math.max(1, Math.ceil(Math.abs(span) / (Math.PI / 2)));
  const step = span / pieces;
  const alpha = (4 / 3) * Math.tan(step / 4);

  const pointAt = (rxAngle, ryAngle) => [
    cx + rxAbs * Math.cos(rxAngle) * cos - ryAbs * Math.sin(ryAngle) * sin,
    cy + rxAbs * Math.cos(rxAngle) * sin + ryAbs * Math.sin(ryAngle) * cos,
  ];

  const out = [];
  for (let index = 0; index < pieces; index += 1) {
    const from = start + index * step;
    const to = from + step;

    const [ax, ay] = pointAt(from, from);
    const [bx, by] = pointAt(to, to);
    const ax1 = -rxAbs * Math.sin(from) * cos - ryAbs * Math.cos(from) * sin;
    const ay1 = -rxAbs * Math.sin(from) * sin + ryAbs * Math.cos(from) * cos;
    const bx2 = -rxAbs * Math.sin(to) * cos - ryAbs * Math.cos(to) * sin;
    const by2 = -rxAbs * Math.sin(to) * sin + ryAbs * Math.cos(to) * cos;

    out.push([ax, ay, ax + alpha * ax1, ay + alpha * ay1, bx - alpha * bx2, by - alpha * by2, bx, by]);
  }
  return out;
}

// Scans a path definition. A character scanner rather than a split, because SVG
// lets an arc's flag digits run together ("a1.5 1.5 0 00-2.4"), which a plain
// number regex reads as one token and then every following coordinate is wrong.
function parsePath(definition) {
  const polylines = [];
  let current = [];
  let x = 0;
  let y = 0;
  let startX = 0;
  let startY = 0;
  let lastCubic = null;
  let lastQuad = null;
  let command = null;
  let index = 0;

  const skip = () => {
    while (index < definition.length && /[\s,]/.test(definition[index])) {
      index += 1;
    }
  };
  // A number is sign, digits, at most one decimal point, digits. It has to stop
  // after that single point, because SVG writes ".53.53" for two numbers.
  const number = () => {
    skip();
    const from = index;
    if (definition[index] === "+" || definition[index] === "-") {
      index += 1;
    }

    let digits = 0;
    while (index < definition.length && /\d/.test(definition[index])) {
      index += 1;
      digits += 1;
    }
    if (definition[index] === ".") {
      index += 1;
      while (index < definition.length && /\d/.test(definition[index])) {
        index += 1;
        digits += 1;
      }
    }
    if (digits === 0) {
      throw new Error(`expected a number at ${from} in "${definition}"`);
    }

    if (definition[index] === "e" || definition[index] === "E") {
      index += 1;
      if (definition[index] === "+" || definition[index] === "-") {
        index += 1;
      }
      while (index < definition.length && /\d/.test(definition[index])) {
        index += 1;
      }
    }

    const value = Number(definition.slice(from, index));
    if (!Number.isFinite(value)) {
      throw new Error(`bad number at ${from} in "${definition}"`);
    }
    return value;
  };
  // Arc flags are single characters and may be written without a separator.
  const flag = () => {
    skip();
    const value = definition[index] === "1" ? 1 : 0;
    index += 1;
    return value;
  };
  const push = (point) => current.push(point);
  const finish = () => {
    if (current.length > 1) {
      polylines.push(current);
    }
    current = [];
  };

  while (index < definition.length) {
    skip();
    if (index >= definition.length) {
      break;
    }

    if (/[a-zA-Z]/.test(definition[index])) {
      command = definition[index];
      index += 1;
    } else if (command === null) {
      index += 1;
      continue;
    }

    const relative = command === command.toLowerCase();
    const upper = command.toUpperCase();

    if (upper === "M") {
      finish();
      x = relative ? x + number() : number();
      y = relative ? y + number() : number();
      startX = x;
      startY = y;
      push([x, y]);
      command = relative ? "l" : "L";
      continue;
    }

    if (upper === "L") {
      x = relative ? x + number() : number();
      y = relative ? y + number() : number();
      push([x, y]);
      lastCubic = null;
      lastQuad = null;
      continue;
    }

    if (upper === "H") {
      x = relative ? x + number() : number();
      push([x, y]);
      continue;
    }

    if (upper === "V") {
      y = relative ? y + number() : number();
      push([x, y]);
      continue;
    }

    if (upper === "C" || upper === "S") {
      let cx1;
      let cy1;
      if (upper === "C") {
        cx1 = relative ? x + number() : number();
        cy1 = relative ? y + number() : number();
      } else {
        const mirror = lastCubic ?? [x, y];
        cx1 = 2 * x - mirror[0];
        cy1 = 2 * y - mirror[1];
      }
      const cx2 = relative ? x + number() : number();
      const cy2 = relative ? y + number() : number();
      const nx = relative ? x + number() : number();
      const ny = relative ? y + number() : number();

      for (const point of cubicPoints(x, y, cx1, cy1, cx2, cy2, nx, ny)) {
        push(point);
      }
      lastCubic = [cx2, cy2];
      lastQuad = null;
      x = nx;
      y = ny;
      continue;
    }

    if (upper === "Q" || upper === "T") {
      let cx;
      let cy;
      if (upper === "Q") {
        cx = relative ? x + number() : number();
        cy = relative ? y + number() : number();
      } else {
        const mirror = lastQuad ?? [x, y];
        cx = 2 * x - mirror[0];
        cy = 2 * y - mirror[1];
      }
      const nx = relative ? x + number() : number();
      const ny = relative ? y + number() : number();

      for (const point of quadPoints(x, y, cx, cy, nx, ny)) {
        push(point);
      }
      lastQuad = [cx, cy];
      lastCubic = null;
      x = nx;
      y = ny;
      continue;
    }

    if (upper === "A") {
      const rx = number();
      const ry = number();
      const rotation = number();
      const largeArc = flag();
      const sweep = flag();
      const nx = relative ? x + number() : number();
      const ny = relative ? y + number() : number();

      for (const cubic of arcToCubics(x, y, rx, ry, rotation, largeArc, sweep, nx, ny)) {
        for (const point of cubicPoints(...cubic)) {
          push(point);
        }
      }
      lastCubic = null;
      lastQuad = null;
      x = nx;
      y = ny;
      continue;
    }

    if (upper === "Z") {
      push([startX, startY]);
      finish();
      x = startX;
      y = startY;
      continue;
    }

    index += 1;
  }

  finish();
  return polylines;
}

const distanceToSegment = (point, from, to) => {
  const dx = to[0] - from[0];
  const dy = to[1] - from[1];
  const length = dx * dx + dy * dy;
  if (length === 0) {
    return Math.hypot(point[0] - from[0], point[1] - from[1]);
  }
  const t = Math.min(1, Math.max(0, ((point[0] - from[0]) * dx + (point[1] - from[1]) * dy) / length));
  return Math.hypot(point[0] - (from[0] + t * dx), point[1] - (from[1] + t * dy));
};

// Douglas-Peucker, which is what keeps the generated table small: a flattened
// curve is mostly points that sit on the line between two others.
function simplify(points) {
  if (points.length < 3) {
    return points;
  }

  const first = points[0];
  const last = points[points.length - 1];
  let worst = 0;
  let at = -1;

  for (let index = 1; index < points.length - 1; index += 1) {
    const distance = distanceToSegment(points[index], first, last);
    if (distance > worst) {
      worst = distance;
      at = index;
    }
  }

  if (worst <= EPSILON) {
    return [first, last];
  }

  return simplify(points.slice(0, at + 1))
    .slice(0, -1)
    .concat(simplify(points.slice(at)));
}

// A closed shape cannot be simplified against its own start point, so it is
// split in half first.
function simplifyClosed(points) {
  const first = points[0];
  const last = points[points.length - 1];
  const closed =
    points.length > 2 && Math.abs(first[0] - last[0]) < 0.01 && Math.abs(first[1] - last[1]) < 0.01;
  if (!closed) {
    return simplify(points);
  }

  const middle = Math.floor(points.length / 2);
  const head = simplify(points.slice(0, middle + 1));
  const tail = simplify(points.slice(middle));
  return head.slice(0, -1).concat(tail);
}

function geometry(svg) {
  const polylines = [];

  for (const tag of svg.match(/<(path|circle|rect|line|polyline|polygon)\b[^>]*>/gi) ?? []) {
    const kind = (tag.match(/^<([a-z]+)/i) ?? [])[1].toLowerCase();

    if (kind === "path") {
      polylines.push(...parsePath(attribute(tag, "d") ?? ""));
      continue;
    }

    if (kind === "circle") {
      const cx = Number(attribute(tag, "cx") ?? 0);
      const cy = Number(attribute(tag, "cy") ?? 0);
      const r = Number(attribute(tag, "r") ?? 0);
      const steps = Math.max(12, Math.ceil(r * 8));
      const ring = [];
      for (let index = 0; index <= steps; index += 1) {
        const angle = (index / steps) * Math.PI * 2;
        ring.push([cx + r * Math.cos(angle), cy + r * Math.sin(angle)]);
      }
      polylines.push(ring);
      continue;
    }

    if (kind === "rect") {
      const x = Number(attribute(tag, "x") ?? 0);
      const y = Number(attribute(tag, "y") ?? 0);
      const width = Number(attribute(tag, "width") ?? 0);
      const height = Number(attribute(tag, "height") ?? 0);
      const radius = Number(attribute(tag, "rx") ?? 0);
      if (radius > 0) {
        const arc = (fromX, fromY, toX, toY, cx1, cy1, cx2, cy2) =>
          arcToCubics(fromX, fromY, radius, radius, 0, 0, 1, toX, toY);
        const corners = [];
        const corner = (fromX, fromY, controlX, controlY, toX, toY) => {
          for (const cubic of arc(fromX, fromY, toX, toY, controlX, controlY, controlX, controlY)) {
            for (const point of cubicPoints(...cubic)) {
              corners.push(point);
            }
          }
        };
        const ring = [[x + radius, y]];
        ring.push([x + width - radius, y]);
        corner(x + width - radius, y, x + width, y, x + width, y + radius);
        ring.push([x + width, y + radius]);
        ring.push([x + width, y + height - radius]);
        corner(x + width, y + height - radius, x + width, y + height, x + width - radius, y + height);
        ring.push([x + width - radius, y + height]);
        ring.push([x + radius, y + height]);
        corner(x + radius, y + height, x, y + height, x, y + height - radius);
        ring.push([x, y + height - radius]);
        ring.push([x, y + radius]);
        corner(x, y + radius, x, y, x + radius, y);
        ring.push([x + radius, y]);
        polylines.push(ring);
        continue;
      }
      polylines.push([
        [x, y],
        [x + width, y],
        [x + width, y + height],
        [x, y + height],
        [x, y],
      ]);
      continue;
    }

    if (kind === "line") {
      polylines.push([
        [Number(attribute(tag, "x1") ?? 0), Number(attribute(tag, "y1") ?? 0)],
        [Number(attribute(tag, "x2") ?? 0), Number(attribute(tag, "y2") ?? 0)],
      ]);
      continue;
    }

    const list = (attribute(tag, "points") ?? "").match(/-?\d*\.?\d+(?:e[-+]?\d+)?/gi) ?? [];
    const points = [];
    for (let index = 0; index + 1 < list.length; index += 2) {
      points.push([Number(list[index]), Number(list[index + 1])]);
    }
    if (points.length > 1) {
      if (kind === "polygon") {
        points.push(points[0]);
      }
      polylines.push(points);
    }
  }

  const cleaned = [];
  for (const line of polylines) {
    const withoutRepeats = [];
    for (const point of line) {
      if (!Number.isFinite(point[0]) || !Number.isFinite(point[1])) {
        throw new Error("non-finite coordinate");
      }
      const previous = withoutRepeats[withoutRepeats.length - 1];
      if (
        !previous ||
        Math.abs(previous[0] - point[0]) > 0.01 ||
        Math.abs(previous[1] - point[1]) > 0.01
      ) {
        withoutRepeats.push(point);
      }
    }

    const reduced = simplifyClosed(withoutRepeats);
    if (reduced.length > 1) {
      cleaned.push(reduced);
    }
  }
  return cleaned;
}

const format = (value) => String(Math.round(value * 100) / 100);

const failures = [];
const entries = [];
const sizes = [];
let points = 0;

for (const [name, file] of Object.entries(ICONS)) {
  const source = path.join(SOURCE, `${file}.svg`);
  if (!fs.existsSync(source)) {
    failures.push(`${name}: ${file}.svg is not in lucide-static`);
    continue;
  }

  let polylines;
  try {
    polylines = geometry(fs.readFileSync(source, "utf8"));
  } catch (error) {
    failures.push(`${name}: ${error.message}`);
    continue;
  }

  if (polylines.length === 0) {
    failures.push(`${name}: no geometry in ${file}.svg`);
    continue;
  }

  const count = polylines.reduce((total, line) => total + line.length, 0);
  points += count;
  sizes.push([name, count]);
  const body = polylines
    .map((line) => `\t\t\t{ ${line.map(([x, y]) => `${format(x)},${format(y)}`).join(", ")} },`)
    .join("\n");
  entries.push(`\t${name} = {\n${body}\n\t},`);
}

entries.sort((a, b) => a.localeCompare(b));
sizes.sort((a, b) => b[1] - a[1]);

const file = [
  "--!strict",
  "-- Generated by tools/icons.mjs from lucide-static, which is ISC licensed.",
  "-- Do not edit; run that tool instead.",
  "--",
  "-- An icon is a list of polylines, each a flat x, y, x, y... run on the 24x24",
  "-- grid that Icons/Draw.luau scales, strokes and positions.",
  "--",
  `-- ${entries.length} icons, ${points} points.`,
  "",
  "local ICONS: { [string]: { { number } } } = {",
  entries.join("\n"),
  "}",
  "",
  "return ICONS",
  "",
].join("\n");

// --check regenerates in memory and compares, so a stale table fails the build
// the way a formatting drift does.
if (process.argv.includes("--check")) {
  const current = fs.existsSync(TARGET) ? fs.readFileSync(TARGET, "utf8") : "";
  if (current !== file) {
    console.error(`${TARGET} is out of date; run \`node tools/icons.mjs\``);
    process.exit(1);
  }
  console.log(`icons: ${entries.length} up to date`);
  process.exit(failures.length > 0 ? 1 : 0);
}

fs.mkdirSync(path.dirname(TARGET), { recursive: true });
fs.writeFileSync(TARGET, file);

console.log(`icons: ${entries.length} -> ${TARGET} (${Math.round(file.length / 1024)} KB)`);
console.log(`points: ${points}, average ${Math.round(points / Math.max(1, entries.length))}`);
console.log(`heaviest: ${sizes.slice(0, 4).map(([name, count]) => `${name} ${count}`).join(", ")}`);

if (failures.length > 0) {
  console.error(`failed (${failures.length}):`);
  for (const failure of failures) {
    console.error(`  ${failure}`);
  }
  process.exit(1);
}
