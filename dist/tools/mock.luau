-- Headless Roblox shim for the Luau CLI. tools/smoke.mjs concatenates this ahead
-- of the bundled library, so it is a chunk that installs globals, not a module.
-- It is deliberately generic: instances are proxies, not per-class records.
-- MOCK_PROFILE picks which executor capability set it pretends to be.

local state = setmetatable({}, { __mode = "k" })
local pending = {}
local files = {}
local folders = {}
local sharedEnv = {}
local services = {}
local enumTypes = {}
local lockedParents = {}

--- Which executor this run pretends to be: full, aliases, bare or locked.
--- tools/smoke.mjs assigns MOCK_PROFILE on the line before this chunk runs.
local PROFILE = MOCK_PROFILE or "full"

-- ---------------------------------------------------------------- typeof ----
-- Config persistence branches on typeof(), so a moc[...]k Color3 must report as
-- "Color3" and an enum item as "EnumItem" exactly like the real VM does.
local rawTypeof = typeof
typeof = function(value)
	local meta = getmetatable(value)
	if type(meta) == "table" and type(meta.__type) == "string" then
		return meta.__type
	end
	return rawTypeof(value)
end

-- ------------------------------------------------------------- datatypes ----

Color3 = {}
Color3.__index = Color3
Color3.__type = "Color3"

function Color3.new(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, Color3)
end

function Color3.fromRGB(r, g, b)
	return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end

function Color3.fromHSV(h, s, v)
	local hue = ((h or 0) % 360) / 60
	local i = math.floor(hue)
	local f = hue - i
	local p = (v or 0) * (1 - (s or 0))
	local q = (v or 0) * (1 - (s or 0) * f)
	local t = (v or 0) * (1 - (s or 0) * (1 - f))
	if i == 0 then
		return Color3.new(v, t, p)
	elseif i == 1 then
		return Color3.new(q, v, p)
	elseif i == 2 then
		return Color3.new(p, v, t)
	elseif i == 3 then
		return Color3.new(p, q, v)
	elseif i == 4 then
		return Color3.new(t, p, v)
	end
	return Color3.new(v, p, q)
end

function Color3.ToHSV(self)
	local r, g, b = self.R, self.G, self.B
	local max, min = math.max(r, g, b), math.min(r, g, b)
	local delta = max - min
	local h = 0
	if delta > 0 then
		if max == r then
			h = 60 * (((g - b) / delta) % 6)
		elseif max == g then
			h = 60 * ((b - r) / delta + 2)
		else
			h = 60 * ((r - g) / delta + 4)
		end
	end
	-- Roblox reports hue as 0..1, unlike Color3.fromHSV which takes degrees.
	return h / 360, (if max == 0 then 0 else delta / max), max
end

function Color3.Lerp(self, other, t)
	return Color3.new(
		self.R + (other.R - self.R) * t,
		self.G + (other.G - self.G) * t,
		self.B + (other.B - self.B) * t
	)
end

function Color3.ToHex(self)
	return string.format(
		"#%02X%02X%02X",
		math.round(self.R * 255),
		math.round(self.G * 255),
		math.round(self.B * 255)
	)
end

Vector2 = {}
Vector2.__index = Vector2

function Vector2.new(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, Vector2)
end

Vector2.zero = Vector2.new(0, 0)
Vector2.one = Vector2.new(1, 1)
Vector2.__add = function(a, b)
	return Vector2.new(a.X + b.X, a.Y + b.Y)
end
Vector2.__sub = function(a, b)
	return Vector2.new(a.X - b.X, a.Y - b.Y)
end
Vector2.__mul = function(a, b)
	return Vector2.new(a.X * b, a.Y * b)
end
Vector2.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y
end

Vector3 = {}
Vector3.__index = Vector3
Vector3.__type = "Vector3"

function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, Vector3)
end

Vector3.zero = Vector3.new(0, 0, 0)
Vector3.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
Vector3.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end

