local ProfileViewClient = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")

local v = require(game.ReplicatedStorage.src.Shared.Data)
v = v.client

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
LocalPlayer:GetMouse()

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ViewProfileEvent = Remotes:WaitForChild("ViewProfileEvent")
local GiveRecognitionEvent = Remotes:WaitForChild("GiveRecognitionEvent")
local RecognitionNotificationEvent = Remotes:WaitForChild("RecognitionNotificationEvent")

local ProfileViewPart = ReplicatedStorage:WaitForChild("ProfileViewPart")
local ViewProfileBillboardGui = PlayerGui:WaitForChild("ViewProfileBillboardGui")
local Frame = ViewProfileBillboardGui:WaitForChild("Frame")

local AvatarImageLabel = Frame:WaitForChild("AvatarImageLabel")
local DisplayNameLabel = Frame:WaitForChild("DisplayNameLabel")
local UsernameLabel = Frame:WaitForChild("UsernameLabel")
local TimePlayedLabel = Frame:WaitForChild("TimePlayedLabel")
local InputIconsFrame = Frame:WaitForChild("InputIconsFrame")
local GiveRecognitionButton = Frame:WaitForChild("GiveRecognitionButton")
local RecognitionsLabel = Frame:WaitForChild("RecognitionsLabel")

local v2 = nil
local v3 = nil
local v4 = 0
local v5 = false

local v6 = { "Touch", "Keyboard", "Mouse", "Gamepad" }

local function formatTimePlayed(p)
	local v7 = math.max(0, (math.floor(tonumber(p) or 0)))
	local v8 = math.floor(v7 / 3600)
	local v9 = math.floor(v7 % 3600 / 60)

	if v8 > 0 then
		return string.format("%dh %dm", v8, v9)
	end

	if v9 > 0 then
		return string.format("%dm", v9)
	end

	return "<1m"
end

local function getClickedCharacter(p)
	local currentCamera = workspace.CurrentCamera

	if not currentCamera then
		return
	end

	local screenPointToRay = currentCamera:ScreenPointToRay(p.X, p.Y)
	local characters = {}

	for _, v7 in Players:GetPlayers() do
		if v7.Character then
			table.insert(characters, v7.Character)
		end
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = characters
	local raycastResult = workspace:Raycast(screenPointToRay.Origin, screenPointToRay.Direction * 50, raycastParams)

	if raycastResult then
		return raycastResult.Instance:FindFirstAncestorOfClass("Model")
	end
end

local function clearHighlight() -- 2 equivalent calls inferred from this helper
	if v3 then
		v3:Destroy()
		v3 = nil
	end
end

local function highlightCharacter(p)
	if v3 and v3.Adornee == p then
		return
	end

	clearHighlight() -- inferred equivalent call
	local clickHighlight = Instance.new("Highlight")
	clickHighlight.Name = "ClickHighlight"
	clickHighlight.FillTransparency = 1
	clickHighlight.OutlineColor = Color3.new(1, 1, 1)
	clickHighlight.OutlineTransparency = 0.5
	clickHighlight.Adornee = p
	clickHighlight.Parent = p
	clickHighlight.DepthMode = Enum.HighlightDepthMode.Occluded

	v3 = clickHighlight
end

local function hideProfile() -- 2 equivalent calls inferred from this helper
	clearHighlight() -- inferred equivalent call
	v2 = nil
	ViewProfileBillboardGui.Enabled = false
	GiveRecognitionButton.Visible = false
	ProfileViewPart.Parent = ReplicatedStorage
end

local function updateInputIcons(player)
	for _, childName in ipairs(v6) do
		local child = InputIconsFrame:FindFirstChild(childName)

		if child then
			child.Visible = player:GetAttribute("Input_" .. childName) == true
		end
	end
end

function ProfileViewClient.Init()
	ViewProfileBillboardGui.Adornee = ProfileViewPart
	ViewProfileBillboardGui.Enabled = false

	ViewProfileEvent.OnClientEvent:Connect(function(player, p: number, p2: number, flag: boolean)
		if not (player and player:IsA("Player")) then
			return
		end

		local character = player.Character

		if not character then
			return
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")

		if not humanoidRootPart then
			return
		end

		ReplicatedStorage.Assets.Sounds["Magic Glows Soft Clusters Of Chiming Hits 1 (SFX)"]:Play()
		ProfileViewPart.ProfileStarsParticles:Emit(1)
		v2 = player
		v4 = p2
		v5 = flag

		if not v3 or v3.Adornee ~= character then
			highlightCharacter(character)
		end

		ProfileViewPart.Parent = workspace
		ProfileViewPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, 4, 0)
		DisplayNameLabel.Text = player.DisplayName
		UsernameLabel.Text = "@" .. player.Name
		TimePlayedLabel.Text = formatTimePlayed(p)
		RecognitionsLabel.Text = "Recognitions - " .. p2
		AvatarImageLabel.Image = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=150&h=150`
		updateInputIcons(player)
		GiveRecognitionButton.Visible = player ~= LocalPlayer
		GiveRecognitionButton.ImageTransparency = flag and 0.75 or 0
		GiveRecognitionButton.UIStroke.Transparency = flag and 0.75 or 0
		GiveRecognitionButton.Active = not flag
		GiveRecognitionButton.AutoButtonColor = not flag
		GiveRecognitionButton.Active = not flag
		GiveRecognitionButton.AutoButtonColor = not flag
		ViewProfileBillboardGui.Enabled = true
	end)
end

function ProfileViewClient.Start()
	local position = nil
	local v7 = false

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.Touch then
			position = input.Position
			v7 = false
		else
			if gameProcessed or input.UserInputType ~= Enum.UserInputType.MouseButton1 then
				return
			end

			local clickedCharacter = getClickedCharacter(input.Position)

			if clickedCharacter then
				local playerFromCharacter = Players:GetPlayerFromCharacter(clickedCharacter)

				if not playerFromCharacter or playerFromCharacter == v2 then
					return
				end

				highlightCharacter(clickedCharacter)
				ViewProfileEvent:FireServer(playerFromCharacter)
			else
				hideProfile() -- inferred equivalent call
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch or not position then
			return
		end

		if (input.Position - position).Magnitude > 15 then
			v7 = true
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local v8 = position
		local v9 = v7

		position = nil
		v7 = false

		if gameProcessed or v9 or not v8 then
			return
		end

		local clickedCharacter = getClickedCharacter(v8)

		if clickedCharacter then
			local playerFromCharacter = Players:GetPlayerFromCharacter(clickedCharacter)

			if not playerFromCharacter or playerFromCharacter == v2 then
				return
			end

			highlightCharacter(clickedCharacter)
			ViewProfileEvent:FireServer(playerFromCharacter)
		else
			hideProfile() -- inferred equivalent call
		end
	end)

	GiveRecognitionButton.Activated:Connect(function()
		if not v2 or v2 == LocalPlayer or v5 then
			return
		end

		v5 = true

		local v8 = v2
		GiveRecognitionButton.ImageTransparency = 0.75
		GiveRecognitionButton.UIStroke.Transparency = 0.75
		GiveRecognitionButton.Active = false
		GiveRecognitionButton.AutoButtonColor = false

		GiveRecognitionEvent:FireServer(v8)

		v4 += 1
		RecognitionsLabel.Text = "Recognitions - " .. v4
	end)

	RecognitionNotificationEvent.OnClientEvent:Connect(function(player)
		StarterGui:SetCore("SendNotification", {
			Title = player.DisplayName,
			Text = "gave you a recognition 🤍",
			Icon = `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=150&h=150`,
			Duration = 4
		})
	end)
end

return ProfileViewClient