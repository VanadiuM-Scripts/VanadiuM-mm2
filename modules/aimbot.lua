local Aimbot = {}

Aimbot.Settings = {
    enabled = false,
    roleCheck = true,
    smoothness = 0,
    showFOV = false,
    fovRadius = 150,
}

Aimbot.Target = nil
Aimbot.FOV = nil
Aimbot.Connections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function hasDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
end

function Aimbot:GetRole(player)
    if not player then return "Unknown" end
    local char = player.Character
    local bag = player:FindFirstChild("Backpack")

    local function has(name)
        return (char and char:FindFirstChild(name)) or (bag and bag:FindFirstChild(name))
    end

    if has("Knife") then return "Murderer" end
    if has("Gun") then return "Sheriff" end
    return "Innocent"
end

function Aimbot:IsSameRole(player)
    local a = self:GetRole(LocalPlayer)
    local b = self:GetRole(player)
    return a ~= "Unknown" and a == b
end

function Aimbot:GetNearestTarget()
    local cam = workspace.CurrentCamera
    if not cam or not LocalPlayer.Character then return nil end

    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    local center = cam.ViewportSize / 2
    local best, bestDist = nil, self.Settings.fovRadius

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if self.Settings.roleCheck and self:IsSameRole(plr) then continue end

        local char = plr.Character
        if not char then continue end

        local th = char:FindFirstChildOfClass("Humanoid")
        local tr = char:FindFirstChild("HumanoidRootPart")
        if not th or not tr or th.Health <= 0 then continue end

        local sp, onScreen = cam:WorldToViewportPoint(tr.Position)
        if not onScreen or sp.Z <= 0 then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best = plr
        end
    end

    return best
end

function Aimbot:EnsureFOV()
    if not hasDrawing() then return end

    if not self.FOV or not isrenderobj or not isrenderobj(self.FOV) then
        local c = Drawing.new("Circle")
        c.Filled = false
        c.Thickness = 1.5
        c.NumSides = 64
        c.Color = Color3.fromRGB(255, 255, 255)
        c.Transparency = 0.6
        c.Visible = false
        self.FOV = c
    end
end

function Aimbot:UpdateFOV()
    self:EnsureFOV()
    if not self.FOV then return end

    local cam = workspace.CurrentCamera
    if not cam then
        self.FOV.Visible = false
        return
    end

    if self.Settings.showFOV and self.Settings.enabled then
        self.FOV.Position = cam.ViewportSize / 2
        self.FOV.Radius = self.Settings.fovRadius
        self.FOV.Visible = true
    else
        self.FOV.Visible = false
    end
end

function Aimbot:ClearFOV()
    if self.FOV then
        pcall(function() self.FOV:Destroy() end)
        self.FOV = nil
    end
end

function Aimbot:AimAt(hrp)
    local cam = workspace.CurrentCamera
    if not cam then return end

    local origin = cam.CFrame.Position
    local target = hrp.Position
    local look = (target - origin).Unit
    local goal = CFrame.new(origin, origin + look)

    local s = self.Settings.smoothness
    if s <= 0 then
        cam.CFrame = goal
    else
        local alpha = math.clamp(1 / math.max(s, 0.05), 0.05, 1)
        cam.CFrame = cam.CFrame:Lerp(goal, alpha)
    end
end

function Aimbot:Update()
    self:UpdateFOV()

    if not self.Settings.enabled then
        self.Target = nil
        return
    end

    local target = self:GetNearestTarget()
    self.Target = target

    if target and target.Character then
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            self:AimAt(hrp)
        end
    end
end

function Aimbot:Init()
    self:Destroy()

    self.Connections.render = RunService.RenderStepped:Connect(function()
        self:Update()
    end)
end

function Aimbot:Destroy()
    self:ClearFOV()
    self.Target = nil
    self.Settings.enabled = false

    for _, conn in pairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(self.Connections)
end

return Aimbot
