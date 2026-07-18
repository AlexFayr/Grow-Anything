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
    WalkSpeedValue = 16, FlyEnabled = false, FlySpeed = 50, NoclipEnabled = false, InfJumpEnabled = false, PlayerMoveMode = "Teleport", SelectedTargetPlayer = ""
}
local UI_Elements = {}
local Localization = {
    RU = {
        Title = "Фарм", ShopTitle = "Магазин", SettingsTitle = "Настройки", PlayerTitle = "Игрок", Autofarm = "Включить автофарм конвейера", MoveMode = "Режим перемещения", RaritiesSec = "Фильтр редкостей для конвейера", Collect = "Собирать: ", GearSec = "— ИНСТРУМЕНТЫ —", BlenderSec = "— МИКСЕРЫ —", Buy = "Купить: ", LangSec = "— СМЕНА ЯЗЫКА —", LangTitle = "Язык интерфейса / Language", ConfigSec = "— КОНФИГУРАЦИЯ —", SaveBtn = "Сохранить конфиг", LoadBtn = "Загрузить конфиг", AutoloadToggle = "Авто-загрузка при старте", SavedNotify = "Конфигурация успешно сохранена!", LoadedNotify = "Конфигурация успешно загружена!", AutoloadNotify = "Авто-конфиг успешно применён!",
        SpeedSlider = "Скорость бега", FlyToggle = "Режим полета", NoclipToggle = "Прохождение сквозь стены", InfJumpToggle = "Бесконечный прыжок", TeleportSec = "— ТЕЛЕПОРТАЦИЯ К ИГРОКАМ —", SelectPlayer = "Выберите игрока", TPMode = "Тип перемещения к игроку", TPButton = "Телепортироваться"
    },
    EN = {
        Title = "Farm", ShopTitle = "Shop", SettingsTitle = "Settings", PlayerTitle = "Player", Autofarm = "Enable Conveyor Autofarm", MoveMode = "Movement Mode", RaritiesSec = "Conveyor Rarity Filter", Collect = "Collect: ", GearSec = "— GEAR / TOOLS —", BlenderSec = "— BLENDERS / MIXERS —", Buy = "Buy: ", LangSec = "— LANGUAGE —", LangTitle = "Interface Language", ConfigSec = "— CONFIGURATION —", SaveBtn = "Save Config", LoadBtn = "Load Config", AutoloadToggle = "Auto-load on startup", SavedNotify = "Configuration saved successfully!", LoadedNotify = "Configuration loaded successfully!", AutoloadNotify = "Auto-config applied successfully!",
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
    setElementTitle(UI_Elements.LangSec, t.LangSec) setElementTitle(UI_Elements.LangDropdown, t.LangTitle) setElementTitle(UI_Elements.ConfigSec, t.ConfigSec) setElementTitle(UI_Elements.AutoloadToggle, t.AutoloadToggle) setElementTitle(UI_Elements.SaveBtn, t.SaveBtn) setElementTitle(UI_Elements.LoadBtn, t.LoadBtn)
    setElementTitle(UI_Elements.SpeedSlider, t.SpeedSlider) setElementTitle(UI_Elements.FlyToggle, t.FlyToggle) setElementTitle(UI_Elements.NoclipToggle, t.NoclipToggle) setElementTitle(UI_Elements.InfJumpToggle, t.InfJumpToggle) setElementTitle(UI_Elements.TeleportSec, t.TeleportSec) setElementTitle(UI_Elements.PlayerDropdown, t.SelectPlayer) setElementTitle(UI_Elements.PlayerMoveModeDropdown, t.TPMode) setElementTitle(UI_Elements.TPButton, t.TPButton)
end
local function SaveConfig()
    if writefile then writefile(ConfigFile, HttpService:JSONEncode(Config)) Fluent:Notify({Title = Config.Language == "RU" and "Успех" or "Success", Content = Localization[Config.Language].SavedNotify, Duration = 3}) end
end
local function LoadConfig(isAutoload)
    if isfile and readfile and isfile(ConfigFile) then
        local data = HttpService:JSONDecode(readfile(ConfigFile))
        if data then
            Config.Language = data.Language or "EN" Config.Autoload = data.Autoload or false Config.Autofarm = data.Autofarm or false Config.MoveMode = data.MoveMode or "Teleport"
            for k, v in pairs(data.Rarities or {}) do Config.Rarities[k] = v end for k, v in pairs(data.Gear or {}) do Config.Gear[k] = v end for k, v in pairs(data.Blenders or {}) do Config.Blenders[k] = v end
            if UI_Elements.AutofarmToggle then UI_Elements.AutofarmToggle:SetValue(Config.Autofarm) end if UI_Elements.MoveModeDropdown then UI_Elements.MoveModeDropdown:SetValue(Config.MoveMode == "Teleport" and "Teleport" or "Fast Walk (Скольжение)") end if UI_Elements.LangDropdown then UI_Elements.LangDropdown:SetValue(Config.Language == "RU" and "Русский (RU)" or "English (EN)") end if UI_Elements.AutoloadToggle then UI_Elements.AutoloadToggle:SetValue(Config.Autoload) end
            for rarity, toggle in pairs(UI_Elements.RarityToggles or {}) do toggle:SetValue(Config.Rarities[rarity]) end for gear, toggle in pairs(UI_Elements.GearToggles or {}) do toggle:SetValue(Config.Gear[gear]) end for blender, toggle in pairs(UI_Elements.BlenderToggles or {}) do toggle:SetValue(Config.Blenders[blender]) end
            UpdateLanguage() Fluent:Notify({Title = Config.Language == "RU" and "Конфиг" or "Config", Content = isAutoload and Localization[Config.Language].AutoloadNotify or Localization[Config.Language].LoadedNotify, Duration = 3})
        end
    end
end
for _, p in pairs(CollectionSpots:GetChildren()) do if p:FindFirstChild("MyGardenGui") and p:FindFirstChild("MyGardenGui").TextLabel.Text == "My Garden" then playercollect = p end end
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
    if playercollect then moveToTarget(hrp, playercollect.CFrame, Config.MoveMode, "Autofarm") else moveToTarget(hrp, originalPos, Config.MoveMode, "Autofarm") end
end
task.spawn(function()
    while true do
        if Config.Autofarm then for _, item in pairs(Items:GetChildren()) do if not Config.Autofarm then break end if item and item:IsA("Model") and item.PrimaryPart and Config.Rarities[getRarity(item)] then collectItem(item) task.wait(0.05) end end end
        task.wait(0.3)
    end
end)
task.spawn(function()
    while true do
        task.wait(1)
        for gearName, enabled in pairs(Config.Gear) do if enabled then Buy:FireServer("PurchaseGearItem", gearName) end end
        for blenderName, enabled in pairs(Config.Blenders) do if enabled then Event:FireServer("PurchaseMixerItem", blenderName) end end
        if typeof(keyclick) == "function" then keyclick(113) end
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
local Window = Fluent:CreateWindow({Title = "TG - @AlexFayrScript", SubTitle = "v7.0 - Configs & Langs", TabWidth = 130, Size = UDim2.fromOffset(480, 440), Theme = "Dark"})
local Tabs = {Main = Window:AddTab({Title = "Farm", Icon = "home"}), Shop = Window:AddTab({Title = "Shop", Icon = "shopping-cart"}), Player = Window:AddTab({Title = "Player", Icon = "user"}), Settings = Window:AddTab({Title = "Settings", Icon = "settings"})}
UI_Elements.MainTab, UI_Elements.ShopTab, UI_Elements.PlayerTab, UI_Elements.SettingsTab = Tabs.Main, Tabs.Shop, Tabs.Player, Tabs.Settings
UI_Elements.AutofarmToggle = Tabs.Main:AddToggle("AutofarmToggle", {Title = "Enable Conveyor Autofarm", Default = false, Callback = function(Value) Config.Autofarm = Value end})
UI_Elements.MoveModeDropdown = Tabs.Main:AddDropdown("MoveModeDropdown", {Title = "Movement Mode", Values = {"Teleport", "Fast Walk (Скольжение)"}, Default = "Teleport", Callback = function(Value) Config.MoveMode = (Value == "Teleport") and "Teleport" or "Walk" end})
UI_Elements.RaritiesSec = Tabs.Main:AddSection("Conveyor Rarity Filter")
UI_Elements.RarityToggles = {}
local rarityOrder = {"Divine", "Secret", "Exotic", "Mythical", "Legendary", "Epic", "Rare", "Uncommon", "Common"}
for _, rarity in ipairs(rarityOrder) do UI_Elements.RarityToggles[rarity] = Tabs.Main:AddToggle("Rarity_" .. rarity, {Title = "Collect: " .. rarity, Default = false, Callback = function(Value) Config.Rarities[rarity] = Value end}) end
UI_Elements.GearSec = Tabs.Shop:AddSection("— GEAR / TOOLS —")
UI_Elements.GearToggles = {}
local gearList = {"Watering Can", "Fertilizer", "Sprinkler", "Better Sprinkler", "Trowel", "Collector", "Copper Rod", "Tower Sprinkler", "Golden Watering Can", "Golden Fertilizer", "Golden Sprinkler", "Void Sprinkler", "Favorite Tool", "Reclaimer"}
for i, gear in ipairs(gearList) do UI_Elements.GearToggles[gear] = Tabs.Shop:AddToggle("ShG" .. i, {Title = "Buy: " .. gear, Default = false, Callback = function(v) Config.Gear[gear] = v end}) end
UI_Elements.BlenderSec = Tabs.Shop:AddSection("— BLENDERS / MIXERS —")
UI_Elements.BlenderToggles = {}
local blenderList = {"Void Blender", "Diamond Blender", "Golden Blender", "Normal Blender", "Basic Blender"}
for i, blender in ipairs(blenderList) do UI_Elements.BlenderToggles[blender] = Tabs.Shop:AddToggle("ShB" .. i, {Title = "Buy: " .. blender, Default = false, Callback = function(v) Config.Blenders[blender] = v end}) end
UI_Elements.SpeedSlider = Tabs.Player:AddSlider("SpeedSlider", {Title = "WalkSpeed", Description = "Регулировка скорости", Min = 16, Max = 200, Default = 16, Rounding = 0, Callback = function(Value) Config.WalkSpeedValue = Value end})
UI_Elements.FlyToggle = Tabs.Player:AddToggle("FlyToggle", {Title = "Fly Mode", Default = false, Callback = function(Value) Config.FlyEnabled = Value end})
UI_Elements.NoclipToggle = Tabs.Player:AddToggle("NoclipToggle", {Title = "Noclip", Default = false, Callback = function(Value) Config.NoclipEnabled = Value end})
UI_Elements.InfJumpToggle = Tabs.Player:AddToggle("InfJumpToggle", {Title = "Infinite Jump", Default = false, Callback = function(Value) Config.InfJumpEnabled = Value end})
UI_Elements.TeleportSec = Tabs.Player:AddSection("— PLAYER TELEPORTATION —")
UI_Elements.PlayerDropdown = Tabs.Player:AddDropdown("PlayerDropdown", {Title = "Select Player", Values = getPlayerNames(), Default = "", Callback = function(Value) Config.SelectedTargetPlayer = Value end})
task.spawn(function() while true do task.wait(3) if UI_Elements.PlayerDropdown then UI_Elements.PlayerDropdown:SetValues(getPlayerNames()) end end end)
UI_Elements.PlayerMoveModeDropdown = Tabs.Player:AddDropdown("PlayerMoveModeDropdown", {Title = "Player TP Movement Mode", Values = {"Teleport", "Fast Walk (Скольжение)"}, Default = "Teleport", Callback = function(Value) Config.PlayerMoveMode = (Value == "Teleport") and "Teleport" or "Walk" end})
UI_Elements.TPButton = Tabs.Player:AddButton({Title = "Teleport to Player", Callback = function()
    local targetName = Config.SelectedTargetPlayer
    if targetName and targetName ~= "" then
        local targetPlayer = Players:FindFirstChild(targetName) local targetChar = targetPlayer and targetPlayer.Character local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local myChar = Player.Character local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if myHrp and targetHrp then moveToTarget(myHrp, targetHrp.CFrame, Config.PlayerMoveMode, nil) end
    end
end})
UI_Elements.LangSec = Tabs.Settings:AddSection("— LANGUAGE —")
UI_Elements.LangDropdown = Tabs.Settings:AddDropdown("LangDropdown", {Title = "Interface Language", Values = {"English (EN)", "Русский (RU)"}, Default = "English (EN)", Callback = function(Value) Config.Language = (Value == "Русский (RU)") and "RU" or "EN" UpdateLanguage() end})
UI_Elements.ConfigSec = Tabs.Settings:AddSection("— CONFIGURATION —")
UI_Elements.SaveBtn = Tabs.Settings:AddButton({Title = "Save Config", Callback = function() SaveConfig() end})
UI_Elements.LoadBtn = Tabs.Settings:AddButton({Title = "Load Config", Callback = function() LoadConfig(false) end})
UI_Elements.AutoloadToggle = Tabs.Settings:AddToggle("AutoloadToggle", {Title = "Auto-load on startup", Default = false, Callback = function(Value) Config.Autoload = Value end})
local ScreenGui = Instance.new("ScreenGui") ScreenGui.Name = "DeltaToggleGui" ScreenGui.ResetOnSpawn = false pcall(function() ScreenGui.Parent = PlayerGui end)
local OpenButton = Instance.new("TextButton") OpenButton.Parent = ScreenGui OpenButton.Size = UDim2.new(0, 80, 0, 45) OpenButton.Position = UDim2.new(0, 15, 0.4, 0) OpenButton.Text = "MENU" OpenButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35) OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255) OpenButton.Font = Enum.Font.SourceSansBold OpenButton.TextSize = 16 OpenButton.Active = true OpenButton.Draggable = true
local UICorner = Instance.new("UICorner", OpenButton) UICorner.CornerRadius = UDim.new(0, 8)
OpenButton.MouseButton1Click:Connect(function() Window:Minimize() end)
if isfile and isfile(ConfigFile) then local checkData = HttpService:JSONDecode(readfile(ConfigFile)) if checkData and checkData.Autoload then LoadConfig(true) end end
UpdateLanguage()
firesignal(Event.OnClientEvent, "Notify", {Top = true, Text = "<b><font color ='#ED401C'>Autofarm</font></b> has been loaded!", Sound = "Mutate"})
