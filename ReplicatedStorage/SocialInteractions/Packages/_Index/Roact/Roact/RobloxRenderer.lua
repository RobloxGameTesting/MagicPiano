local Binding = require(script.Parent.Binding)
local Children = require(script.Parent.PropMarkers.Children)
local ElementKind = require(script.Parent.ElementKind)
local SingleEventManager = require(script.Parent.SingleEventManager)
local getDefaultInstanceProperty = require(script.Parent.getDefaultInstanceProperty)
local Ref = require(script.Parent.PropMarkers.Ref)
local Type = require(script.Parent.Type)
local internalAssert = require(script.Parent.internalAssert)

local GlobalConfig = require(script.Parent.GlobalConfig)
local v = GlobalConfig.get()

local function identity(...)
	return ...
end

local function applyRef(callback, p)
	if callback == nil then
		return
	end

	if typeof(callback) == "function" then
		callback(p)
	elseif Type.of(callback) == Type.Binding then
		Binding.update(callback, p)
	else
		error(("Invalid ref: Expected type Binding but got %s"):format((typeof(callback))))
	end
end

local function setRobloxInstanceProperty(hostObject, p, p2) -- 2 equivalent calls inferred from this helper
	if p2 == nil then
		local _
		_, p2 = getDefaultInstanceProperty(hostObject.ClassName, p)
	end

	hostObject[p] = p2
end

local function removeBinding(state, p) -- 1 equivalent call inferred from this helper
	state.bindings[p]()
	state.bindings[p] = nil
end

local function attachBinding(state, p, object)
	local function updateBoundProperty(p2)
		local success, result = xpcall(function()
			setRobloxInstanceProperty(state.hostObject, p, p2) -- inferred equivalent call
		end, identity)

		if not success then
			local source = state.currentElement.source

			local formatted = ("Error updating props:\n\t%s\nIn element:\n%s\n"):format(
				result,
				source == nil and "<enable element tracebacks>" or source
			)
			error(formatted, 0)
		end
	end

	if state.bindings == nil then
		state.bindings = {}
	end

	state.bindings[p] = Binding.subscribe(object, updateBoundProperty)

	updateBoundProperty(object:getValue())
end

local function detachAllBindings(data) -- 1 equivalent call inferred from this helper
	if data.bindings ~= nil then
		for _, binding in pairs(data.bindings) do
			binding()
		end

		data.bindings = nil
	end
end

local function applyProp(state, k, p, p2)
	if p == p2 or (k == Ref or k == Children) then
		return
	end

	local v2 = Type.of(k)

	if v2 == Type.HostEvent or v2 == Type.HostChangeEvent then
		if state.eventManager == nil then
			state.eventManager = SingleEventManager.new(state.hostObject)
		end

		local name = k.name

		if v2 == Type.HostChangeEvent then
			state.eventManager:connectPropertyChange(name, p)
		else
			state.eventManager:connectEvent(name, p)
		end
	else
		local v3 = Type.of(p) == Type.Binding

		if Type.of(p2) == Type.Binding then
			removeBinding(state, k) -- inferred equivalent call
		end

		if v3 then
			attachBinding(state, k, p)
			return
		end

		setRobloxInstanceProperty(state.hostObject, k, p) -- inferred equivalent call
	end
end

local function applyProps(state, props)
	for k, item in pairs(props) do
		applyProp(state, k, item, nil)
	end
end

local function updateProps(data, props, props2)
	for k, item in pairs(props2) do
		applyProp(data, k, item, props[k])
	end

	for k, item in pairs(props) do
		if props2[k] == nil then
			applyProp(data, k, nil, item)
		end
	end
end

local RobloxRenderer = {}

function RobloxRenderer.isHostObject(instance): boolean
	return typeof(instance) == "Instance"
end

function RobloxRenderer.mountHostNode(p, state)
	local currentElement = state.currentElement
	local hostParent = state.hostParent
	local hostKey = state.hostKey

	if v.internalTypeChecks then
		internalAssert(
			ElementKind.of(currentElement) == ElementKind.Host,
			"Element at given node is not a host Element"
		)
	end

	if v.typeChecks then
		assert(currentElement.props.Name == nil, "Name can not be specified as a prop to a host component in Roact.")
		assert(
			currentElement.props.Parent == nil,
			"Parent can not be specified as a prop to a host component in Roact."
		)
	end

	local instance = Instance.new(currentElement.component)
	state.hostObject = instance

	local success, result = xpcall(function()
		applyProps(state, currentElement.props)
	end, identity)

	if not success then
		local source = currentElement.source

		local formatted = ("Error applying props:\n\t%s\nIn element:\n%s\n"):format(
			result,
			source == nil and "<enable element tracebacks>" or source
		)
		error(formatted, 0)
	end

	instance.Name = tostring(hostKey)

	local v2 = currentElement.props[Children]

	if v2 ~= nil then
		p.updateVirtualNodeWithChildren(state, state.hostObject, v2)
	end

	instance.Parent = hostParent
	state.hostObject = instance

	applyRef(currentElement.props[Ref], instance)

	if state.eventManager ~= nil then
		state.eventManager:resume()
	end
end

function RobloxRenderer.unmountHostNode(p, data)
	applyRef(data.currentElement.props[Ref], nil)

	for _, child in pairs(data.children) do
		p.unmountVirtualNode(child)
	end

	detachAllBindings(data) -- inferred equivalent call
	data.hostObject:Destroy()
end

function RobloxRenderer.updateHostNode(p, data, p2)
	local props = data.currentElement.props
	local props2 = p2.props

	if data.eventManager ~= nil then
		data.eventManager:suspend()
	end

	if props[Ref] ~= props2[Ref] then
		applyRef(props[Ref], nil)
		applyRef(props2[Ref], data.hostObject)
	end

	local success, result = xpcall(function()
		updateProps(data, props, props2)
	end, identity)

	if not success then
		local source = p2.source

		local formatted = ("Error updating props:\n\t%s\nIn element:\n%s\n"):format(
			result,
			source == nil and "<enable element tracebacks>" or source
		)
		error(formatted, 0)
	end

	local v2 = p2.props[Children]

	if v2 ~= nil or props[Children] ~= nil then
		p.updateVirtualNodeWithChildren(data, data.hostObject, v2)
	end

	if data.eventManager ~= nil then
		data.eventManager:resume()
	end

	return data
end

return RobloxRenderer