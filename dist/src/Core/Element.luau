--!strict
-- Base row. Every element is one of these with a widget dropped into `Control`,
-- which is what keeps spacing, typography and hover feedback identical across
-- the whole library.

local New = require("@self/New")
local Ui = require("@self/Ui")
local Animate = require("@self/Animate")
local SignalModule = require("@self/Signal")
local ThemeModule = require("@self/Theme")

type Theme = ThemeModule.Theme

export type Options = {
	Text: string?,
	Description: string?,
	Height: number?,
	Flag: string?,
	NoLabel: boolean?,
	Hover: boolean?,
	ControlWidth: number?,
	ControlHeight: number?,
	Pad: number?,
}

--- Everything a user of an element touches.
export type Element = {
	Theme: Theme,
	Frame: Frame,
	Body: Frame,
	Control: Frame,
	Label: TextLabel?,
	Description: TextLabel?,
	Flag: string?,
	Value: any,
	Changed: SignalModule.Signal,
	OnTheme: (self: Element, handler: (Theme) -> ()) -> (),
	ApplyTheme: (self: Element, theme: Theme) -> (),
	SetText: (self: Element, text: string) -> (),
	SetDescription: (self: Element, text: string?) -> (),
	SetVisible: (self: Element, visible: boolean) -> (),
	GetVisible: (self: Element) -> boolean,
	GetValue: (self: Element) -> any,
	SetValue: (self: Element, value: any) -> (),
	GetFlag: (self: Element) -> string?,
	SetOrder: (self: Element, order: number) -> (),
	Destroy: (self: Element) -> (),
}

--- Element plus the scaffolding subclasses build on.
export type Internal = Element & {
	_emit: (self: Internal, value: any) -> (),
	_paint: (self: Internal, hovered: boolean) -> (),
	_hover: Frame,
	_corner: UICorner,
	_pad: UIPadding,
	_height: number?,
	_options: Options,
	_themeHandlers: { (Theme) -> () },
}

local Element = {}
Element.__index = Element

--- How opaque the hover tint gets, relative to the theme's own hover alpha.
local function hoverAlpha(theme: Theme): number
	return 0.25 + theme.SurfaceHoverTransparency * 0.75
end

--- Width the label gives up to the control, so the two never overlap.
local function reserved(inner: Internal): number
	return (inner._options.ControlWidth or 0) + inner.Theme.Gap
end

--- Title geometry: a plain row centres its label, a described row lifts it and
--- yields the bottom line. The constructor and SetDescription share this so a
--- description added later lands exactly where a built-in one sits.
local function layoutLabel(inner: Internal, hasDescription: boolean)
	local label = inner.Label
	if not label then
		return
	end

	label.Size = UDim2.new(1, -reserved(inner), 1, if hasDescription then -15 else 0)
	label.TextYAlignment = if hasDescription then Enum.TextYAlignment.Bottom else Enum.TextYAlignment.Center
end

--- Shows `text` under the title, building the line when the row never had one,
--- and removes it when `text` is nil. A row with no title label -- a full-bleed
--- button -- has nowhere to draw it, so there it rides on the options alone,
--- the same way SetText behaves.
local function describe(inner: Internal, text: string?)
	if not inner.Label then
		return
	end

	if text == nil then
		local line = inner.Description
		if line then
			line:Destroy()
			inner.Description = nil
		end
		layoutLabel(inner, false)
		return
	end

	local line = inner.Description
	if line then
		line.Text = text
	else
		local created = Ui.textDim(inner.Theme, inner.Body, {
			Name = "Description",
			Size = UDim2.new(1, -reserved(inner), 0, 15),
			Position = UDim2.new(0, 0, 1, -15),
			TextYAlignment = Enum.TextYAlignment.Top,
		})
		created.Text = text
		inner.Description = created
	end
	layoutLabel(inner, true)
end

