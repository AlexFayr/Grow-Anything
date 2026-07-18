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
local playercollect = nil
local ConfigFile = "GardenHub_Config.json"

local Config = {
    Language = "EN", Autoload = false, Autofarm = false, MoveMode = "Teleport",
    Rarities = {["Divine"] = false, ["Secret"] = false, ["Exotic"] = false, ["Mythical"] = false, ["Legendary"] = false, ["Epic"] = false, ["Rare"] = false, ["Uncommon"] = false, ["Common"] = false},
    Gear = {["Watering Can"] = false, ["Fertilizer"] = false, ["Sprinkler"] = false, ["Better Sprinkler"] = false, ["Trowel"] = false, ["Collector"] = false, ["Copper Rod"] = false, ["Tower Sprinkler"] = false, ["Golden Watering Can"] = false, ["Golden Fertilizer"] = false, ["Golden Sprinkler"] = false, ["Void Sprinkler"] = false, ["Favorite Tool"] = false, ["Reclaimer"] = false},
    Blenders = {["Void Blender"] = false, ["Diamond Blender"] = false, ["Golden Blender"] = false, ["Normal Blender"] = false, ["Basic Blender"] = false},
    Eggs = {["Secret"] = false, ["Exotic"] = false, ["Mythic"] = false, ["Legendary"] = false, ["Epic"] = false, ["Rare"] = false, ["Uncommon"] = false, ["Common"] = false},
    WalkSpeedValue = 16, FlyEnabled = false, FlySpeed = 50, NoclipEnabled = false, InfJumpEnabled = false, PlayerMoveMode = "Teleport", SelectedTargetPlayer = ""
}

local UI_Elements = {}
local Localization = {
    RU = {
        Title = "Фарм", ShopTitle = "Магазин", SettingsTitle = "Настройки", PlayerTitle = "Игрок", Autofarm = "Включить автофарм конвейера", MoveMode = "Режим перемещения", RaritiesSec = "Фильтр редкостей для конвейера", Collect = "Собирать: ", GearSec = "— ИНСТРУМЕНТЫ —", BlenderSec = "— МИКСЕРЫ —", EggsSec = "— АВТОПОКУПКА ЯИЦ (БЕЗОПАСНАЯ) —", Buy = "Купить: ", BuyEgg = "Автопокупка: ", LangSec = "— СМЕНА ЯЗЫКА —", LangTitle = "Язык интерфейса / Language", ConfigSec = "— КОНФИГУРАЦИЯ —", SaveBtn = "Сохранить конфиг", LoadBtn = "Загрузить конфиг", AutoloadToggle = "Авто-загрузка при старте", SavedNotify = "Конфигурация успешно сохранена!", LoadedNotify = "Конфигурация успешно загружена!", AutoloadNotify = "Авто-конфиг успешно применён!",
        SpeedSlider = "Скорость бега", FlyToggle = "Режим полета", NoclipToggle = "Прохождение сквозь стены", InfJumpToggle = "Бесконечный прыжок", TeleportSec = "— ТЕЛЕПОРТАЦИЯ К ИГРОКАМ —", SelectPlayer = "Выберите игрока", TPMode = "Тип перемещения к игроку", TPButton = "Телепортироваться"
    },
    EN = {
        Title = "Farm", ShopTitle = "Shop", SettingsTitle = "Settings", PlayerTitle = "Player", Autofarm = "Enable Conveyor Autofarm", MoveMode = "Movement Mode", RaritiesSec = "Conveyor Rarity Filter", Collect = "Collect: ", GearSec = "— GEAR / TOOLS —", BlenderSec = "— BLENDERS / MIXERS —", EggsSec = "— AUTO BUY EGGS (SAFE EXT) —", Buy = "Buy: ", BuyEgg = "Auto Buy: ", LangSec = "— LANGUAGE —", LangTitle = "Interface Language", ConfigSec = "— CONFIGURATION —", SaveBtn = "Save Config", LoadBtn = "Load Config", AutoloadToggle = "Auto-load on startup", SavedNotify = "Configuration saved successfully!", LoadedNotify = "Configuration loaded successfully!", AutoloadNotify = "Auto-config applied successfully!",
        SpeedSlider = "WalkSpeed", FlyToggle = "Fly Mode", NoclipToggle = "Noclip", InfJumpToggle = "Infinite Jump", TeleportSec = "— PLAYER TELEPORTATION —", SelectPlayer = "Select Player", TPMode = "Player TP Movement Mode", TPButton = "Teleport to Player"
    }
}

