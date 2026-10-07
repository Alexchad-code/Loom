--!strict
-- Fluent dialect. dawid's Fluent call surface over a Loom window, so a script
-- written against it keeps its calls and still gets Loom's styles, icons and
-- config system:
--
--   local Fluent = Loom.Api.Fluent
--   local Window = Fluent:CreateWindow({ Title = "My Script", Theme = "Dark" })
--   local Main = Window:AddTab({ Title = "Main", Icon = "home" })
--   Main:AddToggle("enabled", { Title = "Enabled", Default = true,
--       Callback = function(value) end })
--   print(Fluent.Options.enabled.Value)
--
-- The rows that come back are Loom's own elements, extended only where Fluent
-- spells something differently, so `Value` cannot drift out of step with `Set`.

local Support = require("@self/Support")

local Fluent = {}
Fluent.__index = Fluent

export type Fluent = {
	Name: string,
	Loom: any,
	Window: any?,
	Options: { [string]: any },
	Held: { [Enum.KeyCode]: boolean },
	Unloaded: boolean,
	CreateWindow: (self: Fluent, config: any?) -> any,
	Notify: (self: Fluent, config: any) -> any,
	SetTheme: (self: Fluent, name: string) -> (),
	Destroy: (self: Fluent) -> (),
	_began: any,
	_ended: any,
}

local Window = {}
Window.__index = Window

export type Window = {
	Library: Fluent,
	Element: any,
	Name: string,
	Tabs: { [string]: any },
	Order: { any },
	AddTab: (self: Window, config: any?) -> any,
	SelectTab: (self: Window, target: any) -> (),
	Dialog: (self: Window, config: any) -> (),
	Toggle: (self: Window) -> (),
	SetVisible: (self: Window, visible: boolean) -> (),
	Destroy: (self: Window) -> (),
}

--- Fluent's theme names, onto the Loom style that reads closest.
local THEMES: { [string]: string } = {
	Dark = "Nice",
	Darker = "Windows Dark",
	Light = "Clean",
	Aqua = "Glass",
	Amethyst = "Catppuccin",
	Rose = "Goofy",
}

--- A multi dropdown's default is either a list of names or a name -> true map,
--- and Loom only takes the list.
local function names(value: any): any
	if type(value) ~= "table" or #value > 0 then
		return value
	end

	local list = {}
	for name, state in value do
		if state == true then
			table.insert(list, name)
		end
	end
	return list
end

