local Aimbot = {}

Aimbot.Settings = {
    enabled = false,
    teamCheck = true,
    smoothness = 0,
    showFOV = false,
    fovRadius = 150,
}

Aimbot.Target = nil
Aimbot.FieldOfView = nil
Aimbot.Connections = {}

function Aimbot:GetPlayers()
    local players = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(players, player)
        end
    end
    return players
end

function Aimbot:GetHumanoidRootPart(player)
    if player and player.Character then
        return player.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

function Aimbot:GetHumanoid(player)
    if player and player.Character then
        return player.Character:FindFirstChild("Humanoid")
    end
    return nil
end

function Aimbot:IsTeammate(player)
    local localPlayer = game.Players.LocalPlayer
    if localPlayer and player then
        return localPlayer.Team == player.Team
    end
    return false
end

function Aimbot:GetNearestTarget()
    local players = self:GetPlayers()
    local nearestPlayer = nil
    local nearestDist = math.huge
    local fovRadius = self.Settings.fovRadius
    
    local camera = game.Workspace.CurrentCamera
    local localPlayer = game.Players.LocalPlayer
    
    if not camera or not localPlayer or not localPlayer.Character then
        return nil
    end
    
    local character = localPlayer.Character
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not hrp then return nil end
    
    local mouseLocation = game:GetService("UserInputService"):GetMouseLocation()
    local viewportSize = camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    
    for _, player in ipairs(players) do
        if self.Settings.teamCheck and self:IsTeammate(player) then
            continue
        end
        
        local targetHrp = self:GetHumanoidRootPart(player)
        local targetHumanoid = self:GetHumanoid(player)
        
        if not targetHrp or not targetHumanoid or targetHumanoid.Health <= 0 then 
            continue 
        end
        
        local screenPos, onScreen = camera:WorldToViewportPoint(targetHrp.Position)
        
        if onScreen then
            local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
            local distanceFromCenter = (screenPos2D - screenCenter).Magnitude
            
            if distanceFromCenter <= fovRadius and distanceFromCenter < nearestDist then
                nearestDist = distanceFromCenter
                nearestPlayer = player
            end
        end
    end
    
    return nearestPlayer
end

function Aimbot:GetFOVLinePosition(hrp, radius)
    -- Эта функция больше не нужна для новой реализации FOV
    return nil
end

function Aimbot:DrawFOV()
    if not self.Settings.showFOV then
        self:ClearFOV()
        return
    end
    
    -- Очистка старых объектов
    if self.FieldOfView and self.FieldOfView.Parent then
        self.FieldOfView:Destroy()
    end
    
    local camera = game.Workspace.CurrentCamera
    local localPlayer = game.Players.LocalPlayer
    
    if not camera or not localPlayer then
        return
    end
    
    local radius = self.Settings.fovRadius
    
    -- Создаем круг на экране для визуализации FOV
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return end
    
    local fovGui = playerGui:FindFirstChild("AimbotFOVGui")
    if not fovGui then
        fovGui = Instance.new("ScreenGui")
        fovGui.Name = "AimbotFOVGui"
        fovGui.ResetOnSpawn = false
        fovGui.IgnoreGuiInset = true
        fovGui.Parent = playerGui
    end
    
    local circle = Instance.new("Frame")
    circle.Name = "FOVCircle"
    circle.AnchorPoint = Vector2.new(0.5, 0.5)
    circle.BackgroundTransparency = 1
    circle.Size = UDim2.new(0, radius * 2, 0, radius * 2)
    circle.Position = UDim2.new(0.5, 0, 0.5, 0)
    circle.ZIndex = 1
    circle.Parent = fovGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = circle
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = circle
    
    self.FieldOfView = fovGui
end

function Aimbot:ClearFOV()
    if self.FieldOfView and self.FieldOfView.Parent then
        self.FieldOfView:Destroy()
    end
    self.FieldOfView = nil
end

function Aimbot:AutoAim()
    if not self.Settings.enabled then
        return
    end
    
    local target = self:GetNearestTarget()
    self.Target = target
    
    if target then
        local hrp = self:GetHumanoidRootPart(target)
        if hrp then
            self:SmoothAimToTarget(hrp)
        end
    end
end

function Aimbot:SmoothAimToTarget(targetHrp)
    local smoothness = self.Settings.smoothness
    if smoothness <= 0 then 
        -- Мгновенная наводка
        smoothness = 1
    end
    
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return end
    
    local character = localPlayer.Character
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local camera = game.Workspace.CurrentCamera
    
    if not hrp or not camera then return end
    
    local targetPos = targetHrp.Position
    local cameraPos = camera.CFrame.Position
    
    -- Вычисляем направление к цели
    local lookVector = (targetPos - cameraPos).Unit
    
    -- Создаем CFrame направленный на цель
    local targetCFrame = CFrame.new(cameraPos, cameraPos + lookVector)
    
    -- Применяем сглаживание
    local currentCFrame = camera.CFrame
    local alpha = math.clamp(1 / math.max(smoothness, 0.1), 0.01, 1)
    
    local newCFrame = currentCFrame:Lerp(targetCFrame, alpha)
    camera.CFrame = newCFrame
end

function Aimbot:Update()
    if self.Settings.enabled then
        self:AutoAim()
    else
        self.Target = nil
    end
    
    self:DrawFOV()
end

function Aimbot:Init()
    -- Запускаем цикл обновления
    if self.Connections.update then
        self.Connections.update:Disconnect()
    end
    
    self.Connections.update = game:GetService("RunService").RenderStepped:Connect(function()
        self:Update()
    end)
end

function Aimbot:Destroy()
    self:ClearFOV()
    
    for _, conn in ipairs(self.Connections) do
        if conn then
            conn:Disconnect()
        end
    end
    
    self.Connections = {}
end

return Aimbot
