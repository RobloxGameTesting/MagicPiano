local Type = require(script.Parent.Parent.Type)

local Change = {}

local v = {
	__tostring = function(p)
		return ("RoactHostChangeEvent(%s)"):format(p.name)
	end
}

setmetatable(Change, {
	__index = function(_, name)
		local v2 = { [Type] = Type.HostChangeEvent, name = name }

		setmetatable(v2, v)
		Change[name] = v2

		return v2
	end
})

return Change