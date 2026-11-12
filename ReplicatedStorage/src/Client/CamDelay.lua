local CamDelay = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Data = require(game.ReplicatedStorage.src.Shared.Data)
local client = Data.client

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera

local total = 0

local v = nil
local v2 = Vector3.new(0, 0, 0)
local humanoidRootPart = nil

local v3 = nil
local cframe2 = nil
local v4 = Vector3.new(0, 0, 0)
local v5 = false

local v6 = client.settings.cameraDelayEnabled()

local function setCameraDelayEnabled(p) -- 5 equivalent calls inferred from this helper
	if v6 == p then
		return
	end

	v6 = p

	if p then
		v = humanoidRootPart and humanoidRootPart.Position or nil
		v2 = Vector3.new(0, 0, 0)
	end
end

client.settings.cameraDelayEnabled.Changed(function()
	setCameraDelayEnabled(client.settings.cameraDelayEnabled()) -- inferred equivalent call
end)

function CamDelay.SetCameraTarget(_, p)
	setCameraDelayEnabled(true) -- inferred equivalent call
	v3 = p
	cframe2 = CurrentCamera.CFrame
	v4 = Vector3.new(0, 0, 0)
	v5 = false
end

function CamDelay.ClearCameraTarget(_)
	v3 = nil
	v5 = true
	total = 0
	v4 = Vector3.new(0, 0, 0)

	v = humanoidRootPart and humanoidRootPart.Position or nil
	v2 = Vector3.new(0, 0, 0)

	setCameraDelayEnabled(client.settings.cameraDelayEnabled()) -- inferred equivalent call
end

local function onCharacterAdded(instance)
	v = nil
	v2 = Vector3.new(0, 0, 0)
	humanoidRootPart = instance:WaitForChild("HumanoidRootPart")
	setCameraDelayEnabled(client.settings.cameraDelayEnabled()) -- inferred equivalent call
end

local function onCharacterRemoving()
	humanoidRootPart = nil
	v = nil
	v2 = Vector3.new(0, 0, 0)
end

if LocalPlayer.Character then
	local character = LocalPlayer.Character
	v = nil
	v2 = Vector3.new(0, 0, 0)
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local cameraDelayEnabled = client.settings.cameraDelayEnabled()

	if v6 ~= cameraDelayEnabled then
		v6 = cameraDelayEnabled

		if cameraDelayEnabled then
			local v7

			if humanoidRootPart then
				v7 = humanoidRootPart.Position or nil
			end

			v = v7
			v2 = Vector3.new(0, 0, 0)
		end
	end
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving)

RunService:BindToRenderStep("CameraDelay", Enum.RenderPriority.Camera.Value + 1, function(p)
	if not (v6 and humanoidRootPart) then
		return
	end

	local cframe = CurrentCamera.CFrame

	local position = humanoidRootPart.Position

	if not v then
		v = position
	end

	v, v2 = TweenService:SmoothDamp(v, position, v2, 0.0925, nil, p)

	local v7 = cframe.Position - position
	local v8 = cframe - cframe.Position
	local v9 = v8.RightVector * 0
	local cframe3 = v8 + v + v7 + v9

	if v3 then
		cframe2, v4 = TweenService:SmoothDamp(cframe2 or cframe3, v3, v4, 1.5, nil, p)
		CurrentCamera.CFrame = cframe2
	else
		if not v5 then
			CurrentCamera.CFrame = cframe3
			return
		end

		total += p
		local v10 = math.min(total / 4, 1) * -0.9075 + 1

		cframe2, v4 = TweenService:SmoothDamp(cframe2 or CurrentCamera.CFrame, cframe3, v4, v10, nil, p)

		CurrentCamera.CFrame = cframe2

		if total >= 4 then
			v5 = false
			cframe2 = nil
			v4 = Vector3.new(0, 0, 0)
		end
	end
end)

function CamDelay.SetEnabled(p)
	setCameraDelayEnabled(p) -- inferred equivalent call
end

return CamDelay