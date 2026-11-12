local Utility = require(script.Parent.Parent.Utility)
local Default = require(script.Default)
local RunService = game:GetService("RunService")
local isStudio = RunService:IsStudio()

local set = {}
local set2 = {}
local Themes = {}

local v = {
	"Box",
	"Caption",
	"CaptionCorner",
	"Caret",
	"ClickRegion",
	"Contents",
	"ContentsList",
	"DropShadow",
	"Dropdown",
	"DropdownCorner",
	"DropdownList",
	"DropdownPadding",
	"DropdownScroller",
	"DropdownSpeed",
	"Header",
	"Hotkeys",
	"IconButton",
	"IconCorners",
	"IconGradient",
	"IconImage",
	"IconImageCorner",
	"IconImageRatio",
	"IconImageScale",
	"IconLabel",
	"IconLabelContainer",
	"IconOverlay",
	"IconSpot",
	"IconSpotGradient",
	"Indicator",
	"IndicatorButton",
	"Inset",
	"Key1",
	"LabelContent",
	"Layout",
	"Layout1",
	"Menu",
	"MenuGap",
	"MenuUIListLayout",
	"Notice",
	"NoticeLabel",
	"OverlayUICorner",
	"Padding",
	"PaddingCenter",
	"PaddingLeft",
	"PaddingRight",
	"Selection",
	"SelectionContainer",
	"SelectionGradient",
	"UICorner",
	"UIStroke",
	"Widget"
}

for _, v2 in pairs(Default) do
	set[v2[2]] = true
end

local function warnOnce(p, p2) -- 2 equivalent calls inferred from this helper
	if set2[p] then
		return
	end

	set2[p] = true
	warn(`TopbarPlus: {p2} (this warning only shows in Studio)`)
end

function Themes.getThemeValue(items, p, p2, _)
	if not items then
		return nil
	end

	for _, list in pairs(items) do
		local v2, v3, v4 = unpack(list)

		if p == v2 and p2 == v3 then
			return v4
		end
	end

	return nil
end

function Themes.getInstanceValue(instance, attributeName)
	local success, result = pcall(function()
		return instance[attributeName]
	end)

	if not success then
		result = instance:GetAttribute(attributeName)
	end

	return result
end

function Themes.getRealInstance(instance)
	if not instance:GetAttribute("IsAClippedClone") then
		return
	end

	local originalInstance = instance:FindFirstChild("OriginalInstance")

	if originalInstance then
		return originalInstance.Value
	end
end

function Themes.getClippedClone(instance)
	if not instance:GetAttribute("HasAClippedClone") then
		return
	end

	local clippedClone = instance:FindFirstChild("ClippedClone")

	if clippedClone then
		return clippedClone.Value
	end
end

function Themes.getActiveGroup(object)
	local stateGroup = object:getStateGroup()

	if object.activeState ~= "Viewing" then
		return stateGroup
	end

	local v2 = object.isSelected and "Selected" or "Deselected"
	local result = {}
	local v3 = {}

	for _, v4 in pairs(object:getStateGroup(v2)) do
		table.insert(result, v4)
		v3[v4[1] .. "-" .. v4[2]] = #result
	end

	for _, v4 in pairs(stateGroup) do
		local v5 = v4[4]

		if not (typeof(v5) == "string" and string.lower(v5) == "viewing") then
			continue
		end

		local v6 = v3[v4[1] .. "-" .. v4[2]]

		if v6 then
			result[v6] = v4
		else
			table.insert(result, v4)
		end
	end

	return result
end

