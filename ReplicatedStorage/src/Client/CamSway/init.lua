local CamSway = {}

local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local scriptSet = {}
local v = false

local function updateFreecamState()
	v = false

	for k in pairs(scriptSet) do
		if k:GetAttribute("FreecamEnabled") == true then
			v = true
			break
		end
	end
end

local function connectFreecam(screenGui)
	if not (screenGui:IsA("ScreenGui") and string.find(screenGui.Name, "Freecam")) then
		return
	end

	local function findScripts()
		for _, Script in ipairs(screenGui:GetDescendants()) do
			if not Script:IsA("LocalScript") or scriptSet[Script] then
				continue
			end

			scriptSet[Script] = true
			Script:GetAttributeChangedSignal("FreecamEnabled"):Connect(updateFreecamState)
		end

		updateFreecamState()
	end

	findScripts()
	screenGui.DescendantAdded:Connect(findScripts)
end

for _, child in ipairs(PlayerGui:GetChildren()) do
	connectFreecam(child)
end

PlayerGui.ChildAdded:Connect(connectFreecam)

function CamSway.Start()
	local module = require("../Shared/Data")
	local client = module.client
	local module2 = require("../Shared/TweakAttribute")
	local v2 = module2(script)
	local RunService = game:GetService("RunService")
	local Spring = require(script.Spring)
	local random = Random.new()

	local v3 = Spring.new(Vector3.new(0, 0, 0))
	v3.Speed = v2("PositionSpringSpeed", 1)
	v3.Damper = v2("PositionSpringDamper", 1)

	local v4 = Spring.new(Vector3.new(0, 0, 0))
	v4.Speed = v2("RotationSpringSpeed", 3)
	v4.Damper = v2("RotationSpringDamper", 1)

	local v5 = 0
	local flag = false

	RunService:UnbindFromRenderStep("CameraSway")
	RunService:BindToRenderStep("CameraSway", Enum.RenderPriority.Last.Value, function()
		if client.settings.cameraSwayEnabled() then
			flag = true

			v3.Speed = v2("PositionSpringSpeed", 1)
			v3.Damper = v2("PositionSpringDamper", 1)
			v4.Speed = v2("RotationSpringSpeed", 3)
			v4.Damper = v2("RotationSpringDamper", 1)

			local v6 = v2("PositionIntensity", 1.5)
			local v7 = v2("PositionDepthScale", 0.1)

			local v8 = v and v2("FreecamRotationIntensity", Vector3.new(0.03, 0.03, 0.03))
				or v2("RotationIntensity", Vector3.new(0.0001, 0.0001, 0.002))

			local v9 = v2("TargetIntervalMin", 0.25)
			local v10 = v2("TargetIntervalMax", 0.75)

			local now = os.clock()

			if v5 <= now then
				v5 = now + random:NextNumber(v9, v10)

				v3.Target = Vector3.new(
					random:NextNumber(-v6, v6),
					random:NextNumber(-v6, v6),
					random:NextNumber(-v6 * v7, v6 * v7)
				)

				v4.Target = Vector3.new(
					random:NextNumber(-v8.X, v8.X),
					random:NextNumber(-v8.Y, v8.Y),
					random:NextNumber(-v8.Z, v8.Z)
				)
			end

			local v11 = CFrame.new(v3.Position) * CFrame.Angles(v4.Position.X, v4.Position.Y, v4.Position.Z)

			local currentCamera = workspace.CurrentCamera

			if currentCamera then
				currentCamera.CFrame *= v11
			end
		elseif flag then
			v3.Position = Vector3.new(0, 0, 0)
			v3.Velocity = Vector3.new(0, 0, 0)
			v4.Position = Vector3.new(0, 0, 0)
			v4.Velocity = Vector3.new(0, 0, 0)
			flag = false
		end
	end)
end

return CamSway