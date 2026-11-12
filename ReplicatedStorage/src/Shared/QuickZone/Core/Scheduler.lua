--!native
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Parent.Config)
require(script.Parent.Parent.Types)
local Geometry = require(script.Parent.Parent.Utils.Geometry)
local LinearBVH = require(script.Parent.Parent.Utils.LinearBVH)
local Log = require(script.Parent.Parent.Utils.Log)
local State = require(script.Parent.State)

local queryPoint = LinearBVH.queryPoint
local isPointInShape = Geometry.isPointInShape

local staticCFrames = State.staticCFrames
local staticHalfSizes = State.staticHalfSizes
local staticTypes = State.staticTypes
local staticMeshes = State.staticMeshes
local dynamicCFrames = State.dynamicCFrames
local dynamicHalfSizes = State.dynamicHalfSizes
local dynamicTypes = State.dynamicTypes
local dynamicMeshes = State.dynamicMeshes
local zoneIdToZoneObj = State.zoneIdToZoneObj
local zoneAttachedObservers = State.zoneAttachedObservers
local autoSyncZones = State.autoSyncZones

local observerPriorityMap = State.observerPriorityMap
local observerTrackingEntities = State.observerTrackingEntities
local observerEnteredCallbacks = State.observerEnteredCallbacks
local observerExitedCallbacks = State.observerExitedCallbacks
local observerTransitionedCallbacks = State.observerTransitionedCallbacks
local observerEnabled = State.observerEnabled
local observerSafety = State.observerSafety
local observerPrecisionSq = State.observerPrecisionSq
local observerUpdateRate = State.observerUpdateRate
local observerStaticCount = State.observerStaticCount
local observerDynamicCount = State.observerDynamicCount

local entityToReference = State.entityToReference
local entityData = State.entityData
local entityToObservers = State.entityToObservers
local entityToGroups = State.entityToGroups
local groupToObservers = State.groupToObservers
local dirtyProfiles = State.dirtyProfiles
local dirtyTopology = State.dirtyTopology

local staticTree = State.staticTree
local dynamicTree = State.dynamicTree

local vector3 = nil
local count = 0
local v = nil
local v2 = table.create(16)
local v3 = table.create(16)
local v4 = table.create(16)
local v5 = nil
local activeObserverMemberships = nil

local v6 = Config.Scheduler.frameBudget
local v7 = Config.Scheduler.autoSyncRate
local total = 0
local postSimulationConnection = nil

local bucketList = State.bucketList
local buckets = State.buckets
local v8 = 1
local v9 = {}

local pos = Config.Strategy.POS
local prim = Config.Strategy.PRIM
local world = Config.Strategy.WORLD
local cframe = Config.Strategy.CFRAME
local transform = Config.Strategy.TRANSFORM
local pivot = Config.Strategy.PIVOT

local function processProfileChange(k)
	local entityToGroup = entityToGroups[k]

	if not entityToGroup then
		return
	end

	local v10 = entityToObservers[k]

	if v10 then
		table.clear(v10)
	else
		v10 = {}
	end

	local precisionSq = 1e999
	local updateRate2 = 0

	for k2, _ in entityToGroup do
		local groupToObserver = groupToObservers[k2]

		if not groupToObserver then
			continue
		end

		for k3, _ in groupToObserver do
			v10[k3] = true

			local v11 = observerPrecisionSq[k3]
			local v12 = observerUpdateRate[k3]

			if v11 < precisionSq then
				precisionSq = v11
			end

			if updateRate2 < v12 then
				updateRate2 = v12
			end
		end
	end

	local v11 = entityData[k]
	local updateRate = v11.updateRate

	if updateRate ~= updateRate2 then
		if updateRate and updateRate > 0 and buckets[updateRate] then
			local bucket = buckets[updateRate]
			local bucketIndex = v11.bucketIndex
			local count2 = #bucket
			local v12 = bucket[count2]

			if bucketIndex ~= count2 then
				bucket[bucketIndex] = v12

				if entityData[v12] then
					entityData[v12].bucketIndex = bucketIndex
				end
			end

			bucket[count2] = nil

			if #bucket == 0 then
				buckets[updateRate] = nil
				local index = table.find(bucketList, updateRate)

				if index then
					table.remove(bucketList, index)
				end
			end
		end

		if updateRate2 > 0 then
			if not buckets[updateRate2] then
				buckets[updateRate2] = {}
				table.insert(bucketList, updateRate2)
				table.sort(bucketList, function(a: number, b: number): boolean
					return b < a
				end)
			end

			local bucket = buckets[updateRate2]
			local bucketIndex = #bucket + 1
			bucket[bucketIndex] = k
			v11.bucketIndex = bucketIndex
		else
			v11.bucketIndex = 0
		end

		v11.updateRate = updateRate2
	end

	if updateRate2 > 0 then
		v11.precisionSq = precisionSq
		entityToObservers[k] = v10
	else
		entityToObservers[k] = nil
	end
