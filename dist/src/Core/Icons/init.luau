--!strict
-- Icons. Every name in Data is a real Lucide icon drawn from its vector
-- geometry, so nothing has to be uploaded to Roblox or hosted anywhere; any
-- other name falls back to a text glyph, and `rbxasset`/numeric names are still
-- treated as image ids:
--   Window:CreateTab("Main", "settings")   -- Lucide, drawn
--   Window:CreateTab("Main", "sparkles")   -- Lucide too
--   Window:CreateTab("Main", "rbxassetid://123456")

local Draw = require("@self/Draw")
local Data = require("@self/Data")
local ThemeModule = require("@self/../Theme")

type Theme = ThemeModule.Theme

local Glyphs: { [string]: string } = {
	starOutline = "☆",
	nope = "✕",
	dice = "⚀",
}

local NAMES: { string } = {}
for name in Data do
	table.insert(NAMES, name)
end
table.sort(NAMES)

local Icons = {
	Glyphs = Glyphs,
	Names = NAMES,
}

--- True when this build carries real geometry for `name`.
function Icons.has(name: string): boolean
	return Data[name] ~= nil
end

--- Every icon name that draws as vector geometry, sorted.
function Icons.names(): { string }
	return NAMES
end

--- True when `icon` should be drawn as an image rather than a glyph.
function Icons.isAsset(icon: string): boolean
	return string.match(icon, "^rbxasset") ~= nil or string.match(icon, "^%d+$") ~= nil
end

--- Resolves a named glyph. Unknown names pass through, so raw unicode works.
function Icons.resolve(icon: string): string
	return Glyphs[icon] or icon
end

--- Draws a Lucide icon, or nil when the name is not in this build. `props` is
--- the same table a glyph icon gets; `theme` only supplies the resting colour,
--- which callers normally override with Ui.tint.
function Icons.draw(parent: Instance, name: string, theme: Theme, props: { [string]: any }): Frame?
	if not Icons.has(name) then
		return nil
	end
	return Draw.new(parent, name, props, theme.Text, props.Thickness)
end

return Icons
