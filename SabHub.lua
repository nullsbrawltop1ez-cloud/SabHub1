-- ========================================================
-- Sab Hub v1.1 – Часть 1 (Основные переменные, логика и функции)
-- ========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ===== НАСТРОЙКИ ФУНКЦИЙ =====
getgenv().SabConfig = {
    espEnabled = false,
    espNameEnabled = true,
    espHealthEnabled = true,
    espDistEnabled = true,
    chamsEnabled = false,
    aimbotEnabled = false,
    silentAimEnabled = false,
    FOV = 150,
    spinEnabled = false,
    spinSpeed = 5,
    thirdPersonEnabled = false,
    thirdPersonDistance = 8,
    thirdPersonHeight = 3,
    bunnyHopEnabled = false,
    infiniteJumpEnabled = true,
    teleportDist = 5, -- Расстояние при телепорте
    teleKillEnabled = false -- Состояние для TeleKill
}

local cfg = getgenv().SabConfig
local maxJumps = 999999
local currentJumps = 0
local spinAngle = 0
local teleKillTarget = nil

-- Прыжки
UserInputService.JumpRequest:Connect(function()
    if not cfg.infiniteJumpEnabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    if humanoid:GetState() == Enum.HumanoidStateType.Running then
        currentJumps = 0
    else
        if currentJumps < maxJumps then
            currentJumps = currentJumps + 1
            rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 50, rootPart.AssemblyLinearVelocity.Z)
        end
    end
end)

-- Поиск ближайшей цели (для Аима)
local function getClosestTarget()
    local closest, minDist = nil, cfg.FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChild("Humanoid")
            if hrp and hum and hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = hrp
                    end
                end
            end
        end
    end
    return closest
end

