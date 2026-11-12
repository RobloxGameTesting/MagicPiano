local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local ContentProvider = game:GetService("ContentProvider")
local ChatInputBarConfiguration = TextChatService:WaitForChild("ChatInputBarConfiguration")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = workspace.CurrentCamera
local SheetGuiKeyPressed = ReplicatedStorage.Remotes:WaitForChild("SheetGuiKeyPressed")

local PianoNetwork = require(ReplicatedStorage.PianoNetwork)
local PianoGuiModule = require(script.PianoGuiModule)
local PianoVFX = require(ReplicatedStorage.src.Shared.PianoVFX)
local MidiConnect = require(script.MidiConnect)
local QueueTopbar = require(ReplicatedStorage.src.Client.QueueTopbar)
local Data = require(game.ReplicatedStorage.src.Shared.Data)
local client = Data.client

local PianoClient = {}
PianoClient.__index = PianoClient

local v = UserInputService.TouchEnabled and not (UserInputService.MouseEnabled or UserInputService.KeyboardEnabled)

local v2 = {}

local PianoFonts = ReplicatedStorage:WaitForChild("PianoFonts")
local modulesByChildName = {}

local function getSoundFontData(childName) -- 6 equivalent calls inferred from this helper
	if modulesByChildName[childName] then
		return modulesByChildName[childName]
	end

	local moduleScript = PianoFonts:FindFirstChild(childName)

	if moduleScript and moduleScript:IsA("ModuleScript") then
		local module = require(moduleScript)
		modulesByChildName[childName] = module
		return module
	end

	return nil
end

local v3 = {}
local function preloadSoundFont(p, items) -- 3 equivalent calls inferred from this helper
	if v3[p] then
		return
	end

	v3[p] = true
	task.spawn(function()
		local v4 = {}

		for k, item in items do
			local sound = Instance.new("Sound")
			sound.Name = k
			sound.SoundId = item
			table.insert(v4, sound)
		end

		local success, result = pcall(function()
			ContentProvider:PreloadAsync(v4)
		end)

		if not success then
			warn("Failed to preload soundfont:", p, result)
			v3[p] = nil
		end

		for _, v5 in v4 do
			v5:Destroy()
		end
	end)
end

local soundFontData = getSoundFontData("Grand Piano") -- inferred equivalent call

if not v3["Grand Piano"] then
	v3["Grand Piano"] = true
	local v4 = "Grand Piano"
	task.spawn(function()
		local v5 = {}

		for k, soundId in soundFontData do
			local sound = Instance.new("Sound")
			sound.Name = k
			sound.SoundId = soundId
			table.insert(v5, sound)
		end

		local success, result = pcall(function()
			ContentProvider:PreloadAsync(v5)
		end)

		if not success then
			warn("Failed to preload soundfont:", v4, result)
			v3[v4] = nil
		end

		for _, v6 in v5 do
			v6:Destroy()
		end
	end)
end

local function scheduleRemoteEvent(p, fn) -- 2 equivalent calls inferred from this helper
	local v4 = p + 1 - workspace:GetServerTimeNow()

	if v4 <= 0 then
		fn()
	else
		task.delay(v4, fn)
	end
end

local v4 = {
	"A",
	"A#",
	"B",
	"C",
	"C#",
	"D",
	"D#",
	"E",
	"F",
	"F#",
	"G",
	"G#"
}

local v5 = { Flute = true, Violin = true, Organ = true, Trumpet = true }

local function getNoteNameFromIndex(p) -- 1 equivalent call inferred from this helper
	local v6 = p - 1
	local v7 = v6 % 12
	local v8 = v4[v7 + 1]
	return (v7 < 3 and math.floor(v6 / 12) - 1 or math.floor((v6 - 3) / 12)) .. v8
end

local function fadeOutSound(instance, p) -- 5 equivalent calls inferred from this helper
	if not (instance and instance.Parent) then
		return
	end

	local volume = instance.Volume
	local v6 = p / 20

	task.spawn(function()
		for i = 1, 20 do
			task.wait(v6)

			if not instance.Parent then
				return
			end

			instance.Volume = volume * (1 - i / 20)
		end

		if instance.Parent then
			instance:Destroy()
		end
	end)