local function setElementTitle(element, title)
    if not element or type(element) ~= "table" then return end
    if element.SetTitle then local success = pcall(function() element:SetTitle(title) end) if success then return end end
    element.Title = title
    pcall(function()
        if element.Instance then local label = element.Instance:FindFirstChild("Title", true) or element.Instance:FindFirstChild("TextLabel", true) if label and label:IsA("TextLabel") then label.Text = title return end end
        if element.Button then local label = element.Button:FindFirstChild("Title", true) or element.Button:FindFirstChild("TextLabel", true) if label and label:IsA("TextLabel") then label.Text = title end end
    end)
end

local function UpdateLanguage()
    local t = Localization[Config.Language]
    setElementTitle(UI_Elements.MainTab, t.Title) setElementTitle(UI_Elements.ShopTab, t.ShopTitle) setElementTitle(UI_Elements.SettingsTab, t.SettingsTitle) setElementTitle(UI_Elements.PlayerTab, t.PlayerTitle)
    setElementTitle(UI_Elements.AutofarmToggle, t.Autofarm) setElementTitle(UI_Elements.MoveModeDropdown, t.MoveMode) setElementTitle(UI_Elements.RaritiesSec, t.RaritiesSec)
    for rarity, toggle in pairs(UI_Elements.RarityToggles or {}) do setElementTitle(toggle, t.Collect .. rarity) end
    setElementTitle(UI_Elements.GearSec, t.GearSec) for gear, toggle in pairs(UI_Elements.GearToggles or {}) do setElementTitle(toggle, t.Buy .. gear) end
    setElementTitle(UI_Elements.BlenderSec, t.BlenderSec) for blender, toggle in pairs(UI_Elements.BlenderToggles or {}) do setElementTitle(toggle, t.Buy .. blender) end
    setElementTitle(UI_Elements.EggsSec, t.EggsSec) for eggRarity, toggle in pairs(UI_Elements.EggToggles or {}) do setElementTitle(toggle, t.BuyEgg .. eggRarity .. " Egg") end
    setElementTitle(UI_Elements.LangSec, t.LangSec) setElementTitle(UI_Elements.LangDropdown, t.LangTitle) setElementTitle(UI_Elements.ConfigSec, t.ConfigSec) setElementTitle(UI_Elements.AutoloadToggle, t.AutoloadToggle) setElementTitle(UI_Elements.SaveBtn, t.SaveBtn) setElementTitle(UI_Elements.LoadBtn, t.LoadBtn)
    setElementTitle(UI_Elements.SpeedSlider, t.SpeedSlider) setElementTitle(UI_Elements.FlyToggle, t.FlyToggle) setElementTitle(UI_Elements.NoclipToggle, t.NoclipToggle) setElementTitle(UI_Elements.InfJumpToggle, t.InfJumpToggle) setElementTitle(UI_Elements.TeleportSec, t.TeleportSec) setElementTitle(UI_Elements.PlayerDropdown, t.SelectPlayer) setElementTitle(UI_Elements.PlayerMoveModeDropdown, t.TPMode) setElementTitle(UI_Elements.TPButton, t.TPButton)
end

local function SaveConfig()
    if writefile then 
        writefile(ConfigFile, HttpService:JSONEncode(Config)) 
        Fluent:Notify({Title = Config.Language == "RU" and "Успех" or "Success", Content = Localization[Config.Language].SavedNotify, Duration = 3}) 
    end
end

local function updatePlayerPlot()
    if playercollect and playercollect.Parent == CollectionSpots then return playercollect end
    for _, p in pairs(CollectionSpots:GetChildren()) do 
        if p:FindFirstChild("MyGardenGui") and p:FindFirstChild("MyGardenGui").TextLabel.Text == "My Garden" then 
            playercollect = p 
            return p
        end 
    end
    return nil
end

