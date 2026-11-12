local CameraShakeUpdated = {}

local RunService = game:GetService("RunService")

local module = require("./src/Shared/Data")
local client = module.client

local v = {}

function CameraShakeUpdated.new(p: number, roughness: number, duration: number, positionInfluence: Vector3, rotationInfluence: Vector3, fadeOut: number)
	if not client.settings.screenshakeEnabled() then
		return
	end

	while #v >= 2 do
		table.remove(v, 1)
	end

	table.insert(v, {
		Magnitude = p,
		OriginalMagnitude = p,
		Roughness = roughness,
		Duration = duration,
		PositionInfluence = positionInfluence,
		RotationInfluence = rotationInfluence,
		FadeOut = fadeOut,
		StartTime = os.clock(),
		LastOffsetTime = 0,
		Offset = CFrame.identity,
		TargetOffset = CFrame.identity
	})
end

function CameraShakeUpdated._RandomizeOffset(p: number, vector3: Vector3, vector3_2: Vector3)
	local v2 = Vector3.new(math.random(-1, 1) * p, math.random(-1, 1) * p, math.random(-1, 1) * p) * vector3

	local v3 = Vector3.new(math.random(-1, 1) * p, math.random(-1, 1) * p, math.random(-1, 1) * p) * vector3_2

	return CFrame.new(v2) * CFrame.Angles(math.rad(v3.X), math.rad(v3.Y), (math.rad(v3.Z)))
end

RunService:BindToRenderStep("CameraShake", Enum.RenderPriority.Camera.Value + 1, function(p)
	local currentCamera = workspace.CurrentCamera

	if not currentCamera then
		return
	end

	local identity = CFrame.identity
	local now = os.clock()

	for i = #v, 1, -1 do
		local v2 = v[i]
		local v3 = now - v2.StartTime

		if v2.Duration <= v3 then
			table.remove(v, i)
		else
			if now - v2.LastOffsetTime >= v2.Roughness / 100 then
				v2.TargetOffset = CameraShakeUpdated._RandomizeOffset(
					v2.Magnitude,
					v2.PositionInfluence,
					v2.RotationInfluence
				)

				v2.LastOffsetTime = now
			end

			v2.Offset = v2.Offset:Lerp(v2.TargetOffset, (math.clamp(p * 30, 0, 1)))

			local v4 = 1 - v3 / v2.Duration
			identity *= v2.Offset:Lerp(CFrame.identity, 1 - v4)
		end
	end

	currentCamera.CFrame *= identity
end)

return CameraShakeUpdated