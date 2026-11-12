local Enums = require(script.Parent.Enums)
local EnumsToNativeTypes = require(script.Parent.EnumsToNativeTypes)
require(script.Parent.Types)

local function keyValueSwap(items) -- 2 equivalent calls inferred from this helper
	local result = {}

	for k, item in items do
		result[item] = k
	end

	return result
end

local result = keyValueSwap(Enums) -- inferred equivalent call
local v = {
	Array = {
		[Enums.NumberU4] = Enums.FastNumberU4Array,
		[Enums.NumberU8] = Enums.FastNumberU8Array,
		[Enums.NumberI32] = Enums.FastNumberI32Array,
		[Enums.NumberF32] = Enums.FastNumberF32Array,
		[Enums.Boolean] = Enums.FastBoolArray,
		[Enums.String] = Enums.FastStringArray
	},
	DictStatic = {
		[Enums.NumberU4] = Enums.FastNumberU8DictStatic,
		[Enums.NumberU8] = Enums.FastNumberU8DictStatic,
		[Enums.NumberI32] = Enums.FastNumberI32DictStatic,
		[Enums.NumberF32] = Enums.FastNumberF32DictStatic,
		[Enums.Boolean] = Enums.FastBoolDictStatic,
		[Enums.String] = Enums.FastStringDictStatic
	},
	Dict = {
		[Enums.NumberU4] = Enums.FastNumberU8Dict,
		[Enums.NumberU8] = Enums.FastNumberU8Dict,
		[Enums.NumberI32] = Enums.FastNumberI32Dict,
		[Enums.NumberF32] = Enums.FastNumberF32Dict,
		[Enums.Boolean] = Enums.FastBoolDict,
		[Enums.String] = Enums.FastStringDict
	}
}

local function checkSameTypes(list)
	local v2 = list[1]

	for _, item in list do
		if item ~= v2 then
			return false, v2
		end

		v2 = item
	end

	return true, v2
end

local function arrayStatic(list) -- 1 equivalent call inferred from this helper
	local v2 = list[1]
	local v3 = true

	for _, item in list do
		if item == v2 then
			v2 = item
		else
			v3 = false
			break
		end
	end

	return { Enums.ArrayStatic, list, v3 and v.Array[v2] or nil }
end

local function array(list) -- 1 equivalent call inferred from this helper
	local item = list[1]
	return { Enums.Array, item, v.Array[item] }
end

local function arrayDynamic() -- 1 equivalent call inferred from this helper
	return { Enums.ArrayDynamic }
end

local v2 = 1

local function getDictId() -- 1 equivalent call inferred from this helper
	local dictId = v2
	v2 += 1
	return dictId
end

local function dictStatic(items)
	local v3 = {}

	for k, _ in items do
		table.insert(v3, k)
	end

	table.sort(v3, function(a, b): boolean
		local typeName = type(a)
		local typeName2 = type(b)

		if typeName == typeName2 then
			return a < b
		end

		return typeName < typeName2
	end)

	local v4 = {}
	local v5 = {}

	for k, v6 in v3 do
		v4[k] = items[v6]
		v5[v6] = 123
	end

	local v6 = v4[1]
	local v7 = true

	for _, v8 in v4 do
		if v8 == v6 then
			v6 = v8
		else
			v7 = false
			break
		end
	end

	return {
		Enums.DictStatic,
		v4,
		v3,
		v5,
		v7 and v.DictStatic[v6] or nil
	}
end

local function dict(items)
	local v3, v4 = next(items)
	local v5 = v.Dict[v3]
	local v6 = v.Dict[v4]

	return { Enums.Dict, v3, v4, v5, v6, (getDictId()) } -- inferred equivalent call
end

local function dictDynamic() -- 1 equivalent call inferred from this helper
	return { Enums.DictDynamic }
end

