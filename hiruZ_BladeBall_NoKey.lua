-- ══════════════════════════════════════════════════════════════════
-- hiruZ UI — Blade Ball (No Key)
-- by ZivX ◈ Rebuilt: Instant-Fire Engines · Ghost Desync ·
-- Chat Commands · Holographic Key Scanner · All Premium Features
-- FIXED: AutoParry longevity, early-fire 0.5s lookahead,
--        premium ability detector sensitivity, premium rearm
-- ══════════════════════════════════════════════════════════════════

-- ── Services ─────────────────────────────────────────────────────
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local VIM           = game:GetService("VirtualInputManager")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local CoreGui       = game:GetService("CoreGui")
local Lighting      = game:GetService("Lighting")
local Stats         = game:GetService("Stats")
local Plr           = Players.LocalPlayer
local Cam           = workspace.CurrentCamera

-- ── Destroy old instances ─────────────────────────────────────────
pcall(function()
    for _, g in ipairs(CoreGui:GetChildren()) do
        if g.Name:find("Ryuu") then pcall(function() g:Destroy() end) end
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- RAYFIELD STUB (fallback if Rayfield fails to load)
-- ══════════════════════════════════════════════════════════════════
local Rayfield
local function makeStub()
    local function makeTab()
        return {
            CreateToggle   = function(_, t) if t and t.Callback then t.Callback(t.CurrentValue or false) end end,
            CreateSlider   = function(_, t) if t and t.Callback then t.Callback(t.CurrentValue or 0) end end,
            CreateLabel    = function() return {Text=""} end,
            CreateSection  = function() end,
            CreateDivider  = function() end,
            CreateButton   = function() end,
            CreateKeybind  = function() end,
            CreateInput    = function() end,
            CreateDropdown = function(_, t) if t and t.Callback then t.Callback({t.CurrentOption and t.CurrentOption[1] or ""}) end end,
        }
    end
    return {
        CreateWindow = function() return { CreateTab = function() return makeTab() end } end,
        Notify = function() end,
        Flags  = {},
    }
end

-- ══════════════════════════════════════════════════════════════════
-- KEY SYSTEM REMOVED - PREMIUM ALWAYS UNLOCKED

-- PREMIUM PERSISTENCE — auto-save key + settings per device
-- ══════════════════════════════════════════════════════════════════
local PREM_SAVE_FILE = "ryuu_premium.txt"

local function SavePremiumData(key, settings)
    pcall(function()
        local lines = { "key=" .. tostring(key) }
        if settings then
            for k, v in pairs(settings) do
                lines[#lines+1] = tostring(k) .. "=" .. tostring(v)
            end
        end
        writefile(PREM_SAVE_FILE, table.concat(lines, "\n"))
    end)
end

local function LoadPremiumData()
    local ok, data = pcall(function() return readfile(PREM_SAVE_FILE) end)
    if not ok or not data or data == "" then return nil end
    local result = {}
    for line in data:gmatch("[^\n]+") do
        local k, v = line:match("^(.-)=(.+)$")
        if k and v then result[k] = v end
    end
    return result.key and result or nil
end

local function ParseBool(s) return s == "true" end
local function ParseNum(s)  return tonumber(s) end

local function SavePremSettings()
    if not PremiumUnlocked then return end
    local existing = LoadPremiumData()
    local key = existing and existing.key or ""
    SavePremiumData(key, {
        AutoParry       = tostring(P.AutoParry),
        LobbyParry      = tostring(P.LobbyParry),
        GodEmergency    = tostring(P.GodEmergency),
        AutoFace        = tostring(P.AutoFace),
        HitboxTarget    = tostring(P.HitboxTarget),
        EarlyOffset     = tostring(P.EarlyOffset),
        ParrySound      = tostring(PF.ParrySound),
        AntiBlock       = tostring(PF.AntiBlock),
        ComboTracker    = tostring(PF.ComboTracker),
        AutoChat        = tostring(PF.AutoChat),
        TrajectoryESP   = tostring(PF.TrajectoryESP),
        BallSpeedMeter  = tostring(PF.BallSpeedMeter),
        TimeToImpact    = tostring(PF.TimeToImpact),
        TargetAlert     = tostring(PF.TargetAlert),
        DistESP         = tostring(PF.DistESP),
        Chams           = tostring(PF.Chams),
        BallHighlight   = tostring(PF.BallHighlight),
        RainbowTrail    = tostring(PF.RainbowTrail),
        AutoDodge       = tostring(PF.AutoDodge),
        SpeedOnParry    = tostring(PF.SpeedOnParry),
        SpeedOnParryAmt = tostring(PF.SpeedOnParryAmt),
        GhostMode       = tostring(PF.GhostMode),
        PremFPS         = tostring(PF.PremFPS),
        PremFPSCap      = tostring(PF.PremFPSCap),
        KillTracker     = tostring(PF.KillTracker),
        PremWatermark   = tostring(PF.PremWatermark),
        SafeZoneWarn    = tostring(PF.SafeZoneWarn),
        VelArrow        = tostring(PF.VelArrow),
        PremAccuracy    = tostring(PremAccuracy),
    })
end

-- ══════════════════════════════════════════════════════════════════
-- INTRO ◈ CYBERPUNK KATANA BOOT SEQUENCE — V3 ULTRA
-- Multi-layered: matrix rain → katana slash reveal → holographic
-- title card with DNA helix particles → scanline HUD flicker
-- ══════════════════════════════════════════════════════════════════
do
    local IntroSG = Instance.new("ScreenGui")
    IntroSG.Name = "RyuuIntro"; IntroSG.ResetOnSpawn = false
    IntroSG.IgnoreGuiInset = true; IntroSG.DisplayOrder = 99999
    pcall(function() IntroSG.Parent = (typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not IntroSG.Parent then pcall(function() IntroSG.Parent = Plr:WaitForChild("PlayerGui") end) end

    local vs = Cam and Cam.ViewportSize or Vector2.new(1920,1080)
    local CX, CY = vs.X/2, vs.Y/2
    local alive = true

    local function snd(id, vol, pit)
        pcall(function()
            local s = Instance.new("Sound", workspace)
            s.SoundId = "rbxassetid://"..id; s.Volume = vol or 0.6
            s.PlaybackSpeed = pit or 1; s.RollOffMaxDistance = 0; s:Play()
            game:GetService("Debris"):AddItem(s, 8)
        end)
    end

    local function mkFrame(parent, props)
        local f = Instance.new("Frame", parent)
        for k,v in pairs(props) do pcall(function() f[k]=v end) end
        return f
    end
    local function mkLabel(parent, props)
        local l = Instance.new("TextLabel", parent)
        for k,v in pairs(props) do pcall(function() l[k]=v end) end
        return l
    end
    local function mkCorner(parent, r)
        Instance.new("UICorner", parent).CornerRadius = UDim.new(0, r or 8)
    end
    local function mkStroke(parent, thickness, color, trans)
        local s = Instance.new("UIStroke", parent)
        s.Thickness = thickness; s.Color = color; s.Transparency = trans or 0
        return s
    end
    local function mkGrad(parent, keypoints, rot)
        local g = Instance.new("UIGradient", parent)
        g.Color = ColorSequence.new(keypoints); g.Rotation = rot or 0
        return g
    end
    local function ring(parent, color, sz0, szF, dur, delay)
        task.delay(delay or 0, function()
            if not alive then return end
            local r = mkFrame(parent, {
                AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
                Size=UDim2.new(0,sz0,0,sz0), BackgroundTransparency=1, BorderSizePixel=0, ZIndex=6
            })
            mkCorner(r, 9999)
            local rs = mkStroke(r, 2.5, color, 0)
            TweenService:Create(r, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size=UDim2.new(0,szF,0,szF)}):Play()
            TweenService:Create(rs, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Transparency=1}):Play()
            game:GetService("Debris"):AddItem(r, dur+0.1)
        end)
    end

    -- ══ LAYER 0 — VOID BLACK BASE ═══════════════════════════════
    local BG = mkFrame(IntroSG, {
        Size=UDim2.new(1,0,1,0), BackgroundColor3=Color3.fromRGB(0,0,2),
        BackgroundTransparency=0, BorderSizePixel=0, ZIndex=1
    })

    -- ══ LAYER 1 — MATRIX RAIN COLUMNS ═══════════════════════════
    -- Katakana-style characters falling like digital rain
    local MatrixLayer = mkFrame(IntroSG, {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=2
    })
    MatrixLayer.ClipsDescendants = true

    local MATRIX_CHARS = {"ア","イ","ウ","エ","オ","カ","キ","ク","ケ","コ",
        "サ","シ","ス","セ","ソ","タ","チ","ツ","テ","ト","ナ","ニ","ヌ","ネ","ノ",
        "0","1","2","3","4","5","6","7","8","9","R","Y","U","U","∞","◈","⚔","龍"}

    local COL_W = 18
    local NUM_COLS = math.floor(vs.X / COL_W) + 2
    local matrixCols = {}

    for c = 0, NUM_COLS do
        local cx = c * COL_W
        local colLen = math.random(6, 18)
        local speed  = 0.015 + math.random() * 0.025
        local startY = -math.random(20, 80) * COL_W
        local cells  = {}
        for row = 0, colLen do
            local cell = mkLabel(MatrixLayer, {
                Position = UDim2.new(0, cx, 0, startY + row*COL_W),
                Size     = UDim2.new(0, COL_W, 0, COL_W),
                BackgroundTransparency = 1,
                Text = MATRIX_CHARS[math.random(#MATRIX_CHARS)],
                Font = Enum.Font.Code, TextSize = 11,
                TextColor3 = (row == 0)
                    and Color3.fromRGB(255,255,255)
                    or  Color3.fromHSV(0.77, 0.8, math.clamp(1 - row/colLen*0.85, 0.1, 1)),
                TextTransparency = (row == 0) and 0 or math.clamp(row/colLen*0.9, 0, 0.9),
                ZIndex = 2,
            })
            table.insert(cells, {lbl=cell, row=row, len=colLen})
        end
        table.insert(matrixCols, {cells=cells, py=startY, speed=speed, cx=cx, charTimer=0})
    end

    local matrixAlive = true
    task.spawn(function()
        while matrixAlive do
            for _, col in ipairs(matrixCols) do
                col.py = col.py + col.speed * vs.Y * 0.016
                col.charTimer = col.charTimer + 1
                if col.py > vs.Y + 200 then
                    col.py = -math.random(40,120) * 0.8 * COL_W
                    col.speed = 0.015 + math.random()*0.025
                end
                for i, cell in ipairs(col.cells) do
                    pcall(function()
                        cell.lbl.Position = UDim2.new(0, col.cx, 0, col.py + (i-1)*COL_W)
                        -- Occasionally randomize char
                        if col.charTimer % math.random(8,24) == 0 then
                            cell.lbl.Text = MATRIX_CHARS[math.random(#MATRIX_CHARS)]
                        end
                    end)
                end
            end
            task.wait(0.022)
        end
    end)

    -- ══ LAYER 2 — SCANLINE OVERLAY ═══════════════════════════════
    local ScanLayer = mkFrame(IntroSG, {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=3
    })
    -- Horizontal scanlines (thin dark bands)
    local SCAN_STEP = 4
    for sy = 0, math.floor(vs.Y/SCAN_STEP) do
        mkFrame(ScanLayer, {
            Position = UDim2.new(0,0,0,sy*SCAN_STEP),
            Size = UDim2.new(1,0,0,1),
            BackgroundColor3 = Color3.fromRGB(0,0,0),
            BackgroundTransparency = 0.72,
            BorderSizePixel = 0, ZIndex = 3
        })
    end
    -- Animated scanline sweeper
    local sweepLine = mkFrame(ScanLayer, {
        Size=UDim2.new(1,0,0,3), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(160,0,255), BackgroundTransparency=0.55,
        BorderSizePixel=0, ZIndex=4
    })
    mkGrad(sweepLine, {
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220,0,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
    })
    task.spawn(function()
        while sweepLine.Parent and alive do
            sweepLine.Position = UDim2.new(0,0,0,-4)
            TweenService:Create(sweepLine, TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                {Position=UDim2.new(0,0,1,4)}):Play()
            task.wait(2.2)
        end
    end)

    -- ══ LAYER 3 — KATANA SLASH REVEAL ════════════════════════════
    -- A bright diagonal slash tears across screen, peeling away matrix
    local SlashLayer = mkFrame(IntroSG, {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=10
    })
    local SlashLine = mkFrame(SlashLayer, {
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(-0.1,0,0.5,0),
        Size=UDim2.new(0,8,1,600),
        Rotation=15,
        BackgroundColor3=Color3.fromRGB(255,255,255),
        BackgroundTransparency=1,
        BorderSizePixel=0, ZIndex=11
    })
    mkGrad(SlashLine, {
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.15, Color3.fromRGB(0,220,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.85, Color3.fromRGB(255,100,0)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,255,255)),
    }, 90)
    -- Slash afterglow (wider, more transparent)
    local SlashGlow = mkFrame(SlashLayer, {
        AnchorPoint=Vector2.new(0.5,0.5),
        Position=UDim2.new(-0.1,0,0.5,0),
        Size=UDim2.new(0,60,1,600),
        Rotation=15,
        BackgroundColor3=Color3.fromRGB(160,0,255),
        BackgroundTransparency=0.75,
        BorderSizePixel=0, ZIndex=10
    })
    mkGrad(SlashGlow, {
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255,80,0)),
    }, 90)

    -- ══ LAYER 4 — DNA HELIX PARTICLE SYSTEM ══════════════════════
    -- Two strands of particles orbiting a vertical axis = DNA helix
    local DNALayer = mkFrame(IntroSG, {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=8
    })
    DNALayer.ClipsDescendants = true

    local DNA_PARTICLES = 40
    local dnaParticles = {}
    local DNA_COLORS_A = {Color3.fromRGB(0,200,255), Color3.fromRGB(0,150,255)}
    local DNA_COLORS_B = {Color3.fromRGB(255,60,0),  Color3.fromRGB(220,0,255)}

    for i = 1, DNA_PARTICLES do
        local isA = i % 2 == 0
        local t0  = (i / DNA_PARTICLES) * math.pi * 4  -- phase offset
        local col = isA and DNA_COLORS_A[math.random(#DNA_COLORS_A)]
                         or DNA_COLORS_B[math.random(#DNA_COLORS_B)]
        local sz  = math.random(4,8)
        local p   = mkFrame(DNALayer, {
            AnchorPoint = Vector2.new(0.5,0.5),
            Position = UDim2.new(0.5,0,0.5,0),
            Size = UDim2.new(0,sz,0,sz),
            BackgroundColor3 = col,
            BackgroundTransparency = 0.3,
            BorderSizePixel = 0, ZIndex = 8
        })
        mkCorner(p, 99)
        -- connector bar between strand A & B at same phase
        local bar = nil
        if isA then
            bar = mkFrame(DNALayer, {
                AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
                Size=UDim2.new(0,2,0,2), BackgroundColor3=Color3.fromRGB(80,80,80),
                BackgroundTransparency=0.5, BorderSizePixel=0, ZIndex=7
            })
        end
        table.insert(dnaParticles, {f=p, bar=bar, t=t0, isA=isA, sz=sz, col=col})
    end

    local dnaT = 0; local dnaAlive = true
    task.spawn(function()
        while dnaAlive do
            dnaT = dnaT + 0.04
            for _, dp in ipairs(dnaParticles) do
                pcall(function()
                    local phase = dp.t + dnaT
                    local helixR = 80  -- horizontal radius
                    local helixH = 320 -- vertical span
                    -- Y position scrolls downward slowly, wraps
                    local normY = ((dp.t / (math.pi*4)) + dnaT*0.04) % 1
                    local pyAbs = CY - helixH/2 + normY * helixH
                    local sideX = dp.isA and math.cos(phase)*helixR or math.cos(phase+math.pi)*helixR
                    dp.f.Position = UDim2.new(0, CX + sideX, 0, pyAbs)
                    -- Depth cue: scale + alpha based on cosine
                    local depth = (math.cos(phase)+1)/2  -- 0..1
                    local sc    = math.floor((0.5+depth*0.7)*dp.sz)
                    dp.f.Size   = UDim2.new(0, math.max(2,sc), 0, math.max(2,sc))
                    dp.f.BackgroundTransparency = 0.1 + (1-depth)*0.7
                    -- Connector bar (for isA pairs, draw between A and its B twin)
                    if dp.bar then
                        local otherX = math.cos(phase+math.pi)*helixR
                        local midX   = CX + (sideX + otherX)/2
                        local barW   = math.abs(sideX - otherX)
                        dp.bar.Position = UDim2.new(0, midX, 0, pyAbs)
                        dp.bar.Size     = UDim2.new(0, math.max(2,math.floor(barW)), 0, 1)
                        dp.bar.BackgroundTransparency = 0.4 + (1-depth)*0.5
                    end
                end)
            end
            task.wait(0.022)
        end
    end)

    -- ══ LAYER 5 — CENTRAL HOLOGRAPHIC TITLE CARD ══════════════════
    local CardHolder = mkFrame(IntroSG, {
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        Size=UDim2.new(0,0,0,0), BackgroundTransparency=1, ZIndex=20
    })

    -- Outer glow halo
    local Halo = mkFrame(CardHolder, {
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        Size=UDim2.new(1,80,1,80), BackgroundColor3=Color3.fromRGB(120,0,255),
        BackgroundTransparency=0.78, BorderSizePixel=0, ZIndex=19
    })
    mkCorner(Halo, 28)

    -- Main card glass pane
    local Card = mkFrame(CardHolder, {
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0.5,0),
        Size=UDim2.new(1,0,1,0),
        BackgroundColor3=Color3.fromRGB(4,2,14),
        BackgroundTransparency=0.04,
        BorderSizePixel=0, ZIndex=20
    })
    mkCorner(Card, 18)
    local CardStroke = mkStroke(Card, 2.2, Color3.fromRGB(200,60,255), 0.0)
    mkGrad(Card, {
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(10,3,28)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(4,2,14)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,5,20)),
    }, 145)

    -- Animated cycling border
    task.spawn(function()
        local hue = 0
        while CardStroke.Parent and alive do
            hue = (hue + 0.004) % 1
            pcall(function()
                CardStroke.Color = Color3.fromHSV(hue, 0.9, 1.0)
                Halo.BackgroundColor3 = Color3.fromHSV(hue, 0.85, 0.7)
            end)
            task.wait(0.04)
        end
    end)

    -- Top chromatic stripe (3-color, animated offset)
    local TopStripe = mkFrame(Card, {
        Size=UDim2.new(1,0,0,4), Position=UDim2.new(0,0,0,0),
        BackgroundColor3=Color3.fromRGB(255,60,0), BorderSizePixel=0, ZIndex=22
    })
    mkCorner(TopStripe, 18)
    local TopGrad = mkGrad(TopStripe, {
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,30,0)),
        ColorSequenceKeypoint.new(0.25, Color3.fromRGB(255,0,160)),
        ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(100,0,255)),
        ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0,180,255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(0,255,180)),
    })
    task.spawn(function()
        local off = 0
        while TopGrad.Parent and alive do
            off = off + 0.012
            pcall(function() TopGrad.Rotation = math.sin(off)*4 end)
            task.wait(0.04)
        end
    end)

    -- Bottom accent stripe
    local BotStripe = mkFrame(Card, {
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BackgroundColor3=Color3.fromRGB(0,200,255), BorderSizePixel=0, ZIndex=22
    })
    mkCorner(BotStripe, 18)
    mkGrad(BotStripe, {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,200,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255,0,200)),
    })

    -- RYUU  HUB  — massive glitch title
    local TitleMain = mkLabel(Card, {
        AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,14),
        Size=UDim2.new(1,-32,0,56),
        BackgroundTransparency=1,
        Text="龍  RYUU HUB", Font=Enum.Font.GothamBlack, TextSize=40,
        TextTransparency=1, ZIndex=24,
        TextXAlignment=Enum.TextXAlignment.Center,
    })
    mkGrad(TitleMain, {
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,80,0)),
        ColorSequenceKeypoint.new(0.22, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.44, Color3.fromRGB(180,0,255)),
        ColorSequenceKeypoint.new(0.66, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.88, Color3.fromRGB(0,220,255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,80,180)),
    })

    -- Glitch offset shadow (chromatic aberration sim)
    local TitleShadowR = mkLabel(Card, {
        AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,2,0,15),
        Size=UDim2.new(1,-32,0,56),
        BackgroundTransparency=1,
        Text="龍  RYUU HUB", Font=Enum.Font.GothamBlack, TextSize=40,
        TextColor3=Color3.fromRGB(255,0,60), TextTransparency=0.72, ZIndex=23,
        TextXAlignment=Enum.TextXAlignment.Center,
    })
    local TitleShadowB = mkLabel(Card, {
        AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,-2,0,16),
        Size=UDim2.new(1,-32,0,56),
        BackgroundTransparency=1,
        Text="龍  RYUU HUB", Font=Enum.Font.GothamBlack, TextSize=40,
        TextColor3=Color3.fromRGB(0,200,255), TextTransparency=0.72, ZIndex=23,
        TextXAlignment=Enum.TextXAlignment.Center,
    })

    -- Subtitle
    local SubLbl = mkLabel(Card, {
        AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,72),
        Size=UDim2.new(1,-32,0,14),
        BackgroundTransparency=1,
        Text="V 2 . 0  ◈  ZivX  ◈  ELITE PARRY ENGINE",
        Font=Enum.Font.GothamBold, TextSize=10,
        TextColor3=Color3.fromRGB(160,80,255), TextTransparency=1, ZIndex=24,
        TextXAlignment=Enum.TextXAlignment.Center,
    })

    -- Mid divider with diamond
    local DivL = mkFrame(Card, {
        Position=UDim2.new(0.05,0,0,92), Size=UDim2.new(0.38,0,0,1),
        BackgroundColor3=Color3.fromRGB(100,30,200), BorderSizePixel=0, ZIndex=23
    })
    local DivR = mkFrame(Card, {
        Position=UDim2.new(0.57,0,0,92), Size=UDim2.new(0.38,0,0,1),
        BackgroundColor3=Color3.fromRGB(100,30,200), BorderSizePixel=0, ZIndex=23
    })
    local DiamondLbl = mkLabel(Card, {
        AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0.5,0,0,92),
        Size=UDim2.new(0,20,0,14),
        BackgroundTransparency=1, Text="◈",
        Font=Enum.Font.GothamBlack, TextSize=10,
        TextColor3=Color3.fromRGB(200,80,255), ZIndex=24
    })

    -- BOOT LOG — monospace terminal lines
    local LogBG = mkFrame(Card, {
        Position=UDim2.new(0.05,0,0,100), Size=UDim2.new(0.9,0,0,56),
        BackgroundColor3=Color3.fromRGB(2,8,2), BackgroundTransparency=0.15,
        BorderSizePixel=0, ZIndex=23
    })
    mkCorner(LogBG, 6)
    mkStroke(LogBG, 1, Color3.fromRGB(30,80,30), 0.3)
    local logLines = {}
    for ln = 0, 3 do
        local ll = mkLabel(LogBG, {
            Position=UDim2.new(0,8,0,2+ln*13), Size=UDim2.new(1,-16,0,13),
            BackgroundTransparency=1, Text="",
            Font=Enum.Font.Code, TextSize=9,
            TextColor3=Color3.fromRGB(60,220,80), TextTransparency=0.0,
            ZIndex=24, TextXAlignment=Enum.TextXAlignment.Left
        })
        table.insert(logLines, ll)
    end

    -- Progress bar system — segmented blocks style
    local PBarOuter = mkFrame(Card, {
        Position=UDim2.new(0.05,0,0,162), Size=UDim2.new(0.9,0,0,8),
        BackgroundColor3=Color3.fromRGB(8,4,20), BackgroundTransparency=0.1,
        BorderSizePixel=0, ZIndex=23
    })
    mkCorner(PBarOuter, 4)
    mkStroke(PBarOuter, 1, Color3.fromRGB(80,20,160), 0.3)

    local PBarFill = mkFrame(PBarOuter, {
        Position=UDim2.new(0,0,0,0), Size=UDim2.new(0,0,1,0),
        BackgroundColor3=Color3.fromRGB(0,220,255), BackgroundTransparency=0,
        BorderSizePixel=0, ZIndex=24
    })
    mkCorner(PBarFill, 4)
    mkGrad(PBarFill, {
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,30,100)),
        ColorSequenceKeypoint.new(0.35, Color3.fromRGB(200,0,255)),
        ColorSequenceKeypoint.new(0.7,  Color3.fromRGB(0,180,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,255,200)),
    })
    -- Shimmer sweep on bar
    local BarShim = mkFrame(PBarFill, {
        Size=UDim2.new(0,40,1,0), Position=UDim2.new(-0.4,0,0,0),
        BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.35,
        BorderSizePixel=0, ZIndex=25
    })
    mkCorner(BarShim, 4)
    task.spawn(function()
        while BarShim.Parent and alive do
            BarShim.Position = UDim2.new(-0.4,0,0,0)
            TweenService:Create(BarShim, TweenInfo.new(0.7, Enum.EasingStyle.Quad), {Position=UDim2.new(1.3,0,0,0)}):Play()
            task.wait(0.95)
        end
    end)

    -- Percent label
    local PctLbl = mkLabel(Card, {
        AnchorPoint=Vector2.new(0.5,0), Position=UDim2.new(0.5,0,0,173),
        Size=UDim2.new(0.9,0,0,12),
        BackgroundTransparency=1, Text="0%",
        Font=Enum.Font.Code, TextSize=8,
        TextColor3=Color3.fromRGB(80,200,255), TextTransparency=0.0,
        ZIndex=24, TextXAlignment=Enum.TextXAlignment.Right
    })

    -- Tag chips row
    local function makeChip(parent, txt, xpos, col)
        local chip = mkFrame(parent, {
            Position=UDim2.new(0,xpos,0,188), Size=UDim2.new(0,0,0,14),
            BackgroundColor3=col, BackgroundTransparency=0.6,
            BorderSizePixel=0, ZIndex=24
        })
        mkCorner(chip, 4)
        mkStroke(chip, 1, col, 0.1)
        local cl = mkLabel(chip, {
            Size=UDim2.new(1,0,1,0), BackgroundTransparency=1,
            Text=txt, Font=Enum.Font.GothamBold, TextSize=8,
            TextColor3=col, ZIndex=25
        })
        -- Auto-size width
        chip.Size = UDim2.new(0, #txt * 5 + 16, 0, 14)
        return chip
    end
    local chipPad = 12
    local chipX = 0
    local chipsData = {
        {"⚔ AUTO-PARRY",  Color3.fromRGB(255,80,0)},
        {"◈ PREMIUM",     Color3.fromRGB(200,0,255)},
        {"⚡ LOOKAHEAD",   Color3.fromRGB(0,200,255)},
        {"🐉 GHOST",       Color3.fromRGB(80,255,120)},
    }
    for _, cd in ipairs(chipsData) do
        local w = #cd[1] * 5 + 16
        makeChip(Card, cd[1], chipX + chipPad, cd[2])
        chipX = chipX + w + 8
    end

    -- ══ RINGS LAYER (centered on card) ═══════════════════════════
    local RingLayer = mkFrame(IntroSG, {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, ZIndex=12
    })

    -- ══ ANIMATION SEQUENCE ═══════════════════════════════════════
    local loadDone = false

    task.spawn(function()
        -- Phase 0: matrix rain + scanlines for 0.6s
        snd(6042053626, 0.6, 0.8)
        task.wait(0.6)

        -- Phase 1: KATANA SLASH across screen
        snd(4590662766, 0.9, 1.4)
        -- Slash line blasts from left to right
        SlashLine.BackgroundTransparency = 0
        SlashGlow.BackgroundTransparency = 0.55
        TweenService:Create(SlashLine, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position=UDim2.new(1.1,0,0.5,0)}):Play()
        TweenService:Create(SlashGlow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {Position=UDim2.new(1.1,0,0.5,0)}):Play()
        -- Simultaneous: matrix rain flashes white
        for _, col in ipairs(matrixCols) do
            for _, cell in ipairs(col.cells) do
                pcall(function() cell.lbl.TextColor3 = Color3.fromRGB(255,255,255); cell.lbl.TextTransparency = 0.1 end)
            end
        end
        task.wait(0.08)
        -- matrix fades back
        task.spawn(function()
            task.wait(0.15)
            for _, col2 in ipairs(matrixCols) do
                for i2, cell2 in ipairs(col2.cells) do
                    pcall(function()
                        cell2.lbl.TextColor3 = (i2==1)
                            and Color3.fromRGB(255,255,255)
                            or  Color3.fromHSV(0.77, 0.8, math.clamp(1-i2/cell2.len*0.85, 0.1, 1))
                    end)
                end
            end
        end)
        -- Shockwave rings from center
        ring(RingLayer, Color3.fromRGB(255,80,0),   20, math.min(vs.X,vs.Y)*1.2, 1.0, 0.00)
        ring(RingLayer, Color3.fromRGB(200,0,255),  20, math.min(vs.X,vs.Y)*1.0, 0.85, 0.08)
        ring(RingLayer, Color3.fromRGB(0,200,255),  20, math.min(vs.X,vs.Y)*0.8, 0.70, 0.16)
        task.wait(0.08)

        -- Phase 2: card materializes — shrinks in from 0
        CardHolder.Size = UDim2.new(0,0,0,0)
        CardHolder.BackgroundTransparency = 1
        snd(9119713951, 0.55, 0.88)
        TweenService:Create(CardHolder,
            TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size=UDim2.new(0,460,0,210)}):Play()
        task.wait(0.38)

        -- Phase 3: title glitch reveal
        TitleShadowR.TextTransparency = 0.72
        TitleShadowB.TextTransparency = 0.72
        TitleMain.TextTransparency    = 0
        for g = 1, 5 do
            TitleMain.TextTransparency = (g%2==0) and 0 or 0.65
            TitleShadowR.Position = UDim2.new(0.5, math.random(-4,4), 0, 15)
            TitleShadowB.Position = UDim2.new(0.5, math.random(-4,4), 0, 16)
            task.wait(0.045)
        end
        TitleMain.TextTransparency = 0
        TitleShadowR.Position = UDim2.new(0.5, 2, 0, 15)
        TitleShadowB.Position = UDim2.new(0.5,-2, 0, 16)
        snd(4590662766, 0.4, 1.6)
        task.wait(0.1)

        -- Subtitle fades in
        TweenService:Create(SubLbl, TweenInfo.new(0.3), {TextTransparency=0}):Play()
        task.wait(0.2)

        -- Phase 4: boot log lines + progress bar
        local BOOT_LOG = {
            {"[CORE]   Initializing dragon kernel...............",  0.13},
            {"[NET]    Binding server socket....................",   0.30},
            {"[PARRY]  Calibrating kinematic lookahead engine..", 0.52},
            {"[SEC]    Validating device fingerprint............", 0.70},
            {"[UI]     Loading Rayfield interface...............", 0.87},
            {"[SYS]    All subsystems NOMINAL ✓.................", 1.00},
        }
        for li, step in ipairs(BOOT_LOG) do
            if loadDone and li > 4 then break end
            -- Shift log lines up
            for ln = 1, 3 do
                if logLines[ln] then
                    pcall(function() logLines[ln].Text = logLines[ln+1] and logLines[ln+1].Text or "" end)
                end
            end
            if logLines[4] then logLines[4].Text = step[1] end
            -- Animate progress
            local pct = math.floor(step[2]*100)
            TweenService:Create(PBarFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size=UDim2.new(step[2],0,1,0)}):Play()
            -- Pulse bar color
            task.spawn(function()
                TweenService:Create(PBarFill, TweenInfo.new(0.1), {BackgroundTransparency=0.3}):Play()
                task.wait(0.12)
                TweenService:Create(PBarFill, TweenInfo.new(0.15), {BackgroundTransparency=0}):Play()
            end)
            PctLbl.Text = tostring(pct) .. "%"
            task.wait(0.38)
        end

        -- wait for rayfield
        local w2 = 0
        while not loadDone and w2 < 10 do task.wait(0.1); w2 = w2 + 0.1 end

        -- Phase 5: SUCCESS flash
        if logLines[4] then logLines[4].Text = "[RYUU]  *** SYSTEM ONLINE — READY TO PARRY ***" end
        if logLines[4] then logLines[4].TextColor3 = Color3.fromRGB(80,255,150) end
        PBarFill.BackgroundColor3 = Color3.fromRGB(50,255,130)
        PctLbl.Text = "100%"; PctLbl.TextColor3 = Color3.fromRGB(80,255,150)
        TweenService:Create(PBarFill, TweenInfo.new(0.18), {Size=UDim2.new(1,0,1,0)}):Play()
        snd(1847668471, 0.75, 1.05)
        ring(RingLayer, Color3.fromRGB(80,255,150),  20, math.min(vs.X,vs.Y)*1.4, 1.5, 0.0)
        ring(RingLayer, Color3.fromRGB(0,200,255),   20, math.min(vs.X,vs.Y)*1.1, 1.2, 0.12)

        -- card border turns green briefly
        CardStroke.Color = Color3.fromRGB(50,255,130)
        task.wait(1.0)

        -- Phase 6: cinematic teardown
        -- Title chromatic glitch burst then vanish
        for g2 = 1, 6 do
            TitleMain.TextTransparency = (g2%2==0) and 0.85 or 0
            TitleShadowR.Position = UDim2.new(0.5, math.random(-8,8), 0, 15)
            TitleShadowB.Position = UDim2.new(0.5, math.random(-8,8), 0, 16)
            task.wait(0.04)
        end
        alive = false; matrixAlive = false; dnaAlive = false

        local dissolve = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(CardHolder, dissolve, {Size=UDim2.new(0,0,0,0)}):Play()
        TweenService:Create(BG, TweenInfo.new(0.55), {BackgroundTransparency=1}):Play()
        task.wait(0.6)
        pcall(function() IntroSG:Destroy() end)
    end)

    -- Load Rayfield in parallel
    local RF_URLS = {
        "https://sirius.menu/rayfield",
        "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua",
    }
    for _, url in ipairs(RF_URLS) do
        local ok, res = pcall(function() return loadstring(game:HttpGet(url, true))() end)
        if ok and res then Rayfield = res; break end
    end
    if not Rayfield then
        warn("[Ryuu V2] Rayfield load failed — using stub")
        Rayfield = makeStub()
    end
    loadDone = true
