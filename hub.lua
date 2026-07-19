-- dzakob Hub
-- Add games to the Games table, hub auto-detects by PlaceId

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- =====================
-- GAME REGISTRY
-- =====================
local Games = {
    {
        Name = "Drain the Lake",
        PlaceId = {138381251771774, 124786371598438},
        Scripts = {
            {
                Name = "Bucket Farm",
                Description = "Auto fill & pour buckets + collect tokens",
                Type = "toggle",
                Run = function()
                    local remotes = game:GetService("ReplicatedStorage"):WaitForChild("VerdantRemotes")
                    local bucketUsed = remotes:WaitForChild("VDT_Bucket.Used")
                    local bucketPoured = remotes:WaitForChild("VDT_Bucket.Poured")
                    local tokensTake = remotes:WaitForChild("VDT_Tokens.Take")
                    local prompt = workspace:WaitForChild("Scripted"):WaitForChild("CheckpointParts"):WaitForChild("1"):WaitForChild("Drain"):WaitForChild("Scripted"):WaitForChild("ProximityPosition"):WaitForChild("ProximityPrompt")

                    task.spawn(function()
                        while _G.hub_toggles["Bucket Farm"] do
                            for i = 1, 10 do
                                if not _G.hub_toggles["Bucket Farm"] then return end
                                bucketUsed:FireServer()
                                task.wait(0.1)
                            end
                            bucketPoured:FireServer(prompt)
                            task.wait(0.1)
                        end
                    end)

                    while _G.hub_toggles["Bucket Farm"] do
                        tokensTake:FireServer(prompt)
                        task.wait(0.5)
                    end
                end
            }
        }
    },
    {
        Name = "+1 Speed Slime Keyboard Escape",
        PlaceId = {96947338677734},
        Scripts = {
            {
                Name = "Auto Win",
                Description = "Teleport to win button and farm wins",
                Type = "toggle",
                Run = function()
                    local part = workspace:WaitForChild("GiveWins"):WaitForChild("Button13"):WaitForChild("Touch")
                    while _G.hub_toggles["Auto Win"] do
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            local hrp = char.HumanoidRootPart
                            hrp.CFrame = part.CFrame
                            firetouchinterest(hrp, part, 0)
                            task.wait(0.1)
                            firetouchinterest(hrp, part, 1)
                        end
                        task.wait(0.5)
                    end
                end
            }
        }
    },
    {
        Name = "Settings",
        PlaceId = "all",
        Scripts = {
            {
                Name = "Disable 3D Rendering",
                Description = "Fully stop rendering the world for max FPS",
                Type = "toggle",
                Run = function()
                    local RunService = game:GetService("RunService")
                    local ok = pcall(function() RunService:Set3dRenderingEnabled(false) end)
                    if not ok then
                        settings().Rendering.QualityLevel = 1
                        pcall(function() setfpscap(240) end)
                    end
                    while _G.hub_toggles["Disable 3D Rendering"] do task.wait(1) end
                    pcall(function() RunService:Set3dRenderingEnabled(true) end)
                end
            },
            {
                Name = "Notification Corner",
                Description = "Click to cycle: TR → TL → BR → BL",
                Type = "cycle",
                Cycle = {"tr", "tl", "br", "bl"},
                Labels = {tr = "Top Right", tl = "Top Left", br = "Bottom Right", bl = "Bottom Left"},
                Run = function() end
            }
        }
    }
}

-- =====================
-- KEY SYSTEM CONFIG
-- =====================
local VERCEL_URL = "https://dzakob-keys.vercel.app"
local GET_KEY_URL = "https://loot-link.com/s?6pdcrrvy"
local KEY_FILE = "dzakob_key.txt"
local HWID_LOCK = true
local KEY_LIFETIME_HOURS = 24

local function getHWID()
    local ok, hwid = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and hwid or "unknown"
end

