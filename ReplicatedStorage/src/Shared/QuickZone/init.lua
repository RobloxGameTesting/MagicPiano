local RunService = game:GetService("RunService")

require(script.Types)
local Config = require(script.Config)
local Scheduler = require(script.Core.Scheduler)
local State = require(script.Core.State)
local Geometry = require(script.Utils.Geometry)
local LinearBVH = require(script.Utils.LinearBVH)

local queryPoint = LinearBVH.queryPoint
local isPointInShape = Geometry.isPointInShape

local zoneAttachedObservers = State.zoneAttachedObservers
local zoneIdToZoneObj = State.zoneIdToZoneObj
local entityData = State.entityData
local observerIdToObserverObj = State.observerIdToObserverObj
local groups = State.groups
local entityToGroups = State.entityToGroups
local entityToReference = State.entityToReference
local referenceToEntity = State.referenceToEntity

local staticCFrames = State.staticCFrames
local staticHalfSizes = State.staticHalfSizes
local staticTypes = State.staticTypes
local staticMeshes = State.staticMeshes
local dynamicCFrames = State.dynamicCFrames
local dynamicHalfSizes = State.dynamicHalfSizes
local dynamicTypes = State.dynamicTypes
local dynamicMeshes = State.dynamicMeshes
local dynamicTree = State.dynamicTree
local staticTree = State.staticTree

local connection = nil
local parent = nil

local v = {}

local QuickZone = {
	Zone = require(script.Classes.Zone),
	Observer = require(script.Classes.Observer),
	Group = require(script.Classes.Group)
}

function QuickZone:configure(data)
	if data.enabled ~= nil then
		self:setEnabled(data.enabled)
	end

	if data.autoSyncRate ~= nil then
		self:setAutoSyncRate(data.autoSyncRate)
	end

	if data.frameBudget ~= nil then
		self:setFrameBudget(data.frameBudget)
	end

	return self
end

function QuickZone.setEnabled(p, flag: boolean)
	Scheduler.setEnabled(flag)
	return p
end

function QuickZone.update(p, p2: number)
	Scheduler.update(p2)
	return p
end

function QuickZone.setAutoSyncRate(p, p2: number)
	Scheduler.setAutoSyncRate(p2)
	return p
end

function QuickZone.rebuild(p)
	Scheduler.rebuildTrees()
	return p
end

function QuickZone.setReference(p, p2, player)
	local player2 = entityToReference[p2]

	if player == nil then
		if typeof(player2) ~= "Instance" or not player2:IsA("Player") then
			if player2 then
				referenceToEntity[player2] = nil
			end

			entityToReference[p2] = nil
		end
	elseif typeof(player) ~= "Instance" or not player:IsA("Player") then
		entityToReference[p2] = player
		referenceToEntity[player] = p2
	end

	return p
end

function QuickZone.setFrameBudget(p, p2: number)
	local v2 = p2 / 1000
	Scheduler.setFrameBudget(v2)
	return p
end

function QuickZone.removeEntity(p, p2)
	local v2 = referenceToEntity[p2] or p2

	local entityToGroup = entityToGroups[v2]

	if not entityToGroup then
		return p
	end

	local v3 = {}

	for k in entityToGroup do
		table.insert(v3, k)
	end

	for _, v4 in v3 do
		local group = groups[v4]

		if group then
			group:remove(v2)
		end
	end

	return p
end

function QuickZone.getEntityOfReference(_, instance)
	local v2 = referenceToEntity[instance]

	if v2 then
		return v2
	end

	if typeof(instance) == "Instance" then
		if
			instance:IsA("BasePart")
			or instance:IsA("Attachment")
			or instance:IsA("Bone")
			or instance:IsA("Camera")
			or instance:IsA("Model")
		then
			return instance
		end
	elseif
		typeof(instance) == "table"
		and (instance.Position or instance.CFrame or instance.WorldPosition or instance.GetPivot)
	then
		return instance
	end

	return nil
end

function QuickZone.getReferenceOfEntity(_, p)
	return entityToReference[p] or p
end

function QuickZone.getObservers(_)
	local observerObjs = {}

	for _, observerObj in observerIdToObserverObj do
		table.insert(observerObjs, observerObj)
	end

	return observerObjs
end

function QuickZone.getGroups(_)
	local groups2 = {}

	for _, group in groups do
		table.insert(groups2, group)
	end

	return groups2
end

function QuickZone.getZones(_)
	local zoneObjs = {}

	for _, zoneObj in zoneIdToZoneObj do
		table.insert(zoneObjs, zoneObj)
	end

	return zoneObjs
end

function QuickZone.getEntities(_)
	local count = 0
	local entities = {}

	for k in entityData do
		count += 1
		entities[count] = entityToReference[k] or k
	end

	return entities
