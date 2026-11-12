local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Parent.Config)
local State = require(script.Parent.Parent.Core.State)
require(script.Parent.Parent.Types)
local Geometry = require(script.Parent.Parent.Utils.Geometry)
local Log = require(script.Parent.Parent.Utils.Log)

local isPointInShape = Geometry.isPointInShape

local v = {}
local v2 = {}

local dirtyProfiles = State.dirtyProfiles
local dirtyTopology = State.dirtyTopology
local zoneAttachedObservers = State.zoneAttachedObservers

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

local isClient = RunService:IsClient()

local function updateAllEntitiesForObserver(id: number)
	for k, groupToObserver in State.groupToObservers do
		if not groupToObserver[id] then
			continue
		end

		local group = State.groups[k]

		if not group then
			continue
		end

		for _, entity in group.entities do
			dirtyProfiles[entity] = true
			dirtyTopology[entity] = true
		end
	end
end

local function disconnectObserverFromGroup(id: number, p)
	local v3 = State.observerSafety[id]
	local v4 = State.observerEnabled[id]

	for _, entity in p.entities do
		local v5 = State.entityData[entity]

		if not v5 then
			continue
		end

		dirtyProfiles[entity] = true
		dirtyTopology[entity] = true

		local activeObserverMembership = v5.activeObserverMemberships[id]

		if not activeObserverMembership then
			continue
		end

		local v6 = false

		if v4 then
			for k in State.entityToGroups[entity] do
				if State.groupToObservers[k] and State.groupToObservers[k][id] then
					v6 = true
					break
				end
			end
		end

		if v6 then
			continue
		end

		v5.activeObserverMemberships[id] = nil

		if State.observerTrackingEntities[id] then
			State.observerTrackingEntities[id][entity] = nil
		end

		local observerExitedCallback = State.observerExitedCallbacks[id]

		if not observerExitedCallback then
			continue
		end

		local zoneObj = State.zoneIdToZoneObj[activeObserverMembership]
		local v7 = State.entityToReference[entity] or entity

		for _, callback in observerExitedCallback do
			if v3 then
				task.spawn(callback, v7, zoneObj, entity)
			else
				callback(v7, zoneObj, entity)
			end
		end
	end
end

local Observer = {}
Observer.__index = Observer

function Observer.new(data)
	local nextObserverId = State.nextObserverId
	State.nextObserverId += 1

	local object = setmetatable({ id = nextObserverId }, Observer)

	State.observerPriorityMap[nextObserverId] = data and data.priority or 0
	State.observerUpdateRate[nextObserverId] = data and data.updateRate or Config.Observer.updateRate
	State.observerPrecisionSq[nextObserverId] = (data and data.precision or Config.Observer.precision) ^ 2

	State.observerEnteredCallbacks[nextObserverId] = {}
	State.observerExitedCallbacks[nextObserverId] = {}
	State.observerTransitionedCallbacks[nextObserverId] = {}
	State.observerTrackingEntities[nextObserverId] = {}
	State.observerIdToObserverObj[nextObserverId] = object
	State.observerEnabled[nextObserverId] = not data or data.enabled == nil or data.enabled
	local observerSafety = State.observerSafety
	local v3

	if data and data.safety ~= nil then
		v3 = data.safety
	else
		v3 = Config.Observer.safety
	end

	observerSafety[nextObserverId] = v3
	State.observerStaticCount[nextObserverId] = 0
	State.observerDynamicCount[nextObserverId] = 0

	v[nextObserverId] = false
	v2[nextObserverId] = false

	if data and data.zones then
		for _, zone in data.zones do
			object:attach(zone)
		end
	end

	if data and data.groups then
		for _, group in data.groups do
			object:subscribe(group)
		end
	end

	local v4 = data and data.zones ~= nil
	local v5 = data and data.groups ~= nil

	local v6 = not (v4 or v[nextObserverId])
	local v7 = not (v5 or v2[nextObserverId])

	if v6 or v7 then
		local traceback = debug.traceback("", 2)

		task.defer(function()
			if not (State.observerIdToObserverObj[nextObserverId] and object:isEnabled()) then
				return
			end

			if v6 and not v[nextObserverId] then
				Log.warn(
					"Observer %d has no attached zones. It will not detect spatial queries.",
					traceback,
					nextObserverId
				)
			end

			if v7 and not v2[nextObserverId] then
				Log.warn(
					"Observer %d has no subscribed groups. It will not track any entities.",
					traceback,
					nextObserverId
				)
			end
		end)
	end

	return object