local function validateOnServer(key)
    local encoded = key:gsub("[^%w%-]", function(c)
        return string.format("%%%02X", c:byte())
    end)
    local ok, response = pcall(function()
        return game:HttpGet(VERCEL_URL .. "/api/validate?key=" .. encoded .. "&t=" .. tick())
    end)
    if not ok then return nil, "Failed to reach key server" end
    if response:find('"valid"%s*:%s*true') then
        local isAdmin = response:find('"admin"%s*:%s*true') ~= nil
        return true, nil, isAdmin
    end
    return false, "Invalid or expired key"
end

local function checkSavedKey()
    if not (isfile and isfile(KEY_FILE)) then return nil end
    local ok, saved = pcall(readfile, KEY_FILE)
    if not ok then return nil end
    local storedKey, storedHwid, storedTime = saved:match("^(.-)|(.-)|(.*)$")
    if not storedKey then
        storedKey, storedHwid = saved:match("^(.-)|(.*)$")
        storedTime = "0"
    end
    if not storedKey then storedKey = saved end
    if HWID_LOCK and storedHwid and storedHwid ~= getHWID() then
        pcall(delfile, KEY_FILE)
        return nil
    end
    local savedTime = tonumber(storedTime) or 0
    if savedTime > 0 and (os.time() - savedTime) > (KEY_LIFETIME_HOURS * 3600) then
        pcall(delfile, KEY_FILE)
        return nil, "expired"
    end
    return storedKey
end

local function saveKey(key)
    if writefile then
        pcall(writefile, KEY_FILE, key .. "|" .. getHWID() .. "|" .. tostring(os.time()))
    end
end

local function validateKey(key)
    local ok, err, isAdmin = validateOnServer(key)
    if ok then return true, isAdmin end
    return false, err or "Invalid key"
end

-- =====================
-- GUI FRAMEWORK
-- =====================
_G.hub_toggles = _G.hub_toggles or {}

if game:GetService("CoreGui"):FindFirstChild("ScriptHub") then
    game:GetService("CoreGui"):FindFirstChild("ScriptHub"):Destroy()
end
if game:GetService("CoreGui"):FindFirstChild("dzakobKey") then
    game:GetService("CoreGui"):FindFirstChild("dzakobKey"):Destroy()
end

