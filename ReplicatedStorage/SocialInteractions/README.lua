local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialInteractions = require(ReplicatedStorage:WaitForChild("SocialInteractions"))

SocialInteractions.configure({ waistOrientationWeight = 0.75, useChatAnimations = true })

SocialInteractions.setTriggerWordsForChatAnimation("rbxassetid://3344650532", {
	"hi",
	"hello",
	"good morning",
	"hallo",
	"hey",
	"hola",
	"heya",
	"hiya",
	"howdy"
})

SocialInteractions.onChatAnimationPlayed:Connect(function(p, p2)
	print("Chat animation was played", p, p2)
end)