--!strict
-- The built-in appearance panel: the style roster is browsable and the interface
-- is tunable while the script is running. Every control carries a flag, so a
-- config save round-trips the whole panel along with the script's own values.

local Env = require("@self/../Core/Env")
local Theme = require("@self/../Core/Theme")
local Ui = require("@self/../Core/Ui")

local SettingsTab = {}

--- Where overrides are registered. One name for every rebuild, so dragging a
--- slider for a minute does not add a hundred entries to the registry.
local CUSTOM = "Custom"

local DARK = " Dark"
local LIGHT = " Light"

--- The style a variant belongs to, so "iOS Dark" and "iOS" resolve alike.
local function family(name: string): string
	if string.sub(name, -#DARK) == DARK then
		return string.sub(name, 1, #name - #DARK)
	end
	if string.sub(name, -#LIGHT) == LIGHT then
		return string.sub(name, 1, #name - #LIGHT)
	end
	return name
end

--- The dark or light half of a style pair -- "iOS" and "iOS Dark", "Discord
--- Light" and "Discord". A style with no counterpart keeps its own name, so
--- Solarized, Nord and Neumorph never jump somewhere unrelated.
local function variant(name: string, dark: boolean): string
	local base = family(name)
	for _, candidate in { base .. (if dark then DARK else LIGHT), base } do
		local found = Theme.Themes[candidate]
		if found and found.Light ~= dark then
			return candidate
		end
	end
	return name
end

--- Builds the appearance tab and returns it, ready to be selected.
function SettingsTab.new(window: any): any
	local tab = window:CreateTab("Settings", "settings")

	local base: string = window.Theme.Name
	if base == CUSTOM then
		base = Theme.Default
	end

	local overrides: { [string]: any } = {}
	local syncing = false

	-- Declared first because two callbacks below reach back into the panel: the
	-- dark switch moves the style picker, and Reset moves every control at once.
	local style: any
	local dark: any
	local accent: any
	local zoom: any
	local row: any
	local corner: any
	local blur: any
	local pills: any
	local gloss: any
	local info: any

	--- Moves a control without letting its own callback re-enter, so the panel is
	--- the only writer while it resets or swaps a variant.
	local function set(control: any, value: any)
		syncing = true
		control:Set(value)
		syncing = false
	end

	--- Rebuilds the single Custom style from the base and every override, then
	--- puts the window on it, so one tweak repaints rows, sidebar and chrome.
	local function apply()
		local patch: { [string]: any } = { Name = CUSTOM }
		for token, value in overrides do
			patch[token] = value
		end

		window:SetTheme(Theme.extend(base, patch))
		info:Set(`Style: {base}` .. (if next(overrides) then "  (tuned)" else ""))
	end

	--- Puts every override back and returns to the default style.
	local function reset()
		overrides = {}
		base = Theme.Default

		local theme = Theme.get(base)
		set(style, base)
		set(dark, theme.Light == false)
		set(accent, theme.Accent)
		set(zoom, 1)
		set(row, theme.RowHeight)
		set(corner, theme.Corner)
		set(blur, theme.Blur)
		set(pills, theme.Round)
		set(gloss, theme.Gloss > 0)

		window:SetScale(1)
		apply()
	end

	tab:Section({ Text = "Appearance" })

	style = tab:Dropdown({
		Text = "Style",
		Description = `All {#Theme.names()} presets, applied as soon as one is picked`,
		Flag = "loomStyle",
		Options = Theme.names(),
		Default = base,
		Search = true,
		Callback = function(value: any)
			if syncing then
				return
			end
			base = tostring(value)
			apply()
		end,
	})

	dark = tab:Toggle({
		Text = "Dark variant",
		Description = "Swaps to the other half of the pair when this style has one",
		Flag = "loomDark",
		Default = window.Theme.Light == false,
		Callback = function(value: any)
			if syncing then
				return
			end

			local target = variant(base, value == true)
			if target == base then
				-- Nothing to swap to, so the switch goes back to the truth.
				set(dark, window.Theme.Light == false)
				return
			end

			base = target
			set(style, base)
			apply()
		end,
	})

	accent = tab:ColorPicker({
		Text = "Accent",
		Description = "Retints accents, gradients and switches",
		Flag = "loomAccent",
		Default = window.Theme.Accent,
		Callback = function(value: any)
			if syncing then
				return
			end
			overrides.Accent = value
			overrides.AccentB = Ui.shade(value, 1.25)
			apply()
		end,
	})

	tab:Divider()
	tab:Section({ Text = "Interface" })

	zoom = tab:Slider({
		Text = "Zoom",
		Description = "Scales the whole window",
		Flag = "loomZoom",
		Min = 0.75,
		Max = 1.35,
		Default = 1,
		Rounding = 2,
		Suffix = "x",
		Callback = function(value: any)
			if syncing then
				return
			end
			window:SetScale(value)
		end,
	})

	row = tab:Slider({
		Text = "Row height",
		Flag = "loomRow",
		Min = 32,
		Max = 60,
		Default = window.Theme.RowHeight,
		Rounding = 0,
		Callback = function(value: any)
			if syncing then
				return
			end
			overrides.RowHeight = value
			apply()
		end,
	})

	corner = tab:Slider({
		Text = "Corner radius",
		Flag = "loomCorner",
		Min = 0,
		Max = 24,
		Default = window.Theme.Corner,
		Rounding = 0,
		Callback = function(value: any)
			if syncing then
				return
			end
			overrides.Corner = value
			overrides.SmallCorner = math.round(value * 2 / 3)
			apply()
		end,
	})

	blur = tab:Slider({
		Text = "Backdrop blur",
		Flag = "loomBlur",
		Min = 0,
		Max = 48,
		Default = window.Theme.Blur,
		Rounding = 0,
		Callback = function(value: any)
			if syncing then
				return
			end
			overrides.Blur = value
			apply()
		end,
	})

	pills = tab:Toggle({
		Text = "Pill controls",
		Description = "Every control becomes fully rounded",
		Flag = "loomPills",
		Default = window.Theme.Round,
		Callback = function(value: any)
			if syncing then
				return
			end
			overrides.Round = value == true
			apply()
		end,
	})

	gloss = tab:Toggle({
		Text = "Gloss",
		Description = "Specular sheen across the header and cards",
		Flag = "loomGloss",
		Default = window.Theme.Gloss > 0,
		Callback = function(value: any)
			if syncing then
				return
			end
			overrides.Gloss = if value == true then 0.2 else 0
			apply()
		end,
	})

	tab:Divider()
	tab:Section({ Text = "Behaviour" })

	tab:Keybind({
		Text = "Toggle key",
		Description = "Shows and hides the window",
		Flag = "loomKey",
		Default = window.Keybind,
		Callback = function(value: any)
			if syncing then
				return
			end
			window:SetKeybind(value)
		end,
	})

	info = tab:Label({ Text = `Style: {base}` })

	tab:Label({ Text = `Executor: {Env.Executor}` })

	tab:Paragraph({
		Title = "How this works",
		Text = "Picking a style, retinting the accent or moving any slider above "
			.. "rebuilds one style named Custom on top of the base you chose, so the "
			.. "window repaints as you go. Every control here carries a flag, which "
			.. "means SaveConfig keeps the whole panel alongside your own values.",
	})

	tab:Button({ Text = "Reset appearance", Callback = reset })

	return tab
end

return SettingsTab
