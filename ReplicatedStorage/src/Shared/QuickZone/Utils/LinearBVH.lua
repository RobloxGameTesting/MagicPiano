--!native
local Geometry = require(script.Parent.Geometry)
require(script.Parent.Parent.Types)

local v = Vector3.new(1, 1, 1) * 1e999
local v2 = -v

local unionBounds = Geometry.unionBounds
local getObjectBounds = Geometry.getObjectBounds
local getMortonScale = Geometry.getMortonScale
local positionToMortonCode = Geometry.positionToMortonCode

local LinearBVH = {}

local v3 = {}
local v4 = {}
local objectBounds = {}
local v5 = {}

local function getSplitPos(p, p2: number, p3: number)
	if p3 == p2 + 1 then
		return p2 + 1
	end

	local mortonCode = p[p2].mortonCode
	local mortonCode2 = p[p3].mortonCode

	if mortonCode == mortonCode2 then
		return (p2 + p3) // 2
	end

	local v6 = bit32.lshift(1, 31 - bit32.countlz((bit32.bxor(mortonCode, mortonCode2))))
	local v7 = bit32.band(mortonCode, v6)

	while p3 - p2 > 1 do
		local v8 = (p2 + p3) // 2

		if bit32.band(p[v8].mortonCode, v6) == v7 then
			p2 = v8
		else
			p3 = v8
		end
	end

	return p2 + 1
end

local function buildFlatTree(p, objectBounds2, p2, p3: number, count: number, p4, p5: number)
	local v6 = p4.nodes[p5]

	if not v6 then
		v6 = {}
		p4.nodes[p5] = v6
	end

	if p3 == count then
		local id = p[p3].id
		local min = objectBounds2[id]
		local max = p2[id]

		v6.min = min
		v6.max = max
		v6.id = id
		v6.skipIndex = p5 + 1

		return p5 + 1, min, max
	else
		local splitPos = getSplitPos(p, p3, count)
		v6.id = -1

		local v7, v8, v9 = buildFlatTree(p, objectBounds2, p2, p3, splitPos - 1, p4, p5 + 1)
		local skipIndex, v10, v11 = buildFlatTree(p, objectBounds2, p2, splitPos, count, p4, v7)

		local min, max = unionBounds(v8, v9, v10, v11)
		v6.min = min
		v6.max = max
		v6.skipIndex = skipIndex

		return skipIndex, min, max
	end
end

function LinearBVH:build(items, p)
	table.clear(objectBounds)
	table.clear(v5)

	local v6 = v
	local v7 = v2
	local count = 0

	for k, item in items do
		local objectBounds2, v8 = getObjectBounds(item, p[k])

		objectBounds[k] = objectBounds2
		v5[k] = v8

		v6 = vector.min(v6, objectBounds2)
		v7 = vector.max(v7, v8)

		count += 1

		local v9 = v3[count]

		if not v9 then
			local count2 = #v4

			if count2 > 0 then
				v9 = v4[count2]
				v4[count2] = nil
			else
				v9 = { id = 0, mortonCode = 0 }
			end

			v3[count] = v9
		end

		v9.id = k
	end

	if count == 0 then
		self.count = 0
		return
	end

	local count2 = #v3

	if count < count2 then
		local count3 = #v4

		for i = count + 1, count2 do
			count3 += 1
			v4[count3] = v3[i]
			v3[i] = nil
		end
	end

	local vector3 = vector.max(Vector3.new(1, 1, 1), (v7 - v6) * 0.01)
	local v8 = v6 - vector3
	local mortonScale, v9, v10 = getMortonScale(v8, v7 + vector3)

	for i = 1, count do
		local v11 = v3[i]
		v11.mortonCode = positionToMortonCode(items[v11.id].Position, v8, mortonScale, v9, v10)
	end

	table.sort(v3, function(a, b): boolean
		return a.mortonCode < b.mortonCode
	end)

	self.count = buildFlatTree(v3, objectBounds, v5, 1, count, self, 1) - 1
end

function LinearBVH.queryPoint(p, vector3: Vector3, callback)
	local nodes = p.nodes
	local count = p.count
	local x = vector3.X
	local y = vector3.Y
	local z = vector3.Z
	local v6 = 1

	while v6 <= count do
		local node = nodes[v6]
		local min = node.min
		local max = node.max

		if min.X <= x and x <= max.X and min.Y <= y and y <= max.Y and min.Z <= z and z <= max.Z then
			v6 += 1
			local id = node.id

			if id > 0 then
				callback(id)
			end
		else
			v6 = node.skipIndex
		end
	end
end

return LinearBVH