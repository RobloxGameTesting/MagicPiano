local function oneChild(items)
	if not items then
		return nil
	end

	local v, v2 = next(items)

	if not v2 then
		return nil
	end

	if next(items, v) then
		error("Expected at most child, had more than one child.", 2)
	end

	return v2
end

return oneChild