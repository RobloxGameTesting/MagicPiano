local Binding = require(script.Parent.Binding)

local function createRef()
	local v, _ = Binding.create(nil)

	local ref = {}

	setmetatable(ref, {
		__index = function(_, p)
			if p == "current" then
				return v:getValue()
			end

			return v[p]
		end,
		__newindex = function(_, p, p2)
			if p == "current" then
				error("Cannot assign to the 'current' property of refs", 2)
			end

			v[p] = p2
		end,
		__tostring = function(_)
			return ("RoactRef(%s)"):format((tostring(v:getValue())))
		end
	})

	return ref
end

return createRef