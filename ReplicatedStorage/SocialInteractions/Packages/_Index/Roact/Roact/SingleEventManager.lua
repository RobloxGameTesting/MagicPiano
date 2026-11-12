local Logging = require(script.Parent.Logging)

local _ = { Disabled = "Disabled", Suspended = "Suspended", Enabled = "Enabled" }

local SingleEventManager = {}
SingleEventManager.__index = SingleEventManager

function SingleEventManager.new(instance)
	return (setmetatable({
		_suspendedEventQueue = {},
		_connections = {},
		_listeners = {},
		_status = "Disabled",
		_isResuming = false,
		_instance = instance
	}, SingleEventManager))
end

function SingleEventManager:connectEvent(p, p2)
	self:_connect(p, self._instance[p], p2)
end

function SingleEventManager:connectPropertyChange(propertyName, p)
	local success, result = pcall(function()
		return self._instance:GetPropertyChangedSignal(propertyName)
	end)

	if not success then
		error(("Cannot get changed signal on property %q: %s"):format(tostring(propertyName), result), 0)
	end

	self:_connect("Change." .. propertyName, result, p)
end

function SingleEventManager:_connect(p, object, p2)
	if p2 == nil then
		if self._connections[p] ~= nil then
			self._connections[p]:Disconnect()
			self._connections[p] = nil
		end

		self._listeners[p] = nil
	else
		if self._connections[p] == nil then
			self._connections[p] = object:Connect(function(...)
				if self._status == "Enabled" then
					self._listeners[p](self._instance, ...)
				elseif self._status == "Suspended" then
					local v = select("#", ...)
					table.insert(self._suspendedEventQueue, { p, v, ... })
				end
			end)
		end

		self._listeners[p] = p2
	end
end

function SingleEventManager:suspend()
	self._status = "Suspended"
end

function SingleEventManager:resume()
	if self._isResuming then
		return
	end

	self._isResuming = true
	local v = 1

	while v <= #self._suspendedEventQueue do
		local v2 = self._suspendedEventQueue[v]
		local listener = self._listeners[v2[1]]
		local v3 = v2[2]

		if listener ~= nil then
			local thread = coroutine.create(listener)
			local v4, v5 = coroutine.resume(thread, self._instance, unpack(v2, 3, 2 + v3))

			if not v4 then
				Logging.warn("%s", v5)
			end
		end

		v += 1
	end

	self._isResuming = false
	self._status = "Enabled"
	self._suspendedEventQueue = {}
end

return SingleEventManager