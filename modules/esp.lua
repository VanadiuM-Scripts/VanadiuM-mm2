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

function ESP:GetScreenPosition(part)
    local screenPoint, onScreen = game.Workspace.CurrentCamera:WorldToViewportPoint(part.Position)
    return Vector2.new(screenPoint.X, screenPoint.Y), onScreen
end

function ESP:DrawBox2d(position, size, color, thickness)
    local screenPos, onScreen = ESP:GetScreenPosition(position)
    if not onScreen then return end
    
    local camera = game.Workspace.CurrentCamera
    local size3d = size or Vector3.new(2, 4, 2)
    local height = size3d.Y * 2
    local width = size3d.X * 2
    
    -- Примерная конвертация 3D размера в 2D пиксели
    local pixelWidth = width * 0.5
    local pixelHeight = height * 0.5
    
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

function ESP:DrawCornerBox(position, size, color, thickness)
    local screenPos, onScreen = ESP:GetScreenPosition(position)
    if not onScreen then return end
    
    local camera = game.Workspace.CurrentCamera
    local size3d = size or Vector3.new(2, 4, 2)
    local height = size3d.Y * 2
    local width = size3d.X * 2
    
    local pixelWidth = width * 0.5
    local pixelHeight = height * 0.5
    
    local x, y = screenPos.X, screenPos.Y
    local cornerSize = pixelWidth * 0.3
    
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

function ESP:Draw3DBox(position, size, color)
    local screenPos, onScreen = ESP:GetScreenPosition(position)
    if not onScreen then return end
    
    local camera = game.Workspace.CurrentCamera
    local size3d = size or Vector3.new(2, 4, 2)
    local height = size3d.Y * 2
    local width = size3d.X * 2
    
    local pixelWidth = width * 0.5
    local pixelHeight = height * 0.5
    
    local x, y = screenPos.X, screenPos.Y
    
    -- Draw 8 corners of a 3D box
    local corners = {
        {x - pixelWidth, y - pixelHeight},
        {x + pixelWidth, y - pixelHeight},
        {x + pixelWidth, y + pixelHeight},
        {x - pixelWidth, y + pixelHeight},
        {x - pixelWidth * 0.7, y - pixelHeight * 0.8}, -- Top back
        {x + pixelWidth * 0.7, y - pixelHeight * 0.8},
        {x + pixelWidth * 0.7, y + pixelHeight * 0.8},
        {x - pixelWidth * 0.7, y + pixelHeight * 0.8},
    }
    
    -- Front face
    ESP:DrawLine(corners[1][1], corners[1][2], corners[2][1], corners[2][2], 1, color)
    ESP:DrawLine(corners[2][1], corners[2][2], corners[3][1], corners[3][2], 1, color)
    ESP:DrawLine(corners[3][1], corners[3][2], corners[4][1], corners[4][2], 1, color)
    ESP:DrawLine(corners[4][1], corners[4][2], corners[1][1], corners[1][2], 1, color)
    
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
    local Line = Instance.new("Frame")
    Line.AnchorPoint = Vector2.new(0.5, 0.5)
    Line.BackgroundColor3 = color
    Line.BorderSizePixel = 0
    Line.Parent = ESP:GetUIParent()
    
    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    
    if length > 0 then
        Line.Size = UDim2.new(0, length, 0, thickness)
        Line.Position = UDim2.new(0, x1, 0, y1)
        Line.Rotation = math.atan2(dy, dx) * 180 / math.pi
    else
        Line.Size = UDim2.new(0, 1, 0, thickness)
        Line.Position = UDim2.new(0, x1, 0, y1)
        Line.Rotation = 0
    end
    
    table.insert(ESP.Objects, Line)
    
    return Line
end

function ESP:DrawTracer(position, color)
    local screenPos, onScreen = ESP:GetScreenPosition(position)
    if not onScreen then return end
    
    local screenCenter = Vector2.new(
        game.Workspace.CurrentCamera.ViewportSize.X / 2,
        game.Workspace.CurrentCamera.ViewportSize.Y / 2
    )
    
    ESP:DrawLine(screenCenter.X, screenCenter.Y, screenPos.X, screenPos.Y, 1, color)
end

function ESP:DrawRoleText(position, role, color)
    local screenPos, onScreen = ESP:GetScreenPosition(position)
    if not onScreen then return end
    
    local Text = Instance.new("TextLabel")
    Text.AnchorPoint = Vector2.new(0.5, 0.5)
    Text.Text = role
    Text.TextColor3 = color
    Text.TextSize = 14
    Text.BackgroundTransparency = 1
    Text.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y + 30)
    Text.Parent = ESP:GetUIParent()
    table.insert(ESP.Objects, Text)
    
    return Text
end

function ESP:GetUIParent()
    local parent = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui")
    if not parent then
        parent = Instance.new("ScreenGui")
        parent.Name = "VanadiuM_ESP"
        parent.ResetOnSpawn = false
        parent.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    end
    return parent
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
                    ESP:DrawCornerBox(hrp, nil, color, 1)
                elseif ESP.Settings.boxStyle == "3d" then
                    ESP:Draw3DBox(hrp, nil, color)
                else
                    ESP:DrawBox2d(hrp, nil, color, 1)
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
    
    -- Get body parts
    local head = char:FindFirstChild("Head")
    local leftArm = char:FindFirstChild("LeftArm")
    local rightArm = char:FindFirstChild("RightArm")
    local leftLeg = char:FindFirstChild("LeftLeg")
    local rightLeg = char:FindFirstChild("RightLeg")
    local torso = char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso")
    
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
    if head then
        drawBone(head, torso)
    end
    
    if leftArm then
        drawBone(torso, leftArm)
        local leftHand = char:FindFirstChild("LeftHand")
        if leftHand then drawBone(leftArm, leftHand) end
    end
    
    if rightArm then
        drawBone(torso, rightArm)
        local rightHand = char:FindFirstChild("RightHand")
        if rightHand then drawBone(rightArm, rightHand) end
    end
    
    if leftLeg then
        drawBone(torso, leftLeg)
        local leftFoot = char:FindFirstChild("LeftFoot")
        if leftFoot then drawBone(leftLeg, leftFoot) end
    end
    
    if rightLeg then
        drawBone(torso, rightLeg)
        local rightFoot = char:FindFirstChild("RightFoot")
        if rightFoot then drawBone(rightLeg, rightFoot) end
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
