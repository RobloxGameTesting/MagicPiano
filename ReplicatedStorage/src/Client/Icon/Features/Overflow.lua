local Overflow = {}
local childrenByName = {}
local v = {}
local iconsDictionary = nil
local CurrentCamera = workspace.CurrentCamera
local v2 = {}
local uidSet = {}
local Utility = require(script.Parent.Parent.Utility)
local flag = false
local v3 = false
local v4 = nil

function Overflow.start(p)
	v4 = p
	iconsDictionary = v4.iconsDictionary
	local v5 = nil

	for _, v6 in pairs(v4.container) do
		if v5 == nil and v6.ScreenInsets == Enum.ScreenInsets.TopbarSafeInsets then
			v5 = v6
		end

		for _, child in pairs(v6.Holders:GetChildren()) do
			if child:GetAttribute("IsAHolder") then
				childrenByName[child.Name] = child
			end
		end
	end

	local v6 = false
	local stagger = Utility.createStagger(0.1, function(p2)
		if not v6 then
			return
		end

		if not p2 then
			Overflow.updateAvailableIcons("Center")
		end

		Overflow.updateBoundary("Left")
		Overflow.updateBoundary("Right")
	end)
	task.delay(0.5, function()
		v6 = true
		stagger()
	end)
	task.delay(2, function()
		flag = true
		stagger()
	end)
	v4.iconAdded:Connect(stagger)
	v4.iconRemoved:Connect(stagger)
	v4.iconChanged:Connect(stagger)
	CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		stagger(true)
	end)
	v5:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		stagger(true)
	end)

	for _, v7 in pairs(childrenByName) do
		v7:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			stagger(true)
		end)
		v7:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
			stagger(true)
		end)
	end
end

function Overflow.getWidth(p, _)
	local widget = p.widget
	return widget:GetAttribute("TargetWidth") or widget.AbsoluteSize.X
end

function Overflow.getAvailableIcons(p)
	return v[p] or Overflow.updateAvailableIcons(p)
end

function Overflow.updateAvailableIcons(p)
	local result = {}
	local count = 0

	for _, v5 in pairs(iconsDictionary) do
		local parentIconUID = v5.parentIconUID
		local v6 = not parentIconUID or uidSet[parentIconUID]
		local v7 = uidSet[v5.UID]

		if not v6 or v5.alignment ~= p or v7 or not v5.isEnabled then
			continue
		end

		table.insert(result, v5)
		count += 1
	end

	if count <= 0 then
		return {}
	end

	table.sort(result, function(a, b): nil | boolean
		local layoutOrder = a.widget.LayoutOrder
		local layoutOrder2 = b.widget.LayoutOrder
		local parentIconUID = a.parentIconUID
		local parentIconUID2 = b.parentIconUID

		if parentIconUID == parentIconUID2 then
			if layoutOrder < layoutOrder2 then
				return true
			end

			return not (layoutOrder2 < layoutOrder) and a.widget.AbsolutePosition.X < b.widget.AbsolutePosition.X
		end

		if parentIconUID2 then
			return false
		end

		return if parentIconUID then true else nil
	end)

	v[p] = result
	return result
end

function Overflow.getRealXPositions(p, list)
	local v5 = p == "Left"
	local v6 = childrenByName[p]
	local x = v6.AbsolutePosition.X
	local x2 = v6.AbsoluteSize.X
	local offset = v6.UIListLayout.Padding.Offset
	local v7 = v5 and x or x + x2
	local realXPositions = {}

	if v5 then
		Utility.reverseTable(list)
	end

	for i = #list, 1, -1 do
		local item = list[i]
		local width = Overflow.getWidth(item)

		if not v5 then
			v7 -= width
		end

		realXPositions[item.UID] = v7

		if v5 then
			v7 += width
		end

		v7 += v5 and offset or -offset
	end

	return realXPositions
end

