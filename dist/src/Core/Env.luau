--!strict
-- Executor adapter. Every capability is probed once, under every name executors
-- are known to use, and anything missing degrades to a working fallback instead
-- of erroring. Env.Capabilities lists what was actually found on this executor.

local Players = game:GetService("Players")

export type Env = {
	Executor: string,
	Identity: number?,
	Gui: Instance,
	CanProtect: boolean,
	CanSave: boolean,
	CanClipboard: boolean,
	CanFetch: boolean,
	Capabilities: { string },
	Protect: (gui: Instance) -> (),
	Write: (path: string, contents: string) -> boolean,
	Read: (path: string) -> string?,
	Exists: (path: string) -> boolean,
	Mkdir: (path: string) -> (),
	Files: (path: string) -> { string },
	Copy: (text: string) -> (),
	Fetch: (url: string) -> string?,
	Mount: (gui: Instance, preferred: Instance?) -> Instance?,
	shared: () -> { [string]: any },
}

--- Canonical globals, read straight from this chunk. Reading a global an
--- executor does not provide yields nil rather than throwing, so no probe is
--- needed for these -- only for the ones with no declaration to lean on.
local DIRECT: { [string]: () -> any } = {
	gethui = function()
		return gethui
	end,
	protect_gui = function()
		return protect_gui
	end,
	writefile = function()
		return writefile
	end,
	readfile = function()
		return readfile
	end,
	isfile = function()
		return isfile
	end,
	isfolder = function()
		return isfolder
	end,
	makefolder = function()
		return makefolder
	end,
	listfiles = function()
		return listfiles
	end,
	setclipboard = function()
		return setclipboard
	end,
	request = function()
		return request
	end,
	identifyexecutor = function()
		return identifyexecutor
	end,
}

--- The table scripts publish into: getgenv() where there is one, else this
--- chunk's globals. It is handed out live rather than merged, because Loom
--- registers itself here -- and a merged copy would mean the next injection
--- into the same client cannot see the window this one made.
local function liveEnv(): { [string]: any }
	local ok, env = pcall(function()
		return getgenv()
	end)
	if ok and type(env) == "table" then
		return env
	end

	-- Without getgenv() the only table scripts share is _G, and some clients
	-- hand that out readonly. A writable one is used directly so re-injection
	-- still finds the previous window; otherwise writes go to a copy of it.
	local globals = _G
	if type(globals) ~= "table" then
		return {}
	end

	local writable = pcall(function()
		globals.__loomProbe = true
		globals.__loomProbe = nil
	end)
	if writable then
		return globals
	end

	local copy: { [string]: any } = {}
	for key, value in globals do
		copy[key] = value
	end
	return copy
end

local SHARED = liveEnv()

--- Finds a capability under any of the spellings it is known by: this chunk's
--- globals first, then the shared table, then _G when the executor's getgenv()
--- is not the same table as the script environment.
local function lookup(name: string): any
	local getter = DIRECT[name]
	if getter then
		local direct = getter()
		if direct ~= nil then
			return direct
		end
	end

	local value = SHARED[name]
	if value ~= nil then
		return value
	end

	local globals = _G
	if type(globals) == "table" and globals ~= SHARED then
		return globals[name]
	end
	return nil
end

--- The first of `names` this executor provides, or nil.
local function pick(names: { string }): any
	for _, name in names do
		local value = lookup(name)
		if value ~= nil then
			return value
		end
	end
	return nil
end

--- Runs an optional executor function, swallowing a throw. A broken capability
--- should degrade, not take the library down with it.
local function call(fn: any, ...: any): any
	if fn == nil then
		return nil
	end
	local ok, result = pcall(fn, ...)
	return if ok then result else nil
end

local huiFn = pick({ "gethui" })
local protectFn = pick({ "protect_gui", "protectgui" })
local writeFn = pick({ "writefile", "write_file" })
local readFn = pick({ "readfile", "read_file" })
local isfileFn = pick({ "isfile", "is_file" })
local isfolderFn = pick({ "isfolder", "is_folder" })
local makefolderFn = pick({ "makefolder", "makeFolder", "make_folder" })
local listfilesFn = pick({ "listfiles", "listFiles", "list_files" })
local clipboardFn = pick({ "setclipboard", "toclipboard", "set_clipboard" })
local requestFn = pick({ "request", "http_request", "httprequest" })
local identityFn = pick({ "getthreadidentity", "getidentity", "get_thread_identity" })
local nameFn = pick({ "identifyexecutor", "getexecutorname" })

local synTable = SHARED.syn
local synProtect = if type(synTable) == "table" then synTable.protect_gui else nil
local synRequest = if type(synTable) == "table" then synTable.request else nil

--- Executors hand out a hidden container that deliberately survives a game
--- load, so it is asked for once and reused.
local hui: Instance? = call(huiFn)

--- PlayerGui, waiting a bounded amount when the script was injected before the
--- game finished loading rather than dying on a nil LocalPlayer.
local function playerGui(): Instance
	local player = Players.LocalPlayer
	local deadline = os.clock() + 5

	while player == nil and os.clock() < deadline do
		task.wait(0.1)
		player = Players.LocalPlayer
	end

	if player == nil then
		error("[Loom] no LocalPlayer after 5s - inject again once the game has loaded", 2)
	end

	local gui = player:FindFirstChild("PlayerGui")
	if gui then
		return gui
	end

	local waited = player:WaitForChild("PlayerGui", 5)
	if waited == nil then
		error("[Loom] no PlayerGui after 5s", 2)
	end
	return waited
