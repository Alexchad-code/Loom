--!strict
-- Colour picker. The swatch in the row is the whole collapsed state; everything
-- else lives in a popup so a picker costs one row until it is opened.
--
-- Hue, saturation and value are the source of truth rather than the Color3, so
-- dragging brightness through zero does not throw the hue away.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Input = require("@self/../Core/Input")
local SignalModule = require("@self/../Core/Signal")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme
type Connection = SignalModule.Connection

local HUE_STOPS = 6

local ColorPicker = {}
ColorPicker.__index = ColorPicker
setmetatable(ColorPicker, { __index = Element })

export type ColorPicker = Element.Internal & {
	_hue: number,
	_sat: number,
	_val: number,
	_alpha: number,
	_alphaEnabled: boolean,
	_open: boolean,
	_tab: any,
	_callback: ((Color3, number) -> ())?,
	_header: TextButton,
	_swatch: Frame,
	_popup: Frame?,
	_card: Frame?,
	_square: TextButton?,
	_svMarker: Frame?,
	_hueMarker: Frame?,
	_alphaMarker: Frame?,
	_alphaFill: Frame?,
	_preview: Frame?,
	_channels: { TextBox },
	_hex: TextBox?,
	_outside: Connection?,
	_color: (self: ColorPicker) -> Color3,
	_absorb: (self: ColorPicker, color: Color3) -> (),
	_sync: (self: ColorPicker, announce: boolean) -> (),
	_commitChannel: (self: ColorPicker, index: number, text: string) -> (),
	_compile: (self: ColorPicker, card: Frame, theme: Theme) -> (),
	Open: (self: ColorPicker) -> (),
	Set: (self: ColorPicker, color: Color3) -> (),
	Get: (self: ColorPicker) -> Color3,
	GetAlpha: (self: ColorPicker) -> number,
	SetAlpha: (self: ColorPicker, alpha: number) -> (),
	Close: (self: ColorPicker) -> (),
}

local function hueSequence(): ColorSequence
	local points = {}
	for index = 0, HUE_STOPS do
		local fraction = index / HUE_STOPS
		table.insert(points, ColorSequenceKeypoint.new(fraction, Color3.fromHSV(fraction * 360, 1, 1)))
	end
	return ColorSequence.new(points)
end

local function ramp(from: number, to: number): NumberSequence
	return NumberSequence.new({
		NumberSequenceKeypoint.new(0, from),
		NumberSequenceKeypoint.new(1, to),
	})
end

local function hexOf(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.round(color.R * 255),
		math.round(color.G * 255),
		math.round(color.B * 255)
	)
end

local function parseHex(text: string): Color3?
	local hex = string.match(text, "#?(%x%x%x%x%x%x)")
	if not hex then
		return nil
	end
	local red = tonumber(string.sub(hex, 1, 2), 16)
	local green = tonumber(string.sub(hex, 3, 4), 16)
	local blue = tonumber(string.sub(hex, 5, 6), 16)
	if not red or not green or not blue then
		return nil
	end
	return Color3.fromRGB(red, green, blue)
end

local function inside(object: GuiObject, position: Vector3): boolean
	local origin = object.AbsolutePosition
	local size = object.AbsoluteSize
	return position.X >= origin.X
		and position.X <= origin.X + size.X
		and position.Y >= origin.Y
		and position.Y <= origin.Y + size.Y
end

--- Reports the 0..1 fraction of each axis while a pointer drags across `surface`.
local function track(surface: GuiObject, onFraction: (number, number) -> ())
	surface.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end

		local origin = surface.AbsolutePosition
		local size = surface.AbsoluteSize
		local width = math.max(size.X, 1)
		local height = math.max(size.Y, 1)

		local function report(position: Vector3)
			onFraction(
				math.clamp((position.X - origin.X) / width, 0, 1),
				math.clamp((position.Y - origin.Y) / height, 0, 1)
			)
		end

		report(input.Position)

		local moveConnection: Connection
		local endConnection: Connection

		moveConnection = Input.Changed:Connect(function(move: InputObject)
			local moveKind = move.UserInputType
			if moveKind == Enum.UserInputType.MouseMovement or moveKind == Enum.UserInputType.Touch then
				report(move.Position)
			end
		end)

		endConnection = Input.Ended:Connect(function(release: InputObject)
			if release.UserInputType == kind then
				moveConnection:Disconnect()
				endConnection:Disconnect()
			end
		end)
	end)
