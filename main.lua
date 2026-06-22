-- // Zaber candy🍬 [Full Integrated Script - Optimized Performance]
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ContentProvider = game:GetService("ContentProvider")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // UNCAP RENDER DISTANCE
Camera.MaxVisibleRadius = math.huge
settings().Rendering.DrawDistanceMax = math.huge

-- // UI SETUP
local Window = WindUI:CreateWindow({
    Title = "Zaber candy🍬",
    Author = "Developer [น้องอาร์]",
    Folder = "Zaber_Candy_Config",
    Icon = "rbxassetid://97643133348071",
    Transparent = true,
    Theme = "Dark",
    Font = "Gotham",
    CustomBackground = "rbxassetid://97643133348071",
    HideSearchBar = false,
})

Window:EditOpenButton({ Enabled = false })
WindUI:Notify({ Title = "System Verified", Content = "Welcome. High-Performance systems loaded.", Duration = 4 })

loadstring(game:HttpGet('https://raw.githubusercontent.com/Yenixs/ToolScript/refs/heads/main/GuiToggle.luau'))()("rbxassetid://97643133348071", function()
    Window:Toggle()
end)

-- // TABS
local CombatTab = Window:Tab({Title = "Combat", Icon = "sword"})
local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local ESPTab = Window:Tab({Title = "ESP", Icon = "eye"})
local LootTab = Window:Tab({Title = "Auto Loot", Icon = "box"}) 
local MiscTab = Window:Tab({Title = "Misc & FPS", Icon = "settings"})
local ServerTab = Window:Tab({Title = "Server", Icon = "server"})

local RARITY_COLORS = {
    ["Common"] = Color3.fromRGB(255, 255, 255),
    ["Uncommon"] = Color3.fromRGB(99, 255, 52),
    ["Rare"] = Color3.fromRGB(51, 170, 255),
    ["Epic"] = Color3.fromRGB(237, 44, 255),
    ["Legendary"] = Color3.fromRGB(255, 150, 0),
    ["Omega"] = Color3.fromRGB(255, 20, 51),
    ["Money"] = Color3.fromRGB(85, 255, 127),
    ["Default"] = Color3.fromRGB(255, 255, 255)
}

-- // CORE VARIABLES (COMBAT)
local SelectedBodyPart = "Head" 
local SilentAimEnabled = false
local showFov = false
local RainbowFOV = false 
local BulletSpeed = 1500

local GunLookup = {
    ["P226"]=true, ["MP5"]=true, ["M24"]=true, ["Draco"]=true, ["Glock"]=true,
    ["Sawnoff"]=true, ["Uzi"]=true, ["G3"]=true, ["C9"]=true, ["Hunting Rifle"]=true,
    ["Anaconda"]=true, ["AK47"]=true, ["Remington"]=true, ["Double Barrel"]=true,
    ["Skorpion"]=true,
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius = 150
FOVCircle.Thickness = 1 
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255,105,180)
FOVCircle.Visible = false

local TracerLine = Drawing.new("Line")
TracerLine.Color = Color3.fromRGB(255,0,0)
TracerLine.Thickness = 2
TracerLine.Visible = false

local TargetLine = Drawing.new("Line")
TargetLine.Color = Color3.new(1, 1, 1)
TargetLine.Thickness = 1.5
TargetLine.Visible = false

local TargetData = {}
local CurrentAimbotTarget = nil

-- // CORE VARIABLES (PLAYER)
local defaultJumpPower = 20
local maxJumpPower = 100
local highJumpPower = 70
local highJumpEnabled = false
local speedEnabled = false
local speedMultiplier = 0.10
local antiDeadEnabled = false
local isAntiDead = false
local infStamEnabled = false
local FakeAntiAim = false
local SinkEnabled = false
local SinkDepth = 10