end

local function cancelNoteTimeout(p, p2) -- 6 equivalent calls inferred from this helper
	local timer = p.timers[p2]

	if timer then
		task.cancel(timer)
		p.timers[p2] = nil
	end
end

local function scheduleNoteTimeout(data, p, instance, p2)
	cancelNoteTimeout(data, p) -- inferred equivalent call
	local v6 = (data.versions[p] or 0) + 1
	data.versions[p] = v6

	data.timers[p] = task.delay(7, function()
		if data.versions[p] ~= v6 then
			return
		end

		data.timers[p] = nil

		if data.active[p] == instance then
			data.active[p] = nil

			if instance.Parent then
				instance:Destroy()
			end
		elseif data.sustained[p] == instance then
			data.sustained[p] = nil

			if p2 then
				local v7 = instance

				if v7 then
					if not v7.Parent then
						return
					end

					local volume = v7.Volume
					local v8 = p2 / 20

					task.spawn(function()
						for i = 1, 20 do
							task.wait(v8)

							if not v7.Parent then
								return
							end

							v7.Volume = volume * (1 - i / 20)
						end

						if v7.Parent then
							v7:Destroy()
						end
					end)
				end
			elseif instance.Parent then
				instance:Destroy()
			end
		end
	end)
end

local function setActiveNote(p, p2, p3, p4) -- 1 equivalent call inferred from this helper
	fadeOutSound(p.active[p2], 0.2) -- inferred equivalent call

	local v6 = p.sustained[p2]

	if v6 then
		p.sustained[p2] = nil
		fadeOutSound(v6, 0.2) -- inferred equivalent call
	end

	p.active[p2] = p3
	scheduleNoteTimeout(p, p2, p3, p4)
end

local function moveActiveToSustain(p, p2) -- 2 equivalent calls inferred from this helper
	local v6 = p.active[p2]

	if v6 then
		p.active[p2] = nil
		cancelNoteTimeout(p, p2) -- inferred equivalent call
		p.sustained[p2] = v6
	end

	return v6
end

local function releaseActiveNote(p, p2, p3)
	local v6 = p.active[p2]

	if v6 then
		p.active[p2] = nil
		cancelNoteTimeout(p, p2) -- inferred equivalent call

		if v6 then
			if not v6.Parent then
				return
			end

			local volume = v6.Volume
			local v7 = p3 / 20

			task.spawn(function()
				for i = 1, 20 do
					task.wait(v7)

					if not v6.Parent then
						return
					end

					v6.Volume = volume * (1 - i / 20)
				end

				if v6.Parent then
					v6:Destroy()
				end
			end)
		end
	end
end

local function releaseSustainedNote(p, p2) -- 6 equivalent calls inferred from this helper
	for _, v6 in p.sustained do
		if not (v6 and v6.Parent) then
			continue
		end

		local volume = v6.Volume
		local v7 = p2 / 20

		task.spawn(function()
			for i = 1, 20 do
				task.wait(v7)

				if not v6.Parent then
					return
				end

				v6.Volume = volume * (1 - i / 20)
			end

			if v6.Parent then
				v6:Destroy()
			end
		end)
	end

	table.clear(p.sustained)
end

local function clearNoteState(data, p, p2)
	for _, timer in pairs(data.timers) do
		task.cancel(timer)
	end

	table.clear(data.timers)

	for _, v6 in pairs(data.active) do
		if not (v6 and v6.Parent) then
			continue
		end

		local volume = v6.Volume
		local v7 = p / 20

		task.spawn(function()
			for i = 1, 20 do
				task.wait(v7)

				if not v6.Parent then
					return
				end

				v6.Volume = volume * (1 - i / 20)
			end

			if v6.Parent then
				v6:Destroy()
			end
		end)
	end

	table.clear(data.active)

	for _, v6 in pairs(data.sustained) do
		local v7 = p2 or p

		if not (v6 and v6.Parent) then
			continue
		end

		local volume = v6.Volume
		local v8 = v7 / 20

		task.spawn(function()
			for i = 1, 20 do
				task.wait(v8)

				if not v6.Parent then
					return
				end

				v6.Volume = volume * (1 - i / 20)
			end

			if v6.Parent then
				v6:Destroy()
			end
		end)
	end

	table.clear(data.sustained)
	table.clear(data.versions)
