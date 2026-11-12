local QueueTopbar = {}

local module = require("./Icon")
local v = require("../Shared/Data")
v = v.client

local Players = game:GetService("Players")

local QueueRemotes = game.ReplicatedStorage.Remotes.QueueRemotes

local queueIcon = nil
local timerIcon = nil
local leaveQueueIcon = nil
local nextUserIcon = nil

local count = 0
local count2 = 0
local count3 = 0
local v2 = false

local profile = Instance.new("Frame")
profile.Name = "Profile"
profile.Size = UDim2.fromOffset(34, 28)
profile.BackgroundTransparency = 1
local avatar = Instance.new("ImageLabel")
avatar.Name = "Avatar"
avatar.Size = UDim2.fromOffset(28, 28)
avatar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)

avatar.Parent = profile
local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(1, 0)
uiCorner.Parent = avatar
local uiStroke = Instance.new("UIStroke")
uiStroke.Color = Color3.fromRGB(255, 255, 255)
uiStroke.Thickness = 0.5
uiStroke.Transparency = 0
uiStroke.Parent = avatar

function QueueTopbar.Start()
	queueIcon = module.new():setLabel("Queue"):setTextFont(Enum.Font.Fondamento):setEnabled(false):align("Left"):oneClick(true)
	QueueTopbar.QueueIcon = queueIcon

	nextUserIcon = module.new():setLabel("Next: Nobody"):addInstance(profile, "Right"):setTextFont(Enum.Font.Fondamento):oneClick(true):setEnabled(false)
	QueueTopbar.NextUserIcon = nextUserIcon

	timerIcon = module.new():setLabel("10:00"):setTextFont(Enum.Font.Fondamento):setEnabled(false):oneClick(true)
	QueueTopbar.TimerIcon = timerIcon

	leaveQueueIcon = module.new():setLabel("Leave Queue"):setTextFont(Enum.Font.Fondamento):setTextColor(Color3.fromRGB(255, 87, 90)):setEnabled(false):oneClick(true):bindEvent(
		"selected",
		QueueTopbar.LeaveQueue
	)
	QueueTopbar.LeaveQueueIcon = leaveQueueIcon
end

function QueueTopbar.SetPiano(instance)
	local sitPrompt = instance:WaitForChild("PianoSeat"):WaitForChild("SitPrompt")

	QueueRemotes.QueueStarted.OnClientEvent:Connect(function(p)
		count3 += 1
		local v3 = count3
		local v4 = os.clock() + p

		timerIcon:setEnabled(true)

		task.spawn(function()
			while v3 == count3 and os.clock() < v4 do
				local v5 = math.ceil(v4 - os.clock())
				timerIcon:setLabel(string.format("%d:%02d", math.floor(v5 / 60), v5 % 60))

				task.wait(1)
			end

			if v3 == count3 then
				timerIcon:setEnabled(false)
			end
		end)
	end)

	QueueRemotes.QueueUpdate.OnClientEvent:Connect(function(p, p2)
		count += 1
		queueIcon:setEnabled(true)

		if not v2 then
			queueIcon:setLabel("In Line: " .. p)
		end

		local playerByUserId = Players:GetPlayerByUserId(p2)
		nextUserIcon:setLabel("Next: " .. (playerByUserId.DisplayName or "None") .. "  ")
		avatar.Image = `rbxthumb://type=AvatarHeadShot&id={p2}&w=150&h=150`
		nextUserIcon:setEnabled(true)
		leaveQueueIcon:setEnabled(true)
	end)

	QueueRemotes.QueueTurn.OnClientEvent:Connect(function(p)
		count2 += 1
		local v3 = count2
		local v4 = os.clock() + p

		v2 = true
		sitPrompt.ActionText = "Sit"
		queueIcon:setEnabled(true)
		leaveQueueIcon:setEnabled(true)
		game.ReplicatedStorage.Assets.Sounds["Magic Glows Soft Clusters Of Chiming Hits 2 (SFX)"]:Play()

		task.spawn(function()
			while v3 == count2 and os.clock() < v4 do
				local v5 = math.ceil(v4 - os.clock())
				queueIcon:setLabel("Your Turn: " .. v5 .. "s")
				task.wait(1)
			end
		end)
	end)

	QueueRemotes.QueueLeft.OnClientEvent:Connect(function(p)
		count += 1
		count2 += 1
		count3 += 1
		v2 = false
		queueIcon:setEnabled(false)
		nextUserIcon:setEnabled(false)
		timerIcon:setEnabled(false)
		leaveQueueIcon:setEnabled(false)
		sitPrompt.ActionText = p == 1 and "Sit" or "Queue"
	end)

	QueueRemotes.QueueEnded.OnClientEvent:Connect(function()
		count3 += 1
		timerIcon:setEnabled(false)
	end)
end

function QueueTopbar.LeaveQueue()
	QueueRemotes.LeaveQueue:FireServer()
end

return QueueTopbar