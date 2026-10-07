--!strict
-- A page. Owns its sidebar entry, the card its elements live in, and the list
-- of elements so a theme change or a config load can drive all of them.

local New = require("@self/../Core/New")
local Ui = require("@self/../Core/Ui")
local Animate = require("@self/../Core/Animate")
local Element = require("@self/../Core/Element")
local ThemeModule = require("@self/../Core/Theme")

local Button = require("@self/../Elements/Button")
local Toggle = require("@self/../Elements/Toggle")
local Slider = require("@self/../Elements/Slider")
local Dropdown = require("@self/../Elements/Dropdown")
local Textbox = require("@self/../Elements/Textbox")
local Keybind = require("@self/../Elements/Keybind")
local ColorPicker = require("@self/../Elements/ColorPicker")
local Section = require("@self/../Elements/Section")
local Divider = require("@self/../Elements/Divider")
local Label = require("@self/../Elements/Label")
local Paragraph = require("@self/../Elements/Paragraph")

type Theme = ThemeModule.Theme

local ENTRY_HEIGHT = 32

local Tab = {}
Tab.__index = Tab

export type Host = {
	Theme: Theme,
	Pages: Frame,
	Sidebar: Frame,
	Popups: Frame,
	Flags: { [string]: Element.Element },
	SelectTab: (self: Host, tab: Tab) -> (),
}

export type Tab = {
	Name: string,
	Icon: string?,
	Host: Host,
	Theme: Theme,
	Page: Frame,
	Content: ScrollingFrame,
	Popups: Frame,
	Entry: TextButton,
	Elements: { Element.Element },
	OpenPopup: any,
	Selected: boolean,
	Select: (self: Tab) -> (),
	ApplyTheme: (self: Tab, theme: Theme) -> (),
	OnTheme: (self: Tab, handler: (Theme) -> ()) -> (),
	Destroy: (self: Tab) -> (),
	Button: (self: Tab, config: any) -> any,
	Toggle: (self: Tab, config: any) -> any,
	Slider: (self: Tab, config: any) -> any,
	Dropdown: (self: Tab, config: any) -> any,
	Textbox: (self: Tab, config: any) -> any,
	Keybind: (self: Tab, config: any) -> any,
	ColorPicker: (self: Tab, config: any) -> any,
	Section: (self: Tab, config: any) -> any,
	Divider: (self: Tab) -> any,
	Label: (self: Tab, config: any) -> any,
	Paragraph: (self: Tab, config: any) -> any,
	Clear: (self: Tab) -> (),
	GetFlag: (self: Tab, name: string) -> any,
	SetFlag: (self: Tab, name: string, value: any) -> (),
	_activate: (self: Tab) -> (),
	_deactivate: (self: Tab) -> (),
	_paintSelected: (self: Tab) -> (),
	_paintIndicator: (self: Tab, theme: Theme) -> (),
	_register: (self: Tab, element: Element.Element) -> (),
	_fillEntry: (self: Tab, color: Color3, transparency: number) -> (),
	_paintEntry: (self: Tab, hovered: boolean) -> (),
	_entryFill: Frame,
	_fillCorner: UICorner,
	_entryLabel: TextLabel,
	_entryIcon: GuiObject?,
	_indicator: Frame,
	_scroll: ScrollingFrame,
	_corner: UICorner,
	_pad: UIPadding,
	_themeHandlers: { (Theme) -> () },
}

