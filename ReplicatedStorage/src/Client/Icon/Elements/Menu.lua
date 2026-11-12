return function(object)
	local menu = Instance.new("ScrollingFrame")
	menu.Name = "Menu"
	menu.BackgroundTransparency = 1
	menu.Visible = true
	menu.ZIndex = 1
	menu.Size = UDim2.fromScale(1, 1)
	menu.ClipsDescendants = true
	menu.TopImage = ""
	menu.BottomImage = ""
	menu.HorizontalScrollBarInset = Enum.ScrollBarInset.Always
	menu.CanvasSize = UDim2.new(0, 0, 1, -1)
	menu.ScrollingEnabled = true
	menu.ScrollingDirection = Enum.ScrollingDirection.X
	menu.ZIndex = 20
	menu.ScrollBarThickness = 3
	menu.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
	menu.ScrollBarImageTransparency = 0.8
	menu.BorderSizePixel = 0
	menu.Selectable = false

	local iconModule = require(object.iconModule)
	local menuUIListLayout = iconModule.container.TopbarStandard:FindFirstChild("UIListLayout", true):Clone()
	menuUIListLayout.Name = "MenuUIListLayout"
	menuUIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	menuUIListLayout.Parent = menu

	local menuGap = Instance.new("Frame")
	menuGap.Name = "MenuGap"
	menuGap.BackgroundTransparency = 1
	menuGap.Visible = false
	menuGap.AnchorPoint = Vector2.new(0, 0.5)
	menuGap.ZIndex = 5
	menuGap.Parent = menu

	local flag = false
	local Themes = require(script.Parent.Parent.Features.Themes)
	local function totalChildrenChanged()
		local menuJanitor = object.menuJanitor
		local v = #object.menuIcons

		if flag then
			if v <= 0 then
				menuJanitor:clean()
				flag = false
			end
		else
			flag = true

			menuJanitor:add(object.toggled:Connect(function()
				if #object.menuIcons > 0 then
					object.updateSize:Fire()
				end
			end))

			local _, v2 = object:modifyTheme({
				{ "Menu", "Active", true }
			})

			task.defer(function()
				menuJanitor:add(function()
					object:removeModification(v2)
				end)
			end)

			local v3 = menu.AbsoluteCanvasSize.X
			local function rightAlignCanvas()
				if object.alignment == "Right" then
					local x = menu.AbsoluteCanvasSize.X
					local v4 = v3 - x
					v3 = x
					menu.CanvasPosition = Vector2.new(menu.CanvasPosition.X - v4, 0)
				end
			end
			menuJanitor:add(object.selected:Connect(rightAlignCanvas))
			menuJanitor:add(menu:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(rightAlignCanvas))

			local stateGroup = object:getStateGroup()

			if Themes.getThemeValue(stateGroup, "IconImage", "Image", "Deselected") == Themes.getThemeValue(
				stateGroup,
				"IconImage",
				"Image",
				"Selected"
			) then
				local rbxassetfontsfamiliesFredokaOnejson = Font.new(
					"rbxasset://fonts/families/FredokaOne.json",
					Enum.FontWeight.Light,
					Enum.FontStyle.Normal
				)
				object:removeModificationWith("IconLabel", "Text", "Viewing")
				object:removeModificationWith("IconImage", "Image", "Viewing")
				object:modifyTheme({
					{ "IconLabel", "FontFace", rbxassetfontsfamiliesFredokaOnejson, "Selected" },
					{ "IconLabel", "Text", "X", "Selected" },
					{ "IconLabel", "TextSize", 20, "Selected" },
					{ "IconLabel", "TextStrokeTransparency", 0.8, "Selected" },
					{ "IconImage", "Image", "", "Selected" }
				})
			end

			local instance = object:getInstance("MenuGap")
			local function updateAlignent() -- 1 equivalent call inferred from this helper
				local v4, layoutOrder

				if object.alignment == "Right" then
					v4 = 99999
					layoutOrder = 99998
				else
					v4 = -99999
					layoutOrder = -99998
				end

				object:modifyTheme({ "IconSpot", "LayoutOrder", v4 })
				instance.LayoutOrder = layoutOrder
			end
			menuJanitor:add(object.alignmentChanged:Connect(updateAlignent))
			updateAlignent() -- inferred equivalent call
			menu:GetAttributeChangedSignal("MenuCanvasWidth"):Connect(function()
				local menuCanvasWidth = menu:GetAttribute("MenuCanvasWidth")
				local y = menu.CanvasSize.Y
				menu.CanvasSize = UDim2.new(0, menuCanvasWidth, y.Scale, y.Offset)
			end)
			menuJanitor:add(object.updateMenu:Connect(function()
				local maxIcons = menu:GetAttribute("MaxIcons")

				if not maxIcons then
					return
				end

				local v4 = {}

				for _, child in pairs(menu:GetChildren()) do
					if child:GetAttribute("WidgetUID") and child.Visible then
						table.insert(v4, { child, child.AbsolutePosition.X })
					end
				end

				table.sort(v4, function(a, b): boolean
					return a[2] < b[2]
				end)
				local total = 0

				for i = 1, maxIcons do
					local v5 = v4[i]

					if not v5 then
						break
					end

					total += v5[1].AbsoluteSize.X + menuUIListLayout.Padding.Offset
				end

				menu:SetAttribute("MenuWidth", total)
			end))
			local function startMenuUpdate() -- 1 equivalent call inferred from this helper
				task.delay(0.1, function()
					object.startMenuUpdate:Fire()
				end)
			end
			menuJanitor:add(menu.ChildAdded:Connect(startMenuUpdate))
			menuJanitor:add(menu.ChildRemoved:Connect(startMenuUpdate))
			menuJanitor:add(menu:GetAttributeChangedSignal("MaxIcons"):Connect(startMenuUpdate))
			menuJanitor:add(menu:GetAttributeChangedSignal("MaxWidth"):Connect(startMenuUpdate))
			startMenuUpdate() -- inferred equivalent call
		end
	end

	object.menuChildAdded:Connect(totalChildrenChanged)
	object.menuSet:Connect(function(items)
		for _, menuIcon in pairs(object.menuIcons) do
			iconModule.getIconByUID(menuIcon):destroy()
		end

		if type(items) == "table" then
			for _, item in pairs(items) do
				item:joinMenu(object)
			end
		end
	end)

	return menu
end