local function LoadConfig(isAutoload)
    if isfile and readfile and isfile(ConfigFile) then
        local success, data = pcall(function() return HttpService:JSONDecode(readfile(ConfigFile)) end)
        if success and data then
            Config.Language = data.Language or "EN"
            Config.Autoload = data.Autoload or false
            Config.Autofarm = data.Autofarm or false
            Config.MoveMode = data.MoveMode or "Teleport"
            Config.WalkSpeedValue = data.WalkSpeedValue or 16
            Config.FlyEnabled = data.FlyEnabled or false
            Config.FlySpeed = data.FlySpeed or 50
            Config.NoclipEnabled = data.NoclipEnabled or false
            Config.InfJumpEnabled = data.InfJumpEnabled or false
            Config.PlayerMoveMode = data.PlayerMoveMode or "Teleport"
            
            for k, v in pairs(data.Rarities or {}) do Config.Rarities[k] = v end 
            for k, v in pairs(data.Gear or {}) do Config.Gear[k] = v end 
            for k, v in pairs(data.Blenders or {}) do Config.Blenders[k] = v end 
            for k, v in pairs(data.Eggs or {}) do Config.Eggs[k] = v end

            local function safeSet(element, value)
                if element and element.SetValue and value ~= nil then pcall(function() element:SetValue(value) end) end
            end

            safeSet(UI_Elements.AutofarmToggle, Config.Autofarm)
            safeSet(UI_Elements.MoveModeDropdown, Config.MoveMode == "Teleport" and "Teleport" or "Fast Walk (Скольжение)")
            safeSet(UI_Elements.LangDropdown, Config.Language == "RU" and "Русский (RU)" or "English (EN)")
            safeSet(UI_Elements.AutoloadToggle, Config.Autoload)
            safeSet(UI_Elements.SpeedSlider, Config.WalkSpeedValue)
            safeSet(UI_Elements.FlyToggle, Config.FlyEnabled)
            safeSet(UI_Elements.NoclipToggle, Config.NoclipEnabled)
            safeSet(UI_Elements.InfJumpToggle, Config.InfJumpEnabled)
            safeSet(UI_Elements.PlayerMoveModeDropdown, Config.PlayerMoveMode == "Teleport" and "Teleport" or "Fast Walk (Скольжение)")

            for rarity, toggle in pairs(UI_Elements.RarityToggles or {}) do safeSet(toggle, Config.Rarities[rarity]) end
            for gear, toggle in pairs(UI_Elements.GearToggles or {}) do safeSet(toggle, Config.Gear[gear]) end
            for blender, toggle in pairs(UI_Elements.BlenderToggles or {}) do safeSet(toggle, Config.Blenders[blender]) end
            for eggRarity, toggle in pairs(UI_Elements.EggToggles or {}) do safeSet(toggle, Config.Eggs[eggRarity]) end

            UpdateLanguage() 
            Fluent:Notify({Title = Config.Language == "RU" and "Конфиг" or "Config", Content = isAutoload and Localization[Config.Language].AutoloadNotify or Localization[Config.Language].LoadedNotify, Duration = 3})
        end
    end
end

updatePlayerPlot()

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

-- Основной цикл сбора с конвейера
task.spawn(function()
    while true do
        if Config.Autofarm then for _, item in pairs(Items:GetChildren()) do if not Config.Autofarm then break end if item and item:IsA("Model") and item.PrimaryPart and Config.Rarities[getRarity(item)] then collectItem(item) task.wait(0.05) end end end
        task.wait(0.3)
    end
end)

-- Удаленная покупка инструментов и миксеров
task.spawn(function()
    while true do
        task.wait(0.5)
        for gearName, enabled in pairs(Config.Gear) do if enabled then Buy:FireServer("PurchaseGearItem", gearName) end end
        for blenderName, enabled in pairs(Config.Blenders) do if enabled then Event:FireServer("PurchaseMixerItem", blenderName) end end
        if typeof(keyclick) == "function" then keyclick(113) end
    end
end)

