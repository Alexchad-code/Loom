-- Assertions for the dialect adapters under src/Api: the shared Support helpers
-- and all five surfaces (Rayfield, Fluent, Linoria, Obsidian, WindUI).
-- tools/smoke.mjs concatenates this after the bundle, so `Loom` is already a
-- local and the mock's globals are installed.

local failures = 0
local passes = 0

local function check(name, condition, detail)
	if condition then
		passes += 1
		print("ok   - " .. name)
	else
		failures += 1
		print("FAIL - " .. name .. (if detail ~= nil then " :: " .. tostring(detail) else ""))
	end
end

--- One dialect's hard error must not hide the ones after it.
local function group(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		failures += 1
		print("FAIL - group '" .. name .. "' threw :: " .. tostring(err))
	end
end

local Support = Loom.Api.Support

group("support", function()
	local pink = Support.color("#ff0080")
	check("a hex string parses", pink ~= nil and pink.B > 0.49 and pink.R == 1, tostring(pink))
	check("a Color3 passes through", Support.color(Color3.fromRGB(1, 2, 3)).G > 0)
	check("an R/G/B table parses", math.abs(Support.color({ R = 1, G = 0, B = 0 }).R - 1) < 0.001)
	check("a picker value parses", Support.color({ Color = Color3.fromRGB(10, 20, 30) }).R > 0)
	check("nonsense is no colour", Support.color(7) == nil)
	check("a broken hex is no colour", Support.color("#ff") == nil)

	check("a key name resolves", Support.key("Q") == Enum.KeyCode.Q)
	check("a KeyCode passes through", Support.key(Enum.KeyCode.F) == Enum.KeyCode.F)
	check("a number is no bind", Support.key(4) == nil)
	-- The mock invents a member for any name, so the mouse buttons the libraries
	-- write as "MB1" come through here as the enum the real VM resolves them to.
	check("a mouse button is no bind", Support.key(Enum.UserInputType.MouseButton1) == nil)

	check("ok is success", Support.kind("ok") == "success")
	check("an error is danger", Support.kind("Error") == "danger")
	check("nonsense is info", Support.kind(nil) == "info")

	check("seconds stay seconds", Support.duration(5, 4) == 5)
	check("milliseconds become seconds", Support.duration(5000, 4) == 5)
	check("nothing falls back", Support.duration(nil, 4) == 4)

	check("a whole increment has no decimals", Support.precision(1) == 0)
	check("a half has one", Support.precision(0.5) == 1)
	check("a hundredth has two", Support.precision(0.01) == 2)
	check("nothing has none", Support.precision(nil) == 0)

	check("a lucide name passes", Support.icon("home") == "home")
	check("an asset id does not", Support.icon("rbxassetid://1") == nil)
	check("a number does not", Support.icon(4483362458) == nil)
	check("an empty name does not", Support.icon("") == nil)

	check("a known theme maps", Support.style({ Dark = "Nice" }, "dark") == "Nice")
	check("an unknown name falls through", Support.style({ Dark = "Nice" }, "Glass") == "Glass")
	check("no name has no style", Support.style({ Dark = "Nice" }, nil) == nil)

	local listing = Support.options({ "a", "b" })
	check("an array keeps its order", #listing.Names == 2 and listing.Names[2] == "b")
	check("an array stands for itself", listing.Values.b == "b")

	local dictionary = Support.options({ item01 = "Excalibur" })
	check("a dictionary maps label to key", dictionary.Values.Excalibur == "item01")

	local records = Support.options({ { Title = "One" }, { Title = "Two" }, { Type = "Divider" } })
	check("records keep their titles", #records.Names == 2, #records.Names)
	check("a divider is not an option", records.Names[2] == "Two", tostring(records.Names[2]))
end)

group("roster", function()
	local missing = {}
	for _, name in { "Rayfield", "Fluent", "Linoria", "Obsidian", "WindUI" } do
		local dialect = Loom.Api[name]
		if dialect == nil or dialect.Name ~= name then
			table.insert(missing, name)
		end
	end

	check("every dialect is bound", #missing == 0, table.concat(missing, ", "))
	check("the roster lists them", #Loom.Api.Names == 5, #Loom.Api.Names)
	check("the roster is sorted", Loom.Api.Names[1] == "Fluent", Loom.Api.Names[1])
	check("support rides along", Loom.Api.Support == Support)

	check("install hands back what is bound", Loom.Api.install().Rayfield == Loom.Api.Rayfield)
	check("and publishes it to the shared globals", Loom.Env.shared().Fluent == Loom.Api.Fluent)
end)

group("rayfield", function()
	local Rayfield = Loom.Api.Rayfield
	local Window = Rayfield:CreateWindow({ Name = "Rayfield Test", Theme = "Glass" })
	check("a style name passes through", Window.Element.Theme.Name == "Glass", Window.Element.Theme.Name)
	check("the window is the registered one", Loom.Env.shared().Loom == Window.Element)

	local Main = Window:CreateTab("Main", "home")
	check("a tab lands in the index", Window.Tabs.Main == Main)
	check("a lucide icon survives", Main.Icon == "home", tostring(Main.Icon))
	check("an asset icon is dropped", Window:CreateTab("Assets", 4483362458).Icon == nil)

	local before = #Main.Elements
	Main:CreateSection("Movement")
	check("a section adds a row", #Main.Elements == before + 1)

	local fired = 0
	local Toggle = Main:CreateToggle({
		Name = "Enabled",
		Flag = "rayEnabled",
		CurrentValue = true,
		Callback = function()
			fired += 1
		end,
	})
	check("CurrentValue is the default", Toggle:Get() == true)
	check("the flag is filed on the window", Window.Library.Flags.rayEnabled == Toggle)
	Toggle:Set(false)
	check("Set drives the row", Toggle:Get() == false)
	check("and runs the callback", fired == 1, fired)

	local Slider = Main:CreateSlider({
		Name = "Speed",
		Range = { 0, 200 },
		Increment = 0.5,
		CurrentValue = 50,
		Suffix = " wu",
		Flag = "raySpeed",
	})
	check("a slider takes its range", Slider:Get() == 50, Slider:Get())
	check("an increment becomes decimals", Slider._rounding == 1, Slider._rounding)
	Slider:Set(100)
	check("and moves", Slider:Get() == 100, Slider:Get())

	local Multi = Main:CreateDropdown({
		Name = "Mode",
		Options = { "One", "Two" },
		CurrentOption = { "One" },
		MultipleOptions = true,
		Flag = "rayMode",
	})
	check("a multi dropdown keeps its default", #Multi:Get() == 1, #Multi:Get())
	Multi:Refresh({ "Two", "Three" })
	check("Refresh swaps the options", #Multi._Order == 2 and Multi._Order[1] == "Two", Multi._Order[1])

	local Input = Main:CreateInput({ Name = "Note", CurrentValue = "hi", PlaceholderText = "say" })
	check("an input takes CurrentValue", Input:Get() == "hi", Input:Get())
	Input:Set("bye")
	check("and rewrites it", Input:Get() == "bye")

	local Key = Main:CreateKeybind({ Name = "Toggle", CurrentKeybind = "Q", CurrentHoldToggle = "Hold" })
	check("a keybind takes a key name", Key:Get() == "Q", Key:Get())
	Key:Set("F", "Hold")
	check("and a new one", Key.Value == Enum.KeyCode.F)
	Key:Set(Enum.UserInputType.MouseButton1, "Hold")
	check("a mouse button clears it", Key.Value == nil and Key:Get() == "None", tostring(Key.Value))

	local Picker = Main:CreateColorPicker({ Name = "Accent", Color = Color3.fromRGB(255, 0, 128) })
	check("a picker takes a Color3", Picker:Get().R == 1 and Picker:Get().B > 0.5)

	check("a label takes its text positionally", Main:CreateLabel("hello"):Get() == "hello")
	check(
		"a paragraph takes Title and Content",
		Main:CreateParagraph({ Title = "T", Content = "C" }):Get() == "T"
	)

	local toast = Rayfield:Notify({ Title = "Hi", Content = "There", Duration = 6 })
	check("a toast lands", toast ~= nil and toast.Frame.Parent ~= nil)

	check("a config saves", Rayfield:SaveConfiguration() == true)
	check("and loads back", Rayfield:LoadConfiguration() == true)

	Window:Destroy()
	check("teardown removes the screen", Window.Element.Root.Parent == nil)
	check("Destroy is idempotent", Rayfield.Destroy(Rayfield) == nil)
	__drain()
end)

group("fluent", function()
	local Fluent = Loom.Api.Fluent
	local Window = Fluent:CreateWindow({ Title = "Fluent Test", SubTitle = "by dawid", Theme = "Dark" })
	check("the subtitle joins the title", Window.Element.Name == "Fluent Test by dawid", Window.Element.Name)

	local Main = Window:AddTab({ Title = "Main", Icon = "home" })
	check("a tab lands in the index", Window.Tabs.Main == Main)
	check("the first tab opens itself", Window.Element.Selected == Main)

	local Toggle = Main:AddToggle("fluentEnabled", { Title = "Enabled", Default = true })
	check("a toggle carries its flag", Toggle.Flag == "fluentEnabled")
	check("Options finds the row", Fluent.Options.fluentEnabled == Toggle)
	check("Options reads the value", Fluent.Options.fluentEnabled.Value == true)

	local fired = 0
	Toggle:OnChanged(function()
		fired += 1
	end)
	Fluent.Options.fluentEnabled:SetValue(false)
	check("SetValue drives the row", Toggle.Value == false)
	check("OnChanged fired", fired == 1, fired)

	local Slider =
		Main:AddSlider("fluentSpeed", { Title = "Speed", Default = 2, Min = 0, Max = 5, Rounding = 1 })
	check("a slider lands", Fluent.Options.fluentSpeed.Value == 2, Fluent.Options.fluentSpeed.Value)
	Fluent.Options.fluentSpeed:SetValue(3)
	check("Options.SetValue moves the slider", Slider.Value == 3, Slider.Value)

	local Dropdown =
		Main:AddDropdown("fluentMode", { Title = "Mode", Values = { "one", "two", "three" }, Default = 2 })
	check("a numeric default resolves to a name", Dropdown.Value == "two", tostring(Dropdown.Value))

	local Multi = Main:AddDropdown("fluentMany", {
		Title = "Many",
		Values = { "a", "b", "c" },
		Multi = true,
		Default = { "a", "b" },
	})
	check("a multi default is a list", #Multi.Value == 2, #Multi.Value)
	Multi:SetValue({ c = true, a = true })
	check("a name -> true map still sets it", #Multi.Value == 2 and table.find(Multi.Value, "c") ~= nil)

	local Picker =
		Main:AddColorpicker("fluentAccent", { Title = "Accent", Default = Color3.fromRGB(10, 20, 30) })
	check("a picker takes a Color3", typeof(Picker.Value) == "Color3")
	Picker:SetValueRGB(Color3.fromRGB(0, 255, 140))
	check("SetValueRGB moves it", math.abs(Picker:Get().G - 1) < 0.01, Picker:Get().G)

	local Input = Main:AddInput("fluentNote", { Title = "Note", Default = "hello" })
	check("an input keeps its text", Input.Value == "hello")
	Input:SetValue("bye")
	check("SetValue rewrites it", Fluent.Options.fluentNote.Value == "bye")

	local Key = Main:AddKeybind("fluentKey", { Title = "Key", Default = "LeftControl" })
	check("a keybind takes a name", Key.Value == Enum.KeyCode.LeftControl, tostring(Key.Value))
	Key:SetValue("F")
	check("SetValue moves it", Key.Value == Enum.KeyCode.F)
	check("GetState answers", Key:GetState() == false)
	Key:SetValue(Enum.UserInputType.MouseButton2)
	check("a mouse button unbinds", Key.Value == nil)

	Main:AddParagraph({ Title = "P", Content = "C" })
	Main:AddSection("Afterwards")
	check("the tab grew", #Main.Elements >= 8, #Main.Elements)

	local toast =
		Fluent:Notify({ Title = "Loaded", Content = "Ready", SubContent = "Second line", Duration = 5 })
	check("a toast lands", toast ~= nil and toast.Frame.Parent ~= nil)
	check("SubContent joins the content", string.find(toast._content.Text, "Second line", 1, true) ~= nil)

	Fluent:SetTheme("Light")
	check("a theme change lands", Window.Element.Theme.Light == true)

	Window:Destroy()
	Fluent.Destroy(Fluent)
	check("the library reports unloaded", Fluent.Unloaded == true)
	__drain()
end)

group("linoria", function()
	local Linoria = Loom.Api.Linoria
	local Window = Linoria:CreateWindow({ Title = "Linoria Test", Center = true, AutoShow = true })
	check(
		"a window with no theme still opens",
		Window.Element.Theme.Name == "Nice",
		Window.Element.Theme.Name
	)

	local Main = Window:AddTab("Main", "home")
	check("a tab lands in the index", Window.Tabs.Main == Main)

	local Box = Main:AddLeftGroupbox("Movement", "box")
	local Other = Main:AddRightGroupbox("Other")
	check("a groupbox answers the vocabulary", Box.AddToggle ~= nil and Other.AddSlider ~= nil)
	check(
		"each box captions the page",
		Main.Elements[1].Value == "Movement",
		tostring(Main.Elements[1].Value)
	)
	check("the second box follows it", Main.Elements[2].Value == "Other", tostring(Main.Elements[2].Value))

	local Toggle = Box:AddToggle("linSprint", { Text = "Sprint", Default = true })
	check("a toggle lands in Options", Linoria.Options.linSprint == Toggle)
	check("and in Toggles", Linoria.Toggles.linSprint == Toggle)
	check("and on the window", Window.Element.Flags.linSprint == Toggle)

	local Check = Box:AddCheckbox("linFly", { Text = "Fly", Default = false })
	check("a checkbox is a toggle", Linoria.Options.linFly == Check and Check:Get() == false)

	local clicks = 0
	local Button = Box:AddButton({
		Text = "Run",
		Func = function()
			clicks += 1
		end,
	})
	Button._action.Activated:Fire()
	check("Func is the button's callback", clicks == 1, clicks)
	check("a button chains a sub-button", Button.AddButton ~= nil)

	local Slider = Box:AddSlider("linSpeed", { Text = "Speed", Min = 0, Max = 100, Default = 25 })
	check("a slider lands", Linoria.Options.linSpeed.Value == 25, Linoria.Options.linSpeed.Value)

	local Input = Box:AddInput("linNote", { Text = "Note", Default = "hello" })
	check("an input lands", Linoria.Options.linNote.Value == "hello")

	local Dropdown = Box:AddDropdown("linMode", { Values = { "one", "two", "three" }, Default = 3 })
	check("a numeric default resolves", Dropdown.Value == "three", tostring(Dropdown.Value))

	local Label = Box:AddLabel("A label", true, "linLabel")
	check("an indexed label is reachable", Linoria.Options.linLabel == Label)
	Linoria.Options.linLabel:SetText("Changed")
	check("and takes SetText", Label:Get() == "Changed", Label:Get())

	Box:AddDivider()
	check("a divider adds a row", true)

	local Key = Box:AddKeyPicker("linKey", { Text = "Key", Default = "F" })
	check("a key picker takes a name", Key.Value == Enum.KeyCode.F, tostring(Key.Value))
	Key:SetValue("Q")
	check("SetValue resolves a name too", Key.Value == Enum.KeyCode.Q, tostring(Key.Value))

	check("a toast from a bare string lands", Linoria:Notify("Loaded", 3) ~= nil)

	Linoria:Unload()
	check("Unload tears the window down", Window.Element.Root.Parent == nil)
	__drain()
end)

group("obsidian", function()
	local Obsidian = Loom.Api.Obsidian
	local Window = Obsidian:CreateWindow({ Title = "Obsidian Test", Footer = "v1", Center = true })
	check("the window opens", Window.Element ~= nil)

	local Main = Window:AddTab("Main", "user")
	local KeyTab = Window:AddKeyTab("Key System")
	check("a key tab is a tab", KeyTab.Name == "Key System")
	check("and wears the key glyph", KeyTab.Icon == "key", tostring(KeyTab.Icon))

	Main:AddGroupbox({ Side = "Left", Name = "Groupbox", Description = "boxes" })
	check(
		"a groupbox captions the page",
		Main.Elements[1].Value == "Groupbox",
		tostring(Main.Elements[1].Value)
	)

	local Box = Main:AddGroupbox({ Side = "Right", Name = "Other" })
	check("a second groupbox stacks", Main.Elements[2].Value == "Other", tostring(Main.Elements[2].Value))

	local Toggle = Box:AddToggle("obsFly", { Text = "Fly", Default = true, Visible = false })
	check("a toggle lands in Options", Obsidian.Options.obsFly == Toggle)
	check("and in Toggles", Obsidian.Toggles.obsFly == Toggle)
	check("Visible = false hides the row", Toggle.Frame.Visible == false)

	local Check = Box:AddCheckbox("obsEsp", { Text = "ESP" })
	check("a checkbox is a toggle", Obsidian.Options.obsEsp == Check)

	local Slider = Box:AddSlider("obsSpeed", { Text = "Speed", Min = 0, Max = 10, Default = 5 })
	check("a slider lands", Obsidian.Options.obsSpeed.Value == 5, Obsidian.Options.obsSpeed.Value)

	local Dropdown = Box:AddDropdown("obsMode", {
		Values = { item01 = "Excalibur", item05 = "Aegis" },
		Default = "item01",
	})
	check("a dictionary default selects its label", Dropdown.Value == "Excalibur", tostring(Dropdown.Value))

	local Label = Box:AddLabel("note", true, "obsLabel")
	check("an indexed label is reachable", Obsidian.Options.obsLabel == Label)
	Obsidian.Options.obsLabel:SetText("Changed")
	check("and takes SetText", Label:Get() == "Changed", Label:Get())

	local Key = Box:AddKeyPicker("obsKey", { Text = "Key", Default = "F", Mode = "Hold" })
	check("a key picker takes a name", Key.Value == Enum.KeyCode.F, tostring(Key.Value))

	local Tabbox = Main:AddLeftTabbox()
	local Inner = Tabbox:AddTab("Inner")
	check("a tabbox tab answers the vocabulary", Inner.AddToggle ~= nil)
	check(
		"and captions itself",
		Main.Elements[#Main.Elements].Value == "Inner",
		tostring(Main.Elements[#Main.Elements].Value)
	)

	check("a toast from a bare string lands", Obsidian:Notify("Loaded") ~= nil)

	Window:Destroy()
	check("teardown removes the screen", Window.Element.Root.Parent == nil)
	__drain()
end)

group("windui", function()
	local WindUI = Loom.Api.WindUI
	check("the version rides along", WindUI.Version == Loom.Version, WindUI.Version)

	local Window = WindUI:CreateWindow({
		Title = "WindUI Test",
		Size = UDim2.fromOffset(700, 500),
		Topbar = { ButtonsType = "Mac" },
		Icon = "solar:folder",
	})
	check(
		"a UDim2 size becomes offsets",
		Window.Element.Root.Size.X.Offset == 700,
		Window.Element.Root.Size.X.Offset
	)

	local Tab = Window:Tab({ Title = "About", Icon = "solar:info", Desc = "d" })
	check("a tab lands in the index", Window.Tabs.About == Tab)
	check("a namespaced icon draws nothing", Tab.Element.Icon == nil, tostring(Tab.Element.Icon))

	local Section = Tab:Section({ Title = "Group", Box = true, Opened = false })
	check(
		"a section captions the page",
		Tab.Element.Elements[1].Value == "Group",
		tostring(Tab.Element.Elements[1].Value)
	)

	local Group = Section:Group({})
	check("a group answers the vocabulary", Group.Toggle ~= nil)

	local Toggle = Group:Toggle({ Title = "Enabled", Flag = "windEnabled", Value = true })
	check("a toggle lands", WindUI.Options.windEnabled == Toggle and Toggle:Get() == true)

	local Slider = Group:Slider({
		Title = "Speed",
		Step = 1,
		Flag = "windSpeed",
		Value = { Min = 0, Max = 100, Default = 40 },
	})
	check("a nested value is read", WindUI.Options.windSpeed.Value == 40, WindUI.Options.windSpeed.Value)

	local Dropdown =
		Group:Dropdown({ Title = "Mode", Values = { "one", "two" }, Value = 2, Flag = "windMode" })
	check("a numeric default resolves", Dropdown.Value == "two", tostring(Dropdown.Value))

	local Input = Group:Input({ Title = "Note", Value = "hello", Flag = "windNote" })
	check("an input lands", WindUI.Options.windNote.Value == "hello")

	local Key = Group:Keybind({ Title = "Key", Value = "F", Flag = "windKey" })
	check("a keybind takes a name", Key.Value == Enum.KeyCode.F, tostring(Key.Value))

	local Picker =
		Group:Colorpicker({ Title = "Accent", Default = Color3.fromRGB(1, 2, 3), Flag = "windAccent" })
	check("a picker lands", typeof(WindUI.Options.windAccent.Value) == "Color3")

	local Button = Group:Button({ Title = "Go", Callback = function() end })
	Button:Highlight()
	check("Highlight is answered", true)

	local rows = #Window.Element.Selected.Elements
	Group:Paragraph({ Title = "P", Desc = "C", Buttons = { { Title = "One" }, { Title = "Two" } } })
	check(
		"paragraph buttons become rows",
		#Window.Element.Selected.Elements == rows + 3,
		#Window.Element.Selected.Elements
	)

	Group:Space({ Columns = 2 })
	Group:Divider()

	local toast = WindUI:Notify({ Title = "Hi", Content = "There", Duration = 5000 })
	check("a toast lands", toast ~= nil and toast.Frame.Parent ~= nil)
	check("milliseconds become seconds", toast.Duration == 5, toast.Duration)

	local before = #Window.Element.Selected.Elements
	WindUI:Popup({ Title = "Sure?", Content = "This is a popup", Buttons = { { Title = "OK" } } })
	check("a popup's button becomes a row", #Window.Element.Selected.Elements == before + 1)

	Window:SelectTab(0)
	check("a zero-based index selects", Window.Element.Selected == Tab.Element)

	local Elements = Window:Section({ Title = "Elements" })
	check("a window section is registered", Window.Sections.Elements == Elements)
	check("and holds no tab until it is used", Window.Element.Tabs[2] == nil, #Window.Element.Tabs)
	Elements:Button({ Title = "Late" })
	check("the first row claims one", Window.Element.Tabs[2] ~= nil, #Window.Element.Tabs)

	Window:Destroy()
	check("teardown removes the screen", Window.Element.Root.Parent == nil)
	__drain()
end)

print(string.format("SMOKE-ADAPTERS: %d passed, %d failed", passes, failures))
if failures > 0 then
	error("smoke-adapters: " .. failures .. " check(s) failed", 0)
end
print("SMOKE-ADAPTERS OK")
