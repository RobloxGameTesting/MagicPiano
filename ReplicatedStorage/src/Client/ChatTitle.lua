local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")

local function colorToHex(color: Color3) -- 1 equivalent call inferred from this helper
	return string.format(
		"%02X%02X%02X",
		math.round(color.R * 255),
		math.round(color.G * 255),
		(math.round(color.B * 255))
	)
end

local function gradientText(value: string, startColor: Color3, endColor: Color3)
	local v = ""

	for i = 1, #value do
		v ..= "<font color='#" .. colorToHex(startColor:Lerp(endColor, #value == 1 and 0 or (i - 1) / (#value - 1))) .. "'>" .. value:sub(i, i) .. "</font>" -- inferred equivalent call
	end

	return v
end

local v = {
	[887801863] = {
		startColor = Color3.fromRGB(255, 0, 0),
		endColor = Color3.fromRGB(207, 218, 85),
		title = "Builder"
	},
	[1879102207] = {
		startColor = Color3.fromRGB(255, 246, 149),
		endColor = Color3.fromRGB(255, 190, 80),
		title = "Builder"
	},
	[148399802] = {
		startColor = Color3.fromRGB(102, 33, 99),
		endColor = Color3.fromRGB(138, 135, 220),
		title = "Owner"
	},
	[195514930] = {
		startColor = Color3.fromRGB(190, 170, 255),
		endColor = Color3.fromRGB(78, 125, 255),
		title = "Developer"
	},
	[3179687] = {
		startColor = Color3.fromRGB(0, 0, 0),
		endColor = Color3.fromRGB(255, 38, 42),
		title = "vamp"
	},
	[965994246] = {
		startColor = Color3.fromRGB(0, 0, 0),
		endColor = Color3.fromRGB(255, 38, 42),
		title = "vamp"
	}
}

TextChatService.OnIncomingMessage = function(p)
	local textChatMessageProperties = Instance.new("TextChatMessageProperties")

	if not p.TextSource then
		return
	end

	local playerByUserId = Players:GetPlayerByUserId(p.TextSource.UserId)
	local v2 = playerByUserId and v[playerByUserId.UserId]

	if not v2 then
		return
	end

	textChatMessageProperties.PrefixText = gradientText("[" .. v2.title .. "]", v2.startColor, v2.endColor) .. " " .. p.PrefixText
	return textChatMessageProperties
end

return {}