end

function QuickZone.getZonesAtPoint(_, vector3: Vector3)
	local zonesAtPoint = {}
	local count = 0

	queryPoint(dynamicTree, vector3, function(p)
		local v2 = isPointInShape(vector3, dynamicCFrames[p], dynamicHalfSizes[p], dynamicTypes[p], dynamicMeshes[p])
			and zoneIdToZoneObj[p]

		if v2 then
			count += 1
			zonesAtPoint[count] = v2
		end
	end)

	queryPoint(staticTree, vector3, function(p)
		local v2 = isPointInShape(vector3, staticCFrames[p], staticHalfSizes[p], staticTypes[p], staticMeshes[p])
			and zoneIdToZoneObj[p]

		if v2 then
			count += 1
			zonesAtPoint[count] = v2
		end
	end)

	return zonesAtPoint
end

function QuickZone.getZonesOfEntity(_, p)
	local v2 = entityData[referenceToEntity[p] or p]

	if not (v2 and v2.activeObserverMemberships) then
		return {}
	end

	local activeObserverMembershipSet = {}
	local zoneObjs = {}

	for _, activeObserverMembership in v2.activeObserverMemberships do
		if activeObserverMembershipSet[activeObserverMembership] then
			continue
		end

		activeObserverMembershipSet[activeObserverMembership] = true

		local zoneObj = zoneIdToZoneObj[activeObserverMembership]

		if zoneObj then
			table.insert(zoneObjs, zoneObj)
		end
	end

	return zoneObjs
end

function QuickZone.getGroupsOfEntity(_, p)
	local entityToGroup = entityToGroups[referenceToEntity[p] or p]

	if not entityToGroup then
		return {}
	end

	local count = 0
	local groups2 = {}

	for k in entityToGroup do
		local group = groups[k]

		if not group then
			continue
		end

		count += 1
		groups2[count] = group
	end

	return groups2
end

function QuickZone.iterGroups(_)
	local v2 = nil
	return function()
		v2 = next(groups, v2)
		return v2 and groups[v2] or nil
	end
end

function QuickZone.iterZones(_)
	local v2 = nil

	return function()
		v2 = next(zoneIdToZoneObj, v2)
		return v2 and zoneIdToZoneObj[v2] or nil
	end
end

function QuickZone.iterEntities(_)
	local v2 = nil

	return function()
		v2 = next(entityData, v2)

		return v2 and (entityToReference[v2] or v2)
	end
end

function QuickZone.iterObservers(_)
	local v2 = nil

	return function()
		v2 = next(observerIdToObserverObj, v2)
		return v2 and observerIdToObserverObj[v2] or nil
	end
end

function QuickZone.iterGroupsOfEntity(_, p)
	local entityToGroup = entityToGroups[referenceToEntity[p] or p]

	if not entityToGroup then
		return function(): nil
			return nil
		end
	end

	local v2 = nil
	return function()
		v2 = next(entityToGroup, v2)
		return v2 and groups[v2] or nil
	end
end

function QuickZone.iterZonesOfEntity(_, p)
	local v2 = entityData[referenceToEntity[p] or p]

	if not (v2 and v2.activeObserverMemberships) then
		return function(): nil
			return nil
		end
	end

	local activeObserverMemberships = v2.activeObserverMemberships
	local activeObserverMembershipSet = {}
	local v3 = nil

	return function()
		while true do
			v3 = next(activeObserverMemberships, v3)

			if not v3 then
				return nil
			end

			local activeObserverMembership = activeObserverMemberships[v3]

			if activeObserverMembershipSet[activeObserverMembership] then
				continue
			end

			activeObserverMembershipSet[activeObserverMembership] = true
			local zoneObj = zoneIdToZoneObj[activeObserverMembership]

			if zoneObj then
				return zoneObj
			end
		end
	end
end

function QuickZone.iterZonesAtPoint(_, vector3: Vector3)
	local nodes = dynamicTree.nodes
	local count = dynamicTree.count or 0

	local nodes2 = staticTree.nodes
	local count2 = staticTree.count or 0

	local x = vector3.X
	local y = vector3.Y
	local z = vector3.Z

	local v2 = 1
	local flag = true

	return function()
		if flag then
			while v2 <= count do
				local node = nodes[v2]
				local min = node.min
				local max = node.max

				if x < min.X or x > max.X or y < min.Y or y > max.Y or z < min.Z or z > max.Z then
					v2 = node.skipIndex
				else
					v2 += 1
					local id = node.id

					if
						id > 0
						and isPointInShape(
							vector3,
							dynamicCFrames[id],
							dynamicHalfSizes[id],
							dynamicTypes[id],
							dynamicMeshes[id]
						)
					then
						return zoneIdToZoneObj[id]
					end
				end
			end

			flag = false
			v2 = 1
		end

		if flag then
			return nil
		end

		while v2 <= count2 do
			local node = nodes2[v2]
			local min = node.min
			local max = node.max

			if x < min.X or x > max.X or y < min.Y or y > max.Y or z < min.Z or z > max.Z then
				v2 = node.skipIndex
			else
				v2 += 1
				local id = node.id

				if
					id > 0
					and isPointInShape(
						vector3,
						staticCFrames[id],
						staticHalfSizes[id],
						staticTypes[id],
						staticMeshes[id]
					)
				then
					return zoneIdToZoneObj[id]
				end
			end
		end

		return nil
	end
