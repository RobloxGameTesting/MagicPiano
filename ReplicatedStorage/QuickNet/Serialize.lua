local Players = game:GetService("Players")

require(script.Parent.Types)
local Enums = require(script.Parent.Enums)

local v = {
	number = Enums.NumberF64,
	CFrame = Enums.CFrameF32,
	Vector3 = Enums.Vector3F32,
	Vector2 = Enums.Vector2F32,
	["nil"] = Enums.Nil,
	string = Enums.String,
	Color3 = Enums.Color3,
	BrickColor = Enums.BrickColor,
	boolean = Enums.Boolean,
	table = Enums.DictDynamic,
	buffer = Enums.Buffer,
	Instance = Enums.Instance,
	DateTime = Enums.DateTime64,
	TweenInfo = Enums.TweenInfo,
	ColorSequence = Enums.ColorSequence,
	NumberSequence = Enums.NumberSequence,
	NumberRange = Enums.NumberRange,
	UDim = Enums.UDim,
	UDim2 = Enums.UDim2,
	Region3 = Enums.Region3,
	PhysicalProperties = Enums.PhysicalProperties,
	Rect = Enums.Rect
}

local v2 = Enums.Nil
local ArrayDynamic = Enums.ArrayDynamic

local v3 = table.create(100)

local writeu8 = buffer.writeu8
local writeu16 = buffer.writeu16
local writeu32 = buffer.writeu32
local writei8 = buffer.writei8
local writei16 = buffer.writei16
local writei32 = buffer.writei32
local writef32 = buffer.writef32
local writef64 = buffer.writef64
local writestring = buffer.writestring
local readu8 = buffer.readu8
local readu16 = buffer.readu16
local readu32 = buffer.readu32
local readi8 = buffer.readi8
local readi16 = buffer.readi16
local readi32 = buffer.readi32
local readf32 = buffer.readf32
local readf64 = buffer.readf64
local readstring = buffer.readstring
local len = string.len
local sub = string.sub
local frexp = math.frexp
local floor = math.floor

@native local function getTable() -- 6 equivalent calls inferred from this helper
	local count = #v3
	local v4 = v3[count]
	v3[count] = nil
	return v4 or {}
end

@native local function recycleTable(tbl) -- 6 equivalent calls inferred from this helper
	local count = #v3

	if count > 100 then
		return
	end

	table.clear(tbl)
	v3[count + 1] = tbl
end

@native local function isArray(items): boolean -- 1 equivalent call inferred from this helper
	local v4 = 1

	for k, _ in items do
		if k ~= v4 then
			return false
		end

		v4 += 1
	end

	return true
end

@native local function getDataType(items) -- 4 equivalent calls inferred from this helper
	local typeName = typeof(items)
	local dataType = v[typeName] or v2

	if typeName == "table" and isArray(items) then -- inferred equivalent call
		dataType = ArrayDynamic
	end

	return dataType
end

@native local function encodeFloat16(p: number)
	if p == 0 then
		return p
	end

	local v4

	if p < 0 then
		p = -p
		v4 = 1
	else
		v4 = 0
	end

	local v5, v6 = frexp(p)
	local v7 = v6 + 14

	if v7 <= 0 then
		return 0
	end

	if v7 >= 31 then
		return v4 * 32768 + 31744
	end

	local v8 = floor(v5 * 2048 - 1024 + 0.5)
	return v4 * 32768 + v7 * 1024 + v8
end

@native local function decodeFloat16(p: number) -- 12 equivalent calls inferred from this helper
	if p == 0 then
		return 0
	end

	local v4 = p >= 32768 and -1 or 1

	if v4 == -1 then
		p -= 32768
	end

	local v5 = floor(p / 1024)
	local v6 = p - v5 * 1024

	if v5 == 0 then
		return 0
	elseif v5 == 31 then
		return v4 * 1e999
	end

	return v4 * (v6 / 1024 + 1) * 2 ^ (v5 - 15)
end

@native local function encodeNumberU8(buf: buffer, offset: number, _, value: number): number
	writeu8(buf, offset, value)
	return 1
end

@native local function encodeNumberU16(buf: buffer, offset: number, _, value: number): number
	writeu16(buf, offset, value)
	return 2
end

@native local function encodeNumberU32(buf: buffer, offset: number, _, value: number): number
	writeu32(buf, offset, value)
	return 4
end

@native local function encodeNumberI8(buf: buffer, offset: number, _, value: number): number
	writei8(buf, offset, value)
	return 1
end

@native local function encodeNumberI16(buf: buffer, offset: number, _, value: number): number
	writei16(buf, offset, value)
	return 2
end

@native local function encodeNumberI32(buf: buffer, offset: number, _, value: number): number
	writei32(buf, offset, value)
	return 4
end

@native local function encodeNumberF16(buf: buffer, offset: number, _, value: number): number
	if value ~= 0 then
		local v4

		if value < 0 then
			value = -value
			v4 = 1
		else
			v4 = 0
		end

		local v5, v6 = frexp(value)
		local v7 = v6 + 14

		if v7 <= 0 then
			value = 0
		elseif v7 >= 31 then
			value = v4 * 32768 + 31744
		else
			local v8 = floor(v5 * 2048 - 1024 + 0.5)
			value = v4 * 32768 + v7 * 1024 + v8
		end
	end

	writeu16(buf, offset, value)
	return 2
end

@native local function encodeNumberF32(buf: buffer, offset: number, _, value: number): number
	writef32(buf, offset, value)
	return 4
end

@native local function encodeNumberF64(buf: buffer, offset: number, _, value: number): number
	writef64(buf, offset, value)
	return 8
end

@native local function decodeNumberU8(buf: buffer, offset: number, _)
	return readu8(buf, offset), 1
end

@native local function decodeNumberU16(buf: buffer, offset: number, _)
	return readu16(buf, offset), 2
end

@native local function decodeNumberU32(buf: buffer, offset: number, _)
	return readu32(buf, offset), 4
end

@native local function decodeNumberI8(buf: buffer, offset: number, _)
	return readi8(buf, offset), 1
end

@native local function decodeNumberI16(buf: buffer, offset: number, _)
	return readi16(buf, offset), 2
end

@native local function decodeNumberI32(buf: buffer, offset: number, _)
	return readi32(buf, offset), 4
end

@native local function decodeNumberF16(buf: buffer, offset: number, _)
	return decodeFloat16(readu16(buf, offset)), 2 -- inferred equivalent call
end

@native local function decodeNumberF32(buf: buffer, offset: number, _)
	return readf32(buf, offset), 4
end

@native local function decodeNumberF64(buf: buffer, offset: number, _)
	return readf64(buf, offset), 8
end

@native local function encodeCFrameFX8(buf: buffer, offset: number, _, cframe: CFrame): number
	local position = cframe.Position
	local eulerAnglesXYZ, v4, v5 = cframe:ToEulerAnglesXYZ()
	writei8(buf, offset, position.X * 10)
	writei8(buf, offset + 1, position.Y * 10)
	writei8(buf, offset + 2, position.Z * 10)
	writei8(buf, offset + 3, eulerAnglesXYZ * 40.42)
	writei8(buf, offset + 4, v4 * 40.42)
	writei8(buf, offset + 5, v5 * 40.42)
	return 6
end

@native local function encodeCFrameI16FX16(buf: buffer, offset: number, _, cframe: CFrame): number
	local position = cframe.Position
	local eulerAnglesXYZ, v4, v5 = cframe:ToEulerAnglesXYZ()
	writei16(buf, offset, position.X)
	writei16(buf, offset + 2, position.Y)
	writei16(buf, offset + 4, position.Z)
	writei16(buf, offset + 6, eulerAnglesXYZ * 10430)
	writei16(buf, offset + 8, v4 * 10430)
	writei16(buf, offset + 10, v5 * 10430)
	return 12
end

@native local function decodeCFrameI16FX16(buf: buffer, offset: number, _)
	local v4 = readi16(buf, offset)
	local v5 = readi16(buf, offset + 2)
	local v6 = offset + 4
	local vector3 = Vector3.new(v4, v5, (readi16(buf, v6)))

	local v7 = readi16(buf, offset + 6) / 10430
	local v8 = readi16(buf, offset + 8) / 10430
	local v9 = readi16(buf, offset + 10) / 10430
	return CFrame.Angles(v7, v8, v9) + vector3, 12
end

@native local function encodeCFrameFX16(buf: buffer, offset: number, _, cframe: CFrame): number
	local position = cframe.Position
	local eulerAnglesXYZ, v4, v5 = cframe:ToEulerAnglesXYZ()
	writei16(buf, offset, position.X * 100)
	writei16(buf, offset + 2, position.Y * 100)
	writei16(buf, offset + 4, position.Z * 100)
	writei16(buf, offset + 6, eulerAnglesXYZ * 10430)
	writei16(buf, offset + 8, v4 * 10430)
	writei16(buf, offset + 10, v5 * 10430)
	return 12
