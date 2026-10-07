--!strict
-- WindUI dialect. Footagesus' WindUI vocabulary over a Loom window: tabs,
-- sections, groups and the element set, with WindUI's millisecond toasts.

local Support = require("@self/Support")

--- What a page is built from: a tab of its own, a section inside one, or a
--- group of rows. Only a tab carries a Loom element up front.
export type Spec = {
	Title: string,
	Icon: string?,
	Element: any?,
}

local Page = {}
Page.__index = Page

export type Page = {
	Library: any,
	Host: any,
	Element: any?,
	Title: string,
	Icon: string?,
	Target: (self: Page) -> any,
	Tab: (self: Page, config: any) -> Page,
	Section: (self: Page, config: any) -> Page,
	Group: (self: Page, config: any?) -> Page,
	Space: (self: Page, config: any?) -> (),
	Divider: (self: Page) -> (),
	Button: (self: Page, config: any) -> any,
	Toggle: (self: Page, config: any) -> any,
	Slider: (self: Page, config: any) -> any,
	Dropdown: (self: Page, config: any) -> any,
	Input: (self: Page, config: any) -> any,
	Keybind: (self: Page, config: any) -> any,
	Colorpicker: (self: Page, config: any) -> any,
	Paragraph: (self: Page, config: any) -> any,
}

local Window = {}
Window.__index = Window

export type Window = {
	Library: any,
	Element: any,
	Name: string,
	Tabs: { [string]: Page },
	Sections: { [string]: Page },
	Tab: (self: Window, config: any) -> Page,
	Section: (self: Window, config: any) -> Page,
	SelectTab: (self: Window, index: number) -> (),
	Destroy: (self: Window) -> (),
}

local WindUI = {}
WindUI.__index = WindUI

export type WindUI = {
	Name: string,
	Version: string,
	Loom: any,
	Options: { [string]: any },
	Window: Window?,
	Page: Page?,
	CreateWindow: (self: WindUI, config: any?) -> Window,
	Notify: (self: WindUI, config: any) -> any,
	Popup: (self: WindUI, config: any) -> (),
}

--- WindUI's theme names, onto the Loom style that reads closest. A name Loom
--- does not know falls through and lands on the default style.
local THEMES: { [string]: string } = {
	Dark = "Nice",
	Darker = "Windows Dark",
	Light = "Clean",
	Rose = "Goofy",
	Aqua = "Glass",
	Amethyst = "Catppuccin",
}

--- WindUI names an icon "solar:home-bold", and Loom draws Lucide names, so a
--- namespaced name gets no icon rather than a stray glyph where the art should be.
local function icon(value: any): string?
	if type(value) == "string" and string.find(value, ":", 1, true) then
		return nil
	end
	return Support.icon(value)
end

function Page.new(library: WindUI, host: Window, spec: Spec): Page
	return (
		setmetatable({
			Library = library,
			Host = host,
			Element = spec.Element,
			Title = spec.Title,
			Icon = spec.Icon,
		}, Page) :: any
	) :: Page
end

--- The Loom tab these rows go into. A window-level section holds none until
--- something lands in it, which is what keeps an unused section from claiming a
--- sidebar slot of its own.
function Page.Target(self: Page): any
	if self.Element == nil then
		self.Element = self.Host.Element:CreateTab(self.Title, icon(self.Icon))
		self.Host.Tabs[self.Title] = self
	end
	return self.Element
end

--- WindUI nests tabs inside a section of the sidebar. Loom's sidebar is flat, so
--- a nested tab is simply another tab beside its parent.
function Page.Tab(self: Page, config: any): Page
	return self.Host:Tab(config)
end

--- WindUI boxes a section and can collapse it; Loom's section is a caption over a
--- rule that is always open, so `Box`, `BoxBorder` and `Opened` are accepted and
--- dropped.
function Page.Section(self: Page, config: any): Page
	local options = config or {}
	self:Target():Section({ Text = options.Title })

	return Page.new(self.Library, self.Host, {
		Title = options.Title or self.Title,
		Element = self:Target(),
	})
end

--- WindUI draws a box around a group. Loom has no box, so a group is only the
--- rows that follow it, in creation order.
function Page.Group(self: Page, _config: any?): Page
	return Page.new(self.Library, self.Host, {
		Title = self.Title,
		Element = self:Target(),
	})
end

--- WindUI's Space is a gap and its Divider a line; Loom has one spacer row that
--- serves both, so the column count goes nowhere.
function Page.Space(self: Page, _config: any?)
	self:Target():Divider()
end

function Page.Divider(self: Page)
	self:Target():Divider()
end

--- WindUI tints, locks and icons a button; Loom's action row is one style, so
--- `Color`, `Justify`, `Icon`, `Locked` and `LockedTitle` are dropped. There is
--- no flash either, so `:Highlight()` hovers the row and lets it ease back.
function Page.Button(self: Page, config: any): any
	local options = config or {}
	local row = self:Target():Button({ Text = options.Title, Callback = options.Callback })

	return Support.augment(row, {
		Highlight = function(current: any)
			current:_paint(true)
			task.delay(0.25, function()
				current:_paint(false)
			end)
		end,
	})
end

--- A checkbox is WindUI's other face for a switch, which is what Loom's toggle is.
function Page.Toggle(self: Page, config: any): any
	local options = config or {}
	local row = self:Target():Toggle({
		Text = options.Title,
		Description = options.Desc,
		Flag = options.Flag,
		Default = options.Value,
		Callback = options.Callback,
	})
	return Support.remember(self.Library.Options, row)
end

