local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
local vim = game:GetService("VirtualInputManager")
local L2Hub = loadstring(game:HttpGet("https://raw.githubusercontent.com/euloxa/Library/refs/heads/main/library.lua"))()
local Window = L2Hub:CreateWindow({
    Title = "L2-HUB",
    Size = UDim2.new(0, 520, 0, 350),
    Uitransparent = 0.05
})

-- SETTINGS & STATE
local AutoSkillSettings = { Mode = "Disabled" }

local SurvivorSettings = {
    GodMode = false,
    AntiKnock = false,
    AutoVault = false,
    VaultDistance = 6
}

local BoostGenState = {
    Enabled = false,
    IsBoosting = false
}

local CombatSettings = {
    SilentAim = false,
    TargetPart = "Torso",
    TargetMode = "Killer",
    Laser = false
}

local CombatState = {
    Target = nil,
    LookVector = nil,
    CurrentMuzzle = nil,
    TargetPos = nil,
    IsAiming = false
}

local ParrySettings = {
    Enabled = false,
    Aggressive = false,
    Distance = 8,
    ShowCircle = false
}

local ParryState = {
    LastParry = 0,
    ActiveAttackers = {},
    CirclePart = nil
}

local KillerAttackAnims = {
    ["rbxassetid://78432063483146"] = "attack",
    ["rbxassetid://121216847022485"] = "attack",
    ["rbxassetid://74968262036854"] = "attack",
    ["rbxassetid://132817836308238"] = "attack",
    ["rbxassetid://82666958311998"] = "attack",
    ["rbxassetid://111920872708571"] = "attack",
    ["rbxassetid://106871536134254"] = "attack",
    ["rbxassetid://109402730355822"] = "attack",
    ["rbxassetid://130593238885843"] = "attack",
    ["rbxassetid://138720291317243"] = "attack",
    ["rbxassetid://139369275981139"] = "attack",
    ["rbxassetid://133963973694098"] = "attack",
    ["rbxassetid://78935059863801"] = "attack",
    ["rbxassetid://118907603246885"] = "lungehold",
    ["rbxassetid://135002183282873"] = "lungehold",
    ["rbxassetid://113255068724446"] = "lungehold",
    ["rbxassetid://129784271201071"] = "lungehold",
    ["rbxassetid://105374834496520"] = "lungehold",
    ["rbxassetid://117070354890871"] = "lungehold",
    ["rbxassetid://115244153053858"] = "lungehold",
    ["rbxassetid://110355011987939"] = "lungehold",
    ["rbxassetid://117042998468241"] = "lungehold",
    ["rbxassetid://122812055447896"] = "lungehold"
}

local ESPSettings = {
    Enabled = false,
    Mode = "Chams",
    Targets = {Survivor = false, Killer = false},
    ShowName = false,
    ShowDistance = false,
    FillTrans = 0.5,
    OutlineTrans = 0.3,
    TextSize = 12,
    Colors = {
        Survivor = Color3.fromRGB(0, 255, 0),
        Killer = Color3.fromRGB(255, 0, 0)
    },
    WorldEnabled = false,
    WorldMaxDistance = 150,
    WorldTargets = {Generators = false, Hooks = false, Gates = false, Windows = false, Pallets = false, Zombies = false},
    WorldShowName = false,
    WorldShowDistance = false,
    WorldColors = {
        Generators = Color3.fromRGB(0, 170, 255),
        Hooks = Color3.fromRGB(255, 0, 0),
        Gates = Color3.fromRGB(255, 255, 0),
        Windows = Color3.fromRGB(255, 255, 255),
        Pallets = Color3.fromRGB(255, 170, 0),
        Zombies = Color3.fromRGB(170, 0, 255)
    }
}

local LightingSettings = { 
    Fullbright = false,
    FullbrightValue = 180,
    NoFog = false
}

local MiscSettings = {
    Noclip = false,
    SpeedHack = false,
    SpeedValue = 25,
    ShowFPSPing = false
}

local ESPInstances = {}
local WorldESPInstances = {}
local ValidWorldObjects = {}

-- NEW: CACHES UNTUK OPTIMASI VAULT & ZOMBIE AIM
local CachedVaults = {}
local CachedZombies = {}
local lastWorldScan = 0
local TargetModeGui = nil
local TargetButtons = {}

local prevRot = nil
local lastGoalRot = nil
local instantLastVisible = false
local lastPressTime = 0

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local myChar = Players.LocalPlayer.Character
        if myChar and myChar:FindFirstChild("Twist of Fate") then
            CombatState.IsAiming = true
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        CombatState.IsAiming = false
    end
end)

local function hookMobileAimButton()
    local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return end
    
    local survivorMob = pGui:FindFirstChild("Survivor-mob")
    if survivorMob then
        local controls = survivorMob:FindFirstChild("Controls")
        if controls then
            local guiMob = controls:FindFirstChild("Gui-mob")
            if guiMob and guiMob:IsA("GuiButton") and not guiMob:GetAttribute("AimHooked") then
                guiMob:SetAttribute("AimHooked", true)
                guiMob.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local myChar = Players.LocalPlayer.Character
                        if myChar and myChar:FindFirstChild("Twist of Fate") then
                            CombatState.IsAiming = true
                        end
                    end
                end)
                guiMob.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        CombatState.IsAiming = false
                    end
                end)

                local cancelAim = guiMob:FindFirstChild("cancelaim")
                if cancelAim and cancelAim:IsA("GuiButton") and not cancelAim:GetAttribute("AimHooked") then
                    cancelAim:SetAttribute("AimHooked", true)
                    cancelAim.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                            CombatState.IsAiming = false
                        end
                    end)
                end
            end

            local actionBtn = controls:FindFirstChild("action")
            if actionBtn and actionBtn:IsA("GuiButton") and not actionBtn:GetAttribute("AimHooked") then
                actionBtn:SetAttribute("AimHooked", true)
                actionBtn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        local myChar = Players.LocalPlayer.Character
                        if myChar and myChar:FindFirstChild("Twist of Fate") then
                            CombatState.IsAiming = true
                        end
                    end
                end)
                actionBtn.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
                        CombatState.IsAiming = false
                    end
                end)
            end
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        hookMobileAimButton()
    end
end)

local function setupUnequipDetection(char)
    if char then
        char.ChildRemoved:Connect(function(child)
            if child.Name == "Twist of Fate" then
                CombatState.IsAiming = false
            end
        end)
    end
end

setupUnequipDetection(Players.LocalPlayer.Character)
Players.LocalPlayer.CharacterAdded:Connect(setupUnequipDetection)

-- TARGET MODE UI
local function CreateTargetModeOverlay()
    TargetModeGui = Instance.new("ScreenGui")
    TargetModeGui.Name = "SilentAimTargetOverlay"
    TargetModeGui.ResetOnSpawn = false
    TargetModeGui.Enabled = false
    pcall(function() TargetModeGui.Parent = (gethui and gethui() or CoreGui) end)
    if not TargetModeGui.Parent then TargetModeGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

    local TargetFrame = Instance.new("Frame")
    TargetFrame.Size = UDim2.new(0, 160, 0, 130) 
    TargetFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    TargetFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    TargetFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    TargetFrame.BorderSizePixel = 0
    TargetFrame.Active = true
    TargetFrame.Parent = TargetModeGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = TargetFrame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -30, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Text = "TARGET MODE"
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 11
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = TargetFrame

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 20, 0, 20)
    minBtn.Position = UDim2.new(1, -25, 0, 5)
    minBtn.BackgroundTransparency = 1
    minBtn.Text = "-"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.Parent = TargetFrame

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 1, -35)
    btnContainer.Position = UDim2.new(0, 10, 0, 30)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = TargetFrame

    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0, 6)
    layout.Parent = btnContainer

    local function createTargetBtn(name, text, keybind)
        local btn = Instance.new("TextButton")
        btn.Name = name
        btn.Size = UDim2.new(1, 0, 0, 25)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        btn.Text = text .. " (" .. keybind .. ")"
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.Parent = btnContainer
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn
        TargetButtons[name] = btn
        return btn
    end

    createTargetBtn("Killer", "Killer", "K")
    createTargetBtn("Survivor", "Survivor", "J")
    createTargetBtn("Zombie", "Zombie", "L")

    local minimized = false
    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TargetFrame.Size = UDim2.new(0, 160, 0, 30)
            btnContainer.Visible = false
            minBtn.Text = "+"
        else
            TargetFrame.Size = UDim2.new(0, 160, 0, 130)
            btnContainer.Visible = true
            minBtn.Text = "-"
        end
    end)

    local dragging, dragInput, dragStart, startPos
    TargetFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = TargetFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    TargetFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TargetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function updateTargetUI(mode)
        CombatSettings.TargetMode = mode
        for btnName, btn in pairs(TargetButtons) do
            if btnName == mode then
                btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) 
            else
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
            end
        end
    end

    updateTargetUI(CombatSettings.TargetMode)

    for name, btn in pairs(TargetButtons) do
        btn.MouseButton1Click:Connect(function()
            updateTargetUI(name)
        end)
    end

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed or not CombatSettings.SilentAim then return end
        if input.KeyCode == Enum.KeyCode.K then
            updateTargetUI("Killer")
        elseif input.KeyCode == Enum.KeyCode.J then
            updateTargetUI("Survivor")
        elseif input.KeyCode == Enum.KeyCode.L then
            updateTargetUI("Zombie")
        end
    end)
