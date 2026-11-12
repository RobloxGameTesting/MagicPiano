return {
	Init = function()
		local Players = game:GetService("Players")
		local CollectionService = game:GetService("CollectionService")
		local localPlayer = Players.LocalPlayer
		local playerGui = localPlayer:WaitForChild("PlayerGui")
		local toggleShiftLockEvent = game.ReplicatedStorage.Remotes:WaitForChild("ToggleShiftLockEvent")
		local freecamScript = nil

		local function updatePrompt(p) -- 3 equivalent calls inferred from this helper
			local parent = p.Parent

			if not parent:IsA("Seat") then
				return
			end

			p.Enabled = not (freecamScript and freecamScript:GetAttribute("FreecamEnabled"))
				and (parent:FindFirstAncestor("LobbyPiano") ~= nil or parent.Occupant == nil)
		end

		local function updatePrompts() -- 2 equivalent calls inferred from this helper
			for _, v in CollectionService:GetTagged("PianoSitPrompt") do
				updatePrompt(v) -- inferred equivalent call
			end
		end

		local function connectPrompt(p)
			local parent = p.Parent

			if not parent:IsA("Seat") then
				return
			end

			parent:GetPropertyChangedSignal("Occupant"):Connect(function()
				updatePrompt(p) -- inferred equivalent call
			end)
			updatePrompt(p) -- inferred equivalent call
		end

		local function updateFreecam()
			local freecamEnabled = freecamScript:GetAttribute("FreecamEnabled") == true
			toggleShiftLockEvent:FireServer(not freecamEnabled)
			updatePrompts() -- inferred equivalent call
		end

		local function setupFreecam(freecam)
			if freecam.Name ~= "Freecam" then
				return
			end

			freecamScript = freecam:WaitForChild("FreecamScript", 10)

			if not freecamScript then
				warn("FreecamScript not found in PlayerGui.Freecam")
				return
			end

			freecamScript:GetAttributeChangedSignal("FreecamEnabled"):Connect(updateFreecam)
			updatePrompts() -- inferred equivalent call
		end

		CollectionService:GetInstanceAddedSignal("PianoSitPrompt"):Connect(connectPrompt)

		for _, v in CollectionService:GetTagged("PianoSitPrompt") do
			connectPrompt(v)
		end

		local freecam = playerGui:FindFirstChild("Freecam")

		if freecam then
			setupFreecam(freecam)
		end

		playerGui.ChildAdded:Connect(setupFreecam)
		localPlayer.CharacterAdded:Connect(updatePrompts)
	end
}