end

--- CoreGui, but only when the executor can protect a gui parented into it --
--- an unprotected ScreenGui there is invisible at best and rejected at worst.
local function coreGui(): Instance?
	if protectFn == nil and synProtect == nil then
		return nil
	end
	return call(function()
		return game:GetService("CoreGui")
	end)
end

--- Where the ScreenGui is most likely to end up, before it has been mounted.
local function resolveGui(): Instance
	return hui or coreGui() or playerGui()
end

--- What this executor actually offers, for diagnostics.
local function capabilities(): { string }
	local found: { [string]: any } = {
		gethui = huiFn,
		protect_gui = protectFn,
		["syn.protect_gui"] = synProtect,
		writefile = writeFn,
		readfile = readFn,
		isfile = isfileFn,
		isfolder = isfolderFn,
		makefolder = makefolderFn,
		listfiles = listfilesFn,
		setclipboard = clipboardFn,
		request = requestFn,
		["syn.request"] = synRequest,
		identifyexecutor = nameFn,
		getthreadidentity = identityFn,
	}

	local list = {}
	for name, value in found do
		if value ~= nil then
			table.insert(list, name)
		end
	end
	table.sort(list)
	return list
end

local Env: Env = {
	Executor = call(nameFn) or "Unknown",
	Identity = call(identityFn),
	Gui = resolveGui(),
	CanProtect = protectFn ~= nil or synProtect ~= nil,
	CanSave = writeFn ~= nil and readFn ~= nil,
	CanClipboard = clipboardFn ~= nil,
	CanFetch = requestFn ~= nil or synRequest ~= nil,
	Capabilities = capabilities(),

	Protect = function(gui: Instance)
		if synProtect then
			call(synProtect, gui)
		else
			call(protectFn, gui)
		end
	end,

	Write = function(path: string, contents: string): boolean
		if writeFn == nil then
			return false
		end

		local ok = pcall(writeFn, path, contents)
		if not ok then
			-- Some executors refuse a path whose folder does not exist yet.
			local folder = string.match(path, "^(.*)[/\\][^/\\]+$")
			if folder then
				call(makefolderFn, folder)
				ok = pcall(writeFn, path, contents)
			end
		end

		if not ok then
			return false
		end
		if isfileFn then
			local checked, exists = pcall(isfileFn, path)
			return checked and exists == true
		end
		return true
	end,

	Read = function(path: string): string?
		if readFn == nil then
			return nil
		end

		-- Executors without isfile have no way to ask, so just try the read.
		if isfileFn then
			local checked, exists = pcall(isfileFn, path)
			if not checked or exists ~= true then
				return nil
			end
		end

		local ok, contents = pcall(readFn, path)
		if ok and type(contents) == "string" then
			return contents
		end
		return nil
	end,

	Exists = function(path: string): boolean
		if isfolderFn then
			local ok, isFolder = pcall(isfolderFn, path)
			if ok and isFolder == true then
				return true
			end
		end
		if isfileFn then
			local ok, isFile = pcall(isfileFn, path)
			if ok and isFile == true then
				return true
			end
		end
		return false
	end,

	Mkdir = function(path: string)
		-- Creating a folder that already exists throws on most executors.
		call(makefolderFn, path)
	end,

	Files = function(path: string): { string }
		local listing = call(listfilesFn, path)
		return if type(listing) == "table" then listing else {}
	end,

	Copy = function(text: string)
		call(clipboardFn, text)
	end,

	--- Synapse-style takes one options table, http_request style takes
	--- (url, method, body, headers), and every client can fall back to the
	--- DataModel method. Try all three so one call site works everywhere.
	Fetch = function(url: string): string?
		local fetcher = synRequest or requestFn
		if fetcher ~= nil then
			local tableForm = call(fetcher, { Url = url, Method = "GET" })
			if type(tableForm) == "table" and type(tableForm.Body) == "string" then
				return tableForm.Body
			end

			local positional = call(fetcher, url, "GET")
			if type(positional) == "string" then
				return positional
			end
		end

		local ok, body = pcall(function(): any
			return (game :: any):HttpGet(url)
		end)
		if ok and type(body) == "string" then
			return body
		end
		return nil
	end,

	--- Parents `gui` in the first candidate that will actually take it. Locked
	--- CoreGui access and hidden containers that refuse children exist on real
	--- executors, so a rejected parent falls through to the next one instead of
	--- throwing -- every stop on this chain is a legitimate home for the window.
	Mount = function(gui: Instance, preferred: Instance?): Instance?
		local candidates: { Instance? } = { preferred, hui, coreGui(), playerGui() }

		for _, candidate in candidates do
			if candidate ~= nil then
				pcall(function()
					gui.Parent = candidate :: Instance
				end)
				if gui.Parent == candidate then
					return candidate
				end
			end
		end

		return nil
	end,

	--- The live executor table, so scripts can hand things to each other. Loom
	--- registers itself here, which is how a second injection replaces the
	--- first window instead of stacking another one on top of it.
	shared = function(): { [string]: any }
		return SHARED
	end,
}

return Env
