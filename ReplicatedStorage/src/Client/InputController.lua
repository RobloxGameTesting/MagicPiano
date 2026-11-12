local ReplicatedStorage = game:GetService("ReplicatedStorage")
local client = ReplicatedStorage.src.Client

local InputService = require(client.Services.InputService)
local PlayerService = require(client.Services.PlayerService)
local Sprint = require(client.Sprint)

local sprintButton = PlayerService.PlayerGui():WaitForChild("MobileButtonsGui", 30):WaitForChild("MobileButtons"):WaitForChild("SprintButton")
local action = InputService.GetAction("idle", "ToggleSprint")
action.KeyboardBinding.KeyCode = Enum.KeyCode.LeftControl

if sprintButton then
	action.UIBinding.UIButton = sprintButton
end

action.Pressed:Connect(Sprint.Toggle)
return {}