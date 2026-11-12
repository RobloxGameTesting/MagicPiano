local PianoGuiModule = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
game:GetService("ReplicatedStorage")
local Data = require(game.ReplicatedStorage.src.Shared.Data)
local client = Data.client
local v

if client then
	v = client.settings.fullScreenPianoEnabled() or false
else
	v = false
end

local gui = nil

local mainFrame = nil
local sustainButton = nil
local data = {}
local backgroundTransparencies = {}
local connectionsByData = {}
local connection = nil
local connection2 = nil
local touchEndedConnection = nil
local activatedConnection = nil
local activatedConnection2 = nil
local activatedConnection3 = nil
local activatedConnection4 = nil
local touchMovedConnection = nil

local v2 = nil
local v3 = nil
local v4 = nil
local v5 = nil
local v6 = nil
local v7 = nil
local v8 = nil
local v9 = nil
local v10 = nil
local v11 = nil

local v12 = {}
local v13 = {}

local v14 = nil

function PianoGuiModule.setGuiChangedCallback(p)
	v14 = p
end

local function disconnectButtonConnections()
	for _, list in connectionsByData do
		if list.releaseNote then
			list.releaseNote()
			list.releaseNote = nil
		end

		for _, connection3 in ipairs(list) do
			connection3:Disconnect()
		end
	end

	connectionsByData = {}
	v12 = {}
	v13 = {}
end

local function getTopPianoKey(position)
	local guiObjectsAtPosition = Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(position.X, position.Y)

	for _, v15 in guiObjectsAtPosition do
		if connectionsByData[v15] and v15.Name:sub(1, 1) == "B" then
			return v15
		end
	end

	for _, v15 in guiObjectsAtPosition do
		if connectionsByData[v15] and v15.Name:sub(1, 1) == "W" then
			return v15
		end
	end

	return nil
end

local function connectButton(data2, p, p2)
	if not data2 or connectionsByData[data2] then
		return
	end

	local connections = {}
	connectionsByData[data2] = connections

	data[p] = data2
	backgroundTransparencies[p] = data2.BackgroundTransparency

	local v15 = nil
	local function pressNote() -- 1 equivalent call inferred from this helper
		if v15 then
			return
		end

		v15 = p + v2.Value

		if v9 and v9.onSheetKeyPressed then
			v9.onSheetKeyPressed(p)
		end

		if v9 and v9.onPress then
			v9.onPress(v15, nil, p)
		end
	end
	connectionsByData[data2].pressNote = pressNote

	local function releaseNote() -- 1 equivalent call inferred from this helper
		if not v15 then
			return
		end

		local v16 = v15
		v15 = nil

		if v9 and v9.onRelease then
			v9.onRelease(v16, nil, p)
		end
	end
	connectionsByData[data2].releaseNote = releaseNote

	if not p2 then
		table.insert(connections, data2.MouseButton1Down:Connect(pressNote))
		table.insert(connections, data2.MouseButton1Up:Connect(releaseNote))
	end

	table.insert(connections, data2.MouseLeave:Connect(function()
		if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			releaseNote() -- inferred equivalent call
		end
	end))

	table.insert(connections, data2.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local v16 = v13[input]

		if v16 and v16 ~= data2 then
			local v17 = connectionsByData[v16]

			if v17 and v17.releaseNote then
				v17.releaseNote()
			end
		end

		v13[input] = data2
		v12[input] = releaseNote
		pressNote() -- inferred equivalent call
	end))
end

local function connectControlButtons()
	local upTranspose = mainFrame:WaitForChild("UpTranspose")
	local downTranspose = mainFrame:WaitForChild("DownTranspose")
	local upVolume = mainFrame:WaitForChild("UpVolume")
	local downVolume = mainFrame:WaitForChild("DownVolume")

	if activatedConnection then
		activatedConnection:Disconnect()
	end

	if activatedConnection2 then
		activatedConnection2:Disconnect()
	end

	if activatedConnection3 then
		activatedConnection3:Disconnect()
	end

	if activatedConnection4 then
		activatedConnection4:Disconnect()
	end

	activatedConnection = upTranspose.Activated:Connect(function()
		if v9 and v9.onTranspose then
			v9.onTranspose(1)
		end
	end)

	activatedConnection2 = downTranspose.Activated:Connect(function()
		if v9 and v9.onTranspose then
			v9.onTranspose(-1)
		end
	end)

	activatedConnection3 = upVolume.Activated:Connect(function()
		if v9 and v9.onVolume then
			v9.onVolume(0.2)
		end
	end)

	activatedConnection4 = downVolume.Activated:Connect(function()
		if v9 and v9.onVolume then
			v9.onVolume(-0.2)
		end
	end)