end

-- ══════════════════════════════════════════════════════════════════
-- ALWAYS-ON HUD — ULTRA CYBERPUNK EDITION
-- Features: animated border cycle, live parry arc meter, corner
-- brackets, scanline overlay, holographic depth shimmer
-- ══════════════════════════════════════════════════════════════════
do
    local HudSG = Instance.new("ScreenGui")
    HudSG.Name = "RyuuHUD"; HudSG.ResetOnSpawn = false
    HudSG.IgnoreGuiInset = true; HudSG.DisplayOrder = 9998
    pcall(function() HudSG.Parent = (typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not HudSG.Parent then pcall(function() HudSG.Parent = Plr:WaitForChild("PlayerGui") end) end

    local W, H = 222, 148

    -- Outer glow halo
    local HudGlow = Instance.new("Frame", HudSG)
    HudGlow.AnchorPoint = Vector2.new(1,0); HudGlow.Position = UDim2.new(1,-8,0,8)
    HudGlow.Size = UDim2.new(0,W+12,0,H+12)
    HudGlow.BackgroundColor3 = Color3.fromRGB(120,0,255); HudGlow.BackgroundTransparency = 0.88
    HudGlow.BorderSizePixel = 0
    Instance.new("UICorner", HudGlow).CornerRadius = UDim.new(0,16)

    -- Main frame
    local HF = Instance.new("Frame", HudSG)
    HF.Name = "RyuuHUDFrame"
    HF.AnchorPoint = Vector2.new(1,0); HF.Position = UDim2.new(1,-14,0,14)
    HF.Size = UDim2.new(0,W,0,H)
    HF.BackgroundColor3 = Color3.fromRGB(3,1,12)
    HF.BackgroundTransparency = 0.06; HF.BorderSizePixel = 0
    Instance.new("UICorner", HF).CornerRadius = UDim.new(0,13)
    local HFStroke = Instance.new("UIStroke", HF)
    HFStroke.Thickness = 1.8; HFStroke.Color = Color3.fromRGB(160,40,255); HFStroke.Transparency = 0.1

    -- Internal gradient
    local HFGrad = Instance.new("UIGradient", HF)
    HFGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(8,2,24)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(3,1,12)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,4,16)),
    }
    HFGrad.Rotation = 135

    -- Animated border hue cycle
    task.spawn(function()
        local hue = 0
        while HF.Parent do
            hue = (hue + 0.005) % 1
            pcall(function()
                HFStroke.Color = Color3.fromHSV(hue, 0.88, 1.0)
                HudGlow.BackgroundColor3 = Color3.fromHSV(hue, 0.85, 0.6)
            end)
            task.wait(0.05)
        end
    end)

    -- Corner bracket decorations (4 corners)
    local function mkCornerBracket(parent, ax, ay, rx, ry)
        -- Horizontal arm
        local bh = Instance.new("Frame", parent)
        bh.AnchorPoint = Vector2.new(ax,ay); bh.Position = UDim2.new(rx,0,ry,0)
        bh.Size = UDim2.new(0,14,0,2)
        bh.BackgroundColor3 = Color3.fromRGB(0,220,255); bh.BackgroundTransparency = 0.1
        bh.BorderSizePixel = 0; bh.ZIndex = 3
        -- Vertical arm
        local bv = Instance.new("Frame", parent)
        bv.AnchorPoint = Vector2.new(ax,ay); bv.Position = UDim2.new(rx,0,ry,0)
        bv.Size = UDim2.new(0,2,0,14)
        bv.BackgroundColor3 = Color3.fromRGB(0,220,255); bv.BackgroundTransparency = 0.1
        bv.BorderSizePixel = 0; bv.ZIndex = 3
    end
    mkCornerBracket(HF, 0,0, 0,0)    -- top-left
    mkCornerBracket(HF, 1,0, 1,0)    -- top-right
    mkCornerBracket(HF, 0,1, 0,1)    -- bottom-left
    mkCornerBracket(HF, 1,1, 1,1)    -- bottom-right

    -- Top chromatic stripe
    local HTopStripe = Instance.new("Frame", HF)
    HTopStripe.Size = UDim2.new(1,0,0,3); HTopStripe.Position = UDim2.new(0,0,0,0)
    HTopStripe.BorderSizePixel = 0; HTopStripe.ZIndex = 3
    Instance.new("UICorner", HTopStripe).CornerRadius = UDim.new(0,13)
    local HSGrad = Instance.new("UIGradient", HTopStripe)
    HSGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,30,0)),
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(200,0,255)),
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,180,255)),
        ColorSequenceKeypoint.new(1,    Color3.fromRGB(0,255,180)),
    }

    -- Scanline overlay (subtle dark bands)
    local ScanOv = Instance.new("Frame", HF)
    ScanOv.Size = UDim2.new(1,0,1,0); ScanOv.BackgroundTransparency=1; ScanOv.ZIndex=2; ScanOv.ClipsDescendants=true
    for sl = 0, math.floor(H/3) do
        local sf = Instance.new("Frame", ScanOv)
        sf.Position = UDim2.new(0,0,0,sl*3); sf.Size = UDim2.new(1,0,0,1)
        sf.BackgroundColor3 = Color3.fromRGB(0,0,0); sf.BackgroundTransparency = 0.86
        sf.BorderSizePixel = 0; sf.ZIndex = 2
    end

    -- Title row with icon
    local HTitle = Instance.new("TextLabel", HF)
    HTitle.Size = UDim2.new(1,-14,0,20); HTitle.Position = UDim2.new(0,8,0,5)
    HTitle.BackgroundTransparency = 1; HTitle.Text = "◈  RYUU HUB  V2"
    HTitle.Font = Enum.Font.GothamBlack; HTitle.TextSize = 11; HTitle.ZIndex = 4
    HTitle.TextXAlignment = Enum.TextXAlignment.Left
    local HTGrad = Instance.new("UIGradient", HTitle)
    HTGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,80,0)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(220,80,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
    }
    -- Status dot (green/red blink)
    local StatusDot = Instance.new("Frame", HF)
    StatusDot.AnchorPoint = Vector2.new(1,0); StatusDot.Position = UDim2.new(1,-8,0,9)
    StatusDot.Size = UDim2.new(0,7,0,7); StatusDot.BackgroundColor3 = Color3.fromRGB(50,255,100)
    StatusDot.BackgroundTransparency = 0.1; StatusDot.BorderSizePixel = 0; StatusDot.ZIndex = 4
    Instance.new("UICorner", StatusDot).CornerRadius = UDim.new(1,0)
    task.spawn(function()
        while StatusDot.Parent do
            TweenService:Create(StatusDot, TweenInfo.new(0.6), {BackgroundTransparency=0.6}):Play()
            task.wait(0.7)
            TweenService:Create(StatusDot, TweenInfo.new(0.4), {BackgroundTransparency=0.05}):Play()
            task.wait(0.5)
        end
    end)

    -- Divider
    local HDivider = Instance.new("Frame", HF)
    HDivider.Size = UDim2.new(1,-14,0,1); HDivider.Position = UDim2.new(0,7,0,28)
    HDivider.BackgroundColor3 = Color3.fromRGB(60,15,130); HDivider.BorderSizePixel = 0; HDivider.ZIndex = 3

    -- Row factory: icon + key + value
    local function mkRow(icon, label, ypos, valCol)
        local row = Instance.new("Frame", HF)
        row.Size = UDim2.new(1,-12,0,20); row.Position = UDim2.new(0,6,0,ypos)
        row.BackgroundTransparency = 1; row.ZIndex = 4

        -- Icon chip
        local iconBG = Instance.new("Frame", row)
        iconBG.Size = UDim2.new(0,20,0,15); iconBG.Position = UDim2.new(0,0,0.5,-7)
        iconBG.BackgroundColor3 = Color3.fromRGB(12,4,28); iconBG.BackgroundTransparency = 0.3
        iconBG.BorderSizePixel = 0; iconBG.ZIndex = 4
        Instance.new("UICorner", iconBG).CornerRadius = UDim.new(0,4)
        local iLbl = Instance.new("TextLabel", iconBG)
        iLbl.Size = UDim2.new(1,0,1,0); iLbl.BackgroundTransparency = 1
        iLbl.Text = icon; iLbl.Font = Enum.Font.GothamBold; iLbl.TextSize = 9; iLbl.ZIndex = 5
        iLbl.TextColor3 = Color3.fromRGB(180,80,255)

        -- Key label
        local kLbl = Instance.new("TextLabel", row)
        kLbl.Position = UDim2.new(0,24,0,0); kLbl.Size = UDim2.new(0,48,1,0)
        kLbl.BackgroundTransparency = 1; kLbl.Text = label
        kLbl.Font = Enum.Font.Code; kLbl.TextSize = 9; kLbl.ZIndex = 4
        kLbl.TextColor3 = Color3.fromRGB(100,70,160); kLbl.TextXAlignment = Enum.TextXAlignment.Left

        -- Value label (right-aligned)
        local vLbl = Instance.new("TextLabel", row)
        vLbl.Position = UDim2.new(0,72,0,0); vLbl.Size = UDim2.new(1,-74,1,0)
        vLbl.BackgroundTransparency = 1; vLbl.Text = "--"
        vLbl.Font = Enum.Font.GothamBold; vLbl.TextSize = 10; vLbl.ZIndex = 5
        vLbl.TextColor3 = valCol or Color3.fromRGB(210,200,235)
        vLbl.TextXAlignment = Enum.TextXAlignment.Right
        return vLbl
    end

    local HudPing  = mkRow("📶","PING",   33, Color3.fromRGB(0,220,255))
    local HudFPS   = mkRow("🖥","FPS",    55, Color3.fromRGB(80,255,150))
    local HudParry = mkRow("⚔","HIT%",   77, Color3.fromRGB(255,180,0))
    local HudMode  = mkRow("⚡","MODE",   99, Color3.fromRGB(140,100,200))

    -- Live parry arc meter (thin arc bar below rows)
    local ArcBG = Instance.new("Frame", HF)
    ArcBG.Position = UDim2.new(0.04,0,0,124); ArcBG.Size = UDim2.new(0.92,0,0,6)
    ArcBG.BackgroundColor3 = Color3.fromRGB(8,3,20); ArcBG.BackgroundTransparency = 0.1
    ArcBG.BorderSizePixel = 0; ArcBG.ZIndex = 4
    Instance.new("UICorner", ArcBG).CornerRadius = UDim.new(1,0)
    local ArcFill = Instance.new("Frame", ArcBG)
    ArcFill.Position = UDim2.new(0,0,0,0); ArcFill.Size = UDim2.new(0,0,1,0)
    ArcFill.BackgroundColor3 = Color3.fromRGB(80,255,150); ArcFill.BackgroundTransparency = 0
    ArcFill.BorderSizePixel = 0; ArcFill.ZIndex = 5
    Instance.new("UICorner", ArcFill).CornerRadius = UDim.new(1,0)
    local ArcGrad = Instance.new("UIGradient", ArcFill)
    ArcGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,30,100)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,0,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
    }
    -- Arc label
    local ArcLbl = Instance.new("TextLabel", HF)
    ArcLbl.Position = UDim2.new(0.04,0,0,132); ArcLbl.Size = UDim2.new(0.92,0,0,10)
    ArcLbl.BackgroundTransparency = 1; ArcLbl.Text = "PARRY ACCURACY"
    ArcLbl.Font = Enum.Font.Code; ArcLbl.TextSize = 7; ArcLbl.ZIndex = 4
    ArcLbl.TextColor3 = Color3.fromRGB(80,60,120); ArcLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- Arc shimmer
    local ArcShim = Instance.new("Frame", ArcFill)
    ArcShim.Size = UDim2.new(0,30,1,0); ArcShim.BackgroundColor3 = Color3.fromRGB(255,255,255)
    ArcShim.BackgroundTransparency = 0.45; ArcShim.BorderSizePixel = 0; ArcShim.ZIndex = 6
    Instance.new("UICorner", ArcShim).CornerRadius = UDim.new(1,0)
    task.spawn(function()
        while ArcShim.Parent do
            ArcShim.Position = UDim2.new(-0.3,0,0,0)
            TweenService:Create(ArcShim, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {Position=UDim2.new(1.2,0,0,0)}):Play()
            task.wait(1.8)
        end
    end)

    -- Expose to global update system
    _G.RyuuHudMode  = HudMode
    _G.RyuuHudParry = HudParry
    _G.RyuuHudPing  = HudPing
    _G.RyuuHudFPS   = HudFPS
    _G.RyuuArcFill  = ArcFill
    _G.RyuuArcLbl   = ArcLbl
end

