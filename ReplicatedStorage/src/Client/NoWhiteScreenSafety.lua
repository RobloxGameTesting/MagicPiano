local Lighting = game:GetService("Lighting")

local now = nil
local v = nil
local v2 = nil
local v3 = false

task.spawn(function()
	while true do
		task.wait(1)

		local portalTransitionColorCorrection = Lighting:FindFirstChild("PortalTransitionColorCorrection")

		if portalTransitionColorCorrection and portalTransitionColorCorrection:IsA("ColorCorrectionEffect") then
			if portalTransitionColorCorrection ~= v2 then
				v2 = portalTransitionColorCorrection
				now = os.clock()
			end

			if math.abs(math.abs(portalTransitionColorCorrection.Brightness) - 1.15) < 0.01 then
				v = v or os.clock()
			else
				v = nil
			end

			if v and os.clock() - v >= 2 and not v3 then
				v3 = true
				warn("[NoWhiteScreenSafety] Fading out stuck portal effect")

				local TweenService = game:GetService("TweenService")
				local tween = TweenService:Create(
					portalTransitionColorCorrection,
					TweenInfo.new(0.83, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
					{ Brightness = 0, TintColor = Color3.new(1, 1, 1) }
				)

				tween:Play()
				tween.Completed:Once(function()
					if portalTransitionColorCorrection.Parent then
						portalTransitionColorCorrection:Destroy()
					end

					v3 = false
					v = nil
				end)
			end
		else
			now = nil
			v2 = nil
		end
	end
end)
return {}