return {
	Start = function()
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local UserInputService = game:GetService("UserInputService")
		local detectDeviceEvent = ReplicatedStorage.Remotes:WaitForChild("DetectDeviceEvent")
		local function getDeviceInputs() -- 1 equivalent call inferred from this helper
			local deviceInputs = {}

			if UserInputService.TouchEnabled then
				table.insert(deviceInputs, "Touch")
			end

			if UserInputService.KeyboardEnabled then
				table.insert(deviceInputs, "Keyboard")
			end

			if UserInputService.MouseEnabled then
				table.insert(deviceInputs, "Mouse")
			end

			if UserInputService.GamepadEnabled then
				table.insert(deviceInputs, "Gamepad")
			end

			return deviceInputs
		end

		local function updateDevice() -- 1 equivalent call inferred from this helper
			detectDeviceEvent:FireServer(getDeviceInputs()) -- inferred equivalent call
		end

		updateDevice() -- inferred equivalent call

		for _, propertyName in ipairs({
			"TouchEnabled",
			"KeyboardEnabled",
			"MouseEnabled",
			"GamepadEnabled"
		}) do
			UserInputService:GetPropertyChangedSignal(propertyName):Connect(updateDevice)
		end
	end
}