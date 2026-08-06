local ESP = {}

ESP.Settings = {
    enabled = false,
    box = false,
    boxStyle = "2d", -- 2d, corner, 3d
    skeleton = false,
    tracer = false,
    role = false,
}

ESP.Objects = {}

function ESP:GetPlayers()
    local players = {}
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(players, player)
        end
    end
    return players
end

function ESP:GetHumanoidRootPart(player)
    if player and player.Character then
        return player.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

function ESP:GetHumanoid(player)
    if player and player.Character then
        return player.Character:FindFirstChild("Humanoid")
    end
    return nil
end

function ESP:GetRole(humanoid)
    if humanoid then
        local role = humanoid:FindFirstChild("Role")
        if role then
            return role.Value or "Innocent"
        end
        -- Если нет Role object, проверяем имя персонажа
        local charName = humanoid.Parent.Name:lower()
        if charName:find("sheriff") then
            return "Sheriff"
        elseif charName:find("innocent") then
            return "Innocent"
        elseif charName:find("murderer") or charName:find("murder") then
            return "Murderer"
        end
    end
    return "Unknown"
end

function ESP:GetPlayerColor(player, role)
    local roleColors = {
        ["Sheriff"] = Color3.fromRGB(255, 215, 0),
        ["Innocent"] = Color3.fromRGB(0, 255, 0),
        ["Murderer"] = Color3.fromRGB(255, 0, 0),
    }
    return roleColors[role] or Color3.fromRGB(255, 255, 255)
end

function ESP:GetScreenPosition(position)
    local camera = game.Workspace.CurrentCamera
    if not camera then
        return Vector2.new(0, 0), false
    end
    
    local pos = position
    if typeof(position) ~= "Vector3" then
        pos = position.Position
    end
    
    local screenPoint, onScreen = camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

function ESP:DrawBox2d(hrp, size, color, thickness)
    if not hrp then return end
    
    local screenPos, onScreen = ESP:GetScreenPosition(hrp.Position)
    if not onScreen then return end
    
    local camera = game.Workspace.CurrentCamera
    local size3d = size or Vector3.new(2, 5, 2)
    
    -- Вычисляем размер бокса на основе расстояния
    local distance = (camera.CFrame.Position - hrp.Position).Magnitude
    local scaleFactor = 1000 / distance
    
    local pixelWidth = size3d.X * scaleFactor
    local pixelHeight = size3d.Y * scaleFactor
    
    local x, y = screenPos.X, screenPos.Y
    
    -- Top line
    ESP:DrawLine(x - pixelWidth, y - pixelHeight, x + pixelWidth, y - pixelHeight, thickness, color)
    -- Bottom line
    ESP:DrawLine(x - pixelWidth, y + pixelHeight, x + pixelWidth, y + pixelHeight, thickness, color)
    -- Left line
    ESP:DrawLine(x - pixelWidth, y - pixelHeight, x - pixelWidth, y + pixelHeight, thickness, color)
    -- Right line
    ESP:DrawLine(x + pixelWidth, y - pixelHeight, x + pixelWidth, y + pixelHeight, thickness, color)
end

