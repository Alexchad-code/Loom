-- Assertions for the icon renderer, the built-in appearance panel and the
-- window/element/tab API. tools/smoke.mjs concatenates this after the bundle,
-- so `Loom` is already a local and the mock's globals are installed.

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

local function sameColour(a, b)
	return a ~= nil
		and b ~= nil
		and typeof(a) == "Color3"
		and math.abs(a.R - b.R) < 0.001
		and math.abs(a.G - b.G) < 0.001
		and math.abs(a.B - b.B) < 0.001
end

local Window
local closes = 0

group("icons", function()
	local icons = Loom.Icons
	local names = icons.names()

	check("roster is sorted and complete", #names == 136, #names)
	check("roster holds the names the library uses", table.find(names, "settings") ~= nil)
	check("roster holds the tab glyphs", table.find(names, "home") ~= nil and table.find(names, "box") ~= nil)
	check(
		"roster holds the ornament icons",
		table.find(names, "palette") ~= nil and table.find(names, "gamepad") ~= nil
	)
	check("known name is known", icons.has("settings") == true)
	check("unknown name is not", icons.has("definitely-not-an-icon") == false)

	for index = 2, #names do
		if names[index - 1] > names[index] then
			check("roster sorted at " .. names[index], false, names[index - 1] .. " > " .. names[index])
			break
		end
	end

	local parent = Instance.new("Frame")
	local theme = Loom.Theme.get("Nice")
	local broken = {}
	local heaviest = 0

	for _, name in names do
		local icon = icons.draw(parent, name, theme, { Size = UDim2.fromOffset(18, 18) })
		local pieces = if icon then icon:GetChildren() else {}
		heaviest = math.max(heaviest, #pieces)

		local bad = icon == nil or #pieces == 0 or #pieces > 200
		if not bad then
			for _, piece in pieces do
				local frame = piece :: any
				local size = frame.Size
				local position = frame.Position
				if
					not frame:IsA("Frame")
					or size.X.Offset <= 0
					or size.Y.Offset <= 0
					or frame.BackgroundTransparency ~= 0
					or position.X.Offset < 0
					or position.X.Offset > 18
					or position.Y.Offset < 0
					or position.Y.Offset > 18
				then
					bad = true
					break
				end
			end
		end

		if bad then
			table.insert(broken, name)
		end
		if icon then
			icon:Destroy()
		end
	end

	check("every icon draws inside its box", #broken == 0, table.concat(broken, ", "))
	check("no icon is absurdly heavy", heaviest <= 200, heaviest)
	check("a missing icon draws nothing", icons.draw(parent, "definitely-not-an-icon", theme, {}) == nil)

	-- Ui.icon is what elements and tabs actually call.
	local box = Loom.Ui.icon(parent, theme, "search", { Size = UDim2.fromOffset(20, 20) })
	check("Ui.icon draws a Lucide icon", box:IsA("Frame"), box.ClassName)
	check("drawn icon is pieces of geometry", #box:GetChildren() > 0, #box:GetChildren())

	local triangle = Loom.Ui.icon(parent, theme, "search", { Size = UDim2.fromOffset(20, 20) })
	Loom.Ui.tint(triangle, theme.Accent)
	local tinted = 0
	for _, piece in triangle:GetChildren() do
		if sameColour((piece :: any).BackgroundColor3, theme.Accent) then
			tinted += 1
		end
	end
	check("tint recolours every piece", tinted == #triangle:GetChildren(), tinted)
	triangle:Destroy()

	local glyph = Loom.Ui.icon(parent, theme, "definitely-not-an-icon", { TextSize = 14 })
	check("unknown name falls back to a glyph", glyph:IsA("TextLabel"), glyph.ClassName)
	check("glyph fallback shows the raw text", glyph.Text == "definitely-not-an-icon", glyph.Text)
	glyph:Destroy()

	local image = Loom.Ui.icon(parent, theme, "rbxassetid://123456", {})
	check("asset id stays an image", image:IsA("ImageLabel"), image.ClassName)
	image:Destroy()
	box:Destroy()
	parent:Destroy()
end)

group("window api", function()
	Window = Loom:CreateWindow({ Name = "Api", Theme = "Nice" })
	local main = Window:CreateTab("Main", "home")
	Window:CreateTab("Config", "settings")

	main:Toggle({ Text = "Enabled", Flag = "apiToggle", Default = true })
	main:Slider({ Text = "Amount", Flag = "apiSlider", Min = 0, Max = 100, Default = 25 })

	Window:SetScale(1.25)
	check("scale is stored", Window:GetScale() == 1.25, Window:GetScale())
	Window:SetScale(9)
	check("scale clamps high", Window:GetScale() == 1.5, Window:GetScale())
	Window:SetScale(0.1)
	check("scale clamps low", Window:GetScale() == 0.5, Window:GetScale())
	Window:SetScale(1)
	check("scale returns to 1", Window:GetScale() == 1, Window:GetScale())

	Window:SetSize(Vector2.new(700, 500))
	__drain()
	check(
		"SetSize resizes the root",
		Window.Root.Size.X.Offset == 700 and Window.Root.Size.Y.Offset == 500,
		Window.Root.Size.X.Offset .. "x" .. Window.Root.Size.Y.Offset
	)

	Window:SetSize(Vector2.new(10, 10))
	__drain()
	check(
		"SetSize keeps the minimum",
		Window.Root.Size.X.Offset == 380 and Window.Root.Size.Y.Offset == 260,
		Window.Root.Size.X.Offset .. "x" .. Window.Root.Size.Y.Offset
	)

	Window.Root.Position = UDim2.fromScale(0.2, 0.3)
	Window:Center()
	check(
		"Center restores the middle",
		Window.Root.Position.X.Scale == 0.5 and Window.Root.Position.Y.Scale == 0.5
	)

	Window:SetKeybind("K")
	check(
		"keybind by name",
		Window.Keybind ~= nil and Window.Keybind.Name == "K",
		Window.Keybind and Window.Keybind.Name
	)
	check("hint shows the keybind", Window._hint.Text == "K", Window._hint.Text)

	Window:SetKeybind(Enum.KeyCode.G)
	check("keybind accepts an enum", Window.Keybind ~= nil and Window.Keybind.Name == "G")

	Window:SetKeybind(nil)
	check("keybind can be cleared", Window.Keybind == nil, Window.Keybind)
	check("hint clears with it", Window._hint.Text == "", Window._hint.Text)

	Window:SetKeybind("NotAKeyCode")
	check(
		"hint always matches the keybind",
		(Window.Keybind == nil and Window._hint.Text == "") or Window._hint.Text == Window.Keybind.Name,
		Window._hint.Text
	)
	Window:SetKeybind("RightControl")

	Window:SelectTab("Config")
	check("SelectTab takes a name", Window.Selected.Name == "Config", Window.Selected.Name)
	Window:SelectTab("Nope")
	check("unknown tab name is ignored", Window.Selected.Name == "Config", Window.Selected.Name)

	local flags = Window:GetFlags()
	check(
		"GetFlags returns every flag",
		flags.apiToggle == true and flags.apiSlider == 25,
		tostring(flags.apiSlider)
	)
	Window:SetFlag("apiSlider", 40)
	check("GetFlags reflects a change", Window:GetFlags().apiSlider == 40, Window:GetFlags().apiSlider)

	Window:OnClose(function()
		closes += 1
	end)
end)

group("element api", function()
	Window:SelectTab("Main")
	local main = Window.Selected
	local toggle = Window.Flags.apiToggle

	check("element knows its flag", toggle:GetFlag() == "apiToggle", toggle:GetFlag())
	check("tab reads a flag", Window.Selected:GetFlag("apiToggle") == true)

	Window.Selected:SetFlag("apiToggle", false)
	check("tab writes a flag", Window:GetFlag("apiToggle") == false)
	Window.Selected:SetFlag("apiToggle", true)
	Window.Selected:SetFlag("nope", 1)
	check("unknown flag is ignored", Window:GetFlag("nope") == nil)

	check("row starts without a description", toggle.Description == nil)
	toggle:SetDescription("Added later")
	check(
		"description is created on demand",
		toggle.Description ~= nil and toggle.Description.Text == "Added later",
		toggle.Description and toggle.Description.Text
	)
	check("described row lifts its title", toggle.Label.Size.Y.Offset == -15, toggle.Label.Size.Y.Offset)

	toggle:SetDescription(nil)
	check("description can be removed", toggle.Description == nil)
	check("title returns to centred", toggle.Label.Size.Y.Offset == 0, toggle.Label.Size.Y.Offset)

	local scratch = Window:CreateTab("Scratch", "box")
	scratch:Toggle({ Text = "Throwaway", Flag = "scratchToggle", Default = true })
	scratch:Slider({ Text = "Throwaway", Flag = "scratchSlider", Min = 0, Max = 10, Default = 5 })
	check("scratch tab has elements", #scratch.Elements == 2, #scratch.Elements)
	check("scratch flag registered", Window.Flags.scratchToggle ~= nil)

	scratch:Clear()
	check("Clear empties the tab", #scratch.Elements == 0, #scratch.Elements)
	check("Clear drops the flags", Window.Flags.scratchToggle == nil and Window.Flags.scratchSlider == nil)
	check("Clear keeps the entry", scratch.Entry.Parent ~= nil)
	check("Clear keeps the page", scratch.Page.Parent ~= nil)

	scratch:Toggle({ Text = "Rebuilt", Flag = "scratchAgain", Default = false })
	check("tab can be rebuilt after Clear", #scratch.Elements == 1 and Window.Flags.scratchAgain ~= nil)
	check("main tab is untouched", #main.Elements == 2, #main.Elements)
end)

group("settings panel", function()
	local settings = Window:CreateSettingsTab()

	check("settings tab is named", settings.Name == "Settings", settings.Name)
	check("settings tab is populated", #settings.Elements >= 12, #settings.Elements)

	local wanted = {
		"loomStyle",
		"loomDark",
		"loomAccent",
		"loomZoom",
		"loomRow",
		"loomCorner",
		"loomBlur",
		"loomPills",
		"loomGloss",
		"loomKey",
	}
	local missing = {}
	for _, flag in wanted do
		if Window.Flags[flag] == nil then
			table.insert(missing, flag)
		end
	end
	check("every appearance control carries a flag", #missing == 0, table.concat(missing, ", "))

	local nice = Loom.Theme.get("Nice")
	local minecraft = Loom.Theme.get("Minecraft")

	check("the two presets differ", minecraft.RowHeight ~= nice.RowHeight or minecraft.Corner ~= nice.Corner)

	Window:SetFlag("loomStyle", "Minecraft")
	__drain()
	check(
		"style picker applies a preset",
		Window.Theme.RowHeight == minecraft.RowHeight,
		Window.Theme.RowHeight
	)
	check(
		"and leaves the old preset behind",
		Window.Theme.RowHeight ~= nice.RowHeight,
		Window.Theme.RowHeight
	)

	Window:SetFlag("loomRow", 52)
	Window:SetFlag("loomCorner", 20)
	__drain()
	check("row height override lands", Window.Theme.RowHeight == 52, Window.Theme.RowHeight)
	check("corner override lands", Window.Theme.Corner == 20, Window.Theme.Corner)
	check(
		"corner keeps its ratio",
		Window.Theme.SmallCorner == math.round(20 * 2 / 3),
		Window.Theme.SmallCorner
	)

	Window:SetFlag("loomPills", true)
	__drain()
	check("pill override lands", Window.Theme.Round == true)
	check(
		"a row actually became a pill",
		Window.Flags.apiSlider._corner.CornerRadius.Scale == 1,
		Window.Flags.apiSlider._corner.CornerRadius.Scale
	)

	Window:SetFlag("loomGloss", false)
	__drain()
	check("gloss override lands", Window.Theme.Gloss == 0, Window.Theme.Gloss)

	Window:SetFlag("loomBlur", 24)
	__drain()
	check("blur override lands", Window.Theme.Blur == 24, Window.Theme.Blur)

	Window:SetFlag("loomZoom", 1.2)
	__drain()
	check("zoom reaches the window scale", Window:GetScale() == 1.2, Window:GetScale())

	local pink = Color3.fromRGB(255, 0, 128)
	Window:SetFlag("loomAccent", pink)
	__drain()
	check("accent override lands", sameColour(Window.Theme.Accent, pink), tostring(Window.Theme.Accent))
	check("accent drives its gradient partner", Window.Theme.AccentB ~= nil)

	-- The dark switch only moves where the style has a counterpart.
	Window:SetFlag("loomStyle", "iOS")
	__drain()
	check("light half of a pair is light", Window.Theme.Light == true)

	Window:SetFlag("loomDark", false)
	__drain()
	check(
		"switch with nothing to swap to settles",
		Window:GetFlag("loomDark") == false,
		Window:GetFlag("loomDark")
	)
	check("and the style stayed where it was", Window.Theme.Light == true)

	Window:SetFlag("loomDark", true)
	__drain()
	check("dark switch finds the counterpart", Window.Theme.Light == false)
	check("the tuned style follows it", Window.Theme.Name == "Custom", Window.Theme.Name)

	Window:SetFlag("loomStyle", "Nice")
	Window:SetFlag("loomDark", true)
	Window:SetFlag("loomRow", nice.RowHeight)
	Window:SetFlag("loomCorner", nice.Corner)
	Window:SetFlag("loomBlur", nice.Blur)
	Window:SetFlag("loomPills", nice.Round)
	Window:SetFlag("loomGloss", nice.Gloss > 0)
	Window:SetFlag("loomAccent", nice.Accent)
	Window:SetFlag("loomZoom", 1)
	__drain()

	check(
		"neutral overrides restore the preset",
		Window.Theme.RowHeight == nice.RowHeight,
		Window.Theme.RowHeight
	)
	check("corner restored", Window.Theme.Corner == nice.Corner, Window.Theme.Corner)
	check("round restored", Window.Theme.Round == nice.Round, Window.Theme.Round)
	check("accent restored", sameColour(Window.Theme.Accent, nice.Accent), tostring(Window.Theme.Accent))
	check("scale restored", Window:GetScale() == 1, Window:GetScale())
	check("panel survived retheming", Window.Panel.BackgroundColor3 ~= nil and #settings.Elements >= 12)
	check("window still has every tab", #Window.Tabs == 4, #Window.Tabs)
	Window:SelectTab("Main")
	check("elements survived the panel", #Window.Selected.Elements == 2, #Window.Selected.Elements)
end)

group("teardown", function()
	check("version is 1.1.0", Loom.Version == "1.1.0", Loom.Version)

	Window:Destroy()
	check("close handler ran once", closes == 1, closes)

	Window:Destroy()
	check("second Destroy is silent", closes == 1, closes)
	check("registration cleared", Loom.Env.shared().Loom == nil)
end)

print(string.format("SMOKE-API: %d passed, %d failed", passes, failures))
if failures > 0 then
	error("smoke-api: " .. failures .. " check(s) failed", 0)
end
print("SMOKE-API OK")
