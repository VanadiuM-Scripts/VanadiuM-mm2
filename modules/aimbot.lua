local Aimbot = {}

Aimbot.Settings = {
    enabled = false,
    roleCheck = true,
    smoothness = 2,
    showFOV = true,
    fovRadius = 180,
    aimKey = false, -- false = always aim when enabled
    method = "mouse", -- mouse | camera
}

Aimbot.Target = nil
Aimbot.FOV = nil
Aimbot.Connections = {}
Aimbot.RMB = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local function hasDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
end

local function canMouse()
    return typeof(mousemoverel) == "function" or typeof(mousemoveabs) == "function"
end

function Aimbot:GetRole(player)
    if not player then return "Unknown" end
    local char, bag = player.Character, player:FindFirstChild("Backpack")
    local function has(n)
        return (char and char:FindFirstChild(n)) or (bag and bag:FindFirstChild(n))
    end
    if has("Knife") then return "Murderer" end
    if has("Gun") then return "Sheriff" end
    return "Innocent"
end

function Aimbot:IsSameRole(player)
    local a, b = self:GetRole(LocalPlayer), self:GetRole(player)
    return a ~= "Unknown" and a == b
end

function Aimbot:GetAimPart(char)
    return char:FindFirstChild("Head")
        or char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("UpperTorso")
        or char:FindFirstChild("Torso")
end

function Aimbot:GetNearestTarget()
    local cam = workspace.CurrentCamera
    if not cam or not LocalPlayer.Character then return nil end

    local center = cam.ViewportSize / 2
    local best, bestDist = nil, self.Settings.fovRadius

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if self.Settings.roleCheck and self:IsSameRole(plr) then continue end

        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local part = self:GetAimPart(char)
        if not hum or not part or hum.Health <= 0 then continue end

        local sp, on = cam:WorldToViewportPoint(part.Position)
        if not on or sp.Z <= 0 then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best = part
        end
    end
    return best
end

function Aimbot:EnsureFOV()
    if not hasDrawing() then return end

    local alive = self.FOV ~= nil
    if alive then
        local ok = pcall(function()
            return self.FOV.Visible ~= nil
        end)
        if not ok then
            self.FOV = nil
            alive = false
        end
    end

    if not alive then
        local ok, c = pcall(function()
            return Drawing.new("Circle")
        end)
        if not ok or not c then return end
        c.Filled = false
        c.Thickness = 2
        c.NumSides = 64
        c.Color = Color3.fromRGB(255, 255, 255)
        c.Transparency = 0.5
        c.Visible = false
        c.ZIndex = 10
        self.FOV = c
    end
end

function Aimbot:UpdateFOV()
    self:EnsureFOV()
    if not self.FOV then return end

    local cam = workspace.CurrentCamera
    if not cam then
        pcall(function() self.FOV.Visible = false end)
        return
    end

    if self.Settings.showFOV and self.Settings.enabled then
        pcall(function()
            self.FOV.Position = cam.ViewportSize / 2
            self.FOV.Radius = self.Settings.fovRadius
            self.FOV.Color = Color3.fromRGB(255, 255, 255)
            self.FOV.Visible = true
        end)
    else
        pcall(function() self.FOV.Visible = false end)
    end
end

function Aimbot:ClearFOV()
    if self.FOV then
        pcall(function()
            self.FOV.Visible = false
            self.FOV:Destroy()
        end)
        self.FOV = nil
    end
end

function Aimbot:AimMouse(part)
    local cam = workspace.CurrentCamera
    if not cam then return end
    if typeof(isrbxactive) == "function" and not isrbxactive() then return end

    local sp, on = cam:WorldToViewportPoint(part.Position)
    if not on or sp.Z <= 0 then return end

    local target = Vector2.new(sp.X, sp.Y)
    local mouse = UIS:GetMouseLocation()
    local delta = target - mouse

    if delta.Magnitude < 1 then return end

    local smooth = math.max(self.Settings.smoothness, 0.5)
    local step = delta / smooth

    -- clamp huge jumps
    local maxStep = 80
    if step.Magnitude > maxStep then
        step = step.Unit * maxStep
    end

    if typeof(mousemoverel) == "function" then
        mousemoverel(step.X, step.Y)
    elseif typeof(mousemoveabs) == "function" then
        mousemoveabs(mouse.X + step.X, mouse.Y + step.Y)
    end
end

function Aimbot:AimCamera(part)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local origin = cam.CFrame.Position
    local goal = CFrame.new(origin, part.Position)
    local smooth = math.max(self.Settings.smoothness, 0.5)
    local alpha = math.clamp(1 / smooth, 0.08, 1)
    cam.CFrame = cam.CFrame:Lerp(goal, alpha)
end

function Aimbot:ShouldAim()
    if not self.Settings.enabled then return false end
    if self.Settings.aimKey then
        return self.RMB
    end
    return true
end

function Aimbot:Update()
    self:UpdateFOV()

    if not self:ShouldAim() then
        self.Target = nil
        return
    end

    local part = self:GetNearestTarget()
    self.Target = part
    if not part then return end

    local method = self.Settings.method
    if method == "camera" or not canMouse() then
        self:AimCamera(part)
    else
        self:AimMouse(part)
    end
end

-- disconnect only, do NOT touch Settings.enabled
function Aimbot:Cleanup()
    self:ClearFOV()
    self.Target = nil
    self.RMB = false
    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        end
    end
    table.clear(self.Connections)
end

function Aimbot:Init()
    self:Cleanup()

    self.Connections.inputBegan = UIS.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self.RMB = true
        end
    end)

    self.Connections.inputEnded = UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            self.RMB = false
        end
    end)

    self.Connections.render = RunService.RenderStepped:Connect(function()
        self:Update()
    end)

    -- FOV immediately if requested
    if self.Settings.showFOV then
        self:UpdateFOV()
    end
end

function Aimbot:Destroy()
    self.Settings.enabled = false
    self:Cleanup()
end

return Aimbot
