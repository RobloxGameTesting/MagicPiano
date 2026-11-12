local assign = require(script.Parent.assign)
local None = require(script.Parent.None)
local Ref = require(script.Parent.PropMarkers.Ref)

local GlobalConfig = require(script.Parent.GlobalConfig)
local v = GlobalConfig.get()

local v2 = { [Ref] = None }

local function forwardRef(callback)
	if v.typeChecks then
		assert(typeof(callback) == "function", "Expected arg #1 to be a function")
	end

	return function(p)
		local v3 = p[Ref]
		return callback(assign({}, p, v2), v3)
	end
end

return forwardRef