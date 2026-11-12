local RunService = game:GetService("RunService")

local DataServiceClient = require(script.DataServiceClient)
local DataServiceServer = require(script.DataServiceServer)
require(script.DataServiceUtils)
require(script.Value)

return function(p)
	return {
		client = not RunService:IsClient() and {} or DataServiceClient:init(p.template),
		server = not RunService:IsServer() and {} or DataServiceServer:init(p)
	}
end