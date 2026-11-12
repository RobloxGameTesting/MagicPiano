local Component = require(script.Parent.Component)

local extended = Component:extend("PureComponent")

extended.extend = Component.extend

function extended.shouldUpdate(p, items, p2): boolean
	if p2 ~= p.state then
		return true
	end

	if items == p.props then
		return false
	end

	for k, item in pairs(items) do
		if p.props[k] ~= item then
			return true
		end
	end

	for k, v in pairs(p.props) do
		if items[k] ~= v then
			return true
		end
	end

	return false
end

return extended