UDim = {}
UDim.__index = UDim
UDim.__type = "UDim"

function UDim.new(scale, offset)
	return setmetatable({ Scale = scale or 0, Offset = offset or 0 }, UDim)
end

UDim2 = {}
UDim2.__index = UDim2
UDim2.__type = "UDim2"

function UDim2.new(xScale, xOffset, yScale, yOffset)
	return setmetatable({ X = UDim.new(xScale, xOffset), Y = UDim.new(yScale, yOffset) }, UDim2)
end

function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end

function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end

UDim2.zero = UDim2.new()

Rect = {}
Rect.__index = Rect
Rect.__type = "Rect"

function Rect.new(x, y, width, height)
	return setmetatable(
		{ Min = Vector2.new(x, y), Max = Vector2.new((x or 0) + (width or 0), (y or 0) + (height or 0)) },
		Rect
	)
end

NumberSequenceKeypoint = {}
function NumberSequenceKeypoint.new(time, value)
	return { Time = time or 0, Value = value or 0 }
end

NumberSequence = {}
NumberSequence.__type = "NumberSequence"
function NumberSequence.new(value)
	if type(value) == "number" then
		return { Keypoints = { NumberSequenceKeypoint.new(0, value), NumberSequenceKeypoint.new(1, value) } }
	end
	return { Keypoints = value }
end

ColorSequenceKeypoint = {}
function ColorSequenceKeypoint.new(time, color)
	return { Time = time or 0, Value = color }
end

ColorSequence = {}
ColorSequence.__type = "ColorSequence"
function ColorSequence.new(first, second)
	if second == nil then
		return { Keypoints = first }
	end
	return { Keypoints = { ColorSequenceKeypoint.new(0, first), ColorSequenceKeypoint.new(1, second) } }
end

TweenInfo = {}
TweenInfo.__type = "TweenInfo"
function TweenInfo.new(time, style, direction, repeatCount, reverses, delayTime)
	return {
		Time = time or 1,
		EasingStyle = style,
		EasingDirection = direction,
		RepeatCount = repeatCount or 0,
		Reverses = reverses or false,
		DelayTime = delayTime or 0,
	}
end

-- ------------------------------------------------------------------ Enum ----

local ITEM_META = { __type = "EnumItem" }

