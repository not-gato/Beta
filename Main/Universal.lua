--[[
half a sliced cake
IS THIS A PRESSURE REF?!?!!

/ = Good Points
\ = Bad Points

/ Better Logic
/ Better Optimization
/ Overall Better Stability ;)
\ Dont have all features
]]

getgenv().isunx = "this is unxhub. | anti tamper: ahQ%o_q=8mQQt_[QAk"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not isfolder("unxhub") then
    makefolder("unxhub")
    if not isfolder("unxhub/cache") then
        makefolder("unxhub/cache")
        if not isfile("unxhub/cache/lastlogs.txt") then
            writefile("unxhub/cache/lastlogs.txt")
        end
    end
end

function addlog(text, logtype)
    local time = os.date("%Y-%m-%d %H:%M:%S")
    local line = "[" .. time .. "][" .. tostring(logtype) .. "]: " .. tostring(text) .. "\n"
    if isfile("unxhub/cache/lastlogs.txt") then
        appendfile("unxhub/cache/lastlogs.txt", line)
    end
end

local function getsvr(service)
    local success, result = pcall(function()
        return game:GetService(service)
    end)
    if success and result then
        return result
    end
    return game:FindFirstChild(service) or game:FindFirstChildOfClass(service)
end

local Maid = loadstring([[
local Maid = {}
Maid.ClassName = "Maid"
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {},
		_destroyed = false,
	}, Maid)
end

local function cleanupTask(task)
	if not task then
		return
	end

	local t = typeof(task)

	if t == "RBXScriptConnection" then
		task:Disconnect()
	elseif t == "Instance" then
		task:Destroy()
	elseif type(task) == "function" then
		task()
	elseif type(task) == "table" and type(task.Destroy) == "function" then
		task:Destroy()
	end
end

function Maid:Give(key, task)
	if self._destroyed then
		cleanupTask(task)
		return
	end

	if self._tasks[key] then
		cleanupTask(self._tasks[key])
	end

	self._tasks[key] = task
	return task
end

function Maid:GiveTask(task)
	if self._destroyed then
		cleanupTask(task)
		return
	end

	table.insert(self._tasks, task)
	return task
end

function Maid:DoCleaning()
	if self._destroyed then
		return
	end

	self._destroyed = true

	for key, task in pairs(self._tasks) do
		cleanupTask(task)
		self._tasks[key] = nil
	end
end

function Maid:Destroy()
	self:DoCleaning()
end

return Maid
]])()

local Scheduler = loadstring([[
local Maid, RunService, addlog = ...

local Scheduler = {}
Scheduler.__index = Scheduler
Scheduler.Tasks = {}
Scheduler.Maid = Maid.new()

function Scheduler:Every(interval, fn)
    local taskObj = {
        Type = "Every",
        Interval = interval,
        NextRun = tick(),
        Function = fn,
        Active = true
    }
    table.insert(self.Tasks, taskObj)
    return taskObj
end

function Scheduler:After(delay, fn)
    local taskObj = {
        Type = "After",
        NextRun = tick() + delay,
        Function = fn,
        Active = true
    }
    table.insert(self.Tasks, taskObj)
    return taskObj
end

function Scheduler:Cancel(taskObj)
    if taskObj then taskObj.Active = false end
end

function Scheduler:Start()
    self.Maid:GiveTask(RunService.Heartbeat:Connect(function()
        local now = tick()
        for i = #self.Tasks, 1, -1 do
            local taskObj = self.Tasks[i]
            if not taskObj then
                table.remove(self.Tasks, i)
                continue
            end
            if not taskObj.Active then
                table.remove(self.Tasks, i)
            elseif now >= taskObj.NextRun then
                local success, err = pcall(taskObj.Function)
                if not success and addlog then addlog(tostring(err), "UNX_SCHELDULER_ERROR") end
                
                if taskObj and taskObj.Type == "Every" and taskObj.Active then
                    taskObj.NextRun = now + taskObj.Interval
                else
                    table.remove(self.Tasks, i)
                end
            end
        end
    end))
end

function Scheduler:Stop()
    self.Maid:DoCleaning()
    self.Tasks = {}
end

Scheduler:Start()
return Scheduler
]])(Maid, getsvr("RunService"), addlog)

local function GetHttp(url)
    addlog("GAH! Cache not found, using HttpGet() method for " .. tostring(url) .. "...", "UNX_LOADER")
    return game:HttpGet(url)
end

addlog("SafeGet thingy works", "UNX_LOADER")

local f_2 = "unxhub/cache"

local Library = loadstring(
    isfile(f_2 .. "/Library.lua") and readfile(f_2 .. "/Library.lua")
    or GetHttp("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua")
)()

do
    local _notify = Library.Notify
    function Library:Notify(...)
        task.spawn(function()
            local s = workspace:FindFirstChild("unx@instances") and workspace["unx@instances"]:FindFirstChild("unx@sfx")
            if s then
                s:Play()
            end
        end)
        return _notify(self, ...)
    end
end

local ThemeManager = loadstring(
    isfile(f_2 .. "/ThemeManager.lua") and readfile(f_2 .. "/ThemeManager.lua")
    or GetHttp("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/ThemeManager.lua")
)()

local SaveManager = loadstring(
    isfile(f_2 .. "/SaveManager.lua") and readfile(f_2 .. "/SaveManager.lua")
    or GetHttp("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/addons/SaveManager.lua")
)()

local BindModule = loadstring(
    isfile(f_2 .. "/Bind.lua") and readfile(f_2 .. "/Bind.lua")
    or GetHttp("https://api.getunx.cc/Modules/v2/Bind.lua")
)()

if not BindModule or type(BindModule) ~= "table" or not BindModule.Lock then
    BindModule = loadstring(GetHttp("https://api.getunx.cc/Modules/v2/Bind.lua"))()
end

addlog("Other stuff modules works", "UNX_LOADER")

local Options = Library.Options
local Toggles = Library.Toggles

local Players = getsvr("Players")
local RunService = getsvr("RunService")
local UserInputService = getsvr("UserInputService")
local Workspace = getsvr("Workspace")
local Lighting = getsvr("Lighting")
local CoreGui = getsvr("CoreGui")
local Teams = getsvr("Teams")

local OriginalGravity = workspace.Gravity

local function getTeamList()
    local t = {}
    for _, team in ipairs(Teams:GetTeams()) do
        table.insert(t, team.Name)
    end
    return t
end

