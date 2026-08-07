--[[
    VanadiuM World Visuals — Potassium
    Ambient, fog, time, sky, trail, china hat, CC, bloom, etc.
]]

local World = {}

World.Settings = {
    ambientEnabled = false,
    ambient = Color3.fromRGB(128, 128, 128),
    outdoorAmbient = Color3.fromRGB(128, 128, 128),

    fogEnabled = false,
    fogColor = Color3.fromRGB(192, 192, 192),
    fogStart = 0,
    fogEnd = 1000,

    timeEnabled = false,
    clockTime = 14,

    skyEnabled = false,
    skyId = "default", -- default | nebula | sunset | night | custom
    customSkyTx = "",

    trailEnabled = false,
    trailColor = Color3.fromRGB(255, 255, 255),

    chinaHat = false,
    chinaHatColor = Color3.fromRGB(255, 255, 255),

    bloomEnabled = false,
    bloomIntensity = 1,
    bloomSize = 24,

    ccEnabled = false,
    ccBrightness = 0,
    ccContrast = 0,
    ccSaturation = 0,

    atmosphereEnabled = false,
    atmosphereDensity = 0.3,

    crosshair = false,
    crosshairColor = Color3.fromRGB(255, 255, 255),
    crosshairSize = 8,
}

World.Backup = {}
World.Connections = {}
World.Trail = nil
World.Hat = nil
World.Cross = {}
World.Effects = {} -- Bloom, ColorCorrection, Atmosphere we create

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local SKYBOX = {
    default = nil, -- restore original
    nebula = {
        SkyboxBk = "rbxassetid://159454299",
        SkyboxDn = "rbxassetid://159454296",
        SkyboxFt = "rbxassetid://159454293",
        SkyboxLf = "rbxassetid://159454286",
        SkyboxRt = "rbxassetid://159454300",
        SkyboxUp = "rbxassetid://159454288",
    },
    sunset = {
        SkyboxBk = "rbxassetid://600830446",
        SkyboxDn = "rbxassetid://600831635",
        SkyboxFt = "rbxassetid://600832720",
        SkyboxLf = "rbxassetid://600826389",
        SkyboxRt = "rbxassetid://600833862",
        SkyboxUp = "rbxassetid://600835177",
    },
    night = {
        SkyboxBk = "rbxassetid://12064107",
        SkyboxDn = "rbxassetid://12064152",
        SkyboxFt = "rbxassetid://12064121",
        SkyboxLf = "rbxassetid://12063984",
        SkyboxRt = "rbxassetid://12064115",
        SkyboxUp = "rbxassetid://12064131",
    },
}

local function char()
    return LocalPlayer.Character
end

local function head()
    local c = char()
    return c and c:FindFirstChild("Head")
end

local function hrp()
    local c = char()
    return c and c:FindFirstChild("HumanoidRootPart")
end

function World:SaveLighting()
    if self.Backup.saved then return end
    self.Backup = {
        saved = true,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        FogColor = Lighting.FogColor,
        FogStart = Lighting.FogStart,
        FogEnd = Lighting.FogEnd,
        ClockTime = Lighting.ClockTime,
        Brightness = Lighting.Brightness,
        Sky = Lighting:FindFirstChildOfClass("Sky"),
    }
end

function World:ApplyAmbient()
    if self.Settings.ambientEnabled then
        Lighting.Ambient = self.Settings.ambient
        Lighting.OutdoorAmbient = self.Settings.outdoorAmbient
    elseif self.Backup.saved then
        Lighting.Ambient = self.Backup.Ambient
        Lighting.OutdoorAmbient = self.Backup.OutdoorAmbient
    end
end

function World:ApplyFog()
    if self.Settings.fogEnabled then
        Lighting.FogColor = self.Settings.fogColor
        Lighting.FogStart = self.Settings.fogStart
        Lighting.FogEnd = self.Settings.fogEnd
    elseif self.Backup.saved then
        Lighting.FogColor = self.Backup.FogColor
        Lighting.FogStart = self.Backup.FogStart
        Lighting.FogEnd = self.Backup.FogEnd
    end
end

function World:ApplyTime()
    if self.Settings.timeEnabled then
        Lighting.ClockTime = self.Settings.clockTime
    elseif self.Backup.saved then
        Lighting.ClockTime = self.Backup.ClockTime
    end
end

