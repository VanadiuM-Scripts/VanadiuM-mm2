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
        for _, child in ipairs(player.Character:GetChildren()) do
            if child:IsA("BasePart") then
                table.insert(parts, child)
            end
        end
    end
    return parts
end

function Hitbox:ExpandPart(part, sizeMultiplier)
    if not part then return end
    
    local originalSize = part.Size
    local newSize = originalSize * sizeMultiplier
    
    -- Сохраняем оригинальный размер и CFrame для возврата
    part:SetNetworkOwner(nil)
    part.Size = newSize
    
    return {
        part = part,
        originalSize = originalSize,
        originalCFrame = part.CFrame,
    }
end

function Hitbox:ResetPart(partData)
    if partData and partData.part then
        local part = partData.part
        part.Size = partData.originalSize
        part.CFrame = partData.originalCFrame
        part:SetNetworkOwner(game.Players.LocalPlayer)
    end
end

function Hitbox:ApplyHitboxExpansion()
    if not self.Settings.enabled then
        self:ResetAll()
        return
    end
    
    local sizeMultiplier = self.Settings.size
    
    -- Очищаем старые данные
    self:ResetAll()
    
    -- Проходим по всем игрокам
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character then
            local parts = self:GetPlayerParts(player)
            
            for _, part in ipairs(parts) do
                local expansionData = self:ExpandPart(part, sizeMultiplier)
                if expansionData then
                    table.insert(self.ExpandedParts, expansionData)
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
    
    self.Connections.update = game:GetService("RunService").RenderStepped:Connect(function()
        self:Update()
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
