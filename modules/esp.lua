local ESP = {}

ESP.Settings = {
    enabled = false,
    box = false,
    boxStyle = "2d",
    skeleton = false,
    tracer = false,
    role = false,
    coins = false,
    gun = false,
}

ESP.Drawings = {}
ESP.Connections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local ROLE_COLOR = {
    Murderer = Color3.fromRGB(255, 50, 50),
    Sheriff  = Color3.fromRGB(255, 210, 40),
    Innocent = Color3.fromRGB(70, 255, 90),
    Unknown  = Color3.fromRGB(200, 200, 200),
    Coin     = Color3.fromRGB(255, 220, 60),
    Gun      = Color3.fromRGB(100, 180, 255),
}

local function hasDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
end

function ESP:GetRole(player)
    if not player then return "Unknown" end
    local char, bag = player.Character, player:FindFirstChild("Backpack")
    local function has(n)
        return (char and char:FindFirstChild(n)) or (bag and bag:FindFirstChild(n))
    end
    if has("Knife") then return "Murderer" end
    if has("Gun") then return "Sheriff" end
    return "Innocent"
end

function ESP:WorldToScreen(v3)
    local cam = workspace.CurrentCamera
    if not cam then return Vector2.zero, false end
    local sp, on = cam:WorldToViewportPoint(v3)
    return Vector2.new(sp.X, sp.Y), on and sp.Z > 0
end

function ESP:Line(a, b, color, thick)
    if not hasDrawing() then return end
    local l = Drawing.new("Line")
    l.From, l.To = a, b
    l.Color = color
    l.Thickness = thick or 1.5
    l.Transparency = 1
    l.Visible = true
    l.ZIndex = 2
    table.insert(self.Drawings, l)
end

function ESP:Label(text, pos, color, size)
    if not hasDrawing() then return end
    local t = Drawing.new("Text")
    t.Text = text
    t.Position = pos
    t.Color = color
    t.Size = size or 14
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.new(0, 0, 0)
    t.Font = (Drawing.Fonts and Drawing.Fonts.UI) or 0
    t.Transparency = 1
    t.Visible = true
    t.ZIndex = 3
    table.insert(self.Drawings, t)
end

function ESP:Clear()
    for _, d in ipairs(self.Drawings) do
        pcall(function() d:Destroy() end)
    end
    table.clear(self.Drawings)
end

