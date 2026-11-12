local module = require("../Shared/Data")
local client = module.client
local module2 = require("./MenuTopbar")
local ClientData = {}

function ClientData.Init() end

function ClientData.Start()
	module2.ChimesIcon:setLabel((tostring(client.chimes())))
	client.chimes.Changed(function(p)
		module2.ChimesIcon:setLabel((tostring(p)))
	end)
end

return ClientData