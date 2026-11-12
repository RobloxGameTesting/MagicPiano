local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)
local Portal = require(script.Parent.Portal)

local v = newproxy(true)

local v2 = {
	Portal = Symbol.named("Portal"),
	Host = Symbol.named("Host"),
	Function = Symbol.named("Function"),
	Stateful = Symbol.named("Stateful"),
	Fragment = Symbol.named("Fragment")
}

function v2.of(p)
	if typeof(p) == "table" then
		return p[v]
	end

	return nil
end

local v3 = { string = v2.Host, ["function"] = v2.Function, table = v2.Stateful }

function v2.fromComponent(p)
	if p == Portal then
		return v.Portal
	end

	return v3[typeof(p)]
end

getmetatable(v).__index = v2

strict(v2, "ElementKind")

return v