game:GetService("ReplicatedStorage")

local ParallelModuleLoader = require(script.Parent:WaitForChild("ParallelModuleLoader"))

local parent = script.Parent

parent:BindToMessage("RequireModule", function(p)
	ParallelModuleLoader.onRequireModule(script, p)
end)

parent:BindToMessage("InitModule", function()
	ParallelModuleLoader.onInitModule(script)
end)

parent:BindToMessage("StartModule", function()
	ParallelModuleLoader.onStartModule(script)
end)

script:SetAttribute("Loaded", true)