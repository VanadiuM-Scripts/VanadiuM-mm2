local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "VanadiuM | mm2",
    Center = true,
    AutoShow = true,
})

-- Load modules
local espModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/VanadiuM-Scripts/VanadiuM-mm2/refs/heads/main/modules/esp.lua"))()
local aimbotModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/VanadiuM-Scripts/VanadiuM-mm2/refs/heads/main/modules/aimbot.lua"))()
local hitboxModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/VanadiuM-Scripts/VanadiuM-mm2/refs/heads/main/modules/hitbox.lua"))()

-- Initialize ESP module immediately so it starts updating
espModule:Init()

local FirstTab = Window:AddTab("Combat")
local SecondTab = Window:AddTab("Visuals")
local ThirdTab = Window:AddTab("Exploits")
local FourthTab = Window:AddTab("Miscallenous")
local FifthTab = Window:AddTab("Settings")

local LeftGroup = FirstTab:AddLeftGroupbox("aimbot")
local RightGroup = FirstTab:AddRightGroupbox("hitbox expander")

local LeftTabbox = SecondTab:AddLeftTabbox("Visuals subtabs")
local PlayerEspSubtab = LeftTabbox:AddTab("player")
local OtherEspSubtab = LeftTabbox:AddTab("other")
local WorldVisualsGroup = SecondTab:AddRightGroupbox("world")

local MenuGroup = FifthTab:AddLeftGroupbox("Menu")

local ExpLeftGroup = ThirdTab:AddLeftGroupbox("buy premium for this XD")
local ExpRightGroup = ThirdTab:AddRightGroupbox("buy premium for this XD")

local MiscLeftGroup = FourthTab:AddLeftGroupbox("player")
local MiscRightGroup = FourthTab:AddRightGroupbox("other")

local Options = {}

OtherEspSubtab:AddToggle("Sheriff's gun", {
	Text = "Sheriff's gun",
	Default = false,

	Callback = function(Value)
		if Value == true then
			print("Sheriff's gun ON")
		end
	end
})

WorldVisualsGroup:AddLabel("i add something to this tab")
WorldVisualsGroup:AddLabel("on v1.1 or later")

-- ESP Settings
Options.ESP = {
    enabled = false,
    box = false,
    boxStyle = "2d",
    skeleton = false,
    tracer = false,
    role = false,
}

PlayerEspSubtab:AddToggle("enabled", {
    Text = "Enabled",
    Default = false,
    
    Callback = function(Value)
        Options.ESP.enabled = Value
        espModule.Settings.enabled = Value
    end
})

PlayerEspSubtab:AddToggle("box", {
    Text = "box",
    Default = false,
    
    Callback = function(Value)
        Options.ESP.box = Value
        espModule.Settings.box = Value
    end
})

PlayerEspSubtab:AddDropdown("box style", {
    Values = { "2d", "corner", "3d" },
    Default = 1,
    Multi = false,
    Text = "box style",

    Callback = function(Value)
        local styles = {"2d", "corner", "3d"}
        Options.ESP.boxStyle = styles[Value]
        espModule.Settings.boxStyle = styles[Value]
    end
})

PlayerEspSubtab:AddToggle("skeleton", {
	Text = "skeleton",
	Default = false,

	Callback = function(Value)
		Options.ESP.skeleton = Value
		espModule.Settings.skeleton = Value
	end
})

PlayerEspSubtab:AddToggle("role", {
	Text = "role",
	Default = false,

	Callback = function(Value)
	Options.ESP.role = Value
	espModule.Settings.role = Value
end
})

PlayerEspSubtab:AddToggle("Tracer", {
	Text = "Tracer",
	Default = false,

	Callback = function(Value)
	Options.ESP.tracer = Value
	espModule.Settings.tracer = Value
end
})

-- Aimbot Settings
Options.Aimbot = {
    enabled = false,
    teamCheck = true,
    smoothness = 0,
    showFOV = false,
    fovRadius = 150,
}

LeftGroup:AddToggle("aimbot", {
    Text = "enable",
    Default = false,
    Tooltip = "автонаводка",

    Callback = function(Value)
        Options.Aimbot.enabled = Value
        aimbotModule.Settings.enabled = Value
        if Value then
            aimbotModule:Init()
        else
            aimbotModule:Destroy()
        end
    end
})

LeftGroup:AddToggle("innocent check", {
    Text = "Team check",
    Default = false,
    Tooltip = "не позволяет наводится на тимейтов",

    Callback = function(Value)
        Options.Aimbot.teamCheck = Value
        aimbotModule.Settings.teamCheck = Value
    end
})

LeftGroup:AddSlider("smoothness", {
    Text = "smoothness",
    Default = 0,
    Min = 0,
    Max = 5,
    Rounding = 0,

    Callback = function(Value)
        Options.Aimbot.smoothness = Value
        aimbotModule.Settings.smoothness = Value
    end
})

LeftGroup:AddToggle("show FOV", {
    Text = "show FOV",
    Default = false,
    Tooltip = "радиус действия аимбота",

    Callback = function(Value)
        Options.Aimbot.showFOV = Value
        aimbotModule.Settings.showFOV = Value
    end
})

LeftGroup:AddSlider("FOV radius", {
    Text = "FOV radius",
    Default = 150,
    Min = 10,
    Max = 800,
    Rounding = 0,

    Callback = function(Value)
        Options.Aimbot.fovRadius = Value
        aimbotModule.Settings.fovRadius = Value
    end
})

-- Hitbox Settings
Options.Hitbox = {
    enabled = false,
    size = 1,
}

RightGroup:AddToggle("hitbox expander", {
    Text = "enable",
    Default = false,
    Tooltip = "увеличивает заданую часть тела",

    Callback = function(Value)
        Options.Hitbox.enabled = Value
        hitboxModule.Settings.enabled = Value
        if Value then
            hitboxModule:Init()
        else
            hitboxModule:Destroy()
        end
    end
})

RightGroup:AddSlider("size", {
    Text = "size",
    Default = 1,
    Min = 1,
    Max = 20,
    Rounding = 0,

    Callback = function(Value)
        Options.Hitbox.size = Value
        hitboxModule.Settings.size = Value
    end
})

MenuGroup:AddButton("Unload", function()
    -- Cleanup modules
    if aimbotModule.Destroy then aimbotModule:Destroy() end
    if hitboxModule.Destroy then hitboxModule:Destroy() end
    if espModule.Destroy then espModule:Destroy() end
    Library:Unload()
end)

MenuGroup:AddLabel("Menu keybind")
    :AddKeyPicker("MenuKeybind", {
        Default = "End",
        NoUI = true,
        Text = "Menu keybind"
    })

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({
    "MenuKeybind"
})

ThemeManager:SetFolder("VanadiuM")
SaveManager:SetFolder("VanadiuM/MM2")

SaveManager:BuildConfigSection(FifthTab)
ThemeManager:ApplyToTab(FifthTab)

SaveManager:LoadAutoloadConfig()