-- ══════════════════════════════════════════════════════════════════
-- LOBBY BADGE
-- ══════════════════════════════════════════════════════════════════
local LobbyBadgeSG = nil
local function BuildLobbyBadge(visible)
    if LobbyBadgeSG then pcall(function() LobbyBadgeSG:Destroy() end); LobbyBadgeSG = nil end
    if not visible then return end
    LobbyBadgeSG = Instance.new("ScreenGui")
    LobbyBadgeSG.Name = "RyuuLobbyBadge"; LobbyBadgeSG.ResetOnSpawn = false
    LobbyBadgeSG.IgnoreGuiInset = true; LobbyBadgeSG.DisplayOrder = 9997
    pcall(function() LobbyBadgeSG.Parent = (typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not LobbyBadgeSG.Parent then pcall(function() LobbyBadgeSG.Parent = Plr:WaitForChild("PlayerGui") end) end

    local BadgeFrame = Instance.new("Frame", LobbyBadgeSG)
    BadgeFrame.AnchorPoint = Vector2.new(0.5,0); BadgeFrame.Position = UDim2.new(0.5,0,0,14)
    BadgeFrame.Size = UDim2.new(0,240,0,36); BadgeFrame.BackgroundColor3 = Color3.fromRGB(3,12,6)
    BadgeFrame.BackgroundTransparency = 0.08; BadgeFrame.BorderSizePixel = 0
    Instance.new("UICorner", BadgeFrame).CornerRadius = UDim.new(0,12)
    local BStroke = Instance.new("UIStroke", BadgeFrame)
    BStroke.Thickness = 1.8; BStroke.Color = Color3.fromRGB(35,220,100); BStroke.Transparency = 0.1

    -- Accent line
    local BAccent = Instance.new("Frame", BadgeFrame)
    BAccent.Size = UDim2.new(1,0,0,2); BAccent.Position = UDim2.new(0,0,0,0)
    BAccent.BorderSizePixel = 0; BAccent.ZIndex = 2
    Instance.new("UICorner", BAccent).CornerRadius = UDim.new(0,12)
    local BAGrad = Instance.new("UIGradient", BAccent)
    BAGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,80)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80,255,160)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,80)),
    }

    local BLbl = Instance.new("TextLabel", BadgeFrame)
    BLbl.Size = UDim2.new(1,-12,1,0); BLbl.Position = UDim2.new(0,12,0,0)
    BLbl.BackgroundTransparency = 1; BLbl.Text = "🏟  LOBBY PARRY  —  ACTIVE"
    BLbl.Font = Enum.Font.GothamBlack; BLbl.TextSize = 11; BLbl.ZIndex = 2
    BLbl.TextXAlignment = Enum.TextXAlignment.Left
    local BLGrad = Instance.new("UIGradient", BLbl)
    BLGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(80,255,140)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,255,220)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(80,255,140)),
    }

    -- Animated stroke pulse
    task.spawn(function()
        local t = 0
        while BadgeFrame.Parent do
            t = t + 0.04
            local pulse = math.abs(math.sin(t))
            pcall(function()
                BStroke.Color = Color3.fromRGB(
                    math.floor(30 + pulse*20),
                    math.floor(200 + pulse*55),
                    math.floor(80 + pulse*60))
                BStroke.Transparency = 0.05 + pulse * 0.3
            end)
            task.wait(0.05)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════════════════════
local S = {
    AutoParry    = false,
    LobbyParry   = false,
    AutoFace     = false,
    BallESP      = false,
    AbilityESP   = false,
    Fullbright   = false,
    Noclip       = false,
    InfJump      = false,
    WalkSpeed    = 16,
    JumpPower    = 50,
    ParryCooldown= 0.30,
    EmergencyParry = true,
    ParryAccuracy  = 100,
    ParryReset     = 0.16,
    EarlyOffset    = 0,
}

local P = {
    AutoParry       = false,
    LobbyParry      = false,
    GodEmergency    = false,
    AutoFace        = false,
    HitboxTarget    = 4.0,
    EarlyOffset     = 0,
}

local PremiumUnlocked = true
local PremiumActive   = false
local PremAccuracy    = 100

-- ── AUTO-RESTORE PREMIUM ─────────────────────────────────────────
task.defer(function()
    local saved = LoadPremiumData()
    if not saved or not saved.key then return end
    local result = ValidateKey(saved.key)
    if result ~= "ok" then return end

    PremiumUnlocked = true
    PremiumActive   = true

    if saved.AutoParry    then P.AutoParry    = ParseBool(saved.AutoParry)    end
    if saved.LobbyParry   then P.LobbyParry   = ParseBool(saved.LobbyParry)   end
    if saved.GodEmergency then P.GodEmergency = ParseBool(saved.GodEmergency) end
    if saved.AutoFace     then P.AutoFace     = ParseBool(saved.AutoFace)     end
    if saved.HitboxTarget then P.HitboxTarget = ParseNum(saved.HitboxTarget) or 4.0 end
    if saved.EarlyOffset  then P.EarlyOffset  = ParseNum(saved.EarlyOffset)  or 0   end

    if saved.ParrySound      then PF.ParrySound      = ParseBool(saved.ParrySound)      end
    if saved.AntiBlock       then PF.AntiBlock       = ParseBool(saved.AntiBlock)       end
    if saved.ComboTracker    then PF.ComboTracker    = ParseBool(saved.ComboTracker)    end
    if saved.AutoChat        then PF.AutoChat        = ParseBool(saved.AutoChat)        end
    if saved.TrajectoryESP   then PF.TrajectoryESP   = ParseBool(saved.TrajectoryESP)   end
    if saved.BallSpeedMeter  then PF.BallSpeedMeter  = ParseBool(saved.BallSpeedMeter)  end
    if saved.TimeToImpact    then PF.TimeToImpact    = ParseBool(saved.TimeToImpact)    end
    if saved.TargetAlert     then PF.TargetAlert     = ParseBool(saved.TargetAlert)     end
    if saved.DistESP         then PF.DistESP         = ParseBool(saved.DistESP)         end
    if saved.Chams           then PF.Chams           = ParseBool(saved.Chams)           end
    if saved.BallHighlight   then PF.BallHighlight   = ParseBool(saved.BallHighlight)   end
    if saved.RainbowTrail    then PF.RainbowTrail    = ParseBool(saved.RainbowTrail)    end
    if saved.AutoDodge       then PF.AutoDodge       = ParseBool(saved.AutoDodge)       end
    if saved.SpeedOnParry    then PF.SpeedOnParry    = ParseBool(saved.SpeedOnParry)    end
    if saved.SpeedOnParryAmt then PF.SpeedOnParryAmt = ParseNum(saved.SpeedOnParryAmt) or 40 end
    if saved.GhostMode       then PF.GhostMode       = ParseBool(saved.GhostMode)       end
    if saved.PremFPS         then PF.PremFPS         = ParseBool(saved.PremFPS)         end
    if saved.PremFPSCap      then PF.PremFPSCap      = ParseNum(saved.PremFPSCap) or 0  end
    if saved.KillTracker     then PF.KillTracker     = ParseBool(saved.KillTracker)     end
    if saved.PremWatermark   then PF.PremWatermark   = ParseBool(saved.PremWatermark)   end
    if saved.SafeZoneWarn    then PF.SafeZoneWarn    = ParseBool(saved.SafeZoneWarn)    end
    if saved.VelArrow        then PF.VelArrow        = ParseBool(saved.VelArrow)        end
    if saved.PremAccuracy    then PremAccuracy       = ParseNum(saved.PremAccuracy) or 100 end

    task.wait(3.0)
    if P.AutoParry   then StopEngine(); StartPremiumEngine() end
    if P.LobbyParry  then StartPremiumLobbyEngine() end
    if PF.AntiBlock  then StartAntiBlock() end
    if PF.AutoDodge  then StartAutoDodge() end
    if PF.PremFPS    then SetPremFPS(true, PF.PremFPSCap) end
    if PF.GhostMode  then ApplyGhost(true) end
    if PF.Chams      then ApplyChams(true) end
    if PF.KillTracker     then BuildKillWidget() end
    if PF.ComboTracker    then BuildComboWidget() end
    if PF.TrajectoryESP   then BuildTrajectoryESP() end
    if PF.BallSpeedMeter  then BuildSpeedMeter() end
    if PF.TimeToImpact    then BuildTTI() end
    if PF.TargetAlert     then BuildTargetAlert() end
    if PF.SafeZoneWarn    then BuildSafeZoneWarning() end
    if PF.PremWatermark   then BuildWatermark() end
    if PF.BallHighlight   then StartBallHighlight() end
    if PF.RainbowTrail    then StartRainbowTrail() end
    if PF.VelArrow        then VelArrowActive=true; BuildVelArrow() end

    Rayfield:Notify({
        Title   = "✨ Premium Auto-Restored",
        Content = "Saved key recognized — all settings loaded.",
        Duration = 5,
        Image   = 4483362458
    })
end)

-- ══════════════════════════════════════════════════════════════════
-- PING / SMOOTHED
-- ══════════════════════════════════════════════════════════════════
local PingMs      = 1
local PingRaw     = 0
local PingScale   = 1.0
local PingSamples = {}
local smoothedPing = 0.05

local smoothedPingSamples = {}
local function updateSmoothedPing()
    pcall(function()
        local raw = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        if not raw or raw <= 0 then return end
        table.insert(smoothedPingSamples, raw)
        if #smoothedPingSamples > 10 then table.remove(smoothedPingSamples, 1) end
        local sum = 0
        for _, v in ipairs(smoothedPingSamples) do sum = sum + v end
        local avg = sum / #smoothedPingSamples
        local jitter = 0
        for _, v in ipairs(smoothedPingSamples) do jitter = jitter + math.abs(v - avg) end
        jitter = jitter / #smoothedPingSamples
        smoothedPing = (avg + jitter * 0.4) / 1000
    end)
end

task.spawn(function()
    while true do
        local ok, raw = pcall(function()
            return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        if ok and type(raw) == "number" and raw > 0 then
            PingRaw = raw
            table.insert(PingSamples, raw)
            if #PingSamples > 12 then table.remove(PingSamples, 1) end
            local lowest = math.huge
            for _, v in ipairs(PingSamples) do if v < lowest then lowest = v end end
            PingMs = lowest
        end
        task.wait(0.5)
    end
end)

local fpsCount, fpsTimer = 0, 0
RunService.Heartbeat:Connect(function(dt)
    fpsCount = fpsCount + 1
    fpsTimer = fpsTimer + dt
    if fpsTimer >= 0.5 then
        local fps = math.floor(fpsCount / fpsTimer)
        fpsCount = 0; fpsTimer = 0
        local col = fps >= 55 and Color3.fromRGB(34,197,110)
                 or fps >= 30 and Color3.fromRGB(255,200,50)
                 or Color3.fromRGB(255,80,80)
        pcall(function()
            _G.RyuuHudFPS.Text = ("%d fps"):format(fps)
            _G.RyuuHudFPS.TextColor3 = col
        end)
        -- Arc meter update on each fps tick
        pcall(function()
            local rate = (ParryStats and ParryStats.total > 0)
                and math.clamp(ParryStats.hits / ParryStats.total, 0, 1)
                or 0
            if _G.RyuuArcFill then
                TweenService:Create(_G.RyuuArcFill, TweenInfo.new(0.5, Enum.EasingStyle.Quad),
                    {Size=UDim2.new(math.max(0.03, rate), 0, 1, 0)}):Play()
            end
            if _G.RyuuArcLbl then
                _G.RyuuArcLbl.Text = ("PARRY ACC  %d%%"):format(math.floor(rate*100))
            end
        end)
    end
    pcall(function()
        local ms  = math.floor(PingRaw > 0 and PingRaw or PingMs)
        local col = ms < 60  and Color3.fromRGB(34,197,110)
                 or ms < 120 and Color3.fromRGB(255,200,50)
                 or Color3.fromRGB(255,80,80)
        _G.RyuuHudPing.Text = ("%d ms"):format(ms)
        _G.RyuuHudPing.TextColor3 = col
    end)
end)

-- ══════════════════════════════════════════════════════════════════
-- BALL / PLAYER HELPERS
-- ══════════════════════════════════════════════════════════════════
local function GetBall()
    local folder = workspace:FindFirstChild("Balls")
    if folder then
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("BasePart") and v:GetAttribute("realBall") then return v end
        end
        for _, v in ipairs(folder:GetChildren()) do
            if v:IsA("BasePart") then return v end
        end
    end
    for _, v in ipairs(workspace:GetChildren()) do
        if v:IsA("BasePart") and v.Name:lower():find("ball") then return v end
    end
    return nil
end

local function GetHRP()
    local c = Plr.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetVel(ball)
    local best = Vector3.zero
    local ok, v = pcall(function() return ball.AssemblyLinearVelocity end)
    if ok and v.Magnitude > best.Magnitude then best = v end
    pcall(function()
        for _, d in ipairs(ball:GetChildren()) do
            if (d:IsA("BodyVelocity") or d:IsA("LinearVelocity")) then
                if d.VectorVelocity.Magnitude > best.Magnitude then best = d.VectorVelocity end
            end
        end
    end)
    return best
end

-- ══════════════════════════════════════════════════════════════════
-- PARRY STATS
-- ══════════════════════════════════════════════════════════════════
local ParryStats = { total=0, hits=0, lastFireTime=0 }
local function ParrySuccessRate()
    if ParryStats.total == 0 then return 100 end
    return math.floor((ParryStats.hits / ParryStats.total) * 100)
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        local rate = ParrySuccessRate()
        local col  = rate >= 80 and Color3.fromRGB(34,197,110)
                  or rate >= 50 and Color3.fromRGB(255,200,50)
                  or Color3.fromRGB(255,80,80)
        _G.RyuuHudParry.Text = ("⚔ Hit Rate — %d%%"):format(rate)
        _G.RyuuHudParry.TextColor3 = col
    end)
end)

-- ══════════════════════════════════════════════════════════════════
-- SHARED MATH HELPERS
-- ══════════════════════════════════════════════════════════════════
local function LSQClosingRate(history)
    local n = #history
    if n < 4 then return 0 end
    local sx,sy,sxy,sxx,sw = 0,0,0,0,0
    local t0 = history[1].t
    for i = 1, n do
        local p = history[i]
        local w = math.exp((i - n) * 0.40)
        local x = p.t - t0
        sx=sx+w*x; sy=sy+w*p.d; sxy=sxy+w*x*p.d; sxx=sxx+w*x*x; sw=sw+w
    end
    local denom = sw*sxx - sx*sx
    if math.abs(denom) < 1e-7 then return 0 end
    return -(sw*sxy - sx*sy) / denom
end

local function AvgAccel(spdHistory, n)
    n = n or 5
    local count = #spdHistory
    if count < n+1 then return 0 end
    local sum, cnt = 0, 0
    for i = count-n, count-1 do
        local dt = spdHistory[i+1].t - spdHistory[i].t
        if dt > 0.001 then
            sum = sum + (spdHistory[i+1].s - spdHistory[i].s) / dt
            cnt = cnt + 1
        end
    end
    return cnt > 0 and sum/cnt or 0
end

local function CurveRate(velHistory, n)
    n = n or 4
    local count = #velHistory
    if count < n+1 then return 0 end
    local ang, tm = 0, 0
    for i = count-n, count do
        local a = velHistory[i-1]; local b = velHistory[i]
        if a and b and a.v.Magnitude > 1 and b.v.Magnitude > 1 then
            local dot = math.clamp(a.v:Dot(b.v)/(a.v.Magnitude*b.v.Magnitude),-1,1)
            local dt  = b.t - a.t
            if dt > 0.001 then ang=ang+math.deg(math.acos(dot)); tm=tm+dt end
        end
    end
    return tm > 0 and ang/tm or 0
end

local function SpikeMul(spdHistory)
    local n = #spdHistory
    if n < 5 then return 1.0 end
    local cur   = spdHistory[n].s
    local prev3 = spdHistory[n-3] and spdHistory[n-3].s or 1
    local ratio = cur / math.max(prev3, 1)
    if     ratio > 2.0  then return 1.55
    elseif ratio > 1.7  then return 1.40
    elseif ratio > 1.45 then return 1.28
    elseif ratio > 1.18 then return 1.12
    end
    return 1.0
end

-- ══════════════════════════════════════════════════════════════════
-- VISUAL: PARRY TIMING INDICATOR
-- ══════════════════════════════════════════════════════════════════
local ParryIndicatorGui = nil
local ParryIndicatorBar = nil
local ParryIndicatorLbl = nil