end
task.spawn(CreateTargetModeOverlay)

-- LOGIC: BOOST GENERATOR
local FloatingGenUI = nil
local DragConfigPath = "L2Hub_GenBypassPos.json"
local HttpService = game:GetService("HttpService")

local function loadBypassButtonPosition()
    local pos = nil
    pcall(function()
        if isfile and readfile and isfile(DragConfigPath) then
            local raw = readfile(DragConfigPath)
            local data = HttpService:JSONDecode(raw)
            if data and data.XScale ~= nil and data.XOffset ~= nil and data.YScale ~= nil and data.YOffset ~= nil then
                pos = UDim2.new(data.XScale, data.XOffset, data.YScale, data.YOffset)
            end
        end
    end)
    return pos
end

local function saveBypassButtonPosition(udim2Pos)
    pcall(function()
        if writefile then
            writefile(DragConfigPath, HttpService:JSONEncode({
                XScale  = udim2Pos.X.Scale,
                XOffset = udim2Pos.X.Offset,
                YScale  = udim2Pos.Y.Scale,
                YOffset = udim2Pos.Y.Offset,
            }))
        end
    end)
end

local function ToggleBoostGenUI(state)
    BoostGenState.Enabled = state
    
    if FloatingGenUI then
        FloatingGenUI:Destroy()
        FloatingGenUI = nil
    end
    
    pcall(function()
        if CoreGui:FindFirstChild("BoostGenFloatingUI") then CoreGui.BoostGenFloatingUI:Destroy() end
        if Players.LocalPlayer:FindFirstChild("PlayerGui") and Players.LocalPlayer.PlayerGui:FindFirstChild("BoostGenFloatingUI") then
            Players.LocalPlayer.PlayerGui.BoostGenFloatingUI:Destroy()
        end
    end)

    if state then
        FloatingGenUI = Instance.new("ScreenGui")
        FloatingGenUI.Name = "BoostGenFloatingUI"
        FloatingGenUI.ResetOnSpawn = false
        FloatingGenUI.DisplayOrder = 9999 

        pcall(function() FloatingGenUI.Parent = (gethui and gethui() or CoreGui) end)
        if not FloatingGenUI.Parent then 
            FloatingGenUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") 
        end

        local GenBtn = Instance.new("ImageButton")
        GenBtn.Name = "GenButton"
        GenBtn.Size = UDim2.new(0, 75, 0, 75)
        GenBtn.AnchorPoint = Vector2.new(1, 0.5)
        
        local savedPos = loadBypassButtonPosition()
        GenBtn.Position = savedPos or UDim2.new(1, -20, 0.5, 0)
        
        GenBtn.BackgroundTransparency = 1
        GenBtn.Image = "rbxassetid://73955247819019" 
        GenBtn.ScaleType = Enum.ScaleType.Fit
        GenBtn.BorderSizePixel = 0
        GenBtn.AutoButtonColor = false
        GenBtn.Active = true
        GenBtn.ZIndex = 2
        GenBtn.Parent = FloatingGenUI

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.5, 0)
        corner.Parent = GenBtn

        local function updateButtonColor()
            if not GenBtn then return end
            local char = Players.LocalPlayer.Character
            if not char then
                GenBtn.ImageColor3 = Color3.new(1, 1, 1)
                return
            end
            local ci = char:FindFirstChild("CheckInterractable")
            if not ci then
                GenBtn.ImageColor3 = Color3.new(1, 1, 1)
                return
            end
            local repairing = ci:GetAttribute("isRepairing") or ci:GetAttribute("IsRepairing")
            GenBtn.ImageColor3 = repairing and Color3.fromRGB(255, 140, 0) or Color3.new(1, 1, 1)
        end

        local btnCheckConn
        local function bindCheck(character)
            if not character then return end
            local ci = character:WaitForChild("CheckInterractable", 5)
            if ci then
                if btnCheckConn then btnCheckConn:Disconnect() end
                btnCheckConn = ci:GetAttributeChangedSignal("isRepairing"):Connect(updateButtonColor)
                ci:GetAttributeChangedSignal("IsRepairing"):Connect(updateButtonColor)
                updateButtonColor()
            end
        end

        if Players.LocalPlayer.Character then bindCheck(Players.LocalPlayer.Character) end
        Players.LocalPlayer.CharacterAdded:Connect(bindCheck)

        local dragging, dragInput, dragStart, startPos
        GenBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = GenBtn.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        if dragging then
                            dragging = false
                            saveBypassButtonPosition(GenBtn.Position)
                        end
                    end
                end)
            end
        end)
        
        GenBtn.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                GenBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        GenBtn.MouseButton1Click:Connect(function()
            if BoostGenState.IsBoosting then return end
            
            local char = Players.LocalPlayer.Character
            if not char then return end
            local ci = char:FindFirstChild("CheckInterractable")
            if not ci then return end
            local repairing = ci:GetAttribute("isRepairing") or ci:GetAttribute("IsRepairing")
            
            if not repairing then
                Window:Notify({Title = "Boost Gen", Content = "Must be Generator first", Duration = 3})
                return
            end

            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            BoostGenState.IsBoosting = true

            local genCache = {}
            local folder = workspace:FindFirstChild("Map") or workspace
            for _, v in pairs(folder:GetDescendants()) do
                if v:IsA("Model") and v.Name == "Generator" then
                    local real = v:GetAttribute("RepairProgress") ~= nil
                        or v:GetAttribute("kickcount") ~= nil
                        or v:GetAttribute("ProgressRepair") ~= nil
                    if real then
                        table.insert(genCache, v)
                    end
                end
            end

            local function getPoints(genModel)
                local pts = {}
                for _, obj in pairs(genModel:GetChildren()) do
                    if obj.Name:find("GeneratorPoint") and obj:IsA("BasePart") then
                        table.insert(pts, obj)
                    end
                end
                return pts
            end

            local function waitRepairing(point, timeout)
                local start = tick()
                while tick() - start < timeout do
                    if point:GetAttribute("IsRepairing") == true then
                        return true
                    end
                    task.wait(0.05)
                end
                return false
            end

            local repStorage = game:GetService("ReplicatedStorage")
            local RepairEvent = nil
            pcall(function()
                local remotes = repStorage:FindFirstChild("Remotes")
                if remotes then
                    local genFolder = remotes:FindFirstChild("Generator")
                    if genFolder then
                        RepairEvent = genFolder:FindFirstChild("RepairEvent")
                    end
                end
            end)

            if not RepairEvent then
                Window:Notify({Title = "Error", Content = "RepairEvent not found!", Duration = 3})
                BoostGenState.IsBoosting = false
                return
            end

            local bestPoint, bestDist = nil, math.huge
            local bestGen = nil
            for _, gen in pairs(genCache) do
                for _, pt in pairs(getPoints(gen)) do
                    local d = (hrp.Position - pt.Position).Magnitude
                    if d < bestDist then
                        bestDist = d
                        bestPoint = pt
                        bestGen = gen
                    end
                end
            end

            if bestPoint and bestGen then
                local allPoints = getPoints(bestGen)
                local targetPoints = {}
                for _, p in ipairs(allPoints) do
                    if p ~= bestPoint then table.insert(targetPoints, p) end
                end
                
                if #targetPoints == 0 then
                    Window:Notify({Title = "Error", Content = "There are no gen here!", Duration = 3})
                    BoostGenState.IsBoosting = false
                    return
                end
                
                local startCFrame = hrp.CFrame
                Window:Notify({Title = "Bypass Gen", Content = "Loading " .. #targetPoints .. " ......", Duration = 2})

                task.spawn(function()
                    for i, point in ipairs(targetPoints) do
                        if not point.Parent then continue end
                        hrp.Anchored = true
                        hrp.CFrame = point.CFrame
                        task.wait(0.15)
                        
                        if RepairEvent then
                            RepairEvent:FireServer(point, true)
                        end
                        
                        local ok = waitRepairing(point, 0.8)
                        if not ok then
                            if RepairEvent then RepairEvent:FireServer(point, false) end
                            task.wait(0.1)
                            hrp.CFrame = point.CFrame
                            task.wait(0.15)
                            if RepairEvent then RepairEvent:FireServer(point, true) end
                            waitRepairing(point, 0.5)
                        end
                        hrp.Anchored = false
                        task.wait(0.05)
                    end
                    
                    pcall(function()
                        hrp.Anchored = false
                        hrp.CFrame = startCFrame
                    end)
                    
                    local lastPoint = targetPoints[#targetPoints]
                    if lastPoint and RepairEvent then
                        task.wait(0.1)
                        RepairEvent:FireServer(lastPoint, false)
                    end
                    
                    Window:Notify({Title = "Bypass Gen", Content = "Success!", Duration = 3})
                    BoostGenState.IsBoosting = false
                end)
            else
                Window:Notify({Title = "Error", Content = "There are no generators near you.!", Duration = 3})
                BoostGenState.IsBoosting = false
            end
        end)
    end
end

-- TAB MENUS
local SurvivorTab = Window:AddTab({ Name = "Survivor", Icon = "user", Type = "Single" })
local AimTab = Window:AddTab({ Name = "Aim", Icon = "crosshairs", Type = "Single" })
local VisualTab = Window:AddTab({ Name = "Visuals", Icon = "eye", Type = "Single" })

local SurvivorTabbox = SurvivorTab:AddCenterTabbox("Survivor Features")
local SubTabAutomation = SurvivorTabbox:AddTab({ Name = "Automation", Icon = "cpu" })
local SubTabUtility = SurvivorTabbox:AddTab({ Name = "Utility", Icon = "shield" })

SubTabAutomation:AddDivider({Text = "Generator & Healing"})
SubTabAutomation:AddDropdown({
    Name = "Auto Skill Check Mode",
    Default = "Disabled",
    Values = {"Disabled", "Normal", "Perfect", "Instant"},
    Callback = function(v)
        AutoSkillSettings.Mode = v
    end
})

SubTabAutomation:AddDivider({Text = "Generator Exploits"})
SubTabAutomation:AddToggle({
    Name = "Enable Boost Generator",
    Default = false,
    Callback = function(state) 
        ToggleBoostGenUI(state)
    end
})

SubTabUtility:AddDivider({Text = "Movement"})
SubTabUtility:AddToggle({
    Name = "Enable Auto Vault",
    Default = false,
    Callback = function(v)
        SurvivorSettings.AutoVault = v
    end
})
SubTabUtility:AddSlider({
    Name = "Vault Distance Trigger",
    Min = 4, Max = 15, Default = 6, Rounding = 1,
    Callback = function(v)
        SurvivorSettings.VaultDistance = v
    end
})

SubTabUtility:AddDivider({Text = "Health & Protection"})
SubTabUtility:AddToggle({
    Name = "God Mode",
    Default = false,
    Callback = function(v) 
        SurvivorSettings.GodMode = v 
        SurvivorSettings.AntiKnock = v
    end
})

local SubTabCombat = SurvivorTabbox:AddTab({ Name = "Combat", Icon = "crosshair" })
SubTabCombat:AddDivider({Text = "Auto Parry (Dagger)"})
SubTabCombat:AddToggle({
    Name = "Enable Auto Parry",
    Default = false,
    Callback = function(v) ParrySettings.Enabled = v end
})
SubTabCombat:AddToggle({
    Name = "Auto Parry Aggressive",
    Default = false,
    Callback = function(v) ParrySettings.Aggressive = v end
})
SubTabCombat:AddSlider({
    Name = "Parry Distance Trigger",
    Min = 4, Max = 25, Default = 8, Rounding = 1,
    Callback = function(v) ParrySettings.Distance = v end
})
SubTabCombat:AddToggle({
    Name = "Show Parry Range Circle",
    Default = false,
    Callback = function(v) ParrySettings.ShowCircle = v end
})

local AimTabbox = AimTab:AddCenterTabbox("Aim Features")
local SubTabSilentAim = AimTabbox:AddTab({ Name = "Silent Aim", Icon = "crosshairs" })

SubTabSilentAim:AddDivider({Text = "Silent Aim (Twist of Fate)"})
SubTabSilentAim:AddToggle({
    Name = "Enable Silent Aim",
    Default = false,
    Callback = function(v) 
        CombatSettings.SilentAim = v 
        if TargetModeGui then
            TargetModeGui.Enabled = v
        end
    end
})
SubTabSilentAim:AddDropdown({
    Name = "Target Part",
    Default = "Torso",
    Values = {"Head", "Torso", "Root"},
    Callback = function(v) CombatSettings.TargetPart = v end
})
SubTabSilentAim:AddToggle({
    Name = "Laser Pointer (Hold to Aim)",
    Default = false,
    Callback = function(v) CombatSettings.Laser = v end
})

local VisualTabbox = VisualTab:AddCenterTabbox("Visual Features")
local SubTabESP = VisualTabbox:AddTab({ Name = "ESP", Icon = "eye" })
local SubTabCamera = VisualTabbox:AddTab({ Name = "Camera", Icon = "camera-small" })
local SubTabLighting = VisualTabbox:AddTab({ Name = "Lighting", Icon = "sun" })

SubTabESP:AddDivider({Text = "Highlight Settings"})
SubTabESP:AddSlider({
    Name = "Fill Transparency",
    Min = 0, Max = 1, Default = 0.5, Rounding = 2,
    Callback = function(v) ESPSettings.FillTrans = v end
})
SubTabESP:AddSlider({
    Name = "Outline Transparency",
    Min = 0, Max = 1, Default = 0.3, Rounding = 2,
    Callback = function(v) ESPSettings.OutlineTrans = v end
})
SubTabESP:AddSlider({
    Name = "Text Size",
    Min = 8, Max = 24, Default = 12, Rounding = 0,
    Callback = function(v) ESPSettings.TextSize = v end
})

SubTabESP:AddDivider({Text = "Player ESP"})
SubTabESP:AddToggle({
    Name = "Enable Player ESP",
    Default = false,
    Callback = function(state) ESPSettings.Enabled = state end
})
SubTabESP:AddDropdown({
    Name = "Select Target",
    Multi = true,
    Values = {"Survivor ESP", "Killer ESP"},
    Default = {},
    Callback = function(v)
        ESPSettings.Targets.Survivor = v["Survivor ESP"] or false
        ESPSettings.Targets.Killer = v["Killer ESP"] or false
    end
})
SubTabESP:AddDropdown({
    Name = "ESP Style",
    Default = "Chams",
    Values = {"Chams", "Box", "Skeleton"},
    Callback = function(v)
        ESPSettings.Mode = v
        for _, p in ipairs(Players:GetPlayers()) do
            ClearESP(p)
        end
    end
})
SubTabESP:AddToggle({
    Name = "Player Nametags",
    Default = false,
    Callback = function(state) ESPSettings.ShowName = state end
})
SubTabESP:AddToggle({
    Name = "Player Distance",
    Default = false,
    Callback = function(state) ESPSettings.ShowDistance = state end
})
SubTabESP:AddColorPicker({
    Name = "Survivor Color",
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(v) ESPSettings.Colors.Survivor = v end
})
SubTabESP:AddColorPicker({
    Name = "Killer Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(v) ESPSettings.Colors.Killer = v end
})

SubTabESP:AddDivider({Text = "World Highlight ESP"})
SubTabESP:AddToggle({
    Name = "Enable World ESP",
    Default = false,
    Callback = function(state) ESPSettings.WorldEnabled = state end
})
SubTabESP:AddDropdown({
    Name = "Select World Objects",
    Multi = true,
    Values = {"Generators", "Hooks", "Gates", "Windows", "Pallets", "SCP / Zombie"},
    Default = {},
    Callback = function(v)
        ESPSettings.WorldTargets.Generators = v["Generators"] or false
        ESPSettings.WorldTargets.Hooks = v["Hooks"] or false
        ESPSettings.WorldTargets.Gates = v["Gates"] or false
        ESPSettings.WorldTargets.Windows = v["Windows"] or false
        ESPSettings.WorldTargets.Pallets = v["Pallets"] or false
        ESPSettings.WorldTargets.Zombies = v["SCP / Zombie"] or false
    end
})
SubTabESP:AddToggle({
    Name = "World Nametags",
    Default = false,
    Callback = function(state) ESPSettings.WorldShowName = state end
})
SubTabESP:AddToggle({
    Name = "World Distance ESP",
    Default = false,
    Callback = function(state) ESPSettings.WorldShowDistance = state end
})
SubTabESP:AddSlider({
    Name = "World Max Distance",
    Min = 50, Max = 1000, Default = 150, Rounding = 0,
    Callback = function(v) ESPSettings.WorldMaxDistance = v end
})
SubTabESP:AddColorPicker({
    Name = "Generator Color",
    Default = ESPSettings.WorldColors.Generators,
    Callback = function(v) ESPSettings.WorldColors.Generators = v end
})
SubTabESP:AddColorPicker({
    Name = "Hook Color",
    Default = ESPSettings.WorldColors.Hooks,
    Callback = function(v) ESPSettings.WorldColors.Hooks = v end
})
SubTabESP:AddColorPicker({
    Name = "Window Color",
    Default = ESPSettings.WorldColors.Windows,
    Callback = function(v) ESPSettings.WorldColors.Windows = v end
})
SubTabESP:AddColorPicker({
    Name = "Pallet Color",
    Default = ESPSettings.WorldColors.Pallets,
    Callback = function(v) ESPSettings.WorldColors.Pallets = v end
})

SubTabCamera:AddDivider({Text = "Camera Adjustments"})
SubTabCamera:AddToggle({
    Name = "Enable FOV Modifier",
    Default = false,
    Callback = function(state) print("FOV:", state) end
})
SubTabCamera:AddSlider({
    Name = "Field of View",
    Min = 70, Max = 120, Default = 70, Rounding = 0,
    Callback = function(v) print("FOV Set:", v) end
})

SubTabLighting:AddDivider({Text = "World Lighting"})
SubTabLighting:AddToggle({
    Name = "Fullbright",
    Default = false,
    Callback = function(state) 
        LightingSettings.Fullbright = state 
        if not state then ApplyFullbright(false) end
    end
})
SubTabLighting:AddSlider({
    Name = "Fullbright Brightness",
    Min = 100, Max = 255, Default = 180, Rounding = 0,
    Callback = function(v)
        LightingSettings.FullbrightValue = v
        if LightingSettings.Fullbright then ApplyFullbright(true) end 
    end
})
SubTabLighting:AddToggle({
    Name = "No Fog & Disable Effects",
    Default = false,
    Callback = function(state) 
        LightingSettings.NoFog = state 
        if not state then ApplyNoFog(false) end
    end
})
SubTabLighting:AddDivider({Text = "Performance Boost"})
SubTabLighting:AddButton({
    Name = "Reduce Texture (Minecraft Mode)",
    Callback = function()
        workspace.Terrain.WaterWaveSize = 0
        workspace.Terrain.WaterWaveSpeed = 0
        workspace.Terrain.WaterReflectance = 0
        workspace.Terrain.WaterTransparency = 0
        
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
            elseif v:IsA("Decal") or v:IsA("Texture") then
                v.Transparency = 1 
            end
        end
        Window:Notify({Title = "Performance Boost", Content = "Textures reduced successfully!", Duration = 3})
    end
})

-- UI: MISC TAB
local MiscTab = Window:AddTab({ Name = "Misc", Icon = "box", Type = "Single" })
local MiscTabbox = MiscTab:AddCenterTabbox("Miscellaneous")

local SubTabMovement = MiscTabbox:AddTab({ Name = "Movement", Icon = "move" })
SubTabMovement:AddDivider({Text = "Character Physics"})
SubTabMovement:AddToggle({
    Name = "Enable Noclip",
    Default = false,
    Callback = function(v) MiscSettings.Noclip = v end
})
SubTabMovement:AddToggle({
    Name = "Enable Speed Hack",
    Default = false,
    Callback = function(v) MiscSettings.SpeedHack = v end
})
SubTabMovement:AddSlider({
    Name = "Speed Value",
    Min = 16, Max = 100, Default = 25, Rounding = 0,
    Callback = function(v) MiscSettings.SpeedValue = v end
})

local SubTabInfo = MiscTabbox:AddTab({ Name = "Info Overlay", Icon = "monitor" })
SubTabInfo:AddDivider({Text = "Performance Stats"})
SubTabInfo:AddToggle({
    Name = "Show FPS & Ping",
    Default = false,
    Callback = function(v) 
        MiscSettings.ShowFPSPing = v 
        ToggleFPSPingUI(v)
    end
})

-- LOGIC: COMBAT
local PersistentLaser = workspace:FindFirstChild("SilentLaserPart") or Instance.new("Part")
PersistentLaser.Name = "SilentLaserPart"
PersistentLaser.Anchored = true
PersistentLaser.CanCollide = false
PersistentLaser.Material = Enum.Material.Neon
PersistentLaser.Color = Color3.fromRGB(255, 0, 0)
PersistentLaser.Transparency = 1
PersistentLaser.Parent = workspace

local function GetTargetPartPos(char)
    if not char then return nil end
    local part = CombatSettings.TargetPart
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if part == "Head" then
        local head = char:FindFirstChild("Head")
        if head and head:IsA("BasePart") then return head.Position end
    elseif part == "Torso" then
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if torso and torso:IsA("BasePart") then return torso.Position end
    end
    
    if root then return root.Position end
    return nil
end

local function GetMuzzlePos()
    local myChar = Players.LocalPlayer.Character
    if not myChar then return nil end
    local tool = myChar:FindFirstChild("Twist of Fate")
    if not tool then return nil end

    local success, gunPart = pcall(function()
        return tool:FindFirstChild("Right Arm") and tool["Right Arm"]:FindFirstChild("gun") and tool["Right Arm"].gun:FindFirstChild("gun")
    end)

    if success and gunPart and gunPart:IsA("BasePart") then
        return gunPart.Position
    end

    local rightArm = myChar:FindFirstChild("Right Arm") or myChar:FindFirstChild("RightHand")
    if rightArm then
        return rightArm.Position
    end
    return nil
end

local function UpdateCombat()
    local myChar = Players.LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local heldTool = myChar and myChar:FindFirstChild("Twist of Fate")

    if not CombatSettings.SilentAim or not myRoot then
        CombatState.TargetPos = nil
        CombatState.LookVector = nil
        PersistentLaser.Transparency = 1
        CombatState.IsAiming = false
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local bestDist3D = math.huge
    local bestTargetPlayer = nil

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Players.LocalPlayer and plr.Team then
            local teamName = string.lower(plr.Team.Name)
            local isValidTarget = false
            
            if CombatSettings.TargetMode == "Killer" and string.find(teamName, "killer") then
                isValidTarget = true
            elseif CombatSettings.TargetMode == "Survivor" and string.find(teamName, "survivor") then
                isValidTarget = true
            end
            
            if isValidTarget then
                local char = plr.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local pos = GetTargetPartPos(char)
                    
                    if hum and hum.Health > 0 and typeof(pos) == "Vector3" then
                        local dist3D = (pos - myRoot.Position).Magnitude
                        if dist3D < bestDist3D then
                            bestDist3D = dist3D
                            bestTargetPlayer = plr
                        end
                    end
                end
            end
        end
    end

    local bestTargetEntity = nil
    if CombatSettings.TargetMode == "Zombie" then
        for _, obj in ipairs(CachedZombies) do
            if obj and obj.Parent then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local root = obj:FindFirstChild("HumanoidRootPart") or obj.PrimaryPart
                
                if hum and hum.Health > 0 and root then
                    local dist3D = (root.Position - myRoot.Position).Magnitude
                    if dist3D < bestDist3D then
                        bestDist3D = dist3D
                        bestTargetEntity = obj
                    end
                end
            end
        end
    end

    local finalTargetChar = nil
    if bestTargetPlayer and bestTargetPlayer.Character then
        finalTargetChar = bestTargetPlayer.Character
    elseif bestTargetEntity then
        finalTargetChar = bestTargetEntity
    end

    if finalTargetChar then
         local bestPos = GetTargetPartPos(finalTargetChar)
         if not bestPos and bestTargetEntity then
             bestPos = bestTargetEntity:FindFirstChild("HumanoidRootPart") and bestTargetEntity.HumanoidRootPart.Position or bestTargetEntity:GetPivot().Position
         end
         if typeof(bestPos) == "Vector3" then
             local muzzlePos = GetMuzzlePos()
             if typeof(muzzlePos) ~= "Vector3" then
                 muzzlePos = cam.CFrame.Position
             end
             local dir = (bestPos - muzzlePos).Unit
             CombatState.TargetPos = bestPos
             CombatState.LookVector = dir
             CombatState.CurrentMuzzle = muzzlePos
         end
    else
        CombatState.TargetPos = nil
        CombatState.LookVector = nil
    end

    if CombatSettings.Laser and heldTool and CombatState.IsAiming and CombatState.TargetPos and CombatState.CurrentMuzzle then
        local mPos = CombatState.CurrentMuzzle
        local tPos = CombatState.TargetPos
        local dist = (mPos - tPos).Magnitude
        PersistentLaser.Size = Vector3.new(0.05, 0.05, dist)
        PersistentLaser.CFrame = CFrame.lookAt(mPos, tPos) * CFrame.new(0, 0, -dist / 2)
        PersistentLaser.Transparency = 0.4
    else
        PersistentLaser.Transparency = 1
    end
end

local repStorage = game:GetService("ReplicatedStorage")
local twistOfFateFireRemote = pcall(function() return repStorage:WaitForChild("Remotes", 2):WaitForChild("Items", 2):WaitForChild("Twist of Fate", 2):WaitForChild("Fire", 2) end)
local fallRemote = pcall(function() return repStorage:WaitForChild("Remotes", 2):WaitForChild("Mechanics", 2):WaitForChild("Fall", 2) end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() and method == "FireServer" and typeof(self) == "Instance" then
        if (SurvivorSettings.AntiKnock or SurvivorSettings.GodMode) and tostring(self.Name) == "Fall" then
            return 
        end
        local selfName = string.lower(self.Name)
        if CombatSettings.SilentAim and typeof(CombatState.LookVector) == "Vector3" and typeof(CombatState.TargetPos) == "Vector3" then
            if selfName == "fire" or selfName == "visualizebullet" or string.find(selfName, "twist of fate") then
                for i = 1, #args do
                    local arg = args[i]
                    if typeof(arg) == "Vector3" then
                        if arg.Magnitude > 10 then
                            args[i] = CombatState.TargetPos
                        else
                            args[i] = CombatState.LookVector
                        end
                    elseif typeof(arg) == "CFrame" then
                        local myRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            args[i] = CFrame.lookAt(myRoot.Position, CombatState.TargetPos)
                        end
                    end
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- LOGIC: ESP
local function GetPlayerRole(player)
    if player.Team and string.find(string.lower(player.Team.Name), "killer") then
        return "Killer"
    end
    return "Survivor"
end

local function ClearESP(player)
    if ESPInstances[player] then
        if ESPInstances[player].Highlight then ESPInstances[player].Highlight:Destroy() end
        if ESPInstances[player].Billboard then ESPInstances[player].Billboard:Destroy() end
        if ESPInstances[player].BoxOutline then ESPInstances[player].BoxOutline:Remove() end
        if ESPInstances[player].Box then ESPInstances[player].Box:Remove() end
        if ESPInstances[player].Skeleton then
            for _, line in pairs(ESPInstances[player].Skeleton) do
                line:Remove()
            end
        end
        ESPInstances[player] = nil
    end
end

local function CreateLine()
    local line = Drawing.new("Line")
    line.Thickness = 1.5
    line.Transparency = 1
    return line
end

local function UpdateESP()
    local cam = workspace.CurrentCamera
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            local role = GetPlayerRole(player)

            if ESPSettings.Enabled and ESPSettings.Targets[role] and root and hum and hum.Health > 0 then
                if not ESPInstances[player] then
                    ESPInstances[player] = { Skeleton = {} }

                    -- 1. CHAMS (Highlight)
                    local highlight = Instance.new("Highlight")
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = CoreGui
                    ESPInstances[player].Highlight = highlight

                    -- 2. NAMETAG (BillboardGui)
                    local billboard = Instance.new("BillboardGui")
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.new(0, 200, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.Parent = CoreGui

                    local textLabel = Instance.new("TextLabel")
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Font = Enum.Font.GothamBold
                    textLabel.TextStrokeTransparency = 0
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    textLabel.Parent = billboard
                    
                    ESPInstances[player].Billboard = billboard
                    ESPInstances[player].Text = textLabel

                    -- 3. BOX ESP (Drawing API)
                    local boxOutline = Drawing.new("Square")
                    boxOutline.Thickness = 3
                    boxOutline.Filled = false
                    boxOutline.Color = Color3.new(0, 0, 0)
                    ESPInstances[player].BoxOutline = boxOutline

                    local box = Drawing.new("Square")
                    box.Thickness = 1.5
                    box.Filled = false
                    ESPInstances[player].Box = box

                    -- 4. SKELETON ESP (Drawing API)
                    for i = 1, 15 do
                        ESPInstances[player].Skeleton[i] = CreateLine()
                    end
                end

                local inst = ESPInstances[player]
                local espColor = ESPSettings.Colors[role]
                
                -- UPDATE NAMETAGS & DISTANCE
                local bb = inst.Billboard
                local txt = inst.Text
                bb.Adornee = root
                
                if ESPSettings.ShowName or ESPSettings.ShowDistance then
                    bb.Enabled = true
                    txt.TextSize = ESPSettings.TextSize
                    txt.TextColor3 = espColor
                    
                    local localRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local dist = localRoot and math.floor((localRoot.Position - root.Position).Magnitude) or 0
                    local displayText = ""
                    
                    if ESPSettings.ShowName then displayText = player.Name end
                    if ESPSettings.ShowDistance then
                        displayText = (displayText ~= "" and (displayText .. "\n[" .. dist .. "m]") or ("[" .. dist .. "m]"))
                    end
                    txt.Text = displayText
                else
                    bb.Enabled = false
                end

                -- UPDATE CHAMS
                local hl = inst.Highlight
                if ESPSettings.Mode == "Chams" then
                    hl.Enabled = true
                    hl.Adornee = char
                    hl.FillColor = espColor
                    hl.OutlineColor = espColor
                    hl.FillTransparency = ESPSettings.FillTrans
                    hl.OutlineTransparency = ESPSettings.OutlineTrans
                else
                    hl.Enabled = false
                end

                -- UPDATE BOX & SKELETON
                local rootPos, onScreen = cam:WorldToViewportPoint(root.Position)
                
                -- Reset smua sblm di-update
                inst.Box.Visible = false
                inst.BoxOutline.Visible = false
                for _, line in pairs(inst.Skeleton) do line.Visible = false end

                if onScreen then
                    if ESPSettings.Mode == "Box" then
                        local head = char:FindFirstChild("Head")
                        if head then
                            local headPos = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                            local legPos = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                            
                            local height = math.abs(headPos.Y - legPos.Y)
                            local width = height / 2

                            -- Posisi & Ukuran Box
                            inst.BoxOutline.Size = Vector2.new(width, height)
                            inst.BoxOutline.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                            inst.BoxOutline.Visible = true

                            inst.Box.Size = Vector2.new(width, height)
                            inst.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
                            inst.Box.Color = espColor
                            inst.Box.Visible = true
                        end
                    elseif ESPSettings.Mode == "Skeleton" then
                        -- Fungsi tarik garis ke tulang/sendi
                        local function DrawBone(index, p1, p2)
                            local line = inst.Skeleton[index]
                            if char:FindFirstChild(p1) and char:FindFirstChild(p2) then
                                local pt1, on1 = cam:WorldToViewportPoint(char[p1].Position)
                                local pt2, on2 = cam:WorldToViewportPoint(char[p2].Position)
                                if on1 and on2 then
                                    line.From = Vector2.new(pt1.X, pt1.Y)
                                    line.To = Vector2.new(pt2.X, pt2.Y)
                                    line.Color = espColor
                                    line.Visible = true
                                end
                            end
                        end
                        
                        -- Cek Animasi R15
                        if char:FindFirstChild("UpperTorso") then
                            DrawBone(1, "Head", "UpperTorso")
                            DrawBone(2, "UpperTorso", "LowerTorso")
                            DrawBone(3, "UpperTorso", "RightUpperArm")
                            DrawBone(4, "RightUpperArm", "RightLowerArm")
                            DrawBone(5, "RightLowerArm", "RightHand")
                            DrawBone(6, "UpperTorso", "LeftUpperArm")
                            DrawBone(7, "LeftUpperArm", "LeftLowerArm")
                            DrawBone(8, "LeftLowerArm", "LeftHand")
                            DrawBone(9, "LowerTorso", "RightUpperLeg")
                            DrawBone(10, "RightUpperLeg", "RightLowerLeg")
                            DrawBone(11, "RightLowerLeg", "RightFoot")
                            DrawBone(12, "LowerTorso", "LeftUpperLeg")
                            DrawBone(13, "LeftUpperLeg", "LeftLowerLeg")
                            DrawBone(14, "LeftLowerLeg", "LeftFoot")
                        -- Kalau Animasi R6
                        elseif char:FindFirstChild("Torso") then
                            DrawBone(1, "Head", "Torso")
                            DrawBone(2, "Torso", "Right Arm")
                            DrawBone(3, "Torso", "Left Arm")
                            DrawBone(4, "Torso", "Right Leg")
                            DrawBone(5, "Torso", "Left Leg")
                        end
                    end
                end
            else
                ClearESP(player)
            end
        end
    end
end

-- OPTIMIZED MAP SCANNER
local mapConnections = {}

local function GetWorldTargetPart(obj, targetType)
    if targetType == "Generators" then
        return obj:FindFirstChild("HitBox", true) or obj:FindFirstChild("GeneratorPoint", true)
    elseif targetType == "Pallets" then
        local candidates = {
            obj:FindFirstChild("HumanoidRootPart", true),
            obj:FindFirstChild("PrimaryPartPallet", true),
            obj:FindFirstChild("Primary1", true),
            obj:FindFirstChild("Primary2", true),
            obj:FindFirstChild("PalletPoint", true),
            obj:FindFirstChild("PalletPointSlide", true)
        }
        for _, p in ipairs(candidates) do if p and p:IsA("BasePart") then return p end end
    elseif targetType == "Windows" then
        local v = obj:FindFirstChild("VaultPoint", true) or obj:FindFirstChild("VaultTrigger", true)
        if v and v:IsA("BasePart") then return v end
    elseif targetType == "Zombies" then
        return obj:FindFirstChild("HumanoidRootPart", true) or obj:FindFirstChild("UpperTorso", true) or obj:FindFirstChild("Torso", true)
    end
    return obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true) or obj
end

local function ProcessMapObject(obj)
    if obj.Name == "VaultTrigger" or obj.Name == "VaultPoint" then
        table.insert(CachedVaults, obj)
    end

    if obj:IsA("Model") then
        local nameLower = string.lower(obj.Name)
        local targetType, targetName = nil, nil
        
        if string.find(nameLower, "generator") then
            targetType, targetName = "Generators", "Generator"
        elseif string.find(nameLower, "hook") then
            targetType, targetName = "Hooks", "Hook"
        elseif (string.find(nameLower, "gate") or obj:FindFirstChild("ExitLever")) then
            targetType, targetName = "Gates", "Gate"
        elseif string.find(nameLower, "window") then
            targetType, targetName = "Windows", "Window"
        elseif string.find(nameLower, "pallet") then
            targetType, targetName = "Pallets", "Pallet"
        elseif (string.find(nameLower, "zombie") or string.find(nameLower, "scp")) then
            if obj:FindFirstChildOfClass("Humanoid") then
                table.insert(CachedZombies, obj)
            end
            targetType, targetName = "Zombies", obj.Name
        end
        
        if targetType then
            local targetPart = GetWorldTargetPart(obj, targetType)
            
            if targetType == "Windows" or targetType == "Pallets" then
                for _, v in pairs(obj:GetDescendants()) do
                    if v:IsA("BasePart") and v.Transparency >= 1 then
                        v.Transparency = 0.99
                    end
                end
            end

            ValidWorldObjects[obj] = {Type = targetType, Name = targetName, TargetPart = targetPart or obj}
        end
    end
end

local function RemoveMapObject(obj)
    if ValidWorldObjects[obj] then
        if WorldESPInstances[obj] then
            if WorldESPInstances[obj].Highlight then WorldESPInstances[obj].Highlight:Destroy() end
            if WorldESPInstances[obj].Billboard then WorldESPInstances[obj].Billboard:Destroy() end
            WorldESPInstances[obj] = nil
        end
        ValidWorldObjects[obj] = nil
    end
end

local function InitMapScanner()
    table.clear(ValidWorldObjects)
    table.clear(CachedVaults)
    table.clear(CachedZombies)
    
    for _, inst in pairs(WorldESPInstances) do
        if inst.Highlight then inst.Highlight:Destroy() end
        if inst.Billboard then inst.Billboard:Destroy() end
    end
    table.clear(WorldESPInstances)
    
    for _, conn in ipairs(mapConnections) do conn:Disconnect() end
    table.clear(mapConnections)

    local currentMap = workspace:FindFirstChild("Map")
    if not currentMap then return end

    for _, obj in ipairs(currentMap:GetDescendants()) do
        ProcessMapObject(obj)
    end

    table.insert(mapConnections, currentMap.DescendantAdded:Connect(ProcessMapObject))
    table.insert(mapConnections, currentMap.DescendantRemoving:Connect(RemoveMapObject))
end

workspace.ChildAdded:Connect(function(child)
    if child.Name == "Map" then
        task.wait(2)
        InitMapScanner()
    end
end)
task.spawn(InitMapScanner)

local function GetGeneratorInfo(model)
    local pct = tonumber(model:GetAttribute("RepairProgress") or model:GetAttribute("Progress")) or 0
    if pct >= 0 and pct <= 1.001 then pct = pct * 100 end
    pct = math.clamp(pct, 0, 100)

    local repairers = tonumber(model:GetAttribute("PlayersRepairingCount")) or 0
    local paused = model:GetAttribute("ProgressPaused") == true
    local kickcount = tonumber(model:GetAttribute("kickcount") or model:GetAttribute("KickCount")) or 0

    local parts = { "Gen " .. tostring(math.floor(pct + 0.5)) .. "%" }
    if repairers > 0 then table.insert(parts, "(" .. repairers .. "p)") end
    if paused then table.insert(parts, "Pause") end
    if kickcount > 0 then table.insert(parts, "K:" .. kickcount) end

    local hue = math.clamp((pct / 100) * 0.33, 0, 0.33)
    return table.concat(parts, " "), Color3.fromHSV(hue, 1, 1)
end

local function UpdateWorldESP()
    if not ESPSettings.WorldEnabled then
        for obj, inst in pairs(WorldESPInstances) do
            if inst.Highlight then inst.Highlight:Destroy() end
            if inst.Billboard then inst.Billboard:Destroy() end
        end
        table.clear(WorldESPInstances)
        return
    end

    local localRoot = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    for obj, data in pairs(ValidWorldObjects) do
        if obj and obj.Parent then
            if ESPSettings.WorldTargets[data.Type] then
                if not WorldESPInstances[obj] then
                    WorldESPInstances[obj] = {}
                    
                    local targetPart = data.TargetPart
                    
                    local highlight = Instance.new("Highlight")
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Adornee = obj 
                    highlight.Parent = CoreGui
                    WorldESPInstances[obj].Highlight = highlight

                    local billboard = Instance.new("BillboardGui")
                    billboard.AlwaysOnTop = true
                    billboard.Size = UDim2.new(0, 200, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 3, 0)
                    billboard.Adornee = targetPart 
                    billboard.Parent = CoreGui
                    
                    local textLabel = Instance.new("TextLabel")
                    textLabel.Size = UDim2.new(1, 0, 1, 0)
                    textLabel.BackgroundTransparency = 1
                    textLabel.Font = Enum.Font.GothamBold
                    textLabel.TextStrokeTransparency = 0
                    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    textLabel.TextYAlignment = Enum.TextYAlignment.Bottom
                    textLabel.Parent = billboard
                    
                    WorldESPInstances[obj].Billboard = billboard
                    WorldESPInstances[obj].Text = textLabel
                end

                local espColor = ESPSettings.WorldColors[data.Type]
                local displayText = data.Name

                if data.Type == "Generators" then
                    local genText, genColor = GetGeneratorInfo(obj)
                    displayText = genText
                    espColor = genColor
                end
                
                local hl = WorldESPInstances[obj].Highlight
                hl.FillColor = espColor
                hl.OutlineColor = espColor
                hl.FillTransparency = ESPSettings.FillTrans
                hl.OutlineTransparency = ESPSettings.OutlineTrans

                local bb = WorldESPInstances[obj].Billboard
                local txt = WorldESPInstances[obj].Text

                local dist = 0
                if localRoot and data.TargetPart then
                    local partPos = data.TargetPart:IsA("Model") and data.TargetPart:GetPivot().Position or data.TargetPart.Position
                    dist = math.floor((localRoot.Position - partPos).Magnitude)
                end

                -- OPTIMASI SLIDER DISTANCE: Bebasin Limit Highlight Roblox & atur manual 150m
                local withinDist = dist <= (ESPSettings.WorldMaxDistance or 150)
                local isAlwaysVisible = (data.Type == "Generators" or data.Type == "Gates")
                local isVisible = withinDist or isAlwaysVisible

                hl.Enabled = isVisible

                if (ESPSettings.WorldShowName or ESPSettings.WorldShowDistance) and isVisible then
                    bb.Enabled = true
                    txt.TextSize = ESPSettings.TextSize
                    txt.TextColor3 = espColor
                    
                    local finalString = ""
                    if ESPSettings.WorldShowName then finalString = displayText end
                    if ESPSettings.WorldShowDistance then
                        finalString = (finalString ~= "" and (finalString .. "\n[" .. dist .. "m]") or ("[" .. dist .. "m]"))
                    end
                    txt.Text = finalString
                else
                    bb.Enabled = false
                end
            else
                if WorldESPInstances[obj] then
                    if WorldESPInstances[obj].Highlight then WorldESPInstances[obj].Highlight:Destroy() end
                    if WorldESPInstances[obj].Billboard then WorldESPInstances[obj].Billboard:Destroy() end
                    WorldESPInstances[obj] = nil
                end
            end
        end
    end

    for obj, inst in pairs(WorldESPInstances) do
        if not ValidWorldObjects[obj] or not obj.Parent or not ESPSettings.WorldTargets[ValidWorldObjects[obj].Type] then
            if inst.Highlight then inst.Highlight:Destroy() end
            if inst.Billboard then inst.Billboard:Destroy() end
            WorldESPInstances[obj] = nil
        end
    end
end

-- LOGIC: LIGHTING 
local Lighting = game:GetService("Lighting")
local OriginalLighting = {}
local CachedVFX = {}
local CachedGUI = {}

local function ProcessEffect(v)
    if v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
        if CachedVFX[v] == nil then
            CachedVFX[v] = {Type = "Effect", Enabled = v.Enabled}
        end
        pcall(function() v.Enabled = false end)
        
    elseif v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("Sky") then
        if CachedVFX[v] == nil then
            CachedVFX[v] = {Type = "Atmosphere", Parent = v.Parent}
        end
        pcall(function() v.Parent = nil end)
    end
end

local function ProcessGUI(gui)
    local n = string.lower(gui.Name)
    if (gui:IsA("ScreenGui") or gui:IsA("ImageLabel")) and (
        string.find(n, "film") or 
        string.find(n, "grain") or 
        string.find(n, "noise") or 
        string.find(n, "blink") or 
        string.find(n, "effect") or 
        string.find(n, "misc") or 
        string.find(n, "vignette") or 
        n == "darkness"
    ) then
        pcall(function()
            if gui:IsA("ScreenGui") then
                if CachedGUI[gui] == nil then CachedGUI[gui] = gui.Enabled end
                gui.Enabled = false 
            else
                if CachedGUI[gui] == nil then CachedGUI[gui] = gui.Visible end
                gui.Visible = false
            end
        end)
    end
end

local function ApplyNoFog(state)
    if state then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 100000
        Lighting.GlobalShadows = false
        
        for _, v in ipairs(Lighting:GetChildren()) do ProcessEffect(v) end
        for _, v in ipairs(workspace.CurrentCamera:GetChildren()) do ProcessEffect(v) end
        
        local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if pGui then
            for _, gui in ipairs(pGui:GetDescendants()) do ProcessGUI(gui) end
        end
    else
        Lighting.FogEnd = 10000
        Lighting.GlobalShadows = true
        for obj, data in pairs(CachedVFX) do
            if obj then
                pcall(function()
                    if data.Type == "Atmosphere" then
                        obj.Parent = data.Parent
                    else
                        obj.Enabled = data.Enabled
                    end
                end)
            end
        end
        table.clear(CachedVFX)
        
        for guiObj, wasEnabled in pairs(CachedGUI) do
            if guiObj then
                pcall(function() 
                    if guiObj:IsA("ScreenGui") then
                        guiObj.Enabled = wasEnabled
                    else
                        guiObj.Visible = wasEnabled
                    end
                end)
            end
        end
        table.clear(CachedGUI)
    end
end

Lighting.DescendantAdded:Connect(function(child)
    if LightingSettings.NoFog then ProcessEffect(child) end
end)
workspace.CurrentCamera.DescendantAdded:Connect(function(child)
    if LightingSettings.NoFog then ProcessEffect(child) end
end)

task.spawn(function()
    local pGui = Players.LocalPlayer:WaitForChild("PlayerGui", 5)
    if pGui then
        pGui.DescendantAdded:Connect(function(child)
            if LightingSettings.NoFog then ProcessGUI(child) end
        end)
    end
end)

-- OPTIMASI: SKILL CHECK
local function getSkillCheckUI()
    local pGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    if not pGui then return nil, nil end

    local prompt = pGui:FindFirstChild("SkillCheckPromptGui") or pGui:FindFirstChild("SkillCheckPromptGui-con")
    if prompt then
        local check = prompt:FindFirstChild("Check")
        if check and check.Visible then
            return check:FindFirstChild("Line", true), check:FindFirstChild("Goal", true)
        end
    end
    return nil, nil
end

local function doSkillCheckClick()
    local pGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    local mobileBtn = nil
    
    if pGui then
        local survivorMob = pGui:FindFirstChild("Survivor-mob", true)
        if survivorMob then
            local controls = survivorMob:FindFirstChild("Controls", true)
            if controls then
                mobileBtn = controls:FindFirstChild("action") or controls:FindFirstChild("Gui-mob")
            end
        end
    end

    if mobileBtn and type(firesignal) == "function" then
        firesignal(mobileBtn.MouseButton1Down)
        task.delay(0.05, function()
            if mobileBtn and mobileBtn.Parent then
                firesignal(mobileBtn.MouseButton1Up)
                firesignal(mobileBtn.MouseButton1Click)
            end
        end)
    else
        vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
        task.wait(0.01)
        vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end
end

local function UpdateAutoSkillCheck()
    if AutoSkillSettings.Mode == "Disabled" then return end
    
    local line, goal = getSkillCheckUI()
    if not (line and goal) then
        instantLastVisible = false
        lastGoalRot = nil
        prevRot = nil
        return
    end

    local lineRot = line.Rotation
    local goalRot = goal.Rotation
    local now = tick()

    if now - lastPressTime < 0.1 then
        prevRot = lineRot
        return
    end

    if AutoSkillSettings.Mode == "Instant" then
        if not instantLastVisible or goalRot ~= lastGoalRot then
            line.Rotation = goalRot + 109
            lastGoalRot = goalRot
            instantLastVisible = true
            lastPressTime = now
            doSkillCheckClick()
        end
    else
        local relRot = (lineRot - goalRot) % 360
        local prevRelRot = -1
        if prevRot and lastGoalRot == goalRot then
            prevRelRot = (prevRot - goalRot) % 360
        end
        lastGoalRot = goalRot

        local minRot, maxRot
        if AutoSkillSettings.Mode == "Perfect" then
            minRot, maxRot = 102, 116
        elseif AutoSkillSettings.Mode == "Normal" then
            minRot, maxRot = 116, 159
        else
            return
        end

        local inside = relRot >= minRot and relRot <= maxRot
        local skipped = prevRelRot >= 0 and prevRelRot < minRot and relRot > maxRot

        if inside or skipped then
            if skipped then
                line.Rotation = goalRot + (minRot + maxRot) / 2
            end
            lastPressTime = now
            doSkillCheckClick()
        end
    end
    prevRot = lineRot
end

-- OPTIMASI: MOVEMENT AUTO VAULT & SLIDE PALLET
local CollectionService = game:GetService("CollectionService")
local lastMovementScan = 0
local vaultedObjects = {}

local function UpdateMovement()
    if not SurvivorSettings.AutoVault then return end
    
    if tick() - lastMovementScan < 0.15 then return end
    lastMovementScan = tick()

    local char = Players.LocalPlayer.Character
    local myRoot = char and char:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    
    local vel = myRoot.AssemblyLinearVelocity
    if Vector3.new(vel.X, 0, vel.Z).Magnitude < 1 then return end 

    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
    if not remotes then return end
    
    local winFolder = remotes:FindFirstChild("Window")
    local palletFolder = remotes:FindFirstChild("Pallet")
    
    local vaultEvent = winFolder and winFolder:FindFirstChild("VaultEvent")
    local vaultBindable = winFolder and winFolder:FindFirstChild("Vaultbindable")
    local fastvault = winFolder and winFolder:FindFirstChild("fastvault")
    local vaultComplete1 = winFolder and winFolder:FindFirstChild("VaultCompleteEventpart1")
    local vaultComplete = winFolder and winFolder:FindFirstChild("VaultCompleteEvent")

    local palletSlideEvent = palletFolder and palletFolder:FindFirstChild("PalletSlideEvent")
    local slidebindable = palletFolder and palletFolder:FindFirstChild("Slidebindable")

    local myPos = myRoot.Position
    local bestPart = nil
    local bestDist = SurvivorSettings.VaultDistance
    local objType = "" 
    local palletPoints = CollectionService:GetTagged("PalletPointSlide")
    for _, part in ipairs(palletPoints) do
        if part:IsA("BasePart") and not part:IsDescendantOf(char) then
            local dist = Vector3.new(myPos.X - part.Position.X, 0, myPos.Z - part.Position.Z).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestPart = part
                objType = "Pallet"
            end
        end
    end

    for _, obj in ipairs(CachedVaults) do
        if obj and obj.Parent and obj:IsA("BasePart") then
            local dist = Vector3.new(myPos.X - obj.Position.X, 0, myPos.Z - obj.Position.Z).Magnitude
            if dist < bestDist then
                bestDist = dist
                bestPart = obj
                objType = "Window"
            end
        end
    end

    if not bestPart then return end
    local rootModel = bestPart.Parent
    if bestPart.Name == "VaultPoint" and bestPart.Parent and bestPart.Parent.Name == "VaultTrigger" then
        rootModel = bestPart.Parent.Parent
    end

    local lastUsed = vaultedObjects[rootModel] or 0
    if tick() - lastUsed < 2.5 then return end

    if objType == "Window" then
        if vaultEvent then pcall(function() vaultEvent:FireServer(bestPart, true) end) end
        if vaultBindable then pcall(function() vaultBindable:Fire(bestPart, true) end) end
        if fastvault then pcall(function() fastvault:FireServer(Players.LocalPlayer) end) end
        if vaultComplete1 then pcall(function() vaultComplete1:FireServer() end) end
        if vaultComplete then pcall(function() vaultComplete:FireServer(bestPart, false) end) end
        vaultedObjects[rootModel] = tick()
        
    elseif objType == "Pallet" then
        local isSprinting = char:GetAttribute("Sprinting") or false
        if palletSlideEvent then pcall(function() palletSlideEvent:FireServer(bestPart, isSprinting) end) end
        if slidebindable then pcall(function() slidebindable:Fire(bestPart, isSprinting) end) end
        vaultedObjects[rootModel] = tick()
    end
end

-- LOGIC: UTILITY
local lastUtilScan = 0
local lastHum = nil
local lastGodMode = nil
local lastAntiKnock = nil

local function UpdateUtility()
    if tick() - lastUtilScan < 0.2 then return end
    lastUtilScan = tick()

    local myChar = Players.LocalPlayer.Character
    local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if hum ~= lastHum then
        lastHum = hum
        lastGodMode = nil
        lastAntiKnock = nil
    end

    if SurvivorSettings.GodMode ~= lastGodMode then
        lastGodMode = SurvivorSettings.GodMode
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Dead, not SurvivorSettings.GodMode)
        end)
    end

    -- Update state AntiKnock CUMA kalau toggle-nya berubah
    if SurvivorSettings.AntiKnock ~= lastAntiKnock then
        lastAntiKnock = SurvivorSettings.AntiKnock
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, not SurvivorSettings.AntiKnock)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not SurvivorSettings.AntiKnock)
        end)
    end

    -- Loop pertahanan atribut kalau GodMode ON
    if SurvivorSettings.GodMode then
        pcall(function()
            if hum.Health < hum.MaxHealth and hum.Health > 0 then
                hum.Health = hum.MaxHealth
            end
            
            local badStates = {"Injured", "Bleeding", "Hurt", "Broken", "Wounded"}
            for _, attr in ipairs(badStates) do
                if myChar:GetAttribute(attr) == true then myChar:SetAttribute(attr, false) end
                
                local val = myChar:FindFirstChild(attr)
                if val then
                    if val:IsA("BoolValue") and val.Value == true then 
                        val.Value = false 
                    elseif (val:IsA("NumberValue") or val:IsA("IntValue")) and val.Value ~= 0 then 
                        val.Value = 0 
                    end
                end
            end
        end)
    end

    -- Loop pertahanan atribut kalau AntiKnock ON
    if SurvivorSettings.AntiKnock then
        pcall(function()
            local knockStates = {"Knocked", "Downed", "Carried", "Grabbed", "Ragdolled", "IsKnocked", "IsCarried", "Disabled", "Stunned"}
            for _, attr in ipairs(knockStates) do
                if myChar:GetAttribute(attr) == true then myChar:SetAttribute(attr, false) end
                
                local val = myChar:FindFirstChild(attr)
                if val then
                    if val:IsA("BoolValue") and val.Value == true then 
                        val.Value = false 
                    elseif (val:IsA("NumberValue") or val:IsA("IntValue")) and val.Value ~= 0 then 
                        val.Value = 0 
                    end
                end
            end
            
            if hum.PlatformStand then hum.PlatformStand = false end
            if hum.Sit then hum.Sit = false end
            hum.AutoRotate = true
        end)
    end
