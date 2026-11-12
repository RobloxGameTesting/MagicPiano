local InventoryClient = {}

local module = require("../../Shared/Data")
local client = module.client
local module2 = require("../ShopSystem/ShopData")
local module3 = require("./InventoryNet")
local module4 = require("../../Client/MenuTopbar")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Click = ReplicatedStorage.Assets.Sounds.Click

local Players = game:GetService("Players")
local InventoryGui = Players.LocalPlayer.PlayerGui:WaitForChild("InventoryGui")
local InventoryFrame = InventoryGui:WaitForChild("InventoryFrame")

local closeButton = InventoryFrame:WaitForChild("Header"):WaitForChild("CloseButton")

local CategoryFrame = InventoryFrame:WaitForChild("CategoryFrame")
local CategoryTemplateButton = CategoryFrame:WaitForChild("CategoryTemplateButton")
CategoryTemplateButton.Visible = false

local InfoFrame = InventoryFrame:WaitForChild("InfoFrame")
local EquipButton = InfoFrame:WaitForChild("EquipButton")
local ImageLabel = InfoFrame:WaitForChild("ImageLabel")
local NameLabel = InfoFrame:WaitForChild("NameLabel")
local DescLabel = InfoFrame:WaitForChild("DescLabel")

local ItemScrollingFrame = InventoryFrame:WaitForChild("ItemScrollingFrame")
local ItemTemplateButton = ItemScrollingFrame:WaitForChild("ItemTemplateButton")
ItemTemplateButton.Visible = false

local color = Color3.fromRGB(255, 255, 255)
local color2 = Color3.fromRGB(0, 0, 0)

local v = nil
local clonesById = {}
local categoryIdsById = {}
local clonesById2 = {}

local v2 = { Tools = true, Emotes = true, Gamepasses = true }

local function isEquipped(data): boolean -- 1 equivalent call inferred from this helper
	return client.equippedItems()[data.Id] == true
end

local function refreshEquipButton(p, p2) -- 2 equivalent calls inferred from this helper
	if p.Type == "Gamepass" then
		EquipButton.Visible = false
		return
	end

	EquipButton.Visible = true
	EquipButton.Text = p2 and "Unequip" or "Equip"
end

local function selectItem(item)
	Click:Play()
	v = item

	InfoFrame.Visible = true

	for k, v3 in clonesById do
		local uiStroke = v3.UIStroke
		local color3 = if k == item.Id then color else color2
		uiStroke.Color = color3
	end

	ImageLabel.Image = item.Image
	NameLabel.Text = item.Name
	DescLabel.Text = item.Description
	refreshEquipButton(item, isEquipped(item)) -- inferred equivalent call
end

local function showCategory(p)
	Click:Play()

	for k, v3 in clonesById2 do
		v3.UIStroke.Transparency = k == p and 0 or 0.5
	end

	for k, v3 in clonesById do
		v3.Visible = categoryIdsById[k] == p
	end
end

local function clearItems()
	for _, v3 in clonesById do
		v3:Destroy()
	end

	table.clear(clonesById)
	table.clear(categoryIdsById)
	v = nil
	InfoFrame.Visible = false
end

local function clearCategories() -- 1 equivalent call inferred from this helper
	for _, v3 in clonesById2 do
		v3:Destroy()
	end

	table.clear(clonesById2)
end

local function buildCategories()
	for _, category in module2.Categories do
		if not v2[category.Id] then
			continue
		end

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
	local inventory = client.inventory()

	for _, item in module2.Items do
		if not (v2[item.CategoryId] and inventory[item.Id]) then
			continue
		end

		local clone = ItemTemplateButton:Clone()
		clone.Name = item.Name
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

local function refreshInventory() -- 1 equivalent call inferred from this helper
	clearCategories() -- inferred equivalent call
	clearItems()
	buildCategories()
	buildItems()
	showCategory("Tools")
end

EquipButton.MouseButton1Click:Connect(function()
	if not v then
		return
	end

	Click:Play()

	local v3 = v
	local v4 = EquipButton.Text == "Unequip"
	local v5

	if v4 then
		local _
		v5, _ = module3.UnequipItem:InvokeServer(v3.Id)
	else
		local _
		v5, _ = module3.EquipItem:InvokeServer(v3.Id)
	end

	if v5 and v == v3 then
		refreshEquipButton(v3, not v4) -- inferred equivalent call
	end
end)

function InventoryClient.Start()
	function module4.InventorySelected()
		InventoryGui.Enabled = true
		refreshInventory() -- inferred equivalent call
	end
	function module4.InventoryDeselected()
		InventoryGui.Enabled = false
	end

	closeButton.MouseButton1Click:Connect(function()
		Click:Play()
		InventoryGui.Enabled = false
		module4.InventoryIcon:deselect()
	end)
end

return InventoryClient