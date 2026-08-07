print("Loading...")
local function httpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res then return res end
    if typeof(request) == "function" then
        local r = request({ Url = url, Method = "GET" })
        if r and (r.Success or r.StatusCode == 200) and r.Body then return r.Body end
    end
    return nil
end

local function loadModule(name)
    local paths = {
        "VanadiuM-mm2-fixed/modules/" .. name .. ".lua",
        "VanadiuM-mm2/modules/" .. name .. ".lua",
        "modules/" .. name .. ".lua",
        name .. ".lua",
    }
    if typeof(isfile) == "function" and typeof(readfile) == "function" then
        for _, path in ipairs(paths) do
            if isfile(path) then
                local fn, err = loadstring(readfile(path))
                if fn then
                    local ok, mod = pcall(fn)
                    if ok and mod then
                        print("[VanadiuM] local:", path)
                        return mod
                    end
                else
                    warn("[VanadiuM] compile", path, err)
                end
            end
        end
    end
    local url = "https://raw.githubusercontent.com/VanadiuM-Scripts/VanadiuM-mm2/main/modules/" .. name .. ".lua"
    local src = httpGet(url)
    if src then
        local fn = loadstring(src)
        if fn then
            local ok, mod = pcall(fn)
            if ok and mod then
                print("[VanadiuM] remote:", name)
                return mod
            end
        end
    end
    warn("[VanadiuM] missing module:", name)
    return nil
end

local libSrc = httpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua")
local themeSrc = httpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua")
local saveSrc = httpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua")
assert(libSrc and themeSrc and saveSrc, "[VanadiuM] LinoriaLib fetch failed")

local Library = loadstring(libSrc)()
local ThemeManager = loadstring(themeSrc)()
local SaveManager = loadstring(saveSrc)()

local Window = Library:CreateWindow({
    Title = "VanadiuM | mm2 (Potassium)",
    Center = true,
    AutoShow = true,
})

local esp = loadModule("esp")
local aimbot = loadModule("aimbot")
local hitbox = loadModule("hitbox")
local movement = loadModule("movement")
local misc = loadModule("misc")
local world = loadModule("world")
local combat = loadModule("combat")

if esp and esp.Init then esp:Init() end
if movement and movement.Init then movement:Init() end
if misc and misc.Init then misc:Init() end
if world and world.Init then world:Init() end
if combat and combat.Init then combat:Init() end

do
    local missing = {}
    for name, mod in pairs({
        esp = esp, aimbot = aimbot, hitbox = hitbox,
        movement = movement, misc = misc, world = world, combat = combat,
    }) do
        if not mod then table.insert(missing, name) end
    end
    if #missing > 0 then
        Library:Notify("Modules missing: " .. table.concat(missing, ", "), 8)
    end
end

local TabCombat = Window:AddTab("Combat")
local TabVisuals = Window:AddTab("Visuals")
local TabWorld = Window:AddTab("World")
local TabMove = Window:AddTab("Movement")
local TabMisc = Window:AddTab("Misc")
local TabSettings = Window:AddTab("Settings")

local AimGroup = TabCombat:AddLeftGroupbox("Aimbot")
local HitGroup = TabCombat:AddRightGroupbox("Hitbox")
local KillGroup = TabCombat:AddLeftGroupbox("Kill All")

local EspBox = TabVisuals:AddLeftTabbox("ESP")
local EspPlayer = EspBox:AddTab("Player")
local EspItems = EspBox:AddTab("Items")

local WLighting = TabWorld:AddLeftGroupbox("Lighting")
local WEffects = TabWorld:AddRightGroupbox("Effects")
local WPlayer = TabWorld:AddLeftGroupbox("Player FX")
local WAura = TabWorld:AddRightGroupbox("Aura")

local MoveL = TabMove:AddLeftGroupbox("Speed / Fly")
local MoveR = TabMove:AddRightGroupbox("Noclip")
local MiscL = TabMisc:AddLeftGroupbox("Utilities")
local MiscR = TabMisc:AddRightGroupbox("Camera")
local MenuGroup = TabSettings:AddLeftGroupbox("Menu")

