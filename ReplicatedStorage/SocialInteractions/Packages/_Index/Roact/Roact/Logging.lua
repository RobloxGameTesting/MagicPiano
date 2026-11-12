local v = true

local v2 = {}

local tracebackSet = {}

local function indent(value, count) -- 2 equivalent calls inferred from this helper
	local v3 = ("\t"):rep(count)

	return v3 .. value:gsub("\n", "\n" .. v3)
end

local function indentLines(list, count)
	local v3 = {}

	for _, item in ipairs(list) do
		table.insert(v3, indent(item, count)) -- inferred equivalent call
	end

	return table.concat(v3, "\n")
end

local v3 = {
	__tostring = function(data)
		local v3 = { "LogInfo {" }

		local count = #data.errors
		local count2 = #data.warnings
		local count3 = #data.infos

		if count + count2 + count3 == 0 then
			table.insert(v3, "\t(no messages)")
		end

		if count > 0 then
			table.insert(v3, ("\tErrors (%d) {"):format(count))
			table.insert(v3, indentLines(data.errors, 2))
			table.insert(v3, "\t}")
		end

		if count2 > 0 then
			table.insert(v3, ("\tWarnings (%d) {"):format(count2))
			table.insert(v3, indentLines(data.warnings, 2))
			table.insert(v3, "\t}")
		end

		if count3 > 0 then
			table.insert(v3, ("\tInfos (%d) {"):format(count3))
			table.insert(v3, indentLines(data.infos, 2))
			table.insert(v3, "\t}")
		end

		table.insert(v3, "}")

		return table.concat(v3, "\n")
	end
}

local function createLogInfo()
	local logInfo = { errors = {}, warnings = {}, infos = {} }

	setmetatable(logInfo, v3)

	return logInfo
end

local Logging = {}

function Logging.capture(callback)
	local logInfo = createLogInfo()

	local v4 = v
	v = false
	v2[logInfo] = true

	local success, result = pcall(callback)

	v2[logInfo] = nil
	v = v4

	assert(success, result)

	return logInfo
end

function Logging.warn(value, ...)
	local formatted = value:format(...)

	for k in pairs(v2) do
		table.insert(k.warnings, formatted)
	end

	local formatted2 = ("%s\n%s"):format(formatted, indent(debug.traceback("", 2):sub(2), 1)) -- inferred equivalent call

	if v then
		warn(formatted2)
	end
end

function Logging.warnOnce(p, ...)
	local traceback = debug.traceback()

	if tracebackSet[traceback] then
		return
	end

	tracebackSet[traceback] = true
	Logging.warn(p, ...)
end

return Logging