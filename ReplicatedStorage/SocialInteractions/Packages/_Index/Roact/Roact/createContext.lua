local Symbol = require(script.Parent.Symbol)
local createFragment = require(script.Parent.createFragment)
local createSignal = require(script.Parent.createSignal)
local Children = require(script.Parent.PropMarkers.Children)
local Component = require(script.Parent.Component)

local function createContextEntry(value) -- 1 equivalent call inferred from this helper
	return { value = value, onUpdate = createSignal() }
end

local function createProvider(p)
	local provider = Component:extend("Provider")

	function provider:init(p2)
		self.contextEntry = createContextEntry(p2.value) -- inferred equivalent call
		self:__addContext(p.key, self.contextEntry)
	end

	function provider.willUpdate(p2, p3)
		if p3.value ~= p2.props.value then
			p2.contextEntry.value = p3.value
		end
	end

	function provider.didUpdate(p2, p3)
		if p3.value ~= p2.props.value then
			p2.contextEntry.onUpdate:fire(p2.props.value)
		end
	end

	function provider.render(p2)
		return createFragment(p2.props[Children])
	end

	return provider
end

local function createConsumer(p)
	local consumer = Component:extend("Consumer")

	function consumer.validateProps(p2)
		if type(p2.render) == "function" then
			return true
		end

		return false, "Consumer expects a `render` function"
	end

	function consumer:init(_)
		self.contextEntry = self:__getContext(p.key)
	end

	function consumer.render(p2)
		local v

		if p2.contextEntry == nil then
			v = p.defaultValue
		else
			v = p2.contextEntry.value
		end

		return p2.props.render(v)
	end

	function consumer:didUpdate()
		if self.contextEntry ~= nil then
			self.lastValue = self.contextEntry.value
		end
	end

	function consumer:didMount()
		if self.contextEntry ~= nil then
			self.disconnect = self.contextEntry.onUpdate:subscribe(function(p2)
				if p2 ~= self.lastValue then
					self:setState({})
				end
			end)
		end
	end

	function consumer:willUnmount()
		if self.disconnect ~= nil then
			self.disconnect()
			self.disconnect = nil
		end
	end

	return consumer
end

local class = {}
class.__index = class

function class.new(defaultValue)
	return (setmetatable({ defaultValue = defaultValue, key = Symbol.named("ContextKey") }, class))
end

function class.__tostring(_): string
	return "RoactContext"
end

local function createContext(p)
	local v = class.new(p)

	return { Provider = createProvider(v), Consumer = createConsumer(v) }
end

return createContext