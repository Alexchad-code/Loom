--!strict
-- Slim spacer with a hairline rule through the middle, for grouping rows.

local New = require("@self/../Core/New")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

local Divider = {}
Divider.__index = Divider
setmetatable(Divider, { __index = Element })

export type Divider = Element.Internal & {
	_rule: Frame,
}

local HEIGHT = 13

function Divider.new(tab: any, config: any): Divider
	local options = config or {}
	local self: Divider = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Flag = options.Flag,
				Height = options.Height or HEIGHT,
				NoLabel = true,
				Hover = false,
			}),
			Divider
		) :: any
	) :: Divider

	local theme: Theme = tab.Theme

	local rule = New("Frame", {
		Name = "Rule",
		Size = UDim2.new(1, 0, 0, theme.StrokeWidth),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency,
		BorderSizePixel = 0,
	}, nil, self.Frame)
	self._rule = rule

	self:OnTheme(function(next: Theme)
		rule.Size = UDim2.new(1, 0, 0, next.StrokeWidth)
		rule.BackgroundColor3 = next.Stroke
		rule.BackgroundTransparency = next.StrokeTransparency
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

return Divider