local function getPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Players.LocalPlayer then table.insert(list, p.Name) end
    end
    return list
end

local CharacterManager = {}
CharacterManager.__index = CharacterManager

function CharacterManager.new()
    local self = setmetatable({}, CharacterManager)
    self.LocalPlayer = Players.LocalPlayer
    self.ClickToTPMaid = Maid.new()
    self.SwimMaid = Maid.new()
    self.SwimActive = false
    self.XRayOriginals = {}
    self.XRayActive = false
    self.OriginalWalkSpeed = 16
    self.OriginalJumpPower = 50
    self.OriginalMaxZoom = 128
    return self
end

function CharacterManager:Init()
    local VirtualUser = getsvr("VirtualUser")

    local char = self.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            self.OriginalWalkSpeed = hum.WalkSpeed
            self.OriginalJumpPower = hum.JumpPower
        end
    end
    self.OriginalMaxZoom = self.LocalPlayer.CameraMaxZoomDistance or 128

    self.LocalPlayer.CharacterAdded:Connect(function(newChar)
        local p = workspace:FindFirstChild("unx@pltf")
        if p then p:Destroy() end

        task.wait(0.5)
        local hum = newChar:FindFirstChildOfClass("Humanoid")
        if hum then
            self.OriginalWalkSpeed = hum.WalkSpeed
            self.OriginalJumpPower = hum.JumpPower
        end
    end)

    UserInputService.JumpRequest:Connect(function()
        if Toggles.InfiniteJump and Toggles.InfiniteJump.Value then
            local c = self.LocalPlayer.Character
            if c then
                local hum = c:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)

    RunService.Stepped:Connect(function()
        if Toggles.Noclip and Toggles.Noclip.Value then
            local c = self.LocalPlayer.Character
            if c then
                for _, part in pairs(c:GetChildren()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)

    self.LocalPlayer.Idled:Connect(function()
        if Toggles.NoAFKKick and Toggles.NoAFKKick.Value then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end
    end)

    Scheduler:Every(0.02, function()
        self:UpdateLoop()
    end)
end

function CharacterManager:StartSwim()
    if self.SwimActive then return end
    self.SwimActive = true
    self.SwimMaid:DoCleaning()
    self.SwimMaid = Maid.new()

    local player = self.LocalPlayer
    local camera = Workspace.CurrentCamera

    local function enableSwim()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        hum:SetStateEnabled(Enum.HumanoidStateType.Running, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)

        self.SwimMaid:GiveTask(function()
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end
        end)

        local attachment = Instance.new("Attachment")
        attachment.Name = "SwimAttachment"
        attachment.Parent = root
        self.SwimMaid:GiveTask(attachment)

        local linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Attachment0 = attachment
        linearVelocity.MaxForce = math.huge
        linearVelocity.VectorVelocity = Vector3.zero
        linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        linearVelocity.Parent = root
        self.SwimMaid:GiveTask(linearVelocity)

        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        bodyGyro.P = 10000
        bodyGyro.D = 500
        bodyGyro.Parent = root
        self.SwimMaid:GiveTask(bodyGyro)

        local controlModule
        pcall(function()
            controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule", 5):WaitForChild("ControlModule", 5))
        end)

        self.SwimMaid:GiveTask(RunService.Heartbeat:Connect(function()
            if not hum or not root or not linearVelocity.Parent or not bodyGyro.Parent then return end

            hum:ChangeState(Enum.HumanoidStateType.Swimming)
            local speed = tonumber(Options.SwimSpeed.Value) or 16

            if controlModule then
                local moveVector = controlModule:GetMoveVector()
                if moveVector.Magnitude > 0.01 then
                    local dir = camera.CFrame:VectorToWorldSpace(moveVector)
                    linearVelocity.VectorVelocity = dir * speed
                    bodyGyro.CFrame = camera.CFrame
                else
                    linearVelocity.VectorVelocity = Vector3.zero
                end
            else
                local moveDir = hum.MoveDirection
                if moveDir.Magnitude > 0.01 then
                    local camLook = camera.CFrame.LookVector
                    local dir = Vector3.new(moveDir.X, camLook.Y * moveDir.Magnitude, moveDir.Z)
                    linearVelocity.VectorVelocity = dir.Unit * speed
                    bodyGyro.CFrame = camera.CFrame
                else
                    linearVelocity.VectorVelocity = Vector3.zero
                end
            end
        end))
    end

    enableSwim()
    self.SwimMaid:GiveTask(player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if self.SwimActive then
            enableSwim()
        end
    end))
end

function CharacterManager:StopSwim()
    self.SwimActive = false
    self.SwimMaid:DoCleaning()
    self.SwimMaid = Maid.new()
end

function CharacterManager:HandleClickToTP(enabled)
    self.ClickToTPMaid:DoCleaning()
    self.ClickToTPMaid = Maid.new()
    if not enabled then return end

    local player = self.LocalPlayer
    local mouse = player:GetMouse()
    local method = Options.ClickToTPMethod and Options.ClickToTPMethod.Value or "Always On"

    if method == "Always On" then
        self.ClickToTPMaid:GiveTask(mouse.Button1Down:Connect(function()
            if UserInputService:GetFocusedTextBox() then return end
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root or not mouse.Hit then return end
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end))
    elseif method == "Tool" then
        local tool = Instance.new("Tool")
        tool.Name = "Teleport Tool"
        tool.RequiresHandle = false
        tool.CanBeDropped = false
        tool.ToolTip = "Click to teleport!"
        tool.TextureId = "rbxassetid://210746026"
        tool.Parent = player.Backpack
        self.ClickToTPMaid:GiveTask(tool)

        self.ClickToTPMaid:GiveTask(tool.Activated:Connect(function()
            local char = player.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root or not mouse.Hit then return end
            root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
        end))
    end
end

function CharacterManager:ApplyXRay()
    local transparencyVal = (Options.XRayTransparency and Options.XRayTransparency.Value or 50) / 100
    local localChar = self.LocalPlayer.Character

    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and not obj:IsA("Terrain") then
            if localChar and obj:IsDescendantOf(localChar) then continue end
            if obj.Name == "unx@pltf" or obj.Name == "unx@novoid" then continue end
            if obj.Transparency >= 1 then continue end

            if not self.XRayOriginals[obj] then
                self.XRayOriginals[obj] = obj.Transparency
            end
            obj.Transparency = transparencyVal
        end
    end
end

