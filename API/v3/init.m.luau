local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "UNXHub",
    Footer = "hi :)!",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {}

local function Loadthinf(url, ...)
    local func, err = loadstring(game:HttpGet(url))
    if not func then 
        return 
    end
    func(...)
end

Loadthinf("https://raw.githubusercontent.com/not-gato/Beta/refs/heads/main/API/v3/example.c.luau", Library, Window, Tabs)
Loadthinf("https://raw.githubusercontent.com/not-gato/Beta/refs/heads/main/API/v3/coolerexample.c.luau", Library, Window, Tabs)
Loadthinf("https://raw.githubusercontent.com/not-gato/Beta/refs/heads/main/API/v3/uisettings.c.luau", Library, Window, Tabs, ThemeManager, SaveManager)

Library:OnUnload(function()
    Library.Unloaded = true
end)