--- Fluent's Tab:Add* vocabulary, closed over its library so the Options index
--- and the key-state table stay in reach.
local function tabMethods(library: Fluent): { [string]: any }
	local TAB: { [string]: any } = {}

	function TAB.AddSection(self: any, name: any): any
		return self:Section({ Text = name })
	end

	function TAB.AddParagraph(self: any, config: any): any
		local options = config or {}
		return self:Paragraph({ Title = options.Title, Text = options.Content })
	end

	-- Loom's button is a single-line row, so a Fluent Description has nowhere to
	-- sit and is the one option this dialect drops.
	function TAB.AddButton(self: any, config: any): any
		local options = config or {}
		return self:Button({ Text = options.Title, Callback = options.Callback })
	end

	function TAB.AddToggle(self: any, flag: string, config: any): any
		local options = config or {}
		return Support.remember(
			library.Options,
			self:Toggle({
				Text = options.Title,
				Description = options.Description,
				Flag = flag,
				Default = options.Default,
				Callback = options.Callback,
			})
		)
	end

	function TAB.AddSlider(self: any, flag: string, config: any): any
		local options = config or {}
		return Support.remember(
			library.Options,
			self:Slider({
				Text = options.Title,
				Description = options.Description,
				Flag = flag,
				Min = options.Min,
				Max = options.Max,
				Rounding = options.Rounding,
				Default = options.Default,
				Callback = options.Callback,
			})
		)
	end

	function TAB.AddDropdown(self: any, flag: string, config: any): any
		local options = config or {}
		local listing = Support.options(options.Values)
		local chosen = options.Default
		if type(chosen) == "number" then
			chosen = listing.Names[chosen]
		end

		local row = Support.remember(
			library.Options,
			self:Dropdown({
				Text = options.Title,
				Description = options.Description,
				Flag = flag,
				Options = listing.Names,
				Multi = options.Multi == true,
				Default = names(chosen),
				Callback = options.Callback,
			})
		)

		if options.Multi ~= true then
			return row
		end

		-- Fluent writes a multi selection as a name -> true map, and reads
		-- Options.Flag.Value back as one; Loom deals in a flat list of names.
		local raw = row.SetValue
		return Support.augment(row, {
			SetValue = function(current: any, value: any)
				raw(current, names(value))
			end,
		})
	end

	function TAB.AddColorpicker(self: any, flag: string, config: any): any
		local options = config or {}
		local row = Support.remember(
			library.Options,
			self:ColorPicker({
				Text = options.Title,
				Description = options.Description,
				Flag = flag,
				Default = Support.color(options.Default),
				Alpha = options.Transparency ~= nil,
				Callback = options.Callback,
			})
		)

		-- Fluent's opacity lives on the picker as Transparency; Loom spells it
		-- SetAlpha/GetAlpha, so only the write side is worth bridging.
		return Support.augment(row, {
			SetValueRGB = function(current: any, color: any)
				current:Set(Support.color(color))
			end,
		})
	end

	--- Fluent splits a keybind into a press callback and a changed one. Loom's
	--- keybind reports the change itself, so the press is watched for on Loom's
	--- own input signal, in whichever of Fluent's three modes was asked for.
	function TAB.AddKeybind(self: any, flag: string, config: any): any
		local options = config or {}
		local row = Support.remember(
			library.Options,
			self:Keybind({
				Text = options.Title,
				Description = options.Description,
				Flag = flag,
				Default = options.Default,
				Callback = options.ChangedCallback,
			})
		)

		local mode = options.Mode or "Toggle"
		local callback = options.Callback
		local state = false

		local began = library.Loom.Input.Began:Connect(function(input: InputObject)
			local bound = row.Value
			if callback == nil or bound == nil or input.KeyCode ~= bound then
				return
			end

			if mode == "Toggle" then
				state = not state
				callback(state)
			else
				callback(true)
			end
		end)

		local ended = library.Loom.Input.Ended:Connect(function(input: InputObject)
			if mode ~= "Hold" or callback == nil or row.Value == nil then
				return
			end
			if input.KeyCode == row.Value then
				callback(false)
			end
		end)

		local raw = row.Set
		local destroy = row.Destroy
		return Support.augment(row, {
			SetValue = function(current: any, key: any, _mode: any)
				raw(current, Support.key(key))
			end,
			GetState = function(current: any): boolean
				if mode == "Toggle" then
					return state
				end
				local bound = current.Value
				return bound ~= nil and library.Held[bound] == true
			end,
			Destroy = function(current: any)
				began:Disconnect()
				ended:Disconnect()
				destroy(current)
			end,
		})
	end

	-- Loom's textbox already commits on Return as well as on focus loss, which
	-- is exactly what Fluent's Finished asks for, so that option changes nothing.
	function TAB.AddInput(self: any, flag: string, config: any): any
		local options = config or {}
		return Support.remember(
			library.Options,
			self:Textbox({
				Text = options.Title,
				Description = options.Description,
				Flag = flag,
				Default = options.Default,
				Placeholder = options.Placeholder,
				Numeric = options.Numeric == true,
				Callback = options.Callback,
			})
		)
	end

	return TAB
end

function Window.AddTab(self: Window, config: any?): any
	local options = config or {}
	local tab = self.Element:CreateTab(options.Title or "Tab", Support.icon(options.Icon))
	self.Tabs[options.Title or "Tab"] = tab
	table.insert(self.Order, tab)
	return Support.augment(tab, tabMethods(self.Library))
