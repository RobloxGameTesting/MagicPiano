local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
game:GetService("ContentProvider")

local ScreenTransition = require(game.ReplicatedStorage.ScreenTransition)
local LightingPresets = require(game.ReplicatedStorage.LightingPresets)
local LightingApplier = require(game.ReplicatedStorage.LightingApplier)
local Data = require(game.ReplicatedStorage.src.Shared.Data)
local client = Data.client
local CamDelay = require(game.ReplicatedStorage.src.Client.CamDelay)

local MapChangeClient = {}

local LocalPlayer = Players.LocalPlayer

local v = {}
local v2 = {}
local count = 0
local v3 = nil
local v4 = nil
local v5 = nil

local function findPortalEffect() -- 2 equivalent calls inferred from this helper
	local portalTransitionColorCorrection = Lighting:FindFirstChild("PortalTransitionColorCorrection")

	if portalTransitionColorCorrection and portalTransitionColorCorrection:IsA("ColorCorrectionEffect") then
		return portalTransitionColorCorrection
	end

	return nil
end

local function forceWhiteScreenOff() -- 2 equivalent calls inferred from this helper
	if v4 then
		v4:Cancel()
		v4 = nil
	end

	local portalEffect = findPortalEffect() -- inferred equivalent call

	if portalEffect then
		portalEffect:Destroy()
	end
end

local function cancelActiveTransition() -- 2 equivalent calls inferred from this helper
	local v6 = v3
	v3 = nil

	if v4 then
		v4:Cancel()
		v4 = nil
	end

	if v6 and v6.thread and coroutine.status(v6.thread) ~= "dead" then
		task.cancel(v6.thread)
	end
end

local function resetAllEffects()
	for _, v6 in v do
		for _, v7 in v6.sounds or {} do
			v7:Stop()
			v7:RemoveTag("AmbienceSound")
		end
	end

	for _, v6 in CollectionService:GetTagged("AmbienceSound") do
		v6:Stop()
		v6:RemoveTag("AmbienceSound")
	end

	for k, parent in v2 do
		local _, _ = pcall(function()
			k.Parent = parent
		end)

		v2[k] = nil
	end

	for _, v6 in v do
		for _, child in Lighting:GetChildren() do
			if child:GetAttribute(v6.attributeName) then
				child.Parent = v6.lightingFolder
			end
		end
	end

	pcall(function()
		LightingApplier.Apply(LightingPresets.Default)
	end)

	for _, child in Lighting:GetChildren() do
		if child:GetAttribute("DefaultLightingClone") then
			child:Destroy()
		end
	end

	local lobby = workspace:FindFirstChild("Lobby")
	local defaultLighting = lobby and lobby:FindFirstChild("DefaultLighting")

	if not defaultLighting then
		warn("[RESPAWN CLEANUP] DefaultLighting folder NOT FOUND")

		return
	end

	for _, child in defaultLighting:GetChildren() do
		local clone = child:Clone()
		clone:SetAttribute("DefaultLightingClone", true)
		clone.Parent = Lighting
	end
end

local function playFlash(data, p, p2)
	if not client.settings.portalTransitionEnabled() then
		return
	end

	local color = data.blackFade and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)

	local tween = ScreenTransition.tween(LocalPlayer.PlayerGui, p, p2, color)

	if not tween then
		return
	end

	v4 = tween

	local v6 = false

	local completedConnection = tween.Completed:Connect(function()
		v6 = true
	end)

	local v7 = os.clock() + p2 + 1

	while not v6 and os.clock() < v7 do
		task.wait()
	end

	completedConnection:Disconnect()

	if not v6 then
		tween:Cancel()
		local portalEffect = findPortalEffect() -- inferred equivalent call

		if portalEffect then
			if p >= 1 then
				portalEffect:Destroy()
			elseif p <= 0 then
				portalEffect.Brightness = color == Color3.new(0, 0, 0) and -1 or 1
				portalEffect.TintColor = color
			end
		end
	end

	if v4 == tween then
		v4 = nil
	end
end

local function waitForLiveCharacter()
	while true do
		local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid", 5)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)

		if character.Parent and humanoid and humanoidRootPart and humanoid.Health > 0 then
			return character, humanoidRootPart
		end

		LocalPlayer.CharacterAdded:Wait()
	end