end

local function buildButtonMap()
	disconnectButtonConnections()

	local localPlayer = Players.LocalPlayer
	local v15 = UserInputService.TouchEnabled
		and not (UserInputService.MouseEnabled or UserInputService.KeyboardEnabled)
	local blackKeys, whiteKeys

	if v15 then
		local playerGui = localPlayer:WaitForChild("PlayerGui")

		gui = v and playerGui:WaitForChild("FullScreenPianoMobileGui") or playerGui:WaitForChild("PianoMobileGui")

		mainFrame = gui:WaitForChild("MainFrame")

		local keyFrames = mainFrame.ScrollingFrame:WaitForChild("KeyFrames")
		blackKeys = keyFrames:WaitForChild("BlackKeys")
		whiteKeys = keyFrames:WaitForChild("WhiteKeys")
	else
		gui = localPlayer.PlayerGui:WaitForChild("PianoGui")
		mainFrame = gui:WaitForChild("MainFrame")

		blackKeys = mainFrame:WaitForChild("BlackKeys")
		whiteKeys = mainFrame:WaitForChild("WhiteKeys")
	end

	sustainButton = mainFrame:FindFirstChild("SustainButton", true)

	data = {}
	backgroundTransparencies = {}

	local v16 = {
		false,
		true,
		false,
		true,
		false,
		false,
		true,
		false,
		true,
		false,
		true,
		false
	}
	local v17 = 6
	local v18 = 9

	for i = 1, 73 do
		local v19

		if v16[(i - 1) % 12 + 1] then
			v17 += 1
			v19 = blackKeys:FindFirstChild("B" .. v17)
		else
			v18 += 1
			v19 = whiteKeys:FindFirstChild(v18 <= 9 and v18 .. "W" or "W" .. v18)
		end

		if v19 then
			connectButton(v19, i, v15)
		end
	end

	local v19 = {
		false,
		true,
		false,
		false,
		true,
		false,
		true,
		false,
		false,
		true,
		false,
		true,
		false,
		true,
		false
	}
	local count = 0
	local count2 = 0

	for i = 1, #v19 do
		local v20

		if v19[i] then
			count += 1
			v20 = blackKeys:FindFirstChild("B" .. count)
		else
			count2 += 1
			v20 = whiteKeys:FindFirstChild(count2 <= 9 and count2 .. "W" or "W" .. count2)
		end

		local v21 = i + -15

		if v20 then
			connectButton(v20, v21, v15)
		end
	end

	if v14 then
		v14(gui, mainFrame)
	end
end

function PianoGuiModule.init(p, p2, p3, p4, p5, p6, p7, p8, p9)
	v2 = p
	v3 = p2
	v4 = p3
	v5 = p4
	v6 = p5
	v7 = p6
	v8 = p7
	v10 = p8
	v11 = p9

	buildButtonMap()
	connectControlButtons()

	if touchEndedConnection then
		touchEndedConnection:Disconnect()
	end

	touchEndedConnection = UserInputService.TouchEnded:Connect(function(otherPart)
		local v15 = v12[otherPart]

		if not v15 then
			return
		end

		v13[otherPart] = nil
		v12[otherPart] = nil
		v15()
	end)

	touchMovedConnection = UserInputService.TouchMoved:Connect(function(p10)
		local v15 = v13[p10]

		if not v15 then
			return
		end

		local topPianoKey = getTopPianoKey(p10.Position)

		if not topPianoKey or topPianoKey == v15 then
			return
		end

		local v16 = connectionsByData[v15]
		local v17 = connectionsByData[topPianoKey]

		if v16 and v16.releaseNote then
			v16.releaseNote()
		end

		v13[p10] = topPianoKey

		if v17 and v17.pressNote then
			v17.pressNote()
			v12[p10] = v17.releaseNote
		else
			v12[p10] = nil
		end
	end)

	PianoGuiModule.updateLabels()
end

function PianoGuiModule.highlight(value)
	local v15 = math.clamp(value, -14, 88)
	local v16 = data[v15]

	if v16 then
		v16.BackgroundTransparency = 0.25
	end
end

function PianoGuiModule.unhighlight(value)
	local v15 = math.clamp(value, -14, 88)
	local v16 = data[v15]

	if v16 then
		v16.BackgroundTransparency = backgroundTransparencies[v15] or 0
	end
