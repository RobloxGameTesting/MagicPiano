local SocialInteractions = script:FindFirstAncestor("SocialInteractions")

local Players = game:GetService("Players")

local OrientableBody = require(SocialInteractions.Modules.OrientableBody)

local v = {}
local v2 = {}
local v3 = {}
local playerAddedConnection = nil
local playerRemovingConnection = nil
local flag = false

local function onCharacterAdded(player, character) -- 2 equivalent calls inferred from this helper
	local v4 = OrientableBody.new(character)
	v[player] = v4

	if character == Players.LocalPlayer.Character then
		v4:useCameraAsSource()
	else
		v4:useAttributeAsSource()
	end
end

local function onPlayerEntered(child)
	if child.Character then
		onCharacterAdded(child, child.Character) -- inferred equivalent call
	end

	v2[child] = child.CharacterAdded:Connect(function(character)
		onCharacterAdded(child, character) -- inferred equivalent call
	end)

	v3[child] = child.CharacterRemoving:Connect(function()
		if v[child] then
			v[child]:destroy()
			v[child] = nil
		end
	end)
end

local function onPlayerRemoving(child) -- 1 equivalent call inferred from this helper
	if v[child] then
		v[child]:destroy()
		v[child] = nil
	end

	if v2[child] then
		v2[child]:Disconnect()
		v2[child] = nil
	end

	if v3[child] then
		v3[child]:Disconnect()
		v3[child] = nil
	end
end

local BodyOrientation = {}

function BodyOrientation.enable()
	if flag then
		return
	end

	playerRemovingConnection = Players.PlayerRemoving:Connect(onPlayerRemoving)
	playerAddedConnection = Players.PlayerAdded:Connect(onPlayerEntered)

	for _, child in ipairs(Players:GetChildren()) do
		onPlayerEntered(child)
	end

	flag = true
end

function BodyOrientation.disable()
	if not flag then
		return
	end

	playerAddedConnection:Disconnect()
	playerRemovingConnection:Disconnect()

	for _, child in ipairs(Players:GetChildren()) do
		onPlayerRemoving(child) -- inferred equivalent call
	end

	flag = false
end

return BodyOrientation