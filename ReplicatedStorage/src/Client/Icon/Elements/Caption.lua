local Utility = require(script.Parent.Parent.Utility)
local color = Color3.fromRGB(39, 41, 48)

return function(object)
	local instance = object:getInstance("ClickRegion")
	local caption = Instance.new("CanvasGroup")
	caption.Name = "Caption"
	caption.AnchorPoint = Vector2.new(0.5, 0)
	caption.BackgroundTransparency = 1
	caption.BorderSizePixel = 0
	caption.GroupTransparency = 1
	caption.Position = UDim2.fromOffset(0, 0)
	caption.Visible = true
	caption.ZIndex = 30
	caption.Parent = instance

	local box = Instance.new("Frame")
	box.Name = "Box"
	box.AutomaticSize = Enum.AutomaticSize.XY
	box.BackgroundColor3 = color
	box.Position = UDim2.fromOffset(4, 7)
	box.ZIndex = 12
	box.Parent = caption

	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.FontFace = Font.new(
		"rbxasset://fonts/families/BuilderSans.json",
		Enum.FontWeight.Medium,
		Enum.FontStyle.Normal
	)

	header.Text = "Caption"
	header.TextColor3 = Color3.fromRGB(247, 247, 248)
	header.TextSize = 15
	header.TextTruncate = Enum.TextTruncate.None
	header.TextWrapped = false
	header.AutomaticSize = Enum.AutomaticSize.X
	header.BackgroundTransparency = 1
	header.LayoutOrder = 1
	header.Size = UDim2.fromOffset(0, 16)
	header.ZIndex = 18
	header.Parent = box

	local layout = Instance.new("UIListLayout")
	layout.Name = "Layout"
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = box

	local captionCorner = Instance.new("UICorner")
	captionCorner.Name = "CaptionCorner"
	captionCorner.Parent = box

	local padding = Instance.new("UIPadding")
	padding.Name = "Padding"
	padding.PaddingBottom = UDim.new(0, 12)
	padding.PaddingLeft = UDim.new(0, 12)
	padding.PaddingRight = UDim.new(0, 12)
	padding.PaddingTop = UDim.new(0, 12)
	padding.Parent = box

	local hotkeys = Instance.new("Frame")
	hotkeys.Name = "Hotkeys"
	hotkeys.AutomaticSize = Enum.AutomaticSize.Y
	hotkeys.BackgroundTransparency = 1
	hotkeys.LayoutOrder = 3
	hotkeys.Size = UDim2.fromScale(1, 0)
	hotkeys.Visible = false
	hotkeys.Parent = box

	local layout1 = Instance.new("UIListLayout")
	layout1.Name = "Layout1"
	layout1.Padding = UDim.new(0, 6)
	layout1.FillDirection = Enum.FillDirection.Vertical
	layout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout1.HorizontalFlex = Enum.UIFlexAlignment.None
	layout1.ItemLineAlignment = Enum.ItemLineAlignment.Automatic
	layout1.VerticalFlex = Enum.UIFlexAlignment.None
	layout1.SortOrder = Enum.SortOrder.LayoutOrder
	layout1.Parent = hotkeys

	local key1 = Instance.new("ImageLabel")
	key1.Name = "Key1"
	key1.Image = "rbxasset://textures/ui/Controls/key_single.png"
	key1.ImageTransparency = 0.7
	key1.ScaleType = Enum.ScaleType.Slice
	key1.SliceCenter = Rect.new(5, 5, 23, 24)
	key1.AutomaticSize = Enum.AutomaticSize.X
	key1.BackgroundTransparency = 1
	key1.LayoutOrder = 1
	key1.Size = UDim2.fromOffset(0, 30)
	key1.ZIndex = 15
	key1.Parent = hotkeys

	local inset = Instance.new("UIPadding")
	inset.Name = "Inset"
	inset.PaddingLeft = UDim.new(0, 8)
	inset.PaddingRight = UDim.new(0, 8)
	inset.Parent = key1

	local labelContent = Instance.new("TextLabel")
	labelContent.AutoLocalize = false
	labelContent.Name = "LabelContent"
	labelContent.FontFace = Font.new(
		"rbxasset://fonts/families/GothamSSm.json",
		Enum.FontWeight.Medium,
		Enum.FontStyle.Normal
	)

	labelContent.Text = ""
	labelContent.TextColor3 = Color3.fromRGB(189, 190, 190)
	labelContent.TextSize = 15
	labelContent.AutomaticSize = Enum.AutomaticSize.X
	labelContent.BackgroundTransparency = 1
	labelContent.Position = UDim2.fromOffset(0, -1)
	labelContent.Size = UDim2.fromScale(1, 1)
	labelContent.ZIndex = 16
	labelContent.Parent = key1

	local caret = Instance.new("ImageLabel")
	caret.Name = "Caret"
	caret.Image = "rbxassetid://101906294438076"
	caret.ImageColor3 = color
	caret.AnchorPoint = Vector2.new(0, 0.5)
	caret.BackgroundTransparency = 1
	caret.Position = UDim2.new(0, 0, 0, 4)
	caret.Size = UDim2.fromOffset(16, 8)
	caret.ZIndex = 12
	caret.Parent = caption

	local dropShadow = Instance.new("ImageLabel")
	dropShadow.Visible = true
	dropShadow.Name = "DropShadow"
	dropShadow.Image = "rbxassetid://124920646932671"
	dropShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	dropShadow.ImageTransparency = 0.5
	dropShadow.ScaleType = Enum.ScaleType.Slice
	dropShadow.SliceCenter = Rect.new(12, 12, 13, 13)
	dropShadow.BackgroundTransparency = 1
	dropShadow.Position = UDim2.fromOffset(0, 5)
	dropShadow.Size = UDim2.fromOffset(0, 48)
	dropShadow.Parent = caption
	box:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		dropShadow.Size = UDim2.fromOffset(box.AbsoluteSize.X + 8, box.AbsoluteSize.Y + 8)
	end)

	local captionJanitor = object.captionJanitor
	local _, v = object:clipOutside(caption)
	v.AutomaticSize = Enum.AutomaticSize.None
	local function matchSize() -- 1 equivalent call inferred from this helper
		local absoluteSize = caption.AbsoluteSize
		v.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
	end
	captionJanitor:add(caption:GetPropertyChangedSignal("AbsoluteSize"):Connect(matchSize))
	matchSize() -- inferred equivalent call
	local v2 = false
	local header2 = caption.Box.Header
	local UserInputService = game:GetService("UserInputService")
	local function updateHotkey(fakeToggleKey) -- 2 equivalent calls inferred from this helper
		local keyboardEnabled = UserInputService.KeyboardEnabled
		local captionText = caption:GetAttribute("CaptionText") or ""
		local v3 = captionText == "_hotkey_"

		if not keyboardEnabled and v3 then
			object:setCaption()
			return
		end

		header2.Text = captionText
		header2.Visible = not v3

		if fakeToggleKey then
			labelContent.Text = fakeToggleKey.Name
			hotkeys.Visible = true
		end

		if not keyboardEnabled then
			hotkeys.Visible = false
		end
	end
	caption:GetAttributeChangedSignal("CaptionText"):Connect(updateHotkey)

	local quad = Enum.EasingStyle.Quad

	local tweenInfo = TweenInfo.new(0.2, quad, Enum.EasingDirection.In)
	local tweenInfo2 = TweenInfo.new(0.2, quad, Enum.EasingDirection.Out)
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")
	local function getCaptionPosition(p) -- 1 equivalent call inferred from this helper
		if p == nil then
			p = v2
		end

		return UDim2.new(0.5, 0, 1, p and 5 or -3)
	end

	local function updatePosition(p)
		if not v2 then
			return
		end

		if p == nil then
			p = v2
		end

		local captionPosition = getCaptionPosition(not p) -- inferred equivalent call
		local v3 = if p == nil then v2 else p

		local udim = UDim2.new(0.5, 0, 1, v3 and 5 or -3)

		if p then
			local offset = caret.Position.Y.Offset
			caret.Position = UDim2.fromOffset(0, offset)
			caption.AutomaticSize = Enum.AutomaticSize.XY
			caption.Size = UDim2.fromOffset(32, 53)
		else
			local absoluteSize = caption.AbsoluteSize
			caption.AutomaticSize = Enum.AutomaticSize.Y
			caption.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
		end

		local v4 = nil
		local function updateCaret()
			local v5 = instance.AbsolutePosition.X - caption.AbsolutePosition.X + instance.AbsoluteSize.X / 2 - caret.AbsoluteSize.X / 2
			local offset = caret.Position.Y.Offset
			local udim2 = UDim2.fromOffset(v5, offset)

			if v4 ~= v5 then
				v4 = v5
				caret.Position = UDim2.fromOffset(0, offset)
				task.wait()
			end

			caret.Position = udim2
		end
		v.Position = captionPosition
		updateCaret()

		local tween = TweenService:Create(v, Utility.getTweenInfo(p and tweenInfo or tweenInfo2), {
			Position = udim
		})
		local heartbeatConnection = RunService.Heartbeat:Connect(updateCaret)
		tween:Play()
		tween.Completed:Once(function()
			heartbeatConnection:Disconnect()
		end)
	end
	captionJanitor:add(instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updatePosition()
	end))
	updatePosition(false)

	captionJanitor:add(object.toggleKeyAdded:Connect(updateHotkey))

	for k, _ in pairs(object.bindedToggleKeys) do
		local keyboardEnabled = UserInputService.KeyboardEnabled
		local captionText = caption:GetAttribute("CaptionText") or ""
		local v3 = captionText == "_hotkey_"

		if not keyboardEnabled and v3 then
			object:setCaption()
			break
		end

		header2.Text = captionText
		header2.Visible = not v3

		if k then
			labelContent.Text = k.Name
			hotkeys.Visible = true
		end

		if keyboardEnabled then
			break
		end

		hotkeys.Visible = false
		break
	end

	captionJanitor:add(object.fakeToggleKeyChanged:Connect(updateHotkey))
	local fakeToggleKey = object.fakeToggleKey

	if fakeToggleKey then
		updateHotkey(fakeToggleKey) -- inferred equivalent call
	end

	local function setCaptionEnabled(flag)
		if v2 == flag then
			return
		end

		local joinedFrame = object.joinedFrame

		if joinedFrame and string.match(joinedFrame.Name, "Dropdown") then
			flag = false
		end

		v2 = flag

		local tween = TweenService:Create(caption, flag and tweenInfo or tweenInfo2, {
			GroupTransparency = flag and 0 or 1
		})

		if flag then
			Utility.setVisible(caption, true, "CaptionFade")
		else
			tween.Completed:Once(function()
				if not v2 then
					Utility.setVisible(caption, false, "CaptionFade")
				end
			end)
		end

		tween:Play()

		if flag then
			v:SetAttribute("ForceUpdate", true)
		end

		updatePosition()
		updateHotkey() -- inferred equivalent call
	end

	Utility.setVisible(caption, false, "CaptionFade")

	local iconModule = require(object.iconModule)
	captionJanitor:add(object.stateChanged:Connect(function(p)
		if p == "Viewing" then
			local captionLastClosedClock = iconModule.captionLastClosedClock
			local v3 = (captionLastClosedClock and os.clock() - captionLastClosedClock or 999) < 0.3 and 0 or 0.5
			task.delay(v3, function()
				if object.activeState == "Viewing" then
					setCaptionEnabled(true)
				end
			end)
		else
			iconModule.captionLastClosedClock = os.clock()
			setCaptionEnabled(false)
		end
	end))

	return caption
end