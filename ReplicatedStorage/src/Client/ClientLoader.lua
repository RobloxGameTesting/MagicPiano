local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleLoader = require(ReplicatedStorage.src.Shared.ModuleLoader)

ModuleLoader.ChangeSettings({
	FOLDER_SEARCH_DEPTH = 2,
	YIELD_THRESHOLD = 10,
	VERBOSE_LOADING = false,
	WAIT_FOR_SERVER = true
})

ModuleLoader.Start(script, ReplicatedStorage.src.Client, ReplicatedStorage.src.Client.Services)