local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local ElementUtils = require(script.Parent.ElementUtils)
local Children = require(script.Parent.PropMarkers.Children)
local Symbol = require(script.Parent.Symbol)
local internalAssert = require(script.Parent.internalAssert)

local GlobalConfig = require(script.Parent.GlobalConfig)
local v = GlobalConfig.get()

local named = Symbol.named("InternalData")

local function createReconciler(data)
	local reconciler = nil
	local mountVirtualNode
	local updateVirtualNode
	local unmountVirtualNode

	local function replaceVirtualNode(data2, p) -- 2 equivalent calls inferred from this helper
		local hostParent = data2.hostParent
		local hostKey = data2.hostKey
		local depth = data2.depth
		local parent = data2.parent

		local originalContext = data2.originalContext or data2.context
		local parentLegacyContext = data2.parentLegacyContext

		if not data2.wasUnmounted then
			unmountVirtualNode(data2)
		end

		local v2 = mountVirtualNode(p, hostParent, hostKey, originalContext, parentLegacyContext)

		if v2 ~= nil then
			v2.depth = depth
			v2.parent = parent
		end

		return v2
	end

	local function updateChildren(parent, p, p2)
		if v.internalTypeChecks then
			internalAssert(Type.of(parent) == Type.VirtualNode, "Expected arg #1 to be of type VirtualNode")
		end

		parent.updateChildrenCount += 1

		local updateChildrenCount = parent.updateChildrenCount

		local set = {}

		for k, child in pairs(parent.children) do
			local elementByKey = ElementUtils.getElementByKey(p2, k)
			local v2 = updateVirtualNode(child, elementByKey)

			if parent.updateChildrenCount == updateChildrenCount then
				if v2 == nil then
					set[k] = true
				else
					parent.children[k] = v2
				end
			else
				if v2 and v2 ~= parent.children[k] then
					unmountVirtualNode(v2)
				end

				return
			end
		end

		for k in pairs(set) do
			parent.children[k] = nil
		end

		for k, v2 in ElementUtils.iterateElements(p2) do
			local v3

			if k == ElementUtils.UseParentKey then
				v3 = parent.hostKey
			else
				v3 = k
			end

			if parent.children[k] ~= nil then
				continue
			end

			local v4 = mountVirtualNode(v2, p, v3, parent.context, parent.legacyContext)

			if parent.updateChildrenCount == updateChildrenCount then
				if v4 ~= nil then
					v4.depth = parent.depth + 1
					v4.parent = parent
					parent.children[k] = v4
				end
			else
				if v4 then
					unmountVirtualNode(v4)
				end

				break
			end
		end
	end

	local function updateVirtualNodeWithChildren(parent, p, p2) -- 4 equivalent calls inferred from this helper
		updateChildren(parent, p, p2)
	end

	local function updateVirtualNodeWithRenderResult(parent, hostParent, component)
		if Type.of(component) == Type.Element or component == nil or typeof(component) == "boolean" then
			updateChildren(parent, hostParent, component)
		else
			error(
				("%s\n%s"):format(
					"Component returned invalid children:",
					parent.currentElement.source or "<enable element tracebacks>"
				),
				0
			)
		end
	end

	unmountVirtualNode = function(state)
		if v.internalTypeChecks then
			internalAssert(Type.of(state) == Type.VirtualNode, "Expected arg #1 to be of type VirtualNode")
		end

		state.wasUnmounted = true

		local v2 = ElementKind.of(state.currentElement)

		if v2 == ElementKind.Host then
			data.unmountHostNode(reconciler, state)
			return
		end

		if v2 ~= ElementKind.Function then
			if v2 == ElementKind.Stateful then
				state.instance:__unmount()
				return
			end

			if v2 ~= ElementKind.Portal and v2 ~= ElementKind.Fragment then
				error(("Unknown ElementKind %q"):format((tostring(v2))), 2)

				return
			end
		end

		for _, child in pairs(state.children) do
			unmountVirtualNode(child)
		end
	end

	local function updateFunctionVirtualNode(state, currentElement) -- 1 equivalent call inferred from this helper
		local component = currentElement.component(currentElement.props)

		updateVirtualNodeWithRenderResult(state, state.hostParent, component)

		return state
	end

	local function updatePortalVirtualNode(data2, p)
		local target = data2.currentElement.props.target

		local target2 = p.props.target

		assert(data.isHostObject(target2), "Expected target to be host object")

		if target2 == target then
			updateVirtualNodeWithChildren(data2, target2, p.props[Children]) -- inferred equivalent call

			return data2
		end

		return replaceVirtualNode(data2, p) -- inferred equivalent call
	end

	local function updateFragmentVirtualNode(state, currentElement) -- 1 equivalent call inferred from this helper
		updateVirtualNodeWithChildren(state, state.hostParent, currentElement.elements) -- inferred equivalent call

		return state
	end

	updateVirtualNode = function(state, currentElement, p)
		if v.internalTypeChecks then
			internalAssert(Type.of(state) == Type.VirtualNode, "Expected arg #1 to be of type VirtualNode")
		end

		if v.typeChecks then
			assert(
				Type.of(currentElement) == Type.Element or typeof(currentElement) == "boolean" or currentElement == nil,
				"Expected arg #2 to be of type Element, boolean, or nil"
			)
		end

		if state.currentElement == currentElement and p == nil then
			return state
		end

		if typeof(currentElement) == "boolean" or currentElement == nil then
			unmountVirtualNode(state)
			return nil
		end

		if state.currentElement.component == currentElement.component then
			local v2 = ElementKind.of(currentElement)

			local v3 = true

			if v2 == ElementKind.Host then
				state = data.updateHostNode(reconciler, state, currentElement)
			elseif v2 == ElementKind.Function then
				updateFunctionVirtualNode(state, currentElement) -- inferred equivalent call
			elseif v2 == ElementKind.Stateful then
				v3 = state.instance:__update(currentElement, p)
			elseif v2 == ElementKind.Portal then
				local target = state.currentElement.props.target

				local target2 = currentElement.props.target

				assert(data.isHostObject(target2), "Expected target to be host object")

				if target2 == target then
					updateChildren(state, target2, currentElement.props[Children])
				else
					local hostParent = state.hostParent
					local hostKey = state.hostKey
					local depth = state.depth
					local parent = state.parent

					local originalContext = state.originalContext or state.context
					local parentLegacyContext = state.parentLegacyContext

					if not state.wasUnmounted then
						unmountVirtualNode(state)
					end

					state = mountVirtualNode(currentElement, hostParent, hostKey, originalContext, parentLegacyContext)

					if state ~= nil then
						state.depth = depth
						state.parent = parent
					end
				end
			elseif v2 == ElementKind.Fragment then
				updateFragmentVirtualNode(state, currentElement) -- inferred equivalent call
			else
				error(("Unknown ElementKind %q"):format((tostring(v2))), 2)
			end

			if not v3 then
				return state
			end

			state.currentElement = currentElement

			return state
		end

		return replaceVirtualNode(state, currentElement) -- inferred equivalent call
	end

	local function createVirtualNode(currentElement, hostParent, hostKey, options, p)
		if v.internalTypeChecks then
			internalAssert(data.isHostObject(hostParent) or hostParent == nil, "Expected arg #2 to be a host object")

			internalAssert(typeof(options) == "table" or options == nil, "Expected arg #4 to be of type table or nil")
			internalAssert(typeof(p) == "table" or p == nil, "Expected arg #5 to be of type table or nil")
		end

		if v.typeChecks then
			assert(hostKey ~= nil, "Expected arg #3 to be non-nil")
			assert(
				Type.of(currentElement) == Type.Element or typeof(currentElement) == "boolean",
				"Expected arg #1 to be of type Element or boolean"
			)
		end

		return {
			[Type] = Type.VirtualNode,
			currentElement = currentElement,
			depth = 1,
			parent = nil,
			children = {},
			hostParent = hostParent,
			hostKey = hostKey,
			updateChildrenCount = 0,
			wasUnmounted = false,
			legacyContext = p,
			parentLegacyContext = p,
			context = options or {},
			originalContext = nil
		}
	end

	local function mountFunctionVirtualNode(virtualNode) -- 1 equivalent call inferred from this helper
		local currentElement = virtualNode.currentElement

		local component = currentElement.component(currentElement.props)

		updateVirtualNodeWithRenderResult(virtualNode, virtualNode.hostParent, component)
	end

	local function mountPortalVirtualNode(virtualNode) -- 1 equivalent call inferred from this helper
		local currentElement = virtualNode.currentElement

		local target = currentElement.props.target
		local v2 = currentElement.props[Children]

		assert(data.isHostObject(target), "Expected target to be host object")
		updateVirtualNodeWithChildren(virtualNode, target, v2) -- inferred equivalent call
	end

	local function mountFragmentVirtualNode(virtualNode) -- 1 equivalent call inferred from this helper
		local elements = virtualNode.currentElement.elements

		updateVirtualNodeWithChildren(virtualNode, virtualNode.hostParent, elements) -- inferred equivalent call
	end

	mountVirtualNode = function(currentElement, hostParent, hostKey, p, p2)
		if v.internalTypeChecks then
			internalAssert(data.isHostObject(hostParent) or hostParent == nil, "Expected arg #2 to be a host object")

			internalAssert(typeof(p2) == "table" or p2 == nil, "Expected arg #5 to be of type table or nil")
		end

		if v.typeChecks then
			assert(hostKey ~= nil, "Expected arg #3 to be non-nil")
			assert(
				Type.of(currentElement) == Type.Element or typeof(currentElement) == "boolean",
				"Expected arg #1 to be of type Element or boolean"
			)
		end

		if typeof(currentElement) == "boolean" then
			return nil
		end

		local v2 = ElementKind.of(currentElement)

		local virtualNode = createVirtualNode(currentElement, hostParent, hostKey, p, p2)

		if v2 == ElementKind.Host then
			data.mountHostNode(reconciler, virtualNode)
			return virtualNode
		end

		if v2 == ElementKind.Function then
			mountFunctionVirtualNode(virtualNode) -- inferred equivalent call
		else
			if v2 == ElementKind.Stateful then
				currentElement.component:__mount(reconciler, virtualNode)
				return virtualNode
			end

			if v2 == ElementKind.Portal then
				mountPortalVirtualNode(virtualNode) -- inferred equivalent call
			else
				if v2 ~= ElementKind.Fragment then
					error(("Unknown ElementKind %q"):format((tostring(v2))), 2)

					return virtualNode
				end

				mountFragmentVirtualNode(virtualNode) -- inferred equivalent call
			end
		end

		return virtualNode
	end

	reconciler = {
		mountVirtualTree = function(p, p2, p3)
			if v.typeChecks then
				assert(Type.of(p) == Type.Element, "Expected arg #1 to be of type Element")
				assert(data.isHostObject(p2) or p2 == nil, "Expected arg #2 to be a host object")
			end

			local v2 = p3 == nil and "RoactTree" or p3

			local v3 = {
				[Type] = Type.VirtualTree,
				[named] = { rootNode = nil, mounted = true }
			}

			v3[named].rootNode = mountVirtualNode(p, p2, v2)

			return v3
		end,
		unmountVirtualTree = function(p)
			local v2 = p[named]

			if v.typeChecks then
				assert(Type.of(p) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
				assert(v2.mounted, "Cannot unmounted a Roact tree that has already been unmounted")
			end

			v2.mounted = false

			if v2.rootNode ~= nil then
				unmountVirtualNode(v2.rootNode)
			end
		end,
		updateVirtualTree = function(p, p2)
			local v2 = p[named]

			if v.typeChecks then
				assert(Type.of(p) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
				assert(Type.of(p2) == Type.Element, "Expected arg #2 to be a Roact Element")
			end

			v2.rootNode = updateVirtualNode(v2.rootNode, p2)

			return p
		end,
		createVirtualNode = createVirtualNode,
		mountVirtualNode = mountVirtualNode,
		unmountVirtualNode = unmountVirtualNode,
		updateVirtualNode = updateVirtualNode,
		updateVirtualNodeWithChildren = updateVirtualNodeWithChildren,
		updateVirtualNodeWithRenderResult = updateVirtualNodeWithRenderResult
	}

	return reconciler
end

return createReconciler