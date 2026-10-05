-- =========================================================
-- SZKHUB — FLUX WIND UI EDITION
-- MADE BY SZK
-- =========================================================

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local LP = LocalPlayer
local camera = workspace.CurrentCamera
local cam = camera

local parent
if gethui then parent = gethui()
else
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok then parent = core else parent = LocalPlayer:WaitForChild("PlayerGui") end
end
local CORE = parent

local vp = camera.ViewportSize
local screenW, screenH = vp.X, vp.Y

-- =========================================================
-- CONSTANTES
-- =========================================================
local SCRIPT_NAME    = "SZKHUB"
local SCRIPT_VERSION = "v1.7.0"
local LAST_UPDATE    = "05/10/2026"
local DISCORD_LINK   = "https://discord.gg/gRzA4bsTxv"
local GAME_NAME      = "Murderers vs Sheriffs Duels"

local WIN_W = math.min(620, math.floor(screenW * 0.94))
local WIN_H = math.min(640, math.floor(screenH * 0.9))
local BALL_SIZE = 48
local SIDEBAR_W = 120

-- =========================================================
-- TEMA
-- =========================================================
local Theme = {
    Background    = Color3.fromRGB(8, 8, 12),
    Background2   = Color3.fromRGB(15, 15, 22),
    Sidebar       = Color3.fromRGB(12, 12, 18),
    Card          = Color3.fromRGB(20, 20, 28),
    Card2         = Color3.fromRGB(15, 15, 22),
    Section       = Color3.fromRGB(28, 28, 40),
    Border        = Color3.fromRGB(50, 50, 65),
    Stroke        = Color3.fromRGB(60, 65, 95),
    Text          = Color3.fromRGB(245, 245, 255),
    TextDim       = Color3.fromRGB(150, 150, 165),
    TextMuted     = Color3.fromRGB(100, 100, 115),
    Accent        = Color3.fromRGB(130, 110, 255),
    Accent2       = Color3.fromRGB(0, 220, 255),
    Success       = Color3.fromRGB(0, 230, 150),
    Warning       = Color3.fromRGB(250, 200, 45),
    Danger        = Color3.fromRGB(255, 80, 110),
    Inactive      = Color3.fromRGB(40, 44, 64),
}

-- =========================================================
-- HELPERS UI
-- =========================================================
local function addCorner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p
    return c
end

local function addStroke(p, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function addGradient(p, c1, c2, rotation)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rotation or 90
    g.Parent = p
    return g
end

local function createLabel(parent, text, size, pos, color, font, textSize)
    local l = Instance.new("TextLabel")
    l.Size = size; l.Position = pos
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = color or Theme.Text
    l.Font = font or Enum.Font.Gotham
    l.TextSize = textSize or 10
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = parent
    return l
end

local function tween(obj, props, time, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(time or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
    t:Play(); return t
end

local function Notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration or 3,
        })
    end)
end

-- =========================================================
-- ESTADO SZKHUB
-- =========================================================
local SZK = {
    GlobalFov = 300,
    SilentAim  = {Enabled=false, Keybind=Enum.KeyCode.Q, Target="Cabeza", UseFovLimit=true, WallCheck=true, MaxDistance=5000, FovSize=300, _toggled=false},
    AutoShoot  = {Enabled=false, Keybind=Enum.KeyCode.E, Target="Cabeza", UseFovLimit=true, WallCheck=true, MaxDistance=5000, FovSize=300, ShootDelay=0.15, ActivateTime=0.05, _toggled=false, _lastShot=0},
    TriggerBot = {Enabled=false, Keybind=Enum.KeyCode.T, AutoEquip=true, AutoShoot=true, UnequipNoEnemy=true, PreferFirearm=true, DropMelee=true, Target="Cabeza", UseFovLimit=true, FovSize=300, WallCheck=true, MaxDistance=5000, ShootDelay=0.04, ActivateTime=0.02, _toggled=false, _lastShot=0, _weaponEquipped=nil, _shots=0},
    Settings   = {ShowFovCircle=true, ButtonsLocked=false},
    ESP = {
        Enabled=false, Highlight=false, Box=false, FillBox=false, Skeleton=false, HeadDot=false, Name=false,
        Distance=false, Health=false, Tracer=false, TracerOrigin="Bottom",
        ShowTeammates=false, TeamColor=Color3.fromRGB(0,255,100), EnemyColor=Color3.fromRGB(255,80,110),
        MaxDistance=1500
    },
    AutoFarm = {Enabled=false, _loopRunning=false},
    KnifeBot = {Enabled=false, TargetPart="Cabeza"},
    Macro    = {Enabled=false, Target="Cabeza", MaxDistance=5000, WallCheck=true, Cooldown=0.2, AutoEquip=true, _lastUse=0},
    Aimbot   = {Enabled=false, OnlyGun=true, ShowFOV=false, TargetPart="Cabeza", AimMode="FOV", Smoothness=0.9, Prediction=true, PredictionScale=0.7},
    Keybinds = {ESP=nil, TriggerBot=nil, SilentAim=nil, Aimbot=nil},
    Hitbox   = {Enabled=false, Size=15},
    Speed    = {Enabled=false, Multiplier=0.5, _loop=nil},
    Anim     = {Enabled=false, Selected=nil, Mix={Idle="None",Walk="None",Run="None",Jump="None",Fall="None",Climb="None"}, AutoMix=false},
    Sky      = {Selected="None"},
}
local genv = getgenv and getgenv() or _G
genv.SZK = SZK

local STATE_COLORS = {
    Lobby = Color3.fromRGB(150, 150, 160),
    Clear = Color3.fromRGB(0, 230, 150),
    Enemy = Color3.fromRGB(255, 80, 110),
}
local currentStateColor = STATE_COLORS.Lobby
local ENEMY_COLOR = Color3.fromRGB(255, 80, 110)
local TEAM_COLOR  = Color3.fromRGB(0, 255, 100)

genv.SZK_Target = nil
genv.SZK_ShotTarget = nil
genv.SZK_KnifeTarget = nil
genv.SZK_EquippedAccessories = genv.SZK_EquippedAccessories or {}
genv.SZK_HeadlessOn = false
genv.SZK_KorbloxOn = false

-- =========================================================
-- TEAM CHECK
-- =========================================================
local function getScoreboard()
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    local main = pg:FindFirstChild("Main")
    if not main then return nil end
    local frame = main:FindFirstChild("MainGameFrame")
    if not frame then return nil end
    return frame:FindFirstChild("IngameScore")
end

local function refreshTeams()
    local snap = {}
    local score = getScoreboard()
    if score then
        for _, fName in ipairs({"TeamRed","TeamBlue"}) do
            local folder = score:FindFirstChild(fName)
            if folder then
                local team = (fName == "TeamRed") and "Red" or "Blue"
                for _, entry in ipairs(folder:GetChildren()) do
                    snap[string.lower(entry.Name)] = team
                end
            end
        end
    end
    return snap
end

local function getPlayerTeam(target)
    if not target then return nil end
    local snap = refreshTeams()
    local t = snap[string.lower(target.Name)]
    if not t and target.DisplayName then t = snap[string.lower(target.DisplayName)] end
    return t
end

local function IsSameTeam(plr)
    if not plr then return false end
    local a = getPlayerTeam(LP); local b = getPlayerTeam(plr)
    if not a or not b then return false end
    return a == b
end

local function InGame()
    if not LP then return false end
    local pg = LP:FindFirstChild("PlayerGui")
    local main = pg and (pg:FindFirstChild("Main") or pg)
    local frame = main and main:FindFirstChild("MainGameFrame")
    local score = frame and frame:FindFirstChild("IngameScore")
    local timer = score and score:FindFirstChild("Timer")
    if timer then
        local txt = tostring(timer.Text or ""):match("^%s*%d+:%d%d%s*$")
        if txt then return true end
    end
    local gA = LP:GetAttribute("Game"); local mA = LP:GetAttribute("Map")
    if typeof(gA) == "string" and gA ~= "" and typeof(mA) == "string" and mA ~= "" then return true end
    return false
end

-- =========================================================
-- HELPERS JUGADOR
-- =========================================================
local function GetHRP(plr)
    local c = plr and plr.Character
    if not c then return nil end
    local h = c:FindFirstChild("HumanoidRootPart")
    return (h and h:IsA("BasePart")) and h or nil
end

local function IsAlive(plr)
    local c = plr and plr.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function IsEnemy(plr)
    if not plr or plr == LP then return false end
    if not plr.Character then return false end
    if IsSameTeam(plr) then return false end
    return IsAlive(plr)
end

