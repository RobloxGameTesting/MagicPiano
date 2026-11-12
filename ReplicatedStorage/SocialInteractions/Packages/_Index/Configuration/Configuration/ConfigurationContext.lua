local Roact = require(script.Parent.Parent.Roact)
local Cryo = require(script.Parent.Parent.Cryo)

local context = Roact.createContext({})

local extended = Roact.Component:extend("ConfigurationProvider")
function extended:init()
	assert(
		typeof(self.props.config) == "table",
		"ConfigurationContext requires the `config` prop to be an instance of Configuration"
	)

	self.state = self.props.config.getValues()
	self:_connectUpdateEvent()
end

function extended.render(p)
	return Roact.createElement(context.Provider, { value = p.state }, p.props[Roact.Children])
end

function extended:didMount()
	self:_connectUpdateEvent()
end

function extended:willUnmount()
	if self.changedConn then
		self.changedConn:Disconnect()
		self.changedConn = nil
	end
end

function extended:_connectUpdateEvent()
	if self.changedConn then
		return
	end

	self.changedConn = self.props.config.changed:Connect(function(p)
		self:setState(p)
	end)
end

return {
	ConfigurationProvider = extended,
	withConfiguration = function(p)
		return function(p2)
			if p2.configuration then
				warn("Child component has a prop named `configuration` and will be overriden by ConfigurationContext.")
			end

			return Roact.createElement(context.Consumer, {
				render = function(configuration)
					local joined = Cryo.Dictionary.join({ configuration = configuration }, p2)

					return Roact.createElement(p, joined)
				end
			})
		end
	end
}