end

function Observer:subscribe(p)
	v2[self.id] = true

	local id = p.id

	if not State.groupToObservers[id] then
		State.groupToObservers[id] = {}
	end

	State.groupToObservers[id][self.id] = true

	for _, entity in p.entities do
		dirtyProfiles[entity] = true
		dirtyTopology[entity] = true
	end

	return self
end

function Observer.unsubscribe(p, p2)
	local id = p2.id

	if State.groupToObservers[id] then
		State.groupToObservers[id][p.id] = nil
	end

	disconnectObserverFromGroup(p.id, p2)

	return p
end

function Observer:attach(object)
	v[self.id] = true
	object:attach(self)
	return self
end

function Observer:detach(object)
	object:detach(self)
	return self
end

function Observer:observe(callback)
	local v3 = {}
	local v4 = {}
	local count = 0

	local v5 = self:onEnter(function(p, p2, p3)
		count += 1
		local v5 = count
		v4[p3] = v5

		local v6 = callback(p, p2, p3)

		if v4[p3] == v5 then
			if type(v6) == "function" then
				v3[p3] = v6
			end
		elseif type(v6) == "function" then
			v6()
		end
	end)

	local v6 = self:onExit(function(_, _, p)
		v4[p] = nil

		local v6 = v3[p]

		if v6 then
			v3[p] = nil
			v6()
		end
	end)

	local function disconnect()
		v5()
		v6()

		table.clear(v4)

		for k, callback2 in v3 do
			v3[k] = nil
			task.spawn(callback2)
		end
	end

	local v7 = self:onDestroy(disconnect)

	return function()
		v7()
		disconnect()
	end
end

function Observer:onEnter(callback)
	table.insert(State.observerEnteredCallbacks[self.id], callback)
	return function()
		local index = table.find(State.observerEnteredCallbacks[self.id], callback)

		if index then
			table.remove(State.observerEnteredCallbacks[self.id], index)
		end
	end
end

function Observer:onExit(callback)
	table.insert(State.observerExitedCallbacks[self.id], callback)
	return function()
		local index = table.find(State.observerExitedCallbacks[self.id], callback)

		if index then
			table.remove(State.observerExitedCallbacks[self.id], index)
		end
	end
end

function Observer:observePlayer(callback)
	local v3 = {}
	local v4 = {}
	local count = 0

	local v5 = self:onEnter(function(player, p, p2)
		if typeof(player) ~= "Instance" or not player:IsA("Player") then
			return
		end

		count += 1
		local v5 = count
		v4[p2] = v5

		local v6 = callback(player, p, p2)

		if v4[p2] == v5 then
			if type(v6) == "function" then
				v3[p2] = v6
			end
		elseif type(v6) == "function" then
			v6()
		end
	end)

	local v6 = self:onExit(function(_, _, p)
		if not v4[p] then
			return
		end

		v4[p] = nil

		local v6 = v3[p]

		if v6 then
			v3[p] = nil
			v6()
		end
	end)

	local function disconnect()
		v5()
		v6()

		table.clear(v4)

		for k, callback2 in v3 do
			v3[k] = nil
			task.spawn(callback2)
		end
	end

	local v7 = self:onDestroy(disconnect)

	return function()
		v7()
		disconnect()
	end
end

function Observer:onPlayerEnter(callback)
	return self:onEnter(function(player, p, p2)
		if typeof(player) == "Instance" and player:IsA("Player") then
			callback(player, p, p2)
		end
	end)
