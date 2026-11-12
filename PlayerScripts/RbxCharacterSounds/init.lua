local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local AtomicBinding = require(script:WaitForChild("AtomicBinding"))

local function loadFlag(p: string) -- 4 equivalent calls inferred from this helper
	local success, result = pcall(function()
		return UserSettings():IsUserFeatureEnabled(p)
	end)

	return success and result
end

local flag2 = loadFlag("UserSoundsUseRelativeVelocity2") -- inferred equivalent call
local flag3 = loadFlag("UserNewCharacterSoundsApi3") -- inferred equivalent call
local flag4 = loadFlag("UserFixCharSoundsEmitters") -- inferred equivalent call
local flag5 = loadFlag("UserFixCharSoundsEmitterRootPart") -- inferred equivalent call
local v = {
	Climbing = { SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3", Looped = true },
	Died = { SoundId = "rbxasset://sounds/uuhhh.mp3" },
	FreeFalling = { SoundId = "rbxasset://sounds/action_falling.ogg", Looped = true },
	GettingUp = { SoundId = "rbxasset://sounds/action_get_up.mp3" },
	Jumping = { SoundId = "rbxasset://sounds/action_jump.mp3" },
	Landing = { SoundId = "rbxasset://sounds/action_jump_land.mp3" },
	Running = {
		SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
		Looped = true,
		Pitch = 1.85
	},
	Splash = { SoundId = "rbxasset://sounds/impact_water.mp3" },
	Swimming = { SoundId = "rbxasset://sounds/action_swim.mp3", Looped = true, Pitch = 1.6 }
}

local v2 = {
	Climbing = { AssetId = "rbxasset://sounds/action_footsteps_plastic.mp3", Looping = true },
	Died = { AssetId = "rbxasset://sounds/uuhhh.mp3" },
	FreeFalling = { AssetId = "rbxasset://sounds/action_falling.ogg", Looping = true },
	GettingUp = { AssetId = "rbxasset://sounds/action_get_up.mp3" },
	Jumping = { AssetId = "rbxasset://sounds/action_jump.mp3" },
	Landing = { AssetId = "rbxasset://sounds/action_jump_land.mp3" },
	Running = {
		AssetId = "rbxasset://sounds/action_footsteps_plastic.mp3",
		Looping = true,
		PlaybackSpeed = 1.85
	},
	Splash = { AssetId = "rbxasset://sounds/impact_water.mp3" },
	Swimming = {
		AssetId = "rbxasset://sounds/action_swim.mp3",
		Looping = true,
		PlaybackSpeed = 1.6
	}
}

local function map(y: number, p: number, p2: number, p3: number, p4: number) -- 2 equivalent calls inferred from this helper
	return (y - p) * (p4 - p3) / (p2 - p) + p3
end

local function getRelativeVelocity(controllerManager, p)
	if not controllerManager then
		return p
	end

	local groundSensor = controllerManager.ActiveController
		and (controllerManager.ActiveController:IsA("GroundController") and controllerManager.GroundSensor or controllerManager.ActiveController:IsA("ClimbController") and controllerManager.ClimbSensor)

	if groundSensor and groundSensor.SensedPart then
		return p - groundSensor.SensedPart:GetVelocityAtPosition(controllerManager.RootPart.Position)
	end

	return p
end

local function playSound(audioPlayer, flag: boolean?) -- 9 equivalent calls inferred from this helper
	if not flag then
		audioPlayer.TimePosition = 0
	end

	if flag3 and audioPlayer:IsA("AudioPlayer") then
		audioPlayer:Play()
	else
		audioPlayer.Playing = true
	end
end

local function stopSound(audioPlayer) -- 1 equivalent call inferred from this helper
	if flag3 and audioPlayer:IsA("AudioPlayer") then
		audioPlayer:Stop()
	else
		audioPlayer.Playing = false
	end
end

local function playSoundIf(audioPlayer, playing: boolean) -- 2 equivalent calls inferred from this helper
	if flag3 and audioPlayer:IsA("AudioPlayer") then
		if audioPlayer.IsPlaying and not playing then
			audioPlayer:Stop()
		elseif not audioPlayer.IsPlaying and playing then
			audioPlayer:Play()
		end
	else
		audioPlayer.Playing = playing
	end
end

local function setSoundLooped(audioPlayer, flag: boolean) -- 1 equivalent call inferred from this helper
	if flag3 and audioPlayer:IsA("AudioPlayer") then
		audioPlayer.Looping = flag
	else
		audioPlayer.Looped = flag
	end
end

local function shallowCopy(items)
	local result = {}

	for k, item in pairs(items) do
		result[k] = item
	end

	return result
end

local function initializeSoundSystem(p)
	local humanoid = p.humanoid
	local rootPart = p.rootPart
	local rbxCharacterSoundsEmitter = nil
	local controllerManager

	if flag2 then
		controllerManager = humanoid.Parent:FindFirstChild("ControllerManager")
	else
		controllerManager = nil
	end

	local v3 = {}

	if flag3 and SoundService.CharacterSoundsUseNewApi == Enum.RolloutState.Enabled then
		local character = nil
		local rootPart2 = nil

		if flag4 then
			if flag5 then
				rootPart2 = humanoid.RootPart or humanoid.Parent
			else
				rootPart2 = humanoid.RootPart
			end
		else
			character = Players.LocalPlayer.Character
		end

		local v4 = 5
		local v5 = {}

		while v4 < 150 do
			v5[v4] = 5 / v4
			v4 *= 1.25
		end

		v5[150] = 0

		if flag4 then
			rbxCharacterSoundsEmitter = Instance.new("AudioEmitter", rootPart2)
		else
			rbxCharacterSoundsEmitter = Instance.new("AudioEmitter", character)
		end

		rbxCharacterSoundsEmitter.Name = "RbxCharacterSoundsEmitter"
		rbxCharacterSoundsEmitter:SetDistanceAttenuation(v5)

		for k, v6 in pairs(v2) do
			local audioPlayer = Instance.new("AudioPlayer")
			local wire = Instance.new("Wire")
			audioPlayer.Name = k
			wire.Name = k .. "Wire"

			audioPlayer.Archivable = false
			audioPlayer.Volume = 0.65

			for k2, v7 in pairs(v6) do
				audioPlayer[k2] = v7
			end

			audioPlayer.Parent = rootPart
			wire.Parent = audioPlayer
			wire.SourceInstance = audioPlayer
			wire.TargetInstance = rbxCharacterSoundsEmitter
			v3[k] = audioPlayer
		end
	else
		for k, v4 in pairs(v) do
			local sound = Instance.new("Sound")
			sound.Name = k

			sound.Archivable = false
			sound.RollOffMinDistance = 5
			sound.RollOffMaxDistance = 150
			sound.Volume = 0.65

			for k2, v5 in pairs(v4) do
				sound[k2] = v5
			end

			sound.Parent = rootPart
			v3[k] = sound
		end
	end

	local v4 = {}

	local function stopPlayingLoopedSounds(p2)
		local v5 = {}
		local v6 = p2 or nil

		for k, v7 in pairs(v4) do
			v5[k] = v7
		end

		for k in pairs(v5) do
			if k == v6 then
				continue
			end

			stopSound(k) -- inferred equivalent call
			v4[k] = nil
		end
	end

	local v5 = {
		[Enum.HumanoidStateType.FallingDown] = function()
			stopPlayingLoopedSounds()
		end,
		[Enum.HumanoidStateType.GettingUp] = function()
			stopPlayingLoopedSounds()
			playSound(v3.GettingUp, false) -- inferred equivalent call
		end,
		[Enum.HumanoidStateType.Jumping] = function()
			stopPlayingLoopedSounds()
			playSound(v3.Jumping, false) -- inferred equivalent call
		end,
		[Enum.HumanoidStateType.Swimming] = function()
			local y = math.abs(rootPart.AssemblyLinearVelocity.Y)

			if y > 0.1 then
				v3.Splash.Volume = math.clamp(map(y, 100, 350, 0.28, 1), 0, 1) -- inferred equivalent call
				playSound(v3.Splash, false) -- inferred equivalent call
			end

			stopPlayingLoopedSounds(v3.Swimming)
			playSound(v3.Swimming, true) -- inferred equivalent call
			v4[v3.Swimming] = true
		end,
		[Enum.HumanoidStateType.Freefall] = function()
			v3.FreeFalling.Volume = 0
			stopPlayingLoopedSounds(v3.FreeFalling)

			setSoundLooped(v3.FreeFalling, true) -- inferred equivalent call

			if v3.FreeFalling:IsA("Sound") then
				v3.FreeFalling.PlaybackRegionsEnabled = true
			end

			v3.FreeFalling.LoopRegion = NumberRange.new(2, 9)
			playSound(v3.FreeFalling, false) -- inferred equivalent call

			v4[v3.FreeFalling] = true
		end,
		[Enum.HumanoidStateType.Landed] = function()
			stopPlayingLoopedSounds()
			local y = math.abs(rootPart.AssemblyLinearVelocity.Y)

			if y > 75 then
				v3.Landing.Volume = math.clamp(map(y, 50, 100, 0, 1), 0, 1) -- inferred equivalent call
				playSound(v3.Landing, false) -- inferred equivalent call
			end
		end,
		[Enum.HumanoidStateType.Running] = function()
			stopPlayingLoopedSounds(v3.Running)
			playSound(v3.Running, true) -- inferred equivalent call
			v4[v3.Running] = true
		end,
		[Enum.HumanoidStateType.Climbing] = function()
			local climbing = v3.Climbing
			local assemblyLinearVelocity = rootPart.AssemblyLinearVelocity

			if flag2 then
				assemblyLinearVelocity = getRelativeVelocity(controllerManager, assemblyLinearVelocity)
			end

			if math.abs(assemblyLinearVelocity.Y) > 0.1 then
				playSound(climbing, true) -- inferred equivalent call
				stopPlayingLoopedSounds(climbing)
			else
				stopPlayingLoopedSounds()
			end

			v4[climbing] = true
		end,
		[Enum.HumanoidStateType.Seated] = function()
			stopPlayingLoopedSounds()
		end,
		[Enum.HumanoidStateType.Dead] = function()
			stopPlayingLoopedSounds()
			playSound(v3.Died, false) -- inferred equivalent call
		end
	}

	local v6 = {
		[v3.Climbing] = function(_: number, audioPlayer, vector3: Vector3)
			if flag2 then
				vector3 = getRelativeVelocity(controllerManager, vector3)
			end

			playSoundIf(audioPlayer, vector3.Magnitude > 0.1) -- inferred equivalent call
		end,
		[v3.FreeFalling] = function(p2: number, p3, vector3: Vector3)
			if vector3.Magnitude > 75 then
				p3.Volume = math.clamp(p3.Volume + p2 * 0.9, 0, 1)
			else
				p3.Volume = 0
			end
		end,
		[v3.Running] = function(_: number, audioPlayer, vector3: Vector3)
			playSoundIf(audioPlayer, vector3.Magnitude > 0.5 and humanoid.MoveDirection.Magnitude > 0.5) -- inferred equivalent call
		end
	}

	local runningsByRunningNoPhysics = {
		[Enum.HumanoidStateType.RunningNoPhysics] = Enum.HumanoidStateType.Running
	}

	local v7 = runningsByRunningNoPhysics[humanoid:GetState()] or humanoid:GetState()

	local function transitionTo(p2) -- 2 equivalent calls inferred from this helper
		local v8 = v5[p2]

		if v8 then
			v8()
		end

		v7 = p2
	end

	transitionTo(v7) -- inferred equivalent call
	local stateChangedConnection = humanoid.StateChanged:Connect(function(_, p2)
		local v8 = runningsByRunningNoPhysics[p2] or p2

		if v8 ~= v7 then
			transitionTo(v8) -- inferred equivalent call
		end
	end)

	local steppedConnection = RunService.Stepped:Connect(function(_, dt: number)
		for k in pairs(v4) do
			local v8 = v6[k]

			if v8 then
				v8(dt, k, rootPart.AssemblyLinearVelocity)
			end
		end
	end)

	local function terminate()
		stateChangedConnection:Disconnect()
		steppedConnection:Disconnect()

		if flag5 and rbxCharacterSoundsEmitter then
			rbxCharacterSoundsEmitter:Destroy()
		end

		for _, v8 in pairs(v3) do
			v8:Destroy()
		end

		table.clear(v3)
	end

	return terminate
end

local v3 = AtomicBinding.new({ humanoid = "Humanoid", rootPart = "HumanoidRootPart" }, initializeSoundSystem)

local v4 = {}

local function characterAdded(character) -- 1 equivalent call inferred from this helper
	v3:bindRoot(character)
end

local function characterRemoving(character) -- 1 equivalent call inferred from this helper
	v3:unbindRoot(character)
end

local function playerAdded(player)
	local connections = v4[player]

	if not connections then
		connections = {}
		v4[player] = connections
	end

	if player.Character then
		characterAdded(player.Character) -- inferred equivalent call
	end

	table.insert(connections, player.CharacterAdded:Connect(characterAdded))
	table.insert(connections, player.CharacterRemoving:Connect(characterRemoving))
end

local function playerRemoving(player)
	local v5 = v4[player]

	if v5 then
		for _, connection in ipairs(v5) do
			connection:Disconnect()
		end

		v4[player] = nil
	end

	if player.Character then
		characterRemoving(player.Character) -- inferred equivalent call
	end
end

for _, v5 in ipairs(Players:GetPlayers()) do
	task.spawn(playerAdded, v5)
end

Players.PlayerAdded:Connect(playerAdded)
Players.PlayerRemoving:Connect(playerRemoving)