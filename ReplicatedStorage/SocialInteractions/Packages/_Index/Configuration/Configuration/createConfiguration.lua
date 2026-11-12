local Cryo = require(script.Parent.Parent.Cryo)
local t = require(script.Parent.Parent.t)

return function(object, object2, object3)
	local tuple = t.tuple(t.string, t.table, t.callback)
	return {
		new = function(name, p, validate)
			assert(tuple(name, p, validate))

			local joined = Cryo.Dictionary.join(p, {})

			assert(validate(joined))

			local bindableEvent = Instance.new("BindableEvent")

			local v = {
				name = name,
				initialValues = joined,
				values = joined,
				validate = validate,
				changed = bindableEvent.Event
			}

			function v.getValues()
				return v.values
			end

			function v._updateValues(values)
				v.values = values
				bindableEvent:Fire(values)
			end

			function v.configure(p2)
				local joined2 = Cryo.Dictionary.join(v.values, p2)

				assert(v.validate(joined2))

				v._updateValues(joined2)

				if object:IsServer() then
					object2:FireAllClients(v.name, joined2)
				end
			end

			function v.reset()
				v.values = {}
				v.configure(v.initialValues)
			end

			function v.destroy()
				if v._configChangedConn then
					v._configChangedConn:Disconnect()
				end

				if v._configRequestedConn then
					v._configRequestedConn:Disconnect()
				end
			end

			if object:IsServer() then
				v._configRequestedConn = object3.OnServerEvent:Connect(function(player, p2: string)
					if v.name == p2 then
						object2:FireClient(player, v.name, v.values)
					end
				end)
				return v
			end

			if object:IsClient() then
				v._configChangedConn = object2.OnClientEvent:Connect(function(p2: string, p3)
					if v.name == p2 then
						v._updateValues(p3)
					end
				end)

				object3:FireServer(v.name)
			end

			return v
		end
	}
end