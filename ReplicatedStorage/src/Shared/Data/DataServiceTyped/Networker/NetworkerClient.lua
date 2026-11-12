local RunService = game:GetService("RunService")

local parent = script.Parent.Parent
local Signal = require(parent.Signal)
local NetworkerUtils = require(script.Parent.NetworkerUtils)

local NetworkerClient = {}
NetworkerClient.__index = NetworkerClient

function NetworkerClient.new(instance, p)
	assert(RunService:IsClient(), "NetworkerClient can only be created on the client")

	local v = { networkTag = instance, changedSignals = {} }

	setmetatable(v, NetworkerClient)

	if not RunService:IsRunning() then
		return v
	end

	if typeof(instance) == "Instance" then
		local attribute = instance:GetAttribute(NetworkerUtils.INSTANCE_ATTRIBUTE)

		if not attribute then
			instance:GetAttributeChangedSignal(NetworkerUtils.INSTANCE_ATTRIBUTE):Wait()
			attribute = instance:GetAttribute(NetworkerUtils.INSTANCE_ATTRIBUTE)
		end

		assert(attribute, "NetworkerClient instance does not have a networkTag attribute")
		v.networkTag = attribute
	end

	local child = script.Parent:WaitForChild("_remotes"):WaitForChild(v.networkTag)
	v.remotes = child

	child.Destroying:Once(function()
		v:destroy()
	end)

	child.RemoteEvent.OnClientEvent:Connect(function(p2: string, p3: string, ...)
		if p2 == NetworkerUtils.SET_TAG then
			p[p3] = ...

			if v.changedSignals[p3] then
				v.changedSignals[p3]:Fire(p[p3])
			end
		else
			assert(p[p2], "Method " .. p2 .. " does not exist on networkTag " .. child.Name)
			p[p2](p, p3, ...)
		end
	end)

	return v
end

function NetworkerClient.getServerChangedSignal(p, p2: string)
	if not p.changedSignals[p2] then
		p.changedSignals[p2] = Signal.new()
	end

	return p.changedSignals[p2]
end

function NetworkerClient.fire(p, p2: string, ...)
	if RunService:IsRunning() then
		p.remotes.RemoteEvent:FireServer(p2, ...)
	end
end

function NetworkerClient.fetch(p, p2: string, ...)
	if RunService:IsRunning() then
		return p.remotes.RemoteFunction:InvokeServer(p2, ...)
	end

	return nil
end

function NetworkerClient:destroy()
	if self.remotes then
		self.remotes:Destroy()
	end

	for _, changedSignal in self.changedSignals do
		changedSignal:Destroy()
	end

	if self.instanceConn then
		self.instanceConn:Disconnect()
	end
end

return NetworkerClient