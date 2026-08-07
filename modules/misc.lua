--[[
    VanadiuM Misc — Potassium
    Anti-AFK, Fullbright, FOV unlock
]]

local Misc = {}

Misc.Settings = {
    antiAfk = false,
    fullbright = false,
    fovEnabled = false,
    fovValue = 90,
}

Misc.Connections = {}
Misc.OriginalBrightness = nil
Misc.OriginalAmbient = nil
Misc.OriginalFOV = nil

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer

function Misc:ApplyFullbright()
    if self.Settings.fullbright then
        if not self.OriginalBrightness then
            self.OriginalBrightness = Lighting.Brightness
            self.OriginalAmbient = Lighting.Ambient
        end
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(180, 180, 180)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
    else
        if self.OriginalBrightness then
            Lighting.Brightness = self.OriginalBrightness
            Lighting.Ambient = self.OriginalAmbient or Color3.new(0.5, 0.5, 0.5)
            Lighting.GlobalShadows = true
            self.OriginalBrightness = nil
            self.OriginalAmbient = nil
        end
    end
end

function Misc:ApplyFOV()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if self.Settings.fovEnabled then
        if not self.OriginalFOV then
            self.OriginalFOV = cam.FieldOfView
        end
        cam.FieldOfView = self.Settings.fovValue
    elseif self.OriginalFOV then
        cam.FieldOfView = self.OriginalFOV
        self.OriginalFOV = nil
    end
end

function Misc:Init()
    self:Destroy()

    self.Connections.step = game:GetService("RunService").Heartbeat:Connect(function()
        self:ApplyFullbright()
        self:ApplyFOV()
    end)

    self.Connections.idled = LocalPlayer.Idled:Connect(function()
        if self.Settings.antiAfk then
            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    end)
end

function Misc:Destroy()
    self.Settings.antiAfk = false
    self.Settings.fullbright = false
    self.Settings.fovEnabled = false
    self:ApplyFullbright()
    self:ApplyFOV()

    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(self.Connections)
end

return Misc
