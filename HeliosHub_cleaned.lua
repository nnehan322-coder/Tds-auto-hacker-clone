-- Load WindUI
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()

-- Create main window
local Window = WindUI:CreateWindow({
    Title = "HeliosHub",
    Folder = "HeliosHub",
    Icon = "solar:gamepad-bold-duotone",
    OpenButton = {
        Title = "Open HeliosHub",
        CornerRadius = UDim.new(1, 0),
        StrokeThickness = 3,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        Scale = 0.6,
        Color = ColorSequence.new(Color3.fromHex("#30FF6A"), Color3.fromHex("#e7ff2f")),
    },
    Topbar = { Height = 44, ButtonsType = "Mac" },
})

Window:Tag({ Title = "v1.0", Icon = "github", Color = Color3.fromHex("#1c1c1c"), Border = true })

-- Hide/show button
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HeliosHubToggle"
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false

local btn = Instance.new("TextButton")
btn.Parent = gui
btn.Size = UDim2.new(0, 45, 0, 45)
btn.Position = UDim2.new(0, 20, 0.5, 0)
btn.Text = "H"
btn.TextColor3 = Color3.fromRGB(255,255,255)
btn.TextSize = 18
btn.BackgroundColor3 = Color3.fromRGB(20,20,20)
btn.AutoButtonColor = true
Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)

local dragging = false
local dragStart
local startPos
btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = btn.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local open = true
btn.MouseButton1Click:Connect(function()
    if open then
        Window:Close()
    else
        Window:Open()
    end
    open = not open
end)

-- Global references
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RemoteFunc = ReplicatedStorage:WaitForChild("RemoteFunction")
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local LocalPlayer = game.Players.LocalPlayer
local mouse = LocalPlayer:GetMouse()
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- AUTOMATION TAB (without Pursuit)
local AutomationTab = Window:Tab({ Title = "Automation", Icon = "solar:bot-bold", IconColor = Color3.fromHex("#30FF6A"), Border = true })

-- Auto Skip Waves
local AutoSkipRunning = false
local AutoSkipThread = nil
local function RunVoteSkip() pcall(function() RemoteFunc:InvokeServer("Voting", "Skip") end) end
local function StartAutoSkip()
    if AutoSkipRunning then return end
    AutoSkipRunning = true
    AutoSkipThread = task.spawn(function()
        while AutoSkipRunning do
            local skipVisible = PlayerGui:FindFirstChild("ReactOverridesVote")
                and PlayerGui.ReactOverridesVote:FindFirstChild("Frame")
                and PlayerGui.ReactOverridesVote.Frame:FindFirstChild("votes")
                and PlayerGui.ReactOverridesVote.Frame.votes:FindFirstChild("vote")
            if skipVisible and skipVisible.Position == UDim2.new(0.5, 0, 0.5, 0) then
                RunVoteSkip()
            end
            task.wait(1)
        end
    end)
end
local function StopAutoSkip() AutoSkipRunning = false; if AutoSkipThread then task.cancel(AutoSkipThread) end end
AutomationTab:Toggle({
    Title = "Auto Skip Waves",
    Desc = "Automatically skips waves when the vote appears",
    Callback = function(v) if v then StartAutoSkip() else StopAutoSkip() end end,
})
AutomationTab:Space()