end

local function blockJump()
	return Enum.ContextActionResult.Sink
end

local function getDistanceVolume(p, p2, value) -- 2 equivalent calls inferred from this helper
	local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

	if humanoidRootPart then
		return math.max(0, 1 - ((humanoidRootPart.Position - p).Magnitude / p2) ^ 1.5) * (value or 1)
	end

	return 0
end

task.spawn(function()
	while task.wait(0.5) do
		for k, v6 in v2 do
			if k.Parent then
				k.Volume = getDistanceVolume(v6.source, v6.range, v6.volume) -- inferred equivalent call
			else
				v2[k] = nil
			end
		end
	end
end)

local v6 = 0
local v7 = 1.4
local v8 = nil

function PianoClient.new(parent)
	local object = setmetatable({}, PianoClient)

	local pianoNetwork = PianoNetwork(parent)

	local v9 = parent.Name == "LobbyPiano"

	if v9 then
		QueueTopbar.SetPiano(parent)
	end

	local pianoSeat = parent:WaitForChild("PianoSeat")
	local sitPrompt = pianoSeat:WaitForChild("SitPrompt")

	if v9 and client and client.chimes() == 0 then
		sitPrompt.Enabled = false
		task.delay(240, function()
			sitPrompt.Enabled = true
		end)
	end

	local transpose = parent:WaitForChild("Transpose")
	local volume = parent:WaitForChild("Volume")

	local v10 = parent:GetAttribute("SoundFont") or "Grand Piano"
	preloadSoundFont(v10, getSoundFontData(v10)) -- inferred equivalent call
	local flag = false
	volume.Value = 1.4

	local inputBeganConnection = nil
	local inputEndedConnection = nil
	local activatedConnection = nil
	local sustainButton = nil
	local v11 = {}
	local v12 = {}
	local v13 = true
	local v14 = true

	local v15 = { active = {}, sustained = {}, timers = {}, versions = {} }
	local v16 = { active = {}, sustained = {}, timers = {}, versions = {} }

	local pianoLive = Instance.new("Folder")
	pianoLive.Name = "PianoLive"
	pianoLive.Parent = parent

	local function getSoundIdForNote(p) -- 1 equivalent call inferred from this helper
		local noteNameFromIndex = getNoteNameFromIndex(p) -- inferred equivalent call
		local grandPiano2 = getSoundFontData(v10) -- inferred equivalent call

		if not grandPiano2 then
			if modulesByChildName["Grand Piano"] then
				grandPiano2 = modulesByChildName["Grand Piano"]
			else
				local grandPiano = PianoFonts:FindFirstChild("Grand Piano")

				if grandPiano and grandPiano:IsA("ModuleScript") then
					grandPiano2 = require(grandPiano)
					modulesByChildName["Grand Piano"] = grandPiano2
				else
					grandPiano2 = nil
				end
			end
		end

		local soundIdForNote = grandPiano2 and grandPiano2[noteNameFromIndex]

		if not soundIdForNote then
			local soundFontData2 = getSoundFontData("Grand Piano") -- inferred equivalent call
			soundIdForNote = soundFontData2 and soundFontData2[noteNameFromIndex]
		end

		return soundIdForNote
	end

	local function playNoteAudio(p, p2, p3, value, p4)
		local soundIdForNote = getSoundIdForNote(p + 15) -- inferred equivalent call

		if not soundIdForNote then
			return nil
		end

		local sound = Instance.new("Sound")
		sound.SoundId = soundIdForNote

		local child = PianoFonts:FindFirstChild(v10)
		local effects = child and child:FindFirstChild("Effects")

		if effects then
			for _, soundEffect in effects:GetChildren() do
				if not soundEffect:IsA("SoundEffect") then
					continue
				end

				local clone = soundEffect:Clone()
				clone.Parent = sound
			end
		end

		sound.Parent = pianoLive

		if p2 and p3 then
			local distanceVolume = getDistanceVolume(p2, p3, value) -- inferred equivalent call

			if distanceVolume < 0.01 then
				sound:Destroy()
				return nil
			end

			sound.Volume = distanceVolume
		else
			sound.Volume = p4 or volume.Value
		end

		sound:Play()
		return sound
	end

	local function playNote(p, p2, p3, p4, p5, p6, p7) -- 2 equivalent calls inferred from this helper
		local v17 = playNoteAudio(p2, p3, p4, p5, p7)

		if v17 then
			setActiveNote(p, p2, v17, p6) -- inferred equivalent call
		end

		return v17
	end

	local function playNoteClient(p, p2, p3, p4)
		if not p then
			return
		end

		if v14 and v5[v10] then
			releaseSustainedNote(v15, 0.4) -- inferred equivalent call
			pianoNetwork.ReleaseSustain:FireServer(workspace:GetServerTimeNow())
		end

		PianoGuiModule.highlight(p3 or p)

		local v17 = math.clamp(p4 or p2 and 5 * p2 / 127 or volume.Value, 0, 5)
		playNote(v15, p, nil, nil, nil, nil, v17) -- inferred equivalent call
		pianoNetwork.Play:FireServer(p, v17, workspace:GetServerTimeNow())
		PianoVFX.TriggerLocal(parent, "Pressed", p, v17)
	end

	local function playNoteFromServer(p, source, range, volume2) -- 1 equivalent call inferred from this helper
		local v17 = playNote(v16, p, source, range, volume2, 0.35) -- inferred equivalent call

		if v17 then
			v2[v17] = { source = source, range = range, volume = volume2 }
		end
	end

	local function releaseNoteClient(note, _, highlightNote)
		if not note then
			return
		end

		PianoGuiModule.unhighlight(highlightNote or note)
		local serverTimeNow = workspace:GetServerTimeNow()

		if v13 then
			moveActiveToSustain(v15, note) -- inferred equivalent call
			pianoNetwork.SustainNote:FireServer(note, serverTimeNow)
			PianoVFX.TriggerLocal(parent, "Sustained", note, volume.Value)
		else
			local v17 = v15
			local v18 = v17.active[note]

			if v18 then
				v17.active[note] = nil
				cancelNoteTimeout(v17, note) -- inferred equivalent call
				fadeOutSound(v18, 0.35) -- inferred equivalent call
			end

			pianoNetwork.ReleaseNote:FireServer(note, serverTimeNow)
			PianoVFX.TriggerLocal(parent, "Released", note, volume.Value)
		end
	end

	local function letterToNote(value, p, p2)
		local v17 = string.char(value)

		if p2 then
			local v18 = ("1234567890qwert"):find(v17, 1, true)

			if v18 then
				return -14 + (v18 - 1)
			end

			local v19 = ("yuiopasdfghj"):find(v17, 1, true)

			if v19 then
				return 62 + (v19 - 1)
			end

			return nil
		else
			local v18 = ("1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm"):find(v17, 1, true)

			if v18 then
				return v18 + (p and 1 or 0)
			end

			return nil
		end
	end

	local function setSustainEnabled(visible) -- 8 equivalent calls inferred from this helper
		v13 = visible

		local imageLabel = sustainButton and sustainButton:FindFirstChild("ImageLabel")

		if imageLabel then
			imageLabel.Visible = visible
		end
	end

	local function bindGuiControls()
		if activatedConnection then
			activatedConnection:Disconnect()
			activatedConnection = nil
		end

		for k, connection in pairs(v11) do
			connection:Disconnect()
			v11[k] = nil
		end

		sustainButton = PianoGuiModule:GetSustainButton()

		if sustainButton then
			setSustainEnabled(v14) -- inferred equivalent call
			activatedConnection = sustainButton.Activated:Connect(function()
				v14 = not v14

				if v14 then
					setSustainEnabled(true) -- inferred equivalent call
					pianoNetwork.Sustained:FireServer(workspace:GetServerTimeNow())
					PianoVFX.TriggerLocal(parent, "SustainEnabled")
				else
					setSustainEnabled(false) -- inferred equivalent call
					releaseSustainedNote(v15, 0.4) -- inferred equivalent call
					pianoNetwork.ReleaseSustain:FireServer(workspace:GetServerTimeNow())
					PianoVFX.TriggerLocal(parent, "SustainReleased")
				end
			end)
		end

		local gui = PianoGuiModule:GetGui()

		if not gui then
			return
		end

		for _, button in gui.MainFrame:WaitForChild("FontsScrollingFrame"):GetChildren() do
			if button:IsA("TextButton") then
				v11[button] = button.Activated:Connect(function()
					v10 = button.Text
					pianoNetwork.ChangeSoundFont:FireServer(v10)
					preloadSoundFont(v10, getSoundFontData(v10)) -- inferred equivalent call
				end)
			end
		end
	end

	local function changeTransposition(p) -- 2 equivalent calls inferred from this helper
		transpose.Value += p
		v6 = transpose.Value
		PianoGuiModule.updateLabels()
	end

	local function changeVolume(p) -- 2 equivalent calls inferred from this helper
		volume.Value = math.clamp(volume.Value + p, 0, 2)
		v7 = volume.Value
		PianoGuiModule.updateLabels()
	end

	local function onKeyDown(data)
		if ChatInputBarConfiguration.IsFocused then
			return
		end

		local value = data.KeyCode.Value

		if value >= 97 and value <= 122 or value >= 48 and value <= 57 then
			local v17 = (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) ~= false
			local v18 = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
			local v19 = (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt))
				and ("1234567890qwertyuiopasdfghjklzxc"):find(string.char(value), 1, true)

			if v19 then
				v8 = 0.2 * 25 ^ ((v19 - 1) / 31) ^ 0.8
				return
			end

			local highlightNote = letterToNote(value, v17, v18)

			if highlightNote then
				local note = highlightNote + transpose.Value
				v12[value] = { note = note, highlightNote = highlightNote }

				playNoteClient(note, nil, highlightNote, v8)
				v8 = nil
			end
		elseif value == 8 then
			if ChatInputBarConfiguration.IsFocused or UserInputService:GetFocusedTextBox() then
				return
			end

			pianoNetwork.Abort:FireServer()
		elseif value == 32 then
			if v14 then
				setSustainEnabled(false) -- inferred equivalent call
				releaseSustainedNote(v15, 0.4) -- inferred equivalent call
				pianoNetwork.ReleaseSustain:FireServer(workspace:GetServerTimeNow())
			else
				setSustainEnabled(true) -- inferred equivalent call
			end
		elseif value == 274 then
			changeTransposition(-1) -- inferred equivalent call
		elseif value == 273 then
			changeTransposition(1) -- inferred equivalent call
		elseif value == 275 then
			changeVolume(0.2) -- inferred equivalent call
		elseif value == 276 then
			changeVolume(-0.2) -- inferred equivalent call
		end
	end

	local function onKeyUp(input)
		local value = input.KeyCode.Value

		local v17 = v12[value]

		if v17 then
			v12[value] = nil
			releaseNoteClient(v17.note, nil, v17.highlightNote)
		end

		if value == 32 then
			if v14 then
				setSustainEnabled(true) -- inferred equivalent call
				pianoNetwork.Sustained:FireServer(workspace:GetServerTimeNow())
			else
				setSustainEnabled(false) -- inferred equivalent call
				releaseSustainedNote(v15, 0.4) -- inferred equivalent call
				pianoNetwork.ReleaseSustain:FireServer(workspace:GetServerTimeNow())
			end
		end
	end

	local function onInputBegan(data, _)
		if
			data.UserInputType ~= Enum.UserInputType.Keyboard
			or data.UserInputState ~= Enum.UserInputState.Begin
			or MidiConnect.processInput(data.KeyCode.Value)
		then
			return
		end

		onKeyDown(data)
	end

	local function onActivate()
		local humanoid = LocalPlayer.Character:WaitForChild("Humanoid")

		if pianoSeat.Occupant ~= humanoid or flag then
			return
		end

		flag = true

		transpose.Value = v6
		volume.Value = v7

		PianoGuiModule.setNoteCallback({
			onPress = playNoteClient,
			onRelease = releaseNoteClient,
			onTranspose = changeTransposition,
			onVolume = changeVolume,
			onSheetKeyPressed = function(p)
				SheetGuiKeyPressed:Fire(p)
			end
		})

		PianoGuiModule.setGuiChangedCallback(bindGuiControls)
		PianoGuiModule.init(
			transpose,
			volume,
			"1!2@34$5%6^78*9(0qQwWeErtTyYuiIoOpPasSdDfgGhHjJklLzZxcCvVbBnm",
			"1234567890qwert",
			-14,
			"yuiopasdfghj",
			62,
			0,
			2
		)

		PianoGuiModule.updateLabels()
		PianoGuiModule.setEnabled(true)

		MidiConnect.init(playNoteClient, releaseNoteClient, function(visible)
			setSustainEnabled(visible) -- inferred equivalent call

			if visible then
				pianoNetwork.Sustained:FireServer(workspace:GetServerTimeNow())
				return
			end

			releaseSustainedNote(v15, 0.4) -- inferred equivalent call
			pianoNetwork.ReleaseSustain:FireServer(workspace:GetServerTimeNow())
		end)

		inputBeganConnection = UserInputService.InputBegan:Connect(onInputBegan)
		inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end

			onKeyUp(input)
		end)

		if LocalPlayer.PlayerGui:FindFirstChild("Freecam") then
			LocalPlayer.PlayerGui.Freecam.FreecamScript.Enabled = false
		end

		local pianoCamPart = pianoSeat:FindFirstChild("PianoCamPart")

		if pianoCamPart then
			if v then
				pianoCamPart.Position = pianoSeat.Position
			end

			workspace.CurrentCamera.CameraSubject = pianoCamPart
		end

		ContextActionService:BindAction("DisablePianoJump", blockJump, false, Enum.KeyCode.Space)
		ContextActionService:BindActionAtPriority("DisableIOZooming", function()
			return Enum.ContextActionResult.Sink
		end, false, 3000, Enum.KeyCode.I, Enum.KeyCode.O)

		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:UnequipTools()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, false)

		if v9 then
			sitPrompt.Enabled = false
		end
	end

	local function onDeactivate()
		local humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
		workspace.CurrentCamera.CameraSubject = humanoid
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, true)
		PianoGuiModule.setEnabled(false)
		PianoGuiModule.resetHighlights()
		PianoGuiModule.clearLabels()
		PianoGuiModule.disconnect()

		if inputBeganConnection then
			inputBeganConnection:Disconnect()
			inputBeganConnection = nil
		end

		if inputEndedConnection then
			inputEndedConnection:Disconnect()
			inputEndedConnection = nil
		end

		for k, connection in v11 do
			connection:Disconnect()
			v11[k] = nil
		end

		table.clear(v12)
		clearNoteState(v15, 0.35, 0.4)

		for _, v17 in v16.active do
			v2[v17] = nil
		end

		for _, v17 in v16.sustained do
			v2[v17] = nil
		end

		clearNoteState(v16, 0.35, 0.4)

		if activatedConnection then
			activatedConnection:Disconnect()
			activatedConnection = nil
		end

		ContextActionService:UnbindAction("DisablePianoJump")
		ContextActionService:UnbindAction("DisableIOZooming")

		if LocalPlayer.PlayerGui:FindFirstChild("Freecam") then
			LocalPlayer.PlayerGui.Freecam.FreecamScript.Enabled = true
		end

		flag = false

		if v9 then
			sitPrompt.Enabled = true
		end

		task.delay(0.1, function()
			if flag then
				return
			end

			local seatPart = humanoid.SeatPart

			if humanoid.Sit and (seatPart == nil or seatPart == pianoSeat) then
				humanoid.Sit = false
				humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end

	pianoNetwork.Activate.OnClientEvent:Connect(onActivate)
	pianoNetwork.Deactivate.OnClientEvent:Connect(onDeactivate)
	pianoNetwork.ServerPlayNote.OnClientEvent:Connect(function(p, source, range, volume2, p2)
		local function fn()
			playNoteFromServer(p, source, range, volume2) -- inferred equivalent call
		end

		local v17 = p2 + 1 - workspace:GetServerTimeNow()

		if v17 <= 0 then
			local v18 = v16
			local v19 = playNoteAudio(p, source, range, volume2, nil)

			if v19 then
				local v20 = v18.active[p]

				if v20 then
					fadeOutSound(v20, 0.2)
				end

				local v21 = v18.sustained[p]

				if v21 then
					v18.sustained[p] = nil
					fadeOutSound(v21, 0.2)
				end

				v18.active[p] = v19
				scheduleNoteTimeout(v18, p, v19, 0.35)
			end

			if v19 then
				v2[v19] = { source = source, range = range, volume = volume2 }
			end
		else
			task.delay(v17, fn)
		end
	end)
	pianoNetwork.ServerReleaseNote.OnClientEvent:Connect(function(p, p2)
		local function fn()
			local v17 = v16.active[p]
			local v18 = v16
			local v19 = p
			local v20 = v18.active[v19]

			if v20 then
				v18.active[v19] = nil
				cancelNoteTimeout(v18, v19) -- inferred equivalent call
				fadeOutSound(v20, 0.35) -- inferred equivalent call
			end

			if v17 then
				v2[v17] = nil
			end
		end

		local v17 = p2 + 1 - workspace:GetServerTimeNow()

		if v17 <= 0 then
			local v18 = v16.active[p]
			local v19 = v16
			local v20 = v19.active[p]

			if v20 then
				v19.active[p] = nil
				cancelNoteTimeout(v19, p) -- inferred equivalent call
				fadeOutSound(v20, 0.35) -- inferred equivalent call
			end

			if v18 then
				v2[v18] = nil
			end
		else
			task.delay(v17, fn)
		end
	end)
	pianoNetwork.ServerSustainNote.OnClientEvent:Connect(function(p, p2)
		local function fn()
			moveActiveToSustain(v16, p) -- inferred equivalent call
		end

		scheduleRemoteEvent(p2, fn) -- inferred equivalent call
	end)
	pianoNetwork.ServerReleaseSustain.OnClientEvent:Connect(function(p)
		local function fn()
			for _, v17 in v16.sustained do
				v2[v17] = nil
			end

			releaseSustainedNote(v16, 0.4) -- inferred equivalent call
		end

		scheduleRemoteEvent(p, fn) -- inferred equivalent call
	end)
	pianoNetwork.ServerWarning.OnClientEvent:Connect(function(text)
		StarterGui:SetCore("SendNotification", {
			Title = "⚠️ Warning",
			Text = text,
			Duration = 20,
			Button1 = "OK"
		})
	end)

	parent:GetAttributeChangedSignal("SoundFont"):Connect(function()
		local soundFont = parent:GetAttribute("SoundFont")

		if not soundFont then
			return
		end

		v10 = soundFont
		preloadSoundFont(v10, getSoundFontData(v10)) -- inferred equivalent call
	end)

	pianoSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if pianoSeat.Occupant then
			return
		end

		for _, v17 in v16.active do
			v2[v17] = nil
		end

		for _, v17 in v16.sustained do
			v2[v17] = nil
		end

		clearNoteState(v16, 0.35, 0.4)
	end)

	return object
end

return PianoClient