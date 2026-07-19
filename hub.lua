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
        Name = "Win Farm",
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
        Name = "Universal",
        PlaceId = "all",
        Scripts = {
            {
                Name = "Remote Spy",
                Description = "Open SimpleSpy remote logger",
                Type = "button",
                Run = function()
                    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/78n/SimpleSpy/main/SimpleSpyBeta.lua"))()
                end
            },
            {
                Name = "Vex Explorer",
                Description = "Open Vex Explorer GUI",
                Type = "button",
                Run = function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua"))()
                end
            },
            {
                Name = "Cobalt",
                Description = "Open Cobalt GUI",
                Type = "button",
                Run = function()
                    loadstring(game:HttpGet("https://github.com/notpoiu/cobalt/releases/latest/download/Cobalt.luau"))()
                end
            },
            {
                Name = "Free Gamepass",
                Description = "Unlock gamepasses for free",
                Type = "button",
                Run = function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/7yd7/FreeGamepass/main/Script.luau"))()
                end
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
        return true
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
    local ok, err = validateOnServer(key)
    if ok then return true end
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

-- main frame
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 500, 0, 350)
main.Position = UDim2.new(0.5, -250, 0.5, -175)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = main

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 80)
mainStroke.Thickness = 1.5
mainStroke.Parent = main

-- title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
titleBar.BorderSizePixel = 0
titleBar.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 10)
titleCorner.Parent = titleBar

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0, 12)
titleFix.Position = UDim2.new(0, 0, 1, -12)
titleFix.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 14, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "dzakob"
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
titleLabel.TextSize = 15
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- game indicator
local gameIndicator = Instance.new("TextLabel")
gameIndicator.Size = UDim2.new(0, 200, 0, 16)
gameIndicator.Position = UDim2.new(0, 14, 0, 36)
gameIndicator.BackgroundTransparency = 1
gameIndicator.Text = ""
gameIndicator.TextColor3 = Color3.fromRGB(100, 200, 120)
gameIndicator.TextSize = 11
gameIndicator.Font = Enum.Font.Gotham
gameIndicator.TextXAlignment = Enum.TextXAlignment.Left
gameIndicator.Parent = main

-- close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -36, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar

-- minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 36, 0, 36)
minBtn.Position = UDim2.new(1, -72, 0, 0)
minBtn.BackgroundTransparency = 1
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.TextSize = 20
minBtn.Font = Enum.Font.GothamBold
minBtn.Parent = titleBar

-- sidebar
local sidebar = Instance.new("ScrollingFrame")
sidebar.Name = "Sidebar"
sidebar.Size = UDim2.new(0, 130, 1, -56)
sidebar.Position = UDim2.new(0, 0, 0, 56)
sidebar.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
sidebar.BorderSizePixel = 0
sidebar.ScrollBarThickness = 2
sidebar.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
sidebar.Parent = main

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.Padding = UDim.new(0, 2)
sidebarLayout.Parent = sidebar

local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 4)
sidebarPad.PaddingLeft = UDim.new(0, 4)
sidebarPad.PaddingRight = UDim.new(0, 4)
sidebarPad.Parent = sidebar

-- content area
local content = Instance.new("ScrollingFrame")
content.Name = "Content"
content.Size = UDim2.new(1, -140, 1, -56)
content.Position = UDim2.new(0, 136, 0, 56)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 3
content.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
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

-- =====================
-- DRAGGING
-- =====================
local dragging, dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- =====================
-- MINIMIZE / CLOSE
-- =====================
local minimized = false
local fullSize = main.Size

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        TweenService:Create(main, TweenInfo.new(0.2), {Size = UDim2.new(0, 500, 0, 36)}):Play()
        minBtn.Text = "+"
    else
        TweenService:Create(main, TweenInfo.new(0.2), {Size = fullSize}):Play()
        minBtn.Text = "-"
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    for k in _G.hub_toggles do
        _G.hub_toggles[k] = false
    end
    gui:Destroy()
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
    card.Size = UDim2.new(1, 0, 0, 60)
    card.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    card.BorderSizePixel = 0
    card.Parent = content

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 8)
    cardCorner.Parent = card

    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, -90, 0, 22)
    name.Position = UDim2.new(0, 12, 0, 8)
    name.BackgroundTransparency = 1
    name.Text = scriptData.Name
    name.TextColor3 = Color3.fromRGB(230, 230, 250)
    name.TextSize = 14
    name.Font = Enum.Font.GothamBold
    name.TextXAlignment = Enum.TextXAlignment.Left
    name.Parent = card

    local desc = Instance.new("TextLabel")
    desc.Size = UDim2.new(1, -90, 0, 16)
    desc.Position = UDim2.new(0, 12, 0, 32)
    desc.BackgroundTransparency = 1
    desc.Text = scriptData.Description
    desc.TextColor3 = Color3.fromRGB(120, 120, 150)
    desc.TextSize = 11
    desc.Font = Enum.Font.Gotham
    desc.TextXAlignment = Enum.TextXAlignment.Left
    desc.Parent = card

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 30)
    btn.Position = UDim2.new(1, -80, 0.5, -15)
    btn.BorderSizePixel = 0
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = card

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn

    if scriptData.Type == "toggle" then
        _G.hub_toggles[scriptData.Name] = _G.hub_toggles[scriptData.Name] or false

        local function updateToggle()
            if _G.hub_toggles[scriptData.Name] then
                btn.Text = "ON"
                btn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            else
                btn.Text = "OFF"
                btn.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
                btn.TextColor3 = Color3.fromRGB(180, 180, 200)
            end
        end

        updateToggle()

        btn.MouseButton1Click:Connect(function()
            _G.hub_toggles[scriptData.Name] = not _G.hub_toggles[scriptData.Name]
            updateToggle()
            if _G.hub_toggles[scriptData.Name] then
                task.spawn(function()
                    local ok, err = pcall(scriptData.Run)
                    if not ok then warn("Script error:", err) end
                    _G.hub_toggles[scriptData.Name] = false
                    updateToggle()
                end)
            end
        end)
    else
        btn.Text = "RUN"
        btn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)

        btn.MouseButton1Click:Connect(function()
            btn.Text = "..."
            task.spawn(function()
                local ok, err = pcall(scriptData.Run)
                if not ok then warn("Script error:", err) end
                btn.Text = "RUN"
            end)
        end)
    end
end

local function loadTab(gameData)
    clearContent()
    activeTab = gameData.Name

    for _, tabBtn in tabButtons do
        if tabBtn.Name == gameData.Name then
            tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
            tabBtn.TextColor3 = Color3.fromRGB(220, 220, 255)
        else
            tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
            tabBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
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
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = gameData.Name
        tabBtn.Size = UDim2.new(1, 0, 0, 32)
        tabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = gameData.Name
        tabBtn.TextColor3 = Color3.fromRGB(140, 140, 160)
        tabBtn.TextSize = 12
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextTruncate = Enum.TextTruncate.AtEnd
        tabBtn.Parent = sidebar

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 6)
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
