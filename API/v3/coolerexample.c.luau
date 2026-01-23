return function(Library, Window, Tabs)
    Tabs.Cool = Window:AddTab("Example But Cool", "box")
    
    local LeftGroup = Tabs.Cool:AddLeftGroupbox("Cool Features")
    local RightGroup = Tabs.Cool:AddRightGroupbox("Extra")

    LeftGroup:AddLabel("This tab is separated into a new file :p gah")
    
    LeftGroup:AddDropdown("CoolDropdown", {
        Values = { "Option 1", "Option 2", "Option 3" },
        Default = 1,
        Multi = false,
        Text = "Select Mode",
    })

    RightGroup:AddInput("CoolInput", {
        Default = "",
        Numeric = false,
        Finished = true,
        Text = "Custom Text",
        Placeholder = "Type here...",
    })

    RightGroup:AddToggle("CoolToggle", {
        Text = "Risky Feature 👁👁",
        Default = false,
        Risky = true,
    })
end
