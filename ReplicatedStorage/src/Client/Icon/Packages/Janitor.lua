local RunService = game:GetService("RunService")
local Heartbeat = RunService.Heartbeat
local function getPromiseReference(): boolean -- 2 equivalent calls inferred from this helper
	return false
end

local v = newproxy(true)
getmetatable(v).__tostring = function(): string
	return "IndicesReference"
end

local v2 = newproxy(true)
getmetatable(v2).__tostring = function(): string
	return "LinkToInstanceIndex"
end

local Janitor = {
	IGNORE_MEMORY_DEBUG = true,
	ClassName = "Janitor",
	__index = { CurrentlyCleaning = true, [v] = nil }
}

local v3 = { ["function"] = true, Promise = "cancel", RBXScriptConnection = "Disconnect" }

function Janitor.new()
	return (setmetatable({ CurrentlyCleaning = false, [v] = nil }, Janitor))
end

function Janitor.Is(p): boolean
	return type(p) == "table" and getmetatable(p) == Janitor
end

Janitor.is = Janitor.Is

function Janitor.__index:Add(callback, p, p2)
	if p2 then
		self:Remove(p2)

		local callbacks = self[v]

		if not callbacks then
			callbacks = {}
			self[v] = callbacks
		end

		callbacks[p2] = callback
	end

	local typeName = typeof(callback)
	local v4 = typeName == "table" and string.match(tostring(callback), "Promise") and "Promise" or typeName

	local v5 = p or v3[v4] or "Destroy"

	if type(callback) ~= "function" and not callback[v5] then
		warn(string.format(
			"Object %s doesn't have method %s, are you sure you want to add it? Traceback: %s",
			tostring(callback),
			tostring(v5),
			debug.traceback(nil, 2)
		))
	end

	self[callback] = { v5, (debug.traceback("")) }
	return callback
end

Janitor.__index.Give = Janitor.__index.Add

function Janitor.__index.AddPromise(_, p)
	local _promiseReference = getPromiseReference() -- inferred equivalent call
	return p
end

Janitor.__index.GivePromise = Janitor.__index.AddPromise

function Janitor.__index:AddObject(object)
	local v4 = newproxy(false)
	local promiseReference = getPromiseReference() -- inferred equivalent call

	if not (promiseReference and promiseReference.is(object)) then
		return self:Add(object, false, v4), v4
	end

	if object:getStatus() ~= promiseReference.Status.Started then
		return object
	end

	local v5 = self:Add(promiseReference.resolve(object), "cancel", v4)
	v5:finallyCall(self.Remove, self, v4)
	return v5, v4
end

Janitor.__index.GiveObject = Janitor.__index.AddObject

function Janitor.__index:Remove(p)
	local v4 = self[v]

	local v5 = v4 and v4[p]

	if not v5 then
		return self
	end

	local v6 = self[v5]
	local v7 = v6 and v6[1]

	if v7 then
		if v7 == true then
			v5()
		else
			local v8 = v5[v7]

			if v8 then
				v8(v5)
			end
		end

		self[v5] = nil
	end

	v4[p] = nil

	return self
end

function Janitor.__index.Get(p, p2)
	local v4 = p[v]

	if v4 then
		return v4[p2]
	end

	return nil
end

function Janitor.__index:Cleanup()
	if not self.CurrentlyCleaning then
		self.CurrentlyCleaning = nil

		for k, v4 in next, self do
			if k == v then
				continue
			end

			local typeName = type(k)

			if typeName == "string" or typeName == "number" then
				self[k] = nil
			else
				local v5 = v4[1]
				local v6 = v4[2]
				local function warnUser(p)
					local traceback = debug.traceback("", 3)

					warn("-------- Janitor Error --------" .. "\n" .. tostring(p) .. "\n" .. traceback .. "" .. v6)
				end

				if v5 == true then
					local success, result = pcall(k)

					if not success then
						local traceback = debug.traceback("", 3)

						warn("-------- Janitor Error --------" .. "\n" .. tostring(result) .. "\n" .. traceback .. "" .. v6)
					end
				else
					local v7 = k[v5]

					if v7 then
						local success, result = pcall(v7, k)
						local v8

						if typeof(k) == "Instance" then
							v8 = v7 == "Destroy"
						else
							v8 = false
						end

						if not (success or v8) then
							local traceback = debug.traceback("", 3)

							warn("-------- Janitor Error --------" .. "\n" .. tostring(result) .. "\n" .. traceback .. "" .. v6)
						end
					end
				end

				self[k] = nil
			end
		end

		local v4 = self[v]

		if v4 then
			for k in next, v4 do
				v4[k] = nil
			end

			self[v] = {}
		end

		self.CurrentlyCleaning = false
	end
end

Janitor.__index.Clean = Janitor.__index.Cleanup

function Janitor.__index:Destroy()
	self:Cleanup()
end

Janitor.__call = Janitor.__index.Cleanup

local v4 = { Connected = true }
v4.__index = v4
function v4:Disconnect()
	if self.Connected then
		self.Connected = false
		self.Connection:Disconnect()
	end
end

function v4.__tostring(p)
	return "Disconnect<" .. tostring(p.Connected) .. ">"
end

function Janitor.__index:LinkToInstance(instance, p)
	local ancestryChangedConnection = nil
	local v5 = p and newproxy(false) or v2
	local v6 = instance.Parent == nil
	local object = setmetatable({}, v4)

	local function ChangedFunction(_, parent) -- 1 equivalent call inferred from this helper
		if object.Connected then
			v6 = parent == nil

			if v6 then
				coroutine.wrap(function()
					Heartbeat:Wait()

					if not object.Connected then
						return
					end

					if not ancestryChangedConnection.Connected then
						self:Cleanup()
						return
					end

					while v6 and ancestryChangedConnection.Connected and object.Connected do
						Heartbeat:Wait()
					end

					if object.Connected and v6 then
						self:Cleanup()
					end
				end)()
			end
		end
	end

	ancestryChangedConnection = instance.AncestryChanged:Connect(ChangedFunction)
	object.Connection = ancestryChangedConnection

	if v6 then
		ChangedFunction(nil, instance.Parent) -- inferred equivalent call
	end

	return self:Add(object, "Disconnect", v5)
end

function Janitor.__index:LinkToInstances(...)
	local maid = Janitor.new()

	for _, v5 in ipairs({ ... }) do
		maid:Add(self:LinkToInstance(v5, true), "Disconnect")
	end

	return maid
end

for k, v5 in next, Janitor.__index do
	local v6 = string.sub(string.lower(k), 1, 1) .. string.sub(k, 2)
	Janitor.__index[v6] = v5
end

return Janitor