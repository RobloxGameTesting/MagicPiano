--!native
local value = Enum.PartType.Block.Value
local value2 = Enum.PartType.Ball.Value
local value3 = Enum.PartType.Cylinder.Value
local value4 = Enum.PartType.Wedge.Value
local value5 = Enum.PartType.CornerWedge.Value

local v = table.create(1024)

for i = 0, 1023 do
	local v2 = bit32.band(bit32.bor(bit32.lshift(i, 16), i), 4278190335)
	local v3 = bit32.band(bit32.bor(bit32.lshift(v2, 8), v2), 251719695)
	local v4 = bit32.band(bit32.bor(bit32.lshift(v3, 4), v3), 51130563)
	local v5 = bit32.band(bit32.bor(bit32.lshift(v4, 2), v4), 153391689)
	v[i + 1] = v5
end

local function expandBits(p: number) -- 3 equivalent calls inferred from this helper
	return v[bit32.band(p, 1023) + 1]
end

local Geometry = {}
Geometry.MESH_SHAPE_VALUE = -1

function Geometry.unionBounds(vector3: Vector3, vector3_2: Vector3, vector3_3: Vector3, vector3_4: Vector3)
	return vector.min(vector3, vector3_3), (vector.max(vector3_2, vector3_4))
end

function Geometry.getObjectBounds(cframe: CFrame, vector3: Vector3)
	local position = cframe.Position
	local rightVector = cframe.RightVector
	local upVector = cframe.UpVector
	local lookVector = cframe.LookVector

	local vector3_2 = Vector3.new(
		math.abs(rightVector.X) * vector3.X + math.abs(upVector.X) * vector3.Y + math.abs(lookVector.X) * vector3.Z,
		math.abs(rightVector.Y) * vector3.X + math.abs(upVector.Y) * vector3.Y + math.abs(lookVector.Y) * vector3.Z,
		math.abs(rightVector.Z) * vector3.X + math.abs(upVector.Z) * vector3.Y + math.abs(lookVector.Z) * vector3.Z
	)
	return position - vector3_2, position + vector3_2
end

function Geometry.getMortonScale(vector3: Vector3, vector3_2: Vector3)
	local vector3_3 = vector3_2 - vector3
	return 1023 / vector3_3.X, 1023 / vector3_3.Y, 1023 / vector3_3.Z
end

function Geometry.positionToMortonCode(vector3: Vector3, vector3_2: Vector3, p: number, p2: number, p3: number)
	local v2 = math.floor((math.clamp((vector3.X - vector3_2.X) * p, 0, 1023)))
	local v3 = math.floor((math.clamp((vector3.Y - vector3_2.Y) * p2, 0, 1023)))
	local v4 = math.floor((math.clamp((vector3.Z - vector3_2.Z) * p3, 0, 1023)))

	return (bit32.bor(expandBits(v2), bit32.lshift(expandBits(v3), 1), (bit32.lshift(expandBits(v4), 2)))) -- inferred equivalent call
end

function Geometry.isPointInShape(vector3: Vector3, cframe: CFrame, vector3_2: Vector3, p: number, object): boolean
	if p == value then
		local vector3_3 = vector.abs((cframe:PointToObjectSpace(vector3)))
		return vector.min(vector3_3, vector3_2) == vector3_3
	end

	if p == value3 then
		local position = cframe.Position
		local x = vector3_2.X
		local v2 = position - cframe.RightVector * x
		local v3 = vector3 - v2
		local rightVector = cframe.RightVector
		local v4 = vector.dot(v3, rightVector)

		if v4 >= 0 and v4 <= x * 2 then
			local vector3_3 = v2 + rightVector * v4
			return vector.dot(vector3 - vector3_3, vector3 - vector3_3) <= vector3_2.Y * vector3_2.Y
		end

		return false
	elseif p == value2 then
		local v2 = vector3_2.X * vector3_2.X
		local position = cframe.Position
		return vector.dot(position - vector3, position - vector3) <= v2
	elseif p == value4 then
		local pointToObjectSpace = cframe:PointToObjectSpace(vector3)
		local vector3_3 = vector.abs(pointToObjectSpace)

		if vector.min(vector3_3, vector3_2) ~= vector3_3 then
			return false
		end

		local vector3_4 = vector3_2 * 2
		return pointToObjectSpace.Y / vector3_4.Y - pointToObjectSpace.Z / vector3_4.Z <= 0
	elseif p == value5 then
		local vector3_3 = vector3_2 * 2
		local pointToObjectSpace = cframe:PointToObjectSpace(vector3)

		if vector.dot(pointToObjectSpace, (vector.normalize((Vector3.new(0, vector3_3.Z, vector3_3.Y))))) > 0 then
			return false
		end

		if vector.dot(pointToObjectSpace, (vector.normalize((Vector3.new(-vector3_3.Y, vector3_3.X, 0))))) > 0 then
			return false
		end

		local vector3_4 = vector.abs(pointToObjectSpace)
		return vector.min(vector3_4, vector3_2) == vector3_4
	else
		if not (p == -1 and object) then
			return false
		end

		local v2 = object:GetClosestPointOnSurface(vector3) - vector3
		return vector.dot(v2, v2) <= 0.0001
	end
end

return Geometry