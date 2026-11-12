local QuickNet = require(game.ReplicatedStorage.QuickNet)
local Data = QuickNet.Data

return {
	PurchaseShopItem = QuickNet:register("PurchaseShopItem", Data.String):Response(Data.Boolean, Data.String)
}