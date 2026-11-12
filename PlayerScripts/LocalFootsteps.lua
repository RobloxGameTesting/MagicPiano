local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local footstepSounds = script:WaitForChild("FootstepSounds")
footstepSounds.Parent = SoundService
local FootstepSounds = SoundService:WaitForChild("FootstepSounds")

local LocalPlayer = Players.LocalPlayer

local v = nil
local humanoid = nil
local v2 = false
local v3 = nil

local function getMaterial() -- 1 equivalent call inferred from this helper
	local floorMaterial = humanoid.FloorMaterial
	return string.split(tostring(floorMaterial), "Enum.Material.")[2]
end

local function stopSounds()
	for _, sound in pairs(FootstepSounds:GetChildren()) do
		if sound:IsA("Sound") then
			sound.Playing = false
		end
	end
end

local function setupCharacter(instance)
	v = instance
	humanoid = instance:WaitForChild("Humanoid")
	instance:WaitForChild("HumanoidRootPart")

	v2 = false
	v3 = nil

	humanoid.Running:Connect(function(p)
		v2 = humanoid.WalkSpeed / 2 < p

		if not v2 then
			stopSounds()
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)

if LocalPlayer.Character then
	setupCharacter(LocalPlayer.Character)
else
	setupCharacter(LocalPlayer.CharacterAdded:Wait())
end

RunService.Heartbeat:Connect(function()
	if not (humanoid and humanoid.Parent) then
		return
	end

	if v2 then
		local material = getMaterial() -- inferred equivalent call
		local child = FootstepSounds:FindFirstChild(material)

		if material ~= v3 then
			local child2 = v3 and FootstepSounds:FindFirstChild(v3)

			if child2 then
				child2.Playing = false
			end

			if child then
				child.Playing = true
			end

			v3 = material
		end

		if child and child.Playing then
			child.PlaybackSpeed = humanoid.WalkSpeed / 14
		end
	else
		stopSounds()
		v3 = nil
	end
end)