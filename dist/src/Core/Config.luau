--!strict
-- Flag persistence. Every element with a `Flag` is already reachable from the
-- window, so a config is just that table encoded and written to the executor's
-- filesystem.

local Env = require("@self/Env")

local HttpService = game:GetService("HttpService")

local FOLDER = "Loom"

export type Store = {
	Flags: { [string]: any },
}

local Config = {}

--- Turns an element's current value into something JSON can hold.
function Config.encode(element: any): any
	local value = element:GetValue()
	local kind = typeof(value)

	if kind == "boolean" or kind == "number" or kind == "string" then
		return value
	end

	if kind == "EnumItem" then
		return (value :: EnumItem).Name
	end

	if kind == "Color3" then
		local color = value :: Color3
		return { r = color.R, g = color.G, b = color.B }
	end

	if kind == "table" then
		if typeof(value.Color) == "Color3" then
			local color = value.Color :: Color3
			return { r = color.R, g = color.G, b = color.B, a = value.Alpha }
		end

		local list = {}
		for _, item in value do
			table.insert(list, item)
		end
		return list
	end

	return nil
end

--- Reshapes a stored value back into what the element's SetValue expects.
function Config.decode(element: any, raw: any): any
	local current = element:GetValue()
	local kind = typeof(current)

	if kind == "EnumItem" then
		return if type(raw) == "string" then (Enum.KeyCode :: any)[raw] else nil
	end

	if kind == "table" and typeof(current.Color) == "Color3" then
		if type(raw) == "table" and type(raw.r) == "number" then
			return {
				Color = Color3.new(raw.r, raw.g, raw.b),
				Alpha = if type(raw.a) == "number" then raw.a else 1,
			}
		end
		return nil
	end

	return raw
end

function Config.path(name: string): string
	return `{FOLDER}/{name}.json`
end

--- Writes every flagged element. Returns the path, or nil when the executor has
--- no filesystem.
function Config.save(store: Store, name: string): string?
	if not Env.CanSave then
		return nil
	end

	local payload: { [string]: any } = {}
	for flag, element in store.Flags do
		payload[flag] = Config.encode(element)
	end

	if not Env.Exists(FOLDER) then
		Env.Mkdir(FOLDER)
	end

	local path = Config.path(name)
	if not Env.Write(path, HttpService:JSONEncode(payload)) then
		return nil
	end
	return path
end

--- Applies a stored config. Returns false when it is missing or unreadable.
function Config.load(store: Store, name: string): boolean
	local raw = Env.Read(Config.path(name))
	if not raw then
		return false
	end

	local decoded = nil
	local ok = pcall(function()
		decoded = HttpService:JSONDecode(raw)
	end)
	if not ok or type(decoded) ~= "table" then
		return false
	end

	for flag, element in store.Flags do
		local stored = decoded[flag]
		if stored ~= nil then
			element:SetValue(Config.decode(element, stored))
		end
	end

	return true
end

--- Config names already written, without the extension.
function Config.list(): { string }
	if not Env.CanSave then
		return {}
	end

	local names = {}
	for _, path in Env.Files(FOLDER) do
		local name = string.match(path, "([^/\\]+)%.json$")
		if name then
			table.insert(names, name)
		end
	end
	return names
end

return Config
