--!strict
-- Switch. The whole row is the hit target, so anywhere on the row toggles it.

local Ui = require("@self/../Core/Ui")
local Animate = require("@self/../Core/Animate")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

local Toggle = {}
Toggle.__index = Toggle
setmetatable(Toggle, { __index = Element })

export type Toggle = Element.Internal & {
	Set: (self: Toggle, value: boolean) -> (),
	Get: (self: Toggle) -> boolean,
	GetValue: (self: Toggle) -> any,
	SetValue: (self: Toggle, value: any) -> (),
	_apply: (self: Toggle, on: boolean, animate: boolean?) -> (),
	_on: boolean,
	_hovered: boolean,
	_track: Frame,
	_fill: Frame,
	_knob: Frame,
	_knobStroke: UIStroke,
	_callback: ((boolean) -> ())?,
}

local TRACK_WIDTH = 40
local TRACK_HEIGHT = 22
local KNOB = 18
local KNOB_HOVER = 20
local EDGE = 2

local function knobPosition(on: boolean, size: number): UDim2
	return UDim2.new(0, if on then TRACK_WIDTH - size - EDGE else EDGE, 0.5, 0)
end

function Toggle.new(tab: any, config: any): Toggle
	local options = config or {}
	local self: Toggle = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				Description = options.Description,
				Flag = options.Flag,
				Height = options.Height,
				ControlWidth = TRACK_WIDTH,
				ControlHeight = TRACK_HEIGHT,
			}),
			Toggle
		) :: any
	) :: Toggle

	local theme: Theme = tab.Theme
	self._on = false
	self._hovered = false
	self._callback = options.Callback

	local track = Ui.pill(self.Control, theme, theme.Track)
	track.Name = "Track"
	track.Size = UDim2.fromOffset(TRACK_WIDTH, TRACK_HEIGHT)
	self._track = track

	local fill = Ui.accentFill(track, theme, theme.SwitchOn)
	fill.Name = "Fill"
	fill.Size = UDim2.new(0, 0, 1, 0)
	self._fill = fill

	local knob = Ui.pill(track, theme, theme.SwitchKnob)
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0, 0.5)
	knob.Size = UDim2.fromOffset(KNOB, KNOB)
	knob.Position = knobPosition(false, KNOB)
	self._knob = knob
	self._knobStroke = Ui.stroke(knob, theme, theme.Window, 0.55)

	Ui.hover(self.Frame, function(hovered: boolean)
		self._hovered = hovered
		local size = if hovered then KNOB_HOVER else KNOB
		local current = self.Theme
		Animate.play(knob, {
			Size = UDim2.fromOffset(size, size),
			Position = knobPosition(self._on, size),
		}, current.Duration, current.Easing)
	end)

	self.Frame.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			self:Set(not self._on)
		end
	end)

	self:OnTheme(function(next: Theme)
		track.BackgroundColor3 = next.Track
		track.BackgroundTransparency = next.TrackTransparency
		Ui.accentTheme(self._fill, next, next.SwitchOn)
		knob.BackgroundColor3 = if self._on then next.SwitchKnobOn else next.SwitchKnob
		self._knobStroke.Color = next.Window
	end)

	self:_apply(options.Default == true, false)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Toggle._apply(self: Toggle, on: boolean, animate: boolean?)
	local theme = self.Theme
	local size = if self._hovered then KNOB_HOVER else KNOB
	self._on = on
	self.Value = on

	local knobGoal: { [string]: any } = {
		Size = UDim2.fromOffset(size, size),
		Position = knobPosition(on, size),
		BackgroundColor3 = if on then theme.SwitchKnobOn else theme.SwitchKnob,
	}
	local fillGoal: { [string]: any } = {
		Size = UDim2.new(if on then 1 else 0, 0, 1, 0),
	}

	if animate == false then
		Animate.snap(self._fill, fillGoal)
		Animate.snap(self._knob, knobGoal)
	else
		Animate.play(self._fill, fillGoal, theme.Duration, theme.Easing)
		Animate.play(self._knob, knobGoal, theme.Duration, theme.Easing)
	end
end

function Toggle.Set(self: Toggle, value: boolean)
	local on = value == true
	if on == self._on then
		return
	end

	self:_apply(on, true)
	self:_emit(on)

	if self._callback then
		self._callback(on)
	end
end

function Toggle.Get(self: Toggle): boolean
	return self._on
end

function Toggle.GetValue(self: Toggle): any
	return self._on
end

function Toggle.SetValue(self: Toggle, value: any)
	self:Set(value == true)
end

return Toggle
