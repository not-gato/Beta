return function(Library, Tabs, RootMaid, CacheManager, MaidClass)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Lighting = game:GetService("Lighting")
    local LocalPlayer = Players.LocalPlayer
    local Options = Library.Options
    local Toggles = Library.Toggles
    
    local VisualsMaid = MaidClass.new()
    RootMaid:GiveTask(VisualsMaid)

    local VisualsTabbox = Tabs.Visuals:AddLeftTabbox()
    local ESPTab = VisualsTabbox:AddTab("ESPs", "scan")

    ESPTab:AddToggle("ComputerESP", {Text = "Computer ESP", Default = false})
        :AddColorPicker("ComputerESPColor", {Default = Color3.fromRGB(0,255,0), Title = "Normal"})
        :AddColorPicker("ComputerESPCompletedColor", {Default = Color3.fromRGB(40,127,71), Title = "Completed"})

    ESPTab:AddToggle("FreezePodESP", {Text = "Freeze Pod ESP", Default = false}):AddColorPicker("FreezePodESPColor", {Default = Color3.fromRGB(0,255,255)})
    ESPTab:AddToggle("BeastESP", {Text = "Beast ESP", Default = false}):AddColorPicker("BeastESPColor", {Default = Color3.fromRGB(255,0,0)})
    ESPTab:AddToggle("SurvivorESP", {Text = "Survivor ESP", Default = false}):AddColorPicker("SurvivorESPColor", {Default = Color3.fromRGB(255,255,255)})

    local ConfigTab = VisualsTabbox:AddTab("Configurations", "gear")
    ConfigTab:AddToggle("ShowDistance", {Text = "Show Distance", Default = true})
    ConfigTab:AddLabel("Tracers"); ConfigTab:AddDivider()
    ConfigTab:AddToggle("SurvivorTracers", {Text = "Survivor Tracers", Default = false})
    ConfigTab:AddToggle("BeastTracers", {Text = "Beast Tracers", Default = false})
    ConfigTab:AddToggle("ComputerTracers", {Text = "Computer Tracers", Default = false})
    ConfigTab:AddToggle("FreezePodTracers", {Text = "Freeze Pod Tracers", Default = false})
    ConfigTab:AddLabel("Outlines"); ConfigTab:AddDivider()
    ConfigTab:AddToggle("OutlineSurvivors", {Text = "Outline Survivors", Default = false})
    ConfigTab:AddToggle("OutlineBeast", {Text = "Outline Beast", Default = false})
    ConfigTab:AddToggle("OutlineComputers", {Text = "Outline Computers", Default = false})
    ConfigTab:AddToggle("OutlineFreezePod", {Text = "Outline Freeze Pod", Default = false})
    ConfigTab:AddLabel("Rainbow Effects"); ConfigTab:AddDivider()
    ConfigTab:AddToggle("RainbowSurvivorESP", {Text = "Rainbow Survivors ESPs", Default = false})
    ConfigTab:AddToggle("RainbowBeastESP", {Text = "Rainbow Beast ESPs", Default = false})
    ConfigTab:AddToggle("RainbowComputerESP", {Text = "Rainbow Computers ESPs", Default = false})
    ConfigTab:AddToggle("RainbowFreezePodESP", {Text = "Rainbow Freeze Pod ESPs", Default = false})
    ConfigTab:AddSlider("RainbowSpeed", {Text = "Rainbow Speed", Default = 1, Min = 1, Max = 10, Rounding = 1})
    ConfigTab:AddLabel("Other"); ConfigTab:AddDivider()
    ConfigTab:AddSlider("ESPTextSize", {Text = "ESP Text Size", Default = 16, Min = 1, Max = 50, Rounding = 0})
    ConfigTab:AddSlider("TracerThickness", {Text = "Tracer Thickness", Default = 2, Min = 1, Max = 10, Rounding = 0})
    ConfigTab:AddSlider("OutlineFillTransparency", {Text = "Outline Fill (%)", Default = 100, Min = 0, Max = 100, Rounding = 0})
    ConfigTab:AddSlider("OutlineTransparency", {Text = "Outline Transp (%)", Default = 0, Min = 0, Max = 100, Rounding = 0})
    ConfigTab:AddToggle("AutoReloadESP", {Text = "Auto Re-Load ESP", Default = false})

    local VisualsGameCamGB = Tabs.Visuals:AddRightGroupbox("Game & Camera", "camera")
    VisualsGameCamGB:AddSlider("FOVSlider", {Text = "FOV", Default = 80, Min = 80, Max = 120, Rounding = 0})
    VisualsGameCamGB:AddToggle("Fullbright", {Text = "Full Bright", Default = false}):AddColorPicker("FullbrightColor", {Default = Color3.fromRGB(255,255,255)})
    VisualsGameCamGB:AddToggle("NoFog", {Text = "No Fog", Default = false})

    local ESP = {Drawings = {}, Tracers = {}, Highlights = {}}
    
    local function CreateLine()
        local l = Drawing.new("Line")
        l.Visible = false; l.Thickness = 2; l.Transparency = 1
        return l
    end

    local function CreateHighlight()
        local h = Instance.new("Highlight")
        h.FillTransparency = 1; h.OutlineTransparency = 0; h.Enabled = false
        return h
    end

    local function CreateBillboard(target)
        if not target then return nil end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "unxcontainer"
        billboard.Adornee = target
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 2, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = false
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Parent = billboard
        textLabel.BackgroundTransparency = 1
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        textLabel.TextSize = 16
        textLabel.Font = Enum.Font.BuilderSans 
        textLabel.Text = "..."
        
        local uiStroke = Instance.new("UIStroke")
        uiStroke.Parent = textLabel
        uiStroke.Thickness = 1.2
        uiStroke.Color = Color3.fromRGB(200, 200, 200)
        uiStroke.Transparency = 0
        
        if target:IsA("BasePart") or target:IsA("Model") then billboard.Parent = target else billboard.Parent = game.CoreGui end
        return billboard
    end

    local function GetRainbow(speed) return Color3.fromHSV((tick() * ((speed or 1) / 10)) % 1, 1, 1) end
    local function GetDarkerColor(c) return Color3.new(math.clamp(c.R * 0.784, 0, 1), math.clamp(c.G * 0.784, 0, 1), math.clamp(c.B * 0.784, 0, 1)) end

    local function RemoveESP(key)
        local d = ESP.Drawings[key]
        if d and d:IsA("Instance") then d:Destroy() end
        local t = ESP.Tracers[key]
        if t and t.Remove then t:Remove() end
        local h = ESP.Highlights[key]
        if h and h.Destroy then h:Destroy() end
        ESP.Drawings[key], ESP.Tracers[key], ESP.Highlights[key] = nil, nil, nil
    end

    local function ClearAllESP()
        for key in pairs(ESP.Drawings) do RemoveESP(key) end
        for key in pairs(ESP.Tracers) do RemoveESP(key) end
        for key in pairs(ESP.Highlights) do RemoveESP(key) end
    end
    VisualsMaid:GiveTask(ClearAllESP)

    ConfigTab:AddButton("Re-load ESPs", function() ClearAllESP() CacheManager:Update() end)

    local function MonitorPlayer(player)
        if player == LocalPlayer then return end
        VisualsMaid:GiveTask(player.CharacterAdded:Connect(function(char)
            VisualsMaid:GiveTask(char.AncestryChanged:Connect(function(_, parent)
                if not parent then RemoveESP("Beast_" .. player.UserId); RemoveESP("Surv_" .. player.UserId) end
            end))
        end))
        VisualsMaid:GiveTask(player.CharacterRemoving:Connect(function() RemoveESP("Beast_" .. player.UserId); RemoveESP("Surv_" .. player.UserId) end))
    end

    for _, p in ipairs(Players:GetPlayers()) do MonitorPlayer(p) end
    VisualsMaid:GiveTask(Players.PlayerAdded:Connect(MonitorPlayer))
    VisualsMaid:GiveTask(Players.PlayerRemoving:Connect(function(player) RemoveESP("Beast_" .. player.UserId); RemoveESP("Surv_" .. player.UserId) end))

    local function UpdateESP()
        local activeKeys = {}
        local cam = workspace.CurrentCamera
        if not cam then return end
        local camPos = cam.CFrame.Position
        local showDist = Toggles.ShowDistance and Toggles.ShowDistance.Value

        for _, bb in pairs(ESP.Drawings) do 
            if bb and bb:IsA("BillboardGui") then
                local txt = bb:FindFirstChild("TextLabel")
                if txt then txt.TextSize = Options.ESPTextSize and Options.ESPTextSize.Value or 16 end
            end 
        end
        for _, l in pairs(ESP.Tracers) do if l then l.Thickness = Options.TracerThickness and Options.TracerThickness.Value or 2 end end
        for _, h in pairs(ESP.Highlights) do 
            if h then 
                h.FillTransparency = (Options.OutlineFillTransparency and Options.OutlineFillTransparency.Value or 100) / 100
                h.OutlineTransparency = (Options.OutlineTransparency and Options.OutlineTransparency.Value or 0) / 100
            end 
        end

        if Toggles.ComputerESP and Toggles.ComputerESP.Value then
            for i, obj in ipairs(CacheManager.Computers) do
                if obj and obj.Parent then
                    local screen = obj:FindFirstChild("Screen")
                    local isCompleted, isError = false, false
                    if screen and screen:IsA("BasePart") then
                        local c = screen.Color
                        if math.abs(c.R*255 - 40) < 5 and math.abs(c.G*255 - 127) < 5 and math.abs(c.B*255 - 71) < 5 then isCompleted = true
                        elseif math.abs(c.R*255 - 196) < 5 and math.abs(c.G*255 - 40) < 5 and math.abs(c.B*255 - 28) < 5 then isError = true end
                    end

                    local key = "Comp_" .. obj:GetDebugId()
                    activeKeys[key] = true
                    local targetPart = screen or obj.PrimaryPart
                    local billboard = ESP.Drawings[key] 
                    if not billboard or billboard.Parent ~= targetPart then
                        if billboard then billboard:Destroy() end
                        if targetPart then billboard = CreateBillboard(targetPart); ESP.Drawings[key] = billboard end
                    end
                    local tracer = ESP.Tracers[key] or CreateLine(); ESP.Tracers[key] = tracer
                    local hl = ESP.Highlights[key] or CreateHighlight(); ESP.Highlights[key] = hl
                    
                    local color = (Toggles.RainbowComputerESP and Toggles.RainbowComputerESP.Value and GetRainbow(Options.RainbowSpeed.Value)) or
                                  (isError and Color3.fromRGB(196, 40, 28)) or
                                  (isCompleted and (Options.ComputerESPCompletedColor and Options.ComputerESPCompletedColor.Value or Color3.fromRGB(40, 127, 71))) or
                                  (Options.ComputerESPColor and Options.ComputerESPColor.Value or Color3.fromRGB(0, 255, 0))

                    local pos = obj:GetPivot().Position
                    if billboard then
                        local txt = billboard:FindFirstChild("TextLabel")
                        if txt then
                            txt.Text = "Computer #"..i..(showDist and " ["..math.floor((camPos-pos).Magnitude).."]" or "")..(isError and " (ERROR)" or (isCompleted and " (COMPLETED)" or ""))
                            txt.TextColor3 = color
                            local stroke = txt:FindFirstChild("UIStroke")
                            if stroke then stroke.Color = GetDarkerColor(color) end
                        end
                        billboard.Enabled = true
                    end

                    if Toggles.ComputerTracers.Value then
                        local screenPos, onScreen = cam:WorldToViewportPoint(pos + Vector3.new(0, 5, 0))
                        if onScreen then
                            tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y)
                            tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            tracer.Color = color
                            tracer.Visible = true
                        else tracer.Visible = false end
                    else tracer.Visible = false end
                    
                    if Toggles.OutlineComputers.Value then
                        hl.Parent = obj; hl.FillColor = color; hl.OutlineColor = color; hl.Enabled = true
                    else hl.Enabled = false end
                end
            end
        else
            for i, obj in ipairs(CacheManager.Computers) do
                 local key = "Comp_" .. obj:GetDebugId()
                 if ESP.Drawings[key] then ESP.Drawings[key].Enabled = false end
                 if ESP.Tracers[key] then ESP.Tracers[key].Visible = false end
                 if ESP.Highlights[key] then ESP.Highlights[key].Enabled = false end
            end
        end

        -- Note: FreezePod logic follows same pattern, condensing for brevity in modular logic
        if Toggles.FreezePodESP and Toggles.FreezePodESP.Value then
            for i, obj in ipairs(CacheManager.Pods) do
                if obj and obj.Parent then
                    local key = "Pod_" .. obj:GetDebugId(); activeKeys[key] = true
                    local targetPart = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
                    local billboard = ESP.Drawings[key]
                    if not billboard or billboard.Parent ~= targetPart then
                        if billboard then billboard:Destroy() end
                        if targetPart then billboard = CreateBillboard(targetPart); ESP.Drawings[key] = billboard end
                    end
                    local tracer = ESP.Tracers[key] or CreateLine(); ESP.Tracers[key] = tracer
                    local hl = ESP.Highlights[key] or CreateHighlight(); ESP.Highlights[key] = hl
                    local color = (Toggles.RainbowFreezePodESP and Toggles.RainbowFreezePodESP.Value and GetRainbow(Options.RainbowSpeed.Value)) or (Options.FreezePodESPColor and Options.FreezePodESPColor.Value or Color3.fromRGB(0,255,255))
                    local pos = obj:GetPivot().Position
                    if billboard then
                        local txt = billboard:FindFirstChild("TextLabel")
                        if txt then
                            txt.Text = "Freeze Pod #"..i..(showDist and " ["..math.floor((camPos-pos).Magnitude).."]" or "")
                            txt.TextColor3 = color
                            if txt:FindFirstChild("UIStroke") then txt:FindFirstChild("UIStroke").Color = GetDarkerColor(color) end
                        end
                        billboard.Enabled = true
                    end
                    if Toggles.FreezePodTracers.Value then
                        local screenPos, onScreen = cam:WorldToViewportPoint(pos + Vector3.new(0, 5, 0))
                        if onScreen then tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y); tracer.To = Vector2.new(screenPos.X, screenPos.Y); tracer.Color = color; tracer.Visible = true else tracer.Visible = false end
                    else tracer.Visible = false end
                    if Toggles.OutlineFreezePod.Value then hl.Parent = obj; hl.FillColor = color; hl.OutlineColor = color; hl.Enabled = true else hl.Enabled = false end
                end
            end
        else
            for i, obj in ipairs(CacheManager.Pods) do
                 local key = "Pod_" .. obj:GetDebugId()
                 if ESP.Drawings[key] then ESP.Drawings[key].Enabled = false end
                 if ESP.Tracers[key] then ESP.Tracers[key].Visible = false end
                 if ESP.Highlights[key] then ESP.Highlights[key].Enabled = false end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local isBeast = player.Character:FindFirstChild("Hammer") ~= nil
                local key = (isBeast and "Beast_" or "Surv_") .. player.UserId
                local shouldShow = (isBeast and Toggles.BeastESP and Toggles.BeastESP.Value) or (not isBeast and Toggles.SurvivorESP and Toggles.SurvivorESP.Value)
                
                if shouldShow then
                    local root = player.Character:FindFirstChild("HumanoidRootPart")
                    local head = player.Character:FindFirstChild("Head")
                    if root and head then
                        activeKeys[key] = true
                        local billboard = ESP.Drawings[key]
                        if not billboard or billboard.Parent ~= head then
                            if billboard then billboard:Destroy() end
                            billboard = CreateBillboard(head); ESP.Drawings[key] = billboard
                        end
                        local tracer = ESP.Tracers[key] or CreateLine(); ESP.Tracers[key] = tracer
                        local hl = ESP.Highlights[key] or CreateHighlight(); ESP.Highlights[key] = hl
                        
                        local useRainbow = (isBeast and Toggles.RainbowBeastESP and Toggles.RainbowBeastESP.Value) or (not isBeast and Toggles.RainbowSurvivorESP and Toggles.RainbowSurvivorESP.Value)
                        local color = useRainbow and GetRainbow(Options.RainbowSpeed.Value) or (isBeast and (Options.BeastESPColor and Options.BeastESPColor.Value or Color3.fromRGB(255,0,0)) or (Options.SurvivorESPColor and Options.SurvivorESPColor.Value or Color3.fromRGB(255,255,255)))
                        
                        if billboard then
                            local txt = billboard:FindFirstChild("TextLabel")
                            if txt then
                                txt.Text = player.DisplayName..(isBeast and " [BEAST]" or " [SURV]")..(showDist and " ["..math.floor((camPos-root.Position).Magnitude).."]" or "")
                                txt.TextColor3 = color
                                if txt:FindFirstChild("UIStroke") then txt:FindFirstChild("UIStroke").Color = GetDarkerColor(color) end
                            end
                            billboard.Enabled = true
                        end

                        if (isBeast and Toggles.BeastTracers.Value) or (not isBeast and Toggles.SurvivorTracers.Value) then
                            local screenPos, onScreen = cam:WorldToViewportPoint(root.Position + Vector3.new(0,3.5,0))
                            if onScreen then tracer.From = Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y); tracer.To = Vector2.new(screenPos.X, screenPos.Y); tracer.Color = color; tracer.Visible = true else tracer.Visible = false end
                        else tracer.Visible = false end

                        if (isBeast and Toggles.OutlineBeast.Value) or (not isBeast and Toggles.OutlineSurvivors.Value) then hl.Parent = player.Character; hl.FillColor = color; hl.OutlineColor = color; hl.Enabled = true else hl.Enabled = false end
                    end
                else
                    if ESP.Drawings[key] then ESP.Drawings[key].Enabled = false end
                    if ESP.Tracers[key] then ESP.Tracers[key].Visible = false end
                    if ESP.Highlights[key] then ESP.Highlights[key].Enabled = false end
                end
            else
                local k1, k2 = "Beast_"..player.UserId, "Surv_"..player.UserId
                if ESP.Drawings[k1] then ESP.Drawings[k1].Enabled = false end
                if ESP.Tracers[k1] then ESP.Tracers[k1].Visible = false end
                if ESP.Highlights[k1] then ESP.Highlights[k1].Enabled = false end
                if ESP.Drawings[k2] then ESP.Drawings[k2].Enabled = false end
                if ESP.Tracers[k2] then ESP.Tracers[k2].Visible = false end
                if ESP.Highlights[k2] then ESP.Highlights[k2].Enabled = false end
            end
        end

        for key in pairs(ESP.Drawings) do
            if not activeKeys[key] and not string.find(key, "Beast_") and not string.find(key, "Surv_") then RemoveESP(key) end
        end
    end
    
    VisualsMaid:GiveTask(RunService.RenderStepped:Connect(UpdateESP))
    
    local lastAutoReload = 0
    VisualsMaid:GiveTask(RunService.Heartbeat:Connect(function()
        if Toggles.AutoReloadESP and Toggles.AutoReloadESP.Value and tick() - lastAutoReload > 1 then
            CacheManager:Update()
            lastAutoReload = tick()
        end
    end))

    local LightingMaid = MaidClass.new()
    VisualsMaid:GiveTask(LightingMaid)

    LightingMaid:GiveTask(RunService.Heartbeat:Connect(function()
        workspace.CurrentCamera.FieldOfView = Options.FOVSlider and Options.FOVSlider.Value or 80
        if Toggles.Fullbright and Toggles.Fullbright.Value then
            local color = Options.FullbrightColor and Options.FullbrightColor.Value or Color3.fromRGB(255,255,255)
            Lighting.Ambient = color; Lighting.ColorShift_Bottom = color; Lighting.ColorShift_Top = color
            Lighting.OutdoorAmbient = color; Lighting.Brightness = 1; Lighting.ClockTime = 12; Lighting.GlobalShadows = false
        else
            Lighting.Ambient = Color3.fromRGB(127, 127, 127); Lighting.ColorShift_Bottom = Color3.new(); Lighting.ColorShift_Top = Color3.new()
            Lighting.OutdoorAmbient = Color3.fromRGB(127, 127, 127); Lighting.Brightness = 1; Lighting.ClockTime = 14; Lighting.GlobalShadows = true
        end
        if Toggles.NoFog and Toggles.NoFog.Value then
            Lighting.FogEnd = 100000; Lighting.FogStart = 0; if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Density = 0 end
        else
            Lighting.FogEnd = 100; Lighting.FogStart = 0; if Lighting:FindFirstChild("Atmosphere") then Lighting.Atmosphere.Density = 0.3 end
        end
    end))
end
