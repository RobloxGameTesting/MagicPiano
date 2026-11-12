local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local renderStepped = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat

local identity = CFrame.identity
local newCFrame = CFrame.new
local Angles = CFrame.Angles
local rad = math.rad

local function assertVec3Table(list, p) -- 2 equivalent calls inferred from this helper
	local v = type(list) == "table"
		and type(list[1]) == "number"
		and type(list[2]) == "number"
		and type(list[3]) == "number"
	assert(v, ("[MultiTween.TweenModel] '%s' must be {x, y, z} or {1, 2, 3} numeric table"):format(p))
end

local function resolveVec3(value, p) -- 3 equivalent calls inferred from this helper
	if typeof(value) == "Vector3" then
		return value
	end

	if type(value) ~= "table" then
		error(("[MultiTween.TweenModel] '%s' must be a Vector3 or numeric table"):format(p))
		return
	end

	assertVec3Table(value, p) -- inferred equivalent call
	return (Vector3.new(value[1], value[2], value[3]))
end

return {
	TweenModel = function(instance)
		assert(type(instance) == "table", "[MultiTween.TweenModel] config must be a table")

		local model = instance.Model

		local v = typeof(model) == "Instance" and (model:IsA("Model") or model:IsA("BasePart"))
		assert(v, "[MultiTween.TweenModel] 'Model' must be a Model or BasePart")

		if instance.CFrame ~= nil and instance.Position ~= nil then
			error("[MultiTween.TweenModel] Supply 'CFrame' or 'Position', not both")
		end

		local duration = instance.Duration or 1
		local v2 = type(duration) == "number" and duration > 0
		assert(v2, "[MultiTween.TweenModel] 'Duration' must be a positive number")

		local v3 = instance.WaitTweenEnd

		if v3 == nil then
			v3 = false
		end

		assert(type(v3) == "boolean", "[MultiTween.TweenModel] 'WaitTweenEnd' must be a boolean")

		local easingStyle = instance.EasingStyle or Enum.EasingStyle.Sine

		local v4 = typeof(easingStyle) == "EnumItem" and easingStyle.EnumType == Enum.EasingStyle
		assert(v4, "[MultiTween.TweenModel] 'EasingStyle' must be an Enum.EasingStyle")

		local easingDirection = instance.EasingDirection or Enum.EasingDirection.Out

		local v5 = typeof(easingDirection) == "EnumItem" and easingDirection.EnumType == Enum.EasingDirection
		assert(v5, "[MultiTween.TweenModel] 'EasingDirection' must be an Enum.EasingDirection")

		local v6 = instance.Scale ~= nil
		local v7 = Vector3.new(1, 1, 1)

		if v6 then
			local scale = instance.Scale

			if type(scale) == "number" then
				assert(scale > 0, "[MultiTween.TweenModel] 'Scale' number must be positive")

				v7 = Vector3.new(scale, scale, scale)
			elseif type(scale) == "table" then
				assertVec3Table(scale, "Scale") -- inferred equivalent call
				v7 = Vector3.new(scale[1], scale[2], scale[3])
			else
				error("[MultiTween.TweenModel] 'Scale' must be a positive number or {x, y, z} table")
			end
		end

		local rotation

		if instance.Rotation == nil then
			rotation = nil
		else
			assert(
				typeof(instance.Rotation) == "Vector3" or type(instance.Rotation) == "table",
				"[MultiTween.TweenModel] 'Rotation' must be a Vector3 or numeric table"
			)

			rotation = instance.Rotation
			rotation = resolveVec3(rotation, "Rotation") -- inferred equivalent call
		end

		local offset

		if instance.Offset == nil then
			offset = nil
		else
			assert(
				typeof(instance.Offset) == "Vector3" or type(instance.Offset) == "table",
				"[MultiTween.TweenModel] 'Offset' must be a Vector3 or numeric table"
			)

			offset = instance.Offset
			offset = resolveVec3(offset, "Offset") -- inferred equivalent call
		end

		local position

		if instance.Position ~= nil then
			assert(
				typeof(instance.Position) == "Vector3" or type(instance.Position) == "table",
				"[MultiTween.TweenModel] 'Position' must be a Vector3 or numeric table"
			)

			position = instance.Position
			position = resolveVec3(position, "Position") -- inferred equivalent call
		end

		local cframe = model:IsA("BasePart") and model.CFrame or model:GetPivot()

		local v8 = nil

		if instance.CFrame == nil then
			if position then
				v8 = newCFrame(position) * cframe.Rotation
			end
		else
			v8 = instance.CFrame
			assert(
				typeof(v8) == "CFrame" or typeof(v8) == "Vector3" or type(v8) == "table",
				"[MultiTween.TweenModel] 'CFrame' must be a CFrame, Vector3, or numeric table"
			)

			if typeof(v8) ~= "CFrame" then
				v8 = newCFrame(resolveVec3(v8, "CFrame")) * cframe.Rotation
			end
		end

		local v9 = {}

		if model:IsA("BasePart") then
			v9[1] = model
		end

		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				v9[#v9 + 1] = part
			end
		end

		local count = #v9
		assert(count > 0, "[MultiTween.TweenModel] 'Model' contains no BaseParts to animate")

		local v10 = table.create(count)

		for i = 1, count do
			local part = v9[i]
			local objectSpace = cframe:ToObjectSpace(part.CFrame)
			v10[i] = {
				part = part,
				size = part.Size,
				relPos = objectSpace.Position,
				rotOnly = objectSpace - objectSpace.Position
			}
		end

		local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)

		local numberValue = Instance.new("NumberValue")
		local tween = TweenService:Create(numberValue, tweenInfo, { Value = 1 })

		local v11 = {
			Model = true,
			Duration = true,
			Scale = true,
			Rotation = true,
			Offset = true,
			Position = true,
			CFrame = true,
			WaitTweenEnd = true,
			EasingStyle = true,
			EasingDirection = true
		}

		local v12 = {}

		for k, v13 in pairs(instance) do
			if not v11[k] then
				v12[k] = v13
			end
		end

		local v13 = table.create(count)

		for i = 1, count do
			local v14 = v10[i]
			local v15 = {}

			for k, v16 in pairs(v12) do
				v15[k] = v16
			end

			if v6 then
				v15.Size = v14.size * v7
			end

			if next(v15) then
				v13[#v13 + 1] = TweenService:Create(v14.part, tweenInfo, v15)
			end
		end

		local flag = true
		local flag2 = false

		local function cleanup()
			if flag2 then
				return
			end

			flag2 = true
			flag = false

			tween:Cancel()

			for i = 1, #v13 do
				v13[i]:Cancel()
			end

			if numberValue.Parent == nil then
				pcall(function()
					numberValue:Destroy()
				end)
			else
				numberValue:Destroy()
			end
		end

		local function runLoop()
			tween:Play()

			for i = 1, #v13 do
				v13[i]:Play()
			end

			while flag do
				local value = numberValue.Value

				local v14 = v6 and (Vector3.new(1, 1, 1)):Lerp(v7, value) or Vector3.new(1, 1, 1)
				local v15

				if v8 then
					v15 = cframe:Lerp(v8, value)
				else
					v15 = cframe * (offset and newCFrame(offset * value) or identity)
				end

				if rotation then
					v15 *= Angles(rad(rotation.X * value), rad(rotation.Y * value), (rad(rotation.Z * value)))
				end

				for i = 1, count do
					local v16 = v10[i]
					local part = v16.part

					if part.Parent then
						part.CFrame = v15 * newCFrame(v16.relPos * v14) * v16.rotOnly
					end
				end

				if value >= 1 then
					break
				end

				renderStepped:Wait()
			end

			cleanup()
		end

		if rotation ~= nil or offset ~= nil or v8 ~= nil or v6 then
			if v3 then
				runLoop()
			else
				task.spawn(runLoop)
			end
		else
			tween.Completed:Connect(cleanup)
			tween:Play()

			for i = 1, #v13 do
				v13[i]:Play()
			end
		end

		return {
			Stop = cleanup,
			IsRunning = function()
				return flag and not flag2
			end
		}
	end
}