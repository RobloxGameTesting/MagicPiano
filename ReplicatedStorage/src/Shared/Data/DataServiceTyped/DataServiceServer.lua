local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if RunService:IsClient() then
	return {}
end

local parent = script.Parent
local Value = require(script.Parent.Value)
require(script.Parent.DataServiceUtils)
local Signal = require(parent.Signal)
local Networker = require(parent.Networker)
local ProfileStore

if RunService:IsServer() then
	ProfileStore = require(parent.ProfileStore)
else
	ProfileStore = nil
end

local DataServiceServer = {
	_profiles = {},
	_waitSignals = {},
	_removalFunctions = {},
	_globalCallbacks = {},
	_globalCallbackAdded = Signal.new(),
	data = {}
}

function DataServiceServer:init(options)
	assert(RunService:IsServer(), "DataServiceServer can only be used on the server.")
	assert(not self.playerStore, "DataServiceServer has already been initialized.")
	Value.shouldRecordPath = true
	self.options = options
	self.networker = Networker.server.new("DataService", self, {})
	self.playerStore = ProfileStore.New(options.profileStoreIndex or "Default", options.template)

	for _, v in Players:GetPlayers() do
		task.spawn(function()
			self:_playerAdded(v)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		self:_playerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:_playerRemoving(player)
	end)

	self.data.Service = self
	return self.data
end

local function storeCancel(instance) -- 2 equivalent calls inferred from this helper
	return {
		Cancel = function(): boolean
			return instance.Parent ~= Players
		end
	}
end

function DataServiceServer:resetData(object)
	local profileKey = self:_getProfileKey(object.UserId)
	self:_playerRemoving(object)
	self.playerStore:RemoveAsync(profileKey)
	object:Kick("Your data has been reset. Please rejoin.")
end

function DataServiceServer:_playerAdded(instance)
	local overridenUserId = self.options.overridenUserId or self.options.viewedUserId or instance.UserId
	local profileKey = self:_getProfileKey(overridenUserId)

	if self.options.resetData and not self.options.viewedUserId then
		self.playerStore:RemoveAsync(profileKey)
	end

	local v

	if self.options.useMock then
		v = self.playerStore.Mock:StartSessionAsync(profileKey, storeCancel(instance)) -- inferred equivalent call
	elseif self.options.viewedUserId or self.options.dontSave then
		v = self.playerStore:GetAsync(profileKey)
	else
		v = self.playerStore:StartSessionAsync(profileKey, storeCancel(instance)) -- inferred equivalent call
	end

	if v then
		v:AddUserId(overridenUserId)
		v:Reconcile()
		v.OnSessionEnd:Connect(function()
			self._profiles[instance] = nil
			instance:Kick("Profile session end - Please rejoin")
		end)

		if not instance:IsDescendantOf(Players) then
			instance:Kick("Profile load fail - Please rejoin")
			return
		end

		self._profiles[instance] = v
		self:_initPlayer(instance, v.Data)

		if instance:IsDescendantOf(Players) then
			v:MessageHandler(function(p, callback)
				local globalCallback = self._globalCallbacks[p.key]

				if globalCallback then
					if globalCallback(instance, p.data) ~= false then
						callback()
					end
				else
					local connection = nil
					connection = self._globalCallbackAdded:Connect(function(p2: string)
						if p2 ~= p.key then
							return
						end

						if self._globalCallbacks[p.key](instance, p.data) ~= false then
							callback()
						end

						connection:Disconnect()
					end)
				end
			end)
		else
			instance:Kick("Profile load fail - Please rejoin")
		end
	elseif instance:IsDescendantOf(Players) then
		instance:Kick("Failed to load your data. Please rejoin.")
	end
end

function DataServiceServer:sendGlobalMessage(p: string, p2, p3)
	return self.playerStore:MessageAsync(self:_getProfileKey(p2), { key = p, data = p3 })
end

function DataServiceServer:addGlobalCallback(p: string, callback)
	assert(self._globalCallbacks[p] == nil, "Global callback already exists for key: " .. p)
	self._globalCallbacks[p] = callback
	self._globalCallbackAdded:Fire(p)
end

function DataServiceServer:_getProfileKey(p)
	return self:_getDataPrefix() .. tostring(p)
end

function DataServiceServer:_getDataPrefix()
	return self.options.profileStoreDataPrefix or "PLAYER_"
end

function DataServiceServer:onPlayerInit(_, _) end

function DataServiceServer:_initPlayer(p, p2)
	self:onPlayerInit(p, p2)
	self.networker:fire(p, "load", p2)

	self.data[p] = Value.new(p2, nil, nil, function(p3: string, p4, ...)
		self.networker:fire(p, p3, p4, ...)
	end)

	local waitSignal = self._waitSignals[p]

	if waitSignal then
		waitSignal:Fire()
		waitSignal:Destroy()
		self._waitSignals[p] = nil
	end
end

function DataServiceServer:_playerRemoving(p)
	local profile = self._profiles[p]

	if not profile then
		return
	end

	for _, callback in self._removalFunctions do
		local success, result = pcall(callback, p, profile.Data)

		if not success then
			warn(result or "Error in removal function for " .. p.Name)
		end
	end

	profile:EndSession()
	self._profiles[p] = nil

	local waitSignal = self._waitSignals[p]

	if waitSignal then
		waitSignal:Destroy()
		self._waitSignals[p] = nil
	end

	self.data[p] = nil
end

function DataServiceServer:addPlayerRemovingCallback(callback)
	table.insert(self._removalFunctions, callback)
	return function()
		local index = table.find(self._removalFunctions, callback)

		if index then
			table.remove(self._removalFunctions, index)
		end
	end
end

function DataServiceServer:asyncGetProfile(p)
	return self.playerStore:GetAsync(self:_getProfileKey(p))
end

function DataServiceServer:getProfile(p)
	return self._profiles[p]
end

function DataServiceServer:waitForData(p)
	local v = self.data[p]

	if v then
		return v
	end

	local v2 = self._waitSignals[p]

	if not v2 then
		v2 = Signal.new()
		self._waitSignals[p] = v2
	end

	v2:Wait()
	return self.data[p]
end

return DataServiceServer