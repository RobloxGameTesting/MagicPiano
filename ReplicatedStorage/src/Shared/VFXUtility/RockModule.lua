local RockModule = {}

local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local debrisFolder = nil

local function GetDebrisFolder()
	if debrisFolder and debrisFolder.Parent then
		return debrisFolder
	end

	local debris = workspace:FindFirstChild("Debris")

	if debris and debris:IsA("Folder") then
		debrisFolder = debris
	else
		local debris2 = Instance.new("Folder")
		debris2.Name = "Debris"
		debris2.Parent = workspace
		debrisFolder = debris2
	end

	return debrisFolder
end

local function BuildIgnoreRaycastParams(p)
	local filterDescendantsInstances = { p }

	for _, v in ipairs(Players:GetPlayers()) do
		local character = v.Character

		if character then
			table.insert(filterDescendantsInstances, character)
		end
	end

	for _, v in ipairs(CollectionService:GetTagged("RockModuleIgnore")) do
		table.insert(filterDescendantsInstances, v)
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = filterDescendantsInstances
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true

	return raycastParams
end

local function CreateStyledRock(parent, name: string, instance) -- 1 equivalent call inferred from this helper
	local part = Instance.new("Part")
	part.Name = name
	part.Color = instance.Color
	part.Material = instance.Material
	part.Transparency = instance.Transparency
	part.CanCollide = true
	part.Parent = parent
	return part
end

function RockModule.Crater(cframe: CFrame, value: number?, value2: number?, value3: number?, flag: boolean?)
	local v = value or 7

	local v2 = flag == nil or flag

	local parent = GetDebrisFolder()
	local ignoreRaycastParams = BuildIgnoreRaycastParams(parent)

	local raycastResult = workspace:Raycast(cframe.Position, cframe.UpVector * -1000, ignoreRaycastParams)

	if not raycastResult then
		return
	end

	local v3 = math.random(value2 or 7, value3 or 10)
	local cframe2 = CFrame.new(raycastResult.Position)
	local v4 = 360 / v3
	local total = 0

	for _ = 1, v3 do
		local v5 = (cframe2 * CFrame.Angles(0, math.rad(total), 0) * CFrame.new(0, 0, -v)).Position + Vector3.new(0, -5, 0)

		local raycastResult2 = workspace:Raycast(
			v5 + Vector3.new(0, 7, 0),
			Vector3.new(0, -1000, 0),
			ignoreRaycastParams
		)

		if not raycastResult2 then
			continue
		end

		local instance

		if raycastResult2 then
			instance = raycastResult2.Instance
		else
			instance = raycastResult.Instance
		end

		if not instance:IsA("BasePart") then
			break
		end

		local styledRock = CreateStyledRock(parent, "GroundSlam", instance) -- inferred equivalent call
		styledRock.Size = Vector3.new(math.random(3, 5), math.random(2, 3), math.random(2, 4))
		styledRock.CFrame = CFrame.lookAt(v5, raycastResult.Position)
		styledRock.Anchored = true

		if v2 == false then
			styledRock.CollisionGroup = "RockDebris"
		end

		Debris:AddItem(styledRock, 30)

		TweenService:Create(styledRock, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Position = styledRock.Position + Vector3.new(0, 4.5, 0)
		}):Play()

		task.delay(math.random(6.5, 9.5), function()
			TweenService:Create(styledRock, TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = styledRock.Position + Vector3.new(0, -5, 0),
				Size = Vector3.new(1, 1, 1)
			}):Play()
		end)

		total += v4
	end
end

function RockModule.Explosion(cframe: CFrame, value: number?, value2: number?, value3: number?, flag: boolean?)
	local v = value2 or 0.5
	local v2 = value3 or 2.5

	if flag == nil then
		flag = false
	end

	local parent = GetDebrisFolder()
	local ignoreRaycastParams = BuildIgnoreRaycastParams(parent)

	local raycastResult = workspace:Raycast(cframe.Position, cframe.UpVector * -100, ignoreRaycastParams)

	if not (raycastResult and raycastResult.Instance:IsA("BasePart")) then
		return
	end

	local instance = raycastResult.Instance

	for _ = 1, value or 7 do
		local v3 = math.floor((math.random(v * 100, v2 * 100))) / 100

		local explosionPart = Instance.new("Part")
		explosionPart.Name = "ExplosionPart"

		if math.random(1, 5) == 3 then
			explosionPart.Size = Vector3.new(v3 * 2, 0.15, v3 * 2)
		else
			explosionPart.Size = Vector3.new(v3, v3, v3)
		end

		explosionPart.CFrame = cframe
		explosionPart.Color = instance.Color
		explosionPart.Material = instance.Material
		explosionPart.Transparency = instance.Transparency
		explosionPart.Orientation = Vector3.new(math.random(-359, 359), math.random(-359, 359), math.random(-359, 359))
		explosionPart.Anchored = false
		explosionPart.CanCollide = true

		if flag == false then
			explosionPart.CollisionGroup = "RockDebris"
		end

		explosionPart.Parent = parent
		Debris:AddItem(explosionPart, 4.5)

		local vector3 = Vector3.new(math.random(-32, 32), 22, math.random(-32, 32))

		explosionPart.AssemblyLinearVelocity = vector3
		local bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.Velocity = vector3
		bodyVelocity.MaxForce = Vector3.new(1e999, 1e999, 1e999)
		bodyVelocity.P = 5000
		bodyVelocity.Parent = explosionPart
		Debris:AddItem(bodyVelocity, 0.25)

		task.delay(4, function()
			TweenService:Create(
				explosionPart,
				TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut),
				{ Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }
			):Play()
		end)
	end
end

function RockModule.CraterRows(cframe: CFrame, value: number?, value2: number?, value3: number?, value4: number?, value5: number?, flag: boolean?)
	local v = flag == nil or flag
	local v2 = value or 7
	local v3 = value4 or 7
	local v4 = value5 or 10
	local v5 = value3 or 4

	for i = 1, value2 or 3 do
		RockModule.Crater(cframe, v2, v3 * i, v4 * i, v)
		v2 += v5
	end
end

function RockModule.ClearDebris(flag: boolean?)
	local debrisFolder2 = GetDebrisFolder()

	for _, part in ipairs(debrisFolder2:GetChildren()) do
		if flag then
			if part:IsA("BasePart") then
				TweenService:Create(part, TweenInfo.new(0.75, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
					Size = Vector3.new(0.1, 0.1, 0.1),
					Transparency = 1
				}):Play()
				Debris:AddItem(part, 1)
			end
		else
			part:Destroy()
		end
	end
end

return RockModule