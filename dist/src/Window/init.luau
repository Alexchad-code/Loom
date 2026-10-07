--!strict
-- The window shell. Everything a user sees hangs off this: the screen gui, the
-- drag and resize handles, the sidebar, the page area and the notification
-- stack. Popups deliberately live in their own layer above the panel so a
-- dropdown can be taller than the space it was opened from.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Env = require("@self/../Core/Env")
local Input = require("@self/../Core/Input")
local Config = require("@self/../Core/Config")
local Animate = require("@self/../Core/Animate")
local SignalModule = require("@self/../Core/Signal")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")
local TabModule = require("@self/Tab")
local Notify = require("@self/Notify")
local SettingsTab = require("@self/Settings")

type Theme = ThemeModule.Theme
type Tab = TabModule.Tab
type Connection = SignalModule.Connection

local HEADER = 44
local GRIP = 18
local DEFAULT_SIZE = Vector2.new(620, 460)
local MIN_SIZE = Vector2.new(380, 260)
local NOTIFY_WIDTH = 264
local MIN_SCALE = 0.5
local MAX_SCALE = 1.5

local Window = {}
Window.__index = Window

export type Window = {
	Name: string,
	Screen: ScreenGui,
	Root: Frame,
	Panel: Frame,
	Header: Frame,
	Sidebar: Frame,
	Body: Frame,
	Pages: Frame,
	Popups: Frame,
	Tabs: { Tab },
	Flags: { [string]: Element.Element },
	Theme: Theme,
	Keybind: Enum.KeyCode?,
	Selected: Tab?,
	TabSelected: SignalModule.Signal,
	CreateTab: (self: Window, name: string, icon: string?) -> Tab,
	SelectTab: (self: Window, target: Tab | string) -> (),
	Center: (self: Window) -> (),
	SetSize: (self: Window, size: Vector2) -> (),
	SetScale: (self: Window, scale: number) -> (),
	GetScale: (self: Window) -> number,
	SetKeybind: (self: Window, key: Enum.KeyCode | string | nil) -> (),
	OnClose: (self: Window, handler: () -> ()) -> (),
	GetFlags: (self: Window) -> { [string]: any },
	CreateSettingsTab: (self: Window) -> Tab,
	_findTab: (self: Window, name: string) -> Tab?,
	_drag: (self: Window, handle: GuiObject) -> (),
	_resize: (self: Window, handle: GuiObject) -> (),
	SetTheme: (self: Window, theme: string | Theme) -> (),
	OnTheme: (self: Window, handler: (Theme) -> ()) -> (),
	Notify: (self: Window, config: any, kind: any) -> any,
	SetVisible: (self: Window, visible: boolean) -> (),
	Toggle: (self: Window) -> (),
	Minimize: (self: Window) -> (),
	Maximize: (self: Window) -> (),
	GetFlag: (self: Window, name: string) -> any,
	SetFlag: (self: Window, name: string, value: any) -> (),
	SaveConfig: (self: Window, name: string) -> string?,
	LoadConfig: (self: Window, name: string) -> boolean,
	Destroy: (self: Window) -> (),
	_apply: (self: Window, theme: Theme) -> (),
	_paintChrome: (self: Window, button: TextButton, hovered: boolean, danger: boolean) -> (),
	_entries: ScrollingFrame,
	_panelCorner: UICorner,
	_scale: UIScale,
	_panelStroke: UIStroke,
	_blur: any,
	_notifyHost: Frame,
	_notifyList: { any },
	_title: TextLabel,
	_hint: TextLabel,
	_close: TextButton,
	_minimize: TextButton,
	_traffic: Frame,
	_caption: Frame,
	_dots: { TextButton },
	_chromeCorners: { UICorner },
	_restore: UDim2?,
	_minimized: boolean,
	_hidden: boolean,
	_expanded: UDim2?,
	_destroyed: boolean,
	_closeHandlers: { () -> () },
	_gloss: Frame?,
	_handlers: { (Theme) -> () },
	_input: SignalModule.Connection,
}

--- A post effect some executors refuse to let a script create. A missing blur
--- is a cosmetic loss, not a reason to refuse to load.
local function makeBlur(size: number): any
	local ok, blur =
		pcall(New, "BlurEffect", { Name = "LoomBlur", Size = size }, nil, game:GetService("Lighting"))
	return if ok then blur else nil
end

