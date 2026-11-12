local SocialInteractions = script:FindFirstAncestor("SocialInteractions")

local t = require(SocialInteractions.Packages.t)
local Configuration = require(SocialInteractions.Packages.Configuration)
local configuration = Configuration.Configuration

local strictInterface = t.strictInterface({
	useBodyOrientation = t.optional(t.boolean),
	waistOrientationWeight = t.optional(t.number),
	useChatAnimations = t.optional(t.boolean),
	useDefaultTriggerWordsForChatEmotes = t.optional(t.boolean)
})
return (configuration.new(
	"SocialInteractions",
	{
		useBodyOrientation = false,
		waistOrientationWeight = 0.5,
		useChatAnimations = true,
		useDefaultTriggerWordsForChatEmotes = true
	},
	strictInterface
))