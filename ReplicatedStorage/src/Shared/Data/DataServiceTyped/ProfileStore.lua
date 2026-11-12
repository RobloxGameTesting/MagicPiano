local v = 300
local v2 = 10
local v3 = 5
local v4 = 40
local v5 = 630
local v6 = 120

local v7 = 5
local v8 = 120
local v9 = 120

local v10 = 1000

local v11 = nil

local function AcquireRunnerThreadAndCallEventHandler(callback, ...)
	local v12 = v11
	v11 = nil
	callback(...)

	v11 = v12
end

local function RunEventHandlerInFreeThread(...)
	AcquireRunnerThreadAndCallEventHandler(...)

	while true do
		AcquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

local class = {}
class.__index = class

local class2 = {}
class2.__index = class2

function class:Disconnect()
	if self.is_connected == false then
		return
	end

	local signal = self.signal
	self.is_connected = false
	signal.listener_count -= 1

	if signal.head == self then
		signal.head = self.next
		return
	end

	local v12 = signal.head

	while v12 ~= nil and v12.next ~= self do
		v12 = v12.next
	end

	if v12 ~= nil then
		v12.next = self.next
	end
end

function class2.New()
	local v12 = { head = nil, listener_count = 0 }

	setmetatable(v12, class2)

	return v12
end

function class2:Connect(listener)
	if type(listener) ~= "function" then
		error(`[{script.Name}]: "listener" must be a function; Received {typeof(listener)}`)
	end

	local head = { listener = listener, signal = self, next = self.head, is_connected = true }

	setmetatable(head, class)

	self.head = head
	self.listener_count += 1

	return head
end

function class2.GetListenerCount(p)
	return p.listener_count
end

function class2:Fire(...)
	local v12 = self.head

	while v12 ~= nil do
		if v12.is_connected == true then
			if not v11 then
				v11 = coroutine.create(RunEventHandlerInFreeThread)
			end

			task.spawn(v11, v12.listener, ...)
		end

		v12 = v12.next
	end
end

function class2:Wait()
	local thread = coroutine.running()
	local connection = nil
	connection = self:Connect(function(...)
		connection:Disconnect()
		task.spawn(thread, ...)
	end)
	return coroutine.yield()
end

local frozen = table.freeze({ New = class2.New })

local activeSessionCheck = {}
local autoSaveList = {}
local nows = {}

local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local PlaceId = game.PlaceId
local JobId = game.JobId

local v12 = 1
local now = os.clock()

local count = 0

local activeProfileLoadJobs = 0
local activeProfileSaveJobs = 0

local lastTime = 0

local isStudio = RunService:IsStudio()
local v13 = "NotReady"

local mockStore = {}
local userMockStore = {}
local v14 = false

local onError = frozen.New()
local onOverwrite = frozen.New()

local updateQueue = {}

local function WaitInUpdateQueue(p)
	local v15

	if updateQueue[p] == nil then
		updateQueue[p] = {}
		v15 = true
	else
		v15 = false
	end

	local threads = updateQueue[p]

	if v15 == false then
		table.insert(threads, coroutine.running())
		coroutine.yield()
	end

	return function()
		local v16 = table.remove(threads, 1)

		if v16 == nil then
			updateQueue[p] = nil
		else
			coroutine.resume(v16)
		end
	end
end

local function SessionToken(name, p, p2) -- 4 equivalent calls inferred from this helper
	return (p2 == true and "U_" or v13 ~= "Access" and "M_" or "L_") .. name .. "\0" .. p
end

local function DeepCopyTable(items)
	local result = {}

	for k, item in pairs(items) do
		if type(item) == "table" then
			result[k] = DeepCopyTable(item)
		else
			result[k] = item
		end
	end

	return result
end

local function ReconcileTable(data, template)
	for k, item in pairs(template) do
		if type(k) ~= "string" then
			continue
		end

		if data[k] == nil then
			if type(item) == "table" then
				data[k] = DeepCopyTable(item)
			else
				data[k] = item
			end
		elseif type(data[k]) == "table" and type(item) == "table" then
			ReconcileTable(data[k], item)
		end
	end
end

local function RegisterError(p, name, p2) -- 1 equivalent call inferred from this helper
	warn(`[{script.Name}]: DataStore API error (STORE:{name}; KEY:{p2}) - {tostring(p)}`)
	table.insert(nows, os.clock())
	onError:Fire(tostring(p), name, p2)
end

local function RegisterOverwrite(name, p) -- 1 equivalent call inferred from this helper
	warn(`[{script.Name}]: Invalid profile was overwritten (STORE:{name}; KEY:{p})`)
	onOverwrite:Fire(name, p)
end

local function NewMockDataStoreKeyInfo(data)
	local versionId = tostring(data.VersionId or 0)
	local metaData = data.MetaData or {}
	local userIds = data.UserIds or {}

	return {
		CreatedTime = data.CreatedTime,
		UpdatedTime = data.UpdatedTime,
		Version = string.rep("0", 16) .. "." .. string.rep("0", 10 - string.len(versionId)) .. versionId .. "." .. string.rep("0", 16) .. ".01",
		GetMetadata = function()
			return (DeepCopyTable(metaData))
		end,
		GetUserIds = function()
			return (DeepCopyTable(userIds))
		end
	}
end

