local function deepEqual(items, items2)
	if typeof(items) ~= typeof(items2) then
		return false, (("{1} is of type %s, but {2} is of type %s"):format(typeof(items), (typeof(items2))))
	end

	if typeof(items) == "table" then
		local set = {}

		for k, item in pairs(items) do
			set[k] = true

			local v, v2 = deepEqual(item, items2[k])

			if not v and v2 then
				return
					false,
					(v2:gsub("{1}", ("{1}[%s]"):format((tostring(k)))):gsub("{2}", ("{2}[%s]"):format((tostring(k)))))
			end
		end

		for k, item in pairs(items2) do
			if set[k] then
				continue
			end

			local v, v2 = deepEqual(item, items[k])

			if not v and v2 then
				return
					false,
					(v2:gsub("{1}", ("{1}[%s]"):format((tostring(k)))):gsub("{2}", ("{2}[%s]"):format((tostring(k)))))
			end
		end

		return true, nil
	elseif items == items2 then
		return true, nil
	else
		return false, "{1} ~= {2}"
	end
end

local function assertDeepEqual(p, p2)
	local v, v2 = deepEqual(p, p2)

	if not v and v2 then
		local formatted = ("Values were not deep-equal.\n%s"):format((v2:gsub("{1}", "first"):gsub("{2}", "second")))

		error(formatted, 2)
	end
end

return assertDeepEqual