-- // CORE VARIABLES (ESP)
_G.EnabledBox = false
_G.EnabledHpBar = false
_G.EnabledName = false
_G.EnabledDistance = false
_G.EnabledItemDrop = true -- ฟังก์ชั่นใหม่ที่คุณเพิ่มเข้ามา

local player_drawings = {}
local item_drawings = {} -- ตารางเก็บค่าโมเดลไอเทมที่วาดอยู่บนจอ

-- // CORE VARIABLES (LOOT MAGNET)
local MagnetConfig = { Enabled = false, Radius = 2000, Ignore = { Common = false, Uncommon = false, Rare = false, Epic = false, Legendary = false, Omega = false, Default = false } }
local ItemDatabase = {}

-- ==========================================
-- // CONNECT UI TO INTERFACES
-- ==========================================

-- Combat Tab
CombatTab:Toggle({ Title = "Enable Silent Aim (Pro Resolver)", Default = false, Callback = function(v) SilentAimEnabled = v; TracerLine.Visible = v and TracerLine.Visible end })
CombatTab:Dropdown({ Title = "Target BodyPart", Default = "Head", Values = {"Head", "HumanoidRootPart"}, Callback = function(v) SelectedBodyPart = v end })
CombatTab:Toggle({ Title = "Show FOV Circle", Default = false, Callback = function(v) showFov = v; FOVCircle.Visible = v end })
CombatTab:Toggle({ Title = "Rainbow FOV Circle", Default = false, Callback = function(v) RainbowFOV = v end })
CombatTab:Slider({ Title = "FOV Radius", Step = 1, Value = {Min = 50, Max = 800, Default = FOVCircle.Radius}, Callback = function(v) FOVCircle.Radius = tonumber(v) end })

-- Player Tab
PlayerTab:Toggle({ Title = "Enable Walk Speed", Default = false, Callback = function(s) speedEnabled = s end })
PlayerTab:Slider({ Title = "Speed Multiplier", Value = {Min = 0.05, Max = 0.15, Default = speedMultiplier}, Step = 0.01, Callback = function(v) speedMultiplier = tonumber(v) end })
PlayerTab:Toggle({ Title = "Enable High Jump", Default = false, Callback = function(s) highJumpEnabled = s; local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait() local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.UseJumpPower = true; hum.JumpPower = math.clamp(s and highJumpPower or defaultJumpPower, 0, maxJumpPower) end end })
PlayerTab:Slider({ Title = "High Jump Power", Value = {Min = 20, Max = maxJumpPower, Default = highJumpPower}, Step = 1, Callback = function(v) highJumpPower = tonumber(v); if highJumpEnabled then local char = LocalPlayer.Character if char then local hum = char:FindFirstChildOfClass("Humanoid") if hum then hum.JumpPower = math.clamp(highJumpPower, 0, maxJumpPower) end end end end })
PlayerTab:Toggle({ Title = "Infinite Stamina", Default = false, Callback = function(s) infStamEnabled = s end })
PlayerTab:Toggle({ Title = "Velocity Desync Anti-Aim", Default = false, Callback = function(s) FakeAntiAim = s end })
PlayerTab:Toggle({ Title = "Underground Noclip", Default = false, Callback = function(s) SinkEnabled = s end })
PlayerTab:Slider({ Title = "Underground Depth", Value = {Min = 1, Max = 100, Default = SinkDepth}, Step = 1, Callback = function(v) SinkDepth = tonumber(v) end })
PlayerTab:Toggle({ Title = "Anti-Dead (Evasion under 25 HP)", Default = false, Callback = function(s) antiDeadEnabled = s end })

-- ESP Tab
ESPTab:Toggle({ Title = "Show Box (Hollow & Dynamic)", Default = false, Callback = function(s) _G.EnabledBox = s end })
ESPTab:Toggle({ Title = "Show Health", Default = false, Callback = function(s) _G.EnabledHpBar = s end })
ESPTab:Toggle({ Title = "Show Name (Scaled Tiny)", Default = false, Callback = function(s) _G.EnabledName = s end })
ESPTab:Toggle({ Title = "Show Distance (m)", Default = false, Callback = function(s) _G.EnabledDistance = s end })
ESPTab:Toggle({ Title = "Show Dropped Items (Drawing API)", Default = true, Callback = function(s) _G.EnabledItemDrop = s end }) -- เปลี่ยนมาคุมตัวแปรใหม่ตรงนี้แล้ว

