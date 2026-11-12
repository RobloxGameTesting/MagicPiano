local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UnreliableUpdateTorso = ReplicatedStorage.Remotes:WaitForChild("UnreliableUpdateTorso")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local rad = math.rad
local asin = math.asin
local clamp = math.clamp
local Angles = CFrame.Angles
local atan2 = math.atan2

local function setRotation(data, p, p2)
	if data.neck then
		local neck = data.neck

		if data.isR6 then
			neck.Transform = Angles(-p * 0.75, 0, p2 * 0.75)
		else
			neck.Transform = Angles(p * 0.75, p2 * 0.75, 0)
		end
	end

	if data.waist then
		local transform = data.waist.Transform
		data.waist.Transform = transform * Angles(p * 0.25, p2 * 0.25, 0)
	end
end

local v = nil
local v2 = {}

local function findJoint(folder, p)
	for _, descendant in folder:GetDescendants() do
		if
			descendant.Name == p
			and not descendant:FindFirstAncestorOfClass("Accessory")
			and (descendant:IsA("Motor6D") or descendant:IsA("AnimationConstraint"))
		then
			return descendant
		end
	end

	return nil
end

local function setupCharacter(instance)
	local humanoid = instance:WaitForChild("Humanoid")
	local humanoidRootPart = instance:WaitForChild("HumanoidRootPart")
	return humanoidRootPart, {
		neck = findJoint(instance, "Neck"),
		waist = findJoint(instance, "Waist"),
		root = humanoidRootPart,
		isR6 = humanoid.RigType == Enum.HumanoidRigType.R6
	}
end

local function setupOtherPlr(player)
	if player == Players.LocalPlayer then
		return
	end

	local function setupOtherChar(instance)
		local humanoid = instance:WaitForChild("Humanoid", 5)
		local humanoidRootPart = instance:WaitForChild("HumanoidRootPart", 5)

		if not humanoid or not humanoidRootPart or instance.Parent == nil then
			return
		end

		v2[player] = {
			neck = findJoint(instance, "Neck"),
			waist = findJoint(instance, "Waist"),
			root = humanoidRootPart,
			isR6 = humanoid.RigType == Enum.HumanoidRigType.R6
		}
	end

	if player.Character then
		task.spawn(setupOtherChar, player.Character)
	end

	player.CharacterAdded:Connect(setupOtherChar)
	player.CharacterRemoving:Connect(function()
		v2[player] = nil
	end)
end

return {
	Init = function()
		local module = require("../../Shared/Data")
		local client = module.client
		local v3 = client.settings.headTurnEnabled()
		local v4 = v3
		client.settings.headTurnEnabled.Changed(function(p)
			v3 = p
		end)

		local v5 = nil
		local humanoid = nil
		local function setupLocal(instance)
			v5, v = setupCharacter(instance)
			humanoid = instance:WaitForChild("Humanoid")
		end

		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		v5, v = setupCharacter(character)
		humanoid = character:WaitForChild("Humanoid")

		LocalPlayer.CharacterAdded:Connect(setupLocal)

		local total = 0
		local total2 = 0
		local total3 = 0

		local v6 = false
		RunService.PreSimulation:Connect(function(dt)
			if not (humanoid and v5) then
				return
			end

			local v7 = 1 - math.exp(-12 * dt)

			for _, v8 in v2 do
				if not v8.pitch then
					continue
				end

				local parent = v8.root.Parent

				if not parent then
					continue
				end

				local humanoid2 = parent:FindFirstChildOfClass("Humanoid")

				if humanoid2 and humanoid2.SeatPart and humanoid2.SeatPart.Name == "PianoSeat" then
					if not v8.wasSittingAtPiano then
						v8.currentPitch = 0
						v8.currentYaw = 0
						v8.pitch = 0
						v8.yaw = 0
						setRotation(v8, 0, 0)
						v8.wasSittingAtPiano = true
					end
				else
					v8.wasSittingAtPiano = false

					v8.currentPitch = v8.currentPitch or v8.pitch
					v8.currentYaw = v8.currentYaw or v8.yaw
					v8.currentPitch += (v8.pitch - v8.currentPitch) * v7
					v8.currentYaw += (v8.yaw - v8.currentYaw) * v7
					setRotation(v8, v8.currentPitch, v8.currentYaw)
				end
			end

			if humanoid.SeatPart and humanoid.SeatPart.Name == "PianoSeat" then
				if not v6 then
					setRotation(v, 0, 0)
					total2 = 0
					total3 = 0
					UnreliableUpdateTorso:FireServer(0, 0)
				end

				v6 = true
			else
				v6 = false

				if v3 then
					v4 = true

					local freecam = LocalPlayer.PlayerGui:FindFirstChild("Freecam")
					local localScript = freecam and freecam:FindFirstChildWhichIsA("LocalScript")
					local freecamEnabled = localScript and localScript:GetAttribute("FreecamEnabled")
					local v8 = (CurrentCamera.CFrame.Position - CurrentCamera.Focus.Position).Magnitude < 1
					local v9 = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
					local sit = humanoid.Sit

					if v8 or v9 then
						v9 = not (sit or freecamEnabled)
					end

					local v10 = humanoid.MoveDirection.Magnitude > 0
					humanoid.AutoRotate = not freecamEnabled and (v10 or not v9)
					local lookVector = v5.CFrame:ToObjectSpace(CurrentCamera.CFrame).LookVector
					local v11 = atan2(-lookVector.X, -lookVector.Z)

					if v9 and math.abs(v11) > 1.3962634015954636 then
						local v12 = v11 - clamp(v11, -1.3962634015954636, 1.3962634015954636)
						v5.CFrame *= Angles(0, v12, 0)
					end

					local lookVector2 = v5.CFrame:ToObjectSpace(CurrentCamera.CFrame).LookVector
					local v12 = clamp(-asin(lookVector2.X), -1.3962634015954636, 1.3962634015954636)
					local v13 = asin(lookVector2.Y)
					local v14

					if v13 < 0 then
						v14 = clamp(math.max(0, -v13 - 0.08726646259971647) / 1.4835298641951802, 0, 1) ^ 2 * -0.7853981633974483
					else
						v14 = clamp(v13, -0.08726646259971647, 0.7853981633974483)
					end

					local v15 = 1 - math.exp(-12 * dt)
					total2 += (v14 - total2) * v15
					total3 += (v12 - total3) * v15
					setRotation(v, total2, total3)
					total += dt

					if total >= 0.025 then
						total = 0

						if typeof(total2) ~= "number" or typeof(total3) ~= "number" then
							return
						end

						UnreliableUpdateTorso:FireServer(total2, total3)
					end
				else
					if not v4 then
						return
					end

					setRotation(v, 0, 0)
					total2 = 0
					total3 = 0
					UnreliableUpdateTorso:FireServer(0, 0)
					v4 = false
				end
			end
		end)

		for _, v7 in Players:GetPlayers() do
			setupOtherPlr(v7)
		end

		Players.PlayerAdded:Connect(setupOtherPlr)
		Players.PlayerRemoving:Connect(function(player)
			v2[player] = nil
		end)

		UnreliableUpdateTorso.OnClientEvent:Connect(function(p, pitch, yaw)
			local v7 = v2[p]

			if not v7 then
				return
			end

			v7.pitch = pitch
			v7.yaw = yaw
		end)
	end
}