Enum = setmetatable({}, {
	__index = function(_, enumName)
		local cached = enumTypes[enumName]
		if cached then
			return cached
		end

		local items = {}
		local enumType
		enumType = setmetatable({}, {
			__index = function(_, itemName)
				local item = items[itemName]
				if item then
					return item
				end
				-- EnumType is the enum table itself, the way the real VM reports it.
				item = setmetatable({ Name = itemName, Value = #items + 1, EnumType = enumType }, ITEM_META)
				items[itemName] = item
				return item
			end,
		})

		enumTypes[enumName] = enumType
		return enumType
	end,
})

-- ----------------------------------------------------------------- Signal ----

local function newSignal()
	local listeners = {}

	local signal = {}

	function signal.Connect(_self, callback)
		local connection = { Connected = true }
		function connection.Disconnect()
			if not connection.Connected then
				return
			end
			connection.Connected = false
			for index, entry in listeners do
				if entry.connection == connection then
					table.remove(listeners, index)
					break
				end
			end
		end
		table.insert(listeners, { connection = connection, callback = callback })
		return connection
	end

	function signal.Once(_self, callback)
		local connection
		connection = signal:Connect(function(...)
			connection:Disconnect()
			callback(...)
		end)
		return connection
	end

	function signal.Fire(_self, ...)
		for _, entry in table.clone(listeners) do
			if entry.connection.Connected then
				entry.callback(...)
			end
		end
	end

	function signal.Wait(_self) end

	function signal.DisconnectAll(_self)
		for _, entry in table.clone(listeners) do
			entry.connection:Disconnect()
		end
	end

	return signal
end

-- --------------------------------------------------------------- Instances ----

local EVENT_NAMES = {
	Changed = true,
	ChildAdded = true,
	ChildRemoved = true,
	AncestryChanged = true,
	Destroying = true,
	MouseEnter = true,
	MouseLeave = true,
	InputBegan = true,
	InputChanged = true,
	InputEnded = true,
	Activated = true,
	MouseButton1Down = true,
	MouseButton1Up = true,
	MouseButton1Click = true,
	Focused = true,
	FocusLost = true,
	ReturnPressedFromOnScreenKeyboard = true,
	TextChanged = true,
	SelectionChanged = true,
	Completed = true,
}

local SUPER = {
	TextLabel = "GuiObject",
	TextButton = "GuiObject",
	ImageLabel = "GuiObject",
	ImageButton = "GuiObject",
	TextBox = "GuiObject",
	Frame = "GuiObject",
	ScrollingFrame = "GuiObject",
	CanvasGroup = "GuiObject",
	ViewportFrame = "GuiObject",
	VideoFrame = "GuiObject",
	GuiObject = "GuiBase2d",
	GuiBase2d = "Instance",
	ScreenGui = "GuiBase2d",
	BillboardGui = "GuiBase2d",
	SurfaceGui = "GuiBase2d",
	BlurEffect = "PostEffect",
	PostEffect = "Instance",
	UIGradient = "UIComponent",
	UIStroke = "UIComponent",
	UICorner = "UIComponent",
	UIPadding = "UIComponent",
	UIShadow = "UIComponent",
	UIComponent = "Instance",
	UIListLayout = "UILayout",
	UILayout = "UIComponent",
	UIGridLayout = "UILayout",
	UITableLayout = "UILayout",
	UIScale = "UIComponent",
	DataModel = "Instance",
	Workspace = "Instance",
	Player = "Instance",
	PlayerGui = "Instance",
	Folder = "Instance",
}

local METHODS = {}
local attributes
local propertySignals

local function instanceState(self)
	return state[self]
end

local function computedAbsoluteSize(self, depth)
	local st = state[self]
	if not st then
		return Vector2.new(0, 0)
	end
	if st.props.AbsoluteSize then
		return st.props.AbsoluteSize
	end

	local size = st.props.Size
	if not size then
		return Vector2.new(0, 0)
	end

	local parentSize = Vector2.new(0, 0)
	if st.props.Parent and (depth or 0) < 12 then
		parentSize = computedAbsoluteSize(st.props.Parent, (depth or 0) + 1)
	end

	return Vector2.new(
		size.X.Offset + size.X.Scale * parentSize.X,
		size.Y.Offset + size.Y.Scale * parentSize.Y
	)
end

local function computedAbsolutePosition(self, depth)
	local st = state[self]
	if not st then
		return Vector2.new(0, 0)
	end
	if st.props.AbsolutePosition then
		return st.props.AbsolutePosition
	end

	local position = st.props.Position
	if not position then
		return Vector2.new(0, 0)
	end

	local parent = st.props.Parent
	if parent == nil or (depth or 0) >= 12 then
		return Vector2.new(position.X.Offset, position.Y.Offset)
	end

	local parentPosition = computedAbsolutePosition(parent, (depth or 0) + 1)
	local parentSize = computedAbsoluteSize(parent, 0)
	return Vector2.new(
		parentPosition.X + position.X.Offset + position.X.Scale * parentSize.X,
		parentPosition.Y + position.Y.Offset + position.Y.Scale * parentSize.Y
	)
end

--- Roblox guarantees a value for every property, so reading one the library
--- never wrote must not come back nil. AbsoluteSize/AbsolutePosition are
--- deliberately absent: they are computed from Size/Position below.
local DEFAULTS = {
	Name = "",
	ClassName = "Instance",
	Text = "",
	Visible = true,
	Enabled = true,
	Active = false,
	LayoutOrder = 0,
	ZIndex = 1,
	Rotation = 0,
	ClipsDescendants = false,
	BackgroundTransparency = 0,
	BackgroundColor3 = Color3.new(1, 1, 1),
	BorderSizePixel = 1,
	TextTransparency = 0,
	TextColor3 = Color3.new(1, 1, 1),
	ImageTransparency = 0,
	GroupTransparency = 0,
	ScrollBarThickness = 12,
	Position = UDim2.new(),
	Size = UDim2.new(),
	AnchorPoint = Vector2.new(),
	CanvasSize = UDim2.new(),
	CanvasPosition = Vector2.new(),
}

local instanceMeta = {}

instanceMeta.__index = function(self, key)
	local st = state[self]
	if not st then
		return nil
	end

	if key == "ClassName" then
		return st.props.ClassName
	end

	local method = METHODS[key]
	if method then
		return method
	end

	if EVENT_NAMES[key] then
		if not st.events[key] then
			st.events[key] = newSignal()
		end
		return st.events[key]
	end

	local value = st.props[key]
	if value ~= nil then
		return value
	end

	if key == "AbsoluteSize" then
		return computedAbsoluteSize(self, 0)
	end
	if key == "AbsolutePosition" then
		return computedAbsolutePosition(self, 0)
	end
	if key == "TextBounds" then
		return Vector2.new(#tostring(st.props.Text or "") * 7, 14)
	end
	if key == "AbsoluteRotation" then
		return 0
	end
	if key == "Parent" then
		return nil
	end

	return DEFAULTS[key]
end

--- Events are created on first use, including from __newindex, so assigning
--- Parent before anything ever read .ChildAdded still fires it.
local function eventFor(st, name)
	if not st.events[name] then
		st.events[name] = newSignal()
	end
	return st.events[name]
end

instanceMeta.__newindex = function(self, key, value)
	local st = state[self]
	if not st then
		return
	end

	if key == "Parent" then
		-- A container that refuses children, so the library's mount fallback
		-- chain has something real to walk past.
		if lockedParents[value] then
			error("mock: parent is locked", 2)
		end

		local previous = st.props.Parent
		if previous ~= nil then
			local previousState = state[previous]
			if previousState then
				for index, child in previousState.children do
					if child == self then
						table.remove(previousState.children, index)
						break
					end
				end
				eventFor(previousState, "ChildRemoved"):Fire(self)
			end
		end

		st.props.Parent = value

		if value ~= nil then
			local nextState = state[value]
			if nextState then
				table.insert(nextState.children, self)
				eventFor(nextState, "ChildAdded"):Fire(self)
			end
		end

		eventFor(st, "Changed"):Fire("Parent")
		return
	end

	if METHODS[key] or EVENT_NAMES[key] then
		return
	end

	st.props[key] = value
	if st.events.Changed then
		st.events.Changed:Fire(key)
	end

	local bag = propertySignals[self]
	if bag and bag[key] then
		bag[key]:Fire(value)
	end
end

local function newInstance(className)
	local self = setmetatable({}, instanceMeta)
	state[self] = {
		props = { ClassName = className, Name = "" },
		children = {},
		events = {},
		destroyed = false,
	}
	return self
end

function METHODS.FindFirstChild(self, name, recursive)
	local st = state[self]
	for _, child in st.children do
		if child.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in st.children do
			local found = METHODS.FindFirstChild(child, name, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function METHODS.WaitForChild(self, name)
	return METHODS.FindFirstChild(self, name)
end

local function inheritsFrom(className, target)
	if className == target then
		return true
	end
	local current = SUPER[className]
	local guard = 0
	while current and guard < 12 do
		if current == target then
			return true
		end
		current = SUPER[current]
		guard += 1
	end
	return false
end

function METHODS.IsA(self, className)
	return inheritsFrom(state[self].props.ClassName, className)
end

function METHODS.FindFirstChildOfClass(self, className)
	for _, child in state[self].children do
		if state[child].props.ClassName == className then
			return child
		end
	end
	return nil
end

function METHODS.FindFirstChildWhichIsA(self, className)
	for _, child in state[self].children do
		if inheritsFrom(state[child].props.ClassName, className) then
			return child
		end
	end
	return nil
end

function METHODS.GetChildren(self)
	return table.clone(state[self].children)
end

function METHODS.GetDescendants(self)
	local out = {}
	local function walk(node)
		for _, child in state[node].children do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end

function METHODS.FindFirstAncestorOfClass(self, className)
	local parent = state[self].props.Parent
	while parent do
		if state[parent].props.ClassName == className then
			return parent
		end
		parent = state[parent].props.Parent
	end
	return nil
end

function METHODS.FindFirstAncestorWhichIsA(self, className)
	local parent = state[self].props.Parent
	while parent do
		if inheritsFrom(state[parent].props.ClassName, className) then
			return parent
		end
		parent = state[parent].props.Parent
	end
	return nil
end

function METHODS.GetFullName(self)
	local parts = {}
	local node = self
	while node do
		table.insert(parts, 1, node.Name)
		node = state[node].props.Parent
	end
	return table.concat(parts, ".")
end

function METHODS.ClearAllChildren(self)
	for _, child in METHODS.GetChildren(self) do
		state[child].props.Parent = nil
	end
	state[self].children = {}
end

function METHODS.Destroy(self)
	local st = state[self]
	if st.destroyed then
		return
	end
	st.destroyed = true
	eventFor(st, "Destroying"):Fire()
	METHODS.ClearAllChildren(self)

	local parent = st.props.Parent
	if parent ~= nil then
		local parentState = state[parent]
		if parentState then
			for index, child in parentState.children do
				if child == self then
					table.remove(parentState.children, index)
					break
				end
			end
			eventFor(parentState, "ChildRemoved"):Fire(self)
		end
		st.props.Parent = nil
	end
	state[self] = nil
end

function METHODS.Clone(self)
	local st = state[self]
	local copy = newInstance(st.props.ClassName)
	for key, value in st.props do
		if key ~= "Parent" and key ~= "ClassName" then
			copy[key] = value
		end
	end
	for _, child in st.children do
		local childCopy = METHODS.Clone(child)
		childCopy.Parent = copy
	end
	return copy
end

attributes = setmetatable({}, { __mode = "k" })

function METHODS.GetAttribute(self, name)
	local bag = attributes[self]
	return bag and bag[name]
end

function METHODS.SetAttribute(self, name, value)
	if not attributes[self] then
		attributes[self] = {}
	end
	attributes[self][name] = value
end

function METHODS.GetAttributes(self)
	local bag = attributes[self]
	local out = {}
	if bag then
		for key, value in bag do
			out[key] = value
		end
	end
	return out
end

propertySignals = setmetatable({}, { __mode = "k" })

function METHODS.GetPropertyChangedSignal(self, property)
	if not propertySignals[self] then
		propertySignals[self] = {}
	end
	if not propertySignals[self][property] then
		propertySignals[self][property] = newSignal()
	end
	return propertySignals[self][property]
end

function METHODS.GetService(self, name)
	local cached = services[name]
	if cached then
		return cached
	end
	local service = newInstance(name)
	service.Name = name
	service.Parent = self
	services[name] = service
	return service
end

__httpGetCalls = 0

--- game:HttpGet is a Roblox API rather than an executor one, so every profile
--- has it; the library falls back to it when there is no request().
function METHODS.HttpGet(_self, url)
	__httpGetCalls += 1
	return "httpget:" .. tostring(url)
end

Instance = {}
function Instance.new(className)
	return newInstance(className)
end
function Instance.fromExisting(instance)
	return instance
end

-- ------------------------------------------------------------------- game ----

game = newInstance("DataModel")
game.Name = "Game"
workspace = newInstance("Workspace")
workspace.Name = "Workspace"

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
game:GetService("RunService")
game:GetService("CoreGui")
game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
game:GetService("GuiService")
game:GetService("ContextActionService")
game:GetService("StarterGui")
game:GetService("SoundService")

--- A viewport, so the window's default-size clamp and Maximize() have something
--- to measure against.
local camera = newInstance("Camera")
camera.Name = "Camera"
camera.ViewportSize = Vector2.new(1920, 1080)
camera.Parent = workspace
workspace.CurrentCamera = camera

local localPlayer = newInstance("Player")
localPlayer.Name = "SmokePlayer"
localPlayer.Parent = Players
local playerGui = newInstance("PlayerGui")
playerGui.Name = "PlayerGui"
playerGui.Parent = localPlayer
Players.LocalPlayer = localPlayer

UserInputService.KeyboardEnabled = true
UserInputService.MouseEnabled = true
UserInputService.TouchEnabled = false
UserInputService.GetFocusedTextBox = function(_self)
	return nil
end

local function queueCallback(fn)
	table.insert(pending, { kind = "fn", fn = fn })
end

TweenService.Create = function(_self, instance, _info, goal)
	local completed = newSignal()
	local tween = {}

	tween.Play = function()
		for key, value in goal do
			instance[key] = value
		end
		queueCallback(function()
			completed:Fire(Enum.PlaybackState.Completed)
		end)
	end
	tween.Cancel = function() end
	tween.Pause = function() end
	tween.Completed = completed

	return tween
end

TextService.GetTextSize = function(_self, text, size, _font, _bounds)
	return Vector2.new(#tostring(text) * (size or 14) * 0.5, size or 14)
end

-- -------------------------------------------------------------- HttpService ----

local function jsonEncode(value)
	local kind = type(value)
	if kind == "nil" then
		return "null"
	end
	if kind == "boolean" then
		return if value then "true" else "false"
	end
	if kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return "null"
		end
		if value == math.floor(value) then
			return string.format("%d", value)
		end
		return string.format("%.14g", value)
	end
	if kind == "string" then
		local escaped = string.gsub(value, '[%c"\\]', function(character)
			if character == '"' then
				return '\\"'
			elseif character == "\\" then
				return "\\\\"
			elseif character == "\n" then
				return "\\n"
			elseif character == "\r" then
				return "\\r"
			elseif character == "\t" then
				return "\\t"
			end
			return string.format("\\u%04x", string.byte(character))
		end)
		return '"' .. escaped .. '"'
	end
	if kind == "table" then
		if #value > 0 then
			local parts = {}
			for _, item in value do
				table.insert(parts, jsonEncode(item))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		local parts = {}
		for key, item in value do
			if type(key) == "string" then
				table.insert(parts, jsonEncode(key) .. ":" .. jsonEncode(item))
			end
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local function jsonDecode(text)
	local position = 1

	local function skip()
		while position <= #text do
			local character = string.sub(text, position, position)
			if character == " " or character == "\t" or character == "\n" or character == "\r" then
				position += 1
			else
				break
			end
		end
	end

	local function parseString()
		position += 1
		local buffer = {}
		while true do
			local character = string.sub(text, position, position)
			if character == '"' then
				position += 1
				break
			end
			if character == "\\" then
				local escape = string.sub(text, position + 1, position + 1)
				position += 2
				if escape == "n" then
					table.insert(buffer, "\n")
				elseif escape == "t" then
					table.insert(buffer, "\t")
				elseif escape == "r" then
					table.insert(buffer, "\r")
				elseif escape == "u" then
					local hex = string.sub(text, position, position + 3)
					position += 4
					table.insert(buffer, utf8.char(tonumber(hex, 16) or 63))
				else
					table.insert(buffer, escape)
				end
			else
				table.insert(buffer, character)
				position += 1
			end
		end
		return table.concat(buffer)
	end

	local function parseNumber()
		local start = position
		while position <= #text and string.match(string.sub(text, position, position), "[%d%.eE%+%-]") do
			position += 1
		end
		return tonumber(string.sub(text, start, position - 1))
	end

	local parseValue
	parseValue = function()
		skip()
		local character = string.sub(text, position, position)

		if character == "{" then
			position += 1
			local object = {}
			skip()
			if string.sub(text, position, position) == "}" then
				position += 1
				return object
			end
			while true do
				skip()
				local key = parseString()
				skip()
				position += 1
				object[key] = parseValue()
				skip()
				local delimiter = string.sub(text, position, position)
				position += 1
				if delimiter == "}" then
					break
				end
			end
			return object
		end

		if character == "[" then
			position += 1
			local array = {}
			skip()
			if string.sub(text, position, position) == "]" then
				position += 1
				return array
			end
			while true do
				local item = parseValue()
				if item ~= nil then
					table.insert(array, item)
				end
				skip()
				local delimiter = string.sub(text, position, position)
				position += 1
				if delimiter == "]" then
					break
				end
			end
			return array
		end

		if character == '"' then
			return parseString()
		end
		if string.sub(text, position, position + 3) == "true" then
			position += 4
			return true
		end
		if string.sub(text, position, position + 4) == "false" then
			position += 5
			return false
		end
		if string.sub(text, position, position + 3) == "null" then
			position += 4
			return nil
		end

		return parseNumber()
	end

	return parseValue()
end

HttpService.JSONEncode = function(_self, value)
	return jsonEncode(value)
end

HttpService.JSONDecode = function(_self, text)
	return jsonDecode(text)
end

-- ------------------------------------------------------------------- task ----

task = {}

local function queueThread(thread, args)
	table.insert(pending, { kind = "co", thread = thread, args = args, resumes = 0 })
end

function task.spawn(fn, ...)
	local thread = coroutine.create(fn)
	local ok, err = coroutine.resume(thread, ...)
	if not ok then
		print("[mock] task.spawn error: " .. tostring(err))
	elseif coroutine.status(thread) ~= "dead" then
		queueThread(thread, {})
	end
	return thread
end

function task.defer(fn, ...)
	queueThread(coroutine.create(fn), { ... })
end

function task.delay(_seconds, fn, ...)
	return task.defer(fn, ...)
end

function task.wait(_seconds)
	if coroutine.isyieldable and coroutine.isyieldable() then
		coroutine.yield()
	end
	return 0
end

function task.cancel(_thread) end

--- Runs every queued callback until the queue is empty, so tween completion,
--- deferred closes and delayed work all settle deterministically.
function __drain()
	local guard = 0
	while #pending > 0 and guard < 4000 do
		guard += 1
		local entry = table.remove(pending, 1)

		if entry.kind == "fn" then
			entry.fn()
		else
			local ok, err = coroutine.resume(entry.thread, table.unpack(entry.args or {}))
			entry.args = {}
			if not ok then
				print("[mock] deferred thread error: " .. tostring(err))
			elseif coroutine.status(entry.thread) ~= "dead" then
				entry.resumes += 1
				if entry.resumes < 12 then
					table.insert(pending, entry)
				end
			end
		end
	end
	return guard
end

-- ---------------------------------------------------------- executor env ----
-- The library finds capabilities by probing globals, so the harness has to be
-- able to present an executor that spells them differently, one that offers
-- nothing at all, and one whose containers refuse children.

local function doWrite(path, contents)
	files[path] = contents
end

local function doRead(path)
	return files[path]
end

local function doAppend(path, contents)
	files[path] = (files[path] or "") .. contents
end

local function doIsFile(path)
	return files[path] ~= nil
end

local function doIsFolder(path)
	return folders[path] == true
end

local function doMakeFolder(path)
	folders[path] = true
end

local function doListFiles(path)
	local out = {}
	local prefix = path .. "/"
	for name in files do
		if string.sub(name, 1, #prefix) == prefix then
			table.insert(out, name)
		end
	end
	return out
end

local function doDeleteFile(path)
	files[path] = nil
end

local function doDeleteFolder(path)
	folders[path] = nil
end

local function doClipboard(text)
	__clipboard = text
end

--- The body both Synapse-style request() and http_request() hand back. Takes
--- the options table or a plain url, like the real ones do.
local function doRequest(options)
	local url = if type(options) == "table" then options.Url else options
	return { Body = "request:" .. tostring(url), StatusCode = 200, Success = true }
end

--- gethui() hands out a hidden container. Built before any lock goes on, so the
--- locked profile can parent it somewhere ordinary first.
local hiddenUi = newInstance("Folder")
hiddenUi.Name = "HiddenUI"
hiddenUi.Parent = game:GetService("CoreGui")

--- Real executors publish their capabilities as bare globals and through
--- getgenv() alike, and the library probes both, so each one goes in twice.
local function installCanonical(name)
	writefile = doWrite
	sharedEnv.writefile = doWrite
	readfile = doRead
	sharedEnv.readfile = doRead
	appendfile = doAppend
	sharedEnv.appendfile = doAppend
	isfile = doIsFile
	sharedEnv.isfile = doIsFile
	isfolder = doIsFolder
	sharedEnv.isfolder = doIsFolder
	makefolder = doMakeFolder
	sharedEnv.makefolder = doMakeFolder
	listfiles = doListFiles
	sharedEnv.listfiles = doListFiles
	delfile = doDeleteFile
	sharedEnv.delfile = doDeleteFile
	delfolder = doDeleteFolder
	sharedEnv.delfolder = doDeleteFolder
	setclipboard = doClipboard
	sharedEnv.setclipboard = doClipboard
	request = doRequest
	sharedEnv.request = doRequest
	getgenv = function()
		return sharedEnv
	end
	identifyexecutor = function()
		return name
	end
	sharedEnv.identifyexecutor = identifyexecutor
end

--- The same capabilities under the spellings the less canonical executors use.
local function installAliased()
	write_file = doWrite
	sharedEnv.write_file = doWrite
	read_file = doRead
	sharedEnv.read_file = doRead
	is_file = doIsFile
	sharedEnv.is_file = doIsFile
	is_folder = doIsFolder
	sharedEnv.is_folder = doIsFolder
	make_folder = doMakeFolder
	sharedEnv.make_folder = doMakeFolder
	list_files = doListFiles
	sharedEnv.list_files = doListFiles
	toclipboard = doClipboard
	sharedEnv.toclipboard = doClipboard
	http_request = doRequest
	sharedEnv.http_request = doRequest
	getgenv = function()
		return sharedEnv
	end
	getexecutorname = function()
		return "AliasMock"
	end
	sharedEnv.getexecutorname = getexecutorname
	getidentity = function()
		return 3
	end
	sharedEnv.getidentity = getidentity
	gethui = function()
		return hiddenUi
	end
	sharedEnv.gethui = gethui
	protectgui = function() end
	sharedEnv.protectgui = protectgui
end

if PROFILE == "aliases" then
	installAliased()
elseif PROFILE ~= "bare" then
	installCanonical(if PROFILE == "locked" then "LockedMock" else "SmokeMock")
end

if PROFILE == "locked" then
	local hui = function()
		return hiddenUi
	end
	gethui = hui
	sharedEnv.gethui = hui

	local protect = function() end
	protect_gui = protect
	sharedEnv.protect_gui = protect

	lockedParents[hiddenUi] = true
	lockedParents[game:GetService("CoreGui")] = true
end

tick = function()
	return os.clock()
end

time = function()
	return os.clock()
end

warn = function(...)
	print("[warn]", ...)
end

__files = files
__folders = folders
__lockedParents = lockedParents
