return function(Library, Window, Tabs, ThemeManager, SaveManager)
    Tabs.UnxHub = Window:AddTab("UNXHub", "settings")

    local MenuGroup = Tabs.UnxHub:AddLeftGroupbox("Menu")

    MenuGroup:AddButton("Unload", function() Library:Unload() end)
    MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

    Library.ToggleKeybind = Library.Options.MenuKeybind

    ThemeManager:SetLibrary(Library)
    SaveManager:SetLibrary(Library)

    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

    ThemeManager:SetFolder("UnxHub")
    SaveManager:SetFolder("UnxHub/main")

    SaveManager:BuildConfigSection(Tabs.UnxHub)
    ThemeManager:ApplyToTab(Tabs.UnxHub)
end
