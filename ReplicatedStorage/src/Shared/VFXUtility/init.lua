local VFXUtility = {}

local MultiTween = require(script.MultiTween)
VFXUtility.tween = MultiTween.Tween
VFXUtility.tweenProperties = MultiTween.TweenProperties

local RockModule = require(script.RockModule)
VFXUtility.explosion = RockModule.Explosion
VFXUtility.crater = RockModule.Crater
VFXUtility.craterRows = RockModule.CraterRows
VFXUtility.clearDebris = RockModule.ClearDebris

function VFXUtility.weld(p, part)
	local function getPart(instance) -- 2 equivalent calls inferred from this helper
		if instance:IsA("BasePart") then
			return instance
		end

		if instance:IsA("Model") and instance.PrimaryPart then
			return instance.PrimaryPart
		end

		return instance:FindFirstChildWhichIsA("BasePart", true)
	end

	p = getPart(p) -- inferred equivalent call
	part = getPart(part) -- inferred equivalent call

	if not (p and part) then
		return
	end

	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = p
	weldConstraint.Part1 = part
	weldConstraint.Parent = p
	return weldConstraint
end

function VFXUtility.tweakAttribute(instance, attributeName: string, p)
	local attribute = instance:GetAttribute(attributeName)

	if attribute ~= nil then
		return attribute
	end

	if p == nil then
		warn(`VFXUtility.tweak: No value found for "{attributeName}" and no default was provided`)
		return nil
	end

	instance:SetAttribute(attributeName, p)
	return p
end

function VFXUtility.attributeTweaker(p)
	return function(p2: string, p3)
		return VFXUtility.tweakAttribute(p, p2, p3)
	end
end

function VFXUtility.spawn(instance, position, value: number?)
	local clone = instance:Clone()
	clone:PivotTo(typeof(position) == "CFrame" and position or CFrame.new(position))
	clone.Parent = workspace
	task.delay(value or 1, function()
		if clone.Parent then
			clone:Destroy()
		end
	end)
	return clone
end

function VFXUtility.emit(folder)
	if not folder then
		warn("VFX trigger target not found!")
		return
	end

	for _, descendant in folder:GetDescendants() do
		if not (descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Sound")) then
			continue
		end

		task.spawn(function()
			if not descendant.Parent then
				return
			end

			local emitDelay = descendant:GetAttribute("EmitDelay") or 0
			local emitDuration = descendant:GetAttribute("EmitDuration")

			if emitDelay > 0 then
				task.wait(emitDelay)
			end

			if not descendant.Parent then
				return
			end

			if descendant:IsA("Sound") then
				descendant:Play()
			elseif descendant:IsA("ParticleEmitter") then
				local emitCount = descendant:GetAttribute("EmitCount")

				if emitDuration and emitDuration > 0 then
					descendant.Enabled = true
					task.wait(emitDuration)

					if descendant.Parent then
						descendant.Enabled = false
					end
				elseif emitCount and emitCount > 0 then
					descendant:Emit(emitCount)
				else
					descendant:Emit(1)
				end
			elseif descendant:IsA("Beam") then
				local clone = descendant:Clone()
				clone.Parent = descendant.Parent
				clone.Enabled = true
				task.wait(not (emitDuration and emitDuration > 0) and 0.03 or emitDuration)

				if clone and clone.Parent then
					clone:Destroy()
				end
			end
		end)
	end
end

return VFXUtility