--!strict
-- Loom.
--
--   local Loom = loadstring(game:HttpGet("https://.../loom.lua"))()
--   local Window = Loom:CreateWindow({ Name = "My Script", Theme = "Glass" })
--   local Main = Window:CreateTab("Main", "home")
--   Main:Toggle({ Text = "Enabled", Flag = "enabled", Default = true })
--   Window:Notify({ Title = "Loaded", Content = "Ready.", Kind = "success" })

local Signal = require("@self/Core/Signal")
local New = require("@self/Core/New")
local Animate = require("@self/Core/Animate")
local Theme = require("@self/Core/Theme")
local Ui = require("@self/Core/Ui")
local Icons = require("@self/Core/Icons")
local Env = require("@self/Core/Env")
local Input = require("@self/Core/Input")
local Element = require("@self/Core/Element")
local Config = require("@self/Core/Config")
local Window = require("@self/Window")
local Api = require("@self/Api")

local Loom = {
	Version = "1.1.0",
	Api = {} :: { [string]: any },
	Signal = Signal,
	New = New,
	Animate = Animate,
	Theme = Theme,
	Themes = Theme.Themes,
	Ui = Ui,
	Icons = Icons,
	Env = Env,
	Input = Input,
	Element = Element,
	Config = Config,
}

export type Loom = {
	Version: string,
	Api: { [string]: any },
	Themes: { [string]: Theme.Theme },
	CreateWindow: (self: Loom, config: WindowConfig?) -> Window.Window,
	AddTheme: (self: Loom, base: string, patch: { [string]: any }) -> Theme.Theme,
}

export type WindowConfig = {
	Name: string?,
	Theme: string | Theme.Theme?,
	Size: Vector2?,
	Keybind: Enum.KeyCode | string?,
	Parent: Instance?,
}

--- Creates the window. The first tab created becomes the visible one.
---
--- Loom registers itself in the executor's shared globals, so re-injecting a
--- script replaces the previous window instead of stacking a second one behind
--- it -- the single most common way these libraries end up doubled up.
function Loom.CreateWindow(_self: Loom, config: WindowConfig?): Window.Window
	local shared = Env.shared()
	local previous = shared.Loom
	if type(previous) == "table" and type(previous.Destroy) == "function" then
		pcall(previous.Destroy, previous)
	end

	local window = Window.new(config)
	shared.Loom = window
	return window
end

--- Registers a custom palette: Loom:AddTheme("Nice", { Name = "Blood", Accent = ... })
function Loom.AddTheme(_self: Loom, base: string, patch: { [string]: any }): Theme.Theme
	return Theme.extend(base, patch)
end

--- The compatibility surfaces, bound to this build: Loom.Api.Fluent,
--- Loom.Api.Rayfield, Loom.Api.Linoria, Loom.Api.Obsidian and Loom.Api.WindUI.
--- Each one is that library's call surface over a Loom window, so an existing
--- script keeps its calls. See src/Api for what each dialect covers.
Loom.Api = Api.bind(Loom)

return Loom
