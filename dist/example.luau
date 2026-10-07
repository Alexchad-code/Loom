--!nonstrict
-- Loom example. Host dist/loom.lua anywhere and point the URL at it.
--
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/main/dist/loom.lua"))()

local URL = "https://raw.githubusercontent.com/you/loom/main/dist/loom.lua"

-- The cast is for the analyzer: it types loadstring as callable-or-nil.
local Loom = (loadstring(game:HttpGet(URL)) :: any)()

-- Second argument is an icon: any name from Loom.Icons.names() (Lucide, drawn
-- from its geometry), a unicode glyph, or an rbxassetid:// id.
local Window = Loom:CreateWindow({
	Name = "Loom",
	Theme = "Nice",
	Size = Vector2.new(660, 480),
	Keybind = "RightControl",
})

Window:Notify({ Title = "Loom", Content = "Loaded. Press RightControl to hide.", Kind = "success" })

-- ------------------------------------------------------------- dialects ----
--
-- The same window in another library's vocabulary. Loom.Api carries five:
-- Rayfield, Fluent, Linoria, Obsidian and WindUI. Each dialect's CreateWindow
-- goes through Loom:CreateWindow, so a dialect window replaces this one instead
-- of stacking behind it -- run one of these or the window below, not both.
--
--   local Fluent = Loom.Api.Fluent
--   local Window = Fluent:CreateWindow({ Title = "My Script", Theme = "Dark" })
--   local Main = Window:AddTab({ Title = "Main", Icon = "home" })
--
--   Main:AddToggle("enabled", { Title = "Enabled", Default = true })
--   Main:AddSlider("speed", { Title = "Speed", Min = 8, Max = 100, Default = 16 })
--   Fluent:Notify({ Title = "Loaded", Content = "Ready." })
--
--   print(Fluent.Options.enabled.Value)   -- the real Loom row behind it
--
-- A script written for Rayfield reads the same way under different names:
--
--   local Main = Window:CreateTab("Main", "home")
--   Main:CreateToggle({ Name = "Enabled", Flag = "enabled", CurrentValue = true })
--
-- See the Dialects section of the README for what each surface covers.

local Main = Window:CreateTab("Main", "home")
local Visuals = Window:CreateTab("Visuals", "palette")
local Config = Window:CreateTab("Config", "save")

-- The built-in appearance panel gets its own tab: browse every style and tune
-- the interface itself while the script runs.
Window:CreateSettingsTab()

-- ---------------------------------------------------------------- main ----

Main:Section({ Text = "Actions" })

Main:Button({
	Text = "Print something",
	Callback = function()
		print("clicked")
		Window:Notify({ Title = "Button", Content = "You clicked it.", Kind = "info" })
	end,
})

Main:Button({
	Text = "Reset every flag",
	Callback = function()
		Window:SetFlag("enabled", false)
		Window:SetFlag("speed", 16)
	end,
})

Main:Divider()

Main:Section({ Text = "Toggles" })

Main:Toggle({
	Text = "Enabled",
	Description = "The main switch",
	Flag = "enabled",
	Default = true,
	Callback = function(value)
		print("enabled", value)
	end,
})

Main:Toggle({ Text = "Notifications", Flag = "notify", Default = false })
Main:Toggle({ Text = "Auto save", Flag = "autosave", Default = false })

Main:Section({ Text = "Values" })

Main:Slider({
	Text = "Walk speed",
	Flag = "speed",
	Min = 8,
	Max = 100,
	Default = 16,
	Rounding = 0,
	Callback = function(value)
		-- game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = value
		print("speed", value)
	end,
})

local volume = Main:Slider({
	Text = "Volume",
	Flag = "volume",
	Min = 0,
	Max = 1,
	Default = 0.5,
	Rounding = 2,
	Suffix = "x",
})

-- A description can arrive after the row exists, not only in the config.
volume:SetDescription("0 to 1, in hundredths")

Main:Textbox({
	Text = "Username",
	Flag = "username",
	Placeholder = "type a name",
	Default = "",
	Callback = function(value)
		print("username", value)
	end,
})

Main:Textbox({ Text = "Amount", Flag = "amount", Numeric = true, Default = "10" })

Main:Section({ Text = "Selection" })

Main:Dropdown({
	Text = "Mode",
	Flag = "mode",
	Options = { "Legit", "Blatant", "Silent" },
	Default = "Legit",
	Search = true,
	Callback = function(value)
		print("mode", value)
	end,
})

Main:Dropdown({
	Text = "Features",
	Flag = "features",
	Multi = true,
	Options = { "Aimbot", "ESP", "Fly", "Speed", "Noclip" },
	Default = { "ESP" },
})

