local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = require(ReplicatedStorage.src.Client.Services.PlayerService)

local v = false

local function setSprinting(flag: boolean)
	local humanoid = PlayerService.Humanoid()

	if not humanoid or humanoid.WalkSpeed == 0 then
		return
	end

	v = flag
	humanoid.WalkSpeed = flag and 27 or 16
end

local Sprint = {
	Toggle = function()
		local v2 = not v
		local humanoid = PlayerService.Humanoid()

		if humanoid then
			if humanoid.WalkSpeed == 0 then
				return
			end

			v = v2
			humanoid.WalkSpeed = v2 and 27 or 16
		end
	end
}

PlayerService.CharacterReady():Connect(function()
	local humanoid = PlayerService.Humanoid()

	if humanoid then
		if humanoid.WalkSpeed == 0 then
			return
		end

		v = false
		humanoid.WalkSpeed = 16
	end
end)

return Sprint