--!strict
-- Single-line text input. Commits on focus loss, which also covers Return.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Animate = require("@self/../Core/Animate")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

local Textbox = {}
Textbox.__index = Textbox
setmetatable(Textbox, { __index = Element })

export type Textbox = Element.Internal & {
	Set: (self: Textbox, value: string) -> (),
	Get: (self: Textbox) -> string,
	_Box: Frame,
	_Focus: UIStroke,
	_Input: TextBox,
	_Config: { [string]: any },
}

--- Keeps digits, one leading minus and at most one decimal point.
local function sanitize(text: string): string
	local cleaned = (string.gsub(text, "[^%d%.%-]", ""))
	local sign = if string.find(cleaned, "^-") then "-" else ""
	local whole, fraction = string.match((string.gsub(cleaned, "%-", "")), "^(%d*)%.?(%d*)")
	local decimal = if fraction and fraction ~= "" then "." .. fraction else ""
	return sign .. (whole or "0") .. decimal
end

function Textbox.new(tab: any, config: any): Textbox
	local options: { [string]: any } = config or {}
	local theme: Theme = tab.Theme

	local self: Textbox = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				Description = options.Description,
				Flag = options.Flag,
				Height = options.Height,
				ControlWidth = 160,
				ControlHeight = 30,
			}),
			Textbox
		) :: any
	) :: Textbox

	local initial: string = if options.Default ~= nil then tostring(options.Default) else ""
	self.Value = initial
	self._Config = options

	local box = Ui.inset(self.Control, theme, { Name = "Textbox", Size = UDim2.fromScale(1, 1) })
	Ui.pad(box, 0, 10, 0, 10)
	self._Box = box

	local focus = Ui.stroke(box, theme, theme.Accent, 1)
	self._Focus = focus

	local input = New("TextBox", {
		Name = "Input",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = theme.Font,
		TextSize = theme.FontSize,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = initial,
		PlaceholderText = options.Placeholder or "",
		PlaceholderColor3 = theme.TextFaint,
		ClearTextOnFocus = options.ClearOnFocus == true,
	}, nil, box)
	self._Input = input

	input.Focused:Connect(function()
		Animate.play(focus, { Transparency = 0 }, 0.15, self.Theme.Easing)
	end)

	input.FocusLost:Connect(function()
		Animate.play(focus, { Transparency = 1 }, 0.15, self.Theme.Easing)

		local text = input.Text
		if options.Numeric then
			text = sanitize(text)
			input.Text = text
		end
		self:Set(text)
	end)

	self:OnTheme(function(updated: Theme)
		box.BackgroundColor3 = updated.Inset
		box.BackgroundTransparency = updated.InsetTransparency
		focus.Color = updated.Accent
		input.Font = updated.Font
		input.TextSize = updated.FontSize
		input.TextColor3 = updated.Text
		input.PlaceholderColor3 = updated.TextFaint
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Textbox.Set(self: Textbox, value: string)
	self.Value = value
	self._Input.Text = value
	self:_emit(value)
	if self._Config.Callback then
		self._Config.Callback(value)
	end
end

function Textbox.Get(self: Textbox): string
	return self.Value
end

function Textbox.SetValue(self: Textbox, value: any)
	self:Set(value)
end

function Textbox.GetValue(self: Textbox): any
	return self:Get()
end

return Textbox