end

--- A rounded TextButton, since the draggable surfaces cannot be plain Frames.
local function surface(parent: Instance, theme: Theme, size: UDim2, radius: UDim, order: number): TextButton
	local object = New("TextButton", {
		Size = size,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		LayoutOrder = order,
	}, nil, parent)
	Ui.corner(object, radius)
	return object
end

local function marker(parent: Instance, theme: Theme, size: number): Frame
	local object = Ui.pill(parent, theme, Color3.new(1, 1, 1), 0.72)
	object.Size = UDim2.fromOffset(size, size)
	object.AnchorPoint = Vector2.new(0.5, 0.5)
	object.ZIndex = 3
	Ui.stroke(object, theme, theme.Text, 0.1)
	return object
end

function ColorPicker._color(self: ColorPicker): Color3
	return Color3.fromHSV(self._hue, self._sat, self._val)
end

--- Pulls hue/saturation/value out of `color`, preserving the hue when the
--- colour is grey (white, black and greys carry no hue of their own).
function ColorPicker._absorb(self: ColorPicker, color: Color3)
	local hue, saturation, value = color:ToHSV()
	if saturation > 0 and value > 0 then
		self._hue = hue * 360
	end
	self._sat = saturation
	self._val = value
end

function ColorPicker._sync(self: ColorPicker, announce: boolean)
	local color = self:_color()

	self._swatch.BackgroundColor3 = color
	self._swatch.BackgroundTransparency = 1 - self._alpha

	local card = self._card
	if card then
		if self._square then
			self._square.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
		end
		if self._svMarker then
			self._svMarker.Position = UDim2.fromScale(self._sat, 1 - self._val)
		end
		if self._hueMarker then
			self._hueMarker.Position = UDim2.fromScale(self._hue / 360, 0.5)
			self._hueMarker.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)
		end
		if self._alphaMarker then
			self._alphaMarker.Position = UDim2.fromScale(self._alpha, 0.5)
		end
		if self._alphaFill then
			self._alphaFill.BackgroundColor3 = color
		end
		if self._preview then
			self._preview.BackgroundColor3 = color
			self._preview.BackgroundTransparency = 1 - self._alpha
		end

		local red = math.round(color.R * 255)
		local green = math.round(color.G * 255)
		local blue = math.round(color.B * 255)
		if self._channels[1] then
			self._channels[1].Text = tostring(red)
			self._channels[2].Text = tostring(green)
			self._channels[3].Text = tostring(blue)
		end
		if self._hex then
			self._hex.Text = hexOf(color)
		end
	end

	if not announce then
		return
	end

	self:_emit(color)
	if self._callback then
		self._callback(color, self._alpha)
	end
end

function ColorPicker._commitChannel(self: ColorPicker, index: number, text: string)
	local channel = tonumber(text)
	if not channel then
		self:_sync(false)
		return
	end

	local red = math.round(self:_color().R * 255)
	local green = math.round(self:_color().G * 255)
	local blue = math.round(self:_color().B * 255)

	local clamped = math.clamp(math.round(channel), 0, 255)
	if index == 1 then
		red = clamped
	elseif index == 2 then
		green = clamped
	else
		blue = clamped
	end

	self:_absorb(Color3.fromRGB(red, green, blue))
	self:_sync(true)
end

