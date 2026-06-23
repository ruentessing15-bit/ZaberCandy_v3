-- // Zaber candy [ULTIMATE HYBRID - DELTA OPTIMIZED - BUG FIXED]
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- // CLEANUP PREVIOUS RUNS
if _G.ZaberCandyCleanup then _G.ZaberCandyCleanup() end

-- // GLOBAL DATA TABLES
local BillboardCache = {}
local player_esp_data = {}
local TargetData = {}
local WeaponDB = {}
local Connections = {}

-- // UI SETUP
local Window = WindUI:CreateWindow({
    Title = "Zaber candy",
    Author = "Developer [Nong R]",
    Folder = "Zaber_Candy_Config",
    Icon = "rbxassetid://97643133348071",
    Transparent = true,
    Theme = "Dark",
    Font = "Gotham",
    CustomBackground = "rbxassetid://97643133348071",
    HideSearchBar = false,
})

Window:EditOpenButton({ Enabled = false })
WindUI:Notify({ Title = "System Verified", Content = "Zaber candy Systems Loaded.", Duration = 4 })

-- // Floating Button
loadstring(game:HttpGet("https://raw.githubusercontent.com/Yenixs/ToolScript/refs/heads/main/GuiToggle.luau"))()("rbxassetid://97643133348071", function()
    Window:Toggle()
end)

-- // TABS
local CombatTab = Window:Tab({Title = "Combat", Icon = "sword"})
local PlayerTab = Window:Tab({Title = "Player", Icon = "user"})
local ESPTab = Window:Tab({Title = "ESP", Icon = "eye"})
local LootTab = Window:Tab({Title = "Auto Loot", Icon = "box"}) 
local MiscTab = Window:Tab({Title = "Misc & FPS", Icon = "settings"})

-- // VARIABLES
local RARITY_COLORS = {["Common"] = Color3.fromRGB(255, 255, 255), ["Uncommon"] = Color3.fromRGB(99, 255, 52), ["Rare"] = Color3.fromRGB(51, 170, 255), ["Epic"] = Color3.fromRGB(237, 44, 255), ["Legendary"] = Color3.fromRGB(255, 150, 0), ["Omega"] = Color3.fromRGB(255, 20, 51), ["Money"] = Color3.fromRGB(85, 255, 127), ["Default"] = Color3.fromRGB(255, 255, 255)}
local SelectedBodyPart = "Head"; local SilentAimEnabled = false; local showFov = false; local BulletSpeed = 1500
local GunLookup = {["P226"]=true, ["MP5"]=true, ["M24"]=true, ["Draco"]=true, ["Glock"]=true, ["Sawnoff"]=true, ["Uzi"]=true, ["G3"]=true, ["C9"]=true, ["Hunting Rifle"]=true, ["Anaconda"]=true, ["AK47"]=true, ["Remington"]=true, ["Double Barrel"]=true, ["Skorpion"]=true}

local FOVCircle = Drawing.new("Circle"); FOVCircle.Radius = 150; FOVCircle.Thickness = 1; FOVCircle.Filled = false; FOVCircle.Color = Color3.fromRGB(255,105,180); FOVCircle.Visible = false
local TracerLine = Drawing.new("Line"); TracerLine.Color = Color3.fromRGB(255,0,0); TracerLine.Thickness = 2; TracerLine.Visible = false

-- // PLAYER MODS VARS
local speedEnabled = false; local speedMultiplier = 0.10; local antiDeadEnabled = false; local infStamEnabled = false; local MagnetConfig = { Enabled = false, Radius = 20 }

-- // ESP VARS
_G.EnabledBox = false; _G.EnabledHpBar = false; _G.EnabledName = false; _G.EnabledDistance = false; local ItemESP_Enabled = true

-- ==========================================
-- // CORE LOGIC
-- ==========================================
local function GetTargetPart(character) return character and character:FindFirstChild(SelectedBodyPart) end

local function GetClosestTarget()
    local closest, shortest = nil, math.huge; local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Humanoid") and plr.Character.Humanoid.Health > 0 then
            local part = GetTargetPart(plr.Character)
            if part then
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if (not showFov or dist <= FOVCircle.Radius) and dist < shortest then shortest = dist closest = plr end
                end
            end
        end
    end
    return closest
end

