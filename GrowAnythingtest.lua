local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Переменные игры
local Items = game:GetService("Workspace").Conveyor.Items
local Event = game:GetService("ReplicatedStorage").Remotes.Network.RemoteEvent
local CollectionSpots = game:GetService("Workspace").CollectionSpots
local Buy = game:GetService("ReplicatedStorage").Remotes.Network.RemoteEvent
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local playercollect = nil
local ConfigFile = "GardenHub_Config.json"

-- Единая таблица конфигурации
local Config = {
    Language = "EN", -- По умолчанию Английский
    Autoload = false,
    Autofarm = false,
    MoveMode = "Teleport",
    Rarities = {
        ["Divine"] = false, ["Secret"] = false, ["Exotic"] = false, 
        ["Mythical"] = false, ["Legendary"] = false, ["Epic"] = false, 
        ["Rare"] = false, ["Uncommon"] = false, ["Common"] = false
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
    -- Параметры игрока
    WalkSpeedValue = 16,
    FlyEnabled = false,
    FlySpeed = 50,
    NoclipEnabled = false,
    InfJumpEnabled = false,
    PlayerMoveMode = "Teleport",
    SelectedTargetPlayer = ""
}

-- Элементы интерфейса для динамического перевода
local UI_Elements = {}

-- Словари локализации
local Localization = {
    RU = {
        Title = "Фарм", ShopTitle = "Магазин", SettingsTitle = "Настройки", PlayerTitle = "Игрок",
        Autofarm = "Включить автофарм конвейера", MoveMode = "Режим перемещения",
        RaritiesSec = "Фильтр редкостей для конвейера", Collect = "Собирать: ",
        GearSec = "— ИНСТРУМЕНТЫ —", BlenderSec = "— МИКСЕРЫ —", Buy = "Купить: ",
        LangSec = "— СМЕНА ЯЗЫКА —", LangTitle = "Язык интерфейса / Language",
        ConfigSec = "— КОНФИГУРАЦИЯ —", SaveBtn = "Сохранить конфиг", LoadBtn = "Загрузить конфиг",
        AutoloadToggle = "Авто-загрузка при старте", SavedNotify = "Конфигурация успешно сохранена!",
        LoadedNotify = "Конфигурация успешно загружена!", AutoloadNotify = "Авто-конфиг успешно применён!",
        -- Перевод для вкладки Игрок
        SpeedSlider = "Скорость бега", FlyToggle = "Режим полета", NoclipToggle = "Прохождение сквозь стены",
        InfJumpToggle = "Бесконечный прыжок", TeleportSec = "— ТЕЛЕПОРТАЦИЯ К ИГРОКАМ —",
        SelectPlayer = "Выберите игрока", TPMode = "Тип перемещения к игроку", TPButton = "Телепортироваться"
    },
    EN = {
        Title = "Farm", ShopTitle = "Shop", SettingsTitle = "Settings", PlayerTitle = "Player",
        Autofarm = "Enable Conveyor Autofarm", MoveMode = "Movement Mode",
        RaritiesSec = "Conveyor Rarity Filter", Collect = "Collect: ",
        GearSec = "— GEAR / TOOLS —", BlenderSec = "— BLENDERS / MIXERS —", Buy = "Buy: ",
        LangSec = "— LANGUAGE —", LangTitle = "Interface Language",
        ConfigSec = "— CONFIGURATION —", SaveBtn = "Save Config", LoadBtn = "Load Config",
        AutoloadToggle = "Auto-load on startup", SavedNotify = "Configuration saved successfully!",
        LoadedNotify = "Configuration loaded successfully!", AutoloadNotify = "Auto-config applied successfully!",
        -- Перевод для вкладки Игрок
        SpeedSlider = "WalkSpeed", FlyToggle = "Fly Mode", NoclipToggle = "Noclip",
        InfJumpToggle = "Infinite Jump", TeleportSec = "— PLAYER TELEPORTATION —",
        SelectPlayer = "Select Player", TPMode = "Player TP Movement Mode", TPButton = "Teleport to Player"
    }
}

-- Безопасная функция обновления заголовков во Fluent
local function setElementTitle(element, title)
    if not element or type(element) ~= "table" then return end
    if element.SetTitle then
        local success = pcall(function() element:SetTitle(title) end)
        if success then return end
    end
    element.Title = title
    pcall(function()
        if element.Instance then
            local label = element.Instance:FindFirstChild("Title", true) or element.Instance:FindFirstChild("TextLabel", true)
            if label and label:IsA("TextLabel") then label.Text = title return end
        end
        if element.Button then
            local label = element.Button:FindFirstChild("Title", true) or element.Button:FindFirstChild("TextLabel", true)
            if label and label:IsA("TextLabel") then label.Text = title end
        end
    end)
end

-- Функция обновления языка интерфейса
local function UpdateLanguage()
    local lang = Config.Language
    local t = Localization[lang]
    
    setElementTitle(UI_Elements.MainTab, t.Title)
    setElementTitle(UI_Elements.ShopTab, t.ShopTitle)
    setElementTitle(UI_Elements.SettingsTab, t.SettingsTitle)
    setElementTitle(UI_Elements.PlayerTab, t.PlayerTitle)
    
    setElementTitle(UI_Elements.AutofarmToggle, t.Autofarm)
    setElementTitle(UI_Elements.MoveModeDropdown, t.MoveMode)
    setElementTitle(UI_Elements.RaritiesSec, t.RaritiesSec)
    
    for rarity, toggle in pairs(UI_Elements.RarityToggles or {}) do
        setElementTitle(toggle, t.Collect .. rarity)
    end
    
    setElementTitle(UI_Elements.GearSec, t.GearSec)
    for gear, toggle in pairs(UI_Elements.GearToggles or {}) do
        setElementTitle(toggle, t.Buy .. gear)
    end
    
    setElementTitle(UI_Elements.BlenderSec, t.BlenderSec)
    for blender, toggle in pairs(UI_Elements.BlenderToggles or {}) do
        setElementTitle(toggle, t.Buy .. blender)
    end
    
    setElementTitle(UI_Elements.LangSec, t.LangSec)
    setElementTitle(UI_Elements.LangDropdown, t.LangTitle)
    setElementTitle(UI_Elements.ConfigSec, t.ConfigSec)
    setElementTitle(UI_Elements.AutoloadToggle, t.AutoloadToggle)
    setElementTitle(UI_Elements.SaveBtn, t.SaveBtn)
    setElementTitle(UI_Elements.LoadBtn, t.LoadBtn)

    -- Обновление вкладки Player
    setElementTitle(UI_Elements.SpeedSlider, t.SpeedSlider)
    setElementTitle(UI_Elements.FlyToggle, t.FlyToggle)
    setElementTitle(UI_Elements.NoclipToggle, t.NoclipToggle)
    setElementTitle(UI_Elements.InfJumpToggle, t.InfJumpToggle)
    setElementTitle(UI_Elements.TeleportSec, t.TeleportSec)
    setElementTitle(UI_Elements.PlayerDropdown, t.SelectPlayer)
    setElementTitle(UI_Elements.PlayerMoveModeDropdown, t.TPMode)
    setElementTitle(UI_Elements.TPButton, t.TPButton)
end

-- Функции сохранения и загрузки конфигов
local function SaveConfig()
    local data = HttpService:JSONEncode(Config)
    if writefile then
        writefile(ConfigFile, data)
        Fluent:Notify({
            Title = Config.Language == "RU" and "Успех" or "Success",
            Content = Localization[Config.Language].SavedNotify,
            Duration = 3
        })
    end
end

local function LoadConfig(isAutoload)
    if isfile and readfile and isfile(ConfigFile) then
        local data = HttpService:JSONDecode(readfile(ConfigFile))
        if data then
            Config.Language = data.Language or "EN"
            Config.Autoload = data.Autoload or false
            Config.Autofarm = data.Autofarm or false
            Config.MoveMode = data.MoveMode or "Teleport"
            
            for k, v in pairs(data.Rarities or {}) do Config.Rarities[k] = v end
            for k, v in pairs(data.Gear or {}) do Config.Gear[k] = v end
            for k, v in pairs(data.Blenders or {}) do Config.Blenders[k] = v end
            
            if UI_Elements.AutofarmToggle then UI_Elements.AutofarmToggle:SetValue(Config.Autofarm) end
            if UI_Elements.MoveModeDropdown then UI_Elements.MoveModeDropdown:SetValue(Config.MoveMode == "Teleport" and "Teleport" or "Fast Walk (Скольжение)") end
            if UI_Elements.LangDropdown then UI_Elements.LangDropdown:SetValue(Config.Language == "RU" and "Русский (RU)" or "English (EN)") end
            if UI_Elements.AutoloadToggle then UI_Elements.AutoloadToggle:SetValue(Config.Autoload) end
            
            for rarity, toggle in pairs(UI_Elements.RarityToggles or {}) do toggle:SetValue(Config.Rarities[rarity]) end
            for gear, toggle in pairs(UI_Elements.GearToggles or {}) do toggle:SetValue(Config.Gear[gear]) end
            for blender, toggle in pairs(UI_Elements.BlenderToggles or {}) do toggle:SetValue(Config.Blenders[blender]) end
            
            UpdateLanguage()
            
            Fluent:Notify({
                Title = Config.Language == "RU" and "Конфиг" or "Config",
                Content = isAutoload and Localization[Config.Language].AutoloadNotify or Localization[Config.Language].LoadedNotify,
                Duration = 3
            })
        end
    end
end

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
                if string.find(text, rarityName:lower()) then return rarityName end
            end
        end
    end
    for rarityName, _ in pairs(Config.Rarities) do
        if string.find(itemModel.Name:lower(), rarityName:lower()) then return rarityName end
    end
    return "Common"
end

-- Функция перемещения универсальная
local function moveToTarget(hrp, targetCFrame, currentMoveMode, checkState)
    if currentMoveMode == "Teleport" then
        hrp.CFrame = targetCFrame
        task.wait(0.08)
    else
        local distance = (hrp.Position - targetCFrame.Position).Magnitude
        local speed = 160
        local duration = distance / speed
        local startTime = os.clock()
        local startCFrame = hrp.CFrame
        
        while os.clock() - startTime < duration do
            if checkState and not Config[checkState] then break end
            local t = (os.clock() - startTime) / duration
            hrp.CFrame = startCFrame:Lerp(targetCFrame, t)
            task.wait()
        end
        hrp.CFrame = targetCFrame
        task.wait(0.05)
    end
end

-- Логика сбора предмета конвейера
local function collectItem(item)
    local character = Player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp or not item.PrimaryPart then return end
    
    local originalPos = hrp.CFrame
    moveToTarget(hrp, item.PrimaryPart.CFrame, Config.MoveMode, "Autofarm")
    
    local prox = item:FindFirstChild("BuyPrompt") or item:FindFirstChildOfClass("ProximityPrompt")
    if prox then fireproximityprompt(prox) end
    task.wait(0.04)
    
    if playercollect then
        moveToTarget(hrp, playercollect.CFrame, Config.MoveMode, "Autofarm")
    else
        moveToTarget(hrp, originalPos, Config.MoveMode, "Autofarm")
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

-- Поток автопокупки
task.spawn(function()
    while true do
        task.wait(1)
        for gearName, enabled in pairs(Config.Gear) do
            if enabled then Buy:FireServer("PurchaseGearItem", gearName) end
        end
        for blenderName, enabled in pairs(Config.Blenders) do
            if enabled then Event:FireServer("PurchaseMixerItem", blenderName) end
        end
        if typeof(keyclick) == "function" then keyclick(113) end
    end
end)

-- ==================== ЛОГИКА ФУНКЦИЙ ИГРОКА ====================

-- Поток WalkSpeed & Noclip
RunService.Stepped:Connect(function()
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and not Config.FlyEnabled then
            hum.WalkSpeed = Config.WalkSpeedValue
        end
        if Config.NoclipEnabled then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if Config.InfJumpEnabled then
        local char = Player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState("Jumping") end
    end
end)

-- Функционал Fly
local flyBodyGyro, flyBodyVelocity
task.spawn(function()
    while true do
        task.wait(0.1)
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if Config.FlyEnabled and hrp then
            if not flyBodyGyro then
                flyBodyGyro = Instance.new("BodyGyro", hrp)
                flyBodyGyro.P = 9e4
                flyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyBodyGyro.cframe = hrp.CFrame
                
                flyBodyVelocity = Instance.new("BodyVelocity", hrp)
                flyBodyVelocity.velocity = Vector3.new(0, 0.1, 0)
                flyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
            end
            
            local camera = workspace.CurrentCamera
            local hum = char:FindFirstChildOfClass("Humanoid")
            local moveDirection = hum and hum.MoveDirection or Vector3.new(0,0,0)
            
            flyBodyGyro.cframe = camera.CFrame
            if moveDirection.Magnitude > 0 then
                flyBodyVelocity.velocity = moveDirection * Config.FlySpeed
            else
                flyBodyVelocity.velocity = Vector3.new(0, 0.1, 0)
            end
        else
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
            if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        end
    end
end)

-- Функция обновления списка игроков в Dropdown
local function getPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then table.insert(names, p.Name) end
    end
    return names
end

-- ==================== СОЗДАНИЕ ИНТЕРФЕЙСА ====================

local Window = Fluent:CreateWindow({
    Title = "Garden Ultimate Hub",
    SubTitle = "v7.0 - Configs & Langs",
    TabWidth = 130,
    Size = UDim2.fromOffset(480, 440),
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Farm", Icon = "home" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Player = Window:AddTab({ Title = "Player", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

UI_Elements.MainTab = Tabs.Main
UI_Elements.ShopTab = Tabs.Shop
UI_Elements.PlayerTab = Tabs.Player
UI_Elements.SettingsTab = Tabs.Settings

-- Вкладка: Фарм
UI_Elements.AutofarmToggle = Tabs.Main:AddToggle("AutofarmToggle", {
    Title = "Enable Conveyor Autofarm",
    Default = false,
    Callback = function(Value) Config.Autofarm = Value end
})

UI_Elements.MoveModeDropdown = Tabs.Main:AddDropdown("MoveModeDropdown", {
    Title = "Movement Mode",
    Values = {"Teleport", "Fast Walk (Скольжение)"},
    Default = "Teleport",
    Callback = function(Value)
        Config.MoveMode = (Value == "Teleport") and "Teleport" or "Walk"
    end
})

UI_Elements.RaritiesSec = Tabs.Main:AddSection("Conveyor Rarity Filter")
UI_Elements.RarityToggles = {}
local rarityOrder = {"Divine", "Secret", "Exotic", "Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
for _, rarity in ipairs(rarityOrder) do
    UI_Elements.RarityToggles[rarity] = Tabs.Main:AddToggle("Rarity_" .. rarity, {
        Title = "Collect: " .. rarity,
        Default = false,
        Callback = function(Value) Config.Rarities[rarity] = Value end
    })
end

-- Вкладка: Магазин
UI_Elements.GearSec = Tabs.Shop:AddSection("— GEAR / TOOLS —")
UI_Elements.GearToggles = {}
local gearList = {
    "Watering Can", "Fertilizer", "Sprinkler", "Better Sprinkler", "Trowel", 
    "Collector", "Copper Rod", "Tower Sprinkler", "Golden Watering Can", 
    "Golden Fertilizer", "Golden Sprinkler", "Void Sprinkler", "Favorite Tool", "Reclaimer"
}
for i, gear in ipairs(gearList) do
    UI_Elements.GearToggles[gear] = Tabs.Shop:AddToggle("ShG" .. i, {
        Title = "Buy: " .. gear,
        Default = false,
        Callback = function(v) Config.Gear[gear] = v end
    })
end

UI_Elements.BlenderSec = Tabs.Shop:AddSection("— BLENDERS / MIXERS —")
UI_Elements.BlenderToggles = {}
local blenderList = {"Void Blender", "Diamond Blender", "Golden Blender", "Normal Blender", "Basic Blender"}
for i, blender in ipairs(blenderList) do
    UI_Elements.BlenderToggles[blender] = Tabs.Shop:AddToggle("ShB" .. i, {
        Title = "Buy: " .. blender,
        Default = false,
        Callback = function(v) Config.Blenders[blender] = v end
    })
end

-- Вкладка: Игрок (Новая)
UI_Elements.SpeedSlider = Tabs.Player:AddSlider("SpeedSlider", {
    Title = "WalkSpeed",
    Description = "Регулировка скорости",
    Min = 16,
    Max = 200,
    Default = 16,
    Rounding = 0,
    Callback = function(Value) Config.WalkSpeedValue = Value end
})

UI_Elements.FlyToggle = Tabs.Player:AddToggle("FlyToggle", {
    Title = "Fly Mode",
    Default = false,
    Callback = function(Value) Config.FlyEnabled = Value end
})

UI_Elements.NoclipToggle = Tabs.Player:AddToggle("NoclipToggle", {
    Title = "Noclip",
    Default = false,
    Callback = function(Value) Config.NoclipEnabled = Value end
})

UI_Elements.InfJumpToggle = Tabs.Player:AddToggle("InfJumpToggle", {
    Title = "Infinite Jump",
    Default = false,
    Callback = function(Value) Config.InfJumpEnabled = Value end
})

UI_Elements.TeleportSec = Tabs.Player:AddSection("— PLAYER TELEPORTATION —")

UI_Elements.PlayerDropdown = Tabs.Player:AddDropdown("PlayerDropdown", {
    Title = "Select Player",
    Values = getPlayerNames(),
    Default = "",
    Callback = function(Value) Config.SelectedTargetPlayer = Value end
})

-- Обновление списка игроков при открытии выпадающего списка
task.spawn(function()
    while true do
        task.wait(3)
        if UI_Elements.PlayerDropdown then
            UI_Elements.PlayerDropdown:SetValues(getPlayerNames())
        end
    end
end)

UI_Elements.PlayerMoveModeDropdown = Tabs.Player:AddDropdown("PlayerMoveModeDropdown", {
    Title = "Player TP Movement Mode",
    Values = {"Teleport", "Fast Walk (Скольжение)"},
    Default = "Teleport",
    Callback = function(Value)
        Config.PlayerMoveMode = (Value == "Teleport") and "Teleport" or "Walk"
    end
})

UI_Elements.TPButton = Tabs.Player:AddButton({
    Title = "Teleport to Player",
    Callback = function()
        local targetName = Config.SelectedTargetPlayer
        if targetName and targetName ~= "" then
            local targetPlayer = Players:FindFirstChild(targetName)