-- Auto Loot Tab
LootTab:Toggle({ Title = "Enable Auto PickUp", Default = false, Callback = function(s) MagnetConfig.Enabled = s end })
LootTab:Toggle({ Title = "Ignore Common", Default = false, Callback = function(s) MagnetConfig.Ignore.Common = s end })
LootTab:Toggle({ Title = "Ignore Uncommon", Default = false, Callback = function(s) MagnetConfig.Ignore.Uncommon = s end })
LootTab:Toggle({ Title = "Ignore Rare", Default = false, Callback = function(s) MagnetConfig.Ignore.Rare = s end })
LootTab:Toggle({ Title = "Ignore Epic", Default = false, Callback = function(s) MagnetConfig.Ignore.Epic = s end })
LootTab:Toggle({ Title = "Ignore Legendary", Default = false, Callback = function(s) MagnetConfig.Ignore.Legendary = s end })
LootTab:Toggle({ Title = "Ignore Omega", Default = false, Callback = function(s) MagnetConfig.Ignore.Omega = s end })
LootTab:Toggle({ Title = "Ignore Default", Default = false, Callback = function(s) MagnetConfig.Ignore.Default = s end })

-- Misc Tab
MiscTab:Button({ Title = "Boost FPS 60", Callback = function() setfpscap(60) end })
MiscTab:Button({ Title = "Boost FPS 120", Callback = function() setfpscap(120) end })
MiscTab:Button({ Title = "Boost FPS 240", Callback = function() setfpscap(240) end })

-- Server Tab
local function ServerHop(sortOrder)
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=" .. sortOrder .. "&limit=100"
    local success, res = pcall(function() return game:HttpGet(url) end)
    if success and res then
        local data = HttpService:JSONDecode(res)
        for _, server in ipairs(data.data) do
            if server.playing and server.playing < server.maxPlayers and server.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                break
            end
        end
    end
end
ServerTab:Button({ Title = "Rejoin Server", Callback = function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end })
ServerTab:Button({ Title = "Hop Low Server", Callback = function() ServerHop("Asc") end })
ServerTab:Button({ Title = "Hop High Server", Callback = function() ServerHop("Desc") end })


-- ==========================================
-- // CORE FUNCTIONAL LOGIC (BACKEND OPERATIONS)
-- ==========================================

local function GetTargetPart(character)
    return character and character:FindFirstChild(SelectedBodyPart)
end

local function GetClosestTarget()
    local closest, shortest = nil, math.huge
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local part = GetTargetPart(plr.Character)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if (not showFov or dist <= FOVCircle.Radius) and dist < shortest then
                        shortest = dist
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

local function IsHoldingAllowedGun(args)
    local ok, weapon = pcall(function() return args[3] end)
    if ok and typeof(weapon)=="Instance" and GunLookup[weapon.Name] then return true end
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if (tool:IsA("Tool") or tool:IsA("Model")) and GunLookup[tool.Name] then return true end
    end
    return false
end