end

function Observer:onPlayerExit(callback)
	return self:onExit(function(player, p, p2)
		if typeof(player) == "Instance" and player:IsA("Player") then
			callback(player, p, p2)
		end
	end)
end

function Observer:observeLocalPlayer(callback)
	if not isClient then
		Log.fatal("Observer:observeLocalPlayer can only be called on the Client.", nil)
	end

	local v3 = {}
	local v4 = {}
	local count = 0

	local v5 = self:onEnter(function(p, p2, p3)
		if p ~= Players.LocalPlayer then
			return
		end

		count += 1
		local v5 = count
		v4[p3] = v5

		local v6 = callback(p2, p3)

		if v4[p3] == v5 then
			if type(v6) == "function" then
				v3[p3] = v6
			end
		elseif type(v6) == "function" then
			v6()
		end
	end)

	local v6 = self:onExit(function(_, _, p)
		if not v4[p] then
			return
		end

		v4[p] = nil

		local v6 = v3[p]

		if v6 then
			v3[p] = nil
			v6()
		end
	end)

	local function disconnect()
		v5()
		v6()

		table.clear(v4)

		for k, callback2 in v3 do
			v3[k] = nil
			task.spawn(callback2)
		end
	end

	local v7 = self:onDestroy(disconnect)

	return function()
		v7()
		disconnect()
	end
end

function Observer:onLocalPlayerEnter(callback)
	if not isClient then
		Log.fatal("Observer:onLocalPlayerEnter can only be called on the Client.", nil)
	end

	return self:onEnter(function(p, p2, p3)
		if p == Players.LocalPlayer then
			callback(p2, p3)
		end
	end)
end

function Observer:onLocalPlayerExit(callback)
	if not isClient then
		Log.fatal("Observer:onLocalPlayerExit can only be called on the Client.", nil)
	end

	return self:onExit(function(p, p2, p3)
		if p == Players.LocalPlayer then
			callback(p2, p3)
		end
	end)
end

function Observer:observeGroup(callback)
	local v3 = {}
	local v4 = {}

	return self:observe(function(_, p, p2)
		local entityToGroup = State.entityToGroups[p2]

		if not entityToGroup then
			return nil
		end

		for k, _ in entityToGroup do
			local group = State.groups[k]

			if not (group and State.groupToObservers[k][self.id]) then
				continue
			end

			if not v3[k] then
				v3[k] = {}
			end

			if next(v3[k]) == nil then
				v3[k][p2] = true
				local v5 = callback(group, p, p2)

				if typeof(v5) == "function" then
					v4[k] = v5
				end
			else
				v3[k][p2] = true
			end
		end

		return function()
			for k, v5 in v3 do
				if not v5[p2] then
					continue
				end

				v5[p2] = nil

				if next(v5) ~= nil then
					continue
				end

				v3[k] = nil
				local v6 = v4[k]

				if not v6 then
					continue
				end

				v6()
				v4[k] = nil
			end
		end
	end)
end

function Observer:onGroupEnter(callback)
	local v3 = {}

	return self:observe(function(_, p, p2)
		local entityToGroup = State.entityToGroups[p2]

		if not entityToGroup then
			return nil
		end

		for k, _ in entityToGroup do
			if not (State.groupToObservers[k] and State.groupToObservers[k][self.id]) then
				continue
			end

			if not v3[k] then
				v3[k] = {}
			end

			local v4 = next(v3[k]) == nil
			v3[k][p2] = true

			if not v4 then
				continue
			end

			local group = State.groups[k]

			if group then
				callback(group, p, p2)
			end
		end

		return function()
			for k, v4 in v3 do
				if not v4[p2] then
					continue
				end

				v4[p2] = nil

				if next(v4) == nil then
					v3[k] = nil
				end
			end
		end
	end)
end

