local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Переменные игры
local Items = game:GetService("Workspace").Conveyor.Items
local Event = game:GetService("ReplicatedStorage").Remotes.Network.RemoteEvent
local CollectionSpots = game:GetService("Workspace").CollectionSpots
local Buy = game:GetService("ReplicatedStorage").Remotes.Network.RemoteEvent
local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local playercollect = nil

-- Единая таблица конфигурации
local Config = {
    Autofarm = false,
    MoveMode = "Teleport",
    Rarities = {
        ["Divine"] = false,
        ["Secret"] = false,
        ["Exotic"] = false,
        ["Mythical"] = false,
        ["Legendary"] = false,
        ["Epic"] = false,
        ["Rare"] = false,
        ["Uncommon"] = false,
        ["Common"] = false
    },
    Gear = {
        ["Watering Can"] = false, ["Fertilizer"] = false, ["Sprinkler"] = false, 
        ["Better Sprinkler"] = false, ["Trowel"] = false, ["Collector"] = false, 
        ["Copper Rod"] = false, ["Tower Sprinkler"] = false, ["Golden Watering Can"] = false, 
        ["Golden Fertilizer"] = false, ["Golden Sprinkler"] = false, ["Void Sprinkler"] = false, 
        ["Favorite Tool"] = false, ["Reclaimer"] = false
    },
    Blenders = {
        ["Void Blender"] = false, ["Diamond Blender"] = false, ["Golden Blender"] = false, 
        ["Normal Blender"] = false, ["Basic Blender"] = false
    },
    Noclip = false,
    WalkSpeed = 16,
    SpeedEnabled = false
}

-- Ищем грядку игрока для возврата
for _, p in pairs(CollectionSpots:GetChildren()) do
    if p:FindFirstChild("MyGardenGui") then
        if p:FindFirstChild("MyGardenGui").TextLabel.Text == "My Garden" then
            playercollect = p
        end
    end
end

-- Динамическое определение редкости предмета
local function getRarity(itemModel)
    for _, child in pairs(itemModel:GetDescendants()) do
        if child:IsA("TextLabel") then
            local text = child.Text:lower()
            for rarityName, _ in pairs(Config.Rarities) do
                if string.find(text, rarityName:lower()) then
                    return rarityName
                end
            end
        end
    end
    
    for rarityName, _ in pairs(Config.Rarities) do
        if string.find(itemModel.Name:lower(), rarityName:lower()) then
            return rarityName
        end
    end
    
    return "Common"
end

-- Функция перемещения (Телепорт или Быстрое скольжение)
local function moveToTarget(hrp, targetCFrame)
    if Config.MoveMode == "Teleport" then
        hrp.CFrame = targetCFrame
        task.wait(0.08)
    else
        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 160
        local duration = distance / speed
        local startTime = os.clock()
        local startCFrame = hrp.CFrame
        
        while os.clock() - startTime < duration and Config.Autofarm do
            local t = (os.clock() - startTime) / duration
            hrp.CFrame = startCFrame:Lerp(targetCFrame, t)
            task.wait()
        end
        hrp.CFrame = targetCFrame
        task.wait(0.05)
    end
end

-- Логика сбора предмета
local function collectItem(item)
    local character = Player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or not item.PrimaryPart then return end
    
    local originalPos = hrp.CFrame
    
    moveToTarget(hrp, item.PrimaryPart.CFrame)
    
    local prox = item:FindFirstChild("BuyPrompt") or item:FindFirstChildOfClass("ProximityPrompt")
    if prox then
        fireproximityprompt(prox)
    end
    task.wait(0.04)
    
    if playercollect then
        moveToTarget(hrp, playercollect.CFrame)
    else
        moveToTarget(hrp, originalPos)
    end
end