function Element.new(theme: Theme, parent: Instance, options: Options?): Internal
	local config: Options = options or {}
	local height = config.Height or theme.RowHeight

	local self: Internal = (
		setmetatable({
			Theme = theme,
			Frame = nil :: any,
			Body = nil :: any,
			Control = nil :: any,
			Label = nil,
			Description = nil,
			Flag = config.Flag,
			Value = nil,
			Changed = SignalModule.new(),
			_hover = nil :: any,
			_corner = nil :: any,
			_pad = nil :: any,
			_height = config.Height,
			_options = config,
			_themeHandlers = {},
		}, Element) :: any
	) :: Internal

	local row = New("Frame", {
		Name = config.Flag or config.Text or "Element",
		Size = UDim2.new(1, 0, 0, height),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, parent)
	self.Frame = row

	local hover = New("Frame", {
		Name = "Hover",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.SurfaceHover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, row)
	self._hover = hover
	self._corner = Ui.corner(hover, Ui.control(theme))

	local body = New("Frame", {
		Name = "Body",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, row)
	self.Body = body
	self._pad = Ui.pad(body, config.Pad or theme.Pad)

	if config.NoLabel then
		self.Control = New("Frame", {
			Name = "Control",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, nil, body)
	else
		self.Control = New("Frame", {
			Name = "Control",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromOffset(config.ControlWidth or 140, config.ControlHeight or 28),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, nil, body)
	end

	if not config.NoLabel and config.Text then
		self.Label = Ui.text(theme, body, {
			Name = "Label",
			Text = config.Text,
			Font = theme.MediumFont,
		})
		describe(self, config.Description)
	end

	if config.Hover ~= false then
		Ui.hover(row, function(hovered: boolean)
			self:_paint(hovered)
		end)
	end

	return self
end

function Element._paint(self: Internal, hovered: boolean)
	local theme = self.Theme
	Animate.play(
		self._hover,
		{ BackgroundTransparency = if hovered then hoverAlpha(theme) else 1 },
		0.12,
		theme.Easing
	)
end

--- Registers a handler run on every theme change, for anything the base class
--- cannot know about such as a slider's fill gradient.
function Element.OnTheme(self: Element, handler: (Theme) -> ())
	table.insert((self :: Internal)._themeHandlers, handler)
end

function Element.ApplyTheme(self: Element, theme: Theme)
	local inner = self :: Internal
	self.Theme = theme

	self.Frame.Size = UDim2.new(1, 0, 0, inner._height or theme.RowHeight)
	inner._hover.BackgroundColor3 = theme.SurfaceHover
	inner._corner.CornerRadius = Ui.control(theme)

	local pad = UDim.new(0, inner._options.Pad or theme.Pad)
	inner._pad.PaddingTop = pad
	inner._pad.PaddingBottom = pad
	inner._pad.PaddingLeft = pad
	inner._pad.PaddingRight = pad

	if self.Label then
		self.Label.Font = theme.MediumFont
		self.Label.TextSize = theme.FontSize
		self.Label.TextColor3 = theme.Text
	end

	if self.Description then
		self.Description.Font = theme.Font
		self.Description.TextSize = theme.SmallFontSize
		self.Description.TextColor3 = theme.TextFaint
	end

	for _, handler in inner._themeHandlers do
		handler(theme)
	end
end

function Element.SetText(self: Element, text: string)
	local inner = self :: Internal
	inner._options.Text = text
	if self.Label then
		self.Label.Text = text
	end
end

--- Sets or clears the description line. A row built without one grows it on
--- demand rather than quietly doing nothing.
function Element.SetDescription(self: Element, text: string?)
	local inner = self :: Internal
	inner._options.Description = text
	describe(inner, text)
end

function Element.SetVisible(self: Element, visible: boolean)
	self.Frame.Visible = visible
end

function Element.GetVisible(self: Element): boolean
	return self.Frame.Visible
end

--- Last value the element published. Config drives elements through the paired
--- SetValue, so subclasses override both and keep `Get`/`Set` for their own API.
function Element.GetValue(self: Element): any
	return self.Value
end

function Element.SetValue(_self: Element, _value: any) end

function Element._emit(self: Internal, value: any)
	self.Value = value
	self.Changed:Fire(value)
end

function Element.SetOrder(self: Element, order: number)
	self.Frame.LayoutOrder = order
end

function Element.GetFlag(self: Element): string?
	return self.Flag
end

function Element.Destroy(self: Element)
	local inner = self :: Internal
	self.Changed:DisconnectAll()
	inner._themeHandlers = {}
	self.Frame:Destroy()
end

return Element
