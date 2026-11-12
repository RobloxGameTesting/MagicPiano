local Utility = require(script.Parent.Parent.Utility)
return function(_)
	local selectionContainer = Instance.new("Frame")
	selectionContainer.Name = "SelectionContainer"
	selectionContainer.Visible = false

	local selection = Instance.new("Frame")
	selection.Name = "Selection"
	selection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	selection.BackgroundTransparency = 1
	selection.BorderColor3 = Color3.fromRGB(0, 0, 0)
	selection.BorderSizePixel = 0
	selection.Parent = selectionContainer

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Name = "UIStroke"
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	uiStroke.Color = Color3.fromRGB(255, 255, 255)
	uiStroke.Thickness = 3
	uiStroke.Parent = selection

	local selectionGradient = Instance.new("UIGradient")
	selectionGradient.Name = "SelectionGradient"
	selectionGradient.Parent = uiStroke

	local uiCorner = Instance.new("UICorner")
	uiCorner:SetAttribute("Collective", "IconCorners")
	uiCorner.Name = "UICorner"
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = selection

	local RunService = game:GetService("RunService")
	local GuiService = game:GetService("GuiService")
	local v = 1
	selection:GetAttributeChangedSignal("RotationSpeed"):Connect(function()
		v = selection:GetAttribute("RotationSpeed")
	end)
	RunService.Heartbeat:Connect(function()
		if GuiService.SelectedObject and not Utility.isReducedMotion() then
			selectionGradient.Rotation = os.clock() * v * 100 % 360
		end
	end)

	return selectionContainer
end