function World:ApplySky()
    local id = self.Settings.skyId
    if not self.Settings.skyEnabled or id == "default" then
        -- remove our sky if any, don't destroy game's original if we cached instance
        local sky = Lighting:FindFirstChild("VanadiuM_Sky")
        if sky then sky:Destroy() end
        return
    end

    local preset = SKYBOX[id]
    local sky = Lighting:FindFirstChild("VanadiuM_Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Name = "VanadiuM_Sky"
        sky.Parent = Lighting
    end

    if preset then
        for prop, val in pairs(preset) do
            pcall(function() sky[prop] = val end)
        end
    elseif id == "custom" and self.Settings.customSkyTx ~= "" then
        local tx = self.Settings.customSkyTx
        if not string.find(tx, "rbxassetid://") then
            tx = "rbxassetid://" .. tx
        end
        for _, prop in ipairs({ "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" }) do
            pcall(function() sky[prop] = tx end)
        end
    end
end

function World:ClearTrail()
    if self.Trail then
        pcall(function() self.Trail:Destroy() end)
        self.Trail = nil
    end
    local c = char()
    if c then
        local t = c:FindFirstChild("VanadiuM_Trail")
        if t then pcall(function() t:Destroy() end) end
        local a0 = c:FindFirstChild("VanadiuM_TrailA0")
        local a1 = c:FindFirstChild("VanadiuM_TrailA1")
        if a0 then pcall(function() a0:Destroy() end) end
        if a1 then pcall(function() a1:Destroy() end) end
    end
end

function World:ApplyTrail()
    if not self.Settings.trailEnabled then
        self:ClearTrail()
        return
    end
    local root = hrp()
    if not root then return end
    if self.Trail and self.Trail.Parent then
        self.Trail.Color = ColorSequence.new(self.Settings.trailColor)
        return
    end
    self:ClearTrail()

    local a0 = Instance.new("Attachment")
    a0.Name = "VanadiuM_TrailA0"
    a0.Position = Vector3.new(0, 0.5, 0)
    a0.Parent = root

    local a1 = Instance.new("Attachment")
    a1.Name = "VanadiuM_TrailA1"
    a1.Position = Vector3.new(0, -0.5, 0)
    a1.Parent = root

    local trail = Instance.new("Trail")
    trail.Name = "VanadiuM_Trail"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = 0.6
    trail.MinLength = 0.05
    trail.FaceCamera = true
    trail.Color = ColorSequence.new(self.Settings.trailColor)
    trail.Transparency = NumberSequence.new(0.2, 1)
    trail.WidthScale = NumberSequence.new(1, 0)
    trail.Parent = root
    self.Trail = trail
end

function World:ClearHat()
    if self.Hat then
        pcall(function() self.Hat:Destroy() end)
        self.Hat = nil
    end
    local h = head()
    if h then
        local old = h:FindFirstChild("VanadiuM_ChinaHat")
        if old then pcall(function() old:Destroy() end) end
    end
end

function World:ApplyChinaHat()
    if not self.Settings.chinaHat then
        self:ClearHat()
        return
    end
    local h = head()
    if not h then return end
    if self.Hat and self.Hat.Parent == h then
        self.Hat.Color = self.Settings.chinaHatColor
        return
    end
    self:ClearHat()

    local hat = Instance.new("Part")
    hat.Name = "VanadiuM_ChinaHat"
    hat.Size = Vector3.new(0.15, 1.2, 1.2)
    hat.Anchored = false
    hat.CanCollide = false
    hat.Massless = true
    hat.Material = Enum.Material.SmoothPlastic
    hat.Color = self.Settings.chinaHatColor
    hat.CastShadow = false

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1778999" -- classic cone-ish; fallback cylinder if fails
    mesh.Scale = Vector3.new(1.2, 1.1, 1.2)
    mesh.Parent = hat

    hat.CFrame = h.CFrame * CFrame.new(0, 0.85, 0)
    hat.Parent = h

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = h
    weld.Part1 = hat
    weld.Parent = hat

    self.Hat = hat
end

function World:GetOrCreateEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing:IsA(className) then return existing end
    if existing then existing:Destroy() end
    local fx = Instance.new(className)
    fx.Name = name
    fx.Parent = Lighting
    self.Effects[name] = fx
    return fx
end

function World:ApplyBloom()
    local name = "VanadiuM_Bloom"
    if not self.Settings.bloomEnabled then
        local fx = Lighting:FindFirstChild(name)
        if fx then fx:Destroy() end
        return
    end
    local bloom = self:GetOrCreateEffect("BloomEffect", name)
    bloom.Intensity = self.Settings.bloomIntensity
    bloom.Size = self.Settings.bloomSize
    bloom.Threshold = 0.8
    bloom.Enabled = true
end

function World:ApplyCC()
    local name = "VanadiuM_CC"
    if not self.Settings.ccEnabled then
        local fx = Lighting:FindFirstChild(name)
        if fx then fx:Destroy() end
        return
    end
    local cc = self:GetOrCreateEffect("ColorCorrectionEffect", name)
    cc.Brightness = self.Settings.ccBrightness
    cc.Contrast = self.Settings.ccContrast
    cc.Saturation = self.Settings.ccSaturation
    cc.Enabled = true
end

function World:ApplyAtmosphere()
    local name = "VanadiuM_Atmosphere"
    if not self.Settings.atmosphereEnabled then
        local fx = Lighting:FindFirstChild(name)
        if fx then fx:Destroy() end
        return
    end
    local at = self:GetOrCreateEffect("Atmosphere", name)
    at.Density = self.Settings.atmosphereDensity
    at.Offset = 0.25
    at.Color = Color3.fromRGB(200, 200, 220)
    at.Decay = Color3.fromRGB(100, 100, 120)
    at.Glare = 0.2
    at.Haze = 1.5
end

function World:ClearCrosshair()
    for _, d in ipairs(self.Cross) do
        pcall(function() d:Destroy() end)
    end
    table.clear(self.Cross)
end

function World:ApplyCrosshair()
    if not self.Settings.crosshair then
        self:ClearCrosshair()
        return
    end
    if typeof(Drawing) ~= "table" then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local c = cam.ViewportSize / 2
    local s = self.Settings.crosshairSize
    local col = self.Settings.crosshairColor

    if #self.Cross < 2 then
        self:ClearCrosshair()
        for i = 1, 2 do
            local l = Drawing.new("Line")
            l.Thickness = 1.5
            l.Transparency = 1
            l.ZIndex = 20
            l.Visible = true
            table.insert(self.Cross, l)
        end
    end
    local h, v = self.Cross[1], self.Cross[2]
    h.From = Vector2.new(c.X - s, c.Y)
    h.To = Vector2.new(c.X + s, c.Y)
    h.Color = col
    h.Visible = true
    v.From = Vector2.new(c.X, c.Y - s)
    v.To = Vector2.new(c.X, c.Y + s)
    v.Color = col
    v.Visible = true
end

function World:Tick()
    self:ApplyAmbient()
    self:ApplyFog()
    self:ApplyTime()
    self:ApplySky()
    self:ApplyTrail()
    self:ApplyChinaHat()
    self:ApplyBloom()
    self:ApplyCC()
    self:ApplyAtmosphere()
    self:ApplyCrosshair()
end

function World:Init()
    self:Destroy()
    self:SaveLighting()

    self.Connections.step = RunService.RenderStepped:Connect(function()
        self:Tick()
    end)

    self.Connections.char = LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.4)
        self:ClearTrail()
        self:ClearHat()
        self.Trail = nil
        self.Hat = nil
    end)