local function GetParts(plr, mode)
    local char = plr and plr.Character
    if not char then return {} end
    local names
    if mode == "Cabeza" then names = {"Head"}
    elseif mode == "Torso" then names = {"UpperTorso","LowerTorso","Torso"}
    else names = {"Head","UpperTorso","LowerTorso","Torso","LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg"} end
    local out = {}
    for _, n in ipairs(names) do
        local p = char:FindFirstChild(n)
        if p and p:IsA("BasePart") then out[#out+1] = p end
    end
    return out
end

local function FindBestTarget(cfg)
    local char = LP.Character
    local myHRP = GetHRP(LP)
    if not char or not myHRP then return nil end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local myPos = myHRP.Position
    local cx, cy = cam.ViewportSize.X/2, cam.ViewportSize.Y/2
    local fovLimit = cfg.FovSize or SZK.GlobalFov
    local best, bestScore, bestName = nil, math.huge, nil
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsEnemy(plr) then
            params.FilterDescendantsInstances = {char, plr.Character}
            for _, part in ipairs(GetParts(plr, cfg.Target)) do
                local dist = (part.Position - myPos).Magnitude
                if dist <= cfg.MaxDistance then
                    local sp, on = cam:WorldToViewportPoint(part.Position)
                    if on and sp.Z > 0 then
                        local sd = (Vector2.new(sp.X, sp.Y) - Vector2.new(cx, cy)).Magnitude
                        if not cfg.UseFovLimit or sd <= fovLimit then
                            local score = sd + dist*0.05
                            if score < bestScore then
                                local visible = true
                                if cfg.WallCheck then
                                    local ray = workspace:Raycast(myPos, part.Position - myPos, params)
                                    visible = (ray == nil)
                                end
                                if visible then bestScore, best, bestName = score, part, plr.Name end
                            end
                        end
                    end
                end
            end
        end
    end
    return best, bestName
end

-- =========================================================
-- ARMAS
-- =========================================================
local FIREARM_KEYWORDS = {"gun","pistol","rifle","smg","shotgun","sniper","revolver","glock","deagle","awp","ak","m4","mp5","uzi","tec","firearm","handgun","carbine","machinegun","lmg","dmr","ar15","scar","famas","aug","vector","p90"}
local MELEE_KEYWORDS = {"knife","sword","blade","dagger","machete","axe","bat","hammer","crowbar","katana","scythe","spear","melee","fist","punch","combat","stick","club","wrench"}

local function NameContains(name, list)
    local l = string.lower(name)
    for _, kw in ipairs(list) do if string.find(l, kw, 1, true) then return true end end
    return false
end
local function IsFirearm(tool)
    if not tool then return nil end
    if NameContains(tool.Name, FIREARM_KEYWORDS) then return true end
    if NameContains(tool.Name, MELEE_KEYWORDS) then return false end
    return nil
end
local function IsMelee(tool) if not tool then return false end return IsFirearm(tool) == false end

local function FindWeaponInBackpack(prefer)
    local char = LP.Character
    if not char then return nil end
    local equipped = char:FindFirstChildOfClass("Tool")
    local bp = LP:FindFirstChildOfClass("Backpack")
    local list = {}
    if equipped then list[#list+1] = {tool=equipped, eq=true} end
    if bp then
        for _, i in ipairs(bp:GetChildren()) do
            if i:IsA("Tool") then list[#list+1] = {tool=i, eq=false} end
        end
    end
    if #list == 0 then return nil end
    if prefer then
        for _, e in ipairs(list) do if e.eq and IsFirearm(e.tool) == true then return e.tool end end
        for _, e in ipairs(list) do if not e.eq and IsFirearm(e.tool) == true then return e.tool end end
    end
    for _, e in ipairs(list) do if e.eq then return e.tool end end
    for _, e in ipairs(list) do return e.tool end
    return nil
end
local function EquipTool(tool)
    local char = LP.Character
    if not char or not tool then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    pcall(function() hum:EquipTool(tool) end)
    return true
end
local function UnequipCurrentTool()
    local char = LP.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    pcall(function() hum:UnequipTools() end)
    return true
end

-- =========================================================
-- FOV CIRCLE
-- =========================================================
local FovGui = Instance.new("ScreenGui", CORE)
FovGui.Name = "SZK_fov"
FovGui.ResetOnSpawn = false
FovGui.IgnoreGuiInset = true
FovGui.DisplayOrder = 5

local FovFrame = Instance.new("Frame", FovGui)
FovFrame.AnchorPoint = Vector2.new(0.5,0.5)
FovFrame.BackgroundTransparency = 1
FovFrame.BorderSizePixel = 0
FovFrame.Visible = false
Instance.new("UICorner", FovFrame).CornerRadius = UDim.new(1,0)
local FovStroke = Instance.new("UIStroke", FovFrame)
FovStroke.Color = Theme.Accent
FovStroke.Thickness = 2

local function HasVisibleEnemy()
    if not InGame() then return false end
    local myHRP = GetHRP(LP)
    if not myHRP then return false end
    for _, plr in ipairs(Players:GetPlayers()) do
        if IsEnemy(plr) then
            local eChar = plr.Character
            local part = eChar and (eChar:FindFirstChild("Head") or eChar:FindFirstChild("HumanoidRootPart"))
            if part then
                local sp, on = cam:WorldToViewportPoint(part.Position)
                if on and sp.Z > 0 then return true end
            end
        end
    end
    return false
end

local function UpdateStateColor()
    if not InGame() then currentStateColor = STATE_COLORS.Lobby
    elseif HasVisibleEnemy() then currentStateColor = STATE_COLORS.Enemy
    else currentStateColor = STATE_COLORS.Clear end
end

RunService.RenderStepped:Connect(function()
    UpdateStateColor()
    local center = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
    local radius = SZK.GlobalFov
    local anyActive = SZK.SilentAim._toggled or SZK.AutoShoot._toggled or SZK.TriggerBot._toggled or SZK.Aimbot.Enabled
    FovFrame.Position = UDim2.fromOffset(center.X, center.Y)
    FovFrame.Size = UDim2.fromOffset(radius*2, radius*2)
    FovStroke.Color = currentStateColor
    FovFrame.Visible = SZK.Settings.ShowFovCircle and anyActive
end)

-- =========================================================
-- ESP
-- =========================================================
local EspGui = Instance.new("ScreenGui", CORE)
EspGui.Name = "SZK_esp"
EspGui.ResetOnSpawn = false
EspGui.IgnoreGuiInset = true
EspGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local ESP_Data = {}
local vpSize = cam.ViewportSize
cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() vpSize = cam.ViewportSize end)

local function setLine(f, from, to, thick)
    local dx, dy = to.X - from.X, to.Y - from.Y
    local dist = math.sqrt(dx*dx + dy*dy)
    if dist < 0.5 then f.Visible = false; return end
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Size = UDim2.new(0, dist, 0, thick or 2)
    f.Position = UDim2.new(0, (from.X+to.X)/2, 0, (from.Y+to.Y)/2)
    f.Rotation = math.deg(math.atan2(dy, dx))
    f.Visible = true
end

local function destroyESP(plr)
    local d = ESP_Data[plr]
    if not d then return end
    if d.hl then pcall(function() d.hl:Destroy() end) end
    if d.bb then pcall(function() d.bb:Destroy() end) end
    if d.box then pcall(function() d.box:Destroy() end) end
    if d.tracer then pcall(function() d.tracer:Destroy() end) end
    if d.headDot then pcall(function() d.headDot:Destroy() end) end
    if d.skel then for _, l in ipairs(d.skel) do pcall(function() l:Destroy() end) end end
    ESP_Data[plr] = nil
end

local SKELETON_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKELETON_R6 = {{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"}}

local FontB = Enum.Font.GothamBold
local FontM = Enum.Font.GothamMedium

local function createESP(plr)
    if plr == LP then return end
    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    if not hrp or not head then return end
    destroyESP(plr)
    local d = {skel={}}
    ESP_Data[plr] = d

    d.hl = Instance.new("Highlight", CORE)
    d.hl.FillColor = ENEMY_COLOR
    d.hl.OutlineColor = Color3.fromRGB(255,255,255)
    d.hl.FillTransparency = 0.8
    d.hl.OutlineTransparency = 0.4
    d.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    d.hl.Adornee = char

    local bb = Instance.new("BillboardGui", CORE)
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.Adornee = head
    bb.ResetOnSpawn = false
    bb.LightInfluence = 0
    bb.MaxDistance = 500
    bb.Enabled = true
    d.bb = bb

    d.name = Instance.new("TextLabel", bb)
    d.name.Size = UDim2.new(1, 0, 0, 18)
    d.name.BackgroundTransparency = 1
    d.name.Text = plr.Name
    d.name.TextColor3 = Color3.fromRGB(255, 255, 255)
    d.name.Font = FontB
    d.name.TextSize = 13
    d.name.TextStrokeTransparency = 0

    d.dist = Instance.new("TextLabel", bb)
    d.dist.Size = UDim2.new(1, 0, 0, 12)
    d.dist.Position = UDim2.new(0, 0, 0, 18)
    d.dist.BackgroundTransparency = 1
    d.dist.Text = "0m"
    d.dist.TextColor3 = ENEMY_COLOR
    d.dist.Font = FontM
    d.dist.TextSize = 10
    d.dist.TextStrokeTransparency = 0

    local hpBg = Instance.new("Frame", bb)
    hpBg.Name = "HpBg"
    hpBg.Size = UDim2.new(0, 70, 0, 5)
    hpBg.Position = UDim2.new(0.5, -35, 0, 34)
    hpBg.BackgroundColor3 = Color3.fromRGB(20,20,20)
    hpBg.BorderSizePixel = 0
    Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)
    d.hp = Instance.new("Frame", hpBg)
    d.hp.Size = UDim2.new(1, 0, 1, 0)
    d.hp.BackgroundColor3 = Theme.Success
    d.hp.BorderSizePixel = 0
    Instance.new("UICorner", d.hp).CornerRadius = UDim.new(0, 3)

    d.box = Instance.new("Frame", EspGui)
    d.box.BackgroundTransparency = 1
    d.box.BorderSizePixel = 0
    d.box.Visible = false
    d.box.ZIndex = 2
    Instance.new("UICorner", d.box).CornerRadius = UDim.new(0, 4)
    d.boxStroke = Instance.new("UIStroke", d.box)
    d.boxStroke.Color = ENEMY_COLOR
    d.boxStroke.Thickness = 2
    d.boxFill = Instance.new("Frame", d.box)
    d.boxFill.Size = UDim2.new(1, 0, 1, 0)
    d.boxFill.BackgroundColor3 = ENEMY_COLOR
    d.boxFill.BackgroundTransparency = 0.8
    d.boxFill.BorderSizePixel = 0
    d.boxFill.Visible = false
    d.boxFill.ZIndex = 1
    Instance.new("UICorner", d.boxFill).CornerRadius = UDim.new(0, 4)

    d.headDot = Instance.new("Frame", EspGui)
    d.headDot.Size = UDim2.new(0, 8, 0, 8)
    d.headDot.BackgroundColor3 = ENEMY_COLOR
    d.headDot.BorderSizePixel = 0
    d.headDot.Visible = false
    d.headDot.ZIndex = 4
    Instance.new("UICorner", d.headDot).CornerRadius = UDim.new(1, 0)
    local hdSt = Instance.new("UIStroke", d.headDot)
    hdSt.Color = Color3.fromRGB(255,255,255)
    hdSt.Thickness = 1

    d.tracer = Instance.new("Frame", EspGui)
    d.tracer.BackgroundColor3 = ENEMY_COLOR
    d.tracer.BorderSizePixel = 0
    d.tracer.Visible = false
    d.tracer.ZIndex = 1

    local bones = char:FindFirstChild("UpperTorso") and SKELETON_R15 or SKELETON_R6
    d.bones = bones
    for i = 1, #bones do
        local ln = Instance.new("Frame", EspGui)
        ln.BackgroundColor3 = ENEMY_COLOR
        ln.BorderSizePixel = 0
        ln.Visible = false
        ln.ZIndex = 3
        Instance.new("UICorner", ln).CornerRadius = UDim.new(1, 0)
        d.skel[i] = ln
    end
end

local function getScreenBounds(char)
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not head or not hrp or not hum then return nil end
    local topPos = head.Position + Vector3.new(0, 0.6, 0)
    local hipH = hum.HipHeight or 2
    local bottomPos = hrp.Position - Vector3.new(0, hipH - 0.2, 0)
    local spT, onT = cam:WorldToViewportPoint(topPos)
    local spB, onB = cam:WorldToViewportPoint(bottomPos)
    local spH, onH = cam:WorldToViewportPoint(hrp.Position)
    if spT.Z <= 0 or spB.Z <= 0 or spH.Z <= 0 then return nil end
    if not onT and not onB and not onH then return nil end
    local height = math.abs(spB.Y - spT.Y)
    if height < 5 then return nil end
    local width = height * 0.55
    return spH.X - width/2, spT.Y, spH.X + width/2, spT.Y + height
end

local function hideESP(d)
    if d.hl then d.hl.Enabled = false end
    if d.bb then d.bb.Enabled = false end
    if d.box then d.box.Visible = false end
    if d.tracer then d.tracer.Visible = false end
    if d.headDot then d.headDot.Visible = false end
    if d.skel then for _, l in ipairs(d.skel) do l.Visible = false end end
end

local function updateESP()
    local myHRP = GetHRP(LP)
    if not myHRP then return end
    local myPos = myHRP.Position
    for plr, d in pairs(ESP_Data) do
        local teammate = IsSameTeam(plr)
        local active = SZK.ESP.Enabled
        if teammate and not SZK.ESP.ShowTeammates then active = false end
        local targetColor = teammate and TEAM_COLOR or ENEMY_COLOR
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local head = char and char:FindFirstChild("Head")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local distance = (hrp and myHRP) and (hrp.Position - myPos).Magnitude or 0
        local tooFar = distance > SZK.ESP.MaxDistance
        if not char or not hum or hum.Health <= 0 then destroyESP(plr)
        elseif not active or not hrp or not head or tooFar then hideESP(d)
        else
            if d.hl then d.hl.Enabled = SZK.ESP.Highlight; d.hl.FillColor = targetColor end
            if d.bb then
                d.bb.Enabled = (SZK.ESP.Name or SZK.ESP.Distance or SZK.ESP.Health)
                if d.name then d.name.Visible = SZK.ESP.Name; d.name.TextColor3 = targetColor end
                if d.dist then
                    d.dist.Visible = SZK.ESP.Distance
                    if SZK.ESP.Distance then
                        d.dist.Text = string.format("%dm", math.floor(distance))
                        d.dist.TextColor3 = targetColor
                    end
                end
                local hpBg = d.bb:FindFirstChild("HpBg")
                if hpBg then
                    hpBg.Visible = SZK.ESP.Health
                    if SZK.ESP.Health and d.hp then
                        local pct = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        d.hp.Size = UDim2.new(pct, 0, 1, 0)
                        d.hp.BackgroundColor3 = Color3.fromRGB(math.floor(255*(1-pct)), math.floor(255*pct), 60)
                    end
                end
            end
            if d.box then
                if SZK.ESP.Box then
                    local x1,y1,x2,y2 = getScreenBounds(char)
                    if x1 then
                        d.box.Position = UDim2.new(0, x1, 0, y1)
                        d.box.Size = UDim2.new(0, math.max(x2-x1,1), 0, math.max(y2-y1,1))
                        d.box.Visible = true
                        if d.boxStroke then d.boxStroke.Color = targetColor end
                        if d.boxFill then d.boxFill.Visible = SZK.ESP.FillBox; d.boxFill.BackgroundColor3 = targetColor end
                    else d.box.Visible = false end
                else d.box.Visible = false end
            end
            if d.headDot then
                if SZK.ESP.HeadDot then
                    local sp, on = cam:WorldToViewportPoint(head.Position)
                    if on and sp.Z > 0 then
                        d.headDot.Position = UDim2.new(0, sp.X-4, 0, sp.Y-4)
                        d.headDot.BackgroundColor3 = targetColor
                        d.headDot.Visible = true
                    else d.headDot.Visible = false end
                else d.headDot.Visible = false end
            end
            if d.bones then
                for i, pair in ipairs(d.bones) do
                    local ln = d.skel[i]
                    if ln then
                        if SZK.ESP.Skeleton then
                            local a = char:FindFirstChild(pair[1])
                            local b = char:FindFirstChild(pair[2])
                            if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
                                local sa, onA = cam:WorldToViewportPoint(a.Position)
                                local sb, onB = cam:WorldToViewportPoint(b.Position)
                                if sa.Z > 0 and sb.Z > 0 and onA and onB then
                                    setLine(ln, Vector2.new(sa.X, sa.Y), Vector2.new(sb.X, sb.Y), 1.5)
                                    ln.BackgroundColor3 = targetColor
                                else ln.Visible = false end
                            else ln.Visible = false end
                        else ln.Visible = false end
                    end
                end
            end
            if d.tracer then
                if SZK.ESP.Tracer then
                    local sp, on = cam:WorldToViewportPoint(hrp.Position)
                    if on and sp.Z > 0 then
                        local origin = Vector2.new(vpSize.X/2, vpSize.Y)
                        if SZK.ESP.TracerOrigin == "Top" then origin = Vector2.new(vpSize.X/2, 0)
                        elseif SZK.ESP.TracerOrigin == "Center" then origin = Vector2.new(vpSize.X/2, vpSize.Y/2) end
                        setLine(d.tracer, origin, Vector2.new(sp.X, sp.Y), 1.5)
                        d.tracer.BackgroundColor3 = targetColor
                    else d.tracer.Visible = false end
                else d.tracer.Visible = false end
            end
        end
    end
end

local function setupPlayerESP(plr)
    if plr == LP then return end
    plr.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart", 5)
        local head = char:WaitForChild("Head", 5)
        if hrp and head then createESP(plr) end
    end)
    plr.CharacterRemoving:Connect(function() destroyESP(plr) end)
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Head") then
        createESP(plr)
    end
end
for _, p in ipairs(Players:GetPlayers()) do setupPlayerESP(p) end
Players.PlayerAdded:Connect(setupPlayerESP)
Players.PlayerRemoving:Connect(destroyESP)

local function rebuildAllESP()
    for plr in pairs(ESP_Data) do destroyESP(plr) end
    if SZK.ESP.Enabled then
        for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LP and plr.Character then createESP(plr) end end
    end
end
RunService.RenderStepped:Connect(updateESP)
task.spawn(function()
    while task.wait(1) do
        for plr, _ in pairs(ESP_Data) do
            local char = plr.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not char or not hum or hum.Health <= 0 then destroyESP(plr) end
        end
    end
end)

-- =========================================================
-- HEADLESS / KORBLOX / ACCESORIOS
-- =========================================================
local AvatarBackup = {Headless=nil, Korblox=nil}
local LoadAccessoryToPlayer, RemoveAccessoryByID

local function ApplyHeadless()
    local char = LP.Character; if not char then return false end
    local head = char:FindFirstChild("Head"); if not head then return false end
    if not AvatarBackup.Headless then
        AvatarBackup.Headless = {trans=head.Transparency, kids={}}
        for _, v in ipairs(head:GetChildren()) do
            if v:IsA("Decal") or v:IsA("Texture") or v:IsA("SpecialMesh") then
                AvatarBackup.Headless.kids[v] = v.Transparency
            end
        end
    end
    pcall(function()
        head.Transparency = 1
        for _, v in ipairs(head:GetChildren()) do
            if v:IsA("Decal") or v:IsA("Texture") or v:IsA("SpecialMesh") then v.Transparency = 1 end
        end
    end)
    return true
end
local function RemoveHeadless()
    local char = LP.Character; if not char then return false end
    local head = char:FindFirstChild("Head"); if not head then return false end
    pcall(function()
        if AvatarBackup.Headless then
            head.Transparency = AvatarBackup.Headless.trans or 0
            for c, t in pairs(AvatarBackup.Headless.kids) do if c and c.Parent then c.Transparency = t end end
        else
            head.Transparency = 0
            for _, v in ipairs(head:GetChildren()) do
                if v:IsA("Decal") or v:IsA("Texture") or v:IsA("SpecialMesh") then v.Transparency = 0 end
            end
        end
    end)
    return true
end

local function ApplyKorblox()
    local char = LP.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    if not AvatarBackup.Korblox then
        AvatarBackup.Korblox = {parts={}, meshes={}}
        if hum.RigType == Enum.HumanoidRigType.R15 then
            for _, n in ipairs({"RightFoot","RightLowerLeg","RightUpperLeg"}) do
                local p = char:FindFirstChild(n)
                if p then AvatarBackup.Korblox.parts[p] = {t=p.Transparency, c=p.Color} end
            end
            local rul = char:FindFirstChild("RightUpperLeg")
            if rul then AvatarBackup.Korblox.meshes[rul] = {MeshId=rul.MeshId or "", TextureID=rul.TextureID or "", Color=rul.Color} end
        else
            local rl = char:FindFirstChild("Right Leg")
            if rl then
                AvatarBackup.Korblox.parts[rl] = {t=rl.Transparency, c=rl.Color}
                local mesh = rl:FindFirstChildOfClass("SpecialMesh")
                if mesh then AvatarBackup.Korblox.meshes[rl] = {MeshType=mesh.MeshType, MeshId=mesh.MeshId, TextureId=mesh.TextureId, Scale=mesh.Scale} end
            end
        end
    end
    pcall(function()
        if hum.RigType == Enum.HumanoidRigType.R15 then
            local rf = char:FindFirstChild("RightFoot"); local rll = char:FindFirstChild("RightLowerLeg"); local rul = char:FindFirstChild("RightUpperLeg")
            if rf then rf.Transparency = 1 end
            if rll then rll.Transparency = 1 end
            if rul then rul.MeshId = "rbxassetid://902942096"; rul.TextureID = "rbxassetid://902843398"; rul.Color = Color3.new(1,1,1); rul.Transparency = 0 end
        else
            local rl = char:FindFirstChild("Right Leg")
            if rl then
                for _, v in ipairs(char:GetChildren()) do
                    if v:IsA("CharacterMesh") and v.BodyPart == Enum.BodyPart.RightLeg then v:Destroy() end
                end
                local mesh = rl:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", rl)
                rl.Color = Color3.fromRGB(64,64,64)
                mesh.MeshType = Enum.MeshType.FileMesh
                mesh.MeshId = "rbxassetid://101851696"
                mesh.TextureId = "rbxassetid://101851254"
                mesh.Scale = Vector3.new(1,1,1)
            end
        end
    end)
    return true
end
local function RemoveKorblox()
    local char = LP.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    pcall(function()
        if AvatarBackup.Korblox then
            for p, d in pairs(AvatarBackup.Korblox.parts) do if p and p.Parent then p.Transparency = d.t; p.Color = d.c end end
            for p, d in pairs(AvatarBackup.Korblox.meshes) do
                if p and p.Parent then
                    local mesh = p:FindFirstChildOfClass("SpecialMesh")
                    if mesh then
                        if d.MeshType then mesh.MeshType = d.MeshType end
                        if d.MeshId then mesh.MeshId = d.MeshId end
                        if d.TextureId then mesh.TextureId = d.TextureId end
                        if d.Scale then mesh.Scale = d.Scale end
                    end
                end
            end
        end
    end)
    return true
end

LoadAccessoryToPlayer = function(accId)
    local char = LP.Character; if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
    local ok = pcall(function()
        local s, content = pcall(function() return game:GetObjects("rbxassetid://"..accId) end)
        if not s or not content or not content[1] then return end
        local acc = content[1]
        if not acc:IsA("Accessory") then return end
        for _, o in ipairs(char:GetChildren()) do if o:IsA("Accessory") and o.Name == acc.Name then return end end
        local handle = acc:FindFirstChild("Handle")
        if not handle then acc.Parent = char; return end
        handle.Anchored = false; handle.CanCollide = false
        local att = handle:FindFirstChildOfClass("Attachment")
        local tAtt = nil
        if att then
            for _, bp in ipairs(char:GetChildren()) do
                if bp:IsA("BasePart") then
                    local f = bp:FindFirstChild(att.Name)
                    if f and f:IsA("Attachment") then tAtt = f; break end
                end
            end
        end
        if tAtt then
            handle.CFrame = tAtt.WorldCFrame * att.CFrame:Inverse()
            local w = Instance.new("Weld")
            w.Part0 = tAtt.Parent; w.Part1 = handle
            w.C0 = tAtt.CFrame; w.C1 = att.CFrame
            w.Parent = handle
        else
            local head = char:FindFirstChild("Head")
            if head then
                handle.CFrame = head.CFrame
                local w = Instance.new("Weld")
                w.Part0 = head; w.Part1 = handle
                w.C0 = CFrame.new(); w.C1 = att and att.CFrame or CFrame.new()
                w.Parent = handle
            end
        end
        acc.Parent = char
    end)
    if ok then genv.SZK_EquippedAccessories[accId] = true end
    return ok
end

RemoveAccessoryByID = function(accId)
    local char = LP.Character; if not char then return false end
    local s, content = pcall(function() return game:GetObjects("rbxassetid://"..accId) end)
    if s and content and content[1] then
        local tName = content[1].Name
        for _, o in ipairs(char:GetChildren()) do
            if o:IsA("Accessory") and o.Name == tName then o:Destroy() end
        end
    end
    genv.SZK_EquippedAccessories[accId] = nil
    return true
end

LP.CharacterAdded:Connect(function(char)
    AvatarBackup.Headless = nil
    AvatarBackup.Korblox = nil
    char:WaitForChild("Humanoid", 5)
    char:WaitForChild("HumanoidRootPart", 5)
    char:WaitForChild("Head", 5)
    task.wait(0.9)
    for accId, _ in pairs(genv.SZK_EquippedAccessories) do
        pcall(function() LoadAccessoryToPlayer(accId) end); task.wait(0.1)
    end
    if genv.SZK_HeadlessOn then pcall(ApplyHeadless) end
    if genv.SZK_KorbloxOn then pcall(ApplyKorblox) end
end)

-- =========================================================
-- BOOMBOX
-- =========================================================
local BOOMBOX_SONGS = {
    {name="Song 1",id="rbxassetid://131465489873214"},{name="Song 2",id="rbxassetid://135321902579514"},
    {name="Song 3",id="rbxassetid://128048502331483"},{name="Song 4",id="rbxassetid://115440201770223"},
    {name="Song 5",id="rbxassetid://138863509657081"},{name="Song 6",id="rbxassetid://110398343528156"},
    {name="Song 7",id="rbxassetid://93699644879957"},{name="Song 8",id="rbxassetid://135609653444873"},
    {name="Song 9",id="rbxassetid://75688616622595"},{name="Song 10",id="rbxassetid://71393805905055"},
    {name="Song 11",id="rbxassetid://82746224492420"},{name="Song 12",id="rbxassetid://87570666848900"},
    {name="Song 13",id="rbxassetid://86503267790406"},{name="Song 14",id="rbxassetid://90851490275942"},
    {name="Song 15",id="rbxassetid://86317637164248"},{name="Song 16",id="rbxassetid://110685134112291"},
    {name="Song 17",id="rbxassetid://117810918009991"},{name="Song 18",id="rbxassetid://75793040119604"},
    {name="Song 19",id="rbxassetid://78775217854077"},{name="Song 20",id="rbxassetid://100840031560163"},
    {name="Song 21",id="rbxassetid://104242464450684"},{name="Song 22",id="rbxassetid://81151325045733"},
    {name="Song 23",id="rbxassetid://80735192805425"},{name="Song 24",id="rbxassetid://93930555396098"},
    {name="Song 25",id="rbxassetid://118773510013062"},{name="Song 26",id="rbxassetid://113269872401718"},
    {name="Song 27",id="rbxassetid://117334682026487"},{name="Song 28",id="rbxassetid://99625326669788"},
    {name="Song 29",id="rbxassetid://90859442818485"},
}
local Boombox = Instance.new("Sound", SoundService)
Boombox.Name = "SZK_boombox"
Boombox.Volume = 0.5
Boombox.Looped = true
Boombox.SoundId = BOOMBOX_SONGS[1].id
local BoomboxState = {CurrentSong=BOOMBOX_SONGS[1].id, CurrentName=BOOMBOX_SONGS[1].name, Volume=0.5, Loop=true, Playing=false}

-- =========================================================
-- BACKGROUND LIST
-- =========================================================
local BG_LIST = {
    {name="Background 1",id="rbxassetid://127475690425531"},
    {name="Background 2",id="rbxassetid://138242673369180"},
    {name="Background 3",id="rbxassetid://70609842395967"},
    {name="Background 4",id="rbxassetid://81053303516002"},
    {name="Background 5",id="rbxassetid://130691930643174"},
    {name="Background 6",id="rbxassetid://135414401061463"},
    {name="Background 7",id="rbxassetid://88751579241211"},
    {name="Background 8",id="rbxassetid://104239381391061"},
    {name="Background 9",  id="rbxassetid://99224315720440"},
    {name="Background 10", id="rbxassetid://75102853478391"},
    {name="Background 11", id="rbxassetid://102574649815324"},
    {name="Background 12", id="rbxassetid://97823921818913"},
    {name="Background 13", id="rbxassetid://129712892318094"},
    {name="Background 14", id="rbxassetid://77327983749206"},
    {name="Background 15", id="rbxassetid://70967429484455"},
}

local DEFAULT_BG = "rbxassetid://130691930643174"

-- =========================================================
-- KILL SOUND
-- =========================================================
local KillSound = {
    Enabled = false,
    Selected = "Among Us",
    Volume = 1,
    Options = {"Good", "Among Us", "Arsenal OG"},
    Assets = {
        Good             = "131977397046203",
        ["Among Us"]     = "130456049552264",
        ["Arsenal OG"]   = "88261753232248",
    },
    PlayerConnections = {},
}
genv.SZK_KillSound = KillSound

local function PlayKillSound()
    if not KillSound.Enabled then return end
    local assetId = KillSound.Assets[KillSound.Selected]
    if not assetId then return end
    local sound = Instance.new("Sound")
    sound.Name = "SZK_KillSound"
    sound.SoundId = "rbxassetid://" .. assetId
    sound.Volume = KillSound.Volume
    sound.Parent = SoundService
    sound:Play()
    sound.Ended:Connect(function() if sound.Parent then sound:Destroy() end end)
    game:GetService("Debris"):AddItem(sound, 12)
end

local function RegisterKillSound(targetPlayer)
    if targetPlayer == LP then return end
    local data = KillSound.PlayerConnections[targetPlayer]
    if not data then
        data = {}
        KillSound.PlayerConnections[targetPlayer] = data
    end
    if data.HumanoidConnection then data.HumanoidConnection:Disconnect() end
    if data.CharacterConnection then data.CharacterConnection:Disconnect() end

    local function hookHumanoid()
        local hum = targetPlayer.Character and targetPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            data.HumanoidConnection = hum.Died:Connect(function()
                if KillSound.Enabled and not IsSameTeam(targetPlayer) then
                    PlayKillSound()
                end
            end)
        end
    end

    hookHumanoid()
    data.CharacterConnection = targetPlayer.CharacterAdded:Connect(function()
        task.wait(0.4)
        hookHumanoid()
    end)
end

local function UnregisterKillSound(targetPlayer)
    local data = KillSound.PlayerConnections[targetPlayer]
    if data then
        if data.HumanoidConnection then data.HumanoidConnection:Disconnect() end
        if data.CharacterConnection then data.CharacterConnection:Disconnect() end
    end
    KillSound.PlayerConnections[targetPlayer] = nil
end

for _, p in ipairs(Players:GetPlayers()) do
    RegisterKillSound(p)
end
Players.PlayerAdded:Connect(RegisterKillSound)
Players.PlayerRemoving:Connect(UnregisterKillSound)

-- =========================================================
-- ANIMATION DATA (PACKS)
-- =========================================================
local animationData = {
    ["Old School"] = { Walk = 10921244891, Run = 10921240218, Jump = 10921242013, Fall = 10921241244, SwimIdle = 10921244018, Swim = 10921243048, Idle = 10921230744, Idle2 = 10921232093, Climb = 10921229866 },
    ["Adidas Sports"] = { Walk = 18537392113, Run = 18537384940, Jump = 18537380791, Fall = 18537367238, SwimIdle = 18537387180, Swim = 18537389531, Idle = 18537376492, Idle2 = 18537371272, Climb = 18537363391 },
    ["Adidas Community"] = { Walk = 122150855457006, Run = 82598234841035, Jump = 75290611992385, Fall = 98600215928904, SwimIdle = 109346520324160, Swim = 133308483266208, Idle = 122257458498464, Idle2 = 102357151005774, Climb = 88763136693023 },
    ["Adidas Aura"] = { Walk = 83842218823011, Run = 118320322718866, Jump = 109996626521204, Fall = 95603166884636, SwimIdle = 94922130551805, Swim = 134530128383903, Idle = 110211186840347, Idle2 = 114191137265065, Climb = 97824616490448 },
    ["Wicked Popular"] = { Walk = 92072849924640, Run = 72301599441680, Jump = 104325245285198, Fall = 121152442762481, Idle = 118832222982049, Idle2 = 76049494037641, SwimIdle = 113199415118199, Swim = 99384245425157, Climb = 131326830509784 },
    ["Elder"] = { Walk = 10921111375, Run = 10921104374, Jump = 10921107367, Fall = 10921105765, SwimIdle = 10921110146, Swim = 10921108971, Idle = 10921101664, Idle2 = 10921102574, Climb = 10921100400 },
    ["Zombie"] = { Walk = 10921355261, Run = 616163682, Jump = 10921351278, Fall = 10921350320, SwimIdle = 10921353442, Swim = 10921352344, Idle = 10921344533, Idle2 = 10921345304, Climb = 10921343576 },
    ["Mage"] = { Walk = 10921152678, Run = 10921148209, Jump = 10921149743, Fall = 10921148939, SwimIdle = 10921151661, Swim = 10921150788, Idle = 10921144709, Idle2 = 10921145797, Climb = 10921143404 },
    ["Catwalk Glam"] = { Walk = 109168724482748, Run = 81024476153754, Jump = 116936326516985, Fall = 92294537340807, SwimIdle = 98854111361360, Swim = 134591743181628, Idle = 133806214992291, Idle2 = 94970088341563, Climb = 119377220967554 },
    ["Astronaut"] = { Walk = 10921046031, Run = 10921039308, Jump = 10921042494, Fall = 10921040576, SwimIdle = 10921045006, Swim = 10921044000, Idle = 10921034824, Idle2 = 10921036806, Climb = 10921032124 },
    ['Wicked "Dancing Through Life"'] = { Walk = 73718308412641, Run = 135515454877967, Jump = 78508480717326, Fall = 78147885297412, SwimIdle = 129183123083281, Swim = 110657013921774, Idle = 92849173543269, Idle2 = 132238900951109, Climb = 129447497744818 },
    ["Werewolf"] = { Walk = 10921342074, Run = 10921336997, Jump = 10921339274, Fall = 10921337907, SwimIdle = 10921341319, Swim = 10921340419, Idle = 10921330408, Idle2 = 10921333667, Climb = 10921329322 },
    ["Superhero"] = { Walk = 10921298616, Run = 10921291831, Jump = 10921294559, Fall = 10921293373, SwimIdle = 10921297391, Swim = 10921295495, Idle = 10921288909, Idle2 = 10921290167, Climb = 10921286911 },
    ["Toy"] = { Walk = 10921312010, Run = 10921306285, Jump = 10921308158, Fall = 10921307341, SwimIdle = 10921310341, Swim = 10921309319, Idle = 10921301576, Climb = 10921300839 },
    ["No Boundaries"] = { Walk = 18747074203, Run = 18747070484, Jump = 18747069148, Fall = 18747062535, SwimIdle = 18747071682, Swim = 18747073181, Idle = 18747067405, Idle2 = 18747063918, Climb = 18747060903 },
    ["NFL"] = { Walk = 110358958299415, Run = 117333533048078, Jump = 119846112151352, Fall = 129773241321032, SwimIdle = 79090109939093, Swim = 132697394189921, Idle = 92080889861410, Idle2 = 74451233229259, Climb = 134630013742019 },
    ["Amazon Unboxed"] = { Walk = 90478085024465, Run = 134824450619865, Jump = 121454505477205, Fall = 94788218468396, SwimIdle = 129126268464847, Swim = 105962919001086, Idle = 98281136301627, Climb = 121145883950231 },
    ["Vampire"] = { Walk = 10921326949, Run = 10921320299, Jump = 10921322186, Fall = 10921321317, SwimIdle = 10921325443, Swim = 10921324408, Idle = 10921315373, Climb = 10921314188 },
    ["Ninja"] = { Walk = 656121766, Run = 656118852, Jump = 656117878, Fall = 656115606, SwimIdle = 656121397, Swim = 656119721, Idle = 656117400, Idle2 = 656118341, Climb = 656114359 },
    ["Robot"] = { Walk = 616095330, Run = 616091570, Jump = 616090535, Fall = 616087089, SwimIdle = 616094091, Swim = 616092998, Idle = 616088211, Idle2 = 616089559, Climb = 616086039 },
    ["Levitation"] = { Walk = 616013216, Run = 616010382, Jump = 616008936, Fall = 616005863, SwimIdle = 616012453, Swim = 616011509, Idle = 616006778, Idle2 = 616008087, Climb = 616003713 },
    ["Stylish"] = { Walk = 616146177, Run = 616140816, Jump = 616139451, Fall = 616134815, SwimIdle = 616144772, Swim = 616143378, Idle = 616136790, Idle2 = 616138447, Climb = 616133594 },
    ["Bubbly"] = { Walk = 910034870, Run = 910025107, Jump = 910016857, Fall = 910001910, SwimIdle = 910030921, Swim = 910028158, Idle = 910004836, Idle2 = 910009958, Climb = 909997997 },
    ["Cartoon"] = { Walk = 742640026, Run = 742638842, Jump = 742637942, Fall = 742637544, SwimIdle = 742639220, Swim = 742639220, Idle = 742637544, Idle2 = 742638445, Climb = 742636889 }
}

-- =========================================================
-- ANIMATION SYSTEM
-- =========================================================
local currentActiveAnim = nil
local myOriginalAnims = nil
local animationCharacter = nil
local animationApplyInProgress = false
local animationsEnabled = false

local animationBindings = {
    {Key = "Idle", Folder = "idle", Name = "Animation1"},
    {Key = "Idle2", Folder = "idle", Name = "Animation2"},
    {Key = "Walk", Folder = "walk", Name = "WalkAnim"},
    {Key = "Run", Folder = "run", Name = "RunAnim"},
    {Key = "Jump", Folder = "jump", Name = "JumpAnim"},
    {Key = "Climb", Folder = "climb", Name = "ClimbAnim"},
    {Key = "Fall", Folder = "fall", Name = "FallAnim"},
    {Key = "Swim", Folder = "swim", Name = "Swim"},
    {Key = "SwimIdle", Folder = "swimidle", Name = "SwimIdle"}
}

local function clearAllAnimations(hum)
    if not hum then return end
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        pcall(function() track:Stop(0) end)
        pcall(function() track:Destroy() end)
    end
    task.wait(0.05)
end

local function getAnimationId(animation)
    if not animation or not animation:IsA("Animation") then return nil end
    return animation.AnimationId:match("%d+")
end

local function getAnimationObject(animate, binding)
    local folder = animate and animate:FindFirstChild(binding.Folder)
    return folder and folder:FindFirstChild(binding.Name)
end

local function animationStateMatches(customData, animate)
    if not customData or not animate then return false end
    for _, binding in ipairs(animationBindings) do
        local desiredId = customData[binding.Key]
        if binding.Key == "Idle2" and not desiredId then
            desiredId = customData.Idle
        elseif binding.Key == "SwimIdle" and not desiredId then
            desiredId = customData.Swim
        end
        if desiredId then
            local currentId = getAnimationId(getAnimationObject(animate, binding))
            if currentId ~= tostring(desiredId) then return false end
        end
    end
    return true
end

local function hasPlayingAnimation(hum)
    for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
        if track.IsPlaying then return true end
    end
    return false
end

local function applyCustomAnims(customData)
    if not customData or animationApplyInProgress then return end
    local char = LP.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not animate or not hum then return end

    animationApplyInProgress = true
    local success = pcall(function()
        if animationCharacter ~= char then
            animationCharacter = char
            myOriginalAnims = nil
        end
        if not myOriginalAnims then
            local function getAnim(folderName, animName)
                local folder = animate:FindFirstChild(folderName)
                local anim = folder and folder:FindFirstChild(animName)
                local id = getAnimationId(anim)
                return id and tonumber(id) or nil
            end
            myOriginalAnims = {
                Idle = getAnim("idle", "Animation1") or 507766666,
                Idle2 = getAnim("idle", "Animation2") or 507766951,
                Walk = getAnim("walk", "WalkAnim") or 507777826,
                Run = getAnim("run", "RunAnim") or 507767714,
                Jump = getAnim("jump", "JumpAnim") or 507765000,
                Climb = getAnim("climb", "ClimbAnim") or 507765644,
                Fall = getAnim("fall", "FallAnim") or 507767968,
                Swim = getAnim("swim", "Swim") or 507784897,
                SwimIdle = getAnim("swimidle", "SwimIdle") or 507785072
            }
        end
        animate.Disabled = true
        clearAllAnimations(hum)
        local function updateAnimation(folderName, animName, animId)
            if not animId then return end
            local folder = animate:FindFirstChild(folderName)
            local anim = folder and folder:FindFirstChild(animName)
            if anim and anim:IsA("Animation") then
                anim.AnimationId = "rbxassetid://" .. tostring(animId)
            end
        end
        updateAnimation("idle", "Animation1", customData.Idle)
        updateAnimation("idle", "Animation2", customData.Idle2 or customData.Idle)
        updateAnimation("walk", "WalkAnim", customData.Walk)
        updateAnimation("run", "RunAnim", customData.Run)
        updateAnimation("jump", "JumpAnim", customData.Jump)
        updateAnimation("climb", "ClimbAnim", customData.Climb)
        updateAnimation("fall", "FallAnim", customData.Fall)
        updateAnimation("swim", "Swim", customData.Swim)
        updateAnimation("swimidle", "SwimIdle", customData.SwimIdle or customData.Swim)
        task.wait(0.05)
        animate.Disabled = false
        hum:ChangeState(Enum.HumanoidStateType.Landed)
        task.wait(0.05)
        hum:ChangeState(Enum.HumanoidStateType.Running)
    end)
    if not success and animate.Parent then
        animate.Disabled = false
    end
    animationApplyInProgress = false
end

-- Loop de reparación de animaciones
task.spawn(function()
    while task.wait(0.35) do
        if not animationsEnabled then continue end
        local customData = currentActiveAnim
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local animate = char and char:FindFirstChild("Animate")
        if customData and hum and hum.Health > 0 and animate and not animationApplyInProgress then
            local needsRepair = not animationStateMatches(customData, animate)
            local hasTrack = hasPlayingAnimation(hum)
            if needsRepair or not hasTrack then
                applyCustomAnims(customData)
            end
        end
    end
end)

-- Reset al respawnear
LP.CharacterAdded:Connect(function()
    animationCharacter = nil
    myOriginalAnims = nil
    if animationsEnabled and currentActiveAnim then
        task.wait(1.5)
        task.spawn(function() applyCustomAnims(currentActiveAnim) end)
    end
end)

local function applyMix()
    local mix = SZK.Anim.Mix
    local customMix = {}
    if mix.Idle ~= "None" then
        customMix.Idle = animationData[mix.Idle].Idle
        customMix.Idle2 = animationData[mix.Idle].Idle2
    end
    if mix.Walk ~= "None" then customMix.Walk = animationData[mix.Walk].Walk end
    if mix.Run ~= "None" then customMix.Run = animationData[mix.Run].Run end
    if mix.Jump ~= "None" then customMix.Jump = animationData[mix.Jump].Jump end
    if mix.Fall ~= "None" then customMix.Fall = animationData[mix.Fall].Fall end
    if mix.Climb ~= "None" then customMix.Climb = animationData[mix.Climb].Climb end
    local hasValues = false
    for _, v in pairs(customMix) do
        if v then hasValues = true; break end
    end
    if hasValues then
        animationsEnabled = true
        SZK.Anim.Enabled = true
        currentActiveAnim = customMix
        task.spawn(function() applyCustomAnims(customMix) end)
    else
        Notify("ANIM MIX", "Selecciona al menos una parte", 2)
    end
end

local function resetAnimations()
    animationsEnabled = false
    SZK.Anim.Enabled = false
    SZK.Anim.Selected = nil
    currentActiveAnim = nil
    local char = LP.Character
    if char then
        local animate = char:FindFirstChild("Animate")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if animate and hum and myOriginalAnims then
            pcall(function()
                local function updateAnimation(folderName, animName, animId)
                    local folder = animate:FindFirstChild(folderName)
                    local anim = folder and folder:FindFirstChild(animName)
                    if anim and anim:IsA("Animation") and animId then
                        anim.AnimationId = "rbxassetid://" .. tostring(animId)
                    end
                end
                updateAnimation("idle", "Animation1", myOriginalAnims.Idle)
                updateAnimation("idle", "Animation2", myOriginalAnims.Idle2)
                updateAnimation("walk", "WalkAnim", myOriginalAnims.Walk)
                updateAnimation("run", "RunAnim", myOriginalAnims.Run)
                updateAnimation("jump", "JumpAnim", myOriginalAnims.Jump)
                updateAnimation("climb", "ClimbAnim", myOriginalAnims.Climb)
                updateAnimation("fall", "FallAnim", myOriginalAnims.Fall)
                updateAnimation("swim", "Swim", myOriginalAnims.Swim)
                updateAnimation("swimidle", "SwimIdle", myOriginalAnims.SwimIdle)
            end)
        end
    end
    Notify("ANIM", "Animaciones reseteadas", 2)
end

-- =========================================================
-- SKYBOX DATA
-- =========================================================
local skyboxData = {
    Twilight = {"264908339", "264907909", "264909420", "264909758", "264908886", "264907379"},
    Nebula = {"159454299", "159454296", "264908886", "264907379", "264908886", "264907379"},
    Vaporwave = {"1417494030", "1417494146", "1417494253", "1417494402", "1417494499", "1417494643"},
    Redshift = {"401664839", "401664862", "401664960", "401664881", "401664901", "401664936"},
    ["Blue Stars"] = {"149397684", "149397686", "149397688", "149397692", "149397697", "149397702"},
    ["Sakura Pink Sky"] = {"271042516", "271077243", "271042556", "271042310", "271042467", "271077958"},
    Default = {"591058823", "591059876", "591058104", "591057861", "591057625", "591059642"},
    Desert = {"1013852", "1013853", "1013850", "1013851", "1013849", "1013854"},
    DaBaby = {"7245418472", "7245418472", "7245418472", "7245418472", "7245418472", "7245418472"},
    Minecraft = {"1876545003", "1876544331", "1876542941", "1876543392", "1876543764", "1876544642"},
    SpongeBob = {"7633178166", "7633178166", "7633178166", "7633178166", "7633178166", "7633178166"},
    Skibidi = {"14952256113", "14952256113", "14952256113", "14952256113", "14952256113", "14952256113"},
    Blaze = {"150939022", "150939038", "150939047", "150939056", "150939063", "150939082"},
    ["Pussy Cat"] = {"11154422902", "11154422902", "11154422902", "11154422902", "11154422902", "11154422902"},
    ["Among Us"] = {"5752463190", "5752463190", "5752463190", "5752463190", "5752463190", "5752463190"},
    ["Space Wave"] = {"16262356578", "16262358026", "16262360469", "16262362003", "16262363873", "16262366016"},
    ["Space Wave 2"] = {"1233158420", "1233158838", "1233157105", "1233157640", "1233157995", "1233159158"},
    ["Turquoise Wave"] = {"47974894", "47974690", "47974821", "47974776", "47974859", "47974909"},
    ["Dark Night"] = {"6285719338", "6285721078", "6285722964", "6285724682", "6285726335", "6285730635"},
    ["White Galaxy"] = {"5540798456", "5540801779", "5540799108", "5540800635", "5540798456", "5540800635"},
}

local downloadedSkyboxFaceMaps = {
    Evernight = {
        SkyboxBk = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Evernight/evernight_RT.png",
        SkyboxDn = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Evernight/evernight_DN.png",
        SkyboxFt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Evernight/evernight_FT.png",
        SkyboxLf = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Evernight/evernight_BK.png",
        SkyboxRt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Evernight/evernight_LF.png",
        SkyboxUp = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Evernight/evernight_UP.png"
    },
    ItsukiNakano = {
        SkyboxBk = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/ItsukiNakano/ItsukiNakano_Bk.png",
        SkyboxDn = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/ItsukiNakano/ItsukiNakano_Dn.png",
        SkyboxFt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/ItsukiNakano/ItsukiNakano_Ft.png",
        SkyboxLf = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/ItsukiNakano/ItsukiNakano_Lf.png",
        SkyboxRt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/ItsukiNakano/ItsukiNakano_Rt.png",
        SkyboxUp = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/ItsukiNakano/ItsukiNakano_Up.png"
    },
    MaiSakurajima = {
        SkyboxBk = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MaiSakurajima/back.png",
        SkyboxDn = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MaiSakurajima/down.png",
        SkyboxFt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MaiSakurajima/front.png",
        SkyboxLf = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MaiSakurajima/left.png",
        SkyboxRt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MaiSakurajima/right.png",
        SkyboxUp = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MaiSakurajima/top.png"
    },
    MikuNakano = {
        SkyboxBk = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MikuNakano/MikuNakano_Bk.png",
        SkyboxDn = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MikuNakano/MikuNakano_Dn.png",
        SkyboxFt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MikuNakano/MikuNakano_Ft.png",
        SkyboxLf = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MikuNakano/MikuNakano_Lf.png",
        SkyboxRt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MikuNakano/MikuNakano_Rt.png",
        SkyboxUp = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/MikuNakano/MikuNakano_Up.png"
    },
    ["Nino Nakano"] = {
        SkyboxBk = "https://od.lk/d/NjNfOTg0NjQyODJf/left1.png",
        SkyboxDn = "https://od.lk/d/NjNfOTg0NjQyNzlf/down.png",
        SkyboxFt = "https://od.lk/d/NjNfOTg0NjQyODBf/front.png",
        SkyboxLf = "https://od.lk/d/NjNfOTg0NjQyNzhf/back.png",
        SkyboxRt = "https://od.lk/d/NjNfOTg0NjQyODNf/right1.png",
        SkyboxUp = "https://od.lk/d/NjNfOTg0NjQyODFf/up.png"
    },
    ["Rias Gremory"] = {
        SkyboxBk = "https://od.lk/d/NjNfOTg0NzkyOTNf/leftRias.png",
        SkyboxDn = "https://od.lk/d/NjNfOTg0NzkyOThf/downRias.png",
        SkyboxFt = "https://od.lk/d/NjNfOTg0NzkyOTVf/front%20Rias.png",
        SkyboxLf = "https://od.lk/d/NjNfOTg0NzkyOTRf/BackRias.png",
        SkyboxRt = "https://od.lk/d/NjNfOTg0NzkyOTFf/RightRias.png",
        SkyboxUp = "https://od.lk/d/NjNfOTg0NzkyOTJf/UpRias.png"
    },
    ["Saki Saki"] = {
        SkyboxBk = "https://od.lk/d/NjNfOTg0NjQyNjZf/back1.png",
        SkyboxDn = "https://od.lk/d/NjNfOTg0NjQyNjdf/down1.png",
        SkyboxFt = "https://od.lk/d/NjNfOTg0NjQyNjhf/front1.png",
        SkyboxLf = "https://od.lk/d/NjNfOTg0NjQyNzBf/left.png",
        SkyboxRt = "https://od.lk/d/NjNfOTg0NjQyNzNf/right.png",
        SkyboxUp = "https://od.lk/d/NjNfOTg0NjQyNjlf/Up1.png"
    },
    Waguri = {
        SkyboxBk = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Waguri/waguri_ft.png",
        SkyboxDn = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Waguri/waguri_dn.png",
        SkyboxFt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Waguri/waguri_bk.png",
        SkyboxLf = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Waguri/waguri_rt.png",
        SkyboxRt = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Waguri/waguri_lf.png",
        SkyboxUp = "https://raw.githubusercontent.com/StyearX/Custom-skybox/main/Waguri/waguri_up.png"
    },
    ["Xenovia Quarta"] = {
        SkyboxBk = "https://od.lk/d/NjNfOTg0NjM0ODlf/ft.png",
        SkyboxDn = "https://od.lk/d/NjNfOTg0NjM0OTBf/dn.png",
        SkyboxFt = "https://od.lk/d/NjNfOTg0NjM0OTFf/bk.png",
        SkyboxLf = "https://od.lk/d/NjNfOTg0NjM0ODhf/if.png",
        SkyboxRt = "https://od.lk/d/NjNfOTg0NjM0ODdf/rt.png",
        SkyboxUp = "https://od.lk/d/NjNfOTg0NjM0ODZf/up.png"
    },
    ["Yotsuba Nakano"] = {
        SkyboxBk = "https://od.lk/d/NjNfOTg0NzkzMzFf/YotsubaBk.png",
        SkyboxDn = "https://od.lk/d/NjNfOTg0NzkzMzNf/YotsubaDn.png",
        SkyboxFt = "https://od.lk/d/NjNfOTg0NzkzMzRf/YotsubaFt.png",
        SkyboxLf = "https://od.lk/d/NjNfOTg0NzkzMzZf/YotsubaLeft.png",
        SkyboxRt = "https://od.lk/d/NjNfOTg0NzkzMzdf/YotsubaRt.png",
        SkyboxUp = "https://od.lk/d/NjNfOTg0NzkzMzhf/YotsubaUp.png"
    },
    Alya = {
        SkyboxBk = "https://od.lk/d/NjNfOTg0NzkzMTFf/bk.png",
        SkyboxDn = "https://od.lk/d/NjNfOTg0NzkzMTJf/dn.png",
        SkyboxFt = "https://od.lk/d/NjNfOTg0NzkzMTNf/ft.png",
        SkyboxLf = "https://od.lk/d/NjNfOTg0NzkzMTRf/if.png",
        SkyboxRt = "https://od.lk/d/NjNfOTg0NzkzMTZf/Rt.png",
        SkyboxUp = "https://od.lk/d/NjNfOTg0NzkzMTVf/Up.png"
    },
    ["Alya 2"] = {
        SkyboxBk = "https://od.lk/d/NjNfOTg0NzkzMjBf/AlyaBk.png",
        SkyboxDn = "https://od.lk/d/NjNfOTg0NzkzMjFf/alyaDn.png",
        SkyboxFt = "https://od.lk/d/NjNfOTg0NzkzMjJf/AlyaFt.png",
        SkyboxLf = "https://od.lk/d/NjNfOTg0NzkzMjNf/AlyaLf.png",
        SkyboxRt = "https://od.lk/d/NjNfOTg0NzkzMjRf/AlyaRt.png",
        SkyboxUp = "https://od.lk/d/NjNfOTg0NzkzMjVf/AlyaUp.png"
    }
}

local currentSky = nil
local function applySkyboxById(ids)
    if currentSky then
        pcall(function() currentSky:Destroy() end)
        currentSky = nil
    end
    local sky = Instance.new("Sky")
    sky.Name = "SZK_Sky"
    sky.SkyboxBk = "rbxassetid://" .. ids[1]
    sky.SkyboxDn = "rbxassetid://" .. ids[2]
    sky.SkyboxFt = "rbxassetid://" .. ids[3]
    sky.SkyboxLf = "rbxassetid://" .. ids[4]
    sky.SkyboxRt = "rbxassetid://" .. ids[5]
    sky.SkyboxUp = "rbxassetid://" .. ids[6]
    sky.Parent = Lighting
    currentSky = sky
end

local function applySkyboxByUrls(urls)
    if currentSky then
        pcall(function() currentSky:Destroy() end)
        currentSky = nil
    end
    local sky = Instance.new("Sky")
    sky.Name = "SZK_Sky"
    sky.SkyboxBk = urls.SkyboxBk
    sky.SkyboxDn = urls.SkyboxDn
    sky.SkyboxFt = urls.SkyboxFt
    sky.SkyboxLf = urls.SkyboxLf
    sky.SkyboxRt = urls.SkyboxRt
    sky.SkyboxUp = urls.SkyboxUp
    sky.Parent = Lighting
    currentSky = sky
end

local function removeSkybox()
    if currentSky then
        pcall(function() currentSky:Destroy() end)
        currentSky = nil
    end
    Notify("SKY", "Skybox removido", 2)
end

-- =========================================================
-- GUI PRINCIPAL
-- =========================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SZKHUB_FluxUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = parent

-- =========================================================
-- MINI HUD
-- =========================================================
local MiniHUD = Instance.new("Frame")
MiniHUD.Size = UDim2.new(0, 128, 0, 40)
MiniHUD.Position = UDim2.new(0, 16, 0, 16)
MiniHUD.BackgroundColor3 = Theme.Card
MiniHUD.BackgroundTransparency = 0.05
MiniHUD.BorderSizePixel = 0
MiniHUD.Active = true
MiniHUD.Parent = ScreenGui
addCorner(MiniHUD, 9)
addStroke(MiniHUD, Theme.Accent, 1.2, 0.15)

createLabel(MiniHUD, "🎯", UDim2.new(0,12,0,14), UDim2.new(0,6,0,3), Theme.Text, Enum.Font.GothamBold, 9).TextXAlignment = Enum.TextXAlignment.Center
local fpsValue = createLabel(MiniHUD, "60", UDim2.new(0,24,0,14), UDim2.new(0,19,0,3), Theme.Success, Enum.Font.GothamBold, 10)
fpsValue.TextXAlignment = Enum.TextXAlignment.Center

local hudDiv = Instance.new("Frame")
hudDiv.Size = UDim2.new(0,1,0,12); hudDiv.Position = UDim2.new(0,46,0,3)
hudDiv.BackgroundColor3 = Theme.Border; hudDiv.BorderSizePixel = 0
hudDiv.Parent = MiniHUD

createLabel(MiniHUD, "📡", UDim2.new(0,12,0,14), UDim2.new(0,52,0,3), Theme.Text, Enum.Font.GothamBold, 9).TextXAlignment = Enum.TextXAlignment.Center
local pingValue = createLabel(MiniHUD, "45", UDim2.new(0,28,0,14), UDim2.new(0,64,0,3), Theme.Accent2, Enum.Font.GothamBold, 10)
pingValue.TextXAlignment = Enum.TextXAlignment.Center

local madeByLbl = createLabel(MiniHUD, "SZKHUB • SZK", UDim2.new(1,0,0,9), UDim2.new(0,0,0,27), Theme.TextMuted, Enum.Font.GothamBold, 7)
madeByLbl.TextXAlignment = Enum.TextXAlignment.Center

local hudDragging = false
local hudDragStart, hudStartPos
MiniHUD.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        hudDragging = true; hudDragStart = input.Position; hudStartPos = MiniHUD.Position
    end
end)
MiniHUD.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then hudDragging = false end
end)
UserInputService.InputChanged:Connect(function(input)
    if hudDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - hudDragStart
        MiniHUD.Position = UDim2.new(hudStartPos.X.Scale, hudStartPos.X.Offset + d.X, hudStartPos.Y.Scale, hudStartPos.Y.Offset + d.Y)
    end
end)

