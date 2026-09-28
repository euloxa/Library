local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Camera            = workspace.CurrentCamera

local CONFIG = {
    Key            = "L2-HUB",
    DiscordInvite  = "https://discord.gg/lifeorlose",
    GetKeyURL      = "https://discord.gg/lifeorlose",
    WebsiteURL     = "https://lifeorlose.xyz",
    BannerURL      = "https://files.catbox.moe/6ajzfh.png",
    LogoAsset      = "rbxassetid://120932910004936",
    WindowTitle    = "L2 HUB",
    WindowSubtitle = "Freemium Roblox Scripts",
    BaseSize       = Vector2.new(400, 315),
    ExpandedSize   = Vector2.new(400, 420),
    Accent         = Color3.fromRGB(0, 255, 100),
    AccentDark     = Color3.fromRGB(0, 100, 40),
    DiscordBlurple = Color3.fromRGB(88, 101, 242),
    BG             = Color3.fromRGB(12, 12, 12),
    Surface        = Color3.fromRGB(20, 22, 27),
    SurfaceLight   = Color3.fromRGB(28, 30, 36),
    Outline        = Color3.fromRGB(45, 48, 58),
    Text           = Color3.fromRGB(255, 255, 255),
    Placeholder    = Color3.fromRGB(140, 140, 155),
}

local ICONS = {
    Close   = "73723454580812",
    Discord = "125095115408066",
    GetKey  = "123791018818522",
    Website = "113512058469465",
    Key     = "10709791182",
    Verify  = "10709791760",
    Play    = "10709791760",
    Game    = "113512058469465",
}

local function GetCoreGui()
    if gethui then
        local ok, res = pcall(gethui)
        if ok and res then return res end
    end
    if get_hidden_gui then
        local ok, res = pcall(get_hidden_gui)
        if ok and res then return res end
    end
    return game:GetService("CoreGui")
end

local function ProtectGui(gui)
    if syn and syn.protect_gui then pcall(syn.protect_gui, gui) end
end

local function LoadRemoteAsset(url, fileName)
    if not (getcustomasset and isfolder and writefile and isfile) then return nil end
    local dir = "L2Hub_LoaderAssets"
    if not isfolder(dir) then makefolder(dir) end
    local path = dir .. "/" .. fileName
    if not isfile(path) then
        local ok, bytes = pcall(game.HttpGet, game, url)
        if not ok or type(bytes) ~= "string" or #bytes < 128 then return nil end
        if bytes:sub(1, 15):lower():find("<!doctype") or bytes:sub(1, 6):lower():find("<html") then
            return nil
        end
        pcall(writefile, path, bytes)
    end
    if not isfile(path) then return nil end
    local ok, asset = pcall(getcustomasset, path)
    if ok and type(asset) == "string" then return asset end
    return nil
end

