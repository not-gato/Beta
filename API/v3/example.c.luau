return function(Library, Window, Tabs)
    Tabs.Example = Window:AddTab("Example", "box")
    
    local Group = Tabs.Example:AddLeftGroupbox("Main Features")
    
    Group:AddToggle("MyToggle", {
        Text = "Enabled",
        Default = true,
        Tooltip = "This is a toggle",
    })

    Group:AddSlider("MySlider", {
        Text = "Speed",
        Default = 16,
        Min = 0,
        Max = 100,
        Rounding = 0,
        Compact = false,
    })

    Group:AddButton("Click Me", function()
        print("Button clicked in Example tab")
    end)
end