-- Auto Commander Chain
local AutoChainRunning = false
local AutoChainThread = nil
local function StartAutoChain()
    if AutoChainRunning then return end
    AutoChainRunning = true
    AutoChainThread = task.spawn(function()
        local idx = 1
        while AutoChainRunning do
            local commanders = {}
            local towersFolder = workspace:FindFirstChild("Towers")
            if towersFolder then
                for _, obj in ipairs(towersFolder:GetDescendants()) do
                    if obj:IsA("Folder") and obj.Name == "TowerReplicator"
                        and obj:GetAttribute("Name") == "Commander"
                        and obj:GetAttribute("OwnerId") == LocalPlayer.UserId
                        and (obj:GetAttribute("Upgrade") or 0) >= 2 then
                        commanders[#commanders + 1] = obj.Parent
                    end
                end
            end
            if #commanders >= 3 then
                if idx > #commanders then idx = 1 end
                local current = commanders[idx]
                local response = RemoteFunc:InvokeServer("Troops", "Abilities", "Activate", { Troop = current, Name = "Call Of Arms", Data = {} })
                if response then
                    idx = idx + 1
                    local hotbar = PlayerGui:FindFirstChild("ReactUniversalHotbar")
                    local timescaleFrame = hotbar and hotbar:FindFirstChild("Frame") and hotbar.Frame:FindFirstChild("timescale")
                    if timescaleFrame and timescaleFrame.Visible then
                        if timescaleFrame:FindFirstChild("Lock") then task.wait(10.3) else task.wait(5.25) end
                    else
                        task.wait(10.3)
                    end
                else
                    task.wait(0.5)
                end
            else
                task.wait(1)
            end
        end
    end)
end
local function StopAutoChain() AutoChainRunning = false; if AutoChainThread then task.cancel(AutoChainThread) end end
AutomationTab:Toggle({
    Title = "Auto Commander Chain",
    Desc = "Cycles through your Commanders and uses Call Of Arms",
    Callback = function(v) if v then StartAutoChain() else StopAutoChain() end end,
})
AutomationTab:Space()

-- Auto DJ Booth
local AutoDJRunning = false
local AutoDJThread = nil
local function StartAutoDJ()
    if AutoDJRunning then return end
    AutoDJRunning = true
    AutoDJThread = task.spawn(function()
        while AutoDJRunning do
            local dj = nil
            local towersFolder = workspace:FindFirstChild("Towers")
            if towersFolder then
                for _, obj in ipairs(towersFolder:GetDescendants()) do
                    if obj:IsA("Folder") and obj.Name == "TowerReplicator"
                        and obj:GetAttribute("Name") == "DJ Booth"
                        and obj:GetAttribute("OwnerId") == LocalPlayer.UserId
                        and (obj:GetAttribute("Upgrade") or 0) >= 3 then
                        dj = obj.Parent
                        break
                    end
                end
            end
            if dj then
                pcall(function()
                    RemoteFunc:InvokeServer("Troops", "Abilities", "Activate", { Troop = dj, Name = "Drop The Beat", Data = {} })
                end)
            end
            task.wait(1)
        end
    end)
end
local function StopAutoDJ() AutoDJRunning = false; if AutoDJThread then task.cancel(AutoDJThread) end end
AutomationTab:Toggle({
    Title = "Auto DJ Booth",
    Desc = "Activates DJ Booth 'Drop The Beat' (upgrade ≥3)",
    Callback = function(v) if v then StartAutoDJ() else StopAutoDJ() end end,
})
AutomationTab:Space()

-- Auto Necro (25 sec cooldown)
local AutoNecroRunning = false
local AutoNecroThread = nil
local function StartAutoNecro()
    if AutoNecroRunning then return end
    AutoNecroRunning = true
    AutoNecroThread = task.spawn(function()
        local lastActivation = 0
        while AutoNecroRunning do
            local towersFolder = workspace:FindFirstChild("Towers")
            local necromancers = {}
            if towersFolder then
                for _, obj in ipairs(towersFolder:GetDescendants()) do
                    if obj:IsA("Folder") and obj.Name == "TowerReplicator"
                        and obj:GetAttribute("Name") == "Necromancer"
                        and obj:GetAttribute("OwnerId") == LocalPlayer.UserId then
                        necromancers[#necromancers + 1] = obj.Parent
                    end
                end
            end
            local now = tick()
            if #necromancers > 0 and (now - lastActivation) >= 25 then
                for _, necro in ipairs(necromancers) do
                    pcall(function()
                        RemoteFunc:InvokeServer("Troops", "Abilities", "Activate", { Troop = necro, Name = "Raise The Dead", Data = {} })
                    end)
                end
                lastActivation = now
            end
            task.wait(1)
        end
    end)
end
local function StopAutoNecro() AutoNecroRunning = false; if AutoNecroThread then task.cancel(AutoNecroThread) end end
AutomationTab:Toggle({
    Title = "Auto Necro",
    Desc = "Uses Necromancer 'Raise The Dead' (25 sec cooldown)",
    Callback = function(v) if v then StartAutoNecro() else StopAutoNecro() end end,
})
AutomationTab:Space()

-- Auto Mercenary Base with dynamic path slider
local AutoMercenaryRunning = false
local AutoMercenaryThread = nil
local MercenaryPathDistance = 195
local MaxPathDistance = 300

local function FindPath()
    local MapFolder = workspace:FindFirstChild("Map")
    if not MapFolder then return nil end
    local PathsFolder = MapFolder:FindFirstChild("Paths")
    if not PathsFolder then return nil end
    local PathFolder = PathsFolder:GetChildren()[1]
    if not PathFolder then return nil end
    local PathNodes = {}
    for _, node in ipairs(PathFolder:GetChildren()) do
        if node:IsA("BasePart") then
            table.insert(PathNodes, node)
        end
    end
    table.sort(PathNodes, function(a, b)
        local NumA = tonumber(a.Name:match("%d+"))
        local NumB = tonumber(b.Name:match("%d+"))
        if NumA and NumB then return NumA < NumB end
        return a.Name < b.Name
    end)
    return PathNodes
end

local function TotalLength(PathNodes)
    local total = 0
    for i = 1, #PathNodes - 1 do
        total = total + (PathNodes[i + 1].Position - PathNodes[i].Position).Magnitude
    end
    return total
end

-- Slider defined FIRST so UpdateMaxPathDistance can reference it
local MercenarySlider = AutomationTab:Slider({
    Title = "Mercenary Path Distance",
    Desc = "Distance from the base where the air-drop lands (auto-updates to map length)",
    IsTooltip = true,
    IsTextbox = true,
    Step = 1,
    Value = {
        Min = 0,
        Max = MaxPathDistance,
        Default = MercenaryPathDistance,
    },
    Callback = function(value) MercenaryPathDistance = value end,
})

local function UpdateMaxPathDistance()
    local map = workspace:FindFirstChild("Map")
    if PlayerGui:FindFirstChild("ReactUniversalHotbar") and map then
        local nodes = FindPath()
        if nodes and #nodes > 0 then
            MaxPathDistance = TotalLength(nodes)
            MercenarySlider:SetMax(MaxPathDistance)
            return true
        end
    end
    return false
end

AutomationTab:Toggle({
    Title = "Auto Mercenary Base",
    Desc = "Uses Air-Drop ability on all level 5+ Mercenary Bases",
    Callback = function(v)
        if v then
            if AutoMercenaryRunning then return end
            AutoMercenaryRunning = true
            AutoMercenaryThread = task.spawn(function()
                while AutoMercenaryRunning do
                    local towersFolder = workspace:FindFirstChild("Towers")
                    if towersFolder then
                        for _, obj in ipairs(towersFolder:GetDescendants()) do
                            if obj:IsA("Folder") and obj.Name == "TowerReplicator"
                                and obj:GetAttribute("Name") == "Mercenary Base"
                                and obj:GetAttribute("OwnerId") == LocalPlayer.UserId
                                and (obj:GetAttribute("Upgrade") or 0) >= 5 then
                                pcall(function()
                                    RemoteFunc:InvokeServer("Troops", "Abilities", "Activate", {
                                        Troop = obj.Parent,
                                        Name = "Air-Drop",
                                        Data = { pathName = 1, directionCFrame = CFrame.new(), dist = MercenaryPathDistance }
                                    })
                                end)
                            end
                        end
                    end
                    task.wait(0.5)
                end
            end)
        else
            AutoMercenaryRunning = false
            if AutoMercenaryThread then task.cancel(AutoMercenaryThread) end
        end
    end,
})

task.spawn(function()
    while true do
        UpdateMaxPathDistance()
        task.wait(2)
    end
end)

-- AUTO PURSUIT PATROL (All Towers)

-- Find ALL owned Pursuit towers
local function GetAllPursuits()
    local pursuits = {}
    local towersFolder = workspace:FindFirstChild("Towers")
    if not towersFolder then return pursuits end
    for _, obj in ipairs(towersFolder:GetDescendants()) do
        if obj:IsA("Folder") and obj.Name == "TowerReplicator"
            and obj:GetAttribute("Name") == "Pursuit"
            and obj:GetAttribute("OwnerId") == LocalPlayer.UserId then
            pursuits[#pursuits + 1] = obj.Parent
        end
    end
    return pursuits
end

-- Enemy detection (models with "Enemy" in name)
local function GetAnyEnemy()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and string.find(obj.Name, "Enemy") then
            return obj
        end
    end
    return nil
end

-- Purple ESP on the targeted enemy
local currentHighlight = nil
local function HighlightEnemy(enemy)
    if currentHighlight then currentHighlight:Destroy() end
    if not enemy then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(128, 0, 255)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.Parent = enemy
    currentHighlight = highlight
    task.delay(2, function()
        if highlight and highlight.Parent then highlight:Destroy() end
        if currentHighlight == highlight then currentHighlight = nil end
    end)
end

local AutoPursuitRunning = false
local AutoPursuitThread = nil

-- Simultaneous mode: all Pursuits patrol at once every 10 seconds
local function StartAutoPursuit()
    if AutoPursuitRunning then return end
    AutoPursuitRunning = true
    AutoPursuitThread = task.spawn(function()
        while AutoPursuitRunning do
            local pursuits = GetAllPursuits()
            if #pursuits > 0 then
                local enemy = GetAnyEnemy()
                if enemy then
                    HighlightEnemy(enemy)
                    local targetPos = enemy:GetPivot().Position
                    for _, pursuit in ipairs(pursuits) do
                        pcall(function()
                            RemoteFunc:InvokeServer("Troops", "Abilities", "Activate", {
                                Troop = pursuit,
                                Name = "Patrol",
                                Data = { position = targetPos }
                            })
                        end)
                        task.wait(0.1)
                    end
                end
            end
            task.wait(1)
        end
    end)
end

local function StopAutoPursuit()
    AutoPursuitRunning = false
    if AutoPursuitThread then task.cancel(AutoPursuitThread) end
    if currentHighlight then currentHighlight:Destroy() end
end

AutomationTab:Toggle({
    Title = "Auto Pursuit Patrol (All Towers)",
    Desc = "Every 10 sec, ALL your Pursuits patrol to the first enemy",
    Callback = function(v) if v then StartAutoPursuit() else StopAutoPursuit() end end,
})

AutomationTab:Space()

--  AUTO GATLING (external script by Warry. I love him if you're reading this for some reason)
-- Auto Gatling (checks for an active round)
AutomationTab:Toggle({
    Title = "Auto Gatling (shoot all ammo at once)",
    Desc = "Credits to Warry. Type 60 in multiplier to shoot all ammo at once.",
    Value = false,
    Callback = function(v)
        if v then
            -- Check if we are in a game round (not lobby)
            local inGame = false
            local playerGui = game.Players.LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                inGame = playerGui:FindFirstChild("ReactUniversalHotbar") ~= nil
            end
            if not inGame then
                WindUI:Notify({
                    Title = "HeliosHub",
                    Content = "You need to be in a round to execute that script.",
                    Duration = 5,
                    Type = "error"
                })
                -- Turn the toggle back off
                v = false
                -- The callback cannot directly reset the toggle value.
                return
            end
            -- Load the script only once
            if not _G.GatlingLoaded then
                _G.GatlingLoaded = true
                local success, err = pcall(function()
                    loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/ahhsempai/diddler-gatling/main/diddler.lua"))()
                end)
                if success then
                    WindUI:Notify({
                        Title = "HeliosHub",
                        Content = "Auto Gatling loaded. Adjust multiplier in the script's settings.",
                        Duration = 5
                    })
                else
                    WindUI:Notify({
                        Title = "HeliosHub",
                        Content = "Failed to load Gatling script: " .. tostring(err),
                        Duration = 5,
                        Type = "error"
                    })
                    _G.GatlingLoaded = nil
                end
            else
                WindUI:Notify({
                    Title = "HeliosHub",
                    Content = "Auto Gatling already loaded. Reload script to load again.",
                    Duration = 3,
                    Type = "warning"
                })
            end
        else
            WindUI:Notify({
                Title = "HeliosHub",
                Content = "Auto Gatling cannot be unloaded. Restart the game to disable.",
                Duration = 4,
                Type = "warning"
            })
        end
    end
})

-- PART 2: TOWERS TAB (two dropdowns with source toggle)
local TowersTab = Window:Tab({ Title = "Towers", Icon = "solar:gamepad-bold", IconColor = Color3.fromHex("#FFA500"), Border = true })
task.wait(0.1)

-- GetEquippedTowers (from library)
local function GetEquippedTowers()
    local towers = {}
    local StateReplicators = game:GetService("ReplicatedStorage"):FindFirstChild("StateReplicators")
    if StateReplicators then
        for _, folder in ipairs(StateReplicators:GetChildren()) do
            if folder.Name == "PlayerReplicator" and folder:GetAttribute("UserId") == LocalPlayer.UserId then
                local equipped = folder:GetAttribute("EquippedTowers")
                if type(equipped) == "string" then
                    local CleanedJson = equipped:match("%[.*%]")
                    local success, TowerTable = pcall(function()
                        return HttpService:JSONDecode(CleanedJson)
                    end)
                    if success and type(TowerTable) == "table" then
                        for i = 1, 5 do
                            if TowerTable[i] then
                                table.insert(towers, TowerTable[i])
                            end
                        end
                    end
                end
                break
            end
        end
    end
    if #towers == 0 then table.insert(towers, "None") end
    return towers
end

-- Full tower list (all towers)
local ALL_TOWERS = {
    "Paintballer", "Scout", "Soldier", "Sniper", "Demoman", "Shotgunner", "Assassin", "Farm",
    "Electroshocker", "Medic", "Military Base", "Freezer", "Ace Pilot", "Trapper", "Militant",
    "Pyromancer", "Crook Boss", "Hunter", "Rocketeer", "Cowboy", "Saboteur", "Commander", "Warden",
    "DJ Booth", "Mortar", "Minigunner", "Tesla", "Mercenary Base", "Mecha Base", "Ranger", "Pursuit", "Gatling Gun",
    "Turret", "Brawler", "Engineer", "Hacker", "Necromancer", "Accelerator", "Commando", "Gladiator",
    "Slasher", "Archer", "Frost Blaster", "Swarmer", "Toxic Gunner", "Elf Camp", "Jester", "Cryomancer",
    "Halloween Punk", "Snowballer", "Harvester", "Elementalist", "Spotlight Technician",
    "Firework Technician", "Biologist", "Warlock", "War Machine", "EvolvedJuggernaut", "EvolvedOperator", "EvolvedEnforcer"
}

-- Global variable for selected tower (will be updated by active dropdown)
_G.SelectedTower = nil

-- Tower Source Toggle (ON = use All Towers dropdown, OFF = use Equipped dropdown)
local useAllTowers = false   -- default to equipped towers
local equippedTower = nil
local allTower = nil

TowersTab:Section({ Title = "Tower Source", TextSize = 14 })
local sourceToggle = TowersTab:Toggle({
    Title = "Use All Towers List",
    Desc = "When ON: uses tower from 'All Towers' dropdown. When OFF: uses tower from 'Equipped Towers' dropdown.",
    Value = false,
    Callback = function(v)
        useAllTowers = v
        -- Update global selected tower based on current toggle state
        if useAllTowers then
            _G.SelectedTower = allTower or ALL_TOWERS[1]
        else
            _G.SelectedTower = equippedTower or "None"
        end
        WindUI:Notify({ Title = "HeliosHub", Content = "Now using " .. (useAllTowers and "All Towers" or "Equipped Towers") .. " selection.", Duration = 2 })
    end
})
TowersTab:Space()

-- Dropdown 1: Equipped Towers (auto‑refresh)
TowersTab:Section({ Title = "Equipped Towers", TextSize = 14 })
local equippedDropdown = TowersTab:Dropdown({
    Title = "Your Loadout",
    Desc = "Towers currently equipped",
    Values = GetEquippedTowers(),
    Value = "None",
    Callback = function(selected)
        equippedTower = selected
        if not useAllTowers then
            _G.SelectedTower = selected
        end
        -- No notification to avoid spam
    end
})
TowersTab:Space()

-- Refresh equipped dropdown every 5 seconds (no callback spam)
local isRefreshing = false
task.spawn(function()
    while true do
        task.wait(5)
        if isRefreshing then continue end
        isRefreshing = true
        local newList = GetEquippedTowers()
        equippedDropdown:Refresh(newList)
        if equippedTower and not table.find(newList, equippedTower) then
            equippedTower = nil
            if not useAllTowers then _G.SelectedTower = nil end
        end
        isRefreshing = false
    end
end)

-- Dropdown 2: All Towers (static)
TowersTab:Section({ Title = "All Towers", TextSize = 14 })
local allTowersDropdown = TowersTab:Dropdown({
    Title = "Full List",
    Desc = "Any tower in the game",
    Values = ALL_TOWERS,
    Value = ALL_TOWERS[1],
    Callback = function(selected)
        allTower = selected
        if useAllTowers then
            _G.SelectedTower = selected
        end
    end
})
TowersTab:Space()

-- STACKING (green sphere + triple‑tap)
local StackEnabled = false
local StackSphere = nil
local tapHistory = {}
local TAP_TIMEOUT = 0.5
local TAP_RADIUS = 30
local REQUIRED_TAPS = 3

local function isWithinRadius(pos1, pos2)
    return (pos1 - pos2).Magnitude <= TAP_RADIUS
end

local function placeStackedTower(position)
    if not StackEnabled or not _G.SelectedTower or _G.SelectedTower == "" then return end
    local newPos = Vector3.new(position.X, position.Y + 25, position.Z)
    pcall(function()
        RemoteFunc:InvokeServer("Troops", "Place", { Rotation = CFrame.new(), Position = newPos }, _G.SelectedTower)
    end)
    WindUI:Notify({ Title = "HeliosHub", Content = "Stacked tower placed", Duration = 2 })
end

local function recordTap(position)
    local now = tick()
    for i = #tapHistory, 1, -1 do
        if now - tapHistory[i].time > TAP_TIMEOUT then
            table.remove(tapHistory, i)
        end
    end
    table.insert(tapHistory, { pos = position, time = now })
    if #tapHistory >= REQUIRED_TAPS then
        local allSame = true
        for i = 2, REQUIRED_TAPS do
            if not isWithinRadius(tapHistory[1].pos, tapHistory[i].pos) then
                allSame = false
                break
            end
        end
        if allSame then
            placeStackedTower(tapHistory[1].pos)
            tapHistory = {}
        end
    end
end

local function UpdateStackSphere()
    if StackEnabled and _G.SelectedTower and _G.SelectedTower ~= "" then
        if not StackSphere then
            StackSphere = Instance.new("Part")
            StackSphere.Shape = Enum.PartType.Ball
            StackSphere.Size = Vector3.new(1.5, 1.5, 1.5)
            StackSphere.Color = Color3.fromRGB(0, 255, 0)
            StackSphere.Transparency = 0.5
            StackSphere.Anchored = true
            StackSphere.CanCollide = false
            StackSphere.Material = Enum.Material.Neon
            StackSphere.Parent = workspace
            mouse.TargetFilter = StackSphere
        end
        local hit = mouse.Hit
        if hit then StackSphere.Position = hit.Position end
    elseif StackSphere then
        StackSphere:Destroy()
        StackSphere = nil
        mouse.TargetFilter = nil
    end
end

TowersTab:Toggle({
    Title = "Stack Tower",
    Desc = "Green sphere follows finger. Triple‑tap the ground to place a stacked tower.",
    Callback = function(v)
        StackEnabled = v
        if not v and StackSphere then
            StackSphere:Destroy()
            StackSphere = nil
            mouse.TargetFilter = nil
            tapHistory = {}
        end
        if v and _G.SelectedTower and _G.SelectedTower ~= "" then
            WindUI:Notify({ Title = "HeliosHub", Content = "Stacking enabled. Triple‑tap to place " .. _G.SelectedTower, Duration = 4 })
        elseif v and (not _G.SelectedTower or _G.SelectedTower == "") then
            WindUI:Notify({ Title = "HeliosHub", Content = "Select a tower source and choose a tower first.", Duration = 3, Type = "warning" })
        end
    end,
})
TowersTab:Space()

local function onInputBegan(input, gameProcessed)
    if gameProcessed then return end
    if not StackEnabled or not _G.SelectedTower or _G.SelectedTower == "" then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local unitRay = mouse.UnitRay
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        if StackSphere then raycastParams.FilterDescendantsInstances = { StackSphere } end
        local raycastResult = workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, raycastParams)
        if raycastResult then
            recordTap(raycastResult.Position)
        end
    end
end
UserInputService.InputBegan:Connect(onInputBegan)
RunService.RenderStepped:Connect(UpdateStackSphere)

-- TOWER MANAGEMENT BUTTONS (Upgrade/Sell)
-- UPGRADE LEVEL DROPDOWN & NEW UPGRADE BUTTON
TowersTab:Section({ Title = "Upgrade Settings", TextSize = 14 })
local targetUpgradeLevel = 5
local levelDropdown = TowersTab:Dropdown({
    Title = "Target Upgrade Level",
    Desc = "Upgrade all selected towers to this level (1‑7)",
    Values = {"1", "2", "3", "4", "5", "6", "7"},
    Value = "5",
    Callback = function(choice)
        targetUpgradeLevel = tonumber(choice) or 5
    end
})
TowersTab:Space()

-- Helper: get in‑game cash (same path as before)
local function GetCash()
    local cashLabel = LocalPlayer.PlayerGui:FindFirstChild("ReactUniversalHotbar")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar:FindFirstChild("Frame")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame:FindFirstChild("values")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame.values:FindFirstChild("cash")
        and LocalPlayer.PlayerGui.ReactUniversalHotbar.Frame.values.cash:FindFirstChild("amount")
    if cashLabel then
        local text = cashLabel.Text
        local numStr = text:gsub("[$,]", "")
        return tonumber(numStr) or 0
    end
    return 0
end

-- Helper: get upgrade level of a tower
local function GetUpgradeLevel(tower)
    local replicator = tower:FindFirstChild("TowerReplicator")
    if replicator then
        return replicator:GetAttribute("Upgrade") or 0
    end
    return 0
end

-- Helper: upgrade a single tower to target level (waits for cash)
local function UpgradeTowerToLevel(tower, targetLvl)
    local current = GetUpgradeLevel(tower)
    if current >= targetLvl then return true end
    while current < targetLvl do
        local success, result = pcall(function()
            return RemoteFunc:InvokeServer("Troops", "Upgrade", "Set", { Troop = tower, Path = 1 })
        end)
        if success and (result == true or (type(result) == "table" and result.Success)) then
            current = current + 1
            task.wait(0.3)
        else
            -- insufficient cash – wait and retry
            local cash = GetCash()
            task.wait(2)
        end
    end
    return true
end

-- Helper: get all towers owned by the player
local function GetAllPlayerTowers()
    local towers = {}
    local towersFolder = workspace:FindFirstChild("Towers")
    if towersFolder then
        for _, model in ipairs(towersFolder:GetChildren()) do
            local replicator = model:FindFirstChild("TowerReplicator")
            if replicator and replicator:GetAttribute("OwnerId") == LocalPlayer.UserId then
                table.insert(towers, model)
            end
        end
    end
    return towers
end

-- NEW Upgrade Selected button (upgrades ALL towers of the selected type)
TowersTab:Button({
    Title = "Upgrade Selected",
    Justify = "Center",
    Color = Color3.fromRGB(0, 100, 200),
    Callback = function()
        if not _G.SelectedTower or _G.SelectedTower == "" then
            WindUI:Notify({ Title = "HeliosHub", Content = "No tower selected. Pick from either dropdown.", Duration = 3, Type = "error" })
            return
        end
        local towersToUpgrade = {}
        for _, tower in ipairs(GetAllPlayerTowers()) do
            local replicator = tower:FindFirstChild("TowerReplicator")
            if replicator and replicator:GetAttribute("Name") == _G.SelectedTower then
                table.insert(towersToUpgrade, tower)
            end
        end
        if #towersToUpgrade == 0 then
            WindUI:Notify({ Title = "HeliosHub", Content = "No towers of type " .. _G.SelectedTower .. " found.", Duration = 3, Type = "error" })
            return
        end
        WindUI:Notify({ Title = "HeliosHub", Content = "Upgrading " .. #towersToUpgrade .. " towers to level " .. targetUpgradeLevel, Duration = 3 })
        task.spawn(function()
            for _, tower in ipairs(towersToUpgrade) do
                UpgradeTowerToLevel(tower, targetUpgradeLevel)
            end
            WindUI:Notify({ Title = "HeliosHub", Content = "All " .. _G.SelectedTower .. " upgraded to level " .. targetUpgradeLevel, Duration = 3 })
        end)
    end,
})
TowersTab:Space()

Callback = function()
    if not _G.SelectedTower or _G.SelectedTower == "" then
        WindUI:Notify({ Title = "HeliosHub", Content = "No tower selected. Pick from dropdown.", Duration = 3, Type = "error" })
        return
    end
    local count = 0
    local failed = 0
    for _, tower in ipairs(GetPlayerTowers()) do
        local replicator = tower:FindFirstChild("TowerReplicator")
        if replicator and replicator:GetAttribute("Name") == _G.SelectedTower then
            local success, err = pcall(function()
                RemoteFunc:InvokeServer("Troops", "Sell", { Troop = tower })
            end)
            if success then
                count = count + 1
            else
                failed = failed + 1
                WindUI:Notify({ Title = "Debug", Content = "Failed to sell: " .. tower.Name .. " | Error: " .. tostring(err), Duration = 3, Type = "error" })
            end
        end
    end
    if count > 0 then
        WindUI:Notify({ Title = "HeliosHub", Content = "Sold " .. count .. " " .. _G.SelectedTower .. "(s)", Duration = 3 })
    else
        WindUI:Notify({ Title = "HeliosHub", Content = "No matching towers found. Check name.", Duration = 3, Type = "error" })
    end
    if failed > 0 then
        WindUI:Notify({ Title = "HeliosHub", Content = "Failed to sell " .. failed .. " tower(s). Check debug notifications.", Duration = 5, Type = "error" })
    end
end
TowersTab:Space()

TowersTab:Button({
    Title = "Upgrade All",
    Justify = "Center",
    Color = Color3.fromRGB(0, 150, 100),
    Callback = function()
        local count = 0
        for _, tower in ipairs(GetPlayerTowers()) do
            pcall(function() RemoteFunc:InvokeServer("Troops", "Upgrade", "Set", { Troop = tower }) end)
            count = count + 1
        end
        WindUI:Notify({ Title = "HeliosHub", Content = "Upgraded " .. count .. " towers", Duration = 3 })
    end,
})
TowersTab:Space()

TowersTab:Button({
    Title = "Sell All",
    Justify = "Center",
    Color = Color3.fromRGB(200, 30, 30),
    Callback = function()
        WindUI:Popup({
            Title = "Confirm Sell All",
            Content = "Sell ALL your towers? Cannot undo.",
            Buttons = {
                { Title = "Confirm", Variant = "Destructive", Callback = function()
                    local count = 0
                    for _, tower in ipairs(GetPlayerTowers()) do
                        pcall(function() RemoteFunc:InvokeServer("Troops", "Sell", { Troop = tower }) end)
                        count = count + 1
                    end
                    WindUI:Notify({ Title = "HeliosHub", Content = "Sold " .. count .. " towers", Duration = 3 })
                end },
                { Title = "Cancel", Variant = "Tertiary" }
            }
        })
    end,
})
-- TOWER TARGETING (apply to all selected towers)
TowersTab:Section({ Title = "Change Targeting", TextSize = 14 })

-- Targeting mode dropdown
local targetModes = {"First", "Last", "Strongest", "Weakest", "Closest", "Farthest", "Random"}
local selectedTargetMode = "First"

local targetDropdown = TowersTab:Dropdown({
    Title = "Targeting Mode",
    Desc = "Choose the targeting mode to change the selected towers into",
    Values = targetModes,
    Value = "First",
    Callback = function(choice)
        selectedTargetMode = choice
    end,
})
TowersTab:Space()

-- Button to apply targeting to all selected towers
TowersTab:Button({
    Title = "Change Targeting to Selected Towers",
    Justify = "Center",
    Color = Color3.fromRGB(0, 150, 200),
    Callback = function()
        if not _G.SelectedTower or _G.SelectedTower == "" then
            WindUI:Notify({ Title = "HeliosHub", Content = "No tower selected. Pick a tower from tower list.", Duration = 3, Type = "error" })
            return
        end

        local count = 0
        local towersFolder = workspace:FindFirstChild("Towers")
        if towersFolder then
            for _, model in ipairs(towersFolder:GetChildren()) do
                local replicator = model:FindFirstChild("TowerReplicator")
                if replicator and replicator:GetAttribute("OwnerId") == LocalPlayer.UserId then
                    if replicator:GetAttribute("Name") == _G.SelectedTower then
                        pcall(function()
                            RemoteFunc:InvokeServer("Troops", "Target", "Set", {
                                Troop = model,
                                Target = selectedTargetMode
                            })
                            count = count + 1
                        end)
                    end
                end
            end
        end

        if count > 0 then
            WindUI:Notify({ Title = "HeliosHub", Content = "Set targeting to " .. selectedTargetMode .. " on " .. count .. " towers", Duration = 3 })
        else
            WindUI:Notify({ Title = "HeliosHub", Content = "No matching towers found. Check name or ensure they are placed.", Duration = 3, Type = "error" })
        end
    end,
})
-- PART 6: UTILITIES TAB (No lobby/game checks)
local UtilitiesTab = Window:Tab({ Title = "Utilities", Icon = "solar:settings-bold", IconColor = Color3.fromRGB(255,200,100), Border = true })

-- HELPER: Get current wave (if not already defined)
if not GetCurrentWave then
    function GetCurrentWave()
        local label = PlayerGui:FindFirstChild("ReactGameTopGameDisplay", true)
            and PlayerGui.ReactGameTopGameDisplay.Frame.wave.container:FindFirstChild("value")
        if label then
            return tonumber(label.Text:match("(%d+)")) or 0
        end
        return 0
    end
end

-- 1. INVENTORY MANAGEMENT (Buttons)
local CrateList = {
    "All", "Basic", "Premium", "Deluxe", "Golden", "Bunny", "Halloween 2019",
    "Party", "Toy", "Valentines", "Xmas 2019", "Spooky", "Pumpkin", "Frost",
    "Lovely", "Cold Front", "Ducky", "Vigilante", "Pirate", "Phantom",
    "Halloween", "Jolly", "Lunar", "Lovestruck", "UglyCrate", "Coin Crate",
    "Banned", "Christmas 2025", "Showtime", "Valentines 2026", "Shamrock",
    "Low Grade", "Mid Grade", "High Grade"
}
local SelectedCrate = "All"

UtilitiesTab:Section({ Title = "Inventory Management", TextSize = 14 })

-- Dropdown for crate selection
UtilitiesTab:Dropdown({
    Title = "Target Crate",
    Desc = "Select which crate to open (or All)",
    Values = CrateList,
    Value = "All",
    Callback = function(choice)
        SelectedCrate = choice
    end,
})
UtilitiesTab:Space()

-- Button: Open Selected Crate
UtilitiesTab:Button({
    Title = "Open Selected Crate",
    Justify = "Center",
    Color = Color3.fromRGB(0, 150, 200),
    Callback = function()
        local crateName = SelectedCrate
        if crateName == "All" then
            for _, name in ipairs(CrateList) do
                if name ~= "All" then
                    pcall(function()
                        RemoteFunc:InvokeServer("Inventory", "Open", "Crate", name)
                    end)
                    task.wait(0.1)
                end
            end
            WindUI:Notify({ Title = "HeliosHub", Content = "Opened all crates", Duration = 2 })
        else
            pcall(function()
                RemoteFunc:InvokeServer("Inventory", "Open", "Crate", crateName)
            end)
            WindUI:Notify({ Title = "HeliosHub", Content = "Opened " .. crateName, Duration = 2 })
        end
    end,
})
UtilitiesTab:Space()

-- Button: Claim Spin Tickets
UtilitiesTab:Button({
    Title = "Claim Spin Tickets",
    Justify = "Center",
    Color = Color3.fromRGB(200, 150, 0),
    Callback = function()
        local SpinTickets = LocalPlayer:FindFirstChild("SpinTickets")
        if SpinTickets and SpinTickets.Value > 0 then
            local DailySpin = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("DailySpin")
            if DailySpin then
                local RedeemRemote = DailySpin:FindFirstChild("RF:RedeemSpin")
                if RedeemRemote then
                    local count = SpinTickets.Value
                    for i = 1, count do
                        pcall(function() RedeemRemote:InvokeServer() end)
                        task.wait(0.3)
                    end
                    WindUI:Notify({ Title = "HeliosHub", Content = "Used " .. count .. " spin tickets", Duration = 2 })
                else
                    WindUI:Notify({ Title = "HeliosHub", Content = "RedeemSpin remote not found", Duration = 2, Type = "error" })
                end
            else
                WindUI:Notify({ Title = "HeliosHub", Content = "DailySpin not found", Duration = 2, Type = "error" })
            end
        else
            WindUI:Notify({ Title = "HeliosHub", Content = "No spin tickets available", Duration = 2 })
        end
    end,
})
UtilitiesTab:Space()

-- Button: Claim Playtime Rewards
UtilitiesTab:Button({
    Title = "Claim Playtime Rewards",
    Justify = "Center",
    Color = Color3.fromRGB(0, 180, 100),
    Callback = function()
        local PlaytimeRewards = ReplicatedStorage:FindFirstChild("Network") and ReplicatedStorage.Network:FindFirstChild("PlaytimeRewards")
        if PlaytimeRewards then
            local ClaimRemote = PlaytimeRewards:FindFirstChild("RF:ClaimReward")
            if ClaimRemote then
                for i = 1, 6 do
                    pcall(function() ClaimRemote:InvokeServer(i) end)
                    task.wait(0.3)
                end
                WindUI:Notify({ Title = "HeliosHub", Content = "Claimed all playtime rewards", Duration = 2 })
            else
                WindUI:Notify({ Title = "HeliosHub", Content = "ClaimReward remote not found", Duration = 2, Type = "error" })
            end
        else
            WindUI:Notify({ Title = "HeliosHub", Content = "PlaytimeRewards not found", Duration = 2, Type = "error" })
        end
    end,
})
UtilitiesTab:Space()

-- 2. SELL FARMS ON WAVE (Toggle + Dropdown)
local SellFarmsRunning = false
local SellFarmsThread = nil
local SellFarmsWave = 30
local sellFarmsToggle = nil

UtilitiesTab:Section({ Title = "Farming", TextSize = 14 })

local waveOptions = {}
for i = 1, 50 do table.insert(waveOptions, tostring(i)) end

UtilitiesTab:Dropdown({
    Title = "Sell Wave",
    Desc = "Wave number to sell farms",
    Values = waveOptions,
    Value = "30",
    Callback = function(choice)
        SellFarmsWave = tonumber(choice) or 30
    end,
})
UtilitiesTab:Space()

sellFarmsToggle = UtilitiesTab:Toggle({
    Title = "Sell Farms on Wave",
    Desc = "Sells all your farms when the specified wave is reached (auto‑turns off after selling)",
    Value = false,
    Callback = function(v)
        if v then
            if SellFarmsRunning then return end
            SellFarmsRunning = true
            SellFarmsThread = task.spawn(function()
                while SellFarmsRunning do
                    if GameState == "GAME" then
                        local currentWave = GetCurrentWave()
                        if currentWave >= SellFarmsWave then
                            local towersFolder = workspace:FindFirstChild("Towers")
                            if towersFolder then
                                for _, replicator in ipairs(towersFolder:GetDescendants()) do
                                    if replicator:IsA("Folder") and replicator.Name == "TowerReplicator" then
                                        if replicator:GetAttribute("Name") == "Farm" and replicator:GetAttribute("OwnerId") == LocalPlayer.UserId then
                                            local model = replicator.Parent
                                            pcall(function()
                                                RemoteFunc:InvokeServer("Troops", "Sell", { Troop = model })
                                            end)
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            end
                            SellFarmsRunning = false
                            pcall(function() sellFarmsToggle:Set(false) end)
                            WindUI:Notify({ Title = "HeliosHub", Content = "Farms sold on wave " .. SellFarmsWave, Duration = 3 })
                            break
                        end
                    end
                    task.wait(1)
                end
                SellFarmsRunning = false
            end)
        else
            SellFarmsRunning = false
            if SellFarmsThread then task.cancel(SellFarmsThread) end
            SellFarmsThread = nil
        end
    end,
})
UtilitiesTab:Space()

-- 3. AUTO COLLECT PICKUPS (Toggle)
local AutoPickupsRunning = false
local AutoPickupsThread = nil

local function GetRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsVoidCharm(obj)
    return math.abs(obj.Position.Y) > 999999
end

UtilitiesTab:Toggle({
    Title = "Auto Collect Pickups",
    Desc = "Instantly teleports to Logbooks and event currency (silent)",
    Value = false,
    Callback = function(v)
        if v then
            if AutoPickupsRunning then return end
            AutoPickupsRunning = true
            AutoPickupsThread = task.spawn(function()
                while AutoPickupsRunning do
                    if GameState == "GAME" then
                        local folder = workspace:FindFirstChild("Pickups")
                        local hrp = GetRoot()
                        if folder and hrp then
                            for _, item in ipairs(folder:GetChildren()) do
                                if not AutoPickupsRunning then break end
                                if item:IsA("MeshPart") and (item.Name == "SnowCharm" or item.Name == "Lorebook" or item.Name == "Bunz") then
                                    if not IsVoidCharm(item) then
                                        hrp.CFrame = item.CFrame * CFrame.new(0, 3, 0)
                                        task.wait(0.2)
                                        task.wait(0.3)
                                    end
                                end
                            end
                        end
                    end
                    task.wait(1)
                end
                AutoPickupsRunning = false
            end)
        else
            AutoPickupsRunning = false
            if AutoPickupsThread then task.cancel(AutoPickupsThread) end
            AutoPickupsThread = nil
        end
    end,
})
UtilitiesTab:Space()

print("Utilities tab loaded – no lobby checks, buttons work anywhere.")
-- Startup notification (moved here for now)
WindUI:Notify({
    Title = "HeliosHub",
    Content = "you need to be in sandbox mode to place towers like mecha base e.t.c you also can't literally equip them. You need to use the stack function to place them. If you have any problem then let me know in the comments of pastebin scripblox or rscripts.",
    Duration = 15
})
