local v = {
	internalTypeChecks = false,
	typeChecks = false,
	elementTracing = false,
	propValidation = false
}

local v2 = {}

for k in pairs(v) do
	table.insert(v2, k)
end

local Config = {}

function Config.new()
	local v3 = {}

	v3._currentConfig = setmetatable({}, {
		__index = function(_, p)
			local formatted = ("Invalid global configuration key %q. Valid configuration keys are: %s"):format(
				tostring(p),
				table.concat(v2, ", ")
			)

			error(formatted, 3)
		end
	})

	function v3.set(...)
		return Config.set(v3, ...)
	end

	function v3.get(...)
		return Config.get(v3, ...)
	end

	function v3.scoped(...)
		return Config.scoped(v3, ...)
	end

	v3.set(v)

	return v3
end

function Config:set(items)
	for k, item in pairs(items) do
		if v[k] == nil then
			local formatted = ("Invalid global configuration key %q (type %s). Valid configuration keys are: %s"):format(
				tostring(k),
				typeof(k),
				table.concat(v2, ", ")
			)

			error(formatted, 3)
		end

		if typeof(item) ~= "boolean" then
			local formatted = ("Invalid value %q (type %s) for global configuration key %q. Valid values are: true, false"):format(
				tostring(item),
				typeof(item),
				(tostring(k))
			)

			error(formatted, 3)
		end

		self._currentConfig[k] = item
	end
end

function Config:get()
	return self._currentConfig
end

function Config:scoped(p, callback)
	local v3 = {}

	for k, v4 in pairs(self._currentConfig) do
		v3[k] = v4
	end

	self.set(p)

	local success, result = pcall(callback)

	self.set(v3)

	assert(success, result)
end

return Config