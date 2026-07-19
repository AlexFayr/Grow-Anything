local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local Items = game:GetService("Workspace").Conveyor.Items
local Event = game:GetService("ReplicatedStorage").Remotes.Network.RemoteEvent
local CollectionSpots = game:GetService("Workspace").CollectionSpots
local Buy = game:GetService("ReplicatedStorage").Remotes.Network.RemoteEvent
local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")

local SellingModule = nil
pcall(function() SellingModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("Shared"):WaitForChild("Selling")) end)

local playercollect = nil
local ConfigFile = "GardenHub_Config.json"

local Config = {
    Language = "EN", Autoload = false, Autofarm = false, AutoHarvestPlot = false, AutoSell = false, MoveMode = "Teleport",
    UseDailyBoost = false, UseFriendBoost = false,
    Rarities = {["Divine"] = false, ["Secret"] = false, ["Exotic"] = false, ["Mythical"] = false, ["Legendary"] = false, ["Epic"] = false, ["Rare"] = false, ["Uncommon"] = false, ["Common"] = false},
    Gear = {["Watering Can"] = false, ["Fertilizer"] = false, ["Sprinkler"] = false, ["Better Sprinkler"] = false, ["Trowel"] = false, ["Collector"] = false, ["Copper Rod"] = false, ["Tower Sprinkler"] = false, ["Golden Watering Can"] = false, ["Golden Fertilizer"] = false, ["Golden Sprinkler"] = false, ["Void Sprinkler"] = false, ["Favorite Tool"] = false, ["Reclaimer"] = false},
    Blenders = {["Void Blender"] = false, ["Diamond Blender"] = false, ["Golden Blender"] = false, ["Normal Blender"] = false, ["Basic Blender"] = false},
    Eggs = {["Secret"] = false, ["Exotic"] = false, ["Mythic"] = false, ["Legendary"] = false, ["Epic"] = false, ["Rare"] = false, ["Uncommon"] = false, ["Common"] = false},
    WalkSpeedValue = 16, FlyEnabled = false, FlySpeed = 50, NoclipEnabled = false, InfJumpEnabled = false, PlayerMoveMode = "Teleport", SelectedTargetPlayer = ""
}

-- ПОЛУЧЕНИЕ МНОЖИТЕЛЕЙ БУСТОВ ИЗ ИНТЕРФЕЙСА (CASHUI)
local function getBoostMultipliers()
    local dailyMult = 1
    local friendMult = 1
    
    local cashUI = PlayerGui:FindFirstChild("CashUI")
    if cashUI and cashUI:FindFirstChild("Frame") then
        local frame = cashUI.Frame
        if Config.UseDailyBoost and frame:FindFirstChild("DailyBoostLabel") then
            local txt = frame.DailyBoostLabel.Text
            local percent = string.match(txt, "%+(%d+)%%") or string.match(txt, "(%d+)%%")
            if percent then dailyMult = 1 + (tonumber(percent) / 100) end
        end
        if Config.UseFriendBoost and frame:FindFirstChild("FriendBoost") then
            local txt = frame.FriendBoost.Text
            local percent = string.match(txt, "%+(%d+)%%") or string.match(txt, "(%d+)%%")
            if percent then friendMult = 1 + (tonumber(percent) / 100) end
        end
    end
    return dailyMult, friendMult
end

-- УЛУЧШЕННЫЙ КАЛЬКУЛЯТОР ИНВЕНТАРЯ С БУСТАМИ
local function CalculateInventoryValue()
    if not SellingModule then return "Module not found!" end
    local total = 0
    local inv = Player:FindFirstChild("Inventory") or Player:FindFirstChild("Backpack") 
    if inv then
        for _, item in pairs(inv:GetChildren()) do
            if item:IsA("Model") or item:IsA("Tool") then
                pcall(function() 
                    local basePrice = SellingModule:CalculatePrice(item)
                    total = total + basePrice
                end)
            end
        end
    end
    
    local dailyM, friendM = getBoostMultipliers()
    total = total * dailyM * friendM
    return math.floor(total)
