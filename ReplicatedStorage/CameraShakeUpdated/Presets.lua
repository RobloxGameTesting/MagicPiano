local parentModule = require(script.Parent)

local v = 0
return {
	Vibration = function()
		local now = os.clock()

		if now - v < 0.1 then
			return
		end

		v = now

		task.spawn(parentModule.new, 0.25, 1, 1, Vector3.new(1, 1, 1), Vector3.new(0, 0, 0), 0.02)
	end
}