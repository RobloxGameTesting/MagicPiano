return function(object, p)
	local Utility = require(script.Parent.Parent.Utility)
	local v = false

	local widget = Instance.new("Frame")
	widget:SetAttribute("WidgetUID", object.UID)
	widget.Name = "Widget"
	widget.BackgroundTransparency = 1
	widget.Visible = true
	widget.ZIndex = 20
	widget.Active = false
	widget.ClipsDescendants = true

	local iconButton = Instance.new("Frame")
	iconButton.Name = "IconButton"
	iconButton.Visible = true
	iconButton.ZIndex = 2
	iconButton.BorderSizePixel = 0
	iconButton.Parent = widget
	iconButton.ClipsDescendants = true
	iconButton.Active = false
	object.deselected:Connect(function()
		iconButton.ClipsDescendants = true
		task.delay(0.2, function()
			if object.isSelected then
				iconButton.ClipsDescendants = false
			end
		end)
	end)

	local GuiService = game:GetService("GuiService")
	object:setBehaviour("IconButton", "BackgroundTransparency", function(p2)
		local v2 = p2 * GuiService.PreferredTransparency
		return if p2 == 1 then 1 else v2
	end)

	object.janitor:add(GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(function()
		object:refreshAppearance(iconButton, "BackgroundTransparency")
	end))

	local uiCorner = Instance.new("UICorner")
	uiCorner:SetAttribute("Collective", "IconCorners")
	uiCorner.Name = "UICorner"
	uiCorner.Parent = iconButton

	local Menu = require(script.Parent.Menu)
	local parent = Menu(object)
	local menuUIListLayout = parent.MenuUIListLayout
	local menuGap = parent.MenuGap
	parent.Parent = iconButton

	local iconSpot = Instance.new("Frame")
	iconSpot.Name = "IconSpot"
	iconSpot.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
	iconSpot.BackgroundTransparency = 0.9
	iconSpot.Visible = true
	iconSpot.AnchorPoint = Vector2.new(0, 0.5)
	iconSpot.ZIndex = 5
	iconSpot.Parent = parent

	local clone = uiCorner:Clone()
	clone.Parent = iconSpot

	local iconOverlay = iconSpot:Clone()
	iconOverlay.UICorner.Name = "OverlayUICorner"
	iconOverlay.Name = "IconOverlay"
	iconOverlay.BackgroundColor3 = Color3.fromRGB(208, 217, 251)
	iconOverlay.ZIndex = iconSpot.ZIndex + 1
	iconOverlay.Size = UDim2.new(1, 0, 1, 0)
	iconOverlay.Position = UDim2.new(0, 0, 0, 0)
	iconOverlay.AnchorPoint = Vector2.new(0, 0)
	iconOverlay.Visible = false
	iconOverlay.Parent = iconSpot

	local clickRegion = Instance.new("TextButton")
	clickRegion:SetAttribute("CorrespondingIconUID", object.UID)
	clickRegion.Name = "ClickRegion"
	clickRegion.BackgroundTransparency = 1
	clickRegion.Visible = true
	clickRegion.Text = ""
	clickRegion.ZIndex = 20
	clickRegion.Selectable = true
	clickRegion.SelectionGroup = true
	clickRegion.Parent = iconSpot

	local Gamepad = require(script.Parent.Parent.Features.Gamepad)
	Gamepad.registerButton(clickRegion)

	local clone_2 = uiCorner:Clone()
	clone_2.Parent = clickRegion

	local contents = Instance.new("Frame")
	contents.Name = "Contents"
	contents.BackgroundTransparency = 1
	contents.Size = UDim2.fromScale(1, 1)
	contents.Parent = iconSpot

	local contentsList = Instance.new("UIListLayout")
	contentsList.Name = "ContentsList"
	contentsList.FillDirection = Enum.FillDirection.Horizontal
	contentsList.VerticalAlignment = Enum.VerticalAlignment.Center
	contentsList.SortOrder = Enum.SortOrder.LayoutOrder
	contentsList.VerticalFlex = Enum.UIFlexAlignment.SpaceEvenly
	contentsList.Padding = UDim.new(0, 3)
	contentsList.Parent = contents

	local paddingLeft = Instance.new("Frame")
	paddingLeft.Name = "PaddingLeft"
	paddingLeft.LayoutOrder = 0
	paddingLeft.ZIndex = 5
	paddingLeft.BorderColor3 = Color3.fromRGB(0, 0, 0)
	paddingLeft.BackgroundTransparency = 1
	paddingLeft.BorderSizePixel = 0
	paddingLeft.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	paddingLeft.Parent = contents

	local paddingCenter = Instance.new("Frame")
	paddingCenter.Name = "PaddingCenter"
	paddingCenter.LayoutOrder = 3
	paddingCenter.ZIndex = 5
	paddingCenter.Size = UDim2.new(0, 0, 1, 0)
	paddingCenter.BorderColor3 = Color3.fromRGB(0, 0, 0)
	paddingCenter.BackgroundTransparency = 1
	paddingCenter.BorderSizePixel = 0
	paddingCenter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	paddingCenter.Parent = contents

	local paddingRight = Instance.new("Frame")
	paddingRight.Name = "PaddingRight"
	paddingRight.LayoutOrder = 7
	paddingRight.ZIndex = 5
	paddingRight.BorderColor3 = Color3.fromRGB(0, 0, 0)
	paddingRight.BackgroundTransparency = 1
	paddingRight.BorderSizePixel = 0
	paddingRight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	paddingRight.Parent = contents

	local iconLabelContainer = Instance.new("Frame")
	iconLabelContainer.Name = "IconLabelContainer"
	iconLabelContainer.LayoutOrder = 4
	iconLabelContainer.ZIndex = 3
	iconLabelContainer.AnchorPoint = Vector2.new(0, 0.5)
	iconLabelContainer.Size = UDim2.new(0, 0, 0.5, 0)
	iconLabelContainer.BackgroundTransparency = 1
	iconLabelContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	iconLabelContainer.Parent = contents

	local iconLabel = Instance.new("TextLabel")
	local v2 = workspace.CurrentCamera.ViewportSize.X + 200
	iconLabel.Name = "IconLabel"
	iconLabel.LayoutOrder = 4
	iconLabel.ZIndex = 15
	iconLabel.AnchorPoint = Vector2.new(0, 0)
	iconLabel.Size = UDim2.new(0, v2, 1, 0)
	iconLabel.ClipsDescendants = false
	iconLabel.BackgroundTransparency = 1
	iconLabel.Position = UDim2.fromScale(0, 0)
	iconLabel.RichText = true
	iconLabel.TextColor3 = Color3.fromRGB(247, 247, 248)
	iconLabel.TextXAlignment = Enum.TextXAlignment.Left
	iconLabel.Text = ""
	iconLabel.TextWrapped = true
	iconLabel.TextScaled = false
	iconLabel.Active = false
	iconLabel.AutoLocalize = true
	iconLabel.Parent = iconLabelContainer

	local iconImage = Instance.new("ImageLabel")
	iconImage.Name = "IconImage"
	iconImage.LayoutOrder = 2
	iconImage.ZIndex = 15
	iconImage.AnchorPoint = Vector2.new(0, 0.5)
	iconImage.Size = UDim2.new(0, 0, 0.5, 0)
	iconImage.BackgroundTransparency = 1
	iconImage.Position = UDim2.new(0, 11, 0.5, 0)
	iconImage.ScaleType = Enum.ScaleType.Stretch
	iconImage.Active = false
	iconImage.Parent = contents

	local iconImageCorner = uiCorner:Clone()
	iconImageCorner:SetAttribute("Collective", nil)
	iconImageCorner.CornerRadius = UDim.new(0, 0)
	iconImageCorner.Name = "IconImageCorner"
	iconImageCorner.Parent = iconImage

	local TweenService = game:GetService("TweenService")
	local v3 = 0
	local function handleLabelAndImageChangesUnstaggered(_)
		task.defer(function()
			local indicator = object.indicator
			local visible = indicator and indicator.Visible
			local v4 = visible or iconLabel.Text ~= ""
			local v5 = iconImage.Image ~= "" or iconImage.ImageContent.SourceType ~= Enum.ContentSourceType.None
			local _center = Enum.HorizontalAlignment.Center
			local udim = UDim2.fromScale(1, 1)

			if v5 and not v4 then
				iconLabelContainer.Visible = false
				iconImage.Visible = true
				paddingLeft.Visible = false
				paddingCenter.Visible = false
				paddingRight.Visible = false
			elseif v5 or not v4 then
				if v5 and v4 then
					iconLabelContainer.Visible = true
					iconImage.Visible = true
					paddingLeft.Visible = true
					paddingCenter.Visible = not visible
					paddingRight.Visible = not visible
					local _left = Enum.HorizontalAlignment.Left
				end
			else
				iconLabelContainer.Visible = true
				iconImage.Visible = false
				paddingLeft.Visible = true
				paddingCenter.Visible = false
				paddingRight.Visible = true
			end

			iconButton.Size = udim

			local function getItemWidth(instance)
				local targetWidth = instance:GetAttribute("TargetWidth")

				if targetWidth then
					return targetWidth
				end

				local automaticSize = instance.AutomaticSize
				local v6 = automaticSize == Enum.AutomaticSize.X or automaticSize == Enum.AutomaticSize.XY

				if instance.Size.X.Scale == 0 and not v6 then
					return instance.Size.X.Offset
				end

				return instance.AbsoluteSize.X
			end

			local offset = contentsList.Padding.Offset

			local x = iconLabel.TextBounds.X
			iconLabelContainer.Size = UDim2.new(0, x, iconLabel.Size.Y.Scale, 0)
			local v6 = offset

			for _, guiObject in pairs(contents:GetChildren()) do
				if guiObject:IsA("GuiObject") and guiObject.Visible == true then
					v6 += getItemWidth(guiObject) + offset
				end
			end

			local minimumWidth = widget:GetAttribute("MinimumWidth")
			local minimumHeight = widget:GetAttribute("MinimumHeight")
			local borderSize = widget:GetAttribute("BorderSize")
			local v7 = math.clamp(v6, minimumWidth, (math.max(v2, minimumWidth)))

			local v8 = 0
			local isSelected = #object.menuIcons > 0 and object.isSelected

			if isSelected then
				for _, guiObject in pairs(parent:GetChildren()) do
					if guiObject ~= iconSpot and guiObject:IsA("GuiObject") and guiObject.Visible then
						v8 += getItemWidth(guiObject) + menuUIListLayout.Padding.Offset
					end
				end

				if not iconSpot.Visible then
					v7 -= getItemWidth(iconSpot) + menuUIListLayout.Padding.Offset * 2 + borderSize
				end

				v8 -= borderSize * 0.5
				v7 += v8 - borderSize * 0.75
			end

			menuGap.Visible = isSelected and iconSpot.Visible
			local desiredWidth = widget:GetAttribute("DesiredWidth")

			if desiredWidth and v7 < desiredWidth then
				v7 = desiredWidth
			end

			object.updateMenu:Fire()
			local v9 = math.max(v7 - v8, minimumWidth) - borderSize * 2
			local v10 = object.isSelected and #object.menuIcons == 3 and 50 or v9
			local menuWidth = parent:GetAttribute("MenuWidth")
			local v11 = menuWidth and menuWidth + v10 + menuUIListLayout.Padding.Offset + 10

			if v11 then
				local maxWidth = parent:GetAttribute("MaxWidth")

				if maxWidth then
					v11 = math.max(maxWidth, minimumWidth)
				end

				parent:SetAttribute("MenuCanvasWidth", v7)

				if v11 < v7 then
					v7 = v11
				end
			end

			local quint = Enum.EasingStyle.Quint
			local out = Enum.EasingDirection.Out
			local v12 = math.max(v10, getItemWidth(iconSpot), iconSpot.AbsoluteSize.X)
			local v13 = math.max(v7, getItemWidth(widget), widget.AbsoluteSize.X)

			local v14 = not v and contents.AbsoluteSize.Y > 0

			if v14 then
				v = true
			end

			local v15

			if v14 then
				v15 = TweenInfo.new(0)
			else
				v15 = Utility.getTweenInfo(TweenInfo.new(v12 / 750, quint, out))
			end

			local v16

			if v14 then
				v16 = TweenInfo.new(0)
			else
				v16 = Utility.getTweenInfo(TweenInfo.new(v13 / 750, quint, out))
			end

			TweenService:Create(iconSpot, v15, {
				Position = UDim2.new(0, borderSize, 0.5, 0),
				Size = UDim2.new(0, v10, 1, -borderSize * 2)
			}):Play()
			TweenService:Create(clickRegion, v15, { Size = UDim2.new(0, v10, 1, 0) }):Play()
			local udim2 = UDim2.fromOffset(v7, minimumHeight)

			if widget.Size.Y.Offset ~= minimumHeight then
				widget.Size = udim2
			end

			widget:SetAttribute("TargetWidth", udim2.X.Offset)
			TweenService:Create(widget, v16, { Size = udim2 }):Play()
			v3 += 1

			for i = 1, math.max(v16.Time * 100, 1) do
				task.delay(i / 100, function()
					p.iconChanged:Fire(object)
				end)
			end

			task.delay(v16.Time - 0.2, function()
				v3 -= 1
				task.defer(function()
					if v3 == 0 then
						object.resizingComplete:Fire()
					end
				end)
			end)
			object:updateParent()
		end)
	end
	local stagger = Utility.createStagger(0.01, handleLabelAndImageChangesUnstaggered)

	local v4 = contents.AbsoluteSize.Y
	contents:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local y = contents.AbsoluteSize.Y

		if y ~= v4 then
			v4 = y
			stagger()
		end
	end)
	iconLabel:GetPropertyChangedSignal("TextBounds"):Connect(stagger)
	local flag = true
	object:setBehaviour("IconLabel", "Text", stagger)
	object:setBehaviour("IconLabel", "FontFace", function(p2)
		if iconLabel.FontFace == p2 then
			return
		end

		task.spawn(function()
			stagger()

			if flag then
				flag = false

				for _ = 1, 10 do
					task.wait(1)
					stagger()
				end
			end
		end)
	end)
	local function updateBorderSize() -- 1 equivalent call inferred from this helper
		task.defer(function()
			local borderSize = widget:GetAttribute("BorderSize")
			local alignment = object.alignment
			local v5

			if iconSpot.Visible == false then
				v5 = 0
			elseif alignment == "Right" then
				v5 = -borderSize or borderSize
			else
				v5 = borderSize
			end

			parent.Position = UDim2.new(0, v5, 0, 0)
			menuGap.Size = UDim2.fromOffset(borderSize, 0)
			menuUIListLayout.Padding = UDim.new(0, 0)
			stagger()
		end)
	end
	object:setBehaviour("Widget", "BorderSize", updateBorderSize)
	object:setBehaviour("IconSpot", "Visible", updateBorderSize)
	object.startMenuUpdate:Connect(stagger)
	object.updateSize:Connect(stagger)
	object:setBehaviour("ContentsList", "HorizontalAlignment", stagger)
	object:setBehaviour("Widget", "Visible", stagger)
	object:setBehaviour("Widget", "DesiredWidth", stagger)
	object:setBehaviour("Widget", "MinimumWidth", stagger)
	object:setBehaviour("PaddingLeft", "Size", stagger)
	object:setBehaviour("PaddingCenter", "Size", stagger)
	object:setBehaviour("PaddingRight", "Size", stagger)
	object:setBehaviour("Widget", "MinimumHeight", stagger)
	object:setBehaviour("Indicator", "Visible", stagger)
	object:setBehaviour("IconImageRatio", "AspectRatio", stagger)
	object:setBehaviour("IconImage", "Image", function(value)
		local v5 = typeof(value) == "Content"

		if not v5 then
			value = not tonumber(value) and (value or "") or `rbxassetid://{value}`
		end

		local v6

		if v5 then
			v6 = iconImage.ImageContent
		else
			v6 = iconImage.Image
		end

		if v6 ~= value then
			stagger()
		end

		return value
	end)

	object.alignmentChanged:Connect(function(p2)
		local v5 = p2 == "Center" and "Left" or p2

		menuUIListLayout.HorizontalAlignment = Enum.HorizontalAlignment[v5]
		updateBorderSize() -- inferred equivalent call
	end)

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
	local v5 = localPlayer.LocaleId
	object.janitor:add(localPlayer:GetPropertyChangedSignal("LocaleId"):Connect(function()
		task.delay(0.2, function()
			local localeId = localPlayer.LocaleId

			if localeId ~= v5 then
				v5 = localeId
				object:refresh()
				task.wait(0.5)
				object:refresh()
			end
		end)
	end))

	local iconImageScale = Instance.new("NumberValue")
	iconImageScale.Name = "IconImageScale"
	iconImageScale.Parent = iconImage
	iconImageScale:GetPropertyChangedSignal("Value"):Connect(function()
		iconImage.Size = UDim2.new(iconImageScale.Value, 0, iconImageScale.Value, 0)
	end)

	local iconImageRatio = Instance.new("UIAspectRatioConstraint")
	iconImageRatio.Name = "IconImageRatio"
	iconImageRatio.AspectType = Enum.AspectType.FitWithinMaxSize
	iconImageRatio.DominantAxis = Enum.DominantAxis.Height
	iconImageRatio.Parent = iconImage

	local iconGradient = Instance.new("UIGradient")
	iconGradient.Name = "IconGradient"
	iconGradient.Enabled = true
	iconGradient.Parent = iconButton

	local iconSpotGradient = Instance.new("UIGradient")
	iconSpotGradient.Name = "IconSpotGradient"
	iconSpotGradient.Enabled = true
	iconSpotGradient.Parent = iconSpot

	return widget
end