function ESP:DrawCornerBox(hrp, size, color, thickness)
    if not hrp then return end
    
    local screenPos, onScreen = ESP:GetScreenPosition(hrp.Position)
    if not onScreen then return end
    
    local camera = game.Workspace.CurrentCamera
    local size3d = size or Vector3.new(2, 5, 2)
    
    -- Вычисляем размер бокса на основе расстояния
    local distance = (camera.CFrame.Position - hrp.Position).Magnitude
    local scaleFactor = 1000 / distance
    
    local pixelWidth = size3d.X * scaleFactor
    local pixelHeight = size3d.Y * scaleFactor
    
    local x, y = screenPos.X, screenPos.Y
    local cornerSize = math.min(pixelWidth * 0.25, pixelHeight * 0.15)
    
    -- Top left corner
    ESP:DrawLine(x - pixelWidth, y - pixelHeight, x - pixelWidth + cornerSize, y - pixelHeight, thickness, color)
    ESP:DrawLine(x - pixelWidth, y - pixelHeight, x - pixelWidth, y - pixelHeight + cornerSize, thickness, color)
    -- Top right corner
    ESP:DrawLine(x + pixelWidth - cornerSize, y - pixelHeight, x + pixelWidth, y - pixelHeight, thickness, color)
    ESP:DrawLine(x + pixelWidth, y - pixelHeight, x + pixelWidth, y - pixelHeight + cornerSize, thickness, color)
    -- Bottom left corner
    ESP:DrawLine(x - pixelWidth, y + pixelHeight - cornerSize, x - pixelWidth, y + pixelHeight, thickness, color)
    ESP:DrawLine(x - pixelWidth, y + pixelHeight, x - pixelWidth + cornerSize, y + pixelHeight, thickness, color)
    -- Bottom right corner
    ESP:DrawLine(x + pixelWidth - cornerSize, y + pixelHeight, x + pixelWidth, y + pixelHeight, thickness, color)
    ESP:DrawLine(x + pixelWidth, y + pixelHeight - cornerSize, x + pixelWidth, y + pixelHeight, thickness, color)
end

function ESP:Draw3DBox(hrp, size, color)
    if not hrp then return end
    
    local screenPos, onScreen = ESP:GetScreenPosition(hrp.Position)
    if not onScreen then return end
    
    local camera = game.Workspace.CurrentCamera
    local size3d = size or Vector3.new(2, 5, 2)
    
    -- Вычисляем размер бокса на основе расстояния
    local distance = (camera.CFrame.Position - hrp.Position).Magnitude
    local scaleFactor = 1000 / distance
    
    local pixelWidth = size3d.X * scaleFactor
    local pixelHeight = size3d.Y * scaleFactor
    
    local x, y = screenPos.X, screenPos.Y
    
    -- Draw 8 corners of a 3D box
    local depthOffset = pixelWidth * 0.3
    local corners = {
        -- Front face
        {x - pixelWidth, y - pixelHeight},
        {x + pixelWidth, y - pixelHeight},
        {x + pixelWidth, y + pixelHeight},
        {x - pixelWidth, y + pixelHeight},
        -- Back face
        {x - pixelWidth + depthOffset, y - pixelHeight + depthOffset},
        {x + pixelWidth + depthOffset, y - pixelHeight + depthOffset},
        {x + pixelWidth + depthOffset, y + pixelHeight + depthOffset},
        {x - pixelWidth + depthOffset, y + pixelHeight + depthOffset},
    }
    
    -- Front face
    ESP:DrawLine(corners[1][1], corners[1][2], corners[2][1], corners[2][2], 2, color)
    ESP:DrawLine(corners[2][1], corners[2][2], corners[3][1], corners[3][2], 2, color)
    ESP:DrawLine(corners[3][1], corners[3][2], corners[4][1], corners[4][2], 2, color)
    ESP:DrawLine(corners[4][1], corners[4][2], corners[1][1], corners[1][2], 2, color)
    
    -- Back face
    ESP:DrawLine(corners[5][1], corners[5][2], corners[6][1], corners[6][2], 1, color)
    ESP:DrawLine(corners[6][1], corners[6][2], corners[7][1], corners[7][2], 1, color)
    ESP:DrawLine(corners[7][1], corners[7][2], corners[8][1], corners[8][2], 1, color)
    ESP:DrawLine(corners[8][1], corners[8][2], corners[5][1], corners[5][2], 1, color)
    
    -- Connecting lines
    ESP:DrawLine(corners[1][1], corners[1][2], corners[5][1], corners[5][2], 1, color)
    ESP:DrawLine(corners[2][1], corners[2][2], corners[6][1], corners[6][2], 1, color)
    ESP:DrawLine(corners[3][1], corners[3][2], corners[7][1], corners[7][2], 1, color)
    ESP:DrawLine(corners[4][1], corners[4][2], corners[8][1], corners[8][2], 1, color)
