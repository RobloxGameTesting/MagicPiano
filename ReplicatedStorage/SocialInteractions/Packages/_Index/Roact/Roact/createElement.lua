local Children = require(script.Parent.PropMarkers.Children)
local ElementKind = require(script.Parent.ElementKind)
local Logging = require(script.Parent.Logging)
local Type = require(script.Parent.Type)

local GlobalConfig = require(script.Parent.GlobalConfig)
local v = GlobalConfig.get()

local function createElement(component, props, children)
	if v.typeChecks then
		assert(component ~= nil, "`component` is required")
		assert(typeof(props) == "table" or props == nil, "`props` must be a table or nil")
		assert(typeof(children) == "table" or children == nil, "`children` must be a table or nil")
	end

	local props2 = props == nil and {} or props

	if children ~= nil then
		if props2[Children] ~= nil then
			Logging.warnOnce([[
The prop `Roact.Children` was defined but was overridden by the third parameter to createElement!
This can happen when a component passes props through to a child element but also uses the `children` argument:

	Roact.createElement("Frame", passedProps, {
		child = ...
	})

Instead, consider using a utility function to merge tables of children together:

	local children = mergeTables(passedProps[Roact.Children], {
		child = ...
	})

	local fullProps = mergeTables(passedProps, {
		[Roact.Children] = children
	})

	Roact.createElement("Frame", fullProps)]])
		end

		props2[Children] = children
	end

	local v2 = ElementKind.fromComponent(component)

	local element = {
		[Type] = Type.Element,
		[ElementKind] = v2,
		component = component,
		props = props2
	}

	if v.elementTracing then
		element.source = debug.traceback("", 2):sub(2)
	end

	return element
end

return createElement