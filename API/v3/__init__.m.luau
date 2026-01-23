local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local BaseUrl = "https://raw.githubusercontent.com/not-gato/Beta/main/API/v3/"

local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

local function SafeCallback(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        return false, result
    end
    return true, result
end

local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

local function unxgmfu(url, ...)
    local success, response = pcall(request, {Url = url, Method = "GET"})
    
    if not success or not response or not response.Body then
        warn("[UNXHub] Failed to fetch URL: " .. url .. " | Error: " .. tostring(response))
        return
    end

    local chunk, loadErr = loadstring(response.Body)
    if not chunk then
        warn("[UNXHub] Syntax Error in " .. url .. ": " .. tostring(loadErr))
        return
    end

    local chunkSuccess, moduleFunc = SafeCallback(chunk)
    if not chunkSuccess then
        warn("[UNXHub] Error initializing chunk " .. url .. ": " .. tostring(moduleFunc))
        return
    end

    if type(moduleFunc) ~= "function" then
        warn("[UNXHub] Module at " .. url .. " did not return a function.")
        return
    end

    local runSuccess, runErr = SafeCallback(moduleFunc, ...)
    if not runSuccess then
        warn("[UNXHub] Runtime Error inside " .. url .. ": " .. tostring(runErr))
    end
end

local MaidClass
local maidSuccess, maidResult = pcall(function() 
    local chunk = loadstring(game:HttpGet(BaseUrl .. "maid.m.luau"))
    local factory = chunk()
    return factory()
end)

if not maidSuccess then
    warn("[UNXHub] Critical: Failed to load Maid class: " .. tostring(maidResult))
    return
end
MaidClass = maidResult

Library.ForceCheckbox = true

local Window = Library:CreateWindow({
    Title = "UNXHub | FTF",
    Footer = "Version: " .. (getgenv().unxshared and getgenv().unxshared.version or "Modular") .. ", Game: " .. (getgenv().unxshared and getgenv().unxshared.gamename or "Unknown"),
    Icon = 73740010358428,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Main = Window:AddTab("Main", "user"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Features = Window:AddTab("Features", "bug"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local RootMaid = MaidClass.new()
local RunService = game:GetService("RunService")

local CacheManager = {
    Computers = {},
    Pods = {},
    Exits = {}
}

function CacheManager:Update()
    local pcs = {}
    local pods = {}
    local exits = {}

    local descendants = workspace:GetDescendants()
    for i = 1, #descendants do
        local obj = descendants[i]
        if obj:IsA("Model") then
            if obj.Name == "ComputerTable" then
                local screen = obj:FindFirstChild("Screen")
                if screen and screen:IsA("BasePart") then
                    table.insert(pcs, obj)
                end
            elseif obj.Name == "FreezePod" or obj.Name == "Freeze Pod" then
                table.insert(pods, obj)
            end
        elseif obj:IsA("BasePart") and obj.Name == "ExitDoorTrigger" then
            table.insert(exits, obj)
        end
    end

    self.Computers = pcs
    self.Pods = pods
    self.Exits = exits
end

RootMaid:GiveTask(task.spawn(function()
    CacheManager:Update()
    while task.wait(5) do
        CacheManager:Update()
    end
end))

unxgmfu(BaseUrl .. "main.t.luau", Library, Tabs, RootMaid, CacheManager, MaidClass)
unxgmfu(BaseUrl .. "visuals.t.luau", Library, Tabs, RootMaid, CacheManager, MaidClass)
unxgmfu(BaseUrl .. "features.t.luau", Library, Tabs, RootMaid, CacheManager, MaidClass)
unxgmfu(BaseUrl .. "uisettings.t.luau", Library, Tabs, RootMaid, SaveManager, ThemeManager)

Library:OnUnload(function()
    if getgenv().unxshared then getgenv().unxshared.isloaded = false end
    RootMaid:Destroy()
    Library.Unloaded = true
end)