task.spawn(function()
    while true do
        local ping = 0
        local ok = pcall(function() ping = math.floor(LP:GetNetworkPing() * 1000) end)
        if ok and ping and ping > 0 then
            pingValue.Text = tostring(ping)
            local c = Theme.Success
            if ping >= 120 then c = Theme.Danger elseif ping >= 60 then c = Theme.Warning end
            pingValue.TextColor3 = c
        else pingValue.Text = "--"; pingValue.TextColor3 = Theme.TextMuted end
        task.wait(1.5)
    end
end)
task.spawn(function()
    local frames = 0; local last = os.clock()
    RunService.RenderStepped:Connect(function() frames = frames + 1 end)
    while true do
        local now = os.clock(); local el = now - last
        if el >= 1 then
            local fps = math.floor(frames / el)
            fpsValue.Text = tostring(fps)
            local c = Theme.Success
            if fps < 30 then c = Theme.Danger elseif fps < 50 then c = Theme.Warning end
            fpsValue.TextColor3 = c
            frames = 0; last = now
        end
        task.wait(0.1)
    end
end)

-- =========================================================
-- VENTANA PRINCIPAL
-- =========================================================
local HOME_POS = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, WIN_W, 0, WIN_H)
MainFrame.Position = HOME_POS
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 14)

