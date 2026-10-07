-- Executor-fallback assertions. tools/smoke.mjs runs this chunk after the bundle
-- under several MOCK_PROFILEs, so every claim about a missing capability is
-- graded under a profile that actually lacks it.

local profile = MOCK_PROFILE or "full"

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

local function has(list, name)
	return table.find(list, name) ~= nil
end

local function playerGui()
	return game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
end

local env = Loom.Env

--- A window with one tab and one element: enough for the checks that only need
--- the library to survive this capability set.
local function build()
	local window = Loom:CreateWindow({ Name = "Env", Theme = "Nice" })
	local tab = window:CreateTab("Main", "home")
	tab:Toggle({ Text = "Enabled", Flag = "envToggle", Default = true })
	return window, tab
end

group("capabilities", function()
	local capabilities = env.Capabilities

	check("Loom.Env is exposed", type(env) == "table")
	check("Capabilities is a list", type(capabilities) == "table")
	check("Mount is wired up", type(env.Mount) == "function")
	check("Executor is a string", type(env.Executor) == "string")

	if profile == "bare" then
		check("nothing detected", #capabilities == 0, #capabilities)
		check("executor is unknown", env.Executor == "Unknown", env.Executor)
		check("no thread identity", env.Identity == nil, env.Identity)
		check("no filesystem", env.CanSave == false)
		check("no protection", env.CanProtect == false)
		check("no clipboard", env.CanClipboard == false)
		check("no http", env.CanFetch == false)
		return
	end

	local canonical = {
		"writefile",
		"readfile",
		"isfile",
		"isfolder",
		"makefolder",
		"listfiles",
		"setclipboard",
		"request",
		"identifyexecutor",
	}
	for _, name in canonical do
		check("capability " .. name, has(capabilities, name))
	end

	check("filesystem detected", env.CanSave == true)
	check("clipboard detected", env.CanClipboard == true)
	check("http detected", env.CanFetch == true)

	if profile == "full" then
		check("executor identified", env.Executor == "SmokeMock", env.Executor)
		check("no thread identity offered", env.Identity == nil, env.Identity)
		check("no gui protection offered", env.CanProtect == false)
		check("gethui absent", not has(capabilities, "gethui"))
		check("protect_gui absent", not has(capabilities, "protect_gui"))
	elseif profile == "aliases" then
		check("executor identified by its alias", env.Executor == "AliasMock", env.Executor)
		check("thread identity read by its alias", env.Identity == 3, env.Identity)
		check("protection found by its alias", env.CanProtect == true)
		check("gethui found", has(capabilities, "gethui"))
		check("protect_gui found by its alias", has(capabilities, "protect_gui"))
	elseif profile == "locked" then
		check("executor identified", env.Executor == "LockedMock", env.Executor)
		check("gethui found", has(capabilities, "gethui"))
		check("protect_gui found", has(capabilities, "protect_gui"))
	end
end)

group("mounting", function()
	local window, tab = build()

	check("window built under this profile", window.Panel ~= nil)
	check("screen parented somewhere", window.Screen.Parent ~= nil)
	check("theme applied", window.Theme.Name == "Nice")
	check("tab registered", #window.Tabs == 1, #window.Tabs)
	check("element registered", #tab.Elements == 1, #tab.Elements)
	check("element reads its default", window:GetFlag("envToggle") == true)

	if profile == "bare" then
		check("gui resolved to PlayerGui", env.Gui == playerGui())
		check("screen fell back to PlayerGui", window.Screen.Parent == playerGui())
	elseif profile == "aliases" then
		check("gui resolved to the hidden container", env.Gui == gethui())
		check("screen parented to the hidden container", window.Screen.Parent == gethui())
	elseif profile == "locked" then
		check("gui resolved to the hidden container", env.Gui.Name == "HiddenUI", env.Gui.Name)
		check("gui is not the PlayerGui", env.Gui ~= playerGui())
		check("screen walked past the locked container", window.Screen.Parent == playerGui())
		check("screen is not on the hidden container", window.Screen.Parent ~= env.Gui)
	else
		check("gui resolved to PlayerGui", env.Gui:IsA("PlayerGui"))
		check("screen parented to Env.Gui", window.Screen.Parent == env.Gui)
	end

	window:SetFlag("envToggle", false)
	check("element driven by flag", window:GetFlag("envToggle") == false)
	window:Destroy()
end)

group("files and fetch", function()
	local window = Loom:CreateWindow({ Name = "Env" })
	local path = window:SaveConfig("env")
	local started = __httpGetCalls
	local body = env.Fetch("u")

	if profile == "bare" then
		check("SaveConfig refuses without a filesystem", path == nil, path)
		check("Read finds nothing", env.Read("Loom/env.json") == nil)
		check("Files finds nothing", #env.Files("Loom") == 0)
		check("fetch fell back to game:HttpGet", body == "httpget:u", body)
		check("HttpGet was used", __httpGetCalls == started + 1, __httpGetCalls)

		local ok = pcall(function()
			env.Copy("x")
		end)
		check("Copy without a clipboard does not throw", ok)

		window:Destroy()
		return
	end

	check("fetch used the executor request", body == "request:u", body)
	check("HttpGet untouched while request works", __httpGetCalls == started, __httpGetCalls)
	check("SaveConfig returns a path", type(path) == "string", path)
	check("config readable back", path ~= nil and type(env.Read(path)) == "string", path)
	check("config listed on disk", path ~= nil and has(env.Files("Loom"), path), path)

	env.Copy("clip")
	check("clipboard written through Copy", __clipboard == "clip", __clipboard)

	window:Destroy()
end)

group("single instance", function()
	local first = Loom:CreateWindow({ Name = "First" })
	local second = Loom:CreateWindow({ Name = "Second" })

	check("second window registered in the shared env", env.shared().Loom == second)
	check("first window torn down by the second", first.Screen.Parent == nil)

	if getgenv ~= nil then
		check("published to the executor globals", getgenv().Loom == second)
	end

	second:Destroy()
	check("registration cleared on destroy", env.shared().Loom == nil)

	local ok = pcall(function()
		second:Destroy()
	end)
	check("destroy is idempotent", ok)
end)

print(string.format("SMOKE-ENV (%s): %d passed, %d failed", profile, passes, failures))
if failures > 0 then
	error("smoke-env: " .. failures .. " check(s) failed", 0)
end
print("SMOKE-ENV OK")