-- Безопасный глобальный поиск магазинных яиц
task.spawn(function()
    while true do
        task.wait(0.5)
        
        local anyEggEnabled = false
        for _, enabled in pairs(Config.Eggs) do if enabled then anyEggEnabled = true break end end
        
        if anyEggEnabled then
            local character = Player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local currentPlot = updatePlayerPlot()
            
            if hrp then
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("ProximityPrompt") and obj.Parent then
                        local model = obj.Parent
                        local modelName = model.Name:lower()
                        local fullName = obj:GetFullName():lower()
                        
                        local isBlacklistedLocation = false
                        if obj:IsDescendantOf(CollectionSpots) or 
                           (currentPlot and obj:IsDescendantOf(currentPlot)) or
                           string.find(fullName, "collectionspots") or 
                           string.find(fullName, "plot") or 
                           string.find(fullName, "garden") or 
                           string.find(fullName, "placed") or 
                           string.find(fullName, "nest") or
                           string.find(modelName, "plot") or 
                           string.find(modelName, "garden") or
                           string.find(modelName, "placed") then
                            isBlacklistedLocation = true
                        end
                        
                        local isRobuxPrompt = false
                        local actionText = obj.ActionText and obj.ActionText:lower() or ""
                        local objectText = obj.ObjectText and obj.ObjectText:lower() or ""
                        
                        if string.find(actionText, "robux") or string.find(actionText, "r$") or string.find(actionText, "skip") or string.find(actionText, "instant") or 
                           string.find(objectText, "robux") or string.find(objectText, "r$") or string.find(objectText, "skip") or string.find(objectText, "instant") then
                            isRobuxPrompt = true
                        end
                        
                        if not isBlacklistedLocation and not isRobuxPrompt then
                            if string.find(modelName, "egg") or string.find(objectText, "egg") or string.find(actionText, "egg") then
                                
                                local foundRarity = nil
                                for eggRarity, _ in pairs(Config.Eggs) do
                                    if string.find(modelName, eggRarity:lower()) or string.find(objectText, eggRarity:lower()) then
                                        foundRarity = eggRarity
                                        break
                                    end
                                end
                                
                                if foundRarity and Config.Eggs[foundRarity] then
                                    local targetPart = model:IsA("BasePart") and model or model:FindFirstChildWhichIsA("BasePart", true)
                                    
                                    if targetPart then
                                        local originalCFrame = hrp.CFrame
                                        
                                        hrp.CFrame = targetPart.CFrame * CFrame.new(0, 3, 0)
                                        task.wait(0.2)
                                        
                                        fireproximityprompt(obj)
                                        task.wait(0.12)
                                        
                                        local plot = updatePlayerPlot()
                                        if plot then hrp.CFrame = plot.CFrame else hrp.CFrame = originalCFrame end
                                        task.wait(0.4)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    local char = Player.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid") if hum and not Config.FlyEnabled then hum.WalkSpeed = Config.WalkSpeedValue end
        if Config.NoclipEnabled then for _, part in pairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    end
end)

game:GetService("UserInputService").JumpRequest:Connect(function() if Config.InfJumpEnabled then local char = Player.Character local hum = char and char:FindFirstChildOfClass("Humanoid") if hum then hum:ChangeState("Jumping") end end end)
local flyBodyGyro, flyBodyVelocity
task.spawn(function()
    while true do
        task.wait(0.1) local char = Player.Character local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if Config.FlyEnabled and hrp then
            if not flyBodyGyro then
                flyBodyGyro = Instance.new("BodyGyro", hrp) flyBodyGyro.P = 9e4 flyBodyGyro.maxTorque = Vector3.new(9e9, 9e9, 9e9) flyBodyGyro.cframe = hrp.CFrame
                flyBodyVelocity = Instance.new("BodyVelocity", hrp) flyBodyVelocity.velocity = Vector3.new(0, 0.1, 0) flyBodyVelocity.maxForce = Vector3.new(9e9, 9e9, 9e9)
            end
            local camera = workspace.CurrentCamera local hum = char:FindFirstChildOfClass("Humanoid") local moveDirection = hum and hum.MoveDirection or Vector3.new(0,0,0)
            flyBodyGyro.cframe = camera.CFrame if moveDirection.Magnitude > 0 then flyBodyVelocity.velocity = moveDirection * Config.FlySpeed else flyBodyVelocity.velocity = Vector3.new(0, 0.1, 0) end
        else
            if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
        end
    end
end)

local function getPlayerNames() local names = {} for _, p in pairs(Players:GetPlayers()) do if p ~= Player then table.insert(names, p.Name) end end return names end
local Window = Fluent:CreateWindow({Title = "TG - @AlexFayrScript", SubTitle = "v7.8 - Clean & Stable", TabWidth = 130, Size = UDim2.fromOffset(480, 440), Theme = "Dark"})
local Tabs = {
    Main = Window:AddTab({Title = "Farm", Icon = "home"}), 
    Shop = Window:AddTab({Title = "Shop", Icon = "shopping-cart"}), 
    Player = Window:AddTab({Title = "Player", Icon = "user"}), 
    Settings = Window:AddTab({Title = "Settings", Icon = "settings"})
}
UI_Elements.MainTab, UI_Elements.ShopTab, UI_Elements.PlayerTab, UI_Elements.SettingsTab = Tabs.Main, Tabs.Shop, Tabs.Player, Tabs.Settings

UI_Elements.EggsSec = Tabs.Shop:AddSection("— AUTO BUY EGGS (SAFE EXT) —")
UI_Elements.EggToggles = {}
local eggRaritiesList = {"Secret", "Exotic", "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
for i, eggRarity in ipairs(eggRaritiesList) do
    UI_Elements.EggToggles[eggRarity] = Tabs.Shop:AddToggle("EggRar_"..i, {Title = "Auto Buy: " .. eggRarity .. " Egg", Default = false, Callback = function(v) Config.Eggs[eggRarity] = v end})