local MenuBg = Instance.new("ImageLabel")
MenuBg.Name = "MenuBg"
MenuBg.Size = UDim2.new(1, 0, 1, 0)
MenuBg.Position = UDim2.new(0, 0, 0, 0)
MenuBg.BackgroundTransparency = 1
MenuBg.Image = DEFAULT_BG
MenuBg.ScaleType = Enum.ScaleType.Crop
MenuBg.ImageTransparency = 0
MenuBg.ZIndex = 1
MenuBg.Parent = MainFrame
addCorner(MenuBg, 14)

local BgOverlay = Instance.new("Frame")
BgOverlay.Size = UDim2.new(1, 0, 1, 0)
BgOverlay.BackgroundColor3 = Theme.Background
BgOverlay.BackgroundTransparency = 0.55
BgOverlay.BorderSizePixel = 0
BgOverlay.ZIndex = 2
BgOverlay.Parent = MainFrame
addCorner(BgOverlay, 14)
addGradient(BgOverlay, Theme.Background, Theme.Background2, 135)

local mainStroke = addStroke(MainFrame, Theme.Border, 1.2)
mainStroke.ZIndex = 6

-- =========================================================
-- BOLA TOGGLE
-- =========================================================
local BallBtn = Instance.new("TextButton")
BallBtn.Size = UDim2.new(0, BALL_SIZE, 0, BALL_SIZE)
BallBtn.Position = UDim2.new(0, 16, 0.5, -BALL_SIZE/2)
BallBtn.BackgroundColor3 = Theme.Accent
BallBtn.Text = ""
BallBtn.TextColor3 = Color3.fromRGB(255,255,255)
BallBtn.TextSize = 22
BallBtn.Font = Enum.Font.GothamBold
BallBtn.AutoButtonColor = false
BallBtn.ClipsDescendants = true
BallBtn.Parent = ScreenGui
addCorner(BallBtn, BALL_SIZE/2)
addStroke(BallBtn, Color3.fromRGB(255,255,255), 1.6, 0.25)

local BallIcon = Instance.new("ImageLabel")
BallIcon.Size = UDim2.new(1, 0, 1, 0)
BallIcon.Position = UDim2.new(0, 0, 0, 0)
BallIcon.BackgroundTransparency = 1
BallIcon.Image = "rbxassetid://132065937809574"
BallIcon.ScaleType = Enum.ScaleType.Crop
BallIcon.ZIndex = 2
BallIcon.Parent = BallBtn
addCorner(BallIcon, BALL_SIZE/2)