-- Функция TeleportRandomPlayer (телепорт к случайному или ближайшему игроку один раз без молний)
local function teleportRandomPlayer()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local alivePlayers = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local pHum = player.Character:FindFirstChild("Humanoid")
            if pRoot and pHum and pHum.Health > 0 then
                table.insert(alivePlayers, pRoot)
            end
        end
    end

    if #alivePlayers > 0 then
        local target = alivePlayers[math.random(1, #alivePlayers)]
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, -cfg.teleportDist)
    end
end

-- Chams
local chamsHighlights = {}
local function updateChams()
    if not cfg.chamsEnabled then
        for p, h in pairs(chamsHighlights) do if h then h:Destroy() end end
        chamsHighlights = {}
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                if not chamsHighlights[player] or not chamsHighlights[player].Parent then
                    local h = Instance.new("Highlight")
                    h.Adornee = char
                    h.FillColor = Color3.fromRGB(0, 255, 0)
                    h.FillTransparency = 0.3
                    h.OutlineColor = Color3.fromRGB(255, 255, 255)
                    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    h.Parent = char
                    chamsHighlights[player] = h
                else
                    chamsHighlights[player].Enabled = true
                end
            else
                if chamsHighlights[player] then chamsHighlights[player]:Destroy(); chamsHighlights[player] = nil end
            end
        end
    end
end

-- ESP
local espData = {}
local function updateESP()
    if not cfg.espEnabled then
        for p, data in pairs(espData) do
            if data.hl then data.hl:Destroy() end
            if data.bb then data.bb:Destroy() end
        end
        espData = {}
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local hum = char and char:FindFirstChild("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if char and hum and hrp and hum.Health > 0 then
                if not espData[player] then
                    local highlight = Instance.new("Highlight")
                    highlight.Adornee = char
                    highlight.FillColor = Color3.fromRGB(255, 255, 255)
                    highlight.FillTransparency = 0.3
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.Parent = char

                    local billboard = Instance.new("BillboardGui")
                    billboard.Adornee = char:FindFirstChild("Head") or hrp
                    billboard.Size = UDim2.new(0, 100, 0, 50)
                    billboard.StudsOffset = Vector3.new(0, 2, 0)
                    billboard.AlwaysOnTop = true
                    billboard.Parent = billboard.Adornee

                    local nameL = Instance.new("TextLabel")
                    nameL.Size = UDim2.new(1, 0, 0.3, 0)
                    nameL.BackgroundTransparency = 1
                    nameL.Text = player.Name
                    nameL.TextColor3 = Color3.fromRGB(255, 255, 255)
                    nameL.TextSize = 11
                    nameL.Font = Enum.Font.GothamBold
                    nameL.Parent = billboard

                    local hpBg = Instance.new("Frame")
                    hpBg.Size = UDim2.new(0, 4, 0, 25)
                    hpBg.Position = UDim2.new(0.1, 0, 0.35, 0)
                    hpBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    hpBg.Parent = billboard

                    local hpFill = Instance.new("Frame")
                    hpFill.Size = UDim2.new(1, 0, 1, 0)
                    hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                    hpFill.Parent = hpBg

                    local distL = Instance.new("TextLabel")
                    distL.Size = UDim2.new(1, 0, 0.3, 0)
                    distL.Position = UDim2.new(0, 0, 0.7, 0)
                    distL.BackgroundTransparency = 1
                    distL.TextColor3 = Color3.fromRGB(255, 255, 255)
                    distL.TextSize = 9
                    distL.Font = Enum.Font.Gotham
                    distL.Parent = billboard

                    espData[player] = {hl = highlight, bb = billboard, name = nameL, fill = hpFill, dist = distL, hpB = hpBg}
                else
                    local d = espData[player]
                    d.hl.Enabled = true
                    d.bb.Enabled = true
                    d.name.Visible = cfg.espNameEnabled
                    d.hpB.Visible = cfg.espHealthEnabled
                    d.dist.Visible = cfg.espDistEnabled

                    local hpPercent = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    d.fill.Size = UDim2.new(1, 0, hpPercent, 0)
                    d.fill.Position = UDim2.new(0, 0, 1 - hpPercent, 0)

                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                    d.dist.Text = string.format("%.0fm", dist)
                end
            else
                if espData[player] then
                    if espData[player].hl then espData[player].hl:Destroy() end
                    if espData[player].bb then espData[player].bb:Destroy() end
                    espData[player] = nil
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    updateESP()
    updateChams()

    -- Логика TeleKill (постоянное следование за спиной противника)
    if cfg.teleKillEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            if not teleKillTarget or not teleKillTarget.Parent or not teleKillTarget.Parent:FindFirstChild("Humanoid") or teleKillTarget.Parent.Humanoid.Health <= 0 then
                teleKillTarget = nil
                local minDist = math.huge
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer and player.Character then
                        local pRoot = player.Character:FindFirstChild("HumanoidRootPart")
                        local pHum = player.Character:FindFirstChild("Humanoid")
                        if pRoot and pHum and pHum.Health > 0 then
                            local dist = (hrp.Position - pRoot.Position).Magnitude
                            if dist < minDist then
                                minDist = dist
                                teleKillTarget = pRoot
                            end
                        end
                    end
                end
            end

            if teleKillTarget then
                hrp.CFrame = teleKillTarget.CFrame * CFrame.new(0, 0, cfg.teleportDist)
            end
        end
    else
        teleKillTarget = nil
    end

    if cfg.spinEnabled then
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            spinAngle = spinAngle + math.rad(cfg.spinSpeed)
            hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
        end
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local targetPoint = nil
        if cfg.aimbotEnabled then
            local target = getClosestTarget()
            if target then targetPoint = target.Position end
        end

        if cfg.thirdPersonEnabled then
            local lookDir = (targetPoint and (targetPoint - hrp.Position).Unit) or hrp.CFrame.LookVector
            local camPos = hrp.Position - lookDir * cfg.thirdPersonDistance + Vector3.new(0, cfg.thirdPersonHeight, 0)
            Camera.CFrame = CFrame.new(camPos, targetPoint or (hrp.Position + Vector3.new(0, 1.5, 0)))
        else
            if cfg.aimbotEnabled and targetPoint then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPoint)
            end
        end
    end

    if cfg.bunnyHopEnabled then
        local humanoid = char and char:FindFirstChild("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if humanoid and hrp then
            local state = humanoid:GetState()
            if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and cfg.silentAimEnabled and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local target = getClosestTarget()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end
end)
-- ========================================================
-- Sab Hub v1.1 – Часть 2 (Графический интерфейс и меню)
-- ========================================================

if CoreGui:FindFirstChild("SabHubGUI") then
    CoreGui.SabHubGUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SabHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 340)
