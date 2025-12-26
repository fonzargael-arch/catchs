--[[
    ═══════════════════════════════════════
    🔥 GF PROFESSIONAL HUB
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Game: Pet/Animal Simulator
    Features: ESP, Auto Farm, Insta Catch, Christmas Event
    ═══════════════════════════════════════
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Load Modern UI Library (Rayfield)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables
local espEnabled = false
local espConnections = {}
local instaCatchEnabled = false
local autoCollectEnabled = false
local autoFeedEnabled = false
local autoBreedEnabled = false
local espSettings = {
    ShowCommon = true,
    ShowRare = true,
    ShowEpic = true,
    ShowLegendary = true,
    ShowMythical = true,
    ShowExclusive = true,
    Distance = 1000
}

-- Remotes (from your scan)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ThrowLasso = Remotes:WaitForChild("ThrowLasso")
local UpdateProgress = Remotes:WaitForChild("UpdateProgress")
local collectPetCash = Remotes:WaitForChild("collectPetCash")
local collectAllPetCash = Remotes:WaitForChild("collectAllPetCash")
local minigameRequest = Remotes:WaitForChild("minigameRequest")
local breedRequest = Remotes:WaitForChild("breedRequest")
local getPetInventory = Remotes:WaitForChild("getPetInventory")

-- Christmas Event Remotes
local ClaimFeepEgg = Remotes:WaitForChild("ClaimFeepEgg")
local superLuckSpins = Remotes:WaitForChild("superLuckSpins")

-- Create Window
local Window = Rayfield:CreateWindow({
    Name = "🔥 GF Professional Hub",
    LoadingTitle = "GF Hub Loading...",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GFHub",
        FileName = "PetSimConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = false
    },
    KeySystem = false
})

-- ═══════════════════════════════════════
-- 🎯 ESP FUNCTIONS
-- ═══════════════════════════════════════

local function getPetRarity(petName)
    -- Detect rarity based on pet name or egg type
    local name = petName:lower()
    
    if name:find("mythical") or name:find("celestial") or name:find("galaxy") then
        return "Mythical", Color3.fromRGB(255, 0, 255)
    elseif name:find("legendary") or name:find("unicorn") or name:find("griffin") then
        return "Legendary", Color3.fromRGB(255, 215, 0)
    elseif name:find("epic") or name:find("sabertooth") then
        return "Epic", Color3.fromRGB(138, 43, 226)
    elseif name:find("rare") or name:find("snow") then
        return "Rare", Color3.fromRGB(0, 191, 255)
    elseif name:find("exclusive") or name:find("xmas") then
        return "Exclusive", Color3.fromRGB(255, 105, 180)
    else
        return "Common", Color3.fromRGB(150, 150, 150)
    end
end

local function createESP(object, name, color)
    if object:FindFirstChild("GF_ESP") then return end
    
    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Name = "GF_ESP"
    billboardGui.Parent = object
    billboardGui.AlwaysOnTop = true
    billboardGui.Size = UDim2.new(0, 100, 0, 50)
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    
    local frame = Instance.new("Frame")
    frame.Parent = billboardGui
    frame.BackgroundColor3 = color
    frame.BackgroundTransparency = 0.5
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BorderSizePixel = 2
    frame.BorderColor3 = color
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = frame
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 0.6, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Text = name
    textLabel.TextStrokeTransparency = 0
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Parent = frame
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0.4, 0)
    distLabel.Position = UDim2.new(0, 0, 0.6, 0)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextScaled = true
    distLabel.TextStrokeTransparency = 0
    
    -- Update distance
    RunService.RenderStepped:Connect(function()
        if object and object.Parent and humanoidRootPart then
            local dist = (object.Position - humanoidRootPart.Position).Magnitude
            distLabel.Text = math.floor(dist) .. "m"
            
            -- Hide if too far
            if dist > espSettings.Distance then
                billboardGui.Enabled = false
            else
                billboardGui.Enabled = true
            end
        end
    end)
end

