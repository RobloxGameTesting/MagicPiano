local Type = require(script.Parent.Parent.Type)

local Event = {}

local v = {
	__tostring = function(p)
		return ("RoactHostEvent(%s)"):format(p.name)
	end
}

setmetatable(Event, {
	__index = function(_, name)
		local v2 = { [Type] = Type.HostEvent, name = name }

		setmetatable(v2, v)

		Event[name] = v2

		return v2
	end
})

return Event