function ColorPicker._compile(self: ColorPicker, card: Frame, theme: Theme)
	local square = surface(card, theme, UDim2.fromOffset(208, 120), Ui.control(theme), 1)
	square.BackgroundColor3 = Color3.fromHSV(self._hue, 1, 1)

	local wash = New("Frame", {
		Name = "Wash",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 1,
	}, nil, square)
	Ui.corner(wash, Ui.control(theme))
	New("UIGradient", { Rotation = 0, Transparency = ramp(0, 1) }, nil, wash)

	local shade = New("Frame", {
		Name = "Shade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 2,
	}, nil, square)
	Ui.corner(shade, Ui.control(theme))
	New("UIGradient", { Rotation = 90, Transparency = ramp(1, 0) }, nil, shade)

	local svMarker = marker(square, theme, 13)
	self._svMarker = svMarker

	track(square, function(x: number, y: number)
		self._sat = x
		self._val = 1 - y
		self:_sync(true)
	end)

	local hueBar = surface(card, theme, UDim2.fromOffset(208, 14), Ui.control(theme), 2)
	New("UIGradient", { Rotation = 0, Color = hueSequence() }, nil, hueBar)

	local hueMarker = marker(hueBar, theme, 15)
	self._hueMarker = hueMarker

	track(hueBar, function(x: number)
		self._hue = x * 360
		self:_sync(true)
	end)

	if self._alphaEnabled then
		local alphaBar = surface(card, theme, UDim2.fromOffset(208, 14), Ui.control(theme), 3)
		alphaBar.BackgroundColor3 = theme.Track
		alphaBar.BackgroundTransparency = theme.TrackTransparency

		local fill = New("Frame", {
			Name = "Alpha",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = self:_color(),
			BorderSizePixel = 0,
			ZIndex = 1,
		}, nil, alphaBar)
		Ui.corner(fill, Ui.control(theme))
		New("UIGradient", { Rotation = 0, Transparency = ramp(1, 0) }, nil, fill)
		self._alphaFill = fill

		local alphaMarker = marker(alphaBar, theme, 15)
		self._alphaMarker = alphaMarker

		track(alphaBar, function(x: number)
			self._alpha = x
			self:_sync(true)
		end)
	end

	local channels = New("Frame", {
		Name = "Channels",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 4,
	}, nil, card)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, channels)

	local boxes: { TextBox } = {}
	for index, name in { "R", "G", "B" } do
		local holder = Ui.inset(channels, theme, { Size = UDim2.fromOffset(64, 30), LayoutOrder = index })
		local box = New("TextBox", {
			Name = name,
			Size = UDim2.new(1, -16, 1, 0),
			Position = UDim2.new(0, 8, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Font = theme.MonoFont,
			TextSize = theme.SmallFontSize,
			TextColor3 = theme.Text,
			TextXAlignment = Enum.TextXAlignment.Center,
			PlaceholderText = name,
			PlaceholderColor3 = theme.TextFaint,
			ClearTextOnFocus = false,
			Text = "",
		}, nil, holder)

		box.FocusLost:Connect(function()
			self:_commitChannel(index, box.Text)
		end)
		box.ReturnPressedFromOnScreenKeyboard:Connect(function()
			self:_commitChannel(index, box.Text)
		end)

		table.insert(boxes, box)
	end
	self._channels = boxes

	local footer = New("Frame", {
		Name = "Footer",
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = 5,
	}, nil, card)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, footer)

	local hexHolder = Ui.inset(footer, theme, { Size = UDim2.fromOffset(148, 30), LayoutOrder = 1 })
	local hexBox = New("TextBox", {
		Name = "Hex",
		Size = UDim2.new(1, -16, 1, 0),
		Position = UDim2.new(0, 8, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Font = theme.MonoFont,
		TextSize = theme.SmallFontSize,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		PlaceholderText = "#RRGGBB",
		PlaceholderColor3 = theme.TextFaint,
		ClearTextOnFocus = false,
		Text = "",
	}, nil, hexHolder)
	self._hex = hexBox

	local function commitHex()
		local parsed = parseHex(hexBox.Text)
		if not parsed then
			self:_sync(false)
			return
		end
		self:_absorb(parsed)
		self:_sync(true)
	end

	hexBox.FocusLost:Connect(commitHex)
	hexBox.ReturnPressedFromOnScreenKeyboard:Connect(commitHex)

	local previewHolder = Ui.inset(footer, theme, { Size = UDim2.fromOffset(52, 30), LayoutOrder = 2 })
	local preview = Ui.pill(previewHolder, theme, self:_color(), 1 - self._alpha)
	preview.Size = UDim2.new(1, -8, 1, -8)
	preview.AnchorPoint = Vector2.new(0.5, 0.5)
	preview.Position = UDim2.fromScale(0.5, 0.5)
	self._preview = preview
end

function ColorPicker.Close(self: ColorPicker)
	local popup = self._popup
	if not popup then
		return
	end

	self._popup = nil
	self._open = false

	if self._tab.OpenPopup == self then
		self._tab.OpenPopup = nil
	end
	if self._outside then
		self._outside:Disconnect()
		self._outside = nil
	end

	self._card = nil
	self._square = nil
	self._svMarker = nil
	self._hueMarker = nil
	self._alphaMarker = nil
	self._alphaFill = nil
	self._preview = nil
	self._hex = nil
	self._channels = {}

	popup:Destroy()
end

function ColorPicker.Open(self: ColorPicker)
	if self._open then
		return
	end

	local tab = self._tab
	local previous = tab.OpenPopup
	if previous and previous ~= self and previous.Close then
		previous:Close()
	end

	local theme = self.Theme
	local header = self._header
	local origin = header.AbsolutePosition

	local popup = New("Frame", {
		Name = "ColorPicker",
		Position = UDim2.fromOffset(origin.X, origin.Y + header.AbsoluteSize.Y + 6),
		Size = UDim2.new(0, 232, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 40,
	}, nil, tab.Popups)
	Ui.shadow(popup, theme, 18, theme.Corner)

	local card = New("Frame", {
		Name = "Card",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Popup,
		BackgroundTransparency = theme.PopupTransparency,
		BorderSizePixel = 0,
		ZIndex = 1,
	}, nil, popup)
	Ui.corner(card, UDim.new(0, theme.Corner))
	Ui.stroke(card, theme)
	Ui.pad(card, 12)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, card)

	self._popup = popup
	self._card = card
	self._open = true
	tab.OpenPopup = self

	self:_compile(card, theme)
	self:_sync(false)

	self._outside = Input.Began:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.MouseButton1 and kind ~= Enum.UserInputType.Touch then
			return
		end
		if inside(popup, input.Position) or inside(header, input.Position) then
			return
		end
		self:Close()
	end)