local function parseUnion(tbl, unions)
	if type(tbl) == "table" then
		local v3 = tbl[1]

		if v3 == Enums.Optional then
			error("[QuickNet] optional type cannot be unioned", 2)
		elseif v3 == Enums.Any then
			error("[QuickNet] Any type cannot be unioned", 2)
		elseif v3 == Enums.Literal then
			error("[QuickNet] literal types cannot be unioned", 2)
		else
			unions.table = tbl
		end
	else
		local enumsToNativeType = EnumsToNativeTypes[tbl]

		if not enumsToNativeType then
			error("[QuickNet] invalid union type", 2)
		elseif unions[enumsToNativeType] == nil then
			unions[enumsToNativeType] = tbl
		else
			error("[QuickNet] cannot union multiple types of the same native type", 2)
		end
	end
end

local function processSchema(list)
	if type(list) == "table" then
		local item = list[1]

		if item == Enums.Literal then
			return list
		end

		if item == Enums.Optional then
			list[2] = processSchema(list[2])
			return list
		end

		if item == Enums.Union then
			local v3 = {}

			for k, item2 in list do
				if type(k) ~= "string" then
					continue
				end

				local v4 = processSchema(item2)
				list[k] = v4

				local v5 = if type(v4) == "table" then v4[1] else v4

				v3[v5] = v4
			end

			for k, v4 in v3 do
				list[k] = v4
			end

			return list
		else
			local count = 0
			local flag = true
			local v3 = nil

			for k, _ in list do
				count += 1

				if k ~= count then
					flag = false
				end
			end

			local v4, _ = next(list)
			local v5

			if count == 1 then
				v5 = v4 == 1
			else
				v5 = false
			end

			local v6 = not v5 and count == 1
			local v7 = not flag and count > 1

			if v5 then
				local v8 = array(list) -- inferred equivalent call
				local v9 = v8[2]

				if v9 == Enums.Any then
					return arrayDynamic() -- inferred equivalent call
				end

				v8[2] = processSchema(v9)
				return v8
			elseif flag then
				local v8 = arrayStatic(list) -- inferred equivalent call
				local v9 = {}

				for k, v10 in v8[2] do
					v9[k] = processSchema(v10)
				end

				v8[2] = v9
				return v8
			elseif v6 then
				local v8 = dict(list)
				local v9 = v8[2]
				local v10 = v8[3]

				if v9 == Enums.Any and v10 == Enums.Any then
					return dictDynamic() -- inferred equivalent call
				end

				v8[2] = processSchema(v9)
				v8[3] = processSchema(v10)
				return v8
			else
				if not v7 then
					error("[QuickNet] invalid schema", 2)

					return v3
				end

				local v8 = dictStatic(list)
				local v9 = v8[2]

				for k, v10 in v9 do
					v9[k] = processSchema(v10)
				end

				return v8
			end
		end
	else
		if not result[list] then
			error("[QuickNet] invalid data type", 2)
		end

		return list
	end
end

local Parser = {}

function Parser.getSchema(...)
	local schema = { ... }

	for k, v3 in schema do
		schema[k] = processSchema(v3)
	end

	return schema
end

function Parser.optional(p)
	return { Enums.Optional, p }
end

function Parser.union(tbl, tbl2)
	local unions = {}
	parseUnion(tbl, unions)
	parseUnion(tbl2, unions)
	unions[1] = Enums.Union
	return unions
end

function Parser.unionMany(...)
	local unions = {}

	for _, v3 in { ... } do
		parseUnion(v3, unions)
	end

	unions[1] = Enums.Union
	return unions
end

function Parser.literal(...)
	local v3 = { ... }

	for _, v4 in v3 do
		local typeName = typeof(v4)

		if typeName ~= "string" and typeName ~= "number" and typeName ~= "boolean" and typeName ~= "Vector3" then
			error("[QuickNet]" .. " unsupported literal type: " .. typeName, 2)
			return
		end
	end

	local result2 = keyValueSwap(v3) -- inferred equivalent call
	return { Enums.Literal, v3, result2 }
end

return Parser