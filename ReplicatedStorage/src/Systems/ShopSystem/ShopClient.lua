local ShopClient = {}

local module = require("../../Shared/Data")
local client = module.client
local module2 = require("./ShopData")
local module3 = require("./ShopNet")
local module4 = require("../../Client/MenuTopbar")

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Click = ReplicatedStorage.Assets.Sounds.Click

local ShopGui = PlayerGui:WaitForChild("ShopGui")
local ShopFrame = ShopGui:WaitForChild("ShopFrame")

local closeButton = ShopFrame:WaitForChild("Header"):WaitForChild("CloseButton")

local CategoryFrame = ShopFrame:WaitForChild("CategoryFrame")
local CategoryTemplateButton = CategoryFrame:WaitForChild("CategoryTemplateButton")
CategoryTemplateButton.Visible = false

local InfoFrame = ShopFrame:WaitForChild("InfoFrame")
local BuyButton = InfoFrame:WaitForChild("BuyButton")
local ImageLabel = InfoFrame:WaitForChild("ImageLabel")
local NameLabel = InfoFrame:WaitForChild("NameLabel")
local DescLabel = InfoFrame:WaitForChild("DescLabel")
local CostLabel = InfoFrame:WaitForChild("CostLabel")

local ItemScrollingFrame = ShopFrame:WaitForChild("ItemScrollingFrame")
local ItemTemplateButton = ItemScrollingFrame:WaitForChild("ItemTemplateButton")
ItemTemplateButton.Visible = false

local v = nil
local clonesById = {}
local categoryIdsById = {}
local clonesById2 = {}
local v2 = {}

local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(0, 0, 0)

local function isPermanent(p): boolean -- 1 equivalent call inferred from this helper
	return p.Type == "Tool" or p.Type == "Emote" or p.Type == "Gamepass"
end

local function isOwned(data) -- 1 equivalent call inferred from this helper
	return isPermanent(data) and client.inventory()[data.Id] == true -- inferred equivalent call
end

local function updateCostLabelAsync(data)
	if data.Currency ~= "Robux" then
		CostLabel.Text = tostring(data.Cost) .. " " .. data.Currency
		return
	end

	local text = v2[data.Id]

	if text then
		CostLabel.Text = text
		return
	end

	CostLabel.Text = "R$..."
	task.spawn(function()
		local success, result = pcall(function()
			if data.Type == "Gamepass" then
				return MarketplaceService:GetProductInfoAsync(data.GamepassId, Enum.InfoType.GamePass)
			end

			return MarketplaceService:GetProductInfoAsync(data.ProductId, Enum.InfoType.Product)
		end)

		local text2 = success and result and result.PriceInRobux and "R$" .. tostring(result.PriceInRobux) or "R$?"
		v2[data.Id] = text2

		if v == data then
			CostLabel.Text = text2
		end
	end)
end

local function selectItem(data)
	Click:Play()
	v = data
	InfoFrame.Visible = true

	for k, v3 in clonesById do
		local uiStroke = v3.UIStroke
		local color3 = if k == data.Id then color else color2
		uiStroke.Color = color3
	end

	ImageLabel.Image = data.Image
	NameLabel.Text = data.Name
	DescLabel.Text = data.Description
	updateCostLabelAsync(data)

	if isOwned(data) then -- inferred equivalent call
		BuyButton.Text = "Owned"
		BuyButton.Active = false
	else
		BuyButton.Text = "Buy"
		BuyButton.Active = true
	end
end

local function showCategory(id)
	Click:Play()

	for k, v3 in clonesById2 do
		v3.UIStroke.Transparency = k == id and 0 or 0.5
	end

	for k, v3 in clonesById do
		v3.Visible = categoryIdsById[k] == id
	end
end

local function buildCategories()
	for _, category in module2.Categories do
		local clone = CategoryTemplateButton:Clone()
		clone.Name = category.Id
		clone.Text = category.Name
		clone.ImageLabel.Image = category.Image
		clone.Visible = true
		clone.Parent = CategoryFrame
		clone.MouseButton1Click:Connect(function()
			showCategory(category.Id)
		end)
		clonesById2[category.Id] = clone
	end
end

local function buildItems()
	for _, item in module2.Items do
		local clone = ItemTemplateButton:Clone()
		clone.Name = item.Id
		clone.ItemImage.Image = item.Image
		clone.ItemName.Text = item.Name
		clone.Visible = false
		clone.Parent = ItemScrollingFrame
		clone.MouseButton1Click:Connect(function()
			selectItem(item)
		end)
		clonesById[item.Id] = clone
		categoryIdsById[item.Id] = item.CategoryId
	end
end

BuyButton.MouseButton1Click:Connect(function()
	if not v then
		return
	end

	Click:Play()

	local v3 = v

	if v3.Type == "Gamepass" then
		MarketplaceService:PromptGamePassPurchase(LocalPlayer, v3.GamepassId)
		return
	end

	if v3.Type == "DeveloperProduct" then
		MarketplaceService:PromptProductPurchase(LocalPlayer, v3.ProductId)
		return
	end

	local v4, _ = module3.PurchaseShopItem:InvokeServer(v3.Id)

	if v4 and v == v3 then
		selectItem(v3)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, p2, p3)
	if p ~= LocalPlayer or not p3 then
		return
	end

	if v and v.GamepassId == p2 then
		selectItem(v)
	end
end)

function ShopClient.Start()
	buildCategories()
	buildItems()

	if module2.Categories[1] then
		showCategory(module2.Categories[1].Id)
	end

	function module4.ShopSelected()
		ShopGui.Enabled = true
	end
	function module4.ShopDeselected()
		ShopGui.Enabled = false
	end
	closeButton.MouseButton1Click:Connect(function()
		Click:Play()
		ShopGui.Enabled = false
		module4.ShopIcon:deselect()
	end)
end

return ShopClient