MainFrame.Position = UDim2.new(0.5, -260, 0.5, -170)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundTransparency = 1
TopBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(0, 120, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Text = "Sab Hub"
Title.TextColor3 = Color3.fromRGB(240, 240, 245)
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0, 150, 1, 0)
SubTitle.Position = UDim2.new(0, 85, 0, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Font = Enum.Font.Gotham
SubTitle.Text = "v1.1"
SubTitle.TextColor3 = Color3.fromRGB(120, 120, 130)
SubTitle.TextSize = 11
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = TopBar

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 25, 0, 25)
MinBtn.Position = UDim2.new(1, -60, 0, 5)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "−"
MinBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TopBar

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TopBar

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, 160, 1, -45)
Sidebar.Position = UDim2.new(0, 10, 0, 40)
Sidebar.BackgroundTransparency = 1
Sidebar.BorderSizePixel = 0
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 200)
Sidebar.ScrollBarThickness = 2
Sidebar.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -180, 1, -45)
ContentArea.Position = UDim2.new(0, 175, 0, 40)
ContentArea.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
ContentArea.BorderSizePixel = 0
ContentArea.Parent = MainFrame

local ContentCorner = Instance.new("UICorner")
ContentCorner.CornerRadius = UDim.new(0, 8)
ContentCorner.Parent = ContentArea

local tabsPages = {}
local function createTabPage(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, -10, 1, -10)
    page.Position = UDim2.new(0, 5, 0, 5)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.CanvasSize = UDim2.new(0, 0, 0, 450)
    page.ScrollBarThickness = 3
    page.Visible = false
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page

    tabsPages[name] = page
    return page
end

local pageMain = createTabPage("Main")
local pageAim = createTabPage("Aim")
local pageWH = createTabPage("WallHack")
local pageRest = createTabPage("Rest")

local function createTabButton(name, order, pageObj)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -5, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.Font = Enum.Font.GothamMedium
    btn.Text = "   " .. name
    btn.TextColor3 = Color3.fromRGB(170, 170, 180)
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.LayoutOrder = order
    btn.Parent = Sidebar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(tabsPages) do p.Visible = false end
        for _, child in ipairs(Sidebar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
                child.TextColor3 = Color3.fromRGB(170, 170, 180)
            end
        end
        pageObj.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)
    return btn
end

createTabButton("Main", 1, pageMain)
createTabButton("Aim", 2, pageAim)
createTabButton("WallHack", 3, pageWH)
createTabButton("Rest", 4, pageRest)

pageMain.Visible = true
Sidebar:GetChildren()[2].BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Sidebar:GetChildren()[2].TextColor3 = Color3.fromRGB(255, 255, 255)

local isMinimized = false
MinBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        MainFrame.Size = UDim2.new(0, 520, 0, 35)
        MinBtn.Text = "+"
        Sidebar.Visible = false
        ContentArea.Visible = false
    else
        MainFrame.Size = UDim2.new(0, 520, 0, 340)
        MinBtn.Text = "−"
        Sidebar.Visible = true
        ContentArea.Visible = true
    end
end)

local dragging, dragInput, dragStart, startPos
TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