function Observer:onGroupExit(callback)
	local v3 = {}

	return self:observe(function(_, p, p2)
		local entityToGroup = State.entityToGroups[p2]

		if not entityToGroup then
			return nil
		end

		for k, _ in entityToGroup do
			if not (State.groupToObservers[k] and State.groupToObservers[k][self.id]) then
				continue
			end

			if not v3[k] then
				v3[k] = {}
			end

			v3[k][p2] = true
		end

		return function()
			for k, v4 in v3 do
				if not v4[p2] then
					continue
				end

				v4[p2] = nil

				if next(v4) ~= nil then
					continue
				end

				v3[k] = nil
				local group = State.groups[k]

				if group then
					callback(group, p, p2)
				end
			end
		end
	end)
end

function Observer:onTransition(callback)
	table.insert(State.observerTransitionedCallbacks[self.id], callback)

	return function()
		local index = table.find(State.observerTransitionedCallbacks[self.id], callback)

		if index then
			table.remove(State.observerTransitionedCallbacks[self.id], index)
		end
	end
end

function Observer:onPlayerTransition(callback)
	return self:onTransition(function(p, p2, p3)
		local player = State.entityToReference[p] or p

		if typeof(player) == "Instance" and player:IsA("Player") then
			callback(player, p2, p3)
		end
	end)
end

function Observer:onLocalPlayerTransition(callback)
	if not isClient then
		Log.fatal("Observer:onLocalPlayerTransition can only be called on the Client.", nil)
	end

	return self:onTransition(function(p, p2, p3)
		if (State.entityToReference[p] or p) == Players.LocalPlayer then
			callback(p2, p3)
		end
	end)
end

function Observer:setEnabled(flag: boolean)
	if self:isEnabled() == flag then
		return self
	end

	local id = self.id
	State.observerEnabled[id] = flag
	State.logicVersion += 1

	if not flag then
		for k, groupToObserver in State.groupToObservers do
			if not groupToObserver[id] then
				continue
			end

			local group = State.groups[k]

			if group then
				disconnectObserverFromGroup(id, group)
			end
		end
	end

	updateAllEntitiesForObserver(self.id)

	return self
end

function Observer.setSafety(p, flag: boolean)
	State.observerSafety[p.id] = flag
	return p
end

function Observer.setPriority(p, p2: number)
	State.observerPriorityMap[p.id] = p2
	State.logicVersion += 1
	return p
end

function Observer.setUpdateRate(p, p2: number)
	if p2 < 0 then
		Log.fatal("updateRate must be non-negative.", nil)
	end

	State.observerUpdateRate[p.id] = p2
	updateAllEntitiesForObserver(p.id)
	return p
end

function Observer.setPrecision(p, p2: number)
	if p2 < 0 then
		Log.fatal("precision must be non-negative.", nil)
	end

	State.observerPrecisionSq[p.id] = p2 ^ 2
	updateAllEntitiesForObserver(p.id)
	return p
end

function Observer:isEnabled(): boolean
	return State.observerEnabled[self.id] ~= false
end

function Observer.isPointInside(p, vector3: Vector3): boolean
	local x = vector3.X
	local y = vector3.Y
	local z = vector3.Z
	local id = p.id

	local nodes = dynamicTree.nodes

	local count = dynamicTree.count
	local v3 = 1

	while v3 <= count do
		local node = nodes[v3]
		local min = node.min
		local max = node.max

		if x < min.X or max.X < x or y < min.Y or max.Y < y or z < min.Z or max.Z < z then
			v3 = node.skipIndex
		else
			local id2 = node.id
			v3 += 1

			if id2 ~= 0 then
				local zoneAttachedObserver = zoneAttachedObservers[id2]

				if
					zoneAttachedObserver
					and table.find(zoneAttachedObserver, id)
					and isPointInShape(
						vector3,
						dynamicCFrames[id2],
						dynamicHalfSizes[id2],
						dynamicTypes[id2],
						dynamicMeshes[id2]
					)
				then
					return true
				end
			end
		end
	end

	local nodes2 = staticTree.nodes

	local count2 = staticTree.count
	local v4 = 1

	while v4 <= count2 do
		local node = nodes2[v4]
		local min = node.min
		local max = node.max

		if x < min.X or max.X < x or y < min.Y or max.Y < y or z < min.Z or max.Z < z then
			v4 = node.skipIndex
		else
			local id2 = node.id
			v4 += 1

			if id2 ~= 0 then
				local zoneAttachedObserver = zoneAttachedObservers[id2]

				if
					zoneAttachedObserver
					and table.find(zoneAttachedObserver, id)
					and isPointInShape(
						vector3,
						staticCFrames[id2],
						staticHalfSizes[id2],
						staticTypes[id2],
						staticMeshes[id2]
					)
				then
					return true
				end
			end
		end
	end

	return false