end

local function processTopologyChange(k)
	local v10 = entityData[k]

	if not v10 then
		return
	end

	local needsStatic = false
	local needsDynamic = false
	local entityToObserver = entityToObservers[k]

	if entityToObserver then
		for k2, _ in entityToObserver do
			needsStatic = (observerStaticCount[k2] or 0) > 0 or needsStatic

			needsDynamic = (observerDynamicCount[k2] or 0) > 0 or needsDynamic

			if needsStatic and needsDynamic then
				break
			end
		end
	end

	v10.needsStatic = needsStatic
	v10.needsDynamic = needsDynamic
end

local function processZoneHit(p: number)
	local zoneAttachedObserver = zoneAttachedObservers[p]

	if not zoneAttachedObserver then
		return
	end

	for _, v10 in zoneAttachedObserver do
		if not (v5[v10] and observerEnabled[v10] ~= false) then
			continue
		end

		local v11 = v2[v10]
		local v12 = observerPriorityMap[v10] or 0

		if v11 then
			if v11 < v12 then
				v3[v10] = p
				v2[v10] = v12

				if v < v12 then
					v = v12
				end
			elseif v12 == v11 and activeObserverMemberships[v10] == p then
				v3[v10] = p
			end
		else
			count += 1
			v4[count] = v10
			v3[v10] = p
			v2[v10] = v12

			if v < v12 then
				v = v12
			end
		end
	end
end

local function queryCallbackStatic(p: number)
	if isPointInShape(vector3, staticCFrames[p], staticHalfSizes[p], staticTypes[p], staticMeshes[p]) then
		processZoneHit(p)
	end
end

local function queryCallbackDynamic(p: number)
	if isPointInShape(vector3, dynamicCFrames[p], dynamicHalfSizes[p], dynamicTypes[p], dynamicMeshes[p]) then
		processZoneHit(p)
	end
end

local function fireCallback(items, p, zoneObj, p2, flag: boolean)
	if flag then
		for _, callback in items do
			task.spawn(callback, p, zoneObj, p2)
		end
	else
		for _, item in items do
			item(p, zoneObj, p2)
		end
	end
end

local Scheduler = {}

