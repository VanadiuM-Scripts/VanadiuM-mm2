local Hitbox = {}

Hitbox.Settings = {
    enabled = false,
    size = 50,
    showVisual = true,
    visualTransparency = 0.7,
    part = "HumanoidRootPart", -- HumanoidRootPart | Head | both
}

-- [BasePart] = original props
Hitbox.Originals = {}
Hitbox.Connections = {}
Hitbox.Drawings = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function hasDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
end

local function snapshot(part)
    if Hitbox.Originals[part] then return Hitbox.Originals[part] end
    local data = {
        Size = part.Size,
        Transparency = part.Transparency,
        CanCollide = part.CanCollide,
        Massless = part.Massless,
        Color = part.Color,
        Material = part.Material,
        BrickColor = part.BrickColor,
    }
    Hitbox.Originals[part] = data
    return data
end

local function restorePart(part)
    local data = Hitbox.Originals[part]
    if not data then return end
    if part and part.Parent then
        pcall(function()
            part.Size = data.Size
            part.Transparency = data.Transparency
            part.CanCollide = data.CanCollide
            part.Massless = data.Massless
            part.Color = data.Color
            part.Material = data.Material
            -- BrickColor if still valid
            pcall(function() part.BrickColor = data.BrickColor end)
        end)
    end
    Hitbox.Originals[part] = nil
end

function Hitbox:RestoreAll()
    local parts = {}
    for part in pairs(self.Originals) do
        table.insert(parts, part)
    end
    for _, part in ipairs(parts) do
        restorePart(part)
    end
    table.clear(self.Originals)
    self:ClearDrawings()
end

function Hitbox:ClearDrawings()
    for _, d in ipairs(self.Drawings) do
        pcall(function() d:Destroy() end)
    end
    table.clear(self.Drawings)
end

function Hitbox:DrawBox3D(part, color)
    if not hasDrawing() or not part or not part.Parent then return end
    local cam = workspace.CurrentCamera
    if not cam then return end

    local cf, size = part.CFrame, part.Size
    local half = size / 2
    local corners = {}
    for _, sx in ipairs({ -1, 1 }) do
        for _, sy in ipairs({ -1, 1 }) do
            for _, sz in ipairs({ -1, 1 }) do
                table.insert(corners, (cf * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position)
            end
        end
    end

    local sc = {}
    for i, w in ipairs(corners) do
        local sp, on = cam:WorldToViewportPoint(w)
        sc[i] = { Vector2.new(sp.X, sp.Y), on and sp.Z > 0 }
    end

    local edges = {
        {1,2},{3,4},{5,6},{7,8},
        {1,3},{2,4},{5,7},{6,8},
        {1,5},{2,6},{3,7},{4,8},
    }

    for _, e in ipairs(edges) do
        local a, b = sc[e[1]], sc[e[2]]
        if a and b and a[2] and b[2] then
            local line = Drawing.new("Line")
            line.From = a[1]
            line.To = b[1]
            line.Color = color
            line.Thickness = 1.5
            line.Transparency = 1
            line.Visible = true
            line.ZIndex = 4
            table.insert(self.Drawings, line)
        end
    end
end

local function getTargets(char, mode)
    local targets = {}
    if not char then return targets end
    if mode == "Head" then
        local h = char:FindFirstChild("Head")
        if h then table.insert(targets, h) end
    elseif mode == "both" then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")
        if hrp then table.insert(targets, hrp) end
        if head then table.insert(targets, head) end
    else
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then table.insert(targets, hrp) end
    end
    return targets
end

local function forcePart(part, size, showVisual, transparency)
    if not part or not part:IsA("BasePart") then return end
    snapshot(part)
    pcall(function()
        part.Size = Vector3.new(size, size, size)
        part.CanCollide = false
        -- do NOT set Massless = true — that contributes to client "freeze" feel
        if showVisual then
            part.Transparency = transparency
            part.BrickColor = BrickColor.new("Really blue")
            part.Material = Enum.Material.Neon
        end
    end)
end

function Hitbox:Apply()
    -- disabled → restore everything and stop
    if not self.Settings.enabled then
        if next(self.Originals) ~= nil then
            self:RestoreAll()
        else
            self:ClearDrawings()
        end
        return
    end

    local size = math.max(1, self.Settings.size)
    local show = self.Settings.showVisual
    local trans = self.Settings.visualTransparency
    local mode = self.Settings.part

    self:ClearDrawings()

    local alive = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end

        for _, part in ipairs(getTargets(char, mode)) do
            forcePart(part, size, show, trans)
            alive[part] = true
            if show then
                self:DrawBox3D(part, Color3.fromRGB(0, 120, 255))
            end
        end
    end

    -- restore parts that no longer exist / left range
    local toRestore = {}
    for part in pairs(self.Originals) do
        if not alive[part] or not part.Parent then
            table.insert(toRestore, part)
        end
    end
    for _, part in ipairs(toRestore) do
        restorePart(part)
    end
end

function Hitbox:Cleanup()
    self:RestoreAll()
    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        end
    end
    table.clear(self.Connections)
end

function Hitbox:Init()
    self:Cleanup() -- restores any leftover, clears connections

    self.Connections.render = RunService.RenderStepped:Connect(function()
        self:Apply()
    end)

    -- when someone respawns, drop stale originals for old character
    self.Connections.playerAdded = Players.PlayerAdded:Connect(function(plr)
        if plr == LocalPlayer then return end
        self.Connections["char_" .. plr.UserId] = plr.CharacterAdded:Connect(function()
            -- old parts become parentless → restored next Apply
        end)
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            self.Connections["char_" .. plr.UserId] = plr.CharacterAdded:Connect(function() end)
        end
    end
end

function Hitbox:Destroy()
    self.Settings.enabled = false
    self:Cleanup() -- full restore
end

return Hitbox
