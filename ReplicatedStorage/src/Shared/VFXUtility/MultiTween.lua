local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local isClient = RunService:IsClient()

local function connectToStepped(stepActiveTweens) -- 1 equivalent call inferred from this helper
	if isClient then
		return RunService.RenderStepped:Connect(stepActiveTweens)
	end

	return RunService.Heartbeat:Connect(stepActiveTweens)
end

local v = {
	Target = true,
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

local v2 = {}
local connection = nil

local function releaseTweenState(state) -- 5 equivalent calls inferred from this helper
	state.IsActive = false

	if state.DestroyingConnection then
		state.DestroyingConnection:Disconnect()
		state.DestroyingConnection = nil
	end

	local waitingThread = state.WaitingThread

	if waitingThread then
		state.WaitingThread = nil
		task.defer(waitingThread)
	end
end

local function warnTweenError(p)
	warn("[MultiTween.Tween] tween stopped due to error: " .. debug.traceback((tostring(p))))
end

local function stepActiveTweens(p: number)
	for i = #v2, 1, -1 do
		local v3 = v2[i]
		local v4 = not v3.IsActive

		if not v4 then
			v3.ElapsedTime += p

			local v5 = v3.ElapsedTime / v3.Duration
			local v6

			if v5 >= 1 then
				v6 = 1
				v5 = 1
			else
				v6 = TweenService:GetValue(v5, v3.EasingStyle, v3.EasingDirection)
			end

			if xpcall(v3.ApplyAlpha, warnTweenError, v6) then
				if v5 >= 1 then
					v4 = true
					releaseTweenState(v3) -- inferred equivalent call
				end
			else
				v4 = true
				releaseTweenState(v3) -- inferred equivalent call
			end
		end

		if not v4 then
			continue
		end

		local count = #v2
		v2[i] = v2[count]
		v2[count] = nil
	end

	if #v2 == 0 and connection then
		connection:Disconnect()
		connection = nil
	end
end

local function registerTweenState(p) -- 2 equivalent calls inferred from this helper
	v2[#v2 + 1] = p

	if not connection then
		connection = connectToStepped(stepActiveTweens) -- inferred equivalent call
	end
end

local function assertVec3Table(list, p: string) -- 2 equivalent calls inferred from this helper
	local v3 = type(list) == "table"
		and type(list[1]) == "number"
		and type(list[2]) == "number"
		and type(list[3]) == "number"
	assert(v3, ("[MultiTween.Tween] '%s' must be {x, y, z} or {1, 2, 3} numeric table"):format(p))
end

local function resolveVec3(value, p: string) -- 2 equivalent calls inferred from this helper
	if typeof(value) == "Vector3" then
		return value
	end

	if type(value) ~= "table" then
		error(("[MultiTween.Tween] '%s' must be a Vector3 or numeric table"):format(p))
		return
	end

	assertVec3Table(value, p) -- inferred equivalent call
	return (Vector3.new(value[1], value[2], value[3]))
end

local function collectBaseParts(part)
	local parts = {}

	if part:IsA("BasePart") then
		parts[1] = part
	end

	for _, part2 in ipairs(part:GetDescendants()) do
		if part2:IsA("BasePart") then
			parts[#parts + 1] = part2
		end
	end

	return parts
end

local v3 = {
	Vector2 = true,
	Vector3 = true,
	Color3 = true,
	CFrame = true,
	UDim2 = true
}

local function readProperty(p, p2: string)
	return p[p2]
end

local function matchesClasses(instance, classes): boolean
	if classes == nil then
		return true
	end

	for _, className in ipairs(classes) do
		if instance:IsA(className) then
			return true
		end
	end

	return false
end

local function mergeKeypointTimes(keypoints, keypoints2)
	local timeSet = {}
	local times = {}

	for _, list in ipairs({ keypoints, keypoints2 }) do
		for _, item in ipairs(list) do
			local time = item.Time

			if timeSet[time] then
				continue
			end

			timeSet[time] = true
			times[#times + 1] = time
		end
	end

	table.sort(times)
	assert(#times <= 20, "[MultiTween.TweenProperties] merging the two sequences would exceed 20 keypoints")

	return times
end

local function sampleNumberKeypoints(keypoints, p: number)
	local item = keypoints[1]

	if p <= item.Time then
		return item.Value, item.Envelope
	end

	for i = 2, #keypoints do
		local item2 = keypoints[i]

		if p <= item2.Time then
			local item3 = keypoints[i - 1]
			local v4 = item2.Time - item3.Time
			local v5 = not (v4 > 0) and 1 or (p - item3.Time) / v4
			return
				item3.Value + (item2.Value - item3.Value) * v5,
				item3.Envelope + (item2.Envelope - item3.Envelope) * v5
		end
	end

	local item2 = keypoints[#keypoints]
	return item2.Value, item2.Envelope
end

local function sampleColorKeypoints(keypoints, p: number)
	local item = keypoints[1]

	if p <= item.Time then
		return item.Value
	end

	for i = 2, #keypoints do
		local item2 = keypoints[i]

		if p <= item2.Time then
			local item3 = keypoints[i - 1]
			local v4 = item2.Time - item3.Time
			local v5 = not (v4 > 0) and 1 or (p - item3.Time) / v4
			return item3.Value:Lerp(item2.Value, v5)
		end
	end

	return keypoints[#keypoints].Value
end

local function buildNumberSequence(times, list, list2)
	local numberSequenceKeypoints = {}

	for i = 1, #times do
		numberSequenceKeypoints[i] = NumberSequenceKeypoint.new(times[i], list[i], list2[i])
	end

	return NumberSequence.new(numberSequenceKeypoints)
end

local function buildColorSequence(times, list)
	local colorSequenceKeypoints = {}

	for i = 1, #times do
		colorSequenceKeypoints[i] = ColorSequenceKeypoint.new(times[i], list[i])
	end

	return ColorSequence.new(colorSequenceKeypoints)
end

local function createNumberSequenceInterpolator(sequence, value)
	local keypoints = sequence.Keypoints
	local times = {}
	local v4 = {}
	local v5 = {}
	local v6 = {}
	local v7 = {}

	if type(value) == "number" then
		for i, keypoint in ipairs(keypoints) do
			times[i] = keypoint.Time
			v4[i] = keypoint.Value
			v5[i] = keypoint.Envelope
			v6[i] = value
			v7[i] = keypoint.Envelope
		end
	else
		if typeof(value) ~= "NumberSequence" then
			return nil, nil
		end

		local keypoints2 = value.Keypoints
		times = mergeKeypointTimes(keypoints, keypoints2)

		for i, v8 in ipairs(times) do
			local v9, v10 = sampleNumberKeypoints(keypoints, v8)
			v4[i] = v9
			v5[i] = v10
			local v11, v12 = sampleNumberKeypoints(keypoints2, v8)
			v6[i] = v11
			v7[i] = v12
		end
	end

	local count = #times

	local function interpolate(p: number)
		local numberSequenceKeypoints = {}

		for i = 1, count do
			numberSequenceKeypoints[i] = NumberSequenceKeypoint.new(
				times[i],
				v4[i] + (v6[i] - v4[i]) * p,
				v5[i] + (v7[i] - v5[i]) * p
			)
		end

		return NumberSequence.new(numberSequenceKeypoints)
	end

	return interpolate, buildNumberSequence(times, v6, v7)
end

local function createColorSequenceInterpolator(sequence, sequence2)
	local keypoints = sequence.Keypoints
	local times = {}
	local v4 = {}
	local v5 = {}

	if typeof(sequence2) == "Color3" then
		for i, keypoint in ipairs(keypoints) do
			times[i] = keypoint.Time
			v4[i] = keypoint.Value
			v5[i] = sequence2
		end
	else
		if typeof(sequence2) ~= "ColorSequence" then
			return nil, nil
		end

		local keypoints2 = sequence2.Keypoints
		times = mergeKeypointTimes(keypoints, keypoints2)

		for i, v6 in ipairs(times) do
			v4[i] = sampleColorKeypoints(keypoints, v6)
			v5[i] = sampleColorKeypoints(keypoints2, v6)
		end
	end

	local count = #times

	local function interpolate(p: number)
		local colorSequenceKeypoints = {}

		for i = 1, count do
			colorSequenceKeypoints[i] = ColorSequenceKeypoint.new(times[i], v4[i]:Lerp(v5[i], p))
		end

		return ColorSequence.new(colorSequenceKeypoints)
	end

	return interpolate, buildColorSequence(times, v5)
end

local function createNumberRangeInterpolator(range: NumberRange, value)
	local v4

	if type(value) == "number" then
		v4 = value
	else
		if typeof(value) ~= "NumberRange" then
			return nil, nil
		end

		v4 = value.Min
		value = value.Max
	end

	local min = range.Min
	local max = range.Max

	local function interpolate(p: number)
		return NumberRange.new(min + (v4 - min) * p, max + (value - max) * p)
	end

	return interpolate, NumberRange.new(v4, value)
end

local function createInterpolator(result, property)
	local typeName = typeof(result)

	if typeName == "number" then
		if type(property) ~= "number" then
			return nil, nil
		end

		local function interpolateNumber(p: number)
			return result + (property - result) * p
		end

		return interpolateNumber, property
	elseif v3[typeName] then
		if typeof(property) ~= typeName then
			return nil, nil
		end

		local function interpolateLerpable(p: number)
			return result:Lerp(property, p)
		end

		return interpolateLerpable, property
	else
		if typeName == "NumberSequence" then
			return createNumberSequenceInterpolator(result, property)
		elseif typeName == "ColorSequence" then
			return createColorSequenceInterpolator(result, property)
		elseif typeName == "NumberRange" then
			return createNumberRangeInterpolator(result, property)
		end

		return nil, nil
	end
end

local MultiTween = {}

function MultiTween.Tween(instance)
	assert(type(instance) == "table", "[MultiTween.Tween] config must be a table")

	local target = instance.Target

	local v4 = typeof(target) == "Instance" and target:IsA("PVInstance")
	assert(v4, "[MultiTween.Tween] 'Target' must be a Model or BasePart")

	if instance.CFrame ~= nil and instance.Position ~= nil then
		error("[MultiTween.Tween] Supply 'CFrame' or 'Position', not both")
	end

	local duration = instance.Duration or 1
	assert(duration > 0, "[MultiTween.Tween] 'Duration' must be a positive number")

	local waitTweenEnd = instance.WaitTweenEnd or false
	local easingStyle = instance.EasingStyle or Enum.EasingStyle.Sine
	local easingDirection = instance.EasingDirection or Enum.EasingDirection.Out

	local scale = instance.Scale
	local v5 = scale ~= nil
	local v6 = Vector3.new(1, 1, 1)

	if scale ~= nil then
		if type(scale) == "number" then
			assert(scale > 0, "[MultiTween.Tween] 'Scale' number must be positive")
			v6 = Vector3.new(scale, scale, scale)
		elseif type(scale) == "table" then
			assertVec3Table(scale, "Scale") -- inferred equivalent call
			v6 = Vector3.new(scale[1], scale[2], scale[3])
		else
			error("[MultiTween.Tween] 'Scale' must be a positive number or {x, y, z} table")
		end
	end

	local vector3

	if instance.Rotation == nil then
		vector3 = nil
	else
		local vec3 = resolveVec3(instance.Rotation, "Rotation") -- inferred equivalent call
		vector3 = Vector3.new(math.rad(vec3.X), math.rad(vec3.Y), (math.rad(vec3.Z)))
	end

	local offset

	if instance.Offset == nil then
		offset = nil
	else
		offset = instance.Offset
		offset = resolveVec3(offset, "Offset") -- inferred equivalent call
	end

	local pivot = target:GetPivot()

	local v7 = nil
	local cframe = instance.CFrame
	local position = instance.Position

	if cframe == nil then
		if position ~= nil then
			v7 = CFrame.new(resolveVec3(position, "Position")) * pivot.Rotation
		end
	elseif typeof(cframe) == "CFrame" then
		v7 = cframe
	else
		v7 = CFrame.new(resolveVec3(cframe, "CFrame")) * pivot.Rotation
	end

	local v8 = {}

	for k, v9 in pairs(instance) do
		if not v[k] then
			v8[k] = v9
		end
	end

	local v9 = next(v8) ~= nil
	local v10 = v5 or vector3 ~= nil or offset ~= nil or v7 ~= nil
	local v11 = {
		IsActive = true,
		ElapsedTime = 0,
		Duration = duration,
		EasingStyle = easingStyle,
		EasingDirection = easingDirection,
		ApplyAlpha = nil,
		WaitingThread = nil,
		DestroyingConnection = nil
	}
	local v12

	if v5 or v9 then
		v12 = collectBaseParts(target)
		assert(#v12 > 0, "[MultiTween.Tween] 'Target' contains no BaseParts to animate")
	else
		v12 = {}
	end

	local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)

	local v13 = {}

	if v9 then
		for i = 1, #v12 do
			v13[i] = TweenService:Create(v12[i], tweenInfo, v8)
		end
	end

	if not v10 and #v13 == 0 then
		v11.IsActive = false
		return {
			Stop = function() end,
			IsRunning = function(): boolean
				return false
			end
		}
	end

	local function stopTween()
		if not v11.IsActive then
			return
		end

		for _, v14 in ipairs(v13) do
			v14:Cancel()
		end

		releaseTweenState(v11) -- inferred equivalent call
	end

	v11.DestroyingConnection = target.Destroying:Connect(stopTween)

	if v10 then
		local v14 = {}
		local count = #v12

		if v5 then
			for i = 1, count do
				local part = v12[i]
				local objectSpace = pivot:ToObjectSpace(part.CFrame)
				v14[i] = {
					Part = part,
					Size = part.Size,
					RelativePosition = objectSpace.Position,
					RelativeRotation = objectSpace.Rotation
				}
			end
		end

		local function computePivot(p: number)
			local pivot2

			if v7 then
				pivot2 = pivot:Lerp(v7, p)
			elseif offset then
				pivot2 = pivot * CFrame.new(offset * p)
			else
				pivot2 = pivot
			end

			if vector3 then
				pivot2 *= CFrame.Angles(vector3.X * p, vector3.Y * p, vector3.Z * p)
			end

			return pivot2
		end

		if v5 then
			function v11.ApplyAlpha(p: number)
				local v15 = computePivot(p)
				local lerped = (Vector3.new(1, 1, 1)):Lerp(v6, p)

				for i = 1, count do
					local v16 = v14[i]
					local part = v16.Part

					if not part.Parent then
						continue
					end

					part.Size = v16.Size * lerped
					part.CFrame = v15 * CFrame.new(v16.RelativePosition * lerped) * v16.RelativeRotation
				end
			end
		else
			function v11.ApplyAlpha(p: number)
				target:PivotTo(computePivot(p))
			end
		end

		registerTweenState(v11) -- inferred equivalent call

		for _, v15 in ipairs(v13) do
			v15:Play()
		end
	else
		v13[1].Completed:Once(function()
			releaseTweenState(v11) -- inferred equivalent call
		end)

		for _, v14 in ipairs(v13) do
			v14:Play()
		end
	end

	if waitTweenEnd and v11.IsActive then
		v11.WaitingThread = coroutine.running()
		coroutine.yield()
	end

	return {
		Stop = stopTween,
		IsRunning = function()
			return v11.IsActive
		end
	}
end

function MultiTween.TweenProperties(data)
	assert(type(data) == "table", "[MultiTween.TweenProperties] config must be a table")

	local target = data.Target
	assert(typeof(target) == "Instance", "[MultiTween.TweenProperties] 'Target' must be an Instance")

	local properties = data.Properties
	assert(type(properties) == "table", "[MultiTween.TweenProperties] 'Properties' must be a table")

	local duration = data.Duration or 1
	assert(duration > 0, "[MultiTween.TweenProperties] 'Duration' must be a positive number")

	local waitTweenEnd = data.WaitTweenEnd or false
	local easingStyle = data.EasingStyle or Enum.EasingStyle.Sine
	local easingDirection = data.EasingDirection or Enum.EasingDirection.Out
	local classes = data.Classes

	local descendants = { target }

	if data.IncludeDescendants ~= false then
		for _, descendant in ipairs(target:GetDescendants()) do
			descendants[#descendants + 1] = descendant
		end
	end

	local v4 = {}

	for k, property in pairs(properties) do
		local count = 0

		for _, targetInstance in ipairs(descendants) do
			if not matchesClasses(targetInstance, classes) then
				continue
			end

			local success, result = pcall(readProperty, targetInstance, k)

			if not success then
				continue
			end

			local interpolator, finalValue = createInterpolator(result, property)

			if interpolator == nil then
				continue
			end

			v4[#v4 + 1] = {
				TargetInstance = targetInstance,
				PropertyName = k,
				Interpolate = interpolator,
				FinalValue = finalValue
			}

			count += 1
		end

		if count == 0 then
			warn(("[MultiTween.TweenProperties] '%s' matched nothing (unknown property, unsupported type, or goal type doesn't fit)"):format((tostring(k))))
		end
	end

	local count = #v4

	if count == 0 then
		return {
			Stop = function() end,
			IsRunning = function(): boolean
				return false
			end
		}
	end

	local function applyAlpha(p: number)
		local v5 = p == 1

		for i = 1, count do
			local v6 = v4[i]
			local v7

			if v5 then
				v7 = v6.FinalValue
			else
				v7 = v6.Interpolate(p)
			end

			v6.TargetInstance[v6.PropertyName] = v7
		end
	end

	local v5 = {
		IsActive = true,
		ElapsedTime = 0,
		Duration = duration,
		EasingStyle = easingStyle,
		EasingDirection = easingDirection,
		ApplyAlpha = applyAlpha,
		WaitingThread = nil,
		DestroyingConnection = nil
	}

	local function stopTween()
		if v5.IsActive then
			releaseTweenState(v5) -- inferred equivalent call
		end
	end

	v5.DestroyingConnection = target.Destroying:Connect(stopTween)
	registerTweenState(v5) -- inferred equivalent call

	if waitTweenEnd then
		v5.WaitingThread = coroutine.running()
		coroutine.yield()
	end

	return {
		Stop = stopTween,
		IsRunning = function()
			return v5.IsActive
		end
	}
end

return MultiTween