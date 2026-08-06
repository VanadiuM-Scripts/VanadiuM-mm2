local ESP = {}

ESP.Settings = {
    enabled = false,
    box = false,
    boxStyle = "2d", -- 2d | corner | 3d
    skeleton = false,
    tracer = false,
    role = false,
}

ESP.Drawings = {} -- pool of active Drawing objects this frame
ESP.Connections = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local function hasDrawing()
    return typeof(Drawing) == "table" and typeof(Drawing.new) == "function"
end

local ROLE_COLOR = {
    Murderer = Color3.fromRGB(255, 50, 50),
    Sheriff  = Color3.fromRGB(255, 210, 40),
    Innocent = Color3.fromRGB(70, 255, 90),
    Unknown  = Color3.fromRGB(200, 200, 200),
}

function ESP:GetRole(player)
    if not player then return "Unknown" end
    local char = player.Character
    local bag = player:FindFirstChild("Backpack")

    local function has(name)
        return (char and char:FindFirstChild(name)) or (bag and bag:FindFirstChild(name))
    end

    if has("Knife") then return "Murderer" end
    if has("Gun") then return "Sheriff" end
    return "Innocent"
end

function ESP:WorldToScreen(pos)
    local cam = workspace.CurrentCamera
    if not cam then return Vector2.zero, false end
    local v = typeof(pos) == "Vector3" and pos or pos.Position
    local sp, on = cam:WorldToViewportPoint(v)
    return Vector2.new(sp.X, sp.Y), on and sp.Z > 0
end

function ESP:Line(from, to, color, thickness)
    if not hasDrawing() then return end
    local l = Drawing.new("Line")
    l.From = from
    l.To = to
    l.Color = color
    l.Thickness = thickness or 1.5
    l.Transparency = 1
    l.Visible = true
    l.ZIndex = 2
    table.insert(self.Drawings, l)
end

function ESP:Label(text, pos, color, size)
    if not hasDrawing() then return end
    local t = Drawing.new("Text")
    t.Text = text
    t.Position = pos
    t.Color = color
    t.Size = size or 14
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.new(0, 0, 0)
    t.Font = (Drawing.Fonts and Drawing.Fonts.UI) or 0
    t.Transparency = 1
    t.Visible = true
    t.ZIndex = 3
    table.insert(self.Drawings, t)
end

function ESP:Clear()
    for _, d in ipairs(self.Drawings) do
        pcall(function() d:Destroy() end)
    end
    table.clear(self.Drawings)
end

function ESP:Box2D(hrp, color)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, on = self:WorldToScreen(hrp.Position)
    if not on then return end

    local dist = (cam.CFrame.Position - hrp.Position).Magnitude
    local scale = math.clamp(900 / dist, 6, 90)
    local w, h = scale * 0.85, scale * 1.55
    local x, y = sp.X, sp.Y

    self:Line(Vector2.new(x - w, y - h), Vector2.new(x + w, y - h), color)
    self:Line(Vector2.new(x - w, y + h), Vector2.new(x + w, y + h), color)
    self:Line(Vector2.new(x - w, y - h), Vector2.new(x - w, y + h), color)
    self:Line(Vector2.new(x + w, y - h), Vector2.new(x + w, y + h), color)
end

function ESP:BoxCorner(hrp, color)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, on = self:WorldToScreen(hrp.Position)
    if not on then return end

    local dist = (cam.CFrame.Position - hrp.Position).Magnitude
    local scale = math.clamp(900 / dist, 6, 90)
    local w, h = scale * 0.85, scale * 1.55
    local c = math.min(w * 0.35, h * 0.25)
    local x, y = sp.X, sp.Y

    -- TL
    self:Line(Vector2.new(x - w, y - h), Vector2.new(x - w + c, y - h), color)
    self:Line(Vector2.new(x - w, y - h), Vector2.new(x - w, y - h + c), color)
    -- TR
    self:Line(Vector2.new(x + w - c, y - h), Vector2.new(x + w, y - h), color)
    self:Line(Vector2.new(x + w, y - h), Vector2.new(x + w, y - h + c), color)
    -- BL
    self:Line(Vector2.new(x - w, y + h - c), Vector2.new(x - w, y + h), color)
    self:Line(Vector2.new(x - w, y + h), Vector2.new(x - w + c, y + h), color)
    -- BR
    self:Line(Vector2.new(x + w - c, y + h), Vector2.new(x + w, y + h), color)
    self:Line(Vector2.new(x + w, y + h - c), Vector2.new(x + w, y + h), color)