end

function ESP:DrawLine(x1, y1, x2, y2, thickness, color)
    local parent = ESP:GetUIParent()
    if not parent then return end
    
    local Line = Instance.new("Frame")
    Line.AnchorPoint = Vector2.new(0.5, 0.5)
    Line.BackgroundColor3 = color
    Line.BorderSizePixel = 0
    Line.ZIndex = 10
    Line.Parent = parent
    
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    
    if length > 0 then
        Line.Size = UDim2.new(0, length, 0, thickness)
        Line.Position = UDim2.new(0, (x1 + x2) / 2, 0, (y1 + y2) / 2)
        Line.Rotation = math.deg(math.atan2(dy, dx))
    else
        Line.Size = UDim2.new(0, 1, 0, thickness)
        Line.Position = UDim2.new(0, x1, 0, y1)
        Line.Rotation = 0
    end
    
    table.insert(ESP.Objects, Line)
    
    return Line
end

function ESP:DrawTracer(hrp, color)
    if not hrp then return end
    
    local screenPos, onScreen = ESP:GetScreenPosition(hrp.Position)
    if not onScreen then return end
    
    local camera = game.Workspace.CurrentCamera
    if not camera then return end
    
    local viewportSize = camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y)
    
    ESP:DrawLine(screenCenter.X, screenCenter.Y, screenPos.X, screenPos.Y, 2, color)
end

function ESP:DrawRoleText(hrp, role, color)
    if not hrp then return end
    
    local screenPos, onScreen = ESP:GetScreenPosition(hrp.Position)
    if not onScreen then return end
    
    local parent = ESP:GetUIParent()
    if not parent then return end
    
    local camera = game.Workspace.CurrentCamera
    local distance = (camera.CFrame.Position - hrp.Position).Magnitude
    local scaleFactor = 1000 / distance
    
    local Text = Instance.new("TextLabel")
    Text.AnchorPoint = Vector2.new(0.5, 0)
    Text.Text = role
    Text.TextColor3 = color
    Text.TextSize = math.clamp(scaleFactor * 0.8, 12, 18)
    Text.Font = Enum.Font.SourceSansBold
    Text.TextStrokeTransparency = 0.5
    Text.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Text.BackgroundTransparency = 1
    Text.Size = UDim2.new(0, 100, 0, 20)
    Text.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y + scaleFactor * 1.5)
    Text.ZIndex = 10
    Text.Parent = parent
    table.insert(ESP.Objects, Text)
    
    return Text
end

function ESP:GetUIParent()
    local localPlayer = game:GetService("Players").LocalPlayer
    if not localPlayer then return nil end
    
    local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
    if not playerGui then
        playerGui = localPlayer:WaitForChild("PlayerGui", 5)
    end
    
    if not playerGui then return nil end
    
    local espGui = playerGui:FindFirstChild("VanadiuM_ESP")
    if not espGui then
        espGui = Instance.new("ScreenGui")
        espGui.Name = "VanadiuM_ESP"
        espGui.ResetOnSpawn = false
        espGui.IgnoreGuiInset = true
        espGui.Parent = playerGui
    end
    
    return espGui
end