-- Only real body parts (ignore Knife/Gun/tools/accessories)
local BODY_PARTS = {
    -- no HumanoidRootPart (hitbox expander blows it up)
    -- no tools / accessories
    "Head", "Torso", "UpperTorso", "LowerTorso",
    "Left Arm", "Right Arm", "Left Leg", "Right Leg",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

function ESP:GetCharacterBounds(char)
    local points = {}
    for _, name in ipairs(BODY_PARTS) do
        local part = char:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            local cf, size = part.CFrame, part.Size
            local half = size * 0.5
            for _, sx in ipairs({ -1, 1 }) do
                for _, sy in ipairs({ -1, 1 }) do
                    for _, sz in ipairs({ -1, 1 }) do
                        table.insert(points, (cf * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position)
                    end
                end
            end
        end
    end

    if #points == 0 then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return nil end
        local half = Vector3.new(2, 3, 1)
        local cf = hrp.CFrame
        for _, sx in ipairs({ -1, 1 }) do
            for _, sy in ipairs({ -1, 1 }) do
                for _, sz in ipairs({ -1, 1 }) do
                    table.insert(points, (cf * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position)
                end
            end
        end
    end

    -- world AABB from body points only
    local minV = Vector3.new(math.huge, math.huge, math.huge)
    local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, p in ipairs(points) do
        minV = Vector3.new(math.min(minV.X, p.X), math.min(minV.Y, p.Y), math.min(minV.Z, p.Z))
        maxV = Vector3.new(math.max(maxV.X, p.X), math.max(maxV.Y, p.Y), math.max(maxV.Z, p.Z))
    end

    local center = (minV + maxV) * 0.5
    local size = maxV - minV
    -- clamp absurd sizes (safety)
    size = Vector3.new(
        math.clamp(size.X, 1, 8),
        math.clamp(size.Y, 1, 10),
        math.clamp(size.Z, 1, 8)
    )
    local cf = CFrame.new(center)
    local half = size * 0.5
    local corners = {}
    for _, sx in ipairs({ -1, 1 }) do
        for _, sy in ipairs({ -1, 1 }) do
            for _, sz in ipairs({ -1, 1 }) do
                table.insert(corners, (cf * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position)
            end
        end
    end
    return corners, cf, size
end

function ESP:ProjectBounds(corners)
    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local any = false

    for _, world in ipairs(corners) do
        local sp, on = self:WorldToScreen(world)
        if on then
            any = true
            minX = math.min(minX, sp.X)
            minY = math.min(minY, sp.Y)
            maxX = math.max(maxX, sp.X)
            maxY = math.max(maxY, sp.Y)
        end
    end

    if not any then return nil end
    return { minX = minX, minY = minY, maxX = maxX, maxY = maxY }
end

function ESP:Box2D(bounds, color)
    local x1, y1, x2, y2 = bounds.minX, bounds.minY, bounds.maxX, bounds.maxY
    self:Line(Vector2.new(x1, y1), Vector2.new(x2, y1), color)
    self:Line(Vector2.new(x2, y1), Vector2.new(x2, y2), color)
    self:Line(Vector2.new(x2, y2), Vector2.new(x1, y2), color)
    self:Line(Vector2.new(x1, y2), Vector2.new(x1, y1), color)
end

function ESP:BoxCorner(bounds, color)
    local x1, y1, x2, y2 = bounds.minX, bounds.minY, bounds.maxX, bounds.maxY
    local w, h = x2 - x1, y2 - y1
    local c = math.min(w, h) * 0.25

    self:Line(Vector2.new(x1, y1), Vector2.new(x1 + c, y1), color)
    self:Line(Vector2.new(x1, y1), Vector2.new(x1, y1 + c), color)
    self:Line(Vector2.new(x2 - c, y1), Vector2.new(x2, y1), color)
    self:Line(Vector2.new(x2, y1), Vector2.new(x2, y1 + c), color)
    self:Line(Vector2.new(x1, y2 - c), Vector2.new(x1, y2), color)
    self:Line(Vector2.new(x1, y2), Vector2.new(x1 + c, y2), color)
    self:Line(Vector2.new(x2 - c, y2), Vector2.new(x2, y2), color)
    self:Line(Vector2.new(x2, y2 - c), Vector2.new(x2, y2), color)
end

function ESP:Box3D(corners, color)
    local e = {
        {1,2},{3,4},{5,6},{7,8},
        {1,3},{2,4},{5,7},{6,8},
        {1,5},{2,6},{3,7},{4,8},
    }
    local sc = {}
    for i, world in ipairs(corners) do
        local sp, on = self:WorldToScreen(world)
        sc[i] = { sp, on }
    end
    for _, pair in ipairs(e) do
        local a, b = sc[pair[1]], sc[pair[2]]
        if a and b and a[2] and b[2] then
            self:Line(a[1], b[1], color, 1.2)
        end
    end
end

function ESP:Tracer(hrp, color)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, on = self:WorldToScreen(hrp.Position)
    if not on then return end
    self:Line(Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y), sp, color, 1.5)
end

function ESP:Skeleton(char, color)
    local function part(...)
        for _, n in ipairs({ ... }) do
            local p = char:FindFirstChild(n)
            if p and p:IsA("BasePart") then return p end
        end
    end
    local function bone(a, b)
        if not a or not b then return end
        local p1, o1 = self:WorldToScreen(a.Position)
        local p2, o2 = self:WorldToScreen(b.Position)
        if o1 and o2 then self:Line(p1, p2, color, 1.2) end
    end

    local head = part("Head")
    local upper = part("UpperTorso", "Torso")
    local lower = part("LowerTorso")
    local lua_ = part("LeftUpperArm", "Left Arm")
    local rua = part("RightUpperArm", "Right Arm")
    local lla = part("LeftLowerArm")
    local rla = part("RightLowerArm")
    local lh = part("LeftHand")
    local rh = part("RightHand")
    local lul = part("LeftUpperLeg", "Left Leg")
    local rul = part("RightUpperLeg", "Right Leg")
    local lll = part("LeftLowerLeg")
    local rll = part("RightLowerLeg")
    local lf = part("LeftFoot")
    local rf = part("RightFoot")

    bone(head, upper)
    bone(upper, lower)
    bone(upper, lua_); bone(lua_, lla); bone(lla or lua_, lh)
    bone(upper, rua); bone(rua, rla); bone(rla or rua, rh)
    local hip = lower or upper
    bone(hip, lul); bone(lul, lll); bone(lll or lul, lf)
    bone(hip, rul); bone(rul, rll); bone(rll or rul, rf)
end

function ESP:DrawWorldItem(part, label, color)
    if not part or not part:IsA("BasePart") then return end
    local sp, on = self:WorldToScreen(part.Position)
    if not on then return end
    local cam = workspace.CurrentCamera
    local dist = (cam.CFrame.Position - part.Position).Magnitude
    local s = math.clamp(400 / dist, 4, 20)
    self:Line(Vector2.new(sp.X - s, sp.Y - s), Vector2.new(sp.X + s, sp.Y - s), color, 1.5)
    self:Line(Vector2.new(sp.X + s, sp.Y - s), Vector2.new(sp.X + s, sp.Y + s), color, 1.5)
    self:Line(Vector2.new(sp.X + s, sp.Y + s), Vector2.new(sp.X - s, sp.Y + s), color, 1.5)
    self:Line(Vector2.new(sp.X - s, sp.Y + s), Vector2.new(sp.X - s, sp.Y - s), color, 1.5)
    if label then
        self:Label(label, Vector2.new(sp.X, sp.Y - s - 12), color, 13)
    end
end

function ESP:ScanCoinsAndGun()
    if not (self.Settings.coins or self.Settings.gun) then return end

    for _, obj in ipairs(workspace:GetDescendants()) do
        if not obj:IsA("BasePart") then continue end
        local n = string.lower(obj.Name)

        if self.Settings.coins and (n:find("coin") or n:find("gold")) then
            if obj.Transparency < 1 and obj.Size.Magnitude < 15 then
                self:DrawWorldItem(obj, "Coin", ROLE_COLOR.Coin)
            end
        end

        if self.Settings.gun and (n == "gun" or n:find("gun_drop") or n:find("gunpickup")) then
            self:DrawWorldItem(obj, "Gun", ROLE_COLOR.Gun)
        end
    end
end

function ESP:Update()
    self:Clear()
    if not self.Settings.enabled then return end
    if not hasDrawing() then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        local role = self:GetRole(plr)
        local color = ROLE_COLOR[role] or ROLE_COLOR.Unknown
        local corners = self:GetCharacterBounds(char)

        if corners and self.Settings.box then
            if self.Settings.boxStyle == "3d" then
                self:Box3D(corners, color)
            else
                local bounds = self:ProjectBounds(corners)
                if bounds then
                    if self.Settings.boxStyle == "corner" then
                        self:BoxCorner(bounds, color)
                    else
                        self:Box2D(bounds, color)
                    end
                end
            end
        end

        if self.Settings.skeleton then self:Skeleton(char, color) end
        if self.Settings.tracer then self:Tracer(hrp, color) end
        if self.Settings.role then
            local sp, on = self:WorldToScreen(hrp.Position + Vector3.new(0, 3, 0))
            if on then self:Label(role, sp, color, 14) end
        end
    end

    self:ScanCoinsAndGun()
end

function ESP:Init()
    self:Destroy()
    self.Connections.render = RunService.RenderStepped:Connect(function()
        self:Update()
    end)
end

function ESP:Destroy()
    self:Clear()
    self.Settings.enabled = false
    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(self.Connections)
end

return ESP