-- ESP
if esp then
    EspPlayer:AddToggle("esp_on", { Text = "Enabled", Default = false, Callback = function(v) esp.Settings.enabled = v end })
    EspPlayer:AddToggle("esp_box", { Text = "Box (body parts)", Default = false, Callback = function(v) esp.Settings.box = v end })
    EspPlayer:AddDropdown("esp_style", {
        Values = { "2d", "corner", "3d" }, Default = 1, Multi = false, Text = "Box style",
        Callback = function(v)
            if type(v) == "number" then esp.Settings.boxStyle = ({ "2d", "corner", "3d" })[v] or "2d"
            else esp.Settings.boxStyle = v end
        end,
    })
    EspPlayer:AddToggle("esp_skel", { Text = "Skeleton", Default = false, Callback = function(v) esp.Settings.skeleton = v end })
    EspPlayer:AddToggle("esp_role", { Text = "Role", Default = false, Callback = function(v) esp.Settings.role = v end })
    EspPlayer:AddToggle("esp_tracer", { Text = "Tracer", Default = false, Callback = function(v) esp.Settings.tracer = v end })
    EspItems:AddToggle("esp_coins", { Text = "Coins ESP", Default = false, Callback = function(v) esp.Settings.coins = v end })
    EspItems:AddToggle("esp_gun", { Text = "Dropped gun ESP", Default = false, Callback = function(v) esp.Settings.gun = v end })
else
    EspPlayer:AddLabel("esp module not loaded")
end