-- // ADVANCED ANTI-ANTI-AIM RESOLVER (PRECISE ACCELERATION DETECTION)
local function GetResolvedVelocity(target, root)
    if not root or not target.Character then return Vector3.zero end
    
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    local trackingPart = (hum and hum.SeatPart) and hum.SeatPart or root
    
    if not TargetData[target] then
        TargetData[target] = { LastPos = trackingPart.Position, LastTick = tick(), SmoothVel = Vector3.zero, LastVel = Vector3.zero }
    end
    
    local data = TargetData[target]
    local now = tick()
    local dt = now - data.LastTick
    local currentPos = trackingPart.Position
    
    local calculatedVel = Vector3.zero
    if dt > 0.001 and dt < 1 then
        calculatedVel = (currentPos - data.LastPos) / dt
    end
    
    data.LastPos = currentPos
    data.LastTick = now
    
    local engineVel = trackingPart.AssemblyLinearVelocity
    local realVel = engineVel
    
    if engineVel.Magnitude > 150 or math.abs(engineVel.Y) > 150 or (engineVel - data.LastVel).Magnitude > 200 then
        if calculatedVel.Magnitude > 0.1 then
            realVel = calculatedVel
        else
            realVel = Vector3.zero
        end
    end
    
    if realVel.Magnitude > 350 then
        realVel = realVel.Unit * 350
    end
    
    data.LastVel = engineVel
    data.SmoothVel = data.SmoothVel:Lerp(realVel, 0.85)
    return data.SmoothVel
end

local function GetPing()
    local success, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000 end)
    return success and ping or 0.1
end

-- // SILENT AIM RE-HOOK
local send = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Send")
local oldFire
oldFire = hookfunction(send.FireServer, function(self, ...)
    local args = {...}
    if SilentAimEnabled and IsHoldingAllowedGun(args) then
        local target = GetClosestTarget()
        CurrentAimbotTarget = target
        
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(SelectedBodyPart) or target.Character:FindFirstChild("HumanoidRootPart")
            local root = target.Character:FindFirstChild("HumanoidRootPart")
            
            if targetPart and root then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local CurrentPosition = myRoot and myRoot.Position or Camera.CFrame.Position
                local TargetPosition = targetPart.Position
                
                local TargetVelocity = GetResolvedVelocity(target, root)
                local Distance = (TargetPosition - CurrentPosition).Magnitude
                local Ping = GetPing()
                
                local TotalTimeOffset = (Distance / BulletSpeed) + Ping
                local AimPosition = TargetPosition + (TargetVelocity * TotalTimeOffset)
                
                if TargetVelocity.Y < -5 then
                    local dropOffset = 0.5 * workspace.Gravity * (TotalTimeOffset ^ 2)
                    AimPosition = AimPosition - Vector3.new(0, dropOffset, 0)
                end

                if type(args[4]) == "userdata" then args[4] = CFrame.new(math.huge, math.huge, math.huge) end
                
                if type(args[5]) == "table" then
                    for i, bullet in pairs(args[5]) do
                        if type(bullet) == "table" and bullet[1] then
                            bullet[1]["Instance"] = targetPart
                            bullet[1]["Position"] = AimPosition
                        end
                    end
                end
            end
        end
    else
        CurrentAimbotTarget = nil
    end
    return oldFire(self, unpack(args))
end)

-- // STAMINA ENGINE MODIFICATION
pcall(function()
    local getupvalue = getupvalue or (debug and debug.getupvalue)
    local getgc = getgc or getgc
    local OriginalSprintUpdate = nil
    local SprintModule = require(ReplicatedStorage.Modules.Game.Sprint)
    local consume_stamina = SprintModule.consume_stamina

    if getupvalue then
        local SprintBar = getupvalue(consume_stamina, 2).sprint_bar
        if SprintBar then
            OriginalSprintUpdate = SprintBar.update
            SprintBar.update = function(...)
                if infStamEnabled then
                    return OriginalSprintUpdate(function() return 1 end)
                else
                    return OriginalSprintUpdate(...)
                end
            end
        end
    end

    task.spawn(function()
        if not getgc then return end
        local ct = nil
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and rawget(obj, "event") and rawget(obj, "func") then ct = obj break end
        end
        if not ct then return end
        local Send = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Send")
        while true do
            if infStamEnabled then
                ct.event = (ct.event or 0) + 1
                pcall(function() Send:FireServer(ct.event, "set_sprinting_1", true) end)
                task.wait(0.5)
                ct.event = (ct.event or 0) + 1
                pcall(function() Send:FireServer(ct.event, "set_sprinting_1", false) end)
            end
            task.wait(0.1)
        end
    end)
end)

