game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local ParallelModuleLoader = script.ParallelModuleLoader
local ActorForServer = script:FindFirstChild("ActorForServer")
local ActorForClient = script:FindFirstChild("ActorForClient")
local isClient = RunService:IsClient()
local require = require
local loadedEvent

if isClient then
	loadedEvent = script:WaitForChild("LoadedEvent")
else
	loadedEvent = Instance.new("RemoteEvent")
	loadedEvent.Name = "LoadedEvent"
	loadedEvent.Parent = script
end

local v = false

local v2 = { Load = {}, Init = {}, Start = {} }

local v3 = { Load = {}, Init = {}, Start = {} }

local v4 = {
	FOLDER_SEARCH_DEPTH = script:GetAttribute("FolderSearchDepth"),
	YIELD_THRESHOLD = script:GetAttribute("YieldThreshold"),
	VERBOSE_LOADING = script:GetAttribute("VerboseLoading"),
	WAIT_FOR_SERVER = script:GetAttribute("ClientWaitForServer"),
	USE_COLLECTION_SERVICE = script:GetAttribute("UseCollectionService")
}
local v5 = isClient and "[C]" or "[S]"
local v6 = isClient and "Client" or "Server"
local parent2

if isClient then
	parent2 = Players.LocalPlayer.PlayerScripts
else
	parent2 = game:GetService("ServerScriptService")
end

local loaderTag = script:GetAttribute("LoaderTag")
local RELOCATED_MODULES

if RunService:IsServer() then
	RELOCATED_MODULES = Instance.new("Folder")
	RELOCATED_MODULES.Name = "RELOCATED_MODULES"
	RELOCATED_MODULES.Parent = ServerScriptService
else
	RELOCATED_MODULES = nil
end

local function waitForEither(attributeChangedSignal, propertyChangedSignal)
	local thread = coroutine.running()

	local connection = nil
	local connection2 = nil

	connection = attributeChangedSignal:Once(function(...)
		if connection == nil then
			return
		end

		connection:Disconnect()
		connection2:Disconnect()
		connection = nil
		connection2 = nil

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, true, ...)
		end
	end)

	connection2 = propertyChangedSignal:Once(function(...)
		if connection2 == nil then
			return
		end

		connection:Disconnect()
		connection2:Disconnect()
		connection = nil
		connection2 = nil

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread, false, ...)
		end
	end)

	return coroutine.yield()
end

local function copy(p, flag: boolean?) -- 2 equivalent calls inferred from this helper
	if not flag then
		return (table.clone(p))
	end

	local function deepCopy(items)
		assert(typeof(items) == "table", "Expected table for deepCopy!")

		local self = setmetatable({}, (getmetatable(items)))

		for k, item in items do
			if typeof(item) == "table" then
				self[k] = deepCopy(item)
			else
				self[k] = item
			end
		end

		return self
	end

	return (deepCopy(p))
end

local function reconcile(p, items)
	assert(type(p) == "table", "First argument must be a table")
	assert(type(items) == "table", "Second argument must be a table")

	local clone = table.clone(p)

	for k, item in items do
		local v7 = p[k]

		if v7 == nil then
			if type(item) == "table" then
				clone[k] = copy(item, true) -- inferred equivalent call
			else
				clone[k] = item
			end
		elseif type(v7) == "table" then
			if type(item) == "table" then
				clone[k] = reconcile(v7, item)
			else
				clone[k] = copy(v7, true) -- inferred equivalent call
			end
		end
	end

	return clone
end

local function mergeArrays(moduleScripts, list) -- 1 equivalent call inferred from this helper
	local v7 = #list
	local clone = table.clone(list)

	for i, item in ipairs(moduleScripts) do
		clone[v7 + i] = item
	end

	return clone
end

