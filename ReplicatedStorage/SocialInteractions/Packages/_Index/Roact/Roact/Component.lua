local assign = require(script.Parent.assign)
local ComponentLifecyclePhase = require(script.Parent.ComponentLifecyclePhase)
local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)
local invalidSetStateMessages = require(script.Parent.invalidSetStateMessages)
local internalAssert = require(script.Parent.internalAssert)

local GlobalConfig = require(script.Parent.GlobalConfig)
local v = GlobalConfig.get()

local named = Symbol.named("InternalData")

local v2 = {
	__tostring = function(p)
		return p.__componentName
	end
}

local Component = {}
setmetatable(Component, v2)

Component[Type] = Type.StatefulComponentClass
Component.__index = Component
Component.__componentName = "Component"

function Component.extend(items, componentName)
	if v.typeChecks then
		assert(Type.of(items) == Type.StatefulComponentClass, "Invalid `self` argument to `extend`.")
		assert(typeof(componentName) == "string", "Component class name must be a string")
	end

	local result = {}

	for k, item in pairs(items) do
		if k ~= "extend" then
			result[k] = item
		end
	end

	result[Type] = Type.StatefulComponentClass
	result.__index = result
	result.__componentName = componentName

	setmetatable(result, v2)

	return result
end

function Component:__getDerivedState(p, p2)
	if v.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__getDerivedState`")
	end

	local componentClass = self[named].componentClass

	if componentClass.getDerivedStateFromProps == nil then
		return nil
	end

	local derivedStateFromProps = componentClass.getDerivedStateFromProps(p, p2)

	if derivedStateFromProps ~= nil then
		if v.typeChecks then
			assert(typeof(derivedStateFromProps) == "table", "getDerivedStateFromProps must return a table!")
		end

		return derivedStateFromProps
	end

	return nil
end

function Component:setState(callback)
	if v.typeChecks then
		assert(Type.of(self) == Type.StatefulComponentInstance, "Invalid `self` argument to `extend`.")
	end

	local v3 = self[named]
	local lifecyclePhase = v3.lifecyclePhase

	if
		lifecyclePhase == ComponentLifecyclePhase.ShouldUpdate
		or lifecyclePhase == ComponentLifecyclePhase.WillUpdate
		or lifecyclePhase == ComponentLifecyclePhase.Render
	then
		local formatted = invalidSetStateMessages[v3.lifecyclePhase]:format((tostring(v3.componentClass)))
		error(formatted, 2)
	elseif lifecyclePhase == ComponentLifecyclePhase.WillUnmount then
		return
	end

	local pendingState = v3.pendingState

	local v4 = nil

	if typeof(callback) == "function" then
		v4 = callback(pendingState or self.state, self.props)

		if v4 == nil then
			return
		end
	elseif typeof(callback) == "table" then
		v4 = callback
	else
		error("Invalid argument to setState, expected function or table", 2)
	end

	local v5

	if pendingState == nil then
		v5 = assign({}, self.state, v4)
	else
		v5 = assign(pendingState, v4)
	end

	if lifecyclePhase == ComponentLifecyclePhase.Init then
		self.state = assign(v5, (self:__getDerivedState(self.props, v5)))
	elseif
		lifecyclePhase == ComponentLifecyclePhase.DidMount
		or lifecyclePhase == ComponentLifecyclePhase.DidUpdate
		or lifecyclePhase == ComponentLifecyclePhase.ReconcileChildren
	then
		v3.pendingState = assign(v5, (self:__getDerivedState(self.props, v5)))
	else
		if lifecyclePhase == ComponentLifecyclePhase.Idle then
			self:__update(nil, v5)
			return
		end

		local formatted = invalidSetStateMessages.default:format((tostring(v3.componentClass)))

		error(formatted, 2)
	end
end

function Component:getElementTraceback()
	return self[named].virtualNode.currentElement.source
end

function Component:render()
	local formatted = ("The component %q is missing the `render` method.\n`render` must be defined when creating a Roact component!"):format((tostring(self[named].componentClass)))

	error(formatted, 0)
end

function Component.__getContext(p, p2)
	if v.internalTypeChecks then
		internalAssert(Type.of(p) == Type.StatefulComponentInstance, "Invalid use of `__getContext`")
		internalAssert(p2 ~= nil, "Context key cannot be nil")
	end

	return p[named].virtualNode.context[p2]
end

function Component.__addContext(p, p2, p3)
	if v.internalTypeChecks then
		internalAssert(Type.of(p) == Type.StatefulComponentInstance, "Invalid use of `__addContext`")
	end

	local virtualNode = p[named].virtualNode

	if virtualNode.originalContext == nil then
		virtualNode.originalContext = virtualNode.context
	end

	virtualNode.context = assign({}, virtualNode.context, { [p2] = p3 })
end

function Component:__validateProps(p)
	if not v.propValidation then
		return
	end

	local validateProps = self[named].componentClass.validateProps

	if validateProps == nil then
		return
	end

	if typeof(validateProps) ~= "function" then
		error(("validateProps must be a function, but it is a %s.\nCheck the definition of the component %q."):format(
			typeof(validateProps),
			self.__componentName
		))
	end

	local v3, v4 = validateProps(p)

	if not v3 then
		error(
			("Property validation failed in %s: %s\n\n%s"):format(
				self.__componentName,
				tostring(v4 or "<Validator function did not supply a message>"),
				self:getElementTraceback() or "<enable element tracebacks>"
			),
			0
		)
	end
end

function Component.__mount(componentClass, reconciler, state)
	if v.internalTypeChecks then
		internalAssert(Type.of(componentClass) == Type.StatefulComponentClass, "Invalid use of `__mount`")
		internalAssert(Type.of(state) == Type.VirtualNode, "Expected arg #2 to be of type VirtualNode")
	end

	local currentElement = state.currentElement
	local hostParent = state.hostParent

	local v3 = {
		reconciler = reconciler,
		virtualNode = state,
		componentClass = componentClass,
		lifecyclePhase = ComponentLifecyclePhase.Init,
		pendingState = nil
	}

	local instance = { [Type] = Type.StatefulComponentInstance, [named] = v3 }

	setmetatable(instance, componentClass)

	state.instance = instance

	local props = currentElement.props

	if componentClass.defaultProps ~= nil then
		props = assign({}, componentClass.defaultProps, props)
	end

	instance:__validateProps(props)

	instance.props = props

	instance._context = assign({}, state.legacyContext)

	instance.state = assign({}, instance:__getDerivedState(instance.props, {}))

	if instance.init ~= nil then
		instance:init(instance.props)
		assign(instance.state, instance:__getDerivedState(instance.props, instance.state))
	end

	state.legacyContext = instance._context

	v3.lifecyclePhase = ComponentLifecyclePhase.Render
	local v4 = instance:render()

	v3.lifecyclePhase = ComponentLifecyclePhase.ReconcileChildren
	reconciler.updateVirtualNodeWithRenderResult(state, hostParent, v4)

	if instance.didMount ~= nil then
		v3.lifecyclePhase = ComponentLifecyclePhase.DidMount
		instance:didMount()
	end

	if v3.pendingState ~= nil then
		instance:__update(nil, nil)
	end

	v3.lifecyclePhase = ComponentLifecyclePhase.Idle
end

function Component.__unmount(object)
	if v.internalTypeChecks then
		internalAssert(Type.of(object) == Type.StatefulComponentInstance, "Invalid use of `__unmount`")
	end

	local v3 = object[named]
	local virtualNode = v3.virtualNode
	local reconciler = v3.reconciler

	if object.willUnmount ~= nil then
		v3.lifecyclePhase = ComponentLifecyclePhase.WillUnmount
		object:willUnmount()
	end

	for _, child in pairs(virtualNode.children) do
		reconciler.unmountVirtualNode(child)
	end
end

function Component:__update(p, p2)
	if v.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__update`")
		internalAssert(Type.of(p) == Type.Element or p == nil, "Expected arg #1 to be of type Element or nil")

		internalAssert(typeof(p2) == "table" or p2 == nil, "Expected arg #2 to be of type table or nil")
	end

	local v3 = self[named]
	local componentClass = v3.componentClass

	local props = self.props

	if p ~= nil then
		props = p.props

		if componentClass.defaultProps ~= nil then
			props = assign({}, componentClass.defaultProps, props)
		end

		self:__validateProps(props)
	end

	local count = 0

	while true do
		local v4

		if v3.pendingState ~= nil then
			v4 = v3.pendingState
			v3.pendingState = nil
		end

		if p2 ~= nil or props ~= self.props then
			if v4 == nil then
				v4 = p2 or self.state
			else
				v4 = assign(v4, p2)
			end

			local __getDerivedState = self:__getDerivedState(props, v4)

			if __getDerivedState ~= nil then
				v4 = assign({}, v4, __getDerivedState)
			end

			p2 = nil
		end

		if not self:__resolveUpdate(props, v4) then
			return false
		end

		count += 1

		if count > 100 then
			error(
				("The component %q has reached the setState update recursion limit.\nWhen using `setState` in `didUpdate`, make sure that it won't repeat infinitely!"):format((tostring(v3.componentClass))),
				3
			)
		end

		if v3.pendingState == nil then
			return true
		end
	end
