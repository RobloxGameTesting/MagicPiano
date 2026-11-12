local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Reference = {}
Reference.objectName = "TopbarPlusReference"

function Reference.addToReplicatedStorage()
	if ReplicatedStorage:FindFirstChild(Reference.objectName) then
		return false
	end

	local objectValue = Instance.new("ObjectValue")
	objectValue.Name = Reference.objectName
	objectValue.Value = script.Parent
	objectValue.Parent = ReplicatedStorage
	return objectValue
end

function Reference.getObject()
	return ReplicatedStorage:FindFirstChild(Reference.objectName) or false
end

return Reference