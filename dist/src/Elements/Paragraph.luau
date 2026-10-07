--!strict
-- A block of prose: a heading over wrapped body text, sized to its contents.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

local Paragraph = {}
Paragraph.__index = Paragraph
setmetatable(Paragraph, { __index = Element })

export type Paragraph = Element.Internal & {
	_title: TextLabel,
	_text: TextLabel,
	Set: (self: Paragraph, title: string, text: string) -> (),
	Get: (self: Paragraph) -> (string, string),
}

local function grow(row: Frame, body: Frame, control: Frame)
	control.Size = UDim2.fromOffset(0, 0)
	control.Visible = false
	body.Size = UDim2.new(1, 0, 0, 0)
	body.AutomaticSize = Enum.AutomaticSize.Y
	row.Size = UDim2.new(1, 0, 0, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
end

function Paragraph.new(tab: any, config: any): Paragraph
	local options = config or {}

	local self: Paragraph = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Title,
				NoLabel = true,
				Hover = false,
				Height = options.Height,
			}),
			Paragraph
		) :: any
	) :: Paragraph

	local theme = tab.Theme

	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, self.Body)

	local title = Ui.text(theme, self.Body, {
		Name = "Title",
		Text = options.Title or "",
		Font = theme.MediumFont,
		TextSize = theme.FontSize,
		TextColor3 = theme.Text,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		LayoutOrder = 1,
	})

	local text = Ui.textDim(theme, self.Body, {
		Name = "Text",
		Text = options.Text or "",
		Font = theme.Font,
		TextSize = theme.SmallFontSize,
		TextColor3 = theme.TextDim,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
		LayoutOrder = 2,
	})

	self._title = title
	self._text = text
	self.Value = text.Text

	grow(self.Frame, self.Body, self.Control)

	self:OnTheme(function(next: Theme)
		title.Font = next.MediumFont
		title.TextSize = next.FontSize
		title.TextColor3 = next.Text
		text.Font = next.Font
		text.TextSize = next.SmallFontSize
		text.TextColor3 = next.TextDim
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Paragraph.ApplyTheme(self: Paragraph, theme: Theme)
	Element.ApplyTheme(self, theme)
	grow(self.Frame, self.Body, self.Control)
end

function Paragraph.Set(self: Paragraph, title: string, text: string)
	self._title.Text = title
	self._text.Text = text
	self:_emit(text)
end

function Paragraph.Get(self: Paragraph): (string, string)
	return self._title.Text, self._text.Text
end

function Paragraph.SetValue(self: Paragraph, value: any)
	self:Set(self._title.Text, tostring(value))
end

function Paragraph.GetValue(self: Paragraph): any
	return self._text.Text
end

return Paragraph