end

local UI_Elements = {}
local Localization = {
    RU = {
        Title = "Фарм", ShopTitle = "Магазин", SettingsTitle = "Настройки", PlayerTitle = "Игрок", StatTitle = "Статистика", 
        Autofarm = "Включить автофарм конвейера", AutoHarvest = "Авто-сбор урожая (Свой Плот)", AutoSell = "Авто-продажа (Телепорт каждые 15с)", 
        MoveMode = "Режим перемещения", RaritiesSec = "Фильтр редкостей для конвейера", Collect = "Собирать: ", 
        GearSec = "— ИНСТРУМЕНТЫ —", BlenderSec = "— МИКСЕРЫ —", EggsSec = "— АВТОПОКУПКА ЯИЦ (БЕЗОПАСНАЯ) —", 
        Buy = "Купить: ", BuyEgg = "Автопокупка: ", LangSec = "— СМЕНА ЯЗЫКА —", LangTitle = "Язык интерфейса / Language", 
        ConfigSec = "— КОНФИГУРАЦИЯ —", SaveBtn = "Сохранить конфиг", LoadBtn = "Загрузить конфиг", AutoloadToggle = "Авто-загрузка при старте", 
        SavedNotify = "Конфигурация успешно сохранена!", LoadedNotify = "Конфигурация успешно загружена!", AutoloadNotify = "Авто-конфиг успешно применён!",
        SpeedSlider = "Скорость бега", FlyToggle = "Режим полета", NoclipToggle = "Прохождение сквозь стены", InfJumpToggle = "Бесконечный прыжок", 
        TeleportSec = "— ТЕЛЕПОРТАЦИЯ К ИГРОКАМ —", SelectPlayer = "Выберите игрока", TPMode = "Тип перемещения к игроку", TPButton = "Телепортироваться",
        CalcBtn = "Посчитать стоимость инвентаря", DailyToggle = "Учитывать Daily Boost", FriendToggle = "Учитывать Friend Boost"
    },
    EN = {
        Title = "Farm", ShopTitle = "Shop", SettingsTitle = "Settings", PlayerTitle = "Player", StatTitle = "Stats / Calc", 
        Autofarm = "Enable Conveyor Autofarm", AutoHarvest = "Auto-Harvest (Own Plot)", AutoSell = "Auto-Sell (Teleport every 15s)", 
        MoveMode = "Movement Mode", RaritiesSec = "Conveyor Rarity Filter", Collect = "Collect: ", 
        GearSec = "— GEAR / TOOLS —", BlenderSec = "— BLENDERS / MIXERS —", EggsSec = "— AUTO BUY EGGS (SAFE EXT) —", 
        Buy = "Buy: ", BuyEgg = "Auto Buy: ", LangSec = "— LANGUAGE —", LangTitle = "Interface Language", 
        ConfigSec = "— CONFIGURATION —", SaveBtn = "Save Config", LoadBtn = "Load Config", AutoloadToggle = "Auto-load on startup", 
        SavedNotify = "Configuration saved successfully!", LoadedNotify = "Configuration loaded successfully!", AutoloadNotify = "Auto-config applied successfully!",
        SpeedSlider = "WalkSpeed", FlyToggle = "Fly Mode", NoclipToggle = "Noclip", InfJumpToggle = "Infinite Jump", 
        TeleportSec = "— PLAYER TELEPORTATION —", SelectPlayer = "Select Player", TPMode = "Player TP Movement Mode", TPButton = "Teleport to Player",
        CalcBtn = "Calculate Inventory Value", DailyToggle = "Include Daily Boost", FriendToggle = "Include Friend Boost"
    }
}

local function setElementTitle(element, title) if element and element.SetTitle then pcall(function() element:SetTitle(title) end) end end