RunService.RenderStepped:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local function addToggle(parent, text, key, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 34)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local state = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 20)
    btn.Position = UDim2.new(1, -58, 0.5, -10)
    btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(45, 45, 55)
    btn.Text = state and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 10
    btn.Font = Enum.Font.GothamBold
    btn.Parent = frame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 4)
    btnCorner.Parent = btn

    btn.MouseButton1Click:Connect(function()
        state = not state
        cfg[key] = state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(45, 45, 55)
        btn.Text = state and "ON" or "OFF"
    end)
end

local function addSlider(parent, text, key, min, max, default)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 45)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    frame.BorderSizePixel = 0
    frame.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.Text = text .. ": " .. default
    label.TextColor3 = Color3.fromRGB(220, 220, 225)
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 28)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame

    local sCorner = Instance.new("UICorner")
    sCorner.CornerRadius = UDim.new(1, 0)
    sCorner.Parent = sliderBg

    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBg

    local fCorner = Instance.new("UICorner")
    fCorner.CornerRadius = UDim.new(1, 0)
    fCorner.Parent = sliderFill

    local draggingSlider = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local pos = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            sliderFill.Size = UDim2.new(pos, 0, 1, 0)
            local val = math.floor(min + (max - min) * pos)
            label.Text = text .. ": " .. val
            cfg[key] = val
        end
    end)
end

local function addButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -5, 0, 34)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Parent = parent

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    btn.MouseButton1Click:Connect(callback)
end

-- НАПОЛНЕНИЕ ВКЛАДОК
local mainTitle = Instance.new("TextLabel")
mainTitle.Size = UDim2.new(1, -5, 0, 25)
mainTitle.BackgroundTransparency = 1
mainTitle.Font = Enum.Font.GothamBold
mainTitle.Text = "By @sab1488"
mainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
mainTitle.TextSize = 14
mainTitle.TextXAlignment = Enum.TextXAlignment.Left
mainTitle.Parent = pageMain

local mainTele = Instance.new("TextLabel")
mainTele.Size = UDim2.new(1, -5, 0, 25)
mainTele.BackgroundTransparency = 1
mainTele.Font = Enum.Font.GothamBold
mainTele.Text = "Telegram channel: SabHubb"
mainTele.TextColor3 = Color3.fromRGB(0, 170, 255)
mainTele.TextSize = 13
mainTele.TextXAlignment = Enum.TextXAlignment.Left
mainTele.Parent = pageMain

-- Вкладка Aim
addToggle(pageAim, "Aimbot", "aimbotEnabled", false)
addToggle(pageAim, "Silent Aim", "silentAimEnabled", false)
addSlider(pageAim, "FOV Size", "FOV", 50, 400, 150)

-- Вкладка WallHack
addToggle(pageWH, "Enable ESP (Global)", "espEnabled", false)
addToggle(pageWH, "ESP Nicknames", "espNameEnabled", true)
addToggle(pageWH, "ESP Health Bar", "espHealthEnabled", true)
addToggle(pageWH, "ESP Distance", "espDistEnabled", true)
addToggle(pageWH, "Chams (Highlight)", "chamsEnabled", false)

-- Вкладка Rest (функционал движения, SpinBot, TeleportRandomPlayer и TeleKill)
addToggle(pageRest, "SpinBot", "spinEnabled", false)
addSlider(pageRest, "Spin Speed", "spinSpeed", 1, 30, 5)
addToggle(pageRest, "Third Person", "thirdPersonEnabled", false)
addToggle(pageRest, "BunnyHop", "bunnyHopEnabled", false)
addToggle(pageRest, "Infinite Jump", "infiniteJumpEnabled", true)

addButton(pageRest, "TeleportRandomPlayer", function()
    teleportRandomPlayer()
end)

addToggle(pageRest, "TeleKill", "teleKillEnabled", false)

print("✅ Sab Hub v1.1 полностью загружен и готов к использованию!")