end

function World:Destroy()
    -- disable flags
    self.Settings.ambientEnabled = false
    self.Settings.fogEnabled = false
    self.Settings.timeEnabled = false
    self.Settings.skyEnabled = false
    self.Settings.trailEnabled = false
    self.Settings.chinaHat = false
    self.Settings.bloomEnabled = false
    self.Settings.ccEnabled = false
    self.Settings.atmosphereEnabled = false
    self.Settings.crosshair = false

    self:ClearTrail()
    self:ClearHat()
    self:ClearCrosshair()

    local sky = Lighting:FindFirstChild("VanadiuM_Sky")
    if sky then sky:Destroy() end
    for _, name in ipairs({ "VanadiuM_Bloom", "VanadiuM_CC", "VanadiuM_Atmosphere" }) do
        local fx = Lighting:FindFirstChild(name)
        if fx then fx:Destroy() end
    end

    if self.Backup.saved then
        pcall(function()
            Lighting.Ambient = self.Backup.Ambient
            Lighting.OutdoorAmbient = self.Backup.OutdoorAmbient
            Lighting.FogColor = self.Backup.FogColor
            Lighting.FogStart = self.Backup.FogStart
            Lighting.FogEnd = self.Backup.FogEnd
            Lighting.ClockTime = self.Backup.ClockTime
        end)
    end

    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(self.Connections)
end

return World
