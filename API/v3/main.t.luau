return function(Library, Tabs, RootMaid, CacheManager, MaidClass)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local Options = Library.Options
    local Toggles = Library.Toggles
    local BindModule = loadstring(game:HttpGet("https://apigetunx.vercel.app/Modules/v2/Bind.lua"))()
    
    local ModuleMaid = MaidClass.new()
    RootMaid:GiveTask(ModuleMaid)
    RootMaid:GiveTask(function() if BindModule then BindModule:Kill() end end)

    RootMaid:GiveTask(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        Camera = workspace.CurrentCamera
    end))

    local MovementManager = {}

    function MovementManager.StartFlying(maid, speed)
        maid:DoCleaning()
        local flyMaid = MaidClass.new()
        maid:GiveTask(flyMaid)
        
        local character = LocalPlayer.Character
        if not character then return end
        local humanoid = character:FindFirstChild("Humanoid")
        local rootpart = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not rootpart then return end
        
        humanoid.PlatformStand = true
        flyMaid:GiveTask(function()
            if humanoid then humanoid.PlatformStand = false end
        end)
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6)
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.Parent = rootpart
        flyMaid:GiveTask(bodyVelocity)
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
        bodyGyro.P = 10000
        bodyGyro.D = 500
        bodyGyro.Parent = rootpart
        flyMaid:GiveTask(bodyGyro)
        
        flyMaid:GiveTask(RunService.Heartbeat:Connect(function()
            if not humanoid or not rootpart or not bodyVelocity.Parent or not bodyGyro.Parent then return end
            local cm = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule",5):WaitForChild("ControlModule",5))
            if not cm then return end
            local mv = cm:GetMoveVector()
            local dir = Camera.CFrame:VectorToWorldSpace(mv)
            bodyVelocity.Velocity = dir * (speed * 10)
            bodyGyro.CFrame = Camera.CFrame
        end))
    end

    function MovementManager.SmartTeleport(targetPos)
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local root = char.HumanoidRootPart
        local teleportType = Options.TeleportType and Options.TeleportType.Value or "Instant (TP)"
        local useNoclip = Toggles.NoclipOnTween and Toggles.NoclipOnTween.Value or false
        local originalNoclip = Toggles.NoClip and Toggles.NoClip.Value or false
        
        if teleportType == "Instant (TP)" then
            root.CFrame = CFrame.new(targetPos)
            return
        end
        
        local distance = (root.Position - targetPos).Magnitude
        local tweenSpeed = Options.TweenSpeed and Options.TweenSpeed.Value or 100
        local duration = distance / tweenSpeed
        if duration <= 0 then duration = 0.1 end
        
        local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(targetPos)})
        
        if useNoclip and Toggles.NoClip then
            Toggles.NoClip:SetValue(true)
        end
        
        tween:Play()
        tween.Completed:Connect(function()
            if useNoclip and not originalNoclip and Toggles.NoClip then
                Toggles.NoClip:SetValue(false)
            end
        end)
    end

    local MainCharacterGB = Tabs.Main:AddLeftGroupbox("Character", "user")
    local MainFlyGB = Tabs.Main:AddRightGroupbox("Fly", "plane")
    local MainOtherGB = Tabs.Main:AddRightGroupbox("Other", "package")

    MainCharacterGB:AddToggle("LockWalkSpeed", {Text = "Lock Walkspeed Value", Default = true})
    MainCharacterGB:AddSlider("WalkSpeed", {Text = "Walk Speed", Default = 16, Min = 16, Max = 100, Rounding = 0})

    MainCharacterGB:AddToggle("WalkspeedBindToggle", {
        Text = "Walkspeed BindButton",
        Default = false,
        Callback = function(v)
            if v then
                BindModule:AddToggleBB("WalkSpeed", 
                    function() if Toggles.LockWalkSpeed then Toggles.LockWalkSpeed:SetValue(true) end end, 
                    function() if Toggles.LockWalkSpeed then Toggles.LockWalkSpeed:SetValue(false) end end
                )
            else
                BindModule:DelBindB("WalkSpeed")
            end
        end
    })

    MainCharacterGB:AddSlider("JumpPower", {Text = "Jump Power", Default = 50, Min = 50, Max = 250, Rounding = 0})
    MainCharacterGB:AddSlider("MaxZoom", {Text = "Max Zoom", Default = 128, Min = 0, Max = 800, Rounding = 0})
    MainCharacterGB:AddToggle("NoVelocity", {Text = "No Velocity", Default = false})
    MainCharacterGB:AddDivider()
    MainCharacterGB:AddToggle("NoClip", {Text = "No-Clip", Default = false})
    Toggles.NoClip:AddKeyPicker("NoclipKeybind", {Default="N", Mode="Toggle", Text="Noclip", SyncToggleState=true})

    MainCharacterGB:AddToggle("InfiniteJump", {Text = "Infinite Jump", Default = false})
    MainCharacterGB:AddToggle("SpeedGlitch", {Text = "Speed Glitch", Default = false})
    MainCharacterGB:AddSlider("SpeedGlitchForce", {Text = "Speed Glitch Force", Default = 100, Min = 1, Max = 250, Rounding = 0})
    MainCharacterGB:AddDropdown("SpeedGlitchMethod", {Text = "Speed Glitch Method", Values = {"Speed", "Body Velocity"}, Default = 2})

    MainCharacterGB:AddDivider()
    MainCharacterGB:AddToggle("BunnyHop", {Text = "Bunny Hop", Default = false})
    MainCharacterGB:AddSlider("BunnyHopDelay", {Text = "Bunny Hop Delay (s)", Default = 0.2, Min = 0, Max = 3, Rounding = 2})

    local FlyMaid = MaidClass.new()
    ModuleMaid:GiveTask(FlyMaid)
    local flySpeed = 5

    MainFlyGB:AddToggle("Fly", {Text="Enable Fly", Default=false, Callback=function(v)
        if v then MovementManager.StartFlying(FlyMaid, flySpeed) else FlyMaid:DoCleaning() end
    end})
    Toggles.Fly:AddKeyPicker("FlyKeybind", {Default="F", Mode="Toggle", Text="Fly", SyncToggleState=true})
    MainFlyGB:AddSlider("FlySpeed", {Text="Fly Speed", Default=5, Min=1, Max=75, Rounding=0, Callback=function(v) flySpeed = v end})

    ModuleMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(c)
        if Toggles.Fly.Value then task.wait(0.5) MovementManager.StartFlying(FlyMaid, flySpeed) end
    end))

    local TeleportLocations = {
        Cabin = Vector3.new(104, 8, -417),
        ["Map Voting #1"] = Vector3.new(148, 4, -334),
        ["Map Voting #2"] = Vector3.new(153, 4, -333),
        ["Map Voting #3"] = Vector3.new(159, 4, -333),
        ["Map Voting #4"] = Vector3.new(166, 4, -333),
    }

    MainOtherGB:AddButton("Teleport (Cabin)", function() MovementManager.SmartTeleport(TeleportLocations.Cabin) end)
    MainOtherGB:AddDivider()
    MainOtherGB:AddButton("Teleport (Map Voting #1)", function() MovementManager.SmartTeleport(TeleportLocations["Map Voting #1"]) end)
    MainOtherGB:AddButton("Teleport (Map Voting #2)", function() MovementManager.SmartTeleport(TeleportLocations["Map Voting #2"]) end)
    MainOtherGB:AddButton("Teleport (Map Voting #3)", function() MovementManager.SmartTeleport(TeleportLocations["Map Voting #3"]) end)
    MainOtherGB:AddButton("Teleport (Map Voting #4)", function() MovementManager.SmartTeleport(TeleportLocations["Map Voting #4"]) end)
    
    MainOtherGB:AddButton("Teleport (Beast)", function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Hammer") then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then MovementManager.SmartTeleport(root.Position + Vector3.new(0, 5, 0)); break end
            end
        end
    end)

    local survivorNames = {"No Survivors"}
    MainOtherGB:AddDropdown("SurvivorDropdown", {Text = "Survivors", Values = {}, Default = 1, Searchable = true, Scrollable = true})

    MainOtherGB:AddButton("Teleport (Survivor)", function()
        local target = Options.SurvivorDropdown and Options.SurvivorDropdown.Value
        if target and target ~= "No Survivors" then
            local player = Players:FindFirstChild(target)
            if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                MovementManager.SmartTeleport(player.Character.HumanoidRootPart.Position + Vector3.new(0, 5, 0))
            end
        end
    end)

    local computerNames = {"No Computers"}
    MainOtherGB:AddDropdown("ComputerDropdown", {Text = "Computers", Values = {}, Default = 1, Searchable = true, Scrollable = true})

    MainOtherGB:AddButton("Teleport (Computer)", function()
        local target = Options.ComputerDropdown and Options.ComputerDropdown.Value
        if target and target ~= "No Computers" then
            local index = tonumber(target:match("#(%d+)"))
            if index and CacheManager.Computers[index] then
                MovementManager.SmartTeleport(CacheManager.Computers[index]:GetPivot().Position + Vector3.new(0, 5, 0))
            end
        end
    end)

    MainOtherGB:AddLabel("Other")
    MainOtherGB:AddDivider()
    MainOtherGB:AddDropdown("TeleportType", {Text = "Teleport Type", Values = {"Instant (TP)", "Slow (Tween)"}, Default = 1})
    MainOtherGB:AddSlider("TweenSpeed", {Text = "Tween Speed (Studs/s)", Default = 100, Min = 1, Max = 250, Rounding = 0})
    MainOtherGB:AddToggle("NoclipOnTween", {Text = "Noclip On Tween", Default = true})

    local function ApplyCharacterMods()
        if not (Toggles.LockWalkSpeed and Toggles.LockWalkSpeed.Value) then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = Options.WalkSpeed and Options.WalkSpeed.Value or 16
            hum.JumpPower = Options.JumpPower and Options.JumpPower.Value or 50
        end
    end

    local function ApplyZoom() LocalPlayer.CameraMaxZoomDistance = Options.MaxZoom and Options.MaxZoom.Value or 128 end
    
    local function ApplyNoVelocity()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.new(0,0,0); root.AssemblyLinearVelocity = Vector3.new(0,0,0) end
    end

    ModuleMaid:GiveTask(game:GetService("UserInputService").JumpRequest:Connect(function()
        if Toggles.InfiniteJump and Toggles.InfiniteJump.Value then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end))

    local function setupSpeedGlitch(char)
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        ModuleMaid:GiveTask(hum.StateChanged:Connect(function(old, new)
            if new == Enum.HumanoidStateType.Jumping and Toggles.SpeedGlitch and Toggles.SpeedGlitch.Value then
                local root = char:FindFirstChild("HumanoidRootPart")
                if not root or hum.MoveDirection.Magnitude <= 0 then return end
                local force = Options.SpeedGlitchForce.Value
                if Options.SpeedGlitchMethod.Value == "Body Velocity" then
                    local bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(1e5, 0, 1e5)
                    bv.Velocity = hum.MoveDirection * force
                    bv.Parent = root
                    game:GetService("Debris"):AddItem(bv, 0.1)
                else
                    local oldWs = hum.WalkSpeed
                    hum.WalkSpeed = force
                    task.delay(0.1, function() if hum then hum.WalkSpeed = oldWs end end)
                end
            end
        end))
    end

    local BHopMaid = MaidClass.new()
    ModuleMaid:GiveTask(BHopMaid)
    local lastJump = 0

    ModuleMaid:GiveTask(RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        if Toggles.NoClip and Toggles.NoClip.Value then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end))

    local function ToggleBunnyHop()
        BHopMaid:DoCleaning()
        BHopMaid = MaidClass.new()
        ModuleMaid:GiveTask(BHopMaid)
        if Toggles.BunnyHop and Toggles.BunnyHop.Value then
            BHopMaid:GiveTask(RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.FloorMaterial == Enum.Material.Air then return end
                local delay = Options.BunnyHopDelay and Options.BunnyHopDelay.Value or 0.2
                if tick() - lastJump >= delay then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    lastJump = tick()
                end
            end))
        end
    end

    task.spawn(function()
        while not Options.WalkSpeed do task.wait() end
        Options.WalkSpeed:OnChanged(function() if Toggles.LockWalkSpeed.Value then ApplyCharacterMods() end end)
        Options.JumpPower:OnChanged(function() if Toggles.LockWalkSpeed.Value then ApplyCharacterMods() end end)
        Options.MaxZoom:OnChanged(ApplyZoom)
        Toggles.NoVelocity:OnChanged(ApplyNoVelocity)
        Toggles.BunnyHop:OnChanged(ToggleBunnyHop)
        Options.BunnyHopDelay:OnChanged(function() if Toggles.BunnyHop and Toggles.BunnyHop.Value then ToggleBunnyHop() end end)
    end)

    ModuleMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(function(c)
        task.wait(0.1)
        ApplyCharacterMods()
        ApplyZoom()
        setupSpeedGlitch(c)
        if Toggles.BunnyHop and Toggles.BunnyHop.Value then ToggleBunnyHop() end
    end))

    ModuleMaid:GiveTask(RunService.Heartbeat:Connect(function()
        if Toggles.NoVelocity and Toggles.NoVelocity.Value then ApplyNoVelocity() end
    end))

    if LocalPlayer.Character then ApplyCharacterMods(); ApplyZoom(); setupSpeedGlitch(LocalPlayer.Character) end
    
    local lastDropdownUpdate = 0
    ModuleMaid:GiveTask(RunService.Heartbeat:Connect(function()
        if tick() - lastDropdownUpdate > 1 then
            local newSurvivors = {}
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character and not player.Character:FindFirstChild("Hammer") then
                    table.insert(newSurvivors, player.DisplayName)
                end
            end
            if #newSurvivors == 0 then newSurvivors = {"No Survivors"} end
            if Options.SurvivorDropdown then
                Options.SurvivorDropdown:SetValues(newSurvivors)
                if not table.find(newSurvivors, Options.SurvivorDropdown.Value) then Options.SurvivorDropdown:SetValue(newSurvivors[1]) end
            end

            local newComputers = {}
            for i, _ in ipairs(CacheManager.Computers) do table.insert(newComputers, "Computer #" .. i) end
            if #newComputers == 0 then newComputers = {"No Computers"} end
            if Options.ComputerDropdown then
                Options.ComputerDropdown:SetValues(newComputers)
                if not table.find(newComputers, Options.ComputerDropdown.Value) then Options.ComputerDropdown:SetValue(newComputers[1]) end
            end

            lastDropdownUpdate = tick()
        end
    end))
end
