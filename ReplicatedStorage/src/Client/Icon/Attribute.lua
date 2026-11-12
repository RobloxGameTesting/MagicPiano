task.defer(function()
	local RunService = game:GetService("RunService")
	local VERSION = require(script.Parent.VERSION)
	local appVersion = VERSION.getAppVersion()
	local latestVersion = VERSION.getLatestVersion()
	local v = not VERSION.isUpToDate()

	if not RunService:IsStudio() then
		print(`🍍 Running TopbarPlus {appVersion} by @ForeverHD & HD Admin`)
	end

	if v and latestVersion then
		warn(`A new version of TopbarPlus ({appVersion} -> {latestVersion}) is available: https://devforum.roblox.com/t/topbarplus/1017485`)
	end
end)

task.defer(function()
	local RunService = game:GetService("RunService")
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	if not RunService:IsStudio() or not localPlayer or localPlayer.UserId <= 0 then
		return
	end

	local BadgeService = game:GetService("BadgeService")
	local success, result = pcall(BadgeService.UserHasBadgeAsync, BadgeService, localPlayer.UserId, 3117667999886969)

	if success and not result then
		print("[TopbarPlus]: Please consider a one-time donation (from 5 Robux) at https://www.roblox.com/games/start?placeId=106966695720565 to support this project (this message only ever appears to non-donators in-studio)")
	end
end)

return {}