--- True for the two input kinds that count as a press.
local function isPointer(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch
end

--- True for the two input kinds that count as that press moving.
local function isPointerMove(input: InputObject): boolean
	local kind = input.UserInputType
	return kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch
end

--- One glyph button in the right-hand caption group. Its corner is applied by
--- the caller so a theme change can round it with the rest of the controls.
local function chromeButton(
	parent: Instance,
	theme: Theme,
	glyph: string,
	name: string,
	x: number
): TextButton
	return New("TextButton", {
		Name = name,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, x, 0.5, 0),
		Size = UDim2.fromOffset(26, 26),
		BackgroundColor3 = theme.SurfaceHover,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = theme.Font,
		TextSize = theme.FontSize,
		Text = glyph,
		TextColor3 = theme.TextDim,
	}, nil, parent)
end

function Window.new(config: any): Window
	local options = config or {}
	local theme = ThemeModule.get(options.Theme)
	local size = options.Size or DEFAULT_SIZE

	-- Phones and small windows: shrink the default so it fits on screen rather
	-- than hanging off the edge. An explicit Size is always honoured.
	local camera = workspace.CurrentCamera
	if options.Size == nil and camera then
		local viewport = camera.ViewportSize
		size = Vector2.new(
			math.clamp(size.X, MIN_SIZE.X, math.max(MIN_SIZE.X, viewport.X - 24)),
			math.clamp(size.Y, MIN_SIZE.Y, math.max(MIN_SIZE.Y, viewport.Y - 24))
		)
	end

	local self = (
		setmetatable({
			Name = options.Name or "Loom",
			Theme = theme,
			Tabs = {},
			Flags = {},
			TabSelected = SignalModule.new(),
			_notifyList = {},
			_handlers = {},
			_minimized = false,
			_hidden = false,
			_destroyed = false,
			_closeHandlers = {},
		}, Window) :: any
	) :: Window

	local keybind = options.Keybind
	if keybind == nil then
		keybind = Enum.KeyCode.RightControl
	elseif type(keybind) == "string" then
		keybind = (Enum.KeyCode :: any)[keybind]
	end
	self.Keybind = keybind

	local screen = New("ScreenGui", {
		Name = "Loom",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	})
	self.Screen = screen

	-- Mounted last, and only where the client actually accepts it: a requested
	-- parent, then the executor's hidden container, then CoreGui, then PlayerGui.
	if Env.Mount(screen, options.Parent) == nil then
		error("[Loom] nowhere to parent the window on this executor", 2)
	end
	Env.Protect(screen)

	local root = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, screen)
	self.Root = root

	-- Everything is laid out in unscaled pixels; one UIScale zooms the lot, which
	-- is why the drag and resize gestures below divide their deltas by it.
	self._scale = New("UIScale", { Scale = 1 }, nil, root)

	local panel = New("Frame", {
		Name = "Panel",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Window,
		BackgroundTransparency = theme.WindowTransparency,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 1,
	}, nil, root)
	self.Panel = panel
	self._panelCorner = Ui.corner(panel, UDim.new(0, theme.Corner))
	self._panelStroke = Ui.stroke(panel, theme)
	Ui.shadow(panel, theme, 26)

	local header = New("Frame", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HEADER),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, panel)
	self.Header = header

	local title = Ui.text(theme, header, {
		Name = "Title",
		Text = self.Name,
		Font = theme.BoldFont,
		TextSize = theme.TitleFontSize,
		Position = UDim2.fromOffset(theme.Pad, 0),
		Size = UDim2.new(1, -180, 1, 0),
	})
	self._title = title

	local caption = New("Frame", {
		Name = "Caption",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -theme.Pad, 0.5, 0),
		Size = UDim2.fromOffset(58, 26),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, header)
	self._caption = caption

	local minimize = chromeButton(caption, theme, "—", "Minimize", 0)
	self._minimize = minimize

	local close = chromeButton(caption, theme, "✕", "Close", 32)
	self._close = close
	self._chromeCorners = {
		Ui.corner(minimize, Ui.control(theme)),
		Ui.corner(close, Ui.control(theme)),
	}

	-- Both chrome idioms exist at once and one is shown, because the theme picks
	-- between them and a theme can change while the window is on screen.
	local traffic = New("Frame", {
		Name = "Traffic",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, theme.Pad, 0.5, 0),
		Size = UDim2.fromOffset(44, 12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, header)
	self._traffic = traffic

	local dots: { TextButton } = {}
	for index, glyph in { "✕", "—", "+" } do
		local dot = New("TextButton", {
			Name = if index == 1 then "Close" elseif index == 2 then "Minimize" else "Zoom",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, (index - 1) * 16, 0.5, 0),
			Size = UDim2.fromOffset(12, 12),
			BackgroundColor3 = theme.DotClose,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Font = theme.BoldFont,
			TextSize = 9,
			Text = glyph,
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextTransparency = 1,
		}, nil, traffic)
		Ui.corner(dot, UDim.new(1, 0))
		table.insert(dots, dot)
	end
	self._dots = dots

	-- Apple shows the glyph only while the pointer is over the group.
	Ui.hover(traffic, function(hovered: boolean)
		for _, dot in dots do
			Animate.play(dot, { TextTransparency = if hovered then 0.25 else 1 }, 0.1)
		end
	end)

	local hint = Ui.textDim(theme, header, {
		Name = "Hint",
		Text = if self.Keybind then self.Keybind.Name else "",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -(theme.Pad + 62), 0.5, 0),
		Size = UDim2.fromOffset(70, 16),
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	self._hint = hint

	Ui.hover(minimize, function(hovered: boolean)
		self:_paintChrome(minimize, hovered, false)
	end)

	Ui.hover(close, function(hovered: boolean)
		self:_paintChrome(close, hovered, true)
	end)

	minimize.Activated:Connect(function()
		self:Minimize()
	end)

	close.Activated:Connect(function()
		self:SetVisible(false)
	end)

	dots[1].Activated:Connect(function()
		self:SetVisible(false)
	end)

	dots[2].Activated:Connect(function()
		self:Minimize()
	end)

	dots[3].Activated:Connect(function()
		self:Maximize()
	end)

	local sidebar = New("Frame", {
		Name = "Sidebar",
		Position = UDim2.fromOffset(0, HEADER),
		Size = UDim2.new(0, theme.SidebarWidth, 1, -HEADER),
		BackgroundColor3 = theme.Sidebar,
		BackgroundTransparency = theme.SidebarTransparency,
		BorderSizePixel = 0,
	}, nil, panel)
	self.Sidebar = sidebar

	local entries = New("ScrollingFrame", {
		Name = "Entries",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 3,
	}, nil, sidebar)
	Ui.scrollbar(entries, theme)
	Ui.pad(entries, theme.Gap, 0, theme.Gap, theme.Gap)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		Padding = UDim.new(0, 4),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, entries)
	self._entries = entries

	local body = New("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(theme.SidebarWidth, HEADER),
		Size = UDim2.new(1, -theme.SidebarWidth, 1, -HEADER),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, panel)
	self.Body = body

	local pages = New("Frame", {
		Name = "Pages",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, body)
	Ui.pad(pages, theme.Gap)
	self.Pages = pages

	local notifyHost = New("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -theme.Pad, 1, -theme.Pad),
		Size = UDim2.new(0, NOTIFY_WIDTH, 1, -(HEADER + theme.Pad * 2)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 60,
	}, nil, panel)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Vertical,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, theme.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, nil, notifyHost)
	self._notifyHost = notifyHost

	local grip = New("TextButton", {
		Name = "Grip",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(GRIP, GRIP),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = theme.Font,
		TextSize = 12,
		Text = "◢",
		TextColor3 = theme.TextFaint,
		TextTransparency = 0.5,
		ZIndex = 70,
	}, nil, panel)
	Ui.hover(grip, function(hovered: boolean)
		Animate.play(grip, { TextTransparency = if hovered then 0.1 else 0.5 }, theme.Duration)
	end)
	self:_resize(grip)

	Ui.hover(header, function(hovered: boolean)
		Animate.play(grip, { TextTransparency = if hovered then 0.35 else 0.5 }, theme.Duration)
	end)
	self:_drag(header)

	local popups = New("Frame", {
		Name = "Popups",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 200,
	}, nil, root)
	self.Popups = popups
	self._input = Input.Began:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or Input.typing() or not self.Keybind then
			return
		end
		if input.KeyCode == self.Keybind then
			self:Toggle()
		end
	end)

	self:_apply(theme)
	return self
