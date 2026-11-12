local function internalAssert(p, p2)
	if not p then
		error(p2 .. " (This is probably a bug in Roact!)", 3)
	end
end

return internalAssert