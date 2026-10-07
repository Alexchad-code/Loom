--!strict
-- Linoria dialect. LinoriaLib's call surface over a Loom window, so a script
-- written against it keeps its calls and still gets Loom's styles, icons and
-- config system:
--
--   local Linoria = Loom.Api.Linoria
--   local Window = Linoria:CreateWindow({ Title = "My Script" })
--   local Tabs = { Main = Window:AddTab("Main") }
--   Tabs.Main:AddLeftGroupbox("Movement"):AddToggle("sprint", { Text = "Sprint" })
--
-- Linoria's groupboxes are a two-column layout and a Loom page is one column, so
-- a groupbox is a caption above the rows that follow it. The handle it returns is
-- the tab carrying Linoria's method names, which keeps every box on a page
-- working in creation order.
--
-- The addons that ship beside LinoriaLib -- ThemeManager, SaveManager and
-- InterfaceManager -- are out of scope: a Loom window already has a style picker
-- and a config system, reached with Window:SetTheme and Window:SaveConfig.

local Support = require("@self/Support")

local Linoria = {}
Linoria.__index = Linoria

export type Linoria = {
	Name: string,
	Loom: any,
	Window: any?,
	Options: { [string]: any },
	Toggles: { [string]: any },
	CreateWindow: (self: Linoria, config: any?) -> any,
	Notify: (self: Linoria, message: any, duration: any?) -> any,
	Unload: (self: Linoria) -> (),
}

local Window = {}
Window.__index = Window

export type Window = {
	Library: Linoria,
	Element: any,
	Name: string,
	Tabs: { [string]: any },
	AddTab: (self: Window, name: string, icon: any?) -> any,
	SelectTab: (self: Window, target: any) -> (),
	Notify: (self: Window, message: any, duration: any?) -> any,
	Toggle: (self: Window) -> (),
	Destroy: (self: Window) -> (),
}

--- Linoria keeps its palette in ThemeManager rather than the library; these are
--- the names that addon ships, onto the Loom style that reads closest.
local THEMES: { [string]: string } = {
	Dark = "Nice",
	Darker = "Windows Dark",
	Light = "Clean",
	Aqua = "Glass",
	Amethyst = "Catppuccin",
	Rose = "Goofy",
	Serenity = "Nord",
}

--- The names inside a multi-selection, which these libraries write either as a
--- list of names or as a name -> true map.
local function names(value: any): { string }
	local picked: { string } = {}
	for key, entry in value do
		if type(key) == "number" then
			table.insert(picked, tostring(entry))
		elseif entry then
			table.insert(picked, tostring(key))
		end
	end
	return picked
end

--- A dropdown Default is an index into Values, a name, or a list of names; Loom
--- wants the names themselves.
local function chosen(listing: Support.Options, value: any): any
	if type(value) == "number" then
		return listing.Names[value]
	end
	if type(value) == "table" then
		return names(value)
	end
	return value
end

--- Linoria chains a sub-button off the one above it; a Loom page is a flat list,
--- so `:AddButton` adds another row directly below instead of nesting.
local function button(self: any, config: any): any
	local options = config or {}
	local callback = options.Func or options.Callback

	-- A double-click button fires on the second press, so the first one arms it.
	local armed = false
	local handler = if options.DoubleClick == true
		then function()
			armed = not armed
			if not armed and callback then
				callback()
			end
		end
		else callback

	local row = self:Button({ Text = options.Text, Callback = handler })
	return Support.augment(row, {
		AddButton = function(_current: any, next: any): any
			return button(self, next)
		end,
	})
end

--- Linoria's groupbox vocabulary, dropped onto the tab itself so the rows are
--- real Loom rows created in order after the caption a box added.
local GROUP: { [string]: any } = {}

--- Linoria's checkbox is a toggle drawn as a tick and Loom has one switch shape,
--- so a checkbox is the same row under its other name.
function GROUP.AddCheckbox(self: any, flag: string, config: any): any
	return self:AddToggle(flag, config)
end

function GROUP.AddToggle(self: any, flag: string, config: any): any
	local options = config or {}
	local row = self:Toggle({
		Text = options.Text,
		Flag = flag,
		Default = options.Default,
		Callback = options.Callback,
	})

	Support.remember(self.Library.Toggles, row)
	return Support.remember(self.Library.Options, row)
end

function GROUP.AddButton(self: any, config: any): any
	return button(self, config)
end

--- The first argument is either the text, or the index when a table follows.
--- Linoria's DoesWrap has no equivalent: a Loom label always wraps.
function GROUP.AddLabel(self: any, text: any, wrap: any, index: any): any
	local options = if type(wrap) == "table" then wrap else nil
	local source = if type(wrap) == "string" then wrap else index
	local flag: string? = if type(source) == "string" then source else nil
	if options then
		flag = tostring(text)
	end

	local row = self:Label({ Text = if options then options.Text else tostring(text) })
	row.Flag = flag
	Support.remember(self.Library.Options, row)

	return Support.augment(row, {
		SetText = function(current: any, value: any)
			current:Set(tostring(value))
		end,
	})
end

