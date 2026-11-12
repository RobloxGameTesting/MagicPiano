local LagDetector = {}
LagDetector.isLaggy = false
local v = {}
function LagDetector.OnChanged(p)
	table.insert(v, p)
end

function LagDetector.Start()
	local RunService = game:GetService("RunService")

	local total = 0
	local count = 0
	local total2 = 0
	local total3 = 0

	RunService.PreRender:Connect(function(dt)
		total += dt
		count += 1

		if total < 1 then
			return
		end

		local v2 = count / total

		if LagDetector.isLaggy then
			if v2 >= 35 then
				total3 += total
			else
				total3 = 0
			end

			if total3 >= 5 then
				LagDetector.isLaggy = false
				total3 = 0

				for _, v3 in v do
					v3(false)
				end
			end
		else
			if v2 < 25 then
				total2 += total
			else
				total2 = 0
			end

			if total2 >= 5 then
				LagDetector.isLaggy = true
				total2 = 0

				for _, v3 in v do
					v3(true)
				end
			end
		end

		total = 0
		count = 0
	end)
end

return LagDetector