end

function Window._paintChrome(self: Window, button: TextButton, hovered: boolean, danger: boolean)
	local theme = self.Theme
	Animate.play(button, {
		BackgroundTransparency = if hovered then 0.15 + theme.SurfaceHoverTransparency * 0.85 else 1,
		TextColor3 = if hovered and danger then theme.Danger elseif hovered then theme.Text else theme.TextDim,
	}, theme.Duration * 0.7, theme.Easing)
	button.BackgroundColor3 = if danger then theme.Danger else theme.SurfaceHover
end

--- Drags the window by `handle`. The cursor delta arrives in screen pixels
--- while the root moves in its own unscaled offset space, so the delta is
--- divided by the UI scale -- without that a zoomed window outruns the cursor.
function Window._drag(self: Window, handle: GuiObject)
	handle.InputBegan:Connect(function(input: InputObject)
		if not isPointer(input) then
			return
		end

		local start = input.Position
		local origin = self.Root.Position

		local moveConnection: Connection
		local endConnection: Connection

		moveConnection = Input.Changed:Connect(function(move: InputObject)
			if not isPointerMove(move) then
				return
			end
			local delta = (move.Position - start) / math.max(self._scale.Scale, 0.01)
			self.Root.Position = UDim2.new(
				origin.X.Scale,
				origin.X.Offset + delta.X,
				origin.Y.Scale,
				origin.Y.Offset + delta.Y
			)
		end)

		endConnection = Input.Ended:Connect(function(release: InputObject)
			if release.UserInputType == input.UserInputType then
				moveConnection:Disconnect()
				endConnection:Disconnect()
			end
		end)
	end)