end

--- Fluent selects tabs by 1-based position; a name or the tab itself works too.
function Window.SelectTab(self: Window, target: any)
	if type(target) == "number" then
		local found = self.Order[target]
		if found then
			self.Element:SelectTab(found)
		end
		return
	end

	self.Element:SelectTab(target)
end

--- Loom has no modal, so a dialog shows its text as a toast and lands one real
--- button row per entry on the open tab, where the callbacks stay clickable.
function Window.Dialog(self: Window, config: any)
	local options = config or {}
	local selected = self.Element.Selected

	self.Element:Notify({
		Title = options.Title,
		Content = options.Content,
		Duration = 6,
		Kind = "info",
	})

	if selected == nil then
		return
	end

	for _, button in options.Buttons or {} do
		selected:Button({ Text = button.Title, Callback = button.Callback })
	end
end

function Window.Toggle(self: Window)
	self.Element:Toggle()
end

function Window.SetVisible(self: Window, visible: boolean)
	self.Element:SetVisible(visible)
end

function Window.Destroy(self: Window)
	self.Element:Destroy()
end

--- Wraps a live Loom window in Fluent's vocabulary.
local function window(library: Fluent, element: any): Window
	local self: Window = (setmetatable({ Library = library, Element = element }, Window) :: any) :: Window
	self.Name = element.Name
	self.Tabs = {}
	self.Order = {}
	return self
end

--- Fluent's key state is read straight off Loom's input signal, because Loom
--- itself only reports a change of bind, never a key that is being held.
function Fluent.new(loom: any): Fluent
	local self: Fluent = (
		setmetatable({
			Name = "Fluent",
			Loom = loom,
			Options = {},
			Held = {},
			Unloaded = false,
		}, Fluent) :: any
	) :: Fluent

	self._began = loom.Input.Began:Connect(function(input: InputObject)
		self.Held[input.KeyCode] = true
	end)

	self._ended = loom.Input.Ended:Connect(function(input: InputObject)
		self.Held[input.KeyCode] = nil
	end)

	return self
end

--- Fluent's window is a single title with an optional subtitle under it; Loom
--- has one header line, so the subtitle is appended to the name. TabWidth and
--- Acrylic are accepted and dropped: the style owns the sidebar and the blur.
function Fluent.CreateWindow(self: Fluent, config: any?): any
	local options = config or {}
	local size = options.Size
	local title = options.Title or "Fluent"
	if options.SubTitle then
		title = `{title} {options.SubTitle}`
	end

	local element = self.Loom:CreateWindow({
		Name = title,
		Theme = Support.style(THEMES, options.Theme),
		Size = if size then Vector2.new(size.X.Offset, size.Y.Offset) else nil,
		Keybind = options.MinimizeKey,
	})

	self.Window = window(self, element)
	return self.Window
end

function Fluent.Notify(self: Fluent, config: any): any
	local options = config or {}
	local target = if self.Window then (self.Window :: any).Element else nil
	if target == nil then
		return nil
	end

	local content = options.Content or ""
	if options.SubContent then
		content = `{content}\n{options.SubContent}`
	end

	-- A nil Duration means "stay up", which Loom expresses with a long one.
	return target:Notify({
		Title = options.Title,
		Content = content,
		Duration = if options.Duration == nil then 3600 else Support.duration(options.Duration, 5),
		Kind = "info",
	})
end

function Fluent.SetTheme(self: Fluent, name: string)
	local target = if self.Window then (self.Window :: any).Element else nil
	if target then
		target:SetTheme(Support.style(THEMES, name) or name)
	end
end

function Fluent.Destroy(self: Fluent)
	self.Unloaded = true
	self._began:Disconnect()
	self._ended:Disconnect()

	if self.Window then
		self.Window:Destroy()
	end
end

return Fluent
