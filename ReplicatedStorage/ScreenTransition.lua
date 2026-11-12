local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local ScreenTransition = {}

local count = 0

local function getEffect()
	local portalTransitionColorCorrection = Lighting:FindFirstChild("PortalTransitionColorCorrection")

	if portalTransitionColorCorrection and portalTransitionColorCorrection:IsA("ColorCorrectionEffect") then
		return portalTransitionColorCorrection
	end

	local portalTransitionColorCorrection2 = Instance.new("ColorCorrectionEffect")
	portalTransitionColorCorrection2.Name = "PortalTransitionColorCorrection"
	portalTransitionColorCorrection2.Brightness = 0
	portalTransitionColorCorrection2.TintColor = Color3.new(1, 1, 1)
	portalTransitionColorCorrection2.Parent = Lighting

	return portalTransitionColorCorrection2
end

function ScreenTransition.tween(p, p2: number, duration: number, color: Color3?)
	if not p then
		return nil
	end

	count += 1
	local v = count

	local effect = getEffect()
	local tintColor, brightness

	if p2 <= 0 then
		tintColor = color or Color3.new(1, 1, 1)

		brightness = tintColor == Color3.new(0, 0, 0) and -1.15 or 1.15
	else
		tintColor = Color3.new(1, 1, 1)
		brightness = 0
	end

	local v2 = p2 <= 0 and Enum.EasingDirection.In or Enum.EasingDirection.Out

	local tween = TweenService:Create(effect, TweenInfo.new(duration, Enum.EasingStyle.Sine, v2), {
		Brightness = brightness,
		TintColor = tintColor
	})

	if p2 >= 1 then
		tween.Completed:Once(function(p3)
			if p3 == Enum.PlaybackState.Completed and count == v and effect.Parent == Lighting then
				effect:Destroy()
			end
		end)
	end

	tween:Play()
	return tween
end

function ScreenTransition.tweenForPlayer(instance, p: number, p2: number)
	return ScreenTransition.tween(instance:FindFirstChildOfClass("PlayerGui"), p, p2)
end

return ScreenTransition