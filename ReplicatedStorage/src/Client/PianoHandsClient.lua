return {
	Init = function()
		local Players = game:GetService("Players")
		local CollectionService = game:GetService("CollectionService")
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local PianoHandsController = require(ReplicatedStorage.src.Shared.PianoHandsController)

		local v = {}

		local function getPianoSeat(instance) -- 2 equivalent calls inferred from this helper
			return instance:FindFirstChildWhichIsA("Seat", true)
		end

		local function suppressEarlyAnimation(instance)
			if instance == Players.LocalPlayer.Character then
				return
			end

			local humanoid = instance:WaitForChild("Humanoid")
			local animator = humanoid:WaitForChild("Animator")
			local function checkTrack(object)
				local animation = object.Animation

				if not animation or animation.Name ~= "Animation" then
					return
				end

				local animationId = animation.AnimationId

				if animationId ~= "rbxassetid://93038381318687" and animationId ~= "rbxassetid://82644670816191" then
					return
				end

				for _, v2 in CollectionService:GetTagged("PianoModel") do
					local pianoSeat = getPianoSeat(v2) -- inferred equivalent call

					if pianoSeat and pianoSeat.Occupant == humanoid then
						object:Stop(0)
						break
					end
				end
			end

			local animationPlayedConnection = animator.AnimationPlayed:Connect(checkTrack)

			for _, v2 in animator:GetPlayingAnimationTracks() do
				checkTrack(v2)
			end

			return animationPlayedConnection
		end

		local function watchPlayer(player) -- 1 equivalent call inferred from this helper
			local function onCharacterAdded(character) -- 1 equivalent call inferred from this helper
				if v[player] then
					v[player]:Disconnect()
				end

				task.spawn(function()
					local v2 = suppressEarlyAnimation(character)

					if v2 then
						v[player] = v2
					end
				end)
			end

			if player.Character then
				onCharacterAdded(player.Character) -- inferred equivalent call
			end

			player.CharacterAdded:Connect(onCharacterAdded)
		end

		local v2 = {}

		for _, v3 in Players:GetPlayers() do
			watchPlayer(v3) -- inferred equivalent call
		end

		Players.PlayerAdded:Connect(watchPlayer)
		Players.PlayerRemoving:Connect(function(player)
			if v[player] then
				v[player]:Disconnect()
				v[player] = nil
			end
		end)

		local function registerPiano(instance) -- 1 equivalent call inferred from this helper
			if v2[instance] then
				return
			end

			local pianoSeat = getPianoSeat(instance) -- inferred equivalent call

			if not pianoSeat then
				return
			end

			v2[instance] = PianoHandsController.Init(pianoSeat)
		end
		local function unregisterPiano(p)
			local v3 = v2[p]

			if v3 then
				v3()
				v2[p] = nil
			end
		end

		for _, v3 in CollectionService:GetTagged("PianoModel") do
			registerPiano(v3) -- inferred equivalent call
		end

		CollectionService:GetInstanceAddedSignal("PianoModel"):Connect(registerPiano)
		CollectionService:GetInstanceRemovedSignal("PianoModel"):Connect(unregisterPiano)
	end
}