end

-- LOGIC: PARRY
local function ExecuteParry()
    if tick() - ParryState.LastParry < 0.2 then return end
    ParryState.LastParry = tick()

    local pGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
    local mobBtn = pGui and pGui:FindFirstChild("Survivor-mob") and pGui["Survivor-mob"]:FindFirstChild("Controls") and pGui["Survivor-mob"].Controls:FindFirstChild("Gui-mob")
    
    if mobBtn and type(firesignal) == "function" then
        firesignal(mobBtn.MouseButton1Down)
        task.delay(0.05, function()
            if mobBtn and mobBtn.Parent then firesignal(mobBtn.MouseButton1Up) end
        end)
    else
        local rs = game:GetService("ReplicatedStorage")
        local parryRemote = rs:FindFirstChild("Remotes") and rs.Remotes:FindFirstChild("Items") and rs.Remotes.Items:FindFirstChild("Parrying Dagger") and rs.Remotes.Items["Parrying Dagger"]:FindFirstChild("parry")
        
        if parryRemote then
            pcall(function() parryRemote:FireServer() end)
        else
            vim:SendMouseButtonEvent(0, 0, 1, true, game, 0)
            task.wait(0.05)
            vim:SendMouseButtonEvent(0, 0, 1, false, game, 0)
        end
    end
