local Farm = {}

Farm.Settings = {
    coins = false,
    speed = 80,          -- tween studs/sec-ish
    method = "touch",    -- touch | tween | both
    maxDist = 500,
}

Farm.Connections = {}
Farm.Busy = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local function hrp()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isCoin(obj)
    if not obj or not obj:IsA("BasePart") then return false end
    if obj.Transparency >= 1 then return false end
    local n = string.lower(obj.Name)
    if n:find("coin") or n == "gold" or n:find("token") then
        return true
    end
    -- attribute / tag heuristics
    if obj:GetAttribute("Coin") or obj:GetAttribute("IsCoin") then
        return true
    end
    return false
end

function Farm:FindCoins()
    local list = {}
    local root = hrp()
    if not root then return list end

    local folders = {
        workspace:FindFirstChild("CoinContainer"),
        workspace:FindFirstChild("Coins"),
        workspace:FindFirstChild("Debris"),
        workspace:FindFirstChild("Map"),
        workspace,
    }

    local seen = {}
    for _, folder in ipairs(folders) do
        if not folder then continue end
        for _, obj in ipairs(folder:GetDescendants()) do
            if seen[obj] then continue end
            if isCoin(obj) then
                seen[obj] = true
                local dist = (obj.Position - root.Position).Magnitude
                if dist <= self.Settings.maxDist then
                    table.insert(list, { part = obj, dist = dist })
                end
            end
        end
        -- only full workspace scan once
        if folder == workspace then break end
    end

    table.sort(list, function(a, b) return a.dist < b.dist end)
    return list
end

local function touchCoin(part, root)
    if not part or not root then return end
    -- Potassium / UNC
    if typeof(firetouchinterest) == "function" then
        pcall(function()
            firetouchinterest(part, root, 0)
            task.wait()
            firetouchinterest(part, root, 1)
        end)
        return true
    end
    -- fallback: brief teleport on top of coin
    pcall(function()
        root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
    end)
    return true
end

local function tweenTo(part, root, speed)
    if not part or not root then return end
    local dist = (part.Position - root.Position).Magnitude
    local t = math.clamp(dist / math.max(speed, 10), 0.05, 2.5)
    local goal = { CFrame = part.CFrame + Vector3.new(0, 3, 0) }
    local info = TweenInfo.new(t, Enum.EasingStyle.Linear)
    local tw = TweenService:Create(root, info, goal)
    tw:Play()
    tw.Completed:Wait()
end

function Farm:CollectOnce()
    if self.Busy or not self.Settings.coins then return end
    local root = hrp()
    local humanoid = hum()
    if not root or not humanoid or humanoid.Health <= 0 then return end

    local coins = self:FindCoins()
    if #coins == 0 then return end

    self.Busy = true
    local method = self.Settings.method

    for _, entry in ipairs(coins) do
        if not self.Settings.coins then break end
        local part = entry.part
        if not part or not part.Parent then continue end
        root = hrp()
        if not root then break end

        if method == "tween" or method == "both" then
            pcall(function()
                tweenTo(part, root, self.Settings.speed)
            end)
        end

        if method == "touch" or method == "both" or method == "tween" then
            touchCoin(part, root)
        end

        task.wait(0.05)
    end

    self.Busy = false
end

function Farm:Init()
    self:Cleanup()

    self.Connections.loop = task.spawn(function()
        while true do
            task.wait(0.15)
            if self.Settings.coins and not self.Busy then
                self:CollectOnce()
            end
        end
    end)
end

function Farm:Cleanup()
    self.Busy = false
    if self.Connections.loop then
        pcall(function()
            task.cancel(self.Connections.loop)
        end)
        self.Connections.loop = nil
    end
    for k, c in pairs(self.Connections) do
        if typeof(c) == "RBXScriptConnection" then
            c:Disconnect()
        end
        self.Connections[k] = nil
    end
end

function Farm:Destroy()
    self.Settings.coins = false
    self:Cleanup()
end

return Farm
