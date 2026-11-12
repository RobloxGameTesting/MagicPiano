local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

local function coerce(data, materialColor) -- 1 equivalent call inferred from this helper
	if typeof(materialColor) == "Color3" and typeof(data) == "Vector3" then
		return Color3.fromRGB(data.X, data.Y, data.Z)
	end

	return data
end

local function setClouds(item)
	for _, clouds in Terrain:GetChildren() do
		if clouds:IsA("Clouds") then
			clouds.Enabled = clouds.Name == item
		end
	end
end

return {
	Apply = function(items): boolean
		if not items then
			warn("LightingApplier: missing lighting preset")
			return false
		end

		for k, item in pairs(items) do
			if k == "Terrain" then
				if typeof(item) == "table" then
					for k2, v in pairs(item) do
						local v2 = Enum.Material[k2]

						if v2 then
							Terrain:SetMaterialColor(v2, coerce(v, Terrain:GetMaterialColor(v2)))
						else
							warn(("LightingApplier: invalid material '%s'"):format(k2))
						end
					end
				else
					warn("LightingApplier: 'Terrain' must be a table")
				end
			elseif k == "Clouds" then
				setClouds(item)
			elseif k == "GlobalWind" then
				workspace.GlobalWind = item
			else
				local success, result = pcall(function()
					return Lighting[k]
				end)

				if success then
					item = coerce(item, result) -- inferred equivalent call
					local v = item
					local success2, result2 = pcall(function()
						Lighting[k] = v
					end)

					if not success2 then
						warn(("LightingApplier: failed to set '%s': %s"):format(k, (tostring(result2))))
					end
				else
					warn(("LightingApplier: '%s' is not a valid Lighting property, skipping"):format(k))
				end
			end
		end

		return true
	end
}