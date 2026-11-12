local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)

local v = newproxy(true)

local v2 = {}

local function addType(p) -- 8 equivalent calls inferred from this helper
	v2[p] = Symbol.named("Roact" .. p)
end

addType("Binding") -- inferred equivalent call
addType("Element") -- inferred equivalent call
addType("HostChangeEvent") -- inferred equivalent call
addType("HostEvent") -- inferred equivalent call
addType("StatefulComponentClass") -- inferred equivalent call
addType("StatefulComponentInstance") -- inferred equivalent call
addType("VirtualNode") -- inferred equivalent call
addType("VirtualTree") -- inferred equivalent call

function v2.of(p)
	if typeof(p) == "table" then
		return p[v]
	end

	return nil
end

getmetatable(v).__index = v2

getmetatable(v).__tostring = function(): string
	return "RoactType"
end

strict(v2, "Type")

return v