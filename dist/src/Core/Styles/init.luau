--!strict
-- Every style preset, merged from the three rosters. The registry in Theme.luau
-- pulls this in, so a preset only has to exist in a roster to be selectable --
-- and the roster key becomes its name, so a preset cannot be misnamed.

local Token = require("@self/../Token")
local Os = require("@self/Os")
local Idiom = require("@self/Idiom")
local Palette = require("@self/Palette")

type Theme = Token.Theme

local ROSTERS: { { [string]: Theme } } = { Os, Idiom, Palette }

local Styles: { [string]: Theme } = {}

for _, roster in ROSTERS do
	for name, preset in roster do
		preset.Name = name
		Styles[name] = preset
	end
end

return Styles
