local None = require(script.Parent.None)

local function assign(p, ...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)

		if v == nil then
			continue
		end

		for k, v2 in pairs(v) do
			if v2 == None then
				p[k] = nil
			else
				p[k] = v2
			end
		end
	end

	return p
end

return assign