local function Corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = (typeof(radius) == "UDim") and radius or UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or CONFIG.Outline
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.35
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function Tween(obj, props, time, style, dir)
    local info = TweenInfo.new(time or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function Gradient(parent, colorA, colorB, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(colorA, colorB)
    g.Rotation = rotation or 90
    g.Parent = parent
    return g
end

local function CopyURL(url)
    if not url:match("^https?://") then url = "https://" .. url end
    local copied = false
    if setclipboard then copied = pcall(setclipboard, url)
    elseif toclipboard then copied = pcall(toclipboard, url)
    elseif set_clipboard then copied = pcall(set_clipboard, url) end
    return copied, url
end

local function FireVerified(result)
    local bindable = getgenv().L2HUB_VERIFIED
    if bindable and typeof(bindable) == "Instance" and bindable:IsA("BindableEvent") then
        pcall(function() bindable:Fire(result) end)
    end
end

local GAMES = getgenv().L2HUB_GAMES or {}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "L2HubLoader"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ProtectGui(ScreenGui)
ScreenGui.Parent = GetCoreGui()

local UIScaleHolder = Instance.new("Frame")
UIScaleHolder.Name = "ScaleHolder"
UIScaleHolder.AnchorPoint = Vector2.new(0.5, 0.5)
UIScaleHolder.Position = UDim2.fromScale(0.5, 0.5)
UIScaleHolder.Size = UDim2.fromOffset(CONFIG.BaseSize.X, CONFIG.BaseSize.Y)
UIScaleHolder.BackgroundTransparency = 1
UIScaleHolder.Parent = ScreenGui

local UIScale = Instance.new("UIScale")
UIScale.Parent = UIScaleHolder
UIScale.Scale = 1

local function ApplyResponsiveScale()
    local vp = Camera.ViewportSize
    local maxW = vp.X * 0.88
    local maxH = vp.Y * 0.88
    local refH = math.max(CONFIG.BaseSize.Y, CONFIG.ExpandedSize.Y)
    local s = math.min(maxW / CONFIG.BaseSize.X, maxH / refH, 1)
    s = math.clamp(s, 0.5, 1)
    UIScale.Scale = s
end

ApplyResponsiveScale()
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyResponsiveScale)

local Root = Instance.new("Frame")
Root.Name = "Root"
Root.Size = UDim2.fromScale(1, 1)
Root.BackgroundColor3 = CONFIG.BG
Root.BackgroundTransparency = 0.05
Root.BorderSizePixel = 0
Root.ClipsDescendants = true
Root.Active = true
Root.Parent = UIScaleHolder
Corner(Root, 14)
Stroke(Root, CONFIG.Outline, 1, 0.4)

local BannerHolder = Instance.new("Frame")
BannerHolder.Name = "BannerHolder"
BannerHolder.Size = UDim2.new(1, 0, 0, 110)
BannerHolder.BackgroundColor3 = CONFIG.Surface
BannerHolder.BorderSizePixel = 0
BannerHolder.ClipsDescendants = true
BannerHolder.Parent = Root

local BannerFallback = Instance.new("Frame")
BannerFallback.Size = UDim2.fromScale(1, 1)
BannerFallback.BackgroundColor3 = CONFIG.AccentDark
BannerFallback.BorderSizePixel = 0
BannerFallback.Parent = BannerHolder
Gradient(BannerFallback, Color3.fromRGB(0, 200, 80), Color3.fromRGB(0, 40, 20), 45)

local BannerImage = Instance.new("ImageLabel")
BannerImage.Name = "Banner"
BannerImage.Size = UDim2.fromScale(1, 1)
BannerImage.BackgroundTransparency = 1
BannerImage.ScaleType = Enum.ScaleType.Crop
BannerImage.Image = ""
BannerImage.ImageTransparency = 1
BannerImage.Parent = BannerHolder

task.spawn(function()
    local asset = LoadRemoteAsset(CONFIG.BannerURL, "banner.png")
    if asset then
        BannerImage.Image = asset
        Tween(BannerImage, { ImageTransparency = 0 }, 0.4)
    end
end)

local BannerOverlay = Instance.new("Frame")
BannerOverlay.Size = UDim2.fromScale(1, 1)
BannerOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BannerOverlay.BackgroundTransparency = 0.55
BannerOverlay.BorderSizePixel = 0
BannerOverlay.Parent = BannerHolder
Gradient(BannerOverlay, Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0), 90)

