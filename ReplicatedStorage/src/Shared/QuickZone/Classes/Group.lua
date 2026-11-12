local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

require(script.Parent.Parent.Types)
local Config = require(script.Parent.Parent.Config)
local PlayerTracker = require(script.Parent.Parent.Core.PlayerTracker)
local State = require(script.Parent.Parent.Core.State)
local Log = require(script.Parent.Parent.Utils.Log)

local pos = Config.Strategy.POS
local prim = Config.Strategy.PRIM
local world = Config.Strategy.WORLD
local cframe = Config.Strategy.CFRAME
local transform = Config.Strategy.TRANSFORM
local pivot = Config.Strategy.PIVOT

local precisionSq = Config.Observer.precision ^ 2

local isClient = RunService:IsClient()

local Group = {}
Group.__index = Group

function Group.new(p)
	local nextGroupId = State.nextGroupId
	State.nextGroupId += 1

	local autoClean = Config.Group.autoClean

	if p and p.autoClean ~= nil then
		autoClean = p.autoClean
	end

	local object = setmetatable({
		id = nextGroupId,
		entities = {},
		entityIndices = {},
		autoClean = autoClean
	}, Group)

	State.groups[nextGroupId] = object
	State.groupToObservers[nextGroupId] = {}
	State.groupEntityCleanups[nextGroupId] = {}

	if p and p.entities then
		object:_addBulk(p.entities)
	end

	return object
end

function Group.fromTag(tag: string)
	local v = Group.new({ autoClean = false, entities = nil })
	v.isManaged = true

	local v2 = {}

	local function checkAncestry(instance) -- 2 equivalent calls inferred from this helper
		if instance:IsDescendantOf(workspace) then
			v:_add(instance)
		else
			v:_remove(instance)
		end
	end

	local function startWatching(instance)
		if v2[instance] then
			return
		end

		if not (instance:IsA("BasePart") or instance:IsA("Model") or instance:IsA("Attachment") or instance:IsA("Bone") or instance:IsA("Camera")) then
			return
		end

		v2[instance] = instance.AncestryChanged:Connect(function()
			checkAncestry(instance) -- inferred equivalent call
		end)
		checkAncestry(instance) -- inferred equivalent call
	end

	local function stopWatching(k) -- 1 equivalent call inferred from this helper
		local connection = v2[k]

		if connection then
			connection:Disconnect()
			v2[k] = nil
		end

		v:_remove(k)
	end

	local connection = CollectionService:GetInstanceAddedSignal(tag):Connect(startWatching)
	local connection2 = CollectionService:GetInstanceRemovedSignal(tag):Connect(stopWatching)

	for _, v3 in CollectionService:GetTagged(tag) do
		startWatching(v3)
	end

	v:onDestroy(function()
		connection:Disconnect()
		connection2:Disconnect()

		for k, _ in v2 do
			stopWatching(k) -- inferred equivalent call
		end
	end)

	return v
end

function Group.players()
	local v = Group.new({ autoClean = false, entities = nil })
	v.isManaged = true

	local playerAddedConnection = Players.PlayerAdded:Connect(function(player)
		v:_add(player)
	end)

	for _, v2 in Players:GetPlayers() do
		v:_add(v2)
	end

	v:onDestroy(function()
		playerAddedConnection:Disconnect()
	end)

	return v
end

function Group.localPlayer()
	if not isClient then
		Log.fatal("Group.localPlayer() can only be called on the Client.", nil)
	end

	local v = Group.new({ autoClean = false, entities = nil })
	v.isManaged = true

	v:_add(Players.LocalPlayer)

	return v
end

function Group:setAutoClean(autoClean: boolean)
	if self.isManaged then
		Log.warn("Cannot set autoClean on a Managed Group. Ignoring request.", nil)
		return self
	end

	if self.autoClean == autoClean then
		return self
	end

	self.autoClean = autoClean
	local groupEntityCleanup = State.groupEntityCleanups[self.id]

	if autoClean then
		for _, entity in self.entities do
			if typeof(entity) ~= "Instance" or groupEntityCleanup[entity] then
				continue
			end

			groupEntityCleanup[entity] = entity.AncestryChanged:Connect(function(_, parent)
				if not parent then
					self:_remove(entity)
				end
			end)
		end
	else
		for k, connection in groupEntityCleanup do
			connection:Disconnect()
			groupEntityCleanup[k] = nil
		end
	end

	return self