Main:Keybind({
	Text = "Toggle key",
	Flag = "togglekey",
	Default = Enum.KeyCode.RightControl,
	Callback = function(key)
		Window:SetKeybind(key)
		if key then
			print("toggle key", key.Name)
		end
	end,
})

Main:ColorPicker({
	Text = "Highlight",
	Flag = "highlight",
	Default = Color3.fromRGB(108, 132, 255),
	Callback = function(color)
		print("highlight", color)
	end,
})

-- ------------------------------------------------------------- visuals ----

Visuals:Section({ Text = "Style" })

-- One from each family, so the whole idea is visible without scrolling: the OS
-- idioms, three of the modifiers and a palette. "Every style" has the rest.
Visuals:Dropdown({
	Text = "Style",
	Flag = "style",
	Options = {
		"iOS",
		"macOS",
		"Windows",
		"Linux",
		"Android",
		"Minecraft",
		"Discord",
		"Vaporwave",
		"Retro",
		"Nord",
		"Nice",
	},
	Default = "Nice",
	Callback = function(value)
		Window:SetTheme(value)
	end,
})

Visuals:Dropdown({
	Text = "Every style",
	Flag = "theme",
	Options = Loom.Theme.names(),
	Default = "Nice",
	Search = true,
	Callback = function(value)
		Window:SetTheme(value)
	end,
})

Visuals:Paragraph({
	Title = "About styles",
	Text = "A style carries structure, not only colour: which window controls are "
		.. "drawn, whether the title is centred, whether controls are pills, how the "
		.. "sidebar selects and what colour the switch is. Switching one restyles "
		.. "everything already on screen, so you can flip between iOS, Minecraft "
		.. "and Nord while a script is running.",
})

Visuals:Label({ Text = "Styles are just tables. Register your own with Loom:AddTheme." })
Visuals:Label({ Text = `Icons: {#Loom.Icons.names()} drawn from geometry, nothing to upload` })

Visuals:Divider()
Visuals:Section({ Text = "Effects" })

Visuals:ColorPicker({
	Text = "Accent",
	Flag = "accent",
	Default = Color3.fromRGB(168, 108, 255),
	Alpha = true,
})
Visuals:Slider({ Text = "Transparency", Flag = "alpha", Min = 0, Max = 1, Default = 1, Rounding = 2 })
Visuals:Toggle({ Text = "Bloom", Flag = "bloom", Default = false })

-- -------------------------------------------------------------- config ----

Config:Section({ Text = "Configuration" })

local names = Loom.Config.list()
Config:Dropdown({
	Text = "Config slot",
	Flag = "slot",
	Options = if #names > 0 then names else { "default" },
	Default = "default",
})

Config:Button({
	Text = "Save config",
	Callback = function()
		local path = Window:SaveConfig(Window:GetFlag("slot"))
		Window:Notify({
			Title = "Saved",
			Content = path and `Wrote {path}` or "No filesystem available on this executor.",
			Kind = if path then "success" else "warning",
		})
	end,
})

Config:Button({
	Text = "Load config",
	Callback = function()
		local ok = Window:LoadConfig(Window:GetFlag("slot"))
		Window:Notify({
			Title = "Config",
			Content = if ok then "Loaded." else "Nothing saved under that name.",
			Kind = if ok then "success" else "warning",
		})
	end,
})

Config:Divider()
Config:Section({ Text = "Window" })

Config:Button({
	Text = "Minimise",
	Callback = function()
		Window:Minimize()
	end,
})
Config:Button({
	Text = "Maximise",
	Callback = function()
		Window:Maximize()
	end,
})
Config:Button({
	Text = "Centre",
	Callback = function()
		Window:Center()
	end,
})
Config:Button({
	Text = "Zoom 1.2x",
	Callback = function()
		Window:SetScale(1.2)
	end,
})
Config:Button({
	Text = "Close",
	Callback = function()
		Window:SetVisible(false)
	end,
})

Config:Section({ Text = "State" })

Config:Button({
	Text = "Print every flag",
	Callback = function()
		for name, value in Window:GetFlags() do
			print(name, value)
		end
	end,
})

Config:Button({
	Text = "Print this tab's flags",
	Callback = function()
		print("mode", Config:GetFlag("mode"), "speed", Config:GetFlag("speed"))
	end,
})

Config:Label({ Text = `Executor: {Loom.Env.Executor}` })
Config:Label({ Text = `Keybind: {if Window.Keybind then Window.Keybind.Name else "none"}` })