local function MockUpdateAsync(p, name, p2, fn, p3)
	local v15 = p[name]

	if v15 == nil then
		v15 = {}
		p[name] = v15
	end

	local v16 = math.floor(os.time() * 1000)
	local v17 = v15[p2]
	local v18

	if v17 == nil then
		v18 = true

		if p3 ~= true then
			v17 = {
				Data = nil,
				CreatedTime = v16,
				UpdatedTime = v16,
				VersionId = 0,
				UserIds = {},
				MetaData = {}
			}

			v15[p2] = v17
		end
	else
		v18 = false
	end

	local v19

	if v18 == false then
		v19 = NewMockDataStoreKeyInfo(v17) or nil
	end

	local v20, v21, v22 = fn(v17 and v17.Data, v19)

	if v20 == nil then
		return nil
	end

	if v17 ~= nil and p3 ~= true then
		v17.Data = DeepCopyTable(v20)
		v17.UserIds = DeepCopyTable(v21 or {})
		v17.MetaData = DeepCopyTable(v22 or {})
		v17.VersionId += 1
		v17.UpdatedTime = v16
	end

	local deepCopyTable = DeepCopyTable(v20)
	local v23

	if v17 ~= nil then
		v23 = NewMockDataStoreKeyInfo(v17) or nil
	end

	return deepCopyTable, v23
end

local function UpdateAsync(p, p2, data, p3, p4, p5)
	local v15 = nil
	local v16 = nil

	local waitInUpdateQueue = WaitInUpdateQueue(SessionToken(p.Name, p2, p3)) -- inferred equivalent call

	local success, result = pcall(function()
		local function fn(state)
			local v17 = false
			local v18 = false
			local globalUpdates = { 0, {} }

			if state == nil then
				v17 = true
			elseif type(state) == "table" then
				if
					type(state.Data) == "table"
					and type(state.MetaData) == "table"
					and type(state.GlobalUpdates) == "table"
				then
					state.WasOverwritten = false
					globalUpdates = state.GlobalUpdates

					if data.ExistingProfileHandle ~= nil then
						data.ExistingProfileHandle(state)
					end
				elseif state.Data == nil and state.MetaData == nil and type(state.GlobalUpdates) == "table" then
					state.WasOverwritten = false
					globalUpdates = state.GlobalUpdates or globalUpdates
					v17 = true
				else
					v17 = true
					v18 = true
				end
			else
				v17 = true
				v18 = true
			end

			if v17 == true then
				state = { GlobalUpdates = globalUpdates }

				if data.MissingProfileHandle ~= nil then
					data.MissingProfileHandle(state)
				end
			end

			if data.EditProfile ~= nil then
				data.EditProfile(state)
			end

			if v18 == true then
				state.WasOverwritten = true
			end

			return state, state.UserIds, state.RobloxMetaData
		end

		if p3 == true then
			v15, v16 = MockUpdateAsync(userMockStore, p.Name, p2, fn, p4)
			task.wait()
		elseif v13 == "Access" then
			if p4 == true then
				if p5 == nil then
					v15, v16 = p.data_store:GetAsync(p2)
				else
					local success, result = pcall(function()
						v15, v16 = p.data_store:GetVersionAsync(p2, p5)
					end)

					if success == false and type(result) == "string" and string.find(result, "not valid") ~= nil then
						warn(`[{script.Name}]: Passed version argument is not valid; Traceback:\n` .. debug.traceback())
					end
				end

				v15 = fn(v15)
			else
				v15, v16 = p.data_store:UpdateAsync(p2, fn)
			end
		else
			v15, v16 = MockUpdateAsync(mockStore, p.Name, p2, fn, p4)
			task.wait()
		end
	end)

	waitInUpdateQueue()

	if success == true and type(v15) == "table" then
		if v15.WasOverwritten == true and p4 ~= true then
			RegisterOverwrite(p.Name, p2) -- inferred equivalent call
		end

		return v15, v16
	end

	RegisterError(result or "Undefined error", p.Name, p2) -- inferred equivalent call

	return nil
end

local function IsThisSession(list): boolean -- 8 equivalent calls inferred from this helper
	return list[1] == PlaceId and list[2] == JobId
end

local function ReadMockFlag() -- 5 equivalent calls inferred from this helper
	local mockFlag = v14
	v14 = false
	return mockFlag
end

local function WaitForStoreReady(p) -- 5 equivalent calls inferred from this helper
	while p.is_ready == false do
		task.wait()
	end
end

local function AddProfileToAutoSave(p) -- 2 equivalent calls inferred from this helper
	activeSessionCheck[p.session_token] = p

	table.insert(autoSaveList, v12, p)

	if #autoSaveList > 1 then
		v12 += 1
	elseif #autoSaveList == 1 then
		now = os.clock()
	end
end

local function RemoveProfileFromAutoSave(object) -- 3 equivalent calls inferred from this helper
	activeSessionCheck[object.session_token] = nil

	local index = table.find(autoSaveList, object)

	if index ~= nil then
		table.remove(autoSaveList, index)

		if index < v12 then
			v12 -= 1
		end

		if autoSaveList[v12] == nil then
			v12 = 1
		end
	end
end