local function UpdateLanguage()
    local t = Localization[Config.Language]
    setElementTitle(UI_Elements.MainTab, t.Title) setElementTitle(UI_Elements.ShopTab, t.ShopTitle) setElementTitle(UI_Elements.SettingsTab, t.SettingsTitle) setElementTitle(UI_Elements.PlayerTab, t.PlayerTitle) setElementTitle(UI_Elements.StatTab, t.StatTitle)
    setElementTitle(UI_Elements.AutofarmToggle, t.Autofarm) setElementTitle(UI_Elements.AutoHarvestToggle, t.AutoHarvest) setElementTitle(UI_Elements.AutoSellToggle, t.AutoSell) setElementTitle(UI_Elements.MoveModeDropdown, t.MoveMode) setElementTitle(UI_Elements.RaritiesSec, t.RaritiesSec)
    for rarity, toggle in pairs(UI_Elements.RarityToggles or {}) do setElementTitle(toggle, t.Collect .. rarity) end
    setElementTitle(UI_Elements.GearSec, t.GearSec) for gear, toggle in pairs(UI_Elements.GearToggles or {}) do setElementTitle(toggle, t.Buy .. gear) end
    setElementTitle(UI_Elements.BlenderSec, t.BlenderSec) for blender, toggle in pairs(UI_Elements.BlenderToggles or {}) do setElementTitle(toggle, t.Buy .. blender) end
    setElementTitle(UI_Elements.EggsSec, t.EggsSec) for eggRarity, toggle in pairs(UI_Elements.EggToggles or {}) do setElementTitle(toggle, t.BuyEgg .. eggRarity .. " Egg") end
    setElementTitle(UI_Elements.LangSec, t.LangSec) setElementTitle(UI_Elements.LangDropdown, t.LangTitle) setElementTitle(UI_Elements.ConfigSec, t.ConfigSec) setElementTitle(UI_Elements.AutoloadToggle, t.AutoloadToggle) setElementTitle(UI_Elements.SaveBtn, t.SaveBtn) setElementTitle(UI_Elements.LoadBtn, t.LoadBtn)
    setElementTitle(UI_Elements.SpeedSlider, t.SpeedSlider) setElementTitle(UI_Elements.FlyToggle, t.FlyToggle) setElementTitle(UI_Elements.NoclipToggle, t.NoclipToggle) setElementTitle(UI_Elements.InfJumpToggle, t.InfJumpToggle) setElementTitle(UI_Elements.TeleportSec, t.TeleportSec) setElementTitle(UI_Elements.PlayerDropdown, t.SelectPlayer) setElementTitle(UI_Elements.PlayerMoveModeDropdown, t.TPMode) setElementTitle(UI_Elements.TPButton, t.TPButton) setElementTitle(UI_Elements.CalcBtn, t.CalcBtn)
    setElementTitle(UI_Elements.DailyToggle, t.DailyToggle) setElementTitle(UI_Elements.FriendToggle, t.FriendToggle)
end

local function SaveConfig()
    if writefile then writefile(ConfigFile, HttpService:JSONEncode(Config)) Fluent:Notify({Title = "Success", Content = "Saved!", Duration = 2}) end
end

local function updatePlayerPlot()
    if playercollect and playercollect.Parent == CollectionSpots then return playercollect end
    for _, p in pairs(CollectionSpots:GetChildren()) do 
        if p:FindFirstChild("MyGardenGui") and p:FindFirstChild("MyGardenGui").TextLabel.Text == "My Garden" then playercollect = p return p end 
    end
    return nil
end