-- =====================
-- KEY GUI
-- =====================
local function showKeyGui(onSuccess)
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "dzakobKey"
    keyGui.ResetOnSpawn = false
    keyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    keyGui.Parent = game:GetService("CoreGui")

    local kframe = Instance.new("Frame")
    kframe.Size = UDim2.new(0, 380, 0, 225)
    kframe.Position = UDim2.new(0.5, -190, 0.5, -112)
    kframe.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    kframe.BorderSizePixel = 0
    kframe.Active = true
    kframe.Parent = keyGui

    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(0, 10)
    kCorner.Parent = kframe

    local kStroke = Instance.new("UIStroke")
    kStroke.Color = Color3.fromRGB(60, 60, 80)
    kStroke.Thickness = 1.5
    kStroke.Parent = kframe

    local kTitle = Instance.new("TextLabel")
    kTitle.Size = UDim2.new(1, 0, 0, 40)
    kTitle.Position = UDim2.new(0, 0, 0, 12)
    kTitle.BackgroundTransparency = 1
    kTitle.Text = "dzakob"
    kTitle.TextColor3 = Color3.fromRGB(230, 230, 250)
    kTitle.TextSize = 22
    kTitle.Font = Enum.Font.GothamBold
    kTitle.Parent = kframe

    local kSub = Instance.new("TextLabel")
    kSub.Size = UDim2.new(1, 0, 0, 18)
    kSub.Position = UDim2.new(0, 0, 0, 50)
    kSub.BackgroundTransparency = 1
    kSub.Text = "Enter key to continue"
    kSub.TextColor3 = Color3.fromRGB(140, 140, 160)
    kSub.TextSize = 12
    kSub.Font = Enum.Font.Gotham
    kSub.Parent = kframe

    local kInput = Instance.new("TextBox")
    kInput.Size = UDim2.new(1, -40, 0, 36)
    kInput.Position = UDim2.new(0, 20, 0, 90)
    kInput.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    kInput.BorderSizePixel = 0
    kInput.PlaceholderText = "Paste key here..."
    kInput.PlaceholderColor3 = Color3.fromRGB(90, 90, 110)
    kInput.Text = ""
    kInput.TextColor3 = Color3.fromRGB(230, 230, 250)
    kInput.TextSize = 13
    kInput.Font = Enum.Font.Gotham
    kInput.ClearTextOnFocus = false
    kInput.Parent = kframe

    local iCorner = Instance.new("UICorner")
    iCorner.CornerRadius = UDim.new(0, 6)
    iCorner.Parent = kInput

    local checkBtn = Instance.new("TextButton")
    checkBtn.Size = UDim2.new(0.45, -6, 0, 36)
    checkBtn.Position = UDim2.new(0, 20, 0, 138)
    checkBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
    checkBtn.BorderSizePixel = 0
    checkBtn.Text = "CHECK KEY"
    checkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkBtn.TextSize = 12
    checkBtn.Font = Enum.Font.GothamBold
    checkBtn.Parent = kframe

    local cCorner = Instance.new("UICorner")
    cCorner.CornerRadius = UDim.new(0, 6)
    cCorner.Parent = checkBtn

    local getBtn = Instance.new("TextButton")
    getBtn.Size = UDim2.new(0.45, -6, 0, 36)
    getBtn.Position = UDim2.new(0.55, -8, 0, 138)
    getBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    getBtn.BorderSizePixel = 0
    getBtn.Text = "GET KEY"
    getBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    getBtn.TextSize = 12
    getBtn.Font = Enum.Font.GothamBold
    getBtn.Parent = kframe

    local gCorner = Instance.new("UICorner")
    gCorner.CornerRadius = UDim.new(0, 6)
    gCorner.Parent = getBtn

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -40, 0, 20)
    status.Position = UDim2.new(0, 20, 1, -30)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(200, 200, 220)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.Parent = kframe

    -- dragging
    local dragging, dStart, sPos
    kTitle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dStart = input.Position
            sPos = kframe.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dStart
            kframe.Position = UDim2.new(sPos.X.Scale, sPos.X.Offset + delta.X, sPos.Y.Scale, sPos.Y.Offset + delta.Y)
        end
    end)

    checkBtn.MouseButton1Click:Connect(function()
        local key = kInput.Text:match("^%s*(.-)%s*$")
        if key == "" then
            status.Text = "Enter a key first"
            status.TextColor3 = Color3.fromRGB(255, 180, 80)
            return
        end
        status.Text = "Checking..."
        status.TextColor3 = Color3.fromRGB(200, 200, 220)
        task.spawn(function()
            local ok, err = validateKey(key)
            if ok then
                saveKey(key)
                status.Text = "Key valid — loading hub"
                status.TextColor3 = Color3.fromRGB(80, 220, 100)
                task.wait(0.6)
                keyGui:Destroy()
                onSuccess()
            else
                status.Text = err
                status.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end)
    end)

    getBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(GET_KEY_URL)
            status.Text = "Link copied to clipboard"
            status.TextColor3 = Color3.fromRGB(80, 220, 100)
        else
            status.Text = "Go to: " .. GET_KEY_URL
        end
    end)

end

-- =====================
-- MAIN HUB LOADER
-- =====================
local function loadHub()

local gui = Instance.new("ScreenGui")
gui.Name = "ScriptHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = game:GetService("CoreGui")

-- backdrop (gradient)
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(0, 500, 0, 350)
backdrop.Position = UDim2.new(0.5, -250, 0.5, -175)
backdrop.BackgroundColor3 = Color3.fromRGB(42, 26, 62)
backdrop.BorderSizePixel = 0
backdrop.ClipsDescendants = true
backdrop.Parent = gui

