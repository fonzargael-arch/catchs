--[[
    ═══════════════════════════════════════
    🔥 GF ULTIMATE HUB - FULLY WORKING
    ═══════════════════════════════════════
    Created by: Gael Fonzar
    Based on REAL scanned remotes
    ═══════════════════════════════════════
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════════════════════════════════
-- GET ALL REMOTES FROM SCAN
-- ═══════════════════════════════════════

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Main Remotes
local collectAllPetCash = Remotes:FindFirstChild("collectAllPetCash")
local collectPetCash = Remotes:FindFirstChild("collectPetCash")
local UpdateProgress = Remotes:FindFirstChild("UpdateProgress")
local ThrowLasso = Remotes:FindFirstChild("ThrowLasso")
local CancelMinigame = Remotes:FindFirstChild("CancelMinigame")

-- Functions
local getPetInventory = Remotes:FindFirstChild("getPetInventory")
local sellPet = Remotes:FindFirstChild("sellPet")
local sellEgg = Remotes:FindFirstChild("sellEgg")
local getEggInventory = Remotes:FindFirstChild("getEggInventory")
local breedRequest = Remotes:FindFirstChild("breedRequest")
local placeEgg = Remotes:FindFirstChild("placeEgg")
local pickupRequest = Remotes:FindFirstChild("pickupRequest")
local minigameRequest = Remotes:FindFirstChild("minigameRequest")
local toggleFavorite = Remotes:FindFirstChild("toggleFavorite")
local equipLassoVisual = Remotes:FindFirstChild("equipLassoVisual")

-- Christmas Event
local ClaimFeepEgg = Remotes:FindFirstChild("ClaimFeepEgg")
local superLuckSpins = Remotes:FindFirstChild("superLuckSpins")

-- Knit Services
local KnitPath = ReplicatedStorage.Packages._Index["sleitnick_knit@1.7.0"].knit.Services

-- Food Service
local FoodService = KnitPath:FindFirstChild("FoodService")
local FeedPet = FoodService and FoodService.RF:FindFirstChild("FeedPet")

-- Egg Service
local EggService = KnitPath:FindFirstChild("EggService")
local InstantHatch = EggService and EggService.RE:FindFirstChild("InstantHatch")

-- Pen Service
local PenService = KnitPath:FindFirstChild("PenService")
local extendFence = PenService and PenService.RF:FindFirstChild("extendFence")
local getMaxPetsForPlayer = PenService and PenService.RF:FindFirstChild("getMaxPetsForPlayer")

-- Lasso Service
local LassoService = KnitPath:FindFirstChild("LassoService")
local BuyLasso = LassoService and LassoService.RE:FindFirstChild("BuyLasso")
local EquipLasso = LassoService and LassoService.RE:FindFirstChild("EquipLasso")

-- Timer Service
local TimerService = KnitPath:FindFirstChild("TimerService")
local RequestEggHatch = TimerService and TimerService.RF:FindFirstChild("RequestEggHatch")

-- Variables
local instaCatchEnabled = false
local autoCollectEnabled = false
local autoFeedEnabled = false
local autoBreedEnabled = false
local autoHatchEnabled = false
local espEnabled = false
local infiniteJumpEnabled = false
local espConnections = {}

-- ═══════════════════════════════════════
-- 🎯 INSTA CATCH - WORKING METHOD
-- ═══════════════════════════════════════

local instaCatchConnection
local originalNamecall

local function hookInstaCatch()
    -- Method 1: Hook the minigame GUI
    instaCatchConnection = RunService.Heartbeat:Connect(function()
        if not instaCatchEnabled then return end
        
        local lassoUI = playerGui:FindFirstChild("LassoMinigame")
        if lassoUI and lassoUI.Enabled then
            -- Force complete any progress bars
            for _, descendant in pairs(lassoUI:GetDescendants()) do
                if descendant:IsA("Frame") and descendant.Name:lower():find("progress") then
                    descendant.Size = UDim2.new(1, 0, descendant.Size.Y.Scale, descendant.Size.Y.Offset)
                end
                
                -- Auto click success buttons
                if descendant:IsA("TextButton") then
                    local text = descendant.Text:lower()
                    if text:find("success") or text:find("perfect") or text:find("good") then
                        task.spawn(function()
                            for _, signal in pairs(getconnections(descendant.MouseButton1Click)) do
                                signal:Fire()
                            end
                        end)
                    end
                end
            end
            
            -- Force invoke success
            if minigameRequest then
                pcall(function()
                    minigameRequest:InvokeServer(1)
                end)
            end
        end
    end)
    
    -- Method 2: Hook UpdateProgress remote
    if UpdateProgress then
        local mt = getrawmetatable(game)
        local oldNamecall = mt.__namecall
        setreadonly(mt, false)
        
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if instaCatchEnabled and method == "FireServer" and self == UpdateProgress then
                -- Force max progress
                return oldNamecall(self, 1)
            end
            
            return oldNamecall(self, ...)
        end)
        
        setreadonly(mt, true)
        originalNamecall = oldNamecall
    end
end

local function unhookInstaCatch()
    if instaCatchConnection then
        instaCatchConnection:Disconnect()
    end
end

-- ═══════════════════════════════════════
-- 👁️ ESP - WORKING
-- ═══════════════════════════════════════

local function createESP(part, text, color)
    if part:FindFirstChild("ESP_HIGHLIGHT") then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_HIGHLIGHT"
    highlight.Parent = part
    highlight.FillColor = color
    highlight.OutlineColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_TEXT"
    billboard.Parent = part
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    
    local label = Instance.new("TextLabel")
    label.Parent = billboard
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.Text = text
    
    table.insert(espConnections, {highlight, billboard})
end

local function enableESP()
    espEnabled = true
    
    -- ESP for eggs in workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:find("Egg") then
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                createESP(part, obj.Name, Color3.fromRGB(255, 215, 0))
            end
        end
    end
    
    -- ESP for pets
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and (obj:FindFirstChild("Humanoid") or obj.Name:lower():find("pet")) then
            local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
            if part and not obj:IsDescendantOf(player.Character) then
                createESP(part, obj.Name, Color3.fromRGB(0, 255, 255))
            end
        end
    end
    
    -- Monitor new objects
    table.insert(espConnections, Workspace.DescendantAdded:Connect(function(obj)
        if not espEnabled then return end
        wait(0.1)
        
        if obj:IsA("Model") and obj.Name:find("Egg") then
            local part = obj:FindFirstChildWhichIsA("BasePart", true)
            if part then
                createESP(part, obj.Name, Color3.fromRGB(255, 215, 0))
            end
        end
    end))
end

local function disableESP()
    espEnabled = false
    
    for _, connection in pairs(espConnections) do
        if typeof(connection) == "RBXScriptConnection" then
            connection:Disconnect()
        elseif typeof(connection) == "table" then
            for _, obj in pairs(connection) do
                if typeof(obj) == "Instance" then
                    obj:Destroy()
                end
            end
        end
    end
    
    espConnections = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "ESP_HIGHLIGHT" or obj.Name == "ESP_TEXT" then
            obj:Destroy()
        end
    end
end

-- ═══════════════════════════════════════
-- 💰 AUTO COLLECT CASH
-- ═══════════════════════════════════════

task.spawn(function()
    while task.wait(3) do
        if autoCollectEnabled and collectAllPetCash then
            pcall(function()
                collectAllPetCash:FireServer()
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🍖 AUTO FEED PETS
-- ═══════════════════════════════════════

task.spawn(function()
    while task.wait(10) do
        if autoFeedEnabled and FeedPet and getPetInventory then
            pcall(function()
                local inventory = getPetInventory:InvokeServer()
                if inventory then
                    for _, pet in pairs(inventory) do
                        FeedPet:InvokeServer(pet, "Enriched Feed")
                        task.wait(0.2)
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🐣 AUTO BREED
-- ═══════════════════════════════════════

task.spawn(function()
    while task.wait(20) do
        if autoBreedEnabled and breedRequest and getPetInventory then
            pcall(function()
                local inventory = getPetInventory:InvokeServer()
                if inventory and #inventory >= 2 then
                    breedRequest:InvokeServer(inventory[1], inventory[2])
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🥚 AUTO HATCH EGGS
-- ═══════════════════════════════════════

task.spawn(function()
    while task.wait(5) do
        if autoHatchEnabled and RequestEggHatch and getEggInventory then
            pcall(function()
                local eggs = getEggInventory:InvokeServer()
                if eggs then
                    for _, egg in pairs(eggs) do
                        RequestEggHatch:InvokeServer(egg)
                        task.wait(0.5)
                    end
                end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- 🎨 CREATE GUI
-- ═══════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "🔥 GF Ultimate Hub",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Gael Fonzar",
    ConfigurationSaving = {Enabled = false},
    KeySystem = false
})

-- ═══════════════════════════════════════
-- MAIN TAB
-- ═══════════════════════════════════════

local MainTab = Window:CreateTab("🏠 Main", 4483362458)

MainTab:CreateSection("Lasso Features")

MainTab:CreateToggle({
    Name = "🎯 Insta Catch (Auto Complete)",
    CurrentValue = false,
    Callback = function(v)
        instaCatchEnabled = v
        if v then
            hookInstaCatch()
            Rayfield:Notify({Title = "✅ Insta Catch ON", Content = "Minigame will auto-complete", Duration = 3})
        else
            unhookInstaCatch()
        end
    end
})

MainTab:CreateButton({
    Name = "❌ Cancel Minigame",
    Callback = function()
        if CancelMinigame then
            CancelMinigame:FireServer()
            Rayfield:Notify({Title = "❌ Cancelled", Content = "Minigame cancelled", Duration = 2})
        end
    end
})

MainTab:CreateSection("Money & Pets")

MainTab:CreateToggle({
    Name = "💰 Auto Collect Cash (3s)",
    CurrentValue = false,
    Callback = function(v)
        autoCollectEnabled = v
        if v then
            Rayfield:Notify({Title = "💰 Auto Collect ON", Content = "Collecting every 3 seconds", Duration = 3})
        end
    end
})

MainTab:CreateButton({
    Name = "💵 Collect ALL Cash NOW",
    Callback = function()
        if collectAllPetCash then
            collectAllPetCash:FireServer()
            Rayfield:Notify({Title = "💵 Collected!", Content = "Cash collected", Duration = 2})
        end
    end
})

MainTab:CreateToggle({
    Name = "🍖 Auto Feed Pets",
    CurrentValue = false,
    Callback = function(v)
        autoFeedEnabled = v
    end
})

MainTab:CreateToggle({
    Name = "🐣 Auto Breed Pets",
    CurrentValue = false,
    Callback = function(v)
        autoBreedEnabled = v
    end
})

MainTab:CreateToggle({
    Name = "🥚 Auto Hatch Eggs",
    CurrentValue = false,
    Callback = function(v)
        autoHatchEnabled = v
    end
})

-- ═══════════════════════════════════════
-- ESP TAB
-- ═══════════════════════════════════════

local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateToggle({
    Name = "🔍 Enable ESP",
    CurrentValue = false,
    Callback = function(v)
        if v then
            enableESP()
            Rayfield:Notify({Title = "👁️ ESP ON", Content = "Showing eggs and pets", Duration = 3})
        else
            disableESP()
        end
    end
})

ESPTab:CreateButton({
    Name = "🔄 Refresh ESP",
    Callback = function()
        if espEnabled then
            disableESP()
            task.wait(0.5)
            enableESP()
            Rayfield:Notify({Title = "🔄 Refreshed", Content = "ESP updated", Duration = 2})
        end
    end
})

-- ═══════════════════════════════════════
-- CHRISTMAS TAB
-- ═══════════════════════════════════════

local XmasTab = Window:CreateTab("🎄 Christmas", 4483362458)

XmasTab:CreateButton({
    Name = "🎁 Claim Feep Egg",
    Callback = function()
        if ClaimFeepEgg then
            ClaimFeepEgg:FireServer()
            Rayfield:Notify({Title = "🎄 Claimed", Content = "Feep Egg claimed!", Duration = 2})
        end
    end
})

XmasTab:CreateButton({
    Name = "🍀 Use Super Luck Spin",
    Callback = function()
        if superLuckSpins then
            superLuckSpins:FireServer()
            Rayfield:Notify({Title = "🍀 Used", Content = "Super luck activated!", Duration = 2})
        end
    end
})

local autoXmas = false

XmasTab:CreateToggle({
    Name = "🎅 Auto Farm Christmas",
    CurrentValue = false,
    Callback = function(v)
        autoXmas = v
    end
})

task.spawn(function()
    while task.wait(30) do
        if autoXmas then
            pcall(function()
                if ClaimFeepEgg then ClaimFeepEgg:FireServer() end
                task.wait(2)
                if superLuckSpins then superLuckSpins:FireServer() end
            end)
        end
    end
end)

-- ═══════════════════════════════════════
-- TELEPORTS TAB
-- ═══════════════════════════════════════

local TpTab = Window:CreateTab("🚀 Teleports", 4483362458)

TpTab:CreateButton({
    Name = "🏠 Teleport to My Pen",
    Callback = function()
        local pens = Workspace:FindFirstChild("PlayerPens")
        if pens then
            for _, pen in pairs(pens:GetChildren()) do
                local sign = pen:FindFirstChild("Sign")
                if sign then
                    local gui = sign:FindFirstChild("GuiPart")
                    if gui then
                        local surface = gui:FindFirstChildOfClass("SurfaceGui")
                        if surface then
                            local username = surface:FindFirstChild("Username")
                            if username and username.Text == player.Name then
                                local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = pen.StarterPen:GetChildren()[1].CFrame + Vector3.new(0, 5, 0)
                                    Rayfield:Notify({Title = "🏠 Teleported", Content = "Moved to your pen", Duration = 2})
                                    return
                                end
                            end
                        end
                    end
                end
            end
        end
    end
})

-- ═══════════════════════════════════════
-- MISC TAB
-- ═══════════════════════════════════════

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")

MiscTab:CreateSlider({
    Name = "🏃 WalkSpeed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        hum.WalkSpeed = v
    end
})

MiscTab:CreateSlider({
    Name = "🦘 JumpPower",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(v)
        hum.JumpPower = v
    end
})

MiscTab:CreateToggle({
    Name = "🚀 Infinite Jump",
    CurrentValue = false,
    Callback = function(v)
        infiniteJumpEnabled = v
    end
})

game:GetService("UserInputService").JumpRequest:Connect(function()
    if infiniteJumpEnabled and hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

MiscTab:CreateButton({
    Name = "🔄 Rejoin Server",
    Callback = function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, player)
    end
})

-- ═══════════════════════════════════════
-- INFO TAB
-- ═══════════════════════════════════════

local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateParagraph({
    Title = "🔥 GF Ultimate Hub",
    Content = [[
Created by: Gael Fonzar

✅ WORKING FEATURES:
• Insta Catch
• Auto Collect Cash
• Auto Feed/Breed/Hatch
• ESP for Eggs & Pets
• Christmas Event Auto Farm
• Speed/Jump Mods
• Teleports

Based on 126 RemoteEvents
and 112 RemoteFunctions scanned!

Enjoy! 🚀
    ]]
})

-- STARTUP
Rayfield:Notify({
    Title = "🔥 GF Hub Loaded",
    Content = "Welcome " .. player.Name .. "!",
    Duration = 5
})

print("════════════════════════════════")
print("🔥 GF Ultimate Hub Loaded!")
print("Created by: Gael Fonzar")
print("════════════════════════════════")