local function SaveProfileAsync(object, p, p2, value)
	if type(object.Data) ~= "table" then
		error(`[{script.Name}]: Developer code likely set "Profile.Data" to a non-table value! (STORE:{object.ProfileStore.Name}; KEY:{object.Key})`)
	end

	object.OnSave:Fire()

	if p == true then
		object.OnLastSave:Fire(value or "Manual")
	end

	if p == true and p2 ~= true then
		if object.roblox_message_subscription ~= nil then
			object.roblox_message_subscription:Disconnect()
		end

		RemoveProfileFromAutoSave(object) -- inferred equivalent call
		object.OnSessionEnd:Fire()
	end

	activeProfileSaveJobs += 1
	local v15 = true
	local v16 = 1

	while v15 == true do
		if p ~= true then
			v15 = false
		end

		local v17, keyInfo = UpdateAsync(object.ProfileStore, object.Key, {
			ExistingProfileHandle = nil,
			MissingProfileHandle = nil,
			EditProfile = function(state)
				local v17 = false

				if p2 == true then
					v17 = true
				else
					local activeSession = state.MetaData.ActiveSession
					local sessionLoadCount = state.MetaData.SessionLoadCount

					if type(activeSession) == "table" then
						v17 = IsThisSession(activeSession) and sessionLoadCount == object.load_index -- inferred equivalent call
					end
				end

				if v17 == true then
					local locked_global_updates = object.locked_global_updates
					local globalUpdate = state.GlobalUpdates[2]

					if next(locked_global_updates) ~= nil then
						local v18 = 1

						while v18 <= #globalUpdate do
							if locked_global_updates[globalUpdate[v18][1]] == true then
								table.remove(globalUpdate, v18)
							else
								v18 += 1
							end
						end
					end

					state.Data = object.Data
					state.RobloxMetaData = object.RobloxMetaData
					state.UserIds = object.UserIds

					if p2 == true then
						state.MetaData.ActiveSession = nil
						state.MetaData.ForceLoadSession = nil
					else
						state.MetaData.LastUpdate = os.time()

						if p == true then
							state.MetaData.ActiveSession = nil
						end
					end
				end
			end
		}, object.is_mock)

		if v17 == nil or keyInfo == nil then
			if v15 == true then
				task.wait(v16)
				v16 = math.min(value == "Shutdown" and 8 or 20, v16 * 2)
			end
		else
			if p2 == true then
				break
			end

			v15 = false

			local activeSession = v17.MetaData.ActiveSession
			local sessionLoadCount = v17.MetaData.SessionLoadCount
			local v18

			if type(activeSession) == "table" then
				v18 = IsThisSession(activeSession) and sessionLoadCount == object.load_index -- inferred equivalent call
			else
				v18 = false
			end

			local forceLoadSession = v17.MetaData.ForceLoadSession
			local v19

			if type(forceLoadSession) == "table" then
				v19 = not IsThisSession(forceLoadSession) -- inferred equivalent call
			else
				v19 = false
			end

			local isActive = object:IsActive()

			if v19 == true and v18 == true then
				if isActive ~= true then
					break
				end

				SaveProfileAsync(object, true, false, "External")
				break
			else
				local locked_global_updates = object.locked_global_updates
				local received_global_updates = object.received_global_updates
				local globalUpdate = v17.GlobalUpdates[2]

				local v20 = {}
				local set = {}

				for _, v21 in ipairs(globalUpdate) do
					if locked_global_updates[v21[1]] == true then
						set[v21[1]] = true
					elseif received_global_updates[v21[1]] ~= true then
						received_global_updates[v21[1]] = true
						table.insert(v20, v21)
					end
				end

				for k in pairs(locked_global_updates) do
					if set[k] ~= true then
						locked_global_updates[k] = nil
					end
				end

				object.KeyInfo = keyInfo
				object.LastSavedData = v17.Data
				object.global_updates = v17.GlobalUpdates and v17.GlobalUpdates[2] or {}

				if v18 == true then
					if isActive == true and p ~= true then
						for _, v21 in ipairs(v20) do
							local v22 = v21[1]
							local v23 = v21[#v21]

							for _, callback in ipairs(object.message_handlers) do
								local v24 = false
								local function fn()
									v24 = true
									locked_global_updates[v22] = true
								end

								local deepCopyTable = DeepCopyTable(v23)

								task.spawn(callback, deepCopyTable, fn)

								if v24 == true then
									break
								end
							end
						end
					end
				else
					if object.roblox_message_subscription ~= nil then
						object.roblox_message_subscription:Disconnect()
					end

					if isActive == true then
						RemoveProfileFromAutoSave(object) -- inferred equivalent call
						object.OnSessionEnd:Fire()
					end
				end

				object.OnAfterSave:Fire(object.LastSavedData)
			end
		end
	end

	activeProfileSaveJobs -= 1
end

local class3 = {}
class3.__index = class3

function class3.New(data, keyInfo, profileStore, p, is_mock, value)
	local data2 = data.Data or {}
	local activeSession

	if data.MetaData then
		activeSession = data.MetaData.ActiveSession or nil
	end

	local global_updates = data.GlobalUpdates and data.GlobalUpdates[2] or {}
	local set = {}

	for _, v15 in ipairs(global_updates) do
		set[v15[1]] = true
	end

	local v15 = {
		Data = data2,
		LastSavedData = DeepCopyTable(data2),
		FirstSessionTime = data.MetaData and data.MetaData.ProfileCreateTime or 0,
		SessionLoadCount = data.MetaData and data.MetaData.SessionLoadCount or 0,
		Session = activeSession and { PlaceId = activeSession[1], JobId = activeSession[2] },
		RobloxMetaData = data.RobloxMetaData or {},
		UserIds = data.UserIds or {},
		KeyInfo = keyInfo,
		OnAfterSave = frozen.New(),
		OnSave = frozen.New(),
		OnLastSave = frozen.New(),
		OnSessionEnd = frozen.New(),
		ProfileStore = profileStore,
		Key = p,
		load_timestamp = os.clock(),
		is_mock = is_mock,
		session_token = value or "",
		load_index = data.MetaData and data.MetaData.SessionLoadCount or 0,
		locked_global_updates = {},
		received_global_updates = set,
		message_handlers = {},
		global_updates = global_updates
	}

	setmetatable(v15, class3)

	return v15
end

function class3:IsActive(): boolean
	return activeSessionCheck[self.session_token] == self
end

function class3.Reconcile(p)
	ReconcileTable(p.Data, p.ProfileStore.template)
end

function class3:EndSession()
	if self:IsActive() == true then
		task.spawn(SaveProfileAsync, self, true, nil, "Manual")
	end
end

function class3.AddUserId(p, value)
	if type(value) ~= "number" or value % 1 ~= 0 then
		warn(`[{script.Name}]: Invalid UserId argument for :AddUserId() ({tostring(value)}); Traceback:\n` .. debug.traceback())
		return
	end

	if value < 0 and p.is_mock ~= true and v13 == "Access" then
		return
	end

	if table.find(p.UserIds, value) == nil then
		table.insert(p.UserIds, value)
	end
end

function class3.RemoveUserId(p, value)
	if type(value) ~= "number" or value % 1 ~= 0 then
		warn(`[{script.Name}]: Invalid UserId argument for :RemoveUserId() ({tostring(value)}); Traceback:\n` .. debug.traceback())
		return
	end

	local index = table.find(p.UserIds, value)

	if index ~= nil then
		table.remove(p.UserIds, index)
	end
end

function class3:SetAsync()
	if self.view_mode ~= true then
		error(`[{script.Name}]: :SetAsync() can only be used in view mode`)
	end

	SaveProfileAsync(self, nil, true)
end

function class3:MessageHandler(callback)
	if type(callback) ~= "function" then
		error(`[{script.Name}]: fn argument is not a function`)
	end

	if self.view_mode ~= true and self:IsActive() ~= true then
		return
	end

	local locked_global_updates = self.locked_global_updates
	table.insert(self.message_handlers, callback)

	for _, global_update in ipairs(self.global_updates) do
		local v15 = global_update[1]
		local v16 = global_update[#global_update]

		if locked_global_updates[v15] == true then
			continue
		end

		local deepCopyTable = DeepCopyTable(v16)
		task.spawn(callback, deepCopyTable, function()
			locked_global_updates[v15] = true
		end)
	end
end

function class3:Save()
	if self.view_mode == true then
		error(`[{script.Name}]: Can't save profile in view mode; Should you be calling :SetAsync() instead?`)
	end

	if self:IsActive() == false then
		warn(`[{script.Name}]: Attempted saving an inactive profile (STORE:{self.ProfileStore.Name}; KEY:{self.Key});` .. " Traceback:\n" .. debug.traceback())
		return
	end

	RemoveProfileFromAutoSave(self) -- inferred equivalent call
	AddProfileToAutoSave(self) -- inferred equivalent call
	task.spawn(SaveProfileAsync, self)
end

local ProfileStore = {
	IsClosing = false,
	IsCriticalState = false,
	OnError = onError,
	OnOverwrite = onOverwrite,
	OnCriticalToggle = frozen.New(),
	DataStoreState = "NotReady"
}

ProfileStore.__index = ProfileStore

function ProfileStore.SetConstant(p, value)
	if type(value) ~= "number" then
		error(`[{script.Name}]: Invalid value type`)
	end

	if p == "AUTO_SAVE_PERIOD" then
		v = value
	elseif p == "LOAD_REPEAT_PERIOD" then
		v2 = value
	elseif p == "FIRST_LOAD_REPEAT" then
		v3 = value
	elseif p == "SESSION_STEAL" then
		v4 = value
	elseif p == "ASSUME_DEAD" then
		v5 = value
	elseif p == "START_SESSION_TIMEOUT" then
		v6 = value
	elseif p == "CRITICAL_STATE_ERROR_COUNT" then
		v7 = value
	elseif p == "CRITICAL_STATE_ERROR_EXPIRE" then
		v8 = value
	elseif p == "CRITICAL_STATE_EXPIRE" then
		v9 = value
	elseif p == "MAX_MESSAGE_QUEUE" then
		v10 = value
	else
		error(`[{script.Name}]: Invalid constant name was provided`)
	end
end

function ProfileStore.Test()
	return {
		ActiveSessionCheck = activeSessionCheck,
		AutoSaveList = autoSaveList,
		ActiveProfileLoadJobs = activeProfileLoadJobs,
		ActiveProfileSaveJobs = activeProfileSaveJobs,
		MockStore = mockStore,
		UserMockStore = userMockStore,
		UpdateQueue = updateQueue
	}
end

function ProfileStore.New(name, template)
	template = template or {}

	if type(name) == "string" then
		if string.len(name) == 0 then
			error(`[{script.Name}]: store_name cannot be an empty string`)
		elseif string.len(name) > 50 then
			error(`[{script.Name}]: store_name is too long`)
		end
	else
		error(`[{script.Name}]: Invalid or missing "store_name"`)
	end

	if type(template) ~= "table" then
		error(`[{script.Name}]: Invalid template argument`)
	end

	local v15 = nil
	v15 = {
		Mock = {
			Name = name,
			StartSessionAsync = function(self, p)
				v14 = true
				return v15:StartSessionAsync(p)
			end,
			MessageAsync = function(self, p, p2)
				v14 = true
				return v15:MessageAsync(p, p2)
			end,
			GetAsync = function(self, p, p2)
				v14 = true
				return v15:GetAsync(p, p2)
			end,
			VersionQuery = function(self, p, p2, p3, p4)
				v14 = true
				return v15:VersionQuery(p, p2, p3, p4)
			end,
			RemoveAsync = function(self, p)
				v14 = true
				return v15:RemoveAsync(p)
			end
		},
		Name = name,
		template = template,
		data_store = nil,
		load_jobs = {},
		mock_load_jobs = {},
		is_ready = true
	}

	setmetatable(v15, ProfileStore)

	local dataStoreOptions = Instance.new("DataStoreOptions")
	dataStoreOptions:SetExperimentalFeatures({ v2 = true })

	if v13 == "NotReady" then
		v15.is_ready = false

		task.spawn(function()
			repeat
				task.wait()
			until v13 ~= "NotReady"

			if v13 == "Access" then
				v15.data_store = DataStoreService:GetDataStore(name, nil, dataStoreOptions)
			end

			v15.is_ready = true
		end)
	elseif v13 == "Access" then
		v15.data_store = DataStoreService:GetDataStore(name, nil, dataStoreOptions)
	end

	return v15
end

local function RobloxMessageSubscription(object, p)
	local lastTime2 = 0

	local connection = MessagingService:SubscribeAsync("PS_" .. p, function(p2)
		if type(p2.Data) == "table" and p2.Data.LoadCount == object.SessionLoadCount and os.clock() - lastTime2 > 6 then
			lastTime2 = os.clock()

			if object:IsActive() == true then
				if p2.Data.EndSession == true then
					SaveProfileAsync(object, true, false, "External")
				else
					object:Save()
				end
			end
		end
	end)

	if object:IsActive() == true then
		object.roblox_message_subscription = connection
	else
		connection:Disconnect()
	end
end

function ProfileStore:StartSessionAsync(value, options)
	local readMockFlag = ReadMockFlag() -- inferred equivalent call

	if type(value) == "string" then
		if string.len(value) == 0 then
			error(`[{script.Name}]: Invalid profile_key`)
		elseif string.len(value) > 50 then
			error(`[{script.Name}]: profile_key is too long`)
		end
	else
		error(`[{script.Name}]: profile_key must be a string`)
	end

	if options ~= nil and type(options) ~= "table" then
		error(`[{script.Name}]: Invalid params`)
	end

	if ProfileStore.IsClosing == true then
		return nil
	end

	local v15 = options or {}
	WaitForStoreReady(self) -- inferred equivalent call
	local sessionToken = SessionToken(self.Name, value, readMockFlag) -- inferred equivalent call

	if activeSessionCheck[sessionToken] ~= nil then
		error(`[{script.Name}]: Profile (STORE:{self.Name}; KEY:{value}) is already loaded in this session`)
	end

	activeProfileLoadJobs += 1

	local v16 = false

	local function cancel_condition() -- 7 equivalent calls inferred from this helper
		if v16 ~= false then
			return true
		end

		if v15.Cancel ~= nil then
			v16 = v15.Cancel() == true
		end

		return v16
	end

	local steal = v15.Steal == true

	local lastTime2 = os.clock()
	local v17 = false
	local v18 = true
	local v19 = 1
	local count2 = 0

	while ProfileStore.IsClosing == false do
		if cancel_condition() ~= false then -- inferred equivalent call
			break
		end

		count += 1
		local v20 = count
		local mock_load_jobs = readMockFlag == true and self.mock_load_jobs or self.load_jobs
		local mock_load_job = mock_load_jobs[value]

		local guid = HttpService:GenerateGUID(false)
		local v21, v22

		if mock_load_job == nil then
			local v23 = { v20, nil }
			mock_load_jobs[value] = v23

			v23[2] = table.pack(UpdateAsync(self, value, {
				ExistingProfileHandle = function(p)
					if ProfileStore.IsClosing ~= true and cancel_condition() ~= true then -- inferred equivalent call
						local activeSession = p.MetaData.ActiveSession
						local forceLoadSession = p.MetaData.ForceLoadSession

						if activeSession == nil then
							p.MetaData.ActiveSession = { PlaceId, JobId, guid }
							p.MetaData.ForceLoadSession = nil
						elseif type(activeSession) == "table" then
							if IsThisSession(activeSession) == false then -- inferred equivalent call
								local lastUpdate = p.MetaData.LastUpdate

								if lastUpdate ~= nil then
									local v24 = os.time() - lastUpdate

									if v5 < v24 then
										p.MetaData.ActiveSession = { PlaceId, JobId, guid }
										p.MetaData.ForceLoadSession = nil
										return
									end
								end

								if v17 == true or steal == true then
									local v24

									if forceLoadSession == nil then
										v24 = true
									else
										v24 = not IsThisSession(forceLoadSession) -- inferred equivalent call
									end

									if v24 == false or steal == true then
										p.MetaData.ActiveSession = { PlaceId, JobId, guid }
										p.MetaData.ForceLoadSession = nil
									end
								elseif v18 == true then
									p.MetaData.ForceLoadSession = { PlaceId, JobId }
								end
							else
								p.MetaData.ForceLoadSession = nil
							end
						end
					end
				end,
				MissingProfileHandle = function(p)
					local v24

					if ProfileStore.IsClosing == true then
						v24 = true
					else
						v24 = cancel_condition() == true -- inferred equivalent call
					end

					p.Data = DeepCopyTable(self.template)
					p.MetaData = {
						ProfileCreateTime = os.time(),
						SessionLoadCount = 0,
						ActiveSession = v24 == false and { PlaceId, JobId, guid } or nil,
						ForceLoadSession = nil,
						MetaTags = {}
					}
				end,
				EditProfile = function(p)
					if ProfileStore.IsClosing ~= true and cancel_condition() ~= true then -- inferred equivalent call
						local activeSession = p.MetaData.ActiveSession

						if activeSession ~= nil and IsThisSession(activeSession) == true then -- inferred equivalent call
							p.MetaData.SessionLoadCount = p.MetaData.SessionLoadCount + 1
							p.MetaData.LastUpdate = os.time()
						end
					end
				end
			}, readMockFlag))

			if v23[1] == v20 then
				v21, v22 = table.unpack(v23[2])
				mock_load_jobs[value] = nil
			else
				activeProfileLoadJobs -= 1
				return nil
			end
		else
			mock_load_job[1] = v20

			while mock_load_job[2] == nil do
				task.wait()
			end

			if mock_load_job[1] == v20 then
				v21, v22 = table.unpack(mock_load_job[2])
				mock_load_jobs[value] = nil
			else
				activeProfileLoadJobs -= 1
				return nil
			end
		end

		if v21 == nil or v22 == nil then
			local v23

			if v15.Cancel == nil then
				local v24 = os.clock() - lastTime2
				v23 = v6 <= v24
			else
				v23 = false
			end

			if v23 ~= true and ProfileStore.IsClosing ~= true and cancel_condition() ~= true then -- inferred equivalent call
				task.wait(v19)
				v19 = math.min(20, v19 * 2)
				continue
			end

			activeProfileLoadJobs -= 1
			return nil
		else
			local activeSession = v21.MetaData.ActiveSession

			if type(activeSession) ~= "table" then
				activeProfileLoadJobs -= 1
				return nil
			end

			if IsThisSession(activeSession) == true then -- inferred equivalent call
				local v23 = class3.New(v21, v22, self, value, readMockFlag, sessionToken)
				AddProfileToAutoSave(v23) -- inferred equivalent call

				if readMockFlag ~= true and v13 == "Access" then
					task.spawn(RobloxMessageSubscription, v23, guid)
				end

				if ProfileStore.IsClosing == true then
					SaveProfileAsync(v23, true)
					v23 = nil
				elseif cancel_condition() == true then -- inferred equivalent call
					SaveProfileAsync(v23, true)
					v23 = nil
				end

				activeProfileLoadJobs -= 1
				return v23
			end

			if ProfileStore.IsClosing ~= true and cancel_condition() ~= true then -- inferred equivalent call
				local forceLoadSession = v21.MetaData.ForceLoadSession
				local v23

				if forceLoadSession == nil then
					v23 = true
				else
					v23 = not IsThisSession(forceLoadSession) -- inferred equivalent call
				end

				if v23 ~= false then
					activeProfileLoadJobs -= 1
					return nil
				end

				if v18 == false then
					count2 += 1

					if math.ceil(v4 / v2) <= count2 then
						v17 = true
					end
				end

				if type(activeSession[3]) == "string" then
					local sessionLoadCount = v21.MetaData.SessionLoadCount or 0
					task.spawn(MessagingService.PublishAsync, MessagingService, "PS_" .. activeSession[3], {
						LoadCount = sessionLoadCount,
						EndSession = true
					})
				end

				local now2 = os.clock()
				local v24 = if v18 == true then v3 else v2
				local v25 = now2 + v24

				repeat
					task.wait()
				until v25 <= os.clock() or ProfileStore.IsClosing == true

				v18 = false
				continue
			end

			activeProfileLoadJobs -= 1
			return nil
		end
	end

	activeProfileLoadJobs -= 1
	return nil
end

function ProfileStore:MessageAsync(value, p): boolean
	local readMockFlag = ReadMockFlag() -- inferred equivalent call

	if type(value) == "string" then
		if string.len(value) == 0 then
			error(`[{script.Name}]: Invalid profile_key`)
		elseif string.len(value) > 50 then
			error(`[{script.Name}]: profile_key is too long`)
		end
	else
		error(`[{script.Name}]: profile_key must be a string`)
	end

	if type(p) ~= "table" then
		error(`[{script.Name}]: message must be a table`)
	end

	if ProfileStore.IsClosing == true then
		return false
	end

	WaitForStoreReady(self) -- inferred equivalent call
	local v15 = 1

	while ProfileStore.IsClosing == false do
		local updateAsync = UpdateAsync(self, value, {
			ExistingProfileHandle = nil,
			MissingProfileHandle = nil,
			EditProfile = function(p2)
				local globalUpdates = p2.GlobalUpdates
				local globalUpdate = globalUpdates[2]

				globalUpdates[1] += 1
				table.insert(globalUpdate, { globalUpdates[1], p })

				while true do
					local v16 = #globalUpdate

					if not (v10 < v16) then
						break
					end

					table.remove(globalUpdate, 1)
				end
			end
		}, readMockFlag)

		if updateAsync == nil then
			task.wait(v15)
			v15 = math.min(20, v15 * 2)
		else
			local v16 = activeSessionCheck[SessionToken(self.Name, value, readMockFlag)] -- inferred equivalent call

			if v16 == nil then
				local metaData = updateAsync.MetaData or {}
				local activeSession = metaData.ActiveSession
				local sessionLoadCount = metaData.SessionLoadCount or 0

				if type(activeSession) == "table" and type(activeSession[3]) == "string" then
					task.spawn(MessagingService.PublishAsync, MessagingService, "PS_" .. activeSession[3], {
						LoadCount = sessionLoadCount
					})
				end
			else
				v16:Save()
			end

			return true
		end
	end

	return false
end

function ProfileStore:GetAsync(value, p)
	local readMockFlag = ReadMockFlag() -- inferred equivalent call

	if type(value) == "string" then
		if string.len(value) == 0 then
			error(`[{script.Name}]: Invalid profile_key`)
		elseif string.len(value) > 50 then
			error(`[{script.Name}]: profile_key is too long`)
		end
	else
		error(`[{script.Name}]: profile_key must be a string`)
	end

	if ProfileStore.IsClosing == true then
		return nil
	end

	WaitForStoreReady(self) -- inferred equivalent call

	if p ~= nil and (readMockFlag or v13 ~= "Access") then
		return nil
	end

	local v15 = 1

	while ProfileStore.IsClosing == false do
		local v16, v17 = UpdateAsync(self, value, {
			ExistingProfileHandle = nil,
			MissingProfileHandle = function(p2)
				p2.Data = DeepCopyTable(self.template)
				p2.MetaData = {
					ProfileCreateTime = os.time(),
					SessionLoadCount = 0,
					ActiveSession = nil,
					ForceLoadSession = nil,
					MetaTags = {}
				}
			end,
			EditProfile = nil
		}, readMockFlag, true, p)

		if v16 == nil then
			task.wait(v15)
			v15 = math.min(20, v15 * 2)
		else
			if v17 == nil then
				return nil
			end

			local result = class3.New(v16, v17, self, value, readMockFlag)
			result.view_mode = true

			return result
		end
	end

	return nil
end

function ProfileStore:RemoveAsync(value)
	local readMockFlag = ReadMockFlag() -- inferred equivalent call

	if type(value) ~= "string" or string.len(value) == 0 then
		error(`[{script.Name}]: Invalid profile_key`)
	end

	if ProfileStore.IsClosing == true then
		return false
	end

	WaitForStoreReady(self) -- inferred equivalent call
	local waitInUpdateQueue = WaitInUpdateQueue(SessionToken(self.Name, value, readMockFlag)) -- inferred equivalent call
	local v15

	if readMockFlag == true then
		local v16 = userMockStore[self.Name]

		if v16 ~= nil then
			v16[value] = nil

			if next(v16) == nil then
				userMockStore[self.Name] = nil
			end
		end

		task.wait()
		v15 = true
	elseif v13 == "Access" then
		v15 = pcall(function()
			self.data_store:RemoveAsync(value)
		end)
	else
		local v16 = mockStore[self.Name]

		if v16 ~= nil then
			v16[value] = nil

			if next(v16) == nil then
				mockStore[self.Name] = nil
			end
		end

		task.wait()
		v15 = true
	end

	waitInUpdateQueue()

	return v15
end

local class4 = {}
class4.__index = class4

function class4.New(profile_store, profile_key, sort_direction, min_date, max_date, is_mock)
	local v15 = {
		profile_store = profile_store,
		profile_key = profile_key,
		sort_direction = sort_direction,
		min_date = min_date,
		max_date = max_date,
		query_pages = nil,
		query_index = 0,
		query_failure = false,
		is_query_yielded = false,
		query_queue = {},
		is_mock = is_mock
	}

	setmetatable(v15, class4)

	return v15
end

function MoveVersionQueryQueue(p)
	while #p.query_queue > 0 do
		local v15 = table.remove(p.query_queue, 1)

		task.spawn(v15)

		if p.is_query_yielded == true then
			break
		end
	end
end

local v15 = false
local v16 = false

function class4:NextAsync()
	local v17 = v15 == true
	v15 = false

	WaitForStoreReady(self.profile_store) -- inferred equivalent call

	if ProfileStore.IsClosing == true then
		return nil
	end

	if self.is_mock == true or v13 ~= "Access" then
		if isStudio == true and v16 == false then
			v16 = true
			warn(`[{script.Name}]: :VersionQuery() is not supported in mock mode!`)
		end

		return nil
	else
		local v18 = nil
		local v19 = false

		local function query_job()
			if self.query_failure == true then
				v19 = true
			elseif self.query_pages == nil then
				self.is_query_yielded = true

				task.spawn(function()
					v15 = true
					v18 = self:NextAsync()
					v19 = true
				end)

				local success, result = pcall(function()
					self.query_pages = self.profile_store.data_store:ListVersionsAsync(
						self.profile_key,
						self.sort_direction,
						self.min_date,
						self.max_date
					)

					self.query_index = 0
				end)

				if success == false or self.query_pages == nil then
					warn(`[{script.Name}]: Version query fail - {tostring(result)}`)
					self.query_failure = true
				end

				self.is_query_yielded = false

				MoveVersionQueryQueue(self)
			else
				local v20 = self.query_pages:GetCurrentPage()[self.query_index + 1]

				if self.query_pages.IsFinished == true and v20 == nil then
					v19 = true
				elseif v20 == nil then
					self.is_query_yielded = true
					task.spawn(function()
						v15 = true
						v18 = self:NextAsync()
						v19 = true
					end)

					local success, _ = pcall(function()
						self.query_pages:AdvanceToNextPageAsync()
						self.query_index = 0
					end)

					if success == false or #self.query_pages:GetCurrentPage() == 0 then
						self.query_failure = true
					end

					self.is_query_yielded = false
					MoveVersionQueryQueue(self)
				else
					self.query_index += 1
					v18 = self.profile_store:GetAsync(self.profile_key, v20.Version)
					v19 = true
				end
			end
		end

		if self.is_query_yielded == false then
			query_job()
		elseif v17 == true then
			table.insert(self.query_queue, 1, query_job)
		else
			table.insert(self.query_queue, query_job)
		end

		while v19 == false do
			task.wait()
		end

		return v18
	end
end

function ProfileStore:VersionQuery(value, p, value2, value3)
	local readMockFlag = ReadMockFlag() -- inferred equivalent call

	if type(value) ~= "string" or string.len(value) == 0 then
		error(`[{script.Name}]: Invalid profile_key`)
	end

	if p ~= nil and (typeof(p) ~= "EnumItem" or p.EnumType ~= Enum.SortDirection) then
		error(`[{script.Name}]: Invalid sort_direction ({tostring(p)})`)
	end

	if value2 ~= nil and typeof(value2) ~= "DateTime" and typeof(value2) ~= "number" then
		error(`[{script.Name}]: Invalid min_date ({tostring(value2)})`)
	end

	if value3 ~= nil and typeof(value3) ~= "DateTime" and typeof(value3) ~= "number" then
		error(`[{script.Name}]: Invalid max_date ({tostring(value3)})`)
	end

	value2 = typeof(value2) == "DateTime" and value2.UnixTimestampMillis or value2
	value3 = typeof(value3) == "DateTime" and value3.UnixTimestampMillis or value3

	return class4.New(self, value, p, value2, value3, readMockFlag)
end

if isStudio == true then
	task.spawn(function()
		local success, result = pcall(function()
			DataStoreService:GetDataStore("____PS"):SetAsync("____PS", os.time())
		end)
		local v17

		if success == false then
			v17 = string.find(result, "ConnectFail", 1, true) ~= nil
		else
			v17 = false
		end

		if v17 == true then
			warn(`[{script.Name}]: No internet access - check your network connection`)
		end

		local dataStoreState

		if
			success == false
			and (string.find(result, "403", 1, true) ~= nil or string.find(result, "must publish", 1, true) ~= nil or v17 == true)
		then
			dataStoreState = v17 == true and "NoInternet" or "NoAccess"
			print(`[{script.Name}]: Roblox API services unavailable - data will not be saved`)
		else
			print(`[{script.Name}]: Roblox API services available - data will be saved`)
			dataStoreState = "Access"
		end

		v13 = dataStoreState
		ProfileStore.DataStoreState = dataStoreState
	end)
else
	v13 = "Access"
	ProfileStore.DataStoreState = "Access"
end

RunService.Heartbeat:Connect(function()
	local count2 = #autoSaveList

	if count2 > 0 then
		local v17 = v / count2
		local now2 = os.clock()

		while v17 < now2 - now do
			now += v17
			local v18 = autoSaveList[v12]

			if now2 - v18.load_timestamp < v / 2 then
				v18 = nil

				for _ = 1, count2 - 1 do
					v12 += 1

					if count2 < v12 then
						v12 = 1
					end

					v18 = autoSaveList[v12]
					local v19 = now2 - v18.load_timestamp

					if v / 2 <= v19 then
						break
					end

					v18 = nil
				end
			end

			v12 += 1

			if count2 < v12 then
				v12 = 1
			end

			if v18 ~= nil then
				task.spawn(SaveProfileAsync, v18)
			end
		end
	end

	if ProfileStore.IsCriticalState == false then
		local v17 = #nows

		if v7 <= v17 then
			ProfileStore.IsCriticalState = true
			ProfileStore.OnCriticalToggle:Fire(true)
			lastTime = os.clock()
			warn(`[{script.Name}]: Entered critical state`)
		end
	else
		local v17 = #nows

		if v7 <= v17 then
			lastTime = os.clock()
		else
			local v18 = os.clock() - lastTime

			if v9 < v18 then
				ProfileStore.IsCriticalState = false
				ProfileStore.OnCriticalToggle:Fire(false)
				warn(`[{script.Name}]: Critical state ended`)
			end
		end
	end

	while true do
		local v17 = nows[1]

		if v17 == nil then
			break
		end

		local v18 = os.clock() - v17

		if v8 < v18 then
			table.remove(nows, 1)
		else
			break
		end
	end
end)

task.spawn(function()
	while v13 == "NotReady" do
		task.wait()
	end

	if v13 == "Access" then
		game:BindToClose(function()
			ProfileStore.IsClosing = true

			local v17 = {}
			local v18 = 0

			for i, v19 in ipairs(autoSaveList) do
				v17[i] = v19
			end

			for _, v19 in ipairs(v17) do
				if v19:IsActive() ~= true then
					continue
				end

				v18 += 1
				task.spawn(function()
					SaveProfileAsync(v19, true, nil, "Shutdown")
					v18 -= 1
				end)
			end

			while v18 > 0 or activeProfileLoadJobs > 0 or activeProfileSaveJobs > 0 do
				task.wait()
			end
		end)
	else
		game:BindToClose(function()
			ProfileStore.IsClosing = true
			task.wait()
		end)
	end
end)

return ProfileStore