function GROUP.AddDivider(self: any): any
	return self:Divider()
end

function GROUP.AddSlider(self: any, flag: string, config: any): any
	local options = config or {}
	local row = self:Slider({
		Text = options.Text,
		Flag = flag,
		Min = options.Min,
		Max = options.Max,
		Default = options.Default,
		Rounding = options.Rounding,
		Suffix = options.Suffix,
		Callback = options.Callback,
	})

	return Support.remember(self.Library.Options, row)
end

--- Linoria's `Finished` narrows a callback to the enter key; a Loom textbox
--- commits on focus loss, which Return already counts as, so it is accepted and
--- dropped.
function GROUP.AddInput(self: any, flag: string, config: any): any
	local options = config or {}
	local row = self:Textbox({
		Text = options.Text,
		Flag = flag,
		Default = options.Default,
		Placeholder = options.Placeholder,
		Numeric = options.Numeric,
		ClearOnFocus = options.ClearTextOnFocus == true,
		Callback = options.Callback,
	})

	return Support.remember(self.Library.Options, row)
end

function GROUP.AddDropdown(self: any, flag: string, config: any): any
	local options = config or {}
	local listing = Support.options(options.Values)

	local row = self:Dropdown({
		Text = options.Text,
		Flag = flag,
		Options = listing.Names,
		Multi = options.Multi == true,
		Search = options.Searchable == true,
		Default = chosen(listing, options.Default),
		Callback = options.Callback,
	})

	return Support.remember(self.Library.Options, row)
end

--- Linoria's key picker answers with a table of key and mode; a Loom bind reads
--- the KeyCode alone, so Value is that enum and the mode is accepted and
--- dropped. `:SetValue` still takes the key name its users write.
function GROUP.AddKeyPicker(self: any, flag: string, config: any): any
	local options = config or {}
	local row = self:Keybind({
		Text = options.Text,
		Flag = flag,
		Default = options.Default,
		Callback = options.Callback,
	})

	local raw = row.SetValue
	Support.remember(self.Library.Options, row)

	return Support.augment(row, {
		SetValue = function(current: any, key: any)
			raw(current, Support.key(key))
		end,
	})
end

--- Captions the rows that follow. A groupbox's own icon has nowhere to go: Loom
--- section headers are text and a rule.
local function groupbox(self: any, name: string): any
	self:Section({ Text = name })
	return Support.augment(self, GROUP)
end

--- Linoria's Tab vocabulary, dropped onto the Loom tab along with the groupbox
--- one so a script that skips the box still finds its Add* names.
local TAB: { [string]: any } = {}

function TAB.AddLeftGroupbox(self: any, name: string, _icon: any?): any
	return groupbox(self, name)
end

function TAB.AddRightGroupbox(self: any, name: string, _icon: any?): any
	return groupbox(self, name)
end

function Window.AddTab(self: Window, name: string, icon: any?): any
	local tab = Support.augment(self.Element:CreateTab(name, Support.icon(icon)), TAB)
	Support.augment(tab, GROUP)
	tab.Library = self.Library

	self.Tabs[name] = tab
	return tab
end

function Window.SelectTab(self: Window, target: any)
	self.Element:SelectTab(target)
end

function Window.Notify(self: Window, message: any, duration: any?): any
	return self.Library:Notify(message, duration)
end

function Window.Toggle(self: Window)
	self.Element:Toggle()
end

function Window.Destroy(self: Window)
	self.Element:Destroy()
end

--- Wraps a live Loom window in Linoria's vocabulary.
local function window(library: Linoria, element: any): Window
	local self: Window = (setmetatable({ Library = library, Element = element }, Window) :: any) :: Window
	self.Name = element.Name
	self.Tabs = {}
	return self
end

function Linoria.new(loom: any): Linoria
	local self: Linoria = (
		setmetatable({ Name = "Linoria", Loom = loom, Options = {}, Toggles = {} }, Linoria) :: any
	) :: Linoria
	return self
end

--- Linoria's window flags -- Center, AutoShow, Resizable -- are how a Loom
--- window behaves anyway, so they are accepted and dropped.
function Linoria.CreateWindow(self: Linoria, config: any?): any
	local options = config or {}
	local element = self.Loom:CreateWindow({
		Name = options.Title or options.Name or "Linoria",
		Theme = Support.style(THEMES, options.Theme),
		Size = options.Size,
		Keybind = options.Keybind,
	})

	self.Window = window(self, element)
	return self.Window
end

--- Linoria's notification is a message plus an optional duration; a table with
--- Title and Content works here as well.
function Linoria.Notify(self: Linoria, message: any, duration: any?): any
	local options = message
	if type(message) ~= "table" then
		options = { Content = message, Duration = duration }
	end

	local target = if self.Window then self.Window.Element else nil
	if target == nil then
		return nil
	end

	return target:Notify({
		Title = options.Title,
		Content = options.Content,
		Duration = Support.duration(options.Duration, 4),
		Kind = Support.kind(options.Kind or options.Type),
	})
end

function Linoria.Unload(self: Linoria)
	if self.Window then
		self.Window:Destroy()
	end
end

return Linoria
