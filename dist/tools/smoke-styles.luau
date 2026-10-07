-- Style coverage. tools/smoke.mjs concatenates this after the bundle, so `Loom`,
-- the mock's globals and `__drain()` are already in scope. Every theme is graded
-- here because a preset is data: a forgotten or mistyped token only shows up
-- when something reads it.

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

--- The mock's Color3 has no __eq, so compare components.
local function sameColor(a, b)
	return math.abs(a.R - b.R) < 0.001 and math.abs(a.G - b.G) < 0.001 and math.abs(a.B - b.B) < 0.001
end

local function colorDetail(color)
	return string.format("%.3f %.3f %.3f", color.R, color.G, color.B)
end

local COLOR_TOKENS = {
	"Window",
	"Sidebar",
	"Surface",
	"SurfaceHover",
	"Inset",
	"Track",
	"Popup",
	"Stroke",
	"Text",
	"TextDim",
	"TextFaint",
	"OnAccent",
	"Accent",
	"AccentB",
	"Success",
	"Warning",
	"Danger",
	"DotClose",
	"DotMinimize",
	"DotZoom",
	"SwitchOn",
	"SwitchKnob",
	"SwitchKnobOn",
	"SliderKnob",
}

local NUMBER_TOKENS = {
	"WindowTransparency",
	"SidebarTransparency",
	"SurfaceTransparency",
	"SurfaceHoverTransparency",
	"InsetTransparency",
	"TrackTransparency",
	"PopupTransparency",
	"StrokeTransparency",
	"Corner",
	"SmallCorner",
	"StrokeWidth",
	"Indicator",
	"RowHeight",
	"Pad",
	"Gap",
	"SidebarWidth",
	"FontSize",
	"SmallFontSize",
	"TitleFontSize",
	"Gloss",
	"Blur",
	"Shadow",
	"Duration",
}

local ENUM_TOKENS = { "TitleAlign", "Font", "MediumFont", "BoldFont", "MonoFont", "Easing" }

local BOOL_TOKENS = { "Light", "Round", "EntryAccent", "Gradient" }

--- The expected kind of every token. A preset that forgets one inherits nothing,
--- because a style is built from a complete base -- so the failure mode is a
--- missing key on the merged table, which is exactly what this catches.
local KINDS: { [string]: string } = { Name = "string", Chrome = "string" }
for _, key in COLOR_TOKENS do
	KINDS[key] = "Color3"
end
for _, key in NUMBER_TOKENS do
	KINDS[key] = "number"
end
for _, key in ENUM_TOKENS do
	KINDS[key] = "EnumItem"
end
for _, key in BOOL_TOKENS do
	KINDS[key] = "boolean"
end

local LEGACY = { "Nice", "Glossy", "Glass", "Poly", "Pro", "Goofy", "Clean" }

local STYLES = {
	"iOS",
	"iOS Dark",
	"macOS",
	"macOS Dark",
	"Windows",
	"Windows Dark",
	"Linux",
	"Linux Dark",
	"Android",
	"Android Dark",
	"Neumorph",
	"Neumorph Dark",
	"Brutalist",
	"Vaporwave",
	"Retro",
	"Pixel",
	"Minecraft",
	"Discord",
	"Discord Light",
	"Nord",
	"Dracula",
	"Tokyo Night",
	"Gruvbox",
	"Catppuccin",
	"One Dark",
	"Solarized",
}

local Window
local Main
local Switch

