-- Assertions for the headless run. tools/smoke.mjs concatenates this after the
-- bundle, so `Loom` is already a local in this chunk and the mock's Roblox
-- globals are installed.

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

--- One group's hard error must not hide the groups after it.
local function group(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		failures += 1
		print("FAIL - group '" .. name .. "' threw :: " .. tostring(err))
	end
end

local function countKeys(target)
	local total = 0
	for _ in target do
		total += 1
	end
	return total
end

local Window
local Main
local Picker
local SliderElement
local NameElement
local calls = {}

group("window", function()
	Window = Loom:CreateWindow({ Name = "Smoke", Theme = "Nice", Size = Vector2.new(620, 460) })

	check("CreateWindow returns a table", type(Window) == "table")
	check("window exposes a panel", Window.Panel ~= nil)
	check(
		"panel has children",
		Window.Panel ~= nil and #Window.Panel:GetChildren() > 0,
		Window.Panel and #Window.Panel:GetChildren()
	)
	check(
		"screen has children",
		Window.Screen ~= nil and #Window.Screen:GetChildren() > 0,
		Window.Screen and #Window.Screen:GetChildren()
	)
	check(
		"theme resolved by name",
		Window.Theme ~= nil and Window.Theme.Name == "Nice",
		Window.Theme and Window.Theme.Name
	)
	check(
		"keybind defaults to RightControl",
		Window.Keybind ~= nil and Window.Keybind.Name == "RightControl",
		Window.Keybind and Window.Keybind.Name
	)
	check("popup layer exists on the window", Window.Popups ~= nil)
	check(
		"popup layer is a sibling of the panel",
		Window.Popups ~= nil and Window.Popups.Parent == Window.Root
	)
end)

group("tabs", function()
	Main = Window:CreateTab("Main", "home")
	local second = Window:CreateTab("Config", "settings")
	local third = Window:CreateTab("About", nil)

	check("three tabs registered", #Window.Tabs == 3, #Window.Tabs)
	check("first tab auto selected", Window.Selected == Main)
	check("first page visible", Main.Page.Visible == true)
	check("second page hidden", second.Page.Visible == false)
	check("third page hidden", third.Page.Visible == false)
	check("tab exposes the page content frame", Main.Content ~= nil)
	check("tab has a sidebar entry", Main.Entry ~= nil)
	check("sidebar entry named after the tab", Main.Entry.Name == "Main", Main.Entry.Name)

	Window:SelectTab(second)
	check("second page visible after SelectTab", second.Page.Visible == true)
	check("first page hidden after SelectTab", Main.Page.Visible == false)

	Window:SelectTab(Main)
	check("selection returns to the first tab", Main.Page.Visible == true and second.Page.Visible == false)
end)

group("elements", function()
	local section = Main:Section({ Text = "General" })
	local label = Main:Label({ Text = "A wrapped label" })
	local paragraph = Main:Paragraph({ Title = "Paragraph", Text = "Body text that wraps across lines." })
	local divider = Main:Divider()

	local buttonFired = 0
	local button = Main:Button({
		Text = "Press",
		Callback = function()
			buttonFired += 1
		end,
	})

	local toggle = Main:Toggle({
		Text = "Enabled",
		Flag = "smokeToggle",
		Default = true,
		Callback = function(value)
			table.insert(calls, { "toggle", value })
		end,
	})

	SliderElement = Main:Slider({
		Text = "Amount",
		Flag = "smokeSlider",
		Min = 0,
		Max = 100,
		Default = 10,
		Rounding = 0,
		Callback = function(value)
			table.insert(calls, { "slider", value })
		end,
	})

	local dropdown = Main:Dropdown({
		Text = "Pick",
		Flag = "smokePick",
		Options = { "A", "B", "C" },
		Default = "A",
		Callback = function(value)
			table.insert(calls, { "dropdown", value })
		end,
	})

	local multi = Main:Dropdown({
		Text = "Multi",
		Flag = "smokeMulti",
		Options = { "A", "B", "C" },
		Multi = true,
		Default = { "A" },
		Search = true,
		Callback = function(value)
			table.insert(calls, { "multi", value })
		end,
	})

	NameElement = Main:Textbox({
		Text = "Name",
		Flag = "smokeName",
		Default = "start",
		Placeholder = "type here",
		Callback = function(value)
			table.insert(calls, { "textbox", value })
		end,
	})

	local keybind = Main:Keybind({
		Text = "Bind",
		Flag = "smokeBind",
		Callback = function(value)
			table.insert(calls, { "keybind", value })
		end,
	})

	Picker = Main:ColorPicker({
		Text = "Colour",
		Flag = "smokeColour",
		Default = Color3.fromRGB(10, 20, 30),
		Callback = function(color, alpha)
			table.insert(calls, { "colour", color, alpha })
		end,
	})

	local created = {
		Section = section,
		Label = label,
		Paragraph = paragraph,
		Divider = divider,
		Button = button,
		Toggle = toggle,
		Slider = SliderElement,
		Dropdown = dropdown,
		MultiDropdown = multi,
		Textbox = NameElement,
		Keybind = keybind,
		ColorPicker = Picker,
	}

	for name, element in created do
		check("element " .. name .. " has a row frame", element ~= nil and element.Frame ~= nil)
	end

	check("tab recorded every element", #Main.Elements == 12, #Main.Elements)
	check("window registered seven flags", countKeys(Window.Flags) == 7, countKeys(Window.Flags))

	toggle:Set(false)
	check("toggle Get after Set(false)", toggle:Get() == false, tostring(toggle:Get()))
	check("toggle GetValue mirrors Get", toggle:GetValue() == false)
	check(
		"toggle callback fired",
		calls[#calls] ~= nil and calls[#calls][1] == "toggle" and calls[#calls][2] == false
	)

	SliderElement:Set(42)
	check("slider Get after Set(42)", SliderElement:Get() == 42, tostring(SliderElement:Get()))
	SliderElement:Set(500)
	check("slider clamps above Max", SliderElement:Get() == 100, tostring(SliderElement:Get()))
	SliderElement:Set(42)

	NameElement:Set("hello")
	check("textbox Get after Set", NameElement:Get() == "hello", tostring(NameElement:Get()))

	dropdown:Set("B")
	check("dropdown Get after Set", dropdown:Get() == "B", tostring(dropdown:Get()))

	multi:Set({ "A", "C" })
	local picked = multi:Get()
	check("multi dropdown returns a list", type(picked) == "table" and #picked == 2, picked and #picked)

	keybind:Set(Enum.KeyCode.E)
	check(
		"keybind Get after Set",
		keybind:Get() ~= nil and keybind:Get().Name == "E",
		keybind:Get() and keybind:Get().Name
	)
	keybind:Set(nil)
	check("keybind clears to nil", keybind:Get() == nil)
	keybind:Set(Enum.KeyCode.E)

	Picker:Set(Color3.fromRGB(200, 100, 50))
	local colour = Picker:Get()
	check("colour picker returns a Color3", typeof(colour) == "Color3", typeof(colour))
	check("colour picker round trips", math.abs(colour.R - 200 / 255) < 0.01, colour and colour.R)

	toggle:SetValue(true)
	check("SetValue drives the element", toggle:Get() == true)

	button._action.Activated:Fire()
	check("button callback fired on Activated", buttonFired == 1, buttonFired)
end)

group("signals", function()
	local fired = 0
	local connection = SliderElement.Changed:Connect(function()
		fired += 1
	end)

	SliderElement:Set(33)
	check("element Changed signal fired once", fired == 1, fired)

	connection:Disconnect()
	SliderElement:Set(34)
	check("disconnected listener stops firing", fired == 1, fired)
	SliderElement:Set(42)
end)

group("popups", function()
	check("tab exposes a popup layer", Main.Popups ~= nil, Main.Popups == nil and "tab.Popups is nil" or nil)
	check("window popup layer reachable via the tab host", Main.Host ~= nil and Main.Host.Popups ~= nil)

	if Main.Popups == nil then
		print("     (skipping dropdown/colour popup checks: tab.Popups is nil, elements parent popups to it)")
		return
	end

	local dropdown = Window.Flags.smokePick
	dropdown.Header.Activated:Fire()
	check("dropdown popup built on open", dropdown._Popup ~= nil)
	check(
		"dropdown popup parented to the popup layer",
		dropdown._Popup ~= nil and dropdown._Popup.Parent == Main.Popups
	)
	check("dropdown popup became visible", dropdown._Popup ~= nil and dropdown._Popup.Visible == true)
	dropdown:Close()
	__drain()
	check("dropdown popup hidden after Close", dropdown._Popup == nil or dropdown._Popup.Visible == false)

	Picker:Open()
	local pickerPopup = Picker._popup
	check("colour picker popup built on open", pickerPopup ~= nil)
	check(
		"colour picker popup parented to the popup layer",
		pickerPopup ~= nil and pickerPopup.Parent == Main.Popups
	)
	Picker:Close()
	__drain()
	check("colour picker popup closed", Picker._open == false)
end)

group("flags", function()
	check(
		"GetFlag reads the element",
		Window:GetFlag("smokeSlider") == 42,
		tostring(Window:GetFlag("smokeSlider"))
	)
	Window:SetFlag("smokeSlider", 77)
	check(
		"SetFlag drives the element",
		Window:GetFlag("smokeSlider") == 77,
		tostring(Window:GetFlag("smokeSlider"))
	)
	check("missing flag reads as nil", Window:GetFlag("nope") == nil)
	Window:SetFlag("smokeSlider", 42)
end)

group("themes", function()
	for _, name in { "Glossy", "Glass", "Poly", "Pro", "Goofy", "Clean", "Nice" } do
		Window:SetTheme(name)
		check("theme " .. name .. " applied", Window.Theme.Name == name, Window.Theme.Name)
	end

	Window:SetTheme("Nope")
	check("unknown theme falls back to the default", Window.Theme.Name == "Nice", Window.Theme.Name)

	__drain()
	check("panel survived retheming", Window.Panel.BackgroundColor3 ~= nil)
	check("every element survived retheming", #Main.Elements == 12)
end)

group("blur", function()
	local lighting = game:GetService("Lighting")

	Window:SetTheme("Nice")
	__drain()
	local blur = lighting:FindFirstChild("LoomBlur")
	check("backdrop blur created for a blurring theme", blur ~= nil)
	check("backdrop blur uses the theme size", blur ~= nil and blur.Size == 16, blur and blur.Size)

	Window:SetTheme("Poly")
	__drain()
	check("backdrop blur removed when the theme has none", lighting:FindFirstChild("LoomBlur") == nil)

	Window:SetTheme("Nice")
	__drain()
	check("backdrop blur recreated", lighting:FindFirstChild("LoomBlur") ~= nil)
end)

group("notifications", function()
	local before = #Window._notifyHost:GetChildren()
	local note = Window:Notify({ Title = "Hello", Content = "World", Kind = "success", Duration = 3 })

	check("Notify returns an object", type(note) == "table")
	check(
		"notification is parented",
		#Window._notifyHost:GetChildren() == before + 1,
		#Window._notifyHost:GetChildren()
	)
	check("notification frame is named", note.Frame.Name == "Notification", note.Frame.Name)

	note:Close()
	__drain()
	check(
		"notification removed on close",
		#Window._notifyHost:GetChildren() == before,
		#Window._notifyHost:GetChildren()
	)

	local expiring = Window:Notify({ Title = "Expires", Content = "On its own", Duration = 1 })
	check("second notification parented", #Window._notifyHost:GetChildren() == before + 1)
	__drain()
	check(
		"expired notification removed by its timer",
		#Window._notifyHost:GetChildren() == before,
		#Window._notifyHost:GetChildren()
	)
	check("notification helper is closed", expiring._closed == true)
end)

group("config", function()
	local savedName = Window:GetFlag("smokeName")
	local savedSlider = Window:GetFlag("smokeSlider")
	local savedColour = Picker:Get()

	local path = Window:SaveConfig("smoke")
	check("SaveConfig returns a path", type(path) == "string", path)
	check("config file written", path ~= nil and __files[path] ~= nil, path)
	check("config file listed on disk", table.find(listfiles("Loom"), path) ~= nil, path)

	Window:SetFlag("smokeName", "changed")
	Window:SetFlag("smokeSlider", 5)
	check("flag actually changed", Window:GetFlag("smokeName") == "changed")

	local loaded = Window:LoadConfig("smoke")
	check("LoadConfig returns true", loaded == true, loaded)
	__drain()

	check(
		"string flag restored",
		Window:GetFlag("smokeName") == savedName,
		tostring(Window:GetFlag("smokeName"))
	)
	check(
		"number flag restored",
		Window:GetFlag("smokeSlider") == savedSlider,
		tostring(Window:GetFlag("smokeSlider"))
	)

	local restored = Picker:Get()
	check(
		"colour flag restored",
		typeof(restored) == "Color3" and math.abs(restored.R - savedColour.R) < 0.01,
		tostring(restored)
	)

	local keybind = Window.Flags.smokeBind
	check(
		"keybind restored as an EnumItem",
		keybind:Get() ~= nil and typeof(keybind:Get()) == "EnumItem",
		tostring(keybind:Get())
	)
end)

group("minimize", function()
	local height = Window.Root.Size.Y.Offset
	Window:Minimize()
	__drain()
	check("window collapsed to the header height", Window.Root.Size.Y.Offset == 44, Window.Root.Size.Y.Offset)
	check("sidebar hidden while collapsed", Window.Sidebar.Visible == false)

	Window:Minimize()
	__drain()
	check(
		"window height restored",
		Window.Root.Size.Y.Offset == height,
		Window.Root.Size.Y.Offset .. " wanted " .. height
	)
	check("sidebar visible again", Window.Sidebar.Visible == true)
end)

group("visibility", function()
	Window:Toggle()
	check("Toggle hides the window", Window.Root.Visible == false)
	Window:Toggle()
	check("Toggle shows the window", Window.Root.Visible == true)
end)

group("teardown", function()
	local first = Main.Elements[1]
	first:SetVisible(false)
	check("SetVisible hides a row", first.Frame.Visible == false)
	check("GetVisible reads it back", first:GetVisible() == false)
	first:SetVisible(true)

	Window:Destroy()
	check("Destroy completed without error", true)
end)

print(string.format("SMOKE: %d passed, %d failed", passes, failures))
if failures > 0 then
	error("smoke: " .. failures .. " check(s) failed", 0)
end
print("SMOKE OK")
