--!strict
-- Free-standing wrapped text. The row sizes itself to the text instead of
-- using the theme's fixed row height.

local Ui = require("@self/../Core/Ui")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

local Label = {}
Label.__index = Label
setmetatable(Label, { __index = Element })

export type Label = Element.Internal & {
	_text: TextLabel,
	Set: (self: Label, text: string) -> (),
	Get: (self: Label) -> string,
}

--- Turns a fixed-height row into one that grows with its wrapped contents.
local function grow(row: Frame, body: Frame, control: Frame)
	control.Size = UDim2.fromOffset(0, 0)
	control.Visible = false
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
end

function Label.new(tab: any, config: any): Label
	local options = config or {}

	local self: Label = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				NoLabel = true,
				Hover = false,
				Height = options.Height,
			}),
			Label
		) :: any
	) :: Label

	local theme = tab.Theme

	local text = Ui.textDim(theme, self.Body, {
		Name = "Text",
		Text = options.Text or "",
		Font = theme.Font,
		TextSize = theme.FontSize,
		TextColor3 = theme.TextDim,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
	})

	self._text = text
	self.Value = text.Text

	grow(self.Frame, self.Body, self.Control)

	self:OnTheme(function(next: Theme)
		text.Font = next.Font
		text.TextSize = next.FontSize
		text.TextColor3 = next.TextDim
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

--- The base class pins a fixed row height, so restore the automatic sizing.
function Label.ApplyTheme(self: Label, theme: Theme)
	Element.ApplyTheme(self, theme)
	grow(self.Frame, self.Body, self.Control)
end

function Label.Set(self: Label, text: string)
	self._text.Text = text
	self:_emit(text)
end

function Label.Get(self: Label): string
	return self._text.Text
end

function Label.SetValue(self: Label, value: any)
	self:Set(tostring(value))
end

function Label.GetValue(self: Label): any
	return self:Get()
end

return Label