local function filter(allFromClass, fn)
	assert(type(allFromClass) == "table", "First argument must be a table")
	assert(type(fn) == "function", "Second argument must be a function")
	local result = table.create(#allFromClass)

	if #allFromClass > 0 then
		local count = 0

		for k, item in allFromClass do
			if not fn(item, k, allFromClass) then
				continue
			end

			count += 1
			result[count] = item
		end

		return result
	end

	for k, item in allFromClass do
		if fn(item, k, allFromClass) then
			result[k] = item
		end
	end

	return result
end

local function getDepthInHierarchy(p, p2)
	local count = 0

	while p and p ~= p2 do
		p = p.Parent
		count += 1
	end

	return not p and 0 or count
end

local function findAllFromClass(className: string, folder, FOLDER_SEARCH_DEPTH: number?)
	assert(className and (typeof)(className) == "string", "class is invalid or nil")
	assert(folder and typeof(folder) == "Instance", "searchIn is invalid or nil")

	local descendants = {}

	if FOLDER_SEARCH_DEPTH then
		for _, descendant in pairs(folder:GetDescendants()) do
			if not descendant:IsA(className) then
				continue
			end

			local v7 = descendant
			local count = 0

			while v7 and v7 ~= folder do
				v7 = v7.Parent
				count += 1
			end

			if (not v7 and 0 or count) <= FOLDER_SEARCH_DEPTH then
				table.insert(descendants, descendant)
			end
		end
	else
		for _, descendant in pairs(folder:GetDescendants()) do
			if descendant:IsA(className) then
				table.insert(descendants, descendant)
			end
		end
	end

	return descendants
end

local function keepModule(p, instance): boolean
	if
		instance:GetAttribute("ClientOnly") and RunService:IsServer()
		or instance:GetAttribute("ServerOnly") and RunService:IsClient()
	then
		return false
	end

	if instance:GetAttribute("IgnoreLoader") then
		return false
	end

	local parent = instance.Parent

	while parent do
		if parent == p then
			return true
		end

		if not parent:IsA("Folder") then
			return false
		end

		parent = parent.Parent
	end

	return false
end

local function newPrint(...)
	print(v5, ...)
end

local function newWarn(...)
	warn(v5, ...)
end

local function loadModule(module)
	local function attemptRelocate(instance)
		if RunService:IsClient() or not instance:GetAttribute("RelocateToServerScriptService") then
			return
		end

		if instance:IsDescendantOf(ServerScriptService) then
			warn(`RelocateToServerScriptService attribute is enabled on module '{instance:GetFullName()}' that's already in ServerScriptService`)

			return
		end

		local relocatedTemplate = script:FindFirstChild("RelocatedTemplate")
		assert(relocatedTemplate, "ModuleLoader missing RelocatedTemplate child")
		local clone = relocatedTemplate:Clone()
		clone.Name = instance.Name
		clone:SetAttribute("ServerOnly", true)
		clone.Parent = instance.Parent
		instance.Parent = RELOCATED_MODULES
	end

	if module:GetAttribute("Parallel") then
		local v7 = if isClient then ActorForClient else ActorForServer

		if v7 == nil then
			newWarn(`Parallel module {module.Name} requested but no Actor template is configured - loading normally`)
		else
			local clone = v7:Clone()
			local clone_2 = ParallelModuleLoader:Clone()
			clone_2.Parent = clone
			local baseScript = clone:FindFirstChildWhichIsA("BaseScript")

			baseScript.Enabled = true
			baseScript.Name = `Required{module.Name}`
			clone.Parent = parent2

			if not baseScript:GetAttribute("Loaded") then
				baseScript:GetAttributeChangedSignal("Loaded"):Wait()
			end

			clone:SendMessage("RequireModule", module)

			if v4.VERBOSE_LOADING then
				newPrint(("Loading PARALLEL module '%s'"):format(module.Name))
			end

			local now = tick()

			if not baseScript:GetAttribute("Required") then
				if RunService:IsServer() then
					newWarn(
						`[SECURITY] Module '{module.Name}' yielded during require()!\n`,
						"Modules with RelocateToServerScriptService may still be accessible to clients.\n",
						"Avoid yielding in module top-level code to ensure timely relocation."
					)
				end

				baseScript:GetAttributeChangedSignal("Required"):Wait()
			end

			local now2 = tick()

			if v4.VERBOSE_LOADING and not baseScript:GetAttribute("Errored") then
				newPrint(`>> Loaded PARALLEL module {module.Name}`, ("(took %.3f seconds)"):format(now2 - now))
			elseif baseScript:GetAttribute("Errored") then
				newWarn(`>> Failed to load PARALLEL module {module.Name}`, ("(took %.3f seconds)"):format(now2 - now))
			end

			attemptRelocate(module)

			v3.Load[module] = clone
			v2.Load[module] = true
			v2.Init[module] = true
			v2.Start[module] = true
			return
		end
	end

	if v4.VERBOSE_LOADING then
		newPrint(("Loading module '%s'"):format(module.Name))
	end

	local thread = coroutine.running()
	local lastTime = tick()
	local now = nil
	local v7 = false
	local v8 = ""
	local thread2 = task.spawn(function()
		debug.setmemorycategory(`Module::{module.Name}`)
		local success, result = xpcall(function()
			return require(module)
		end, debug.traceback)
		debug.resetmemorycategory()

		if success then
			v2.Load[module] = result

			if result.Init then
				v2.Init[module] = false
			end

			if result.Start then
				v2.Start[module] = false
			end

			v7 = true

			attemptRelocate(module)
		else
			v8 = result
		end

		now = tick()

		if coroutine.status(thread) == "suspended" then
			task.spawn(thread)
		end
	end)

	if not now then
		now = tick()
	end

	if coroutine.status(thread2) == "suspended" then
		if RunService:IsServer() then
			newWarn(
				`[SECURITY] Module '{module.Name}' yielded during require()!\n`,
				"Modules with RelocateToServerScriptService may still be accessible to clients.\n",
				"Avoid yielding in module top-level code to ensure timely relocation."
			)
		end

		local thread3 = task.spawn(function()
			task.wait(v4.YIELD_THRESHOLD)

			while true do
				if coroutine.status(thread2) == "suspended" then
					newWarn(
						`>> Loading Module '{module.Name}' is taking a while!`,
						("(%.3f seconds elapsed)"):format(tick() - lastTime)
					)
				end

				task.wait(5)
			end
		end)
		coroutine.yield()

		if coroutine.status(thread3) ~= "dead" then
			task.cancel(thread3)
		end
	end

	if v4.VERBOSE_LOADING and v7 then
		newPrint(`>> Loaded module {module.Name}`, ("(took %.3f seconds)"):format(now - lastTime))
	elseif not v7 then
		newWarn(`>> Failed to load module {module.Name}`, ("(took %.3f seconds)\n%s"):format(now - lastTime, v8))
	end
end

local function initializeModule(object, module)
	if v3.Load[module] then
		local baseScript = v3.Load[module]:FindFirstChildWhichIsA("BaseScript")
		v3.Load[module]:SendMessage("InitModule")

		if v4.VERBOSE_LOADING then
			newPrint(("Initializing PARALLEL module '%s'"):format(baseScript.Name))
		end

		local now = tick()

		if not baseScript:GetAttribute("Initialized") then
			baseScript:GetAttributeChangedSignal("Initialized"):Wait()
		end

		local now2 = tick()

		if v4.VERBOSE_LOADING and not baseScript:GetAttribute("Errored") then
			newPrint(`>> Initialized PARALLEL module {baseScript.Name}`, ("(took %.3f seconds)"):format(now2 - now))
		elseif baseScript:GetAttribute("Errored") then
			newWarn(`>> Failed to init PARALLEL module {baseScript.Name}`, ("(took %.3f seconds)"):format(now2 - now))
		end
	else
		if not object.Init then
			return
		end

		if v4.VERBOSE_LOADING then
			newPrint(("Initializing module '%s'"):format(module.Name))
		end

		local thread = coroutine.running()
		local lastTime = tick()
		local now = nil
		local v7 = false
		local v8 = ""
		local thread2 = task.spawn(function()
			local success, result = xpcall(function()
				object:Init()
			end, function(p)
				return `{p}\n{debug.traceback()}`
			end)

			v7 = success

			if success then
				v2.Init[module] = true
			else
				v8 = result
			end

			now = tick()

			if coroutine.status(thread) == "suspended" then
				task.spawn(thread)
			end
		end)

		if not now then
			now = tick()
		end

		if coroutine.status(thread2) == "suspended" then
			local thread3 = task.spawn(function()
				task.wait(v4.YIELD_THRESHOLD)

				while true do
					if coroutine.status(thread2) == "suspended" then
						newWarn(
							`>> :Init() for Module '{module.Name}' is taking a while!`,
							("(%.3f seconds elapsed)"):format(tick() - lastTime)
						)
					end

					task.wait(5)
				end
			end)
			coroutine.yield()

			if coroutine.status(thread3) ~= "dead" then
				task.cancel(thread3)
			end
		end

		if v4.VERBOSE_LOADING and v7 then
			newPrint(`>> Initialized module {module.Name}`, ("(took %.3f seconds)"):format(now - lastTime))
		elseif not v7 then
			newWarn(`>> Failed to init module {module.Name}`, ("(took %.3f seconds)\n%s"):format(now - lastTime, v8))
		end
	end
end

local function startModule(object, module)
	if v3.Load[module] then
		local baseScript = v3.Load[module]:FindFirstChildWhichIsA("BaseScript")
		v3.Load[module]:SendMessage("StartModule")

		if v4.VERBOSE_LOADING then
			newPrint(("Starting PARALLEL module '%s'"):format(baseScript.Name))
		end

		local now = tick()

		if not baseScript:GetAttribute("Started") then
			baseScript:GetAttributeChangedSignal("Started"):Wait()
		end

		local now2 = tick()

		if v4.VERBOSE_LOADING and not baseScript:GetAttribute("Errored") then
			newPrint(`>> Started PARALLEL module {baseScript.Name}`, ("(took %.3f seconds)"):format(now2 - now))
		elseif baseScript:GetAttribute("Errored") then
			newWarn(`>> Failed to start PARALLEL module {baseScript.Name}`, ("(took %.3f seconds)"):format(now2 - now))
		end
	else
		if not object.Start then
			return
		end

		if v4.VERBOSE_LOADING then
			newPrint(("Starting module '%s'"):format(module.Name))
		end

		local thread = coroutine.running()
		local lastTime = tick()
		local now = nil
		local v7 = false
		local v8 = ""
		local thread2 = task.spawn(function()
			local success, result = xpcall(function()
				object:Start()
			end, function(p)
				return `{p}\n{debug.traceback()}`
			end)

			v7 = success

			if success then
				v2.Start[module] = true
			else
				v8 = result
			end

			now = tick()

			if coroutine.status(thread) == "suspended" then
				task.spawn(thread)
			end
		end)

		if not now then
			now = tick()
		end

		if coroutine.status(thread2) == "suspended" then
			local thread3 = task.spawn(function()
				task.wait(v4.YIELD_THRESHOLD)

				while true do
					if coroutine.status(thread2) == "suspended" then
						newWarn(
							`>> :Start() for Module '{module.Name}' is taking a while!`,
							("(%.3f seconds elapsed)"):format(tick() - lastTime)
						)
					end

					task.wait(5)
				end
			end)
			coroutine.yield()

			if coroutine.status(thread3) ~= "dead" then
				task.cancel(thread3)
			end
		end

		if v4.VERBOSE_LOADING and v7 then
			newPrint(`>> Started module {module.Name}`, ("(took %.3f seconds)"):format(now - lastTime))
		elseif not v7 then
			newWarn(`>> Failed to start module {module.Name}`, ("(took %.3f seconds)\n%s"):format(now - lastTime, v8))
		end
	end
end

local function getModules(list)
	local moduleScripts = {}

	for _, item in ipairs(list) do
		moduleScripts = mergeArrays( -- inferred equivalent call
			moduleScripts,
			filter(findAllFromClass("ModuleScript", item, v4.FOLDER_SEARCH_DEPTH), function(p)
				return keepModule(item, p)
			end)
		)
	end

	if v4.USE_COLLECTION_SERVICE and loaderTag ~= "" then
		for _, moduleScript in CollectionService:GetTagged(loaderTag) do
			if moduleScript:IsA("ModuleScript") then
				if keepModule(moduleScript.Parent, moduleScript) and not table.find(moduleScripts, moduleScript) then
					table.insert(moduleScripts, moduleScript)
				end
			else
				warn(`item: {moduleScript} with tag: {loaderTag} is not a module script!`)
			end
		end
	end

	table.sort(moduleScripts, function(a, b): boolean
		return (a:GetAttribute("LoaderPriority") or 0) > (b:GetAttribute("LoaderPriority") or 0)
	end)

	return moduleScripts
end

local function start(...)
	assert(not v, "attempt to start module loader more than once")
	v = true
	local v7 = { ... }

	if isClient and v4.WAIT_FOR_SERVER and not workspace:GetAttribute("ServerLoaded") then
		workspace:GetAttributeChangedSignal("ServerLoaded"):Wait()
	end

	if v4.VERBOSE_LOADING then
		newWarn("=== LOADING MODULES ===")
		local modules = getModules(v7)

		for _, module in modules do
			loadModule(module)
		end

		newWarn("=== INITIALIZING MODULES ===")

		for _, module in modules do
			if v2.Load[module] then
				initializeModule(v2.Load[module], module)
			end
		end

		newWarn("=== STARTING MODULES ===")

		for _, module in modules do
			if v2.Load[module] then
				startModule(v2.Load[module], module)
			end
		end

		newWarn("=== LOADING FINISHED ===")
	else
		local modules = getModules(v7)

		for _, module in modules do
			loadModule(module)
		end

		for _, module in modules do
			if v2.Load[module] then
				initializeModule(v2.Load[module], module)
			end
		end

		for _, module in modules do
			if v2.Load[module] then
				startModule(v2.Load[module], module)
			end
		end
	end

	workspace:SetAttribute(`{v6}LoadedTimestamp`, workspace:GetServerTimeNow())
	workspace:SetAttribute(`{v6}Loaded`, true)

	if RunService:IsClient() then
		loadedEvent:FireServer()
	end
end

local function startCustom(callback, ...)
	keepModule = callback
	start(...)
end

local function isClientLoaded(instance): boolean
	return instance:GetAttribute("_ModulesLoaded") == true
end

local function isServerLoaded(): boolean -- 1 equivalent call inferred from this helper
	return workspace:GetAttribute("ServerLoaded") == true
end

local function waitForLoadedClient(instance)
	if instance:GetAttribute("_ModulesLoaded") then
		return true
	end

	return waitForEither(
		instance:GetAttributeChangedSignal("_ModulesLoaded"),
		instance:GetPropertyChangedSignal("Parent")
	)
end

local function changeSettings(p)
	v4 = reconcile(p, v4)
end

local function getServerLoadedTimestamp()
	assert(isServerLoaded(), "server is not loaded yet!") -- inferred equivalent call
	return workspace:GetAttribute("ServerLoadedTimestamp")
end

if not isClient then
	loadedEvent.OnServerEvent:Connect(function(instance)
		instance:SetAttribute("_ModulesLoaded", true)
	end)
end

return {
	Start = start,
	StartCustom = startCustom,
	ChangeSettings = changeSettings,
	IsServerLoaded = isServerLoaded,
	IsClientLoaded = isClientLoaded,
	WaitForLoadedClient = waitForLoadedClient,
	GetServerLoadedTimestamp = getServerLoadedTimestamp
}