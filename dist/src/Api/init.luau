--!strict
-- Compatibility surfaces. Loom's own API is the one the README documents; this
-- folder re-expresses it in the dialects people already write scripts against,
-- so an existing script keeps its calls and still gets Loom's styles, icons and
-- config system underneath:
--
--   local Fluent = Loom.Api.Fluent
--   local Window = Fluent:CreateWindow({ Title = "My Script" })
--
-- Api.install() also publishes every dialect into the executor's shared globals,
-- for a script that expects the real library to already be there.

local Env = require("@self/../Core/Env")
local Support = require("@self/Support")
local Rayfield = require("@self/Rayfield")
local Fluent = require("@self/Fluent")
local Linoria = require("@self/Linoria")
local Obsidian = require("@self/Obsidian")
local WindUI = require("@self/WindUI")

local MODULES: { [string]: any } = {
	Rayfield = Rayfield,
	Fluent = Fluent,
	Linoria = Linoria,
	Obsidian = Obsidian,
	WindUI = WindUI,
}

local NAMES: { string } = {}
for name in MODULES do
	table.insert(NAMES, name)
end
table.sort(NAMES)

--- What `Loom.Api` is: one instance of each dialect, bound once for the life of
--- the process. A dialect holds no GUI until its own CreateWindow is called.
local BOUND: { [string]: any } = {
	Support = Support,
	Names = NAMES,
}

local Api = {
	Support = Support,
	Names = NAMES,
}

export type Api = {
	Support: any,
	Names: { string },
	bind: (loom: any) -> { [string]: any },
	install: () -> { [string]: any },
}

--- Binds every dialect to `loom`. This is what `Loom.Api` becomes, so a surface
--- is reached by name: Loom.Api.Rayfield:CreateWindow({ Name = "My Script" }).
function Api.bind(loom: any): { [string]: any }
	for name, module in MODULES do
		BOUND[name] = module.new(loom)
	end

	-- Reachable as Loom.Api.install(), rather than needing this module again.
	BOUND.install = Api.install
	return BOUND
end

--- Publishes the bound dialects into the executor's shared globals, so a payload
--- written against the real Rayfield or Fluent can run on Loom by dropping its
--- loadstring line. Reached as Loom.Api.install().
function Api.install(): { [string]: any }
	local shared = Env.shared()

	for _, name in NAMES do
		shared[name] = BOUND[name]
	end

	return BOUND
end

return Api
