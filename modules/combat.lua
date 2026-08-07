--[[
    VanadiuM Combat — kill all (client-side knife loop)
]]

local Combat = {}

Combat.Settings = {
    killAll = false,
    delay = 0.12,
    range = 12,
    method = "tp", -- tp | touch | both
}

Combat.Connections = {}
Combat.Busy = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function char()
    return LocalPlayer.Character
end

local function hrp()
    local c = char()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hasKnife()
    local c = char()
    local bag = LocalPlayer:FindFirstChild("Backpack")
    if c and c:FindFirstChild("Knife") then return c:FindFirstChild("Knife") end
    if bag and bag:FindFirstChild("Knife") then return bag:FindFirstChild("Knife") end
    return nil
end

local function equipKnife()
    local knife = hasKnife()
    if not knife then return nil end
    local hum = char() and char():FindFirstChildOfClass("Humanoid")
    if hum and knife.Parent == LocalPlayer.Backpack then
        pcall(function() hum:EquipTool(knife) end)
        task.wait(0.05)
    end
    return char() and char():FindFirstChild("Knife")
end

local function activateKnife(knife)
    if not knife then return end
    pcall(function()
        knife:Activate()
    end)
    if typeof(mouse1click) == "function" then
        pcall(mouse1click)
    end
end

function Combat:Targets()
    local list = {}
    local root = hrp()
    if not root then return list end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local c = plr.Character
        if not c then continue end
        local hum = c:FindFirstChildOfClass("Humanoid")
        local th = c:FindFirstChild("HumanoidRootPart")
        if hum and th and hum.Health > 0 then
            table.insert(list, { plr = plr, hrp = th, hum = hum })
        end
    end
    return list
end

function Combat:KillOnce()
    if self.Busy or not self.Settings.killAll then return end
    local root = hrp()
    if not root then return end

    local knife = equipKnife()
    if not knife then return end -- only works as murderer with knife

    self.Busy = true
    local method = self.Settings.method
    local delay = math.max(self.Settings.delay, 0.05)

    for _, t in ipairs(self:Targets()) do
        if not self.Settings.killAll then break end
        root = hrp()
        if not root then break end
        if not t.hrp or not t.hrp.Parent then continue end

        if method == "tp" or method == "both" then
            pcall(function()
                root.CFrame = t.hrp.CFrame * CFrame.new(0, 0, 2)
            end)
        end

        if method == "touch" or method == "both" then
            local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
            if handle and typeof(firetouchinterest) == "function" then
                pcall(function()
                    firetouchinterest(handle, t.hrp, 0)
                    task.wait()
                    firetouchinterest(handle, t.hrp, 1)
                end)
            end
        end

        activateKnife(knife)
        task.wait(delay)
    end

    self.Busy = false
end

function Combat:Init()
    self:Cleanup()
    self.Connections.loop = task.spawn(function()
        while true do
            task.wait(0.2)
            if self.Settings.killAll and not self.Busy then
                self:KillOnce()
            end
        end
    end)
end

function Combat:Cleanup()
    self.Busy = false
    if self.Connections.loop then
        pcall(function() task.cancel(self.Connections.loop) end)
        self.Connections.loop = nil
    end
    for k, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
        self.Connections[k] = nil
    end
end

function Combat:Destroy()
    self.Settings.killAll = false
    self:Cleanup()
end

return Combat