local function GetResolvedVelocity(target, root)
    if not root or not target.Character then return Vector3.zero end
    local hum = target.Character:FindFirstChildOfClass("Humanoid"); local trackingPart = (hum and hum.SeatPart) and hum.SeatPart or root
    if not TargetData[target] then TargetData[target] = { LastPos = trackingPart.Position, LastTick = tick(), SmoothVel = Vector3.zero } end
    local data = TargetData[target]; local now, dt = tick(), tick() - data.LastTick
    local calculatedVel = (dt > 0.01 and dt < 1) and (trackingPart.Position - data.LastPos) / dt or Vector3.zero
    
    -- UPDATE LAST POS AND TICK (FIXED)
    data.LastPos = trackingPart.Position
    data.LastTick = now
    
    local realVel = trackingPart.AssemblyLinearVelocity
    if realVel.Magnitude > 250 or realVel.Magnitude < 2 then if calculatedVel.Magnitude > 1 then realVel = calculatedVel end end
    data.SmoothVel = data.SmoothVel:Lerp(realVel.Magnitude > 500 and realVel.Unit * 500 or realVel, 0.75)
    return data.SmoothVel
end

local send = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Send")
local oldFire
oldFire = hookfunction(send.FireServer, function(self, ...)
    local args = {...}; local isGun = false
    pcall(function() if typeof(args[3])=="Instance" and GunLookup[args[3].Name] then isGun = true end end)
    if not isGun and LocalPlayer.Character then for _, t in pairs(LocalPlayer.Character:GetChildren()) do if (t:IsA("Tool") or t:IsA("Model")) and GunLookup[t.Name] then isGun = true break end end end
    if SilentAimEnabled and isGun then
        local target = GetClosestTarget(); 
        if target and target.Character then
            local tPart = target.Character:FindFirstChild(SelectedBodyPart) or target.Character:FindFirstChild("HumanoidRootPart")
            local root = target.Character:FindFirstChild("HumanoidRootPart")
            if tPart and root then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local curPos = myRoot and myRoot.Position or Camera.CFrame.Position
                local dist = (tPart.Position - curPos).Magnitude; local ping = (Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000) or 0.1
                local offset = (dist / BulletSpeed) + ping; local aimPos = tPart.Position + (GetResolvedVelocity(target, root) * offset)
                if type(args[4]) == "userdata" then args[4] = CFrame.new(9e9, 9e9, 9e9) end
                if type(args[5]) == "table" then for _, b in pairs(args[5]) do if type(b) == "table" and b[1] then b[1]["Instance"], b[1]["Position"] = tPart, aimPos end end end
            end
        end
    end
    return oldFire(self, unpack(args))
end)

-- // ITEM ESP LOGIC
local function generateUniqueKey(tool)
    if not tool or not tool:IsA("Tool") then return nil end
    local itemId = tool:GetAttribute("ItemId") or tool:GetAttribute("Id")
    if itemId and itemId ~= "" then return "ITEMID_" .. tostring(itemId) end
    return "NAME_" .. (tool:GetAttribute("DisplayName") or tool.Name) .. "_" .. tool.Name
end

local function registerItems(folder)
    if not folder then return end
    for _, tool in ipairs(folder:GetDescendants()) do
        if tool:IsA("Tool") then
            local key = generateUniqueKey(tool)
            if key then WeaponDB[key] = {Name = tool:GetAttribute("DisplayName") or tool.Name, Rarity = tool:GetAttribute("RarityName") or "Common", ImageId = tool:GetAttribute("ImageId") or "rbxassetid://7072725737"} end
        end
    end
end
pcall(function() registerItems(ReplicatedStorage:WaitForChild("Items", 5)) registerItems(game:GetService("StarterPack")) end)

