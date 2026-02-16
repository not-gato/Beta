getgenv().isunx = "this is unxhub. | anti tamper: ahQ%o_q=8mQQt_[QAk"

local Repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local BaseUrl = "https://raw.githubusercontent.com/not-gato/Beta/main/API/v3/"

local Library = loadstring(game:HttpGet(Repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(Repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(Repo .. "addons/SaveManager.lua"))()

Library.ForceCheckbox = true

local function SafeCallback(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        return false, result
    end
    return true, result
end

local request = http_request or request or (http and http.request)

local function unxgmfu(url, ...)
    local fileName = url:match("^.+/(.+)$") or url
    
    Library:Notify("Fetching " .. fileName, 1)

    local success, response = pcall(request, {Url = url, Method = "GET"})
    
    if not success or not response or not response.Body then
        warn("[UNXHub] Failed to fetch URL: " .. url .. " | Error: " .. tostring(response))
        Library:Notify("Failed to fetch " .. fileName, 2)
        return nil
    end

    local chunk, loadErr = loadstring(response.Body)
    if not chunk then
        warn("[UNXHub] Syntax Error in " .. url .. ": " .. tostring(loadErr))
        Library:Notify("Syntax Error in " .. fileName, 2)
        return nil
    end

    local chunkSuccess, moduleFunc = SafeCallback(chunk)
    if not chunkSuccess then
        warn("[UNXHub] Error initializing chunk " .. url .. ": " .. tostring(moduleFunc))
        Library:Notify("Init Error in " .. fileName, 2)
        return nil
    end

    if type(moduleFunc) ~= "function" then
        warn("[UNXHub] Module at " .. url .. " did not return a function")
        Library:Notify(fileName .. " invalid return", 2)
        return nil
    end

    local runSuccess, runResult = SafeCallback(moduleFunc, ...)
    if not runSuccess then
        warn("[UNXHub] Runtime Error inside " .. url .. ": " .. tostring(runResult))
        Library:Notify("Runtime Error in " .. fileName, 2)
        return nil
    else
        Library:Notify("Loaded Sucessfully: " .. fileName, 2)
        return runResult
    end
end

local MaidClass = unxgmfu(BaseUrl .. "maid.m.luau")
if not MaidClass then return end

local Translator = unxgmfu(BaseUrl .. "translator.m.luau")
if Translator then
    Translator.Init()
end

local Window = Library:CreateWindow({
    Title = "UNXHub | FTF",
    Footer = "Version: " .. (getgenv().unxshared and getgenv().unxshared.version or "Modular") .. ", Game: " .. (getgenv().unxshared and getgenv().unxshared.gamename or "Unknown") .. ", Player: " .. (getgenv().unxshared and getgenv().unxshared.playername or "Unknown"),
    Icon = 73740010358428,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local T = Translator.T
local Tabs = {
    Main = Window:AddTab(T("Main"), "user"),
    Visuals = Window:AddTab(T("Visuals"), "eye"),
    Features = Window:AddTab(T("Features"), "bug"),
    ["UI Settings"] = Window:AddTab(T("UI Settings"), "settings"),
}

local RootMaid = MaidClass.new()
local RunService = game:GetService("RunService")

local CacheManager = {
    Computers = {},
    Pods = {},
    Exits = {}
}

CacheManager.Update = newcclosure(function(self)
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
end)

CacheManager:Update()

local Scheduler = unxgmfu(BaseUrl .. "scheduler.m.luau", Library, Tabs, RootMaid, CacheManager, MaidClass)

if Scheduler then
    RootMaid:GiveTask(Scheduler.Interval(5, newcclosure(function()
        CacheManager:Update()
    end)))
end

unxgmfu(BaseUrl .. "main.t.luau", Library, Tabs, RootMaid, CacheManager, MaidClass, Scheduler, Translator)
unxgmfu(BaseUrl .. "visuals.t.luau", Library, Tabs, RootMaid, CacheManager, MaidClass, Scheduler, Translator)
unxgmfu(BaseUrl .. "features.t.luau", Library, Tabs, RootMaid, CacheManager, MaidClass, Scheduler, Translator)
unxgmfu(BaseUrl .. "uisettings.t.luau", Library, Tabs, RootMaid, SaveManager, ThemeManager, Translator, Scheduler)

Library:OnUnload(newcclosure(function()
    if getgenv().unxshared then getgenv().unxshared.isloaded = false end
    RootMaid:Destroy()
    Library.Unloaded = true
end))
