--!strict
-- Rayfield dialect. Rayfield's own call surface over a Loom window, so a script
-- written against it keeps its calls and still gets Loom's styles, icons and
-- config system:
--
--   local Rayfield = Loom.Api.Rayfield
--   local Window = Rayfield:CreateWindow({ Name = "My Script", Theme = "Glass" })
--   local Main = Window:CreateTab("Main", "home")
--   Main:CreateToggle({ Name = "Enabled", Flag = "enabled", CurrentValue = true,
--       Callback = function(value) end })
--
-- The rows that come back are Loom's own elements, so `:Set`, `:Get` and `Value`
-- are the real ones rather than a second copy that could drift out of step.

local Support = require("@self/Support")

local Rayfield = {}
Rayfield.__index = Rayfield

export type Rayfield = {
	Name: string,
	Loom: any,
	Window: any?,
	Flags: { [string]: any },
	Folder: string?,
	CreateWindow: (self: Rayfield, config: any?) -> any,
	Notify: (self: Rayfield, config: any) -> any,
	LoadConfiguration: (self: Rayfield) -> boolean,
	SaveConfiguration: (self: Rayfield) -> boolean,
	Destroy: (self: Rayfield) -> (),
}

local Window = {}
Window.__index = Window

export type Window = {
	Library: Rayfield,
	Element: any,
	Name: string,
	Tabs: { [string]: any },
	CreateTab: (self: Window, name: string, icon: any?) -> any,
	SelectTab: (self: Window, name: string) -> (),
	Notify: (self: Window, config: any) -> any,
	SetVisible: (self: Window, visible: boolean) -> (),
	Toggle: (self: Window) -> (),
	Destroy: (self: Window) -> (),
}

--- Rayfield's theme names, onto the Loom style that reads closest.
local THEMES: { [string]: string } = {
	Default = "Nice",
	DarkBlue = "Nice",
	Green = "Poly",
	Light = "Clean",
	Aqua = "Glass",
	Amethyst = "Catppuccin",
	Blood = "Dracula",
	Serika = "Tokyo Night",
	Purple = "Discord",
	Pink = "Goofy",
}

--- Rayfield's Tab:Create* vocabulary, dropped onto the Loom tab itself.
local TAB: { [string]: any } = {}

function TAB.CreateSection(self: any, name: any): any
	return self:Section({ Text = if type(name) == "table" then name.Name else name })
end

function TAB.CreateButton(self: any, config: any): any
	local options = config or {}
	return self:Button({ Text = options.Name, Callback = options.Callback })
end

function TAB.CreateToggle(self: any, config: any): any
	local options = config or {}
	return self:Toggle({
		Text = options.Name,
		Description = options.Description,
		Flag = options.Flag,
		Default = options.CurrentValue,
		Callback = options.Callback,
	})
end

function TAB.CreateSlider(self: any, config: any): any
	local options = config or {}
	local range = options.Range or {}
	return self:Slider({
		Text = options.Name,
		Description = options.Description,
		Flag = options.Flag,
		Min = range[1] or 0,
		Max = range[2] or 100,
		Rounding = Support.precision(options.Increment),
		Suffix = options.Suffix,
		Default = options.CurrentValue,
		Callback = options.Callback,
	})
end

function TAB.CreateDropdown(self: any, config: any): any
	local options = config or {}
	local listing = Support.options(options.Options)

	local row = self:Dropdown({
		Text = options.Name,
		Description = options.Description,
		Flag = options.Flag,
		Options = listing.Names,
		Multi = options.MultipleOptions == true,
		Search = options.Search == true,
		Default = options.CurrentOption,
		Callback = options.Callback,
	})

	-- Rayfield swaps a dropdown's contents at runtime; Loom calls that SetOptions.
	return Support.augment(row, {
		Refresh = function(current: any, values: any)
			current:SetOptions(Support.options(values).Names)
		end,
	})
end

function TAB.CreateInput(self: any, config: any): any
	local options = config or {}
	return self:Textbox({
		Text = options.Name,
		Description = options.Description,
		Flag = options.Flag,
		Default = options.CurrentValue,
		Placeholder = options.PlaceholderText,
		ClearOnFocus = options.RemoveTextAfterFocusLost == true,
		Callback = options.Callback,
	})