end

@native local function encodeCFrameF16(buf: buffer, offset: number, _, cframe: CFrame): number
	local position = cframe.Position
	local v4, v5, v6 = cframe:ToEulerAnglesXYZ()
	local v7 = position.X

	if v7 ~= 0 then
		local v8

		if v7 < 0 then
			v7 = -v7
			v8 = 1
		else
			v8 = 0
		end

		local v9, v10 = frexp(v7)
		local v11 = v10 + 14

		if v11 <= 0 then
			v7 = 0
		elseif v11 >= 31 then
			v7 = v8 * 32768 + 31744
		else
			local v12 = floor(v9 * 2048 - 1024 + 0.5)
			v7 = v8 * 32768 + v11 * 1024 + v12
		end
	end

	writeu16(buf, offset, v7)
	local v8 = offset + 2
	local v9 = position.Y

	if v9 ~= 0 then
		local v10

		if v9 < 0 then
			v9 = -v9
			v10 = 1
		else
			v10 = 0
		end

		local v11, v12 = frexp(v9)
		local v13 = v12 + 14

		if v13 <= 0 then
			v9 = 0
		elseif v13 >= 31 then
			v9 = v10 * 32768 + 31744
		else
			local v14 = floor(v11 * 2048 - 1024 + 0.5)
			v9 = v10 * 32768 + v13 * 1024 + v14
		end
	end

	writeu16(buf, v8, v9)
	local v10 = offset + 4
	local v11 = position.Z

	if v11 ~= 0 then
		local v12

		if v11 < 0 then
			v11 = -v11
			v12 = 1
		else
			v12 = 0
		end

		local v13, v14 = frexp(v11)
		local v15 = v14 + 14

		if v15 <= 0 then
			v11 = 0
		elseif v15 >= 31 then
			v11 = v12 * 32768 + 31744
		else
			local v16 = floor(v13 * 2048 - 1024 + 0.5)
			v11 = v12 * 32768 + v15 * 1024 + v16
		end
	end

	writeu16(buf, v10, v11)
	local v12 = offset + 6

	if v4 ~= 0 then
		local v13

		if v4 < 0 then
			v4 = -v4
			v13 = 1
		else
			v13 = 0
		end

		local v14, v15 = frexp(v4)
		local v16 = v15 + 14

		if v16 <= 0 then
			v4 = 0
		elseif v16 >= 31 then
			v4 = v13 * 32768 + 31744
		else
			local v17 = floor(v14 * 2048 - 1024 + 0.5)
			v4 = v13 * 32768 + v16 * 1024 + v17
		end
	end

	writeu16(buf, v12, v4)
	local v13 = offset + 8

	if v5 ~= 0 then
		local v14

		if v5 < 0 then
			v5 = -v5
			v14 = 1
		else
			v14 = 0
		end

		local v15, v16 = frexp(v5)
		local v17 = v16 + 14

		if v17 <= 0 then
			v5 = 0
		elseif v17 >= 31 then
			v5 = v14 * 32768 + 31744
		else
			local v18 = floor(v15 * 2048 - 1024 + 0.5)
			v5 = v14 * 32768 + v17 * 1024 + v18
		end
	end

	writeu16(buf, v13, v5)
	local v14 = offset + 10

	if v6 ~= 0 then
		local v15

		if v6 < 0 then
			v6 = -v6
			v15 = 1
		else
			v15 = 0
		end

		local v16, v17 = frexp(v6)
		local v18 = v17 + 14

		if v18 <= 0 then
			v6 = 0
		elseif v18 >= 31 then
			v6 = v15 * 32768 + 31744
		else
			local v19 = floor(v16 * 2048 - 1024 + 0.5)
			v6 = v15 * 32768 + v18 * 1024 + v19
		end
	end

	writeu16(buf, v14, v6)
	return 12
end

@native local function axisId(p: number, p2: number, p3: number): number -- 2 equivalent calls inferred from this helper
	local v4 = math.abs(p)
	local v5 = math.abs(p2)
	local v6 = math.abs(p3)

	if v5 <= v4 and v6 <= v4 then
		return if p > 0 then 0 else 1
	elseif v6 <= v5 then
		return if p2 > 0 then 2 else 3
	else
		return if p3 > 0 then 4 else 5
	end
end

local v4 = {
	[0] = CFrame.identity,
	[1] = CFrame.identity,
	[2] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 1, 0)),
	[3] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(1, 0, 0), -Vector3.new(0, 1, 0)),
	[4] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)),
	[5] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(1, 0, 0), -Vector3.new(0, 0, 1)),
	[6] = CFrame.identity,
	[7] = CFrame.identity,
	[8] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(1, 0, 0), Vector3.new(0, 1, 0)),
	[9] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(1, 0, 0), -Vector3.new(0, 1, 0)),
	[10] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(1, 0, 0), Vector3.new(0, 0, 1)),
	[11] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(1, 0, 0), -Vector3.new(0, 0, 1)),
	[12] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 1, 0), Vector3.new(1, 0, 0)),
	[13] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 1, 0), -Vector3.new(1, 0, 0)),
	[14] = CFrame.identity,
	[15] = CFrame.identity,
	[16] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
	[17] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 1, 0), -Vector3.new(0, 0, 1)),
	[18] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 1, 0), Vector3.new(1, 0, 0)),
	[19] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 1, 0), -Vector3.new(1, 0, 0)),
	[20] = CFrame.identity,
	[21] = CFrame.identity,
	[22] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 1, 0), Vector3.new(0, 0, 1)),
	[23] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 1, 0), -Vector3.new(0, 0, 1)),
	[24] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1), Vector3.new(1, 0, 0)),
	[25] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1), -Vector3.new(1, 0, 0)),
	[26] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 1, 0)),
	[27] = CFrame.fromMatrix(Vector3.new(0, 0, 0), Vector3.new(0, 0, 1), -Vector3.new(0, 1, 0)),
	[28] = CFrame.identity,
	[29] = CFrame.identity,
	[30] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 0, 1), Vector3.new(1, 0, 0)),
	[31] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 0, 1), -Vector3.new(1, 0, 0)),
	[32] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 0, 1), Vector3.new(0, 1, 0)),
	[33] = CFrame.fromMatrix(Vector3.new(0, 0, 0), -Vector3.new(0, 0, 1), -Vector3.new(0, 1, 0)),
	[34] = CFrame.identity,
	[35] = CFrame.identity
}

@native local function encodeCFrameF32Aligned(buf: buffer, offset: number, _, cframe: CFrame): number
	local components, v5, v6, v7, v8, _, v9, v10, _, v11, v12, _ = cframe:GetComponents()
	local v13 = axisId(v7, v9, v11) -- inferred equivalent call
	local v14 = axisId(v8, v10, v12) -- inferred equivalent call
	writef32(buf, offset, components)
	writef32(buf, offset + 4, v5)
	writef32(buf, offset + 8, v6)
	writeu8(buf, offset + 12, v13 * 6 + v14)
	return 13
end

@native local function decodeCFrameF32Aligned(buf: buffer, offset: number, _)
	local v5 = readf32(buf, offset)
	local v6 = readf32(buf, offset + 4)
	local v7 = readf32(buf, offset + 8)
	return v4[readu8(buf, offset + 12)] + Vector3.new(v5, v6, v7), 13
end

@native local function encodeCFrameF32FX16(buf: buffer, offset: number, _, cframe: CFrame): number
	local position = cframe.Position
	local eulerAnglesXYZ, v5, v6 = cframe:ToEulerAnglesXYZ()
	writef32(buf, offset, position.X)
	writef32(buf, offset + 4, position.Y)
	writef32(buf, offset + 8, position.Z)
	writei16(buf, offset + 12, eulerAnglesXYZ * 10430)
	writei16(buf, offset + 14, v5 * 10430)
	writei16(buf, offset + 16, v6 * 10430)
	return 18
end

@native local function encodeCFrameF32(buf: buffer, offset: number, _, cframe: CFrame): number
	local position = cframe.Position
	local eulerAnglesXYZ, v5, v6 = cframe:ToEulerAnglesXYZ()
	writef32(buf, offset, position.X)
	writef32(buf, offset + 4, position.Y)
	writef32(buf, offset + 8, position.Z)
	writef32(buf, offset + 12, eulerAnglesXYZ)
	writef32(buf, offset + 16, v5)
	writef32(buf, offset + 20, v6)
	return 24
end

@native local function decodeCFrameFX8(buf: buffer, offset: number, _)
	local v5 = readi8(buf, offset) / 10
	local v6 = readi8(buf, offset + 1) / 10
	local v7 = readi8(buf, offset + 2) / 10
	local v8 = readi8(buf, offset + 3) / 40.42
	local v9 = readi8(buf, offset + 4) / 40.42
	local v10 = readi8(buf, offset + 5) / 40.42
	return CFrame.Angles(v8, v9, v10) + Vector3.new(v5, v6, v7), 6
