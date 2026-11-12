return {
	Strategy = {
		POS = 1,
		PRIM = 2,
		WORLD = 3,
		CFRAME = 4,
		TRANSFORM = 5,
		PIVOT = 6
	},
	Group = { autoClean = true },
	Scheduler = { enabled = true, frameBudget = 0.001, autoSyncRate = 30 },
	Observer = { updateRate = 30, precision = 0.1, safety = true },
	Debug = {
		staticActive = Color3.fromRGB(0, 204, 255),
		staticInactive = Color3.fromRGB(40, 114, 133),
		dynamicActive = Color3.fromRGB(94, 255, 0),
		dynamicInactive = Color3.fromRGB(80, 141, 46),
		transparency = 0.6
	}
}