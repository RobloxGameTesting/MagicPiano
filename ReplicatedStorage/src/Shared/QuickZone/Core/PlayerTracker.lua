local Players = game:GetService("Players")

require(script.Parent.Parent.Types)
local State = require(script.Parent.State)

local v = {}
local v2 = {}

local function trackPlayer(player)
	if v[player] then
		return
	end

	local childAddedConnection = nil
	local ancestryChangedConnection = nil
	local v3 = nil
	local v4 = nil

	local function clearHrp(p)
		if p and p ~= v4 then
			return
		end

		if ancestryChangedConnection then
			ancestryChangedConnection:Disconnect()
			ancestryChangedConnection = nil
		end

		if v4 then
			local v5 = v2[player]

			if v5 then
				for k, v6 in v5 do
					if State.groups[k] then
						v6:_remove(v4)
					else
						v5[k] = nil
					end
				end
			end

			State.entityToReference[v4] = nil

			if State.referenceToEntity[player] == v4 then
				State.referenceToEntity[player] = nil
			end

			v4 = nil
		end
	end

	local function clearCharacter() -- 3 equivalent calls inferred from this helper
		clearHrp()

		if childAddedConnection then
			childAddedConnection:Disconnect()
			childAddedConnection = nil
		end

		v3 = nil
	end

	local function checkHrp(instance)
		if instance ~= v3 then
			return
		end

		local humanoidRootPart = instance:FindFirstChild("HumanoidRootPart")

		if humanoidRootPart and humanoidRootPart:IsA("BasePart") and humanoidRootPart ~= v4 then
			clearHrp()
			v4 = humanoidRootPart

			State.entityToReference[humanoidRootPart] = player
			State.referenceToEntity[player] = humanoidRootPart

			local v5 = v2[player]

			if v5 then
				for k, v6 in v5 do
					if State.groups[k] then
						v6:_add(humanoidRootPart)
					else
						v5[k] = nil
					end
				end
			end

			ancestryChangedConnection = humanoidRootPart.AncestryChanged:Connect(function(_, parent)
				if not parent then
					clearHrp(humanoidRootPart)
				end
			end)
		end
	end

	local function onCharacterAdded(character) -- 1 equivalent call inferred from this helper
		clearCharacter() -- inferred equivalent call
		v3 = character
		checkHrp(character)

		childAddedConnection = character.ChildAdded:Connect(function(child)
			if child.Name == "HumanoidRootPart" then
				checkHrp(character)
			end
		end)
	end

	local characterAddedConnection = player.CharacterAdded:Connect(onCharacterAdded)
	local characterRemovingConnection = player.CharacterRemoving:Connect(function(character)
		if v3 == character then
			clearCharacter() -- inferred equivalent call
		end
	end)

	v[player] = function()
		characterAddedConnection:Disconnect()
		characterRemovingConnection:Disconnect()
		clearCharacter() -- inferred equivalent call
	end

	if player.Character then
		onCharacterAdded(player.Character) -- inferred equivalent call
	end
end

Players.PlayerRemoving:Connect(function(player)
	local v3 = v[player]

	if v3 then
		v3()
	end

	v[player] = nil
	v2[player] = nil
end)
local PlayerTracker = {}

function PlayerTracker.subscribe(p, object)
	if not v2[p] then
		v2[p] = {}
	end

	v2[p][object.id] = object
	trackPlayer(p)

	local v3 = State.referenceToEntity[p]

	if v3 then
		object:_add(v3)
	end
end

function PlayerTracker.unsubscribe(p, object)
	if v2[p] then
		v2[p][object.id] = nil
	end

	local v3 = State.referenceToEntity[p]

	if v3 then
		object:_remove(v3)
	end
end

return PlayerTracker