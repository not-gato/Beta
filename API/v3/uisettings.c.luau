return function(Library, Window, Tabs, ThemeManager, SaveManager)
    Tabs.Settings = Window:AddTab("UI Settings", "settings")

    local MenuGroup = Tabs.Settings:AddLeftGroupbox("Menu")

    MenuGroup:AddButton("Unload", function() Library:Unload() end)
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

    Library.ToggleKeybind = Library.Options.MenuKeybind

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

    ThemeManager:SetFolder("mspaint")
    SaveManager:SetFolder("mspaint/main")

    SaveManager:BuildConfigSection(Tabs.Settings)
    ThemeManager:ApplyToTab(Tabs.Settings)
end
