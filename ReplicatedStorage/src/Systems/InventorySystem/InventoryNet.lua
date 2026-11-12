local QuickNet = require(game.ReplicatedStorage.QuickNet)
local Data = QuickNet.Data

return {
	EquipItem = QuickNet:register("EquipItem", Data.String):Response(Data.Boolean, Data.String),
	UnequipItem = QuickNet:register("UnequipItem", Data.String):Response(Data.Boolean, Data.String)
}