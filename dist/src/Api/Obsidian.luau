--!strict
-- Obsidian dialect. Obsidian is a Linoria fork, so this is Linoria's shape --
-- Library, Tabs, Groupboxes, and a live Options/Toggles index -- over a Loom
-- window:
--
--   local Obsidian = Loom.Api.Obsidian
--   local Window = Obsidian:CreateWindow({ Title = "My Script", Center = true })
--   local Tabs = { Main = Window:AddTab("Main", "home") }
--   local Box = Tabs.Main:AddLeftGroupbox("Movement")
--   Box:AddToggle("fly", { Text = "Fly", Default = false, Callback = print })
--
-- The rows that come back are Loom's own elements, so `Value`, `:SetValue` and
-- `:OnChanged` are the real ones rather than a second copy that could drift. The
-- ThemeManager and SaveManager addons are not reimplemented: Loom's own styles
-- and Window:SaveConfig cover what they did.

local Support = require("@self/Support")

type Options = Support.Options

local Obsidian = {}
Obsidian.__index = Obsidian

export type Obsidian = {
	Name: string,
	Loom: any,
	Options: { [string]: any },
	Toggles: { [string]: any },
	Window: Window?,
	CreateWindow: (self: Obsidian, config: any?) -> any,
	Notify: (self: Obsidian, content: any, duration: any?) -> any,
	Destroy: (self: Obsidian) -> (),
}

local Window = {}
Window.__index = Window

export type Window = {
	Library: Obsidian,
	Element: any,
	Tabs: { [string]: any },
	AddTab: (self: Window, name: string, icon: any?) -> any,
	AddKeyTab: (self: Window, name: string) -> any,
	SelectTab: (self: Window, name: string) -> (),
	Destroy: (self: Window) -> (),
}

--- Obsidian's group vocabulary. Every group, tabbox and tab answers to it, so
--- the handle a script keeps is the Loom tab itself and two groupboxes on one
--- tab simply stack in the order they were built, each under its own caption.
local GROUP: { [string]: any } = {}

--- Tooltip, Disabled, Risky and DoesWrap are presentation Loom has no
--- equivalent for; Visible is the one this dialect asks for that Loom owns.
local function visible(row: any, options: any)
	if options.Visible == false then
		row:SetVisible(false)
	end
end

--- A groupbox is a caption over the rows that follow it, because Loom's page is
--- a single column: `Side` and `IconName` are accepted and dropped.
function GROUP.AddGroupbox(self: any, config: any): any
	local options = config or {}
	self:Section({ Text = options.Name })
	return self
end

function GROUP.AddLeftGroupbox(self: any, name: any): any
	return self:AddGroupbox({ Name = name })
end

function GROUP.AddRightGroupbox(self: any, name: any): any
	return self:AddGroupbox({ Name = name })
end

--- Obsidian nests a tabbox inside a groupbox; its inner tabs are captions too,
--- which is why the tabbox handle answers the group vocabulary as well.
function GROUP.AddLeftTabbox(self: any): any
	return self
end

function GROUP.AddTab(self: any, name: any): any
	self:Section({ Text = name })
	return self
end

--- A toggle's index comes first and its options second, and Obsidian files the
--- row in both indexes itself so a script can reach it either way.
function GROUP.AddToggle(self: any, index: any, config: any): any
	local options = config or {}
	local row = self:Toggle({
		Text = options.Text,
		Flag = index,
		Default = options.Default,
		Callback = options.Callback,
	})

	visible(row, options)
	Support.remember(self.Library.Toggles, row)
	return Support.remember(self.Library.Options, row)
end

--- A checkbox is a toggle with a different body, so it builds the same row:
--- Loom carries one switch and it answers to both names.
function GROUP.AddCheckbox(self: any, index: any, config: any): any
	return self:AddToggle(index, config)
end

--- Obsidian spell a button's callback Func and let a button grow sub-buttons
--- under itself; DoubleClick is the one behaviour the row cannot express, since
--- a Loom button acts on the first press.
function GROUP.AddButton(self: any, config: any): any
	local options = config or {}
	local row = self:Button({ Text = options.Text, Callback = options.Func or options.Callback })

	visible(row, options)
	return Support.augment(row, {
		AddButton = function(_row: any, sub: any): any
			return GROUP.AddButton(self, sub)
		end,
	})
end

--- Obsidian take a label's text first, or its index followed by a table. A label
--- row has no flag of its own in Loom, so an index is set on the row and filed
--- in the window by hand -- that is what makes `Options.Name:SetText` reach it.
--- The row also needs its own SetText: it draws the text itself rather than
--- through the shared element title.
function GROUP.AddLabel(self: any, first: any, second: any, third: any): any
	local indexed = type(second) == "table"
	local options = if indexed then second else {}
	local flag = if indexed then first else third
	local row = self:Label({ Text = if indexed then options.Text else first })

	if flag ~= nil then
		row.Flag = flag
		self.Host.Flags[flag] = row
	end

	local raw = row.Set
	return Support.remember(
		self.Library.Options,
		Support.augment(row, {
			SetText = function(current: any, text: string)
				raw(current, text)
			end,
		})
	)