function CharacterManager:RemoveXRay()
    for part, origTransparency in pairs(self.XRayOriginals) do
        if part and part.Parent then
            part.Transparency = origTransparency
        end
    end
    self.XRayOriginals = {}
end

function CharacterManager:UpdateLoop()
    local char = self.LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")

    if Toggles.LockWalkSpeed and Toggles.LockWalkSpeed.Value and hum then
        local targetWS = tonumber(Options.WalkSpeed.Value) or 16
        if hum.WalkSpeed ~= targetWS then
            hum.WalkSpeed = targetWS
        end
    end

    if Toggles.LockJumpPower and Toggles.LockJumpPower.Value and hum then
        hum.UseJumpPower = true
        local targetJP = tonumber(Options.JumpPower.Value) or 50
        if hum.JumpPower ~= targetJP then
            hum.JumpPower = targetJP
        end
    end

    if Toggles.LockGravity and Toggles.LockGravity.Value then
        local targetG = tonumber(Options.Gravity.Value) or 196.2
        if workspace.Gravity ~= targetG then
            workspace.Gravity = targetG
        end
    end

    if Toggles.LockMaxZoom and Toggles.LockMaxZoom.Value then
        local targetZoom = tonumber(Options.MaxZoom.Value) or 128
        self.LocalPlayer.CameraMaxZoomDistance = targetZoom
        if self.LocalPlayer.CameraMinZoomDistance > targetZoom then
            self.LocalPlayer.CameraMinZoomDistance = targetZoom
        end
    end

    if Toggles.ForceThirdPerson and Toggles.ForceThirdPerson.Value then
        self.LocalPlayer.CameraMode = Enum.CameraMode.Classic
        self.LocalPlayer.CameraMinZoomDistance = 5
    end

    if Toggles.CounterVoid and Toggles.CounterVoid.Value and root then
        local voidHeight = workspace.FallenPartsDestroyHeight + 5
        local p = workspace:FindFirstChild("unx@novoid")
        if not p then
            p = Instance.new("Part")
            p.Name = "unx@novoid"
            p.Anchored = true
            p.CanCollide = true
            p.Transparency = 1
            p.Size = Vector3.new(10, 1, 10)
            p.Parent = workspace
        end
        p.CFrame = CFrame.new(root.Position.X, voidHeight, root.Position.Z)
    else
        local p = workspace:FindFirstChild("unx@novoid")
        if p then p:Destroy() end
    end

    if Toggles.CounterFling and Toggles.CounterFling.Value and root then
        if root.AssemblyAngularVelocity.Magnitude > 50 or root.AssemblyLinearVelocity.Magnitude > 500 then
            root.AssemblyAngularVelocity = Vector3.new(0,0,0)
            root.AssemblyLinearVelocity = Vector3.new(0,0,0)
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= self.LocalPlayer and p.Character then
                for _, part in pairs(p.Character:GetChildren()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end
    end

    if Toggles.Platform and Toggles.Platform.Value and root and hum then
        local p = workspace:FindFirstChild("unx@pltf")
        if not p then
            p = Instance.new("Part")
            p.Name = "unx@pltf"
            p.Anchored = true
            p.CanCollide = true
            p.Transparency = 0.5
            p.Parent = workspace
        end
        local px = tonumber(Options.PlatformSizeX.Value) or 5
        local pz = tonumber(Options.PlatformSizeZ.Value) or 5
        p.Size = Vector3.new(px, 1, pz)
        local surfaceY = root.Position.Y - hum.HipHeight - (root.Size.Y / 2)
        p.CFrame = CFrame.new(root.Position.X, surfaceY - 0.5, root.Position.Z)
    else
        local p = workspace:FindFirstChild("unx@pltf")
        if p then p:Destroy() end
    end
end

local FlyManager = {}
FlyManager.__index = FlyManager

function FlyManager.new()
    return setmetatable({
        FlyMaid = Maid.new(),
        VFlyMaid = Maid.new(),
        CFlyMaid = Maid.new(),
        FlyActive = false,
        VFlyActive = false,
        CFlyActive = false
    }, FlyManager)
end

function FlyManager:StartFly()
    if self.FlyActive then return end
    self.FlyActive = true
    self.FlyMaid = Maid.new()

    local player = Players.LocalPlayer
    local camera = Workspace.CurrentCamera

    local function enableFly()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        hum.PlatformStand = true
        self.FlyMaid:GiveTask(function() if hum then hum.PlatformStand = false end end)

        local attachment = Instance.new("Attachment")
        attachment.Name = "FlyAttachment"
        attachment.Parent = root
        self.FlyMaid:GiveTask(attachment)

        local linearVelocity = Instance.new("LinearVelocity")
        linearVelocity.Attachment0 = attachment
        linearVelocity.MaxForce = math.huge
        linearVelocity.VectorVelocity = Vector3.zero
        linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
        linearVelocity.Parent = root
        self.FlyMaid:GiveTask(linearVelocity)

        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
        bodyGyro.P = 10000
        bodyGyro.D = 500
        bodyGyro.Parent = root
        self.FlyMaid:GiveTask(bodyGyro)

        local controlModule
        local success, err = pcall(function()
            controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule", 5):WaitForChild("ControlModule", 5))
        end)

        if not success or not controlModule then return end

        self.FlyMaid:GiveTask(RunService.Heartbeat:Connect(function()
            if not hum or not root or not linearVelocity.Parent or not bodyGyro.Parent then return end

            local speed = tonumber(Options.FlySpeed.Value) or 20
            local moveVector = controlModule:GetMoveVector()
            local dir = camera.CFrame:VectorToWorldSpace(moveVector)

            linearVelocity.VectorVelocity = dir * (speed * 10)
            bodyGyro.CFrame = camera.CFrame
        end))
    end

    enableFly()
    self.FlyMaid:GiveTask(player.CharacterAdded:Connect(function()
        task.wait(0.5)
        enableFly()
    end))
end

function FlyManager:StopFly()
    self.FlyActive = false
    self.FlyMaid:DoCleaning()
end

function FlyManager:StartVFly()
    if self.VFlyActive then return end
    self.VFlyActive = true
    self.VFlyMaid = Maid.new()

    local player = Players.LocalPlayer
    local camera = Workspace.CurrentCamera

    local function enableVFly()
        local char = player.Character
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 10)
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        local target = root
        if hum.SeatPart then target = hum.SeatPart end

        local attachment = Instance.new("Attachment")
        attachment.Name = "VFlyAttachment"
        attachment.Parent = target
        self.VFlyMaid:GiveTask(attachment)

        local bv = Instance.new("LinearVelocity")
        bv.Name = "VFlyVelocity"
        bv.Attachment0 = attachment
        bv.MaxForce = math.huge
        bv.VectorVelocity = Vector3.zero
        bv.RelativeTo = Enum.ActuatorRelativeTo.World
        bv.Parent = target
        self.VFlyMaid:GiveTask(bv)

        local bg = Instance.new("BodyGyro")
        bg.Name = "VFlyGyro"
        bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        bg.P = 3000
        bg.D = 100
        bg.CFrame = target.CFrame
        bg.Parent = target
        self.VFlyMaid:GiveTask(bg)

        local controlModule
        local success, err = pcall(function()
            controlModule = require(player.PlayerScripts:WaitForChild("PlayerModule", 5):WaitForChild("ControlModule", 5))
        end)
        if not success or not controlModule then return end

        self.VFlyMaid:GiveTask(RunService.RenderStepped:Connect(function()
            if not target or not target.Parent or not bv.Parent or not bg.Parent then
                return
            end

            bg.CFrame = camera.CFrame
            local speed = tonumber(Options.VFlySpeed.Value) or 100
            local moveVector = controlModule:GetMoveVector()

            if moveVector.Magnitude > 0.1 then
                local direction = (camera.CFrame.LookVector * -moveVector.Z) + (camera.CFrame.RightVector * moveVector.X)
                bv.VectorVelocity = direction.Unit * speed
            else
                bv.VectorVelocity = Vector3.zero
            end
        end))
    end

    enableVFly()
    self.VFlyMaid:GiveTask(player.CharacterAdded:Connect(function()
        task.wait(0.5)
        enableVFly()
    end))