local function enableESP()
    espEnabled = true
    
    -- ESP for Tools/Eggs
    for _, tool in pairs(ReplicatedStorage.Assets.Tools:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Handle") then
            local rarity, color = getPetRarity(tool.Name)
            
            if (rarity == "Common" and espSettings.ShowCommon) or
               (rarity == "Rare" and espSettings.ShowRare) or
               (rarity == "Epic" and espSettings.ShowEpic) or
               (rarity == "Legendary" and espSettings.ShowLegendary) or
               (rarity == "Mythical" and espSettings.ShowMythical) or
               (rarity == "Exclusive" and espSettings.ShowExclusive) then
                createESP(tool.Handle, tool.Name .. " [" .. rarity .. "]", color)
            end
        end
    end
    
    -- ESP for Workspace Pets
    local function scanWorkspace()
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                local name = obj.Name
                if name:find("Egg") or name:find("Pet") or getPetRarity(name) ~= "Common" then
                    local rarity, color = getPetRarity(name)
                    createESP(obj.HumanoidRootPart, name .. " [" .. rarity .. "]", color)
                end
            end
        end
    end
    
    scanWorkspace()
    
    -- Monitor new objects
    table.insert(espConnections, Workspace.DescendantAdded:Connect(function(obj)
        if espEnabled then
            wait(0.1)
            if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") then
                local name = obj.Name
                if name:find("Egg") or name:find("Pet") then
                    local rarity, color = getPetRarity(name)
                    createESP(obj.HumanoidRootPart, name .. " [" .. rarity .. "]", color)
                end
            end
        end
    end))
end

local function disableESP()
    espEnabled = false
    
    for _, connection in pairs(espConnections) do
        connection:Disconnect()
    end
    espConnections = {}
    
    -- Remove all ESP
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "GF_ESP" then
            obj:Destroy()
        end
    end
    
    for _, obj in pairs(ReplicatedStorage:GetDescendants()) do
        if obj.Name == "GF_ESP" then
            obj:Destroy()
        end
    end
end

-- ═══════════════════════════════════════
-- 🎣 INSTA CATCH FUNCTION
-- ═══════════════════════════════════════

local originalUpdateProgress

local function setupInstaCatch()
    if instaCatchEnabled then
        -- Hook UpdateProgress to auto-complete
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "FireServer" and self == UpdateProgress then
                -- Force 100% progress
                args[1] = 1
                return oldNamecall(self, unpack(args))
            end
            
            return oldNamecall(self, ...)
        end)
        
        setreadonly(mt, true)
        
        Rayfield:Notify({
            Title = "✅ Insta Catch Enabled",
            Content = "Lasso will auto-complete!",
            Duration = 3,
            Image = 4483362458
        })
    end
end

-- ═══════════════════════════════════════
-- 💰 AUTO COLLECT CASH
-- ═══════════════════════════════════════

