-- Sabb Edition v1.0 – с вкладками Main/Info, закруглённые кнопки
print("Загрузка Sabb v1.0...")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local CoreGui = game:GetService("CoreGui")

-- ===== НАСТРОЙКИ =====
local espEnabled = false
local aimbotEnabled = false
local spinEnabled = false
local thirdPersonEnabled = false
local silentAimEnabled = false
local bunnyHopEnabled = false
local chamsEnabled = false
local FOV = 150
local spinSpeed = 5
local thirdPersonDistance = 8
local thirdPersonHeight = 3
local bhopSpeed = 28
local spinAngle = 0

-- ===== CHAMS =====
local chamsHighlights = {}
local function createChams(player)
    if chamsHighlights[player] then return end
    local char = player.Character
    if not char then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "ChamsHighlight"
    highlight.Adornee = char
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.FillTransparency = 0.3
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = chamsEnabled
    highlight.Parent = char
    chamsHighlights[player] = highlight
end
local function removeChams(player)
    if chamsHighlights[player] then chamsHighlights[player]:Destroy() end
    chamsHighlights[player] = nil
end
local function updateChams()
    if not chamsEnabled then
        for p, _ in pairs(chamsHighlights) do removeChams(p) end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then
            if chamsHighlights[player] then removeChams(player) end
            continue
        end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            if chamsHighlights[player] then removeChams(player) end
            continue
        end
        if not chamsHighlights[player] then createChams(player)
        else chamsHighlights[player].Enabled = true
        end
    end
    for p, _ in pairs(chamsHighlights) do if not p.Parent then removeChams(p) end end
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        if chamsEnabled then createChams(player) end
    end)
end)

-- ===== ESP =====
local espLabels = {}
local function createESP(player)
    if espLabels[player] then return end
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head") or hrp
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 80)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = head
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = player.TeamColor and player.TeamColor.Color or Color3.new(1, 0, 0)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = billboard
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(0, 80, 0, 6)
    healthBar.Position = UDim2.new(0.5, -40, 0.6, 0)
    healthBar.BackgroundColor3 = Color3.new(0, 1, 0)
    healthBar.BackgroundTransparency = 0.3
    healthBar.Parent = billboard
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distLabel.Position = UDim2.new(0, 0, 0.7, 0)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = ""
    distLabel.TextColor3 = Color3.new(1, 1, 0)
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = billboard
    espLabels[player] = { billboard = billboard, name = nameLabel, health = healthBar, dist = distLabel }
end
local function removeESP(player)
    if espLabels[player] then espLabels[player].billboard:Destroy() end
    espLabels[player] = nil
end
local function updateESP()
    if not espEnabled then
        for p, _ in pairs(espLabels) do removeESP(p) end
        return
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then
            if espLabels[player] then removeESP(player) end
            continue
        end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then
            if espLabels[player] then removeESP(player) end
            continue
        end
        if not espLabels[player] then createESP(player) end
        if espLabels[player] then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (Camera.CFrame.Position - hrp.Position).Magnitude
                espLabels[player].dist.Text = string.format("%.0fm", dist)
            end
            local color = player.TeamColor and player.TeamColor.Color or Color3.new(1, 0, 0)
            espLabels[player].name.TextColor3 = color
            local healthPercent = hum.Health / hum.MaxHealth
            local healthBar = espLabels[player].health
            healthBar.Size = UDim2.new(healthPercent, 0, 0, 6)
            healthBar.BackgroundColor3 = healthPercent > 0.5 and Color3.new(0, 1, 0) or (healthPercent > 0.25 and Color3.new(1, 1, 0) or Color3.new(1, 0, 0))
        end
    end
    for p, _ in pairs(espLabels) do if not p.Parent then removeESP(p) end end
end
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.3)
        if espEnabled then createESP(player) end
    end)
end)

