--!strict
-- Key capture row. Click to listen, the next key wins, Escape or Backspace clears.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Animate = require("@self/../Core/Animate")
local Element = require("@self/../Core/Element")
local Input = require("@self/../Core/Input")
local SignalModule = require("@self/../Core/Signal")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme
type Connection = SignalModule.Connection

local Keybind = {}
Keybind.__index = Keybind
setmetatable(Keybind, { __index = Element })

export type Keybind = Element.Internal & {
	Set: (self: Keybind, key: Enum.KeyCode?) -> (),
	Get: (self: Keybind) -> Enum.KeyCode?,
	Close: (self: Keybind) -> (),
	_Button: TextButton,
	_Label: TextLabel,
	_Listening: boolean,
	_Connection: Connection?,
	_Listen: () -> (),
	_Stop: () -> (),
	_Config: { [string]: any },
}

local function keyName(key: Enum.KeyCode?): string
	return if key then key.Name else "None"
end

function Keybind.new(tab: any, config: any): Keybind
	local options: { [string]: any } = config or {}
	local theme: Theme = tab.Theme

	local self: Keybind = (
		setmetatable(
			Element.new(tab.Theme, tab.Content, {
				Text = options.Text,
				Description = options.Description,
				Flag = options.Flag,
				Height = options.Height,
				ControlWidth = 120,
				ControlHeight = 30,
			}),
			Keybind
		) :: any
	) :: Keybind

	local key = options.Default
	if type(key) == "string" then
		key = (Enum.KeyCode :: any)[key]
	end
	self.Value = key
	self._Config = options
	self._Listening = false

	local button = New("TextButton", {
		Name = "Keybind",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Inset,
		BackgroundTransparency = theme.InsetTransparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, nil, self.Control)
	Ui.corner(button, Ui.control(theme))
	Ui.stroke(button, theme, nil, 0.6)
	self._Button = button

	local label = Ui.text(theme, button, {
		Name = "Key",
		Text = keyName(key),
		Font = theme.MediumFont,
		Size = UDim2.fromScale(1, 1),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	self._Label = label

	local function stop()
		if not self._Listening then
			return
		end
		self._Listening = false

		local connection = self._Connection
		if connection then
			connection:Disconnect()
			self._Connection = nil
		end

		label.Text = keyName(self.Value)
		Animate.play(label, { TextColor3 = self.Theme.Text }, 0.2, self.Theme.Easing)
	end

	local function listen()
		if self._Listening then
			return
		end
		self._Listening = true
		label.Text = "..."

		task.spawn(function()
			while self._Listening do
				Animate.play(label, { TextColor3 = self.Theme.Accent }, 0.45, self.Theme.Easing)
				task.wait(0.45)
				if not self._Listening then
					break
				end
				Animate.play(label, { TextColor3 = self.Theme.TextDim }, 0.45, self.Theme.Easing)
				task.wait(0.45)
			end
		end)

		self._Connection = Input.Began:Connect(function(inputObject: InputObject, gameProcessed: boolean)
			if gameProcessed then
				return
			end

			local pressed = inputObject.KeyCode
			if pressed == (Enum.KeyCode :: any).Unknown then
				return
			end

			stop()
			if pressed == Enum.KeyCode.Escape or pressed == Enum.KeyCode.Backspace then
				self:Set(nil)
			else
				self:Set(pressed)
			end
		end)
	end

	self._Listen = listen
	self._Stop = stop

	button.Activated:Connect(function()
		if self._Listening then
			stop()
		else
			listen()
		end
	end)

	self:OnTheme(function(updated: Theme)
		button.BackgroundColor3 = updated.Inset
		button.BackgroundTransparency = updated.InsetTransparency
		label.Font = updated.MediumFont
		label.TextSize = updated.FontSize
		if not self._Listening then
			label.TextColor3 = updated.Text
		end
	end)

	if tab._register then
		tab:_register(self)
	end

	return self
end

function Keybind.Close(self: Keybind)
	self._Stop()
end

function Keybind.Set(self: Keybind, key: Enum.KeyCode?)
	self.Value = key
	self._Label.Text = keyName(key)
	self:_emit(key)
	if self._Config.Callback then
		self._Config.Callback(key)
	end
end

function Keybind.Get(self: Keybind): Enum.KeyCode?
	return self.Value
end

function Keybind.SetValue(self: Keybind, value: any)
	self:Set(value)
end

function Keybind.GetValue(self: Keybind): any
	return self:Get()
end

return Keybind
