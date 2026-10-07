--!strict
-- Shared plumbing for the dialect adapters beside this file. Each adapter is a
-- second vocabulary for the same Loom window, so the colour parsing, key names,
-- notification kinds and option lists they all need live here once.

local Icons = require("@self/../Core/Icons")

local KINDS: { [string]: string } = {
	ok = "success",
	success = "success",
	warn = "warning",
	warning = "warning",
	notice = "info",
	info = "info",
	error = "danger",
	err = "danger",
	fail = "danger",
	failed = "danger",
	danger = "danger",
}

local Support = {}

--- A colour from anything the popular libraries hand over: a Color3, "#rrggbb",
--- { R, G, B } in 0..1, or a picker value's own { Color = ... } wrapper.
function Support.color(value: any): Color3?
	if typeof(value) == "Color3" then
		return value
	end

	if type(value) == "string" then
		local hex = string.match(value, "^#?(%x%x%x%x%x%x)$")
		if hex == nil then
			return nil
		end
		return Color3.fromRGB(
			tonumber(string.sub(hex, 1, 2), 16) or 0,
			tonumber(string.sub(hex, 3, 4), 16) or 0,
			tonumber(string.sub(hex, 5, 6), 16) or 0
		)
	end

	if type(value) ~= "table" then
		return nil
	end

	if value.Color ~= nil then
		return Support.color(value.Color)
	end

	if type(value.R) == "number" and type(value.G) == "number" and type(value.B) == "number" then
		return Color3.new(value.R, value.G, value.B)
	end

	return nil
end

--- A KeyCode from either the enum or the key name a user wrote down. Mouse
--- buttons have no KeyCode, so MB1 and MB2 come back as no keybind at all.
function Support.key(value: any): Enum.KeyCode?
	if typeof(value) == "EnumItem" then
		return if value.EnumType == Enum.KeyCode then value :: any else nil
	end
	if type(value) == "string" then
		return (Enum.KeyCode :: any)[value]
	end
	return nil
end

--- The notification kind closest to whatever a dialect calls it.
function Support.kind(value: any): string
	if type(value) ~= "string" then
		return "info"
	end
	return KINDS[string.lower(value)] or "info"
end

--- Durations arrive in seconds from most libraries and milliseconds from
--- WindUI, which is why anything past a minute is read as milliseconds.
function Support.duration(value: any, fallback: number): number
	if type(value) ~= "number" then
		return fallback
	end
	return if value > 60 then value / 1000 else value
end

--- Decimal places that land a slider on `increment` (Rayfield) or `Step`.
function Support.precision(increment: any): number
	if type(increment) ~= "number" or increment <= 0 or increment >= 1 then
		return 0
	end
	return math.min(6, math.max(0, math.ceil(-math.log10(increment))))
end

--- Loom draws its own icons by name, so an asset id or a number has no
--- equivalent here and simply gets no icon.
function Support.icon(value: any): string?
	if type(value) ~= "string" or value == "" or Icons.isAsset(value) then
		return nil
	end
	return value
end

--- Maps a dialect's own theme names onto Loom styles, falling through to the
--- name itself so "Glass" works in every dialect.
function Support.style(map: { [string]: string }, name: any): string?
	if type(name) ~= "string" then
		return nil
	end
	local wanted = string.lower(name)
	for key, style in map do
		if string.lower(key) == wanted then
			return style
		end
	end
	return name
end

export type Options = {
	Names: { string },
	Values: { [string]: any },
}

--- A dropdown's values in the three shapes the libraries accept: a plain array,
--- an array of records with a Title, or a label -> value dictionary. Returns the
--- display names in order and the value each name stands for.
function Support.options(values: any): Options
	local names: { string } = {}
	local mapped: { [string]: any } = {}

	for key, value in values or {} do
		if type(value) == "table" and value.Type == "Divider" then
			continue
		end

		if type(key) == "number" then
			local name = if type(value) == "table" and value.Title ~= nil
				then tostring(value.Title)
				else tostring(value)
			table.insert(names, name)
			mapped[name] = value
		else
			local name = tostring(value)
			table.insert(names, name)
			mapped[name] = key
		end
	end

	return { Names = names, Values = mapped }
end

--- Adds a dialect's extra method names to something Loom already built, so the
--- object a script keeps hold of answers to the names its library documents.
function Support.augment(object: any, methods: { [string]: any }): any
	for name, method in methods do
		object[name] = method
	end
	return object
end

--- Files a row in a dialect's Options index under its own flag and gives it the
--- `:OnChanged` those dialects document. Loom keeps `Value` current on every
--- element already, so the index needs no mirror of its own.
function Support.remember(store: { [string]: any }, element: any): any
	if element.Flag == nil then
		return element
	end

	Support.augment(element, {
		OnChanged = function(row: any, handler: (any) -> ()): any
			return row.Changed:Connect(handler)
		end,
	})

	store[element.Flag] = element
	return element
end

return Support
