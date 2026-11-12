local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PianoVFX = require(ReplicatedStorage.src.Shared.PianoVFX)

local v = { Idle = "Idle", Playing = "Playing", Holding = "Holding" }
return {
	Init = function(instance)
		local parent = instance.Parent

		if not parent then
			return
		end

		local v2 = "Idle"
		local animator = nil
		local track = nil
		local v3 = nil
		local v4 = 0

		local connections = {}
		local connections2 = {}

		local function disconnectConnections(connections3) -- 3 equivalent calls inferred from this helper
			for _, connection in ipairs(connections3) do
				connection:Disconnect()
			end

			table.clear(connections3)
		end

		local function stopAnim()
			v2 = "Idle"

			if track then
				track:Stop(0.2)
			end
		end

		local function resetAnim() -- 4 equivalent calls inferred from this helper
			v2 = v.Idle

			if track then
				track:Stop(0.2)
			end

			disconnectConnections(connections) -- inferred equivalent call
			disconnectConnections(connections2) -- inferred equivalent call
			track = nil
			v3 = nil
			animator = nil
		end

		local function bindHumanoid(parent2)
			disconnectConnections(connections2) -- inferred equivalent call
			table.insert(connections2, parent2.Died:Connect(function()
				resetAnim() -- inferred equivalent call
			end))

			table.insert(connections2, parent2.AncestryChanged:Connect(function(_, parent3)
				if not parent3 then
					resetAnim() -- inferred equivalent call
				end
			end))
		end

		local function loadAnim(occupant)
			resetAnim() -- inferred equivalent call
			v3 = occupant

			animator = occupant:FindFirstChildOfClass("Animator") or Instance.new("Animator")
			animator.Parent = occupant

			local pianoBufferedAnimation = Instance.new("Animation")
			pianoBufferedAnimation.Name = "PianoBufferedAnimation"
			pianoBufferedAnimation.AnimationId = "rbxassetid://" .. (occupant.RigType == Enum.HumanoidRigType.R15 and 82644670816191 or 93038381318687)

			track = animator:LoadAnimation(pianoBufferedAnimation)
			track.Looped = true

			bindHumanoid(occupant)

			local function onHold()
				if v2 == "Playing" then
					v2 = "Holding"
					track:AdjustSpeed(0)
				else
					v2 = v.Idle

					if track then
						track:Stop(0.2)
					end
				end
			end

			table.insert(connections, track:GetMarkerReachedSignal("Right"):Connect(onHold))

			table.insert(connections, track:GetMarkerReachedSignal("Left"):Connect(onHold))

			pianoBufferedAnimation:Destroy()
		end

		local function ensureAnim() -- 1 equivalent call inferred from this helper
			local occupant = instance.Occupant

			if not occupant then
				return
			end

			if not track or occupant ~= v3 then
				loadAnim(occupant)
			end
		end

		local function startPlaying()
			v2 = "Playing"

			if not track.IsPlaying then
				track:Play()
			end

			track:AdjustSpeed(5)
		end

		local function resumeFromHold()
			if not track or v2 ~= "Holding" then
				return
			end

			v2 = "Playing"
			track:AdjustSpeed(5)
		end

		local occupantChangedConnection = instance:GetPropertyChangedSignal("Occupant"):Connect(resetAnim)

		local connection = PianoVFX.OnClient(parent, "Pressed", function(_, _)
			if instance.Occupant then
				local now = os.clock()

				if now - v4 < 0.1 then
					return
				end

				v4 = now
				ensureAnim() -- inferred equivalent call

				if not track then
					return
				end

				if v2 == "Idle" then
					v2 = v.Playing

					if not track.IsPlaying then
						track:Play()
					end

					track:AdjustSpeed(5)
				elseif v2 == "Holding" and track then
					if v2 ~= v.Holding then
						return
					end

					v2 = v.Playing
					track:AdjustSpeed(5)
				end
			else
				v2 = v.Idle

				if track then
					track:Stop(0.2)
				end
			end
		end)

		return function()
			occupantChangedConnection:Disconnect()

			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			end

			resetAnim() -- inferred equivalent call
		end
	end
}