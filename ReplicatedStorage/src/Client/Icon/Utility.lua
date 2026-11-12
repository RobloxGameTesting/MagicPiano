local Utility = {}
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function Utility.createStagger(p, callback, p2)
	local flag = false
	local flag2 = false
	local v = (not p or p == 0) and 0.01 or p
	local function staggeredCallback(...)
		if flag then
			flag2 = true
			return
		end

		local v2 = table.pack(...)
		flag = true
		flag2 = false
		task.spawn(function()
			if p2 then
				task.wait(v)
			end

			callback(table.unpack(v2))
		end)
		task.delay(v, function()
			flag = false

			if flag2 then
				staggeredCallback(table.unpack(v2))
			end
		end)
	end
	return staggeredCallback
end

function Utility.round(p)
	return (math.floor(p + 0.5))
end

function Utility:reverseTable()
	for i = 1, math.floor(#self / 2) do
		local v = #self - i + 1
		local item = self[v]
		local item2 = self[i]
		self[i] = item
		self[v] = item2
	end
end

function Utility.copyTable(list)
	assert(type(list) == "table", "First argument must be a table")
	local result = table.create(#list)

	for k, item in pairs(list) do
		if type(item) == "table" then
			result[k] = Utility.copyTable(item)
		else
			result[k] = item
		end
	end

	return result
end

local v = {
	"a",
	"b",
	"c",
	"d",
	"e",
	"f",
	"g",
	"h",
	"i",
	"j",
	"k",
	"l",
	"m",
	"n",
	"o",
	"p",
	"q",
	"r",
	"s",
	"t",
	"u",
	"v",
	"w",
	"x",
	"y",
	"z",
	"A",
	"B",
	"C",
	"D",
	"E",
	"F",
	"G",
	"H",
	"I",
	"J",
	"K",
	"L",
	"M",
	"N",
	"O",
	"P",
	"Q",
	"R",
	"S",
	"T",
	"U",
	"V",
	"W",
	"X",
	"Y",
	"Z",
	"1",
	"2",
	"3",
	"4",
	"5",
	"6",
	"7",
	"8",
	"9",
	"0",
	"<",
	">",
	"?",
	"@",
	"{",
	"}",
	"[",
	"]",
	"!",
	"(",
	")",
	"=",
	"+",
	"~",
	"#"
}
function Utility.generateUID(value)
	local v2 = v
	local v3 = #v2
	local uid = ""

	for _ = 1, value or 8 do
		uid ..= v2[math.random(1, v3)]
	end

	return uid
end

local v2 = {}
function Utility:setVisible(visible, p)
	local v3 = v2[self]

	if not v3 then
		v3 = {}
		v2[self] = v3
		self.Destroying:Once(function()
			v2[self] = nil
		end)
	end

	if visible then
		v3[p] = nil
	else
		v3[p] = true
	end

	if visible then
		for _, _ in pairs(v3) do
			visible = false
			break
		end
	end

	self.Visible = visible
end

function Utility.formatStateName(value)
	return string.upper((string.sub(value, 1, 1))) .. string.lower((string.sub(value, 2)))
end

function Utility.isReducedMotion()
	local success, result = pcall(function()
		local GuiService = game:GetService("GuiService")
		return GuiService.ReducedMotionEnabled
	end)

	return success and result == true
end

function Utility.getTweenInfo(p)
	if Utility.isReducedMotion() then
		return TweenInfo.new(0)
	end

	return p
end

function Utility.localPlayerRespawned(onCharacterRemoving)
	return LocalPlayer.CharacterRemoving:Connect(onCharacterRemoving)
end

function Utility.getClippedContainer(parent)
	local clippedContainer = parent:FindFirstChild("ClippedContainer")

	if not clippedContainer then
		clippedContainer = Instance.new("Folder")
		clippedContainer.Name = "ClippedContainer"
		clippedContainer.Parent = parent
	end

	return clippedContainer
end

local Janitor = require(script.Parent.Packages.Janitor)
local GuiService = game:GetService("GuiService")
function Utility.clipOutside(data, instance)
	local v3 = data.janitor:add(Janitor.new())
	instance.Destroying:Once(function()
		v3:Destroy()
	end)
	data.janitor:add(instance)

	local parent = instance.Parent
	local parent2 = v3:add(Instance.new("Frame"))
	parent2:SetAttribute("IsAClippedClone", true)
	parent2.Name = instance.Name
	parent2.AnchorPoint = instance.AnchorPoint
	parent2.Size = instance.Size
	parent2.Position = instance.Position
	parent2.BackgroundTransparency = 1
	parent2.LayoutOrder = instance.LayoutOrder
	parent2.Parent = parent

	local originalInstance = Instance.new("ObjectValue")
	originalInstance.Name = "OriginalInstance"
	originalInstance.Value = instance
	originalInstance.Parent = parent2

	local clippedClone = originalInstance:Clone()
	instance:SetAttribute("HasAClippedClone", true)
	clippedClone.Name = "ClippedClone"
	clippedClone.Value = parent2
	clippedClone.Parent = instance

	local v4 = nil
	local iconModule = require(data.iconModule)
	local container = iconModule.container
	local function updateScreenGui()
		local v5 = parent:FindFirstAncestorWhichIsA("ScreenGui")

		if not string.match(v5.Name, "Clipped") then
			v5 = container[v5.Name .. "Clipped"]
		end

		v4 = v5
		instance.AnchorPoint = Vector2.new(0, 0)
		instance.Parent = Utility.getClippedContainer(v4)
	end
	v3:add(data.alignmentChanged:Connect(updateScreenGui))
	updateScreenGui()

	for _, uiAspectRatioConstraint in pairs(instance:GetChildren()) do
		if not uiAspectRatioConstraint:IsA("UIAspectRatioConstraint") then
			continue
		end

		local clone = uiAspectRatioConstraint:Clone()
		clone.Parent = parent2
	end

	local widget = data.widget
	local v5 = false
	local ignoreVisibilityUpdater = instance:GetAttribute("IgnoreVisibilityUpdater")
	local function updateVisibility() -- 7 equivalent calls inferred from this helper
		if ignoreVisibilityUpdater then
			return
		end

		local v6 = widget.Visible

		if v5 then
			v6 = false
		end

		Utility.setVisible(instance, v6, "ClipHandler")
	end
	v3:add(widget:GetPropertyChangedSignal("Visible"):Connect(updateVisibility))

	local v6 = nil
	local function checkIfOutsideParentXBounds()
		task.defer(function()
			local scrollingFrame = nil
			local uid = data.UID

			if instance:GetAttribute("ClipToJoinedParent") then
				local v7 = uid

				for _ = 1, 10 do
					local iconByUID = iconModule.getIconByUID(v7)

					if not iconByUID then
						break
					end

					local joinedFrame = iconByUID.joinedFrame
					v7 = iconByUID.parentIconUID

					if not joinedFrame then
						break
					end

					if joinedFrame and joinedFrame.Name == "DropdownScroller" then
						scrollingFrame = joinedFrame
						break
					end

					scrollingFrame = joinedFrame
				end
			end

			if scrollingFrame then
				local absolutePosition = instance.AbsolutePosition
				local halfAbsoluteSize = instance.AbsoluteSize / 2
				local absolutePosition2 = scrollingFrame.AbsolutePosition
				local absoluteSize = scrollingFrame.AbsoluteSize
				local v7 = absolutePosition + halfAbsoluteSize
				local v8 = v7.X < absolutePosition2.X
				local v9 = v7.X > absolutePosition2.X + absoluteSize.X
				local v10 = v7.Y < absolutePosition2.Y
				local v11 = v7.Y > absolutePosition2.Y + absoluteSize.Y
				local v12 = v8 or v9 or v10 or v11

				if v12 ~= v5 then
					v5 = v12
					updateVisibility() -- inferred equivalent call
				end

				if scrollingFrame:IsA("ScrollingFrame") and v6 ~= scrollingFrame then
					v6 = scrollingFrame
					v3:add(scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
						checkIfOutsideParentXBounds()
					end), "Disconnect", "TrackUtilityScroller-" .. uid)
				end
			else
				v5 = false
				updateVisibility() -- inferred equivalent call
			end
		end)
	end

	local currentCamera = workspace.CurrentCamera
	local additionalOffsetX = instance:GetAttribute("AdditionalOffsetX") or 0
	local function trackProperty(p)
		local v7 = "Absolute" .. p
		local function updateProperty()
			local v8 = parent2[v7]
			local v9 = UDim2.fromOffset(v8.X, v8.Y)

			if p == "Position" then
				local v10 = currentCamera.ViewportSize.X - instance.AbsoluteSize.X - 4
				local v11 = v9.X.Offset

				if v11 < 4 then
					v11 = 4
				elseif v10 < v11 then
					v11 = v10
				end

				local udim = UDim2.fromOffset(v11, v9.Y.Offset)

				local topbarInset = GuiService.TopbarInset
				local x = workspace.CurrentCamera.ViewportSize.X
				local x2 = v4.AbsoluteSize.X
				local v12 = v4.AbsolutePosition.X

				if not iconModule.isOldTopbar then
					v12 = x - x2 - 0
				end

				local v13 = v12 - additionalOffsetX
				v9 = udim + UDim2.fromOffset(-v13, topbarInset.Height)
				task.defer(function()
					local scrollingFrame = nil
					local uid = data.UID

					if instance:GetAttribute("ClipToJoinedParent") then
						local v14 = uid

						for _ = 1, 10 do
							local iconByUID = iconModule.getIconByUID(v14)

							if not iconByUID then
								break
							end

							local joinedFrame = iconByUID.joinedFrame
							v14 = iconByUID.parentIconUID

							if not joinedFrame then
								break
							end

							if joinedFrame and joinedFrame.Name == "DropdownScroller" then
								scrollingFrame = joinedFrame
								break
							end

							scrollingFrame = joinedFrame
						end
					end

					if scrollingFrame then
						local absolutePosition = instance.AbsolutePosition
						local halfAbsoluteSize = instance.AbsoluteSize / 2
						local absolutePosition2 = scrollingFrame.AbsolutePosition
						local absoluteSize = scrollingFrame.AbsoluteSize
						local v14 = absolutePosition + halfAbsoluteSize
						local v15 = v14.X < absolutePosition2.X
						local v16 = v14.X > absolutePosition2.X + absoluteSize.X
						local v17 = v14.Y < absolutePosition2.Y
						local v18 = v14.Y > absolutePosition2.Y + absoluteSize.Y
						local v19 = v15 or v16 or v17 or v18

						if v19 ~= v5 then
							v5 = v19
							updateVisibility() -- inferred equivalent call
						end

						if scrollingFrame:IsA("ScrollingFrame") and v6 ~= scrollingFrame then
							v6 = scrollingFrame
							v3:add(scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
								checkIfOutsideParentXBounds()
							end), "Disconnect", "TrackUtilityScroller-" .. uid)
						end
					else
						v5 = false
						updateVisibility() -- inferred equivalent call
					end
				end)
			end

			instance[p] = v9
		end

		local stagger = Utility.createStagger(0.01, updateProperty)
		v3:add(parent2:GetPropertyChangedSignal(v7):Connect(stagger))
		v3:add(parent2:GetAttributeChangedSignal("ForceUpdate"):Connect(function()
			stagger()
		end))

		local stagger2 = Utility.createStagger(0.5, updateProperty, true)
		v3:add(parent2:GetPropertyChangedSignal(v7):Connect(stagger2))

		if p == "Position" then
			v3:add(v4:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				stagger()
			end))
		end
	end
	task.delay(0.1, checkIfOutsideParentXBounds)
	task.defer(function()
		local scrollingFrame = nil
		local uid = data.UID

		if instance:GetAttribute("ClipToJoinedParent") then
			local v7 = uid

			for _ = 1, 10 do
				local iconByUID = iconModule.getIconByUID(v7)

				if not iconByUID then
					break
				end

				local joinedFrame = iconByUID.joinedFrame
				v7 = iconByUID.parentIconUID

				if not joinedFrame then
					break
				end

				if joinedFrame and joinedFrame.Name == "DropdownScroller" then
					scrollingFrame = joinedFrame
					break
				end

				scrollingFrame = joinedFrame
			end
		end

		if scrollingFrame then
			local absolutePosition = instance.AbsolutePosition
			local halfAbsoluteSize = instance.AbsoluteSize / 2
			local absolutePosition2 = scrollingFrame.AbsolutePosition
			local absoluteSize = scrollingFrame.AbsoluteSize
			local v7 = absolutePosition + halfAbsoluteSize
			local v8 = v7.X < absolutePosition2.X
			local v9 = v7.X > absolutePosition2.X + absoluteSize.X
			local v10 = v7.Y < absolutePosition2.Y
			local v11 = v7.Y > absolutePosition2.Y + absoluteSize.Y
			local v12 = v8 or v9 or v10 or v11

			if v12 ~= v5 then
				v5 = v12
				updateVisibility() -- inferred equivalent call
			end

			if scrollingFrame:IsA("ScrollingFrame") and v6 ~= scrollingFrame then
				v6 = scrollingFrame
				v3:add(scrollingFrame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(function()
					checkIfOutsideParentXBounds()
				end), "Disconnect", "TrackUtilityScroller-" .. uid)
			end
		else
			v5 = false
			updateVisibility() -- inferred equivalent call
		end
	end)
	updateVisibility() -- inferred equivalent call
	trackProperty("Position")

	v3:add(instance:GetPropertyChangedSignal("Visible"):Connect(function() end))

	if instance:GetAttribute("TrackCloneSize") then
		trackProperty("Size")
	else
		v3:add(instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local absoluteSize = instance.AbsoluteSize
			parent2.Size = UDim2.fromOffset(absoluteSize.X, absoluteSize.Y)
		end))
	end

	return parent2