end

function ESP:Box3D(hrp, color)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, on = self:WorldToScreen(hrp.Position)
    if not on then return end

    local dist = (cam.CFrame.Position - hrp.Position).Magnitude
    local scale = math.clamp(900 / dist, 6, 90)
    local w, h = scale * 0.85, scale * 1.55
    local d = w * 0.35
    local x, y = sp.X, sp.Y

    local f = {
        Vector2.new(x - w, y - h), Vector2.new(x + w, y - h),
        Vector2.new(x + w, y + h), Vector2.new(x - w, y + h),
    }
    local b = {
        Vector2.new(x - w + d, y - h + d), Vector2.new(x + w + d, y - h + d),
        Vector2.new(x + w + d, y + h + d), Vector2.new(x - w + d, y + h + d),
    }

    for i = 1, 4 do
        local n = i % 4 + 1
        self:Line(f[i], f[n], color, 1.5)
        self:Line(b[i], b[n], color, 1)
        self:Line(f[i], b[i], color, 1)
    end
end

function ESP:Tracer(hrp, color)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, on = self:WorldToScreen(hrp.Position)
    if not on then return end
    local bottom = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
    self:Line(bottom, sp, color, 1.5)
end

function ESP:RoleText(hrp, role, color)
    local cam = workspace.CurrentCamera
    if not cam then return end
    local sp, on = self:WorldToScreen(hrp.Position)
    if not on then return end
    local dist = (cam.CFrame.Position - hrp.Position).Magnitude
    local scale = math.clamp(900 / dist, 6, 90)
    self:Label(role, Vector2.new(sp.X, sp.Y + scale * 1.7), color, math.clamp(scale * 0.5, 12, 16))
end

function ESP:Skeleton(char, color)
    local function part(...)
        for _, name in ipairs({ ... }) do
            local p = char:FindFirstChild(name)
            if p and p:IsA("BasePart") then return p end
        end
        return nil
    end

    local function bone(a, b)
        if not a or not b then return end
        local p1, o1 = self:WorldToScreen(a.Position)
        local p2, o2 = self:WorldToScreen(b.Position)
        if o1 and o2 then
            self:Line(p1, p2, color, 1.2)
        end
    end

    local head = part("Head")
    local upper = part("UpperTorso", "Torso")
    local lower = part("LowerTorso")
    local lua = part("LeftUpperArm", "Left Arm")
    local rua = part("RightUpperArm", "Right Arm")
    local lla = part("LeftLowerArm")
    local rla = part("RightLowerArm")
    local lh = part("LeftHand")
    local rh = part("RightHand")
    local lul = part("LeftUpperLeg", "Left Leg")
    local rul = part("RightUpperLeg", "Right Leg")
    local lll = part("LeftLowerLeg")
    local rll = part("RightLowerLeg")
    local lf = part("LeftFoot")
    local rf = part("RightFoot")

    bone(head, upper)
    bone(upper, lower)

    bone(upper, lua)
    bone(lua, lla)
    bone(lla or lua, lh)

    bone(upper, rua)
    bone(rua, rla)
    bone(rla or rua, rh)

    local hip = lower or upper
    bone(hip, lul)
    bone(lul, lll)
    bone(lll or lul, lf)

    bone(hip, rul)
    bone(rul, rll)
    bone(rll or rul, rf)
end

function ESP:Update()
    self:Clear()
    if not self.Settings.enabled then return end
    if not hasDrawing() then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then continue end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then continue end

        local role = self:GetRole(plr)
        local color = ROLE_COLOR[role] or ROLE_COLOR.Unknown

        if self.Settings.box then
            if self.Settings.boxStyle == "corner" then
                self:BoxCorner(hrp, color)
            elseif self.Settings.boxStyle == "3d" then
                self:Box3D(hrp, color)
            else
                self:Box2D(hrp, color)
            end
        end

        if self.Settings.skeleton then
            self:Skeleton(char, color)
        end

        if self.Settings.tracer then
            self:Tracer(hrp, color)
        end

        if self.Settings.role then
            self:RoleText(hrp, role, color)
        end
    end
end

function ESP:Init()
    self:Destroy()

    self.Connections.render = RunService.RenderStepped:Connect(function()
        self:Update()
    end)
end

function ESP:Destroy()
    self:Clear()
    self.Settings.enabled = false

    for _, conn in pairs(self.Connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    table.clear(self.Connections)
end

return ESP
