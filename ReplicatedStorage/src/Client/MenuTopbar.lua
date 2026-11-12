local MenuTopbar = {}

local module = require("./Icon")
local module2 = require("../Shared/Data")
local client = module2.client

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Click = Assets.Sounds.Click

MenuTopbar.ScreenshakeToggled = nil
MenuTopbar.ItemSoundsToggled = nil
MenuTopbar.NametagsToggled = nil
MenuTopbar.ShopSelected = nil
MenuTopbar.ShopDeselected = nil
MenuTopbar.InventorySelected = nil
MenuTopbar.InventoryDeselected = nil
MenuTopbar.AmbienceToggled = nil
MenuTopbar.ShadowsToggled = nil
MenuTopbar.LightObjectsToggled = nil
MenuTopbar.PianoEffectsToggled = nil
MenuTopbar.MuteOthersToggled = nil
MenuTopbar.HideOthersToggled = nil
MenuTopbar.HeadTurnToggled = nil
MenuTopbar.PortalTransitionToggled = nil
MenuTopbar.CameraSwayToggled = nil
MenuTopbar.CameraDelayToggled = nil
MenuTopbar.PianoNotesLabelToggled = nil
MenuTopbar.FullScreenPianoToggled = nil
MenuTopbar.TexturesToggled = nil

local chimesIcon = nil
local v = nil
local count = 0

local function resetMenuTimer() -- 9 equivalent calls inferred from this helper
	Click:Play()

	if not v then
		return
	end

	count += 1
	local v2 = count

	task.delay(60, function()
		if not v.isSelected or v2 ~= count then
			return
		end

		v:deselect()
	end)
end

local function createSettingsIcon(p, p2)
	return (module.new():setLabel(p):setTextFont(Enum.Font.Fondamento):oneClick(true):bindEvent("selected", function()
		resetMenuTimer() -- inferred equivalent call

		if MenuTopbar[p2] then
			MenuTopbar[p2]()
		end
	end))
end