end

local function CheckAndParry(killerChar)
    local myChar = Players.LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    local killerRoot = killerChar and killerChar:FindFirstChild("HumanoidRootPart")
    
    if not myRoot or not killerRoot then return end

    local dist = (myRoot.Position - killerRoot.Position).Magnitude
    
    if ParrySettings.Aggressive then
        local ping = math.clamp(Players.LocalPlayer:GetNetworkPing(), 0, 0.3)
        local killerVel = killerRoot.AssemblyLinearVelocity
        local flatVel = Vector3.new(killerVel.X, 0, killerVel.Z)
        
        local predictedPos = killerRoot.Position + (flatVel * ping)
        local predictedDist = (myRoot.Position - predictedPos).Magnitude
        
        if predictedDist <= (ParrySettings.Distance + 2) then
            local dirToMe = (myRoot.Position - killerRoot.Position).Unit
            if flatVel.Magnitude > 8 and flatVel.Unit:Dot(dirToMe) > 0.5 then
                ExecuteParry()
                return
            end
        end
    end

    if dist <= ParrySettings.Distance then
        ExecuteParry()
    end
end

local function HookKillerAnimation(killerPlayer)
    if killerPlayer == Players.LocalPlayer then return end
    
    local function onCharacterAdded(char)
        task.wait(1)
        local hum = char:WaitForChild("Humanoid", 3)
        if hum then
            local animator = hum:WaitForChild("Animator", 3)
            if animator then
                animator.AnimationPlayed:Connect(function(track)
                    if not ParrySettings.Enabled then return end
                    if track and track.Animation then
                        local animType = KillerAttackAnims[track.Animation.AnimationId]
                        if animType then
                            ParryState.ActiveAttackers[killerPlayer] = {char = char, track = track, type = animType}
                        end
                    end
                end)
            end
        end
    end

    if killerPlayer.Character then onCharacterAdded(killerPlayer.Character) end
    killerPlayer.CharacterAdded:Connect(onCharacterAdded)