end

--- Resizes the window from `handle`, floored at MIN_SIZE and scaled the same
--- way _drag is so the grip stays under the pointer at any zoom.
function Window._resize(self: Window, handle: GuiObject)
	handle.InputBegan:Connect(function(input: InputObject)
		if not isPointer(input) then
			return
		end

		local start = input.Position
		local origin = self.Root.Size

		local moveConnection: Connection
		local endConnection: Connection

		moveConnection = Input.Changed:Connect(function(move: InputObject)
			if not isPointerMove(move) then
				return
			end
			local delta = (move.Position - start) / math.max(self._scale.Scale, 0.01)
			self.Root.Size = UDim2.fromOffset(
				math.max(MIN_SIZE.X, origin.X.Offset + delta.X),
				math.max(MIN_SIZE.Y, origin.Y.Offset + delta.Y)
			)
		end)

		endConnection = Input.Ended:Connect(function(release: InputObject)
			if release.UserInputType == input.UserInputType then
				moveConnection:Disconnect()
				endConnection:Disconnect()
			end
		end)
	end)
end

--- The first tab carrying `name`, or nil.
function Window._findTab(self: Window, name: string): Tab?
	for _, tab in self.Tabs do
		if tab.Name == name then
			return tab
		end
	end
	return nil
end

function Window.CreateTab(self: Window, name: string, icon: string?): Tab
	local host: TabModule.Host = self :: any
	local tab = TabModule.new(host, { Name = name, Icon = icon })
	table.insert(self.Tabs, tab)

	if #self.Tabs == 1 then
		self:SelectTab(tab)
	end

	return tab
end

--- Brings a tab to the front, by reference or by its name.
function Window.SelectTab(self: Window, target: Tab | string)
	local found: Tab? = if type(target) == "string" then self:_findTab(target :: string) else target :: Tab
	if found == nil then
		return
	end

	local tab = found :: Tab
	if self.Selected == tab then
		return
	end

	local previous = self.Selected
	self.Selected = tab

	if previous then
		previous:_deactivate()
	end
	tab:_activate()

	self.TabSelected:Fire(tab)
end

function Window.SetTheme(self: Window, theme: string | Theme)
	local next = if type(theme) == "string" then ThemeModule.get(theme :: string) else theme :: Theme
	self:_apply(next)
end

--- Runs a handler whenever the theme changes, for anything the window itself
--- does not own.
function Window.OnTheme(self: Window, handler: (Theme) -> ())
	table.insert(self._handlers, handler)
end