end

function Observer.isSafe(p)
	return State.observerSafety[p.id]
end

function Observer:getId()
	return self.id
end

function Observer.getPriority(p)
	return State.observerPriorityMap[p.id]
end

function Observer.getUpdateRate(p)
	return State.observerUpdateRate[p.id]
end

function Observer.getPrecision(p)
	return (math.sqrt(State.observerPrecisionSq[p.id]))
end

function Observer.getEntitiesInside(p)
	local observerTrackingEntity = State.observerTrackingEntities[p.id]

	if not observerTrackingEntity then
		return {}
	end

	local result = {}

	for k, _ in observerTrackingEntity do
		table.insert(result, State.entityToReference[k] or k)
	end

	return result
end

function Observer.getPlayersInside(p)
	local players = {}

	for k in State.observerTrackingEntities[p.id] do
		local player = State.entityToReference[k] or k

		if typeof(player) ~= "Instance" or not player:IsA("Player") or table.find(players, player) then
			continue
		end

		table.insert(players, player)
	end

	return players
end

function Observer.getZones(p)
	local zoneObjs = {}

	for k, list in State.zoneAttachedObservers do
		if not table.find(list, p.id) then
			continue
		end

		local zoneObj = State.zoneIdToZoneObj[k]

		if zoneObj then
			table.insert(zoneObjs, zoneObj)
		end
	end

	return zoneObjs
end

function Observer.getGroups(p)
	local groups = {}

	for k, groupToObserver in State.groupToObservers do
		if not groupToObserver[p.id] then
			continue
		end

		local group = State.groups[k]

		if group then
			table.insert(groups, group)
		end
	end

	return groups
end

function Observer:getZoneOfEntity(p)
	local v3 = State.referenceToEntity[p] or p

	local v4 = State.entityData[v3]

	if not v4 then
		return nil
	end

	local activeObserverMembership = v4.activeObserverMemberships[self.id]

	if activeObserverMembership then
		return State.zoneIdToZoneObj[activeObserverMembership]
	end

	return nil
end

function Observer:getZoneOfPlayer(p)
	return self:getZoneOfEntity(p)
end

function Observer:getEntitiesInZone(p)
	local entitiesInZone = {}

	for k in self:iterEntitiesInZone(p) do
		table.insert(entitiesInZone, k)
	end

	return entitiesInZone
end

function Observer:getPlayersInZone(p)
	local playersInZone = {}

	for k in self:iterPlayersInZone(p) do
		table.insert(playersInZone, k)
	end

	return playersInZone
end

function Observer.iterZones(p)
	local v3 = nil
	local v4 = nil
	local id = p.id

	return function()
		while true do
			v3, v4 = next(zoneAttachedObservers, v3)

			if not v3 then
				return nil
			end

			local v5 = table.find(v4, id) and State.zoneIdToZoneObj[v3]

			if v5 then
				return v5
			end
		end
	end
end

function Observer.iterGroups(p)
	local v3 = nil
	local v4 = nil
	local id = p.id

	return function()
		while true do
			v3, v4 = next(State.groupToObservers, v3)

			if not v3 then
				return nil
			end

			local v5 = v4[id] and State.groups[v3]

			if v5 then
				return v5
			end
		end
	end
