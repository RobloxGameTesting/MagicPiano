local SocialInteractions = script:FindFirstAncestor("SocialInteractions")

local RunService = game:GetService("RunService")

local Otter = require(SocialInteractions.Packages.Otter)
local Constants = require(SocialInteractions.Constants)
local config = require(SocialInteractions.config)

local BODY_ORIENTATION_ATTRIBUTE = Constants.BODY_ORIENTATION_ATTRIBUTE

local UpdateBodyOrientation = SocialInteractions.UpdateBodyOrientation

local OrientableBody = {}
OrientableBody.__index = OrientableBody

local function waitForDescendantWhichIsA(folder, p: string, className: string)
	for _, descendant in ipairs(folder:GetDescendants()) do
		if descendant.Name == p and descendant:IsA(className) then
			return descendant
		end
	end

	local v

	repeat
		v = folder.DescendantAdded:Wait()
	until v.Name == p and v:IsA(className)

	return v
end

function OrientableBody.new(character)
	local class = {}
	setmetatable(class, OrientableBody)

	class.character = character

	task.spawn(function()
		class.neck = waitForDescendantWhichIsA(character, "Neck", "Motor6D")
		class.waist = waitForDescendantWhichIsA(character, "Waist", "Motor6D")
	end)

	class.motor = Otter.createGroupMotor({ horizontalAngle = 0, verticalAngle = 0 })

	class.motor:onStep(function(p)
		local waistOrientationWeight = config.getValues().waistOrientationWeight
		local v = 1 - waistOrientationWeight
		class:applyAngle(class.neck, p.horizontalAngle * v, p.verticalAngle * v)
		class:applyAngle(
			class.waist,
			p.horizontalAngle * waistOrientationWeight,
			p.verticalAngle * waistOrientationWeight
		)
	end)

	return class
end

function OrientableBody:applyAngle(p, p2, p3)
	if not p then
		return
	end

	local cframe = CFrame.Angles(0, p2, 0)
	local cframe2 = CFrame.Angles(p3, 0, 0)
	p.C0 = CFrame.new(p.C0.Position) * cframe * cframe2
end

function OrientableBody:face(vector3: Vector3)
	local humanoid = self.character and self.character:FindFirstChild("Humanoid")

	if not (humanoid and humanoid.RootPart) then
		return nil
	end

	local pointToObjectSpace = humanoid.RootPart.CFrame:PointToObjectSpace(humanoid.RootPart.Position + vector3)

	local v = math.asin(pointToObjectSpace.Y)
	local v2

	if v < Constants.OFFSET_Y and -Constants.OFFSET_Y < v then
		v2 = 0
	elseif v > 0 then
		v2 = v - Constants.OFFSET_Y
	else
		v2 = v + Constants.OFFSET_Y
	end

	local v3 = math.atan2(-pointToObjectSpace.X, -pointToObjectSpace.Z)

	if v3 > 1.5707963267948966 then
		v3 = 3.141592653589793 - v3
	elseif v3 < -1.5707963267948966 then
		v3 = -3.141592653589793 - v3
	end

	self.motor:setGoal({ horizontalAngle = Otter.spring(v3), verticalAngle = Otter.spring(v2) })

	return Vector2.new(v3, v2)
end

function OrientableBody:useCameraAsSource()
	local v = 0
	self.renderStepConnection = RunService.RenderStepped:Connect(function(dt)
		local currentCamera = workspace.CurrentCamera

		if not currentCamera then
			return
		end

		local face = self:face(currentCamera.CFrame.LookVector)

		v += dt

		if v > Constants.SYNC_INTERVAL and face then
			v %= Constants.SYNC_INTERVAL
			UpdateBodyOrientation:FireServer(face)
		end
	end)
end

function OrientableBody:orientFromAttribute()
	local attribute = self.character:GetAttribute(BODY_ORIENTATION_ATTRIBUTE)

	if attribute then
		self.motor:setGoal({
			horizontalAngle = Otter.spring(attribute.X),
			verticalAngle = Otter.spring(attribute.Y)
		})
	end
end

function OrientableBody:useAttributeAsSource()
	self:orientFromAttribute()
	self.attributeConnection = self.character:GetAttributeChangedSignal(BODY_ORIENTATION_ATTRIBUTE):Connect(function()
		self:orientFromAttribute()
	end)
end

function OrientableBody:destroy()
	if self.attributeConnection then
		self.attributeConnection:Disconnect()
		self.attributeConnection = nil
	end

	if self.renderStepConnection then
		self.renderStepConnection:Disconnect()
		self.renderStepConnection = nil
	end

	self.motor:setGoal({ horizontalAngle = Otter.spring(0), verticalAngle = Otter.spring(0) })

	self.motor:onComplete(function()
		if self.motor then
			self.motor:destroy()
			self.motor = nil
		end
	end)
end

return OrientableBody