--- WindUI nests the numbers inside `Value` and calls the increment `Step`.
function Page.Slider(self: Page, config: any): any
	local options = config or {}
	local range = options.Value or {}

	local row = self:Target():Slider({
		Text = options.Title,
		Description = options.Desc,
		Flag = options.Flag,
		Min = range.Min or 0,
		Max = range.Max or 100,
		Default = range.Default,
		Rounding = Support.precision(options.Step),
		Callback = options.Callback,
	})
	return Support.remember(self.Library.Options, row)
end

--- WindUI's default is a 1-based index into `Values`; Loom selects by name, and
--- a value it cannot match is what `AllowNone` amounts to here.
function Page.Dropdown(self: Page, config: any): any
	local options = config or {}
	local listing = Support.options(options.Values)
	local default = if type(options.Value) == "number" then listing.Names[options.Value] else options.Value

	local row = self:Target():Dropdown({
		Text = options.Title,
		Description = options.Desc,
		Flag = options.Flag,
		Options = listing.Names,
		Multi = options.Multi == true,
		Search = options.SearchBar == true,
		Default = default,
		Callback = options.Callback,
	})
	return Support.remember(self.Library.Options, row)
end

--- A WindUI textarea is still one Loom textbox: the text box is single line here,
--- so `Type = "Textarea"` is accepted and dropped.
function Page.Input(self: Page, config: any): any
	local options = config or {}
	local row = self:Target():Textbox({
		Text = options.Title,
		Description = options.Desc,
		Flag = options.Flag,
		Default = options.Value,
		Placeholder = options.Placeholder,
		Callback = options.Callback,
	})
	return Support.remember(self.Library.Options, row)
end

function Page.Keybind(self: Page, config: any): any
	local options = config or {}
	local value = if type(options.Value) == "table" then options.Value.Key else options.Value

	local row = self:Target():Keybind({
		Text = options.Title,
		Description = options.Desc,
		Flag = options.Flag,
		Default = Support.key(value),
		Callback = options.Callback,
	})
	return Support.remember(self.Library.Options, row)
end

function Page.Colorpicker(self: Page, config: any): any
	local options = config or {}
	local row = self:Target():ColorPicker({
		Text = options.Title,
		Description = options.Desc,
		Flag = options.Flag,
		Default = Support.color(options.Default or options.Value),
		Alpha = options.Transparency ~= nil,
		Callback = options.Callback,
	})
	return Support.remember(self.Library.Options, row)
end

--- Loom's paragraph is prose only, so a paragraph's own buttons become ordinary
--- button rows underneath it.
function Page.Paragraph(self: Page, config: any): any
	local options = config or {}
	local row = self:Target():Paragraph({ Title = options.Title, Text = options.Desc })

	for _, button in options.Buttons or {} do
		self:Button({ Title = button.Title, Callback = button.Callback })
	end

	return row
end

function Window.Tab(self: Window, config: any): Page
	local options = config or {}
	local title = options.Title or "Tab"
	local page = Page.new(self.Library, self, {
		Title = title,
		Icon = options.Icon,
		Element = self.Element:CreateTab(title, icon(options.Icon)),
	})

	self.Tabs[page.Title] = page
	self.Library.Page = page
	return page
end

function Window.Section(self: Window, config: any): Page
	local options = config or {}
	local page = Page.new(self.Library, self, { Title = options.Title or "Section" })

	self.Sections[page.Title] = page
	self.Library.Page = page
	return page
end

--- WindUI counts tabs from zero.
function Window.SelectTab(self: Window, index: number)
	local tab = self.Element.Tabs[index + 1]
	if tab then
		self.Element:SelectTab(tab)
	end
end

function Window.Destroy(self: Window)
	self.Element:Destroy()
end

--- Wraps a live Loom window in WindUI's vocabulary.
local function window(library: WindUI, element: any): Window
	local self: Window = (setmetatable({ Library = library, Element = element }, Window) :: any) :: Window
	self.Name = element.Name
	self.Tabs = {}
	self.Sections = {}
	return self
end

function WindUI.new(loom: any): WindUI
	return (
		setmetatable({
			Name = "WindUI",
			Version = loom.Version,
			Loom = loom,
			Options = {},
		}, WindUI) :: any
	) :: WindUI
end

--- WindUI's `OpenButton`, `Topbar`, `HideSearchBar`, `NewElements`, `Author` and
--- `Icon` are all chrome Loom draws its own way, so they are accepted and dropped.
function WindUI.CreateWindow(self: WindUI, config: any?): Window
	local options = config or {}
	local size = options.Size

	local element = self.Loom:CreateWindow({
		Name = options.Title or "WindUI",
		Theme = Support.style(THEMES, options.Theme),
		Size = if typeof(size) == "UDim2" then Vector2.new(size.X.Offset, size.Y.Offset) else size,
	})

	local target = window(self, element)
	self.Window = target
	return target
end

--- WindUI sizes a toast in milliseconds and lets it be pinned open; Loom's toasts
--- are always dismissable and expect seconds.
function WindUI.Notify(self: WindUI, config: any): any
	local options = config or {}
	local target = if self.Window then (self.Window :: Window).Element else nil
	if target == nil then
		return nil
	end

	return target:Notify({
		Title = options.Title,
		Content = options.Content,
		Duration = Support.duration(options.Duration, 4),
		Kind = Support.kind(options.Type or options.Kind),
	})
end

--- Loom has no modal, so a popup lands as a toast and its buttons become rows on
--- the last page, which is where their callbacks can actually be reached.
function WindUI.Popup(self: WindUI, config: any)
	local options = config or {}
	self:Notify({ Title = options.Title, Content = options.Content })

	local page = self.Page
	if page == nil then
		return
	end

	for _, button in options.Buttons or {} do
		page:Button({ Title = button.Title, Callback = button.Callback })
	end
end

return WindUI