end

--- Rayfield reads and writes keybinds as key *names* alongside a hold/toggle
--- mode, which Loom has no use for: the mode only changes how a script reads the
--- key, so it is accepted and dropped.
function TAB.CreateKeybind(self: any, config: any): any
	local options = config or {}
	local row = self:Keybind({
		Text = options.Name,
		Description = options.Description,
		Flag = options.Flag,
		Default = options.CurrentKeybind,
		Callback = options.Callback,
	})

	local raw = row.Set
	return Support.augment(row, {
		Set = function(current: any, key: any, _mode: any)
			raw(current, Support.key(key))
		end,
		Get = function(current: any): (string, string)
			local held = current.Value
			return if held then held.Name else "None", options.CurrentHoldToggle or "Hold"
		end,
	})
end

function TAB.CreateColorPicker(self: any, config: any): any
	local options = config or {}
	return self:ColorPicker({
		Text = options.Name,
		Description = options.Description,
		Flag = options.Flag,
		Default = Support.color(options.Color),
		Callback = options.Callback,
	})
end

--- Rayfield passes a label's text positionally, though a table works too.
function TAB.CreateLabel(self: any, text: any): any
	return self:Label({ Text = if type(text) == "table" then text.Text else tostring(text) })
end

function TAB.CreateParagraph(self: any, config: any): any
	local options = config or {}
	return self:Paragraph({ Title = options.Title, Text = options.Content })
end

function Window.CreateTab(self: Window, name: string, icon: any?): any
	local tab = self.Element:CreateTab(name, Support.icon(icon))
	self.Tabs[name] = tab
	return Support.augment(tab, TAB)
end

function Window.SelectTab(self: Window, name: string)
	self.Element:SelectTab(name)
end

function Window.Notify(self: Window, config: any): any
	return self.Library:Notify(config)
end

function Window.SetVisible(self: Window, visible: boolean)
	self.Element:SetVisible(visible)
end

function Window.Toggle(self: Window)
	self.Element:Toggle()
end

function Window.Destroy(self: Window)
	self.Element:Destroy()
end

--- Wraps a live Loom window in Rayfield's vocabulary.
local function window(library: Rayfield, element: any): Window
	local self: Window = (setmetatable({ Library = library, Element = element }, Window) :: any) :: Window
	self.Name = element.Name
	self.Tabs = {}
	return self
end

function Rayfield.new(loom: any): Rayfield
	return (setmetatable({ Name = "Rayfield", Loom = loom, Flags = {} }, Rayfield) :: any) :: Rayfield
end

function Rayfield.CreateWindow(self: Rayfield, config: any?): any
	local options = config or {}
	local saving = options.ConfigurationSaving

	local element = self.Loom:CreateWindow({
		Name = options.Name or "Rayfield",
		Theme = Support.style(THEMES, options.Theme),
		Size = options.Size,
		Keybind = options.Keybind,
	})

	self.Window = window(self, element)
	self.Flags = element.Flags
	self.Folder = if type(saving) == "table" then saving.FolderName else nil
	return self.Window
end

--- Rayfield's toasts expect seconds, and drop through Image ids Loom has no
--- use for: it draws its own icons.
function Rayfield.Notify(self: Rayfield, config: any): any
	local options = config or {}
	local target = if self.Window then (self.Window :: any).Element else nil
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

function Rayfield.LoadConfiguration(self: Rayfield): boolean
	local target = if self.Window then (self.Window :: any).Element else nil
	return if target then target:LoadConfig(self.Folder or "Rayfield") else false
end

function Rayfield.SaveConfiguration(self: Rayfield): boolean
	local target = if self.Window then (self.Window :: any).Element else nil
	return if target then target:SaveConfig(self.Folder or "Rayfield") ~= nil else false
end

function Rayfield.Destroy(self: Rayfield)
	if self.Window then
		self.Window:Destroy()
	end
end

return Rayfield