-- ===== АИМБОТ =====
local function getClosestTarget()
    local closest, minDist = nil, FOV
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then continue end
        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
        if dist < minDist then minDist = dist; closest = hrp end
    end
    return closest
end

-- ===== SPIN =====
local function doSpin()
    if not spinEnabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    spinAngle = spinAngle + math.rad(spinSpeed)
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, spinAngle, 0)
end

-- ===== КАМЕРА =====
local function updateCamera()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local targetPoint = nil
    if aimbotEnabled then
        local target = getClosestTarget()
        if target then targetPoint = target.Position end
    end
    if thirdPersonEnabled then
        local lookDir = (targetPoint and (targetPoint - hrp.Position).Unit) or hrp.CFrame.LookVector
        if lookDir.Magnitude < 0.1 then lookDir = Vector3.new(0, 0, -1) end
        local camPos = hrp.Position - lookDir * thirdPersonDistance + Vector3.new(0, thirdPersonHeight, 0)
        local lookTarget = targetPoint or (hrp.Position + Vector3.new(0, 1.5, 0))
        Camera.CFrame = CFrame.new(camPos, lookTarget)
    else
        if aimbotEnabled and targetPoint then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetPoint)
        end
    end
end

-- ===== SILENT AIM =====
local function doSilentAim()
    if not silentAimEnabled then return end
    local target = getClosestTarget()
    if target then Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position) end
end
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if silentAimEnabled then doSilentAim() end
    end
end)

-- ===== BUNNYHOP =====
local function doBunnyHop()
    if not bunnyHopEnabled then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not hrp then return end
    local state = humanoid:GetState()
    if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait(0.05)
    end
    if state == Enum.HumanoidStateType.Jumping or state == Enum.HumanoidStateType.Freefall then
        local vel = hrp.AssemblyLinearVelocity
        local horizontal = Vector3.new(vel.X, 0, vel.Z)
        if horizontal.Magnitude < bhopSpeed then
            local dir = horizontal.Unit
            if dir.Magnitude < 0.1 then
                dir = Camera.CFrame.LookVector
                dir = Vector3.new(dir.X, 0, dir.Z).Unit
            end
            hrp.AssemblyLinearVelocity = Vector3.new(dir.X * bhopSpeed, vel.Y, dir.Z * bhopSpeed)
        end
    end
end
UserInputService.JumpRequest:Connect(function()
    if bunnyHopEnabled then
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        if not humanoid then return end
        local state = humanoid:GetState()
        if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ===== ОСНОВНОЙ ЦИКЛ =====
RunService.RenderStepped:Connect(function()
    updateESP()
    updateChams()
    doSpin()
    updateCamera()
    doBunnyHop()
end)

-- ===== GUI с вкладками =====
local gui = Instance.new("ScreenGui")
gui.Name = "SabbGUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 200, 0, 460)
mainFrame.Position = UDim2.new(0, 10, 0, 10)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 1
mainFrame.BorderColor3 = Color3.fromRGB(60, 60, 80)
mainFrame.Parent = gui
mainFrame.ClipsDescendants = true

-- Закругление главной панели
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 25)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -60, 1, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "Sabb Hub"
title.TextColor3 = Color3.fromRGB(200, 200, 220)
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 25, 0, 25)
minBtn.Position = UDim2.new(1, -55, 0, 0)
minBtn.BackgroundTransparency = 1
minBtn.Text = "−"
minBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
minBtn.TextSize = 18
minBtn.Font = Enum.Font.GothamBold
minBtn.AutoButtonColor = false
minBtn.Parent = titleBar
local isMinimized = false
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    mainFrame.Size = isMinimized and UDim2.new(0, 200, 0, 25) or UDim2.new(0, 200, 0, 460)
    minBtn.Text = isMinimized and "+" or "−"
    for _, child in ipairs(mainFrame:GetChildren()) do
        if child ~= titleBar then
            child.Visible = not isMinimized
        end
    end
