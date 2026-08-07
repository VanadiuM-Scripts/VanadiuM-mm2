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
    skyId = "default",

    trailEnabled = false,
    trailColor = Color3.fromRGB(255, 255, 255),
    trailLifetime = 0.6,
    trailWidth = 1,

    chinaHat = false,
    chinaHatColor = Color3.fromRGB(255, 255, 255),
    chinaHatSize = 1.2,
    chinaHatHeight = 0.85,
    chinaHatTransparency = 0.1,
    chinaHatMaterial = "SmoothPlastic", -- SmoothPlastic | Neon | ForceField

    auraEnabled = false,
    auraColor = Color3.fromRGB(120, 200, 255),
    auraSize = 4,
    auraTransparency = 0.6,
    auraType = "highlight", -- highlight | ring | both

    aspectEnabled = false,
    aspectRatio = 1.333, -- width/height modifier via FOV trick + letterbox feel

    bloomEnabled = false,
    bloomIntensity = 1,
    bloomSize = 24,
    bloomThreshold = 0.8,

    ccEnabled = false,
    ccBrightness = 0,
    ccContrast = 0,
    ccSaturation = 0,
    ccTint = Color3.fromRGB(255, 255, 255),

    atmosphereEnabled = false,
    atmosphereDensity = 0.3,
    atmosphereHaze = 1.5,

    crosshair = false,
    crosshairColor = Color3.fromRGB(255, 255, 255),
    crosshairSize = 8,
    crosshairGap = 3,
    crosshairThickness = 1.5,
}

