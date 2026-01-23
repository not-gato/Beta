return function(Library, Tabs, RootMaid, SaveManager, ThemeManager)
    local UserInputService = game:GetService("UserInputService")
    local TweenService = game:GetService("TweenService")
    local BindModule = loadstring(game:HttpGet("https://apigetunx.vercel.app/Modules/v2/Bind.lua"))()
    
    local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default = "RightShift", NoUI = true, Text = "Menu keybind"})
    MenuGroup:AddButton("Unload", function() Library:Unload() end)
    MenuGroup:AddDivider()
    MenuGroup:AddButton("Reset Bind Buttons Position", function() if BindModule then BindModule:ResetPos() end end)
    MenuGroup:AddDropdown("BindShape", {
        Text = "Bind Buttons Shape", Values = {"Circle", "Square", "Rounded"}, Default = 1,
        Callback = function(v) if BindModule then BindModule:MakeAllShape(v=="Circle" and 0 or v=="Square" and 1 or 2) end end
    })
    MenuGroup:AddSlider("BindSize", {Text = "Bind Button Size", Default = 1, Min = 0.1, Max = 10, Rounding = 1, Callback = function(v) if BindModule then BindModule:SetSizeB(v) end end})

    Library.ToggleKeybind = Library.Options.MenuKeybind
    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({"MenuKeybind"})
    ThemeManager:SetFolder("unxhub")
    SaveManager:SetFolder("unxhub")
    SaveManager:BuildConfigSection(Tabs["UI Settings"])
    ThemeManager:ApplyToTab(Tabs["UI Settings"])
    SaveManager:LoadAutoloadConfig()

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "CustomButtonGui"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.DisplayOrder = 999999999
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = gethui and gethui() or game:GetService("CoreGui")
    RootMaid:GiveTask(screenGui)

    local button = Instance.new("ImageButton")
    button.Name = "CustomButton"
    button.Image = "rbxassetid://130346803512317"
    button.BackgroundTransparency = 1
    button.Position = UDim2.new(0.5, 0, 0, 50)
    button.AnchorPoint = Vector2.new(0.5, 0)
    button.Size = UDim2.new(0, 60, 0, 60)
    button.ClipsDescendants = true
    button.ZIndex = 999999999
    button.Visible = false
    button.Parent = screenGui
    
    local uiCorner = Instance.new("UICorner", button); uiCorner.CornerRadius = UDim.new(0, 6)
    local uiStroke = Instance.new("UIStroke", button); uiStroke.Color = Color3.fromRGB(255, 255, 255); uiStroke.Thickness = 2
    local uiGradient = Instance.new("UIGradient", uiStroke); uiGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 140, 100)), ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 90, 65))}

    local currentInput, dragStartPos, isDragging, clickStartTime = nil, nil, false, 0
    local dragThreshold = 8

    RootMaid:GiveTask(button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if currentInput then return end
            currentInput = input; dragStartPos = input.Position; isDragging = false; clickStartTime = tick()
        end
    end))

    RootMaid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if input == currentInput and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStartPos
            if delta.Magnitude > dragThreshold then isDragging = true end
            if isDragging then TweenService:Create(button, TweenInfo.new(0.1), {Position = UDim2.new(0, dragStartPos.X + delta.X, 0, dragStartPos.Y + delta.Y)}):Play() end
        end
    end))

    RootMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input == currentInput then
            if not isDragging and tick() - clickStartTime < 0.3 then
                Library:Toggle()
                local pos, absPos, absSize = input.Position, button.AbsolutePosition, button.AbsoluteSize
                local wave = Instance.new("ImageLabel", button)
                wave.Size = UDim2.new(0,0,0,0); wave.Position = UDim2.new((pos.X-absPos.X)/absSize.X, 0, (pos.Y-absPos.Y)/absSize.Y, 0); wave.AnchorPoint = Vector2.new(0.5,0.5)
                wave.BackgroundTransparency = 1; wave.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"; wave.ImageTransparency = 0.3; wave.ZIndex = 9e8
                Instance.new("UICorner", wave).CornerRadius = UDim.new(1,0)
                TweenService:Create(wave, TweenInfo.new(0.5), {Size = UDim2.new(2.5,0,2.5,0), ImageTransparency = 1}):Play()
                game.Debris:AddItem(wave, 0.5)
            end
            currentInput = nil; isDragging = false
        end
    end))

    local function updateButtonSize()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local base = math.clamp(math.min(vp.X, vp.Y) * 0.08, 50, 80)
        local scale = (Library.Options.CustomToggleSize and Library.Options.CustomToggleSize.Value or 100) / 100
        button.Size = UDim2.new(0, base * scale, 0, base * scale)
    end
    RootMaid:GiveTask(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateButtonSize))

    local showToggle = isfile("showtoggle.unx")
    MenuGroup:AddToggle("CustomToggle", {Text = "Custom Toggle", Default = showToggle, Callback = function(v) 
        if v then writefile("showtoggle.unx", "") else if isfile("showtoggle.unx") then delfile("showtoggle.unx") end end
        button.Visible = v 
    end})

    local toggleSize = 100
    if isfile("togglesize.unx") then toggleSize = tonumber(readfile("togglesize.unx")) or 100 end
    MenuGroup:AddSlider("CustomToggleSize", {Text = "Custom Toggle Size (%)", Default = toggleSize, Min = 50, Max = 200, Rounding = 0, Callback = function(v)
        writefile("togglesize.unx", tostring(v)); updateButtonSize()
    end})
    
    if showToggle then button.Visible = true end
    updateButtonSize()
end
