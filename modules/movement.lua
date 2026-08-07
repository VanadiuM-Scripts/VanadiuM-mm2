--[[
    VanadiuM Movement — Potassium
    Speed / Fly / Noclip
]]

local Movement = {}

Movement.Settings = {
    speedEnabled = false,
    speedValue = 20,
    flyEnabled = false,
    flySpeed = 50,
    noclipEnabled = false,
}

Movement.Connections = {}
Movement.FlyBV = nil
Movement.FlyBG = nil
Movement.OriginalWalkSpeed = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

function Movement:Char()
    return LocalPlayer.Character
end

function Movement:HRP()
    local c = self:Char()
    return c and c:FindFirstChild("HumanoidRootPart")
end

function Movement:Hum()
    local c = self:Char()
    return c and c:FindFirstChildOfClass("Humanoid")
end

function Movement:ApplySpeed()
    local hum = self:Hum()
    if not hum then return end
    if self.Settings.speedEnabled then
        if not self.OriginalWalkSpeed then
            self.OriginalWalkSpeed = hum.WalkSpeed
        end
        hum.WalkSpeed = self.Settings.speedValue
    elseif self.OriginalWalkSpeed then
        hum.WalkSpeed = self.OriginalWalkSpeed
        self.OriginalWalkSpeed = nil
    end
end

function Movement:StopFly()
    if self.FlyBV then
        pcall(function() self.FlyBV:Destroy() end)
        self.FlyBV = nil
    end
    if self.FlyBG then
        pcall(function() self.FlyBG:Destroy() end)
        self.FlyBG = nil
    end
    local hum = self:Hum()
    if hum then
        hum.PlatformStand = false
    end
end

function Movement:StartFly()
    self:StopFly()
    local hrp = self:HRP()
    local hum = self:Hum()
    if not hrp or not hum then return end

    hum.PlatformStand = true

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    self.FlyBV = bv

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 1e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    self.FlyBG = bg
end

function Movement:UpdateFly()
    if not self.Settings.flyEnabled then
        self:StopFly()
        return
    end

    local hrp = self:HRP()
    local cam = workspace.CurrentCamera
    if not hrp or not cam then return end

    if not self.FlyBV or not self.FlyBV.Parent then
        self:StartFly()
    end
    if not self.FlyBV then return end

    local dir = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.yAxis end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
        dir -= Vector3.yAxis
    end

    if dir.Magnitude > 0 then
        dir = dir.Unit * self.Settings.flySpeed
    end
    self.FlyBV.Velocity = dir
    if self.FlyBG then
        self.FlyBG.CFrame = cam.CFrame
    end
end

function Movement:UpdateNoclip()
    local char = self:Char()
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if self.Settings.noclipEnabled then
                part.CanCollide = false
            end
        end
    end
end

function Movement:Init()
    self:Destroy()

    self.Connections.step = RunService.Heartbeat:Connect(function()
        self:ApplySpeed()
        self:UpdateFly()
        if self.Settings.noclipEnabled then
            self:UpdateNoclip()
        end
    end)

    self.Connections.char = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.3)
        self.OriginalWalkSpeed = nil
        if self.Settings.flyEnabled then
            self:StartFly()
        end
    end)
end

function Movement:Destroy()
    self:StopFly()
    local hum = self:Hum()
    if hum and self.OriginalWalkSpeed then
        hum.WalkSpeed = self.OriginalWalkSpeed
    end
    self.OriginalWalkSpeed = nil
    self.Settings.speedEnabled = false
    self.Settings.flyEnabled = false
    self.Settings.noclipEnabled = false

    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(self.Connections)
end

return Movement