end

function FlyManager:StopVFly()
    self.VFlyActive = false
    self.VFlyMaid:DoCleaning()
end

function FlyManager:StartCFly()
    if self.CFlyActive then return end
    self.CFlyActive = true
    self.CFlyMaid = Maid.new()

    local player = Players.LocalPlayer
    local camera = Workspace.CurrentCamera

    local function enableCFly()
        local char = player.Character
        if not char then return end
        local hum = char:WaitForChild("Humanoid", 10)
        local head = char:WaitForChild("Head", 10)
        if not hum or not head then return end

        hum.PlatformStand = true
        self.CFlyMaid:GiveTask(function() if hum then hum.PlatformStand = false end end)

        head.Anchored = true
        self.CFlyMaid:GiveTask(function() if head then head.Anchored = false end end)

        self.CFlyMaid:GiveTask(RunService.Heartbeat:Connect(function(deltaTime)
            if not hum or not head then return end

            local speed = tonumber(Options.CFlySpeed.Value) or 50
            local moveDirection = hum.MoveDirection * (speed * deltaTime)
            local headCFrame = head.CFrame
            local cameraCFrame = camera.CFrame
            local cameraOffset = headCFrame:ToObjectSpace(cameraCFrame).Position
            cameraCFrame = cameraCFrame * CFrame.new(-cameraOffset.X, -cameraOffset.Y, -cameraOffset.Z + 1)
            local cameraPosition = cameraCFrame.Position
            local headPosition = headCFrame.Position

            local objectSpaceVelocity = CFrame.new(cameraPosition, Vector3.new(headPosition.X, cameraPosition.Y, headPosition.Z)):VectorToObjectSpace(moveDirection)
            head.CFrame = CFrame.new(headPosition) * (cameraCFrame - cameraPosition) * CFrame.new(objectSpaceVelocity)
        end))
    end

    enableCFly()
    self.CFlyMaid:GiveTask(player.CharacterAdded:Connect(function()
        task.wait(0.5)
        enableCFly()
    end))
end

function FlyManager:StopCFly()
    self.CFlyActive = false
    self.CFlyMaid:DoCleaning()
end

local ESPManager = {}
ESPManager.__index = ESPManager

function ESPManager.new()
    local self = setmetatable({
        Maid = Maid.new(),
        Cache = {},
        Players = Players,
        Camera = Workspace.CurrentCamera
    }, ESPManager)

    local success, parent = pcall(function() return CoreGui end)
    self.Container = Instance.new("Folder")
    self.Container.Name = "UNX_ESP_Container"
    self.Container.Parent = success and parent or Players.LocalPlayer:WaitForChild("PlayerGui")
    self.Maid:GiveTask(self.Container)

    return self
end

function ESPManager:AddPlayer(plr)
    if plr == self.Players.LocalPlayer then return end
    if self.Cache[plr] then return end

    local cache = {}

    local hl = Instance.new("Highlight")
    hl.Enabled = false
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = self.Container
    cache.Highlight = hl

    local bg = Instance.new("BillboardGui")
    bg.AlwaysOnTop = true
    bg.Enabled = false
    bg.Size = UDim2.new(0, 200, 0, 50)
    bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.Parent = self.Container

    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.Font = Enum.Font.BuilderSans
    tl.TextSize = 16
    tl.TextStrokeTransparency = 0
    tl.Parent = bg

    local strk = Instance.new("UIStroke")
    strk.Thickness = 1.2
    strk.Color = Color3.fromRGB(0, 0, 0)
    strk.Parent = tl

    cache.Billboard = bg
    cache.Text = tl
    cache.Stroke = strk

    if Drawing then
        local tr = Drawing.new("Line")
        tr.Visible = false
        tr.Thickness = 1
        cache.Tracer = tr
    end

    self.Cache[plr] = cache

    local function updateAdornees(char)
        hl.Adornee = char
        bg.Adornee = char:WaitForChild("Head", 5) or char:WaitForChild("HumanoidRootPart", 5)
    end

    if plr.Character then task.spawn(updateAdornees, plr.Character) end
    self.Maid:GiveTask(plr.CharacterAdded:Connect(updateAdornees))
end

function ESPManager:RemovePlayer(plr)
    local cache = self.Cache[plr]
    if cache then
        if cache.Highlight then cache.Highlight:Destroy() end
        if cache.Billboard then cache.Billboard:Destroy() end
        if cache.Tracer then cache.Tracer:Remove() end
        self.Cache[plr] = nil
    end
end

