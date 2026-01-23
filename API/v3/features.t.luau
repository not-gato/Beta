return function(Library, Tabs, RootMaid, CacheManager, MaidClass)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local Options = Library.Options
    local Toggles = Library.Toggles
    local BindModule = loadstring(game:HttpGet("https://apigetunx.vercel.app/Modules/v2/Bind.lua"))()

    local ModuleMaid = MaidClass.new()
    RootMaid:GiveTask(ModuleMaid)
    RootMaid:GiveTask(function() if BindModule then BindModule:Kill() end end)

    local FeaturesGB = Tabs.Features:AddLeftGroupbox("Features", "zap")
    
    FeaturesGB:AddToggle("NoPCError", {Text = "No PC Error", Default = false})
    FeaturesGB:AddToggle("NoPCErrorBind", {
        Text = "No PC Error BindButton", Default = false,
        Callback = function(v)
            if v then BindModule:AddToggleBB("No PC Err", function() if Toggles.NoPCError then Toggles.NoPCError:SetValue(true) end end, function() if Toggles.NoPCError then Toggles.NoPCError:SetValue(false) end end)
            else BindModule:DelBindB("No PC Err") end
        end
    })
    FeaturesGB:AddLabel("Credits: Imperial - Yarhm")
    FeaturesGB:AddButton({Text = "Execute Yarhm", Func = function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.19/yarhm.lua", false))() end})

    FeaturesGB:AddToggle("DoPCRemotely", {Text = "Bigger PC Range", Default = false})
    FeaturesGB:AddToggle("DoPCRemotelyBind", {
        Text = "Bigger PC Range BindButton", Default = false,
        Callback = function(v)
            if v then BindModule:AddToggleBB("Big Range", function() if Toggles.DoPCRemotely then Toggles.DoPCRemotely:SetValue(true) end end, function() if Toggles.DoPCRemotely then Toggles.DoPCRemotely:SetValue(false) end end)
            else BindModule:DelBindB("Big Range") end
        end
    })

    local PCRangeMaid = MaidClass.new()
    ModuleMaid:GiveTask(PCRangeMaid)
    local timeNear = 0
    local activePC = nil
    local originalTransforms = {}

    PCRangeMaid:GiveTask(RunService.Heartbeat:Connect(function()
        if Toggles.DoPCRemotely and Toggles.DoPCRemotely.Value then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                if activePC then
                    local screen = activePC:FindFirstChild("Screen")
                    local isDone = false
                    if screen and screen:IsA("BasePart") then
                        local c = screen.Color
                        if math.abs(c.R*255 - 40) < 5 and math.abs(c.G*255 - 127) < 5 and math.abs(c.B*255 - 71) < 5 then isDone = true end
                    end
                    if isDone then
                        for part, data in pairs(originalTransforms) do if part and part.Parent then part.CFrame = data.CFrame; part.Size = data.Size end end
                        originalTransforms = {}; activePC = nil
                    else
                        for i = 1, 3 do
                            local trig = activePC:FindFirstChild("ComputerTrigger"..i)
                            if trig and trig:IsA("BasePart") then trig.CFrame = root.CFrame; trig.Size = Vector3.new(9e4, 9e4, 9e4); trig.CanCollide = false end
                        end
                    end
                else
                    for _, pc in ipairs(CacheManager.Computers) do
                        local screen = pc:FindFirstChild("Screen")
                        local isDone = false
                        if screen and screen:IsA("BasePart") then
                            local c = screen.Color
                            if math.abs(c.R*255 - 40) < 5 and math.abs(c.G*255 - 127) < 5 and math.abs(c.B*255 - 71) < 5 then isDone = true end
                        end
                        if not isDone then
                            if (pc:GetPivot().Position - root.Position).Magnitude <= 6 then
                                timeNear = timeNear + 0.05
                                if timeNear >= 1 then
                                    activePC = pc; Library:Notify("Bigger Range Triggered!"); timeNear = 0
                                    for i = 1, 3 do
                                        local trig = pc:FindFirstChild("ComputerTrigger"..i)
                                        if trig and trig:IsA("BasePart") then originalTransforms[trig] = {CFrame = trig.CFrame, Size = trig.Size} end
                                    end
                                end
                                break 
                            end
                        end
                    end
                end
            end
        else
            if activePC then
                for part, data in pairs(originalTransforms) do if part and part.Parent then part.CFrame = data.CFrame; part.Size = data.Size end end
                originalTransforms = {}; activePC = nil; timeNear = 0
            end
        end
    end))

    local OldNameCall
    OldNameCall = hookmetamethod(game, "__namecall", function(Self, ...)
        local Args = {...}
        if getnamecallmethod() == "FireServer" and Args[1] == "SetPlayerMinigameResult" and Toggles.NoPCError and Toggles.NoPCError.Value then Args[2] = true end
        return OldNameCall(Self, unpack(Args))
    end)

    local FlingGroupBox = Tabs.Features:AddLeftGroupbox("Fling", "wind")
    local flingTime = 5
    local flingForce = 50000

    local function Fling(TargetPlayer, duration, force)
        local Character = LocalPlayer.Character
        local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
        local TCharacter = TargetPlayer.Character
        local TRootPart = TCharacter and TCharacter:FindFirstChild("HumanoidRootPart")
        if not RootPart or not TRootPart then return end
        
        local oldPos = RootPart.CFrame
        local startTime = tick()
        local BV = Instance.new("BodyVelocity")
        BV.Velocity = Vector3.new(force, force, force)
        BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
        BV.Parent = RootPart
        
        while tick() - startTime < duration and TargetPlayer.Parent and RootPart.Parent do
            RootPart.CFrame = TRootPart.CFrame
            RootPart.Velocity = Vector3.new(force, force, force)
            RootPart.RotVelocity = Vector3.new(force, force, force)
            task.wait()
        end
        BV:Destroy()
        RootPart.CFrame = oldPos
        RootPart.Velocity = Vector3.zero
    end

    local function getPlayerList()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p.Name) end end
        return list
    end

    FlingGroupBox:AddDropdown("FlingPlayer", {Text = "Select Players", Values = getPlayerList(), Multi = true, Searchable = true})
    FlingGroupBox:AddButton({Text="Fling Selected", Func=function()
        if not Options.FlingPlayer.Value then return end
        for selectedPlayer, isSelected in pairs(Options.FlingPlayer.Value) do
            if isSelected then
                local targetPlayer = Players:FindFirstChild(tostring(selectedPlayer))
                if targetPlayer then Fling(targetPlayer, flingTime, flingForce) end
            end
        end
    end})
    FlingGroupBox:AddButton({Text="Fling Beast", Func=function()
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Hammer") then
                Fling(targetPlayer, flingTime, flingForce); break
            end
        end
    end})
    FlingGroupBox:AddSlider("FlingTime", {Text="Fling Time", Default=5, Min=1, Max=25, Rounding=1, Callback=function(v) flingTime = v end})
    FlingGroupBox:AddSlider("FlingForce", {Text="Fling Force", Default=50000, Min=1, Max=9999999, Rounding=0, Callback=function(v) flingForce = v end})
    
    ModuleMaid:GiveTask(Players.PlayerAdded:Connect(function() if Options.FlingPlayer then Options.FlingPlayer:SetValues(getPlayerList()) end end))
    ModuleMaid:GiveTask(Players.PlayerRemoving:Connect(function() if Options.FlingPlayer then Options.FlingPlayer:SetValues(getPlayerList()) end end))

    local FunMiscGB = Tabs.Features:AddRightGroupbox("Fun & Misc", "confetti_ball")
    FunMiscGB:AddToggle("RGBAsync", {Text = "RGB ASync", Default = false})
    FunMiscGB:AddSlider("RGBAsyncSpeed", {Text = "RGB Async Speed", Default = 5, Min = 1, Max = 10, Rounding = 0})
    FunMiscGB:AddDivider()
    FunMiscGB:AddToggle("RGBHammer", {Text = "RGB Hammer", Default = false})
    FunMiscGB:AddToggle("RGBLight", {Text = "RGB Light", Default = false})
    FunMiscGB:AddSlider("RGBHammerSpeed", {Text = "RGB Hammer Speed", Default = 5, Min = 1, Max = 10, Rounding = 0})
    FunMiscGB:AddSlider("RGBLightSpeed", {Text = "RGB Light Speed", Default = 5, Min = 1, Max = 10, Rounding = 0})
    FunMiscGB:AddDropdown("RGBMethod", {Text = "RGB Method", Values = {"HSV", "RGB"}, Default = 1})
    FunMiscGB:AddButton("Rejoin", function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end)

    local RGB = {HammerHighlight = nil, LastHammerUpdate = 0, LastLightUpdate = 0}
    local function GetRGBColor(method, speed)
        if (method or "HSV") == "HSV" then return Color3.fromHSV((tick() * (speed or 5) / 10) % 1, 1, 1)
        else local t = tick() * (speed or 5); return Color3.fromRGB(127+127*math.sin(t), 127+127*math.sin(t+2), 127+127*math.sin(t+4)) end
    end

    ModuleMaid:GiveTask(RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        if Toggles.RGBHammer and Toggles.RGBHammer.Value then
            local hammer = char:FindFirstChild("Hammer")
            if hammer then
                if not RGB.HammerHighlight then RGB.HammerHighlight = Instance.new("Highlight"); RGB.HammerHighlight.FillTransparency = 0.5; RGB.HammerHighlight.Parent = hammer end
                if tick() - RGB.LastHammerUpdate >= 0.05 then
                    local color = GetRGBColor(Options.RGBMethod.Value, (Toggles.RGBAsync.Value and Options.RGBAsyncSpeed.Value) or Options.RGBHammerSpeed.Value)
                    RGB.HammerHighlight.FillColor = color; RGB.HammerHighlight.OutlineColor = color; RGB.LastHammerUpdate = tick()
                end
            end
        elseif RGB.HammerHighlight then RGB.HammerHighlight:Destroy(); RGB.HammerHighlight = nil end
        
        if Toggles.RGBLight and Toggles.RGBLight.Value then
            local gs = workspace:FindFirstChild(LocalPlayer.Name) and workspace[LocalPlayer.Name]:FindFirstChild("Gemstone")
            local h = gs and gs:FindFirstChild("Handle")
            if h then
                local l = h:FindFirstChild("PointLight") or Instance.new("PointLight", h); l.Brightness = 3; l.Range = 15
                if tick() - RGB.LastLightUpdate >= 0.05 then
                    l.Color = GetRGBColor(Options.RGBMethod.Value, (Toggles.RGBAsync.Value and Options.RGBAsyncSpeed.Value) or Options.RGBLightSpeed.Value)
                    RGB.LastLightUpdate = tick()
                end
            end
        end
    end))

    local AutoInteractMaid = MaidClass.new()
    ModuleMaid:GiveTask(AutoInteractMaid)
    local FeaturesGB2 = Tabs.Features:AddRightGroupbox("Auto Interact", "mouse_pointer")
    FeaturesGB2:AddToggle("AutoInteract", {Text = "Auto Interact", Default = false})
    FeaturesGB2:AddDropdown("AutoInteractConditions", {Text = "Conditions", Values = {"Near PC", "Near Exit Door", "Near Freeze Pod"}, Default = {"Near PC", "Near Exit Door", "Near Freeze Pod"}, Multi = true})
    
    local interactedObjects = {}
    local function isConditionEnabled(name) local val = Options.AutoInteractConditions.Value; return type(val)=="table" and (val[name]==true or table.find(val, name)) end

    AutoInteractMaid:GiveTask(RunService.Heartbeat:Connect(function()
        if Toggles.AutoInteract and Toggles.AutoInteract.Value then
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then
                local function tryInteract(obj, range, condName)
                    if not isConditionEnabled(condName) or not obj or not obj.Parent then return end
                    local screen = obj:FindFirstChild("Screen")
                    local pos = (screen and screen.Position) or (obj:IsA("Model") and obj:GetPivot().Position) or obj.Position
                    if (root.Position - pos).Magnitude <= range then
                        if condName == "Near PC" and screen then
                            local c = screen.Color
                            if math.abs(c.R*255 - 40) < 5 and math.abs(c.G*255 - 127) < 5 and math.abs(c.B*255 - 71) < 5 then return end
                        elseif condName == "Near Exit Door" and interactedObjects[obj] then return end
                        ReplicatedStorage.RemoteEvent:FireServer("Input", "Action", true)
                        if condName == "Near Exit Door" then interactedObjects[obj] = true end
                    else interactedObjects[obj] = nil end
                end
                for _, pc in ipairs(CacheManager.Computers) do tryInteract(pc, 5, "Near PC") end
                for _, pod in ipairs(CacheManager.Pods) do tryInteract(pod, 10, "Near Freeze Pod") end
                for _, exit in ipairs(CacheManager.Exits) do tryInteract(exit, 10, "Near Exit Door") end
            end
        end
    end))
end
