local ExampleURL = "https://raw.githubusercontent.com/not-gato/Beta/main/API/v3/example.c.luau"
local CoolerURL = "https://raw.githubusercontent.com/not-gato/Beta/main/API/v3/coolerexample.c.luau"
local SettingsURL = "https://raw.githubusercontent.com/not-gato/Beta/main/API/v3/uisettings.c.luau"

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "UNXHub",
    Footer = "hi :)",
    Icon = 0,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {}

local request = (http and http.request) or http_request or request

local function unxgmfu(url, ...)
    local response = request({Url = url, Method = "GET"})
    local chunk = loadstring(response.Body)
    local moduleFunc = chunk()
    moduleFunc(...)
end

unxgmfu(ExampleURL, Library, Window, Tabs)
unxgmfu(CoolerURL, Library, Window, Tabs)
unxgmfu(SettingsURL, Library, Window, Tabs, ThemeManager, SaveManager)

Library:OnUnload(function()
    Library.Unloaded = true
end)