group("roster", function()
	local names = Loom.Theme.names()
	check("33 themes registered", #names == 33, #names)

	for _, name in LEGACY do
		check("legacy theme " .. name .. " is offered", table.find(names, name) ~= nil)
	end
	for _, name in STYLES do
		check("style " .. name .. " is offered", table.find(names, name) ~= nil)
	end

	local dark = Loom.Theme.get("macOS Dark")
	check("lookup ignores case", Loom.Theme.get("macos dark") == dark)
	check("lookup ignores spacing too", Loom.Theme.get("MACOSDARK") == dark)
	check("an unknown name falls back to the default", Loom.Theme.get("Nope").Name == "Nice")

	local accent = Loom.Theme.get("Nice").Accent
	check(
		"the hand-tuned accent is unchanged",
		sameColor(accent, Color3.fromRGB(108, 132, 255)),
		colorDetail(accent)
	)
end)

group("tokens", function()
	local counted = 0
	for _ in KINDS do
		counted += 1
	end
	check("the token table covers all 59 tokens", counted == 59, counted)

	for _, name in Loom.Theme.names() do
		local theme = Loom.Theme.get(name)
		local wrong = {}

		for key, kind in KINDS do
			local actual = typeof(theme[key])
			if actual ~= kind then
				table.insert(wrong, `{key} is {actual}, wanted {kind}`)
			end
		end

		check(name .. " carries every token", #wrong == 0, table.concat(wrong, "; "))
	end
end)

group("applies", function()
	Window = Loom:CreateWindow({ Name = "Styles", Theme = "Nice", Size = Vector2.new(620, 460) })
	Main = Window:CreateTab("Main", "home")
	Switch = Main:Toggle({ Text = "Switch", Flag = "styleSwitch", Default = false })
	Main:Slider({ Text = "Level", Flag = "styleLevel", Min = 0, Max = 10, Default = 5 })

	local expected = #Main.Elements

	for _, name in Loom.Theme.names() do
		Window:SetTheme(name)
		__drain()

		check(
			name .. " applies to a live window",
			Window.Theme.Name == name and Window.Panel.BackgroundColor3 ~= nil and #Main.Elements == expected,
			`{Window.Theme.Name} with {#Main.Elements} elements`
		)
	end
end)

group("chrome", function()
	local macos = Loom.Theme.get("macOS")
	Window:SetTheme("macOS")
	__drain()

	check("macOS shows the window dots", Window._traffic.Visible == true)
	check("macOS hides the caption buttons", Window._caption.Visible == false)
	check("macOS centres its title", Window._title.TextXAlignment == Enum.TextXAlignment.Center)
	check("macOS has three dots", #Window._dots == 3, #Window._dots)
	check(
		"the first dot is the close colour",
		sameColor(Window._dots[1].BackgroundColor3, macos.DotClose),
		colorDetail(Window._dots[1].BackgroundColor3)
	)
	check(
		"the second dot is the minimize colour",
		sameColor(Window._dots[2].BackgroundColor3, macos.DotMinimize),
		colorDetail(Window._dots[2].BackgroundColor3)
	)
	check(
		"the third dot is the zoom colour",
		sameColor(Window._dots[3].BackgroundColor3, macos.DotZoom),
		colorDetail(Window._dots[3].BackgroundColor3)
	)

	local windows = Loom.Theme.get("Windows Dark")
	Window:SetTheme("Windows Dark")
	__drain()

	check("Windows hides the dots", Window._traffic.Visible == false)
	check("Windows shows the caption buttons", Window._caption.Visible == true)
	check("Windows keeps its minimize button", Window._minimize.Visible == true)
	check("Windows aligns its title left", Window._title.TextXAlignment == Enum.TextXAlignment.Left)
	check(
		"the dots are recoloured for the new theme anyway",
		sameColor(Window._dots[1].BackgroundColor3, windows.DotClose),
		colorDetail(Window._dots[1].BackgroundColor3)
	)

	Window:SetTheme("Linux")
	__drain()
	check(
		"GNOME keeps one lone close button",
		Window._caption.Visible == true and Window._minimize.Visible == false
	)

	Window:SetTheme("iOS")
	__drain()
	check(
		"iOS keeps one lone close button",
		Window._caption.Visible == true and Window._minimize.Visible == false
	)
end)

group("maximize", function()
	Window:SetTheme("Windows")
	__drain()

	local before = Window.Root.Size
	Window:Maximize()
	__drain()
	check(
		"maximize fills the viewport",
		Window.Root.Size.X.Offset == 1896 and Window.Root.Size.Y.Offset == 1056,
		`{Window.Root.Size.X.Offset}x{Window.Root.Size.Y.Offset}`
	)

	Window:Maximize()
	__drain()
	check(
		"a second maximize restores the size",
		Window.Root.Size.X.Offset == before.X.Offset and Window.Root.Size.Y.Offset == before.Y.Offset,
		`{Window.Root.Size.X.Offset}x{Window.Root.Size.Y.Offset}`
	)
end)

group("controls", function()
	Window:SetTheme("iOS")
	__drain()
	check(
		"a pill style gives rows a pill",
		Switch._corner.CornerRadius.Scale == 1 and Switch._corner.CornerRadius.Offset == 0,
		`{Switch._corner.CornerRadius.Scale}/{Switch._corner.CornerRadius.Offset}`
	)
	check(
		"the iOS switch fills with SwitchOn",
		sameColor(Switch._fill.BackgroundColor3, Loom.Theme.get("iOS").SwitchOn),
		colorDetail(Switch._fill.BackgroundColor3)
	)

	Window:SetTheme("Nice")
	__drain()
	local nice = Loom.Theme.get("Nice")
	check(
		"a rounded style keeps a radius",
		Switch._corner.CornerRadius.Scale == 0 and Switch._corner.CornerRadius.Offset == 8,
		`{Switch._corner.CornerRadius.Scale}/{Switch._corner.CornerRadius.Offset}`
	)
	check(
		"the switch fills with SwitchOn",
		sameColor(Switch._fill.BackgroundColor3, nice.SwitchOn),
		colorDetail(Switch._fill.BackgroundColor3)
	)
	check(
		"the switch knob follows SwitchKnob",
		sameColor(Switch._knob.BackgroundColor3, nice.SwitchKnob),
		colorDetail(Switch._knob.BackgroundColor3)
	)
	check("a sweeping style gets its sweep", Switch._fill:FindFirstChildOfClass("UIGradient") ~= nil)

	Window:SetTheme("Windows Dark")
	__drain()
	check(
		"a flat style takes the small radius",
		Switch._corner.CornerRadius.Scale == 0 and Switch._corner.CornerRadius.Offset == 4,
		`{Switch._corner.CornerRadius.Scale}/{Switch._corner.CornerRadius.Offset}`
	)
	check(
		"the flat switch fills with its own SwitchOn",
		sameColor(Switch._fill.BackgroundColor3, Loom.Theme.get("Windows Dark").SwitchOn),
		colorDetail(Switch._fill.BackgroundColor3)
	)
	check("the sweep is dropped", Switch._fill:FindFirstChildOfClass("UIGradient") == nil)

	Window:SetTheme("Nice")
	__drain()
	check("the sweep comes back", Switch._fill:FindFirstChildOfClass("UIGradient") ~= nil)
end)

group("sidebar", function()
	Window:SetTheme("macOS")
	__drain()

	local selected = Window.Selected
	local macos = Loom.Theme.get("macOS")
	check(
		"macOS fills the selected entry with the accent",
		sameColor(selected._entryFill.BackgroundColor3, macos.Accent),
		colorDetail(selected._entryFill.BackgroundColor3)
	)
	check("macOS has no accent bar", selected._indicator.Visible == false)

	Window:SetTheme("Windows Dark")
	__drain()

	local windows = Loom.Theme.get("Windows Dark")
	check(
		"Windows fills the selected entry with the surface",
		sameColor(selected._entryFill.BackgroundColor3, windows.Surface),
		colorDetail(selected._entryFill.BackgroundColor3)
	)
	check("Windows brings the accent bar back", selected._indicator.Visible == true)
	check(
		"the bar is as wide as the token",
		selected._indicator.Size.X.Offset == windows.Indicator,
		selected._indicator.Size.X.Offset
	)
end)

--- Last, because creating a window replaces the one above.
group("viewport", function()
	local camera = workspace.CurrentCamera
	camera.ViewportSize = Vector2.new(360, 640)

	local small = Loom:CreateWindow({ Name = "Small", Theme = "Nice" })
	__drain()
	check("a tiny viewport clamps the width", small.Root.Size.X.Offset == 380, small.Root.Size.X.Offset)
	check("a tiny viewport keeps the height", small.Root.Size.Y.Offset == 460, small.Root.Size.Y.Offset)

	small:Destroy()
	__drain()
	check("destroying it clears the shared registration", Loom.Env.shared().Loom == nil)

	camera.ViewportSize = Vector2.new(1920, 1080)
end)

print(string.format("SMOKE-STYLES: %d passed, %d failed", passes, failures))
if failures > 0 then
	error("smoke-styles: " .. failures .. " check(s) failed", 0)
end
print("SMOKE-STYLES OK")