local backdropCorner = Instance.new("UICorner")
backdropCorner.CornerRadius = UDim.new(0, 16)
backdropCorner.Parent = backdrop

local backdropGradient = Instance.new("UIGradient")
backdropGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(42, 26, 62)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 42, 78))
}
backdropGradient.Rotation = 135
backdropGradient.Parent = backdrop

-- glass main (fills backdrop entirely, no outer margin)
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(1, 0, 1, 0)
main.Position = UDim2.new(0, 0, 0, 0)
main.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
main.BackgroundTransparency = 0.94
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = backdrop

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 255, 255)
mainStroke.Transparency = 0.88
mainStroke.Thickness = 1
mainStroke.Parent = main

-- title bar (no separate bg, part of glass)
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 46)
titleBar.BackgroundTransparency = 1
titleBar.BorderSizePixel = 0
titleBar.Parent = main

-- separator under title
local titleSep = Instance.new("Frame")
titleSep.Size = UDim2.new(1, -24, 0, 1)
titleSep.Position = UDim2.new(0, 12, 0, 46)
titleSep.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
titleSep.BackgroundTransparency = 0.92
titleSep.BorderSizePixel = 0
titleSep.Parent = main

-- avatar
local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.new(0, 26, 0, 26)
avatar.Position = UDim2.new(0, 14, 0, 10)
avatar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
avatar.BorderSizePixel = 0
avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=48&h=48"
avatar.Parent = titleBar

local avCorner = Instance.new("UICorner")
avCorner.CornerRadius = UDim.new(1, 0)
avCorner.Parent = avatar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -140, 0, 16)
titleLabel.Position = UDim2.new(0, 48, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "dzakob"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 14
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local userLabel = Instance.new("TextLabel")
userLabel.Size = UDim2.new(1, -140, 0, 12)
userLabel.Position = UDim2.new(0, 48, 0, 24)
userLabel.BackgroundTransparency = 1
userLabel.Text = "@" .. player.Name
userLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
userLabel.TextTransparency = 0.5
userLabel.TextSize = 10
userLabel.Font = Enum.Font.Gotham
userLabel.TextXAlignment = Enum.TextXAlignment.Left
userLabel.Parent = titleBar

-- game indicator (bottom of sidebar)
local gameIndicator = Instance.new("TextLabel")
gameIndicator.Size = UDim2.new(0, 130, 0, 14)
gameIndicator.Position = UDim2.new(0, 12, 1, -22)
gameIndicator.BackgroundTransparency = 1
gameIndicator.Text = ""
gameIndicator.TextColor3 = Color3.fromRGB(255, 255, 255)
gameIndicator.TextTransparency = 0.4
gameIndicator.TextSize = 9
gameIndicator.Font = Enum.Font.Gotham
gameIndicator.TextXAlignment = Enum.TextXAlignment.Left
gameIndicator.TextWrapped = true
gameIndicator.Parent = main

-- hint label
local hintLabel = Instance.new("TextLabel")
hintLabel.Size = UDim2.new(0, 130, 0, 14)
hintLabel.Position = UDim2.new(1, -142, 0, 18)
hintLabel.BackgroundTransparency = 1
hintLabel.Text = "LeftAlt to toggle"
hintLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
hintLabel.TextTransparency = 0.55
hintLabel.TextSize = 10
hintLabel.Font = Enum.Font.Gotham
hintLabel.TextXAlignment = Enum.TextXAlignment.Right
hintLabel.Parent = titleBar

-- tabs (horizontal pills, not sidebar anymore)
local tabsBar = Instance.new("Frame")
tabsBar.Name = "TabsBar"
tabsBar.Size = UDim2.new(1, -24, 0, 32)
tabsBar.Position = UDim2.new(0, 12, 0, 54)
tabsBar.BackgroundTransparency = 1
tabsBar.Parent = main

local tabsLayout = Instance.new("UIListLayout")
tabsLayout.FillDirection = Enum.FillDirection.Horizontal
tabsLayout.Padding = UDim.new(0, 6)
tabsLayout.Parent = tabsBar

local sidebar = tabsBar -- alias for existing code

-- search bar (below tabs)
local searchBar = Instance.new("TextBox")
searchBar.Size = UDim2.new(1, -24, 0, 32)
searchBar.Position = UDim2.new(0, 12, 0, 94)
searchBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
searchBar.BackgroundTransparency = 0.92
searchBar.BorderSizePixel = 0
searchBar.PlaceholderText = "Search scripts..."
searchBar.PlaceholderColor3 = Color3.fromRGB(255, 255, 255)
searchBar.Text = ""
searchBar.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBar.TextSize = 12
searchBar.Font = Enum.Font.Gotham
searchBar.TextXAlignment = Enum.TextXAlignment.Left
searchBar.ClearTextOnFocus = false
searchBar.Parent = main

local sbCorner = Instance.new("UICorner")
sbCorner.CornerRadius = UDim.new(0, 10)
sbCorner.Parent = searchBar

local sbPad = Instance.new("UIPadding")
sbPad.PaddingLeft = UDim.new(0, 12)
sbPad.Parent = searchBar

-- content area
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -24, 1, -160)
content.Position = UDim2.new(0, 12, 0, 134)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
content.ScrollBarImageTransparency = 0.7
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = main