end)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 0)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.TextSize = 14
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

-- Перетаскивание
local dragging = false
local dragStart = nil
local frameStart = nil
titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = mainFrame.Position
    end
end)
titleBar.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            frameStart.X.Scale,
            frameStart.X.Offset + delta.X,
            frameStart.Y.Scale,
            frameStart.Y.Offset + delta.Y
        )
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        dragStart = nil
        frameStart = nil
    end
end)

-- Вкладки
local tabsFrame = Instance.new("Frame")
tabsFrame.Size = UDim2.new(1, 0, 0, 25)
tabsFrame.Position = UDim2.new(0, 0, 0, 25)
tabsFrame.BackgroundTransparency = 1
tabsFrame.Parent = mainFrame

local mainTab = Instance.new("TextButton")
mainTab.Size = UDim2.new(0.5, -2, 1, 0)
mainTab.Position = UDim2.new(0, 0, 0, 0)
mainTab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
mainTab.BackgroundTransparency = 0.2
mainTab.Text = "Main"
mainTab.TextColor3 = Color3.new(1, 1, 1)
mainTab.TextSize = 14
mainTab.Font = Enum.Font.GothamSemibold
mainTab.AutoButtonColor = false
mainTab.Parent = tabsFrame
local mainTabCorner = Instance.new("UICorner")
mainTabCorner.CornerRadius = UDim.new(0, 6)
mainTabCorner.Parent = mainTab

local infoTab = Instance.new("TextButton")
infoTab.Size = UDim2.new(0.5, -2, 1, 0)
infoTab.Position = UDim2.new(0.5, 2, 0, 0)
infoTab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
infoTab.BackgroundTransparency = 0.2
infoTab.Text = "Info"
infoTab.TextColor3 = Color3.new(1, 1, 1)
infoTab.TextSize = 14
infoTab.Font = Enum.Font.GothamSemibold
infoTab.AutoButtonColor = false
infoTab.Parent = tabsFrame
local infoTabCorner = Instance.new("UICorner")
infoTabCorner.CornerRadius = UDim.new(0, 6)
infoTabCorner.Parent = infoTab

-- Контейнер Main
local mainContent = Instance.new("Frame")
mainContent.Size = UDim2.new(1, 0, 1, -50)
mainContent.Position = UDim2.new(0, 0, 0, 50)
mainContent.BackgroundTransparency = 1
mainContent.Parent = mainFrame

-- Контейнер Info
local infoContent = Instance.new("Frame")
infoContent.Size = UDim2.new(1, 0, 1, -50)
infoContent.Position = UDim2.new(0, 0, 0, 50)
infoContent.BackgroundTransparency = 1
infoContent.Visible = false
infoContent.Parent = mainFrame

-- Заполнение Info (обновлено)
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 1, 0)
infoLabel.BackgroundTransparency = 1
infoLabel.Font = Enum.Font.Gotham
infoLabel.Text = "Sabb Hub v1.0\nby @sab1488\nTelegram channel: @sabhubb"
infoLabel.TextColor3 = Color3.fromRGB(180, 180, 200)
infoLabel.TextSize = 14
infoLabel.TextXAlignment = Enum.TextXAlignment.Center
infoLabel.TextYAlignment = Enum.TextYAlignment.Top
infoLabel.Parent = infoContent

-- Переключение вкладок
mainTab.MouseButton1Click:Connect(function()
    mainContent.Visible = true
    infoContent.Visible = false
    mainTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    infoTab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
end)

infoTab.MouseButton1Click:Connect(function()
    mainContent.Visible = false
    infoContent.Visible = true
    infoTab.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    mainTab.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
end)

-- Main Content
local content = mainContent

-- Функция создания кнопок
local function createButton(text, y, initColor, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 180, 0, 28)
    btn.Position = UDim2.new(0.5, -90, 0, y)
    btn.BackgroundColor3 = initColor
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamSemibold
    btn.AutoButtonColor = false
    btn.Parent = content
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    return btn
end

