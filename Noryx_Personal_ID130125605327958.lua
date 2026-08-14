local Services = {
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    TweenService = game:GetService("TweenService"),
    RunService = game:GetService("RunService"),
    Lighting = game:GetService("Lighting"),
    TeleportService = game:GetService("TeleportService"),
    UserInputService = game:GetService("UserInputService"),
}

local Players = Services.Players
local LP = Players.LocalPlayer
local ReplicatedStorage = Services.ReplicatedStorage
local TweenService = Services.TweenService
local RunService = Services.RunService
local Lighting = Services.Lighting

local RedzLib = loadstring(game:HttpGet("https://pastefy.app/MAbSfkcD/raw"))()

local Window = RedzLib:MakeWindow({
    Title = "Noryx : Personal",
    SubTitle = "Private Build",
    SaveFolder = "NoryxPersonal"
})

Window:AddMinimizeButton({
    Button = {
        Image = "rbxassetid://130125605327958",
        BackgroundTransparency = 0,
        Size = UDim2.new(0, 55, 0, 55),
        BackgroundColor3 = Color3.fromRGB(20, 20, 20),
        BorderSizePixel = 1,
        BorderColor3 = Color3.fromRGB(40, 120, 255)
    },
    Corner = { CornerRadius = UDim.new(1, 0) }
})

local Tabs = {
    Main = Window:MakeTab({Title = "Main", Icon = "home"}),
    Combat = Window:MakeTab({Title = "Combat", Icon = "crosshair"}),
    Travel = Window:MakeTab({Title = "Travel", Icon = "map"}),
    Settings = Window:MakeTab({Title = "Settings", Icon = "settings"}),
    Info = Window:MakeTab({Title = "Info", Icon = "info"})
}

local State = {
    AutoFarm = false,
    AutoAttack = false,
    Noclip = false,
    FixLag = false,
    Tweening = false,
    TweenToken = 0,
    TweenSpeed = 300,
    FarmHeight = 10,
    TargetRange = 1500,
}

local function Character()
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return nil end
    return char, hrp, hum
end