end

for _, plr in ipairs(Players:GetPlayers()) do HookKillerAnimation(plr) end
Players.PlayerAdded:Connect(HookKillerAnimation)

local function UpdateParry()
    local myChar = Players.LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    if ParrySettings.ShowCircle and myRoot and ParrySettings.Enabled then
        if not ParryState.CirclePart then
            local p = Instance.new("Part")
            p.Name = "ParryCircle"
            p.Anchored = true
            p.CanCollide = false
            p.CastShadow = false
            p.Material = Enum.Material.ForceField
            p.Color = Color3.fromRGB(170, 0, 255)
            p.Transparency = 0.5
            p.Shape = Enum.PartType.Cylinder
            p.Parent = workspace
            ParryState.CirclePart = p
        end
        ParryState.CirclePart.Size = Vector3.new(0.05, ParrySettings.Distance * 2, ParrySettings.Distance * 2)
        ParryState.CirclePart.CFrame = myRoot.CFrame * CFrame.new(0, -myRoot.Size.Y/2, 0) * CFrame.Angles(0, 0, math.rad(90))
    else
        if ParryState.CirclePart then
            ParryState.CirclePart:Destroy()
            ParryState.CirclePart = nil
        end
    end

    if not ParrySettings.Enabled then return end
    
    for plr, data in pairs(ParryState.ActiveAttackers) do
        if not plr or not plr.Parent or not data.track or not data.track.IsPlaying then
            ParryState.ActiveAttackers[plr] = nil
        else
            if data.type == "attack" and data.track.TimePosition < 0.25 then
                CheckAndParry(data.char)
            elseif data.type == "lungehold" then
                CheckAndParry(data.char)
            end
        end
    end