local function LoadConfig(isAutoload)
    if isfile and readfile and isfile(ConfigFile) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if success and data then
            for k, v in pairs(data) do if type(v) ~= "table" then Config[k] = v end end
            for k, v in pairs(data.Rarities or {}) do Config.Rarities[k] = v end 
            for k, v in pairs(data.Gear or {}) do Config.Gear[k] = v end 
            for k, v in pairs(data.Blenders or {}) do Config.Blenders[k] = v end 
            for k, v in pairs(data.Eggs or {}) do Config.Eggs[k] = v end

            local function safeSet(element, value) if element and element.SetValue then pcall(function() element:SetValue(value) end) end end
            safeSet(UI_Elements.AutofarmToggle, Config.Autofarm) safeSet(UI_Elements.AutoHarvestToggle, Config.AutoHarvestPlot) safeSet(UI_Elements.AutoSellToggle, Config.AutoSell)
            safeSet(UI_Elements.MoveModeDropdown, Config.MoveMode == "Teleport" and "Teleport" or "Fast Walk (Скольжение)")
            safeSet(UI_Elements.LangDropdown, Config.Language == "RU" and "Русский (RU)" or "English (EN)") safeSet(UI_Elements.AutoloadToggle, Config.Autoload)
            safeSet(UI_Elements.SpeedSlider, Config.WalkSpeedValue) safeSet(UI_Elements.FlyToggle, Config.FlyEnabled) safeSet(UI_Elements.NoclipToggle, Config.NoclipEnabled) safeSet(UI_Elements.InfJumpToggle, Config.InfJumpEnabled)
            safeSet(UI_Elements.PlayerMoveModeDropdown, Config.PlayerMoveMode == "Teleport" and "Teleport" or "Fast Walk (Скольжение)")
            safeSet(UI_Elements.DailyToggle, Config.UseDailyBoost) safeSet(UI_Elements.FriendToggle, Config.UseFriendBoost)

            for r, t in pairs(UI_Elements.RarityToggles or {}) do safeSet(t, Config.Rarities[r]) end
            for g, t in pairs(UI_Elements.GearToggles or {}) do safeSet(t, Config.Gear[g]) end
            for b, t in pairs(UI_Elements.BlenderToggles or {}) do safeSet(t, Config.Blenders[b]) end
            for e, t in pairs(UI_Elements.EggToggles or {}) do safeSet(t, Config.Eggs[e]) end
            UpdateLanguage()
        end
    end
end

local function getRarity(itemModel)
    for _, child in pairs(itemModel:GetDescendants()) do if child:IsA("TextLabel") then local text = child.Text:lower() for rarityName, _ in pairs(Config.Rarities) do if string.find(text, rarityName:lower()) then return rarityName end end end end
    for rarityName, _ in pairs(Config.Rarities) do if string.find(itemModel.Name:lower(), rarityName:lower()) then return rarityName end end
    return "Common"
end

local function moveToTarget(hrp, targetCFrame, currentMoveMode, checkState)
    if currentMoveMode == "Teleport" then hrp.CFrame = targetCFrame task.wait(0.08)
    else
        local distance = (hrp.Position - targetCFrame.Position).Magnitude local duration = distance / 160 local startTime = os.clock() local startCFrame = hrp.CFrame
        while os.clock() - startTime < duration do if checkState and not Config[checkState] then break end hrp.CFrame = startCFrame:Lerp(targetCFrame, (os.clock() - startTime) / duration) task.wait() end
        hrp.CFrame = targetCFrame task.wait(0.05)
    end
end

local function collectItem(item)
    local character = Player.Character if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart") if not hrp or not item.PrimaryPart then return end
    local originalPos = hrp.CFrame moveToTarget(hrp, item.PrimaryPart.CFrame, Config.MoveMode, "Autofarm")
    local prox = item:FindFirstChild("BuyPrompt") or item:FindFirstChildOfClass("ProximityPrompt") if prox then fireproximityprompt(prox) end task.wait(0.04)
    local plot = updatePlayerPlot()
    if plot then moveToTarget(hrp, plot.CFrame, Config.MoveMode, "Autofarm") else moveToTarget(hrp, originalPos, Config.MoveMode, "Autofarm") end