local contentLayout = Instance.new("UIListLayout")
contentLayout.Padding = UDim.new(0, 6)
contentLayout.Parent = content

local contentPad = Instance.new("UIPadding")
contentPad.PaddingTop = UDim.new(0, 4)
contentPad.PaddingLeft = UDim.new(0, 6)
contentPad.PaddingRight = UDim.new(0, 6)
contentPad.Parent = content

-- notification container
local notifRoot = Instance.new("Frame")
notifRoot.Size = UDim2.new(0, 260, 1, -20)
notifRoot.Position = UDim2.new(1, -270, 0, 10)
notifRoot.BackgroundTransparency = 1
notifRoot.Parent = gui

local notifLayout = Instance.new("UIListLayout")
notifLayout.Padding = UDim.new(0, 6)
notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
notifLayout.Parent = notifRoot

local function notify(text, kind)
    local color = Color3.fromRGB(120, 90, 255)
    if kind == "success" then color = Color3.fromRGB(60, 200, 100) end
    if kind == "error" then color = Color3.fromRGB(240, 80, 80) end

    local n = Instance.new("Frame")
    n.Size = UDim2.new(1, 0, 0, 44)
    n.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    n.BorderSizePixel = 0
    n.Parent = notifRoot

    local nc = Instance.new("UICorner")
    nc.CornerRadius = UDim.new(0, 8)
    nc.Parent = n

    local strip = Instance.new("Frame")
    strip.Size = UDim2.new(0, 3, 1, -12)
    strip.Position = UDim2.new(0, 8, 0, 6)
    strip.BackgroundColor3 = color
    strip.BorderSizePixel = 0
    strip.Parent = n

    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 2)
    sc.Parent = strip

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -24, 1, 0)
    lbl.Position = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(230, 230, 250)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = n

    n.Position = UDim2.new(1, 30, 0, 0)
    TweenService:Create(n, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()

    task.spawn(function()
        task.wait(3)
        TweenService:Create(n, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
        for _, c in n:GetDescendants() do
            if c:IsA("TextLabel") then
                TweenService:Create(c, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            elseif c:IsA("Frame") then
                TweenService:Create(c, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            end
        end
        task.wait(0.4)
        n:Destroy()
    end)
end

_G.dzakob_notify = notify

_G.dzakob_setNotifCorner = function(corner)
    if corner == "tr" then
        notifRoot.Position = UDim2.new(1, -270, 0, 10)
        notifRoot.AnchorPoint = Vector2.new(0, 0)
        notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    elseif corner == "tl" then
        notifRoot.Position = UDim2.new(0, 10, 0, 10)
        notifRoot.AnchorPoint = Vector2.new(0, 0)
        notifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
    elseif corner == "br" then
        notifRoot.Position = UDim2.new(1, -270, 1, -10)
        notifRoot.AnchorPoint = Vector2.new(0, 1)
        notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    elseif corner == "bl" then
        notifRoot.Position = UDim2.new(0, 10, 1, -10)
        notifRoot.AnchorPoint = Vector2.new(0, 1)
        notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    end
end

-- =====================
-- DRAGGING
-- =====================
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = backdrop.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        backdrop.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- =====================
-- LEFT ALT TOGGLE
-- =====================
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.LeftAlt then
        backdrop.Visible = not backdrop.Visible
    end
end)

-- =====================
-- BUILD TABS
-- =====================
local currentPlaceId = game.PlaceId
local activeTab = nil
local tabButtons = {}

local function clearContent()
    for _, child in content:GetChildren() do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function createScriptCard(scriptData)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 58)
    card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    card.BackgroundTransparency = 0.95
    card.BorderSizePixel = 0
    card.Parent = content

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -100, 0, 20)
    name.Position = UDim2.new(0, 14, 0, 10)
    name.BackgroundTransparency = 1
    name.Text = scriptData.Name
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.TextSize = 13
    name.Font = Enum.Font.GothamMedium
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -100, 0, 14)
    desc.Position = UDim2.new(0, 14, 0, 30)
    desc.BackgroundTransparency = 1
    desc.Text = scriptData.Description
    desc.TextColor3 = Color3.fromRGB(255, 255, 255)
    desc.TextTransparency = 0.55
    desc.TextSize = 10
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = card

    if scriptData.Type == "toggle" then
        _G.hub_toggles[scriptData.Name] = _G.hub_toggles[scriptData.Name] or false

        -- pill toggle
        local track = Instance.new("TextButton")
        track.Size = UDim2.new(0, 40, 0, 22)
        track.Position = UDim2.new(1, -54, 0.5, -11)
        track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        track.BackgroundTransparency = 0.75
        track.BorderSizePixel = 0
        track.Text = ""
        track.AutoButtonColor = false
        track.Parent = card

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 18, 0, 18)
        knob.Position = UDim2.new(0, 2, 0.5, -9)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel = 0
        knob.Parent = track

        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local function updateToggle()
            if _G.hub_toggles[scriptData.Name] then
                TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(77, 216, 132), BackgroundTransparency = 0}):Play()
                TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 20, 0.5, -9)}):Play()
            else
                TweenService:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.75}):Play()
                TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9)}):Play()
            end
        end

        updateToggle()

        track.MouseButton1Click:Connect(function()
            _G.hub_toggles[scriptData.Name] = not _G.hub_toggles[scriptData.Name]
            updateToggle()
            if _G.hub_toggles[scriptData.Name] then
                _G.dzakob_notify(scriptData.Name .. " started", "success")
                task.spawn(function()
                    local ok, err = pcall(scriptData.Run)
                    if not ok then
                        _G.dzakob_notify("Error: " .. tostring(err):sub(1,60), "error")
                    end
                    _G.hub_toggles[scriptData.Name] = false
                    updateToggle()
                end)
            else
                _G.dzakob_notify(scriptData.Name .. " stopped")
            end
        end)
    elseif scriptData.Type == "cycle" then
        _G.hub_cycle = _G.hub_cycle or {}
        _G.hub_cycle[scriptData.Name] = _G.hub_cycle[scriptData.Name] or 1

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 0, 28)
        btn.Position = UDim2.new(1, -114, 0.5, -14)
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        btn.TextColor3 = Color3.fromRGB(30, 30, 50)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Text = scriptData.Labels[scriptData.Cycle[_G.hub_cycle[scriptData.Name]]]
        btn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            _G.hub_cycle[scriptData.Name] = (_G.hub_cycle[scriptData.Name] % #scriptData.Cycle) + 1
            local val = scriptData.Cycle[_G.hub_cycle[scriptData.Name]]
            btn.Text = scriptData.Labels[val]
            if scriptData.Name == "Notification Corner" and _G.dzakob_setNotifCorner then
                _G.dzakob_setNotifCorner(val)
            end
        end)
    else
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 62, 0, 28)
        btn.Position = UDim2.new(1, -76, 0.5, -14)
        btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        btn.Text = "RUN"
        btn.TextColor3 = Color3.fromRGB(30, 30, 50)
        btn.TextSize = 11
        btn.Font = Enum.Font.GothamBold
        btn.Parent = card

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        btn.MouseButton1Click:Connect(function()
            btn.Text = "..."
            task.spawn(function()
                local ok, err = pcall(scriptData.Run)
                if not ok then
                    _G.dzakob_notify("Error: " .. tostring(err):sub(1,60), "error")
                else
                    _G.dzakob_notify(scriptData.Name .. " ran", "success")
                end
                btn.Text = "RUN"
            end)
        end)
    end
    card.Name = scriptData.Name
