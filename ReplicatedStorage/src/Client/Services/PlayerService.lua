local PlayerService = {}

local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts")

local bindableEvent = Instance.new("BindableEvent")

local v = nil
local v2 = nil
local v3 = nil

local function clearCharacter(p)
	if v == p then
		v = nil
		v2 = nil
		v3 = nil
	end
end

local function setCharacter(instance)
	local humanoid = instance:WaitForChild("Humanoid", 10)

	local humanoidRootPart = instance:WaitForChild("HumanoidRootPart", 10)

	if LocalPlayer.Character ~= instance then
		warn("PlayerService: Character was removed or replaced before it finished loading.")
		return
	end

	if not humanoid then
		warn("PlayerService: Timed out waiting for Humanoid.")
		return
	end

	if not humanoidRootPart then
		warn("PlayerService: Timed out waiting for HumanoidRootPart.")
		return
	end

	v = instance
	v2 = humanoid
	v3 = humanoidRootPart

	bindableEvent:Fire(instance)
end

if LocalPlayer.Character then
	task.spawn(setCharacter, LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(function(character)
	task.spawn(setCharacter, character)
end)

LocalPlayer.CharacterRemoving:Connect(clearCharacter)

local function waitForCharacter() -- 3 equivalent calls inferred from this helper
	if v then
		return v
	end

	while not v do
		bindableEvent.Event:Wait()
	end

	return v
end

function PlayerService.Player()
	return LocalPlayer
end

function PlayerService.Character()
	return waitForCharacter() -- inferred equivalent call
end

function PlayerService.Humanoid()
	waitForCharacter() -- inferred equivalent call
	return v2
end

function PlayerService.HRP()
	waitForCharacter() -- inferred equivalent call
	return v3
end

function PlayerService.PlayerGui()
	return PlayerGui
end

function PlayerService.PlayerScripts()
	return PlayerScripts
end

function PlayerService.Health()
	local humanoid = PlayerService.Humanoid()

	return if humanoid then humanoid.Health else nil
end

function PlayerService.WalkSpeed()
	local humanoid = PlayerService.Humanoid()

	return if humanoid then humanoid.WalkSpeed else nil
end

function PlayerService.Position()
	local hrp = PlayerService.HRP()

	return if hrp then hrp.Position else nil
end

function PlayerService.CFrame()
	local hrp = PlayerService.HRP()

	return if hrp then hrp.CFrame else nil
end

function PlayerService.Mouse()
	return LocalPlayer:GetMouse()
end

function PlayerService.CharacterReady()
	return bindableEvent.Event
end

return PlayerService