function Overflow.updateBoundary(p)
	local v5 = childrenByName[p]
	local uiListLayout = v5.UIListLayout
	local x = v5.AbsolutePosition.X
	local v6 = v5.AbsoluteSize.X
	local offset = uiListLayout.Padding.Offset
	local offset2 = uiListLayout.Padding.Offset

	local v7 = Overflow.updateAvailableIcons(p)
	local total = 0
	local count = 0

	for _, v8 in pairs(v7) do
		total += Overflow.getWidth(v8) + offset2
		count += 1
	end

	if count <= 0 then
		return
	end

	local v8 = p == "Center"
	local v9 = p == "Left"
	local v10 = not v9
	local v11 = v2[p]

	if not v11 and not v8 and #v7 > 0 then
		v11 = v4.new()
		v11:setImage(6069276526, "Deselected")
		v11:setName("Overflow" .. p)
		v11:setOrder(v9 and -9999999 or 9999999)
		v11:setAlignment(p)
		v11:autoDeselect(false)
		v11.isAnOverflow = true

		v11:select("OverflowStart", v11)
		v11:setEnabled(false)
		v2[p] = v11
		uidSet[v11.UID] = true

		if not v4.closeableOverflowMenus then
			local instance = v11:getInstance("IconSpot")
			instance.Visible = false
		end
	end

	local v12 = p == "Left" and "Right" or "Left"
	local v13 = Overflow.updateAvailableIcons(v12)
	local v14 = v9 and v13[1] or v10 and v13[#v13]
	local v15 = v2[v12]
	local v16

	if v9 then
		v16 = x + v6 or x
	else
		v16 = x
	end

	if v14 then
		local v17 = Overflow.getRealXPositions(v12, v13)[v14.UID]
		local width = Overflow.getWidth(v14)
		v16 = v9 and v17 - offset or v17 + width + offset
	end

	local count2 = 0
	local function checkToShiftCentralIcon()
		local availableIcons = Overflow.getAvailableIcons("Center")
		local availableIcon = availableIcons[v9 and 1 or #availableIcons]
		local function secondaryCheck() -- 2 equivalent calls inferred from this helper
			if not v3 then
				v3 = true
				task.delay(3, Overflow.updateBoundary, p)
			end
		end

		if availableIcon and not availableIcon.hasRelocatedInOverflow then
			local v17 = v9 and v7[#v7] or v10 and v7[1]
			local x2 = availableIcon.widget.AbsolutePosition.X
			local v18 = v17.widget.AbsolutePosition.X
			local width = Overflow.getWidth(v17)
			local v19 = v9 and x2 - offset or x2 + Overflow.getWidth(availableIcon) + offset
			v18 = v9 and v18 + width or v18
			local flag2 = false

			if v9 then
				if v19 < v18 then
					if flag then
						availableIcon:align("Left")
						availableIcon.hasRelocatedInOverflow = true
						flag2 = true
					else
						secondaryCheck() -- inferred equivalent call
						return
					end
				end
			elseif v10 and v18 < v19 then
				if flag and not (v18 < 0) then
					availableIcon:align("Right")
					availableIcon.hasRelocatedInOverflow = true
					flag2 = true
				else
					secondaryCheck() -- inferred equivalent call
					return
				end
			end

			if flag2 then
				count2 += 1

				if count2 <= 4 then
					Overflow.updateAvailableIcons("Center")
					checkToShiftCentralIcon()
				end
			end
		end
	end
	checkToShiftCentralIcon()

	if v11 then
		local instance = v11:getInstance("Menu")
		local v17 = x + v6

		if instance and v15 then
			local x2 = v15.widget.AbsolutePosition.X
			local width = Overflow.getWidth(v15)
			local v18 = v9 and x2 - offset or x2 + width + offset
			local instance2 = v15:getInstance("Menu")
			local v19 = instance.AbsoluteCanvasSize.X >= instance2.AbsoluteCanvasSize.X

			local v20 = x + v6 / 2
			local v21 = v9 and v20 - offset / 2 or v20 + offset / 2

			if v19 then
				v21 = v18
			end

			v6 = v9 and v21 - x or v17 - v21
		end

		local maxWidth = instance and instance:GetAttribute("MaxWidth")
		local rounded = Utility.round(v6)

		if instance and maxWidth ~= rounded then
			instance:SetAttribute("MaxWidth", rounded)
		end
	end

	local realXPositions = Overflow.getRealXPositions(p, v7)
	local v17 = false

	for i = #v7, 1, -1 do
		local v18 = v7[i]
		local width = Overflow.getWidth(v18)
		local realXPosition = realXPositions[v18.UID]

		if v9 and v16 <= realXPosition + width or v10 and realXPosition <= v16 then
			v17 = true
		end
	end

	for i = #v7, 1, -1 do
		local v18 = v7[i]

		if uidSet[v18.UID] then
			continue
		end

		if v17 and not v18.parentIconUID then
			v18:joinMenu(v11)
		elseif not v17 and v18.parentIconUID then
			v18:leave()
		end
	end

	if v11.isEnabled ~= v17 then
		v11:setEnabled(v17)
	end

	if v11.isEnabled and not v11.overflowAlreadyOpened then
		v11.overflowAlreadyOpened = true
		v11:select()
	end
end

return Overflow