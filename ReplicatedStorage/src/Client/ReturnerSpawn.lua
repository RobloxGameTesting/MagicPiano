local module = require("../Shared/Data")
local client = module.client
local LocalPlayer = game.Players.LocalPlayer

local function spawnCharacter(character)
	if not client.hasSeenSecondCutscene() then
		return
	end

	local RunService = game:GetService("RunService")

	if RunService:IsStudio() then
		return
	end

	character:PivotTo(workspace.Lobby:WaitForChild("SpawnLocation2").CFrame)
end

return {
	Init = function()
		LocalPlayer.CharacterAdded:Connect(spawnCharacter)

		if LocalPlayer.Character then
			spawnCharacter(LocalPlayer.Character)
		end
	end
}