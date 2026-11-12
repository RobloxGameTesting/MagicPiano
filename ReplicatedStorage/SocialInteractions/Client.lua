local socialInteractions = script:FindFirstAncestor("SocialInteractions")

local BodyOrientation = require(socialInteractions.Modules.BodyOrientation)
local ChatEmotes = require(socialInteractions.Modules.ChatEmotes)
local config = require(socialInteractions.config)

function onConfigChanged(p)
	if p.useBodyOrientation then
		BodyOrientation.enable()
	else
		BodyOrientation.disable()
	end

	if p.useChatAnimations then
		ChatEmotes.enable()
	else
		ChatEmotes.disable()
	end
end

config.changed:Connect(onConfigChanged)
onConfigChanged(config.initialValues)