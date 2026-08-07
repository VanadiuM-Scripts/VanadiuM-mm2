local Hitbox = {}

Hitbox.Settings = {
    enabled = false,
    size = 50,
    showVisual = true,
    visualTransparency = 0.7,
    part = "HumanoidRootPart",
}

Hitbox.Connections = {}
Hitbox.Drawings = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function hasDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
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

local function forcePart(part, size, showVisual, transparency)
    if not part or not part:IsA("BasePart") then return end
    pcall(function()
        part.Size = Vector3.new(size, size, size)
        part.CanCollide = false
        part.Massless = true
        if showVisual then
            part.Transparency = transparency
            part.BrickColor = BrickColor.new("Really blue")
            part.Material = Enum.Material.Neon
        end
    end)
end

function Hitbox:Apply()
    if not self.Settings.enabled then
        self:ClearDrawings()
        return
    end

    local size = math.max(1, self.Settings.size)
    local show = self.Settings.showVisual
    local trans = self.Settings.visualTransparency
    local mode = self.Settings.part

    self:ClearDrawings()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end

        local targets = {}
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

        for _, part in ipairs(targets) do
            forcePart(part, size, show, trans)
            if show then
                self:DrawBox3D(part, Color3.fromRGB(0, 120, 255))
            end
        end
    end
end

function Hitbox:Cleanup()
    self:ClearDrawings()
    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        end
    end
    table.clear(self.Connections)
end

function Hitbox:Init()
    self:Cleanup() -- do NOT set enabled = false
    self.Connections.render = RunService.RenderStepped:Connect(function()
        self:Apply()
    end)
end

function Hitbox:Destroy()
    self.Settings.enabled = false
    self:Cleanup()
end

return Hitbox