function ESPManager:Init()
    for _, p in pairs(self.Players:GetPlayers()) do
        self:AddPlayer(p)
    end

    self.Maid:GiveTask(self.Players.PlayerAdded:Connect(function(p)
        self:AddPlayer(p)
    end))

    self.Maid:GiveTask(self.Players.PlayerRemoving:Connect(function(p)
        self:RemovePlayer(p)
    end))

    self.Maid:GiveTask(RunService.RenderStepped:Connect(function()
        self:Update()
    end))
end

local function isPlayerAllowed(plr, teamOption, playerOption)
    local teamFilterHasSelections = false
    if teamOption and teamOption.Value then
        for _, v in pairs(teamOption.Value) do
            if v then teamFilterHasSelections = true break end
        end
    end

    local playerFilterHasSelections = false
    if playerOption and playerOption.Value then
        for _, v in pairs(playerOption.Value) do
            if v then playerFilterHasSelections = true break end
        end
    end

    if not teamFilterHasSelections and not playerFilterHasSelections then
        return true
    end

    if playerFilterHasSelections and playerOption.Value and playerOption.Value[plr.Name] then
        return true
    end

    if teamFilterHasSelections and teamOption.Value and plr.Team and teamOption.Value[plr.Team.Name] then
        return true
    end

    return false
end

function ESPManager:Update()
    local lp = self.Players.LocalPlayer
    local lpChar = lp.Character
    local lpRoot = lpChar and lpChar:FindFirstChild("HumanoidRootPart")

    for plr, cache in pairs(self.Cache) do
        local char = plr.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")
        local head = char and char:FindFirstChild("Head") or root

        if not char or not root or not hum or hum.Health <= 0 then
            if cache.Highlight then cache.Highlight.Enabled = false end
            if cache.Billboard then cache.Billboard.Enabled = false end
            if cache.Tracer then cache.Tracer.Visible = false end
            continue
        end

        local screenPos, onScreen = self.Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2, 0))

        if Toggles.ESP and Toggles.ESP.Value and cache.Billboard and onScreen and isPlayerAllowed(plr, Options.ESPTeamOnly, Options.ESPPlayersOnly) then
            cache.Billboard.Enabled = true

            local c = Options.ESPColor.Value
            if Toggles.ESPColorFromTeam and Toggles.ESPColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
            if Toggles.RainbowESP and Toggles.RainbowESP.Value then
                local speed = Options.RainbowSpeed and Options.RainbowSpeed.Value or 5
                c = Color3.fromHSV(tick() * (speed / 50) % 1, 1, 1)
            end

            cache.Text.TextColor3 = c
            cache.Text.TextSize = Options.ESPSize and Options.ESPSize.Value or 16

            if Options.ESPFont and Options.ESPFont.Value then
                cache.Text.Font = Enum.Font[Options.ESPFont.Value] or Enum.Font.BuilderSans
            end

            if cache.Stroke then
                if Toggles.RainbowESP and Toggles.RainbowESP.Value then
                    local speed = Options.RainbowSpeed and Options.RainbowSpeed.Value or 5
                    cache.Stroke.Color = Color3.fromHSV(tick() * (speed / 50) % 1, 1, 0.5)
                else
                    cache.Stroke.Color = Color3.fromRGB(0, 0, 0)
                end
            end

            local dist = 0
            if lpRoot then
                dist = (lpRoot.Position - root.Position).Magnitude
            elseif self.Camera then
                dist = (self.Camera.CFrame.Position - root.Position).Magnitude
            end

            local txt = ""
            if Toggles.ShowPlayerName and Toggles.ShowPlayerName.Value then txt = txt .. plr.Name end
            if Toggles.ShowDistance and Toggles.ShowDistance.Value then txt = txt .. (txt ~= "" and " " or "") .. string.format("[%d]", math.floor(dist)) end
            if Toggles.ShowHealth and Toggles.ShowHealth.Value then txt = txt .. (txt ~= "" and " " or "") .. string.format("[%dHP]", math.floor(hum.Health)) end

            if cache.Text.Text ~= txt then cache.Text.Text = txt end
        else
            if cache.Billboard then cache.Billboard.Enabled = false end
        end

        if cache.Highlight then
            if onScreen and Toggles.Outline and Toggles.Outline.Value and isPlayerAllowed(plr, Options.OutlineTeamOnly, Options.OutlinePlayersOnly) then
                cache.Highlight.Enabled = true
                local c = Options.OutlineColor.Value
                if Toggles.OutlineColorFromTeam and Toggles.OutlineColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
                if Toggles.RainbowOutline and Toggles.RainbowOutline.Value then
                    local speed = Options.RainbowSpeed and Options.RainbowSpeed.Value or 5
                    c = Color3.fromHSV(tick() * (speed / 50) % 1, 1, 1)
                end

                cache.Highlight.OutlineColor = c
                cache.Highlight.FillColor = c
                cache.Highlight.OutlineTransparency = (Options.OutlineTransparency and Options.OutlineTransparency.Value or 0) / 100
                cache.Highlight.FillTransparency = (Options.OutlineFillTransparency and Options.OutlineFillTransparency.Value or 100) / 100
            else
                cache.Highlight.Enabled = false
            end
        end

        if cache.Tracer then
            if onScreen and Toggles.Tracers and Toggles.Tracers.Value and isPlayerAllowed(plr, Options.TracersTeamOnly, Options.TracersPlayersOnly) then
                cache.Tracer.Visible = true
                local c = Options.TracersColor.Value
                if Toggles.TracersColorFromTeam and Toggles.TracersColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
                if Toggles.RainbowTracers and Toggles.RainbowTracers.Value then
                    local speed = Options.RainbowSpeed and Options.RainbowSpeed.Value or 5
                    c = Color3.fromHSV(tick() * (speed / 50) % 1, 1, 1)
                end

                cache.Tracer.Color = c

                local mousePos = UserInputService:GetMouseLocation()
                local tOrig = Options.TracersPosition and Options.TracersPosition.Value or "Down"

                if tOrig == "Mouse" then
                    cache.Tracer.From = mousePos
                elseif tOrig == "Upper" then
                    cache.Tracer.From = Vector2.new(self.Camera.ViewportSize.X / 2, 0)
                elseif tOrig == "Middle" then
                    cache.Tracer.From = Vector2.new(self.Camera.ViewportSize.X / 2, self.Camera.ViewportSize.Y / 2)
                else
                    cache.Tracer.From = Vector2.new(self.Camera.ViewportSize.X / 2, self.Camera.ViewportSize.Y)
                end

                local headScreenPos = self.Camera:WorldToViewportPoint(head.Position)
                cache.Tracer.To = Vector2.new(headScreenPos.X, headScreenPos.Y)
            else
                cache.Tracer.Visible = false
            end
        end
    end
