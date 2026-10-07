--!strict
-- Continuous value picker. Clicking the rail jumps to that value and keeps
-- dragging, so a single press-and-move gesture covers both interactions.

local Ui = require("@self/../Core/Ui")
local Element = require("@self/../Core/Element")
local SignalModule = require("@self/../Core/Signal")
local Input = require("@self/../Core/Input")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme
type Connection = SignalModule.Connection

local Slider = {}
Slider.__index = Slider
setmetatable(Slider, { __index = Element })

export type Slider = Element.Internal & {
	Set: (self: Slider, value: number) -> (),
	Get: (self: Slider) -> number,
	GetValue: (self: Slider) -> any,
	SetValue: (self: Slider, value: any) -> (),
	_format: (number) -> string,
	_apply: (self: Slider, value: number) -> (),
	_quantize: (self: Slider, value: number) -> number,
	_setFromX: (self: Slider, x: number) -> (),
	_min: number,
	_max: number,
	_rounding: number,
	_suffix: string,
	_rail: Frame,
	_fill: Frame,
	_knob: Frame,
	_value: TextLabel,
	_callback: ((number) -> ())?,
}

local RAIL = 140
local RAIL_HEIGHT = 6
local KNOB = 14
local VALUE_WIDTH = 52
local CONTROL_WIDTH = RAIL + 8 + VALUE_WIDTH

local function isPress(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

local function isMove(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch
end

function Slider.new(tab: any, config: any): Slider
	local options = config or {}
	local self: Slider = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				Description = options.Description,
				Flag = options.Flag,
				Height = options.Height,
				ControlWidth = CONTROL_WIDTH,
				ControlHeight = 22,
			}),
			Slider
		) :: any
	) :: Slider

	local theme: Theme = tab.Theme
	self._min = options.Min or 0
	self._max = options.Max or 100
	self._rounding = options.Rounding or 0
	self._suffix = options.Suffix or ""
	self._callback = options.Callback
	self._format = function(value: number): string
		return string.format(`%.{self._rounding}f`, value)
	end

	local rail = Ui.pill(self.Control, theme, theme.Track)
	rail.Name = "Rail"
	rail.AnchorPoint = Vector2.new(0, 0.5)
	rail.Position = UDim2.new(0, 0, 0.5, 0)
	rail.Size = UDim2.fromOffset(RAIL, RAIL_HEIGHT)
	self._rail = rail

	local fill = Ui.accentFill(rail, theme, theme.Accent)
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	self._fill = fill

	local knob = Ui.pill(rail, theme, theme.SliderKnob)
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(0, 0, 0.5, 0)
	knob.Size = UDim2.fromOffset(KNOB, KNOB)
	Ui.stroke(knob, theme, theme.Accent, theme.StrokeTransparency)
	self._knob = knob

	local value = Ui.textDim(theme, self.Control, {
		Name = "Value",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(VALUE_WIDTH, 14),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	self._value = value

	local function beginDrag(input: InputObject)
		if not isPress(input) then
			return
		end

		self:_setFromX(input.Position.X)

		local moveConnection: Connection
		local endConnection: Connection

		moveConnection = Input.Changed:Connect(function(move: InputObject)
			if not isMove(move) then
				return
			end
			self:_setFromX(move.Position.X)
		end)

		endConnection = Input.Ended:Connect(function(release: InputObject)
			if release.UserInputType == input.UserInputType then
				moveConnection:Disconnect()
				endConnection:Disconnect()
			end
		end)
	end

	rail.InputBegan:Connect(beginDrag)
	knob.InputBegan:Connect(beginDrag)

	self:OnTheme(function(next: Theme)
		rail.BackgroundColor3 = next.Track
		rail.BackgroundTransparency = next.TrackTransparency
		Ui.accentTheme(self._fill, next, next.Accent)
		knob.BackgroundColor3 = next.SliderKnob
		value.TextColor3 = next.TextFaint
	end)

	self:_apply(self:_quantize(math.clamp(options.Default or self._min, self._min, self._max)))

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Slider._quantize(self: Slider, value: number): number
	local factor = 10 ^ self._rounding
	return math.round(value * factor) / factor
end

function Slider._apply(self: Slider, value: number)
	local span = self._max - self._min
	local percent = if span == 0 then 0 else (value - self._min) / span

	self.Value = value
	self._fill.Size = UDim2.new(percent, 0, 1, 0)
	self._knob.Position = UDim2.new(percent, 0, 0.5, 0)
	self._value.Text = self._format(value) .. self._suffix
end

function Slider._setFromX(self: Slider, x: number)
	local width = self._rail.AbsoluteSize.X
	if width <= 0 then
		return
	end

	local percent = math.clamp((x - self._rail.AbsolutePosition.X) / width, 0, 1)
	local target = self:_quantize(self._min + percent * (self._max - self._min))
	if target == self.Value then
		return
	end

	self:_apply(target)
	self:_emit(target)

	if self._callback then
		self._callback(target)
	end
end

function Slider.Set(self: Slider, value: number)
	local target = self:_quantize(math.clamp(value, self._min, self._max))
	if target == self.Value then
		return
	end

	self:_apply(target)
	self:_emit(target)

	if self._callback then
		self._callback(target)
	end
end

function Slider.Get(self: Slider): number
	return self.Value
end

function Slider.GetValue(self: Slider): any
	return self.Value
end

function Slider.SetValue(self: Slider, value: any)
	self:Set(tonumber(value) or self._min)
end

return Slider