function MenuTopbar.Init()
	local inventoryIcon = module.new():setImage(96943151264418):bindEvent("selected", function()
		Click:Play()

		if v then
			count += 1
			local v2 = count

			task.delay(60, function()
				if not v.isSelected or v2 ~= count then
					return
				end

				v:deselect()
			end)
		end

		if MenuTopbar.InventorySelected then
			MenuTopbar.InventorySelected()
		end

		if MenuTopbar.ShopDeselected then
			MenuTopbar.ShopDeselected()
		end
	end):bindEvent("deselected", function()
		Click:Play()

		if v then
			count += 1
			local v2 = count

			task.delay(60, function()
				if not v.isSelected or v2 ~= count then
					return
				end

				v:deselect()
			end)
		end

		if MenuTopbar.InventoryDeselected then
			MenuTopbar.InventoryDeselected()
		end
	end)
	MenuTopbar.InventoryIcon = inventoryIcon

	local shopIcon = module.new():setImage(4882429582):bindEvent("selected", function()
		Click:Play()

		if v then
			count += 1
			local v2 = count

			task.delay(60, function()
				if not v.isSelected or v2 ~= count then
					return
				end

				v:deselect()
			end)
		end

		if MenuTopbar.ShopSelected then
			MenuTopbar.ShopSelected()
		end

		if MenuTopbar.InventoryDeselected then
			MenuTopbar.InventoryDeselected()
		end
	end):bindEvent("deselected", function()
		Click:Play()

		if v then
			count += 1
			local v2 = count

			task.delay(60, function()
				if not v.isSelected or v2 ~= count then
					return
				end

				v:deselect()
			end)
		end

		if MenuTopbar.ShopDeselected then
			MenuTopbar.ShopDeselected()
		end
	end)
	MenuTopbar.ShopIcon = shopIcon

	local settingsIcon = createSettingsIcon("Screenshake", "ScreenshakeToggled")
	local settingsIcon2 = createSettingsIcon("Ambience", "AmbienceToggled")
	local settingsIcon3 = createSettingsIcon("Piano Effects", "PianoEffectsToggled")
	local settingsIcon4 = createSettingsIcon("Camera Delay", "CameraDelayToggled")
	local settingsIcon5 = createSettingsIcon("Mute Other Pianos", "MuteOthersToggled")
	local settingsIcon6 = createSettingsIcon("Hide Others", "HideOthersToggled")
	local settingsIcon7 = createSettingsIcon("Item Sounds", "ItemSoundsToggled")
	local settingsIcon8 = createSettingsIcon("Head Turn", "HeadTurnToggled")
	local settingsIcon9 = createSettingsIcon("Nametags", "NametagsToggled")
	local settingsIcon10 = createSettingsIcon("Global Shadows", "ShadowsToggled")
	local settingsIcon11 = createSettingsIcon("Light Sources", "LightObjectsToggled")
	local settingsIcon12 = createSettingsIcon("Portal Fade", "PortalTransitionToggled")

	local settingsIcon13 = createSettingsIcon("Camera Sway", "CameraSwayToggled")
	local settingsIcon14 = createSettingsIcon("Note Labels", "PianoNotesLabelToggled")
	local settingsIcon15 = createSettingsIcon("Fullscreen Piano (Mobile)", "FullScreenPianoToggled")
	local settingsIcon16 = createSettingsIcon("Textures", "TexturesToggled")
	MenuTopbar.ScreenshakeIcon = settingsIcon
	MenuTopbar.AmbienceIcon = settingsIcon2
	MenuTopbar.PianoEffectsIcon = settingsIcon3
	MenuTopbar.CameraDelayIcon = settingsIcon4
	MenuTopbar.MuteOthersIcon = settingsIcon5
	MenuTopbar.HideOthersIcon = settingsIcon6
	MenuTopbar.ItemSoundsIcon = settingsIcon7
	MenuTopbar.HeadTurnIcon = settingsIcon8
	MenuTopbar.NametagsIcon = settingsIcon9
	MenuTopbar.ShadowsIcon = settingsIcon10
	MenuTopbar.LightObjectsIcon = settingsIcon11
	MenuTopbar.PortalTransitionIcon = settingsIcon12
	MenuTopbar.CameraSwayIcon = settingsIcon13
	MenuTopbar.PianoNoteLabelsIcon = settingsIcon14
	MenuTopbar.FullScreenPianoIcon = settingsIcon15
	MenuTopbar.TexturesIcon = settingsIcon16

	local v2 = module.new():setLabel("General"):setTextFont(Enum.Font.Fondamento):setImage(6720824670):setDropdown({
		settingsIcon2,
		settingsIcon6,
		settingsIcon7,
		settingsIcon8,
		settingsIcon9
	})

	local v3 = module.new():setLabel("Piano"):setTextFont(Enum.Font.Fondamento):setImage(93160522453913):setDropdown({
		settingsIcon3,
		settingsIcon5,
		settingsIcon14,
		settingsIcon15
	})

	local v4 = module.new():setLabel("Performance"):setTextFont(Enum.Font.Fondamento):setImage(18446448769):setDropdown({
		settingsIcon,
		settingsIcon4,
		settingsIcon13,
		settingsIcon10,
		settingsIcon16,
		settingsIcon11,
		settingsIcon12
	})

	local function closeOtherSettingsMenus(object)
		for _, v5 in { v2, v3, v4 } do
			if v5 ~= object and v5.isSelected then
				v5:deselect()
			end
		end
	end

	local function bindSettingsMenuEvents(object) -- 3 equivalent calls inferred from this helper
		object:bindEvent("selected", function()
			closeOtherSettingsMenus(object)
			resetMenuTimer() -- inferred equivalent call
		end):bindEvent("deselected", resetMenuTimer):setCloseOnOutsideClick(false)
	end

	bindSettingsMenuEvents(v2) -- inferred equivalent call
	bindSettingsMenuEvents(v3) -- inferred equivalent call
	bindSettingsMenuEvents(v4) -- inferred equivalent call
	local v5 = nil

	local v6 = module.new():setMenu({ v2, v3, v4 }):bindEvent("deselected", function()
		resetMenuTimer() -- inferred equivalent call

		if v5 then
			v5:deselect()
		end
	end)

	v5 = module.new():setImage(9405931578):setCloseOnOutsideClick(false):setDropdown({ v6 }):bindEvent(
		"selected",
		function()
			resetMenuTimer() -- inferred equivalent call
			v6:select()
		end
	):bindEvent(
		"deselected",
		function()
			Click:Play()

			if not v then
				return
			end

			count += 1
			local v7 = count

			task.delay(60, function()
				if not v.isSelected or v7 ~= count then
					return
				end

				v:deselect()
			end)
		end
	)

	local v7 = module.new():setImage(11893826115):oneClick(true):bindEvent("selected", function()
		Click:Play()

		if v then
			count += 1
			local v7 = count

			task.delay(60, function()
				if not v.isSelected or v7 ~= count then
					return
				end

				v:deselect()
			end)
		end

		local SocialService = game:GetService("SocialService")
		local experienceInviteOptions = Instance.new("ExperienceInviteOptions")
		experienceInviteOptions.PromptMessage = "Ask your friends to experience the magic!"

		local success, result = pcall(function()
			return SocialService:CanSendGameInviteAsync(LocalPlayer)
		end)

		if success and result then
			SocialService:PromptGameInvite(LocalPlayer, experienceInviteOptions)
		end
	end)

	local v8 = module.new():setImage(6071020687):setImageScale(0.7):oneClick():bindEvent("selected", function()
		MarketplaceService:PromptRobloxSubscriptionPurchase(LocalPlayer)
	end)

	local webhookGui = PlayerGui:WaitForChild("WebhookGui")
	local closeButton = webhookGui.Frame.CloseButton
	local v9 = module.new():setImage(89866927060973):bindEvent("selected", function()
		resetMenuTimer() -- inferred equivalent call
		webhookGui.Enabled = true
	end):bindEvent("deselected", function()
		resetMenuTimer() -- inferred equivalent call
		webhookGui.Enabled = false
	end)

	closeButton.Activated:Connect(function()
		webhookGui.Enabled = false
		v9:deselect()
	end)

	local creditsGui = PlayerGui:WaitForChild("CreditsGui")
	local closeButton2 = creditsGui.CreditsFrame.Header.CloseButton
	local v10 = module.new():setImage(12955894642):bindEvent("selected", function()
		resetMenuTimer() -- inferred equivalent call
		creditsGui.Enabled = true
	end):bindEvent("deselected", function()
		resetMenuTimer() -- inferred equivalent call
		creditsGui.Enabled = false
	end)

	closeButton2.Activated:Connect(function()
		creditsGui.Enabled = false
		v10:deselect()
	end)

	v = module.new():call(function(p)
		v = p
	end):setImage(16009597038):modifyTheme({ "Menu", "MaxIcons", 4 }):setMenu({
		inventoryIcon,
		shopIcon,
		v5,
		v7,
		v8,
		v9,
		v10
	}):bindEvent("selected", function()
		chimesIcon:setEnabled(true)
		Assets.Sounds["Magic Glows Soft Clusters Of Chiming Hits 1 (SFX)"]:Play()
		resetMenuTimer() -- inferred equivalent call

		if not client.seenMenuIcon() then
			game.ReplicatedStorage.Remotes.SeenMenuEvent:FireServer()
		end
	end):bindEvent("deselected", function()
		Click:Play()
		chimesIcon:setEnabled(false)
		count += 1
	end)

	chimesIcon = module.new():setTextFont(Enum.Font.Fondamento):oneClick(true):setLabel("nil"):setImage(98992199615101):setEnabled(false)

	MenuTopbar.ChimesIcon = chimesIcon
end

function MenuTopbar.Start()
	if client.seenMenuIcon() then
		return
	end

	task.delay(240, function()
		if client.seenMenuIcon() or not v then
			return
		end

		v:notify()
		v:modifyTheme({
			{ "Notice", "BackgroundColor3", Color3.fromRGB(195, 61, 70) }
		})
		local instance = v:getInstance("Notice")

		if not instance then
			return
		end

		local textLabel = instance:FindFirstChildWhichIsA("TextLabel", true)

		if textLabel then
			textLabel.Visible = false
		end

		local uiScale = instance:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", instance)
		local TweenService = game:GetService("TweenService")
		TweenService:Create(
			uiScale,
			TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut, 0, true, 0.5),
			{ Scale = 3 }
		):Play()
	end)
end

return MenuTopbar