end

@native local function decodeCFrameFX16(buf: buffer, offset: number, _)
	local v5 = readi16(buf, offset) / 100
	local v6 = readi16(buf, offset + 2) / 100
	local v7 = readi16(buf, offset + 4) / 100
	local v8 = readi16(buf, offset + 6) / 10430
	local v9 = readi16(buf, offset + 8) / 10430
	local v10 = readi16(buf, offset + 10) / 10430
	return CFrame.Angles(v8, v9, v10) + Vector3.new(v5, v6, v7), 12
end

@native local function decodeCFrameF16(buf: buffer, offset: number, _)
	local v5 = decodeFloat16(readu16(buf, offset)) -- inferred equivalent call
	local v6 = decodeFloat16(readu16(buf, offset + 2)) -- inferred equivalent call
	local v7 = decodeFloat16(readu16(buf, offset + 4)) -- inferred equivalent call
	local v8 = decodeFloat16(readu16(buf, offset + 6)) -- inferred equivalent call
	local v9 = decodeFloat16(readu16(buf, offset + 8)) -- inferred equivalent call
	local v10 = offset + 10
	return CFrame.Angles(v8, v9, decodeFloat16(readu16(buf, v10))) + Vector3.new(v5, v6, v7), 12 -- inferred equivalent call
end

@native local function decodeCFrameF32FX16(buf: buffer, offset: number, _)
	local v5 = readf32(buf, offset)
	local v6 = readf32(buf, offset + 4)
	local v7 = readf32(buf, offset + 8)
	local v8 = readi16(buf, offset + 12) / 10430
	local v9 = readi16(buf, offset + 14) / 10430
	local v10 = readi16(buf, offset + 16) / 10430
	return CFrame.Angles(v8, v9, v10) + Vector3.new(v5, v6, v7), 18
end

@native local function decodeCFrameF32(buf: buffer, offset: number, _)
	local v5 = readf32(buf, offset)
	local v6 = readf32(buf, offset + 4)
	local v7 = readf32(buf, offset + 8)
	local v8 = readf32(buf, offset + 12)
	local v9 = readf32(buf, offset + 16)
	local v10 = readf32(buf, offset + 20)
	return CFrame.Angles(v8, v9, v10) + Vector3.new(v5, v6, v7), 24
end

@native local function encodeVector3FX8(buf: buffer, offset: number, _, vector3: Vector3): number
	writei8(buf, offset, vector3.X * 10)
	writei8(buf, offset + 1, vector3.Y * 10)
	writei8(buf, offset + 2, vector3.Z * 10)
	return 3
end

@native local function encodeVector3I16(buf: buffer, offset: number, _, vector3: Vector3): number
	writei16(buf, offset, vector3.X)
	writei16(buf, offset + 2, vector3.Y)
	writei16(buf, offset + 4, vector3.Z)
	return 6
end

@native local function decodeVector3I16(buf: buffer, offset: number, _)
	local v5 = readi16(buf, offset)
	local v6 = readi16(buf, offset + 2)
	local v7 = offset + 4
	return Vector3.new(v5, v6, (readi16(buf, v7))), 6
end

@native local function encodeVector3FX16(buf: buffer, offset: number, _, vector3: Vector3): number
	writei16(buf, offset, vector3.X * 100)
	writei16(buf, offset + 2, vector3.Y * 100)
	writei16(buf, offset + 4, vector3.Z * 100)
	return 6
end

@native local function encodeVector3F16(buf: buffer, offset: number, _, vector3: Vector3): number
	local v5 = vector3.X

	if v5 ~= 0 then
		local v6

		if v5 < 0 then
			v5 = -v5
			v6 = 1
		else
			v6 = 0
		end

		local v7, v8 = frexp(v5)
		local v9 = v8 + 14

		if v9 <= 0 then
			v5 = 0
		elseif v9 >= 31 then
			v5 = v6 * 32768 + 31744
		else
			local v10 = floor(v7 * 2048 - 1024 + 0.5)
			v5 = v6 * 32768 + v9 * 1024 + v10
		end
	end

	writeu16(buf, offset, v5)
	local v6 = offset + 2
	local v7 = vector3.Y

	if v7 ~= 0 then
		local v8

		if v7 < 0 then
			v7 = -v7
			v8 = 1
		else
			v8 = 0
		end

		local v9, v10 = frexp(v7)
		local v11 = v10 + 14

		if v11 <= 0 then
			v7 = 0
		elseif v11 >= 31 then
			v7 = v8 * 32768 + 31744
		else
			local v12 = floor(v9 * 2048 - 1024 + 0.5)
			v7 = v8 * 32768 + v11 * 1024 + v12
		end
	end

	writeu16(buf, v6, v7)
	local v8 = offset + 4
	local v9 = vector3.Z

	if v9 ~= 0 then
		local v10

		if v9 < 0 then
			v9 = -v9
			v10 = 1
		else
			v10 = 0
		end

		local v11, v12 = frexp(v9)
		local v13 = v12 + 14

		if v13 <= 0 then
			v9 = 0
		elseif v13 >= 31 then
			v9 = v10 * 32768 + 31744
		else
			local v14 = floor(v11 * 2048 - 1024 + 0.5)
			v9 = v10 * 32768 + v13 * 1024 + v14
		end
	end

	writeu16(buf, v8, v9)
	return 6
end

@native local function encodeVector3F32(buf: buffer, offset: number, _, vector3: Vector3): number
	writef32(buf, offset, vector3.X)
	writef32(buf, offset + 4, vector3.Y)
	writef32(buf, offset + 8, vector3.Z)
	return 12
end

@native local function decodeVector3FX8(buf: buffer, offset: number, _)
	local v5 = readi8(buf, offset) / 10
	local v6 = readi8(buf, offset + 1) / 10
	local v7 = offset + 2
	return Vector3.new(v5, v6, readi8(buf, v7) / 10), 3
end

@native local function decodeVector3FX16(buf: buffer, offset: number, _)
	local v5 = readi16(buf, offset) / 100
	local v6 = readi16(buf, offset + 2) / 100
	local v7 = offset + 4
	return Vector3.new(v5, v6, readi16(buf, v7) / 100), 6
end

@native local function decodeVector3F16(buf: buffer, offset: number, _)
	local v5 = decodeFloat16(readu16(buf, offset)) -- inferred equivalent call
	local v6 = decodeFloat16(readu16(buf, offset + 2)) -- inferred equivalent call
	local v7 = offset + 4
	return Vector3.new(v5, v6, decodeFloat16(readu16(buf, v7))), 6 -- inferred equivalent call
end

@native local function decodeVector3F32(buf: buffer, offset: number, _)
	local v5 = readf32(buf, offset)
	local v6 = readf32(buf, offset + 4)
	local v7 = offset + 8
	return Vector3.new(v5, v6, (readf32(buf, v7))), 12
end

@native local function encodeVector2FX8(buf: buffer, offset: number, _, vector2: Vector2): number
	writei8(buf, offset, vector2.X * 10)
	writei8(buf, offset + 1, vector2.Y * 10)
	return 2
end

@native local function encodeVector2I16(buf: buffer, offset: number, _, vector2: Vector2): number
	writei16(buf, offset, vector2.X)
	writei16(buf, offset + 2, vector2.Y)
	return 4
end

@native local function decodeVector2I16(buf: buffer, offset: number, _)
	return Vector2.new(readi16(buf, offset), (readi16(buf, offset + 2))), 4
end

@native local function encodeVector2FX16(buf: buffer, offset: number, _, vector2: Vector2): number
	writei16(buf, offset, vector2.X * 100)
	writei16(buf, offset + 2, vector2.Y * 100)
	return 4
end

@native local function encodeVector2F16(buf: buffer, offset: number, _, vector2: Vector2): number
	local v5 = vector2.X

	if v5 ~= 0 then
		local v6

		if v5 < 0 then
			v5 = -v5
			v6 = 1
		else
			v6 = 0
		end

		local v7, v8 = frexp(v5)
		local v9 = v8 + 14

		if v9 <= 0 then
			v5 = 0
		elseif v9 >= 31 then
			v5 = v6 * 32768 + 31744
		else
			local v10 = floor(v7 * 2048 - 1024 + 0.5)
			v5 = v6 * 32768 + v9 * 1024 + v10
		end
	end

	writeu16(buf, offset, v5)
	local v6 = offset + 2
	local v7 = vector2.Y

	if v7 ~= 0 then
		local v8

		if v7 < 0 then
			v7 = -v7
			v8 = 1
		else
			v8 = 0
		end

		local v9, v10 = frexp(v7)
		local v11 = v10 + 14

		if v11 <= 0 then
			v7 = 0
		elseif v11 >= 31 then
			v7 = v8 * 32768 + 31744
		else
			local v12 = floor(v9 * 2048 - 1024 + 0.5)
			v7 = v8 * 32768 + v11 * 1024 + v12
		end
	end

	writeu16(buf, v6, v7)
	return 4
