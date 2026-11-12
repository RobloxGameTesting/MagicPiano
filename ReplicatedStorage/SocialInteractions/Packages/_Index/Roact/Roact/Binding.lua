local createSignal = require(script.Parent.createSignal)
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local GlobalConfig = require(script.Parent.GlobalConfig)
local v = GlobalConfig.get()

local named = Symbol.named("BindingImpl")

local Binding = {}

local v2 = {
	__index = {
		getValue = function(p)
			return Binding.getValue(p)
		end,
		map = function(p, p2)
			return Binding.map(p, p2)
		end
	},
	__tostring = function(object)
		return string.format("RoactBinding(%s)", (tostring(object:getValue())))
	end
}

function Binding.update(p, p2)
	return p[named].update(p2)
end

function Binding.subscribe(p, p2)
	return p[named].subscribe(p2)
end

function Binding.getValue(p)
	return p[named].getValue()
end

function Binding.create(p)
	local v3 = { value = p, changeSignal = createSignal() }

	function v3.subscribe(p2)
		return v3.changeSignal:subscribe(p2)
	end

	function v3.update(p2)
		v3.value = p2
		v3.changeSignal:fire(p2)
	end

	function v3.getValue()
		return v3.value
	end

	return setmetatable({ [Type] = Type.Binding, [named] = v3 }, v2), v3.update
end

function Binding:map(callback)
	if v.typeChecks then
		assert(Type.of(self) == Type.Binding, "Expected arg #1 to be a binding")
		assert(typeof(callback) == "function", "Expected arg #1 to be a function")
	end

	return (setmetatable({
		[Type] = Type.Binding,
		[named] = {
			subscribe = function(callback2)
				return Binding.subscribe(self, function(p)
					callback2(callback(p))
				end)
			end,
			update = function(_)
				error("Bindings created by Binding:map(fn) cannot be updated directly", 2)
			end,
			getValue = function()
				return callback(self:getValue())
			end
		}
	}, v2))
end

function Binding.join(items)
	if v.typeChecks then
		assert(typeof(items) == "table", "Expected arg #1 to be of type table")

		for k, item in pairs(items) do
			if Type.of(item) == Type.Binding then
				continue
			end

			local formatted = ("Expected arg #1 to contain only bindings, but key %q had a non-binding value"):format((tostring(k)))

			error(formatted, 2)
		end
	end

	local function getValue()
		local value = {}

		for k, item in pairs(items) do
			value[k] = item:getValue()
		end

		return value
	end

	return (setmetatable({
		[Type] = Type.Binding,
		[named] = {
			subscribe = function(callback)
				local v3 = {}

				for k, item in pairs(items) do
					v3[k] = Binding.subscribe(item, function(_)
						callback(getValue())
					end)
				end

				return function()
					if v3 == nil then
						return
					end

					for _, v4 in pairs(v3) do
						v4()
					end

					v3 = nil
				end
			end,
			update = function(_)
				error("Bindings created by joinBindings(...) cannot be updated directly", 2)
			end,
			getValue = function()
				return getValue()
			end
		}
	}, v2))
end

return Binding