end

local LightningManager = {}
LightningManager.__index = LightningManager

function LightningManager.new()
    local self = setmetatable({
        Maid = Maid.new(),
        Original = {
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            Brightness = Lighting.Brightness,
            ClockTime = Lighting.ClockTime,
            FogEnd = Lighting.FogEnd,
            FogStart = Lighting.FogStart,
            FogColor = Lighting.FogColor,
            GlobalShadows = Lighting.GlobalShadows
        },
        OriginalAtmos = {}
    }, LightningManager)

    for _, v in pairs(Lighting:GetDescendants()) do
        if v:IsA("Atmosphere") then
            self.OriginalAtmos[v] = v.Density
        end
    end

    return self
end

function LightningManager:Init()
    Scheduler:Every(0.1, function()
        if Toggles.FullBright and Toggles.FullBright.Value then
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255,255,255)
            Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            Lighting.ClockTime = 12
            Lighting.FogEnd = 100000
            Lighting.FogStart = 0
            Lighting.FogColor = Color3.fromRGB(255,255,255)
        end

        if Toggles.NoFog and Toggles.NoFog.Value then
            Lighting.FogEnd = 100000000
            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("Atmosphere") then v.Density = 0 end
            end
        end
    end)

    if Toggles.FullBright then
        Toggles.FullBright:OnChanged(function(v)
            if not v then
                Lighting.Brightness = self.Original.Brightness
                Lighting.Ambient = self.Original.Ambient
                Lighting.OutdoorAmbient = self.Original.OutdoorAmbient
                Lighting.ClockTime = self.Original.ClockTime
                if Toggles.NoFog and not Toggles.NoFog.Value then
                    Lighting.FogEnd = self.Original.FogEnd
                    Lighting.FogStart = self.Original.FogStart
                    Lighting.FogColor = self.Original.FogColor
                end
            end
        end)
    end

    if Toggles.NoFog then
        Toggles.NoFog:OnChanged(function(v)
            if not v then
                if Toggles.FullBright and not Toggles.FullBright.Value then
                    Lighting.FogEnd = self.Original.FogEnd
                end
                for atmos, dens in pairs(self.OriginalAtmos) do
                    if atmos and atmos.Parent then
                        atmos.Density = dens
                    end
                end
            end
        end)
    end
end

local CM = CharacterManager.new()
local FM = FlyManager.new()
local ESPM = ESPManager.new()
local LM = LightningManager.new()

Library.ForceCheckbox = true
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "UNXHub",
    Footer = "Version: " .. tostring(getgenv().unxshared and getgenv().unxshared.version or "Unknown") .. ", Game: " .. tostring(getgenv().unxshared and getgenv().unxshared.gamename or "Unknown") .. ", Player: " .. tostring(getgenv().unxshared and getgenv().unxshared.playername or "Unknown"),
    Icon = 73740010358428,
    NotifySide = "Right",
    ShowCustomCursor = false,
})

local Tabs = {
    Main = Window:AddTab("Main", "house"),
    Visuals = Window:AddTab("Visuals", "eye"),
    Features = Window:AddTab("Features", "bug"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local CharacterMods = Tabs.Main:AddLeftGroupbox("Character Mods", "user")

local function HandleBindButton(tglValue, bindName, optionToggle)
    if not BindModule then return end
    if tglValue then
        BindModule:AddToggleBB(bindName, function()
            optionToggle:SetValue(true)
        end, function()
            optionToggle:SetValue(false)
        end)
    else
        BindModule:DelBindB(bindName)
    end
end

CharacterMods:AddToggle("LockWalkSpeed", {
    Text = "Lock Walkspeed",
    Default = false,
})

CharacterMods:AddToggle("LockWalkSpeedBindButton", {
    Text = "Lock Walkspeed BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Lock Walkspeed", Toggles.LockWalkSpeed)
    end
})

CharacterMods:AddInput("WalkSpeed", {
    Default = "16",
    Numeric = true,
    Finished = false,
    Text = "Walkspeed",
    Placeholder = "16",
})

CharacterMods:AddToggle("LockJumpPower", {
    Text = "Lock Jumppower",
    Default = false,
})

CharacterMods:AddToggle("LockJumpPowerBindButton", {
    Text = "Lock Jumppower BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Lock Jumppower", Toggles.LockJumpPower)
    end
})

CharacterMods:AddInput("JumpPower", {
    Default = "50",
    Numeric = true,
    Finished = false,
    Text = "JumpPower",
    Placeholder = "50",
})

CharacterMods:AddToggle("LockGravity", {
    Text = "Lock Gravity",
    Default = false,
    Callback = function(Value)
        if not Value then
            workspace.Gravity = OriginalGravity
        end
    end
})

CharacterMods:AddToggle("LockGravityBindButton", {
    Text = "Lock Gravity BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Lock Gravity", Toggles.LockGravity)
    end
})

CharacterMods:AddInput("Gravity", {
    Default = "196.2",
    Numeric = true,
    Finished = false,
    Text = "Gravity",
    Placeholder = "196.2",
})

CharacterMods:AddToggle("LockMaxZoom", {
    Text = "Lock MaxZoom",
    Default = false,
})

CharacterMods:AddToggle("LockMaxZoomBindButton", {
    Text = "Lock MaxZoom BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Lock MaxZoom", Toggles.LockMaxZoom)
    end
})

CharacterMods:AddInput("MaxZoom", {
    Default = "128",
    Numeric = true,
    Finished = false,
    Text = "MaxZoom",
    Placeholder = "128",
})

CharacterMods:AddDivider()

CharacterMods:AddToggle("InfiniteJump", {
    Text = "Infinite Jump",
    Default = false,
})

CharacterMods:AddToggle("InfiniteJumpBindButton", {
    Text = "Infinite Jump BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Infinite Jump", Toggles.InfiniteJump)
    end
})

CharacterMods:AddToggle("Noclip", {
    Text = "Noclip",
    Default = false,
}):AddKeyPicker("NoclipKeybind", {
    Default = "N",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Noclip"
})

CharacterMods:AddToggle("NoclipBindButton", {
    Text = "Noclip BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Noclip", Toggles.Noclip)
    end
})

CharacterMods:AddToggle("ForceThirdPerson", {
    Text = "Force Third Person",
    Default = false,
})