function ESP:Update()
    -- Clear old objects
    for _, obj in ipairs(ESP.Objects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    ESP.Objects = {}
    
    if not ESP.Settings.enabled then return end
    
    local players = ESP:GetPlayers()
    
    for _, player in ipairs(players) do
        local hrp = ESP:GetHumanoidRootPart(player)
        local humanoid = ESP:GetHumanoid(player)
        
        if hrp and humanoid and humanoid.Health > 0 then
            local role = ESP:GetRole(humanoid)
            local color = ESP:GetPlayerColor(player, role)
            
            -- Draw box
            if ESP.Settings.box then
                if ESP.Settings.boxStyle == "corner" then
                    ESP:DrawCornerBox(hrp, nil, color, 2)
                elseif ESP.Settings.boxStyle == "3d" then
                    ESP:Draw3DBox(hrp, nil, color)
                else
                    ESP:DrawBox2d(hrp, nil, color, 2)
                end
            end
            
            -- Draw skeleton
            if ESP.Settings.skeleton then
                ESP:DrawSkeleton(hrp, color)
            end
            
            -- Draw tracer
            if ESP.Settings.tracer then
                ESP:DrawTracer(hrp, color)
            end
            
            -- Draw role
            if ESP.Settings.role then
                ESP:DrawRoleText(hrp, role, color)
            end
        end
    end
end

function ESP:DrawSkeleton(hrp, color)
    local char = hrp.Parent
    if not char then return end
    
    -- Get body parts (supports both R6 and R15)
    local head = char:FindFirstChild("Head")
    local leftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm") or char:FindFirstChild("LeftArm")
    local rightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm") or char:FindFirstChild("RightArm")
    local leftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftLeg")
    local rightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg") or char:FindFirstChild("RightLeg")
    local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local lowerTorso = char:FindFirstChild("LowerTorso")
    
    if not torso then return end
    
    local function drawBone(part1, part2)
        if part1 and part2 and part1:IsA("BasePart") and part2:IsA("BasePart") then
            local pos1, onScreen1 = ESP:GetScreenPosition(part1.Position)
            local pos2, onScreen2 = ESP:GetScreenPosition(part2.Position)
            
            if onScreen1 and onScreen2 then
                ESP:DrawLine(pos1.X, pos1.Y, pos2.X, pos2.Y, 1, color)
            end
        end
    end
    
    -- Connect body parts
    if head and torso then
        drawBone(head, torso)
    end
    
    if leftArm and torso then
        drawBone(torso, leftArm)
        local leftLowerArm = char:FindFirstChild("LeftLowerArm") or char:FindFirstChild("LeftHand")
        if leftLowerArm then drawBone(leftArm, leftLowerArm) end
    end
    
    if rightArm and torso then
        drawBone(torso, rightArm)
        local rightLowerArm = char:FindFirstChild("RightLowerArm") or char:FindFirstChild("RightHand")
        if rightLowerArm then drawBone(rightArm, rightLowerArm) end
    end
    
    -- Connect torso to lower body (R15)
    if lowerTorso then
        drawBone(torso, lowerTorso)
        if leftLeg then
            drawBone(lowerTorso, leftLeg)
        end
        if rightLeg then
            drawBone(lowerTorso, rightLeg)
        end
    else
        -- R6 style
        if leftLeg and torso then
            drawBone(torso, leftLeg)
        end
        if rightLeg and torso then
            drawBone(torso, rightLeg)
        end
    end
    
    -- Connect legs to feet
    if leftLeg then
        local leftLowerLeg = char:FindFirstChild("LeftLowerLeg") or char:FindFirstChild("LeftFoot")
        if leftLowerLeg then drawBone(leftLeg, leftLowerLeg) end
    end
    
    if rightLeg then
        local rightLowerLeg = char:FindFirstChild("RightLowerLeg") or char:FindFirstChild("RightFoot")
        if rightLowerLeg then drawBone(rightLeg, rightLowerLeg) end
    end
end

ESP.Connections = {}

function ESP:Init()
    -- Запускаем цикл обновления
    if self.Connections.update then
        self.Connections.update:Disconnect()
    end
    
    self.Connections.update = game:GetService("RunService").RenderStepped:Connect(function()
        self:Update()
    end)
end

function ESP:Destroy()
    -- Clear all objects
    for _, obj in ipairs(self.Objects) do
        if obj and obj.Parent then
            obj:Destroy()
        end
    end
    self.Objects = {}
    
    -- Disconnect update loop
    if self.Connections.update then
        self.Connections.update:Disconnect()
    end
    self.Connections = {}
end

return ESP