local function GetRoot(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

local function IsAlive(model)
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and model.Parent ~= nil
end

local function GetNearestEnemy()
    local _, hrp = Character()
    if not hrp then return nil end

    local enemies = workspace:FindFirstChild("Enemies")
    if not enemies then return nil end

    local best, bestDistance = nil, State.TargetRange
    for _, mob in ipairs(enemies:GetChildren()) do
        if IsAlive(mob) then
            local root = GetRoot(mob)
            if root then
                local distance = (root.Position - hrp.Position).Magnitude
                if distance < bestDistance then
                    best = mob
                    bestDistance = distance
                end
            end
        end
    end
    return best
end

local function StopTween()
    State.TweenToken += 1
    State.Tweening = false
    local _, hrp = Character()
    if hrp then
        local tween = hrp:FindFirstChild("NoryxTween")
        if tween then tween:Destroy() end
    end
end

local function TweenTo(target)
    if typeof(target) ~= "CFrame" then return false end

    local _, hrp = Character()
    if not hrp then return false end

    State.TweenToken += 1
    local token = State.TweenToken
    State.Tweening = true

    local distance = (target.Position - hrp.Position).Magnitude
    if distance <= 1 then
        State.Tweening = false
        hrp.CFrame = target
        return true
    end

    local speed = math.max(50, tonumber(State.TweenSpeed) or 300)
    local duration = math.max(distance / speed, 0.08)
    local info = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
    local tween = TweenService:Create(hrp, info, {CFrame = target})

    tween:SetAttribute("NoryxTween", true)
    tween:Play()
    tween.Completed:Wait()

    if token == State.TweenToken then
        hrp.CFrame = target
        State.Tweening = false
    end

    return token == State.TweenToken
end

local function AttackTarget(mob)
    local char, hrp, hum = Character()
    if not char or not hrp or not hum or not IsAlive(mob) then return end

    local root = GetRoot(mob)
    if not root then return end

    local standPosition = root.Position + Vector3.new(0, State.FarmHeight, 0)
    local standCFrame = CFrame.new(standPosition)

    TweenTo(standCFrame)

    if not IsAlive(mob) then return end

    local tool = char:FindFirstChildOfClass("Tool") or LP.Backpack:FindFirstChildOfClass("Tool")
    if tool and tool.Parent ~= char then
        hum:EquipTool(tool)
    end

    task.spawn(function()
        while State.AutoAttack and IsAlive(mob) do
            local activeTool = char:FindFirstChildOfClass("Tool")
            if not activeTool then break end

            pcall(function()
                activeTool:Activate()
            end)

            task.wait(0.12)
        end
    end)
end

local function ApplyFixLag()
    State.FixLag = true
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9

    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if terrain then
        pcall(function()
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
        end)
    end

    local descendants = game:GetDescendants()
    for i, obj in ipairs(descendants) do
        pcall(function()
            if obj:IsA("BasePart") then
                obj.CastShadow = false
                obj.Material = Enum.Material.SmoothPlastic
            elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
            elseif obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                obj.Enabled = false
            elseif obj:IsA("Beam") then
                obj.Enabled = false
            elseif obj:IsA("PostEffect") then
                obj.Enabled = false
            end
        end)

        if i % 500 == 0 then
            task.wait()
        end
    end
end

local function SetNoclip(enabled)
    State.Noclip = enabled
end

RunService.Stepped:Connect(function()
    if not State.Noclip then return end
    local char = LP.Character
    if not char then return end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.CanCollide = false
        end
    end
end)

Tabs.Main:AddSection({"Noryx Personal"})

Tabs.Main:AddToggle({
    Name = "Auto Farm Nearest",
    Description = "Farm mục tiêu gần nhất",
    Default = false,
    Callback = function(v)
        State.AutoFarm = v
    end
})

Tabs.Main:AddToggle({
    Name = "Noclip",
    Description = "Xuyên vật thể khi di chuyển",
    Default = false,
    Callback = SetNoclip
})

Tabs.Combat:AddSection({"Combat"})

Tabs.Combat:AddToggle({
    Name = "Auto Attack",
    Description = "Tự kích hoạt Tool đang cầm",
    Default = false,
    Callback = function(v)
        State.AutoAttack = v
    end
})

Tabs.Combat:AddSlider({
    Name = "Farm Height",
    Flag = "FarmHeight",
    Description = "Khoảng cách đứng phía trên mục tiêu",
    Min = 5,
    Max = 30,
    Default = 10,
    Callback = function(v)
        State.FarmHeight = v
    end
})

Tabs.Combat:AddSlider({
    Name = "Target Range",
    Flag = "TargetRange",
    Description = "Bán kính tìm mục tiêu",
    Min = 100,
    Max = 3000,
    Default = 1500,
    Callback = function(v)
        State.TargetRange = v
    end
})

Tabs.Travel:AddSection({"Movement"})

Tabs.Travel:AddSlider({
    Name = "Tween Speed",
    Flag = "TweenSpeed",
    Description = "Tốc độ tween",
    Min = 100,
    Max = 600,
    Default = 300,
    Callback = function(v)
        State.TweenSpeed = v
    end
})

Tabs.Travel:AddButton({
    Name = "Stop Tween",
    Description = "Dừng chuyển động hiện tại",
    Callback = StopTween
})

Tabs.Travel:AddButton({
    Name = "Teleport Middle Town",
    Description = "Sea 1",
    Callback = function()
        TweenTo(CFrame.new(-690, 15, 1581))
    end
})

Tabs.Travel:AddButton({
    Name = "Teleport Mansion",
    Description = "Sea 2",
    Callback = function()
        TweenTo(CFrame.new(-390, 331, 673))
    end
})

Tabs.Travel:AddButton({
    Name = "Teleport Castle",
    Description = "Sea 3",
    Callback = function()
        TweenTo(CFrame.new(-5110, 316, -2987))
    end
})

Tabs.Settings:AddSection({"Performance"})

Tabs.Settings:AddButton({
    Name = "Siêu Fix Lag",
    Description = "Giảm đồ họa nhưng giữ màu vật thể",
    Callback = ApplyFixLag
})

Tabs.Settings:AddToggle({
    Name = "Keep Noclip",
    Description = "Giữ noclip cho toàn bộ nhân vật",
    Default = false,
    Callback = SetNoclip
})

Tabs.Info:AddSection({"Noryx"})
Tabs.Info:AddParagraph({
    Title = "Noryx Personal",
    Content = "Private build • Clean core • Tween 300 mặc định"
})

Tabs.Info:AddParagraph({
    Title = "Build ID",
    Content = "NRX-P01"
})

local function FarmLoop()
    if not State.AutoFarm then return end
    if not IsAlive(LP.Character) then return end

    local target = GetNearestEnemy()
    if not target then return end

    AttackTarget(target)
end

task.spawn(function()
    while task.wait(0.25) do
        if State.AutoFarm then
            pcall(FarmLoop)
        end
    end
end)

LP.CharacterAdded:Connect(function()
    StopTween()
    task.wait(1)
end)

return Window