end

function Observer.iterEntitiesInside(p)
	local v3 = State.observerTrackingEntities[p.id] or {}
	local v4 = nil
	local id = p.id

	return function()
		while true do
			v4 = next(v3, v4)

			if not v4 then
				return nil
			end

			local v5 = State.entityData[v4]

			local v6 = v5 and v5.activeObserverMemberships[id]

			if v6 then
				return State.entityToReference[v4] or v4, State.zoneIdToZoneObj[v6]
			end
		end
	end
end

function Observer.iterPlayersInside(p)
	local v3 = State.observerTrackingEntities[p.id] or {}
	local v4 = nil
	local id = p.id

	return function()
		while true do
			v4 = next(v3, v4)

			if not v4 then
				return nil, nil
			end

			local v5 = State.entityData[v4]

			local v6 = v5 and v5.activeObserverMemberships[id]

			if not v6 then
				continue
			end

			local player = State.entityToReference[v4] or v4

			if typeof(player) == "Instance" and player:IsA("Player") then
				return player, State.zoneIdToZoneObj[v6]
			end
		end
	end
end

function Observer:iterEntitiesInZone(object)
	local observerTrackingEntity = State.observerTrackingEntities[self.id]

	if not observerTrackingEntity then
		return function(): nil
			return nil
		end
	end

	local v3 = nil
	local id = object:getId()
	local id2 = self.id

	return function()
		while true do
			v3 = next(observerTrackingEntity, v3)

			if not v3 then
				return nil
			end

			local v4 = State.entityData[v3]

			if v4 and v4.activeObserverMemberships[id2] == id then
				return State.entityToReference[v3] or v3
			end
		end
	end
end

function Observer:iterPlayersInZone(object)
	local observerTrackingEntity = State.observerTrackingEntities[self.id]

	if not observerTrackingEntity then
		return function(): nil
			return nil
		end
	end

	local v3 = nil
	local id = object:getId()
	local id2 = self.id

	return function()
		while true do
			v3 = next(observerTrackingEntity, v3)

			if not v3 then
				return nil
			end

			local v4 = State.entityData[v3]

			if not (v4 and v4.activeObserverMemberships[id2] == id) then
				continue
			end

			local player = State.entityToReference[v3] or v3

			if typeof(player) == "Instance" and player:IsA("Player") then
				return player
			end
		end
	end
end

function Observer:onDestroy(callback)
	if not self.onDestroyCallbacks then
		self.onDestroyCallbacks = {}
	end

	table.insert(self.onDestroyCallbacks, callback)

	return function()
		local index = table.find(self.onDestroyCallbacks, callback)

		if index then
			table.remove(self.onDestroyCallbacks, index)
		end
	end
end

function Observer:destroy()
	if self.onDestroyCallbacks then
		for _, callback in self.onDestroyCallbacks do
			task.spawn(callback)
		end

		table.clear(self.onDestroyCallbacks)
	end

	self:setEnabled(false)

	local id = self.id

	for _, groupToObserver in State.groupToObservers do
		groupToObserver[id] = nil
	end

	for _, list in State.zoneAttachedObservers do
		local index = table.find(list, id)

		if not index then
			continue
		end

		local count = #list

		if index ~= count then
			list[index] = list[count]
		end

		list[count] = nil
	end

	State.observerPriorityMap[id] = nil
	State.observerEnteredCallbacks[id] = nil
	State.observerExitedCallbacks[id] = nil
	State.observerTransitionedCallbacks[id] = nil
	State.observerTrackingEntities[id] = nil
	State.observerIdToObserverObj[id] = nil
	State.observerEnabled[id] = nil
	State.observerSafety[id] = nil
	State.observerUpdateRate[id] = nil
	State.observerPrecisionSq[id] = nil
	State.observerStaticCount[id] = nil
	State.observerDynamicCount[id] = nil

	v[id] = nil
	v2[id] = nil

	State.logicVersion += 1
	setmetatable(self, nil)
end

return Observer