end

function QuickZone.visualize(p, flag: boolean)
	if connection then
		connection:Disconnect()
		connection = nil
	end

	if parent then
		parent:Destroy()
		parent = nil
	end

	table.clear(v)

	if not flag then
		return p
	end

	local quickZone_Debug_Visuals = Instance.new("Folder")
	quickZone_Debug_Visuals.Name = "QuickZone_Debug_Visuals"
	quickZone_Debug_Visuals.Parent = workspace
	parent = quickZone_Debug_Visuals

	local function getOrCreateVisual(k: number)
		local visual = v[k]
		local shape = zoneIdToZoneObj[k]:getShape()

		if visual and visual.shape ~= shape then
			visual.adornment:Destroy()
			v[k] = nil
		end

		if visual then
			return visual
		end

		local adornment

		if shape == "Ball" then
			adornment = Instance.new("SphereHandleAdornment")
		elseif shape == "Cylinder" then
			adornment = Instance.new("CylinderHandleAdornment")
		else
			adornment = Instance.new("BoxHandleAdornment")
		end

		adornment.Name = "Zone_" .. k
		adornment.Adornee = workspace.Terrain
		adornment.Transparency = Config.Debug.transparency
		adornment.AlwaysOnTop = true
		adornment.ZIndex = 1
		adornment.Parent = parent
		visual = { adornment = adornment, shape = shape }

		v[k] = visual

		return visual
	end

	connection = (RunService:IsClient() and RunService.PreRender or RunService.Heartbeat):Connect(function()
		if not parent then
			return
		end

		for k, staticCFrame in staticCFrames do
			local visual = getOrCreateVisual(k)
			local adornment = visual.adornment
			local staticHalfSiz = staticHalfSizes[k]
			local size = staticHalfSiz * 2

			local zoneAttachedObserver = zoneAttachedObservers[k]
			local staticActive = zoneAttachedObserver
				and next(zoneAttachedObserver) ~= nil
				and Config.Debug.staticActive
				or Config.Debug.staticInactive

			if visual.shape == "Ball" then
				adornment.Radius = math.max(staticHalfSiz.X, staticHalfSiz.Y, staticHalfSiz.Z)
				adornment.CFrame = staticCFrame
			elseif visual.shape == "Cylinder" then
				adornment.Radius = math.max(staticHalfSiz.X, staticHalfSiz.Z)
				adornment.Height = size.X
				adornment.CFrame = staticCFrame * CFrame.Angles(0, 1.5707963267948966, 0)
			else
				adornment.Size = size
				adornment.CFrame = staticCFrame
			end

			adornment.Color3 = staticActive
		end

		for k, dynamicCFrame in dynamicCFrames do
			local visual = getOrCreateVisual(k)
			local adornment = visual.adornment
			local dynamicHalfSiz = dynamicHalfSizes[k]
			local size = dynamicHalfSiz * 2

			local zoneAttachedObserver = zoneAttachedObservers[k]
			local dynamicActive = zoneAttachedObserver
				and next(zoneAttachedObserver) ~= nil
				and Config.Debug.dynamicActive
				or Config.Debug.dynamicInactive

			if visual.shape == "Ball" then
				adornment.Radius = math.max(dynamicHalfSiz.X, dynamicHalfSiz.Y, dynamicHalfSiz.Z)
				adornment.CFrame = dynamicCFrame
			elseif visual.shape == "Cylinder" then
				adornment.Radius = math.max(dynamicHalfSiz.X, dynamicHalfSiz.Z)
				adornment.Height = size.X
				adornment.CFrame = dynamicCFrame * CFrame.Angles(0, 1.5707963267948966, 0)
			else
				adornment.Size = size
				adornment.CFrame = dynamicCFrame
			end

			adornment.Color3 = dynamicActive
		end

		for k, v2 in v do
			if staticCFrames[k] or dynamicCFrames[k] then
				continue
			end

			v2.adornment:Destroy()
			v[k] = nil
		end
	end)

	return p
end

return QuickZone