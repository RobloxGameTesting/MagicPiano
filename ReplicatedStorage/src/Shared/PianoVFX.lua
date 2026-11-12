local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PianoNetwork = require(ReplicatedStorage.PianoNetwork)
local module = require("../Shared/Data")
local client = module.client

local object = setmetatable({}, { __mode = "k" })

local function getPianoData(p)
	local v = object[p]

	if v then
		return v
	end

	local v2 = {
		listeners = {
			Pressed = {},
			Released = {},
			Sustained = {},
			SustainEnabled = {},
			SustainReleased = {}
		}
	}

	object[p] = v2

	local pianoNetwork = PianoNetwork(p)

	local function dispatch(p2, ...)
		for _, v3 in v2.listeners[p2] do
			v3(...)
		end
	end

	local function receive(p2, p3, p4, ...)
		local v3 = table.pack(...)
		local v4 = p3 + 1 - workspace:GetServerTimeNow()

		local function play() -- 1 equivalent call inferred from this helper
			dispatch(p2, table.unpack(v3, 1, v3.n))
		end

		if p4 >= 2147483648 then
			p4 -= 4294967296
		end

		if p4 == Players.LocalPlayer.UserId or v4 <= 0 then
			play() -- inferred equivalent call
		else
			task.delay(v4, play)
		end
	end

	pianoNetwork.VFXNotePressed.OnClientEvent:Connect(function(p2, p3, p4, p5)
		receive("Pressed", p4, p5, p2, p3)
	end)

	pianoNetwork.VFXNoteReleased.OnClientEvent:Connect(function(p2, p3, p4)
		receive("Released", p3, p4, p2)
	end)

	pianoNetwork.VFXNoteSustained.OnClientEvent:Connect(function(p2, p3, p4)
		receive("Sustained", p3, p4, p2)
	end)

	pianoNetwork.VFXSustained.OnClientEvent:Connect(function(p2, p3)
		receive("SustainEnabled", p2, p3)
	end)

	pianoNetwork.VFXSustainReleased.OnClientEvent:Connect(function(p2, p3)
		receive("SustainReleased", p2, p3)
	end)

	return v2
end

local PianoVFX = {}

function PianoVFX.OnClient(p, p2, p3)
	local listener = getPianoData(p).listeners[p2]
	assert(listener, "Unknown VFX event: " .. p2)
	table.insert(listener, p3)
end

function PianoVFX.TriggerLocal(p, p2, ...)
	if not client.settings.pianoEffectsEnabled() then
		return
	end

	local listener = getPianoData(p).listeners[p2]
	assert(listener, "Unknown VFX event: " .. p2)

	for _, v in listener do
		v(...)
	end
end

return PianoVFX