World.Backup = {}
World.Connections = {}
World.Trail = nil
World.Hat = nil
World.AuraParts = {}
World.AuraHighlight = nil
World.Cross = {}
World.Effects = {}

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local SKYBOX = {
    default = nil,
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

local MATERIALS = {
    SmoothPlastic = Enum.Material.SmoothPlastic,
    Neon = Enum.Material.Neon,
    ForceField = Enum.Material.ForceField,
    Glass = Enum.Material.Glass,
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
        FieldOfView = workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView or 70,
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
    end
end

function World:ClearTrail()
    if self.Trail then pcall(function() self.Trail:Destroy() end) self.Trail = nil end
    local c = char()
    if not c then return end
    for _, n in ipairs({ "VanadiuM_Trail", "VanadiuM_TrailA0", "VanadiuM_TrailA1" }) do
        local o = c:FindFirstChild(n, true)
        if o then pcall(function() o:Destroy() end) end
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
        self.Trail.Lifetime = self.Settings.trailLifetime
        return
    end
    self:ClearTrail()
    local a0 = Instance.new("Attachment")
    a0.Name = "VanadiuM_TrailA0"
    a0.Position = Vector3.new(0, 0.5 * self.Settings.trailWidth, 0)
    a0.Parent = root
    local a1 = Instance.new("Attachment")
    a1.Name = "VanadiuM_TrailA1"
    a1.Position = Vector3.new(0, -0.5 * self.Settings.trailWidth, 0)
    a1.Parent = root
    local trail = Instance.new("Trail")
    trail.Name = "VanadiuM_Trail"
    trail.Attachment0 = a0
    trail.Attachment1 = a1
    trail.Lifetime = self.Settings.trailLifetime
    trail.MinLength = 0.05
    trail.FaceCamera = true
    trail.Color = ColorSequence.new(self.Settings.trailColor)
    trail.Transparency = NumberSequence.new(0.15, 1)
    trail.WidthScale = NumberSequence.new(1, 0)
    trail.Parent = root
    self.Trail = trail
end

function World:ClearHat()
    if self.Hat then pcall(function() self.Hat:Destroy() end) self.Hat = nil end
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

    local scale = self.Settings.chinaHatSize
    local height = self.Settings.chinaHatHeight
    local mat = MATERIALS[self.Settings.chinaHatMaterial] or Enum.Material.SmoothPlastic

    if self.Hat and self.Hat.Parent == h then
        self.Hat.Color = self.Settings.chinaHatColor
        self.Hat.Transparency = self.Settings.chinaHatTransparency
        self.Hat.Material = mat
        local mesh = self.Hat:FindFirstChildOfClass("SpecialMesh")
        if mesh then mesh.Scale = Vector3.new(scale, scale * 0.9, scale) end
        -- keep weld; offset via CFrame on hat if needed
        return
    end

    self:ClearHat()
    local hat = Instance.new("Part")
    hat.Name = "VanadiuM_ChinaHat"
    hat.Size = Vector3.new(0.2, 1, 1)
    hat.Anchored = false
    hat.CanCollide = false
    hat.Massless = true
    hat.Material = mat
    hat.Color = self.Settings.chinaHatColor
    hat.Transparency = self.Settings.chinaHatTransparency
    hat.CastShadow = false

    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1778999"
    mesh.Scale = Vector3.new(scale, scale * 0.9, scale)
    mesh.Parent = hat

    hat.CFrame = h.CFrame * CFrame.new(0, height, 0)
    hat.Parent = h

    local weld = Instance.new("Weld")
    weld.Part0 = h
    weld.Part1 = hat
    weld.C0 = CFrame.new(0, height, 0)
    weld.Parent = hat

    self.Hat = hat
end

function World:ClearAura()
    if self.AuraHighlight then
        pcall(function() self.AuraHighlight:Destroy() end)
        self.AuraHighlight = nil
    end
    for _, p in ipairs(self.AuraParts) do
        pcall(function() p:Destroy() end)
    end
    table.clear(self.AuraParts)
    local c = char()
    if c then
        local old = c:FindFirstChild("VanadiuM_Aura")
        if old then pcall(function() old:Destroy() end) end
        local hl = c:FindFirstChild("VanadiuM_AuraHL")
        if hl then pcall(function() hl:Destroy() end) end
    end
end

function World:ApplyAura()
    if not self.Settings.auraEnabled then
        self:ClearAura()
        return
    end
    local c = char()
    local root = hrp()
    if not c or not root then return end

    local typ = self.Settings.auraType
    local col = self.Settings.auraColor
    local size = self.Settings.auraSize
    local trans = self.Settings.auraTransparency

    -- Highlight
    if typ == "highlight" or typ == "both" then
        local hl = self.AuraHighlight
        if not hl or not hl.Parent then
            hl = Instance.new("Highlight")
            hl.Name = "VanadiuM_AuraHL"
            hl.FillTransparency = math.clamp(trans + 0.2, 0, 1)
            hl.OutlineTransparency = math.clamp(trans - 0.2, 0, 1)
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = c
            self.AuraHighlight = hl
        end
        hl.FillColor = col
        hl.OutlineColor = col
        hl.FillTransparency = math.clamp(trans + 0.15, 0, 1)
        hl.OutlineTransparency = math.clamp(trans * 0.5, 0, 1)
        hl.Adornee = c
    elseif self.AuraHighlight then
        pcall(function() self.AuraHighlight:Destroy() end)
        self.AuraHighlight = nil
    end

    -- Ring under feet
    if typ == "ring" or typ == "both" then
        local ring = self.AuraParts[1]
        if not ring or not ring.Parent then
            self:ClearAura()
            -- re-add highlight if both
            if typ == "both" then
                local hl = Instance.new("Highlight")
                hl.Name = "VanadiuM_AuraHL"
                hl.Parent = c
                self.AuraHighlight = hl
            end
            ring = Instance.new("Part")
            ring.Name = "VanadiuM_Aura"
            ring.Anchored = false
            ring.CanCollide = false
            ring.Massless = true
            ring.Material = Enum.Material.Neon
            ring.Shape = Enum.PartType.Cylinder
            ring.Size = Vector3.new(0.15, size, size)
            ring.Transparency = trans
            ring.Color = col
            ring.CastShadow = false
            ring.Parent = root
            local weld = Instance.new("Weld")
            weld.Part0 = root
            weld.Part1 = ring
            weld.C0 = CFrame.new(0, -2.8, 0) * CFrame.Angles(0, 0, math.rad(90))
            weld.Parent = ring
            self.AuraParts[1] = ring
        else
            ring.Size = Vector3.new(0.15, size, size)
            ring.Transparency = trans
            ring.Color = col
        end
    else
        for _, p in ipairs(self.AuraParts) do
            pcall(function() p:Destroy() end)
        end
        table.clear(self.AuraParts)
    end
end

function World:ApplyAspect()
    local cam = workspace.CurrentCamera
    if not cam then return end
    if self.Settings.aspectEnabled then
        -- approximate ultrawide / stretched feel via FOV scale
        local base = self.Backup.FieldOfView or 70
        local r = self.Settings.aspectRatio
        -- higher ratio → wider feel → slightly higher FOV
        cam.FieldOfView = math.clamp(base * (0.75 + r * 0.35), 50, 120)
    end
end

function World:GetOrCreateEffect(className, name)
    local existing = Lighting:FindFirstChild(name)
    if existing and existing:IsA(className) then return existing end
    if existing then existing:Destroy() end
    local fx = Instance.new(className)
    fx.Name = name
    fx.Parent = Lighting
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
    bloom.Threshold = self.Settings.bloomThreshold
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
    cc.TintColor = self.Settings.ccTint
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
    at.Haze = self.Settings.atmosphereHaze
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
    local g = self.Settings.crosshairGap
    local col = self.Settings.crosshairColor
    local th = self.Settings.crosshairThickness

    if #self.Cross < 4 then
        self:ClearCrosshair()
        for _ = 1, 4 do
            local l = Drawing.new("Line")
            l.Thickness = th
            l.Transparency = 1
            l.ZIndex = 20
            l.Visible = true
            table.insert(self.Cross, l)
        end
    end
    -- left, right, up, down (with gap)
    local L, R, U, D = self.Cross[1], self.Cross[2], self.Cross[3], self.Cross[4]
    L.From = Vector2.new(c.X - g - s, c.Y); L.To = Vector2.new(c.X - g, c.Y)
    R.From = Vector2.new(c.X + g, c.Y); R.To = Vector2.new(c.X + g + s, c.Y)
    U.From = Vector2.new(c.X, c.Y - g - s); U.To = Vector2.new(c.X, c.Y - g)
    D.From = Vector2.new(c.X, c.Y + g); D.To = Vector2.new(c.X, c.Y + g + s)
    for _, line in ipairs(self.Cross) do
        line.Color = col
        line.Thickness = th
        line.Visible = true
    end
end

function World:Tick()
    self:ApplyAmbient()
    self:ApplyFog()
    self:ApplyTime()
    self:ApplySky()
    self:ApplyTrail()
    self:ApplyChinaHat()
    self:ApplyAura()
    self:ApplyAspect()
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
        self:ClearAura()
        self.Trail = nil
        self.Hat = nil
    end)
end

function World:Destroy()
    for k, v in pairs(self.Settings) do
        if type(v) == "boolean" then self.Settings[k] = false end
    end
    self:ClearTrail()
    self:ClearHat()
    self:ClearAura()
    self:ClearCrosshair()
    for _, name in ipairs({ "VanadiuM_Sky", "VanadiuM_Bloom", "VanadiuM_CC", "VanadiuM_Atmosphere" }) do
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
            if workspace.CurrentCamera and self.Backup.FieldOfView then
                workspace.CurrentCamera.FieldOfView = self.Backup.FieldOfView
            end
        end)
    end
    for _, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    table.clear(self.Connections)
end

return World
