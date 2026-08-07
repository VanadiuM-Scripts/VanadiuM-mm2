local Hitbox = {}

Hitbox.Settings = {
    enabled = false,
    size = 3,
    showVisual = true,
    visualTransparency = 0.65,
}

Hitbox.Store = {}
Hitbox.Drawings = {}
Hitbox.Connections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local VALID = {
    HumanoidRootPart = true,
    Torso = true,
    UpperTorso = true,
}

local function hasDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
end

function Hitbox:Parts(char)
    local out = {}
    if not char then return out end
    for name in pairs(VALID) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then table.insert(out, p) end
    end
    return out
end

function Hitbox:Expand(part, mult)
    if not part or not VALID[part.Name] then return end
    if not self.Store[part] then
        self.Store[part] = {
            originalSize = part.Size,
            originalMassless = part.Massless,
            originalTransparency = part.Transparency,
            originalCanCollide = part.CanCollide,
            originalColor = part.Color,
        }
    end
    local data = self.Store[part]
    local want = data.originalSize * math.max(1, mult)
    if part.Size ~= want then
        part.Size = want
        part.Massless = true
    end
    if self.Settings.showVisual then
        part.Transparency = self.Settings.visualTransparency
        part.Color = Color3.fromRGB(255, 80, 80)
        part.CanCollide = false
    end
end

function Hitbox:Reset(part)
    local data = self.Store[part]
    if data and part and part.Parent then
        part.Size = data.originalSize
        part.Massless = data.originalMassless
        part.Transparency = data.originalTransparency
        part.CanCollide = data.originalCanCollide
        if data.originalColor then part.Color = data.originalColor end
    end
    self.Store[part] = nil
end

function Hitbox:ResetAll()
    for part in pairs(self.Store) do self:Reset(part) end
    table.clear(self.Store)
end

function Hitbox:ClearDrawings()
    for _, d in ipairs(self.Drawings) do
        pcall(function() d:Destroy() end)
    end
    table.clear(self.Drawings)
end

function Hitbox:DrawBox3D(part, color)
    if not hasDrawing() or not part then return end
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

function Hitbox:Apply()
    if not self.Settings.enabled then return end
    local mult = math.max(1, self.Settings.size)
    self:ClearDrawings()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        for _, part in ipairs(self:Parts(char)) do
            self:Expand(part, mult)
            if self.Settings.showVisual then
                self:DrawBox3D(part, Color3.fromRGB(255, 60, 60))
            end
        end
    end
    for part in pairs(self.Store) do
        if not part.Parent or not part.Parent.Parent then
            self.Store[part] = nil
        end
    end
end

function Hitbox:HookPlayer(plr)
    if plr == LocalPlayer then return end
    local key = "char_" .. tostring(plr.UserId)
    if self.Connections[key] then self.Connections[key]:Disconnect() end
    self.Connections[key] = plr.CharacterAdded:Connect(function()
        task.wait(0.4)
        if self.Settings.enabled then self:Apply() end
    end)
end

function Hitbox:Init()
    self:Destroy()
    self.Connections.heartbeat = RunService.RenderStepped:Connect(function()
        if self.Settings.enabled then
            self:Apply()
        else
            self:ResetAll()
            self:ClearDrawings()
        end
    end)
    for _, plr in ipairs(Players:GetPlayers()) do self:HookPlayer(plr) end
    self.Connections.playerAdded = Players.PlayerAdded:Connect(function(plr)
        self:HookPlayer(plr)
    end)
end

function Hitbox:Destroy()
    self:ResetAll()
    self:ClearDrawings()
    self.Settings.enabled = false
    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(self.Connections)
end

return Hitbox
