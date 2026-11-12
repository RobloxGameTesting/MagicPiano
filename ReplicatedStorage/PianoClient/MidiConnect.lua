local v = {
	[Enum.KeyCode.KeypadZero.Value] = 0,
	[Enum.KeyCode.KeypadOne.Value] = 1,
	[Enum.KeyCode.KeypadTwo.Value] = 2,
	[Enum.KeyCode.KeypadThree.Value] = 3,
	[Enum.KeyCode.KeypadFour.Value] = 4,
	[Enum.KeyCode.KeypadFive.Value] = 5,
	[Enum.KeyCode.KeypadSix.Value] = 6,
	[Enum.KeyCode.KeypadSeven.Value] = 7,
	[Enum.KeyCode.KeypadEight.Value] = 8,
	[Enum.KeyCode.KeypadNine.Value] = 9,
	[Enum.KeyCode.KeypadMinus.Value] = 10,
	[Enum.KeyCode.KeypadPlus.Value] = 11
}

local value = Enum.KeyCode.KeypadMultiply.Value

local v2 = false
local v3 = {}

local v4 = nil
local v5 = nil
local v6 = nil
local MidiConnect = {}

function MidiConnect.init(p, p2, p3)
	v4 = p
	v5 = p2
	v6 = p3
end

function MidiConnect.processInput(p): boolean
	if p == value then
		v2 = true
		table.clear(v3)
		return true
	else
		if not v2 then
			return false
		end

		local v7 = v[p]

		if v7 == nil then
			v2 = false
			table.clear(v3)
			return false
		else
			table.insert(v3, v7)

			if #v3 < 4 then
				return true
			end

			v2 = false

			local v8 = v3[1]
			local v9 = v3[2]
			local v10 = v3[3]
			local v11 = v3[4]

			local v12 = v8 * 12 + v9
			local v13 = v10 * 12 + v11

			if v12 == 143 then
				if v6 then
					v6(v13 >= 64)
				end

				return true
			else
				local v14 = v12 - 35

				if v13 == 0 then
					if v5 then
						v5(v14)
					end
				elseif v4 then
					v4(v14, v13)
				end

				return true
			end
		end
	end
end

return MidiConnect