end

@native local function encodeVector2F32(buf: buffer, offset: number, _, vector2: Vector2): number
	writef32(buf, offset, vector2.X)
	writef32(buf, offset + 4, vector2.Y)
	return 8
end

@native local function decodeVector2FX8(buf: buffer, offset: number, _)
	local v5 = readi8(buf, offset) / 10
	local v6 = readi8(buf, offset + 1) / 10
	return Vector2.new(v5, v6), 2
end

@native local function decodeVector2FX16(buf: buffer, offset: number, _)
	local v5 = readi16(buf, offset) / 100
	local v6 = readi16(buf, offset + 2) / 100
	return Vector2.new(v5, v6), 4
end

@native local function decodeVector2F16(buf: buffer, offset: number, _)
	local v5 = decodeFloat16(readu16(buf, offset)) -- inferred equivalent call
	local v6 = offset + 2
	return Vector2.new(v5, decodeFloat16(readu16(buf, v6))), 4 -- inferred equivalent call
end

@native local function decodeVector2F32(buf: buffer, offset: number, _)
	local v5 = readf32(buf, offset)
	local v6 = readf32(buf, offset + 4)
	return Vector2.new(v5, v6), 8
end

@native local function encodeString(buf: buffer, offset: number, _, str: string)
	local v5 = len(str)
	writeu8(buf, offset, v5)
	writestring(buf, offset + 1, str, v5)
	return v5 + 1
end

@native local function decodeString(buf: buffer, offset: number, _)
	local v5 = readu8(buf, offset)
	return readstring(buf, offset + 1, v5), v5 + 1
end

@native local function encodeStringLong(buf: buffer, offset: number, _, str: string)
	local v5 = len(str)
	writeu32(buf, offset, v5)
	writestring(buf, offset + 4, str, v5)
	return v5 + 4
end

@native local function decodeStringLong(buf: buffer, offset: number, _, _: string)
	local v5 = readu32(buf, offset)
	return readstring(buf, offset + 4, v5), v5 + 4
end

@native local function encodeColor(buf: buffer, offset: number, _, color: Color3): number
	writeu8(buf, offset, color.R * 255 + 0.5)
	writeu8(buf, offset + 1, color.G * 255 + 0.5)
	writeu8(buf, offset + 2, color.B * 255 + 0.5)
	return 3
end

@native local function decodeColor(buf: buffer, offset: number, _)
	local v5 = readu8(buf, offset)
	local v6 = readu8(buf, offset + 1)
	local v7 = readu8(buf, offset + 2)
	return Color3.fromRGB(v5, v6, v7), 3
end

@native local function encodeBrickColor(buf: buffer, offset: number, _, p): number
	writeu16(buf, offset, p.Number)
	return 2
end

@native local function decodeBrickColor(buf: buffer, offset: number, _)
	return BrickColor.new((readu16(buf, offset))), 2
end

@native local function encodeBool(buf: buffer, offset: number, _, flag: boolean): number
	writeu8(buf, offset, flag and 1 or 0)
	return 1
end

@native local function decodeBool(buf: buffer, offset: number, _): (boolean, number)
	return readu8(buf, offset) == 1, 1
end

@native local function encodeNil(_: buffer, _: number, _, _): number
	return 0
end

@native local function decodeNil(_: buffer, _: number, _): (nil, number)
	return nil, 0
end

@native local function encodeBuffer(buf: buffer, offset: number, _, buf2: buffer)
	local v5 = buffer.len(buf2)
	writeu16(buf, offset, v5)
	buffer.copy(buf, offset + 2, buf2, 0, v5)
	return v5 + 2
end

@native local function decodeBuffer(buf: buffer, offset: number, _)
	local v5 = readu16(buf, offset)
	local buf2 = buffer.create(v5)
	buffer.copy(buf2, 0, buf, offset + 2, v5)
	return buf2, v5 + 2
end

@native local function encodeDateTime32(buf: buffer, offset: number, _, p): number
	writeu32(buf, offset, p.UnixTimestamp)
	return 4
end

@native local function decodeDateTime32(buf: buffer, offset: number, _)
	return DateTime.fromUnixTimestamp((readu32(buf, offset))), 4
end

@native local function encodeDateTime64(buf: buffer, offset: number, _, p): number
	writef64(buf, offset, p.UnixTimestampMillis)
	return 8
end

@native local function decodeDateTime64(buf: buffer, offset: number, _)
	return DateTime.fromUnixTimestampMillis((readf64(buf, offset))), 8
end

local v5 = {
	Enum.EasingStyle.Linear,
	Enum.EasingStyle.Back,
	Enum.EasingStyle.Quad,
	Enum.EasingStyle.Bounce,
	Enum.EasingStyle.Sine,
	Enum.EasingStyle.Cubic,
	Enum.EasingStyle.Quart,
	Enum.EasingStyle.Quint,
	Enum.EasingStyle.Elastic,
	Enum.EasingStyle.Circular,
	Enum.EasingStyle.Exponential
}

local v6 = { Enum.EasingDirection.In, Enum.EasingDirection.Out, Enum.EasingDirection.InOut }

local function keyValueSwap(items) -- 2 equivalent calls inferred from this helper
	local result = {}

	for k, item in items do
		result[item] = k
	end

	return result
end

local result2 = keyValueSwap(v5) -- inferred equivalent call
local result3 = keyValueSwap(v6) -- inferred equivalent call

@native local function encodeTweenInfo(buf: buffer, offset: number, _, data): number
	local v7 = result2[data.EasingStyle]
	local v8 = result3[data.EasingDirection]
	local v9 = data.Reverses and 1 or 0
	local v10 = v7 + v8 * 16 + v9 * 128

	writeu16(buf, offset, data.Time * 100)
	writeu8(buf, offset + 2, v10)
	writei8(buf, offset + 3, data.RepeatCount)
	writeu16(buf, offset + 4, data.DelayTime * 100)
	return 6
end

@native local function decodeTweenInfo(buf: buffer, offset: number, _)
	local v7 = readu16(buf, offset) / 100
	local v8 = readu8(buf, offset + 2)
	local v9 = readi8(buf, offset + 3)
	local v10 = readu16(buf, offset + 4) / 100

	local v11 = v8 % 16
	local v12 = v8 // 16 % 8
	local v13 = v8 // 128 == 1

	return TweenInfo.new(v7, v5[v11], v6[v12], v9, v13, v10), 6
end