-- ESP
local espBtn = createButton("ESP: OFF", 3, Color3.fromRGB(180, 50, 50), function(btn)
    espEnabled = not espEnabled
    btn.Text = espEnabled and "ESP: ON" or "ESP: OFF"
    btn.BackgroundColor3 = espEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(180, 50, 50)
    if not espEnabled then for p,_ in pairs(espLabels) do removeESP(p) end else for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then createESP(p) end end end
end)

-- Aimbot
local aimBtn = createButton("Aimbot: OFF", 35, Color3.fromRGB(200, 80, 80), function(btn)
    aimbotEnabled = not aimbotEnabled
    btn.Text = aimbotEnabled and "Aimbot: ON" or "Aimbot: OFF"
    btn.BackgroundColor3 = aimbotEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(200, 80, 80)
end)

-- Spin
local spinBtn = createButton("Spin: OFF", 67, Color3.fromRGB(200, 180, 80), function(btn)
    spinEnabled = not spinEnabled
    btn.Text = spinEnabled and "Spin: ON" or "Spin: OFF"
    btn.BackgroundColor3 = spinEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(200, 180, 80)
end)

-- 3rd Person
local thirdBtn = createButton("3rd Person: OFF", 99, Color3.fromRGB(80, 150, 200), function(btn)
    thirdPersonEnabled = not thirdPersonEnabled
    btn.Text = thirdPersonEnabled and "3rd: ON" or "3rd: OFF"
    btn.BackgroundColor3 = thirdPersonEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(80, 150, 200)
end)

-- Silent Aim
local silentBtn = createButton("Silent Aim: OFF", 131, Color3.fromRGB(200, 100, 200), function(btn)
    silentAimEnabled = not silentAimEnabled
    btn.Text = silentAimEnabled and "Silent Aim: ON" or "Silent Aim: OFF"
    btn.BackgroundColor3 = silentAimEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(200, 100, 200)
end)

-- BunnyHop
local bhopBtn = createButton("BunnyHop: OFF", 163, Color3.fromRGB(255, 200, 0), function(btn)
    bunnyHopEnabled = not bunnyHopEnabled
    btn.Text = bunnyHopEnabled and "BunnyHop: ON" or "BunnyHop: OFF"
    btn.BackgroundColor3 = bunnyHopEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(255, 200, 0)
end)

-- Chams
local chamsBtn = createButton("Chams: OFF", 195, Color3.fromRGB(200, 100, 255), function(btn)
    chamsEnabled = not chamsEnabled
    btn.Text = chamsEnabled and "Chams: ON" or "Chams: OFF"
    btn.BackgroundColor3 = chamsEnabled and Color3.fromRGB(0, 180, 80) or Color3.fromRGB(200, 100, 255)
    if not chamsEnabled then for p,_ in pairs(chamsHighlights) do removeChams(p) end else for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then createChams(p) end end end
end)

-- FOV
local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0, 80, 0, 20)
fovLabel.Position = UDim2.new(0.5, -80, 0, 233)
fovLabel.BackgroundTransparency = 1
fovLabel.Font = Enum.Font.GothamSemibold
fovLabel.Text = "FOV: " .. FOV
fovLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
fovLabel.TextSize = 13
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Parent = content

local fovMinus = Instance.new("TextButton")
fovMinus.Size = UDim2.new(0, 30, 0, 24)
fovMinus.Position = UDim2.new(0.5, 10, 0, 258)
fovMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
fovMinus.Text = "−"
fovMinus.TextColor3 = Color3.new(1, 1, 1)
fovMinus.TextSize = 16
fovMinus.Font = Enum.Font.GothamBold
fovMinus.AutoButtonColor = false
fovMinus.Parent = content
local fovMinusCorner = Instance.new("UICorner")
fovMinusCorner.CornerRadius = UDim.new(0, 6)
fovMinusCorner.Parent = fovMinus
fovMinus.MouseButton1Click:Connect(function()
    FOV = math.max(20, FOV - 10)
    fovLabel.Text = "FOV: " .. FOV
end)

