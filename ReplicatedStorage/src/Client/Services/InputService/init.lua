local InputService = { CurrentContext = "" }

local ActionTemplate = script.ActionTemplate

local v = {}

local function getContext(name: string)
	if v[name] ~= nil then
		return v[name]
	end

	local inputContext = Instance.new("InputContext")
	inputContext.Enabled = name == "idle"
	inputContext.Name = name
	inputContext.Parent = script

	v[name] = { context = inputContext, keybinds = {} }

	return v[name]
end

local function getEmptyAction() -- 1 equivalent call inferred from this helper
	return ActionTemplate:Clone()
end

function InputService.GetAction(name3, name)
	local context = getContext(name3)

	local action = context.keybinds[name]

	if action ~= nil then
		return action
	end

	action = getEmptyAction() -- inferred equivalent call
	action.Name = name
	action.Parent = context.context

	for _, child in action:GetChildren() do
		local name2 = child.Name

		child:GetPropertyChangedSignal("KeyCode"):Connect(function()
			if child.KeyCode == Enum.KeyCode.Unknown then
				return
			end

			local v2

			if child.KeyCode.Name:find("Button") == nil and child.KeyCode.Name:find("DPad") == nil then
				v2 = false
			else
				v2 = child.KeyCode.Name:find("Mouse") == nil
			end

			if (name2 == "GamepadBinding") == v2 then
				for k, keybind in context.keybinds do
					if keybind ~= action and keybind[name2].KeyCode == child.KeyCode then
						warn(`Conflicting keybinds found for {name} and {k}.`)
					end
				end
			else
				child.KeyCode = Enum.KeyCode.Unknown
				warn("Invalid keybind provided. Gamepad bindings must only use gamepad buttons, and vice versa for keyboard.")
			end
		end)
	end

	context.keybinds[name] = action

	return action
end

function InputService.EnableContext(currentContext)
	for k, v2 in v do
		v2.context.Enabled = k == currentContext or k == "idle"
	end

	InputService.CurrentContext = currentContext
end

return InputService