local windowOpen = false
local function setWindow(state)
    windowOpen = state
    if state then
        MainFrame.Visible = true
        MainFrame.Position = UDim2.new(HOME_POS.X.Scale, HOME_POS.X.Offset, HOME_POS.Y.Scale, HOME_POS.Y.Offset + 30)
        MainFrame.Size = UDim2.new(0, WIN_W*0.9, 0, WIN_H*0.9)
        tween(MainFrame, {Position=HOME_POS, Size=UDim2.new(0, WIN_W, 0, WIN_H)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        BallBtn.Visible = false
    else
        tween(MainFrame, {Size=UDim2.new(0, WIN_W*0.85, 0, WIN_H*0.85)}, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        task.delay(0.2, function() MainFrame.Visible = false; BallBtn.Visible = true end)
    end
end

local ballDragging, ballDragStart, ballStartPos = false, nil, nil
local ballMoved = false; local ballPressTime = 0
BallBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        ballDragging = true; ballMoved = false; ballPressTime = tick()
        ballDragStart = input.Position; ballStartPos = BallBtn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                ballDragging = false
                if not ballMoved and (tick() - ballPressTime) < 0.5 then setWindow(true) end
                ballMoved = false
            end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if ballDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local d = input.Position - ballDragStart
        if math.abs(d.X) > 5 or math.abs(d.Y) > 5 then ballMoved = true end
        BallBtn.Position = UDim2.new(ballStartPos.X.Scale, ballStartPos.X.Offset + d.X, ballStartPos.Y.Scale, ballStartPos.Y.Offset + d.Y)
    end
end)

-- =========================================================
-- HEADER
-- =========================================================
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 48)
Header.BackgroundColor3 = Theme.Sidebar
Header.BackgroundTransparency = 0.55
Header.BorderSizePixel = 0
Header.Active = true
Header.ZIndex = 3
Header.Parent = MainFrame
addCorner(Header, 14)
addGradient(Header, Theme.Sidebar, Theme.Background2, 90)

local headerLine = Instance.new("Frame")
headerLine.Size = UDim2.new(1, -28, 0, 1)
headerLine.Position = UDim2.new(0, 14, 1, -1)
headerLine.BackgroundColor3 = Theme.Border
headerLine.BorderSizePixel = 0
headerLine.BackgroundTransparency = 0.5
headerLine.ZIndex = 4
headerLine.Parent = Header

local iconFrame = Instance.new("Frame")
iconFrame.Size = UDim2.new(0, 32, 0, 32)
iconFrame.Position = UDim2.new(0, 13, 0.5, -16)
iconFrame.BackgroundColor3 = Theme.Accent
iconFrame.BorderSizePixel = 0
iconFrame.ZIndex = 4
iconFrame.Parent = Header
addCorner(iconFrame, 10)
addGradient(iconFrame, Theme.Accent2, Theme.Accent, 135)
addStroke(iconFrame, Color3.fromRGB(255,255,255), 1, 0.6)

local iconLabel = createLabel(iconFrame, "S", UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(255,255,255), Enum.Font.GothamBold, 16)
iconLabel.TextXAlignment = Enum.TextXAlignment.Center
iconLabel.ZIndex = 4

local Title = createLabel(Header, "SZKHUB", UDim2.new(1,-150,0,16), UDim2.new(0,54,0,10), Theme.Text, Enum.Font.GothamBold, 13)
Title.ZIndex = 4
local Subtitle = createLabel(Header, "FLUX WIND UI • " .. SCRIPT_VERSION, UDim2.new(1,-150,0,12), UDim2.new(0,54,0,28), Theme.TextDim, Enum.Font.Gotham, 8)
Subtitle.ZIndex = 4

local CenterBtn = Instance.new("TextButton")
CenterBtn.Size = UDim2.new(0, 26, 0, 26)
CenterBtn.Position = UDim2.new(1, -94, 0.5, -13)
CenterBtn.BackgroundTransparency = 1
CenterBtn.Text = "📍"
CenterBtn.TextSize = 12
CenterBtn.Font = Enum.Font.GothamMedium
CenterBtn.TextColor3 = Theme.Text
CenterBtn.ZIndex = 4
CenterBtn.Parent = Header
addCorner(CenterBtn, 7)

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 26)
MinBtn.Position = UDim2.new(1, -64, 0.5, -13)
MinBtn.BackgroundTransparency = 1
MinBtn.Text = "−"
MinBtn.TextSize = 15
MinBtn.Font = Enum.Font.GothamMedium
MinBtn.TextColor3 = Theme.Text
MinBtn.ZIndex = 4
MinBtn.Parent = Header
addCorner(MinBtn, 7)

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 26, 0, 26)
CloseBtn.Position = UDim2.new(1, -34, 0.5, -13)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextColor3 = Theme.Text
CloseBtn.ZIndex = 4
CloseBtn.Parent = Header
addCorner(CloseBtn, 7)

local function setupHeaderBtn(btn, hoverColor, action)
    btn.MouseEnter:Connect(function() tween(btn, {BackgroundTransparency=0, BackgroundColor3=hoverColor}, 0.2) end)
    btn.MouseLeave:Connect(function() tween(btn, {BackgroundTransparency=1}, 0.2) end)
    btn.MouseButton1Click:Connect(action)
end
setupHeaderBtn(CenterBtn, Theme.Section, function() tween(MainFrame, {Position=HOME_POS}, 0.5, Enum.EasingStyle.Back) end)
setupHeaderBtn(CloseBtn, Theme.Danger, function() setWindow(false) end)
setupHeaderBtn(MinBtn, Theme.Warning, function() MiniHUD.Visible = not MiniHUD.Visible end)

do
    local dragging = false; local dragStart; local startOX, startOY = 0, 0
    local function isHdrBtn(t)
        if not t then return false end
        return t == CloseBtn or t == CenterBtn or t == MinBtn
            or t:IsDescendantOf(CloseBtn) or t:IsDescendantOf(CenterBtn) or t:IsDescendantOf(MinBtn)
    end
    local function startDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if input.Target and isHdrBtn(input.Target) then return end
            dragging = true; dragStart = input.Position
            startOX = MainFrame.Position.X.Offset; startOY = MainFrame.Position.Y.Offset
        end
    end
    local function endDrag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end
    Header.InputBegan:Connect(startDrag); Header.InputEnded:Connect(endDrag)
    Title.InputBegan:Connect(startDrag); Title.InputEnded:Connect(endDrag)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            MainFrame.Position = UDim2.new(0, startOX + d.X, 0, startOY + d.Y)
        end
    end)
end

-- =========================================================
-- SIDEBAR + CONTENT
-- =========================================================
local Sidebar = Instance.new("ScrollingFrame")
Sidebar.Size = UDim2.new(0, SIDEBAR_W, 1, -48)
Sidebar.Position = UDim2.new(0, 0, 0, 48)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BackgroundTransparency = 0.65
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 3
Sidebar.Parent = MainFrame
Sidebar.ScrollBarThickness = 3
Sidebar.ScrollBarImageColor3 = Theme.Accent
Sidebar.ScrollBarImageTransparency = 0.3
Sidebar.ScrollingDirection = Enum.ScrollingDirection.Y
Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
Sidebar.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable

local sidebarLayout = Instance.new("UIListLayout")
sidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
sidebarLayout.Padding = UDim.new(0, 4)
sidebarLayout.Parent = Sidebar

local sidebarPad = Instance.new("UIPadding")
sidebarPad.PaddingTop = UDim.new(0, 12)
sidebarPad.PaddingBottom = UDim.new(0, 12)
sidebarPad.PaddingLeft = UDim.new(0, 8)
sidebarPad.PaddingRight = UDim.new(0, 8)
sidebarPad.Parent = Sidebar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, -SIDEBAR_W, 1, -48)
ContentArea.Position = UDim2.new(0, SIDEBAR_W, 0, 48)
ContentArea.BackgroundTransparency = 1
ContentArea.ZIndex = 3
ContentArea.Parent = MainFrame

-- =========================================================
-- TAB SYSTEM
-- =========================================================
local Pages = {}
local ActiveTab = nil

local function CreateTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 28)
    btn.BackgroundColor3 = Theme.Section
    btn.BackgroundTransparency = 0.55
    btn.Text = "  " .. icon .. "  " .. name
    btn.TextColor3 = Theme.TextDim
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 9
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.ZIndex = 25
    btn.Parent = Sidebar
    addCorner(btn, 7)
    local stroke = addStroke(btn, Theme.Border, 1, 0.7)

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(0, 3, 0, 14)
    ind.Position = UDim2.new(0, 0, 0.5, -7)
    ind.BackgroundColor3 = Theme.Accent
    ind.BorderSizePixel = 0
    ind.Visible = false
    ind.Name = "Indicator"
    ind.ZIndex = 26
    ind.Parent = btn
    addCorner(ind, 4)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.Visible = false
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ZIndex = 4
    page.Parent = ContentArea

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 9)
    pad.PaddingRight = UDim.new(0, 9)
    pad.Parent = page

    Pages[name] = page

    btn.MouseEnter:Connect(function()
        if ActiveTab ~= btn then
            tween(btn, {BackgroundTransparency=0.35}, 0.15)
            tween(stroke, {Transparency=0.3, Color=Theme.Accent}, 0.15)
        end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= btn then
            tween(btn, {BackgroundTransparency=0.55}, 0.15)
            tween(stroke, {Transparency=0.7, Color=Theme.Border}, 0.15)
        end
    end)
    btn.MouseButton1Click:Connect(function()
        for _, p in pairs(Pages) do p.Visible = false end
        Pages[name].Visible = true
        if ActiveTab then
            local oi = ActiveTab:FindFirstChild("Indicator"); if oi then oi.Visible = false end
            ActiveTab.BackgroundColor3 = Theme.Section
            ActiveTab.BackgroundTransparency = 0.55
            ActiveTab.TextColor3 = Theme.TextDim
        end
        btn.BackgroundColor3 = Theme.Card
        btn.BackgroundTransparency = 0.15
        btn.TextColor3 = Theme.Text
        ind.Visible = true
        ActiveTab = btn
    end)
    return page
end

-- =========================================================
-- WIDGETS
-- =========================================================
local function CreateCard(parent, title)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.25
    card.BorderSizePixel = 0
    card.ZIndex = 5
    card.Parent = parent
    addCorner(card, 9)
    local cst = addStroke(card, Theme.Border, 1, 0.4)
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new(Theme.Card, Theme.Background2)
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(1, 0.55),
    })
    grad.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6); pad.PaddingBottom = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 9); pad.PaddingRight = UDim.new(0, 9)
    pad.Parent = card
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = card

    if title then
        local h = Instance.new("Frame")
        h.Size = UDim2.new(1, 0, 0, 15)
        h.BackgroundTransparency = 1
        h.LayoutOrder = -1
        h.ZIndex = 6
        h.Parent = card
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 3, 0, 10)
        line.Position = UDim2.new(0, 0, 0.5, -5)
        line.BackgroundColor3 = Theme.Accent
        line.BorderSizePixel = 0
        line.ZIndex = 7
        line.Parent = h
        addCorner(line, 4)
        local lg = Instance.new("UIGradient")
        lg.Color = ColorSequence.new(Theme.Accent2, Theme.Accent)
        lg.Rotation = 90
        lg.Parent = line
        local txt = createLabel(h, title, UDim2.new(1,-14,1,0), UDim2.new(0,10,0,0), Theme.Text, Enum.Font.GothamBold, 9)
        txt.ZIndex = 7
    end
    return card
end