CharacterMods:AddToggle("ForceThirdPersonBindButton", {
    Text = "Force Third Person BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Force Third Person", Toggles.ForceThirdPerson)
    end
})

CharacterMods:AddDivider()

CharacterMods:AddToggle("CounterFling", {
    Text = "Counter Fling",
    Default = false,
})

CharacterMods:AddToggle("CounterVoid", {
    Text = "Counter Void",
    Default = false,
})

CharacterMods:AddToggle("NoAFKKick", {
    Text = "No AFK Kick",
    Default = false,
})

CharacterMods:AddDivider()

CharacterMods:AddToggle("XRay", {
    Text = "X-Ray",
    Default = false,
    Callback = function(Value)
        if Value then
            CM:ApplyXRay()
        else
            CM:RemoveXRay()
        end
    end
})

CharacterMods:AddToggle("XRayBindButton", {
    Text = "X-Ray BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "X-Ray", Toggles.XRay)
    end
})

CharacterMods:AddSlider("XRayTransparency", {
    Text = "X-Ray Transparency",
    Default = 50,
    Min = 0,
    Max = 100,
    Suffix = "%",
    Rounding = 0,
    Compact = false,
    Callback = function()
        if Toggles.XRay and Toggles.XRay.Value then
            CM:ApplyXRay()
        end
    end
})

local FlySection = Tabs.Main:AddLeftGroupbox("Fly", "plane")

FlySection:AddToggle("Fly", {
    Text = "Fly",
    Default = false,
    Callback = function(Value)
        if Value then
            if Toggles.VFly and Toggles.VFly.Value then Toggles.VFly:SetValue(false) end
            if Toggles.CFly and Toggles.CFly.Value then Toggles.CFly:SetValue(false) end
            FM:StartFly()
        else
            FM:StopFly()
        end
    end
}):AddKeyPicker("FlyKeybind", {
    Default = "F",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Fly"
})

FlySection:AddToggle("FlyBindButton", {
    Text = "Fly BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Fly", Toggles.Fly)
    end
})

FlySection:AddInput("FlySpeed", {
    Default = "20",
    Numeric = true,
    Finished = false,
    Text = "Fly Speed",
    Placeholder = "20",
})

local VFlySection = Tabs.Main:AddLeftGroupbox("VFly", "plane")

VFlySection:AddToggle("VFly", {
    Text = "VFly",
    Default = false,
    Callback = function(Value)
        if Value then
            if Toggles.Fly and Toggles.Fly.Value then Toggles.Fly:SetValue(false) end
            if Toggles.CFly and Toggles.CFly.Value then Toggles.CFly:SetValue(false) end
            FM:StartVFly()
        else
            FM:StopVFly()
        end
    end
}):AddKeyPicker("VFlyKeybind", {
    Default = "V",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "VFly"
})

VFlySection:AddToggle("VFlyBindButton", {
    Text = "VFly BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "VFly", Toggles.VFly)
    end
})

VFlySection:AddInput("VFlySpeed", {
    Default = "100",
    Numeric = true,
    Finished = false,
    Text = "VFly Speed",
    Placeholder = "100",
})

local CFlySection = Tabs.Main:AddLeftGroupbox("CFly", "plane")

CFlySection:AddToggle("CFly", {
    Text = "CFly",
    Default = false,
    Callback = function(Value)
        if Value then
            if Toggles.Fly and Toggles.Fly.Value then Toggles.Fly:SetValue(false) end
            if Toggles.VFly and Toggles.VFly.Value then Toggles.VFly:SetValue(false) end
            FM:StartCFly()
        else
            FM:StopCFly()
        end
    end
}):AddKeyPicker("CFlyKeybind", {
    Default = "C",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "CFly"
})

CFlySection:AddToggle("CFlyBindButton", {
    Text = "CFly BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "CFly", Toggles.CFly)
    end
})

CFlySection:AddInput("CFlySpeed", {
    Default = "50",
    Numeric = true,
    Finished = false,
    Text = "CFly Speed",
    Placeholder = "50",
})

local CharFeatures = Tabs.Main:AddRightGroupbox("Character Features", "chevrons-left-right-ellipsis")

CharFeatures:AddToggle("Platform", {
    Text = "Platform",
    Default = false,
}):AddKeyPicker("PlatformKeybind", {
    Default = "P",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Platform"
})

CharFeatures:AddToggle("PlatformBindButton", {
    Text = "Platform BindButton",
    Default = false,
    Callback = function(Value)
        HandleBindButton(Value, "Platform", Toggles.Platform)
    end
})

CharFeatures:AddSlider("PlatformSizeX", {
    Text = "Platform Size (X)",
    Default = 5,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Compact = false,
})

CharFeatures:AddSlider("PlatformSizeZ", {
    Text = "Platform Size (Z)",
    Default = 5,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Compact = false,
})

CharFeatures:AddDivider()

CharFeatures:AddToggle("Swim", {
    Text = "Swim",
    Default = false,
    Callback = function(Value)
        if Value then
            CM:StartSwim()
        else
            CM:StopSwim()
        end
    end
}):AddKeyPicker("SwimKeybind", {
    Default = "G",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Swim"
})

CharFeatures:AddSlider("SwimSpeed", {
    Text = "Swim Speed",
    Default = 16,
    Min = 1,
    Max = 150,
    Rounding = 0,
    Compact = false,
})

CharFeatures:AddToggle("ClickToTP", {
    Text = "Click To TP",
    Default = false,
    Callback = function(Value)
        CM:HandleClickToTP(Value)
    end
}):AddKeyPicker("ClickToTPKeybind", {
    Default = "T",
    SyncToggleState = true,
    Mode = "Toggle",
    Text = "Click To TP"
})

CharFeatures:AddDropdown("ClickToTPMethod", {
    Text = "Click To TP Method",
    Values = {"Always On", "Tool"},
    Default = "Always On",
    Callback = function()
        if Toggles.ClickToTP and Toggles.ClickToTP.Value then
            CM:HandleClickToTP(false)
            CM:HandleClickToTP(true)
        end
    end
})

local OthersSection = Tabs.Main:AddRightGroupbox("Others", "ellipsis")

OthersSection:AddButton("Reset Character", function()
    local char = CM.LocalPlayer.Character
    if char then char:BreakJoints() end
end)

OthersSection:AddButton("Damage Character", function()
    local char = CM.LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:TakeDamage(tonumber(Options.DamageAmount.Value) or 10)
    end
end)