end

function ColorPicker.new(tab: any, config: any): ColorPicker
	local options = config or {}

	local self: ColorPicker = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				Description = options.Description,
				Flag = options.Flag,
				ControlWidth = 60,
				ControlHeight = 30,
			}),
			ColorPicker
		) :: any
	) :: ColorPicker

	local theme = tab.Theme
	local default: Color3 = options.Default or Color3.fromRGB(0, 170, 255)

	self._tab = tab
	self._callback = options.Callback
	self._alphaEnabled = options.Alpha == true
	self._alpha = 1
	self._hue = 0
	self._sat = 1
	self._val = 1
	self._open = false
	self._popup = nil
	self._card = nil
	self._outside = nil
	self._channels = {}

	self:_absorb(default)
	if self._sat == 0 or self._val == 0 then
		self._hue = 210
	end
	self.Value = default

	local header = New("TextButton", {
		Name = "Swatch",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Inset,
		BackgroundTransparency = theme.InsetTransparency,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
	}, nil, self.Control)
	Ui.corner(header, Ui.control(theme))
	self._header = header

	local swatch = Ui.pill(header, theme, default)
	swatch.Name = "Fill"
	swatch.AnchorPoint = Vector2.new(0.5, 0.5)
	swatch.Position = UDim2.fromScale(0.5, 0.5)
	swatch.Size = UDim2.new(1, -8, 1, -8)
	self._swatch = swatch

	header.Activated:Connect(function()
		if self._open then
			self:Close()
		else
			self:Open()
		end
	end)

	self:OnTheme(function(next: Theme)
		header.BackgroundColor3 = next.Inset
		header.BackgroundTransparency = next.InsetTransparency
		self:Close()
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function ColorPicker.Set(self: ColorPicker, color: Color3)
	self:_absorb(color)
	self:_sync(true)
end

function ColorPicker.Get(self: ColorPicker): Color3
	return self:_color()
end

function ColorPicker.GetAlpha(self: ColorPicker): number
	return self._alpha
end

function ColorPicker.SetAlpha(self: ColorPicker, alpha: number)
	self._alpha = math.clamp(alpha, 0, 1)
	self:_sync(true)
end

function ColorPicker.SetValue(self: ColorPicker, value: any)
	if typeof(value) == "Color3" then
		self:Set(value)
		return
	end

	if type(value) ~= "table" then
		return
	end

	if typeof(value.Alpha) == "number" then
		self._alpha = math.clamp(value.Alpha, 0, 1)
	end
	if typeof(value.Color) == "Color3" then
		self:_absorb(value.Color)
	end
	self:_sync(true)
end

function ColorPicker.GetValue(self: ColorPicker): any
	return { Color = self:_color(), Alpha = self._alpha }
end

return ColorPicker
