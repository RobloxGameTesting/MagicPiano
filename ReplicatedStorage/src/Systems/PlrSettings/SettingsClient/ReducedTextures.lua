local ReducedTextures = {}
ReducedTextures.Toggled = false
local v = {}
local parentsByInstance = {}
local descendantAddedConnection = nil

local function hideObject(descendant)
	if descendant:IsA("BasePart") and descendant.Material == Enum.Material.ForceField then
		return
	end

	local model = descendant:FindFirstAncestorOfClass("Model")

	if model and model:FindFirstChildOfClass("Humanoid") then
		return
	end

	if descendant:IsA("BasePart") then
		if not v[descendant] then
			local v2 = { Material = descendant.Material, TextureID = 0 }
			local textureID

			if descendant:IsA("MeshPart") then
				textureID = descendant.TextureID or nil
			end

			v2.TextureID = textureID
			v[descendant] = v2
		end

		descendant.Material = Enum.Material.SmoothPlastic

		if descendant:IsA("MeshPart") then
			descendant.TextureID = ""
		end
	elseif descendant:IsA("Texture") or descendant:IsA("Decal") or descendant:IsA("SurfaceAppearance") then
		if parentsByInstance[descendant] then
			return
		end

		parentsByInstance[descendant] = descendant.Parent
		descendant.Parent = nil
	end
end

local function hideAll()
	descendantAddedConnection = workspace.DescendantAdded:Connect(function(descendant)
		if ReducedTextures.Toggled then
			hideObject(descendant)
		end
	end)

	for _, descendant in ipairs(workspace:GetDescendants()) do
		if not ReducedTextures.Toggled then
			break
		end

		hideObject(descendant)
	end
end

local function showAll()
	if descendantAddedConnection then
		descendantAddedConnection:Disconnect()
		descendantAddedConnection = nil
	end

	for part, v2 in pairs(v) do
		if not part.Parent then
			continue
		end

		part.Material = v2.Material

		if part:IsA("MeshPart") and v2.TextureID ~= nil then
			part.TextureID = v2.TextureID
		end
	end

	table.clear(v)

	for k, parent in pairs(parentsByInstance) do
		if parent and parent:IsDescendantOf(game) then
			k.Parent = parent
		end
	end

	table.clear(parentsByInstance)
end

function ReducedTextures.Hide()
	if ReducedTextures.Toggled then
		return
	end

	ReducedTextures.Toggled = true
	hideAll()
end

function ReducedTextures.Show()
	if not ReducedTextures.Toggled then
		return
	end

	ReducedTextures.Toggled = false
	showAll()
end

return ReducedTextures