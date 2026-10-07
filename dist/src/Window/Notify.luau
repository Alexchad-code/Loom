--!strict
-- Toast notifications. They stack upward from the bottom-right of the window and
-- are sized by their own text, so a one-line notice and a paragraph both look
-- deliberate.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Animate = require("@self/../Core/Animate")
local ThemeModule = require("@self/../Core/Theme")

type Theme = ThemeModule.Theme

export type Kind = "info" | "success" | "warning" | "danger"

export type Config = {
	Title: string?,
	Content: string?,
	Duration: number?,
	Kind: Kind?,
}

local WIDTH = 252
local BAR = 2

local function accentFor(theme: Theme, kind: Kind): Color3
	if kind == "success" then
		return theme.Success
	end
	if kind == "warning" then
		return theme.Warning
	end
	if kind == "danger" then
		return theme.Danger
	end
	return theme.Accent
end

--- GroupTransparency fades a whole subtree in one property, but it is a newer
--- addition and reading it on a client without it throws. Without it there is
--- no cheap way to fade everything, so notifications appear rather than fade.
local canFade = (function(): boolean
	local probe = Instance.new("Frame")
	local ok, value = pcall(function()
		return (probe :: any).GroupTransparency
	end)
	probe:Destroy()
	return ok and value ~= nil
end)()

local Notification = {}
Notification.__index = Notification

export type Notification = {
	Frame: Frame,
	Theme: Theme,
	Kind: Kind,
	Duration: number,
	ApplyTheme: (self: Notification, theme: Theme) -> (),
	Close: (self: Notification) -> (),
	_closed: boolean,
	_dot: Frame,
	_stroke: UIStroke,
	_title: TextLabel,
	_content: TextLabel,
	_close: TextButton,
	_progress: Frame,
	_onClose: ((Notification) -> ())?,
}

function Notification.new(container: Instance, theme: Theme, config: Config?): Notification
	local options: Config = config or {}
	local kind: Kind = options.Kind or "info"
	local duration = options.Duration or 4

	local self = (
		setmetatable({
			Theme = theme,
			Kind = kind,
			Duration = duration,
			_closed = false,
		}, Notification) :: any
	) :: Notification

	local props: { [string]: any } = {
		Name = "Notification",
		Size = UDim2.new(0, WIDTH, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.Popup,
		BackgroundTransparency = theme.PopupTransparency,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}
	if canFade then
		props.GroupTransparency = 1
	end

	local frame = New("Frame", props, nil, container)
	Ui.corner(frame, UDim.new(0, theme.Corner))
	self._stroke = Ui.stroke(frame, theme, accentFor(theme, kind), 0.72)
	Ui.pad(frame, 12, 12, 12, 12)
	Ui.list(frame, theme).Padding = UDim.new(0, 4)
	self.Frame = frame

	local head = New("Frame", {
		Name = "Head",
		Size = UDim2.new(1, 0, 0, 17),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, frame)

	local dot = Ui.pill(head, theme, accentFor(theme, kind))
	dot.Name = "Dot"
	dot.AnchorPoint = Vector2.new(0, 0.5)
	dot.Position = UDim2.new(0, 0, 0.5, 0)
	dot.Size = UDim2.fromOffset(7, 7)
	self._dot = dot

	local title = Ui.text(theme, head, {
		Name = "Title",
		Text = options.Title or string.upper(string.sub(kind, 1, 1)) .. string.sub(kind, 2),
		Font = theme.BoldFont,
		Size = UDim2.new(1, -26, 1, 0),
		Position = UDim2.fromOffset(14, 0),
	})
	self._title = title

	local close = New("TextButton", {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.fromOffset(17, 17),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = theme.Font,
		TextSize = 13,
		Text = "✕",
		TextColor3 = theme.TextFaint,
	}, nil, head)
	self._close = close

	local content = Ui.textDim(theme, frame, {
		Name = "Content",
		Text = options.Content or "",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		TextWrapped = true,
		TextTruncate = Enum.TextTruncate.None,
	})
	self._content = content

	local progress = New("Frame", {
		Name = "Progress",
		Size = UDim2.new(1, 0, 0, BAR),
		BackgroundColor3 = accentFor(theme, kind),
		BorderSizePixel = 0,
	}, nil, frame)
	Ui.corner(progress, UDim.new(1, 0))
	self._progress = progress

	close.Activated:Connect(function()
		self:Close()
	end)

	Ui.hover(close, function(hovered: boolean)
		Animate.play(close, { TextColor3 = if hovered then self.Theme.Text else self.Theme.TextFaint }, 0.12)
	end)

	if canFade then
		Animate.play(frame, { GroupTransparency = 0 }, theme.Duration, theme.Easing)
	end
	Animate.play(progress, { Size = UDim2.new(0, 0, 0, BAR) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		self:Close()
	end)

	return self
end

function Notification.ApplyTheme(self: Notification, theme: Theme)
	if self._closed then
		return
	end

	self.Theme = theme
	local accent = accentFor(theme, self.Kind)

	self.Frame.BackgroundColor3 = theme.Popup
	self.Frame.BackgroundTransparency = theme.PopupTransparency
	self._dot.BackgroundColor3 = accent
	self._stroke.Color = accent
	self._title.Font = theme.BoldFont
	self._title.TextSize = theme.FontSize
	self._title.TextColor3 = theme.Text
	self._content.Font = theme.Font
	self._content.TextSize = theme.SmallFontSize
	self._content.TextColor3 = theme.TextFaint
	self._close.Font = theme.Font
	self._progress.BackgroundColor3 = accent
end

function Notification.Close(self: Notification)
	if self._closed then
		return
	end
	self._closed = true

	if self._onClose then
		self._onClose(self)
	end

	-- A toast whose window is already gone has nothing left to fade into.
	if not canFade or self.Frame.Parent == nil then
		self.Frame:Destroy()
		return
	end

	Animate.play(self.Frame, { GroupTransparency = 1 }, self.Theme.Duration, self.Theme.Easing, function()
		self.Frame:Destroy()
	end)
end

local Notify = {}

--- Shows a notification in `container`. `onClose` fires when it is gone so the
--- window can drop it from the list it retheme from.
function Notify.new(
	container: Instance,
	theme: Theme,
	config: Config?,
	onClose: ((Notification) -> ())?
): Notification
	local notification = Notification.new(container, theme, config)
	notification._onClose = onClose
	return notification
end

return Notify