end

-- LOGIC: MISC
local FPSPingGUI = nil
local StatsText = nil
local lastUpdate = tick()
local frameCount = 0

function ToggleFPSPingUI(state)
    if FPSPingGUI then FPSPingGUI:Destroy() FPSPingGUI = nil end
    if state then
        FPSPingGUI = Instance.new("ScreenGui")
        FPSPingGUI.Name = "L2Hub_FPSPing"
        FPSPingGUI.ResetOnSpawn = false
        pcall(function() FPSPingGUI.Parent = (gethui and gethui() or CoreGui) end)
        if not FPSPingGUI.Parent then FPSPingGUI.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end

        StatsText = Instance.new("TextLabel")
        StatsText.Size = UDim2.new(0, 200, 0, 30)
        StatsText.Position = UDim2.new(0, 10, 0, 10)
        StatsText.BackgroundTransparency = 1
        StatsText.Font = Enum.Font.GothamBold
        StatsText.TextSize = 14
        StatsText.TextColor3 = Color3.fromRGB(0, 255, 127)
        StatsText.TextStrokeTransparency = 0
        StatsText.TextXAlignment = Enum.TextXAlignment.Left
        StatsText.Parent = FPSPingGUI
    end
end
local function UpdateMisc()
    local char = Players.LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if MiscSettings.SpeedHack then
        hum.WalkSpeed = MiscSettings.SpeedValue
    end