local function BuildParryIndicator()
    if ParryIndicatorGui then pcall(function() ParryIndicatorGui:Destroy() end) end
    local sg = Instance.new("ScreenGui")
    sg.Name = "RyuuParryInd"; sg.ResetOnSpawn = false; sg.IgnoreGuiInset = true; sg.DisplayOrder = 9996
    pcall(function() sg.Parent = (typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not sg.Parent then pcall(function() sg.Parent = Plr:WaitForChild("PlayerGui") end) end
    ParryIndicatorGui = sg

    local Container = Instance.new("Frame", sg)
    Container.AnchorPoint = Vector2.new(0.5,1); Container.Position = UDim2.new(0.5,0,1,-18)
    Container.Size = UDim2.new(0,220,0,36); Container.BackgroundColor3 = Color3.fromRGB(5,3,12)
    Container.BackgroundTransparency = 0.2; Container.BorderSizePixel = 0
    Instance.new("UICorner", Container).CornerRadius = UDim.new(0,10)
    local CStroke = Instance.new("UIStroke", Container)
    CStroke.Thickness = 1.2; CStroke.Color = Color3.fromRGB(60,25,120); CStroke.Transparency = 0.3

    local Lbl = Instance.new("TextLabel", Container)
    Lbl.Size = UDim2.new(1,-8,0,14); Lbl.Position = UDim2.new(0,6,0,3)
    Lbl.BackgroundTransparency = 1; Lbl.Text = "PARRY TIMING"
    Lbl.Font = Enum.Font.GothamBold; Lbl.TextSize = 9
    Lbl.TextColor3 = Color3.fromRGB(100,60,200); Lbl.TextXAlignment = Enum.TextXAlignment.Left
    ParryIndicatorLbl = Lbl

    local BarBG = Instance.new("Frame", Container)
    BarBG.Size = UDim2.new(1,-12,0,8); BarBG.Position = UDim2.new(0,6,0,20)
    BarBG.BackgroundColor3 = Color3.fromRGB(15,8,35); BarBG.BorderSizePixel = 0
    Instance.new("UICorner", BarBG).CornerRadius = UDim.new(1,0)

    local Fill = Instance.new("Frame", BarBG)
    Fill.Size = UDim2.new(0,0,1,0); Fill.BackgroundColor3 = Color3.fromRGB(130,50,255)
    Fill.BorderSizePixel = 0; Fill.ZIndex = 2
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)
    ParryIndicatorBar = Fill
end

local function UpdateParryIndicator(dist, fireDist, didJustFire)
    if not ParryIndicatorBar then return end
    pcall(function()
        local ratio = math.clamp(1-(dist-fireDist)/math.max(fireDist,1),0,1)
        local col   = ratio > 0.85 and Color3.fromRGB(50,255,120)
                   or ratio > 0.55 and Color3.fromRGB(255,200,50)
                   or Color3.fromRGB(130,50,255)
        TweenService:Create(ParryIndicatorBar,
            TweenInfo.new(0.06), {Size=UDim2.new(ratio,0,1,0), BackgroundColor3=col}):Play()
        if didJustFire and ParryIndicatorLbl then
            ParryIndicatorLbl.Text = "✓ FIRED — " .. ParrySuccessRate() .. "% hit"
            ParryIndicatorLbl.TextColor3 = Color3.fromRGB(50,220,110)
            task.delay(0.6, function()
                pcall(function()
                    ParryIndicatorLbl.Text = "PARRY TIMING"
                    ParryIndicatorLbl.TextColor3 = Color3.fromRGB(100,60,200)
                end)
            end)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- PREMIUM FEATURES STATE
-- ══════════════════════════════════════════════════════════════════
local PF = {
    ParrySound      = false,
    AntiBlock       = false,
    TimingRandom    = false,
    ComboTracker    = false,
    ComboCount      = 0,
    ComboLastParry  = 0,
    AutoChat        = false,
    TrajectoryESP   = false,
    BallSpeedMeter  = false,
    TimeToImpact    = false,
    TargetAlert     = false,
    DistESP         = false,
    Chams           = false,
    BallHighlight   = false,
    RainbowTrail    = false,
    AutoDodge       = false,
    SpeedOnParry    = false,
    SpeedOnParryAmt = 40,
    GhostMode       = false,
    PremFPS         = false,
    PremFPSCap      = 0,
    KillTracker     = false,
    KillCount       = 0,
    PremWatermark   = false,
    SafeZoneWarn    = false,
    VelArrow        = false,
}

local AUTO_CHAT_MSGS = {
    "nice try 😏","too slow ⚡","skill issue 💯","not even close 🎯","L + ratio 😴",
}
local AutoChatIdx      = 1
local AutoChatLastTime = 0

local function DoAutoChat()
    if not PF.AutoChat or not PremiumUnlocked then return end
    local now = os.clock()
    if now - AutoChatLastTime < 3 then return end
    AutoChatLastTime = now
    local msg = AUTO_CHAT_MSGS[AutoChatIdx]
    AutoChatIdx = (AutoChatIdx % #AUTO_CHAT_MSGS) + 1
    pcall(function()
        game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents")
            :FindFirstChild("SayMessageRequest"):FireServer(msg, "All")
    end)
end

local GUI = {
    Kill=nil, KillLbl=nil, Traj=nil, Dist={}, Chams={},
    TTI=nil, SpeedMeter=nil, Alert=nil, SafeZone=nil,
    Watermark=nil, Combo=nil, ComboFrame=nil, ComboLbl=nil,
}

local function IncrementKill()
    if not PF.KillTracker or not PremiumUnlocked then return end
    PF.KillCount = PF.KillCount + 1
    pcall(function() if GUI.KillLbl then GUI.KillLbl.Text = tostring(PF.KillCount) end end)
end

local function UpdateCombo(scored)
    if not PF.ComboTracker or not PremiumUnlocked then return end
    if not GUI.ComboFrame then return end
    local now = os.clock()
    if scored then
        if now - PF.ComboLastParry < 5 then PF.ComboCount = PF.ComboCount+1 else PF.ComboCount = 1 end
        PF.ComboLastParry = now
        pcall(function()
            GUI.ComboLbl.Text = PF.ComboCount .. "×"
            local hue = math.clamp(PF.ComboCount/25,0,1)
            GUI.ComboLbl.TextColor3 = Color3.fromHSV(0.56-hue*0.22,1,1)
        end)
    end
end

local function ApplySpeedBoost()
    if not PF.SpeedOnParry or not PremiumUnlocked then return end
    local char = Plr.Character; if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
    hum.WalkSpeed = PF.SpeedOnParryAmt
    task.delay(0.8, function()
        pcall(function() if hum and hum.Parent then hum.WalkSpeed = S.WalkSpeed end end)
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- FIRE FUNCTIONS
-- ══════════════════════════════════════════════════════════════════
local FireState = {
    didParry  = false,
    lastFire  = 0,
    resetConn = nil,
}

-- FIX: ArmReset now uses a time-based rearm that is ALWAYS reliable.
-- After the lockout window expires, didParry is reset unconditionally.
-- This prevents the "dies after several parries" bug where didParry
-- got stuck true permanently.
local function ArmReset()
    if FireState.resetConn then task.cancel(FireState.resetConn) end
    local resetDelay = math.max(0.20, S.ParryReset or 0.20)
    FireState.resetConn = task.delay(resetDelay, function()
        FireState.didParry  = false
        FireState.resetConn = nil
    end)
end

local _lastRawFire = 0
local function RawFire()
    local now = os.clock()
    if now - _lastRawFire < 0.05 then return end  -- hard 50ms global gate
    _lastRawFire = now
    pcall(function()
        VIM:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
        VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
end

local function FireParryRemotes() end

function FireParry(ball)
    local now = os.clock()
    if FireState.didParry then return end
    if now - FireState.lastFire < 0.075 then return end

    local acc = math.clamp(S.ParryAccuracy or 100, 1, 100)
    if acc < 100 then
        local jitter = ((100 - acc) / 100) * 0.045
        if jitter > 0.003 then task.wait(jitter * (math.random() * 0.6 + 0.2)) end
    end

    FireState.didParry = true
    FireState.lastFire = now
    ParryStats.total   = ParryStats.total + 1
    ParryStats.lastFireTime = now

    RawFire()
    FireParryRemotes()
    ArmReset()
    pcall(DoAutoChat); pcall(UpdateCombo, true); pcall(ApplySpeedBoost); pcall(IncrementKill)
    if PF.ParrySound then
        pcall(function()
            local s = Instance.new("Sound", workspace)
            s.SoundId = "rbxassetid://3744371342"
            s.Volume = 0.7; s.PlaybackSpeed = 1.1 + math.random() * 0.1; s:Play()
            game:GetService("Debris"):AddItem(s, 2)
        end)
    end
end

function LobbyFireParry()
    local now = os.clock()
    if FireState.didParry then return end
    if now - FireState.lastFire < 0.075 then return end
    FireState.didParry = true; FireState.lastFire = now
    RawFire(); FireParryRemotes(); ArmReset()
end

-- ══════════════════════════════════════════════════════════════════
-- PREMIUM FIRE STATE
-- ══════════════════════════════════════════════════════════════════
local PremFire = { didParry=false, lastParry=0, resetConn=nil }

-- FIX: Premium rearm — same reliable time-based approach.
-- After lockout window, didParry resets unconditionally regardless
-- of ball position. This is the core fix for premium dying mid-match.
local function ArmPremReset()
    if PremFire.resetConn then task.cancel(PremFire.resetConn) end
    local resetDelay = math.max(0.20, S.ParryReset or 0.20)
    PremFire.resetConn = task.delay(resetDelay, function()
        PremFire.didParry  = false
        PremFire.resetConn = nil
    end)
end

function PremiumFire(ball)
    local now = os.clock()
    if PremFire.didParry then return end
    if now - PremFire.lastParry < 0.20 then return end

    local acc = math.clamp(PremAccuracy or 100, 1, 150)
    if acc < 100 then
        local jitter = ((100 - acc) / 100) * 0.030
        if jitter > 0.002 then task.wait(jitter * (math.random() * 0.5 + 0.1)) end
    end

    PremFire.didParry  = true
    PremFire.lastParry = now
    ParryStats.total   = ParryStats.total + 1
    ParryStats.lastFireTime = now

    RawFire()
    FireParryRemotes()
    ArmPremReset()
    pcall(DoAutoChat); pcall(UpdateCombo, true); pcall(ApplySpeedBoost); pcall(IncrementKill)
    if PF.ParrySound then
        pcall(function()
            local s = Instance.new("Sound", workspace)
            s.SoundId = "rbxassetid://3744371342"
            s.Volume = 0.8; s.PlaybackSpeed = 1.2; s:Play()
            game:GetService("Debris"):AddItem(s, 2)
        end)
    end
end

function PremLobbyFire()
    local now = os.clock()
    if PremFire.didParry then return end
    if now - PremFire.lastParry < 0.20 then return end
    PremFire.didParry = true; PremFire.lastParry = now
    RawFire(); FireParryRemotes(); ArmPremReset()
end

-- ══════════════════════════════════════════════════════════════════
-- CLASH / DUEL DETECTOR
-- ══════════════════════════════════════════════════════════════════
local ClashState = {
    active       = false,
    enemyPlr     = nil,
    lastDetect   = 0,
    RANGE        = 22,
    FACING_DOT   = 0.55,
    COOLDOWN     = 0.18,
    lastClashFire= 0,
}

local function DetectClash()
    local hrp = GetHRP(); if not hrp then return false end
    local myFwd = hrp.CFrame.LookVector
    local best, bestScore = nil, 0

    for _, p in ipairs(Players:GetPlayers()) do
        if p == Plr then continue end
        local char = p.Character; if not char then continue end
        local ehr  = char:FindFirstChild("HumanoidRootPart"); if not ehr then continue end
        local dist = (hrp.Position - ehr.Position).Magnitude
        if dist > ClashState.RANGE then continue end

        local toMe   = (hrp.Position - ehr.Position).Unit
        local eFwd   = ehr.CFrame.LookVector
        local facingDot = eFwd:Dot(toMe)

        local toThem = (ehr.Position - hrp.Position).Unit
        local myDot  = myFwd:Dot(toThem)

        local score = facingDot * myDot * (1 / math.max(dist, 1))
        if facingDot > ClashState.FACING_DOT and myDot > ClashState.FACING_DOT and score > bestScore then
            bestScore = score
            best = p
        end
    end

    if best then
        ClashState.enemyPlr = best
        return true
    end
    ClashState.enemyPlr = nil
    return false
end

-- ══════════════════════════════════════════════════════════════════
-- FREE GAME ENGINE — FIXED
-- FIXES:
-- 1. resetFree() no longer clears didParry — ArmReset owns that.
--    This prevents "dies after several parries" where resetting
--    didParry during the lockout window would let the engine
--    double-fire then get confused.
-- 2. Early-fire lookahead of ~0.5s: engine now checks if ball will
--    be in fire range within 30 frames (0.5s @ 60fps) and fires
--    early if so. This makes parries feel proactive, not reactive.
-- 3. History max increased to 25 for better long-range prediction.
-- ══════════════════════════════════════════════════════════════════
local FreeConn = {}
local FreeH    = { pos={}, spd={}, vel={} }
local FREE_MAX = 25  -- increased for better long-range data

local function resetFreeHistory()
    -- ONLY clears history, never touches FireState.didParry
    -- ArmReset() owns didParry — touching it here caused the "dies" bug
    FreeH = { pos={}, spd={}, vel={} }
end

local function resetFree()
    -- Full reset: only called when ball stops targeting us
    -- Still safe to clear didParry here because ball is no longer ours
    FreeH = { pos={}, spd={}, vel={} }
    if FireState.resetConn == nil then
        -- Only clear if lockout already expired (no pending rearm)
        FireState.didParry = false
    end
end

local function pushFree(dist, vel, t)
    local spd = vel.Magnitude
    local function push(tbl, val)
        table.insert(tbl, val)
        if #tbl > FREE_MAX then table.remove(tbl, 1) end
    end
    push(FreeH.pos, {d=dist, t=t})
    push(FreeH.spd, {s=spd,  t=t})
    push(FreeH.vel, {v=vel,  t=t})
end

local function freeFireDist(speed, closing, pingC, curve, accel)
    local base = 9.8 + pingC + (S.EarlyOffset or 0)

    if     speed > 280 then base = base + (speed-280)*0.048
    elseif speed > 200 then base = base + (speed-200)*0.035
    elseif speed > 130 then base = base + (speed-130)*0.022
    elseif speed >  70 then base = base + (speed- 70)*0.012 end

    if     closing > 70 then base = base + (closing-70)*0.075
    elseif closing > 35 then base = base + (closing-35)*0.040 end

    if curve > 8  then base = base + math.min((curve-8)*0.065, 5.0) end
    if accel > 40 then base = base + math.min((accel-40)*0.012, 2.5) end

    local cap = 14.5 + pingC
    return math.min(base, cap)
end

local function RecentClosingRate(posHistory)
    local n = #posHistory
    if n < 3 then return 0 end
    local start = math.max(1, n-5)
    local sub   = {}
    for i = start, n do sub[#sub+1] = posHistory[i] end
    return LSQClosingRate(sub)
end

local function BezierPredict(velHistory, ballPos, steps)
    local n = #velHistory
    if n < 3 then return nil end
    local v2 = velHistory[n].v
    local v1 = velHistory[n-1].v
    local dt  = 1/60
    local p0  = ballPos - v2*dt*2
    local p1  = ballPos - v2*dt
    local p2  = ballPos

    local results = {}
    for step = 1, steps do
        local t = step / steps
        local bx = (1-t)^2*p0.X + 2*(1-t)*t*p1.X + t^2*p2.X
        local by = (1-t)^2*p0.Y + 2*(1-t)*t*p1.Y + t^2*p2.Y
        local bz = (1-t)^2*p0.Z + 2*(1-t)*t*p1.Z + t^2*p2.Z
        results[step] = Vector3.new(bx, by, bz)
    end
    return results
end

local function StartFreeGameEngine()
    if FreeConn.main then FreeConn.main:Disconnect() end
    resetFreeHistory(); BuildParryIndicator()

    FreeConn.main = RunService.PreSimulation:Connect(function()
        if not S.AutoParry then return end
        pcall(updateSmoothedPing)

        local ball = GetBall()
        if not ball then resetFreeHistory(); return end
        local hrp = GetHRP(); if not hrp then return end

        local tgt   = ball:GetAttribute("target") or ""
        local isTgt = tgt == Plr.Name

        if isTgt and S.AutoFace then
            pcall(function()
                hrp.CFrame = CFrame.lookAt(hrp.Position,
                    Vector3.new(ball.Position.X, hrp.Position.Y, ball.Position.Z))
            end)
        end

        if not isTgt then resetFree(); UpdateParryIndicator(99,1,false); return end

        local ballPos = ball.Position
        local dist    = (hrp.Position - ballPos).Magnitude
        local vel     = GetVel(ball)
        local now     = os.clock()
        pushFree(dist, vel, now)

        local inClash = false
        if #FreeH.pos >= 4 then
            inClash = DetectClash()
        end

        if inClash and not FireState.didParry and
           now - ClashState.lastClashFire > ClashState.COOLDOWN then
            local closing = RecentClosingRate(FreeH.pos)
            local clashFireD = 12.0 + smoothedPing * 120
            if dist <= clashFireD then
                ClashState.lastClashFire = now
                FireParry(ball)
                resetFreeHistory()
                UpdateParryIndicator(dist, clashFireD, true)
                return
            end
        end

        local emDist = 7.5 + smoothedPing * 120
        if S.EmergencyParry and not FireState.didParry and dist <= emDist then
            FireParry(ball); resetFreeHistory(); UpdateParryIndicator(dist,dist,true); return
        end
        if not FireState.didParry and dist <= 5.5 + smoothedPing * 100 then
            FireParry(ball); resetFreeHistory(); UpdateParryIndicator(dist,dist,true); return
        end

        if FireState.didParry then return end
        if now - FireState.lastFire < 0.075 then return end

        local speed   = vel.Magnitude
        local closing = RecentClosingRate(FreeH.pos)
        local accel   = AvgAccel(FreeH.spd, 5)
        local curve   = CurveRate(FreeH.vel, 4)
        local spike   = SpikeMul(FreeH.spd)
        local proj    = (speed + math.max(0, accel) * 0.030) * spike
        local pingC   = smoothedPing * proj * 1.35
        if smoothedPing > 0.12 then pingC = pingC * 1.15 end

        local fireD = freeFireDist(proj, closing, pingC, curve, accel)
        UpdateParryIndicator(dist, fireD, false)

        -- Direct distance check
        if dist <= fireD then
            FireParry(ball); resetFreeHistory(); UpdateParryIndicator(dist,fireD,true); return
        end

        -- EARLY-FIRE LOOKAHEAD ~0.5s (30 frames @ 60fps)
        -- Fires the moment the predicted distance FIRST crosses fireD.
        -- NO accumulating tolerance — a flat 0.5 stud buffer only.
        -- The extra `if FireState.didParry then return end` before this
        -- block means only ONE path can ever fire per engine tick.
        if closing > 5 and speed > 20 and not FireState.didParry then
            local LOOKAHEAD_FRAMES = 30
            for step = 1, LOOKAHEAD_FRAMES do
                local dt    = step / 60
                local pDist = dist - closing*dt - 0.5*math.max(0,accel)*dt*dt
                if pDist <= fireD + 0.5 then
                    -- Only fire if we haven't already locked this frame
                    if not FireState.didParry then
                        FireParry(ball); resetFreeHistory(); UpdateParryIndicator(dist,fireD,true)
                    end
                    return
                end
            end
        end

        -- Curve lookahead — only if ball not already predicted above
        if curve > 6 and #FreeH.vel >= 4 and not FireState.didParry then
            local predicted = BezierPredict(FreeH.vel, ballPos, 5)
            if predicted then
                for _, pPos in ipairs(predicted) do
                    if (hrp.Position - pPos).Magnitude <= fireD + 0.5 then
                        if not FireState.didParry then
                            FireParry(ball); resetFreeHistory(); UpdateParryIndicator(dist,fireD,true)
                        end
                        return
                    end
                end
            end
        end
    end)
end

local function StopFreeGameEngine()
    if FreeConn.main then FreeConn.main:Disconnect(); FreeConn.main = nil end
    resetFreeHistory()
end

-- FREE LOBBY ENGINE
local FreeLobbyConn = {}
local function StartFreeLobbyEngine()
    if FreeLobbyConn.main then FreeLobbyConn.main:Disconnect() end
    BuildLobbyBadge(true)
    FreeLobbyConn.main = RunService.PreSimulation:Connect(function()
        if not S.LobbyParry then return end
        pcall(updateSmoothedPing)
        local ball = GetBall(); if not ball then return end
        local hrp  = GetHRP();  if not hrp  then return end
        if (ball:GetAttribute("target") or "") ~= Plr.Name then return end
        local dist  = (hrp.Position - ball.Position).Magnitude
        local vel   = GetVel(ball); local speed = vel.Magnitude
        local pingC = smoothedPing * speed * 1.40
        local fireD = 10.5 + pingC + (S.EarlyOffset or 0)
        local should = dist <= fireD
        if not should then
            for step = 1, 3 do
                local future = ball.Position + vel * (step/60)
                if (hrp.Position - future).Magnitude <= fireD then should=true; break end
            end
        end
        if should then LobbyFireParry() end
    end)
end

local function StopFreeLobbyEngine()
    if FreeLobbyConn.main then FreeLobbyConn.main:Disconnect(); FreeLobbyConn.main = nil end
    BuildLobbyBadge(false)
end

-- ══════════════════════════════════════════════════════════════════
-- PREMIUM GAME ENGINE — FIXED
-- ══════════════════════════════════════════════════════════════════
--
-- FIX 1 — PREMIUM DIES AFTER SEVERAL PARRIES:
--   Root cause: Old engine had a dual-path rearm: timer-based AND
--   distance-based. The distance check (ball moves 4+ studs away)
--   would sometimes never trigger in tight melee exchanges, leaving
--   PremFire.didParry = true forever. Additionally if resetPrem()
--   was called (from ball target change) while a resetConn was still
--   pending, the pending conn would later set didParry=false at an
--   unexpected time creating race conditions.
--   Fix: ArmPremReset() is now the SOLE authority on resetting
--   didParry. It always fires after the lockout window expires.
--   Distance-based rearm is removed entirely — it was unreliable.
--   resetPrem() (target-change reset) now safely cancels any
--   pending conn AND clears didParry immediately since the ball
--   is no longer ours.
--
-- FIX 2 — EARLY FIRE ~0.5s BEFORE HITBOX:
--   Added a 30-frame kinematic lookahead. If the ball will be inside
--   fireD within 30 frames (0.5s), fire immediately. This gives the
--   player a 0.5s lead on the parry window.
--
-- FIX 3 — ABILITY DETECTOR TOO SENSITIVE:
--   Added strict ball-target-equals-Plr.Name check before any
--   ability detection fires. If the ball isn't targeting you,
--   no ability fire happens regardless of what the enemy is doing.
-- ══════════════════════════════════════════════════════════════════

local PremConn = {}
local PremH    = { pos={}, spd={}, vel={} }
local PREM_MAX = 28

local MIN_CLOSING_RATE = 6

local function resetPrem()
    -- Full reset: called when ball changes target to someone else
    -- Safe to cancel resetConn AND clear didParry because ball is no longer ours
    if PremFire.resetConn then
        task.cancel(PremFire.resetConn)
        PremFire.resetConn = nil
    end
    PremH = { pos={}, spd={}, vel={} }
    PremFire.didParry = false
end

local function resetPremHistory()
    -- History-only: called after firing, does NOT touch didParry or resetConn
    PremH = { pos={}, spd={}, vel={} }
end

local function pushPrem(dist, vel, t)
    local spd = vel.Magnitude
    local function push(tbl, val)
        table.insert(tbl, val)
        if #tbl > PREM_MAX then table.remove(tbl, 1) end
    end
    push(PremH.pos, {d=dist, t=t})
    push(PremH.spd, {s=spd,  t=t})
    push(PremH.vel, {v=vel,  t=t})
end

local function premFireDist(speed, closing, pingC, curve, accel)
    local htb  = P.HitboxTarget or 4.0
    local base = 7.5 + pingC + (P.EarlyOffset or 0)

    if base < htb + pingC then base = htb + pingC end

    if     speed > 290 then base = base + (speed-290)*0.052
    elseif speed > 220 then base = base + (speed-220)*0.038
    elseif speed > 155 then base = base + (speed-155)*0.025
    elseif speed > 100 then base = base + (speed-100)*0.013 end

    if     closing > 75 then base = base + (closing-75)*0.080
    elseif closing > 40 then base = base + (closing-40)*0.045 end

    if curve > 6  then base = base + math.min((curve-6)*0.070, 5.5) end
    if accel > 30 then base = base + math.min((accel-30)*0.015, 3.0) end

    local cap = htb + 11.0 + pingC
    return math.min(base, cap)
end

local function BallAimedAtMe(ballPos, vel, hrpPos, hrpCFrame, angleDeg)
    if vel.Magnitude < 5 then return true end
    local toBall = (hrpPos - ballPos)
    local forward = hrpCFrame.LookVector
    local toMeFromBall = toBall.Unit
    local inFront = forward:Dot(toMeFromBall) > -0.35
    if not inFront then return false end
    local dot = vel.Unit:Dot(toMeFromBall)
    return dot >= math.cos(math.rad(angleDeg))
end

local function DetectBallFlip(posHistory)
    local n = #posHistory
    if n < 4 then return false end
    local old3 = posHistory[n-3] and posHistory[n-3].d or 999
    local old2 = posHistory[n-2] and posHistory[n-2].d or 999
    local old1 = posHistory[n-1] and posHistory[n-1].d or 999
    local cur  = posHistory[n].d
    local wasIncreasing = old2 > old3
    local nowDecreasing = cur < old1 and cur < old2
    return wasIncreasing and nowDecreasing
end

local function BezierPredictPrem(velHistory, ballPos, steps)
    local n = #velHistory
    if n < 3 then return nil end
    local v2 = velHistory[n].v
    local v1 = velHistory[n-1].v
    local dt  = 1/60
    local p0  = ballPos - v1*dt
    local p1  = ballPos
    local p2  = ballPos + v2*dt*1.5
    local results = {}
    for step = 1, steps do
        local t = step / steps
        results[step] = Vector3.new(
            (1-t)^2*p0.X + 2*(1-t)*t*p1.X + t^2*p2.X,
            (1-t)^2*p0.Y + 2*(1-t)*t*p1.Y + t^2*p2.Y,
            (1-t)^2*p0.Z + 2*(1-t)*t*p1.Z + t^2*p2.Z
        )
    end
    return results
end

local function StartPremiumGameEngine()
    if PremConn.main then PremConn.main:Disconnect() end
    resetPrem(); BuildParryIndicator()

    PremConn.main = RunService.PreSimulation:Connect(function()
        if not P.AutoParry then return end
        pcall(updateSmoothedPing)

        local ball = GetBall()
        if not ball then resetPrem(); return end
        local hrp = GetHRP(); if not hrp then return end

        local tgt   = ball:GetAttribute("target") or ""
        local isTgt = tgt == Plr.Name

        if isTgt and P.AutoFace then
            pcall(function()
                hrp.CFrame = CFrame.lookAt(hrp.Position,
                    Vector3.new(ball.Position.X, hrp.Position.Y, ball.Position.Z))
            end)
        end

        if not isTgt then
            resetPrem()
            UpdateParryIndicator(99,1,false)
            return
        end

        local ballPos = ball.Position
        local dist    = (hrp.Position - ballPos).Magnitude
        local vel     = GetVel(ball)
        local now     = os.clock()
        pushPrem(dist, vel, now)

        -- FIX: No distance-based rearm. ArmPremReset() is the sole authority.
        -- We only need to detect if ball came back after going away far, which
        -- is handled by resetPrem() being called when isTgt flips to false.
        -- If ball stays targeted the whole time, ArmPremReset timer handles it.

        local speed   = vel.Magnitude
        local closing = RecentClosingRate(PremH.pos)
        local ballApproaching = closing > -5 or dist < 12

        local inClash = false
        if #PremH.pos >= 4 then
            local savedRange = ClashState.RANGE
            ClashState.RANGE = 28
            inClash = DetectClash()
            ClashState.RANGE = savedRange
        end

        if #PremH.pos >= 4 and not PremFire.didParry then
            if DetectBallFlip(PremH.pos) then
                local flipFireD = (P.HitboxTarget or 4.0) + 10.0 + smoothedPing * 130
                if dist <= flipFireD then
                    PremiumFire(ball); resetPremHistory()
                    UpdateParryIndicator(dist, flipFireD, true); return
                end
            end
        end

        if inClash and not PremFire.didParry and
           now - ClashState.lastClashFire > 0.10 then
            local clashFireD = (P.HitboxTarget or 4.0) + 10.0 + smoothedPing * 120
            if dist <= clashFireD then
                ClashState.lastClashFire = now
                PremiumFire(ball); resetPremHistory()
                UpdateParryIndicator(dist, clashFireD, true); return
            end
        end

        local emDist = 7.5 + smoothedPing * 120
        if P.GodEmergency and not PremFire.didParry and dist <= emDist then
            PremiumFire(ball); resetPremHistory(); UpdateParryIndicator(dist,dist,true); return
        end

        if not PremFire.didParry and dist <= 5.5 + smoothedPing * 100 then
            PremiumFire(ball); resetPremHistory(); UpdateParryIndicator(dist,dist,true); return
        end

        if PremFire.didParry then return end
        if now - PremFire.lastParry < 0.20 then return end

        if not ballApproaching and dist > 18 then
            UpdateParryIndicator(dist, 99, false)
            return
        end

        local accel   = AvgAccel(PremH.spd, 6)
        local curve   = CurveRate(PremH.vel, 5)
        local spike   = SpikeMul(PremH.spd)
        local proj    = (speed + math.max(0, accel) * 0.025) * spike
        local pingC   = smoothedPing * proj * 1.40
        if smoothedPing > 0.13 then pingC = pingC * 1.15 end

        local fireD = premFireDist(proj, closing, pingC, curve, accel)

        UpdateParryIndicator(dist, fireD, false)

        -- Direct distance check
        if dist <= fireD then
            PremiumFire(ball); resetPremHistory(); UpdateParryIndicator(dist,fireD,true); return
        end

        -- EARLY-FIRE LOOKAHEAD ~0.5s (30 frames @ 60fps)
        -- Fires as soon as predicted dist FIRST crosses fireD.
        -- Flat 0.5 stud buffer only — no accumulating tolerance per step.
        if closing > MIN_CLOSING_RATE and speed > 20 and not PremFire.didParry then
            local LOOKAHEAD_FRAMES = 30
            for step = 1, LOOKAHEAD_FRAMES do
                local dt    = step / 60
                local pDist = dist - closing*dt - 0.5*math.max(0,accel)*dt*dt
                if pDist <= fireD + 0.5 then
                    if not PremFire.didParry then
                        PremiumFire(ball); resetPremHistory(); UpdateParryIndicator(dist,fireD,true)
                    end
                    return
                end
            end
        end

        -- Curve lookahead (Bezier, 7 frames) — only if not already fired
        if curve > 5 and #PremH.vel >= 4 and not PremFire.didParry then
            local predicted = BezierPredictPrem(PremH.vel, ballPos, 7)
            if predicted then
                for _, pPos in ipairs(predicted) do
                    if (hrp.Position - pPos).Magnitude <= fireD + 0.5 then
                        local toP   = (pPos - hrp.Position)
                        local proj2 = hrp.CFrame.LookVector:Dot(toP.Unit)
                        if proj2 > -0.3 and not PremFire.didParry then
                            PremiumFire(ball); resetPremHistory(); UpdateParryIndicator(dist,fireD,true)
                        end
                        return
                    end
                end
            end
        end
    end)
end

local function StopPremiumGameEngine()
    if PremConn.main then PremConn.main:Disconnect(); PremConn.main = nil end
    resetPrem()
end

-- Respawn cleanup
Plr.CharacterAdded:Connect(function()
    task.wait(1.5)
    resetPrem()
    FireState.didParry = false
    FireState.lastFire = 0
    if FireState.resetConn then task.cancel(FireState.resetConn); FireState.resetConn = nil end
    if PremFire.resetConn then task.cancel(PremFire.resetConn); PremFire.resetConn = nil end
    if P.AutoParry and PremiumUnlocked then
        task.wait(0.5)
        StartPremiumGameEngine()
    elseif S.AutoParry then
        task.wait(0.5)
        StartFreeGameEngine()
    end
end)

-- PREMIUM LOBBY ENGINE
local PremLobbyConn = {}
local function StartPremiumLobbyEngine()
    if PremLobbyConn.main then PremLobbyConn.main:Disconnect() end
    BuildLobbyBadge(true)
    PremLobbyConn.main = RunService.PreSimulation:Connect(function()
        if not P.LobbyParry then return end
        pcall(updateSmoothedPing)
        local ball = GetBall(); if not ball then return end
        local hrp  = GetHRP();  if not hrp  then return end
        if (ball:GetAttribute("target") or "") ~= Plr.Name then return end
        local dist  = (hrp.Position - ball.Position).Magnitude
        local vel   = GetVel(ball); local speed = vel.Magnitude
        local pingC = smoothedPing * speed * 1.50
        local fireD = (P.HitboxTarget or 4.0) + pingC + (P.EarlyOffset or 0)
        local should = dist <= fireD
        if not should then
            for step = 1, 4 do
                local future = ball.Position + vel * (step/60)
                if (hrp.Position - future).Magnitude <= fireD then should=true; break end
            end
        end
        if should then PremLobbyFire() end
    end)
end

local function StopPremiumLobbyEngine()
    if PremLobbyConn.main then PremLobbyConn.main:Disconnect(); PremLobbyConn.main = nil end
    BuildLobbyBadge(false)
end

-- TOGGLE WRAPPERS
local function StartEngine()        StartFreeGameEngine()      end
local function StopEngine()         StopFreeGameEngine()       end
local function StartLobbyEngine()   StartFreeLobbyEngine()     end
local function StopLobbyEngine()    StopFreeLobbyEngine()      end
local function StartPremiumEngine() StartPremiumGameEngine()   end
local function StopPremiumEngine()  StopPremiumGameEngine()    end

-- ══════════════════════════════════════════════════════════════════
-- HUD MODE AUTO-UPDATER
-- ══════════════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    pcall(function()
        if not _G.RyuuHudMode then return end
        if P.AutoParry and PremiumUnlocked then
            _G.RyuuHudMode.Text="⚡ Mode — PREM PARRY"; _G.RyuuHudMode.TextColor3=Color3.fromRGB(200,100,255)
        elseif S.AutoParry then
            _G.RyuuHudMode.Text="⚔ Mode — AUTO PARRY"; _G.RyuuHudMode.TextColor3=Color3.fromRGB(50,220,110)
        elseif S.LobbyParry or P.LobbyParry then
            _G.RyuuHudMode.Text="🏟 Mode — LOBBY"; _G.RyuuHudMode.TextColor3=Color3.fromRGB(50,180,255)
        else
            _G.RyuuHudMode.Text="⚡ Mode — IDLE"; _G.RyuuHudMode.TextColor3=Color3.fromRGB(160,160,160)
        end
    end)
end)

-- ══════════════════════════════════════════════════════════════════
-- BALL VELOCITY ARROW ESP
-- ══════════════════════════════════════════════════════════════════
local VelArrowSG     = nil
local VelArrowActive = false

local function BuildVelArrow()
    if VelArrowSG then pcall(function() VelArrowSG:Destroy() end) end
    VelArrowSG = Instance.new("ScreenGui")
    VelArrowSG.Name="RyuuVelArrow"; VelArrowSG.ResetOnSpawn=false
    VelArrowSG.IgnoreGuiInset=true; VelArrowSG.DisplayOrder=9985
    pcall(function() VelArrowSG.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not VelArrowSG.Parent then pcall(function() VelArrowSG.Parent=Plr:WaitForChild("PlayerGui") end) end

    local Shaft=Instance.new("Frame",VelArrowSG); Shaft.Name="Shaft"
    Shaft.BackgroundColor3=Color3.fromRGB(255,220,0); Shaft.BorderSizePixel=0; Shaft.ZIndex=8; Shaft.Visible=false
    Instance.new("UICorner",Shaft).CornerRadius=UDim.new(1,0)
    local Head=Instance.new("Frame",VelArrowSG); Head.Name="Head"
    Head.AnchorPoint=Vector2.new(0.5,0.5); Head.Size=UDim2.new(0,12,0,12)
    Head.BackgroundColor3=Color3.fromRGB(255,220,0); Head.BorderSizePixel=0; Head.ZIndex=9; Head.Visible=false
    Instance.new("UICorner",Head).CornerRadius=UDim.new(0,2)
    local SpeedTag=Instance.new("TextLabel",VelArrowSG); SpeedTag.Name="SpeedTag"
    SpeedTag.BackgroundTransparency=1; SpeedTag.Size=UDim2.new(0,80,0,16); SpeedTag.Text="-- st/s"
    SpeedTag.Font=Enum.Font.GothamBold; SpeedTag.TextSize=10
    SpeedTag.TextColor3=Color3.fromRGB(255,230,80); SpeedTag.ZIndex=10; SpeedTag.Visible=false

    VelArrowActive = true
    RunService.Heartbeat:Connect(function()
        if not VelArrowActive then Shaft.Visible=false; Head.Visible=false; SpeedTag.Visible=false; return end
        local ball=GetBall()
        if not ball then Shaft.Visible=false; Head.Visible=false; SpeedTag.Visible=false; return end
        local vel=GetVel(ball); local spd=vel.Magnitude
        if spd<4 then Shaft.Visible=false; Head.Visible=false; SpeedTag.Visible=false; return end
        local sp1,on1=Cam:WorldToViewportPoint(ball.Position)
        if not on1 then Shaft.Visible=false; Head.Visible=false; SpeedTag.Visible=false; return end
        local len=math.clamp(spd*0.45,30,130)
        local ahead3D=ball.Position+vel.Unit*(len/15)
        local sp2,_=Cam:WorldToViewportPoint(ahead3D)
        local dx=sp2.X-sp1.X; local dy=sp2.Y-sp1.Y
        local screenLen=math.sqrt(dx*dx+dy*dy)
        if screenLen<4 then return end
        local rot=math.deg(math.atan2(dy,dx))
        local isTgt=(ball:GetAttribute("target") or "")==Plr.Name
        local col=isTgt and Color3.fromRGB(255,60,60) or Color3.fromRGB(255,220,0)
        pcall(function()
            Shaft.Visible=true; Shaft.BackgroundColor3=col
            Shaft.Size=UDim2.new(0,screenLen,0,3); Shaft.Position=UDim2.new(0,sp1.X,0,sp1.Y-1); Shaft.Rotation=rot
            Head.Visible=true; Head.BackgroundColor3=col
            Head.Position=UDim2.new(0,sp2.X,0,sp2.Y); Head.Rotation=rot+45
            SpeedTag.Visible=true; SpeedTag.Position=UDim2.new(0,sp1.X+dx*0.5-40,0,sp1.Y+dy*0.5-20)
            SpeedTag.Text=("%.0f st/s"):format(spd); SpeedTag.TextColor3=col
        end)
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- GHOST DESYNC
-- ══════════════════════════════════════════════════════════════════
local DS = {
    active    = false,
    mainConn  = nil,
    netConn   = nil,
    phase     = math.random() * math.pi * 2,
    strength  = 0.55,
}

local function StopDesync()
    DS.active = false
    if DS.mainConn then DS.mainConn:Disconnect(); DS.mainConn=nil end
    if DS.netConn  then DS.netConn:Disconnect();  DS.netConn=nil  end

    pcall(function()
        local char=Plr.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local v=root.AssemblyLinearVelocity
        root.AssemblyLinearVelocity=Vector3.new(
            math.floor(v.X*10+0.5)/10, v.Y, math.floor(v.Z*10+0.5)/10)
    end)

    if _G.RyuuHudMode then
        pcall(function()
            _G.RyuuHudMode.Text="⚡ Mode — IDLE"
            _G.RyuuHudMode.TextColor3=Color3.fromRGB(160,160,160)
        end)
    end
end

local function StartDesync()
    StopDesync()
    DS.active = true

    DS.mainConn = RunService.Heartbeat:Connect(function(dt)
        if not DS.active then return end
        local char=Plr.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end

        if hum.Health<=0 then return end
        if hum.Sit then return end

        local t     = os.clock() + DS.phase
        local str   = DS.strength

        local moving = hum.MoveDirection.Magnitude > 0.1
        local jScale = moving and 1.0 or 0.35

        local jx = (math.random()-0.5) * 0.32 * str * jScale
        local jz = (math.random()-0.5) * 0.32 * str * jScale

        local driftX = math.sin(t*0.70+1.3) * 0.55 * str
        local driftZ = math.cos(t*0.53+2.1) * 0.48 * str
        local driftY = math.sin(t*0.90)     * 0.10 * str

        pcall(function()
            local cur = root.AssemblyLinearVelocity
            root.AssemblyLinearVelocity = Vector3.new(
                cur.X + (jx + driftX) * 60 * dt,
                cur.Y + driftY        * 30 * dt,
                cur.Z + (jz + driftZ) * 60 * dt
            )
        end)
    end)

    DS.netConn = RunService.PreSimulation:Connect(function()
        if not DS.active then return end
        local char=Plr.Character; if not char then return end
        local root=char:FindFirstChild("HumanoidRootPart"); if not root then return end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end
        if hum.Health<=0 or hum.Sit then return end

        pcall(function()
            local cur=root.AssemblyLinearVelocity
            local nx=(math.random()-0.5)*0.22*DS.strength
            local nz=(math.random()-0.5)*0.22*DS.strength
            root.AssemblyLinearVelocity=Vector3.new(cur.X+nx, cur.Y, cur.Z+nz)
        end)
    end)

    if _G.RyuuHudMode then
        pcall(function()
            _G.RyuuHudMode.Text="👻 Mode — DESYNC"
            _G.RyuuHudMode.TextColor3=Color3.fromRGB(180,80,255)
        end)
    end
end

Plr.CharacterAdded:Connect(function()
    task.wait(2.0)
    if DS.active then
        DS.active=false
        if DS.mainConn then DS.mainConn:Disconnect(); DS.mainConn=nil end
        if DS.netConn  then DS.netConn:Disconnect();  DS.netConn=nil  end
        task.wait(0.5)
        StartDesync()
    end
end)

-- ══════════════════════════════════════════════════════════════════
-- ABILITY ESP
-- ══════════════════════════════════════════════════════════════════
local AbilityBBs     = {}
local AbilityLastSeen= {}

local BB_ABILITIES = {
    ["Infinity"]={tier="S",col=Color3.fromRGB(255,60,220),warn=true},
    ["Time Hole"]={tier="S",col=Color3.fromRGB(255,60,220),warn=true},
    ["Slash of Duality"]={tier="S",col=Color3.fromRGB(255,60,220),warn=true},
    ["Dribble"]={tier="S",col=Color3.fromRGB(255,60,220),warn=true},
    ["Dragon Spirit"]={tier="S",col=Color3.fromRGB(255,60,220),warn=true},
    ["Pull"]={tier="A",col=Color3.fromRGB(255,130,30),warn=true},
    ["Guardian Angel"]={tier="A",col=Color3.fromRGB(255,130,30),warn=false},
    ["Reaper"]={tier="A",col=Color3.fromRGB(255,130,30),warn=false},
    ["Slashes of Fury"]={tier="A",col=Color3.fromRGB(255,130,30),warn=true},
    ["Forcefield"]={tier="A",col=Color3.fromRGB(255,130,30),warn=false},
    ["Bunny Leap"]={tier="A",col=Color3.fromRGB(255,130,30),warn=false},
    ["Singularity"]={tier="A",col=Color3.fromRGB(255,130,30),warn=true},
    ["Invisibility"]={tier="B",col=Color3.fromRGB(80,220,120),warn=false},
    ["Titan Blade"]={tier="B",col=Color3.fromRGB(80,220,120),warn=false},
    ["Scopophobia"]={tier="B",col=Color3.fromRGB(80,220,120),warn=true},
    ["Blade Trap"]={tier="B",col=Color3.fromRGB(80,220,120),warn=true},
    ["Death Slash"]={tier="B",col=Color3.fromRGB(80,220,120),warn=true},
    ["Phantom"]={tier="B",col=Color3.fromRGB(80,220,120),warn=true},
    ["Swap"]={tier="B",col=Color3.fromRGB(80,220,120),warn=true},
    ["Hell Hook"]={tier="B",col=Color3.fromRGB(80,220,120),warn=true},
    ["Blink"]={tier="B",col=Color3.fromRGB(80,220,120),warn=false},
    ["Qi-Charge"]={tier="B",col=Color3.fromRGB(80,220,120),warn=false},
    ["Telekinesis"]={tier="B",col=Color3.fromRGB(80,220,120),warn=true},
    ["Thunder Dash"]={tier="B",col=Color3.fromRGB(80,220,120),warn=false},
    ["Flash Counter"]={tier="C",col=Color3.fromRGB(255,220,40),warn=false},
    ["Pulse"]={tier="C",col=Color3.fromRGB(255,220,40),warn=false},
    ["Raging Deflection"]={tier="C",col=Color3.fromRGB(255,220,40),warn=true},
    ["Freeze"]={tier="C",col=Color3.fromRGB(255,220,40),warn=true},
    ["Quantum Arena"]={tier="C",col=Color3.fromRGB(255,220,40),warn=true},
    ["Dash"]={tier="C",col=Color3.fromRGB(255,220,40),warn=false},
    ["Quasar"]={tier="C",col=Color3.fromRGB(255,220,40),warn=false},
    ["Freeze Trap"]={tier="D",col=Color3.fromRGB(160,160,160),warn=false},
    ["Martyrdom"]={tier="D",col=Color3.fromRGB(160,160,160),warn=true},
    ["Super Jump"]={tier="D",col=Color3.fromRGB(160,160,160),warn=false},
}

local TIER_COL={S=Color3.fromRGB(255,60,220),A=Color3.fromRGB(255,130,30),B=Color3.fromRGB(80,220,120),C=Color3.fromRGB(255,220,40),D=Color3.fromRGB(160,160,160)}

local function ScanAbility(plr)
    if not plr then return nil end
    local char=plr.Character
    local function match(s)
        if not s or #s<2 then return nil end
        if BB_ABILITIES[s] then return s end
        local sl=s:lower()
        for k in pairs(BB_ABILITIES) do if k:lower()==sl then return k end end
        return nil
    end
    for _,n in ipairs({"Ability","ability","AbilityName","EquippedAbility","Skill","CurrentAbility","equipped"}) do
        local ok,v=pcall(function() return plr:GetAttribute(n) end)
        if ok and type(v)=="string" then local r=match(v); if r then return r end end
    end
    if char then
        for _,n in ipairs({"Ability","ability","AbilityName","EquippedAbility","Skill","CurrentAbility"}) do
            local ok,v=pcall(function() return char:GetAttribute(n) end)
            if ok and type(v)=="string" then local r=match(v); if r then return r end end
        end
        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("StringValue") then local r=match(v.Value); if r then return r end end
        end
    end
    return nil
end

local function BuildAbilityBB(plr)
    if not (plr and plr.Character) then return end
    local head=plr.Character:FindFirstChild("Head"); if not head then return end
    if AbilityBBs[plr] and AbilityBBs[plr].Parent then pcall(function() AbilityBBs[plr]:Destroy() end) end
    AbilityLastSeen[plr]=nil

    local bb=Instance.new("BillboardGui")
    bb.Name="RyuuAbilESP"; bb.AlwaysOnTop=true
    bb.Size=UDim2.new(0,152,0,42); bb.StudsOffset=Vector3.new(0,3.2,0)
    bb.MaxDistance=100; bb.Parent=head

    local bg=Instance.new("Frame",bb); bg.Size=UDim2.new(1,0,1,0)
    bg.BackgroundColor3=Color3.fromRGB(7,4,16); bg.BackgroundTransparency=0.12; bg.BorderSizePixel=0
    Instance.new("UICorner",bg).CornerRadius=UDim.new(0,10)

    local accent=Instance.new("Frame",bg); accent.Name="Accent"
    accent.Size=UDim2.new(1,0,0,2); accent.BackgroundColor3=Color3.fromRGB(120,40,240); accent.BorderSizePixel=0
    Instance.new("UICorner",accent).CornerRadius=UDim.new(0,10)

    local stroke=Instance.new("UIStroke",bg); stroke.Name="S"
    stroke.Thickness=1.2; stroke.Color=Color3.fromRGB(55,28,100)

    local nLbl=Instance.new("TextLabel",bg); nLbl.Name="PN"
    nLbl.Size=UDim2.new(1,-36,0,14); nLbl.Position=UDim2.new(0,5,0,4)
    nLbl.BackgroundTransparency=1; nLbl.Text=plr.Name
    nLbl.TextColor3=Color3.fromRGB(140,130,175); nLbl.Font=Enum.Font.GothamBold; nLbl.TextSize=10
    nLbl.TextXAlignment=Enum.TextXAlignment.Left

    local badge=Instance.new("TextLabel",bg); badge.Name="TB"
    badge.Size=UDim2.new(0,26,0,14); badge.Position=UDim2.new(1,-30,0,4)
    badge.BackgroundColor3=Color3.fromRGB(25,12,50); badge.BorderSizePixel=0
    badge.Text="?"; badge.TextColor3=Color3.fromRGB(170,90,255)
    badge.Font=Enum.Font.GothamBlack; badge.TextSize=10
    Instance.new("UICorner",badge).CornerRadius=UDim.new(0,5)

    local aLbl=Instance.new("TextLabel",bg); aLbl.Name="AN"
    aLbl.Size=UDim2.new(1,-10,0,20); aLbl.Position=UDim2.new(0,5,0,18)
    aLbl.BackgroundTransparency=1; aLbl.Text="Scanning..."
    aLbl.TextColor3=Color3.fromRGB(200,200,200); aLbl.Font=Enum.Font.GothamBold; aLbl.TextSize=13
    aLbl.TextXAlignment=Enum.TextXAlignment.Left

    AbilityBBs[plr]=bb
end

local function RefreshBB(plr)
    if not (plr and plr.Character) then return end
    local bb=AbilityBBs[plr]
    if not (bb and bb.Parent) then BuildAbilityBB(plr); bb=AbilityBBs[plr] end
    if not bb then return end
    local bg=bb:FindFirstChildOfClass("Frame"); if not bg then return end
    local aLbl=bg:FindFirstChild("AN"); if not aLbl then return end
    local badge=bg:FindFirstChild("TB"); local stk=bg:FindFirstChild("S"); local accent=bg:FindFirstChild("Accent")
    local name=ScanAbility(plr)
    local cacheKey=name or "__none__"
    if AbilityLastSeen[plr]==cacheKey then return end
    AbilityLastSeen[plr]=cacheKey
    if name then
        local data=BB_ABILITIES[name]
        if data then
            local col=data.warn and Color3.fromRGB(255,65,65) or data.col
            aLbl.Text=(data.warn and "⚠  " or "")..name; aLbl.TextColor3=col
            if badge  then badge.Text=data.tier; badge.TextColor3=TIER_COL[data.tier] or Color3.fromRGB(170,90,255) end
            if stk    then stk.Color=data.warn and Color3.fromRGB(190,40,40) or data.col end
            if accent then accent.BackgroundColor3=col end
        else
            aLbl.Text=name; aLbl.TextColor3=Color3.fromRGB(200,200,200)
        end
    else
        aLbl.Text="No Ability"; aLbl.TextColor3=Color3.fromRGB(80,75,100)
        if badge then badge.Text="-" end
    end
end

local function CleanAbilityESP()
    for _,bb in pairs(AbilityBBs) do pcall(function() if bb and bb.Parent then bb:Destroy() end end) end
    AbilityBBs={}; AbilityLastSeen={}
end

local function StartAbilityESP()
    CleanAbilityESP()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=Plr then BuildAbilityBB(p); RefreshBB(p) end
    end
    task.spawn(function()
        while S.AbilityESP do
            for _,p in ipairs(Players:GetPlayers()) do
                if p~=Plr and p.Character then RefreshBB(p) end
            end
            task.wait(0.75)
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- ABILITY DETECTOR — FIXED: Only fires when ball targets YOU
-- ══════════════════════════════════════════════════════════════════
local Det={conn=nil,cds={},cd=0.4}
local PDet={conn=nil,cds={},cd=0.4}

local FREE_SIGS={
    {name="Slashes of Fury",check=function(char,plr)
        if not char then return false end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
        local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return false end
        for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
            local n=t.Name:lower()
            if n:find("fury") or n:find("slash") or n:find("barrage") then return true end
        end
        return false
    end},
    {name="Pull",check=function(char,plr)
        if not char then return false end
        local aa=plr:GetAttribute("AbilityActive")
        if aa and tostring(aa):lower():find("pull") then return true end
        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.Name:lower():find("pull") then return true end
        end
        return false
    end},
}

local PREM_SIGS={
    {name="Slashes of Fury",check=function(char,plr)
        if not char then return false end
        local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return false end
        local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return false end
        for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
            local n=t.Name:lower()
            if n:find("fury") or n:find("slash") or n:find("barrage") or n:find("multi") then return true end
        end
        return false
    end},
    {name="Time Hole",check=function(char,plr)
        if not char then return false end
        for _,v in ipairs(char:GetDescendants()) do
            local n=v.Name:lower()
            if (n:find("hole") or n:find("time") or n:find("vortex"))
               and (v:IsA("BasePart") or v:IsA("ParticleEmitter")) then return true end
        end
        return false
    end},
    {name="Slash of Duality",check=function(char,plr)
        if not char then return false end
        for _,v in ipairs(char:GetDescendants()) do
            local n=v.Name:lower()
            if (n:find("dual") or n:find("duality"))
               and (v:IsA("BasePart") or v:IsA("ParticleEmitter")) then return true end
        end
        return false
    end},
    {name="Dragon Spirit",check=function(char,plr)
        if not char then return false end
        for _,v in ipairs(char:GetDescendants()) do
            local n=v.Name:lower()
            if (n:find("dragon") or n:find("spirit"))
               and (v:IsA("BasePart") or v:IsA("ParticleEmitter")) then return true end
        end
        return false
    end},
    {name="Pull",check=function(char,plr)
        if not char then return false end
        local aa=plr:GetAttribute("AbilityActive")
        if aa and tostring(aa):lower():find("pull") then return true end
        for _,v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") and v.Name:lower():find("pull") then return true end
        end
        return false
    end},
    {name="Phantom",check=function(char,plr)
        if not char then return false end
        local hrp=char:FindFirstChild("HumanoidRootPart")
        return hrp and hrp.Transparency>0.4 or false
    end},
    {name="Hell Hook",check=function(char,plr)
        if not char then return false end
        local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return false end
        for _,v in ipairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                local n=v.Name:lower()
                if (n:find("hook") or n:find("hell")) and (v.Position-hrp.Position).Magnitude<25 then return true end
            end
        end
        return false
    end},
}

-- FIX: RunDetector now requires ball target == Plr.Name before firing.
-- Without this, the detector would fire for ANY player using an ability
-- near ANY ball, even if the ball was heading toward your teammate.
-- Now it ONLY fires if the ball is currently targeting you.
local function RunDetector(sigList, fireFn, detState)
    local lastTick=0
    return RunService.Heartbeat:Connect(function()
        local now=os.clock()
        if now-lastTick<0.05 then return end
        lastTick=now
        pcall(function()
            local ball=GetBall(); if not ball then return end
            local tgt=ball:GetAttribute("target"); if not tgt then return end

            -- FIX: STRICT GATE — ball must be targeting ME
            -- This is the key fix for "too sensitive" — we only care about
            -- abilities used when the ball is specifically coming at us
            if tgt ~= Plr.Name then return end

            local myHRP=GetHRP(); if not myHRP then return end
            for _,p in ipairs(Players:GetPlayers()) do
                if p==Plr then continue end
                local char=p.Character; if not char then continue end
                local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
                if (myHRP.Position-hrp.Position).Magnitude>80 then continue end

                -- Only check enemies who are near the ball OR near us
                -- (not just anyone in the server who happens to use an ability)
                local ballNearEnemy=(hrp.Position-ball.Position).Magnitude<20
                local enemyNearMe=(myHRP.Position-hrp.Position).Magnitude<30
                if not (ballNearEnemy or enemyNearMe) then continue end

                local cdKey=p.Name
                if detState.cds[cdKey] and now-detState.cds[cdKey]<detState.cd then continue end
                for _,sig in ipairs(sigList) do
                    if sig.check(char,p) then detState.cds[cdKey]=now; fireFn(); break end
                end
            end
        end)
    end)
end

local function StartAbilDetect()
    if Det.conn then Det.conn:Disconnect() end
    Det.cds={}; Det.conn=RunDetector(FREE_SIGS,FireParry,Det)
end
local function StopAbilDetect()
    if Det.conn then Det.conn:Disconnect(); Det.conn=nil end
end
local function StartPremAbilDetect()
    if PDet.conn then PDet.conn:Disconnect() end
    PDet.cds={}; PDet.conn=RunDetector(PREM_SIGS,PremiumFire,PDet)
end
local function StopPremAbilDetect()
    if PDet.conn then PDet.conn:Disconnect(); PDet.conn=nil end
end

-- ══════════════════════════════════════════════════════════════════
-- MISC: Fullbright, Noclip, Inf Jump, Ball ESP
-- ══════════════════════════════════════════════════════════════════
local function SetFB(on)
    if on then Lighting.Brightness=2; Lighting.GlobalShadows=false; Lighting.FogEnd=9e9
    else       Lighting.Brightness=1; Lighting.GlobalShadows=true;  Lighting.FogEnd=100000 end
end

local function StartNoclip()
    RunService.Stepped:Connect(function()
        if not S.Noclip then return end
        local c=Plr.Character; if not c then return end
        for _,p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide=false end
        end
    end)
end

local function StartIJ()
    UIS.JumpRequest:Connect(function()
        if not S.InfJump then return end
        local c=Plr.Character
        local h=c and c:FindFirstChildOfClass("Humanoid")
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
end

local BallESPGui=nil
local function StartESP()
    if BallESPGui then pcall(function() BallESPGui:Destroy() end) end
    local sg=Instance.new("ScreenGui"); sg.Name="RyuuBallESP"
    sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true; sg.DisplayOrder=9997
    pcall(function() sg.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not sg.Parent then pcall(function() sg.Parent=Plr:WaitForChild("PlayerGui") end) end
    BallESPGui=sg
    RunService.Heartbeat:Connect(function()
        if not S.BallESP then return end
        local ball=GetBall(); if not ball then return end
        local isTgt=(ball:GetAttribute("target") or "")==Plr.Name
        local pos,onScreen=Cam:WorldToViewportPoint(ball.Position)
        if not onScreen then return end
        local dot=sg:FindFirstChild("BallDot")
        if not dot then
            dot=Instance.new("Frame",sg); dot.Name="BallDot"
            dot.Size=UDim2.new(0,14,0,14); dot.AnchorPoint=Vector2.new(0.5,0.5)
            dot.BorderSizePixel=0; dot.ZIndex=5
            Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
        end
        dot.Position=UDim2.new(0,pos.X,0,pos.Y)
        dot.BackgroundColor3=isTgt and Color3.fromRGB(255,50,50) or Color3.fromRGB(50,220,80)
    end)
end
local function CleanESP()
    if BallESPGui then pcall(function() BallESPGui:Destroy() end); BallESPGui=nil end
end

-- ══════════════════════════════════════════════════════════════════
-- SWORD SKIN
-- ══════════════════════════════════════════════════════════════════
local SWORD_COLORS={
    Default=nil, Gold=Color3.fromRGB(255,200,40),
    ["Shadow Black"]=Color3.fromRGB(15,10,20), ["Crystal Blue"]=Color3.fromRGB(40,140,255),
    Crimson=Color3.fromRGB(200,30,30), ["Ghost White"]=Color3.fromRGB(230,230,255),
    ["Neon Purple"]=Color3.fromRGB(180,40,255), Emerald=Color3.fromRGB(20,200,80),
    ["Rose Gold"]=Color3.fromRGB(220,140,120), Obsidian=Color3.fromRGB(30,28,35),
    Cyan=Color3.fromRGB(0,220,220), Orange=Color3.fromRGB(255,120,20), Rainbow=nil,
}
local SWORD_MATS={Default=Enum.Material.SmoothPlastic,["Neon Purple"]=Enum.Material.Neon,
    Emerald=Enum.Material.Neon,Cyan=Enum.Material.Neon,Rainbow=Enum.Material.Neon}
local CurrentSwordPreset="Default"
local SwordOrigColors={}
local RainbowHue=0

local function GetSwordParts()
    local char=Plr.Character; if not char then return nil,{} end
    local tool=nil
    for _,v in ipairs(char:GetChildren()) do if v:IsA("Tool") then tool=v; break end end
    if not tool then return nil,{} end
    local parts={}
    for _,v in ipairs(tool:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("UnionOperation") then parts[#parts+1]=v end
    end
    local h=tool:FindFirstChild("Handle"); if h then parts[#parts+1]=h end
    return tool,parts
end

local function ApplySwordPreset(name)
    CurrentSwordPreset=name
    local _,parts=GetSwordParts(); if #parts==0 then return end
    for _,p in ipairs(parts) do
        if not SwordOrigColors[p] then SwordOrigColors[p]={color=p.Color,mat=p.Material} end
    end
    if name=="Default" then
        for _,p in ipairs(parts) do
            local o=SwordOrigColors[p]
            if o then pcall(function() p.Color=o.color; p.Material=o.mat end) end
        end
        return
    end
    if name=="Rainbow" then
        RainbowHue=(RainbowHue+0.08)%1
        local col=Color3.fromHSV(RainbowHue,1,1)
        for _,p in ipairs(parts) do pcall(function() p.Color=col; p.Material=Enum.Material.Neon end) end
        return
    end
    local col=SWORD_COLORS[name]; if not col then return end
    local mat=SWORD_MATS[name] or Enum.Material.SmoothPlastic
    for _,p in ipairs(parts) do pcall(function() p.Color=col; p.Material=mat end) end
end

local function HookSwordApply(char)
    char.ChildAdded:Connect(function(v)
        if v:IsA("Tool") then task.wait(0.1); ApplySwordPreset(CurrentSwordPreset) end
    end)
end
if Plr.Character then HookSwordApply(Plr.Character) end
Plr.CharacterAdded:Connect(function(char)
    task.wait(0.5); HookSwordApply(char)
end)

-- ══════════════════════════════════════════════════════════════════
-- PREMIUM VISUAL FEATURES
-- ══════════════════════════════════════════════════════════════════
local function BuildKillWidget()
    if GUI.Kill then pcall(function() GUI.Kill:Destroy() end) end
    GUI.Kill=Instance.new("ScreenGui"); GUI.Kill.Name="RyuuKills"; GUI.Kill.ResetOnSpawn=false
    GUI.Kill.IgnoreGuiInset=true; GUI.Kill.DisplayOrder=9992
    pcall(function() GUI.Kill.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.Kill.Parent then pcall(function() GUI.Kill.Parent=Plr:WaitForChild("PlayerGui") end) end
    local KFrame=Instance.new("Frame",GUI.Kill); KFrame.AnchorPoint=Vector2.new(1,0)
    KFrame.Position=UDim2.new(1,-14,0,130); KFrame.Size=UDim2.new(0,150,0,46)
    KFrame.BackgroundColor3=Color3.fromRGB(5,12,20); KFrame.BackgroundTransparency=0.2; KFrame.BorderSizePixel=0
    Instance.new("UICorner",KFrame).CornerRadius=UDim.new(0,10)
    local KStr=Instance.new("UIStroke",KFrame); KStr.Thickness=1.2; KStr.Color=Color3.fromRGB(255,60,60); KStr.Transparency=0.3
    local KTitle=Instance.new("TextLabel",KFrame); KTitle.Size=UDim2.new(1,-8,0,13); KTitle.Position=UDim2.new(0,6,0,6)
    KTitle.BackgroundTransparency=1; KTitle.Text="☠  KILLS"; KTitle.Font=Enum.Font.GothamBlack; KTitle.TextSize=9
    KTitle.TextColor3=Color3.fromRGB(255,80,80); KTitle.TextXAlignment=Enum.TextXAlignment.Left
    GUI.KillLbl=Instance.new("TextLabel",KFrame); GUI.KillLbl.Size=UDim2.new(1,-8,0,22); GUI.KillLbl.Position=UDim2.new(0,6,0,20)
    GUI.KillLbl.BackgroundTransparency=1; GUI.KillLbl.Text="0"; GUI.KillLbl.Font=Enum.Font.GothamBlack
    GUI.KillLbl.TextSize=20; GUI.KillLbl.TextColor3=Color3.fromRGB(255,90,90); GUI.KillLbl.TextXAlignment=Enum.TextXAlignment.Left
end

local function BuildTrajectoryESP()
    if GUI.Traj then pcall(function() GUI.Traj:Destroy() end) end
    GUI.Traj=Instance.new("ScreenGui"); GUI.Traj.Name="RyuuTraj"; GUI.Traj.ResetOnSpawn=false
    GUI.Traj.IgnoreGuiInset=true; GUI.Traj.DisplayOrder=9989
    pcall(function() GUI.Traj.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.Traj.Parent then pcall(function() GUI.Traj.Parent=Plr:WaitForChild("PlayerGui") end) end
    local Line=Instance.new("Frame",GUI.Traj); Line.BackgroundColor3=Color3.fromRGB(255,60,60)
    Line.BorderSizePixel=0; Line.ZIndex=5; Line.Visible=false
    Instance.new("UICorner",Line).CornerRadius=UDim.new(1,0)
    local Arrow=Instance.new("Frame",GUI.Traj); Arrow.AnchorPoint=Vector2.new(0.5,0.5)
    Arrow.Size=UDim2.new(0,10,0,10); Arrow.BorderSizePixel=0; Arrow.ZIndex=6; Arrow.Visible=false
    Instance.new("UICorner",Arrow).CornerRadius=UDim.new(0,2)
    RunService.Heartbeat:Connect(function()
        if not PF.TrajectoryESP or not PremiumUnlocked then Line.Visible=false; Arrow.Visible=false; return end
        local ball=GetBall(); if not ball then Line.Visible=false; Arrow.Visible=false; return end
        local vel=GetVel(ball); if vel.Magnitude<2 then Line.Visible=false; Arrow.Visible=false; return end
        local isTgt=(ball:GetAttribute("target") or "")==Plr.Name
        local ahead=ball.Position+vel.Unit*math.min(vel.Magnitude*0.5,50)
        local sp1,on1=Cam:WorldToViewportPoint(ball.Position)
        local sp2,_=Cam:WorldToViewportPoint(ahead)
        if not on1 then Line.Visible=false; Arrow.Visible=false; return end
        local dx=sp2.X-sp1.X; local dy=sp2.Y-sp1.Y; local len=math.sqrt(dx*dx+dy*dy)
        if len<3 then return end
        local rot=math.deg(math.atan2(dy,dx))
        local col=isTgt and Color3.fromRGB(255,50,50) or Color3.fromRGB(0,200,255)
        pcall(function()
            Line.Visible=true; Line.BackgroundColor3=col
            Line.Size=UDim2.new(0,len,0,2); Line.Position=UDim2.new(0,sp1.X,0,sp1.Y-1); Line.Rotation=rot
            Arrow.Visible=true; Arrow.BackgroundColor3=col
            Arrow.Position=UDim2.new(0,sp2.X,0,sp2.Y); Arrow.Rotation=rot+45
        end)
    end)
end

local function UpdateDistESP()
    if not PF.DistESP or not PremiumUnlocked then
        for _,bb in pairs(GUI.Dist) do pcall(function() bb:Destroy() end) end; GUI.Dist={}; return
    end
    local hrp=GetHRP(); if not hrp then return end
    for _,p in ipairs(Players:GetPlayers()) do
        if p==Plr then continue end
        local char=p.Character; if not char then continue end
        local head=char:FindFirstChild("Head"); if not head then continue end
        local pHRP=char:FindFirstChild("HumanoidRootPart"); if not pHRP then continue end
        if not GUI.Dist[p] or not GUI.Dist[p].Parent then
            local bb=Instance.new("BillboardGui"); bb.Name="RyuuDistESP"; bb.AlwaysOnTop=true
            bb.Size=UDim2.new(0,90,0,18); bb.StudsOffset=Vector3.new(0,3,0); bb.MaxDistance=130; bb.Parent=head
            local lbl=Instance.new("TextLabel",bb); lbl.Name="D"; lbl.Size=UDim2.new(1,0,1,0)
            lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11
            lbl.TextStrokeTransparency=0.5; lbl.TextColor3=Color3.fromRGB(0,220,255)
            GUI.Dist[p]=bb
        end
        local dist=(hrp.Position-pHRP.Position).Magnitude
        local lbl=GUI.Dist[p]:FindFirstChild("D")
        if lbl then
            local col=dist<12 and Color3.fromRGB(255,70,70) or dist<35 and Color3.fromRGB(255,200,40) or Color3.fromRGB(0,220,255)
            lbl.Text=("%.0f st  %s"):format(dist,p.Name); lbl.TextColor3=col
        end
    end
end
RunService.Heartbeat:Connect(function() if PF.DistESP and PremiumUnlocked then UpdateDistESP() end end)

local function ApplyChams(on)
    if not on then
        for part,data in pairs(GUI.Chams) do
            pcall(function() if part and part.Parent then part.Material=data.mat; part.Color=data.col end end)
        end; GUI.Chams={}; return
    end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=Plr and p.Character then
            for _,part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") and not GUI.Chams[part] then
                    GUI.Chams[part]={mat=part.Material,col=part.Color}
                    pcall(function() part.Material=Enum.Material.Neon; part.Color=Color3.fromRGB(0,200,255) end)
                end
            end
        end
    end
end

local function BuildTTI()
    if GUI.TTI then pcall(function() GUI.TTI:Destroy() end) end
    GUI.TTI=Instance.new("ScreenGui"); GUI.TTI.Name="RyuuTTI"; GUI.TTI.ResetOnSpawn=false
    GUI.TTI.IgnoreGuiInset=true; GUI.TTI.DisplayOrder=9991
    pcall(function() GUI.TTI.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.TTI.Parent then pcall(function() GUI.TTI.Parent=Plr:WaitForChild("PlayerGui") end) end
    local TTIFrame=Instance.new("Frame",GUI.TTI); TTIFrame.AnchorPoint=Vector2.new(0.5,0)
    TTIFrame.Position=UDim2.new(0.5,0,0,20); TTIFrame.Size=UDim2.new(0,150,0,30)
    TTIFrame.BackgroundColor3=Color3.fromRGB(4,12,20); TTIFrame.BackgroundTransparency=0.18
    TTIFrame.BorderSizePixel=0; TTIFrame.Visible=false
    Instance.new("UICorner",TTIFrame).CornerRadius=UDim.new(0,8)
    local TTIStr=Instance.new("UIStroke",TTIFrame); TTIStr.Thickness=1.2; TTIStr.Color=Color3.fromRGB(0,180,255); TTIStr.Transparency=0.3
    local TTILabel=Instance.new("TextLabel",TTIFrame); TTILabel.Size=UDim2.new(1,0,1,0)
    TTILabel.BackgroundTransparency=1; TTILabel.Text="⏱  --.-s"; TTILabel.Font=Enum.Font.GothamBold
    TTILabel.TextSize=13; TTILabel.TextColor3=Color3.fromRGB(0,220,255)
    RunService.Heartbeat:Connect(function()
        if not PF.TimeToImpact or not PremiumUnlocked then TTIFrame.Visible=false; return end
        local ball=GetBall(); local hrp=GetHRP()
        if not ball or not hrp then TTIFrame.Visible=false; return end
        if (ball:GetAttribute("target") or "")~=Plr.Name then TTIFrame.Visible=false; return end
        local vel=GetVel(ball); local spd=vel.Magnitude
        if spd<1 then TTIFrame.Visible=false; return end
        local dist=(hrp.Position-ball.Position).Magnitude; local tti=dist/spd
        local col=tti<0.3 and Color3.fromRGB(255,60,60) or tti<0.6 and Color3.fromRGB(255,200,40) or Color3.fromRGB(0,220,255)
        pcall(function() TTIFrame.Visible=true; TTILabel.Text=("⏱  %.2fs"):format(tti); TTILabel.TextColor3=col; TTIStr.Color=col end)
    end)
end

local function BuildSpeedMeter()
    if GUI.SpeedMeter then pcall(function() GUI.SpeedMeter:Destroy() end) end
    GUI.SpeedMeter=Instance.new("ScreenGui"); GUI.SpeedMeter.Name="RyuuSpeedMeter"; GUI.SpeedMeter.ResetOnSpawn=false
    GUI.SpeedMeter.IgnoreGuiInset=true; GUI.SpeedMeter.DisplayOrder=9993
    pcall(function() GUI.SpeedMeter.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.SpeedMeter.Parent then pcall(function() GUI.SpeedMeter.Parent=Plr:WaitForChild("PlayerGui") end) end
    local SMFrame=Instance.new("Frame",GUI.SpeedMeter); SMFrame.AnchorPoint=Vector2.new(0.5,1)
    SMFrame.Position=UDim2.new(0.5,0,1,-60); SMFrame.Size=UDim2.new(0,200,0,62)
    SMFrame.BackgroundColor3=Color3.fromRGB(4,12,20); SMFrame.BackgroundTransparency=0.18; SMFrame.BorderSizePixel=0
    Instance.new("UICorner",SMFrame).CornerRadius=UDim.new(0,10)
    local SMStr=Instance.new("UIStroke",SMFrame); SMStr.Thickness=1.2; SMStr.Color=Color3.fromRGB(0,180,255); SMStr.Transparency=0.3
    local SMTitle=Instance.new("TextLabel",SMFrame); SMTitle.Size=UDim2.new(1,-8,0,13); SMTitle.Position=UDim2.new(0,8,0,5)
    SMTitle.BackgroundTransparency=1; SMTitle.Text="⚡  BALL SPEED"; SMTitle.Font=Enum.Font.GothamBlack
    SMTitle.TextSize=9; SMTitle.TextColor3=Color3.fromRGB(0,170,220); SMTitle.TextXAlignment=Enum.TextXAlignment.Left
    local SMVal=Instance.new("TextLabel",SMFrame); SMVal.Size=UDim2.new(0,100,0,22); SMVal.Position=UDim2.new(0,8,0,20)
    SMVal.BackgroundTransparency=1; SMVal.Text="-- st/s"; SMVal.Font=Enum.Font.GothamBlack
    SMVal.TextSize=18; SMVal.TextColor3=Color3.fromRGB(0,220,255); SMVal.TextXAlignment=Enum.TextXAlignment.Left
    RunService.Heartbeat:Connect(function()
        if not PF.BallSpeedMeter or not PremiumUnlocked then return end
        local ball=GetBall(); if not ball then return end
        local spd=GetVel(ball).Magnitude
        pcall(function()
            local col=spd>220 and Color3.fromRGB(255,70,70) or spd>120 and Color3.fromRGB(255,200,40) or Color3.fromRGB(0,220,255)
            SMVal.Text=("%.0f st/s"):format(spd); SMVal.TextColor3=col; SMStr.Color=col
        end)
    end)
end

local function BuildTargetAlert()
    if GUI.Alert then pcall(function() GUI.Alert:Destroy() end) end
    GUI.Alert=Instance.new("ScreenGui"); GUI.Alert.Name="RyuuAlert"; GUI.Alert.ResetOnSpawn=false
    GUI.Alert.IgnoreGuiInset=true; GUI.Alert.DisplayOrder=9990
    pcall(function() GUI.Alert.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.Alert.Parent then pcall(function() GUI.Alert.Parent=Plr:WaitForChild("PlayerGui") end) end
    local function makeEdge(size,pos)
        local f=Instance.new("Frame",GUI.Alert); f.Size=size; f.Position=pos
        f.BackgroundColor3=Color3.fromRGB(255,50,50); f.BackgroundTransparency=1; f.BorderSizePixel=0; f.ZIndex=5; return f
    end
    local edges={
        makeEdge(UDim2.new(1,0,0,5),UDim2.new(0,0,0,0)),
        makeEdge(UDim2.new(1,0,0,5),UDim2.new(0,0,1,-5)),
        makeEdge(UDim2.new(0,5,1,0),UDim2.new(0,0,0,0)),
        makeEdge(UDim2.new(0,5,1,0),UDim2.new(1,-5,0,0)),
    }
    RunService.Heartbeat:Connect(function()
        if not PF.TargetAlert or not PremiumUnlocked then
            for _,e in ipairs(edges) do pcall(function() e.BackgroundTransparency=1 end) end; return
        end
        local ball=GetBall(); if not ball then return end
        if (ball:GetAttribute("target") or "")==Plr.Name then
            local alpha=math.abs(math.sin(os.clock()*8))*0.6+0.05
            for _,e in ipairs(edges) do pcall(function() e.BackgroundTransparency=1-alpha end) end
        else
            for _,e in ipairs(edges) do pcall(function() e.BackgroundTransparency=1 end) end
        end
    end)
end

local function BuildSafeZoneWarning()
    if GUI.SafeZone then pcall(function() GUI.SafeZone:Destroy() end) end
    GUI.SafeZone=Instance.new("ScreenGui"); GUI.SafeZone.Name="RyuuSafeZone"; GUI.SafeZone.ResetOnSpawn=false
    GUI.SafeZone.IgnoreGuiInset=true; GUI.SafeZone.DisplayOrder=9988
    pcall(function() GUI.SafeZone.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.SafeZone.Parent then pcall(function() GUI.SafeZone.Parent=Plr:WaitForChild("PlayerGui") end) end
    local WarnLbl=Instance.new("TextLabel",GUI.SafeZone); WarnLbl.AnchorPoint=Vector2.new(0.5,0)
    WarnLbl.Position=UDim2.new(0.5,0,0,8); WarnLbl.Size=UDim2.new(0,200,0,20)
    WarnLbl.BackgroundTransparency=1; WarnLbl.Text="⚠  EXPOSED — STAY ALERT"
    WarnLbl.Font=Enum.Font.GothamBold; WarnLbl.TextSize=11
    WarnLbl.TextColor3=Color3.fromRGB(255,160,30); WarnLbl.Visible=false; WarnLbl.ZIndex=4
    RunService.Heartbeat:Connect(function()
        if not PF.SafeZoneWarn or not PremiumUnlocked then WarnLbl.Visible=false; return end
        local ball=GetBall()
        WarnLbl.Visible = ball and (ball:GetAttribute("target") or "")==Plr.Name
    end)
end

local function BuildWatermark()
    if GUI.Watermark then pcall(function() GUI.Watermark:Destroy() end) end
    GUI.Watermark=Instance.new("ScreenGui"); GUI.Watermark.Name="RyuuWatermark"; GUI.Watermark.ResetOnSpawn=false
    GUI.Watermark.IgnoreGuiInset=true; GUI.Watermark.DisplayOrder=9987
    pcall(function() GUI.Watermark.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.Watermark.Parent then pcall(function() GUI.Watermark.Parent=Plr:WaitForChild("PlayerGui") end) end
    local WMFrame=Instance.new("Frame",GUI.Watermark); WMFrame.AnchorPoint=Vector2.new(0,1)
    WMFrame.Position=UDim2.new(0,10,1,-10); WMFrame.Size=UDim2.new(0,190,0,28)
    WMFrame.BackgroundColor3=Color3.fromRGB(3,10,20); WMFrame.BackgroundTransparency=0.2; WMFrame.BorderSizePixel=0
    Instance.new("UICorner",WMFrame).CornerRadius=UDim.new(0,8)
    local WMStr=Instance.new("UIStroke",WMFrame); WMStr.Thickness=1; WMStr.Color=Color3.fromRGB(0,180,255); WMStr.Transparency=0.3
    local WMLbl=Instance.new("TextLabel",WMFrame); WMLbl.Size=UDim2.new(1,-8,1,0); WMLbl.Position=UDim2.new(0,8,0,0)
    WMLbl.BackgroundTransparency=1; WMLbl.Text="◈  Ryuu HUB V2  ·  PREMIUM"; WMLbl.Font=Enum.Font.GothamBold
    WMLbl.TextSize=10; WMLbl.TextColor3=Color3.fromRGB(0,200,255); WMLbl.TextXAlignment=Enum.TextXAlignment.Left
end

local function BuildComboWidget()
    if GUI.Combo then pcall(function() GUI.Combo:Destroy() end) end
    GUI.Combo=Instance.new("ScreenGui"); GUI.Combo.Name="RyuuCombo"; GUI.Combo.ResetOnSpawn=false
    GUI.Combo.IgnoreGuiInset=true; GUI.Combo.DisplayOrder=9994
    pcall(function() GUI.Combo.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not GUI.Combo.Parent then pcall(function() GUI.Combo.Parent=Plr:WaitForChild("PlayerGui") end) end
    GUI.ComboFrame=Instance.new("Frame",GUI.Combo); GUI.ComboFrame.AnchorPoint=Vector2.new(0.5,0)
    GUI.ComboFrame.Position=UDim2.new(0.5,0,0,80); GUI.ComboFrame.Size=UDim2.new(0,160,0,58)
    GUI.ComboFrame.BackgroundColor3=Color3.fromRGB(6,3,14); GUI.ComboFrame.BackgroundTransparency=0.15; GUI.ComboFrame.BorderSizePixel=0
    Instance.new("UICorner",GUI.ComboFrame).CornerRadius=UDim.new(0,12)
    local CStr=Instance.new("UIStroke",GUI.ComboFrame); CStr.Thickness=1.4; CStr.Color=Color3.fromRGB(0,200,255); CStr.Transparency=0.2
    local CTitle=Instance.new("TextLabel",GUI.ComboFrame); CTitle.Size=UDim2.new(1,0,0,14); CTitle.Position=UDim2.new(0,0,0,6)
    CTitle.BackgroundTransparency=1; CTitle.Text="COMBO STREAK"; CTitle.Font=Enum.Font.GothamBold; CTitle.TextSize=8; CTitle.TextColor3=Color3.fromRGB(0,130,180)
    GUI.ComboLbl=Instance.new("TextLabel",GUI.ComboFrame); GUI.ComboLbl.Size=UDim2.new(1,0,0,30); GUI.ComboLbl.Position=UDim2.new(0,0,0,18)
    GUI.ComboLbl.BackgroundTransparency=1; GUI.ComboLbl.Text="0×"; GUI.ComboLbl.Font=Enum.Font.GothamBlack
    GUI.ComboLbl.TextSize=26; GUI.ComboLbl.TextColor3=Color3.fromRGB(0,220,255)
end

local function ApplyGhost(on)
    local char=Plr.Character; if not char then return end
    for _,p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.LocalTransparencyModifier=on and 0.85 or 0; p.CanCollide=not on end)
        end
    end
end

local BallHighlightConn=nil
local function StartBallHighlight()
    if BallHighlightConn then BallHighlightConn:Disconnect() end
    BallHighlightConn=RunService.Heartbeat:Connect(function()
        if not PF.BallHighlight or not PremiumUnlocked then BallHighlightConn:Disconnect(); BallHighlightConn=nil; return end
        local ball=GetBall(); if not ball then return end
        local isTgt=(ball:GetAttribute("target") or "")==Plr.Name
        pcall(function() ball.Material=Enum.Material.Neon; ball.Color=isTgt and Color3.fromRGB(255,50,50) or Color3.fromRGB(80,220,255) end)
    end)
end

local RainbowTrailConn=nil; local RainbowTrailHue=0
local function StartRainbowTrail()
    if RainbowTrailConn then RainbowTrailConn:Disconnect() end
    RainbowTrailConn=RunService.Heartbeat:Connect(function(dt)
        if not PF.RainbowTrail or not PremiumUnlocked then RainbowTrailConn:Disconnect(); RainbowTrailConn=nil; return end
        RainbowTrailHue=(RainbowTrailHue+dt*0.45)%1
        local ball=GetBall(); if not ball then return end
        pcall(function() ball.Color=Color3.fromHSV(RainbowTrailHue,1,1); ball.Material=Enum.Material.Neon end)
    end)
end

local DodgeConn=nil
local function StartAutoDodge()
    if DodgeConn then DodgeConn:Disconnect() end
    DodgeConn=RunService.Heartbeat:Connect(function()
        if not PF.AutoDodge or not PremiumUnlocked then DodgeConn:Disconnect(); DodgeConn=nil; return end
        local ball=GetBall(); if not ball then return end
        local hrp=GetHRP(); if not hrp then return end
        if (ball:GetAttribute("target") or "")~=Plr.Name then return end
        local dist=(hrp.Position-ball.Position).Magnitude
        if dist>10 then return end
        local vel=GetVel(ball); if vel.Magnitude<8 then return end
        local away=(hrp.Position-ball.Position).Unit
        away=Vector3.new(away.X,0,away.Z)
        pcall(function() hrp.CFrame=hrp.CFrame+away*0.55 end)
    end)
end

local function SetPremFPS(on,cap)
    if on then
        pcall(function() setfpscap(cap or 0) end)
        pcall(function() game:GetService("RunService"):Set60FpsThrottleEnabled(false) end)
    else
        pcall(function() setfpscap(60) end)
    end
end

-- ══════════════════════════════════════════════════════════════════
-- ANTI-BLOCK — Requires ball targeting you + blocker in path
-- ══════════════════════════════════════════════════════════════════
local AntiBlockConn=nil
local BLOCK_SIGS={"Forcefield","Guardian","Reaper","Titan","Flash"}

local function StartAntiBlock()
    if AntiBlockConn then AntiBlockConn:Disconnect() end
    local enemyCooldowns = {}
    AntiBlockConn=RunService.Heartbeat:Connect(function()
        if not PF.AntiBlock or not PremiumUnlocked then
            if AntiBlockConn then AntiBlockConn:Disconnect(); AntiBlockConn=nil end; return
        end
        local now=os.clock()
        local hrp=GetHRP(); if not hrp then return end
        local ball=GetBall(); if not ball then return end

        if (ball:GetAttribute("target") or "") ~= Plr.Name then return end

        local ballPos = ball.Position
        local closing = RecentClosingRate(PremH.pos)

        local anyVeryClose = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Plr and p.Character then
                local pHRP = p.Character:FindFirstChild("HumanoidRootPart")
                if pHRP and (hrp.Position - pHRP.Position).Magnitude < 9 then
                    anyVeryClose = true; break
                end
            end
        end
        if closing < 5 and not anyVeryClose then return end

        for _,p in ipairs(Players:GetPlayers()) do
            if p==Plr then continue end
            local char=p.Character; if not char then continue end
            local pHRP=char:FindFirstChild("HumanoidRootPart"); if not pHRP then continue end

            local distToMe = (hrp.Position-pHRP.Position).Magnitude
            if distToMe > 25 then continue end

            local toBall = (ballPos - hrp.Position)
            local toEnemy = (pHRP.Position - hrp.Position)
            local alignment = toBall.Unit:Dot(toEnemy.Unit)
            if alignment < 0.5 then continue end

            local ballToEnemy = (pHRP.Position - ballPos).Magnitude
            if ballToEnemy > 14 then continue end

            if enemyCooldowns[p.Name] and now - enemyCooldowns[p.Name] < 1.2 then continue end

            local found=false
            for _,sig in ipairs(BLOCK_SIGS) do
                pcall(function()
                    for _,v in ipairs(char:GetDescendants()) do
                        if tostring(v.Name):lower():find(sig:lower()) then found=true end
                    end
                end)
                if found then break end
            end

            if found then
                enemyCooldowns[p.Name] = now
                pcall(PremiumFire)
                break
            end
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════
-- PREMIUM GUARD
-- ══════════════════════════════════════════════════════════════════
local function PremGuard(val, label, fn)
    -- No key required anymore
    fn(val)
    task.defer(SavePremSettings)
end
    fn(val)
    task.defer(SavePremSettings)
end

-- ══════════════════════════════════════════════════════════════════
-- CHAT COMMANDS
-- ══════════════════════════════════════════════════════════════════
local ChatCmdSG=Instance.new("ScreenGui"); ChatCmdSG.Name="RyuuChatCmd"
ChatCmdSG.ResetOnSpawn=false; ChatCmdSG.IgnoreGuiInset=true; ChatCmdSG.DisplayOrder=99996
pcall(function() ChatCmdSG.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
if not ChatCmdSG.Parent then pcall(function() ChatCmdSG.Parent=Plr:WaitForChild("PlayerGui") end) end

local CmdQueue={}
local function ShowCmdFeedback(text,col)
    col=col or Color3.fromRGB(0,220,255)
    local lbl=Instance.new("TextLabel",ChatCmdSG)
    lbl.AnchorPoint=Vector2.new(0.5,1); lbl.Position=UDim2.new(0.5,0,1,-90-#CmdQueue*28)
    lbl.Size=UDim2.new(0,340,0,24); lbl.BackgroundColor3=Color3.fromRGB(4,12,22)
    lbl.BackgroundTransparency=0.15; lbl.BorderSizePixel=0
    lbl.Text="◈  "..text; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=11
    lbl.TextColor3=col; lbl.ZIndex=10
    Instance.new("UICorner",lbl).CornerRadius=UDim.new(0,8)
    local stroke=Instance.new("UIStroke",lbl); stroke.Thickness=1.2; stroke.Color=col; stroke.Transparency=0.3
    table.insert(CmdQueue,lbl)
    task.delay(2.5,function()
        TweenService:Create(lbl,TweenInfo.new(0.3),{TextTransparency=1,BackgroundTransparency=1}):Play()
        task.wait(0.35); pcall(function()
            local idx=table.find(CmdQueue,lbl); if idx then table.remove(CmdQueue,idx) end; lbl:Destroy()
        end)
    end)
end

local function HandleCmd(msg)
    msg=msg:lower():match("^%s*(.-)%s*$") or ""
    if msg=="/autoparry" then
        S.AutoParry=not S.AutoParry
        if S.AutoParry then if S.LobbyParry then StopLobbyEngine(); S.LobbyParry=false end; StartEngine()
        else StopEngine() end
        ShowCmdFeedback("Auto Parry → "..(S.AutoParry and "ON ⚡" or "OFF"),S.AutoParry and Color3.fromRGB(50,230,110) or Color3.fromRGB(255,80,80))
        return true
    elseif msg=="/lobbyparry" then
        S.LobbyParry=not S.LobbyParry
        if S.LobbyParry then if S.AutoParry then StopEngine(); S.AutoParry=false end; StartLobbyEngine()
        else StopLobbyEngine() end
        ShowCmdFeedback("Lobby Parry → "..(S.LobbyParry and "ON 🏟" or "OFF"),S.LobbyParry and Color3.fromRGB(50,230,110) or Color3.fromRGB(255,80,80))
        return true
    elseif msg=="/parryoff" then
        S.AutoParry=false; S.LobbyParry=false; P.AutoParry=false; P.LobbyParry=false
        StopEngine(); StopLobbyEngine(); StopPremiumEngine(); StopPremiumLobbyEngine()
        ShowCmdFeedback("All Parry → OFF",Color3.fromRGB(255,80,80)); return true
    elseif msg:match("^/speed%s+") then
        local v=tonumber(msg:match("/speed%s+(%S+)"))
        if v then S.WalkSpeed=math.clamp(v,1,300); local h=Plr.Character and Plr.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=S.WalkSpeed end
            ShowCmdFeedback("Speed → "..S.WalkSpeed,Color3.fromRGB(255,200,50)) end; return true
    elseif msg=="/fullbright" then
        S.Fullbright=not S.Fullbright; SetFB(S.Fullbright)
        ShowCmdFeedback("Fullbright → "..(S.Fullbright and "ON" or "OFF"),Color3.fromRGB(255,230,80)); return true
    elseif msg:match("^/accuracy%s+") then
        local v=tonumber(msg:match("/accuracy%s+(%S+)"))
        if v then S.ParryAccuracy=math.clamp(v,1,100); PremAccuracy=math.clamp(v,1,150)
            ShowCmdFeedback("Accuracy → "..v,Color3.fromRGB(0,220,255)) end; return true
    elseif msg:match("^/offset%s+") then
        local v=tonumber(msg:match("/offset%s+(%S+)"))
        if v then S.EarlyOffset=math.clamp(v,-5,10); P.EarlyOffset=S.EarlyOffset
            ShowCmdFeedback("Early Offset → "..S.EarlyOffset,Color3.fromRGB(0,220,255)) end; return true
    elseif msg=="/desync" then
        DS.active=not DS.active
        if DS.active then StartDesync() else StopDesync() end
        ShowCmdFeedback("Desync → "..(DS.active and "ON 👻" or "OFF"),DS.active and Color3.fromRGB(180,80,255) or Color3.fromRGB(255,80,80)); return true
    elseif msg=="/help" then
        ShowCmdFeedback("/autoparry  /lobbyparry  /parryoff  /speed N  /accuracy N  /offset N  /fullbright  /desync",Color3.fromRGB(0,200,255)); return true
    end
    return false
end

task.spawn(function()
    task.wait(2)
    pcall(function()
        local TCS=game:GetService("TextChatService")
        if TCS and TCS.SendingMessage then
            TCS.SendingMessage:Connect(function(props)
                if HandleCmd(props.Text) then props.Text="" end
            end)
            return
        end
    end)
    pcall(function()
        local gui=Plr:WaitForChild("PlayerGui",3); if not gui then return end
        local function hookTB(tb)
            if not tb or not tb:IsA("TextBox") then return end
            tb.FocusLost:Connect(function(enter)
                if enter then HandleCmd(tb.Text) end
            end)
        end
        for _,v in ipairs(gui:GetDescendants()) do hookTB(v) end
        gui.DescendantAdded:Connect(hookTB)
    end)
    ShowCmdFeedback("Chat Commands Ready  /help for list",Color3.fromRGB(0,200,255))
end)

-- ══════════════════════════════════════════════════════════════════
-- RAYFIELD UI
-- ══════════════════════════════════════════════════════════════════
local W = Rayfield:CreateWindow({
    Name="hiruZ UI — Upgraded",
    LoadingTitle="hiruZ UI",
    LoadingSubtitle="",
    Theme="Default",
    DisableRayfieldPrompts=false,
    DisableBuildWarnings=false,
    ConfigurationSaving={Enabled=true,FolderName="RyuuV2",FileName="Config"},
    KeySystem=false,
})

-- ── TAB 1: AUTO PARRY ────────────────────────────────────────────
local T1=W:CreateTab("⚔ Auto Parry",nil)
T1:CreateSection("Game Auto Parry")
T1:CreateToggle({Name="Auto Parry",CurrentValue=false,Flag="AP",Callback=function(v)
    S.AutoParry=v
    if v then if S.LobbyParry then StopLobbyEngine(); S.LobbyParry=false end; StartEngine()
    else StopEngine() end
end})
T1:CreateToggle({Name="Auto Face Ball",CurrentValue=false,Flag="AF",Callback=function(v) S.AutoFace=v end})
T1:CreateDivider()
T1:CreateSection("🏟 Lobby Auto Parry")
T1:CreateLabel("Same engine — use in lobby waiting areas.")
T1:CreateToggle({Name="Lobby Auto Parry",CurrentValue=false,Flag="LAP",Callback=function(v)
    S.LobbyParry=v
    if v then if S.AutoParry then StopEngine(); S.AutoParry=false end; StartLobbyEngine()
    else StopLobbyEngine() end
end})
T1:CreateDivider()
T1:CreateSection("🎯 Parry Accuracy")
T1:CreateLabel("100 = machine precision  ·  Lower = human-like variance")
T1:CreateSlider({Name="Parry Accuracy",Range={1,100},Increment=1,CurrentValue=100,Flag="PA",Callback=function(v)
    S.ParryAccuracy=v
    local tier=v>=95 and "PERFECT" or v>=80 and "Elite" or v>=60 and "Balanced" or "Human"
    Rayfield:Notify({Title="Accuracy: "..v.."  —  "..tier,Content="",Duration=2,Image=4483362458})
end})
T1:CreateDivider()
T1:CreateSection("📡 Ping Compensation")
T1:CreateLabel("Auto-tuned. Scale adjusts the ping multiplier.")
T1:CreateSlider({Name="Ping Scale",Range={0,1},Increment=0.05,Suffix="x",CurrentValue=0.5,Flag="PCS",
    Callback=function(v) PingScale=v end})
T1:CreateDivider()
T1:CreateSection("⏱ Parry Reset Window")
T1:CreateSlider({Name="Parry Reset",Range={0.05,0.40},Increment=0.01,Suffix="s",CurrentValue=0.16,Flag="PR",
    Callback=function(v) S.ParryReset=v end})
T1:CreateDivider()
T1:CreateSection("⚡ Early Offset")
T1:CreateLabel("Positive = fire earlier  ·  Negative = fire later  ·  Default 0")
T1:CreateSlider({Name="Early Offset",Range={-3,8},Increment=0.5,CurrentValue=0,Flag="EO",
    Callback=function(v) S.EarlyOffset=v; P.EarlyOffset=v end})
T1:CreateDivider()
T1:CreateSection("💬 Chat Commands")
T1:CreateLabel("/autoparry  /lobbyparry  /parryoff  /speed N  /accuracy N  /offset N  /fullbright  /desync  /help  ·  Manual Spam: E key")
T1:CreateButton({Name="⚡ Open Manual Spam Widget",Callback=function()
    if _G.RyuuOpenManualSpam then _G.RyuuOpenManualSpam() end
end})

-- ── MANUAL SPAM WIDGET ────────────────────────────────────────────
do
    local MSOn=false; local MSThr=nil
    local MSSG=Instance.new("ScreenGui"); MSSG.Name="RyuuManualSpam"
    MSSG.ResetOnSpawn=false; MSSG.IgnoreGuiInset=true; MSSG.DisplayOrder=9995; MSSG.Enabled=false
    pcall(function() MSSG.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
    if not MSSG.Parent then MSSG.Parent=Plr:WaitForChild("PlayerGui") end

    local MSCard=Instance.new("TextButton",MSSG); MSCard.AnchorPoint=Vector2.new(0.5,0.5)
    MSCard.Size=UDim2.new(0,188,0,64); MSCard.Position=UDim2.new(0.5,0,0.5,0)
    MSCard.BackgroundColor3=Color3.fromRGB(10,7,22); MSCard.BorderSizePixel=0
    MSCard.Text=""; MSCard.AutoButtonColor=false; MSCard.Active=true
    Instance.new("UICorner",MSCard).CornerRadius=UDim.new(0,18)
    local MSStroke=Instance.new("UIStroke",MSCard); MSStroke.Thickness=1.8; MSStroke.Color=Color3.fromRGB(75,45,155); MSStroke.Transparency=0.05
    local Tit=Instance.new("TextLabel",MSCard); Tit.Size=UDim2.new(1,-50,0,20); Tit.Position=UDim2.new(0,14,0,8)
    Tit.BackgroundTransparency=1; Tit.Text="⚡  MANUAL SPAM"; Tit.Font=Enum.Font.GothamBold; Tit.TextSize=13
    Tit.TextColor3=Color3.fromRGB(190,170,245); Tit.TextXAlignment=Enum.TextXAlignment.Left
    local Sub=Instance.new("TextLabel",MSCard); Sub.Size=UDim2.new(1,-50,0,14); Sub.Position=UDim2.new(0,14,0,30)
    Sub.BackgroundTransparency=1; Sub.Text="OFF  ·  Press E to toggle"; Sub.Font=Enum.Font.Gotham; Sub.TextSize=10
    Sub.TextColor3=Color3.fromRGB(110,90,190); Sub.TextXAlignment=Enum.TextXAlignment.Left
    local Close2=Instance.new("TextButton",MSCard); Close2.Size=UDim2.new(0,20,0,20); Close2.Position=UDim2.new(1,-24,0,6)
    Close2.BackgroundTransparency=1; Close2.Text="✕"; Close2.Font=Enum.Font.GothamBold; Close2.TextSize=13; Close2.TextColor3=Color3.fromRGB(130,110,190)

    local dragging,dragStart,startPos=false,nil,nil
    MSCard.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=input.Position; startPos=MSCard.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement then
            local delta=input.Position-dragStart
            local vs=Cam.ViewportSize
            MSCard.Position=UDim2.new(startPos.X.Scale,math.clamp(startPos.X.Offset+delta.X,-200,vs.X-20),startPos.Y.Scale,math.clamp(startPos.Y.Offset+delta.Y,-100,vs.Y-80))
        end
    end)
    UIS.InputEnded:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)

    local function doStart() if MSThr then return end; MSThr=RunService.Heartbeat:Connect(function()
        if not MSOn then MSThr:Disconnect(); MSThr=nil; return end
        pcall(function()
            VIM:SendKeyEvent(true,  Enum.KeyCode.F, false, game)
            VIM:SendKeyEvent(false, Enum.KeyCode.F, false, game)
        end)
    end) end
    local function doStop() MSOn=false; if MSThr then MSThr:Disconnect(); MSThr=nil end end
    local function toggle()
        MSOn=not MSOn; Sub.Text=MSOn and "ON  ·  SPAMMING" or "OFF  ·  Press E to toggle"
        MSStroke.Color=MSOn and Color3.fromRGB(35,215,85) or Color3.fromRGB(75,45,155)
        MSCard.BackgroundColor3=MSOn and Color3.fromRGB(8,30,12) or Color3.fromRGB(10,7,22)
        if MSOn then doStart() else doStop() end
    end
    UIS.InputBegan:Connect(function(input) if input.KeyCode==Enum.KeyCode.E and MSSG.Enabled then toggle() end end)
    MSCard.MouseButton1Click:Connect(toggle)
    Close2.MouseButton1Click:Connect(function() doStop(); MSSG.Enabled=false end)
    _G.RyuuOpenManualSpam=function()
        MSSG.Enabled=true
        MSCard.Position=UDim2.new(0.5,0,1.3,0)
        TweenService:Create(MSCard,TweenInfo.new(0.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Position=UDim2.new(0.5,0,0.5,0)}):Play()
    end
end

-- ── TAB 2: VISUALS ────────────────────────────────────────────────
local T3=W:CreateTab("🎨 Visuals",nil)
T3:CreateSection("Ball ESP")
T3:CreateToggle({Name="Ball ESP",CurrentValue=false,Flag="ESP",Callback=function(v) S.BallESP=v; if v then StartESP() else CleanESP() end end})
T3:CreateDivider()
T3:CreateSection("🏹 Ball Velocity Arrow")
T3:CreateLabel("Yellow = neutral  ·  Red = targeting you")
T3:CreateToggle({Name="Ball Velocity Arrow",CurrentValue=false,Flag="BVA",Callback=function(v)
    PF.VelArrow=v
    if v then VelArrowActive=true; BuildVelArrow()
        Rayfield:Notify({Title="🏹 Velocity Arrow ON",Content="",Duration=2,Image=4483362458})
    else VelArrowActive=false; if VelArrowSG then pcall(function() VelArrowSG:Destroy() end); VelArrowSG=nil end end
end})
T3:CreateDivider()
T3:CreateSection("Lighting")
T3:CreateToggle({Name="Fullbright",CurrentValue=false,Flag="FB",Callback=function(v) S.Fullbright=v; SetFB(v) end})
T3:CreateDivider()
T3:CreateSection("Camera")
T3:CreateSlider({Name="Field of View",Range={30,120},Increment=1,Suffix="°",CurrentValue=70,Flag="FOV",Callback=function(v) Cam.FieldOfView=v end})
T3:CreateDivider()
T3:CreateSection("🔮 Ability ESP")
T3:CreateToggle({Name="Ability ESP",CurrentValue=false,Flag="AESP",Callback=function(v)
    S.AbilityESP=v; if v then StartAbilityESP() else CleanAbilityESP() end
end})
T3:CreateDivider()
T3:CreateSection("⚡ Ability Detector (Free)")
T3:CreateToggle({Name="Ability Detector",CurrentValue=false,Flag="ADET",Callback=function(v)
    if v then StartAbilDetect() else StopAbilDetect() end
end})

-- ── TAB 3: PLAYER ─────────────────────────────────────────────────
local T4=W:CreateTab("🧍 Player",nil)
T4:CreateSection("Movement")
T4:CreateSlider({Name="Walk Speed",Range={16,150},Increment=1,CurrentValue=16,Flag="WS",Callback=function(v)
    S.WalkSpeed=v; local h=Plr.Character and Plr.Character:FindFirstChildOfClass("Humanoid"); if h then h.WalkSpeed=v end
end})
T4:CreateSlider({Name="Jump Power",Range={50,500},Increment=5,CurrentValue=50,Flag="JP",Callback=function(v)
    S.JumpPower=v; local h=Plr.Character and Plr.Character:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower=v end
end})
T4:CreateDivider()
T4:CreateSection("Abilities")
T4:CreateToggle({Name="Infinity Jump",CurrentValue=false,Flag="IJ",Callback=function(v) S.InfJump=v; if v then StartIJ() end end})
T4:CreateToggle({Name="Noclip",CurrentValue=false,Flag="NC",Callback=function(v)
    S.Noclip=v
    if not v then local c=Plr.Character; if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=true end end end
    else StartNoclip() end
end})

-- ── TAB 4: SWORD ─────────────────────────────────────────────────
local T6=W:CreateTab("⚔ Sword",nil)
T6:CreateSection("Sword Color  ◈  Client-Side")
T6:CreateDropdown({
    Name="Sword Color",
    Options={"Default","Gold","Shadow Black","Crystal Blue","Crimson","Ghost White","Neon Purple","Emerald","Rose Gold","Obsidian","Cyan","Orange","Rainbow"},
    CurrentOption={"Default"},MultipleOptions=false,Flag="SWSK",
    Callback=function(v)
        local name=type(v)=="table" and v[1] or tostring(v)
        ApplySwordPreset(name)
        Rayfield:Notify({Title="Sword ◈ "..name,Content="Applied!",Duration=2,Image=4483362458})
    end})
T6:CreateButton({Name="⚔ Apply Now",Callback=function()
    local _,parts=GetSwordParts()
    if #parts>0 then ApplySwordPreset(CurrentSwordPreset); Rayfield:Notify({Title="Applied: "..CurrentSwordPreset,Content="",Duration=2,Image=4483362458})
    else Rayfield:Notify({Title="No sword equipped",Content="Equip your sword first.",Duration=2,Image=4483362458}) end
end})

-- ── TAB 5: DESYNC ─────────────────────────────────────────────────
local TDesync=W:CreateTab("🌀 Desync",nil)
TDesync:CreateSection("👻 Ghost Desync  ·  V2 Upgraded")
TDesync:CreateLabel("3-layer system: micro-jitter + phase drift + network velocity noise. No teleports = no sticking or floating.")
TDesync:CreateDivider()
TDesync:CreateToggle({Name="Enable Desync",CurrentValue=false,Flag="DSYNC",Callback=function(v)
    DS.active=v
    if v then StartDesync(); Rayfield:Notify({Title="👻 Desync ACTIVE",Content="Micro-jitter + phase drift + net noise running.",Duration=4,Image=4483362458})
    else StopDesync(); Rayfield:Notify({Title="👻 Desync OFF",Content="Clean physics restore applied.",Duration=2,Image=4483362458}) end
end})
TDesync:CreateDivider()
TDesync:CreateSection("🎚 Desync Strength")
TDesync:CreateLabel("0.1 = barely noticeable  ·  0.5 = balanced  ·  1.0 = maximum  ·  Default 0.55")
TDesync:CreateSlider({Name="Desync Strength",Range={0.1,1.0},Increment=0.05,CurrentValue=0.55,Flag="DSS",Callback=function(v)
    DS.strength=v
    Rayfield:Notify({Title="Desync Strength → "..v,Content=v<0.4 and "Subtle" or v<0.7 and "Balanced" or "Aggressive",Duration=2,Image=4483362458})
end})
TDesync:CreateLabel("Tip: Use /desync in chat to toggle quickly.")

-- ══════════════════════════════════════════════════════════════════
-- PREMIUM TAB
-- ══════════════════════════════════════════════════════════════════
local PT=W:CreateTab("✨ Premium",nil)
PT:CreateSection("🔑 Premium Key Scanner")
PT:CreateButton({Name="◈ Open Holographic Scanner",Callback=function()
    task.spawn(function()
        pcall(function()
            for _,g in ipairs(CoreGui:GetChildren()) do if g.Name=="RyuuKeyScanner" then g:Destroy() end end
        end)

        local KSG=Instance.new("ScreenGui"); KSG.Name="RyuuKeyScanner"; KSG.ResetOnSpawn=false
        KSG.IgnoreGuiInset=true; KSG.DisplayOrder=100000
        pcall(function() KSG.Parent=(typeof(gethui)=="function" and gethui()) or CoreGui end)
        if not KSG.Parent then pcall(function() KSG.Parent=Plr:WaitForChild("PlayerGui") end) end

        local ScanDebris=game:GetService("Debris")
        local vs2 = Cam and Cam.ViewportSize or Vector2.new(1920,1080)

        local function playSound2(id,vol,pitch)
            pcall(function()
                local s=Instance.new("Sound",workspace); s.SoundId="rbxassetid://"..tostring(id)
                s.Volume=vol or 0.6; s.PlaybackSpeed=pitch or 1; s.RollOffMaxDistance=0; s:Play(); ScanDebris:AddItem(s,6)
            end)
        end

        -- ── BG overlay with noise-like gradient ──────────────────
        local Overlay=Instance.new("Frame",KSG); Overlay.Size=UDim2.new(1,0,1,0)
        Overlay.BackgroundColor3=Color3.fromRGB(2,0,10); Overlay.BackgroundTransparency=1; Overlay.ZIndex=1
        local OvGrad=Instance.new("UIGradient",Overlay)
        OvGrad.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(8,0,24)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(2,0,10)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,4,20)),
        }
        OvGrad.Rotation=120
        TweenService:Create(Overlay,TweenInfo.new(0.6,Enum.EasingStyle.Sine),{BackgroundTransparency=0.28}):Play()

        -- ── Matrix rain columns ───────────────────────────────────
        local RainContainer=Instance.new("Frame",KSG); RainContainer.Size=UDim2.new(1,0,1,0)
        RainContainer.BackgroundTransparency=1; RainContainer.ZIndex=2; RainContainer.ClipsDescendants=true
        local RAIN_CHARS="01◈龍竜炎力神速剣刃斬波雷光闇鬼天ABCDEF"
        local rainDrops={}; local rainActive=true
        local colCount=math.floor(vs2.X/16)
        for col=1,colCount do
            local trailLen=math.random(4,12)
            for t=1,trailLen do
                local drop=Instance.new("TextLabel",RainContainer)
                drop.Size=UDim2.new(0,14,0,14); drop.BackgroundTransparency=1
                drop.Font=Enum.Font.Code; drop.TextSize=10; drop.ZIndex=3
                local bright=t==trailLen and 1.0 or (t/trailLen)*0.6
                drop.TextColor3=Color3.fromRGB(math.floor(120*bright),0,math.floor(255*bright))
                drop.BackgroundTransparency=1
                drop.Text=RAIN_CHARS:sub(math.random(1,#RAIN_CHARS),math.random(1,#RAIN_CHARS))
                drop.Position=UDim2.new(0,col*16,0,math.random(-vs2.Y,0) - t*14)
                table.insert(rainDrops,{lbl=drop,speed=math.random(3,9)+t*0.4,col=col,offset=t*14,bright=bright})
            end
        end
        task.spawn(function()
            while rainActive do
                for _,d in ipairs(rainDrops) do
                    pcall(function()
                        local py=d.lbl.Position.Y.Offset+d.speed
                        if py>vs2.Y+20 then py=-math.random(60,vs2.Y) end
                        d.lbl.Position=UDim2.new(0,d.col*16,0,py)
                        if math.random()<0.08 then
                            d.lbl.Text=RAIN_CHARS:sub(math.random(1,#RAIN_CHARS),math.random(1,#RAIN_CHARS))
                        end
                    end)
                end
                task.wait(0.035)
            end
            for _,d in ipairs(rainDrops) do pcall(function() d.lbl:Destroy() end) end
        end)

        -- ── DNA Helix on left side ─────────────────────────────────
        local HelixContainer=Instance.new("Frame",KSG)
        HelixContainer.Size=UDim2.new(0,60,0,360); HelixContainer.Position=UDim2.new(0,32,0.5,-180)
        HelixContainer.BackgroundTransparency=1; HelixContainer.ZIndex=5; HelixContainer.ClipsDescendants=true
        local helixNodes={}; local helixActive=true; local helixT=0
        local NODE_COUNT=18; local HELIX_H=360
        for i=1,NODE_COUNT do
            local nodeA=Instance.new("Frame",HelixContainer)
            nodeA.AnchorPoint=Vector2.new(0.5,0.5); nodeA.Size=UDim2.new(0,7,0,7)
            nodeA.BackgroundColor3=Color3.fromRGB(200,60,255); nodeA.BorderSizePixel=0; nodeA.ZIndex=6
            Instance.new("UICorner",nodeA).CornerRadius=UDim.new(1,0)
            local nodeB=Instance.new("Frame",HelixContainer)
            nodeB.AnchorPoint=Vector2.new(0.5,0.5); nodeB.Size=UDim2.new(0,7,0,7)
            nodeB.BackgroundColor3=Color3.fromRGB(255,80,0); nodeB.BorderSizePixel=0; nodeB.ZIndex=6
            Instance.new("UICorner",nodeB).CornerRadius=UDim.new(1,0)
            local rung=Instance.new("Frame",HelixContainer)
            rung.AnchorPoint=Vector2.new(0.5,0.5); rung.Size=UDim2.new(0,44,0,2)
            rung.BackgroundColor3=Color3.fromRGB(80,40,160); rung.BorderSizePixel=0; rung.ZIndex=5
            table.insert(helixNodes,{a=nodeA,b=nodeB,r=rung,idx=i})
        end
        task.spawn(function()
            while helixActive do
                helixT=helixT+0.04
                for _,n in ipairs(helixNodes) do
                    local phase=(n.idx/NODE_COUNT)*math.pi*2 + helixT
                    local y=((n.idx-1)/NODE_COUNT)*HELIX_H
                    local xA=30+math.cos(phase)*24
                    local xB=30-math.cos(phase)*24
                    local scale=math.abs(math.cos(phase))*0.5+0.5
                    pcall(function()
                        n.a.Position=UDim2.new(0,xA,0,y)
                        n.b.Position=UDim2.new(0,xB,0,y)
                        n.r.Position=UDim2.new(0,30,0,y)
                        n.r.Size=UDim2.new(0,math.abs(xA-xB),0,2)
                        n.r.BackgroundTransparency=0.2+scale*0.6
                        n.a.BackgroundColor3=Color3.fromHSV((helixT*0.08+n.idx*0.055)%1,0.9,1.0)
                        n.b.BackgroundColor3=Color3.fromHSV((helixT*0.08+n.idx*0.055+0.5)%1,0.9,1.0)
                    end)
                end
                task.wait(0.022)
            end
        end)

        -- ── DNA Helix on right side (mirrored) ─────────────────────
        local HelixContainerR=Instance.new("Frame",KSG)
        HelixContainerR.Size=UDim2.new(0,60,0,360); HelixContainerR.Position=UDim2.new(1,-92,0.5,-180)
        HelixContainerR.BackgroundTransparency=1; HelixContainerR.ZIndex=5; HelixContainerR.ClipsDescendants=true
        local helixNodesR={}
        for i=1,NODE_COUNT do
            local nodeA=Instance.new("Frame",HelixContainerR)
            nodeA.AnchorPoint=Vector2.new(0.5,0.5); nodeA.Size=UDim2.new(0,7,0,7)
            nodeA.BackgroundColor3=Color3.fromRGB(0,200,255); nodeA.BorderSizePixel=0; nodeA.ZIndex=6
            Instance.new("UICorner",nodeA).CornerRadius=UDim.new(1,0)
            local nodeB=Instance.new("Frame",HelixContainerR)
            nodeB.AnchorPoint=Vector2.new(0.5,0.5); nodeB.Size=UDim2.new(0,7,0,7)
            nodeB.BackgroundColor3=Color3.fromRGB(80,255,140); nodeB.BorderSizePixel=0; nodeB.ZIndex=6
            Instance.new("UICorner",nodeB).CornerRadius=UDim.new(1,0)
            local rung=Instance.new("Frame",HelixContainerR)
            rung.AnchorPoint=Vector2.new(0.5,0.5); rung.Size=UDim2.new(0,44,0,2)
            rung.BackgroundColor3=Color3.fromRGB(0,100,160); rung.BorderSizePixel=0; rung.ZIndex=5
            table.insert(helixNodesR,{a=nodeA,b=nodeB,r=rung,idx=i})
        end
        task.spawn(function()
            while helixActive do
                for _,n in ipairs(helixNodesR) do
                    local phase=(n.idx/NODE_COUNT)*math.pi*2 - helixT
                    local y=((n.idx-1)/NODE_COUNT)*360
                    local xA=30+math.cos(phase)*24
                    local xB=30-math.cos(phase)*24
                    pcall(function()
                        n.a.Position=UDim2.new(0,xA,0,y)
                        n.b.Position=UDim2.new(0,xB,0,y)
                        n.r.Position=UDim2.new(0,30,0,y)
                        n.r.Size=UDim2.new(0,math.abs(xA-xB),0,2)
                        n.a.BackgroundColor3=Color3.fromHSV((helixT*0.08+n.idx*0.055+0.33)%1,0.9,1.0)
                        n.b.BackgroundColor3=Color3.fromHSV((helixT*0.08+n.idx*0.055+0.67)%1,0.9,1.0)
                    end)
                end
                task.wait(0.022)
            end
        end)

        -- ── Main scanner card ─────────────────────────────────────
        local ScanCard=Instance.new("Frame",KSG)
        ScanCard.AnchorPoint=Vector2.new(0.5,0.5); ScanCard.Position=UDim2.new(0.5,0,0.5,0)
        ScanCard.Size=UDim2.new(0,0,0,0); ScanCard.BackgroundColor3=Color3.fromRGB(4,2,14)
        ScanCard.BackgroundTransparency=0.06; ScanCard.ZIndex=12
        Instance.new("UICorner",ScanCard).CornerRadius=UDim.new(0,18)

        local cardStroke=Instance.new("UIStroke",ScanCard)
        cardStroke.Thickness=2.4; cardStroke.Color=Color3.fromRGB(160,40,255); cardStroke.Transparency=0.05

        -- Stroke color cycle
        local scanStrokeActive=true
        task.spawn(function()
            local t=0
            while scanStrokeActive and ScanCard.Parent do
                t=t+0.012
                pcall(function() cardStroke.Color=Color3.fromHSV((t*0.4)%1,0.95,1.0) end)
                task.wait(0.05)
            end
        end)

        -- Top gradient accent
        local TopStripe=Instance.new("Frame",ScanCard); TopStripe.Size=UDim2.new(1,0,0,3)
        TopStripe.Position=UDim2.new(0,0,0,0); TopStripe.BorderSizePixel=0; TopStripe.ZIndex=13
        Instance.new("UICorner",TopStripe).CornerRadius=UDim.new(0,18)
        local TSGrad=Instance.new("UIGradient",TopStripe)
        TSGrad.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,60,0)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(200,0,255)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0,180,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(80,255,140)),
        }

        -- Header
        local Header=Instance.new("TextLabel",ScanCard)
        Header.Size=UDim2.new(1,-80,0,34); Header.Position=UDim2.new(0,28,0,14)
        Header.BackgroundTransparency=1; Header.Font=Enum.Font.GothamBlack
        Header.TextSize=18; Header.TextXAlignment=Enum.TextXAlignment.Left; Header.ZIndex=14
        local HGrad=Instance.new("UIGradient",Header)
        HGrad.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,80,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,60,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
        }
        Header.Text="RYUU HUB V2  ◈  PREMIUM"

        -- Subtitle
        local SubHeader=Instance.new("TextLabel",ScanCard)
        SubHeader.Size=UDim2.new(1,-80,0,16); SubHeader.Position=UDim2.new(0,28,0,42)
        SubHeader.BackgroundTransparency=1; SubHeader.Font=Enum.Font.Code; SubHeader.TextSize=10
        SubHeader.TextColor3=Color3.fromRGB(100,60,200); SubHeader.TextXAlignment=Enum.TextXAlignment.Left
        SubHeader.ZIndex=14; SubHeader.Text="BIOMETRIC AUTHORIZATION TERMINAL  ·  SYS:READY"

        -- Glitch subtitle animation
        task.spawn(function()
            local glitchChars="!@#$%^&*<>/?|◈▲★◇▸"
            local baseText="BIOMETRIC AUTHORIZATION TERMINAL  ·  SYS:READY"
            while SubHeader.Parent do
                task.wait(math.random()*3+1.5)
                for _ = 1,3 do
                    local corrupted=""
                    for ci=1,#baseText do
                        if math.random()<0.12 then
                            corrupted=corrupted..glitchChars:sub(math.random(1,#glitchChars),math.random(1,#glitchChars))
                        else
                            corrupted=corrupted..baseText:sub(ci,ci)
                        end
                    end
                    pcall(function() SubHeader.Text=corrupted end)
                    task.wait(0.06)
                end
                pcall(function() SubHeader.Text=baseText end)
            end
        end)

        -- Divider
        local CDivider=Instance.new("Frame",ScanCard); CDivider.Size=UDim2.new(1,-56,0,1); CDivider.Position=UDim2.new(0,28,0,64)
        CDivider.BackgroundColor3=Color3.fromRGB(80,20,160); CDivider.BorderSizePixel=0; CDivider.ZIndex=13

        -- Input label with blinking cursor indicator
        local InputLabel=Instance.new("TextLabel",ScanCard); InputLabel.Size=UDim2.new(1,-56,0,14); InputLabel.Position=UDim2.new(0,28,0,72)
        InputLabel.BackgroundTransparency=1; InputLabel.Font=Enum.Font.GothamBlack; InputLabel.TextSize=9
        InputLabel.TextColor3=Color3.fromRGB(160,60,255); InputLabel.TextXAlignment=Enum.TextXAlignment.Left; InputLabel.ZIndex=14
        InputLabel.Text="▸  AUTHORIZATION KEY  —  ENTER CODE BELOW"

        -- Key slot container
        local SlotContainer=Instance.new("Frame",ScanCard); SlotContainer.Size=UDim2.new(1,-56,0,38); SlotContainer.Position=UDim2.new(0,28,0,88)
        SlotContainer.BackgroundColor3=Color3.fromRGB(4,2,18); SlotContainer.BackgroundTransparency=0.05; SlotContainer.BorderSizePixel=0; SlotContainer.ZIndex=14
        Instance.new("UICorner",SlotContainer).CornerRadius=UDim.new(0,10)
        local SlotStroke=Instance.new("UIStroke",SlotContainer); SlotStroke.Thickness=1.6; SlotStroke.Color=Color3.fromRGB(120,40,255); SlotStroke.Transparency=0.2

        local SLOT_COUNT=22; local slotCells={}
        for i=1,SLOT_COUNT do
            local cell=Instance.new("Frame",SlotContainer)
            cell.AnchorPoint=Vector2.new(0,0.5); cell.Position=UDim2.new((i-1)/SLOT_COUNT,2,0.5,0)
            cell.Size=UDim2.new(1/SLOT_COUNT,-3,0,22); cell.BackgroundColor3=Color3.fromRGB(8,2,28)
            cell.BackgroundTransparency=0.3; cell.BorderSizePixel=0; cell.ZIndex=15
            Instance.new("UICorner",cell).CornerRadius=UDim.new(0,4)
            local cellChar=Instance.new("TextLabel",cell); cellChar.Size=UDim2.new(1,0,1,0); cellChar.BackgroundTransparency=1
            cellChar.Text="·"; cellChar.Font=Enum.Font.Code; cellChar.TextSize=11; cellChar.TextColor3=Color3.fromRGB(50,20,100); cellChar.ZIndex=16
            slotCells[i]={frame=cell,lbl=cellChar}
        end

        -- Cursor blink
        local Cursor=Instance.new("Frame",SlotContainer); Cursor.AnchorPoint=Vector2.new(0,0.5); Cursor.Size=UDim2.new(0,2,0,24); Cursor.Position=UDim2.new(0,3,0.5,0)
        Cursor.BackgroundColor3=Color3.fromRGB(180,60,255); Cursor.BorderSizePixel=0; Cursor.ZIndex=17
        task.spawn(function() while Cursor.Parent do pcall(function() Cursor.BackgroundTransparency=0 end); task.wait(0.45); pcall(function() Cursor.BackgroundTransparency=1 end); task.wait(0.45) end end)

        -- Hidden text input
        local HiddenInput=Instance.new("TextBox",ScanCard); HiddenInput.Size=UDim2.new(1,-56,0,38); HiddenInput.Position=UDim2.new(0,28,0,88)
        HiddenInput.BackgroundTransparency=1; HiddenInput.Text=""; HiddenInput.TextTransparency=1
        HiddenInput.PlaceholderText=""; HiddenInput.Font=Enum.Font.Code; HiddenInput.TextSize=11
        HiddenInput.ClearTextOnFocus=false; HiddenInput.ZIndex=18; HiddenInput.TextColor3=Color3.fromRGB(0,0,0)

        local function UpdateSlots(text)
            local len=math.min(#text,SLOT_COUNT)
            for i=1,SLOT_COUNT do
                local cell=slotCells[i]
                if i<=len then
                    local ch=text:sub(i,i)
                    local hue=(i/SLOT_COUNT)*0.72
                    cell.lbl.Text=ch; cell.lbl.TextColor3=Color3.fromHSV(hue,1,1)
                    cell.frame.BackgroundColor3=Color3.fromHSV(hue,0.85,0.22); cell.frame.BackgroundTransparency=0.05
                    local cs=Instance.new("UIStroke",cell.frame); cs.Thickness=0.8
                    cs.Color=Color3.fromHSV(hue,1,1); cs.Transparency=0.2
                else
                    cell.lbl.Text="·"; cell.lbl.TextColor3=Color3.fromRGB(40,16,80)
                    cell.frame.BackgroundColor3=Color3.fromRGB(8,2,28); cell.frame.BackgroundTransparency=0.3
                end
            end
            local cursorCell=math.min(len+1,SLOT_COUNT)
            Cursor.Position=UDim2.new((cursorCell-1)/SLOT_COUNT,3,0.5,0)
        end
        HiddenInput:GetPropertyChangedSignal("Text"):Connect(function() UpdateSlots(HiddenInput.Text) end)

        -- Biometric scan bar (sweeps across after verify)
        local ScanBarOuter=Instance.new("Frame",ScanCard); ScanBarOuter.Size=UDim2.new(1,-56,0,2); ScanBarOuter.Position=UDim2.new(0,28,0,130)
        ScanBarOuter.BackgroundColor3=Color3.fromRGB(20,8,60); ScanBarOuter.BorderSizePixel=0; ScanBarOuter.ZIndex=14
        Instance.new("UICorner",ScanBarOuter).CornerRadius=UDim.new(1,0)
        local ScanBarFill=Instance.new("Frame",ScanBarOuter); ScanBarFill.Size=UDim2.new(0,0,1,0)
        ScanBarFill.BackgroundColor3=Color3.fromRGB(160,60,255); ScanBarFill.BorderSizePixel=0; ScanBarFill.ZIndex=15
        Instance.new("UICorner",ScanBarFill).CornerRadius=UDim.new(1,0)
        local ScanBarGrad=Instance.new("UIGradient",ScanBarFill)
        ScanBarGrad.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color3.fromRGB(255,60,0)),
            ColorSequenceKeypoint.new(0.5,Color3.fromRGB(200,0,255)),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(0,200,255)),
        }

        -- Status text
        local Status=Instance.new("TextLabel",ScanCard); Status.Size=UDim2.new(1,-56,0,18); Status.Position=UDim2.new(0,28,0,136)
        Status.BackgroundTransparency=1; Status.Text="◈  Awaiting authorization sequence..."
        Status.Font=Enum.Font.GothamBold; Status.TextSize=11; Status.TextColor3=Color3.fromRGB(140,50,255)
        Status.TextXAlignment=Enum.TextXAlignment.Left; Status.ZIndex=14

        -- Device fingerprint
        local DeviceLabel=Instance.new("TextLabel",ScanCard); DeviceLabel.Size=UDim2.new(1,-56,0,13); DeviceLabel.Position=UDim2.new(0,28,0,155)
        DeviceLabel.BackgroundTransparency=1; DeviceLabel.Font=Enum.Font.Code; DeviceLabel.TextSize=9
        DeviceLabel.TextColor3=Color3.fromRGB(60,30,120); DeviceLabel.TextXAlignment=Enum.TextXAlignment.Left; DeviceLabel.ZIndex=14
        pcall(function() DeviceLabel.Text="HWID  ·  "..GetDeviceID():sub(1,26).."..." end)

        -- Verify button with gradient
        local VerifyBtn=Instance.new("TextButton",ScanCard); VerifyBtn.Size=UDim2.new(1,-56,0,42); VerifyBtn.Position=UDim2.new(0,28,0,174)
        VerifyBtn.BackgroundColor3=Color3.fromRGB(60,0,140); VerifyBtn.BorderSizePixel=0
        VerifyBtn.Text=""; VerifyBtn.ZIndex=14
        Instance.new("UICorner",VerifyBtn).CornerRadius=UDim.new(0,10)
        local btnStroke=Instance.new("UIStroke",VerifyBtn); btnStroke.Thickness=1.8; btnStroke.Color=Color3.fromRGB(180,60,255); btnStroke.Transparency=0.1
        local BtnGrad=Instance.new("UIGradient",VerifyBtn)
        BtnGrad.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(80,0,180)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(140,0,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(80,0,180)),
        }
        local BtnLbl=Instance.new("TextLabel",VerifyBtn); BtnLbl.Size=UDim2.new(1,0,1,0)
        BtnLbl.BackgroundTransparency=1; BtnLbl.Text="◈   INITIATE BIOMETRIC SCAN   ◈"
        BtnLbl.Font=Enum.Font.GothamBlack; BtnLbl.TextSize=13; BtnLbl.ZIndex=15
        local BLGrad=Instance.new("UIGradient",BtnLbl)
        BLGrad.Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,   Color3.fromRGB(255,100,0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,220,255)),
        }

        -- Hover effect on button
        VerifyBtn.MouseEnter:Connect(function()
            TweenService:Create(VerifyBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(100,0,200)}):Play()
            TweenService:Create(btnStroke,TweenInfo.new(0.18),{Color=Color3.fromRGB(255,100,255)}):Play()
        end)
        VerifyBtn.MouseLeave:Connect(function()
            TweenService:Create(VerifyBtn,TweenInfo.new(0.18),{BackgroundColor3=Color3.fromRGB(60,0,140)}):Play()
            TweenService:Create(btnStroke,TweenInfo.new(0.18),{Color=Color3.fromRGB(180,60,255)}):Play()
        end)

        -- Close button
        local CloseBtn=Instance.new("TextButton",ScanCard); CloseBtn.Size=UDim2.new(0,32,0,32); CloseBtn.Position=UDim2.new(1,-42,0,10)
        CloseBtn.BackgroundColor3=Color3.fromRGB(30,0,60); CloseBtn.Text="×"; CloseBtn.Font=Enum.Font.GothamBold; CloseBtn.TextSize=22
        CloseBtn.TextColor3=Color3.fromRGB(180,80,255); CloseBtn.ZIndex=15; CloseBtn.BorderSizePixel=0
        Instance.new("UICorner",CloseBtn).CornerRadius=UDim.new(0,8)
        CloseBtn.MouseEnter:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(80,0,20),TextColor3=Color3.fromRGB(255,60,80)}):Play() end)
        CloseBtn.MouseLeave:Connect(function() TweenService:Create(CloseBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(30,0,60),TextColor3=Color3.fromRGB(180,80,255)}):Play() end)

        local function closeScanner()
            rainActive=false; scanStrokeActive=false; helixActive=false
            TweenService:Create(Overlay,TweenInfo.new(0.45),{BackgroundTransparency=1}):Play()
            TweenService:Create(ScanCard,TweenInfo.new(0.4,Enum.EasingStyle.Back,Enum.EasingDirection.In),
                {Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}):Play()
            task.wait(0.5); pcall(function() KSG:Destroy() end)
        end
        CloseBtn.MouseButton1Click:Connect(closeScanner)

        playSound2(9119713951,0.4,0.88); task.wait(0.5)
        TweenService:Create(ScanCard,TweenInfo.new(0.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,500,0,226)}):Play()
        playSound2(4590662766,0.5,1.1)

        local function doVerify()
            local key=HiddenInput.Text:match("^%s*(.-)%s*$") or ""
            if #key<6 then
                Status.Text="◈  Key too short — minimum 6 characters"
                Status.TextColor3=Color3.fromRGB(255,120,40)
                playSound2(6042053626,0.5,0.75)
                -- Shake ScanCard
                for _ = 1,6 do
                    TweenService:Create(ScanCard,TweenInfo.new(0.04),{Position=UDim2.new(0.5,math.random(-6,6),0.5,math.random(-3,3))}):Play()
                    task.wait(0.05)
                end
                TweenService:Create(ScanCard,TweenInfo.new(0.12,Enum.EasingStyle.Elastic),{Position=UDim2.new(0.5,0,0.5,0)}):Play()
                return
            end
            HiddenInput.TextEditable=false; VerifyBtn.Active=false
            BtnLbl.Text="◈   SCANNING — PLEASE WAIT   ◈"
            Status.Text="◈  BIOMETRIC SCAN IN PROGRESS..."; Status.TextColor3=Color3.fromRGB(180,80,255)
            playSound2(9119713951,0.45,1.1)

            -- Scan bar sweeps across
            task.spawn(function()
                TweenService:Create(ScanBarFill,TweenInfo.new(1.8,Enum.EasingStyle.Sine),{Size=UDim2.new(1,0,1,0)}):Play()
            end)
            -- Glitch slot cells during scan
            task.spawn(function()
                local glitchChars2="01◈█▓░"
                for _ = 1,24 do
                    for _,cell in ipairs(slotCells) do
                        if cell.lbl.Text~="·" and math.random()<0.18 then
                            local orig=cell.lbl.Text
                            pcall(function() cell.lbl.Text=glitchChars2:sub(math.random(1,#glitchChars2),math.random(1,#glitchChars2)) end)
                            task.delay(0.06,function() pcall(function() cell.lbl.Text=orig end) end)
                        end
                    end
                    task.wait(0.07)
                end
            end)

            task.wait(1.8+math.random()*0.5)

            local result=ValidateKey(key)
            if result=="ok" then
                playSound2(1847668471,0.8,1.0)
                Status.Text="◈  AUTHENTICATION SUCCESSFUL — PREMIUM GRANTED"
                Status.TextColor3=Color3.fromRGB(60,255,130)
                BtnLbl.Text="✓   ACCESS GRANTED   ✓"
                TweenService:Create(cardStroke,TweenInfo.new(0.3),{Color=Color3.fromRGB(50,255,130)}):Play()
                -- Green flash
                local sFlash=Instance.new("Frame",KSG); sFlash.Size=UDim2.new(1,0,1,0)
                sFlash.BackgroundColor3=Color3.fromRGB(30,255,100); sFlash.BackgroundTransparency=0.55; sFlash.ZIndex=30
                TweenService:Create(sFlash,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play(); ScanDebris:AddItem(sFlash,0.8)
                -- Cells turn green cascade
                for i,cell in ipairs(slotCells) do
                    if cell.lbl.Text~="·" then
                        task.delay(i*0.035,function()
                            pcall(function() TweenService:Create(cell.lbl,TweenInfo.new(0.25),{TextColor3=Color3.fromRGB(60,255,140)}):Play() end)
                        end)
                    end
                end
                PremiumUnlocked=true; PremiumActive=true
                SavePremiumData(key, {})
                Rayfield:Notify({Title="✨ Premium Activated",Content="Full access granted. Settings will auto-restore next game.",Duration=6,Image=4483362458})
                if S.AutoParry then StopEngine(); task.wait(0.08); P.AutoParry=true; StartPremiumEngine() end
                task.wait(2.2); closeScanner()
            else
                playSound2(6042053626,0.7,0.65)
                Status.Text=result=="locked_other" and "◈  DEVICE MISMATCH — HWID LOCKED TO ANOTHER USER" or "◈  INVALID KEY — ACCESS DENIED"
                Status.TextColor3=Color3.fromRGB(255,50,50)
                TweenService:Create(cardStroke,TweenInfo.new(0.2),{Color=Color3.fromRGB(220,40,40)}):Play()
                -- Red flash
                local rFlash=Instance.new("Frame",KSG); rFlash.Size=UDim2.new(1,0,1,0)
                rFlash.BackgroundColor3=Color3.fromRGB(200,0,0); rFlash.BackgroundTransparency=0.7; rFlash.ZIndex=30
                TweenService:Create(rFlash,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play(); ScanDebris:AddItem(rFlash,0.7)
                TweenService:Create(ScanBarFill,TweenInfo.new(0.3),{Size=UDim2.new(0,0,1,0)}):Play()
                task.wait(2.0)
                HiddenInput.Text=""; HiddenInput.TextEditable=true; VerifyBtn.Active=true
                BtnLbl.Text="◈   INITIATE BIOMETRIC SCAN   ◈"
                Status.Text="◈  Awaiting authorization sequence..."; Status.TextColor3=Color3.fromRGB(140,50,255)
                TweenService:Create(cardStroke,TweenInfo.new(0.3),{Color=Color3.fromRGB(160,40,255)}):Play()
            end
        end

        VerifyBtn.MouseButton1Click:Connect(doVerify)
        HiddenInput.FocusLost:Connect(function(enter) if enter then doVerify() end end)
        task.delay(0.65,function() pcall(function() HiddenInput:CaptureFocus() end) end)
    end)
end})

PT:CreateDivider()
PT:CreateSection("⚡ Premium Parry Engine")
PT:CreateLabel("PreSimulation priority · 30-frame lookahead (0.5s) · Predictive early fire · Curve crusher · Never dies mid-match")
PT:CreateToggle({Name="Premium Auto Parry",CurrentValue=false,Flag="PAP",Callback=function(v)
    PremGuard(v,"Premium Parry",function(val)
        if val then StopEngine(); P.AutoParry=true; StartPremiumEngine()
            Rayfield:Notify({Title="⚡ Premium Parry ON",Content="God-tier engine active.",Duration=3,Image=4483362458})
        else StopPremiumEngine(); P.AutoParry=false end
    end)
end})
PT:CreateToggle({Name="God Emergency (3.5 studs)",CurrentValue=false,Flag="PGE",Callback=function(v) PremGuard(v,"God Emergency",function(val) P.GodEmergency=val end) end})
PT:CreateToggle({Name="Auto Face Ball (Premium)",CurrentValue=false,Flag="PAF",Callback=function(v) PremGuard(v,"Auto Face",function(val) P.AutoFace=val end) end})
PT:CreateDivider()
PT:CreateSection("🏟 Premium Lobby Parry")
PT:CreateToggle({Name="Premium Lobby Parry",CurrentValue=false,Flag="PLP",Callback=function(v)
    PremGuard(v,"Prem Lobby",function(val)
        P.LobbyParry=val
        if val then StartPremiumLobbyEngine() else StopPremiumLobbyEngine() end
    end)
end})
PT:CreateDivider()
PT:CreateSection("🎯 Premium Accuracy")
PT:CreateLabel("1-100 = normal  ·  101-150 = fires frames EARLY (GOD MODE)")
PT:CreateSlider({Name="Parry Accuracy",Range={1,150},Increment=1,CurrentValue=100,Flag="PPACC",Callback=function(v)
    PremGuard(v,"Accuracy",function(val)
        PremAccuracy=val
        local tier=val>=150 and "👑 GOD" or val>=120 and "⚡ Insane" or val>=101 and "🔥 God-like" or val==100 and "✅ Perfect" or val>=80 and "💪 Elite" or "🎭 Human"
        Rayfield:Notify({Title="Accuracy: "..val.."  —  "..tier,Content="",Duration=2,Image=4483362458})
    end)
end})
PT:CreateSection("🎯 Hitbox Target")
PT:CreateSlider({Name="Hitbox Target",Range={2.5,6.0},Increment=0.1,CurrentValue=4.0,Flag="PHB",Callback=function(v) PremGuard(v,"Hitbox",function(val) P.HitboxTarget=val end) end})
PT:CreateDivider()
PT:CreateSection("⚡ Premium Ability Detector")
PT:CreateLabel("FIXED: Only fires when ball targets YOU. No more false fires.")
PT:CreateToggle({Name="Premium Ability Detector",CurrentValue=false,Flag="PADET",Callback=function(v)
    PremGuard(v,"Prem Detector",function(val)
        if val then StartPremAbilDetect() else StopPremAbilDetect() end
    end)
end})
PT:CreateDivider()
PT:CreateSection("⚔ Parry Extras")
PT:CreateToggle({Name="Parry Sound (Sword Clash)",CurrentValue=false,Flag="PFS",Callback=function(v) PremGuard(v,"Parry Sound",function(val) PF.ParrySound=val end) end})
PT:CreateToggle({Name="Anti-Block (fires when enemy blocks your ball)",CurrentValue=false,Flag="PAB",Callback=function(v)
    PremGuard(v,"Anti-Block",function(val)
        PF.AntiBlock=val
        if val then StartAntiBlock()
        else if AntiBlockConn then AntiBlockConn:Disconnect(); AntiBlockConn=nil end end
    end)
end})
PT:CreateToggle({Name="Combo Tracker",CurrentValue=false,Flag="PCT",Callback=function(v)
    PremGuard(v,"Combo",function(val) PF.ComboTracker=val; if val then BuildComboWidget() else PF.ComboCount=0; pcall(function() if GUI.Combo then GUI.Combo:Destroy() end end) end end)
end})
PT:CreateToggle({Name="Auto Chat after Parry",CurrentValue=false,Flag="PAC",Callback=function(v) PremGuard(v,"Auto Chat",function(val) PF.AutoChat=val end) end})
PT:CreateDivider()
PT:CreateSection("🔮 Prediction & Ball Tracking")
PT:CreateToggle({Name="Trajectory Line ESP",CurrentValue=false,Flag="PTESP",Callback=function(v) PremGuard(v,"Traj ESP",function(val) PF.TrajectoryESP=val; if val then BuildTrajectoryESP() else pcall(function() if GUI.Traj then GUI.Traj:Destroy() end end) end end) end})
PT:CreateToggle({Name="Ball Speed Meter",CurrentValue=false,Flag="PBSM",Callback=function(v) PremGuard(v,"Speed Meter",function(val) PF.BallSpeedMeter=val; if val then BuildSpeedMeter() else pcall(function() if GUI.SpeedMeter then GUI.SpeedMeter:Destroy() end end) end end) end})
PT:CreateToggle({Name="Time-to-Impact",CurrentValue=false,Flag="PTTI",Callback=function(v) PremGuard(v,"TTI",function(val) PF.TimeToImpact=val; if val then BuildTTI() else pcall(function() if GUI.TTI then GUI.TTI:Destroy() end end) end end) end})
PT:CreateToggle({Name="Ball Target Alert (red edge flash)",CurrentValue=false,Flag="PBTA",Callback=function(v) PremGuard(v,"Target Alert",function(val) PF.TargetAlert=val; if val then BuildTargetAlert() else pcall(function() if GUI.Alert then GUI.Alert:Destroy() end end) end end) end})
PT:CreateDivider()
PT:CreateSection("👁 Visual & ESP")
PT:CreateToggle({Name="Distance ESP",CurrentValue=false,Flag="PDESP",Callback=function(v) PremGuard(v,"Dist ESP",function(val) PF.DistESP=val; if not val then UpdateDistESP() end end) end})
PT:CreateToggle({Name="Chams (see through walls)",CurrentValue=false,Flag="PCH",Callback=function(v) PremGuard(v,"Chams",function(val) PF.Chams=val; ApplyChams(val) end) end})
PT:CreateToggle({Name="Ball Highlight",CurrentValue=false,Flag="PBH",Callback=function(v) PremGuard(v,"Ball Highlight",function(val) PF.BallHighlight=val; if val then StartBallHighlight() else if BallHighlightConn then BallHighlightConn:Disconnect() end end end) end})
PT:CreateToggle({Name="Rainbow Ball Trail",CurrentValue=false,Flag="PRBT",Callback=function(v) PremGuard(v,"Rainbow Trail",function(val) PF.RainbowTrail=val; if val then StartRainbowTrail() else if RainbowTrailConn then RainbowTrailConn:Disconnect() end end end) end})
PT:CreateDivider()
PT:CreateSection("🏃 Movement & Combat")
PT:CreateToggle({Name="Auto Dodge",CurrentValue=false,Flag="PAD",Callback=function(v) PremGuard(v,"Auto Dodge",function(val) PF.AutoDodge=val; if val then StartAutoDodge() else if DodgeConn then DodgeConn:Disconnect() end end end) end})
PT:CreateToggle({Name="Speed Boost on Parry",CurrentValue=false,Flag="PSBP",Callback=function(v) PremGuard(v,"Speed Boost",function(val) PF.SpeedOnParry=val end) end})
PT:CreateSlider({Name="Boost Speed Amount",Range={20,100},Increment=5,CurrentValue=40,Flag="PSBA",Callback=function(v) PremGuard(v,"Boost Amt",function(val) PF.SpeedOnParryAmt=val end) end})
PT:CreateToggle({Name="Ghost Mode (85% transparent)",CurrentValue=false,Flag="PGM",Callback=function(v) PremGuard(v,"Ghost Mode",function(val) PF.GhostMode=val; ApplyGhost(val) end) end})
PT:CreateToggle({Name="Safe Zone Warning",CurrentValue=false,Flag="PSZW",Callback=function(v) PremGuard(v,"Safe Zone",function(val) PF.SafeZoneWarn=val; if val then BuildSafeZoneWarning() end end) end})
PT:CreateDivider()
PT:CreateSection("📊 HUD & UI")
PT:CreateToggle({Name="Premium FPS Unlocker",CurrentValue=false,Flag="PFPS",Callback=function(v) PremGuard(v,"FPS Unlock",function(val) PF.PremFPS=val; SetPremFPS(val,PF.PremFPSCap) end) end})
PT:CreateDropdown({Name="FPS Cap",Options={"Uncapped","144","240","360"},CurrentOption={"Uncapped"},MultipleOptions=false,Flag="PFPSC",Callback=function(v)
    local pick=type(v)=="table" and v[1] or tostring(v)
    PF.PremFPSCap=pick=="Uncapped" and 0 or tonumber(pick) or 0
    if PF.PremFPS then SetPremFPS(true,PF.PremFPSCap) end
end})
PT:CreateToggle({Name="Kill Tracker",CurrentValue=false,Flag="PKT",Callback=function(v) PremGuard(v,"Kill Tracker",function(val) PF.KillTracker=val; if val then BuildKillWidget() end end) end})
PT:CreateButton({Name="☠ Reset Kill Count",Callback=function() PremGuard(true,"Kill Tracker",function()
    PF.KillCount=0; pcall(function() if GUI.KillLbl then GUI.KillLbl.Text="0" end end)
    Rayfield:Notify({Title="Kill Count Reset",Content="",Duration=2,Image=4483362458})
end) end})
PT:CreateToggle({Name="Premium Watermark Badge",CurrentValue=false,Flag="PWM",Callback=function(v) PremGuard(v,"Watermark",function(val) PF.PremWatermark=val; if val then BuildWatermark() end end) end})
PT:CreateDivider()
PT:CreateSection("📊 Status")
PT:CreateButton({Name="Check Premium Status",Callback=function()
    if PremiumUnlocked then
        Rayfield:Notify({Title="✨ Premium ACTIVE",Content="All features unlocked.",Duration=4,Image=4483362458})
    else
        Rayfield:Notify({Title="🔒 Not Unlocked",Content="Open Key Scanner.",Duration=3,Image=4483362458})
    end
end})

-- ── SETTINGS TAB ─────────────────────────────────────────────────
local T5=W:CreateTab("⚙ Settings",nil)
T5:CreateSection("Keybinds")
T5:CreateKeybind({Name="Toggle Auto Parry",CurrentKeybind="F5",HoldToInteract=false,Flag="KB2",Callback=function()
    S.AutoParry=not S.AutoParry
    if S.AutoParry then StartEngine() else StopEngine() end
    Rayfield:Notify({Title="Auto Parry",Content=S.AutoParry and "ON" or "OFF",Duration=2,Image=4483362458})
end})
T5:CreateKeybind({Name="Toggle Ball ESP",CurrentKeybind="F8",HoldToInteract=false,Flag="KB3",Callback=function()
    S.BallESP=not S.BallESP; if S.BallESP then StartESP() else CleanESP() end
end})
T5:CreateDivider()
T5:CreateSection("About")
T5:CreateLabel("hiruZ UI  ·  by ZivX  ·  Upgraded Edition  ·  Fixed Build")
T5:CreateLabel("FIXES: AutoParry longevity · Premium rearm · Early-fire 0.5s · Ability detector gate")
T5:CreateLabel("Chat: /help for all commands")
T5:CreateDivider()
T5:CreateSection("🔗 Discord")
T5:CreateButton({Name="📋 Copy Discord Link",Callback=function()
    local link="https://discord.gg/S2fKywJutE"
    local ok=pcall(function() setclipboard(link) end)
    Rayfield:Notify({Title=ok and "Discord Copied!" or "discord.gg/S2fKywJutE",Content=link,Duration=4,Image=4483362458})
end})

-- ══════════════════════════════════════════════════════════════════
-- BOOT
-- ══════════════════════════════════════════════════════════════════
StartNoclip()
StartIJ()
