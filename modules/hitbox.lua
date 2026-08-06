local Hitbox = {}

Hitbox.Settings = {
    enabled = false,
    size = 2,
}

Hitbox.Store = {} -- [BasePart] = { originalSize, originalMassless }
Hitbox.Connections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local VALID = {
    HumanoidRootPart = true,
    Torso = true,
    UpperTorso = true,
}

function Hitbox:Parts(char)
    local out = {}
    if not char then return out end
    for name in pairs(VALID) do
        local p = char:FindFirstChild(name)
        if p and p:IsA("BasePart") then
            table.insert(out, p)
        end
    end
    return out
end

function Hitbox:Expand(part, mult)
    if not part or not part:IsA("BasePart") or not VALID[part.Name] then return end

    if not self.Store[part] then
        self.Store[part] = {
            originalSize = part.Size,
            originalMassless = part.Massless,
        }
    end

    local data = self.Store[part]
    local want = data.originalSize * math.max(1, mult)
    if part.Size ~= want then
        part.Size = want
        part.Massless = true
    end
end

function Hitbox:Reset(part)
    local data = self.Store[part]
    if data and part and part.Parent then
        part.Size = data.originalSize
        part.Massless = data.originalMassless
    end
    self.Store[part] = nil
end

function Hitbox:ResetAll()
    for part in pairs(self.Store) do
        self:Reset(part)
    end
    table.clear(self.Store)
end

function Hitbox:Apply()
    if not self.Settings.enabled then return end
    local mult = math.max(1, self.Settings.size)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        for _, part in ipairs(self:Parts(char)) do
            self:Expand(part, mult)
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

    if self.Connections[key] then
        self.Connections[key]:Disconnect()
    end

    self.Connections[key] = plr.CharacterAdded:Connect(function()
        task.wait(0.35)
        if self.Settings.enabled then
            self:Apply()
        end
    end)
end

function Hitbox:Init()
    self:Destroy()

    self.Connections.heartbeat = RunService.Heartbeat:Connect(function()
        if self.Settings.enabled then
            self:Apply()
        else
            self:ResetAll()
        end
    end)

    for _, plr in ipairs(Players:GetPlayers()) do
        self:HookPlayer(plr)
    end

    self.Connections.playerAdded = Players.PlayerAdded:Connect(function(plr)
        self:HookPlayer(plr)
    end)

    if self.Settings.enabled then
        self:Apply()
    end
end

function Hitbox:Destroy()
    self:ResetAll()
    self.Settings.enabled = false

    for _, conn in pairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(self.Connections)
end

return Hitbox