-- WORLD
if world then
    WLighting:AddToggle("w_ambient", { Text = "Custom ambient", Default = false, Callback = function(v) world.Settings.ambientEnabled = v end })
    WLighting:AddLabel("Ambient"):AddColorPicker("w_amb_col", { Default = Color3.fromRGB(128,128,128), Callback = function(c) world.Settings.ambient = c end })
    WLighting:AddLabel("Outdoor"):AddColorPicker("w_out_col", { Default = Color3.fromRGB(128,128,128), Callback = function(c) world.Settings.outdoorAmbient = c end })

    WLighting:AddToggle("w_fog", { Text = "Fog", Default = false, Callback = function(v) world.Settings.fogEnabled = v end })
    WLighting:AddLabel("Fog color"):AddColorPicker("w_fog_col", { Default = Color3.fromRGB(192,192,192), Callback = function(c) world.Settings.fogColor = c end })
    WLighting:AddSlider("w_fog_start", { Text = "Fog start", Default = 0, Min = 0, Max = 500, Rounding = 0, Callback = function(v) world.Settings.fogStart = v end })
    WLighting:AddSlider("w_fog_end", { Text = "Fog end", Default = 1000, Min = 50, Max = 5000, Rounding = 0, Callback = function(v) world.Settings.fogEnd = v end })

    WLighting:AddToggle("w_time", { Text = "Custom time", Default = false, Callback = function(v) world.Settings.timeEnabled = v end })
    WLighting:AddSlider("w_clock", { Text = "Clock (0-24)", Default = 14, Min = 0, Max = 24, Rounding = 1, Callback = function(v) world.Settings.clockTime = v end })

    WLighting:AddToggle("w_sky", { Text = "Custom sky", Default = false, Callback = function(v) world.Settings.skyEnabled = v end })
    WLighting:AddDropdown("w_sky_id", {
        Values = { "default", "nebula", "sunset", "night" }, Default = 1, Multi = false, Text = "Sky preset",
        Callback = function(v)
            if type(v) == "number" then world.Settings.skyId = ({ "default", "nebula", "sunset", "night" })[v] or "default"
            else world.Settings.skyId = v end
        end,
    })

    WEffects:AddToggle("w_bloom", { Text = "Bloom", Default = false, Callback = function(v) world.Settings.bloomEnabled = v end })
    WEffects:AddSlider("w_bloom_i", { Text = "Bloom intensity", Default = 1, Min = 0, Max = 5, Rounding = 1, Callback = function(v) world.Settings.bloomIntensity = v end })
    WEffects:AddSlider("w_bloom_s", { Text = "Bloom size", Default = 24, Min = 1, Max = 56, Rounding = 0, Callback = function(v) world.Settings.bloomSize = v end })
    WEffects:AddSlider("w_bloom_t", { Text = "Bloom threshold", Default = 0.8, Min = 0, Max = 2, Rounding = 2, Callback = function(v) world.Settings.bloomThreshold = v end })

    WEffects:AddToggle("w_cc", { Text = "Color correction", Default = false, Callback = function(v) world.Settings.ccEnabled = v end })
    WEffects:AddSlider("w_cc_bri", { Text = "Brightness", Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = function(v) world.Settings.ccBrightness = v end })
    WEffects:AddSlider("w_cc_sat", { Text = "Saturation", Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = function(v) world.Settings.ccSaturation = v end })
    WEffects:AddSlider("w_cc_con", { Text = "Contrast", Default = 0, Min = -1, Max = 1, Rounding = 2, Callback = function(v) world.Settings.ccContrast = v end })
    WEffects:AddLabel("Tint"):AddColorPicker("w_cc_tint", { Default = Color3.fromRGB(255,255,255), Callback = function(c) world.Settings.ccTint = c end })

    WEffects:AddToggle("w_atmo", { Text = "Atmosphere", Default = false, Callback = function(v) world.Settings.atmosphereEnabled = v end })
    WEffects:AddSlider("w_atmo_d", { Text = "Density", Default = 0.3, Min = 0, Max = 1, Rounding = 2, Callback = function(v) world.Settings.atmosphereDensity = v end })
    WEffects:AddSlider("w_atmo_h", { Text = "Haze", Default = 1.5, Min = 0, Max = 10, Rounding = 1, Callback = function(v) world.Settings.atmosphereHaze = v end })

    WEffects:AddToggle("w_cross", { Text = "Crosshair", Default = false, Callback = function(v) world.Settings.crosshair = v end })
    WEffects:AddLabel("Crosshair"):AddColorPicker("w_cross_col", { Default = Color3.fromRGB(255,255,255), Callback = function(c) world.Settings.crosshairColor = c end })
    WEffects:AddSlider("w_cross_s", { Text = "Crosshair size", Default = 8, Min = 2, Max = 30, Rounding = 0, Callback = function(v) world.Settings.crosshairSize = v end })
    WEffects:AddSlider("w_cross_g", { Text = "Crosshair gap", Default = 3, Min = 0, Max = 20, Rounding = 0, Callback = function(v) world.Settings.crosshairGap = v end })
    WEffects:AddSlider("w_cross_th", { Text = "Crosshair thickness", Default = 1.5, Min = 1, Max = 5, Rounding = 1, Callback = function(v) world.Settings.crosshairThickness = v end })

    -- Player FX: trail + china hat
    WPlayer:AddToggle("w_trail", { Text = "Trail", Default = false, Callback = function(v) world.Settings.trailEnabled = v end })
    WPlayer:AddLabel("Trail color"):AddColorPicker("w_trail_col", { Default = Color3.fromRGB(255,255,255), Callback = function(c) world.Settings.trailColor = c end })
    WPlayer:AddSlider("w_trail_life", { Text = "Trail lifetime", Default = 0.6, Min = 0.1, Max = 3, Rounding = 2, Callback = function(v) world.Settings.trailLifetime = v end })
    WPlayer:AddSlider("w_trail_w", { Text = "Trail width", Default = 1, Min = 0.3, Max = 3, Rounding = 1, Callback = function(v) world.Settings.trailWidth = v end })

    WPlayer:AddToggle("w_hat", { Text = "China hat", Default = false, Callback = function(v) world.Settings.chinaHat = v end })
    WPlayer:AddLabel("Hat color"):AddColorPicker("w_hat_col", { Default = Color3.fromRGB(255,255,255), Callback = function(c) world.Settings.chinaHatColor = c end })
    WPlayer:AddSlider("w_hat_sx", { Text = "Hat width (X)", Default = 1.2, Min = 0.2, Max = 4, Rounding = 2, Callback = function(v) world.Settings.chinaHatSizeX = v end })
    WPlayer:AddSlider("w_hat_sy", { Text = "Hat height (Y)", Default = 1.1, Min = 0.2, Max = 4, Rounding = 2, Callback = function(v) world.Settings.chinaHatSizeY = v end })
    WPlayer:AddSlider("w_hat_sz", { Text = "Hat length (Z)", Default = 1.2, Min = 0.2, Max = 4, Rounding = 2, Callback = function(v) world.Settings.chinaHatSizeZ = v end })
    WPlayer:AddSlider("w_hat_px", { Text = "Pos X", Default = 0, Min = -3, Max = 3, Rounding = 2, Callback = function(v) world.Settings.chinaHatPosX = v end })
    WPlayer:AddSlider("w_hat_py", { Text = "Pos Y", Default = 0.85, Min = -2, Max = 4, Rounding = 2, Callback = function(v) world.Settings.chinaHatPosY = v end })
    WPlayer:AddSlider("w_hat_pz", { Text = "Pos Z", Default = 0, Min = -3, Max = 3, Rounding = 2, Callback = function(v) world.Settings.chinaHatPosZ = v end })
    WPlayer:AddSlider("w_hat_tr", { Text = "Hat transparency", Default = 0.1, Min = 0, Max = 0.9, Rounding = 2, Callback = function(v) world.Settings.chinaHatTransparency = v end })
    WPlayer:AddDropdown("w_hat_mat", {
        Values = { "SmoothPlastic", "Neon", "ForceField", "Glass" }, Default = 1, Multi = false, Text = "Hat material",
        Callback = function(v)
            if type(v) == "number" then world.Settings.chinaHatMaterial = ({ "SmoothPlastic", "Neon", "ForceField", "Glass" })[v] or "SmoothPlastic"
            else world.Settings.chinaHatMaterial = v end
        end,
    })

    -- Aura
    WAura:AddToggle("w_aura", { Text = "Aura", Default = false, Callback = function(v) world.Settings.auraEnabled = v end })
    WAura:AddLabel("Aura color"):AddColorPicker("w_aura_col", { Default = Color3.fromRGB(120,200,255), Callback = function(c) world.Settings.auraColor = c end })
    WAura:AddDropdown("w_aura_type", {
        Values = { "highlight", "ring", "both" }, Default = 1, Multi = false, Text = "Aura type",
        Callback = function(v)
            if type(v) == "number" then world.Settings.auraType = ({ "highlight", "ring", "both" })[v] or "highlight"
            else world.Settings.auraType = v end
        end,
    })
    WAura:AddSlider("w_aura_size", { Text = "Ring size", Default = 4, Min = 2, Max = 12, Rounding = 1, Callback = function(v) world.Settings.auraSize = v end })
    WAura:AddSlider("w_aura_tr", { Text = "Aura transparency", Default = 0.6, Min = 0, Max = 0.95, Rounding = 2, Callback = function(v) world.Settings.auraTransparency = v end })