-- // JUMP MECHANIC SYNC
local function setJumpPower(power)
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.UseJumpPower = true; hum.JumpPower = math.clamp(power, 0, maxJumpPower) end
end

local function startAntiDeadLoop()
    if isAntiDead then return end 
    isAntiDead = true
    local char = LocalPlayer.Character
    local hum = char:WaitForChild("Humanoid")
    local root = char:WaitForChild("HumanoidRootPart")

    task.spawn(function()
        while antiDeadEnabled and hum.Health > 0 and isAntiDead and hum.Health < 30 do
            hum.PlatformStand = true
            for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false end end
            root.Velocity = Vector3.zero
            root.CFrame = CFrame.new(root.Position.X, workspace.Terrain.Position.Y - 50, root.Position.Z)
            RunService.Heartbeat:Wait()
        end
        isAntiDead = false 
        hum.PlatformStand = false
        for _, part in pairs(char:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = true end end
    end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid")
    hum.UseJumpPower = true
    task.wait(0.1)
    setJumpPower(highJumpEnabled and highJumpPower or defaultJumpPower)
    
    if antiDeadEnabled and hum.Health <= 25 and not isAntiDead then startAntiDeadLoop() end
    hum.HealthChanged:Connect(function(hp)
        if antiDeadEnabled then
            if hp <= 25 and not isAntiDead then startAntiDeadLoop() 
            elseif hp >= 30 and isAntiDead then isAntiDead = false end
        end
    end)
end)

-- // ESP UTILITY FUNCTIONS
local function draw(drawingType, properties)
    if not Drawing then return nil end
    local drawing = Drawing.new(drawingType)
    for index, value in pairs(properties) do drawing[index] = value end
    return drawing
end

local function isAlive(player)
    return player and player.Character and player.Character:FindFirstChild('Humanoid') and player.Character.Humanoid.Health > 0
end

local function Get2dWorld(part)
    local success, pos, onScreen = pcall(function() return Camera:WorldToViewportPoint(part.Position) end)
    if success and pos then return Vector2.new(pos.X, pos.Y), pos.Z, onScreen end
    return Vector2.new(0, 0), 0, false
end

local function GetColorFromRarity(itemObj)
    local rarity = itemObj:GetAttribute('RarityName')
    if rarity == "Common" then
        return Color3.fromRGB(255, 255, 255)
    elseif rarity == "UnCommon" then
        return Color3.fromRGB(2, 177, 17)
    elseif rarity == "Rare" then
        return Color3.fromRGB(1, 132, 255)
    elseif rarity == "Legendary" then
        return Color3.fromRGB(255, 160, 6)
    elseif rarity == "Epic" then
        return Color3.fromRGB(150, 2, 255)
    elseif rarity == "Omega" then 
        return Color3.fromRGB(255, 6, 10)
    else 
        return Color3.fromRGB(255, 255, 255)
    end
end

-- // HIGH-PERFORMANCE LOW-LATENCY HOLLOW ESP BOX & SCALED SYSTEM
local function CreateESP(player)
    if player == LocalPlayer then return end
    if player_drawings[player] then return end
    player_drawings[player] = {
        box = draw("Square", {Visible = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1.2, Transparency = 1, Filled = false}),
        hpbar = draw("Line", {Visible = false, Color = Color3.new(0, 1, 0), Thickness = 1.5}),
        name = draw("Text", {Visible = false, Color = Color3.new(1, 1, 1), Size = 10, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Text = player.Name}),
        dist = draw("Text", {Visible = false, Color = Color3.new(1, 1, 1), Size = 9, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Text = ""})
    }
end

local function RemoveESP(player)
    if player_drawings[player] then
        for _, drawing in pairs(player_drawings[player]) do if drawing.Remove then drawing:Remove() end end
        player_drawings[player] = nil
    end
end

for _, player in pairs(Players:GetPlayers()) do CreateESP(player) end
Players.PlayerAdded:Connect(CreateESP)
Players.PlayerRemoving:Connect(RemoveESP)

local function getDroppedFolder()
    local names = {"DroppedItems", "Dropped", "Loot", "Items"}
    for _, name in ipairs(names) do
        local folder = workspace:FindFirstChild(name)
        if folder then return folder end
    end
    return nil
end

-- // RENDERSTEPPED PERFORMANCE PIPELINE (LAG FREE PIPELINE)
RunService.RenderStepped:Connect(function(delta)
    local localChar = LocalPlayer.Character
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")

    if speedEnabled and localChar and localRoot then
        local hum = localChar:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            localRoot.CFrame = localRoot.CFrame + hum.MoveDirection.Unit * speedMultiplier * delta * 60
        end
    end

    if SinkEnabled and localChar and localRoot then
        for _, part in pairs(localChar:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = false end end
        localRoot.CFrame = CFrame.new(localRoot.Position.X, workspace.Terrain.Position.Y - SinkDepth, localRoot.Position.Z)
    end

    if FakeAntiAim and localChar and localRoot then
        for _, part in pairs(localChar:GetChildren()) do if part:IsA("BasePart") then part.CanCollide = true end end
        localRoot.AssemblyLinearVelocity = Vector3.new(math.random(-450, 450), 0, math.random(-450, 450))
    end

    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    if showFov then
        FOVCircle.Color = RainbowFOV and Color3.fromHSV(tick() % 5 / 5, 1, 1) or Color3.fromRGB(255, 105, 180)
    end

    TargetLine.Visible = false
    CurrentAimbotTarget = GetClosestTarget()

    if SilentAimEnabled then
        local myHead = localChar and localChar:FindFirstChild("Head")
        local targetHead = CurrentAimbotTarget and CurrentAimbotTarget.Character and CurrentAimbotTarget.Character:FindFirstChild("Head")
        if myHead and targetHead then
            local tPos, onScreen = Camera:WorldToViewportPoint(targetHead.Position)
            if onScreen then
                local my2D = Vector2.new(Camera:WorldToViewportPoint(myHead.Position).X, Camera:WorldToViewportPoint(myHead.Position).Y)
                local t2D = Vector2.new(tPos.X, tPos.Y)
                local distFromCenter = (t2D - Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)).Magnitude
                if not showFov or distFromCenter <= FOVCircle.Radius then
                    TracerLine.From, TracerLine.To, TracerLine.Visible = my2D, t2D, true
                else TracerLine.Visible = false end
            else TracerLine.Visible = false end
        else TracerLine.Visible = false end
    else TracerLine.Visible = false end

    -- PLAYER ESP MONITOR
    for player, drawings in pairs(player_drawings) do
        local Char = player.Character
        local hum = Char and Char:FindFirstChild('Humanoid')
        local root = Char and Char:FindFirstChild('HumanoidRootPart')
        local head = Char and Char:FindFirstChild('Head')

        if Char and hum and head and root and localRoot and isAlive(player) then 
            local rootpos, sizeScreen, on = Get2dWorld(root)
            
            if on then 
                local headHeightPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))
                local feetHeightPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
                
                local boxHeight = math.abs(headHeightPos.Y - feetHeightPos.Y)
                local boxWidth = boxHeight * 0.65

                local isTargeted = (SilentAimEnabled and player == CurrentAimbotTarget)
                local espColor = isTargeted and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)

                local box = drawings.box
                box.Size = Vector2.new(boxWidth, boxHeight)
                box.Position = Vector2.new(rootpos.X - boxWidth / 2, rootpos.Y - boxHeight / 2)
                box.Color = espColor
                box.Visible = _G.EnabledBox or false

                if isTargeted and _G.EnabledBox then
                    TargetLine.From = Vector2.new(box.Position.X + box.Size.X / 2, box.Position.Y - 10)
                    TargetLine.To = Vector2.new(box.Position.X + box.Size.X / 2, box.Position.Y + box.Size.Y + 10)
                    TargetLine.Visible = true
                end

                local hpbar = drawings.hpbar
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                hpbar.From = Vector2.new(box.Position.X - 6, box.Position.Y + boxHeight * (1 - hp))
                hpbar.To   = Vector2.new(box.Position.X - 6, box.Position.Y + boxHeight)
                hpbar.Color = Color3.new(1 - hp, hp, 0)
                hpbar.Visible = _G.EnabledHpBar or false

                local scaledFontSize = math.clamp(math.floor(1400 / sizeScreen), 8, 11)

                local name = drawings.name
                name.Position = Vector2.new(box.Position.X + boxWidth / 2, box.Position.Y - (scaledFontSize + 4))
                name.Size = scaledFontSize
                name.Color = espColor
                name.Visible = _G.EnabledName or false

                local dist = drawings.dist
                dist.Position = Vector2.new(box.Position.X + boxWidth / 2, box.Position.Y + boxHeight + 2)
                dist.Size = scaledFontSize - 1
                dist.Text = "[" .. tostring(math.floor((root.Position - localRoot.Position).Magnitude)) .. "m]"
                dist.Color = espColor
                dist.Visible = _G.EnabledDistance or false
            else
                for _, d in pairs(drawings) do d.Visible = false end    
            end
        else 
            for _, d in pairs(drawings) do d.Visible = false end
        end  
    end

    -- ITEM DROPPED ESP PIPELINE (INTEGRATED SYSTEM)
    local dropfolder = getDroppedFolder()
    
    -- ทำการล้างวาดเส้นไอเทมที่ถูกลบออกจากเกมไปแล้ว หรือเมื่อสั่งปิดฟังก์ชัน
    for i, d in pairs(item_drawings) do
        if not i or not i.Parent or not _G.EnabledItemDrop then
            if d.box then d.box:Remove() end
            if d.name then d.name:Remove() end
            if d.dist then d.dist:Remove() end
            item_drawings[i] = nil
        end
    end

    -- สั่งลูปสแกนและวาดไอเทมถ้าปุ่มเปิดใช้งานอยู่
    if _G.EnabledItemDrop and dropfolder then
        for _, item in pairs(dropfolder:GetChildren()) do
            if item:IsA("Model") and item:FindFirstChild("PickUpZone") and not item:GetAttribute('Locked') then
                local itemesp = item_drawings[item]

                if not itemesp and Drawing then 
                    itemesp = {
                        box = draw("Square", {Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Filled = false}),
                        name = draw("Text", {Color = Color3.fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13}),
                        dist = draw("Text", {Color = Color3.fromRGB(255, 255, 255), Outline = true, Center = true, Size = 11}),
                    }
                    item_drawings[item] = itemesp
                end

                if itemesp then
                    local pickpos, sizeScreen, on = Get2dWorld(item.PickUpZone)
                    local sizescale = math.clamp(200 / sizeScreen, 20, 60)
                    local shouldShow = _G.EnabledItemDrop and on

                    itemesp.box.Size = Vector2.new(sizescale, sizescale)
                    itemesp.box.Position = Vector2.new(pickpos.X - sizescale/2, pickpos.Y - sizescale/2)
                    itemesp.box.Visible = shouldShow

                    itemesp.name.Text = item.Name
                    itemesp.name.Position = Vector2.new(pickpos.X, pickpos.Y - sizescale/2 - 14)
                    itemesp.name.Visible = shouldShow

                    if item.Name ~= "Money" then
                        local colorFound = false
                        if ReplicatedStorage:FindFirstChild("Items") then
                            for _, x in pairs(ReplicatedStorage.Items:GetChildren()) do 
                                for _, b in pairs(x:GetChildren()) do 
                                    if tostring(item.Name) == tostring(b.Name) then 
                                        local rarityColor = GetColorFromRarity(b)
                                        itemesp.box.Color = rarityColor
                                        itemesp.name.Color = rarityColor
                                        colorFound = true
                                        break
                                    end
                                end
                                if colorFound then break end
                            end
                        end
                        if not colorFound then
                            itemesp.box.Color = Color3.fromRGB(255, 255, 255)
                            itemesp.name.Color = Color3.fromRGB(255, 255, 255)
                        end
                    else 
                        itemesp.box.Color = Color3.fromRGB(85, 255, 127) -- ให้สีเงินเขียวตามสไตล์ของสคริปต์หลัก
                        itemesp.name.Color = Color3.fromRGB(85, 255, 127)
                    end

                    local AmountItem = item:FindFirstChild("AmountBillboardGui") and item.AmountBillboardGui:FindFirstChild("TextLabel")
                    itemesp.dist.Text = "[" .. (AmountItem and AmountItem.Text or "1") .. "]"
                    itemesp.dist.Position = Vector2.new(pickpos.X, pickpos.Y + sizescale/2 + 2)
                    itemesp.dist.Visible = shouldShow
                end
            end
        end
    end