end

searchBar:GetPropertyChangedSignal("Text"):Connect(function()
    local q = searchBar.Text:lower()
    for _, c in content:GetChildren() do
        if c:IsA("Frame") then
            c.Visible = q == "" or (c.Name:lower():find(q, 1, true) ~= nil)
        end
    end
end)

local function loadTab(gameData)
    clearContent()
    activeTab = gameData.Name
    searchBar.Text = ""

    for _, tabBtn in tabButtons do
        if tabBtn.Name == gameData.Name then
            TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0, TextColor3 = Color3.fromRGB(30, 30, 60), TextTransparency = 0}):Play()
        else
            TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.85, TextColor3 = Color3.fromRGB(255, 255, 255), TextTransparency = 0.4}):Play()
        end
    end

    for _, scriptData in gameData.Scripts do
        createScriptCard(scriptData)
    end
end

-- detect current game and build sidebar
local detectedGame = nil

for _, gameData in Games do
    local isMatch = false

    if gameData.PlaceId == "all" then
        isMatch = true
    else
        for _, id in gameData.PlaceId do
            if id == currentPlaceId then
                isMatch = true
                detectedGame = gameData.Name
                break
            end
        end
    end

    if isMatch or gameData.PlaceId == "all" then
        local nameLen = #gameData.Name
        local w = math.max(80, math.min(180, nameLen * 8 + 24))
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = gameData.Name
        tabBtn.Size = UDim2.new(0, w, 1, 0)
        tabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.BackgroundTransparency = 0.85
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = gameData.Name
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.TextTransparency = 0.4
        tabBtn.TextSize = 11
        tabBtn.Font = Enum.Font.GothamMedium
        tabBtn.TextTruncate = Enum.TextTruncate.AtEnd
        tabBtn.Parent = sidebar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(1, 0)
        tabCorner.Parent = tabBtn

        table.insert(tabButtons, tabBtn)

        tabBtn.MouseButton1Click:Connect(function()
            loadTab(gameData)
        end)

        if detectedGame == gameData.Name then
            gameIndicator.Text = "Detected: " .. gameData.Name
            task.defer(function() loadTab(gameData) end)
        end
    end
end

if not detectedGame then
    gameIndicator.Text = "Game not recognized (PlaceId: " .. currentPlaceId .. ")"
    gameIndicator.TextColor3 = Color3.fromRGB(200, 200, 100)
    -- load universal by default
    for _, gameData in Games do
        if gameData.PlaceId == "all" then
            task.defer(function() loadTab(gameData) end)
            break
        end
    end
end

print("dzakob loaded | PlaceId: " .. currentPlaceId)
end

-- =====================
-- ENTRY POINT
-- =====================
local savedKey = checkSavedKey()
if savedKey then
    task.spawn(function()
        local ok = validateKey(savedKey)
        if ok then
            loadHub()
        else
            pcall(function() delfile(KEY_FILE) end)
            showKeyGui(loadHub)
        end
    end)
else
    showKeyGui(loadHub)
end
