return function(instance)
	return function(attributeName: string, p)
		local attribute = instance:GetAttribute(attributeName)

		if attribute ~= nil then
			return attribute
		end

		if p == nil then
			warn(`TweakAttribute: No value found for "{attributeName}" and no default was provided`)
			return nil
		end

		instance:SetAttribute(attributeName, p)
		return p
	end
end