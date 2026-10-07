--!strict
-- Full-bleed action row. The whole row is the button, so the label is its text.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Animate = require("@self/../Core/Animate")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

local Button = {}
Button.__index = Button
setmetatable(Button, { __index = Element })

export type Button = Element.Internal & {
	SetCallback: (self: Button, callback: () -> ()) -> (),
	SetText: (self: Button, text: string) -> (),
	_paint: (self: Button, hovered: boolean) -> (),
	_action: TextButton,
	_stroke: UIStroke,
	_hovered: boolean,
	_callback: (() -> ())?,
}

function Button.new(tab: any, config: any): Button
	local options = config or {}
	local self: Button = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				Flag = options.Flag,
				Height = options.Height,
				NoLabel = true,
				Pad = 0,
			}),
			Button
		) :: any
	) :: Button

	local theme: Theme = tab.Theme
	self._hovered = false
	self._callback = options.Callback

	local action = New("TextButton", {
		Name = "Action",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Inset,
		BackgroundTransparency = theme.InsetTransparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = options.Text or "",
		Font = theme.MediumFont,
		TextSize = theme.FontSize,
		TextColor3 = theme.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
	}, nil, self.Control)
	Ui.corner(action, Ui.control(theme))
	self._action = action
	self._stroke = Ui.stroke(action, theme, theme.Stroke, 1)

	Ui.hover(action, function(hovered: boolean)
		self:_paint(hovered)
	end)

	action.MouseButton1Down:Connect(function()
		local current = self.Theme
		Animate.play(action, { BackgroundColor3 = Ui.shade(current.Inset, 1.2) }, 0.08, current.Easing)
	end)

	action.MouseButton1Up:Connect(function()
		self:_paint(self._hovered)
	end)

	action.MouseLeave:Connect(function()
		self:_paint(false)
	end)

	action.Activated:Connect(function()
		if self._callback then
			self._callback()
		end
	end)

	self:OnTheme(function(next: Theme)
		action.Font = next.MediumFont
		action.TextSize = next.FontSize
		action.TextColor3 = next.Text
		action.BackgroundColor3 = if self._hovered then next.SurfaceHover else next.Inset
		action.BackgroundTransparency = if self._hovered
			then next.SurfaceHoverTransparency
			else next.InsetTransparency
		self._stroke.Color = next.Stroke
		self._stroke.Thickness = next.StrokeWidth
		self._stroke.Transparency = if self._hovered then next.StrokeTransparency else 1
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Button._paint(self: Button, hovered: boolean)
	self._hovered = hovered
	local theme = self.Theme

	Animate.play(self._action, {
		BackgroundColor3 = if hovered then theme.SurfaceHover else theme.Inset,
		BackgroundTransparency = if hovered then theme.SurfaceHoverTransparency else theme.InsetTransparency,
	}, theme.Duration * 0.6, theme.Easing)

	Animate.play(
		self._stroke,
		{ Transparency = if hovered then theme.StrokeTransparency else 1 },
		theme.Duration * 0.6,
		theme.Easing
	)
end

function Button.SetCallback(self: Button, callback: () -> ())
	self._callback = callback
end

function Button.SetText(self: Button, text: string)
	self._action.Text = text
end

return Button
