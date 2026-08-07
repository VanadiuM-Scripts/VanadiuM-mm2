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
local farm = loadModule("farm")
local world = loadModule("world")

if esp and esp.Init then esp:Init() end
if movement and movement.Init then movement:Init() end
if misc and misc.Init then misc:Init() end
if farm and farm.Init then farm:Init() end
if world and world.Init then world:Init() end

local TabCombat = Window:AddTab("Combat")
local TabVisuals = Window:AddTab("Visuals")
local TabMove = Window:AddTab("Movement")
local TabMisc = Window:AddTab("Misc")
local TabSettings = Window:AddTab("Settings")

local AimGroup = TabCombat:AddLeftGroupbox("Aimbot")
local HitGroup = TabCombat:AddRightGroupbox("Hitbox")

local EspBox = TabVisuals:AddLeftTabbox("ESP")
local EspPlayer = EspBox:AddTab("Player")
local EspWorld = EspBox:AddTab("World")
local WorldGroup = TabVisuals:AddRightGroupbox("Info")

local MoveL = TabMove:AddLeftGroupbox("Speed / Fly")
local MoveR = TabMove:AddRightGroupbox("Noclip")
local MiscL = TabMisc:AddLeftGroupbox("Utilities")
local MiscR = TabMisc:AddRightGroupbox("Camera")
local MenuGroup = TabSettings:AddLeftGroupbox("Menu")

-- ESP
if esp then
    EspPlayer:AddToggle("esp_on", { Text = "Enabled", Default = false, Callback = function(v) esp.Settings.enabled = v end })
    EspPlayer:AddToggle("esp_box", { Text = "Box (fit body)", Default = false, Callback = function(v) esp.Settings.box = v end })
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
    EspWorld:AddToggle("esp_coins", { Text = "Coins ESP", Default = false, Callback = function(v) esp.Settings.coins = v end })
    EspWorld:AddToggle("esp_gun", { Text = "Dropped gun ESP", Default = false, Callback = function(v) esp.Settings.gun = v end })


