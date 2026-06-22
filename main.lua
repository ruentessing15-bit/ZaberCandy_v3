-- // Zaber candy🍬 [Full Integrated Script - English Only]
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
WindUI:Notify({ Title = "System Verified", Content = "Welcome. All systems are fully operational.", Duration = 4 })

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

local player_drawings = {}
local HeadOff = Vector3.new(0, 0.5, 0)
local LegOff = Vector3.new(0, 3, 0)

-- // ITEM INVENTORY ESP VARIABLES
local ItemESP_Enabled = false
local BillboardCache = {}
local ItemESP_UpdateConnections = {}
local WeaponDB = {}
local PreloadedImages = {}

-- // CORE VARIABLES (LOOT MAGNET)
local MagnetConfig = { Enabled = false, Radius = 2000, Ignore = { Common = false, Uncommon = false, Rare = false, Epic = false, Legendary = false, Omega = false, Default = false } }
local ItemDatabase = {}
local ESP_Settings = { DroppedItems = false }
local DropESP_Cache = {}


-- ==========================================
-- // ITEM ESP SCANNER & COMPILER ENGINE
-- ==========================================

local function generateUniqueKey(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local itemId = tool:GetAttribute("ItemId") or tool:GetAttribute("Id")
    if itemId and itemId ~= "" and (typeof(itemId) == "string" or typeof(itemId) == "number") then
        return "ITEMID_" .. tostring(itemId)
    end
    local partsData = {}
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("SpecialMesh") and part.MeshId and part.MeshId ~= "" and part.MeshId ~= "rbxassetid://" then
            table.insert(partsData, "MESH_"..part.MeshId.."|TEX_"..(part.TextureId or "NOTEX"))
        elseif part:IsA("MeshPart") and part.MeshId and part.MeshId ~= "" and part.MeshId ~= "rbxassetid://" then
            table.insert(partsData, "MESH_"..part.MeshId.."|TEX_"..(part.TextureID or "NOTEX"))
        elseif part:IsA("Decal") and part.Texture and part.Texture ~= "" and part.Texture ~= "rbxassetid://" then
            table.insert(partsData, "DECAL_"..part.Texture)
        elseif part:IsA("Part") then
            table.insert(partsData, "PART_"..part.Name.."_"..part.Size.X.."x"..part.Size.Y.."x"..part.Size.Z)
        end
    end
    if #partsData > 0 then
        table.sort(partsData)
        return "MESHKEY_" .. table.concat(partsData, ";")
    end
    local displayName = tool:GetAttribute("DisplayName") or tool.Name
    local toolName = tool.Name
    local rarity = tool:GetAttribute("RarityName") or tool:GetAttribute("Rarity") or "Unknown"
    local imageId = tool:GetAttribute("ImageId") or "NOIMAGE"
    return "NAME_" .. displayName .. "_" .. toolName .. "_" .. rarity .. "_" .. imageId
end

local function registerItems(folder)
    for _, tool in ipairs(folder:GetDescendants()) do
        if not tool:IsA("Tool") then continue end
        local key = generateUniqueKey(tool)
        if not key then continue end
        local displayName = tool:GetAttribute("DisplayName") or tool.Name
        local imageId = tool:GetAttribute("ImageId") or "rbxassetid://7072725737"
        local rarity = tool:GetAttribute("RarityName") or tool:GetAttribute("Rarity") or "Common"
        WeaponDB[key] = {
            Name = displayName,
            Rarity = rarity,
            ImageId = imageId,
            ToolName = tool.Name,
            Key = key
        }
        if imageId and imageId ~= "" and not PreloadedImages[imageId] then
            PreloadedImages[imageId] = true
            task.spawn(function()
                pcall(function()
                    ContentProvider:PreloadAsync({imageId})
                end)
            end)
        end
    end
end

pcall(function()
    local itemsFolder = ReplicatedStorage:WaitForChild("Items", 5)
    if itemsFolder then registerItems(itemsFolder) end
    for _, obj in ipairs(ReplicatedStorage:GetChildren()) do
        if obj:IsA("Folder") and (obj.Name:find("Weapon") or obj.Name:find("Item") or obj.Name:find("Tool")) then
            registerItems(obj)
        end
    end
    registerItems(game:GetService("StarterPack"))
end)

local function getWeaponInfo(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local key = generateUniqueKey(tool)
    return WeaponDB[key]
end

local function createBillboardForPlayer(player)
    if player == LocalPlayer or BillboardCache[player] then return end
    local billboard, container, layout
    local connections = {}

    local function updateESP()
        if not ItemESP_Enabled or not billboard or not billboard.Parent then return end
        local currentTools = {}
        
        local function scan(folder)
            if not folder then return end
            for _, tool in ipairs(folder:GetChildren()) do
                if tool:IsA("Tool") and tool.Name ~= "Fists" then
                    local info = getWeaponInfo(tool)
                    if info then
                        table.insert(currentTools, info)
                    end
                end
            end
        end

        local char = player.Character
        if char then
            scan(char)
            local backpack = player:FindFirstChild("Backpack")
            if backpack then scan(backpack) end
        end

        container:ClearAllChildren()
        layout = Instance.new("UIGridLayout")
        layout.CellSize = UDim2.new(0, 35, 0, 35)
        layout.CellPadding = UDim2.new(0, 6, 0, 0)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = container

        for i, info in ipairs(currentTools) do
            local img = Instance.new("ImageLabel")
            img.Parent = container
            img.Size = UDim2.new(0, 35, 0, 35)
            img.BackgroundTransparency = 1
            img.Image = info.ImageId or "rbxassetid://7072725737"
            img.ScaleType = Enum.ScaleType.Fit
            img.LayoutOrder = i
            local color = RARITY_COLORS[info.Rarity] or Color3.fromRGB(255, 255, 255)
            img.ImageColor3 = color:Lerp(Color3.new(1,1,1), 0.35)
        end
    end

    local function setupBillboard()
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        if BillboardCache[player] then
            BillboardCache[player]:Destroy()
        end
        for _, conn in pairs(connections) do
            if conn.Connected then conn:Disconnect() end
        end
        connections = {}

        billboard = Instance.new("BillboardGui")
        billboard.Name = "PlayerItemESP"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 280, 0, 40)
        billboard.StudsOffset = Vector3.new(0, -6.5, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.MaxDistance = math.huge -- [ปรับแก้] มองเห็นระยะไกลไร้ขีดจำกัดทั่วแมพ
        billboard.Enabled = ItemESP_Enabled
        billboard.Parent = hrp

        container = Instance.new("Frame", billboard)
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        
        BillboardCache[player] = billboard
        updateESP()

        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            table.insert(connections, backpack.ChildAdded:Connect(updateESP))
            table.insert(connections, backpack.ChildRemoved:Connect(updateESP))
        end

        table.insert(connections, char.ChildAdded:Connect(function(child)
            if child:IsA("Tool") then task.defer(updateESP) end
        end))
        table.insert(connections, char.ChildRemoved:Connect(function(child)
            if child:IsA("Tool") then task.defer(updateESP) end
        end))
        table.insert(connections, player.ChildAdded:Connect(function(child)
            if child.Name == "Backpack" then
                task.wait()
                table.insert(connections, child.ChildAdded:Connect(updateESP))
                table.insert(connections, child.ChildRemoved:Connect(updateESP))
                updateESP()
            end
        end))
    end

    if player.Character then task.spawn(setupBillboard) end
    table.insert(connections, player.CharacterAdded:Connect(function()
        task.wait(1)
        setupBillboard()
    end))
    ItemESP_UpdateConnections[player] = connections
end


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
PlayerTab:Toggle({ Title = "Anti-Aim (Desync View)", Default = false, Callback = function(s) FakeAntiAim = s end })
PlayerTab:Toggle({ Title = "Underground Noclip", Default = false, Callback = function(s) SinkEnabled = s end })
PlayerTab:Slider({ Title = "Underground Depth", Value = {Min = 1, Max = 100, Default = SinkDepth}, Step = 1, Callback = function(v) SinkDepth = tonumber(v) end })
PlayerTab:Toggle({ Title = "Anti-Dead (Evasion under 25 HP)", Default = false, Callback = function(s) antiDeadEnabled = s end })

-- ESP Tab
ESPTab:Toggle({ Title = "Show Box", Default = false, Callback = function(s) _G.EnabledBox = s end })
ESPTab:Toggle({ Title = "Show Health", Default = false, Callback = function(s) _G.EnabledHpBar = s end })
ESPTab:Toggle({ Title = "Show Name", Default = false, Callback = function(s) _G.EnabledName = s end })
ESPTab:Toggle({ Title = "Show Distance (m)", Default = false, Callback = function(s) _G.EnabledDistance = s end })
ESPTab:Toggle({ Title = "Show Dropped Items (Name Only)", Default = false, Callback = function(s) ESP_Settings.DroppedItems = s end })

-- [เพิ่มฟังก์ชันนี้เข้าไป] Toggle Item Inventory ESP ของคนอื่น
ESPTab:Toggle({
    Title = "Player Item Inventory ESP",
    Desc = "ส่องดูไอเทมในกระเป๋าและในมือคนอื่น",
    Default = false,
    Callback = function(state)
        ItemESP_Enabled = state
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local billboard = BillboardCache[player]
                if billboard then
                    billboard.Enabled = state
                elseif state then
                    createBillboardForPlayer(player)
                end
            end
        end
    end
})

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

local function GetResolvedVelocity(target, root)
    if not root or not target.Character then return Vector3.zero end
    
    local hum = target.Character:FindFirstChildOfClass("Humanoid")
    local trackingPart = (hum and hum.SeatPart) and hum.SeatPart or root
    
    if not TargetData[target] then
        TargetData[target] = { LastPos = trackingPart.Position, LastTick = tick(), SmoothVel = Vector3.zero }
    end
    
    local data = TargetData[target]
    local now = tick()
    local dt = now - data.LastTick
    local currentPos = trackingPart.Position
    
    local calculatedVel = Vector3.zero
    if dt > 0.01 and dt < 1 then
        calculatedVel = (currentPos - data.LastPos) / dt
    end
    
    data.LastPos = currentPos
    data.LastTick = now
    
    local engineVel = trackingPart.AssemblyLinearVelocity
    local realVel = engineVel
    
    if engineVel.Magnitude > 250 or engineVel.Magnitude < 2 then
        if calculatedVel.Magnitude > 1 then
            realVel = calculatedVel
        end
    end
    
    if realVel.Magnitude > 500 then
        realVel = realVel.Unit * 500
    end
    
    data.SmoothVel = data.SmoothVel:Lerp(realVel, 0.75)
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
            root.CFrame = CFrame.new(root.Position.X, workspace.Terrain.Position.Y - 50, root.Position.Z) * CFrame.Angles(0, tick() * 20, 0)
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

local function CreateESP(player)
    if player == LocalPlayer then return end
    if player_drawings[player] then return end
    player_drawings[player] = {
        box = draw("Square", {Visible = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1.5, Transparency = 1, Filled = false}),
        hpbar = draw("Line", {Visible = false, Color = Color3.new(0, 1, 0), Thickness = 2}),
        name = draw("Text", {Visible = false, Color = Color3.new(1, 1, 1), Size = 14, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Text = player.Name}),
        dist = draw("Text", {Visible = false, Color = Color3.new(1, 1, 1), Size = 14, Center = true, Outline = true, OutlineColor = Color3.new(0, 0, 0), Text = ""})
    }
    createBillboardForPlayer(player) -- เริ่มระบบสร้างบิลบอร์ดตรวจไอเทมเมื่อเจอผู้เล่น
end

local function RemoveESP(player)
    if player_drawings[player] then
        for _, drawing in pairs(player_drawings[player]) do if drawing.Remove then drawing:Remove() end end
        player_drawings[player] = nil
    end
    if BillboardCache[player] then
        BillboardCache[player]:Destroy()
        BillboardCache[player] = nil
    end
    if ItemESP_UpdateConnections[player] then
        for _, conn in pairs(ItemESP_UpdateConnections[player]) do
            if conn.Connected then conn:Disconnect() end
        end
        ItemESP_UpdateConnections[player] = nil
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

-- // DROPPED ITEMS INTERFACES (MAP DROPS)
task.spawn(function()
    while task.wait(1) do
        if not ESP_Settings.DroppedItems then
            for item, bg in pairs(DropESP_Cache) do if bg then bg:Destroy() end end
            DropESP_Cache = {}
            continue
        end

        local droppedFolder = getDroppedFolder()
        if droppedFolder then
            for item, bg in pairs(DropESP_Cache) do
                if not item.Parent or not item.Parent:IsDescendantOf(workspace) then
                    if bg then bg:Destroy() end
                    DropESP_Cache[item] = nil
                end
            end

            for _, item in pairs(droppedFolder:GetChildren()) do
                if not DropESP_Cache[item] then
                    local part = item:IsA("BasePart") and item or item:FindFirstChildWhichIsA("BasePart")
                    if part then
                        local rarity = item:GetAttribute("Rarity") or (item.Name:lower():match("money") and "Money") or "Common"
                        local exactColor = RARITY_COLORS[rarity] or RARITY_COLORS["Default"]
                  
                        local bg = Instance.new("BillboardGui", part)
                        bg.Size = UDim2.new(0, 100, 0, 30); bg.AlwaysOnTop = true; bg.LightInfluence = 0; bg.MaxDistance = math.huge; bg.ExtentsOffset = Vector3.new(0, 1, 0)
                        
                        local txt = Instance.new("TextLabel", bg)
                        txt.Size = UDim2.new(1, 0, 0, 12); txt.Position = UDim2.new(0, 0, 0, 0); txt.BackgroundTransparency = 1; txt.Text = item.Name; txt.TextColor3 = exactColor; txt.TextStrokeTransparency = 0; txt.Font = Enum.Font.GothamBold; txt.TextSize = 11
                        
                        DropESP_Cache[item] = bg
                    end
                end
            end
        end
    end
end)

-- // RENDERSTEPPED PIPELINE LOOP
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
        localRoot.CFrame = localRoot.CFrame * CFrame.Angles(0, math.rad(math.random(-180,180)), 0)
        localRoot.AssemblyLinearVelocity = Vector3.new(math.random(-500,500), math.random(-500,500), math.random(-500,500))
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

    for player, drawings in pairs(player_drawings) do
        local Char = player.Character
        local hum = Char and Char:FindFirstChild('Humanoid')
        local root = Char and Char:FindFirstChild('HumanoidRootPart')
        local head = Char and Char:FindFirstChild('Head')

        if Char and hum and head and root and localRoot and isAlive(player) then 
            local rootpos, sizeScreen, on = Get2dWorld(root)
            
            if on then 
                local headpos = Camera:WorldToViewportPoint(head.Position + HeadOff)
                local legpos = Camera:WorldToViewportPoint(root.Position - LegOff)
                
                local box = drawings.box
                box.Size = Vector2.new(1000 / sizeScreen, headpos.Y - legpos.Y)
                box.Position = Vector2.new(rootpos.X - box.Size.X / 2, rootpos.Y - box.Size.Y / 2)
                
                local isTargeted = (SilentAimEnabled and player == CurrentAimbotTarget)
                local espColor = isTargeted and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)

                box.Color = espColor
                box.Visible = _G.EnabledBox or false

                if isTargeted and _G.EnabledBox then
                    TargetLine.From = Vector2.new(box.Position.X + box.Size.X / 2, box.Position.Y - 10)
                    TargetLine.To = Vector2.new(box.Position.X + box.Size.X / 2, box.Position.Y + box.Size.Y + 10)
                    TargetLine.Visible = true
                end

                local hpbar = drawings.hpbar
                local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                hpbar.From = Vector2.new(box.Position.X + box.Size.X + 5, box.Position.Y + box.Size.Y * (1 - hp))
                hpbar.To   = Vector2.new(box.Position.X + box.Size.X + 5, box.Position.Y + box.Size.Y)
                hpbar.Color = Color3.new(1 - hp, hp, 0)
                hpbar.Visible = _G.EnabledHpBar or false

                local name = drawings.name
                name.Position = Vector2.new(box.Position.X + box.Size.X / 2, headpos.Y - 20)
                name.Color = espColor
                name.Visible = _G.EnabledName or false

                local dist = drawings.dist
                dist.Position = Vector2.new(box.Position.X + box.Size.X / 2, headpos.Y)
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
end)

-- // LOOT MAGNET FILTER AND COMPILATION ENGINE
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