end

function GROUP.AddDivider(self: any): any
	return self:Divider()
end

function GROUP.AddSlider(self: any, index: any, config: any): any
	local options = config or {}
	local row = self:Slider({
		Text = options.Text,
		Flag = index,
		Min = options.Min,
		Max = options.Max,
		Default = options.Default,
		Rounding = options.Rounding,
		Suffix = options.Suffix,
		Callback = options.Callback,
	})

	visible(row, options)
	return Support.remember(self.Library.Options, row)
end

function GROUP.AddInput(self: any, index: any, config: any): any
	local options = config or {}
	local row = self:Textbox({
		Text = options.Text,
		Flag = index,
		Default = options.Default,
		Placeholder = options.Placeholder,
		Numeric = options.Numeric,
		ClearOnFocus = options.ClearTextOnFocus,
		Callback = options.Callback,
	})

	-- MaxLength and Finished only change when the value is committed.
	visible(row, options)
	return Support.remember(self.Library.Options, row)
end

--- A dropdown selects by value, and a dictionary's value is its key: Loom
--- selects by display name, so the default is looked up the other way round.
local function selected(listing: Options, fallback: any): any
	if type(fallback) ~= "string" then
		return fallback
	end
	for name, value in listing.Values do
		if value == fallback then
			return name
		end
	end
	return fallback
end

function GROUP.AddDropdown(self: any, index: any, config: any): any
	local options = config or {}
	local listing = Support.options(options.Values)
	local fallback = options.Default
	if type(fallback) == "number" then
		fallback = listing.Names[fallback]
	end

	local row = self:Dropdown({
		Text = options.Text,
		Flag = index,
		Options = listing.Names,
		Multi = options.Multi == true,
		Search = options.Searchable == true,
		Default = selected(listing, fallback),
		Callback = options.Callback,
	})

	-- DisabledValues, MaxVisibleDropdownItems and FormatDisplayValue only shape
	-- the popup, which Loom lays out itself.
	visible(row, options)
	return Support.remember(self.Library.Options, row)
end

--- A key picker carries a hold/toggle mode and can mirror a toggle's state;
--- Loom's keybind owns the key alone, so the mode and SyncToggleState are
--- accepted and dropped. SetValue still takes the key name Obsidian writes.
function GROUP.AddKeyPicker(self: any, index: any, config: any): any
	local options = config or {}
	local row = self:Keybind({
		Text = options.Text,
		Flag = index,
		Default = options.Default,
		Callback = options.Callback,
	})

	local raw = row.Set
	return Support.remember(
		self.Library.Options,
		Support.augment(row, {
			SetValue = function(current: any, key: any)
				raw(current, Support.key(key))
			end,
		})
	)
end

function Window.AddTab(self: Window, name: string, icon: any?): any
	local tab = self.Element:CreateTab(name, Support.icon(icon))
	tab.Library = self.Library
	self.Tabs[name] = tab
	return Support.augment(tab, GROUP)
end

--- A key tab is where a hub puts its key box. Loom has no key system, so this is
--- an ordinary tab wearing the key icon.
function Window.AddKeyTab(self: Window, name: string): any
	return self:AddTab(name, "key")
end

function Window.SelectTab(self: Window, name: string)
	self.Element:SelectTab(name)
end

function Window.Destroy(self: Window)
	self.Element:Destroy()
end

--- Wraps a live Loom window in Obsidian's vocabulary.
local function window(library: Obsidian, element: any): Window
	local self: Window = (setmetatable({ Library = library, Element = element }, Window) :: any) :: Window
	self.Tabs = {}
	return self
end

function Obsidian.new(loom: any): Obsidian
	return (
		setmetatable({
			Name = "Obsidian",
			Loom = loom,
			Options = {},
			Toggles = {},
		}, Obsidian) :: any
	) :: Obsidian
end

--- NotifySide, ShowCustomCursor, AlwaysOnTop, AutoShow, Center and Resizable are
--- things Loom already decides -- toasts stack bottom-right, the window is
--- centred and shown -- so they are accepted and left alone. Icon is an asset
--- id, which maps to no Loom icon.
function Obsidian.CreateWindow(self: Obsidian, config: any?): any
	local options = config or {}
	local element = self.Loom:CreateWindow({
		Name = options.Title or "Obsidian",
		Size = options.Size,
	})

	self.Window = window(self, element)
	return self.Window
end

--- Obsidian notifies through the library rather than the window, and reads a
--- bare string as the content.
function Obsidian.Notify(self: Obsidian, content: any, duration: any?): any
	local target = self.Window
	if target == nil then
		return nil
	end

	local options = if type(content) == "table" then content else { Content = content, Duration = duration }
	return target.Element:Notify({
		Title = options.Title,
		Content = options.Content,
		Duration = Support.duration(options.Duration, 4),
		Kind = Support.kind(options.Kind),
	})
end

function Obsidian.Destroy(self: Obsidian)
	local target = self.Window
	if target then
		target:Destroy()
	end
end

return Obsidian