end)

-- // LOOT MAGNET FILTER AND COMPILATION ENGINE
local ItemDatabase = {}
pcall(function() for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do if obj:IsA("Tool") then local rarity = obj:GetAttribute("RarityName") or obj:GetAttribute("Rarity") or obj:GetAttribute("Tier"); if rarity then ItemDatabase[obj.Name] = rarity end end end end)

local function getItemRarity(item)
    local dbRarity = ItemDatabase[item.Name]; if dbRarity then return dbRarity end
    local attrRarity = item:GetAttribute("RarityName") or item:GetAttribute("Rarity"); if attrRarity then return attrRarity end
    local rarityValue = item:FindFirstChild("Rarity") or item:FindFirstChild("Tier"); if rarityValue and rarityValue:IsA("StringValue") then return rarityValue.Value end
    return "Default"
end

local remoteGet = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Get")

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local droppedItems = getDroppedFolder()
    
    if hrp and droppedItems then
        for _, item in pairs(droppedItems:GetChildren()) do
            local itemRarity = getItemRarity(item)
            local isBlocked = MagnetConfig.Ignore[itemRarity]
            
            pcall(function()
                for _, part in ipairs(item:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if isBlocked then
                            if part:GetAttribute("OrigCanTouch") == nil then part:SetAttribute("OrigCanTouch", part.CanTouch); part:SetAttribute("OrigCanCollide", part.CanCollide) end
                            part.CanTouch, part.CanCollide = false, false
                        else
                            if part:GetAttribute("OrigCanTouch") ~= nil then part.CanTouch = part:GetAttribute("OrigCanTouch"); part.CanCollide = part:GetAttribute("OrigCanCollide"); part:SetAttribute("OrigCanTouch", nil); part:SetAttribute("OrigCanCollide", nil) end
                        end
                    end
                end
            end)
            
            local zone = item:FindFirstChild("PickUpZone")
            if zone and zone:IsA("BasePart") then
                if isBlocked or not MagnetConfig.Enabled then zone.Size = Vector3.new(0.1, 0.1, 0.1) else zone.Size = Vector3.new(120, 14, 120); zone.Transparency = 1; zone.CanCollide = false; zone.Anchored = true end
            end
            
            if isBlocked or not MagnetConfig.Enabled then continue end
            local prompt = item:FindFirstChildWhichIsA("ProximityPrompt", true)
            if not prompt then continue end
            
            if (hrp.Position - item.Position).Magnitude <= MagnetConfig.Radius then
                task.spawn(function() pcall(function() remoteGet:InvokeServer("pickup_dropped_item", item) end) end)
            end
        end
    end
end)
