local Symbol = require(script.Parent.Symbol)

local named = Symbol.named("Nil")
local v = {}

local function getDefaultInstanceProperty(className, p)
	local v2 = v[className]

	if v2 then
		local v3 = v2[p]

		if v3 == named then
			return true, nil
		end

		if v3 ~= nil then
			return true, v3
		end
	else
		v2 = {}
		v[className] = v2
	end

	local instance = Instance.new(className)
	local success, result = pcall(function()
		return instance[p]
	end)

	instance:Destroy()

	if not success then
		return success, result
	end

	if result == nil then
		v2[p] = named
		return success, nil
	end

	v2[p] = result

	return success, result
end

return getDefaultInstanceProperty