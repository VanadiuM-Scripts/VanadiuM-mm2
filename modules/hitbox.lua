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
    local originalMassless = part.Massless
    
    -- Увеличиваем размер хитбокса
    part.Size = originalSize * sizeMultiplier
    part.Massless = true  -- Чтобы не влияло на физику
    
    -- Сохраняем оригинальные значения
    return {
        part = part,
        originalSize = originalSize,
        originalTransparency = originalTransparency,
        originalCanCollide = originalCanCollide,
        originalMassless = originalMassless,
    }
end

function Hitbox:ResetPart(partData)
    if partData and partData.part and partData.part.Parent then
        local part = partData.part
        part.Size = partData.originalSize
        part.Transparency = partData.originalTransparency
        part.CanCollide = partData.originalCanCollide
        if partData.originalMassless ~= nil then
            part.Massless = partData.originalMassless
        end
    end
end

function Hitbox:ApplyHitboxExpansion()
    if not self.Settings.enabled then
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
                            -- Обновляем размер если он изменился
                            if data.part.Size ~= data.originalSize * sizeMultiplier then
                                data.part.Size = data.originalSize * sizeMultiplier
                            end
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
    
    -- Очищаем хитбоксы мертвых игроков или тех, кто вышел
    for i = #self.ExpandedParts, 1, -1 do
        local data = self.ExpandedParts[i]
        if not data.part or not data.part.Parent or not data.part.Parent.Parent then
            -- Часть была удалена (игрок умер или вышел)
            table.remove(self.ExpandedParts, i)
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
    if self.Settings.enabled then
        self:ApplyHitboxExpansion()
    else
        self:ResetAll()
    end
end

function Hitbox:Init()
    print("[Hitbox] Initializing...")
    
    -- Запускаем цикл обновления
    if self.Connections.update then
        self.Connections.update:Disconnect()
    end
    
    -- Слушаем добавление новых персонажей
    if self.Connections.playerAdded then
        self.Connections.playerAdded:Disconnect()
    end
    
    if self.Connections.characterAdded then
        for _, conn in pairs(self.Connections.characterAdded) do
            conn:Disconnect()
        end
    end
    self.Connections.characterAdded = {}
    
    -- Heartbeat для постоянного обновления
    self.Connections.update = game:GetService("RunService").Heartbeat:Connect(function()
        self:Update()
    end)
    
    -- Обрабатываем новых игроков
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer then
            self.Connections.characterAdded[player.UserId] = player.CharacterAdded:Connect(function(character)
                task.wait(0.5) -- Даем время на загрузку персонажа
                if self.Settings.enabled then
                    self:ApplyHitboxExpansion()
                end
            end)
        end
    end
    
    -- Слушаем новых подключающихся игроков
    self.Connections.playerAdded = game:GetService("Players").PlayerAdded:Connect(function(player)
        if player ~= game.Players.LocalPlayer then
            self.Connections.characterAdded[player.UserId] = player.CharacterAdded:Connect(function(character)
                task.wait(0.5)
                if self.Settings.enabled then
                    self:ApplyHitboxExpansion()
                end
            end)
        end
    end)
    
    -- Применяем к текущим игрокам
    if self.Settings.enabled then
        self:ApplyHitboxExpansion()
    end
    
    print("[Hitbox] Initialized successfully")
end

function Hitbox:Destroy()
    print("[Hitbox] Destroying...")
    
    self:ResetAll()
    
    for _, conn in pairs(self.Connections) do
        if type(conn) == "table" then
            -- Это таблица characterAdded connections
            for _, subConn in pairs(conn) do
                if subConn and subConn.Disconnect then
                    subConn:Disconnect()
                end
            end
        elseif conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    
    self.Connections = {}
    
    print("[Hitbox] Destroyed successfully")
end

return Hitbox