function Tab.new(host: Host, config: any): Tab
	local options = config or {}
	local theme = host.Theme

	local self = (
		setmetatable({
			Name = options.Name or "Tab",
			Icon = options.Icon,
			Host = host,
			Theme = theme,
			Elements = {},
			OpenPopup = nil,
			Selected = false,
			_themeHandlers = {},
		}, Tab) :: any
	) :: Tab

	local entry = New("TextButton", {
		Name = self.Name,
		Size = UDim2.new(1, 0, 0, ENTRY_HEIGHT),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Text = "",
	}, nil, host.Sidebar)
	self.Entry = entry

	local fill = New("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, entry)
	self._fillCorner = Ui.corner(fill, Ui.control(theme))
	self._entryFill = fill

	local indicator = New("Frame", {
		Name = "Indicator",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(theme.Indicator, 0),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel = 0,
		Visible = false,
	}, nil, entry)
	Ui.corner(indicator, UDim.new(1, 0))
	self._indicator = indicator

	local hasIcon = options.Icon ~= nil and options.Icon ~= ""
	if hasIcon then
		local icon = Ui.icon(entry, theme, options.Icon, {
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 12, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			TextSize = 15,
		})
		self._entryIcon = icon
		Ui.tint(icon, theme.TextDim)
	end

	local label = Ui.text(theme, entry, {
		Name = "Label",
		Text = self.Name,
		Font = theme.MediumFont,
		Size = UDim2.new(1, if hasIcon then -40 else -20, 1, 0),
		Position = UDim2.fromOffset(if hasIcon then 36 else 12, 0),
		TextColor3 = theme.TextDim,
	})
	self._entryLabel = label

	Ui.hover(entry, function(hovered: boolean)
		self:_paintEntry(hovered)
	end)

	entry.Activated:Connect(function()
		host:SelectTab(self)
	end)

	local page = New("Frame", {
		Name = self.Name,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = theme.Surface,
		BackgroundTransparency = theme.SurfaceTransparency,
		BorderSizePixel = 0,
		Visible = false,
	}, nil, host.Pages)
	self.Page = page
	self._corner = Ui.corner(page, UDim.new(0, theme.Corner))
	Ui.stroke(page, theme)

	local inner = New("Frame", {
		Name = "Inner",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
	}, nil, page)
	self._pad = Ui.pad(inner, theme.Pad, theme.Gap)

	local scroll = New("ScrollingFrame", {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
	}, nil, inner)
	Ui.scrollbar(scroll, theme)
	Ui.pad(scroll, 0, 6, 0, 0)
	Ui.list(scroll, theme)
	self.Content = scroll
	self.Popups = host.Popups
	self._scroll = scroll

	return self
end

--- Fades the sidebar entry's highlight to `color` at `transparency`.
function Tab._fillEntry(self: Tab, color: Color3, transparency: number)
	self._entryFill.BackgroundColor3 = color
	self._entryFill.Visible = true
	Animate.play(
		self._entryFill,
		{ BackgroundTransparency = transparency },
		self.Theme.Duration,
		self.Theme.Easing
	)
end

--- Paints the selected entry. Styles with EntryAccent fill it with the accent
--- and invert the text, the way Finder and Material do; the rest keep the
--- neutral surface fill.
function Tab._paintSelected(self: Tab)
	local theme = self.Theme

	if theme.EntryAccent then
		self:_fillEntry(theme.Accent, 0)
		self._entryLabel.TextColor3 = theme.OnAccent
		if self._entryIcon then
			Ui.tint(self._entryIcon, theme.OnAccent)
		end
		return
	end

	self:_fillEntry(theme.Surface, theme.SurfaceTransparency)
	self._entryLabel.TextColor3 = theme.Text
	if self._entryIcon then
		Ui.tint(self._entryIcon, theme.Text)
	end
end

--- Sizes the accent bar for the active style: no bar at all below a width of
--- one, the full bar for the selected tab, otherwise collapsed.
function Tab._paintIndicator(self: Tab, theme: Theme)
	local active = self.Selected and theme.Indicator > 0
	self._indicator.Visible = active
	self._indicator.Size = UDim2.fromOffset(theme.Indicator, if active then 18 else 0)
end

--- The window calls this when this tab becomes the visible one.
function Tab._activate(self: Tab)
	self.Selected = true
	self.Page.Visible = true

	local theme = self.Theme
	self:_paintSelected()

	if theme.Indicator <= 0 then
		self._indicator.Visible = false
		return
	end

	self._indicator.Visible = true
	Animate.play(
		self._indicator,
		{ Size = UDim2.fromOffset(theme.Indicator, 18) },
		theme.Duration,
		theme.Easing
	)
end

function Tab._deactivate(self: Tab)
	self.Selected = false
	self.Page.Visible = false

	if self.OpenPopup then
		self.OpenPopup:Close()
	end

	local theme = self.Theme
	self:_fillEntry(theme.Surface, 1)
	self._entryLabel.TextColor3 = theme.TextDim
	if self._entryIcon then
		Ui.tint(self._entryIcon, theme.TextDim)
	end

	if theme.Indicator <= 0 then
		self._indicator.Visible = false
		return
	end

	Animate.play(
		self._indicator,
		{ Size = UDim2.fromOffset(theme.Indicator, 0) },
		theme.Duration,
		theme.Easing,
		function()
			if not self.Selected then
				self._indicator.Visible = false
			end
		end
	)
end

--- A selected entry keeps its highlight; the others only tint while hovered.
function Tab._paintEntry(self: Tab, hovered: boolean)
	if self.Selected then
		return
	end
	local theme = self.Theme
	self:_fillEntry(theme.SurfaceHover, if hovered then 0.25 + theme.SurfaceHoverTransparency * 0.75 else 1)
end

function Tab.Select(self: Tab)
	self.Host:SelectTab(self)
end

--- Elements register here so the window knows what to retheme, notify and save.
function Tab._register(self: Tab, element: Element.Element)
	table.insert(self.Elements, element)
	element:SetOrder(#self.Elements)

	if element.Flag then
		self.Host.Flags[element.Flag] = element
	end
end

--- Removes every element, leaving the tab and its entry in place so the page can
--- be rebuilt. A flag is only dropped when it still points at the element being
--- removed -- a later element may have claimed the same name. Popups belong to
--- their element, so they go with it and the reference is simply dropped.
function Tab.Clear(self: Tab)
	self.OpenPopup = nil

	for _, element in self.Elements do
		local flag = element.Flag
		if flag and self.Host.Flags[flag] == element then
			self.Host.Flags[flag] = nil
		end
		element:Destroy()
	end

	self.Elements = {}
end

--- Reads a flag by name, the way Window.GetFlag reads any flag in the window.
function Tab.GetFlag(self: Tab, name: string): any
	local element = self.Host.Flags[name]
	return if element then element:GetValue() else nil
end

function Tab.SetFlag(self: Tab, name: string, value: any)
	local element = self.Host.Flags[name]
	if element then
		element:SetValue(value)
	end
end

function Tab.OnTheme(self: Tab, handler: (Theme) -> ())
	table.insert(self._themeHandlers, handler)
end

function Tab.ApplyTheme(self: Tab, theme: Theme)
	self.Theme = theme

	self._corner.CornerRadius = UDim.new(0, theme.Corner)
	self._pad.PaddingTop = UDim.new(0, theme.Pad)
	self._pad.PaddingBottom = UDim.new(0, theme.Pad)
	self._pad.PaddingLeft = UDim.new(0, theme.Gap)
	self._pad.PaddingRight = UDim.new(0, theme.Gap)

	self.Page.BackgroundColor3 = theme.Surface
	self.Page.BackgroundTransparency = theme.SurfaceTransparency

	self._fillCorner.CornerRadius = Ui.control(theme)

	self._entryLabel.Font = theme.MediumFont
	self._entryLabel.TextSize = theme.FontSize
	self._entryLabel.Position = UDim2.fromOffset(if self._entryIcon then 36 else 12, 0)
	self._indicator.BackgroundColor3 = theme.Accent
	self:_paintIndicator(theme)

	if self.Selected then
		self:_paintSelected()
	else
		self._entryLabel.TextColor3 = theme.TextDim
		if self._entryIcon then
			Ui.tint(self._entryIcon, theme.TextDim)
		end
	end

	for _, element in self.Elements do
		element:ApplyTheme(theme)
	end

	for _, handler in self._themeHandlers do
		handler(theme)
	end
end

function Tab.Button(self: Tab, config: any): any
	return Button.new(self, config)
end

function Tab.Toggle(self: Tab, config: any): any
	return Toggle.new(self, config)
end

function Tab.Slider(self: Tab, config: any): any
	return Slider.new(self, config)
end

function Tab.Dropdown(self: Tab, config: any): any
	return Dropdown.new(self, config)
end

function Tab.Textbox(self: Tab, config: any): any
	return Textbox.new(self, config)
end

function Tab.Keybind(self: Tab, config: any): any
	return Keybind.new(self, config)
end

function Tab.ColorPicker(self: Tab, config: any): any
	return ColorPicker.new(self, config)
end

function Tab.Section(self: Tab, config: any): any
	return Section.new(self, config)
end

function Tab.Divider(self: Tab): any
	return Divider.new(self, {})
end

function Tab.Label(self: Tab, config: any): any
	return Label.new(self, config)
end

function Tab.Paragraph(self: Tab, config: any): any
	return Paragraph.new(self, config)
end

function Tab.Destroy(self: Tab)
	if self.OpenPopup then
		self.OpenPopup:Close()
	end
	for _, element in self.Elements do
		element:Destroy()
	end
	self.Elements = {}
	self.Entry:Destroy()
	self.Page:Destroy()
end

return Tab