function Themes.refresh(p, folder, p2)
	if p2 then
		local activeGroup = Themes.getActiveGroup(p)
		local v2 = Themes.getThemeValue(activeGroup, folder.Name, p2) or Themes.getInstanceValue(folder, p2)
		Themes.apply(p, folder, p2, v2, true)
	else
		local activeGroup = Themes.getActiveGroup(p)

		if not activeGroup then
			return
		end

		local v2 = { [folder.Name] = folder }

		for _, descendant in pairs(folder:GetDescendants()) do
			local collective = descendant:GetAttribute("Collective")

			if collective then
				v2[collective] = descendant
			end

			v2[descendant.Name] = descendant
		end

		for _, list in pairs(activeGroup) do
			local v3, v4, v5 = unpack(list)
			local v6 = v2[v3]

			if v6 then
				Themes.apply(p, v6.Name, v4, v5, true)
			end
		end
	end
end

function Themes.apply(object, instance, attributeName, p, p2)
	if object.isDestroyed then
		return
	end

	local v2, clippedClones

	if typeof(instance) == "Instance" then
		v2 = instance.Name
		clippedClones = { instance }
	else
		clippedClones = object:getInstanceOrCollective(instance)
		v2 = instance
	end

	local v3 = v2 .. "-" .. attributeName
	local customBehaviour = object.customBehaviours[v3]

	for _, v4 in pairs(clippedClones) do
		local clippedClone = Themes.getClippedClone(v4)

		if clippedClone then
			table.insert(clippedClones, clippedClone)
		end
	end

	for _, v4 in pairs(clippedClones) do
		if not ((attributeName ~= "Position" or not Themes.getClippedClone(v4)) and (attributeName ~= "Size" or not Themes.getRealInstance(v4))) then
			continue
		end

		local instanceValue = Themes.getInstanceValue(v4, attributeName)

		if not (p2 or p ~= instanceValue) then
			continue
		end

		if customBehaviour then
			local v5 = customBehaviour(p, v4, attributeName)

			if v5 ~= nil then
				p = v5
			end
		end

		local v5 = attributeName == "Image" and typeof(p) == "Content" and "ImageContent" or attributeName

		if pcall(function()
			v4[v5] = p
		end) then
			continue
		end

		local v6 = v4:GetAttribute(attributeName) ~= nil
		v4:SetAttribute(attributeName, p)
		local isAClippedClone = v4:GetAttribute("IsAClippedClone")

		if not isStudio or (isAClippedClone or v6 or set[attributeName]) then
			continue
		end

		warnOnce( -- inferred equivalent call
			`Property-{v2}-{attributeName}`,
			`couldn't set {attributeName} on {v2} to {tostring(p)}. It's either not a real property or the value is the wrong type`
		)
	end
end

function Themes.getModifications(list)
	return typeof(list[1]) ~= "table" and { list } or list
end

function Themes.checkModifications(p, object)
	if not isStudio or typeof(p) ~= "table" then
		return
	end

	for _, v2 in pairs(Themes.getModifications(p)) do
		local v3 = v2[1]

		if typeof(v3) ~= "string" or table.find(v, v3) then
			continue
		end

		task.defer(function()
			if object and not object.isDestroyed and #object:getInstanceOrCollective(v3) > 0 then
				return
			end

			warnOnce( -- inferred equivalent call
				"Instance-" .. v3,
				`a theme names "{v3}" but no icon instance has that name, so it won't change anything`
			)
		end)
	end
end

function Themes:merge(list, callback): boolean
	local v2, v3, v4, v5 = table.unpack(list)
	local v6, v7, _, v8 = table.unpack(self)

	if v2 ~= v6 or v3 ~= v7 or not Themes.statesMatch(v5, v8) then
		return false
	end

	self[3] = v4

	if callback then
		callback(self)
	end

	return true
end

