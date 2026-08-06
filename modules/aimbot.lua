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
    local mouse = localPlayer:FindFirstChild("PlayerScript") and localPlayer:FindFirstChild("PlayerScript"):FindFirstChild("Mouse") or localPlayer:GetMouse()
    
    local localPos = hrp and hrp.Position or camera.CFrame.Position
    local lookDir = camera.CFrame.LookVector
    
    for _, player in ipairs(players) do
        if self.Settings.teamCheck and self:IsTeammate(player) then
            continue
        end
        
        local hrp = self:GetHumanoidRootPart(player)
        if not hrp then continue end
        
        local playerPos = hrp.Position
        local toPlayer = playerPos - localPos
        local dist = toPlayer.Magnitude
        
        -- Проверка в пределах FOV радиуса
        if dist <= fovRadius then
            local normalizedDir = toPlayer.Unit
            local dotProduct = normalizedDir:Dot(lookDir)
            
            -- Угол в радианах
            local angle = math.acos(dotProduct) * 180 / math.pi
            
            -- Проверка в пределах угла (примерно 45 градусов по центру)
            if angle <= 45 then
                if dist < nearestDist then
                    nearestDist = dist
                    nearestPlayer = player
                end
            end
        end
    end
    
    return nearestPlayer
end

function Aimbot:GetFOVLinePosition(hrp, radius)
    local camera = game.Workspace.CurrentCamera
    local localPlayer = game.Players.LocalPlayer
    
    if not camera or not localPlayer or not localPlayer.Character then
        return nil
    end
    
    local character = localPlayer.Character
    local hrpLocal = character:FindFirstChild("HumanoidRootPart")
    local localPos = hrpLocal and hrpLocal.Position or camera.CFrame.Position
    local lookDir = camera.CFrame.LookVector
    
    local playerPos = hrp.Position
    local toPlayer = playerPos - localPos
    local dist = toPlayer.Magnitude
    local normalizedDir = toPlayer.Unit
    
    -- Точка на поверхности FOV сферы
    local fovPos = localPos + lookDir * radius
    return fovPos
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
    
    if not camera or not localPlayer or not localPlayer.Character then
        return
    end
    
    local radius = self.Settings.fovRadius
    
    -- Создаем прозрачную сферу для визуализации FOV
    local sphere = Instance.new("Part")
    sphere.Name = "AimbotFOV"
    sphere.Anchored = true
    sphere.CanCollide = false
    sphere.Transparency = 0.8
    sphere.Shape = "Ball"
    sphere.Size = Vector3.new(radius * 2, radius * 2, radius * 2)
    sphere.Color = Color3.fromRGB(255, 255, 0)
    sphere.Material = "Neon"
    
    local character = localPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if hrp then
        sphere.CFrame = CFrame.new(hrp.Position)
        sphere.Parent = game.Workspace
        self.FieldOfView = sphere
    end
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
    if smoothness <= 0 then return end
    
    local localPlayer = game.Players.LocalPlayer
    if not localPlayer or not localPlayer.Character then return end
    
    local character = localPlayer.Character
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local camera = game.Workspace.CurrentCamera
    
    if not hrp or not camera then return end
    
    local targetPos = targetHrp.Position
    local localPos = hrp.Position
    
    -- Вычисляем угол к цели
    local lookVector = (targetPos - localPos).Unit
    
    -- Поворачиваем камеру (псевдо-авто-наводка через camera.CFrame)
    -- В реальной реализации нужен Raycast или нативный hook
    local lookAtCFrame = CFrame.new(localPos, targetPos)
    
    -- Применяем сглаживание
    local currentCFrame = camera.CFrame
    local goalCFrame = lookAtCFrame * CFrame.Angles(0, 0, 0)
    
    local interpolatedCFrame = currentCFrame:Lerp(goalCFrame, math.clamp(smoothness / 10, 0.01, 1))
    camera.CFrame = interpolatedCFrame
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