spawn(function()
    while wait(5) do
        if autoCollectEnabled then
            pcall(function()
                collectAllPetCash:FireServer()
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🍖 AUTO FEED PETS
-- ═══════════════════════════════════════

local FoodService = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services.FoodService
local FeedPet = FoodService.RF.FeedPet

spawn(function()
    while wait(10) do
        if autoFeedEnabled then
            pcall(function()
                local inventory = getPetInventory:InvokeServer()
                if inventory then
                    for _, pet in pairs(inventory) do
                        -- Feed with best food
                        FeedPet:InvokeServer(pet.id, "Prime Feed")
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🐣 AUTO BREEDING
-- ═══════════════════════════════════════

spawn(function()
    while wait(30) do
        if autoBreedEnabled then
            pcall(function()
                local inventory = getPetInventory:InvokeServer()
                if inventory and #inventory >= 2 then
                    -- Breed best pets
                    breedRequest:InvokeServer(inventory[1].id, inventory[2].id)
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🎨 GUI TABS
-- ═══════════════════════════════════════

-- MAIN TAB
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

local MainSection = MainTab:CreateSection("Main Features")

local InstaCatchToggle = MainTab:CreateToggle({
    Name = "🎯 Insta Catch (Auto Complete)",
    CurrentValue = false,
    Flag = "InstaCatch",
    Callback = function(Value)
        instaCatchEnabled = Value
        if Value then
            setupInstaCatch()
        end
    end,
})

local AutoCollectToggle = MainTab:CreateToggle({
    Name = "💰 Auto Collect Pet Cash",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(Value)
        autoCollectEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "💰 Auto Collect",
                Content = "Collecting cash every 5 seconds",
                Duration = 3
            })
        end
    end,
})

local AutoFeedToggle = MainTab:CreateToggle({
    Name = "🍖 Auto Feed Pets",
    CurrentValue = false,
    Flag = "AutoFeed",
    Callback = function(Value)
        autoFeedEnabled = Value
    end,
})

local AutoBreedToggle = MainTab:CreateToggle({
    Name = "🐣 Auto Breeding",
    CurrentValue = false,
    Flag = "AutoBreed",
    Callback = function(Value)
        autoBreedEnabled = Value
    end,
})

MainTab:CreateButton({
    Name = "🚀 Collect All Cash NOW",
    Callback = function()
        collectAllPetCash:FireServer()
        Rayfield:Notify({
            Title = "💵 Collected!",
            Content = "All pet cash collected",
            Duration = 2
        })
    end,
})

-- ESP TAB
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

local ESPSection = ESPTab:CreateSection("ESP Settings")

local ESPToggle = ESPTab:CreateToggle({
    Name = "🔍 Enable ESP",
    CurrentValue = false,
    Flag = "ESP",
    Callback = function(Value)
        if Value then
            enableESP()
        else
            disableESP()
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Show Common",
    CurrentValue = true,
    Flag = "ShowCommon",
    Callback = function(Value)
        espSettings.ShowCommon = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Show Rare",
    CurrentValue = true,
    Flag = "ShowRare",
    Callback = function(Value)
        espSettings.ShowRare = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Show Epic",
    CurrentValue = true,
    Flag = "ShowEpic",
    Callback = function(Value)
        espSettings.ShowEpic = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Show Legendary",
    CurrentValue = true,
    Flag = "ShowLegendary",
    Callback = function(Value)
        espSettings.ShowLegendary = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Show Mythical",
    CurrentValue = true,
    Flag = "ShowMythical",
    Callback = function(Value)
        espSettings.ShowMythical = Value
    end,
})

ESPTab:CreateToggle({
    Name = "Show Exclusive",
    CurrentValue = true,
    Flag = "ShowExclusive",
    Callback = function(Value)
        espSettings.ShowExclusive = Value
    end,
})

ESPTab:CreateSlider({
    Name = "ESP Distance",
    Range = {100, 5000},
    Increment = 100,
    CurrentValue = 1000,
    Flag = "ESPDistance",
    Callback = function(Value)
        espSettings.Distance = Value
    end,
})

-- CHRISTMAS EVENT TAB
local XmasTab = Window:CreateTab("🎄 Christmas Event", 4483362458)

local XmasSection = XmasTab:CreateSection("Christmas Features")

XmasTab:CreateButton({
    Name = "🎁 Claim Feep Egg",
    Callback = function()
        ClaimFeepEgg:FireServer()
        Rayfield:Notify({
            Title = "🎄 Christmas",
            Content = "Feep Egg claimed!",
            Duration = 3
        })
    end,
})

XmasTab:CreateButton({
    Name = "🍀 Use Super Luck Spin",
    Callback = function()
        superLuckSpins:FireServer()
        Rayfield:Notify({
            Title = "🍀 Luck Spin",
            Content = "Super luck activated!",
            Duration = 3
        })
    end,
})

local XmasFarmSection = XmasTab:CreateSection("Auto Farm Christmas")

local autoXmasFarm = false

XmasTab:CreateToggle({
    Name = "🎅 Auto Claim Christmas Rewards",
    CurrentValue = false,
    Flag = "AutoXmas",
    Callback = function(Value)
        autoXmasFarm = Value
    end,
})

spawn(function()
    while wait(60) do
        if autoXmasFarm then
            pcall(function()
                ClaimFeepEgg:FireServer()
                wait(1)
                superLuckSpins:FireServer()
            end)
        end
    end
end)

-- MISC TAB
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

local MiscSection = MiscTab:CreateSection("Miscellaneous")

MiscTab:CreateButton({
    Name = "🚀 Teleport to Store",
    Callback = function()
        local store = Workspace.PlayerPens["1"].Store
        if store then
            humanoidRootPart.CFrame = store.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        end
    end,
})

MiscTab:CreateButton({
    Name = "🏠 Teleport to My Pen",
    Callback = function()
        local myPen = Workspace.PlayerPens:FindFirstChild(tostring(player.UserId))
        if myPen then
            humanoidRootPart.CFrame = myPen.StarterPen.HumanoidRootPart.CFrame + Vector3.new(0, 5, 0)
        end
    end,
})

local SpeedSlider = MiscTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 150},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(Value)
        character.Humanoid.WalkSpeed = Value
    end,
})

local JumpSlider = MiscTab:CreateSlider({
    Name = "🦘 JumpPower",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(Value)
        character.Humanoid.JumpPower = Value
    end,
})

-- INFO TAB
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateParagraph({Title = "🔥 GF Professional Hub", Content = "Created by: Gael Fonzar\n\nFeatures:\n• Insta Catch (Auto-complete lasso)\n• Auto Collect Cash\n• Auto Feed Pets\n• Auto Breeding\n• ESP by Rarity\n• Christmas Event Auto Farm\n• Speed/Jump modifications\n\nEnjoy! 🚀"})

InfoTab:CreateParagraph({Title = "📊 Scan Stats", Content = "RemoteEvents: 126\nRemoteFunctions: 112\nModuleScripts: 820\nTools Found: 60\nGUIs: 137"})

InfoTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
    end,
})

-- ═══════════════════════════════════════
-- 🚀 STARTUP
-- ═══════════════════════════════════════

Rayfield:Notify({
    Title = "🔥 GF Hub Loaded",
    Content = "Welcome " .. player.Name .. "!",
    Duration = 5,
    Image = 4483362458
})

print("═══════════════════════════════════")
print("🔥 GF Professional Hub Loaded!")
print("Created by: Gael Fonzar")
print("═══════════════════════════════════")