end

function Component:__resolveUpdate(props, state): boolean
	if v.internalTypeChecks then
		internalAssert(Type.of(self) == Type.StatefulComponentInstance, "Invalid use of `__resolveUpdate`")
	end

	local v3 = self[named]
	local virtualNode = v3.virtualNode
	local reconciler = v3.reconciler

	local props2 = self.props
	local state2 = self.state

	if props == nil then
		props = props2
	end

	if state == nil then
		state = state2
	end

	if self.shouldUpdate ~= nil then
		v3.lifecyclePhase = ComponentLifecyclePhase.ShouldUpdate

		if not self:shouldUpdate(props, state) then
			v3.lifecyclePhase = ComponentLifecyclePhase.Idle
			return false
		end
	end

	if self.willUpdate ~= nil then
		v3.lifecyclePhase = ComponentLifecyclePhase.WillUpdate
		self:willUpdate(props, state)
	end

	v3.lifecyclePhase = ComponentLifecyclePhase.Render

	self.props = props
	self.state = state

	local v4 = virtualNode.instance:render()

	v3.lifecyclePhase = ComponentLifecyclePhase.ReconcileChildren
	reconciler.updateVirtualNodeWithRenderResult(virtualNode, virtualNode.hostParent, v4)

	if self.didUpdate ~= nil then
		v3.lifecyclePhase = ComponentLifecyclePhase.DidUpdate
		self:didUpdate(props2, state2)
	end

	v3.lifecyclePhase = ComponentLifecyclePhase.Idle
	return true
end

return Component