end

-- АВТО-СБОР УРОЖАЯ (СТРОГО НА СВОЕМ ПЛОТУ)
task.spawn(function()
    while true do task.wait(0.4)
        if Config.AutoHarvestPlot then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local plotsFolder = game:GetService("Workspace"):FindFirstChild("Plots")
            local myPlot = plotsFolder and plotsFolder:FindFirstChild(Player.Name)
            if hrp and myPlot then
                for _, obj in pairs(myPlot:GetDescendants()) do
                    if not Config.AutoHarvestPlot then break end
                    if obj:IsA("ProximityPrompt") and obj.Parent and obj.Parent:IsA("BasePart") then
                        hrp.CFrame = obj.Parent.CFrame * CFrame.new(0, 3, 0) task.wait(0.15) fireproximityprompt(obj) task.wait(0.25)
                    end
                end
            end
        end
    end
end)

-- УЛЬТРА АВТО-ПРОДАЖА СО СПАМ-КЛИКОМ И АНАЛИЗОМ ПОЗИЦИИ ИЗ DEX
task.spawn(function()
    while true do task.wait(15)
        if Config.AutoSell then
            local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
            local npcFolder = game:GetService("Workspace"):FindFirstChild("NPCs")
            local seller = npcFolder and npcFolder:FindFirstChild("Seller") or game:GetService("Workspace"):FindFirstChild("Seller", true)
            
            if hrp and seller then
                local targetPart = seller:IsA("Model") and (seller.PrimaryPart or seller:FindFirstChildWhichIsA("BasePart")) or seller
                if targetPart and targetPart:IsA("BasePart") then
                    local savedCFrame = hrp.CFrame 
                    hrp.CFrame = targetPart.CFrame * CFrame.new(0, 3, 3) 
                    task.wait(0.5)
                    
                    local prompt = seller:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then fireproximityprompt(prompt) end 
                    
                    local choiceBtn = nil
                    local startTime = os.clock()
                    
                    -- Ждём рендер кнопки в Delta до 3-х секунд
                    while os.clock() - startTime < 3 do
                        local mainFrame = PlayerGui:FindFirstChild("DialogueUI") and PlayerGui.DialogueUI:FindFirstChild("Main")
                        local holder = mainFrame and mainFrame:FindFirstChild("Holder")
                        local scroll = holder and holder:FindFirstChild("ScrollingFrame")
                        local btn = scroll and scroll:FindFirstChild("I would like to sell my inventory")
                        
                        if btn and btn.Visible then
                            choiceBtn = btn
                            break
                        end
                        task.wait(0.1)
                    end
                    
                    -- Запуск жесткого спам-кликера по точным координатам
                    if choiceBtn then
                        pcall(function()
                            for i = 1, 7 do
                                if not Config.AutoSell then break end
                                
                                -- Получаем абсолютные экранные координаты
                                local absPos = choiceBtn.AbsolutePosition
                                local absSize = choiceBtn.AbsoluteSize
                                local centerX = absPos.X + (absSize.X / 2)
                                local centerY = absPos.Y + (absSize.Y / 2) + 36 -- Компенсация плавающего топбара
                                
                                -- 1. Эмуляция физического тапа по экрану (Input Injection)
                                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
                                task.wait(0.03)
                                VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
                                
                                -- 2. Обходной внутренний клик через IY-методы
                                if firesignal then 
                                    firesignal(choiceBtn.MouseButton1Click)
                                    firesignal(choiceBtn.Activated)
                                end
                                if getconnections then
                                    for _, c in pairs(getconnections(choiceBtn.MouseButton1Click)) do c:Fire() end
                                    for _, c in pairs(getconnections(choiceBtn.Activated)) do c:Fire() end
                                end
                                
                                task.wait(0.12) -- Скорость спама (~7 кликов за секунду)
                            end
                        end)
                    end
                    task.wait(2) 
                    hrp.CFrame = savedCFrame
                end
            end
        end
    end
end)
-- Циклы конвейера и авто-покупок инструментов/миксеров
task.spawn(function()
    while true do
        if Config.Autofarm then for _, item in pairs(Items:GetChildren()) do if not Config.Autofarm then break end if item and item:IsA("Model") and item.PrimaryPart and Config.Rarities[getRarity(item)] then collectItem(item) task.wait(0.05) end end end
        task.wait(0.3)
    end
end)