local function createBillboardForPlayer(player)
    if player == LocalPlayer or BillboardCache[player] then return end
    local billboard = Instance.new("BillboardGui"); billboard.Name = "ItemESP"; billboard.Size = UDim2.new(0, 280, 0, 40); billboard.StudsOffset = Vector3.new(0, -6.5, 0); billboard.AlwaysOnTop = true; billboard.Enabled = ItemESP_Enabled
    local container = Instance.new("Frame", billboard); container.Size = UDim2.new(1, 0, 1, 0); container.BackgroundTransparency = 1
    local layout = Instance.new("UIGridLayout", container); layout.CellSize = UDim2.new(0, 35, 0, 35); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    local function updateInventory()
        if not ItemESP_Enabled or not billboard.Parent then return end
        container:ClearAllChildren(); layout.Parent = container
        local tools = {}
        local function scan(f) if f then for _, t in ipairs(f:GetChildren()) do if t:IsA("Tool") and t.Name ~= "Fists" then local info = WeaponDB[generateUniqueKey(t)]; if info then table.insert(tools, info) end end end end end
        scan(player.Character); scan(player:FindFirstChild("Backpack"))
        for _, info in ipairs(tools) do
            local img = Instance.new("ImageLabel", container); img.Size = UDim2.new(0, 35, 0, 35); img.BackgroundTransparency = 1; img.Image = info.ImageId; img.ImageColor3 = (RARITY_COLORS[info.Rarity] or Color3.new(1,1,1)):Lerp(Color3.new(1,1,1), 0.35)
        end
    end

    BillboardCache[player] = billboard
    
    local function setupChar(char)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if root then billboard.Adornee = root; billboard.Parent = root; updateInventory() end
        -- REFRESH ON ITEM CHANGE (FIXED)
        local c1 = char.ChildAdded:Connect(updateInventory)
        local c2 = char.ChildRemoved:Connect(updateInventory)
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            local c3 = backpack.ChildAdded:Connect(updateInventory)
            local c4 = backpack.ChildRemoved:Connect(updateInventory)
            table.insert(Connections, c3); table.insert(Connections, c4)
        end
        table.insert(Connections, c1); table.insert(Connections, c2)
    end

    if player.Character then setupChar(player.Character) end
    local c5 = player.CharacterAdded:Connect(setupChar)
    table.insert(Connections, c5)
end

-- // PLAYER ESP LOGIC
local function createPlayerESP(player)
    if player == LocalPlayer or player_esp_data[player] then return end
    local esp = {
        Box = Drawing.new("Quad"), Name = Drawing.new("Text"), Distance = Drawing.new("Text"),
        HealthBar = Drawing.new("Quad"), HealthBarOutline = Drawing.new("Quad")
    }
    esp.Box.Color = Color3.new(1,1,1); esp.Box.Thickness = 1; esp.Box.Filled = false
    esp.Name.Color = Color3.new(1,1,1); esp.Name.Size = 14; esp.Name.Outline = true; esp.Name.Center = true
    esp.Distance.Color = Color3.new(1,1,1); esp.Distance.Size = 12; esp.Distance.Outline = true; esp.Distance.Center = true
    esp.HealthBarOutline.Color = Color3.new(0,0,0); esp.HealthBarOutline.Filled = true
    esp.HealthBar.Filled = true
    player_esp_data[player] = esp
end

local function updatePlayerESP(player)
    local esp = player_esp_data[player]
    if not esp then return end
    local char = player.Character; local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart"); local head = char and char:FindFirstChild("Head")
    
    -- NIL CHECK (FIXED)
    if not (char and hum and root and head and hum.Health > 0) then
        for _, v in pairs(esp) do v.Visible = false end return
    end

    local screenHead, onHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local screenFeet, onFeet = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

    if onHead or onFeet then
        local height = math.abs(screenHead.Y - screenFeet.Y)
        local width = height / 2; local x = screenHead.X - (width / 2); local y = screenHead.Y

        esp.Box.PointA = Vector2.new(x + width, y); esp.Box.PointB = Vector2.new(x, y)
        esp.Box.PointC = Vector2.new(x, y + height); esp.Box.PointD = Vector2.new(x + width, y + height)
        esp.Box.Visible = _G.EnabledBox

        esp.Name.Text = player.DisplayName; esp.Name.Position = Vector2.new(x + width / 2, y - 16); esp.Name.Visible = _G.EnabledName

        -- SAFE DISTANCE CHECK (FIXED)
        local lChar = LocalPlayer.Character; local lRoot = lChar and lChar:FindFirstChild("HumanoidRootPart")
        if lRoot then
            local dist = math.floor((lRoot.Position - root.Position).Magnitude)
            esp.Distance.Text = tostring(dist) .. "m"; esp.Distance.Position = Vector2.new(x + width / 2, y + height + 2); esp.Distance.Visible = _G.EnabledDistance
        else esp.Distance.Visible = false end

        local healthRatio = hum.Health / hum.MaxHealth
        local hBarX = x - 6; esp.HealthBarOutline.PointA = Vector2.new(hBarX + 4, y); esp.HealthBarOutline.PointB = Vector2.new(hBarX, y)
        esp.HealthBarOutline.PointC = Vector2.new(hBarX, y + height); esp.HealthBarOutline.PointD = Vector2.new(hBarX + 4, y + height)
        esp.HealthBarOutline.Visible = _G.EnabledHpBar

        local hHeight = height * healthRatio
        esp.HealthBar.PointA = Vector2.new(hBarX + 3, y + (height - hHeight)); esp.HealthBar.PointB = Vector2.new(hBarX + 1, y + (height - hHeight))
        esp.HealthBar.PointC = Vector2.new(hBarX + 1, y + height); esp.HealthBar.PointD = Vector2.new(hBarX + 3, y + height)
        esp.HealthBar.Color = Color3.fromHSV(healthRatio * 0.3, 1, 1); esp.HealthBar.Visible = _G.EnabledHpBar
    else
        for _, v in pairs(esp) do v.Visible = false end
    end
