local ShopData = {
	Categories = {
		{ Id = "Tools", Name = "ITEMS", Image = "rbxassetid://5293578204" },
		{ Id = "Emotes", Name = "EMOTES", Image = "rbxassetid://108622256915362" },
		{ Id = "Gamepasses", Name = "GAMEPASSES", Image = "rbxassetid://13312396641" },
		{ Id = "Chimes", Name = "CHIMES", Image = "rbxassetid://98992199615101" }
	},
	Items = {
		{
			Id = "ChairTool",
			CategoryId = "Tools",
			Name = "Chair",
			Description = "Tired from standing? Have a seat.",
			Image = "rbxassetid://118349153310412",
			Currency = "Chimes",
			Cost = 20,
			Type = "Tool"
		},
		{
			Id = "FirefliesTool",
			CategoryId = "Tools",
			Name = "Fireflies",
			Description = "Fill the room with glowing fireflies.",
			Image = "rbxassetid://115341569",
			Currency = "Chimes",
			Cost = 35,
			Type = "Tool"
		},
		{
			Id = "UmbrellaTool",
			CategoryId = "Tools",
			Name = "Umbrella",
			Description = "Is it raining?",
			Image = "rbxassetid://108092484130590",
			Currency = "Chimes",
			Cost = 10,
			Type = "Tool"
		},
		{
			Id = "DrinkTool",
			CategoryId = "Tools",
			Name = "Strawberry Milk",
			Description = "Sweet!",
			Image = "rbxassetid://21384819",
			Currency = "Chimes",
			Cost = 6,
			Type = "Tool"
		},
		{
			Id = "TorchTool",
			CategoryId = "Tools",
			Name = "Torch",
			Description = "A burning stick that emits light and smoke.",
			Image = "rbxassetid://95641520521002",
			Currency = "Chimes",
			Cost = 15,
			Type = "Tool"
		},
		{
			Id = "FlowerTool",
			CategoryId = "Tools",
			Name = "Flower",
			Description = "A lovely flower.",
			Image = "rbxassetid://9950439232",
			Currency = "Chimes",
			Cost = 3,
			Type = "Tool"
		},
		{
			Id = "CakeTool",
			CategoryId = "Tools",
			Name = "Cake",
			Description = "Nom nom nom.",
			Image = "rbxassetid://16214124",
			Currency = "Chimes",
			Cost = 5,
			Type = "Tool"
		},
		{
			Id = "TeddyBearTool",
			CategoryId = "Tools",
			Name = "Teddy",
			Description = "Cute teddy bear.",
			Image = "rbxassetid://12218172",
			Currency = "Chimes",
			Cost = 5,
			Type = "Tool"
		},
		{
			Id = "LanternTool",
			CategoryId = "Tools",
			Name = "Lantern",
			Description = "Hold a lantern that emits light.",
			Image = "rbxassetid://17043658602",
			Currency = "Chimes",
			Cost = 8,
			Type = "Tool"
		},
		{
			Id = "WandTool",
			CategoryId = "Tools",
			Name = "Wand",
			Description = "A simple wand with a sparkling tip.",
			Image = "rbxassetid://93787455587635",
			Currency = "Chimes",
			Cost = 10,
			Type = "Tool"
		},
		{
			Id = "ClapEmote",
			CategoryId = "Emotes",
			Name = "Clap",
			Description = "Clap your hands!",
			Image = "rbxassetid://118297399485422",
			Currency = "Chimes",
			Cost = 5,
			Type = "Emote"
		},
		{
			Id = "BowEmote",
			CategoryId = "Emotes",
			Name = "Bow",
			Description = "A gesture to thank your audience.",
			Image = "rbxassetid://84552731080283",
			Currency = "Chimes",
			Cost = 7,
			Type = "Emote"
		},
		{
			Id = "SitEmote",
			CategoryId = "Emotes",
			Name = "Sit",
			Description = "Sit and relax anywhere.",
			Image = "rbxassetid://106822365709924",
			Currency = "Chimes",
			Cost = 15,
			Type = "Emote"
		},
		{
			Id = "FreecamGamepass",
			CategoryId = "Gamepasses",
			Name = "Freecam",
			Description = "Fly your camera anywhere!\n\nPC: Shift + P to toggle.\t↑,↓ Arrow keys to open menu.\nMobile: Thumbstick to move. \tPinch to zoom.\n",
			Image = "rbxassetid://10917637418",
			Currency = "Robux",
			Type = "Gamepass",
			GamepassId = 1976408749
		},
		{
			Id = "SmallChimes",
			CategoryId = "Chimes",
			Name = "5 Chimes",
			Description = "A few Chimes.",
			Image = "rbxassetid://98992199615101",
			Currency = "Robux",
			Type = "DeveloperProduct",
			ProductId = 3712299351,
			ChimesAmount = 5
		},
		{
			Id = "MediumChimes",
			CategoryId = "Chimes",
			Name = "15 Chimes",
			Description = "A stack of Chimes.",
			Image = "rbxassetid://98992199615101",
			Currency = "Robux",
			Type = "DeveloperProduct",
			ProductId = 3712299466,
			ChimesAmount = 15
		},
		{
			Id = "LargeChimes",
			CategoryId = "Chimes",
			Name = "75 Chimes",
			Description = "A large stack Chimes.",
			Image = "rbxassetid://98992199615101",
			Currency = "Robux",
			Type = "DeveloperProduct",
			ProductId = 3712299515,
			ChimesAmount = 75
		}
	},
	ItemsById = {}
}

for _, item in ShopData.Items do
	ShopData.ItemsById[item.Id] = item
end

return ShopData