task.spawn(function()
    while true do task.wait(0.5)
        for gearName, enabled in pairs(Config.Gear) do if enabled then Buy:FireServer("PurchaseGearItem", gearName) end end
        for blenderName, enabled in pairs(Config.Blenders) do if enabled then Event:FireServer("PurchaseMixerItem", blenderName) end end
    end
end)

RunService.Stepped:Connect(function()
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid") if hum and not Config.FlyEnabled then hum.WalkSpeed = Config.WalkSpeedValue end
        if Config.NoclipEnabled then for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    end
end)

game:GetService("UserInputService").JumpRequest:Connect(function() if Config.InfJumpEnabled then local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid") if hum then hum:ChangeState("Jumping") end end end)
local flyBodyGyro, flyBodyVelocity
task.spawn(function()
    while true do task.wait(0.1) local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        if Config.FlyEnabled and hrp then
            if not flyBodyGyro then flyBodyGyro = Instance.new("BodyGyro", hrp) flyBodyGyro.P = 9e4 flyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9) flyBodyVelocity = Instance.new("BodyVelocity", hrp) flyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9) end
            local camera = workspace.CurrentCamera local hum = Player.Character:FindFirstChildOfClass("Humanoid") local moveDirection = hum and hum.MoveDirection or Vector3.new(0,0,0)
            flyBodyGyro.cframe = camera.CFrame flyBodyVelocity.velocity = moveDirection.Magnitude > 0 and moveDirection * Config.FlySpeed or Vector3.new(0, 0.1, 0)
        else
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        end
    end
end)

local function getPlayerNames() local names = {} for _, p in pairs(Players:GetPlayers()) do if p ~= Player then table.insert(names, p.Name) end end return names end

-- СОЗДАНИЕ ИНТЕРФЕЙСА FLUENT
local Window = Fluent:CreateWindow({Title = "TG - @AlexFayrScript", SubTitle = "v8.4 - Complete Edition", TabWidth = 130, Size = UDim2.fromOffset(480, 440), Theme = "Dark"})
local Tabs = {
    Main = Window:AddTab({Title = "Farm", Icon = "home"}), 
    Shop = Window:AddTab({Title = "Shop", Icon = "shopping-cart"}), 
    Player = Window:AddTab({Title = "Player", Icon = "user"}), 
    Stat = Window:AddTab({Title = "Stats", Icon = "bar-chart"}),
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}
UI_Elements.MainTab, UI_Elements.ShopTab, UI_Elements.PlayerTab, UI_Elements.StatTab, UI_Elements.SettingsTab = Tabs.Main, Tabs.Shop, Tabs.Player, Tabs.Stat, Tabs.Settings

-- ВКЛАДКА FARM
UI_Elements.AutoSellToggle = Tabs.Main:AddToggle("AutoSellToggle", {Title = "Auto-Sell (Teleport every 15s)", Default = false, Callback = function(v) Config.AutoSell = v end})
UI_Elements.AutofarmToggle = Tabs.Main:AddToggle("AutofarmToggle", {Title = "Enable Conveyor Autofarm", Default = false, Callback = function(v) Config.Autofarm = v end})
UI_Elements.AutoHarvestToggle = Tabs.Main:AddToggle("AutoHarvestToggle", {Title = "Auto-Harvest (Own Plot)", Default = false, Callback = function(v) Config.AutoHarvestPlot = v end})
UI_Elements.MoveModeDropdown = Tabs.Main:AddDropdown("MoveModeDropdown", {Title = "Movement Mode", Values = {"Teleport", "Fast Walk (Скольжение)"}, Default = "Teleport", Callback = function(v) Config.MoveMode = (v == "Teleport") and "Teleport" or "Walk" end})