OthersSection:AddInput("DamageAmount", {
    Default = "10",
    Numeric = true,
    Finished = false,
    Text = "Damage",
    Placeholder = "10",
})

OthersSection:AddDivider()

OthersSection:AddButton("Reset Walkspeed", function()
    local char = CM.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = CM.OriginalWalkSpeed
            if Options.WalkSpeed then Options.WalkSpeed:SetValue(tostring(CM.OriginalWalkSpeed)) end
        end
    end
end)

OthersSection:AddButton("Reset Jumppower", function()
    local char = CM.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpPower = CM.OriginalJumpPower
            if Options.JumpPower then Options.JumpPower:SetValue(tostring(CM.OriginalJumpPower)) end
        end
    end
end)

OthersSection:AddButton("Reset Gravity", function()
    workspace.Gravity = OriginalGravity
    if Options.Gravity then Options.Gravity:SetValue(tostring(OriginalGravity)) end
end)

OthersSection:AddButton("Reset MaxZoom", function()
    CM.LocalPlayer.CameraMaxZoomDistance = CM.OriginalMaxZoom
    if Options.MaxZoom then Options.MaxZoom:SetValue(tostring(CM.OriginalMaxZoom)) end
end)

local VisualsTabbox = Tabs.Visuals:AddLeftTabbox()
local EspTab = VisualsTabbox:AddTab("ESPs")
local ConfigTab = VisualsTabbox:AddTab("Configurations")

EspTab:AddToggle("ESP", {Text="ESP", Default=false}):AddColorPicker("ESPColor", {Default=Color3.new(1,1,1), Title="ESP Color"})
EspTab:AddToggle("Outline", {Text="Outline", Default=false}):AddColorPicker("OutlineColor", {Default=Color3.new(1,1,1), Title="Outline Color"})
EspTab:AddToggle("Tracers", {Text="Tracers", Default=false}):AddColorPicker("TracersColor", {Default=Color3.new(1,1,1), Title="Tracers Color"})

EspTab:AddDivider()

EspTab:AddDropdown("ESPTeamOnly", { Values = getTeamList(), Multi = true, Text = "ESP Team Only", Searchable = true })
EspTab:AddDropdown("OutlineTeamOnly", { Values = getTeamList(), Multi = true, Text = "Outline Team Only", Searchable = true })
EspTab:AddDropdown("TracersTeamOnly", { Values = getTeamList(), Multi = true, Text = "Tracers Team Only", Searchable = true })

EspTab:AddDivider()

EspTab:AddDropdown("ESPPlayersOnly", { SpecialType = "Player", ExcludeLocalPlayer = true, Multi = true, Text = "ESP Players Only", Searchable = true })
EspTab:AddDropdown("OutlinePlayersOnly", { SpecialType = "Player", ExcludeLocalPlayer = true, Multi = true, Text = "Outline Players Only", Searchable = true })
EspTab:AddDropdown("TracersPlayersOnly", { SpecialType = "Player", ExcludeLocalPlayer = true, Multi = true, Text = "Tracers Players Only", Searchable = true })

ConfigTab:AddToggle("RainbowESP", {Text="Rainbow ESP", Default=false})
ConfigTab:AddToggle("RainbowOutline", {Text="Rainbow Outline", Default=false})
ConfigTab:AddToggle("RainbowTracers", {Text="Rainbow Tracers", Default=false})
ConfigTab:AddSlider("RainbowSpeed", {Text="Rainbow Speed", Min=0, Max=10, Default=5, Rounding=1})

ConfigTab:AddDivider()

ConfigTab:AddSlider("ESPSize", {Text="ESP Size", Min=10, Max=30, Default=16, Rounding=0})
ConfigTab:AddDropdown("ESPFont", { Text="ESP Font", Values={"BuilderSans","SourceSans","SourceSansBold","Roboto","Arcade","Gotham","GothamBold","Oswald","Code","SciFi","Bodoni","AmaticSC"}, Default=1 })

ConfigTab:AddToggle("ShowDistance", {Text="Show Distance", Default=true})
ConfigTab:AddToggle("ShowPlayerName", {Text="Show Player Name", Default=true})
ConfigTab:AddToggle("ShowHealth", {Text="Show Health", Default=true})

ConfigTab:AddDivider()

ConfigTab:AddSlider("OutlineFillTransparency", {Text="Outline Fill Transparency (%)", Min=0, Max=100, Default=100, Suffix="%", Rounding=0})
ConfigTab:AddSlider("OutlineTransparency", {Text="Outline Transparency (%)", Min=0, Max=100, Default=0, Suffix="%", Rounding=0})
ConfigTab:AddDropdown("TracersPosition", {Text="Tracers Position", Values={"Mouse","Upper","Middle","Down"}, Default="Down"})

ConfigTab:AddDivider()

ConfigTab:AddToggle("ESPColorFromTeam", {Text="ESP Color From Team", Default=false})
ConfigTab:AddToggle("OutlineColorFromTeam", {Text="Outline Color From Team", Default=false})
ConfigTab:AddToggle("TracersColorFromTeam", {Text="Tracers Color From Team", Default=false})

local LightningSection = Tabs.Visuals:AddRightGroupbox("Lightning", "lightbulb")

LightningSection:AddToggle("FullBright", {Text="Full Bright", Default=false})
LightningSection:AddToggle("NoFog", {Text="No Fog", Default=false})

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = false,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = { "Left", "Right" },
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end,
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("unxhub")
SaveManager:SetFolder("unxhub/universal")

SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()
CM:Init()
ESPM:Init()
LM:Init()
if BindModule then
    BindModule:SetSizeB(1)
    BindModule:ResetPos()
end

task.spawn(function()
    while task.wait(5) do
        if Options.ESPTeamOnly then Options.ESPTeamOnly:SetValues(getTeamList()) end
        if Options.OutlineTeamOnly then Options.OutlineTeamOnly:SetValues(getTeamList()) end
        if Options.TracersTeamOnly then Options.TracersTeamOnly:SetValues(getTeamList()) end
        if Options.ESPPlayersOnly then Options.ESPPlayersOnly:SetValues(getPlayerList()) end
        if Options.OutlinePlayersOnly then Options.OutlinePlayersOnly:SetValues(getPlayerList()) end
        if Options.TracersPlayersOnly then Options.TracersPlayersOnly:SetValues(getPlayerList()) end
    end
end)
