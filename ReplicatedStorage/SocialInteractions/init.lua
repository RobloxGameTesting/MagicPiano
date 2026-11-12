local config = require(script.config)
local events = require(script.events)
local ChatEmotes = require(script.Modules.ChatEmotes)

return {
	configure = config.configure,
	setTriggerWordsForChatAnimation = ChatEmotes.setTriggerWordsForChatAnimation,
	onChatAnimationPlayed = events.onChatAnimationPlayed.Event
}