UI_Elements.RaritiesSec = Tabs.Main:AddSection("Conveyor Rarity Filter")
UI_Elements.RarityToggles = {}
local rarityOrder = {"Divine", "Secret", "Exotic", "Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
for _, rarity in ipairs(rarityOrder) do UI_Elements.RarityToggles[rarity] = Tabs.Main:AddToggle("Rarity_" .. rarity, {Title = "Collect: " .. rarity, Default = false, Callback = function(v) Config.Rarities[rarity] = v end}) end

-- ВКЛАДКА SHOP (ИНСТРУМЕНТЫ, ЯЙЦА, МИКСЕРЫ)
UI_Elements.EggsSec = Tabs.Shop:AddSection("— AUTO BUY EGGS (SAFE EXT) —")
UI_Elements.EggToggles = {}
local eggRaritiesList = {"Secret", "Exotic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
for i, eggRarity in ipairs(eggRaritiesList) do UI_Elements.EggToggles[eggRarity] = Tabs.Shop:AddToggle("EggRar_"..i, {Title = "Auto Buy: " .. eggRarity .. " Egg", Default = false, Callback = function(v) Config.Eggs[eggRarity] = v end}) end

UI_Elements.GearSec = Tabs.Shop:AddSection("— GEAR / TOOLS —")
UI_Elements.GearToggles = {}
local gearList = {"Watering Can", "Fertilizer", "Sprinkler", "Better Sprinkler", "Trowel", "Collector", "Copper Rod", "Tower Sprinkler", "Golden Watering Can", "Golden Fertilizer", "Golden Sprinkler", "Void Sprinkler", "Favorite Tool", "Reclaimer"}
for i, gear in ipairs(gearList) do UI_Elements.GearToggles[gear] = Tabs.Shop:AddToggle("ShG" .. i, {Title = "Buy: " .. gear, Default = false, Callback = function(v) Config.Gear[gear] = v end}) end

UI_Elements.BlenderSec = Tabs.Shop:AddSection("— BLENDERS / MIXERS —")
UI_Elements.BlenderToggles = {}
local blenderList = {"Void Blender", "Diamond Blender", "Golden Blender", "Normal Blender", "Basic Blender"}
for i, blender in ipairs(blenderList) do UI_Elements.BlenderToggles[blender] = Tabs.Shop:AddToggle("ShB" .. i, {Title = "Buy: " .. blender, Default = false, Callback = function(v) Config.Blenders[blender] = v end}) end

-- ВКЛАДКА PLAYER
UI_Elements.SpeedSlider = Tabs.Player:AddSlider("SpeedSlider", {Title = "WalkSpeed", Description = "Регулировка скорости", Min = 16, Max = 200, Default = 16, Rounding = 0, Callback = function(v) Config.WalkSpeedValue = v end})
UI_Elements.FlyToggle = Tabs.Player:AddToggle("FlyToggle", {Title = "Fly Mode", Default = false, Callback = function(v) Config.FlyEnabled = v end})
UI_Elements.NoclipToggle = Tabs.Player:AddToggle("NoclipToggle", {Title = "Noclip", Default = false, Callback = function(v) Config.NoclipEnabled = v end})
UI_Elements.InfJumpToggle = Tabs.Player:AddToggle("InfJumpToggle", {Title = "Infinite Jump", Default = false, Callback = function(v) Config.InfJumpEnabled = v end})
UI_Elements.TeleportSec = Tabs.Player:AddSection("— PLAYER TELEPORTATION —")
UI_Elements.PlayerDropdown = Tabs.Player:AddDropdown("PlayerDropdown", {Title = "Select Player", Values = getPlayerNames(), Default = "", Callback = function(v) Config.SelectedTargetPlayer = v end})
task.spawn(function() while true do task.wait(3) if UI_Elements.PlayerDropdown then UI_Elements.PlayerDropdown:SetValues(getPlayerNames()) end end end)
UI_Elements.PlayerMoveModeDropdown = Tabs.Player:AddDropdown("PlayerMoveModeDropdown", {Title = "Player TP Movement Mode", Values = {"Teleport", "Fast Walk (Скольжение)"}, Default = "Teleport", Callback = function(v) Config.PlayerMoveMode = (v == "Teleport") and "Teleport" or "Walk" end})
UI_Elements.TPButton = Tabs.Player:AddButton({Title = "Teleport to Player", Callback = function()
    local targetPlayer = Players:FindFirstChild(Config.SelectedTargetPlayer) local targetHrp = targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    local myHrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if myHrp and targetHrp then moveToTarget(myHrp, targetHrp.CFrame, Config.PlayerMoveMode, nil) end
end})

-- ВКЛАДКА СТАТИСТИКИ
UI_Elements.DailyToggle = Tabs.Stat:AddToggle("DailyToggle", {Title = "Include Daily Boost", Default = false, Callback = function(v) Config.UseDailyBoost = v end})
UI_Elements.FriendToggle = Tabs.Stat:AddToggle("FriendToggle", {Title = "Include Friend Boost", Default = false, Callback = function(v) Config.UseFriendBoost = v end})
UI_Elements.CalcBtn = Tabs.Stat:AddButton({Title = "Calculate Inventory Value", Callback = function()
    local val = CalculateInventoryValue()
    Fluent:Notify({Title = "Calculator", Content = "Total Inventory Value: $" .. tostring(val), Duration = 5})
end})

-- ВКЛАДКА НАСТРОЕК
UI_Elements.LangSec = Tabs.Settings:AddSection("— LANGUAGE —")
UI_Elements.LangDropdown = Tabs.Settings:AddDropdown("LangDropdown", {Title = "Interface Language", Values = {"English (EN)", "Русский (RU)"}, Default = "English (EN)", Callback = function(v) Config.Language = (v == "Русский (RU)") and "RU" or "EN" UpdateLanguage() end})
UI_Elements.ConfigSec = Tabs.Settings:AddSection("— CONFIGURATION —")
UI_Elements.SaveBtn = Tabs.Settings:AddButton({Title = "Save Config", Callback = function() SaveConfig() end})
UI_Elements.LoadBtn = Tabs.Settings:AddButton({Title = "Load Config", Callback = function() LoadConfig(false) end})
UI_Elements.AutoloadToggle = Tabs.Settings:AddToggle("AutoloadToggle", {Title = "Auto-load on startup", Default = false, Callback = function(v) Config.Autoload = v end})

-- МОБИЛЬНАЯ КНОПКА MENU ДЛЯ DELTA
local ScreenGui = Instance.new("ScreenGui") ScreenGui.Name = "DeltaToggleGui" ScreenGui.ResetOnSpawn = false pcall(function() ScreenGui.Parent = PlayerGui end)
local OpenButton = Instance.new("TextButton", ScreenGui) OpenButton.Size = UDim2.new(0, 80, 0, 45) OpenButton.Position = UDim2.new(0, 15, 0.4, 0) OpenButton.Text = "MENU" OpenButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35) OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255) OpenButton.Font = Enum.Font.SourceSansBold OpenButton.TextSize = 16 OpenButton.Active = true OpenButton.Draggable = true
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(0, 8)
OpenButton.MouseButton1Click:Connect(function() Window:Minimize() end)

if isfile and isfile(ConfigFile) then local checkData = HttpService:JSONDecode(readfile(ConfigFile)) if checkData and checkData.Autoload then LoadConfig(true) end end
UpdateLanguage()