local function AddToggle(parent, text, defaultState, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundColor3 = Theme.Section
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.ZIndex = 8
    row.Parent = parent
    addCorner(row, 6)
    local stroke = addStroke(row, Theme.Border, 1, 0.7)

    createLabel(row, text, UDim2.new(0.75,-10,1,0), UDim2.new(0,10,0,0), Theme.Text, Enum.Font.Gotham, 9).ZIndex = 9

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 30, 0, 16)
    track.Position = UDim2.new(1, -40, 0.5, -8)
    track.BackgroundColor3 = defaultState and Theme.Success or Theme.Inactive
    track.BorderSizePixel = 0
    track.ZIndex = 9
    track.Parent = row
    addCorner(track, 8)
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = defaultState and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 10
    knob.Parent = track
    addCorner(knob, 6)

    local state = defaultState
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 15
    btn.AutoButtonColor = false
    btn.Parent = row

    btn.MouseEnter:Connect(function()
        tween(row, {BackgroundTransparency=0.35}, 0.15)
        tween(stroke, {Transparency=0.3, Color=Theme.Accent}, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        tween(row, {BackgroundTransparency=0.55}, 0.15)
        tween(stroke, {Transparency=0.7, Color=Theme.Border}, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(knob, {Position = state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween(track, {BackgroundColor3 = state and Theme.Success or Theme.Inactive}, 0.2)
        if callback then callback(state) end
    end)
end

local function AddSlider(parent, text, min, max, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundColor3 = Theme.Section
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.ZIndex = 8
    row.Parent = parent
    addCorner(row, 6)
    local stroke = addStroke(row, Theme.Border, 1, 0.7)

    createLabel(row, text, UDim2.new(0.7,-10,0,12), UDim2.new(0,10,0,2), Theme.Text, Enum.Font.Gotham, 9).ZIndex = 9
    local valLbl = createLabel(row, tostring(default), UDim2.new(0.3,-10,0,12), UDim2.new(0.7,0,0,2), Theme.Accent, Enum.Font.GothamBold, 9)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 9

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -20, 0, 5)
    barBg.Position = UDim2.new(0, 10, 0, 19)
    barBg.BackgroundColor3 = Theme.Inactive
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 9
    barBg.Parent = row
    addCorner(barBg, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 10
    fill.Parent = barBg
    addCorner(fill, 3)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.Position = UDim2.new((default-min)/(max-min), 0, 0.5, 0)
    dot.BackgroundColor3 = Color3.fromRGB(255,255,255)
    dot.BorderSizePixel = 0
    dot.ZIndex = 11
    dot.Parent = barBg
    addCorner(dot, 5)
    addStroke(dot, Theme.Accent, 2)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 15
    btn.AutoButtonColor = false
    btn.Parent = row

    local dragging = false
    local function update(absX)
        local rel = math.clamp((absX - barBg.AbsolutePosition.X) / math.max(barBg.AbsoluteSize.X, 1), 0, 1)
        local val = math.floor(min + (max-min)*rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        dot.Position = UDim2.new(rel, 0, 0.5, 0)
        valLbl.Text = tostring(val)
        if callback then callback(val) end
    end
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function AddButton(parent, text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 22)
    b.BackgroundColor3 = Theme.Section
    b.BackgroundTransparency = 0.45
    b.Text = text
    b.TextColor3 = Theme.Text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 9
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.ZIndex = 8
    b.Parent = parent
    addCorner(b, 6)
    local st = addStroke(b, Theme.Border, 1, 0.5)
    b.MouseEnter:Connect(function()
        tween(b, {BackgroundTransparency=0.2, TextColor3=Theme.Accent}, 0.15)
        tween(st, {Color=Theme.Accent, Transparency=0.2}, 0.15)
    end)
    b.MouseLeave:Connect(function()
        tween(b, {BackgroundTransparency=0.45, TextColor3=Theme.Text}, 0.15)
        tween(st, {Color=Theme.Border, Transparency=0.5}, 0.15)
    end)
    b.MouseButton1Click:Connect(function() if callback then callback() end end)
    return b
end

local function AddDropdown(parent, text, options, default, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundColor3 = Theme.Section
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.ZIndex = 8
    row.ClipsDescendants = true
    row.Parent = parent
    addCorner(row, 6)
    addStroke(row, Theme.Border, 1, 0.7)

    createLabel(row, text, UDim2.new(0.5,-10,0,22), UDim2.new(0,10,0,0), Theme.Text, Enum.Font.Gotham, 9).ZIndex = 9
    local valLbl = createLabel(row, default, UDim2.new(0.5,-30,0,22), UDim2.new(0.5,0,0,0), Theme.Accent, Enum.Font.GothamBold, 9)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 9
    local arrow = createLabel(row, "v", UDim2.new(0,20,0,22), UDim2.new(1,-22,0,0), Theme.TextDim, Enum.Font.GothamBold, 9)
    arrow.ZIndex = 9

    local expanded = false
    local list = Instance.new("Frame")
    list.Size = UDim2.new(1, 0, 0, 0)
    list.Position = UDim2.new(0, 0, 0, 22)
    list.BackgroundColor3 = Theme.Card
    list.BorderSizePixel = 0
    list.ZIndex = 10
    list.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 15
    btn.AutoButtonColor = false
    btn.Parent = row
    btn.MouseButton1Click:Connect(function()
        expanded = not expanded
        if expanded then
            arrow.Text = "^"
            row.Size = UDim2.new(1, 0, 0, 22 + (#options*18))
            list.Size = UDim2.new(1, 0, 0, #options*18)
        else
            arrow.Text = "v"
            row.Size = UDim2.new(1, 0, 0, 22)
            list.Size = UDim2.new(1, 0, 0, 0)
        end
    end)

    for i, opt in ipairs(options) do
        local ob = Instance.new("TextButton")
        ob.Size = UDim2.new(1, 0, 0, 18)
        ob.Position = UDim2.new(0, 0, 0, (i-1)*18)
        ob.BackgroundColor3 = Theme.Section
        ob.BackgroundTransparency = 0.3
        ob.Text = "  " .. opt
        ob.TextColor3 = Theme.Text
        ob.Font = Enum.Font.Gotham
        ob.TextSize = 9
        ob.TextXAlignment = Enum.TextXAlignment.Left
        ob.BorderSizePixel = 0
        ob.AutoButtonColor = false
        ob.ZIndex = 11
        ob.Parent = list
        ob.MouseButton1Click:Connect(function()
            valLbl.Text = opt
            expanded = false; arrow.Text = "v"
            row.Size = UDim2.new(1, 0, 0, 22)
            list.Size = UDim2.new(1, 0, 0, 0)
            if callback then callback(opt) end
        end)
    end
end

local function AddKeybind(parent, text, defaultKey, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 22)
    row.BackgroundColor3 = Theme.Section
    row.BackgroundTransparency = 0.55
    row.BorderSizePixel = 0
    row.ZIndex = 8
    row.Parent = parent
    addCorner(row, 6)
    createLabel(row, text, UDim2.new(0.5,-10,1,0), UDim2.new(0,10,0,0), Theme.Text, Enum.Font.Gotham, 9).ZIndex = 9
    local kb = Instance.new("TextButton")
    kb.Size = UDim2.new(0, 80, 0, 18)
    kb.Position = UDim2.new(1, -88, 0.5, -9)
    kb.BackgroundColor3 = Theme.Accent
    kb.Text = defaultKey and defaultKey.Name or "None"
    kb.TextColor3 = Color3.fromRGB(255,255,255)
    kb.Font = Enum.Font.GothamBold
    kb.TextSize = 8
    kb.BorderSizePixel = 0
    kb.AutoButtonColor = false
    kb.ZIndex = 10
    kb.Parent = row
    addCorner(kb, 6)
    local listening = false
    kb.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true; kb.Text = "Presiona..."; kb.BackgroundColor3 = Theme.Warning
    end)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not listening or gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            kb.Text = input.KeyCode.Name
            kb.BackgroundColor3 = Theme.Accent
            listening = false
            if callback then callback(input.KeyCode) end
        end
    end)
end

-- =========================================================
-- CREAR TABS
-- =========================================================
local pHome   = CreateTab("HOME", "🏠")
local pAim    = CreateTab("AIM", "🎯")
local pEsp    = CreateTab("ESP", "👁")
local pExtra  = CreateTab("EXTRA", "⚡")
local pPlayer = CreateTab("PLAYER", "🧍")
local pMusic  = CreateTab("MUSIC", "🎵")
local pBg     = CreateTab("BG", "🎨")
local pPc     = CreateTab("PC-MODE", "⌨")
local pInf    = CreateTab("INFO", "ℹ")

-- =========================================================
-- HOME
-- =========================================================
local cWelcome = CreateCard(pHome, "WELCOME")
local wBox = Instance.new("Frame")
wBox.Size = UDim2.new(1, 0, 0, 92)
wBox.BackgroundColor3 = Theme.Section
wBox.BackgroundTransparency = 0.5
wBox.BorderSizePixel = 0
wBox.ZIndex = 8
wBox.Parent = cWelcome
addCorner(wBox, 9)

local avFrame = Instance.new("Frame")
avFrame.Size = UDim2.new(0, 64, 0, 64)
avFrame.Position = UDim2.new(0, 12, 0, 14)
avFrame.BackgroundColor3 = Theme.Background
avFrame.BorderSizePixel = 0
avFrame.ZIndex = 9
avFrame.Parent = wBox
addCorner(avFrame, 32)
addStroke(avFrame, Theme.Accent, 2, 0.1)

local avImg = Instance.new("ImageLabel")
avImg.Size = UDim2.new(1,-4,1,-4)
avImg.Position = UDim2.new(0,2,0,2)
avImg.BackgroundTransparency = 1
avImg.Image = ""
avImg.ScaleType = Enum.ScaleType.Crop
avImg.ZIndex = 10
avImg.Parent = avFrame
addCorner(avImg, 31)

task.spawn(function()
    local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
    if ok and img then avImg.Image = img end
end)

createLabel(wBox, "WELCOME, "..string.upper(LP.DisplayName).."!", UDim2.new(1,-95,0,16), UDim2.new(0,88,0,12), Theme.Text, Enum.Font.GothamBlack, 11).ZIndex = 9
createLabel(wBox, "TO "..SCRIPT_NAME.." • FLUX UI", UDim2.new(1,-95,0,14), UDim2.new(0,88,0,32), Theme.Accent2, Enum.Font.GothamBlack, 10).ZIndex = 9
createLabel(wBox, SCRIPT_VERSION.." • "..LAST_UPDATE, UDim2.new(1,-95,0,12), UDim2.new(0,88,0,50), Theme.TextDim, Enum.Font.GothamBold, 8).ZIndex = 9
createLabel(wBox, "THANKS FOR USING SZKHUB", UDim2.new(1,-95,0,12), UDim2.new(0,88,0,66), Theme.Success, Enum.Font.GothamBold, 8).ZIndex = 9

local cDiscord = CreateCard(pHome, "DISCORD")
local dBox = Instance.new("Frame")
dBox.Size = UDim2.new(1, 0, 0, 68)
dBox.BackgroundColor3 = Theme.Section
dBox.BackgroundTransparency = 0.5
dBox.BorderSizePixel = 0
dBox.ZIndex = 8
dBox.Parent = cDiscord
addCorner(dBox, 9)

createLabel(dBox, "WE WELCOME TO OUR DISCORD SERVER", UDim2.new(1,-20,0,16), UDim2.new(0,10,0,10), Theme.Text, Enum.Font.GothamBold, 9).ZIndex = 9
local dLink = createLabel(dBox, DISCORD_LINK, UDim2.new(1,-20,0,18), UDim2.new(0,10,0,28), Theme.Accent2, Enum.Font.Gotham, 9)
dLink.TextWrapped = true; dLink.ZIndex = 9
local copyBtn = AddButton(dBox, "COPIAR LINK", function()
    pcall(function() if setclipboard then setclipboard(DISCORD_LINK) end end)
    Notify("SZKHUB", "Discord link copiado", 2)
end)
copyBtn.Position = UDim2.new(1, -100, 1, -26)
copyBtn.Size = UDim2.new(0, 90, 0, 20)

local cQuick = CreateCard(pHome, "QUICK INFO")
createLabel(cQuick, "Script: "..SCRIPT_NAME.." "..SCRIPT_VERSION.."\nGame: "..GAME_NAME.."\nLast Update: "..LAST_UPDATE.."   |   Made by SZK", UDim2.new(1,0,0,42), UDim2.new(0,0,0,0), Theme.Text, Enum.Font.Gotham, 9).TextYAlignment = Enum.TextYAlignment.Top

-- =========================================================
-- AIM
-- =========================================================
local cGlobalFov = CreateCard(pAim, "FOV GLOBAL")
AddSlider(cGlobalFov, "FOV Radius", 50, 800, SZK.GlobalFov, function(v)
    SZK.GlobalFov = v
    SZK.SilentAim.FovSize = v; SZK.AutoShoot.FovSize = v; SZK.TriggerBot.FovSize = v
end)
AddToggle(cGlobalFov, "Show FOV Circle", SZK.Settings.ShowFovCircle, function(v) SZK.Settings.ShowFovCircle = v end)
createLabel(cGlobalFov, "🟢 Verde = Sin enemigos  |  🔴 Rojo = Enemigo visible  |  ⚪ Gris = Lobby", UDim2.new(1,0,0,12), UDim2.new(0,0,0,0), Theme.TextDim, Enum.Font.Gotham, 8).TextWrapped = true

local cSilent = CreateCard(pAim, "SILENT AIM")
AddToggle(cSilent, "Enable Silent Aim", SZK.SilentAim.Enabled, function(v) SZK.SilentAim.Enabled = v; SZK.SilentAim._toggled = v end)
AddToggle(cSilent, "Usar FOV Global", SZK.SilentAim.UseFovLimit, function(v) SZK.SilentAim.UseFovLimit = v end)
AddToggle(cSilent, "Wall Check", SZK.SilentAim.WallCheck, function(v) SZK.SilentAim.WallCheck = v end)

local cAuto = CreateCard(pAim, "AUTO SHOOT")
AddToggle(cAuto, "Enable Auto Shoot", SZK.AutoShoot.Enabled, function(v) SZK.AutoShoot.Enabled = v; SZK.AutoShoot._toggled = v end)
AddToggle(cAuto, "Usar FOV Global", SZK.AutoShoot.UseFovLimit, function(v) SZK.AutoShoot.UseFovLimit = v end)
AddSlider(cAuto, "Shoot Delay (ms)", 50, 1000, SZK.AutoShoot.ShootDelay*1000, function(v) SZK.AutoShoot.ShootDelay = v/1000 end)
AddToggle(cAuto, "Wall Check", SZK.AutoShoot.WallCheck, function(v) SZK.AutoShoot.WallCheck = v end)

local cAimbot = CreateCard(pAim, "AIMBOT")
AddToggle(cAimbot, "Enable Aimbot", SZK.Aimbot.Enabled, function(v) SZK.Aimbot.Enabled = v end)
AddToggle(cAimbot, "Only Gun", SZK.Aimbot.OnlyGun, function(v) SZK.Aimbot.OnlyGun = v end)
AddToggle(cAimbot, "Prediction", SZK.Aimbot.Prediction, function(v) SZK.Aimbot.Prediction = v end)
AddDropdown(cAimbot, "Target Part", {"Cabeza","Torso","Completo"}, "Cabeza", function(v) SZK.Aimbot.TargetPart = v end)
AddSlider(cAimbot, "Smoothness", 0, 100, math.floor(SZK.Aimbot.Smoothness*100), function(v) SZK.Aimbot.Smoothness = v/100 end)

local cTrig = CreateCard(pAim, "TRIGGER BOT v2")
AddToggle(cTrig, "Enable Trigger Bot", SZK.TriggerBot.Enabled, function(v)
    SZK.TriggerBot.Enabled = v; SZK.TriggerBot._toggled = v
    Notify("TRIGGER BOT", v and "ON (v2)" or "OFF", 2)
end)
AddToggle(cTrig, "Auto Equip", SZK.TriggerBot.AutoEquip, function(v) SZK.TriggerBot.AutoEquip = v end)
AddToggle(cTrig, "Auto Shoot", SZK.TriggerBot.AutoShoot, function(v) SZK.TriggerBot.AutoShoot = v end)
AddToggle(cTrig, "Preferir Arma", SZK.TriggerBot.PreferFirearm, function(v) SZK.TriggerBot.PreferFirearm = v end)
AddToggle(cTrig, "Tirar Melee", SZK.TriggerBot.DropMelee, function(v) SZK.TriggerBot.DropMelee = v end)
AddSlider(cTrig, "Shoot Delay (ms)", 10, 1000, SZK.TriggerBot.ShootDelay*1000, function(v) SZK.TriggerBot.ShootDelay = v/1000 end)
AddToggle(cTrig, "Wall Check", SZK.TriggerBot.WallCheck, function(v) SZK.TriggerBot.WallCheck = v end)
AddSlider(cTrig, "FOV Radius", 50, 800, SZK.TriggerBot.FovSize, function(v) SZK.TriggerBot.FovSize = v end)

local cKnife = CreateCard(pAim, "KNIFE BOT")
AddToggle(cKnife, "Enable Knife Bot", SZK.KnifeBot.Enabled, function(v) SZK.KnifeBot.Enabled = v end)
AddDropdown(cKnife, "Target Part", {"Cabeza","Torso","Completo"}, "Cabeza", function(v) SZK.KnifeBot.TargetPart = v end)

-- =========================================================
-- ESP
-- =========================================================
local cEsp = CreateCard(pEsp, "ESP MASTER")
AddToggle(cEsp, "Enable ESP", SZK.ESP.Enabled, function(v) SZK.ESP.Enabled = v; rebuildAllESP() end)
AddToggle(cEsp, "Show Teammates (Verde)", SZK.ESP.ShowTeammates, function(v) SZK.ESP.ShowTeammates = v end)
AddSlider(cEsp, "Max Distance", 50, 3000, SZK.ESP.MaxDistance, function(v) SZK.ESP.MaxDistance = v end)
createLabel(cEsp, "🟢 Verde = Compañeros  |  🔴 Rojo = Enemigos", UDim2.new(1,0,0,12), UDim2.new(0,0,0,0), Theme.TextDim, Enum.Font.Gotham, 8).TextWrapped = true

local cEsp2 = CreateCard(pEsp, "ELEMENTOS V2")
AddToggle(cEsp2, "Highlight", SZK.ESP.Highlight, function(v) SZK.ESP.Highlight = v end)
AddToggle(cEsp2, "Box", SZK.ESP.Box, function(v) SZK.ESP.Box = v end)
AddToggle(cEsp2, "Fill Box", SZK.ESP.FillBox, function(v) SZK.ESP.FillBox = v end)
AddToggle(cEsp2, "Skeleton", SZK.ESP.Skeleton, function(v) SZK.ESP.Skeleton = v end)
AddToggle(cEsp2, "Head Dot", SZK.ESP.HeadDot, function(v) SZK.ESP.HeadDot = v end)
AddToggle(cEsp2, "Name", SZK.ESP.Name, function(v) SZK.ESP.Name = v end)
AddToggle(cEsp2, "Distance", SZK.ESP.Distance, function(v) SZK.ESP.Distance = v end)
AddToggle(cEsp2, "Health", SZK.ESP.Health, function(v) SZK.ESP.Health = v end)
AddToggle(cEsp2, "Tracer", SZK.ESP.Tracer, function(v) SZK.ESP.Tracer = v end)
AddDropdown(cEsp2, "Tracer Origin", {"Top","Center","Bottom"}, "Bottom", function(v) SZK.ESP.TracerOrigin = v end)

-- =========================================================
-- EXTRA
-- =========================================================
local cFarm = CreateCard(pExtra, "AUTOFARM")
AddToggle(cFarm, "Enable AutoFarm", SZK.AutoFarm.Enabled, function(v)
    SZK.AutoFarm.Enabled = v
    if v and not SZK.AutoFarm._loopRunning then
        SZK.AutoFarm._loopRunning = true
        task.spawn(function()
            local s, container = pcall(function() return workspace:WaitForChild("SpawnablesClient", 10) end)
            if not s or not container then
                Notify("AutoFarm", "No container", 4)
                SZK.AutoFarm._loopRunning = false; SZK.AutoFarm.Enabled = false
                return
            end
            Notify("AutoFarm", "Started", 3)
            while SZK.AutoFarm.Enabled do
                for _, obj in ipairs(container:GetChildren()) do
                    if not SZK.AutoFarm.Enabled then break end
                    local tp = obj:FindFirstChild("Touch")
                    if tp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                        pcall(function()
                            if firetouchinterest then
                                firetouchinterest(LP.Character.HumanoidRootPart, tp, 0)
                                firetouchinterest(LP.Character.HumanoidRootPart, tp, 1)
                            end
                        end)
                    end
                end
                task.wait(0.45)
            end
            SZK.AutoFarm._loopRunning = false
        end)
    end
end)
AddButton(cFarm, "ONCE FARM", function()
    task.spawn(function()
        local s, c = pcall(function() return workspace:WaitForChild("SpawnablesClient", 5) end)
        if not s or not c then Notify("Once Farm", "No container", 3); return end
        local count = 0
        for _, obj in ipairs(c:GetChildren()) do
            local tp = obj:FindFirstChild("Touch")
            if tp and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
                pcall(function()
                    if firetouchinterest then
                        firetouchinterest(LP.Character.HumanoidRootPart, tp, 0)
                        firetouchinterest(LP.Character.HumanoidRootPart, tp, 1)
                    end
                end)
                count = count + 1; task.wait(0.05)
            end
        end
        Notify("Once Farm", "Tocados "..count, 3)
    end)
end)

local cMacro = CreateCard(pExtra, "MACRO (TAP)")
AddToggle(cMacro, "Enable Macro", SZK.Macro.Enabled, function(v) SZK.Macro.Enabled = v; Notify("MACRO", v and "ON" or "OFF", 2) end)
AddToggle(cMacro, "Auto Equip", SZK.Macro.AutoEquip, function(v) SZK.Macro.AutoEquip = v end)
AddToggle(cMacro, "Wall Check", SZK.Macro.WallCheck, function(v) SZK.Macro.WallCheck = v end)
AddDropdown(cMacro, "Target", {"Cabeza","Torso","Completo"}, "Cabeza", function(v) SZK.Macro.Target = v end)
AddSlider(cMacro, "Cooldown (ms)", 50, 1000, math.floor(SZK.Macro.Cooldown*1000), function(v) SZK.Macro.Cooldown = v/1000 end)

local cHitbox = CreateCard(pExtra, "HITBOX (BIG)")
AddToggle(cHitbox, "Enable Hitbox", SZK.Hitbox.Enabled, function(v)
    SZK.Hitbox.Enabled = v
    if not v then
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then
                local g = p.Character:FindFirstChild("GhostHitbox")
                if g then g:Destroy() end
            end
        end
    end
    Notify("HITBOX", v and "ON" or "OFF", 2)
end)
AddSlider(cHitbox, "Hitbox Size", 5, 35, SZK.Hitbox.Size, function(v) SZK.Hitbox.Size = v end)

RunService.Heartbeat:Connect(function()
    if not SZK.Hitbox.Enabled then return end
    local sz = Vector3.new(SZK.Hitbox.Size, SZK.Hitbox.Size, SZK.Hitbox.Size + 1)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and IsEnemy(p) then
            local c = p.Character
            local rp = c:FindFirstChild("HumanoidRootPart")
            local hum = c:FindFirstChild("Humanoid")
            if rp and hum and hum.Health > 0 then
                if not c:FindFirstChild("GhostHitbox") then
                    local pt = Instance.new("Part")
                    pt.Name = "GhostHitbox"
                    pt.Size = sz
                    pt.Transparency = 0.7
                    pt.CanCollide = false
                    pt.Massless = true
                    pt.CFrame = rp.CFrame
                    pt.Parent = c
                    local w = Instance.new("WeldConstraint")
                    w.Part0 = rp; w.Part1 = pt; w.Parent = pt
                else
                    local pt = c:FindFirstChild("GhostHitbox")
                    if pt then pt.Size = sz end
                end
            end
        end
    end
end)

local cSpeed = CreateCard(pExtra, "SPEED")
AddToggle(cSpeed, "Enable Speed", SZK.Speed.Enabled, function(v)
    SZK.Speed.Enabled = v
    if not v then
        if SZK.Speed._loop then SZK.Speed._loop:Disconnect(); SZK.Speed._loop = nil end
        Notify("SPEED", "OFF", 2); return
    end
    if SZK.Speed._loop then SZK.Speed._loop:Disconnect() end
    SZK.Speed._loop = RunService.Heartbeat:Connect(function()
        if not SZK.Speed.Enabled then return end
        local c = LP.Character; if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        local rp = c:FindFirstChild("HumanoidRootPart")
        if not rp or not hum then return end
        local md = hum.MoveDirection
        if md.Magnitude > 0 then rp.CFrame = rp.CFrame + (md * SZK.Speed.Multiplier) end
    end)
    Notify("SPEED", "ON", 2)
end)
AddSlider(cSpeed, "Multiplier x100", 10, 200, math.floor(SZK.Speed.Multiplier*100), function(v) SZK.Speed.Multiplier = v/100 end)

-- LIMITS
local LIMITS_ACCESSORIES = {
    {name="Hearts", id="10159610478"},
    {name="Silver Crown", id="12922571644"},
    {name="Spring Fairy", id="128217885"},
}
local EXTRA_ACCESSORIES = {
    {name="Ojos Ninja", id="17826440571"},
    {name="Fiery Horns", id="215718515"},
    {name="Rc Crown", id="10159600649"},
}

local function buildAccCard(parent, title, list, tag)
    local c = CreateCard(parent, title)
    for _, acc in ipairs(list) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundColor3 = Theme.Section
        row.BackgroundTransparency = 0.55
        row.BorderSizePixel = 0
        row.ZIndex = 8
        row.Parent = c
        addCorner(row, 6)
        createLabel(row, acc.name, UDim2.new(0.4,-10,1,0), UDim2.new(0,8,0,0), Theme.Text, Enum.Font.GothamBold, 8).ZIndex = 9
        local eq = Instance.new("TextButton")
        eq.Size = UDim2.new(0, 52, 0, 18)
        eq.Position = UDim2.new(1, -110, 0.5, -9)
        eq.BackgroundColor3 = Theme.Accent
        eq.Text = "EQUIPAR"; eq.TextColor3 = Color3.fromRGB(255,255,255)
        eq.Font = Enum.Font.GothamBold; eq.TextSize = 8; eq.BorderSizePixel = 0
        eq.AutoButtonColor = false; eq.ZIndex = 10; eq.Parent = row
        addCorner(eq, 6)
        local rm = Instance.new("TextButton")
        rm.Size = UDim2.new(0, 52, 0, 18)
        rm.Position = UDim2.new(1, -54, 0.5, -9)
        rm.BackgroundColor3 = Theme.Danger
        rm.Text = "QUITAR"; rm.TextColor3 = Color3.fromRGB(255,255,255)
        rm.Font = Enum.Font.GothamBold; rm.TextSize = 8; rm.BorderSizePixel = 0
        rm.AutoButtonColor = false; rm.ZIndex = 10; rm.Parent = row
        addCorner(rm, 6)
        eq.MouseButton1Click:Connect(function()
            if LoadAccessoryToPlayer(acc.id) then Notify(tag, acc.name.." OK", 2) end
        end)
        rm.MouseButton1Click:Connect(function()
            if RemoveAccessoryByID(acc.id) then Notify(tag, acc.name.." quitado", 2) end
        end)
    end
    return c
end
buildAccCard(pExtra, "LIMITS", LIMITS_ACCESSORIES, "LIMITS")
buildAccCard(pExtra, "EXTRA ACCESORIOS", EXTRA_ACCESSORIES, "AVATAR")

-- HEADLESS + KORBLOX
local cHK = CreateCard(pExtra, "HEADLESS + KORBLOX")
local hRow = Instance.new("Frame")
hRow.Size = UDim2.new(1, 0, 0, 26)
hRow.BackgroundColor3 = Theme.Section
hRow.BackgroundTransparency = 0.55
hRow.BorderSizePixel = 0
hRow.ZIndex = 8
hRow.Parent = cHK
addCorner(hRow, 6)
createLabel(hRow, "Headless", UDim2.new(0.6,-10,1,0), UDim2.new(0,10,0,0), Theme.Text, Enum.Font.GothamBold, 9).ZIndex = 9
local hToggle = Instance.new("TextButton")
hToggle.Size = UDim2.new(0, 62, 0, 20)
hToggle.Position = UDim2.new(1, -70, 0.5, -10)
hToggle.BackgroundColor3 = Theme.Success
hToggle.Text = "APLICAR"; hToggle.TextColor3 = Color3.fromRGB(255,255,255)
hToggle.Font = Enum.Font.GothamBold; hToggle.TextSize = 8; hToggle.BorderSizePixel = 0
hToggle.AutoButtonColor = false; hToggle.ZIndex = 10; hToggle.Parent = hRow
addCorner(hToggle, 6)
local hOn = false
hToggle.MouseButton1Click:Connect(function()
    hOn = not hOn; genv.SZK_HeadlessOn = hOn
    if hOn then
        if ApplyHeadless() then hToggle.Text = "QUITAR"; hToggle.BackgroundColor3 = Theme.Danger; Notify("AVATAR", "Headless ON", 2) end
    else
        if RemoveHeadless() then hToggle.Text = "APLICAR"; hToggle.BackgroundColor3 = Theme.Success; Notify("AVATAR", "Headless OFF", 2) end
    end
end)

local kRow = Instance.new("Frame")
kRow.Size = UDim2.new(1, 0, 0, 26)
kRow.BackgroundColor3 = Theme.Section
kRow.BackgroundTransparency = 0.55
kRow.BorderSizePixel = 0
kRow.ZIndex = 8
kRow.Parent = cHK
addCorner(kRow, 6)
createLabel(kRow, "Korblox", UDim2.new(0.6,-10,1,0), UDim2.new(0,10,0,0), Theme.Text, Enum.Font.GothamBold, 9).ZIndex = 9
local kToggle = Instance.new("TextButton")
kToggle.Size = UDim2.new(0, 62, 0, 20)
kToggle.Position = UDim2.new(1, -70, 0.5, -10)
kToggle.BackgroundColor3 = Theme.Success
kToggle.Text = "APLICAR"; kToggle.TextColor3 = Color3.fromRGB(255,255,255)
kToggle.Font = Enum.Font.GothamBold; kToggle.TextSize = 8; kToggle.BorderSizePixel = 0
kToggle.AutoButtonColor = false; kToggle.ZIndex = 10; kToggle.Parent = kRow
addCorner(kToggle, 6)
local kOn = false
kToggle.MouseButton1Click:Connect(function()
    kOn = not kOn; genv.SZK_KorbloxOn = kOn
    if kOn then
        if ApplyKorblox() then kToggle.Text = "QUITAR"; kToggle.BackgroundColor3 = Theme.Danger; Notify("AVATAR", "Korblox ON", 2) end
    else
        if RemoveKorblox() then kToggle.Text = "APLICAR"; kToggle.BackgroundColor3 = Theme.Success; Notify("AVATAR", "Korblox OFF", 2) end
    end
end)

AddButton(cHK, "AMBOS", function()
    ApplyHeadless(); ApplyKorblox()
    hOn = true; kOn = true; genv.SZK_HeadlessOn = true; genv.SZK_KorbloxOn = true
    hToggle.Text = "QUITAR"; hToggle.BackgroundColor3 = Theme.Danger
    kToggle.Text = "QUITAR"; kToggle.BackgroundColor3 = Theme.Danger
    Notify("AVATAR", "Headless + Korblox ON", 2)
end)
AddButton(cHK, "RESET", function()
    RemoveHeadless(); RemoveKorblox()
    hOn = false; kOn = false; genv.SZK_HeadlessOn = false; genv.SZK_KorbloxOn = false
    hToggle.Text = "APLICAR"; hToggle.BackgroundColor3 = Theme.Success
    kToggle.Text = "APLICAR"; kToggle.BackgroundColor3 = Theme.Success
    Notify("AVATAR", "Restaurado", 2)
end)

-- KILL SOUND
local cKill = CreateCard(pExtra, "🔫 KILL SOUND")

AddToggle(cKill, "Enable Kill Sound", KillSound.Enabled, function(v)
    KillSound.Enabled = v
    Notify("KILL SOUND", v and "ON" or "OFF", 2)
end)

AddDropdown(cKill, "Sonido", KillSound.Options, KillSound.Selected, function(v)
    KillSound.Selected = v
    Notify("KILL SOUND", "Seleccionado: "..v, 2)
    if KillSound.Enabled then PlayKillSound() end
end)

AddSlider(cKill, "🔊 Volumen", 0, 100, math.floor(KillSound.Volume*100), function(v)
    KillSound.Volume = v/100
end)

AddButton(cKill, "▶️  PROBAR SONIDO", function()
    local wasEnabled = KillSound.Enabled
    KillSound.Enabled = true
    PlayKillSound()
    task.delay(0.3, function() KillSound.Enabled = wasEnabled end)
    Notify("KILL SOUND", "Preview: "..KillSound.Selected, 2)
end)

createLabel(cKill, "Suena automáticamente cuando muere un enemigo.",
    UDim2.new(1,0,0,14), UDim2.new(0,0,0,0),
    Theme.TextDim, Enum.Font.Gotham, 8).TextWrapped = true

-- LOCK
local cLock = CreateCard(pExtra, "LOCK BUTTONS")
local lockLbl = createLabel(cLock, "Estado: DESBLOQUEADO", UDim2.new(1,0,0,12), UDim2.new(0,0,0,0), Theme.Warning, Enum.Font.GothamBold, 9)
local lockBtn = AddButton(cLock, "BLOQUEAR BOTONES", function() end)
local function updateLockUI()
    if SZK.Settings.ButtonsLocked then
        lockLbl.Text = "Estado: BLOQUEADO"; lockLbl.TextColor3 = Theme.Danger
        lockBtn.Text = "DESBLOQUEAR"
    else
        lockLbl.Text = "Estado: DESBLOQUEADO"; lockLbl.TextColor3 = Theme.Warning
        lockBtn.Text = "BLOQUEAR BOTONES"
    end
end
lockBtn.MouseButton1Click:Connect(function()
    SZK.Settings.ButtonsLocked = not SZK.Settings.ButtonsLocked
    updateLockUI()
end)
updateLockUI()

-- =========================================================
-- PLAYER (NUEVA TAB — ANIMATIONS + MIXER + SKY)
-- =========================================================

-- Lista de animaciones ordenada
local animNames = {"None"}
for name, _ in pairs(animationData) do
    table.insert(animNames, name)
end
table.sort(animNames)

-- Card: ANIMATIONS
local cAnim = CreateCard(pPlayer, "🎬 ANIMATIONS (PACKS)")
createLabel(cAnim, "Elige un pack completo de animaciones.\nSe aplica todo (Idle/Walk/Run/Jump...).", UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), Theme.TextDim, Enum.Font.Gotham, 8).TextWrapped = true

AddDropdown(cAnim, "Pack", animNames, "None", function(v)
    if v == "None" then
        resetAnimations()
        return
    end
    if animationData[v] then
        SZK.Anim.Selected = v
        animationsEnabled = true
        SZK.Anim.Enabled = true
        currentActiveAnim = animationData[v]
        task.spawn(function() applyCustomAnims(animationData[v]) end)
        Notify("ANIM", "Pack: "..v, 2)
    end
end)

AddButton(cAnim, "▶️  APLICAR PACK", function()
    if SZK.Anim.Selected and animationData[SZK.Anim.Selected] then
        animationsEnabled = true
        SZK.Anim.Enabled = true
        currentActiveAnim = animationData[SZK.Anim.Selected]
        task.spawn(function() applyCustomAnims(animationData[SZK.Anim.Selected]) end)
        Notify("ANIM", "Aplicado: "..SZK.Anim.Selected, 2)
    else
        Notify("ANIM", "Selecciona un pack primero", 2)
    end
end)

AddButton(cAnim, "🔄  RESET ANIMACIONES", function() resetAnimations() end)

-- Card: ANIMATION MIXER
local cMix = CreateCard(pPlayer, "🎛️ ANIMATION MIXER")
createLabel(cMix, "Combina animaciones de diferentes packs.\nEj: Walk de Ninja, Run de Adidas, etc.", UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), Theme.TextDim, Enum.Font.Gotham, 8).TextWrapped = true

AddDropdown(cMix, "Idle", animNames, "None", function(v) SZK.Anim.Mix.Idle = v end)
AddDropdown(cMix, "Walk", animNames, "None", function(v) SZK.Anim.Mix.Walk = v end)
AddDropdown(cMix, "Run", animNames, "None", function(v) SZK.Anim.Mix.Run = v end)
AddDropdown(cMix, "Jump", animNames, "None", function(v) SZK.Anim.Mix.Jump = v end)
AddDropdown(cMix, "Fall", animNames, "None", function(v) SZK.Anim.Mix.Fall = v end)
AddDropdown(cMix, "Climb", animNames, "None", function(v) SZK.Anim.Mix.Climb = v end)

AddButton(cMix, "🎛️  APLICAR MIX", function()
    applyMix()
    Notify("ANIM MIX", "Mix aplicado", 2)
end)

AddButton(cMix, "🔄  RESET MIX", function()
    SZK.Anim.Mix = {Idle="None",Walk="None",Run="None",Jump="None",Fall="None",Climb="None"}
    resetAnimations()
    Notify("ANIM MIX", "Mix reseteado", 2)
end)

-- Card: SKY CHANGER
local cSky = CreateCard(pPlayer, "🌌 SKY CHANGER")

local skyNames = {"None"}
for name, _ in pairs(skyboxData) do
    table.insert(skyNames, name)
end
table.sort(skyNames)

AddDropdown(cSky, "Skybox", skyNames, "None", function(v)
    if v == "None" then
        removeSkybox()
    elseif skyboxData[v] then
        SZK.Sky.Selected = v
        applySkyboxById(skyboxData[v])
        Notify("SKY", "Aplicado: "..v, 2)
    end
end)

AddButton(cSky, "🎨  APLICAR SKY", function()
    if SZK.Sky.Selected and skyboxData[SZK.Sky.Selected] then
        applySkyboxById(skyboxData[SZK.Sky.Selected])
        Notify("SKY", "Aplicado: "..SZK.Sky.Selected, 2)
    else
        Notify("SKY", "Selecciona un skybox", 2)
    end
end)

AddButton(cSky, "🔄  QUITAR SKY", function() removeSkybox() end)

-- Downloaded skyboxes
local dlSkyNames = {"None"}
for name, _ in pairs(downloadedSkyboxFaceMaps) do
    table.insert(dlSkyNames, name)
end
table.sort(dlSkyNames)

local cSkyDL = CreateCard(pPlayer, "🖼️ CUSTOM SKYBOX (Downloaded)")
AddDropdown(cSkyDL, "Pack Custom", dlSkyNames, "None", function(v)
    if v == "None" then
        removeSkybox()
    elseif downloadedSkyboxFaceMaps[v] then
        applySkyboxByUrls(downloadedSkyboxFaceMaps[v])
        Notify("SKY", "Custom: "..v, 2)
    end
end)

-- =========================================================
-- MUSIC
-- =========================================================
local cBoom = CreateCard(pMusic, "🎵 BOOMBOX PLAYER")
createLabel(cBoom, "Reproductor con "..#BOOMBOX_SONGS.." canciones.\nElige una, ajusta volumen y pulsa PLAY.\nHotkey: [M] = Play/Pause", UDim2.new(1,0,0,36), UDim2.new(0,0,0,0), Theme.TextDim, Enum.Font.Gotham, 9).TextYAlignment = Enum.TextYAlignment.Top

local songNames = {}
for _, s in ipairs(BOOMBOX_SONGS) do songNames[#songNames+1] = s.name end

AddDropdown(cBoom, "🎶 Song", songNames, BOOMBOX_SONGS[1].name, function(v)
    for _, s in ipairs(BOOMBOX_SONGS) do
        if s.name == v then
            BoomboxState.CurrentSong = s.id; BoomboxState.CurrentName = s.name
            if BoomboxState.Playing then Boombox.SoundId = s.id; Boombox:Play() end
            Notify("BOOMBOX", "Song: "..s.name, 2)
            break
        end
    end
end)
AddSlider(cBoom, "🔊 Volume", 0, 100, math.floor(BoomboxState.Volume*100), function(v)
    BoomboxState.Volume = v/100; Boombox.Volume = BoomboxState.Volume
end)
AddToggle(cBoom, "🔁 Loop", BoomboxState.Loop, function(v) BoomboxState.Loop = v; Boombox.Looped = v end)

local cBoomCtrl = CreateCard(pMusic, "CONTROLES")
AddButton(cBoomCtrl, "▶️  PLAY", function()
    Boombox.SoundId = BoomboxState.CurrentSong
    Boombox.Volume = BoomboxState.Volume
    Boombox.Looped = BoomboxState.Loop
    Boombox:Play(); BoomboxState.Playing = true
    Notify("BOOMBOX", "Playing: "..BoomboxState.CurrentName, 2)
end)
AddButton(cBoomCtrl, "⏸️  PAUSE", function() Boombox:Pause(); Notify("BOOMBOX", "Paused", 2) end)
AddButton(cBoomCtrl, "⏹️  STOP", function() Boombox:Stop(); BoomboxState.Playing = false; Notify("BOOMBOX", "Stopped", 2) end)

-- =========================================================
-- BG CHANGER
-- =========================================================
local cBgChange = CreateCard(pBg, "🎨 BACKGROUND CHANGER")
createLabel(cBgChange, "Cambia el fondo del menú.\nFondo actual aplicado al 100% de opacidad.", UDim2.new(1,0,0,24), UDim2.new(0,0,0,0), Theme.TextDim, Enum.Font.Gotham, 9).TextYAlignment = Enum.TextYAlignment.Top

for _, bg in ipairs(BG_LIST) do
    AddButton(cBgChange, "🖼️  "..bg.name, function()
        MenuBg.Image = bg.id
        MenuBg.ImageTransparency = 0
        Notify("BACKGROUND", bg.name.." aplicado", 2)
    end)
end
AddButton(cBgChange, "🔄  RESET (Fondo principal)", function()
    MenuBg.Image = DEFAULT_BG
    MenuBg.ImageTransparency = 0
    Notify("BACKGROUND", "Fondo principal restaurado", 2)
end)

-- =========================================================
-- PC-MODE
-- =========================================================
local cKb = CreateCard(pPc, "CONTROLES")
AddKeybind(cKb, "ESP Toggle", SZK.Keybinds.ESP, function(k) SZK.Keybinds.ESP = k; Notify("PC-MODE", "ESP: "..k.Name, 2) end)
AddKeybind(cKb, "TriggerBot Toggle", SZK.Keybinds.TriggerBot, function(k) SZK.Keybinds.TriggerBot = k; Notify("PC-MODE", "TriggerBot: "..k.Name, 2) end)
AddKeybind(cKb, "Silent Aim Toggle", SZK.Keybinds.SilentAim, function(k) SZK.Keybinds.SilentAim = k; Notify("PC-MODE", "SilentAim: "..k.Name, 2) end)
AddKeybind(cKb, "Aimbot Toggle", SZK.Keybinds.Aimbot, function(k) SZK.Keybinds.Aimbot = k; Notify("PC-MODE", "Aimbot: "..k.Name, 2) end)

-- =========================================================
-- INFO
-- =========================================================
local cGameInfo = CreateCard(pInf, "INFO DEL JUEGO")
createLabel(cGameInfo, "Game: "..GAME_NAME.."\nPlaceId: "..tostring(game.PlaceId).."\nLast Update: "..LAST_UPDATE, UDim2.new(1,0,0,46), UDim2.new(0,0,0,0), Theme.Text, Enum.Font.Gotham, 9).TextYAlignment = Enum.TextYAlignment.Top

local cCredits = CreateCard(pInf, "CREDITOS")
createLabel(cCredits, "MADE BY SZK\n"..SCRIPT_NAME.." "..SCRIPT_VERSION.."\n"..LAST_UPDATE.."\nDiscord: "..DISCORD_LINK, UDim2.new(1,0,0,60), UDim2.new(0,0,0,0), Theme.Text, Enum.Font.Gotham, 9).TextYAlignment = Enum.TextYAlignment.Top

local cCreators = CreateCard(pInf, "CONTENT CREATORS")
local creators = {
    {name="JUAN", tag="CC", color=Theme.Accent2, link="https://www.tiktok.com/@juancc302"},
    {name="66GHOST660", tag="CC", color=Color3.fromRGB(255,80,200), link="https://www.tiktok.com/@666ghost667"},
}
for _, cc in ipairs(creators) do
    local row = AddButton(cCreators, "★  "..cc.name.."  •  "..cc.tag, function()
        pcall(function() if setclipboard then setclipboard(cc.link) end end)
        pcall(function() game:GetService("GuiService"):OpenBrowserWindow(cc.link) end)
        Notify("CC", cc.name.." TikTok abierto", 3)
    end)
end

local cFeat = CreateCard(pInf, "FEATURES")
local Features = {
    {name="SILENT AIM", s="WALL CHECK", c=Theme.Success},
    {name="AUTO SHOOT", s="WALL CHECK", c=Theme.Success},
    {name="AIMBOT", s="GLOBAL FOV", c=Theme.Accent2},
    {name="TRIGGER BOT v2", s="WALL CHECK", c=Theme.Success},
    {name="MACRO TAP", s="WALL CHECK", c=Theme.Success},
    {name="TEAM CHECK", s="OK", c=Theme.Success},
    {name="ESP V2", s="NEW", c=Theme.Accent2},
    {name="HITBOX BIG", s="15x15x16", c=Theme.Accent2},
    {name="SPEED", s="OK", c=Theme.Success},
    {name="HEADLESS/KORBLOX", s="OK", c=Theme.Success},
    {name="BOOMBOX 29", s="NEW", c=Theme.Accent2},
    {name="KILL SOUND", s="NEW", c=Theme.Accent2},
    {name="SCROLL TABS", s="NEW", c=Theme.Accent2},
    {name="BG 100%", s="15 FONDOS", c=Theme.Accent2},
    {name="CUSTOM ICON", s="NEW", c=Theme.Accent2},
    {name="ANIMATIONS", s="23 PACKS", c=Theme.Accent2},
    {name="ANIM MIXER", s="NEW", c=Theme.Accent2},
    {name="SKY CHANGER", s="30+ SKIES", c=Theme.Accent2},
    {name=SCRIPT_NAME, s=SCRIPT_VERSION, c=Theme.Success},
}
for _, ft in ipairs(Features) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 20)
    row.BackgroundColor3 = Theme.Section
    row.BorderSizePixel = 0
    row.ZIndex = 8
    row.Parent = cFeat
    addCorner(row, 5)
    createLabel(row, ft.name, UDim2.new(0.6,-10,1,0), UDim2.new(0,8,0,0), Theme.Text, Enum.Font.GothamBold, 8).ZIndex = 9
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 82, 0, 13)
    badge.Position = UDim2.new(1, -90, 0.5, -6.5)
    badge.BackgroundColor3 = ft.c
    badge.BackgroundTransparency = 0.82
    badge.BorderSizePixel = 0
    badge.ZIndex = 9
    badge.Parent = row
    addCorner(badge, 6)
    local bt = createLabel(badge, ft.s, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), ft.c, Enum.Font.GothamBold, 8)
    bt.TextXAlignment = Enum.TextXAlignment.Center
    bt.ZIndex = 10
end

-- Abrir Home
task.spawn(function()
    task.wait(0.1)
    local firstBtn = nil
    for _, child in ipairs(Sidebar:GetChildren()) do
        if child:IsA("TextButton") then firstBtn = child; break end
    end
    if firstBtn then
        firstBtn.BackgroundColor3 = Theme.Card
        firstBtn.BackgroundTransparency = 0.15
        firstBtn.TextColor3 = Theme.Text
        local ind = firstBtn:FindFirstChild("Indicator"); if ind then ind.Visible = true end
        ActiveTab = firstBtn
        Pages["HOME"].Visible = true
    end
end)

-- =========================================================
-- LOOPS
-- =========================================================
RunService.RenderStepped:Connect(function(dt)
    local ab = SZK.Aimbot
    if not ab.Enabled then return end
    if ab.OnlyGun then
        local c = LP.Character
        local tool = c and c:FindFirstChildOfClass("Tool")
        if not tool or IsFirearm(tool) ~= true then return end
    end
    local cfg = {Target=ab.TargetPart, UseFovLimit=true, FovSize=SZK.GlobalFov, WallCheck=false, MaxDistance=5000}
    local best = FindBestTarget(cfg)
    if not best then return end
    local tPos = best.Position
    if ab.Prediction then
        local hrp = best.Parent and best.Parent:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.AssemblyLinearVelocity
            if vel.Magnitude > 1 then
                local dist = (tPos - cam.CFrame.Position).Magnitude
                tPos = tPos + vel * (dist/1500) * ab.PredictionScale
            end
        end
    end
    local curCF = cam.CFrame
    local tgtCF = CFrame.new(curCF.Position, tPos)
    local sm = math.clamp(ab.Smoothness, 0, 1)
    local lf = 1 - sm
    if lf <= 0 then return end
    local alpha = 1 - (1-lf)^(dt*60)
    cam.CFrame = curCF:Lerp(tgtCF, alpha)
end)

task.spawn(function()
    local knifeHead = {"Head","HumanoidRootPart","UpperTorso","Torso"}
    local knifeTorso = {"UpperTorso","Torso","HumanoidRootPart","LowerTorso"}
    local knifeFull = {"Head","HumanoidRootPart","UpperTorso","Torso","LowerTorso","LeftUpperArm","RightUpperArm","LeftUpperLeg","RightUpperLeg","LeftArm","RightArm","LeftLeg","RightLeg"}
    local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
    local function getParts(m)
        if m == "Cabeza" then return knifeHead end
        if m == "Torso" then return knifeTorso end
        return knifeFull
    end
    while true do
        if SZK.KnifeBot.Enabled then
            local c = LP.Character
            if c and c:FindFirstChild("HumanoidRootPart") then
                local arma = c:FindFirstChildOfClass("Tool")
                if arma and arma:FindFirstChild("Handle") and IsMelee(arma) then
                    local myPos = c.HumanoidRootPart.Position
                    local objs = {}
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= LP and IsEnemy(p) and p.Character then
                            local eh = p.Character:FindFirstChild("Humanoid")
                            if eh and eh.Health > 0 then
                                for _, pn in ipairs(getParts(SZK.KnifeBot.TargetPart)) do
                                    local pt = p.Character:FindFirstChild(pn)
                                    if pt and pt:IsA("BasePart") then
                                        table.insert(objs, {Part=pt, Dist=(pt.Position-myPos).Magnitude, Char=p.Character})
                                    end
                                end
                            end
                        end
                    end
                    table.sort(objs, function(a,b) return a.Dist < b.Dist end)
                    local tgtPart, tgtChar
                    for _, o in ipairs(objs) do
                        params.FilterDescendantsInstances = {c, o.Char}
                        local cf = o.Part.CFrame
                        local vis = not workspace:Raycast(myPos, cf.Position-myPos, params)
                        if vis then tgtPart = o.Part; tgtChar = o.Char; break end
                    end
                    if tgtPart and tgtChar then
                        local eHRP = tgtChar:FindFirstChild("HumanoidRootPart")
                        if eHRP then genv.SZK_KnifeTarget = eHRP end
                        pcall(function()
                            arma:Activate()
                            task.delay(0.002, function() if arma.Parent == c then arma:Deactivate() end end)
                        end)
                        task.wait(0.003)
                    else
                        genv.SZK_KnifeTarget = nil; task.wait(0.01)
                    end
                else genv.SZK_KnifeTarget = nil; task.wait(0.05) end
            else task.wait(0.1) end
        else genv.SZK_KnifeTarget = nil; task.wait(0.05) end
    end
end)

task.spawn(function()
    while task.wait(0.008) do
        local tb = SZK.TriggerBot
        if tb.Enabled and tb._toggled and InGame() then
            local c = LP.Character
            if c then
                local myHRP = GetHRP(LP)
                if myHRP then
                    local best = FindBestTarget(tb)
                    if best then
                        local ct = c:FindFirstChildOfClass("Tool")
                        if tb.DropMelee and ct and IsMelee(ct) then
                            UnequipCurrentTool(); tb._weaponEquipped = nil; task.wait(0.02)
                            ct = c:FindFirstChildOfClass("Tool")
                        end
                        if tb.AutoEquip then
                            local needF = tb.PreferFirearm and (not ct or IsFirearm(ct) ~= true)
                            if needF or not ct then
                                local w = FindWeaponInBackpack(tb.PreferFirearm)
                                if w and w ~= ct then
                                    EquipTool(w); tb._weaponEquipped = w
                                    task.wait(0.02); ct = c:FindFirstChildOfClass("Tool")
                                end
                            end
                        end
                        if tb.AutoShoot and ct and ct:FindFirstChild("Handle") then
                            local now = tick()
                            if (now - tb._lastShot) >= tb.ShootDelay then
                                tb._lastShot = now
                                genv.SZK_ShotTarget = best
                                pcall(function()
                                    if ct.Parent == c then
                                        ct:Activate()
                                        task.delay(tb.ActivateTime, function()
                                            pcall(function() if ct.Parent == c then ct:Deactivate() end end)
                                        end)
                                    end
                                end)
                                task.delay(0.2, function()
                                    if genv.SZK_ShotTarget == best then genv.SZK_ShotTarget = nil end
                                end)
                            end
                        end
                    else
                        if tb.UnequipNoEnemy and tb._weaponEquipped then
                            local tool = c:FindFirstChildOfClass("Tool")
                            if tool then
                                pcall(function()
                                    local hum = c:FindFirstChildOfClass("Humanoid")
                                    if hum then hum:UnequipTools() end
                                end)
                                tb._weaponEquipped = nil
                            end
                        end
                    end
                end
            end
        end
    end
end)

task.spawn(function()
    while task.wait(0.03) do
        local s = SZK.SilentAim
        if s.Enabled and s._toggled and InGame() then
            genv.SZK_Target = FindBestTarget(s)
        else genv.SZK_Target = nil end
    end
end)

task.spawn(function()
    while task.wait(0.03) do
        local a = SZK.AutoShoot
        if a.Enabled and a._toggled and InGame() then
            local c = LP.Character
            local tool = c and c:FindFirstChildOfClass("Tool")
            if c and tool and tool:FindFirstChild("Handle") then
                local best = FindBestTarget(a)
                local now = tick()
                if best and (now - a._lastShot) >= a.ShootDelay then
                    genv.SZK_ShotTarget = best; a._lastShot = now
                    pcall(function()
                        if tool.Parent == c then tool:Activate() end
                        task.delay(a.ActivateTime, function()
                            pcall(function() if tool.Parent == c then tool:Deactivate() end end)
                        end)
                    end)
                end
            end
        end
    end
end)

-- =========================================================
-- MACRO
-- =========================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if not SZK.Macro.Enabled then return end
    if input.UserInputType ~= Enum.UserInputType.Touch and input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not InGame() then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local g1 = LP.PlayerGui:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
        if #g1 > 0 then return end
        local g2 = CORE:GetGuiObjectsAtPosition(input.Position.X, input.Position.Y)
        if #g2 > 0 then return end
    end
    local now = tick()
    if now - SZK.Macro._lastUse < SZK.Macro.Cooldown then return end
    SZK.Macro._lastUse = now
    task.spawn(function()
        local c = LP.Character; if not c then return end
        local myHRP = GetHRP(LP); if not myHRP then return end
        local tool = c:FindFirstChildOfClass("Tool")
        if SZK.Macro.AutoEquip then
            if not tool or IsFirearm(tool) ~= true then
                local w = FindWeaponInBackpack(true)
                if w then EquipTool(w); task.wait(0.12); tool = c:FindFirstChildOfClass("Tool") end
            end
        end
        if not tool or not tool:FindFirstChild("Handle") then return end
        for i = 1, 3 do
            if not LP.Character or tool.Parent ~= c then break end
            if not InGame() then break end
            local cfg = {Target=SZK.Macro.Target, UseFovLimit=false, WallCheck=SZK.Macro.WallCheck, MaxDistance=SZK.Macro.MaxDistance}
            local best = FindBestTarget(cfg)
            if not best then break end
            genv.SZK_ShotTarget = best; genv.SZK_Target = best
            pcall(function() tool:Activate(); task.wait(0.05); tool:Deactivate() end)
            task.wait(0.05)
        end
        task.delay(0.2, function() genv.SZK_ShotTarget = nil; genv.SZK_Target = nil end)
    end)
end)

-- =========================================================
-- KEYBINDS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.P then
        setWindow(not windowOpen)
    end
    if input.KeyCode == Enum.KeyCode.M then
        if Boombox.Playing then
            Boombox:Pause(); Notify("BOOMBOX", "Paused", 2)
        else
            Boombox.SoundId = BoomboxState.CurrentSong
            Boombox.Volume = BoomboxState.Volume
            Boombox.Looped = BoomboxState.Loop
            Boombox:Play(); BoomboxState.Playing = true
            Notify("BOOMBOX", "Playing: "..BoomboxState.CurrentName, 2)
        end
    end
    if input.KeyCode == SZK.SilentAim.Keybind then SZK.SilentAim._toggled = not SZK.SilentAim._toggled end
    if input.KeyCode == SZK.AutoShoot.Keybind then SZK.AutoShoot._toggled = not SZK.AutoShoot._toggled end
    if input.KeyCode == SZK.TriggerBot.Keybind then
        SZK.TriggerBot._toggled = not SZK.TriggerBot._toggled
        Notify("TRIGGER BOT", SZK.TriggerBot._toggled and "ON" or "OFF", 2)
    end
    if SZK.Keybinds.ESP and input.KeyCode == SZK.Keybinds.ESP then
        SZK.ESP.Enabled = not SZK.ESP.Enabled; rebuildAllESP()
        Notify("PC-MODE", "ESP "..(SZK.ESP.Enabled and "ON" or "OFF"), 2)
    end
    if SZK.Keybinds.TriggerBot and input.KeyCode == SZK.Keybinds.TriggerBot then
        SZK.TriggerBot.Enabled = not SZK.TriggerBot.Enabled
        SZK.TriggerBot._toggled = SZK.TriggerBot.Enabled
        Notify("PC-MODE", "TriggerBot "..(SZK.TriggerBot.Enabled and "ON" or "OFF"), 2)
    end
    if SZK.Keybinds.SilentAim and input.KeyCode == SZK.Keybinds.SilentAim then
        SZK.SilentAim.Enabled = not SZK.SilentAim.Enabled
        SZK.SilentAim._toggled = SZK.SilentAim.Enabled
        Notify("PC-MODE", "SilentAim "..(SZK.SilentAim.Enabled and "ON" or "OFF"), 2)
    end
    if SZK.Keybinds.Aimbot and input.KeyCode == SZK.Keybinds.Aimbot then
        SZK.Aimbot.Enabled = not SZK.Aimbot.Enabled
        Notify("PC-MODE", "Aimbot "..(SZK.Aimbot.Enabled and "ON" or "OFF"), 2)
    end
end)

-- =========================================================
-- SILENT AIM HOOK
-- =========================================================
pcall(function()
    if hookmetamethod and checkcaller and getnamecallmethod then
        local oldH
        oldH = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local target = genv.SZK_ShotTarget or genv.SZK_Target or genv.SZK_KnifeTarget
            if not checkcaller() and target and target.Parent then
                if method == "Raycast" and self == workspace then
                    local origin, direction, params = ...
                    if typeof(direction) == "Vector3" and typeof(origin) == "Vector3" then
                        local newDir = (target.Position - origin).Unit * math.max(direction.Magnitude, 5000)
                        return oldH(self, origin, newDir, params)
                    end
                end
            end
            return oldH(self, ...)
        end)
    end
end)

-- =========================================================
-- ESTADO INICIAL
-- =========================================================
BallBtn.Visible = true
MainFrame.Visible = false
genv.SZK = SZK
genv.SZK_InGame = InGame
Notify(SCRIPT_NAME, SCRIPT_VERSION.." — FLUX WIND UI + PLAYER TAB ✅", 4)