function Scheduler.update(p: number)
	local lastTime = os.clock()

	for k, _ in dirtyProfiles do
		dirtyProfiles[k] = nil

		if entityData[k] then
			processProfileChange(k)
		end
	end

	for k, _ in dirtyTopology do
		dirtyTopology[k] = nil

		if entityData[k] then
			processTopologyChange(k)
		end
	end

	if v7 > 0 then
		local v10 = 1 / v7
		total += p

		if v10 <= total then
			total = 0
			local flag = false

			for k, autoSyncZone in autoSyncZones do
				local reference = autoSyncZone.reference

				if not reference then
					continue
				end

				local worldCFrame = reference:IsA("Attachment") and reference.WorldCFrame or reference.CFrame

				if dynamicCFrames[k] == worldCFrame then
					continue
				end

				dynamicCFrames[k] = worldCFrame
				flag = true
			end

			if flag then
				State.pendingDynamicRebuild = true
			end
		end
	end

	Scheduler.rebuildTrees()

	local v10 = os.clock() - lastTime

	if v6 < v10 then
		return
	end

	local count2 = #bucketList

	if count2 == 0 then
		return
	end

	if count2 < v8 then
		v8 = 1
	end

	local dynamicVersion = State.dynamicVersion
	local staticVersion = State.staticVersion
	local logicVersion = State.logicVersion

	for _ = 1, count2 do
		local bucket = bucketList[v8]
		v8 = v8 % count2 + 1

		local bucket2 = buckets[bucket]
		local count3 = #bucket2

		if count3 == 0 then
			continue
		end

		local v11 = math.clamp(math.ceil(count3 * bucket * p), 1, count3)

		local v12 = v9[bucket] or 1
		local v13 = count3 < v12 and 1 or v12
		local count4 = 0
		local v14 = 32

		while count4 < v11 do
			local v15 = bucket2[v13]
			local v16 = entityData[v15]

			local lastPosition2 = nil
			local strategy = v16.strategy

			if strategy == pos then
				lastPosition2 = v15.Position
			elseif strategy == world then
				lastPosition2 = v15.WorldPosition
			elseif strategy == cframe then
				lastPosition2 = v15.CFrame.Position
			elseif strategy == transform then
				lastPosition2 = v15.Transform.Position
			elseif strategy == prim then
				local primaryPart = v15.PrimaryPart
				lastPosition2 = primaryPart and primaryPart.Position or v15:GetPivot().Position
			elseif strategy == pivot then
				lastPosition2 = v15:GetPivot().Position
			end

			local needsStatic = v16.needsStatic
			local needsDynamic = v16.needsDynamic
			local v17

			if
				v16.logicVersion == logicVersion
				and (not needsDynamic or v16.dynamicVersion == dynamicVersion)
				and (not needsStatic or v16.staticVersion == staticVersion)
			then
				local lastPosition = v16.lastPosition
				local v18 = lastPosition2.X - lastPosition.X
				local v19 = lastPosition2.Y - lastPosition.Y
				local v20 = lastPosition2.Z - lastPosition.Z

				v17 = v18 * v18 + v19 * v19 + v20 * v20 >= v16.precisionSq or false
			else
				v17 = true
			end

			if v17 then
				v16.lastPosition = lastPosition2
				v16.dynamicVersion = dynamicVersion
				v16.logicVersion = logicVersion
				v16.staticVersion = staticVersion

				v5 = entityToObservers[v15]
				activeObserverMemberships = v16.activeObserverMemberships

				vector3 = lastPosition2
				count = 0
				v = -1e999

				if needsDynamic then
					queryPoint(dynamicTree, lastPosition2, queryCallbackDynamic)
				end

				if needsStatic then
					queryPoint(staticTree, lastPosition2, queryCallbackStatic)
				end

				local activeObserverMemberships2 = v16.activeObserverMemberships

				for k, activeObserverMembership in activeObserverMemberships2 do
					local v18 = v2[k]

					if v18 and v <= v18 then
						continue
					end

					activeObserverMemberships2[k] = nil

					if observerTrackingEntities[k] then
						observerTrackingEntities[k][v15] = nil
					end

					local observerExitedCallback = observerExitedCallbacks[k]

					if not observerExitedCallback then
						continue
					end

					local v19 = observerSafety[k]
					local zoneObj = zoneIdToZoneObj[activeObserverMembership]
					fireCallback(observerExitedCallback, entityToReference[v15] or v15, zoneObj, v15, v19)
				end

				for i = 1, count do
					local v18 = v4[i]
					local v19 = v2[v18]
					local v20 = v3[v18]

					v2[v18] = nil
					v3[v18] = nil
					v4[i] = nil

					if not observerTrackingEntities[v18] or v19 < v then
						continue
					end

					local activeObserverMembership = activeObserverMemberships2[v18]

					if activeObserverMembership == v20 then
						continue
					end

					activeObserverMemberships2[v18] = v20
					local v21 = observerSafety[v18]

					if activeObserverMembership then
						local observerTransitionedCallback = observerTransitionedCallbacks[v18]

						if observerTransitionedCallback then
							local zoneObj = zoneIdToZoneObj[v20]
							fireCallback(observerTransitionedCallback, entityToReference[v15] or v15, zoneObj, v15, v21)
						end
					else
						observerTrackingEntities[v18][v15] = true

						local observerEnteredCallback = observerEnteredCallbacks[v18]

						if observerEnteredCallback then
							local zoneObj = zoneIdToZoneObj[v20]
							fireCallback(observerEnteredCallback, entityToReference[v15] or v15, zoneObj, v15, v21)
						end
					end
				end
			end

			local v18 = v13 + 1
			v13 = count3 < v18 and 1 or v18

			count4 += 1

			v14 -= 1

			if v14 ~= 0 then
				continue
			end

			local v19 = os.clock() - lastTime

			if v6 < v19 then
				break
			end

			v14 = 32
		end

		v9[bucket] = v13

		local v15 = os.clock() - lastTime

		if v6 < v15 then
			break
		end
	end
end

function Scheduler.setEnabled(flag: boolean)
	if flag then
		if not postSimulationConnection then
			postSimulationConnection = RunService.PostSimulation:Connect(Scheduler.update)
		end
	elseif postSimulationConnection then
		postSimulationConnection:Disconnect()
		postSimulationConnection = nil
	end
end

function Scheduler.setAutoSyncRate(p: number)
	v7 = if p <= 0 then 0 else p
end

function Scheduler.setFrameBudget(p: number)
	if p <= 0 then
		Log.fatal("frameBudget must be greater than 0.", nil)
	end

	v6 = p
end

function Scheduler.rebuildTrees()
	if State.pendingDynamicRebuild then
		LinearBVH.build(dynamicTree, dynamicCFrames, dynamicHalfSizes)
		State.pendingDynamicRebuild = false
		State.dynamicVersion += 1
	end

	if State.pendingStaticRebuild then
		LinearBVH.build(staticTree, staticCFrames, staticHalfSizes)
		State.pendingStaticRebuild = false
		State.staticVersion += 1
	end
end

Scheduler.setEnabled(Config.Scheduler.enabled)

return Scheduler