end

local function teleportCharacter(cframe) -- 2 equivalent calls inferred from this helper
	local v6, v7 = waitForLiveCharacter()

	v6:PivotTo(cframe)
	v7.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
	v7.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
end

local function rotateCameraYaw(p) -- 2 equivalent calls inferred from this helper
	local currentCamera = workspace.CurrentCamera

	if not currentCamera then
		return
	end

	currentCamera.CFrame = CFrame.new(currentCamera.CFrame.Position) * CFrame.Angles(0, p, 0)
end

local function runEnterTransition(data)
	local lightingPreset = LightingPresets[data.lightingPreset]

	if not lightingPreset then
		error(("Unknown lighting preset: %s"):format((tostring(data.lightingPreset))))
	end

	playFlash(data, 0, 0.5)

	local success, result = pcall(function()
		LightingApplier.Apply(lightingPreset)
	end)

	if not success then
		error(result)
	end

	for _, child in Lighting:GetChildren() do
		local v6 = false

		for _, v7 in v do
			if child:GetAttribute(v7.attributeName) then
				v6 = true
				break
			end
		end

		if v6 or child.Name == "PortalTransitionColorCorrection" then
			continue
		end

		child:Destroy()
	end

	for _, child in data.lightingFolder:GetChildren() do
		v2[child] = data.lightingFolder
		child:SetAttribute(data.attributeName, true)
		child.Parent = Lighting
	end

	teleportCharacter(data.teleportCFrame) -- inferred equivalent call
	rotateCameraYaw(data.cameraAngle or 0) -- inferred equivalent call
	v5 = data

	if data.onEnter then
		data.onEnter()
	end

	for _, v6 in data.sounds or {} do
		v6:AddTag("AmbienceSound")

		if client.settings.ambienceEnabled() then
			v6:Play()
		end
	end

	task.wait(data.waitBeforeFadeOut or 0)
	playFlash(data, 1, data.fadeOutDuration or 0.1)
end

local function runTeleportBackTransition(data)
	playFlash(data, 0, 0.5)
	teleportCharacter(data.tpBackCFrame) -- inferred equivalent call

	if data.onExit then
		data.onExit()
	end

	if data.tpBackCameraAngle then
		rotateCameraYaw(data.tpBackCameraAngle) -- inferred equivalent call
	end

	v5 = nil
	resetAllEffects()

	task.wait(0.1)

	playFlash(data, 1, data.tpBackFadeOutDuration or 2)
end

local function beginTransition(configuration, shouldTeleportBack)
	count += 1

	local v6 = {
		identifier = count,
		configuration = configuration,
		shouldTeleportBack = shouldTeleportBack,
		thread = nil
	}

	v3 = v6
	CamDelay.SetEnabled(false)

	v6.thread = task.spawn(function()
		local success, result = pcall(function()
			if shouldTeleportBack then
				runTeleportBackTransition(configuration)
			else
				runEnterTransition(configuration)
			end
		end)

		if v3 ~= v6 then
			return
		end

		v3 = nil

		if not success then
			warn("[MapChangeClient] Map transition failed:", result)
		end

		CamDelay.SetEnabled(client.settings.cameraDelayEnabled())
		forceWhiteScreenOff() -- inferred equivalent call
	end)
end

local function handleCharacterAdded()
	cancelActiveTransition() -- inferred equivalent call
	forceWhiteScreenOff() -- inferred equivalent call
	resetAllEffects()

	if v5 then
		local v6 = v5
		v5 = nil

		if v6.onExit then
			v6.onExit()
		end
	end
end
LocalPlayer.CharacterAdded:Connect(handleCharacterAdded)

function MapChangeClient.Setup(p)
	table.insert(v, p)
	p.remoteEvent.OnClientEvent:Connect(function(p2)
		local v6 = p2 == true

		if v3 then
			if v3.configuration == p and v3.shouldTeleportBack == v6 then
				return
			end

			cancelActiveTransition() -- inferred equivalent call
		end

		beginTransition(p, v6)
	end)
end

return MapChangeClient