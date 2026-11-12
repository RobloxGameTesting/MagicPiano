return function(object, _)
	local widget = object.widget
	local instance = object:getInstance("Contents")
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.LayoutOrder = 9999999
	indicator.ZIndex = 6
	indicator.Size = UDim2.new(0, 42, 0, 42)
	indicator.BorderColor3 = Color3.fromRGB(0, 0, 0)
	indicator.BackgroundTransparency = 1
	indicator.Position = UDim2.new(1, 0, 0.5, 0)
	indicator.BorderSizePixel = 0
	indicator.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	indicator.Parent = instance

	local indicatorButton = Instance.new("Frame")
	indicatorButton.Name = "IndicatorButton"
	indicatorButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
	indicatorButton.AnchorPoint = Vector2.new(0.5, 0.5)
	indicatorButton.BorderSizePixel = 0
	indicatorButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	indicatorButton.Parent = indicator

	local GuiService = game:GetService("GuiService")
	local GamepadService = game:GetService("GamepadService")
	local instance2 = object:getInstance("ClickRegion")
	local function selectionChanged()
		if GuiService.SelectedObject == instance2 then
			indicatorButton.BackgroundTransparency = 1
			indicatorButton.Position = UDim2.new(0.5, -2, 0.5, 0)
			indicatorButton.Size = UDim2.fromScale(1.2, 1.2)
		else
			indicatorButton.BackgroundTransparency = 0.75
			indicatorButton.Position = UDim2.new(0.5, 2, 0.5, 0)
			indicatorButton.Size = UDim2.fromScale(1, 1)
		end
	end
	object.janitor:add(GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(selectionChanged))
	selectionChanged()

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.LayoutOrder = 2
	imageLabel.ZIndex = 15
	imageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	imageLabel.Size = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	imageLabel.Image = "rbxasset://textures/ui/Controls/XboxController/DPadUp@2x.png"
	imageLabel.Parent = indicatorButton

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = indicatorButton

	local UserInputService = game:GetService("UserInputService")
	local function setIndicatorVisible(p)
		if p == nil then
			p = indicator.Visible
		end

		if GamepadService.GamepadCursorEnabled then
			p = false
		end

		if p then
			object:modifyTheme({ "PaddingRight", "Size", UDim2.new(0, 0, 1, 0) }, "IndicatorPadding")
		elseif indicator.Visible then
			object:removeModification("IndicatorPadding")
		end

		object:modifyTheme({ "Indicator", "Visible", p })
		object.updateSize:Fire()
	end
	object.janitor:add(GamepadService:GetPropertyChangedSignal("GamepadCursorEnabled"):Connect(setIndicatorVisible))
	object.indicatorSet:Connect(function(p)
		local v

		if p then
			imageLabel.Image = UserInputService:GetImageForKeyCode(p)
			v = true
		else
			v = false
		end

		setIndicatorVisible(v)
	end)

	local function updateSize() -- 1 equivalent call inferred from this helper
		local v = widget.AbsoluteSize.Y * 0.96
		indicator.Size = UDim2.new(0, v, 0, v)
	end
	widget:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateSize)
	updateSize() -- inferred equivalent call
	return indicator
end