--!strict
-- Section header: a quiet uppercase caption above a hairline rule.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

local Section = {}
Section.__index = Section
setmetatable(Section, { __index = Element })

export type Section = Element.Internal & {
	_caption: TextLabel,
	_rule: Frame,
	_label: string,
	Set: (self: Section, text: string) -> (),
	Get: (self: Section) -> string,
}

function Section.new(tab: any, config: any): Section
	local options = config or {}

	local self: Section = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				NoLabel = true,
				Hover = false,
				Height = options.Height or 34,
			}),
			Section
		) :: any
	) :: Section

	local theme = tab.Theme
	local label = options.Text or ""

	local caption = Ui.text(theme, self.Body, {
		Name = "Caption",
		Text = string.upper(label),
		Font = theme.MediumFont,
		TextSize = theme.SmallFontSize,
		TextColor3 = theme.TextFaint,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, 0),
		TextYAlignment = Enum.TextYAlignment.Bottom,
	})

	local rule = New("Frame", {
		Name = "Rule",
		Size = UDim2.new(1, 0, 0, theme.StrokeWidth),
		Position = UDim2.new(0, 0, 1, -theme.StrokeWidth),
		BackgroundColor3 = theme.Stroke,
		BackgroundTransparency = theme.StrokeTransparency,
		BorderSizePixel = 0,
	}, nil, self.Frame)

	self._caption = caption
	self._rule = rule
	self._label = label
	self.Value = label

	self:OnTheme(function(next: Theme)
		caption.Font = next.MediumFont
		caption.TextSize = next.SmallFontSize
		caption.TextColor3 = next.TextFaint
		rule.Size = UDim2.new(1, 0, 0, next.StrokeWidth)
		rule.Position = UDim2.new(0, 0, 1, -next.StrokeWidth)
		rule.BackgroundColor3 = next.Stroke
		rule.BackgroundTransparency = next.StrokeTransparency
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Section.Set(self: Section, text: string)
	self._label = text
	self._caption.Text = string.upper(text)
	self:_emit(text)
end

function Section.Get(self: Section): string
	return self._label
end

function Section.SetValue(self: Section, value: any)
	self:Set(tostring(value))
end

function Section.GetValue(self: Section): any
	return self._label
end

return Section
