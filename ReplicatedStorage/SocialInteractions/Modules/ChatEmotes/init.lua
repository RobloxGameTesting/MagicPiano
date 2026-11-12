local SocialInteractions = script:FindFirstAncestor("SocialInteractions")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Cryo = require(SocialInteractions.Packages.Cryo)
local t = require(SocialInteractions.Packages.t)
local config = require(SocialInteractions.config)
local events = require(SocialInteractions.events)

local DefaultChatSystemChatEvents = ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents", 5)
local onNewMessage = DefaultChatSystemChatEvents and DefaultChatSystemChatEvents:WaitForChild("OnNewMessage", 5)

local emotesList = require(script.emotesList)
local v = {}

local ChatEmotes = {}

local flag = false
local connection = nil
local characterAddedConnection = nil
local moveDirectionChangedConnection = nil
local jumpingConnection = nil
local track = nil
local random = Random.new()

local function stopCurrentTrack() -- 2 equivalent calls inferred from this helper
	if track then
		track:Stop()
		track = nil
	end
end

function ChatEmotes.messageMatchesTriggerWord(value: string, value2: string): boolean
	local v2 = " " .. string.lower(value) .. " "
	local v3 = "[%p%s]" .. string.lower(value2) .. "[%p%s]"
	return string.find(v2, v3) ~= nil
end

function ChatEmotes.getEmoteFromMessage(p: string)
	local v2

	if config.getValues().useDefaultTriggerWordsForChatEmotes then
		v2 = Cryo.Dictionary.join(emotesList, v)
	else
		v2 = v
	end

	local v3 = {}

	for _, v4 in pairs(v2) do
		if not (not v4.requiresOwnershipOf or v4.isOwned) then
			continue
		end

		for _, triggerWord in ipairs(v4.triggerWords) do
			if ChatEmotes.messageMatchesTriggerWord(p, triggerWord) then
				table.insert(v3, { animation = v4.animationId, triggerWord = triggerWord })
			end
		end
	end

	if #v3 == 0 then
		return nil
	end

	local v4 = v3[random:NextInteger(1, #v3)]
	return v4.animation, v4.triggerWord
end

function ChatEmotes.setTriggerWordsForChatAnimation(animationId: string, triggerWords)
	assert(t.string(animationId), "Bad argument #1 to ChatEmotes.setTriggerWordsForChatAnimation: expected a string")
	assert(
		t.array(t.string)(triggerWords),
		"Bad argument #2 to ChatEmotes.setTriggerWordsForChatAnimation: expected an array of strings"
	)

	v[animationId] = { animationId = animationId, triggerWords = triggerWords }
end

local function onChatted(message)
	local emoteFromMessage, v2 = ChatEmotes.getEmoteFromMessage(message)
	local humanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("Humanoid")
	local animator = humanoid and humanoid:FindFirstChild("Animator")

	if emoteFromMessage and animator then
		local animation = Instance.new("Animation")
		animation.AnimationId = emoteFromMessage
		stopCurrentTrack() -- inferred equivalent call
		track = animator:LoadAnimation(animation)

		if track then
			track.Priority = Enum.AnimationPriority.Action
			track:Play()
		end

		events.onChatAnimationPlayed:Fire(emoteFromMessage, v2)
	end
end

function ChatEmotes.enable()
	if flag then
		return
	end

	if onNewMessage then
		connection = onNewMessage.OnClientEvent:Connect(function(p)
			if p.SpeakerUserId ~= Players.LocalPlayer.UserId then
				return
			end

			onChatted(p.Message)
		end)
	else
		connection = Players.LocalPlayer.Chatted:Connect(onChatted)
	end

	local function onCharacterAdded(character) -- 1 equivalent call inferred from this helper
		local humanoid = character:WaitForChild("Humanoid")
		moveDirectionChangedConnection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(stopCurrentTrack)
		jumpingConnection = humanoid.Jumping:Connect(stopCurrentTrack)
	end

	if Players.LocalPlayer.Character then
		task.spawn(function()
			onCharacterAdded(Players.LocalPlayer.Character) -- inferred equivalent call
		end)
	end

	characterAddedConnection = Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

	task.spawn(function()
		for _, emote in pairs(emotesList) do
			if not emote.requiresOwnershipOf then
				continue
			end

			local success, result = pcall(function()
				return MarketplaceService:PlayerOwnsAsset(Players.LocalPlayer, emote.requiresOwnershipOf)
			end)

			if success then
				emote.isOwned = result
			else
				emote.isOwned = false
			end
		end
	end)

	flag = true
end

function ChatEmotes.disable()
	if not flag then
		return
	end

	stopCurrentTrack() -- inferred equivalent call

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if characterAddedConnection then
		characterAddedConnection:Disconnect()
		characterAddedConnection = nil
	end

	if moveDirectionChangedConnection then
		moveDirectionChangedConnection:Disconnect()
		moveDirectionChangedConnection = nil
	end

	if jumpingConnection then
		jumpingConnection:Disconnect()
		jumpingConnection = nil
	end

	flag = false
end

return ChatEmotes