end

-- // CLEANUP FUNCTION (FIXED MEMORY LEAK)
_G.ZaberCandyCleanup = function()
    for _, c in pairs(Connections) do c:Disconnect() end
    for _, esp in pairs(player_esp_data) do for _, v in pairs(esp) do v:Remove() end end
    for _, b in pairs(BillboardCache) do b:Destroy() end
    FOVCircle:Remove(); TracerLine:Remove()
    player_esp_data = {}; BillboardCache = {}; TargetData = {}; Connections = {}
end

-- // UI CONNECTIONS
CombatTab:Toggle({ Title = "Enable Silent Aim", Default = false, Callback = function(v) SilentAimEnabled = v end })
CombatTab:Dropdown({ Title = "Target BodyPart", Default = "Head", Values = {"Head", "HumanoidRootPart"}, Callback = function(v) SelectedBodyPart = v end })
CombatTab:Toggle({ Title = "Show FOV Circle", Default = false, Callback = function(v) showFov = v; FOVCircle.Visible = v end })

PlayerTab:Toggle({ Title = "Enable Walk Speed", Default = false, Callback = function(s) speedEnabled = s end })
PlayerTab:Slider({ Title = "Speed Multiplier", Value = {Min = 0.05, Max = 0.15, Default = 0.10}, Step = 0.01, Callback = function(v) speedMultiplier = tonumber(v) end })
PlayerTab:Toggle({ Title = "Infinite Stamina", Default = false, Callback = function(s) infStamEnabled = s end })

ESPTab:Toggle({ Title = "Show Box", Default = false, Callback = function(s) _G.EnabledBox = s end })
ESPTab:Toggle({ Title = "Show Name", Default = false, Callback = function(s) _G.EnabledName = s end })
ESPTab:Toggle({ Title = "Show Distance", Default = false, Callback = function(s) _G.EnabledDistance = s end })
ESPTab:Toggle({ Title = "Show HP Bar", Default = false, Callback = function(s) _G.EnabledHpBar = s end })
ESPTab:Toggle({ Title = "Inventory View", Default = true, Callback = function(s) ItemESP_Enabled = s; for _, b in pairs(BillboardCache) do b.Enabled = s end end })

LootTab:Toggle({ Title = "Enable Auto PickUp", Default = false, Callback = function(s) MagnetConfig.Enabled = s end })

-- // MAIN LOOPS
task.spawn(function()
    while task.wait(0.1) do
        if infStamEnabled then pcall(function() send:FireServer(math.random(1,1000), "set_sprinting_1", true) end) end
    end
end)

RunService.RenderStepped:Connect(function(delta)
    local lChar = LocalPlayer.Character; local lRoot = lChar and lChar:FindFirstChild("HumanoidRootPart")
    if speedEnabled and lRoot then 
        local hum = lChar:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then lRoot.CFrame = lRoot.CFrame + hum.MoveDirection.Unit * speedMultiplier * delta * 60 end 
    end
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    -- UPDATE ESP (OPTIMIZED LOOP)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if not player_esp_data[plr] then createPlayerESP(plr) end
            updatePlayerESP(plr)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if MagnetConfig.Enabled and LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local dropFolder = workspace:FindFirstChild("DroppedItems") or workspace:FindFirstChild("Dropped") or workspace:FindFirstChild("Loot")
        if hrp and dropFolder then
            for _, item in pairs(dropFolder:GetChildren()) do
                if (hrp.Position - item:GetPivot().Position).Magnitude <= MagnetConfig.Radius then 
                    pcall(function() ReplicatedStorage.Remotes.Get:InvokeServer("pickup_dropped_item", item) end) 
                end
            end
        end
    end
end)

-- // INITIALIZE
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then createBillboardForPlayer(p) end end
Players.PlayerAdded:Connect(function(p) if p ~= LocalPlayer then createBillboardForPlayer(p) end end)
Players.PlayerRemoving:Connect(function(p)
    if player_esp_data[p] then for _, v in pairs(player_esp_data[p]) do v:Remove() end player_esp_data[p] = nil end
    if BillboardCache[p] then BillboardCache[p]:Destroy(); BillboardCache[p] = nil end
    TargetData[p] = nil
end)
