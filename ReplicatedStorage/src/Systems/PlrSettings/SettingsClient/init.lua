local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local module = require("../../Shared/Data")
local client = module.client
local module2 = require("../../Shared/Net")
local module3 = require("../../Client/MenuTopbar")

local ReducedTextures = require(script.ReducedTextures)
return {
	Start = function()
		function module3.ScreenshakeToggled()
			module2.ToggleSetting:FireServer("screenshakeEnabled")
		end
		function module3.ItemSoundsToggled()
			module2.ToggleSetting:FireServer("itemSoundsEnabled")
		end
		function module3.NametagsToggled()
			module2.ToggleSetting:FireServer("nametagsEnabled")
		end
		function module3.AmbienceToggled()
			module2.ToggleSetting:FireServer("ambienceEnabled")
		end
		function module3.ShadowsToggled()
			module2.ToggleSetting:FireServer("shadowsEnabled")
		end
		function module3.LightObjectsToggled()
			module2.ToggleSetting:FireServer("lightObjectsEnabled")
		end
		function module3.PianoEffectsToggled()
			module2.ToggleSetting:FireServer("pianoEffectsEnabled")
		end
		function module3.MuteOthersToggled()
			module2.ToggleSetting:FireServer("muteOthersEnabled")
		end
		function module3.HideOthersToggled()
			module2.ToggleSetting:FireServer("hideOthersEnabled")
		end
		function module3.HeadTurnToggled()
			module2.ToggleSetting:FireServer("headTurnEnabled")
		end
		function module3.PortalTransitionToggled()
			module2.ToggleSetting:FireServer("portalTransitionEnabled")
		end
		function module3.CameraSwayToggled()
			module2.ToggleSetting:FireServer("cameraSwayEnabled")
		end
		function module3.CameraDelayToggled()
			module2.ToggleSetting:FireServer("cameraDelayEnabled")
		end
		function module3.PianoNotesLabelToggled()
			module2.ToggleSetting:FireServer("pianoNotesLabelEnabled")
		end
		function module3.FullScreenPianoToggled()
			module2.ToggleSetting:FireServer("fullScreenPianoEnabled")
		end
		function module3.TexturesToggled()
			module2.ToggleSetting:FireServer("texturesEnabled")
		end

		local function updateScreenshakeIcon(p) -- 1 equivalent call inferred from this helper
			module3.ScreenshakeIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function updateItemSounds(p) -- 1 equivalent call inferred from this helper
			module3.ItemSoundsIcon:setImage(p and 7173527603 or 6405243681)

			for _, v in CollectionService:GetTagged("ItemSound") do
				v.Volume = p and 0.05 or 0
			end
		end

		local function updateNametags(enabled) -- 1 equivalent call inferred from this helper
			module3.NametagsIcon:setImage(enabled and 7173527603 or 6405243681)

			for _, v in CollectionService:GetTagged("Nametag") do
				v.Enabled = enabled
			end
		end

		local function updateAmbience(p)
			module3.AmbienceIcon:setImage(p and 7173527603 or 6405243681)

			for _, v in CollectionService:GetTagged("AmbienceSound") do
				if p then
					v:Play()
				else
					v:Stop()
				end
			end
		end

		local function updateShadows(globalShadows) -- 1 equivalent call inferred from this helper
			module3.ShadowsIcon:setImage(globalShadows and 7173527603 or 6405243681)
			game.Lighting.GlobalShadows = globalShadows
		end

		local function updateLightObjects(enabled) -- 1 equivalent call inferred from this helper
			module3.LightObjectsIcon:setImage(enabled and 7173527603 or 6405243681)

			for _, v in CollectionService:GetTagged("LightObject") do
				v.Enabled = enabled
			end
		end
		CollectionService:GetInstanceAddedSignal("LightObject"):Connect(function(p)
			p.Enabled = client.settings.lightObjectsEnabled()
		end)

		local function updatePianoEffects(p) -- 1 equivalent call inferred from this helper
			module3.PianoEffectsIcon:setImage(p and 7173527603 or 6405243681)
		end
		local function updateMuteOthers(p) -- 1 equivalent call inferred from this helper
			module3.MuteOthersIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function changeDescendantTransparency(descendant, transparency, enabled)
			if descendant.Name == "HumanoidRootPart" or descendant.Name == "CollisionPart" then
				return
			end

			if descendant:IsA("BasePart") or descendant:IsA("Decal") then
				descendant.Transparency = transparency
			elseif descendant:IsA("ParticleEmitter") then
				descendant.Enabled = transparency == 0
			elseif descendant:IsA("BillboardGui") then
				if transparency ~= 0 then
					enabled = false
				end

				descendant.Enabled = enabled
			end
		end

		local function changeCharTransparency(folder, transparency, p) -- 3 equivalent calls inferred from this helper
			if not folder then
				return
			end

			for _, descendant in folder:GetDescendants() do
				changeDescendantTransparency(descendant, transparency, p)
			end
		end

		local function updateHideOthers(p)
			module3.HideOthersIcon:setImage(p and 7173527603 or 6405243681)

			for _, v in Players:GetPlayers() do
				if v ~= LocalPlayer then
					changeCharTransparency(v.Character, p and 1 or 0, client.settings.nametagsEnabled()) -- inferred equivalent call
				end
			end
		end

		local function trackPlrToHide(player)
			if player == LocalPlayer then
				return
			end

			local function trackCharToHide(character)
				if client.settings.hideOthersEnabled() then
					changeCharTransparency(character, 1, client.settings.nametagsEnabled()) -- inferred equivalent call
				end

				character.DescendantAdded:Connect(function(descendant)
					if not client.settings.hideOthersEnabled() then
						return
					end

					changeDescendantTransparency(descendant, 1, client.settings.nametagsEnabled())
				end)
			end
			player.CharacterAdded:Connect(trackCharToHide)

			if player.Character then
				trackCharToHide(player.Character)
			end
		end

		for _, v in Players:GetPlayers() do
			if v == LocalPlayer then
				continue
			end

			local function trackCharToHide(character)
				if client.settings.hideOthersEnabled() then
					changeCharTransparency(character, 1, client.settings.nametagsEnabled()) -- inferred equivalent call
				end

				character.DescendantAdded:Connect(function(descendant)
					if not client.settings.hideOthersEnabled() then
						return
					end

					changeDescendantTransparency(descendant, 1, client.settings.nametagsEnabled())
				end)
			end
			v.CharacterAdded:Connect(trackCharToHide)

			if v.Character then
				trackCharToHide(v.Character)
			end
		end

		Players.PlayerAdded:Connect(trackPlrToHide)

		CollectionService:GetInstanceAddedSignal("ItemSound"):Connect(function(p)
			p.Volume = client.settings.itemSoundsEnabled() and 0.05 or 0
		end)
		CollectionService:GetInstanceAddedSignal("Nametag"):Connect(function(p)
			p.Enabled = client.settings.nametagsEnabled()
		end)

		local function updateHeadTurn(p) -- 1 equivalent call inferred from this helper
			module3.HeadTurnIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function updatePortalTransition(p) -- 1 equivalent call inferred from this helper
			module3.PortalTransitionIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function updateCamSway(p) -- 1 equivalent call inferred from this helper
			module3.CameraSwayIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function updateCamDelay(p) -- 1 equivalent call inferred from this helper
			module3.CameraDelayIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function updatePianoNotesLabels(p) -- 1 equivalent call inferred from this helper
			module3.PianoNoteLabelsIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function updateFullScreenPiano(p) -- 1 equivalent call inferred from this helper
			module3.FullScreenPianoIcon:setImage(p and 7173527603 or 6405243681)
		end

		local function updateTextures(p) -- 1 equivalent call inferred from this helper
			module3.TexturesIcon:setImage(p and 7173527603 or 6405243681)

			if p then
				ReducedTextures.Show()
			else
				ReducedTextures.Hide()
			end
		end

		updateScreenshakeIcon(client.settings.screenshakeEnabled()) -- inferred equivalent call
		updateItemSounds(client.settings.itemSoundsEnabled()) -- inferred equivalent call
		updateNametags(client.settings.nametagsEnabled()) -- inferred equivalent call
		updateAmbience(client.settings.ambienceEnabled())
		updateShadows(client.settings.shadowsEnabled()) -- inferred equivalent call
		updateLightObjects(client.settings.lightObjectsEnabled()) -- inferred equivalent call
		updatePianoEffects(client.settings.pianoEffectsEnabled()) -- inferred equivalent call
		updateMuteOthers(client.settings.muteOthersEnabled()) -- inferred equivalent call
		updateHideOthers(client.settings.hideOthersEnabled())
		updateHeadTurn(client.settings.headTurnEnabled()) -- inferred equivalent call
		updatePortalTransition(client.settings.portalTransitionEnabled()) -- inferred equivalent call
		updateCamSway(client.settings.cameraSwayEnabled()) -- inferred equivalent call
		updateCamDelay(client.settings.cameraDelayEnabled()) -- inferred equivalent call
		updatePianoNotesLabels(client.settings.pianoNotesLabelEnabled()) -- inferred equivalent call
		updateFullScreenPiano(client.settings.fullScreenPianoEnabled()) -- inferred equivalent call
		updateTextures(client.settings.texturesEnabled()) -- inferred equivalent call
		client.settings.screenshakeEnabled.Changed(updateScreenshakeIcon)
		client.settings.itemSoundsEnabled.Changed(updateItemSounds)
		client.settings.nametagsEnabled.Changed(updateNametags)
		client.settings.ambienceEnabled.Changed(updateAmbience)
		client.settings.shadowsEnabled.Changed(updateShadows)
		client.settings.lightObjectsEnabled.Changed(updateLightObjects)
		client.settings.pianoEffectsEnabled.Changed(updatePianoEffects)
		client.settings.muteOthersEnabled.Changed(updateMuteOthers)
		client.settings.hideOthersEnabled.Changed(updateHideOthers)
		client.settings.headTurnEnabled.Changed(updateHeadTurn)
		client.settings.portalTransitionEnabled.Changed(updatePortalTransition)
		client.settings.cameraSwayEnabled.Changed(updateCamSway)
		client.settings.cameraDelayEnabled.Changed(updateCamDelay)
		client.settings.pianoNotesLabelEnabled.Changed(updatePianoNotesLabels)
		client.settings.fullScreenPianoEnabled.Changed(updateFullScreenPiano)
		client.settings.texturesEnabled.Changed(updateTextures)
	end
}