function Window._apply(self: Window, theme: Theme)
	self.Theme = theme

	self.Panel.BackgroundColor3 = theme.Window
	self.Panel.BackgroundTransparency = theme.WindowTransparency
	self._panelCorner.CornerRadius = UDim.new(0, theme.Corner)
	self._panelStroke.Color = theme.Stroke
	self._panelStroke.Thickness = theme.StrokeWidth
	self._panelStroke.Transparency = theme.StrokeTransparency

	self._title.Font = theme.BoldFont
	self._title.TextSize = theme.TitleFontSize
	self._title.TextColor3 = theme.Text
	self._title.TextXAlignment = theme.TitleAlign

	-- A centred title is centred in the window, so its box gives up the chrome
	-- on both sides; a left-aligned one only has to clear the left edge.
	if theme.TitleAlign == Enum.TextXAlignment.Center then
		self._title.Position = UDim2.fromOffset(56, 0)
		self._title.Size = UDim2.new(1, -112, 1, 0)
	else
		self._title.Position = UDim2.fromOffset(theme.Pad, 0)
		self._title.Size = UDim2.new(1, -180, 1, 0)
	end

	self._caption.Position = UDim2.new(1, -theme.Pad, 0.5, 0)
	self._traffic.Position = UDim2.new(0, theme.Pad, 0.5, 0)

	local traffic = theme.Chrome == "traffic"
	self._traffic.Visible = traffic
	self._caption.Visible = not traffic
	self._minimize.Visible = theme.Chrome == "caption"

	local dots = self._dots
	dots[1].BackgroundColor3 = theme.DotClose
	dots[2].BackgroundColor3 = theme.DotMinimize
	dots[3].BackgroundColor3 = theme.DotZoom

	for _, corner in self._chromeCorners do
		corner.CornerRadius = Ui.control(theme)
	end

	local hintOffset = theme.Pad + 68
	if theme.Chrome == "traffic" then
		hintOffset = theme.Pad + 8
	elseif theme.Chrome == "close" then
		hintOffset = theme.Pad + 32
	end
	self._hint.Position = UDim2.new(1, -hintOffset, 0.5, 0)
	self._hint.Font = theme.Font
	self._hint.TextSize = theme.SmallFontSize
	self._hint.TextColor3 = theme.TextFaint

	self.Sidebar.BackgroundColor3 = theme.Sidebar
	self.Sidebar.BackgroundTransparency = theme.SidebarTransparency
	self.Sidebar.Size = UDim2.new(0, theme.SidebarWidth, 1, -HEADER)
	self.Body.Position = UDim2.fromOffset(theme.SidebarWidth, HEADER)
	self.Body.Size = UDim2.new(1, -theme.SidebarWidth, 1, -HEADER)

	if theme.Gloss > 0 then
		self._gloss = self._gloss or Ui.gloss(self.Header, theme)
	elseif self._gloss then
		self._gloss:Destroy()
		self._gloss = nil
	end
	if theme.Blur > 0 then
		if self._blur == nil then
			self._blur = makeBlur(theme.Blur)
		else
			self._blur.Size = theme.Blur
		end
	elseif self._blur then
		self._blur:Destroy()
		self._blur = nil
	end

	for _, tab in self.Tabs do
		tab:ApplyTheme(theme)
	end

	for _, notification in self._notifyList do
		notification:ApplyTheme(theme)
	end

	for _, handler in self._handlers do
		handler(theme)
	end
end

function Window.Notify(self: Window, config: any, kind: any): any
	local options = if type(config) == "string" then { Content = config, Kind = kind } else (config or {})

	local notification = Notify.new(self._notifyHost, self.Theme, options, function(closed: any)
		local index = table.find(self._notifyList, closed)
		if index then
			table.remove(self._notifyList, index)
		end
	end)
	table.insert(self._notifyList, notification)
	return notification
end

function Window.SetVisible(self: Window, visible: boolean)
	if self._hidden == not visible then
		return
	end
	self._hidden = not visible

	self.Root.Visible = visible
	if visible then
		Animate.play(self.Root, { GroupTransparency = 0 }, self.Theme.Duration, self.Theme.Easing)
	end
end

function Window.Toggle(self: Window)
	self:SetVisible(self._hidden)
end

function Window.Minimize(self: Window)
	local theme = self.Theme

	if self._minimized then
		self._minimized = false
		self.Sidebar.Visible = true
		self.Body.Visible = true
		Animate.play(self.Root, { Size = self._expanded :: UDim2 }, theme.Duration, theme.Easing)
		return
	end

	self._minimized = true
	local width = self.Root.Size
	self._expanded = width

	Animate.play(
		self.Root,
		{ Size = UDim2.new(width.X.Scale, width.X.Offset, 0, HEADER) },
		theme.Duration,
		theme.Easing,
		function()
			self.Sidebar.Visible = false
			self.Body.Visible = false
		end
	)
end