if world then
    -- Other / world style
    EspOther:AddToggle("w_ambient", {
        Text = "Custom ambient", Default = false,
        Callback = function(v) world.Settings.ambientEnabled = v end,
    })
    EspOther:AddLabel("Ambient color"):AddColorPicker("w_amb_col", {
        Default = Color3.fromRGB(128, 128, 128),
        Callback = function(c) world.Settings.ambient = c end,
    })
    EspOther:AddLabel("Outdoor ambient"):AddColorPicker("w_out_col", {
        Default = Color3.fromRGB(128, 128, 128),
        Callback = function(c) world.Settings.outdoorAmbient = c end,
    })

    EspOther:AddToggle("w_fog", {
        Text = "Fog", Default = false,
        Callback = function(v) world.Settings.fogEnabled = v end,
    })
    EspOther:AddLabel("Fog color"):AddColorPicker("w_fog_col", {
        Default = Color3.fromRGB(192, 192, 192),
        Callback = function(c) world.Settings.fogColor = c end,
    })
    EspOther:AddSlider("w_fog_start", {
        Text = "Fog start", Default = 0, Min = 0, Max = 500, Rounding = 0,
        Callback = function(v) world.Settings.fogStart = v end,
    })
    EspOther:AddSlider("w_fog_end", {
        Text = "Fog end", Default = 1000, Min = 50, Max = 5000, Rounding = 0,
        Callback = function(v) world.Settings.fogEnd = v end,
    })

    EspOther:AddToggle("w_time", {
        Text = "Custom time", Default = false,
        Callback = function(v) world.Settings.timeEnabled = v end,
    })
    EspOther:AddSlider("w_clock", {
        Text = "Clock time", Default = 14, Min = 0, Max = 24, Rounding = 1,
        Callback = function(v) world.Settings.clockTime = v end,
    })

    EspOther:AddToggle("w_sky", {
        Text = "Custom sky", Default = false,
        Callback = function(v) world.Settings.skyEnabled = v end,
    })
    EspOther:AddDropdown("w_sky_id", {
        Values = { "default", "nebula", "sunset", "night" },
        Default = 1, Multi = false, Text = "Sky preset",
        Callback = function(v)
            if type(v) == "number" then
                world.Settings.skyId = ({ "default", "nebula", "sunset", "night" })[v] or "default"
            else
                world.Settings.skyId = v
            end
        end,
    })

    WorldGroup:AddToggle("w_trail", {
        Text = "Trail", Default = false,
        Callback = function(v) world.Settings.trailEnabled = v end,
    })
    WorldGroup:AddLabel("Trail color"):AddColorPicker("w_trail_col", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(c) world.Settings.trailColor = c end,
    })

    WorldGroup:AddToggle("w_hat", {
        Text = "China hat", Default = false,
        Callback = function(v) world.Settings.chinaHat = v end,
    })
    WorldGroup:AddLabel("Hat color"):AddColorPicker("w_hat_col", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(c) world.Settings.chinaHatColor = c end,
    })

    WorldGroup:AddToggle("w_bloom", {
        Text = "Bloom", Default = false,
        Callback = function(v) world.Settings.bloomEnabled = v end,
    })
    WorldGroup:AddSlider("w_bloom_i", {
        Text = "Bloom intensity", Default = 1, Min = 0, Max = 5, Rounding = 1,
        Callback = function(v) world.Settings.bloomIntensity = v end,
    })

    WorldGroup:AddToggle("w_cc", {
        Text = "Color correction", Default = false,
        Callback = function(v) world.Settings.ccEnabled = v end,
    })
    WorldGroup:AddSlider("w_cc_sat", {
        Text = "Saturation", Default = 0, Min = -1, Max = 1, Rounding = 2,
        Callback = function(v) world.Settings.ccSaturation = v end,
    })
    WorldGroup:AddSlider("w_cc_con", {
        Text = "Contrast", Default = 0, Min = -1, Max = 1, Rounding = 2,
        Callback = function(v) world.Settings.ccContrast = v end,
    })

    WorldGroup:AddToggle("w_atmo", {
        Text = "Atmosphere", Default = false,
        Callback = function(v) world.Settings.atmosphereEnabled = v end,
    })
    WorldGroup:AddSlider("w_atmo_d", {
        Text = "Density", Default = 0.3, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) world.Settings.atmosphereDensity = v end,
    })

    WorldGroup:AddToggle("w_cross", {
        Text = "Crosshair", Default = false,
        Callback = function(v) world.Settings.crosshair = v end,
    })
    WorldGroup:AddLabel("Crosshair color"):AddColorPicker("w_cross_col", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(c) world.Settings.crosshairColor = c end,
    })
end

WorldGroup:AddLabel("VanadiuM world visuals")

end

-- Aimbot
if aimbot then
    AimGroup:AddToggle("aim_on", {
        Text = "Enable", Default = false, Tooltip = "Hold RMB to aim",
        Callback = function(v)
            aimbot.Settings.enabled = v
            if v then aimbot:Init() else aimbot:Destroy() end
        end,
    })
    AimGroup:AddToggle("aim_rmb", {
        Text = "Hold RMB only", Default = false,
        Callback = function(v) aimbot.Settings.aimKey = v end,
    })
    AimGroup:AddToggle("aim_role", {
        Text = "Role check", Default = true,
        Callback = function(v) aimbot.Settings.roleCheck = v end,
    })
    AimGroup:AddDropdown("aim_method", {
        Values = { "mouse", "camera", "both" }, Default = 1, Multi = false, Text = "Method",
        Callback = function(v)
            if type(v) == "number" then aimbot.Settings.method = ({ "mouse", "camera", "both" })[v] or "mouse"
            else aimbot.Settings.method = v end
        end,
    })
    AimGroup:AddSlider("aim_smooth", {
        Text = "Smoothness", Default = 2, Min = 0.5, Max = 12, Rounding = 1,
        Callback = function(v) aimbot.Settings.smoothness = v end,
    })
    AimGroup:AddToggle("aim_fov", {
        Text = "Show FOV", Default = true,
        Callback = function(v) aimbot.Settings.showFOV = v end,
    })
    AimGroup:AddSlider("aim_fov_r", {
        Text = "FOV radius", Default = 180, Min = 30, Max = 600, Rounding = 0,
        Callback = function(v) aimbot.Settings.fovRadius = v end,
    })
end

