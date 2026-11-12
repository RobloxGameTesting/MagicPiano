local RunService = game:GetService("RunService")

local createConfiguration = require(script.Parent.createConfiguration)
return (createConfiguration(RunService, script.Parent.serverConfigChanged, script.Parent.serverConfigRequested))