-- Поток автофарма конвейера
task.spawn(function()
    while true do
        if Config.Autofarm then
            for _, item in pairs(Items:GetChildren()) do
                if not Config.Autofarm then break end
                
                if item and item:IsA("Model") and item.PrimaryPart then
                    local rarity = getRarity(item)
                    
                    if Config.Rarities[rarity] then
                        collectItem(item)
                        task.wait(0.05)
                    end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- Поток выборочной автопокупки
task.spawn(function()
    while true do
        task.wait(1)
        
        for gearName, enabled in pairs(Config.Gear) do
            if enabled then
                Buy:FireServer("PurchaseGearItem", gearName)
            end
        end

        for blenderName, enabled in pairs(Config.Blenders) do
            if enabled then
                Event:FireServer("PurchaseMixerItem", blenderName)
            end
        end

        if typeof(keyclick) == "function" then
            keyclick(113)
        end
    end
end)

-- Потоки функций игрока (Noclip и Speed)
RunService.Stepped:Connect(function()
    if Config.Noclip and Player.Character then
        for _, v in pairs(Player.Character:GetDescendants()) do
            if v:IsA("BasePart") then v.CanCollide = false end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(0.1)
        if Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
            local hum = Player.Character:FindFirstChildOfClass("Humanoid")
            if Config.SpeedEnabled then
                hum.WalkSpeed = Config.WalkSpeed
            end
        end
    end
end)

-- Создание Fluent интерфейса
local Window = Fluent:CreateWindow({
    Title = "Garden Ultimate Hub",
    SubTitle = "v6.0 - Delta Fix",
    TabWidth = 130,
    Size = UDim2.fromOffset(480, 440),
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Фарм", Icon = "home" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Gear = Window:AddTab({ Title = "Инструменты", Icon = "wrench" }),
    Blenders = Window:AddTab({ Title = "Миксеры", Icon = "beaker" })
}

-- Вкладка: Фарм
Tabs.Main:AddToggle("AutofarmToggle", {
    Title = "Включить автофарм конвейера",
    Default = false,
    Callback = function(Value) Config.Autofarm = Value end
})

Tabs.Main:AddDropdown("MoveModeDropdown", {
    Title = "Режим перемещения",
    Values = {"Teleport", "Fast Walk (Скольжение)"},
    Default = "Teleport",
    Callback = function(Value)
        if Value == "Teleport" then
            Config.MoveMode = "Teleport"
        else
            Config.MoveMode = "Walk"
        end
    end
})

Tabs.Main:AddSection("Фильтр редкостей для конвейера")
local rarityOrder = {"Divine", "Secret", "Exotic", "Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
for _, rarity in ipairs(rarityOrder) do
    Tabs.Main:AddToggle("Rarity_" .. rarity, {
        Title = "Собирать: " .. rarity,
        Default = false,
        Callback = function(Value) Config.Rarities[rarity] = Value end
    })
end

-- Вкладка: Player
Tabs.Player:AddToggle("NoclipToggle", {
    Title = "Noclip (Сквозь стены)",
    Default = false,
    Callback = function(Value) Config.Noclip = Value end
})

Tabs.Player:AddToggle("SpeedToggle", {
    Title = "Включить кастомную скорость",
    Default = false,
    Callback = function(Value) 
        Config.SpeedEnabled = Value 
        if not Value and Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") then
            Player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
        end
    end
})

Tabs.Player:AddSlider("SpeedSlider", {
    Title = "Скорость бега",
    Min = 16,
    Max = 250,
    Default = 50,
    Callback = function(Value) Config.WalkSpeed = Value end
})

-- Вкладка: Инструменты (Ручная пропись элементов)
Tabs.Gear:AddToggle("g1", { Title = "Купить: Watering Can", Default = false, Callback = function(v) Config.Gear["Watering Can"] = v end })
Tabs.Gear:AddToggle("g2", { Title = "Купить: Fertilizer", Default = false, Callback = function(v) Config.Gear["Fertilizer"] = v end })
Tabs.Gear:AddToggle("g3", { Title = "Купить: Sprinkler", Default = false, Callback = function(v) Config.Gear["Sprinkler"] = v end })
Tabs.Gear:AddToggle("g4", { Title = "Купить: Better Sprinkler", Default = false, Callback = function(v) Config.Gear["Better Sprinkler"] = v end })
Tabs.Gear:AddToggle("g5", { Title = "Купить: Trowel", Default = false, Callback = function(v) Config.Gear["Trowel"] = v end })
Tabs.Gear:AddToggle("g6", { Title = "Купить: Collector", Default = false, Callback = function(v) Config.Gear["Collector"] = v end })
Tabs.Gear:AddToggle("g7", { Title = "Купить: Copper Rod", Default = false, Callback = function(v) Config.Gear["Copper Rod"] = v end })
Tabs.Gear:AddToggle("g8", { Title = "Купить: Tower Sprinkler", Default = false, Callback = function(v) Config.Gear["Tower Sprinkler"] = v end })
Tabs.Gear:AddToggle("g9", { Title = "Купить: Golden Watering Can", Default = false, Callback = function(v) Config.Gear["Golden Watering Can"] = v end })
Tabs.Gear:AddToggle("g10", { Title = "Купить: Golden Fertilizer", Default = false, Callback = function(v) Config.Gear["Golden Fertilizer"] = v end })
Tabs.Gear:AddToggle("g11", { Title = "Купить: Golden Sprinkler", Default = false, Callback = function(v) Config.Gear["Golden Sprinkler"] = v end })
Tabs.Gear:AddToggle("g12", { Title = "Купить: Void Sprinkler", Default = false, Callback = function(v) Config.Gear["Void Sprinkler"] = v end })
Tabs.Gear:AddToggle("g13", { Title = "Купить: Favorite Tool", Default = false, Callback = function(v) Config.Gear["Favorite Tool"] = v end })
Tabs.Gear:AddToggle("g14", { Title = "Купить: Reclaimer", Default = false, Callback = function(v) Config.Gear["Reclaimer"] = v end })

-- Вкладка: Миксеры (Ручная пропись элементов)
Tabs.Blenders:AddToggle("b1", { Title = "Купить: Void Blender", Default = false, Callback = function(v) Config.Blenders["Void Blender"] = v end })
Tabs.Blenders:AddToggle("b2", { Title = "Купить: Diamond Blender", Default = false, Callback = function(v) Config.Blenders["Diamond Blender"] = v end })
Tabs.Blenders:AddToggle("b3", { Title = "Купить: Golden Blender", Default = false, Callback = function(v) Config.Blenders["Golden Blender"] = v end })
Tabs.Blenders:AddToggle("b4", { Title = "Купить: Normal Blender", Default = false, Callback = function(v) Config.Blenders["Normal Blender"] = v end })
Tabs.Blenders:AddToggle("b5", { Title = "Купить: Basic Blender", Default = false, Callback = function(v) Config.Blenders["Basic Blender"] = v end })

-- Кнопка MENU для Delta (Оптимизированная)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "DeltaToggleGui"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = PlayerGui end)

local OpenButton = Instance.new("TextButton")
OpenButton.Parent = ScreenGui
OpenButton.Size = UDim2.new(0, 80, 0, 45)
OpenButton.Position = UDim2.new(0, 15, 0.4, 0)
OpenButton.Text = "MENU"
OpenButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Font = Enum.Font.SourceSansBold
OpenButton.TextSize = 16
OpenButton.Active = true
OpenButton.Draggable = true

local UICorner = Instance.new("UICorner", OpenButton)
UICorner.CornerRadius = UDim.new(0, 8)

OpenButton.MouseButton1Click:Connect(function()
    Window:Minimize()
end)

-- Оригинальное уведомление
firesignal(Event.OnClientEvent, "Notify", {
	Top = true,
	Text = "<b><font color ='#ED401C'>Autofarm</font></b> has been loaded!",
	Sound = "Mutate",
})

Fluent:Notify({
    Title = " Delta Оптимизация",
    Content = "Списки магазинов зафиксированы и кнопка MENU на экране!",
    Duration = 4
})