local CloseBtn = Instance.new("ImageButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.AnchorPoint = Vector2.new(1, 0)
CloseBtn.Position = UDim2.new(1, -10, 0, 10)
CloseBtn.Size = UDim2.fromOffset(28, 28)
CloseBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
CloseBtn.BackgroundTransparency = 0.45
CloseBtn.BorderSizePixel = 0
CloseBtn.Image = "rbxassetid://" .. ICONS.Close
CloseBtn.ImageColor3 = CONFIG.Text
CloseBtn.ImageTransparency = 0.1
CloseBtn.ScaleType = Enum.ScaleType.Fit
CloseBtn.AutoButtonColor = false
CloseBtn.ZIndex = 20
CloseBtn.Parent = BannerHolder
Corner(CloseBtn, UDim.new(1, 0))
Stroke(CloseBtn, CONFIG.Outline, 1, 0.5)

local closeIconScale = Instance.new("UIScale")
closeIconScale.Scale = 0.55
closeIconScale.Parent = CloseBtn

CloseBtn.MouseEnter:Connect(function()
    Tween(CloseBtn, { BackgroundTransparency = 0.1, BackgroundColor3 = Color3.fromRGB(255, 80, 80) }, 0.15)
    Tween(CloseBtn, { ImageTransparency = 0 }, 0.15)
end)
CloseBtn.MouseLeave:Connect(function()
    Tween(CloseBtn, { BackgroundTransparency = 0.45, BackgroundColor3 = Color3.fromRGB(0, 0, 0) }, 0.15)
    Tween(CloseBtn, { ImageTransparency = 0.1 }, 0.15)
end)
CloseBtn.MouseButton1Click:Connect(function()
    FireVerified(false)
    Tween(Root, { BackgroundTransparency = 1 }, 0.2)
    task.wait(0.25)
    ScreenGui:Destroy()
end)

local ProfileRow = Instance.new("Frame")
ProfileRow.Name = "ProfileRow"
ProfileRow.Size = UDim2.new(1, -28, 0, 68)
ProfileRow.Position = UDim2.fromOffset(14, 110 - 38)
ProfileRow.BackgroundTransparency = 1
ProfileRow.ZIndex = 2
ProfileRow.Parent = Root

local AvatarHolder = Instance.new("Frame")
AvatarHolder.Size = UDim2.fromOffset(76, 76)
AvatarHolder.BackgroundColor3 = CONFIG.BG
AvatarHolder.BorderSizePixel = 0
AvatarHolder.ZIndex = 3
AvatarHolder.Parent = ProfileRow
Corner(AvatarHolder, UDim.new(1, 0))
Stroke(AvatarHolder, CONFIG.Accent, 2, 0)

local AvatarImage = Instance.new("ImageLabel")
AvatarImage.AnchorPoint = Vector2.new(0.5, 0.5)
AvatarImage.Position = UDim2.fromScale(0.5, 0.5)
AvatarImage.Size = UDim2.fromScale(0.88, 0.88)
AvatarImage.BackgroundTransparency = 1
AvatarImage.Image = CONFIG.LogoAsset
AvatarImage.ScaleType = Enum.ScaleType.Fit
AvatarImage.ZIndex = 4
AvatarImage.Parent = AvatarHolder
Corner(AvatarImage, UDim.new(1, 0))

local StatusDot = Instance.new("Frame")
StatusDot.AnchorPoint = Vector2.new(1, 1)
StatusDot.Position = UDim2.new(1, -4, 1, -4)
StatusDot.Size = UDim2.fromOffset(14, 14)
StatusDot.BackgroundColor3 = CONFIG.Accent
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 5
StatusDot.Parent = AvatarHolder
Corner(StatusDot, UDim.new(1, 0))
Stroke(StatusDot, CONFIG.BG, 3, 0)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Position = UDim2.fromOffset(90, 10)
TitleLabel.Size = UDim2.new(1, -90, 0, 26)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = CONFIG.WindowTitle
TitleLabel.TextColor3 = CONFIG.Text
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.ZIndex = 3
TitleLabel.Parent = ProfileRow

local SubLabel = Instance.new("TextLabel")
SubLabel.Position = UDim2.fromOffset(90, 38)
SubLabel.Size = UDim2.new(1, -90, 0, 18)
SubLabel.BackgroundTransparency = 1
SubLabel.Font = Enum.Font.GothamMedium
SubLabel.Text = CONFIG.WindowSubtitle
SubLabel.TextColor3 = CONFIG.Placeholder
SubLabel.TextSize = 13
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.ZIndex = 3
SubLabel.Parent = ProfileRow

local ContentArea = Instance.new("Frame")
ContentArea.Position = UDim2.fromOffset(14, 110 + 48)
ContentArea.Size = UDim2.new(1, -28, 1, -(110 + 48) - 14)
ContentArea.BackgroundTransparency = 1
ContentArea.ClipsDescendants = true
ContentArea.Parent = Root

local KeyPage = Instance.new("Frame")
KeyPage.Name = "KeyPage"
KeyPage.Size = UDim2.fromScale(1, 1)
KeyPage.BackgroundTransparency = 1
KeyPage.Parent = ContentArea

local GamePage = Instance.new("Frame")
GamePage.Name = "GamePage"
GamePage.Size = UDim2.fromScale(1, 1)
GamePage.BackgroundTransparency = 1
GamePage.Visible = false
GamePage.Parent = ContentArea

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(1, 0, 0, 1)
Divider.BackgroundColor3 = CONFIG.Outline
Divider.BackgroundTransparency = 0.35
Divider.BorderSizePixel = 0
Divider.Parent = KeyPage

local SectionLabel = Instance.new("TextLabel")
SectionLabel.Position = UDim2.fromOffset(0, 12)
SectionLabel.Size = UDim2.new(1, 0, 0, 16)
SectionLabel.BackgroundTransparency = 1
SectionLabel.Font = Enum.Font.GothamBold
SectionLabel.Text = "AUTHENTICATION"
SectionLabel.TextColor3 = CONFIG.Placeholder
SectionLabel.TextSize = 11
SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
SectionLabel.Parent = KeyPage

local InputHolder = Instance.new("Frame")
InputHolder.Position = UDim2.fromOffset(0, 36)
InputHolder.Size = UDim2.new(1, 0, 0, 38)
InputHolder.BackgroundColor3 = CONFIG.Surface
InputHolder.BackgroundTransparency = 0.15
InputHolder.BorderSizePixel = 0
InputHolder.Parent = KeyPage
Corner(InputHolder, 8)
local InputStroke = Stroke(InputHolder, CONFIG.Outline, 1, 0.35)

local InputIcon = Instance.new("ImageLabel")
InputIcon.AnchorPoint = Vector2.new(0, 0.5)
InputIcon.Position = UDim2.new(0, 12, 0.5, 0)
InputIcon.Size = UDim2.fromOffset(18, 18)
InputIcon.BackgroundTransparency = 1
InputIcon.Image = "rbxassetid://" .. ICONS.Key
InputIcon.ImageColor3 = CONFIG.Accent
InputIcon.ScaleType = Enum.ScaleType.Fit
InputIcon.Parent = InputHolder

local KeyInput = Instance.new("TextBox")
KeyInput.AnchorPoint = Vector2.new(0, 0.5)
KeyInput.Position = UDim2.new(0, 40, 0.5, 0)
KeyInput.Size = UDim2.new(1, -52, 1, 0)
KeyInput.BackgroundTransparency = 1
KeyInput.Font = Enum.Font.GothamMedium
KeyInput.PlaceholderText = "Paste your key here..."
KeyInput.PlaceholderColor3 = CONFIG.Placeholder
KeyInput.Text = ""
KeyInput.TextColor3 = CONFIG.Text
KeyInput.TextSize = 13
KeyInput.TextXAlignment = Enum.TextXAlignment.Left
KeyInput.ClearTextOnFocus = false
KeyInput.Parent = InputHolder

InputHolder.MouseEnter:Connect(function()
    Tween(InputStroke, { Transparency = 0.1 }, 0.15)
end)
InputHolder.MouseLeave:Connect(function()
    Tween(InputStroke, { Transparency = 0.35 }, 0.15)
end)

local BtnRow = Instance.new("Frame")
BtnRow.Position = UDim2.fromOffset(0, 86)
BtnRow.Size = UDim2.new(1, 0, 0, 42)
BtnRow.BackgroundTransparency = 1
BtnRow.Parent = KeyPage

local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Size = UDim2.new(0.62, -3, 0, 42)
VerifyBtn.Position = UDim2.fromOffset(0, 0)
VerifyBtn.BackgroundColor3 = CONFIG.Accent
VerifyBtn.BackgroundTransparency = 0
VerifyBtn.BorderSizePixel = 0
VerifyBtn.Text = ""
VerifyBtn.AutoButtonColor = false
VerifyBtn.Parent = BtnRow
Corner(VerifyBtn, 8)

local VerifyIcon = Instance.new("ImageLabel")
VerifyIcon.AnchorPoint = Vector2.new(0, 0.5)
VerifyIcon.Position = UDim2.new(0, 12, 0.5, 0)
VerifyIcon.Size = UDim2.fromOffset(16, 16)
VerifyIcon.BackgroundTransparency = 1
VerifyIcon.Image = "rbxassetid://" .. ICONS.Verify
VerifyIcon.ImageColor3 = Color3.fromRGB(0, 0, 0)
VerifyIcon.ScaleType = Enum.ScaleType.Fit
VerifyIcon.Parent = VerifyBtn

local VerifyLabel = Instance.new("TextLabel")
VerifyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
VerifyLabel.Position = UDim2.new(0.5, 8, 0.5, 0)
VerifyLabel.Size = UDim2.new(1, -40, 1, 0)
VerifyLabel.BackgroundTransparency = 1
VerifyLabel.Font = Enum.Font.GothamBold
VerifyLabel.Text = "Verify Key"
VerifyLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
VerifyLabel.TextSize = 13
VerifyLabel.Parent = VerifyBtn

VerifyBtn.MouseEnter:Connect(function()
    Tween(VerifyBtn, { BackgroundTransparency = 0.15 }, 0.12)
end)
VerifyBtn.MouseLeave:Connect(function()
    Tween(VerifyBtn, { BackgroundTransparency = 0 }, 0.12)
end)

local function CreateIconButton(iconId, tint, offsetX)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(40, 40)
    btn.AnchorPoint = Vector2.new(1, 0.5)
    btn.Position = UDim2.new(1, offsetX, 0.5, 0)
    btn.BackgroundColor3 = CONFIG.SurfaceLight
    btn.BackgroundTransparency = 0.15
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = false
    btn.Parent = BtnRow
    Corner(btn, 8)
    local st = Stroke(btn, CONFIG.Outline, 1, 0.35)

    local icon = Instance.new("ImageLabel")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.Size = UDim2.fromScale(0.58, 0.58)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxassetid://" .. iconId
    icon.ImageColor3 = tint
    icon.ScaleType = Enum.ScaleType.Fit
    icon.Parent = btn

    btn.MouseEnter:Connect(function()
        Tween(btn, { BackgroundTransparency = 0.35 }, 0.12)
        Tween(st, { Transparency = 0.1, Color = tint }, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, { BackgroundTransparency = 0.15 }, 0.12)
        Tween(st, { Transparency = 0.35, Color = CONFIG.Outline }, 0.12)
    end)

    return btn
end

local IconDiscord = CreateIconButton(ICONS.Discord, CONFIG.DiscordBlurple, 0)
local IconWebsite = CreateIconButton(ICONS.Website, Color3.fromRGB(220, 220, 230), -44)
local IconGetKey  = CreateIconButton(ICONS.GetKey,  CONFIG.Accent,         -88)

local GameDivider = Instance.new("Frame")
GameDivider.Size = UDim2.new(1, 0, 0, 1)
GameDivider.BackgroundColor3 = CONFIG.Outline
GameDivider.BackgroundTransparency = 0.35
GameDivider.BorderSizePixel = 0
GameDivider.Parent = GamePage

local GameSectionLabel = Instance.new("TextLabel")
GameSectionLabel.Position = UDim2.fromOffset(0, 12)
GameSectionLabel.Size = UDim2.new(1, 0, 0, 16)
GameSectionLabel.BackgroundTransparency = 1
GameSectionLabel.Font = Enum.Font.GothamBold
GameSectionLabel.Text = "CHOOSE GAME"
GameSectionLabel.TextColor3 = CONFIG.Placeholder
GameSectionLabel.TextSize = 11
GameSectionLabel.TextXAlignment = Enum.TextXAlignment.Left
GameSectionLabel.Parent = GamePage

local GameScroll = Instance.new("ScrollingFrame")
GameScroll.Position = UDim2.fromOffset(0, 36)
GameScroll.Size = UDim2.new(1, 0, 1, -36)
GameScroll.BackgroundTransparency = 1
GameScroll.BorderSizePixel = 0
GameScroll.ScrollBarThickness = 3
GameScroll.ScrollBarImageColor3 = CONFIG.Accent
GameScroll.ScrollBarImageTransparency = 0.5
GameScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
GameScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
GameScroll.Parent = GamePage

local GameLayout = Instance.new("UIListLayout")
GameLayout.Padding = UDim.new(0, 8)
GameLayout.SortOrder = Enum.SortOrder.LayoutOrder
GameLayout.Parent = GameScroll

local function CreateGameCard(game, index)
    local card = Instance.new("TextButton")
    card.Size = UDim2.new(1, -6, 0, 62)
    card.BackgroundColor3 = CONFIG.Surface
    card.BackgroundTransparency = 0.15
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.LayoutOrder = index
    card.Parent = GameScroll
    Corner(card, 10)
    local st = Stroke(card, CONFIG.Outline, 1, 0.35)

    local iconHolder = Instance.new("Frame")
    iconHolder.Size = UDim2.fromOffset(50, 50)
    iconHolder.Position = UDim2.fromOffset(6, 6)
    iconHolder.BackgroundColor3 = CONFIG.SurfaceLight
    iconHolder.BorderSizePixel = 0
    iconHolder.Parent = card
    Corner(iconHolder, 8)

    local icon = Instance.new("ImageLabel")
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.Size = UDim2.fromScale(0.94, 0.94)
    icon.BackgroundTransparency = 1
    icon.Image = "rbxthumb://type=GameIcon&id=" .. tostring(game.PlaceId) .. "&w=150&h=150"
    icon.ScaleType = Enum.ScaleType.Crop
    icon.Parent = iconHolder
    Corner(icon, 7)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Position = UDim2.fromOffset(66, 12)
    nameLabel.Size = UDim2.new(1, -130, 0, 20)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Text = game.Name or "Unknown"
    nameLabel.TextColor3 = CONFIG.Text
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.Parent = card

    local subLabel = Instance.new("TextLabel")
    subLabel.Position = UDim2.fromOffset(66, 33)
    subLabel.Size = UDim2.new(1, -130, 0, 16)
    subLabel.BackgroundTransparency = 1
    subLabel.Font = Enum.Font.GothamMedium
    subLabel.Text = game.Subtitle or "Ready to launch"
    subLabel.TextColor3 = CONFIG.Placeholder
    subLabel.TextSize = 11
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.TextTruncate = Enum.TextTruncate.AtEnd
    subLabel.Parent = card

    local playIcon = Instance.new("ImageLabel")
    playIcon.AnchorPoint = Vector2.new(1, 0.5)
    playIcon.Position = UDim2.new(1, -14, 0.5, 0)
    playIcon.Size = UDim2.fromOffset(22, 22)
    playIcon.BackgroundTransparency = 1
    playIcon.Image = "rbxassetid://" .. ICONS.Play
    playIcon.ImageColor3 = CONFIG.Accent
    playIcon.ImageTransparency = 0.2
    playIcon.ScaleType = Enum.ScaleType.Fit
    playIcon.Parent = card

    card.MouseEnter:Connect(function()
        Tween(card, { BackgroundTransparency = 0.35 }, 0.15)
        Tween(st, { Transparency = 0.1, Color = CONFIG.Accent }, 0.15)
    end)
    card.MouseLeave:Connect(function()
        Tween(card, { BackgroundTransparency = 0.15 }, 0.15)
        Tween(st, { Transparency = 0.35, Color = CONFIG.Outline }, 0.15)
    end)

    return card, game
end

local function BuildGameList()
    for _, child in ipairs(GameScroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    if #GAMES == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Font = Enum.Font.GothamMedium
        empty.Text = "No games available."
        empty.TextColor3 = CONFIG.Placeholder
        empty.TextSize = 13
        empty.LayoutOrder = 1
        empty.Parent = GameScroll
        return
    end

    for i, game in ipairs(GAMES) do
        local card = CreateGameCard(game, i)
        card.MouseButton1Click:Connect(function()
            FireVerified(game)
            Tween(Root, { BackgroundTransparency = 1 }, 0.25)
            task.wait(0.3)
            ScreenGui:Destroy()
        end)
    end
end

BuildGameList()

local function ShowGamePage()
    KeyPage.Visible = false
    GamePage.Visible = true
    GamePage.BackgroundTransparency = 1
    Tween(UIScaleHolder, {
        Size = UDim2.fromOffset(CONFIG.ExpandedSize.X, CONFIG.ExpandedSize.Y)
    }, 0.4, Enum.EasingStyle.Quint)
end

local ToastHolder = Instance.new("Frame")
ToastHolder.AnchorPoint = Vector2.new(0.5, 0)
ToastHolder.Position = UDim2.new(0.5, 0, 0, 10)
ToastHolder.Size = UDim2.new(1, -28, 0, 38)
ToastHolder.BackgroundColor3 = CONFIG.Surface
ToastHolder.BackgroundTransparency = 1
ToastHolder.BorderSizePixel = 0
ToastHolder.ZIndex = 50
ToastHolder.Parent = Root
Corner(ToastHolder, 8)
local ToastStroke = Stroke(ToastHolder, CONFIG.Outline, 1, 1)
ToastStroke.Transparency = 1

local ToastLabel = Instance.new("TextLabel")
ToastLabel.Size = UDim2.new(1, -20, 1, 0)
ToastLabel.Position = UDim2.fromOffset(10, 0)
ToastLabel.BackgroundTransparency = 1
ToastLabel.Font = Enum.Font.GothamMedium
ToastLabel.Text = ""
ToastLabel.TextColor3 = CONFIG.Text
ToastLabel.TextSize = 13
ToastLabel.TextXAlignment = Enum.TextXAlignment.Center
ToastLabel.TextWrapped = true
ToastLabel.Parent = ToastHolder

local toastBusy = false
local function Toast(text, ok)
    if toastBusy then return end
    toastBusy = true

    ToastLabel.Text = text
    ToastLabel.TextColor3 = ok == false and Color3.fromRGB(255, 120, 120) or CONFIG.Text
    ToastStroke.Color = ok == false and Color3.fromRGB(255, 120, 120) or CONFIG.Accent

    Tween(ToastHolder, { BackgroundTransparency = 0.05 }, 0.2)
    Tween(ToastStroke, { Transparency = 0.35 }, 0.2)
    Tween(ToastLabel, { TextTransparency = 0 }, 0.2)

    task.delay(2.4, function()
        Tween(ToastHolder, { BackgroundTransparency = 1 }, 0.25)
        Tween(ToastStroke, { Transparency = 1 }, 0.25)
        Tween(ToastLabel, { TextTransparency = 1 }, 0.25)
        task.wait(0.3)
        toastBusy = false
    end)
end

local function NormalizeKey(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")):upper()
end

local verifying = false
VerifyBtn.MouseButton1Click:Connect(function()
    if verifying then return end

    local typed = NormalizeKey(KeyInput.Text)
    if typed == "" then
        Toast("Please enter your key first.", false)
        return
    end

    verifying = true
    VerifyLabel.Text = "Verifying..."

    task.spawn(function()
        task.wait(0.9)
        if typed == NormalizeKey(CONFIG.Key) then
            Toast("Access granted.", true)
            VerifyLabel.Text = "Verified"
            task.wait(0.5)
            ShowGamePage()
        else
            Toast("Invalid key. Please try again.", false)
            VerifyLabel.Text = "Verify Key"
            verifying = false
        end
    end)
end)

IconGetKey.MouseButton1Click:Connect(function()
    local copied, url = CopyURL(CONFIG.GetKeyURL)
    Toast(copied and "Get Key link copied." or url, true)
end)

IconWebsite.MouseButton1Click:Connect(function()
    local copied, url = CopyURL(CONFIG.WebsiteURL)
    Toast(copied and "Website link copied." or url, true)
end)

IconDiscord.MouseButton1Click:Connect(function()
    local copied, url = CopyURL(CONFIG.DiscordInvite)
    Toast(copied and "Discord link copied." or url, true)
end)

do
    local dragging, dragStart, startPos = false, nil, nil
    local dragArea = Instance.new("TextButton")
    dragArea.Size = UDim2.new(1, -50, 0, 110)
    dragArea.BackgroundTransparency = 1
    dragArea.Text = ""
    dragArea.ZIndex = 6
    dragArea.Parent = Root

    dragArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = UIScaleHolder.Position
        end
    end)

    dragArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            UIScaleHolder.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

Root.BackgroundTransparency = 1
Tween(Root, { BackgroundTransparency = 0.05 }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

task.delay(0.5, function()
    pcall(function() KeyInput:CaptureFocus() end)
end)