end

local v15 = {
	"A",
	"A♯",
	"B",
	"C",
	"C♯",
	"D",
	"D♯",
	"E",
	"F",
	"F♯",
	"G",
	"G♯"
}

local function getNoteNameFromIndex(p) -- 1 equivalent call inferred from this helper
	return v15[(p - 1) % 12 + 1]
end

local function updateNoteLabel(instance, i) -- 1 equivalent call inferred from this helper
	local noteLabel = instance:FindFirstChild("NoteLabel")

	if not noteLabel then
		return
	end

	local v16 = i + v2.Value + 15
	local text

	if client and client.settings.pianoNotesLabelEnabled() then
		text = getNoteNameFromIndex(v16) or "" -- inferred equivalent call
	else
		text = ""
	end

	noteLabel.Text = text
end

function PianoGuiModule.updateLabels()
	if not (gui and v2) then
		return
	end

	for i = -14, 88 do
		local v16 = data[i]

		if not v16 then
			continue
		end

		v16.Text = ""
		updateNoteLabel(v16, i) -- inferred equivalent call
	end

	for i = 1, #v4 do
		if not (i >= 1 and i <= 88) then
			continue
		end

		local v16 = data[i]

		if v16 then
			v16.Text = v4:sub(i, i)
		end
	end

	local function addZoneLabels(value: string, p: number, p2: number)
		for i = 1, #value do
			local v16 = p + (i - 1)
			local v17 = data[v16]

			if not (v17 and p <= v16 and v16 <= p2) then
				continue
			end

			local text = "<u>" .. value:sub(i, i) .. "</u>"
			text = v17.Text ~= "" and v17.Text .. " " .. text or text
			v17.Text = text
		end
	end

	addZoneLabels(v5, v6, 0)
	addZoneLabels(v7, v8, 73)

	local transposeLabel = mainFrame.Frame:FindFirstChild("TransposeLabel")

	if transposeLabel then
		transposeLabel.Text = "Transpose: " .. v2.Value
	end

	local volumeLabel = mainFrame.Frame:FindFirstChild("VolumeLabel")

	if volumeLabel then
		volumeLabel.Text = "Volume: " .. math.round(v3.Value / 2 * 200) .. "%"
	end
end

function PianoGuiModule.setEnabled(enabled)
	if gui then
		gui.Enabled = enabled
	end
end

function PianoGuiModule.clearLabels()
	for i = -14, 88 do
		local v16 = data[i]

		if v16 then
			v16.Text = ""
		end
	end
end

function PianoGuiModule.resetHighlights()
	for k, v16 in pairs(data) do
		v16.BackgroundTransparency = backgroundTransparencies[k] or 0
	end
end

function PianoGuiModule.setNoteCallback(p)
	v9 = p
end

function PianoGuiModule.disconnect()
	disconnectButtonConnections()

	if connection then
		connection:Disconnect()
		connection = nil
	end

	if connection2 then
		connection2:Disconnect()
		connection2 = nil
	end

	if touchEndedConnection then
		touchEndedConnection:Disconnect()
		touchEndedConnection = nil
	end

	if activatedConnection then
		activatedConnection:Disconnect()
		activatedConnection = nil
	end

	if activatedConnection2 then
		activatedConnection2:Disconnect()
		activatedConnection2 = nil
	end

	if activatedConnection3 then
		activatedConnection3:Disconnect()
		activatedConnection3 = nil
	end

	if activatedConnection4 then
		activatedConnection4:Disconnect()
		activatedConnection4 = nil
	end

	if touchMovedConnection then
		touchMovedConnection:Disconnect()
		touchMovedConnection = nil
	end
end

function PianoGuiModule.GetGui(_)
	return gui
end

function PianoGuiModule.GetSustainButton(_)
	return sustainButton
end

if client then
	client.settings.pianoNotesLabelEnabled.Changed(function()
		PianoGuiModule.updateLabels()
	end)
	client.settings.fullScreenPianoEnabled.Changed(function(p)
		if v == p then
			return
		end

		local enabled = gui and gui.Enabled or false
		PianoGuiModule.resetHighlights()
		v = p

		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		playerGui.PianoMobileGui.Enabled = false
		playerGui.FullScreenPianoMobileGui.Enabled = false
		buildButtonMap()
		connectControlButtons()

		if gui then
			gui.Enabled = enabled
		end

		PianoGuiModule.updateLabels()
	end)
end

return PianoGuiModule