else
    WLighting:AddLabel("world module not loaded")
end


-- KILL ALL
if combat then
    KillGroup:AddToggle("ka_on", {
        Text = "Kill all", Default = false,
        Tooltip = "Needs Knife (Murderer)",
        Callback = function(v) combat.Settings.killAll = v end,
    })
    KillGroup:AddDropdown("ka_method", {
        Values = { "tp", "touch", "both" }, Default = 1, Multi = false, Text = "Method",
        Callback = function(v)
            if type(v) == "number" then
                combat.Settings.method = ({ "tp", "touch", "both" })[v] or "tp"
            else
                combat.Settings.method = v
            end
        end,
    })
    KillGroup:AddSlider("ka_delay", {
        Text = "Delay", Default = 0.12, Min = 0.05, Max = 0.5, Rounding = 2,
        Callback = function(v) combat.Settings.delay = v end,
    })
    KillGroup:AddLabel("Works as Murderer with Knife")
else
    KillGroup:AddLabel("combat module not loaded")
end


-- AIMBOT
if aimbot then
    AimGroup:AddToggle("aim_on", {
        Text = "Enable", Default = false,
        Callback = function(v)
            aimbot.Settings.enabled = v
            if v then aimbot:Init() else aimbot:Destroy() end
        end,
    })
    AimGroup:AddToggle("aim_rmb", { Text = "Hold RMB only", Default = false, Callback = function(v) aimbot.Settings.aimKey = v end })
    AimGroup:AddToggle("aim_role", { Text = "Role check", Default = true, Callback = function(v) aimbot.Settings.roleCheck = v end })
    AimGroup:AddDropdown("aim_method", {
        Values = { "mouse", "camera", "both" }, Default = 1, Multi = false, Text = "Method",
        Callback = function(v)
            if type(v) == "number" then aimbot.Settings.method = ({ "mouse", "camera", "both" })[v] or "mouse"
            else aimbot.Settings.method = v end
        end,
    })
    AimGroup:AddSlider("aim_smooth", { Text = "Smoothness", Default = 2, Min = 0.5, Max = 12, Rounding = 1, Callback = function(v) aimbot.Settings.smoothness = v end })
    AimGroup:AddToggle("aim_fov", { Text = "Show FOV", Default = true, Callback = function(v) aimbot.Settings.showFOV = v end })
    AimGroup:AddSlider("aim_fov_r", { Text = "FOV radius", Default = 180, Min = 30, Max = 600, Rounding = 0, Callback = function(v) aimbot.Settings.fovRadius = v end })