--- Fills the viewport, or goes back to the size the window had before. macOS
--- puts this on its green dot; every style can call it.
function Window.Maximize(self: Window)
	if self._restore then
		Animate.play(self.Root, { Size = self._restore :: UDim2 }, self.Theme.Duration, self.Theme.Easing)
		self._restore = nil
		return
	end

	local camera = workspace.CurrentCamera
	if camera == nil then
		return
	end

	local viewport = camera.ViewportSize
	self._restore = self.Root.Size
	Animate.play(self.Root, {
		Size = UDim2.fromOffset(math.max(MIN_SIZE.X, viewport.X - 24), math.max(MIN_SIZE.Y, viewport.Y - 24)),
	}, self.Theme.Duration, self.Theme.Easing)
end

--- Zooms the whole window. Every size in the library stays in plain pixels, so
--- the scale is one UIScale on the root rather than a second set of numbers.
function Window.SetScale(self: Window, scale: number)
	self._scale.Scale = math.clamp(scale, MIN_SCALE, MAX_SCALE)
end

function Window.GetScale(self: Window): number
	return self._scale.Scale
end

--- Puts the window back in the middle of the screen after it has been dragged.
function Window.Center(self: Window)
	self.Root.Position = UDim2.fromScale(0.5, 0.5)
end

--- Resizes the window, floored at the same minimum the constructor uses.
function Window.SetSize(self: Window, size: Vector2)
	Animate.play(
		self.Root,
		{ Size = UDim2.fromOffset(math.max(MIN_SIZE.X, size.X), math.max(MIN_SIZE.Y, size.Y)) },
		self.Theme.Duration,
		self.Theme.Easing
	)
end

--- Rebinds the show/hide shortcut. Pass a key, a key name, or nil to disable
--- it; a name that is not a real key leaves the shortcut as it was.
function Window.SetKeybind(self: Window, key: Enum.KeyCode | string | nil)
	if key == nil or (key :: any) == false then
		self.Keybind = nil
	elseif type(key) == "string" then
		local resolved: Enum.KeyCode? = (Enum.KeyCode :: any)[key]
		if resolved == nil then
			return
		end
		self.Keybind = resolved
	else
		self.Keybind = key :: Enum.KeyCode
	end

	self._hint.Text = if self.Keybind then self.Keybind.Name else ""
end

--- Runs once when the window is torn down, before anything is destroyed: the
--- place to stop timers a script started alongside the window.
function Window.OnClose(self: Window, handler: () -> ())
	table.insert(self._closeHandlers, handler)
end

--- Every flag and its current value, for scripts that want the whole state.
function Window.GetFlags(self: Window): { [string]: any }
	local values: { [string]: any } = {}
	for name, element in self.Flags do
		values[name] = element:GetValue()
	end
	return values
end

--- The built-in appearance tab: every style, live, with the token overrides a
--- user would otherwise have to patch in by hand.
function Window.CreateSettingsTab(self: Window): Tab
	return SettingsTab.new(self)
end

function Window.GetFlag(self: Window, name: string): any
	local element = self.Flags[name]
	return if element then element:GetValue() else nil
end

function Window.SetFlag(self: Window, name: string, value: any)
	local element = self.Flags[name]
	if element then
		element:SetValue(value)
	end
end

function Window.SaveConfig(self: Window, name: string): string?
	return Config.save(self, name)
end

function Window.LoadConfig(self: Window, name: string): boolean
	return Config.load(self, name)
end

--- Tears the window down once. A second call is a no-op, so re-injecting a
--- script whose previous window is already gone cannot fail here.
function Window.Destroy(self: Window)
	if self._destroyed then
		return
	end
	self._destroyed = true

	-- Drop the registration, or the next CreateWindow tries to destroy this one.
	local shared = Env.shared()
	if shared.Loom == (self :: any) then
		shared.Loom = nil
	end

	self._input:Disconnect()
	self.TabSelected:DisconnectAll()

	for _, handler in self._closeHandlers do
		handler()
	end
	self._closeHandlers = {}

	-- Close toasts before the screen goes, so their timers do not fire into a
	-- frame that no longer exists.
	for _, notification in table.clone(self._notifyList) do
		notification:Close()
	end
	self._notifyList = {}

	for _, tab in self.Tabs do
		tab:Destroy()
	end
	self.Tabs = {}

	if self._blur then
		self._blur:Destroy()
		self._blur = nil
	end

	self.Screen:Destroy()
end

return Window