end
RunService.Stepped:Connect(function()
    if MiscSettings.Noclip then
        local char = Players.LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- MAIN LOOP
RunService.RenderStepped:Connect(function()
    pcall(UpdateESP)
    pcall(UpdateWorldESP)
    pcall(UpdateAutoSkillCheck)
    
    if LightingSettings.Fullbright then
        local val = LightingSettings.FullbrightValue
        pcall(function()
            Lighting.Ambient = Color3.fromRGB(val, val, val)
            Lighting.OutdoorAmbient = Color3.fromRGB(val, val, val)
            Lighting.ColorShift_Bottom = Color3.fromRGB(val, val, val)
            Lighting.ColorShift_Top = Color3.fromRGB(val, val, val)
            Lighting.Brightness = 2
            Lighting.ClockTime = 12
            Lighting.ExposureCompensation = 0
            Lighting.GlobalShadows = false
        end)
    end
    
    if LightingSettings.NoFog then
        pcall(function()
            Lighting.FogEnd = 100000
            Lighting.FogStart = 100000
            
            local lp = Players.LocalPlayer
            if lp then
                if lp:GetAttribute("noshadows") ~= true then lp:SetAttribute("noshadows", true) end
                if lp:GetAttribute("filmgrain") ~= false then lp:SetAttribute("filmgrain", false) end
                if lp:GetAttribute("epilepsymode") ~= false then lp:SetAttribute("epilepsymode", false) end
            end
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
                    if v.Enabled then v.Enabled = false end
                elseif v:IsA("Atmosphere") or v:IsA("Clouds") or v:IsA("Sky") then
                    if v.Parent ~= nil then v.Parent = nil end
                end
            end
        end)
    end
    
    if MiscSettings.ShowFPSPing and StatsText then
        frameCount = frameCount + 1
        if tick() - lastUpdate >= 0.5 then
            local fps = math.floor(frameCount / (tick() - lastUpdate))
            local ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000)
            StatsText.Text = string.format("FPS: %d | Ping: %d ms", fps, ping)
            lastUpdate = tick()
            frameCount = 0
        end
    end
end)

RunService.Heartbeat:Connect(function()
    pcall(UpdateCombat)
    pcall(UpdateMovement)
    pcall(UpdateUtility)
    pcall(UpdateParry)
    pcall(UpdateMisc)
end)

Players.PlayerRemoving:Connect(ClearESP)

Window:Notify({
    Title = "L2-HUB",
    Content = "Best scripts roblox #PlayToDominate",
    Duration = 5
})