else
    AimGroup:AddLabel("aimbot module not loaded")
end

-- HITBOX
if hitbox then
    HitGroup:AddToggle("hb_on", {
        Text = "Enable", Default = false,
        Callback = function(v)
            hitbox.Settings.enabled = v
            if v then hitbox:Init() else hitbox:Destroy() end
        end,
    })
    HitGroup:AddToggle("hb_vis", { Text = "Show expanded", Default = true, Callback = function(v) hitbox.Settings.showVisual = v end })
    HitGroup:AddSlider("hb_size", { Text = "Size", Default = 50, Min = 5, Max = 100, Rounding = 0, Callback = function(v) hitbox.Settings.size = v end })
    HitGroup:AddDropdown("hb_part", {
        Values = { "HumanoidRootPart", "Head", "both" }, Default = 1, Multi = false, Text = "Part",
        Callback = function(v)
            if type(v) == "number" then hitbox.Settings.part = ({ "HumanoidRootPart", "Head", "both" })[v] or "HumanoidRootPart"
            else hitbox.Settings.part = v end
        end,
    })
    HitGroup:AddSlider("hb_trans", { Text = "Visual transparency", Default = 0.7, Min = 0.2, Max = 0.9, Rounding = 2, Callback = function(v) hitbox.Settings.visualTransparency = v end })
else
    HitGroup:AddLabel("hitbox module not loaded")
end

-- MOVEMENT
if movement then
    MoveL:AddToggle("mv_speed", { Text = "Speed", Default = false, Callback = function(v) movement.Settings.speedEnabled = v end })
    MoveL:AddSlider("mv_speed_v", { Text = "WalkSpeed", Default = 20, Min = 16, Max = 100, Rounding = 0, Callback = function(v) movement.Settings.speedValue = v end })
    MoveL:AddToggle("mv_fly", {
        Text = "Fly (WASD+Space/Ctrl)", Default = false,
        Callback = function(v)
            movement.Settings.flyEnabled = v
            if not v and movement.StopFly then movement:StopFly() end
        end,
    })
    MoveL:AddSlider("mv_fly_s", { Text = "Fly speed", Default = 50, Min = 10, Max = 150, Rounding = 0, Callback = function(v) movement.Settings.flySpeed = v end })
    MoveR:AddToggle("mv_noclip", { Text = "Noclip", Default = false, Callback = function(v) movement.Settings.noclipEnabled = v end })
else
    MoveL:AddLabel("movement module not loaded")
end

-- MISC
if misc then
    MiscL:AddToggle("mc_afk", { Text = "Anti-AFK", Default = false, Callback = function(v) misc.Settings.antiAfk = v end })
    MiscL:AddToggle("mc_fb", { Text = "Fullbright", Default = false, Callback = function(v) misc.Settings.fullbright = v end })
    MiscR:AddToggle("mc_fov", { Text = "Custom FOV", Default = false, Callback = function(v) misc.Settings.fovEnabled = v end })
    MiscR:AddSlider("mc_fov_v", { Text = "FOV value", Default = 90, Min = 50, Max = 120, Rounding = 0, Callback = function(v) misc.Settings.fovValue = v end })
else
    MiscL:AddLabel("misc module not loaded")
end

MenuGroup:AddButton("Unload", function()
    if aimbot and aimbot.Destroy then aimbot:Destroy() end
    if hitbox and hitbox.Destroy then hitbox:Destroy() end
    if esp and esp.Destroy then esp:Destroy() end
    if movement and movement.Destroy then movement:Destroy() end
    if misc and misc.Destroy then misc:Destroy() end
    if world and world.Destroy then world:Destroy() end
    if combat and combat.Destroy then combat:Destroy() end
    Library:Unload()
end)

MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
    Default = "End", NoUI = true, Text = "Menu keybind",
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("VanadiuM")
SaveManager:SetFolder("VanadiuM/MM2")
SaveManager:BuildConfigSection(TabSettings)
ThemeManager:ApplyToTab(TabSettings)
SaveManager:LoadAutoloadConfig()
print("loaded!")