function Themes.modify(object, items, p)
	Themes.checkModifications(items, object)

	task.spawn(function()
		p = p or Utility.generateUID()
		items = Themes.getModifications(items)

		for _, list in pairs(items) do
			local v2, v3, v4, v5 = table.unpack(list)

			if v5 == nil then
				Themes.modify(object, { v2, v3, v4, "Selected" }, p)
				Themes.modify(object, { v2, v3, v4, "Viewing" }, p)
			end

			local formatStateName = Utility.formatStateName(v5 or "Deselected")
			local stateGroup = object:getStateGroup(formatStateName)
			local function nowSetIt() -- 2 equivalent calls inferred from this helper
				if formatStateName == object.activeState then
					Themes.apply(object, v2, v3, v4)
				end
			end
			local function updateRecord()
				for _, v6 in pairs(stateGroup) do
					if Themes.merge(v6, list, function(list2)
						list2[5] = p
						nowSetIt() -- inferred equivalent call
					end) then
						return
					end
				end

				table.insert(stateGroup, { v2, v3, v4, formatStateName, p })
				nowSetIt() -- inferred equivalent call
			end
			updateRecord()
		end
	end)
	return p
end

function Themes.remove(p, p2)
	for _, list in pairs(p.appearance) do
		for i = #list, 1, -1 do
			if list[i][5] == p2 then
				table.remove(list, i)
			end
		end
	end

	Themes.rebuild(p)
end

function Themes.removeWith(p, p2, p3, p4)
	for k, list in pairs(p.appearance) do
		if not (p4 == k or not p4) then
			continue
		end

		for i = #list, 1, -1 do
			local item = list[i]
			local v2 = item[1]
			local v3 = item[2]

			if v2 == p2 and v3 == p3 then
				table.remove(list, i)
			end
		end
	end

	Themes.rebuild(p)
end

function Themes.change(p)
	local activeGroup = Themes.getActiveGroup(p)

	for _, list in pairs(activeGroup) do
		local v2, v3, v4 = unpack(list)
		Themes.apply(p, v2, v3, v4)
	end
end

function Themes:set(moduleScript)
	local themesJanitor = self.themesJanitor
	themesJanitor:clean()
	themesJanitor:add(self.stateChanged:Connect(function()
		Themes.change(self)
	end))

	if typeof(moduleScript) == "Instance" and moduleScript:IsA("ModuleScript") then
		moduleScript = require(moduleScript)
	end

	if moduleScript ~= Default then
		Themes.checkModifications(moduleScript, self)
	end

	self.appliedTheme = moduleScript
	Themes.rebuild(self)
end

function Themes.statesMatch(value, value2): boolean
	return (value and string.lower(value)) == (value2 and string.lower(value2)) or not (value and value2)
end

function Themes.rebuild(p)
	local appliedTheme = p.appliedTheme
	local v2 = { "Deselected", "Selected", "Viewing" }
	local function generateTheme()
		for _, v3 in pairs(v2) do
			local copyTables = {}
			local function updateDetails(items, p2)
				if not items then
					return
				end

				for _, item in pairs(items) do
					local v4 = item[5]
					local v5 = item[4]

					if not Themes.statesMatch(p2, v5) then
						continue
					end

					local v6 = item[1] .. "-" .. item[2]
					local copyTable = Utility.copyTable(item)
					copyTable[5] = v4
					copyTables[v6] = copyTable
				end
			end

			if v3 == "Selected" then
				updateDetails(Default, "Deselected")
			end

			updateDetails(Default, "Empty")
			updateDetails(Default, v3)

			if appliedTheme ~= Default then
				if v3 == "Selected" then
					updateDetails(appliedTheme, "Deselected")
				end

				updateDetails(appliedTheme, v3)
			end

			local v4 = {}
			local v5 = p.appearance[v3]

			if v5 then
				for _, v6 in pairs(v5) do
					local v7 = v6[5]

					if v7 ~= nil then
						table.insert(v4, { v6[1], v6[2], v6[3], v3, v7 })
					end
				end
			end

			updateDetails(v4, v3)

			local v6 = {}

			for _, v7 in pairs(copyTables) do
				table.insert(v6, v7)
			end

			p.appearance[v3] = v6
		end

		Themes.change(p)
	end
	generateTheme()
end

return Themes