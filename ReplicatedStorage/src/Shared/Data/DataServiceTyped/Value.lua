local class = {}
local Value = { shouldRecordPath = false }

local function adoptChildren(callback)
	local v = callback()

	if type(v) ~= "table" then
		return
	end

	local v2 = rawget(callback, "___C")

	if not v2 then
		v2 = {}
		rawset(callback, "___C", v2)
	end

	for k, _ in v do
		if not v2[k] then
			v2[k] = Value.new(v, k, callback)
		end
	end

	for k, v3 in v2 do
		rawset(v3, "___X", v)

		if v[k] == nil and rawget(v3, "_ChangedCbs") == nil then
			v2[k] = nil
		end
	end
end

local function sendChangedSignalToChildren(callback, flag: boolean?)
	if not flag then
		local v = rawget(callback, "_ChangedCbs")

		if v then
			local v2 = callback()

			for _, callback2 in v do
				task.spawn(callback2, v2)
			end
		end
	end

	local v = rawget(callback, "___C")

	if not v then
		return
	end

	for _, v2 in v do
		sendChangedSignalToChildren(v2)
	end
end

local function createCallbackFn(p: string) -- 5 equivalent calls inferred from this helper
	return function(p2)
		return function(callback)
			local v = rawget(p2, p)

			if not v then
				v = {}
				rawset(p2, p, v)
			end

			table.insert(v, callback)
			return function()
				local v2 = rawget(p2, p)

				if not v2 then
					return
				end

				local index = table.find(v2, callback)

				if not index then
					return
				end

				table.remove(v2, index)

				if #v2 == 0 then
					rawset(p2, p, nil)
				end
			end
		end
	end
end

local callbackFn = createCallbackFn("_OnKeyRemovedCbs") -- inferred equivalent call

local function fireChangeAndReplicate(callback, p, p2: string?, flag: boolean?, ...)
	local v = flag ~= false
	local v2 = Value.shouldRecordPath and v and {} or nil

	local v3 = nil
	local v4 = nil

	local v5 = rawget(callback, "___P")

	if v5 ~= nil and p2 == "set" then
		local v6 = rawget(callback, "___K")
		local v7 = callback()

		if p == nil and v7 ~= nil then
			local v8 = rawget(v5, "_OnKeyAddedCbs")

			if v8 then
				for _, callback2 in v8 do
					task.spawn(callback2, v6, v7)
				end
			end
		elseif p ~= nil and v7 == nil then
			local v8 = rawget(v5, "_OnKeyRemovedCbs")

			if v8 then
				for _, callback2 in v8 do
					task.spawn(callback2, v6, p)
				end
			end
		end
	end

	while true do
		local v6 = rawget(callback, "___K")

		if v2 and v6 ~= nil then
			table.insert(v2, v6)
		end

		v4 = v4 or rawget(callback, "___R")

		local v7 = rawget(callback, "_ChangedCbs")

		if v7 then
			local v8 = callback()

			for _, callback2 in v7 do
				task.spawn(callback2, v8, p, v3)
			end
		end

		callback = rawget(callback, "___P")

		if callback == nil then
			break
		end

		v3 = v6
	end

	if v and v4 then
		v4(p2, v2, ...)
	end
end

local function ArrayInsert(callback)
	return function(p, p2: number?, flag: boolean?)
		local v = callback()

		if p2 then
			table.insert(v, p2, p)
		else
			table.insert(v, p)
		end

		adoptChildren(callback)
		fireChangeAndReplicate(callback, nil, "insert", flag, p, p2)

		local v2 = rawget(callback, "_OnInsertCbs")

		if v2 then
			local v3 = p2 or table.find(v, p)

			for _, callback2 in v2 do
				task.spawn(callback2, p, v3)
			end
		end
	end
end

local function ArrayRemove(callback)
	return function(p: number?, flag: boolean?)
		local v = callback()
		local v2 = table.remove(v, p)
		adoptChildren(callback)
		fireChangeAndReplicate(callback, nil, "remove", flag, p)

		local v3 = rawget(callback, "_OnRemoveCbs")

		if v3 then
			local v4 = p or #v + 1

			for _, callback2 in v3 do
				task.spawn(callback2, v2, v4)
			end
		end

		return v2
	end
end

local v = {
	Changed = createCallbackFn("_ChangedCbs"), -- inferred equivalent call
	Insert = ArrayInsert,
	Remove = ArrayRemove,
	OnInsert = createCallbackFn("_OnInsertCbs"), -- inferred equivalent call
	OnRemove = createCallbackFn("_OnRemoveCbs"), -- inferred equivalent call
	OnKeyAdded = createCallbackFn("_OnKeyAddedCbs"), -- inferred equivalent call
	OnKeyRemoved = callbackFn
}

function class.__index(callback, p: string)
	local v2 = v[p]

	if v2 then
		return v2(callback)
	end

	local v3 = callback()
	assert(type(v3) == "table", `attempted to index '{rawget(callback, "___K")}'({typeof(v3)}) with '{p}'({typeof(p)})`)

	local v4 = rawget(callback, "___C")

	if v4 and v4[p] ~= nil then
		return v4[p]
	end

	local v5 = Value.new(v3, p, callback)

	if not v4 then
		v4 = {}
		rawset(callback, "___C", v4)
	end

	v4[p] = v5

	return v5
end

function class.__call(p, ...)
	local v2 = rawget(p, "___X")
	local v3 = rawget(p, "___K")
	local selected

	if v3 == nil then
		selected = v2
	else
		selected = v2[v3]
	end

	if select("#", ...) == 0 then
		return selected
	end

	local v4, v5 = ...

	if type(v4) == "function" then
		v2[v3] = v4(selected)
	else
		v2[v3] = v4
	end

	local v6 = v2[v3]
	adoptChildren(p)
	local v7 = rawget(p, "___C")

	if v7 then
		for _, v8 in v7 do
			sendChangedSignalToChildren(v8)
		end
	end

	fireChangeAndReplicate(p, selected, "set", v5, v6)

	return v6
end

function Value.new(p, p2: string?, p3, callback)
	local self = setmetatable({
		["___K"] = p2,
		___P = p3,
		___X = p,
		___R = callback,
		___C = nil
	}, class)

	adoptChildren(self)

	return self
end

return Value