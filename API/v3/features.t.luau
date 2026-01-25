return newcclosure(function(Library, Tabs, RootMaid, CacheManager, MaidClass, Scheduler)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local Options = Library.Options
    local Toggles = Library.Toggles
    local BindModule = loadstring(game:HttpGet("https://apigetunx.vercel.app/Modules/v2/Bind.lua"))()

    local ModuleMaid = MaidClass.new()
    RootMaid:GiveTask(ModuleMaid)
    RootMaid:GiveTask(newcclosure(function() if BindModule then BindModule:Kill() end end))

    local FeaturesGB = Tabs.Features:AddLeftGroupbox("Features", "zap")
    
    FeaturesGB:AddToggle("NoPCError", {Text = "No PC Error", Default = false})
    FeaturesGB:AddToggle("NoPCErrorBind", {
        Text = "No PC Error BindButton", Default = false,
        Callback = newcclosure(function(v)
            if not BindModule then return end
            if v then BindModule:AddToggleBB("No PC Err", newcclosure(function() if Toggles.NoPCError then Toggles.NoPCError:SetValue(true) end end), newcclosure(function() if Toggles.NoPCError then Toggles.NoPCError:SetValue(false) end end))
            else BindModule:DelBindB("No PC Err") end
        end)
    })
    FeaturesGB:AddLabel("Credits Of 'No PC Error' Feature Goes To: Yarhm | Created By Imperial! :D")
    FeaturesGB:AddButton({Text = "Execute Yarhm", Func = newcclosure(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/Joystickplays/psychic-octo-invention/main/source/yarhm/1.19/yarhm.lua", false))() end)})

    FeaturesGB:AddToggle("DoPCRemotely", {Text = "Bigger PC Range", Default = false})
    FeaturesGB:AddToggle("DoPCRemotelyBind", {
        Text = "Bigger PC Range BindButton", Default = false,
        Callback = newcclosure(function(v)
            if not BindModule then return end
            if v then BindModule:AddToggleBB("Big Range", newcclosure(function() if Toggles.DoPCRemotely then Toggles.DoPCRemotely:SetValue(true) end end), newcclosure(function() if Toggles.DoPCRemotely then Toggles.DoPCRemotely:SetValue(false) end end))
            else BindModule:DelBindB("Big Range") end
        end)
    })

    local PCRangeMaid = MaidClass.new()
    ModuleMaid:GiveTask(PCRangeMaid)
    local timeNear = 0
    local activePC = nil
    local originalTransforms = {}

    PCRangeMaid:GiveTask(RunService.Heartbeat:Connect(newcclosure(function()
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
                    local computers = CacheManager.Computers
                    for i = 1, #computers do
                        local pc = computers[i]
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
    end)))

    local OldNameCall
    OldNameCall = hookmetamethod(game, "__namecall", newcclosure(function(Self, ...)
        local Args = {...}
        if getnamecallmethod() == "FireServer" and Args[1] == "SetPlayerMinigameResult" and Toggles.NoPCError and Toggles.NoPCError.Value then Args[2] = true end
        return OldNameCall(Self, unpack(Args))
    end))

    local FlingGroupBox = Tabs.Features:AddLeftGroupbox("Fling", "wind")
    local flingTime = 5
    local flingForce = 50000

    local Fling = newcclosure(function(TargetPlayer, duration, flingForce)
        local startTime = tick()
        local Character = LocalPlayer.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
        local RootPart = Humanoid and Humanoid.RootPart

        local TCharacter = TargetPlayer.Character
        local THumanoid
        local TRootPart
        local THead
        local Accessory
        local Handle

        if TCharacter:FindFirstChildOfClass("Humanoid") then THumanoid = TCharacter:FindFirstChildOfClass("Humanoid") end
        if THumanoid and THumanoid.RootPart then TRootPart = THumanoid.RootPart end
        if TCharacter:FindFirstChild("Head") then THead = TCharacter.Head end
        if TCharacter:FindFirstChildOfClass("Accessory") then Accessory = TCharacter:FindFirstChildOfClass("Accessory") end
        if Accessory and Accessory:FindFirstChild("Handle") then Handle = Accessory.Handle end

        if Character and Humanoid and RootPart then
            if RootPart.Velocity.Magnitude < 50 then getgenv().OldPos = RootPart.CFrame end
            if THead then workspace.CurrentCamera.CameraSubject = THead
            elseif not THead and Handle then workspace.CurrentCamera.CameraSubject = Handle
            elseif THumanoid and TRootPart then workspace.CurrentCamera.CameraSubject = THumanoid end
            if not TCharacter:FindFirstChildWhichIsA("BasePart") then return end
            
            local FPos = function(BasePart, Pos, Ang)
                RootPart.CFrame = CFrame.new(BasePart.Position) * Pos * Ang
                Character:SetPrimaryPartCFrame(CFrame.new(BasePart.Position) * Pos * Ang)
                RootPart.Velocity = Vector3.new(flingForce, flingForce * 10, flingForce)
                RootPart.RotVelocity = Vector3.new(flingForce * 20, flingForce * 20, flingForce * 20)
            end
            
            local SFBasePart = function(BasePart)
                local TimeToWait = duration or 2
                local Time = tick()
                local Angle = 0

                repeat
                    if RootPart and THumanoid then
                        if BasePart.Velocity.Magnitude < 50 then
                            Angle = Angle + 100
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle),0 ,0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(2.25, 1.5, -2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(-2.25, -1.5, 2.25) + THumanoid.MoveDirection * BasePart.Velocity.Magnitude / 1.25, CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0) + THumanoid.MoveDirection,CFrame.Angles(math.rad(Angle), 0, 0))
                            task.wait()
                        else
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, -THumanoid.WalkSpeed), CFrame.Angles(0, 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, THumanoid.WalkSpeed), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, -TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(0, 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, 1.5, TRootPart.Velocity.Magnitude / 1.25), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(math.rad(90), 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5 ,0), CFrame.Angles(math.rad(-90), 0, 0)); task.wait()
                            FPos(BasePart, CFrame.new(0, -1.5, 0), CFrame.Angles(0, 0, 0)); task.wait()
                        end
                    else break end
                until BasePart.Velocity.Magnitude > 500 or BasePart.Parent ~= TargetPlayer.Character or TargetPlayer.Parent ~= Players or not TargetPlayer.Character == TCharacter or THumanoid.Sit or tick() > Time + TimeToWait
            end
            
            local previousDestroyHeight = workspace.FallenPartsDestroyHeight
            workspace.FallenPartsDestroyHeight = 0/0
            
            local BV = Instance.new("BodyVelocity")
            BV.Name = "EpixVel"
            BV.Parent = RootPart
            BV.Velocity = Vector3.new(flingForce, flingForce, flingForce)
            BV.MaxForce = Vector3.new(1/0, 1/0, 1/0)
            
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            
            if TRootPart and THead then
                if (TRootPart.CFrame.p - THead.CFrame.p).Magnitude > 5 then SFBasePart(THead) else SFBasePart(TRootPart) end
            elseif TRootPart and not THead then SFBasePart(TRootPart)
            elseif not TRootPart and THead then SFBasePart(THead)
            elseif not TRootPart and not THead and Accessory and Handle then SFBasePart(Handle) end
            
            BV:Destroy()
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            workspace.CurrentCamera.CameraSubject = Humanoid
            
            repeat
                if Character and Humanoid and RootPart and getgenv().OldPos then
                    RootPart.CFrame = getgenv().OldPos * CFrame.new(0, .5, 0)
                    Character:SetPrimaryPartCFrame(getgenv().OldPos * CFrame.new(0, .5, 0))
                    Humanoid:ChangeState("GettingUp")
                    table.foreach(Character:GetChildren(), function(_, x) if x:IsA("BasePart") then x.Velocity, x.RotVelocity = Vector3.new(), Vector3.new() end end)
                end
                task.wait()
            until RootPart and getgenv().OldPos and (RootPart.Position - getgenv().OldPos.p).Magnitude < 25
            workspace.FallenPartsDestroyHeight = previousDestroyHeight
        end
    end)

    local getPlayerList = newcclosure(function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(list, p.Name) end end
        return list
    end)

    FlingGroupBox:AddDropdown("FlingPlayer", {Text = "Select Players", Values = getPlayerList(), Multi = true, Searchable = true})
    FlingGroupBox:AddButton({Text="Fling Selected", Func=newcclosure(function()
        if not Options.FlingPlayer.Value then return end
        for selectedPlayer, isSelected in pairs(Options.FlingPlayer.Value) do
            if isSelected then
                local targetPlayer = Players:FindFirstChild(tostring(selectedPlayer))
                if targetPlayer then Fling(targetPlayer, flingTime, flingForce); task.wait(flingTime + 0.5) end
            end
        end
    end)})
    FlingGroupBox:AddButton({Text="Fling All", Func=newcclosure(function()
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character then Fling(targetPlayer, flingTime, flingForce); task.wait(flingTime + 0.5) end
        end
    end)})
    FlingGroupBox:AddButton({Text="Fling Beast", Func=newcclosure(function()
        for _, targetPlayer in ipairs(Players:GetPlayers()) do
            if targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Hammer") then
                Fling(targetPlayer, flingTime, flingForce); task.wait(flingTime + 0.5); break
            end
        end
    end)})
    FlingGroupBox:AddDivider()
    FlingGroupBox:AddToggle("FlingBeastBind", {Text = "Fling Beast Bind Button", Default = false, Callback = newcclosure(function(v)
        if not BindModule then return end
        if v then BindModule:BindB("Fling Beast", newcclosure(function()
            for _, targetPlayer in ipairs(Players:GetPlayers()) do
                if targetPlayer ~= LocalPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Hammer") then
                    Fling(targetPlayer, flingTime, flingForce); task.wait(flingTime + 0.5); break
                end
            end
        end)) else BindModule:DelBindB("Fling Beast") end
    end)})
    FlingGroupBox:AddDivider()
    FlingGroupBox:AddSlider("FlingTime", {Text="Fling Time", Default=5, Min=1, Max=25, Rounding=1, Callback=newcclosure(function(v) flingTime = v end)})
    FlingGroupBox:AddSlider("FlingForce", {Text="Fling Force", Default=50000, Min=1, Max=9999999, Rounding=0, Callback=newcclosure(function(v) flingForce = v end)})
    
    ModuleMaid:GiveTask(Players.PlayerAdded:Connect(newcclosure(function() if Options.FlingPlayer then Options.FlingPlayer:SetValues(getPlayerList()) end end)))
    ModuleMaid:GiveTask(Players.PlayerRemoving:Connect(newcclosure(function() if Options.FlingPlayer then Options.FlingPlayer:SetValues(getPlayerList()) end end)))

    local FunMiscGB = Tabs.Features:AddRightGroupbox("Fun & Misc", "confetti_ball")
    FunMiscGB:AddToggle("RGBAsync", {Text = "RGB ASync", Default = false})
    FunMiscGB:AddSlider("RGBAsyncSpeed", {Text = "RGB Async Speed", Default = 5, Min = 1, Max = 10, Rounding = 0})
    FunMiscGB:AddDivider()
    FunMiscGB:AddToggle("RGBHammer", {Text = "RGB Hammer", Default = false})
    FunMiscGB:AddToggle("RGBLight", {Text = "RGB Light", Default = false})
    FunMiscGB:AddSlider("RGBHammerSpeed", {Text = "RGB Hammer Speed", Default = 5, Min = 1, Max = 10, Rounding = 0})
    FunMiscGB:AddSlider("RGBLightSpeed", {Text = "RGB Light Speed", Default = 5, Min = 1, Max = 10, Rounding = 0})
    FunMiscGB:AddDropdown("RGBMethod", {Text = "RGB Method", Values = {"HSV", "RGB"}, Default = 1})
    FunMiscGB:AddDivider()
    FunMiscGB:AddButton("Reset", newcclosure(function()
        if Toggles.RGBAsync then Toggles.RGBAsync:SetValue(false) end
        if Toggles.RGBHammer then Toggles.RGBHammer:SetValue(false) end
        if Toggles.RGBLight then Toggles.RGBLight:SetValue(false) end
        if Options.RGBAsyncSpeed then Options.RGBAsyncSpeed:SetValue(5) end
        if Options.RGBHammerSpeed then Options.RGBHammerSpeed:SetValue(5) end
        if Options.RGBLightSpeed then Options.RGBLightSpeed:SetValue(5) end
        if Options.RGBMethod then Options.RGBMethod:SetValue("HSV") end
    end))
    FunMiscGB:AddButton("Rejoin", newcclosure(function() game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer) end))

    local RGB = {HammerHighlight = nil, LastHammerUpdate = 0, LastLightUpdate = 0}
    local GetRGBColor = newcclosure(function(method, speed)
        if (method or "HSV") == "HSV" then return Color3.fromHSV((tick() * (speed or 5) / 10) % 1, 1, 1)
        else local t = tick() * (speed or 5); return Color3.fromRGB(127+127*math.sin(t), 127+127*math.sin(t+2), 127+127*math.sin(t+4)) end
    end)

    if Scheduler then
        ModuleMaid:GiveTask(Scheduler.Interval(0.05, newcclosure(function()
            local char = LocalPlayer.Character
            if not char then return end
            if Toggles.RGBHammer and Toggles.RGBHammer.Value then
                local hammer = char:FindFirstChild("Hammer")
                if hammer then
                    if not RGB.HammerHighlight then RGB.HammerHighlight = Instance.new("Highlight"); RGB.HammerHighlight.FillTransparency = 0.5; RGB.HammerHighlight.OutlineTransparency = 0; RGB.HammerHighlight.Parent = hammer end
                    local color = GetRGBColor(Options.RGBMethod.Value, (Toggles.RGBAsync.Value and Options.RGBAsyncSpeed.Value) or Options.RGBHammerSpeed.Value)
                    RGB.HammerHighlight.FillColor = color; RGB.HammerHighlight.OutlineColor = color
                end
            elseif RGB.HammerHighlight then RGB.HammerHighlight:Destroy(); RGB.HammerHighlight = nil end
            
            if Toggles.RGBLight and Toggles.RGBLight.Value then
                local gs = workspace:FindFirstChild(LocalPlayer.Name) and workspace[LocalPlayer.Name]:FindFirstChild("Gemstone")
                local h = gs and gs:FindFirstChild("Handle")
                if h then
                    local l = h:FindFirstChild("PointLight") or Instance.new("PointLight", h); l.Brightness = 3; l.Range = 15
                    l.Color = GetRGBColor(Options.RGBMethod.Value, (Toggles.RGBAsync.Value and Options.RGBAsyncSpeed.Value) or Options.RGBLightSpeed.Value)
                end
            else
                local gs = workspace:FindFirstChild(LocalPlayer.Name) and workspace[LocalPlayer.Name]:FindFirstChild("Gemstone")
                if gs then
                    local h = gs:FindFirstChild("Handle")
                    if h then local l = h:FindFirstChild("PointLight"); if l then l:Destroy() end end
                end
            end
        end)))
    end
end)