local fovPlus = Instance.new("TextButton")
fovPlus.Size = UDim2.new(0, 30, 0, 24)
fovPlus.Position = UDim2.new(0.5, 50, 0, 258)
fovPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
fovPlus.Text = "+"
fovPlus.TextColor3 = Color3.new(1, 1, 1)
fovPlus.TextSize = 16
fovPlus.Font = Enum.Font.GothamBold
fovPlus.AutoButtonColor = false
fovPlus.Parent = content
local fovPlusCorner = Instance.new("UICorner")
fovPlusCorner.CornerRadius = UDim.new(0, 6)
fovPlusCorner.Parent = fovPlus
fovPlus.MouseButton1Click:Connect(function()
    FOV = math.min(300, FOV + 10)
    fovLabel.Text = "FOV: " .. FOV
end)

-- Spin Speed
local spinLabel = Instance.new("TextLabel")
spinLabel.Size = UDim2.new(0, 100, 0, 20)
spinLabel.Position = UDim2.new(0.5, -90, 0, 292)
spinLabel.BackgroundTransparency = 1
spinLabel.Font = Enum.Font.GothamSemibold
spinLabel.Text = "Spin Speed: " .. spinSpeed
spinLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
spinLabel.TextSize = 13
spinLabel.TextXAlignment = Enum.TextXAlignment.Left
spinLabel.Parent = content

local spinMinus = Instance.new("TextButton")
spinMinus.Size = UDim2.new(0, 30, 0, 24)
spinMinus.Position = UDim2.new(0.5, 30, 0, 317)
spinMinus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
spinMinus.Text = "−"
spinMinus.TextColor3 = Color3.new(1, 1, 1)
spinMinus.TextSize = 16
spinMinus.Font = Enum.Font.GothamBold
spinMinus.AutoButtonColor = false
spinMinus.Parent = content
local spinMinusCorner = Instance.new("UICorner")
spinMinusCorner.CornerRadius = UDim.new(0, 6)
spinMinusCorner.Parent = spinMinus
spinMinus.MouseButton1Click:Connect(function()
    spinSpeed = math.max(1, spinSpeed - 1)
    spinLabel.Text = "Spin Speed: " .. spinSpeed
end)

local spinPlus = Instance.new("TextButton")
spinPlus.Size = UDim2.new(0, 30, 0, 24)
spinPlus.Position = UDim2.new(0.5, 70, 0, 317)
spinPlus.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
spinPlus.Text = "+"
spinPlus.TextColor3 = Color3.new(1, 1, 1)
spinPlus.TextSize = 16
spinPlus.Font = Enum.Font.GothamBold
spinPlus.AutoButtonColor = false
spinPlus.Parent = content
local spinPlusCorner = Instance.new("UICorner")
spinPlusCorner.CornerRadius = UDim.new(0, 6)
spinPlusCorner.Parent = spinPlus
spinPlus.MouseButton1Click:Connect(function()
    spinSpeed = math.min(20, spinSpeed + 1)
    spinLabel.Text = "Spin Speed: " .. spinSpeed
end)

-- Версия
local ver = Instance.new("TextLabel")
ver.Size = UDim2.new(1, 0, 0, 15)
ver.Position = UDim2.new(0, 0, 1, -17)
ver.BackgroundTransparency = 1
ver.Font = Enum.Font.Gotham
ver.Text = "v1.0"
ver.TextColor3 = Color3.fromRGB(100, 100, 120)
ver.TextSize = 10
ver.TextXAlignment = Enum.TextXAlignment.Right
ver.Parent = content

print("✅ Sabb v1.0 загружен! Вкладки, закругление, всё работает.")