end

function Group:add(p)
	if not self.isManaged then
		return self:_add(p)
	end

	Log.warn("Cannot manually add to a Managed Group. Ignoring request.", nil)
	return self
end

function Group:addBulk(p)
	if not self.isManaged then
		return self:_addBulk(p)
	end

	Log.warn("Cannot manually addBulk to a Managed Group. Ignoring request.", nil)
	return self
end

function Group:remove(p)
	if not self.isManaged then
		return self:_remove(p)
	end

	Log.warn("Cannot manually remove from a Managed Group. Ignoring request.", nil)
	return self
end

function Group:removeBulk(p)
	if not self.isManaged then
		return self:_removeBulk(p)
	end

	Log.warn("Cannot manually removeBulk from a Managed Group. Ignoring request.", nil)
	return self
end

function Group:clear()
	if not self.isManaged then
		return self:_clear()
	end

	Log.warn("Cannot clear a Managed Group. Ignoring request.", nil)
	return self
end

function Group.contains(p, p2)
	local v = State.referenceToEntity[p2] or p2
	local entityToGroup = State.entityToGroups[v]
	return entityToGroup and entityToGroup[p.id] == true and true or false
end

function Group.getId(p)
	return p.id
end

function Group.getEntities(p)
	local entities = table.create(#p.entities)

	for i, entity in ipairs(p.entities) do
		entities[i] = State.entityToReference[entity] or entity
	end

	return entities
end

function Group.iterEntities(p)
	local v = nil

	return function()
		v = next(p.entityIndices, v)

		return v and (State.entityToReference[v] or v)
	end
end

function Group:onDestroy(callback)
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

function Group:destroy()
	if self.onDestroyCallbacks then
		for _, callback in self.onDestroyCallbacks do
			task.spawn(callback)
		end

		table.clear(self.onDestroyCallbacks)
	end

	for i = #self.entities, 1, -1 do
		self:_remove(self.entities[i])
	end

	State.groupToObservers[self.id] = nil
	State.groups[self.id] = nil
	State.groupEntityCleanups[self.id] = nil

	setmetatable(self, nil)
end

function Group:_add(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		PlayerTracker.subscribe(player, self)
		return self
	end

	local instance = State.referenceToEntity[player] or player

	if not State.entityToGroups[instance] then
		State.entityToGroups[instance] = {}
	end

	if State.entityToGroups[instance][self.id] then
		return self
	end

	State.entityToGroups[instance][self.id] = true

	if not State.entityData[instance] then
		local strategy = nil

		if typeof(instance) == "Instance" then
			if instance:IsA("BasePart") then
				strategy = pos
			elseif instance:IsA("Attachment") or instance:IsA("Bone") then
				strategy = world
			elseif instance:IsA("Camera") then
				strategy = cframe
			elseif instance:IsA("Model") then
				strategy = instance.PrimaryPart and prim or pivot
			end
		elseif typeof(instance) == "table" then
			if instance.Position then
				strategy = pos
			elseif instance.CFrame then
				strategy = cframe
			elseif instance.Transform then
				strategy = transform
			elseif instance.WorldPosition then
				strategy = world
			elseif instance.GetPivot then
				strategy = pivot
			end
		end

		if strategy then
			State.entityData[instance] = {
				strategy = strategy,
				lastPosition = Vector3.new(0, 0, 0),
				activeObserverMemberships = {},
				precisionSq = precisionSq,
				updateRate = -1,
				bucketIndex = 0,
				dynamicVersion = -1,
				staticVersion = -1,
				logicVersion = -1,
				needsStatic = false,
				needsDynamic = false
			}
		else
			Log.nonFatal(
				"Invalid entity (%s). Expected BasePart, Model, Bone, Attachment, Camera, or a valid EntityTable.",
				nil,
				(tostring(instance))
			)

			State.entityToGroups[instance][self.id] = nil
			return self
		end
	end

	local v = #self.entities + 1
	self.entities[v] = instance
	self.entityIndices[instance] = v

	State.dirtyProfiles[instance] = true
	State.dirtyTopology[instance] = true
	State.entityData[instance].logicVersion = -1

	if self.autoClean and typeof(instance) == "Instance" and not State.groupEntityCleanups[self.id][instance] then
		State.groupEntityCleanups[self.id][instance] = instance.AncestryChanged:Connect(function(_, parent)
			if not parent then
				self:_remove(instance)
			end
		end)
	end

	return self
end

function Group:_addBulk(items)
	for _, item in items do
		self:_add(item)
	end

	return self
end

function Group:_remove(player)
	if typeof(player) == "Instance" and player:IsA("Player") then
		PlayerTracker.unsubscribe(player, self)
		return self
	end

	local v = State.referenceToEntity[player] or player

	if not (State.entityToGroups[v] and State.entityToGroups[v][self.id]) then
		return self
	end

	local connection = State.groupEntityCleanups[self.id][v]

	if connection then
		connection:Disconnect()
		State.groupEntityCleanups[self.id][v] = nil
	end

	State.entityToGroups[v][self.id] = nil
	local v2 = State.entityData[v]

	local entityIndice = self.entityIndices[v]
	local count = #self.entities

	if entityIndice == count then
		self.entities[count] = nil
		self.entityIndices[v] = nil
	else
		local entity = self.entities[count]
		self.entities[entityIndice] = entity
		self.entityIndices[entity] = entityIndice
		self.entities[count] = nil
		self.entityIndices[v] = nil
	end

	State.dirtyProfiles[v] = true
	State.dirtyTopology[v] = true

	for k, activeObserverMembership in v2.activeObserverMemberships do
		local v3 = false

		for k2 in State.entityToGroups[v] do
			if State.groupToObservers[k2] and State.groupToObservers[k2][k] then
				v3 = true
				break
			end
		end

		if v3 then
			continue
		end

		v2.activeObserverMemberships[k] = nil

		if State.observerTrackingEntities[k] then
			State.observerTrackingEntities[k][v] = nil
		end

		local observerExitedCallback = State.observerExitedCallbacks[k]

		if not observerExitedCallback then
			continue
		end

		local v4 = State.observerSafety[k]
		local zoneObj = State.zoneIdToZoneObj[activeObserverMembership]
		local v5 = State.entityToReference[v] or v

		for _, callback in observerExitedCallback do
			if v4 then
				task.spawn(callback, v5, zoneObj, v)
			else
				callback(v5, zoneObj, v)
			end
		end
	end

	if next(State.entityToGroups[v]) ~= nil then
		return self
	end

	local updateRate = v2.updateRate

	if updateRate and updateRate > 0 and State.buckets[updateRate] then
		local bucket = State.buckets[updateRate]
		local bucketIndex = v2.bucketIndex
		local count2 = #bucket
		local v3 = bucket[count2]

		if bucketIndex ~= count2 then
			bucket[bucketIndex] = v3

			if State.entityData[v3] then
				State.entityData[v3].bucketIndex = bucketIndex
			end
		end

		bucket[count2] = nil
	end

	State.entityData[v] = nil
	State.entityToGroups[v] = nil
	State.entityToObservers[v] = nil
	State.dirtyProfiles[v] = nil
	State.dirtyTopology[v] = nil

	local player2 = State.entityToReference[v]

	if player2 and (typeof(player2) ~= "Instance" or not player2:IsA("Player")) then
		State.entityToReference[v] = nil

		if State.referenceToEntity[player2] == v then
			State.referenceToEntity[player2] = nil
		end
	end

	return self
end

function Group:_removeBulk(items)
	for _, item in items do
		self:_remove(item)
	end

	return self
end

function Group:_clear()
	local entities = self.entities

	for i = #entities, 1, -1 do
		self:_remove(entities[i])
	end

	return self
end

return Group