@native local function encodeColorSequence(buf: buffer, offset: number, _, sequence)
	local keypoints = sequence.Keypoints
	writeu8(buf, offset, #keypoints)
	local v7 = offset + 1

	for _, keypoint in keypoints do
		local value = keypoint.Value
		writeu8(buf, v7, keypoint.Time * 255 + 0.5)
		writeu8(buf, v7 + 1, value.R * 255 + 0.5)
		writeu8(buf, v7 + 2, value.G * 255 + 0.5)
		writeu8(buf, v7 + 3, value.B * 255 + 0.5)
		v7 += 4
	end

	return v7 - offset
end

@native local function decodeColorSequence(buf: buffer, offset: number, _)
	local v7 = readu8(buf, offset)
	local v8 = offset + 1
	local v9 = table.create(v7)

	for i = 1, v7 do
		v9[i] = ColorSequenceKeypoint.new(
			readu8(buf, v8) / 255,
			Color3.fromRGB(readu8(buf, v8 + 1), readu8(buf, v8 + 2), (readu8(buf, v8 + 3)))
		)

		v8 += 4
	end

	return ColorSequence.new(v9), v8 - offset
end

@native local function encodeNumberSequence(buf: buffer, offset: number, _, sequence)
	local keypoints = sequence.Keypoints
	writeu8(buf, offset, #keypoints)
	local v7 = offset + 1

	for _, keypoint in keypoints do
		writeu8(buf, v7, keypoint.Time * 255 + 0.5)
		writeu8(buf, v7 + 1, keypoint.Value * 255 + 0.5)
		writeu8(buf, v7 + 2, keypoint.Envelope * 255 + 0.5)
		v7 += 3
	end

	return v7 - offset
end

@native local function decodeNumberSequence(buf: buffer, offset: number, _)
	local v7 = readu8(buf, offset)
	local v8 = offset + 1
	local v9 = table.create(v7)

	for i = 1, v7 do
		v9[i] = NumberSequenceKeypoint.new(readu8(buf, v8) / 255, readu8(buf, v8 + 1) / 255, readu8(buf, v8 + 2) / 255)

		v8 += 3
	end

	return NumberSequence.new(v9), v8 - offset
end

@native local function encodeNumberRange(buf: buffer, offset: number, _, range: NumberRange): number
	writef32(buf, offset, range.Min)
	writef32(buf, offset + 4, range.Max)
	return 8
end

@native local function decodeNumberRange(buf: buffer, offset: number, _)
	return NumberRange.new(readf32(buf, offset), (readf32(buf, offset + 4))), 8
end

@native local function encodeUDim(buf: buffer, offset: number, _, udim: UDim): number
	writei16(buf, offset, udim.Scale * 1000)
	writei16(buf, offset + 2, udim.Offset)
	return 4
end

@native local function decodeUDim(buf: buffer, offset: number, _)
	return UDim.new(readi16(buf, offset) / 1000, (readi16(buf, offset + 2))), 4
end

@native local function encodeUDim2(buf: buffer, offset: number, _, udim: UDim2): number
	local x = udim.X
	local y = udim.Y
	writei16(buf, offset, x.Scale * 1000)
	writei16(buf, offset + 2, x.Offset)
	writei16(buf, offset + 4, y.Scale * 1000)
	writei16(buf, offset + 6, y.Offset)
	return 8
end

@native local function decodeUDim2(buf: buffer, offset: number, _)
	return
		UDim2.new(
			readi16(buf, offset) / 1000,
			readi16(buf, offset + 2),
			readi16(buf, offset + 4) / 1000,
			(readi16(buf, offset + 6))
		),
		8
end

@native local function encodeRegion3(buf: buffer, offset: number, _, instance): number
	local halfSize = instance.Size / 2
	local position = instance.CFrame.Position
	local v7 = position - halfSize
	local v8 = position + halfSize
	writef32(buf, offset, v7.X)
	writef32(buf, offset + 4, v7.Y)
	writef32(buf, offset + 8, v7.Z)
	writef32(buf, offset + 12, v8.X)
	writef32(buf, offset + 16, v8.Y)
	writef32(buf, offset + 20, v8.Z)
	return 24
end

@native local function decodeRegion3(buf: buffer, offset: number, _)
	local v7 = readf32(buf, offset)
	local v8 = readf32(buf, offset + 4)
	local v9 = offset + 8
	local vector3 = Vector3.new(v7, v8, (readf32(buf, v9)))

	local v10 = readf32(buf, offset + 12)
	local v11 = readf32(buf, offset + 16)
	local v12 = offset + 20
	return Region3.new(vector3, (Vector3.new(v10, v11, (readf32(buf, v12))))), 24
end

@native local function encodePhysicalProperties(buf: buffer, offset: number, _, data): number
	writeu16(buf, offset, data.Density * 655.35)
	writeu8(buf, offset + 2, data.Friction * 127.5)
	writeu8(buf, offset + 3, data.Elasticity * 255)
	writeu16(buf, offset + 4, data.FrictionWeight * 655.35)
	writeu16(buf, offset + 6, data.ElasticityWeight * 655.35)
	writeu8(buf, offset + 8, data.AcousticAbsorption * 255)
	return 9
end

@native local function decodePhysicalProperties(buf: buffer, offset: number, _)
	return
		PhysicalProperties.new(
			readu16(buf, offset) / 655.35,
			readu8(buf, offset + 2) / 127.5,
			readu8(buf, offset + 3) / 255,
			readu16(buf, offset + 4) / 655.35,
			readu16(buf, offset + 6) / 655.35,
			readu8(buf, offset + 8) / 255
		),
		9
end

@native local function encodeRect(buf: buffer, offset: number, _, rect: Rect): number
	local min = rect.Min
	local max = rect.Max
	writef32(buf, offset, min.X)
	writef32(buf, offset + 4, min.Y)
	writef32(buf, offset + 8, max.X)
	writef32(buf, offset + 12, max.Y)
	return 16
end

@native local function decodeRect(buf: buffer, offset: number, _)
	return
		Rect.new(readf32(buf, offset), readf32(buf, offset + 4), readf32(buf, offset + 8), (readf32(buf, offset + 12))),
		16
end

@native local function encodeBulkNumberU4Array(buf: buffer, p: number, list)
	local count = #list
	local v7 = count % 2
	local v8 = p
	local total = 1

	for _ = 1, (count - v7) / 2 do
		writeu8(buf, v8, list[total] + list[total + 1] * 16)
		v8 += 1
		total += 2
	end

	if v7 ~= 0 then
		writeu8(buf, v8, list[count])
	end

	return v8 - p
end

@native local function decodeBulkNumberU4Array(buf: buffer, p: number, p2: number, p3)
	local result = p3 or table.create(p2)
	local v7 = p2 % 2
	local v8 = p
	local total = 1

	for _ = 1, (p2 - v7) / 2 do
		local v9 = readu8(buf, v8)
		local v10 = v9 // 16
		result[total] = v9 - v10 * 16
		result[total + 1] = v10
		v8 += 1
		total += 2
	end

	if v7 ~= 0 then
		result[p2] = readu8(buf, v8)
	end

	return result, v8 - p
end

@native local function encodeBulkNumberU8Array(buf: buffer, p: number, items)
	local v7 = p

	for _, value in items do
		writeu8(buf, v7, value)
		v7 += 1
	end

	return v7 - p
end

@native local function decodeBulkNumberU8Array(buf: buffer, p: number, p2: number, p3)
	local result = p3 or table.create(p2)
	local v7 = p2 % 4
	local v8 = p
	local total = 1

	for _ = 1, (p2 - v7) / 4 do
		local v9 = readu32(buf, v8)
		local v10 = v9 // 256
		local v11 = v10 // 256
		local v12 = v11 // 256
		result[total] = v9 - v10 * 256
		result[total + 1] = v10 - v11 * 256
		result[total + 2] = v11 - v12 * 256
		result[total + 3] = v12
		v8 += 4
		total += 4
	end

	for i = p2 - v7 + 1, p2 do
		result[i] = readu8(buf, v8)
		v8 += 1
	end

	return result, v8 - p
end

@native local function encodeBulkNumberI32Array(buf: buffer, p: number, items)
	local v7 = p

	for _, value in items do
		writei32(buf, v7, value)
		v7 += 4
	end

	return v7 - p
end

@native local function decodeBulkNumberI32Array(buf: buffer, p: number, p2: number, p3)
	local result = p3 or table.create(p2)
	local v7 = p

	for i = 1, p2 do
		result[i] = readi32(buf, v7)
		v7 += 4
	end

	return result, v7 - p
end

@native local function encodeBulkNumberF32Array(buf: buffer, p: number, items)
	local v7 = p

	for _, value in items do
		writef32(buf, v7, value)
		v7 += 4
	end

	return v7 - p
end

@native local function decodeBulkNumberF32Array(buf: buffer, p: number, p2: number, p3)
	local result = p3 or table.create(p2)
	local v7 = p

	for i = 1, p2 do
		result[i] = readf32(buf, v7)
		v7 += 4
	end

	return result, v7 - p
end

@native local function encodeBulkBoolArray(buf: buffer, p: number, list)
	local count = #list
	local v7 = count % 8
	local v8 = p
	local total = 1

	for _ = 1, (count - v7) / 8 do
		writeu8(
			buf,
			v8,
			(list[total] and 1 or 0) + (list[total + 1] and 2 or 0) + (list[total + 2] and 4 or 0) + (list[total + 3] and 8 or 0) + (list[total + 4] and 16 or 0) + (list[total + 5] and 32 or 0) + (list[total + 6] and 64 or 0) + (list[total + 7] and 128 or 0)
		)

		total += 8
		v8 += 1
	end

	for i = count - v7 + 1, count do
		writeu8(buf, v8, list[i] and 1 or 0)
		v8 += 1
	end

	return v8 - p
end

local v7 = table.create(256)
local function buildByteToBools()
	for i = 0, 255 do
		local v8 = table.create(8)
		local v9 = i

		for j = 1, 8 do
			v8[j] = v9 % 2 == 1
			v9 //= 2
		end

		v7[i] = v8
	end
end

buildByteToBools()

@native local function decodeBulkBoolArray(buf: buffer, p: number, p2: number, p3)
	local result = p3 or table.create(p2)
	local v8 = p2 % 8
	local v9 = p
	local total = 1

	for _ = 1, (p2 - v8) / 8 do
		local v10 = readu8(buf, v9)
		v9 += 1

		local v11 = v7[v10]
		result[total] = v11[1]
		result[total + 1] = v11[2]
		result[total + 2] = v11[3]
		result[total + 3] = v11[4]
		result[total + 4] = v11[5]
		result[total + 5] = v11[6]
		result[total + 6] = v11[7]
		result[total + 7] = v11[8]

		total += 8
	end

	for i = p2 - v8 + 1, p2 do
		result[i] = readu8(buf, v9) == 1
		v9 += 1
	end

	return result, v9 - p
end

@native local function encodeBulkStringArray(buf: buffer, p: number, list)
	local v8 = p
	local total = 0

	for _, item in list do
		local v9 = len(item)
		writeu8(buf, v8, v9)
		v8 += 1
		total += v9
	end

	writestring(buf, v8, table.concat(list), total)
	return v8 + total - p
end

@native local function decodeBulkStringArray(buf: buffer, p: number, p2: number, p3)
	local tbl = getTable() -- inferred equivalent call
	local result = p3 or table.create(p2)
	local v8 = p
	local total = 0

	for i = 1, p2 do
		local v9 = readu8(buf, v8)
		tbl[i] = v9
		v8 += 1
		total += v9
	end

	local v9 = readstring(buf, v8, total)
	local v10 = 1

	for k, v11 in tbl do
		local v12 = v10 + v11
		result[k] = sub(v9, v10, v12 - 1)
		v10 = v12
	end

	recycleTable(tbl) -- inferred equivalent call
	return result, v8 + total - p
end

@native local function encodeBulkNumberU8DictStatic(buf: buffer, p: number, p2, items)
	local v8 = p

	for _, item in items do
		writeu8(buf, v8, p2[item])
		v8 += 1
	end

	return v8 - p
end

@native local function decodeBulkNumberU8DictStatic(buf: buffer, p: number, items, p2)
	local clone = table.clone(p2)
	local v8 = p

	for _, item in items do
		clone[item] = readu8(buf, v8)
		v8 += 1
	end

	return clone, v8 - p
end

@native local function encodeBulkNumberI32DictStatic(buf: buffer, p: number, p2, items)
	local v8 = p

	for _, item in items do
		writei32(buf, v8, p2[item])
		v8 += 4
	end

	return v8 - p
end

@native local function decodeBulkNumberI32DictStatic(buf: buffer, p: number, items, p2)
	local clone = table.clone(p2)
	local v8 = p

	for _, item in items do
		clone[item] = readi32(buf, v8)
		v8 += 4
	end

	return clone, v8 - p
end

@native local function encodeBulkNumberF32DictStatic(buf: buffer, p: number, p2, items)
	local v8 = p

	for _, item in items do
		writef32(buf, v8, p2[item])
		v8 += 4
	end

	return v8 - p
end

@native local function decodeBulkNumberF32DictStatic(buf: buffer, p: number, items, p2)
	local clone = table.clone(p2)
	local v8 = p

	for _, item in items do
		clone[item] = readf32(buf, v8)
		v8 += 4
	end

	return clone, v8 - p
end

@native local function encodeBulkBoolDictStatic(buf: buffer, p: number, p2, items)
	local v8 = p

	for _, item in items do
		writeu8(buf, v8, p2[item] and 1 or 0)
		v8 += 1
	end

	return v8 - p
end

@native local function decodeBulkBoolDictStatic(buf: buffer, p: number, items, p2)
	local clone = table.clone(p2)
	local v8 = p

	for _, item in items do
		clone[item] = readu8(buf, v8) == 1
		v8 += 1
	end

	return clone, v8 - p
end

@native local function encodeBulkStringDictStatic(buf: buffer, p: number, p2, items)
	local tbl = getTable() -- inferred equivalent call
	local v8 = p

	for k, item in items do
		local v9 = p2[item]
		writeu8(buf, v8, (len(v9)))
		v8 += 1
		tbl[k] = v9
	end

	local joined = table.concat(tbl)
	local v9 = len(joined)
	writestring(buf, v8, joined, v9)
	local v10 = v8 + v9
	recycleTable(tbl) -- inferred equivalent call
	return v10 - p
end

@native local function decodeBulkStringDictStatic(buf: buffer, p: number, list, p2)
	local count = #list

	local clone = table.clone(p2)
	local tbl = getTable() -- inferred equivalent call
	local v8 = p
	local total = 0
	local v9 = 1

	for i = 1, count do
		local v10 = readu8(buf, v8)
		tbl[i] = v10
		total += v10
		v8 += 1
	end

	local v10 = readstring(buf, p + count, total)

	for k, item in list do
		local v11 = v9 + tbl[k]
		clone[item] = sub(v10, v9, v11 - 1)
		v9 = v11
	end

	recycleTable(tbl) -- inferred equivalent call
	return clone, v9 - p
end

@native local function encodeBulkNumberU8Dict(buf: buffer, p: number, items, flag: boolean?)
	local v8 = nil
	local v9

	if flag then
		v9 = p

		for value, _ in items do
			writeu8(buf, v9, value)
			v9 += 1
		end

		v8 = v9 - p
	else
		v9 = p

		for _, value in items do
			writeu8(buf, v9, value)
			v9 += 1
		end
	end

	return v9 - p, v8
end

@native local function encodeBulkNumberI32Dict(buf: buffer, p: number, items, flag: boolean?)
	local v8 = nil
	local v9

	if flag then
		v9 = p

		for value, _ in items do
			writei32(buf, v9, value)
			v9 += 4
		end

		v8 = v9 - p
	else
		v9 = p

		for _, value in items do
			writei32(buf, v9, value)
			v9 += 4
		end
	end

	return v9 - p, v8
end

@native local function encodeBulkNumberF32Dict(buf: buffer, p: number, items, flag: boolean)
	local v8 = nil
	local v9

	if flag then
		v9 = p

		for value, _ in items do
			writef32(buf, v9, value)
			v9 += 4
		end

		v8 = (v9 - p) / 4
	else
		v9 = p

		for _, value in items do
			writef32(buf, v9, value)
			v9 += 4
		end
	end

	return v9 - p, v8
end

@native local function encodeBulkBoolDict(buf: buffer, p: number, items, flag: boolean?)
	local v8 = nil
	local v9

	if flag then
		v9 = p

		for k, _ in items do
			writeu8(buf, v9, k and 1 or 0)
			v9 += 1
		end

		v8 = v9 - p
	else
		v9 = p

		for _, item in items do
			writeu8(buf, v9, item and 1 or 0)
			v9 += 1
		end
	end

	return v9 - p, v8
end

@native local function encodeBulkStringDict(buf: buffer, p: number, items, flag: boolean?)
	local tbl = getTable() -- inferred equivalent call
	local v8 = nil
	local v9

	if flag then
		v9 = p
		v8 = 0

		for k, _ in items do
			writeu8(buf, v9, (len(k)))
			v9 += 1
			v8 += 1
			tbl[v8] = k
		end
	else
		v9 = p
		local count = 0

		for _, item in items do
			writeu8(buf, v9, (len(item)))
			v9 += 1
			count += 1
			tbl[count] = item
		end
	end

	local joined = table.concat(tbl)
	local v10 = len(joined)
	writestring(buf, v9, joined, v10)
	local v11 = v9 + v10
	recycleTable(tbl) -- inferred equivalent call
	return v11 - p, v8
end

local enumItems = {}
local enumItemsByEnum = {}
local encode = nil
local decode = nil

@native local function encodeEnumItem(buf: buffer, offset: number, _, p): number
	writeu16(buf, offset, enumItemsByEnum[p] or 0)
	return 2
end

@native local function decodeEnumItem(buf: buffer, offset: number, _)
	return enumItems[readu16(buf, offset)], 2
end

@native local function encodeInstance(_: buffer, _: number, _, p, list): number
	list[#list + 1] = p
	return 0
end

@native local function decodeInstance(_: buffer, _: number, _, p)
	local pointer = p.pointer
	p.pointer += 1
	return p[pointer], 0
end

@native local function encodePlayer(buf: buffer, offset: number, _, p): number
	local userId = p.UserId or 0
	writef64(buf, offset, userId)
	return 8
end

@native local function decodePlayer(buf: buffer, offset: number, _)
	return Players:GetPlayerByUserId((readf64(buf, offset))), 8
end

@native local function encodeAny(buf: buffer, offset: number, p, p2, p3)
	local dataType = getDataType(p2) -- inferred equivalent call
	writeu8(buf, offset, dataType)
	local v8 = 1
	return v8 + encode[dataType](buf, offset + v8, p, p2, p3)
end

@native local function decodeAny(buf: buffer, offset: number, p, p2)
	local v8 = readu8(buf, offset)

	local callback = decode[v8]

	if not callback then
		return nil, 1
	end

	local v9, v10 = callback(buf, offset + 1, p, p2)
	return v9, 1 + v10
end

@native local function encodeOptional(buf: buffer, offset: number, list, p, p2)
	local v8 = p == nil
	writeu8(buf, offset, v8 and 0 or 1)

	if v8 then
		return 1
	end

	local item = list[2]
	return (encode[item] or encode[item[1]])(buf, offset + 1, item, p, p2) + 1
end

@native local function decodeOptional(buf: buffer, offset: number, list, p)
	if readu8(buf, offset) == 0 then
		return nil, 1
	end

	local item = list[2]
	local v8, v9 = (decode[item] or decode[item[1]])(buf, offset + 1, item, p)
	return v8, v9 + 1
end

@native local function encodeUnion(buf: buffer, offset: number, p, p2, p3)
	local typeName = typeof(p2)
	local v8 = p[typeName]
	local v9 = if typeName == "table" or not v8 then v8[1] else v8
	writeu8(buf, offset, v9)

	return encode[v9](buf, offset + 1, v8, p2, p3) + 1
end

@native local function decodeUnion(buf: buffer, offset: number, p, p2)
	local v8 = readu8(buf, offset)
	local v9 = p[v8]
	local v10, v11 = decode[v8](buf, offset + 1, v9, p2)
	return v10, v11 + 1
end

@native local function encodeLiteral(buf: buffer, offset: number, list, p): number
	writeu8(buf, offset, list[3][p])
	return 1
end

@native local function decodeLiteral(buf: buffer, offset: number, list)
	return list[2][readu8(buf, offset)], 1
end

@native local function encodeArrayStatic(buf: buffer, p: number, list, p2, p3)
	local item = list[3]

	if item then
		return p + encode[item](buf, p, p2) - p
	end

	local v8 = p

	for k, v9 in list[2] do
		v8 += (encode[v9] or encode[v9[1]])(buf, v8, v9, p2[k], p3)
	end

	return v8 - p
end

@native local function decodeArrayStatic(buf: buffer, p: number, list, p2)
	local item = list[2]
	local item2 = list[3]

	if item2 then
		local v8, v9 = decode[item2](buf, p, #item)
		return v8, p + v9 - p
	end

	local v8 = p
	local result = {}

	for k, v9 in item do
		local v10, v11 = (decode[v9] or decode[v9[1]])(buf, v8, v9, p2)
		v8 += v11
		result[k] = v10
	end

	return result, v8 - p
end

@native local function encodeArray(buf: buffer, offset: number, list, list2, p)
	writeu16(buf, offset, #list2)
	local v8 = offset + 2

	local item = list[3]

	if item then
		return v8 + encode[item](buf, v8, list2) - offset
	end

	local item2 = list[2]
	local v9 = encode[item2] or encode[item2[1]]

	for _, item3 in list2 do
		v8 += v9(buf, v8, item2, item3, p)
	end

	return v8 - offset
end

@native local function decodeArray(buf: buffer, offset: number, list, p)
	local v8 = readu16(buf, offset)
	local v9 = offset + 2

	local item = list[3]

	if item then
		local v10, v11 = decode[item](buf, v9, v8)
		return v10, v9 + v11 - offset
	end

	local item2 = list[2]
	local v10 = decode[item2] or decode[item2[1]]

	local result = table.create(v8)

	for i = 1, v8 do
		local v11, v12 = v10(buf, v9, item2, p)
		v9 += v12
		result[i] = v11
	end

	return result, v9 - offset
end

@native local function encodeArrayDynamic(buf: buffer, offset: number, p, list, p2)
	local count = #list
	writeu16(buf, offset, count)
	local v8 = offset + 2

	for i = 1, count do
		local item = list[i]
		local dataType = getDataType(item) -- inferred equivalent call
		writeu8(buf, v8, dataType)
		local v9 = v8 + 1
		v8 = v9 + encode[dataType](buf, v9, p, item, p2)
	end

	return v8 - offset
end

@native local function decodeArrayDynamic(buf: buffer, offset: number, p, p2)
	local v8 = readu16(buf, offset)
	local v9 = offset + 2
	local result = table.create(v8)

	for i = 1, v8 do
		local v10 = readu8(buf, v9)
		v9 += 1
		local v11, v12 = (decode[v10] or decode[Enums.Nil])(buf, v9, p, p2)
		v9 += v12
		result[i] = v11
	end

	return result, v9 - offset
end

@native local function encodeDictStatic(buf: buffer, p: number, list, p2, p3)
	local item = list[2]
	local item2 = list[3]
	local item3 = list[5]

	if item3 then
		return p + encode[item3](buf, p, p2, item2) - p
	end

	local v8 = p
	local count = 0

	for _, v9 in item2 do
		count += 1
		local v10 = item[count]
		local v11 = p2[v9]
		v8 += (encode[v10] or encode[v10[1]])(buf, v8, v10, v11, p3)
	end

	return v8 - p
end

@native local function decodeDictStatic(buf: buffer, p: number, list, p2)
	local item = list[2]
	local item2 = list[3]
	local item3 = list[4]
	local item4 = list[5]

	if item4 then
		local v8, v9 = decode[item4](buf, p, item2, item3)
		return v8, p + v9 - p
	end

	local clone = table.clone(item3)
	local v8 = p

	for k, v9 in item do
		local v10, v11 = (decode[v9] or decode[v9[1]])(buf, v8, v9, p2)
		v8 += v11
		clone[item2[k]] = v10
	end

	return clone, v8 - p
end

@native local function encodeDict(buf: buffer, offset: number, list, items, p)
	local v8 = 0
	local v9 = offset + 2
	local item = list[4]
	local item2 = list[5]

	if item then
		local v10
		v10, v8 = encode[item](buf, v9, items, true)
		v9 += v10
	else
		local item3 = list[2]
		local v10 = encode[item3] or encode[item3[1]]

		for k, _ in items do
			v9 += v10(buf, v9, item3, k, p)
			v8 += 1
		end
	end

	if item2 then
		v9 += encode[item2](buf, v9, items)
	else
		local item3 = list[3]
		local v10 = encode[item3] or encode[item3[1]]

		for _, item4 in items do
			v9 += v10(buf, v9, item3, item4, p)
		end
	end

	writeu16(buf, offset, v8)
	return v9 - offset
end

local clones = {}

@native local function decodeDict(buf: buffer, offset: number, list, p)
	local v8 = readu16(buf, offset)
	local v9 = offset + 2
	local item = list[4]
	local item2 = list[5]
	local tbl = getTable() -- inferred equivalent call
	local tbl2 = getTable() -- inferred equivalent call

	if item then
		local v10
		tbl, v10 = decode[item](buf, v9, v8, tbl)
		v9 += v10
	else
		local item3 = list[2]
		local v10 = decode[item3] or decode[item3[1]]

		for i = 1, v8 do
			local v11, v12 = v10(buf, v9, item3, p)
			v9 += v12
			tbl[i] = v11
		end
	end

	if item2 then
		local v10
		tbl2, v10 = decode[item2](buf, v9, v8, tbl2)
		v9 += v10
	else
		local item3 = list[3]
		local v10 = decode[item3] or decode[item3[1]]

		for i = 1, v8 do
			local v11, v12 = v10(buf, v9, item3, p)
			v9 += v12
			tbl2[i] = v11
		end
	end

	local item3 = list[6]
	local v10 = clones[item3]
	local result

	if v10 then
		table.clear(v10)
		result = table.clone(v10)
	else
		result = {}
	end

	for k, v11 in tbl do
		result[v11] = tbl2[k]
	end

	recycleTable(tbl) -- inferred equivalent call
	recycleTable(tbl2) -- inferred equivalent call

	if not v10 then
		clones[item3] = table.clone(result)
	end

	return result, v9 - offset
end

@native local function encodeDictDynamic(buf: buffer, offset: number, p, items, p2)
	local v8 = offset + 2
	local count = 0

	for k, item in items do
		local dataType = getDataType(k) -- inferred equivalent call
		local callback = encode[dataType]
		writeu8(buf, v8, dataType)
		local v9 = v8 + 1
		local v10 = v9 + callback(buf, v9, p, k, p2)
		local dataType2 = getDataType(item) -- inferred equivalent call
		local callback2 = encode[dataType2]
		writeu8(buf, v10, dataType2)
		local v11 = v10 + 1
		v8 = v11 + callback2(buf, v11, p, item, p2)
		count += 1
	end

	writeu16(buf, offset, count)
	return v8 - offset
end

@native local function decodeDictDynamic(buf: buffer, offset: number, p, p2)
	local v8 = readu16(buf, offset)
	local v9 = offset + 2
	local result = {}

	for _ = 1, v8 do
		local v10 = readu8(buf, v9)
		v9 += 1
		local v11, v12 = (decode[v10] or decode[Enums.Nil])(buf, v9, p, p2)
		v9 += v12

		local v13 = readu8(buf, v9)
		v9 += 1
		local v14, v15 = (decode[v13] or decode[Enums.Nil])(buf, v9, p, p2)
		v9 += v15
		result[v11] = v14
	end

	return result, v9 - offset
end

encode = {
	[Enums.Start] = function() end,
	[Enums.NumberU4] = encodeNumberU8,
	[Enums.NumberU8] = encodeNumberU8,
	[Enums.NumberU16] = encodeNumberU16,
	[Enums.NumberU32] = encodeNumberU32,
	[Enums.NumberI8] = encodeNumberI8,
	[Enums.NumberI16] = encodeNumberI16,
	[Enums.NumberI32] = encodeNumberI32,
	[Enums.NumberF16] = encodeNumberF16,
	[Enums.NumberF32] = encodeNumberF32,
	[Enums.NumberF64] = encodeNumberF64,
	[Enums.CFrameFX8] = encodeCFrameFX8,
	[Enums.CFrameI16FX16] = encodeCFrameI16FX16,
	[Enums.CFrameFX16] = encodeCFrameFX16,
	[Enums.CFrameF16] = encodeCFrameF16,
	[Enums.CFrameF32Aligned] = encodeCFrameF32Aligned,
	[Enums.CFrameF32FX16] = encodeCFrameF32FX16,
	[Enums.CFrameF32] = encodeCFrameF32,
	[Enums.Vector3FX8] = encodeVector3FX8,
	[Enums.Vector3I16] = encodeVector3I16,
	[Enums.Vector3FX16] = encodeVector3FX16,
	[Enums.Vector3F16] = encodeVector3F16,
	[Enums.Vector3F32] = encodeVector3F32,
	[Enums.Vector2FX8] = encodeVector2FX8,
	[Enums.Vector2I16] = encodeVector2I16,
	[Enums.Vector2FX16] = encodeVector2FX16,
	[Enums.Vector2F16] = encodeVector2F16,
	[Enums.Vector2F32] = encodeVector2F32,
	[Enums.String] = encodeString,
	[Enums.StringLong] = encodeStringLong,
	[Enums.Color3] = encodeColor,
	[Enums.BrickColor] = encodeBrickColor,
	[Enums.Boolean] = encodeBool,
	[Enums.Nil] = encodeNil,
	[Enums.Buffer] = encodeBuffer,
	[Enums.EnumItem] = encodeEnumItem,
	[Enums.Instance] = encodeInstance,
	[Enums.Player] = encodePlayer,
	[Enums.DateTime32] = encodeDateTime32,
	[Enums.DateTime64] = encodeDateTime64,
	[Enums.TweenInfo] = encodeTweenInfo,
	[Enums.ColorSequence] = encodeColorSequence,
	[Enums.NumberSequence] = encodeNumberSequence,
	[Enums.NumberRange] = encodeNumberRange,
	[Enums.UDim] = encodeUDim,
	[Enums.UDim2] = encodeUDim2,
	[Enums.Region3] = encodeRegion3,
	[Enums.PhysicalProperties] = encodePhysicalProperties,
	[Enums.Rect] = encodeRect,
	[Enums.Any] = encodeAny,
	[Enums.Optional] = encodeOptional,
	[Enums.Union] = encodeUnion,
	[Enums.Literal] = encodeLiteral,
	[Enums.ArrayStatic] = encodeArrayStatic,
	[Enums.Array] = encodeArray,
	[Enums.ArrayDynamic] = encodeArrayDynamic,
	[Enums.DictStatic] = encodeDictStatic,
	[Enums.Dict] = encodeDict,
	[Enums.DictDynamic] = encodeDictDynamic,
	[Enums.FastNumberU4Array] = encodeBulkNumberU4Array,
	[Enums.FastNumberU8Array] = encodeBulkNumberU8Array,
	[Enums.FastNumberI32Array] = encodeBulkNumberI32Array,
	[Enums.FastNumberF32Array] = encodeBulkNumberF32Array,
	[Enums.FastBoolArray] = encodeBulkBoolArray,
	[Enums.FastStringArray] = encodeBulkStringArray,
	[Enums.FastNumberU8DictStatic] = encodeBulkNumberU8DictStatic,
	[Enums.FastNumberI32DictStatic] = encodeBulkNumberI32DictStatic,
	[Enums.FastNumberF32DictStatic] = encodeBulkNumberF32DictStatic,
	[Enums.FastBoolDictStatic] = encodeBulkBoolDictStatic,
	[Enums.FastStringDictStatic] = encodeBulkStringDictStatic,
	[Enums.FastNumberU8Dict] = encodeBulkNumberU8Dict,
	[Enums.FastNumberI32Dict] = encodeBulkNumberI32Dict,
	[Enums.FastNumberF32Dict] = encodeBulkNumberF32Dict,
	[Enums.FastBoolDict] = encodeBulkBoolDict,
	[Enums.FastStringDict] = encodeBulkStringDict
}

decode = {
	[Enums.Start] = function() end,
	[Enums.NumberU4] = decodeNumberU8,
	[Enums.NumberU8] = decodeNumberU8,
	[Enums.NumberU16] = decodeNumberU16,
	[Enums.NumberU32] = decodeNumberU32,
	[Enums.NumberI8] = decodeNumberI8,
	[Enums.NumberI16] = decodeNumberI16,
	[Enums.NumberI32] = decodeNumberI32,
	[Enums.NumberF16] = decodeNumberF16,
	[Enums.NumberF32] = decodeNumberF32,
	[Enums.NumberF64] = decodeNumberF64,
	[Enums.CFrameFX8] = decodeCFrameFX8,
	[Enums.CFrameI16FX16] = decodeCFrameI16FX16,
	[Enums.CFrameFX16] = decodeCFrameFX16,
	[Enums.CFrameF16] = decodeCFrameF16,
	[Enums.CFrameF32Aligned] = decodeCFrameF32Aligned,
	[Enums.CFrameF32FX16] = decodeCFrameF32FX16,
	[Enums.CFrameF32] = decodeCFrameF32,
	[Enums.Vector3FX8] = decodeVector3FX8,
	[Enums.Vector3I16] = decodeVector3I16,
	[Enums.Vector3FX16] = decodeVector3FX16,
	[Enums.Vector3F16] = decodeVector3F16,
	[Enums.Vector3F32] = decodeVector3F32,
	[Enums.Vector2FX8] = decodeVector2FX8,
	[Enums.Vector2I16] = decodeVector2I16,
	[Enums.Vector2FX16] = decodeVector2FX16,
	[Enums.Vector2F16] = decodeVector2F16,
	[Enums.Vector2F32] = decodeVector2F32,
	[Enums.String] = decodeString,
	[Enums.StringLong] = decodeStringLong,
	[Enums.Color3] = decodeColor,
	[Enums.BrickColor] = decodeBrickColor,
	[Enums.Boolean] = decodeBool,
	[Enums.Nil] = decodeNil,
	[Enums.Buffer] = decodeBuffer,
	[Enums.EnumItem] = decodeEnumItem,
	[Enums.Instance] = decodeInstance,
	[Enums.Player] = decodePlayer,
	[Enums.DateTime32] = decodeDateTime32,
	[Enums.DateTime64] = decodeDateTime64,
	[Enums.TweenInfo] = decodeTweenInfo,
	[Enums.ColorSequence] = decodeColorSequence,
	[Enums.NumberSequence] = decodeNumberSequence,
	[Enums.NumberRange] = decodeNumberRange,
	[Enums.UDim] = decodeUDim,
	[Enums.UDim2] = decodeUDim2,
	[Enums.Region3] = decodeRegion3,
	[Enums.PhysicalProperties] = decodePhysicalProperties,
	[Enums.Rect] = decodeRect,
	[Enums.Any] = decodeAny,
	[Enums.Optional] = decodeOptional,
	[Enums.Union] = decodeUnion,
	[Enums.Literal] = decodeLiteral,
	[Enums.ArrayStatic] = decodeArrayStatic,
	[Enums.Array] = decodeArray,
	[Enums.ArrayDynamic] = decodeArrayDynamic,
	[Enums.DictStatic] = decodeDictStatic,
	[Enums.Dict] = decodeDict,
	[Enums.DictDynamic] = decodeDictDynamic,
	[Enums.FastNumberU4Array] = decodeBulkNumberU4Array,
	[Enums.FastNumberU8Array] = decodeBulkNumberU8Array,
	[Enums.FastNumberI32Array] = decodeBulkNumberI32Array,
	[Enums.FastNumberF32Array] = decodeBulkNumberF32Array,
	[Enums.FastBoolArray] = decodeBulkBoolArray,
	[Enums.FastStringArray] = decodeBulkStringArray,
	[Enums.FastNumberU8DictStatic] = decodeBulkNumberU8DictStatic,
	[Enums.FastNumberI32DictStatic] = decodeBulkNumberI32DictStatic,
	[Enums.FastNumberF32DictStatic] = decodeBulkNumberF32DictStatic,
	[Enums.FastBoolDictStatic] = decodeBulkBoolDictStatic,
	[Enums.FastStringDictStatic] = decodeBulkStringDictStatic,
	[Enums.FastNumberU8Dict] = decodeBulkNumberU8Array,
	[Enums.FastNumberI32Dict] = decodeBulkNumberI32Array,
	[Enums.FastNumberF32Dict] = decodeBulkNumberF32Array,
	[Enums.FastBoolDict] = decodeBulkBoolArray,
	[Enums.FastStringDict] = decodeBulkStringArray
}

return {
	encode = encode,
	decode = decode,
	enumItems = enumItems,
	enumItemsByEnum = enumItemsByEnum
}