-- Hitbox
if hitbox then
    HitGroup:AddToggle("hb_on", {
        Text = "Enable", Default = false, Tooltip = "Client expand + visual",
        Callback = function(v)
            hitbox.Settings.enabled = v
            if v then hitbox:Init() else hitbox:Destroy() end
        end,
    })
    HitGroup:AddToggle("hb_vis", {
        Text = "Show expanded", Default = true,
        Callback = function(v) hitbox.Settings.showVisual = v end,
    })
    HitGroup:AddSlider("hb_size", {
        Text = "Size", Default = 50, Min = 5, Max = 100, Rounding = 0,
        Callback = function(v) hitbox.Settings.size = v end,
    })
    HitGroup:AddDropdown("hb_part", {
        Values = { "HumanoidRootPart", "Head", "both" }, Default = 1, Multi = false, Text = "Part",
        Callback = function(v)
            if type(v) == "number" then
                hitbox.Settings.part = ({ "HumanoidRootPart", "Head", "both" })[v] or "HumanoidRootPart"
            else
                hitbox.Settings.part = v
            end
        end,
    })
    HitGroup:AddSlider("hb_trans", {
        Text = "Visual transparency", Default = 0.7, Min = 0.2, Max = 0.9, Rounding = 2,
        Callback = function(v) hitbox.Settings.visualTransparency = v end,
    })
end

-- Movement
if movement then
    MoveL:AddToggle("mv_speed", {
        Text = "Speed", Default = false,
        Callback = function(v) movement.Settings.speedEnabled = v end,
    })
    MoveL:AddSlider("mv_speed_v", {
        Text = "WalkSpeed", Default = 20, Min = 16, Max = 100, Rounding = 0,
        Callback = function(v) movement.Settings.speedValue = v end,
    })
    MoveL:AddToggle("mv_fly", {
        Text = "Fly (WASD+Space/Ctrl)", Default = false,
        Callback = function(v)
            movement.Settings.flyEnabled = v
            if not v and movement.StopFly then movement:StopFly() end
        end,
    })
    MoveL:AddSlider("mv_fly_s", {
        Text = "Fly speed", Default = 50, Min = 10, Max = 150, Rounding = 0,
        Callback = function(v) movement.Settings.flySpeed = v end,
    })
    MoveR:AddToggle("mv_noclip", {
        Text = "Noclip", Default = false,
        Callback = function(v) movement.Settings.noclipEnabled = v end,
    })
end

-- Misc
if farm then
    MiscL:AddToggle("farm_coins", {
        Text = "Auto collect coins",
        Default = false,
        Callback = function(v)
            farm.Settings.coins = v
        end,
    })
    MiscL:AddDropdown("farm_method", {
        Values = { "touch", "tween", "both" },
        Default = 1,
        Multi = false,
        Text = "Coin method",
        Callback = function(v)
            if type(v) == "number" then
                farm.Settings.method = ({ "touch", "tween", "both" })[v] or "touch"
            else
                farm.Settings.method = v
            end
        end,
    })
    MiscL:AddSlider("farm_speed", {
        Text = "Tween speed",
        Default = 80,
        Min = 20,
        Max = 200,
        Rounding = 0,
        Callback = function(v) farm.Settings.speed = v end,
    })
end

if misc then
    MiscL:AddToggle("mc_afk", {
        Text = "Anti-AFK", Default = false,
        Callback = function(v) misc.Settings.antiAfk = v end,
    })
    MiscL:AddToggle("mc_fb", {
        Text = "Fullbright", Default = false,
        Callback = function(v) misc.Settings.fullbright = v end,
    })
    MiscR:AddToggle("mc_fov", {
        Text = "Custom FOV", Default = false,
        Callback = function(v) misc.Settings.fovEnabled = v end,
    })
    MiscR:AddSlider("mc_fov_v", {
        Text = "FOV value", Default = 90, Min = 50, Max = 120, Rounding = 0,
        Callback = function(v) misc.Settings.fovValue = v end,
    })
end

MenuGroup:AddButton("Unload", function()
    if aimbot and aimbot.Destroy then aimbot:Destroy() end
    if hitbox and hitbox.Destroy then hitbox:Destroy() end
    if esp and esp.Destroy then esp:Destroy() end
    if movement and movement.Destroy then movement:Destroy() end
    if misc and misc.Destroy then misc:Destroy() end
    if farm and farm.Destroy then farm:Destroy() end
    if world and world.Destroy then world:Destroy() end
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
