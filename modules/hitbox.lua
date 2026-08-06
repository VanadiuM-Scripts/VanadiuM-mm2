local Hitbox = {}

Hitbox.Settings = {
    enabled = false,
    size = 1,
}

Hitbox.ExpandedParts = {}
Hitbox.Connections = {}

function Hitbox:GetPlayerParts(player)
    local parts = {}
    if player and player.Character then
        -- Получаем только основные хитбоксы
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        local torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
        
        if hrp then
            table.insert(parts, hrp)
        end
        if torso and torso ~= hrp then
            table.insert(parts, torso)
        end
    end
    return parts
end

function Hitbox:ExpandPart(part, sizeMultiplier)
    if not part or not part:IsA("BasePart") then return end
    
    -- Проверяем, что часть - это хитбокс (HumanoidRootPart или Torso)
    if part.Name ~= "HumanoidRootPart" and part.Name ~= "Torso" and part.Name ~= "UpperTorso" then
        return nil
    end
    
    local originalSize = part.Size
    local originalTransparency = part.Transparency
    local originalCanCollide = part.CanCollide
    
    -- Увеличиваем размер хитбокса
    part.Size = originalSize * sizeMultiplier
    part.Transparency = 0.5  -- Делаем полупрозрачным для отладки
    part.CanCollide = true
    
    -- Сохраняем оригинальные значения
    return {
        part = part,
        originalSize = originalSize,
        originalTransparency = originalTransparency,
        originalCanCollide = originalCanCollide,
    }
end

function Hitbox:ResetPart(partData)
    if partData and partData.part and partData.part.Parent then
        local part = partData.part
        part.Size = partData.originalSize
        part.Transparency = partData.originalTransparency
        part.CanCollide = partData.originalCanCollide
    end
end

function Hitbox:ApplyHitboxExpansion()
    if not self.Settings.enabled then
        self:ResetAll()
        return
    end
    
    local sizeMultiplier = self.Settings.size
    
    -- Проходим по всем игрокам
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            -- Проверяем, жив ли игрок
            if humanoid and humanoid.Health > 0 then
                local parts = self:GetPlayerParts(player)
                
                for _, part in ipairs(parts) do
                    -- Проверяем, не был ли уже расширен этот хитбокс
                    local alreadyExpanded = false
                    for _, data in ipairs(self.ExpandedParts) do
                        if data.part == part then
                            alreadyExpanded = true
                            break
                        end
                    end
                    
                    if not alreadyExpanded then
                        local expansionData = self:ExpandPart(part, sizeMultiplier)
                        if expansionData then
                            table.insert(self.ExpandedParts, expansionData)
                        end
                    end
                end
            end
        end
    end
end

function Hitbox:ResetAll()
    for _, data in ipairs(self.ExpandedParts) do
        self:ResetPart(data)
    end
    self.ExpandedParts = {}
end

function Hitbox:Update()
    self:ApplyHitboxExpansion()
end

function Hitbox:Init()
    -- Запускаем цикл обновления
    if self.Connections.update then
        self.Connections.update:Disconnect()
    end
    
    -- Слушаем добавление новых персонажей
    if self.Connections.playerAdded then
        self.Connections.playerAdded:Disconnect()
    end
    
    self.Connections.update = game:GetService("RunService").Heartbeat:Connect(function()
        self:Update()
    end)
    
    -- Обрабатываем новых игроков
    self.Connections.playerAdded = game:GetService("Players").PlayerAdded:Connect(function(player)
        if player ~= game.Players.LocalPlayer then
            player.CharacterAdded:Connect(function()
                task.wait(0.5) -- Даем время на загрузку персонажа
                self:ApplyHitboxExpansion()
            end)
        end
    end)
end

function Hitbox:Destroy()
    self:ResetAll()
    
    for _, conn in ipairs(self.Connections) do
        if conn then
            conn:Disconnect()
        end
    end
    
    self.Connections = {}
end

return Hitbox
