local require = require
local v = nil
local ParallelModuleLoader = {}

function ParallelModuleLoader.onRequireModule(instance, moduleScript)
	local success, result = pcall(function()
		return require(moduleScript)
	end)

	if success then
		v = result
	else
		warn("Parallel module errored!\n", result)
		instance:SetAttribute("Errored", true)
	end

	instance:SetAttribute("Required", true)
end

function ParallelModuleLoader.onInitModule(instance)
	if instance:GetAttribute("Errored") then
		warn("Unable to init errored module!")
		instance:SetAttribute("Initialized", true)
	elseif v then
		if not v.Init then
			instance:SetAttribute("Initialized", true)
			return
		end

		local success, result = pcall(function()
			v:Init()
		end)

		if success then
			instance:SetAttribute("Initialized", true)
			return
		end

		warn("Parallel module errored!\n", result)
		instance:SetAttribute("Errored", true)
		instance:SetAttribute("Initialized", true)
	else
		warn("Told to load module that does not exist!")
		instance:SetAttribute("Initialized", true)
	end
end

function ParallelModuleLoader.onStartModule(instance)
	if instance:GetAttribute("Errored") then
		warn("Unable to start errored module!")
		instance:SetAttribute("Started", true)
	elseif v then
		if not v.Start then
			instance:SetAttribute("Started", true)
			return
		end

		local success, result = pcall(function()
			v:Start()
		end)

		if success then
			instance:SetAttribute("Started", true)
			return
		end

		warn("Parallel module errored!\n", result)
		instance:SetAttribute("Errored", true)
		instance:SetAttribute("Started", true)
	else
		warn("Told to start module that does not exist!")
		instance:SetAttribute("Started", true)
	end
end

return ParallelModuleLoader