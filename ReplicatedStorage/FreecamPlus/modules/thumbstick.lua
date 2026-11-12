game:GetService("Players")
game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local vector2 = Vector2.new(0, 0)

return {
	Create = function(state, parent, p, callback, callback2, callback3)
		if state.thumbstickFrame then
			state.thumbstickFrame:Destroy()
			state.thumbstickFrame = nil

			if state.onTouchMovedConn then
				state.onTouchMovedConn:Disconnect()
				state.onTouchMovedConn = nil
			end

			if state.onTouchEndedConn then
				state.onTouchEndedConn:Disconnect()
				state.onTouchEndedConn = nil
			end
		end

		local v = math.min(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) <= 500
		state.thumbstickSize = v and 110 or 120
		state.screenPos = v and UDim2.new(0, state.thumbstickSize / 2 - 10, 1, -state.thumbstickSize - 20)
			or UDim2.new(0, state.thumbstickSize / 2, 1, -state.thumbstickSize * 1.75)

		state.thumbstickFrame = Instance.new("Frame")
		state.thumbstickFrame.Name = "ThumbstickFrame"
		state.thumbstickFrame.Active = true
		state.thumbstickFrame.Visible = false
		state.thumbstickFrame.Size = UDim2.new(0, state.thumbstickSize, 0, state.thumbstickSize)
		state.thumbstickFrame.Position = state.screenPos
		state.thumbstickFrame.BackgroundTransparency = 1

		local outerImage = Instance.new("ImageLabel")
		outerImage.Name = "OuterImage"
		outerImage.Image = "rbxasset://textures/ui/TouchControlsSheet.png"
		outerImage.ImageRectOffset = Vector2.new()
		outerImage.ImageRectSize = Vector2.new(220, 220)
		outerImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
		outerImage.BackgroundTransparency = 1
		outerImage.Size = UDim2.new(0, state.thumbstickSize, 0, state.thumbstickSize)
		outerImage.Position = UDim2.new(0, 0, 0, 0)
		outerImage.Parent = state.thumbstickFrame

		state.stickImage = Instance.new("ImageLabel")
		state.stickImage.Name = "StickImage"
		state.stickImage.Image = "rbxasset://textures/ui/TouchControlsSheet.png"
		state.stickImage.ImageRectOffset = Vector2.new(220, 0)
		state.stickImage.ImageRectSize = Vector2.new(111, 111)
		state.stickImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
		state.stickImage.BackgroundTransparency = 1
		state.stickImage.Size = UDim2.new(0, state.thumbstickSize / 2, 0, state.thumbstickSize / 2)
		state.stickImage.Position = UDim2.new(
			0,
			state.thumbstickSize / 2 - state.thumbstickSize / 4,
			0,
			state.thumbstickSize / 2 - state.thumbstickSize / 4
		)
		state.stickImage.ZIndex = 2
		state.stickImage.Parent = state.thumbstickFrame

		state.stickImage.ImageTransparency = 0.75
		outerImage.ImageTransparency = 0.75

		if not p then
			state.stickImage.ImageTransparency = 1
			outerImage.ImageTransparency = 1
		end

		local vector2_2 = nil

		local function push(p2) -- 1 equivalent call inferred from this helper
			if p2 then
				callback2()
			else
				callback(state.moveVector)
			end
		end

		local function DoMove(direction: Vector2) -- 1 equivalent call inferred from this helper
			local v2 = direction / (state.thumbstickSize / 2)
			local magnitude = v2.Magnitude
			local moveVector

			if magnitude < 0.05 then
				moveVector = Vector3.new(0, 0, 0)
			else
				local v3 = v2.Unit * ((magnitude - 0.05) / 0.95)

				moveVector = Vector3.new(v3.X, 0, v3.Y)
			end

			state.direction = direction
			state.moveVector = moveVector
			push(false) -- inferred equivalent call
		end

		local function MoveStick(position: Vector3)
			local v2 = Vector2.new(position.X - vector2_2.X, position.Y - vector2_2.Y)
			local magnitude = v2.magnitude
			local v3 = state.thumbstickFrame.AbsoluteSize.X / 2

			if state.isFollowStick and v3 < magnitude then
				local _ = v2.unit * v3
			else
				local v4 = math.min(magnitude, v3)
				v2 = v2.unit * v4
			end

			state.stickImage.Position = UDim2.new(
				0,
				v2.X + state.stickImage.AbsoluteSize.X / 2,
				0,
				v2.Y + state.stickImage.AbsoluteSize.Y / 2
			)
		end

		state.thumbstickFrame.InputBegan:Connect(function(input)
			callback3(true)

			if
				state.moveTouchObject
				or input.UserInputType ~= Enum.UserInputType.Touch
				or input.UserInputState ~= Enum.UserInputState.Begin
			then
				return
			end

			state.moveTouchObject = input
			vector2_2 = Vector2.new(
				state.thumbstickFrame.AbsolutePosition.X + state.thumbstickFrame.AbsoluteSize.X / 2,
				state.thumbstickFrame.AbsolutePosition.Y + state.thumbstickFrame.AbsoluteSize.Y / 2
			)
			Vector2.new(input.Position.X - vector2_2.X, input.Position.Y - vector2_2.Y)
		end)

		state.onTouchMovedConn = UserInputService.TouchMoved:Connect(function(p2, _: boolean)
			if p2 == state.moveTouchObject then
				vector2_2 = Vector2.new(
					state.thumbstickFrame.AbsolutePosition.X + state.thumbstickFrame.AbsoluteSize.X / 2,
					state.thumbstickFrame.AbsolutePosition.Y + state.thumbstickFrame.AbsoluteSize.Y / 2
				)
				DoMove(Vector2.new(p2.Position.X - vector2_2.X, p2.Position.Y - vector2_2.Y)) -- inferred equivalent call

				MoveStick(p2.Position)
			end
		end)

		state.onTouchEndedConn = UserInputService.TouchEnded:Connect(function(otherPart, _)
			if otherPart == state.moveTouchObject then
				state.stickImage.Position = UDim2.new(
					0,
					state.thumbstickFrame.Size.X.Offset / 2 - state.thumbstickSize / 4,
					0,
					state.thumbstickFrame.Size.Y.Offset / 2 - state.thumbstickSize / 4
				)
				callback3(false)

				state.moveVector = Vector3.new(0, 0, 0)
				state.isJumping = false
				state.moveTouchObject = nil
				state.direction = vector2
				callback2()

				callback(Vector3.new(0, 0, 0))
			end
		end)

		state.thumbstickFrame.Parent = parent
		return state.thumbstickFrame
	end
}