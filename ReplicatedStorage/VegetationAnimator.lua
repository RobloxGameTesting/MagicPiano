local RunService = game:GetService("RunService")

local v = {}
local v2 = {}

local function getCell(p) -- 2 equivalent calls inferred from this helper
	return math.floor(p.X / 30), (math.floor(p.Z / 30))
end

local function addPart(p, part)
	if not (part:IsA("BasePart") and p.partFilter(part)) then
		return
	end

	local cell, v3 = getCell(part.Position) -- inferred equivalent call
	local v4 = p.cells[cell] or {}
	local v5 = v4[v3] or {}
	v4[v3] = v5
	p.cells[cell] = v4
	v5[#v5 + 1] = {
		part = part,
		baseCFrame = part.CFrame,
		phase = math.random() * 3.141592653589793 * 2
	}
end

local function addInstance(p, folder)
	if folder:IsA("BasePart") then
		addPart(p, folder)
	elseif folder:IsA("Model") or folder:IsA("Folder") then
		for _, descendant in folder:GetDescendants() do
			addPart(p, descendant)
		end
	end
end

local function updateActive(data, position)
	local cell, v3 = getCell(position) -- inferred equivalent call
	table.clear(data.active)

	for i = cell - data.cellRadius, cell + data.cellRadius do
		local cell2 = data.cells[i]

		if not cell2 then
			continue
		end

		for j = v3 - data.cellRadius, v3 + data.cellRadius do
			local v4 = cell2[j]

			if not v4 then
				continue
			end

			for k = #v4, 1, -1 do
				local v5 = v4[k]
				local part = v5.part

				if part.Parent then
					if part:IsDescendantOf(workspace) then
						local v6 = part.Position.X - position.X
						local v7 = part.Position.Z - position.Z

						if v6 * v6 + v7 * v7 <= data.distanceSquared then
							data.active[#data.active + 1] = v5
						end
					end
				else
					table.remove(v4, k)
				end
			end
		end
	end
end

task.spawn(function()
	while true do
		local currentCamera = workspace.CurrentCamera

		if currentCamera then
			local position = currentCamera.CFrame.Position

			for _, v3 in v do
				updateActive(v3, position)
			end
		end

		task.wait(0.1)
	end
end)

RunService:BindToRenderStep("VegetationAnimator", Enum.RenderPriority.Last.Value, function()
	local now = os.clock()

	for _, v3 in v do
		for i = 1, #v3.active do
			local v4 = v3.active[i]
			local part = v4.part

			if not part.Parent then
				continue
			end

			local v5 = math.sin(now * v3.speed + v4.phase) * v3.angle
			local v6 = math.cos(now * v3.speed2 + v4.phase) * v3.angle2

			part.CFrame = v4.baseCFrame * CFrame.Angles(v5, 0, v6)
		end
	end
end)
return {
	new = function(folder, data)
		if v2[folder] then
			return v2[folder]
		end

		local distance = data.distance or 50

		local v3 = {
			folder = folder,
			cells = {},
			active = {},
			distanceSquared = distance ^ 2,
			cellRadius = math.ceil(distance / 30),
			speed = data.speed or 1,
			speed2 = data.speed2 or 0.5,
			angle = math.rad(data.angle or 1.5),
			angle2 = math.rad(data.angle2 or 0.75),
			partFilter = data.partFilter or function(): boolean
				return true
			end
		}

		v[#v + 1] = v3

		for _, descendant in folder:GetDescendants() do
			addInstance(v3, descendant)
		end

		folder.DescendantAdded:Connect(function(descendant)
			addInstance(v3, descendant)
		end)

		v2[folder] = v3
		return v3
	end
}