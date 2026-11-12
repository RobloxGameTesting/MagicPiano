return function(object, p)
	local notice = Instance.new("Frame")
	notice.Name = "Notice"
	notice.ZIndex = 25
	notice.AutomaticSize = Enum.AutomaticSize.X
	notice.BorderColor3 = Color3.fromRGB(0, 0, 0)
	notice.BorderSizePixel = 0
	notice.BackgroundTransparency = 0.1
	notice.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	notice.Visible = false
	notice.Parent = object.widget

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(1, 0)
	uiCorner.Parent = notice

	local uiStroke = Instance.new("UIStroke")
	uiStroke.Parent = notice

	local noticeLabel = Instance.new("TextLabel")
	noticeLabel.Name = "NoticeLabel"
	noticeLabel.ZIndex = 26
	noticeLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	noticeLabel.AutomaticSize = Enum.AutomaticSize.X
	noticeLabel.Size = UDim2.new(1, 0, 1, 0)
	noticeLabel.BackgroundTransparency = 1
	noticeLabel.Position = UDim2.new(0.5, 0, 0.515, 0)
	noticeLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	noticeLabel.TextSize = 14
	noticeLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	noticeLabel.Text = "1"
	noticeLabel.TextWrapped = true
	noticeLabel.Font = Enum.Font.Arial
	noticeLabel.Parent = notice

	local parent = script.Parent.Parent
	local packages = parent.Packages
	local Janitor = require(packages.Janitor)
	local GoodSignal = require(packages.GoodSignal)
	local Utility = require(parent.Utility)
	object.noticeChanged:Connect(function(p2)
		if not p2 then
			return
		end

		local v = p2 > 99
		local noticeLabelText = object.noticeLabelText

		noticeLabel.Text = noticeLabelText or v and "99+" or p2

		if v and not noticeLabelText then
			noticeLabel.TextSize = 11
		end

		local v2 = not (p2 < 1)

		local iconByUID = p.getIconByUID(object.parentIconUID)
		local v3 = #object.dropdownIcons > 0 or #object.menuIcons > 0

		if object.isSelected and v3 then
			v2 = false
		elseif iconByUID and not iconByUID.isSelected then
			v2 = false
		end

		Utility.setVisible(notice, v2, "NoticeHandler")
	end)
	object.noticeStarted:Connect(function(p2, p3)
		local clearNoticeEvent = p2 or object.deselected

		local iconByUID = p.getIconByUID(object.parentIconUID)

		if iconByUID then
			iconByUID:notify(clearNoticeEvent)
		end

		local v = object.janitor:add(Janitor.new())
		local completeSignal = v:add(GoodSignal.new())
		v:add(object.endNotices:Connect(function()
			completeSignal:Fire()
		end))
		v:add(clearNoticeEvent:Connect(function()
			completeSignal:Fire()
		end))
		local v2 = p3 or Utility.generateUID()
		object.notices[v2] = {
			completeSignal = completeSignal,
			clearNoticeEvent = clearNoticeEvent
		}

		local function updateNotice() -- 2 equivalent calls inferred from this helper
			object.noticeChanged:Fire(object.totalNotices)
		end
		object.notified:Fire(v2)
		object.totalNotices += 1
		updateNotice() -- inferred equivalent call
		completeSignal:Once(function()
			v:destroy()
			object.totalNotices -= 1
			object.notices[v2] = nil
			updateNotice() -- inferred equivalent call
		end)
	end)

	notice:SetAttribute("ClipToJoinedParent", true)
	object:clipOutside(notice)

	return notice
end