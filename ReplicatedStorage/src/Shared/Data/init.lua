local module = require("@self/DataServiceTyped")

local module2 = require("../Shared/SettingsList")

return module({
	template = {
		timesJoined = 0,
		timePlayed = 0,
		chimes = 0,
		recognitions = 0,
		givenRecognitions = {},
		equippedItems = {},
		inventory = {},
		settings = module2
	},
	useMock = false
})