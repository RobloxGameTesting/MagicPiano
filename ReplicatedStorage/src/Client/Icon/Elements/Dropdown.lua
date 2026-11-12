local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Themes = require(script.Parent.Parent.Features.Themes)
local Utility = require(script.Parent.Parent.Utility)

return function(object)
	local dropdown = Instance.new("Frame")
	dropdown.Name = "Dropdown"
	dropdown.AutomaticSize = Enum.AutomaticSize.X
	dropdown.BackgroundTransparency = 1
	dropdown.BorderSizePixel = 0
	dropdown.AnchorPoint = Vector2.new(0.5, 0)
	dropdown.Position = UDim2.new(0.5, 0, 1, 10)
	dropdown.ZIndex = -2
	dropdown.ClipsDescendants = true
	dropdown.Parent = object.widget

	local GuiService = game:GetService("GuiService")
	object:setBehaviour("Dropdown", "BackgroundTransparency", function(p)
		local v = p * GuiService.PreferredTransparency
		return if p == 1 then 1 else v
	end)

	object.janitor:add(GuiService:GetPropertyChangedSignal("PreferredTransparency"):Connect(function()
		object:refreshAppearance(dropdown, "BackgroundTransparency")
	end))

	local dropdownCorner = Instance.new("UICorner")
	dropdownCorner.Name = "DropdownCorner"
	dropdownCorner.CornerRadius = UDim.new(0, 8)
	dropdownCorner.Parent = dropdown

	local dropdownScroller = Instance.new("ScrollingFrame")
	dropdownScroller.Name = "DropdownScroller"
	dropdownScroller.AutomaticSize = Enum.AutomaticSize.X
	dropdownScroller.BackgroundTransparency = 1
	dropdownScroller.BorderSizePixel = 0
	dropdownScroller.AnchorPoint = Vector2.new(0, 0)
	dropdownScroller.Position = UDim2.new(0, 0, 0, 0)
	dropdownScroller.ZIndex = -1
	dropdownScroller.ClipsDescendants = true
	dropdownScroller.Visible = true
	dropdownScroller.VerticalScrollBarInset = Enum.ScrollBarInset.None
	dropdownScroller.VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Right
	dropdownScroller.Active = false
	dropdownScroller.ScrollingEnabled = true
	dropdownScroller.AutomaticCanvasSize = Enum.AutomaticSize.Y
	dropdownScroller.ScrollBarThickness = 5
	dropdownScroller.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	dropdownScroller.ScrollBarImageTransparency = 0.8
	dropdownScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
	dropdownScroller.Selectable = false
	dropdownScroller.Active = true
	dropdownScroller.Parent = dropdown

	local dropdownSpeed = Instance.new("NumberValue")
	dropdownSpeed.Name = "DropdownSpeed"
	dropdownSpeed.Value = 0.07
	dropdownSpeed.Parent = dropdown

	local dropdownPadding = Instance.new("UIPadding")
	dropdownPadding.Name = "DropdownPadding"
	dropdownPadding.PaddingTop = UDim.new(0, 0)
	dropdownPadding.PaddingBottom = UDim.new(0, 0)
	dropdownPadding.Parent = dropdownScroller

	local dropdownList = Instance.new("UIListLayout")
	dropdownList.Name = "DropdownList"
	dropdownList.FillDirection = Enum.FillDirection.Vertical
	dropdownList.SortOrder = Enum.SortOrder.LayoutOrder
	dropdownList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dropdownList.HorizontalFlex = Enum.UIFlexAlignment.SpaceEvenly
	dropdownList.Parent = dropdownScroller

	local dropdownJanitor = object.dropdownJanitor
	local iconModule = require(object.iconModule)
	object.dropdownChildAdded:Connect(function(object2)
		local v = {
			{ "Widget", "BorderSize", 0 },
			{ "IconCorners", "CornerRadius", UDim.new(0, 8) },
			{ "Widget", "MinimumWidth", 192 },
			{ "Widget", "MinimumHeight", 56 },
			{ "IconLabel", "TextSize", 20 },
			{ "IconOverlay", "Size", UDim2.new(1, 0, 1, 0) },
			{ "PaddingLeft", "Size", UDim2.fromOffset(15, 0) },
			{ "PaddingCenter", "Size", UDim2.fromOffset(12, 0) },
			{ "Notice", "Position", UDim2.new(1, -24, 0, 5) },
			{ "ContentsList", "HorizontalAlignment", Enum.HorizontalAlignment.Left },
			{ "Selection", "Size", UDim2.new(1, -0, 1, -0) },
			{ "Selection", "Position", UDim2.new(0, 0, 0, 0) }
		}

		local themeValue = Themes.getThemeValue(object2:getStateGroup("Deselected"), "IconImageScale", "Value")

		if themeValue == nil or themeValue == 0.5 then
			table.insert(v, { "IconImageScale", "Value", 0.45 })
		end

		local _, v2 = object2:modifyTheme(v)
		task.defer(function()
			object2.joinJanitor:add(function()
				object2:removeModification(v2)
			end)
		end)
	end)
	object.dropdownSet:Connect(function(items)
		for _, dropdownIcon in pairs(object.dropdownIcons) do
			iconModule.getIconByUID(dropdownIcon):destroy()
		end

		if type(items) == "table" then
			for _, item in pairs(items) do
				item:joinDropdown(object)
			end
		end
	end)

	local function updateMaxIcons()
		local maxIcons = dropdown:GetAttribute("MaxIcons")

		if not maxIcons then
			return 0
		end

		local guiObjects = {}

		for _, guiObject in pairs(dropdownScroller:GetChildren()) do
			if guiObject:IsA("GuiObject") and guiObject.Visible then
				table.insert(guiObjects, guiObject)
			end
		end

		table.sort(guiObjects, function(a, b): boolean
			return a.AbsolutePosition.Y < b.AbsolutePosition.Y
		end)

		local v = math.ceil(maxIcons)
		local total = 0
		local count = 0

		for i = 1, v do
			local v2 = guiObjects[i]

			if not v2 then
				break
			end

			local y = v2.AbsoluteSize.Y
			local v3

			if i == v then
				v3 = v ~= maxIcons
			else
				v3 = false
			end

			if v3 then
				y *= maxIcons - v + 1
			end

			total += y
			count += 1
		end

		return total + dropdownList.Padding.Offset * math.max(count - 1, 0) + (dropdownPadding.PaddingTop.Offset + dropdownPadding.PaddingBottom.Offset)
	end

	local v = nil
	local v2 = nil
	local v3 = nil
	local v4 = nil
	local function getTweenInfo() -- 2 equivalent calls inferred from this helper
		local v5 = Themes.getInstanceValue(dropdown, "MaxIcons") or 1

		if v3 and v3 == v5 and v4 then
			return v4
		end

		local tweenInfo = TweenInfo.new(
			dropdownSpeed.Value * v5,
			Enum.EasingStyle.Exponential,
			Enum.EasingDirection.Out
		)

		v4 = tweenInfo
		v3 = v5
		return tweenInfo
	end

	local function updateVisibility()
		local tweenInfo = getTweenInfo() -- inferred equivalent call

		if v then
			v:Cancel()
			v = nil
		end

		if v2 then
			v2:Cancel()
			v2 = nil
		end

		if object.isSelected then
			local v5 = updateMaxIcons()
			dropdown.Visible = true
			dropdown.BackgroundTransparency = 0
			dropdown.Size = UDim2.new(0, dropdown.Size.X.Offset, 0, 0)

			v = TweenService:Create(dropdown, Utility.getTweenInfo(tweenInfo), {
				Size = UDim2.new(0, dropdown.Size.X.Offset, 0, v5)
			})
			v:Play()
			v.Completed:Connect(function()
				v = nil
			end)
		else
			v2 = TweenService:Create(dropdown, TweenInfo.new(0), {
				Size = UDim2.new(0, dropdown.Size.X.Offset, 0, 0)
			})
			v2:Play()
			v2.Completed:Connect(function()
				v2 = nil
			end)
		end
	end

	dropdownJanitor:add(object.toggled:Connect(updateVisibility))
	updateVisibility()

	local function updateChildSize()
		local tweenInfo = getTweenInfo() -- inferred equivalent call

		if not object.isSelected then
			return
		end

		if v then
			v:Cancel()
			v = nil
		end

		if v2 then
			v2:Cancel()
			v2 = nil
		end

		RunService.Heartbeat:Wait()

		local v5 = updateMaxIcons()

		v = TweenService:Create(dropdown, Utility.getTweenInfo(tweenInfo), {
			Size = UDim2.new(0, dropdown.Size.X.Offset, 0, v5)
		})
		v:Play()
		v.Completed:Connect(function()
			v = nil
		end)
	end

	dropdownJanitor:add(object.toggled:Connect(updateVisibility))

	local count = 0
	local flag = false
	local function updateMaxIconsListener()
		count += 1

		if flag then
			return
		end

		local v5 = count
		flag = true
		task.defer(function()
			flag = false

			if count ~= v5 then
				updateMaxIconsListener()
			end
		end)
		local maxIcons = dropdown:GetAttribute("MaxIcons")

		if not maxIcons then
			return
		end

		local v6 = {}

		for _, guiObject in pairs(dropdownScroller:GetChildren()) do
			if guiObject:IsA("GuiObject") and guiObject.Visible then
				table.insert(v6, { guiObject, guiObject.AbsolutePosition.Y })
			end
		end

		table.sort(v6, function(a, b): boolean
			return a[2] < b[2]
		end)

		local v7 = math.ceil(maxIcons)
		local total = 0
		local count2 = 0
		local flag2 = false

		for i = 1, v7 do
			local v8 = v6[i]

			if not v8 then
				break
			end

			local v9 = v8[1]
			local y = v9.AbsoluteSize.Y
			local v10

			if i == v7 then
				v10 = v7 ~= maxIcons
			else
				v10 = false
			end

			if v10 then
				y *= maxIcons - v7 + 1
			end

			total += y
			count2 += 1

			if v10 then
				continue
			end

			local widgetUID = v9:GetAttribute("WidgetUID")
			local v11 = widgetUID and iconModule.getIconByUID(widgetUID)

			if not v11 then
				continue
			end

			local nextSelectionUp

			if not flag2 then
				nextSelectionUp = object:getInstance("ClickRegion")
				flag2 = true
			end

			local instance = v11:getInstance("ClickRegion")
			instance.NextSelectionUp = nextSelectionUp
		end

		local v8 = total + dropdownList.Padding.Offset * math.max(count2 - 1, 0) + (dropdownPadding.PaddingTop.Offset + dropdownPadding.PaddingBottom.Offset)

		dropdownScroller.Size = UDim2.fromOffset(0, v8)
	end

	dropdownJanitor:add(dropdownScroller:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateMaxIconsListener))
	dropdownJanitor:add(dropdownScroller.ChildAdded:Connect(updateMaxIconsListener))
	dropdownJanitor:add(dropdownScroller.ChildRemoved:Connect(updateChildSize))
	dropdownJanitor:add(dropdownScroller.ChildRemoved:Connect(updateMaxIconsListener))
	dropdownJanitor:add(dropdown:GetAttributeChangedSignal("MaxIcons"):Connect(updateMaxIconsListener))
	dropdownJanitor:add(dropdown:GetAttributeChangedSignal("MaxIcons"):Connect(updateChildSize))
	dropdownJanitor:add(object.childThemeModified:Connect(updateMaxIconsListener))
	updateMaxIconsListener()

	local function connectVisibilityListeners(guiObject) -- 2 equivalent calls inferred from this helper
		if guiObject:IsA("GuiObject") then
			guiObject:GetPropertyChangedSignal("Visible"):Connect(updateChildSize)
			guiObject:GetPropertyChangedSignal("Size"):Connect(updateChildSize)
		end
	end

	for _, child in pairs(dropdownScroller:GetChildren()) do
		connectVisibilityListeners(child) -- inferred equivalent call
	end

	dropdownScroller.ChildAdded:Connect(function(child)
		RunService.Heartbeat:Wait()
		connectVisibilityListeners(child) -- inferred equivalent call
		updateChildSize()
	end)

	dropdown.Visible = false

	return dropdown
end