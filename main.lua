--[[
    ═══════════════════════════════════════
    🔥 GF PROFESSIONAL HUB - FIXED
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Game: Pet/Animal Simulator
    ═══════════════════════════════════════
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Variables
local espEnabled = false
local instaCatchEnabled = false
local autoCollectEnabled = false
local autoFeedEnabled = false
local autoBreedEnabled = false
local espObjects = {}

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local collectAllPetCash = Remotes:WaitForChild("collectAllPetCash")
local getPetInventory = Remotes:WaitForChild("getPetInventory")
local breedRequest = Remotes:WaitForChild("breedRequest")
local minigameRequest = Remotes:WaitForChild("minigameRequest")

-- Knit Services
local KnitServices = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services
local FoodService = KnitServices:FindFirstChild("FoodService")
local FeedPet = FoodService and FoodService.RF:FindFirstChild("FeedPet")

-- ═══════════════════════════════════════
-- 🎯 INSTA CATCH - FIXED
-- ═══════════════════════════════════════

local instaCatchConnection

local function enableInstaCatch()
    if instaCatchConnection then
        instaCatchConnection:Disconnect()
    end
    
    -- Hook the minigame directly
    instaCatchConnection = RunService.Heartbeat:Connect(function()
        if instaCatchEnabled then
            local playerGui = player:WaitForChild("PlayerGui")
            local lassoMinigame = playerGui:FindFirstChild("LassoMinigame")
            
            if lassoMinigame and lassoMinigame.Enabled then
                local mainFrame = lassoMinigame:FindFirstChild("MainFrame")
                if mainFrame and mainFrame.Visible then
                    -- Find the progress bar
                    local progressBar = mainFrame:FindFirstChildOfClass("Frame", true)
                    if progressBar then
                        for _, obj in pairs(mainFrame:GetDescendants()) do
                            -- Force complete the bar
                            if obj:IsA("Frame") and obj.Name:find("Progress") or obj.Name:find("Bar") then
                                obj.Size = UDim2.new(1, 0, obj.Size.Y.Scale, 0)
                            end
                            
                            -- Auto-click success button
                            if obj:IsA("TextButton") and (obj.Text:find("Success") or obj.Text:find("Complete") or obj.Visible) then
                                for _, connection in pairs(getconnections(obj.MouseButton1Click)) do
                                    connection:Fire()
                                end
                            end
                        end
                    end
                    
                    -- Force invoke minigame success
                    pcall(function()
                        minigameRequest:InvokeServer(true, 1) -- Complete with max score
                    end)
                end
            end
        end
    end)
end

local function disableInstaCatch()
    if instaCatchConnection then
        instaCatchConnection:Disconnect()
        instaCatchConnection = nil
    end
end

-- ═══════════════════════════════════════
-- 👁️ ESP - FIXED
-- ═══════════════════════════════════════

local function getRarityColor(name)
    local lower = name:lower()
    
    if lower:find("mythical") or lower:find("celestial") or lower:find("galaxy") then
        return Color3.fromRGB(255, 0, 255), "Mythical"
    elseif lower:find("legendary") or lower:find("unicorn") or lower:find("griffin") then
        return Color3.fromRGB(255, 215, 0), "Legendary"
    elseif lower:find("epic") or lower:find("sabertooth") then
        return Color3.fromRGB(138, 43, 226), "Epic"
    elseif lower:find("rare") or lower:find("snow") then
        return Color3.fromRGB(0, 191, 255), "Rare"
    elseif lower:find("exclusive") or lower:find("xmas") or lower:find("christmas") then
        return Color3.fromRGB(255, 105, 180), "Exclusive"
    else
        return Color3.fromRGB(150, 150, 150), "Common"
    end
end

local function createESP(object, displayName)
    if object:FindFirstChild("GF_ESP_MARKER") then return end
    
    -- Create highlight
    local highlight = Instance.new("Highlight")
    highlight.Name = "GF_ESP_MARKER"
    highlight.Parent = object
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    local color, rarity = getRarityColor(displayName)
    highlight.FillColor = color
    highlight.OutlineColor = color
    
    -- Create billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "GF_ESP_TEXT"
    billboard.Parent = object
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Parent = billboard
    textLabel.BackgroundTransparency = 1
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 16
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Text = displayName .. " [" .. rarity .. "]"
    
    local distLabel = Instance.new("TextLabel")
    distLabel.Parent = billboard
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(1, 0, 0.5, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.Font = Enum.Font.Gotham
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextSize = 14
    distLabel.TextStrokeTransparency = 0
    
    -- Update distance
    local updateConnection
    updateConnection = RunService.RenderStepped:Connect(function()
        if object and object.Parent and humanoidRootPart then
            local distance = (object.Position - humanoidRootPart.Position).Magnitude
            distLabel.Text = math.floor(distance) .. "m"
        else
            updateConnection:Disconnect()
        end
    end)
    
    table.insert(espObjects, {obj = object, highlight = highlight, billboard = billboard, connection = updateConnection})
end

local function clearESP()
    for _, espData in pairs(espObjects) do
        if espData.highlight then espData.highlight:Destroy() end
        if espData.billboard then espData.billboard:Destroy() end
        if espData.connection then espData.connection:Disconnect() end
    end
    espObjects = {}
end

local function scanForPets()
    -- Scan workspace for pets/eggs
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local name = obj.Name:lower()
            -- Check if it's a pet or egg
            if name:find("egg") or name:find("pet") or name:find("animal") or 
               name:find("wolf") or name:find("fox") or name:find("leopard") or
               name:find("unicorn") or name:find("axolotl") or name:find("griffin") then
                
                local mainPart = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Handle") or obj.PrimaryPart
                if mainPart then
                    createESP(mainPart, obj.Name)
                end
            end
        elseif obj:IsA("Tool") and obj.Parent == Workspace then
            local handle = obj:FindFirstChild("Handle")
            if handle and obj.Name:find("Egg") then
                createESP(handle, obj.Name)
            end
        end
    end
    
    -- Scan ReplicatedStorage tools
    local toolsFolder = ReplicatedStorage:FindFirstChild("Assets")
    if toolsFolder then
        toolsFolder = toolsFolder:FindFirstChild("Tools")
        if toolsFolder then
            for _, tool in pairs(toolsFolder:GetChildren()) do
                if tool:IsA("Tool") then
                    local handle = tool:FindFirstChild("Handle")
                    if handle and tool.Name:find("Egg") then
                        createESP(handle, tool.Name)
                    end
                end
            end
        end
    end
end

local espScanConnection

local function enableESP()
    espEnabled = true
    clearESP()
    scanForPets()
    
    -- Continuous scanning for new pets
    espScanConnection = RunService.Heartbeat:Connect(function()
        if espEnabled then
            wait(2) -- Scan every 2 seconds
            scanForPets()
        end
    end)
end

local function disableESP()
    espEnabled = false
    if espScanConnection then
        espScanConnection:Disconnect()
    end
    clearESP()
end

-- ═══════════════════════════════════════
-- 💰 AUTO COLLECT - WORKING
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
-- 🍖 AUTO FEED
-- ═══════════════════════════════════════

spawn(function()
    while wait(15) do
        if autoFeedEnabled and FeedPet then
            pcall(function()
                local inventory = getPetInventory:InvokeServer()
                if inventory then
                    for _, petData in pairs(inventory) do
                        if petData.id then
                            FeedPet:InvokeServer(petData.id, "Prime Feed")
                            wait(0.5)
                        end
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🐣 AUTO BREED
-- ═══════════════════════════════════════

spawn(function()
    while wait(30) do
        if autoBreedEnabled then
            pcall(function()
                local inventory = getPetInventory:InvokeServer()
                if inventory and #inventory >= 2 then
                    breedRequest:InvokeServer(inventory[1].id, inventory[2].id)
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🎨 CREATE GUI
-- ═══════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "🔥 GF Professional Hub - Fixed",
    LoadingTitle = "Loading GF Hub...",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {
        Enabled = false
    },
    KeySystem = false
})

-- MAIN TAB
local MainTab = Window:CreateTab("🏠 Main", 4483362458)

MainTab:CreateToggle({
    Name = "🎯 Insta Catch (Auto Complete Minigame)",
    CurrentValue = false,
    Callback = function(Value)
        instaCatchEnabled = Value
        if Value then
            enableInstaCatch()
            Rayfield:Notify({
                Title = "✅ Insta Catch ON",
                Content = "Lasso minigame will auto-complete!",
                Duration = 3
            })
        else
            disableInstaCatch()
        end
    end,
})

MainTab:CreateToggle({
    Name = "💰 Auto Collect Cash (Every 5s)",
    CurrentValue = false,
    Callback = function(Value)
        autoCollectEnabled = Value
        if Value then
            Rayfield:Notify({
                Title = "💰 Auto Collect ON",
                Content = "Collecting cash automatically",
                Duration = 3
            })
        end
    end,
})

MainTab:CreateToggle({
    Name = "🍖 Auto Feed Pets",
    CurrentValue = false,
    Callback = function(Value)
        autoFeedEnabled = Value
    end,
})

MainTab:CreateToggle({
    Name = "🐣 Auto Breeding",
    CurrentValue = false,
    Callback = function(Value)
        autoBreedEnabled = Value
    end,
})

MainTab:CreateButton({
    Name = "💵 Collect All Cash NOW",
    Callback = function()
        collectAllPetCash:FireServer()
        Rayfield:Notify({
            Title = "💵 Collected!",
            Content = "Cash collected successfully",
            Duration = 2
        })
    end,
})

-- ESP TAB
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "🔍 Enable Pet/Egg ESP",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            enableESP()
            Rayfield:Notify({
                Title = "👁️ ESP Enabled",
                Content = "Showing all pets and eggs",
                Duration = 3
            })
        else
            disableESP()
        end
    end,
})

ESPTab:CreateButton({
    Name = "🔄 Refresh ESP",
    Callback = function()
        if espEnabled then
            clearESP()
            scanForPets()
            Rayfield:Notify({
                Title = "🔄 ESP Refreshed",
                Content = "Scanning for pets...",
                Duration = 2
            })
        end
    end,
})

-- CHRISTMAS TAB
local XmasTab = Window:CreateTab("🎄 Christmas", 4483362458)

local ClaimFeepEgg = Remotes:WaitForChild("ClaimFeepEgg")
local superLuckSpins = Remotes:WaitForChild("superLuckSpins")

XmasTab:CreateButton({
    Name = "🎁 Claim Feep Egg",
    Callback = function()
        ClaimFeepEgg:FireServer()
        Rayfield:Notify({
            Title = "🎄 Claimed",
            Content = "Feep Egg claimed!",
            Duration = 2
        })
    end,
})

XmasTab:CreateButton({
    Name = "🍀 Use Super Luck Spin",
    Callback = function()
        superLuckSpins:FireServer()
        Rayfield:Notify({
            Title = "🍀 Activated",
            Content = "Super luck spin used!",
            Duration = 2
        })
    end,
})

-- MISC TAB
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 150},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.WalkSpeed = Value
        end
    end,
})

MiscTab:CreateSlider({
    Name = "🦘 JumpPower",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.JumpPower = Value
        end
    end,
})

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
    end,
})

-- INFO TAB
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateParagraph({
    Title = "🔥 GF Hub - Fixed Version", 
    Content = "Created by: Gael Fonzar\n\n✅ WORKING:\n• Insta Catch\n• Auto Collect Cash\n• ESP for Pets/Eggs\n• Auto Feed\n• Auto Breed\n• Christmas Event\n\nEnjoy! 🚀"
})

-- STARTUP
Rayfield:Notify({
    Title = "🔥 GF Hub Loaded",
    Content = "Welcome " .. player.Name .. "! All features fixed.",
    Duration = 5
})

print("═══════════════════════════════════")
print("🔥 GF Hub Loaded Successfully!")
print("Created by: Gael Fonzar")
print("═══════════════════════════════════")
