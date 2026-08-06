local function httpGet(url)
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and res then return res end

    if typeof(request) == "function" then
        local r = request({ Url = url, Method = "GET" })
        if r and r.Success and r.Body then
            return r.Body
        end
    end
    return nil
end

local function loadModule(name)
    local candidates = {
        "VanadiuM-mm2-fixed/modules/" .. name .. ".lua",
        "VanadiuM-mm2/modules/" .. name .. ".lua",
        "modules/" .. name .. ".lua",
        name .. ".lua",
    }

    if typeof(isfile) == "function" and typeof(readfile) == "function" then
        for _, path in ipairs(candidates) do
            if isfile(path) then
                local src = readfile(path)
                local fn, err = loadstring(src)
                if fn then
                    local ok, mod = pcall(fn)
                    if ok and mod then
                        print("[VanadiuM] local module:", path)
                        return mod
                    end
                else
                    warn("[VanadiuM] compile error", path, err)
                end
            end
        end
    end

    -- remote fallback (original repo — may be outdated)
    local url = "https://raw.githubusercontent.com/VanadiuM-Scripts/VanadiuM-mm2/main/modules/" .. name .. ".lua"
    local src = httpGet(url)
    if src then
        local fn = loadstring(src)
        if fn then
            local ok, mod = pcall(fn)
            if ok and mod then
                print("[VanadiuM] remote module:", name)
                return mod
            end
        end
    end

    warn("[VanadiuM] failed to load module:", name)
    return nil
end

-- UI
local libSrc = httpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua")
local themeSrc = httpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua")
local saveSrc = httpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua")

assert(libSrc and themeSrc and saveSrc, "[VanadiuM] failed to fetch LinoriaLib")

local Library = loadstring(libSrc)()
local ThemeManager = loadstring(themeSrc)()
local SaveManager = loadstring(saveSrc)()

local Window = Library:CreateWindow({
    Title = "VanadiuM | mm2  (Potassium)",
    Center = true,
    AutoShow = true,
})

local esp = loadModule("esp")
local aimbot = loadModule("aimbot")
local hitbox = loadModule("hitbox")

if not (esp and aimbot and hitbox) then
    Library:Notify("Modules missing. Put fixed files in workspace (see README).", 10)
end

if esp and esp.Init then
    esp:Init()
end

------------------------------------------------------------
-- Tabs
------------------------------------------------------------
local TabCombat = Window:AddTab("Combat")
local TabVisuals = Window:AddTab("Visuals")
local TabExploits = Window:AddTab("Exploits")
local TabMisc = Window:AddTab("Misc")
local TabSettings = Window:AddTab("Settings")

local AimGroup = TabCombat:AddLeftGroupbox("Aimbot")
local HitGroup = TabCombat:AddRightGroupbox("Hitbox")

local EspBox = TabVisuals:AddLeftTabbox("ESP")
local EspPlayer = EspBox:AddTab("Player")
local EspOther = EspBox:AddTab("Other")
local WorldGroup = TabVisuals:AddRightGroupbox("World")

local ExpL = TabExploits:AddLeftGroupbox("Soon")
local ExpR = TabExploits:AddRightGroupbox("Soon")
local MiscL = TabMisc:AddLeftGroupbox("Player")
local MiscR = TabMisc:AddRightGroupbox("Other")
local MenuGroup = TabSettings:AddLeftGroupbox("Menu")

------------------------------------------------------------
-- ESP UI
------------------------------------------------------------
if esp then
    EspPlayer:AddToggle("esp_on", {
        Text = "Enabled",
        Default = false,
        Callback = function(v)
            esp.Settings.enabled = v
        end,
    })

    EspPlayer:AddToggle("esp_box", {
        Text = "Box",
        Default = false,
        Callback = function(v)
            esp.Settings.box = v
        end,
    })

    EspPlayer:AddDropdown("esp_boxstyle", {
        Values = { "2d", "corner", "3d" },
        Default = 1,
        Multi = false,
        Text = "Box style",
        Callback = function(v)
            if type(v) == "number" then
                esp.Settings.boxStyle = ({ "2d", "corner", "3d" })[v] or "2d"
            else
                esp.Settings.boxStyle = v
            end
        end,
    })

    EspPlayer:AddToggle("esp_skel", {
        Text = "Skeleton",
        Default = false,
        Callback = function(v)
            esp.Settings.skeleton = v
        end,
    })

    EspPlayer:AddToggle("esp_role", {
        Text = "Role",
        Default = false,
        Callback = function(v)
            esp.Settings.role = v
        end,
    })

    EspPlayer:AddToggle("esp_tracer", {
        Text = "Tracer",
        Default = false,
        Callback = function(v)
            esp.Settings.tracer = v
        end,
    })
end

EspOther:AddLabel("Gun ESP — later")
WorldGroup:AddLabel("World visuals — later")

------------------------------------------------------------
-- Aimbot UI
------------------------------------------------------------
if aimbot then
    AimGroup:AddToggle("aim_on", {
        Text = "Enable",
        Default = false,
        Tooltip = "Camera aim at nearest in FOV",
        Callback = function(v)
            aimbot.Settings.enabled = v
            if v then
                aimbot:Init()
            else
                aimbot:Destroy()
            end
        end,
    })

    AimGroup:AddToggle("aim_role", {
        Text = "Role check",
        Default = true,
        Tooltip = "Skip same role (Knife/Gun)",
        Callback = function(v)
            aimbot.Settings.roleCheck = v
        end,
    })

    AimGroup:AddSlider("aim_smooth", {
        Text = "Smoothness",
        Default = 0,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Callback = function(v)
            aimbot.Settings.smoothness = v
        end,
    })

    AimGroup:AddToggle("aim_fov", {
        Text = "Show FOV",
        Default = false,
        Callback = function(v)
            aimbot.Settings.showFOV = v
        end,
    })

    AimGroup:AddSlider("aim_fov_r", {
        Text = "FOV radius",
        Default = 150,
        Min = 20,
        Max = 600,
        Rounding = 0,
        Callback = function(v)
            aimbot.Settings.fovRadius = v
        end,
    })
end

------------------------------------------------------------
-- Hitbox UI
------------------------------------------------------------
if hitbox then
    HitGroup:AddToggle("hb_on", {
        Text = "Enable",
        Default = false,
        Tooltip = "Client expand (server may ignore)",
        Callback = function(v)
            hitbox.Settings.enabled = v
            if v then
                hitbox:Init()
            else
                hitbox:Destroy()
            end
        end,
    })

    HitGroup:AddSlider("hb_size", {
        Text = "Size ×",
        Default = 2,
        Min = 1,
        Max = 15,
        Rounding = 1,
        Callback = function(v)
            hitbox.Settings.size = v
        end,
    })
end

ExpL:AddLabel("Nothing yet")
ExpR:AddLabel("buy premium for this XD")
MiscL:AddLabel("Later")
MiscR:AddLabel("Later")

------------------------------------------------------------
-- Menu
------------------------------------------------------------
MenuGroup:AddButton("Unload", function()
    if aimbot and aimbot.Destroy then aimbot:Destroy() end
    if hitbox and hitbox.Destroy then hitbox:Destroy() end
    if esp and esp.Destroy then esp:Destroy() end
    Library:Unload()
end)

MenuGroup:AddLabel("Menu keybind"):AddKeyPicker("MenuKeybind", {
    Default = "End",
    NoUI = true,
    Text = "Menu keybind",
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
