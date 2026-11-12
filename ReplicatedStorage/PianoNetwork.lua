local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local QuickNet = require(ReplicatedStorage.QuickNet)
local Data = QuickNet.Data

local v = {}

local isServer = RunService:IsServer()

local _ = { Play = 1 }

local _ = { ReleaseNote = 1, SustainNote = 2 }

local _ = { ReleaseSustain = 1, Sustained = 2, Abort = 3 }

local _ = { ChangeSoundFont = 1 }

local _ = {
	ReleaseNote = 1,
	SustainNote = 2,
	VFXNotePressed = 3,
	VFXNoteReleased = 4,
	VFXNoteSustained = 5
}

local _ = { PlayNote = 1 }

local _ = { VFXNotePressed = 1 }

local _ = {
	ReleaseSustain = 1,
	Sustained = 2,
	Activate = 3,
	Deactivate = 4,
	Warning = 5,
	VFXSustainReleased = 6,
	VFXSustained = 7
}

local function createFilteredEvent(object, p)
	local filteredEvent = {}

	if isServer then
		filteredEvent.OnServerEvent = {}

		function filteredEvent.OnServerEvent:Connect(callback)
			return object.OnServerEvent:Connect(function(p2, p3, ...)
				if p3 ~= p then
					return
				end

				callback(p2, ...)
			end)
		end

		function filteredEvent.OnServerEvent:ConnectAsync(callback)
			return object.OnServerEvent:ConnectAsync(function(p2, p3, ...)
				if p3 ~= p then
					return
				end

				callback(p2, ...)
			end)
		end

		function filteredEvent.OnServerEvent.Once(_, callback)
			local onServerEventConnection = nil

			onServerEventConnection = object.OnServerEvent:Connect(function(p2, p3, ...)
				if p3 ~= p then
					return
				end

				onServerEventConnection:Disconnect()
				callback(p2, ...)
			end)

			return onServerEventConnection
		end

		function filteredEvent:FireClient(player, ...)
			object:FireClient(player, p, ...)
		end

		function filteredEvent:FireClients(p2, ...)
			object:FireClients(p2, p, ...)
		end

		function filteredEvent:FireAllClients(...)
			object:FireAllClients(p, ...)
		end

		function filteredEvent:FireAllExcept(p2, ...)
			object:FireAllExcept(p2, p, ...)
		end
	else
		filteredEvent.OnClientEvent = {}

		function filteredEvent.OnClientEvent:Connect(callback)
			return object.OnClientEvent:Connect(function(p2, ...)
				if p2 ~= p then
					return
				end

				callback(...)
			end)
		end

		function filteredEvent.OnClientEvent:ConnectAsync(callback)
			return object.OnClientEvent:ConnectAsync(function(p2, ...)
				if p2 ~= p then
					return
				end

				callback(...)
			end)
		end

		function filteredEvent.OnClientEvent.Once(_, callback)
			local onClientEventConnection = nil

			onClientEventConnection = object.OnClientEvent:Connect(function(p2, ...)
				if p2 ~= p then
					return
				end

				onClientEventConnection:Disconnect()
				callback(...)
			end)

			return onClientEventConnection
		end

		function filteredEvent:FireServer(...)
			object:FireServer(p, ...)
		end
	end

	return filteredEvent
end

local function createPianoNetwork(instance)
	local v2 = v[instance]

	if v2 then
		return v2
	end

	local v3 = "Piano_" .. instance:GetFullName():gsub("%.", "_")

	local v4 = QuickNet:register(v3 .. "_ClientPlay", Data.NumberU8, Data.NumberI8, Data.NumberF32, Data.NumberF64)

	local v5 = QuickNet:register(v3 .. "_ClientNote", Data.NumberU8, Data.NumberI8, Data.NumberF64)

	local v6 = QuickNet:register(v3 .. "_ClientAction", Data.NumberU8, Data.optional(Data.NumberF64))

	local v7 = QuickNet:register(v3 .. "_ClientString", Data.NumberU8, Data.String)

	local v8 = QuickNet:register(
		v3 .. "_ServerPlay",
		Data.NumberU8,
		Data.NumberI8,
		Data.Vector3F32,
		Data.NumberF32,
		Data.NumberF32,
		Data.NumberF64
	)

	local v9 = QuickNet:register(
		v3 .. "_ServerNote",
		Data.NumberU8,
		Data.NumberI8,
		Data.optional(Data.NumberF64),
		Data.optional(Data.NumberU32)
	)

	local v10 = QuickNet:register(
		v3 .. "_ServerNoteVolume",
		Data.NumberU8,
		Data.NumberI8,
		Data.NumberF32,
		Data.NumberF64,
		Data.NumberU32
	)

	local v11 = QuickNet:register(
		v3 .. "_ServerAction",
		Data.NumberU8,
		Data.optional(Data.String),
		Data.optional(Data.NumberF64),
		Data.optional(Data.NumberU32)
	)

	local v12 = {
		Play = createFilteredEvent(v4, 1),
		ReleaseNote = createFilteredEvent(v5, 1),
		SustainNote = createFilteredEvent(v5, 2),
		ReleaseSustain = createFilteredEvent(v6, 1),
		Sustained = createFilteredEvent(v6, 2),
		Abort = createFilteredEvent(v6, 3),
		ChangeSoundFont = createFilteredEvent(v7, 1),
		ServerPlayNote = createFilteredEvent(v8, 1),
		ServerReleaseNote = createFilteredEvent(v9, 1),
		ServerSustainNote = createFilteredEvent(v9, 2),
		ServerReleaseSustain = createFilteredEvent(v11, 1),
		ServerWarning = createFilteredEvent(v11, 5),
		Activate = createFilteredEvent(v11, 3),
		Deactivate = createFilteredEvent(v11, 4),
		VFXNotePressed = createFilteredEvent(v10, 1),
		VFXNoteReleased = createFilteredEvent(v9, 4),
		VFXNoteSustained = createFilteredEvent(v9, 5),
		VFXSustainReleased = createFilteredEvent(v11, 6),
		VFXSustained = createFilteredEvent(v11, 7)
	}

	v[instance] = v12

	return v12
end

return createPianoNetwork