end

function Utility:joinFeature(object, uids, joinedFrame)
	local joinJanitor = self.joinJanitor
	joinJanitor:clean()

	if not joinedFrame then
		self:leave()
		return
	end

	self.parentIconUID = object.UID
	self.joinedFrame = joinedFrame
	local function updateAlignent() -- 2 equivalent calls inferred from this helper
		local alignment = object.alignment
		self:setAlignment(alignment == "Center" and "Left" or alignment, true)
	end
	joinJanitor:add(object.alignmentChanged:Connect(updateAlignent))
	updateAlignent() -- inferred equivalent call
	self:modifyTheme({ "IconButton", "BackgroundTransparency", 1 }, "JoinModification")
	self:modifyTheme({ "ClickRegion", "Active", false }, "JoinModification")

	if object.childModifications then
		task.defer(function()
			self:modifyTheme(object.childModifications, object.childModificationsUID)
		end)
	end

	local instance = self:getInstance("ClickRegion")
	local function makeSelectable()
		instance.Selectable = object.isSelected
	end
	joinJanitor:add(object.toggled:Connect(makeSelectable))
	task.defer(makeSelectable)
	joinJanitor:add(function()
		instance.Selectable = true
	end)

	local uid = self.UID
	table.insert(uids, uid)
	object:autoDeselect(false)
	object.childIconsDict[uid] = true

	if not object.isEnabled then
		object:setEnabled(true)
	end

	self.joinedParent:Fire(object)

	joinJanitor:add(function()
		if not self.joinedFrame then
			return
		end

		for k, item in pairs(uids) do
			if item == uid then
				table.remove(uids, k)
				break
			end
		end

		local iconModule = require(self.iconModule)
		local iconByUID = iconModule.getIconByUID(self.parentIconUID)

		if not iconByUID then
			return
		end

		self:setAlignment(self.originalAlignment)
		self.parentIconUID = false
		self.joinedFrame = false

		self:removeModification("JoinModification")

		local v3 = true
		local childIconsDict = iconByUID.childIconsDict
		childIconsDict[uid] = nil

		for _, _ in pairs(childIconsDict) do
			v3 = false
			break
		end

		if v3 and not iconByUID.isAnOverflow then
			iconByUID:setEnabled(false)
		end

		updateAlignent() -- inferred equivalent call
	end)
end

return Utility