return {
	Start = function()
		local UserInputService = game:GetService("UserInputService")
		local virtualInput = UserInputService:CreateVirtualInput()

		if not virtualInput then
			return
		end

		local lastTime = os.clock()
		local function updateLastInputTime() -- 2 equivalent calls inferred from this helper
			lastTime = os.clock()
		end

		UserInputService.InputBegan:Connect(updateLastInputTime)
		UserInputService.InputChanged:Connect(function(input)
			if
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.MouseWheel
				or input.UserInputType == Enum.UserInputType.Touch
			then
				updateLastInputTime() -- inferred equivalent call
			end
		end)

		task.spawn(function()
			while task.wait(30) do
				if os.clock() - lastTime < 900 then
					continue
				end

				pcall(function()
					print("AFK Mode")
					virtualInput:SendMouseButton(Vector2.zero, Enum.UserInputType.MouseButton2, true, 0)
					task.wait(0.1)
					virtualInput:SendMouseButton(Vector2.zero, Enum.UserInputType.MouseButton2, false, 0)
				end)
				updateLastInputTime() -- inferred equivalent call
			end
		end)
	end
}