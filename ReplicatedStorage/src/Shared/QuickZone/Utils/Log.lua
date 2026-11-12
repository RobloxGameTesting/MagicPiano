local function formatLog(formatString: string, p: string?, ...)
	local v = `[QuickZone] {string.format(formatString, ...)}`

	local v2 = p or debug.traceback("", 3)

	if v2 ~= "" then
		v ..= ` \n---- Stack trace ----\n{v2}`
	end

	return (v:gsub("\n", "\n    "))
end

local Log = {}

function Log.info(p: string, p2: string?, ...)
	print(formatLog(p, p2, ...))
end

function Log.warn(p: string, p2: string?, ...)
	warn(formatLog(p, p2, ...))
end

function Log.fatal(p: string, p2: string?, ...)
	error(formatLog(p, p2, ...), 0)
end

function Log.nonFatal(p: string, p2: string?, ...)
	local v = formatLog(p, p2, ...)
	task.spawn(error, v, 0)
end

return Log