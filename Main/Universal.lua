--[[
UNXHUB BETA, THIS MAY FAIL OR BREAK THE GAME, USE ON YOUR OWN RISK!

\ = Good Points
/ = Bad Points

\ This has better logic
\ This is more stable
\ Better code & stuff
/ This still doesnt have aimlock
/ This is still on beta
/ This still doesnt have all features.
]]

loadstring(game:HttpGet("https://github.com/not-gato/UNX/raw/refs/heads/main/Modules/v2/Log.lua",true))()

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local TeleportService = game:GetService("TeleportService")
local TextChatService = game:GetService("TextChatService")

Library.ForceCheckbox = true
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
    Title = "UNXHub",
    Footer = "Beta UNXHub | This Will Change On The Future.",
    Icon = 123333102279908,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
	Main = Window:AddTab("Main", "home"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Features = Window:AddTab("Features", "zap"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local defaultWalkSpeed = 16
local defaultJumpPower = 50
local defaultMaxZoom = 400
local defaultGravity = 196.2
local xrayTransparency = 0.8
local defaultFieldOfView = camera.FieldOfView

local character, humanoid, rootpart

local function getCharacter()
	character = player.Character or player.CharacterAdded:Wait()
	humanoid = character:WaitForChild("Humanoid", 5)
	rootpart = character:WaitForChild("HumanoidRootPart", 5)
	defaultWalkSpeed = humanoid.WalkSpeed
	defaultJumpPower = humanoid.JumpPower
	defaultMaxZoom = player.CameraMaxZoomDistance
	defaultGravity = Workspace.Gravity
end

getCharacter()
player.CharacterAdded:Connect(getCharacter)

local FlyGroupBox = Tabs.Main:AddRightGroupbox("Fly", "plane")

local flySpeed = 5
local flying = false
local bodyVelocity, bodyGyro, flyConnection

local function startFlying()
	if not humanoid or not rootpart then return end
	humanoid.PlatformStand = true
	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(1e6,1e6,1e6)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = rootpart
	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e6,1e6,1e6)
	bodyGyro.P = 10000
	bodyGyro.D = 500
	bodyGyro.Parent = rootpart
	flyConnection = RunService.Heartbeat:Connect(function()
		if not humanoid or not rootpart then return end
		local cm = require(player.PlayerScripts:WaitForChild("PlayerModule",5):WaitForChild("ControlModule",5))
		if not cm then return end
		local mv = cm:GetMoveVector()
		local dir = camera.CFrame:VectorToWorldSpace(mv)
		bodyVelocity.Velocity = dir * (flySpeed*10)
		bodyGyro.CFrame = camera.CFrame
	end)
end

local function stopFlying()
	if humanoid then humanoid.PlatformStand = false end
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	if flyConnection then flyConnection:Disconnect() end
	bodyVelocity, bodyGyro, flyConnection = nil,nil,nil
end

FlyGroupBox:AddToggle("Fly", {Text="Fly", Default=false, Callback=function(v)
	flying = v
	if v then startFlying() else stopFlying() end
end}):AddKeyPicker("FlyKeybind", {Default="F", Mode="Toggle", Text="Fly", SyncToggleState=true})

FlyGroupBox:AddSlider("FlySpeed", {Text="Fly Speed", Default=5, Min=1, Max=75, Rounding=0, Callback=function(v) flySpeed = v end})

player.CharacterAdded:Connect(function(c)
	character = c
	humanoid = c:WaitForChild("Humanoid")
	rootpart = c:WaitForChild("HumanoidRootPart")
	if flying then startFlying() end
end)

local LeftMain = Tabs.Main:AddLeftGroupbox("Character", "user")

LeftMain:AddSlider("Walkspeed", {Text="Walkspeed", Default=defaultWalkSpeed, Min=1, Max=500, Rounding=0})
LeftMain:AddSlider("Jumppower", {Text="Jumppower", Default=defaultJumpPower, Min=1, Max=1000, Rounding=0})
LeftMain:AddSlider("MaxZoom", {Text="Max Zoom", Default=defaultMaxZoom, Min=1, Max=1000, Rounding=0})
LeftMain:AddSlider("Gravity", {Text="Gravity", Default=defaultGravity, Min=0, Max=500, Rounding=1})

LeftMain:AddDivider()

LeftMain:AddToggle("InfiniteJump", {Text="Infinite Jump", Default=false})
	:AddKeyPicker("InfiniteJumpKeybind", {Default="I", Mode="Toggle", Text="Infinite Jump", SyncToggleState=true})

LeftMain:AddToggle("Noclip", {Text="Noclip", Default=false})
	:AddKeyPicker("NoclipKeybind", {Default="N", Mode="Toggle", Text="Noclip", SyncToggleState=true})

LeftMain:AddToggle("ForceThirdPerson", {Text="Force Third Person", Default=false})

LeftMain:AddDivider()

LeftMain:AddToggle("XRay", {Text="X-Ray", Default=false, Callback=function(v)
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("BasePart") and obj.Parent ~= character then
			obj.Transparency = v and xrayTransparency or 0
		end
	end
end})

LeftMain:AddSlider("XRayTransparency", {Text="X-Ray Transparency (%)", Default=80, Min=0, Max=100, Rounding=0, Suffix="%", Callback=function(v)
	xrayTransparency = v/100
	if Toggles.XRay.Value then Toggles.XRay:Callback(true) end
end})

local RightMain = Tabs.Main:AddRightGroupbox("Misc", "box")

RightMain:AddButton({Text="Reset Walk Speed", Func=function() Options.Walkspeed:SetValue(defaultWalkSpeed) end})
RightMain:AddButton({Text="Reset Jump Power", Func=function() Options.Jumppower:SetValue(defaultJumpPower) end})
RightMain:AddButton({Text="Reset Max Zoom", Func=function() Options.MaxZoom:SetValue(defaultMaxZoom) end})
RightMain:AddButton({Text="Reset Gravity", Func=function() Options.Gravity:SetValue(defaultGravity) end})

local ESPTabBox = Tabs.Visuals:AddLeftTabbox()
local ESPTab = ESPTabBox:AddTab("ESP")
local ESPConfigTab = ESPTabBox:AddTab("Config")
local GameVisuals = Tabs.Visuals:AddRightGroupbox("Game", "camera")

local espColor = Color3.new(1,1,1)
local outlineColor = Color3.new(1,1,1)
local tracersColor = Color3.new(1,1,1)
local outlineFillTransparency = 1
local outlineTransparency = 0
local espSize = 16
local espFont = 1
local showDistance = true
local showPlayerName = true
local rainbowSpeed = 5
local tracerOrigin = "Down"

local highlights = {}
local drawings = {}

local function addPlayer(plr)
	if plr == player then return end
	local function onChar(c)
		if drawings[plr] then drawings[plr].espText:Remove() drawings[plr].tracer:Remove() drawings[plr] = nil end
		if highlights[plr] then highlights[plr]:Destroy() highlights[plr] = nil end
		local hl = Instance.new("Highlight")
		hl.Adornee = c
		hl.Parent = c
		hl.Enabled = false
		highlights[plr] = hl
		local t = Drawing.new("Text")
		t.Visible = false t.Center = true t.Outline = true t.Font = espFont t.Size = espSize t.Color = espColor
		local l = Drawing.new("Line")
		l.Visible = false l.Color = tracersColor l.Thickness = 1
		drawings[plr] = {espText=t, tracer=l}
	end
	if plr.Character then onChar(plr.Character) end
	plr.CharacterAdded:Connect(onChar)
end

for _,p in Players:GetPlayers() do addPlayer(p) end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(function(plr)
	if highlights[plr] then highlights[plr]:Destroy() highlights[plr] = nil end
	if drawings[plr] then drawings[plr].espText:Remove() drawings[plr].tracer:Remove() drawings[plr] = nil end
end)

local mousePos = Vector2.new()
UserInputService.InputChanged:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseMovement then mousePos = Vector2.new(i.Position.X,i.Position.Y) end
end)

RunService.RenderStepped:Connect(function()
	for plr, hl in pairs(highlights) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		if not char or not hrp or not hum or hum.Health <= 0 then
			hl.Enabled = false
			if drawings[plr] then drawings[plr].espText.Visible = false drawings[plr].tracer.Visible = false end
			continue
		end
		local head = char:FindFirstChild("Head") or hrp
		local headPos = head.Position + Vector3.new(0,2,0)
		local pos3d, onScreen = camera:WorldToViewportPoint(headPos)
		local pos = Vector2.new(pos3d.X, pos3d.Y)
		if not onScreen then
			hl.Enabled = false
			if drawings[plr] then drawings[plr].espText.Visible = false drawings[plr].tracer.Visible = false end
			continue
		end
		if Toggles.Outline and Toggles.Outline.Value then
			hl.Enabled = true
			local c = outlineColor
			if Toggles.OutlineColorFromTeam and Toggles.OutlineColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
			if Toggles.RainbowOutline and Toggles.RainbowOutline.Value then c = Color3.fromHSV(tick()*(rainbowSpeed/50)%1,1,1) end
			hl.OutlineColor = c hl.FillColor = c hl.OutlineTransparency = outlineTransparency hl.FillTransparency = outlineFillTransparency
		else
			hl.Enabled = false
		end
		if Toggles.ESP and Toggles.ESP.Value and drawings[plr] then
			local d = drawings[plr].espText
			d.Visible = true
			local c = espColor
			if Toggles.ESPColorFromTeam and Toggles.ESPColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
			if Toggles.RainbowESP and Toggles.RainbowESP.Value then c = Color3.fromHSV(tick()*(rainbowSpeed/50)%1,1,1) end
			d.Color = c d.Size = espSize d.Font = espFont d.Position = pos
			local txt = showPlayerName and plr.Name or ""
			if showDistance and rootpart then
				local dist = (rootpart.Position - hrp.Position).Magnitude
				txt = txt .. (txt~="" and " " or "") .. "["..math.floor(dist).." STUDS]"
			end
			d.Text = txt ~= "" and txt or plr.Name
		elseif drawings[plr] then drawings[plr].espText.Visible = false end
		if Toggles.Tracers and Toggles.Tracers.Value and drawings[plr] then
			local t = drawings[plr].tracer
			t.Visible = true
			local c = tracersColor
			if Toggles.TracersColorFromTeam and Toggles.TracersColorFromTeam.Value and plr.Team then c = plr.TeamColor.Color end
			if Toggles.RainbowTracers and Toggles.RainbowTracers.Value then c = Color3.fromHSV(tick()*(rainbowSpeed/50)%1,1,1) end
			t.Color = c
			if tracerOrigin == "Mouse" then t.From = mousePos
			elseif tracerOrigin == "Upper" then t.From = Vector2.new(camera.ViewportSize.X/2,0)
			elseif tracerOrigin == "Middle" then t.From = Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
			else t.From = Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y) end
			t.To = pos
		elseif drawings[plr] then drawings[plr].tracer.Visible = false end
	end
end)

local espToggle = ESPTab:AddToggle("ESP", {Text="ESP", Default=false})
espToggle:AddColorPicker("ESPColor", {Default=Color3.new(1,1,1), Title="ESP Color", Callback=function(v) espColor = v end})

local outlineToggle = ESPTab:AddToggle("Outline", {Text="Outline", Default=false})
outlineToggle:AddColorPicker("OutlineColor", {Default=Color3.new(1,1,1), Title="Outline Color", Callback=function(v) outlineColor = v end})

local tracersToggle = ESPTab:AddToggle("Tracers", {Text="Tracers", Default=false})
tracersToggle:AddColorPicker("TracersColor", {Default=Color3.new(1,1,1), Title="Tracers Color", Callback=function(v) tracersColor = v end})

ESPConfigTab:AddToggle("RainbowESP", {Text="Rainbow ESP", Default=false})
ESPConfigTab:AddToggle("RainbowOutline", {Text="Rainbow Outline", Default=false})
ESPConfigTab:AddToggle("RainbowTracers", {Text="Rainbow Tracers", Default=false})
ESPConfigTab:AddSlider("RainbowSpeed", {Text="Rainbow Speed", Min=0, Max=10, Default=5, Rounding=1, Callback=function(v) rainbowSpeed = v end})
ESPConfigTab:AddSlider("ESPSize", {Text="ESP Size", Min=16, Max=50, Default=16, Rounding=0, Callback=function(v) espSize = v end})
ESPConfigTab:AddDropdown("ESPFont", {Text="ESP Font", Values={"UI","System","Plex","Monospace"}, Default=1, Callback=function(v) espFont = ({UI=0,System=1,Plex=2,Monospace=3})[v] or 1 end})
ESPConfigTab:AddToggle("ShowDistance", {Text="Show Distance", Default=true, Callback=function(v) showDistance = v end})
ESPConfigTab:AddToggle("ShowPlayerName", {Text="Show Player Name", Default=true, Callback=function(v) showPlayerName = v end})
ESPConfigTab:AddSlider("OutlineFillTransparency", {Text="Outline Fill Transparency (%)", Min=0, Max=100, Default=100, Suffix="%", Rounding=0, Callback=function(v) outlineFillTransparency = v/100 end})
ESPConfigTab:AddSlider("OutlineTransparency", {Text="Outline Transparency (%)", Min=0, Max=100, Default=0, Suffix="%", Rounding=0, Callback=function(v) outlineTransparency = v/100 end})
ESPConfigTab:AddDropdown("TracersPosition", {Text="Tracers Position", Values={"Mouse","Upper","Middle","Down"}, Default="Down", Callback=function(v) tracerOrigin = v end})
ESPConfigTab:AddToggle("ESPColorFromTeam", {Text="ESP Color From Team", Default=false})
ESPConfigTab:AddToggle("OutlineColorFromTeam", {Text="Outline Color From Team", Default=false})
ESPConfigTab:AddToggle("TracersColorFromTeam", {Text="Tracers Color From Team", Default=false})

GameVisuals:AddSlider("FieldOfView", {Text="Field Of View", Default=defaultFieldOfView, Min=60, Max=120, Rounding=0})
GameVisuals:AddToggle("FullBright", {Text="Full Bright", Default=false})
GameVisuals:AddToggle("NoFog", {Text="No Fog", Default=false})

local TeleportGroupBox = Tabs.Features:AddLeftGroupbox("Teleport", "map-pin")
local FPSGroupBox = Tabs.Features:AddRightGroupbox("FPS", "activity")

local fpsValue = 60
FPSGroupBox:AddSlider("FPSMeter", {Text="FPS Cap", Default=60, Min=1, Max=720, Rounding=0, Callback=function(v) fpsValue = v end})
FPSGroupBox:AddButton({Text="Apply FPS Cap", Func=function() setfpscap(fpsValue) Library:Notify("FPS set to "..fpsValue,3) end})

local teleportPlayer = nil
local teleportType = "Instant (TP)"

local function getPlayerList()
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then table.insert(list, p.Name) end
	end
	return list
end

TeleportGroupBox:AddDropdown("TeleportPlayer", {
	Text = "Select Player",
	Values = getPlayerList(),
	Callback = function(v) teleportPlayer = Players:FindFirstChild(v) end
})

TeleportGroupBox:AddButton({Text="Teleport To Player", Func=function()
	if not teleportPlayer or not teleportPlayer.Character or not teleportPlayer.Character:FindFirstChild("HumanoidRootPart") then
		Library:Notify("Invalid player!",3) return
	end
	local target = teleportPlayer.Character.HumanoidRootPart
	local wasNoclip = Toggles.Noclip.Value
	if teleportType == "Tween (Fast)" and Toggles.NoclipOnTween.Value then Toggles.Noclip:SetValue(true) end
	if teleportType == "Instant (TP)" then
		if rootpart then rootpart.CFrame = target.CFrame end
	else
		if rootpart then
			local dist = (rootpart.Position - target.Position).Magnitude
			local tween = TweenService:Create(rootpart, TweenInfo.new(dist/500, Enum.EasingStyle.Linear), {CFrame = target.CFrame})
			tween:Play()
			tween.Completed:Wait()
			if Toggles.NoclipOnTween.Value and not wasNoclip then Toggles.Noclip:SetValue(false) end
		end
	end
end})

TeleportGroupBox:AddDropdown("TeleportType", {Text="Teleport Type", Values={"Instant (TP)","Tween (Fast)"}, Default="Instant (TP)", Callback=function(v) teleportType = v end})
TeleportGroupBox:AddToggle("NoclipOnTween", {Text="Noclip During Tween", Default=false})

local ServerGroupBox = Tabs.Features:AddLeftGroupbox("Server", "server")

ServerGroupBox:AddButton({Text = "Copy Server JobID", Func = function()
	setclipboard(game.JobId)
	Library:Notify("Server JobID copied!", 3)
end})

ServerGroupBox:AddButton({Text = "Copy Server Join Link", Func = function()
	local link = string.format("roblox://placeId=%d&gameInstanceId=%s", game.PlaceId, game.JobId)
	setclipboard(link)
	Library:Notify("Join link copied!", 5)
end})

ServerGroupBox:AddDivider()

local targetJobId = ""
ServerGroupBox:AddInput("TargetJobId", {
	Text = "Target Server JobID",
	Placeholder = "Enter JobId...",
	Callback = function(v) targetJobId = v:gsub("%s+", "") end
})

ServerGroupBox:AddButton({Text = "Join Server", Func = function()
	if targetJobId == "" or not targetJobId:match("^%w+%-") then
		Library:Notify("Invalid JobID!", 3) return
	end
	Library:Notify("Joining: "..targetJobId, 3)
	TeleportService:TeleportToPlaceInstance(game.PlaceId, targetJobId, player)
end})

ServerGroupBox:AddDivider()

ServerGroupBox:AddButton({Text = "Rejoin Server", Func = function()
	if game.JobId == "" then Library:Notify("Cannot rejoin reserved server!", 3) return end
	TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
end})

ServerGroupBox:AddButton({Text = "Quit Game", Func = function() game:Shutdown() end}, "Error")

local AutoChatGroupBox = Tabs.Features:AddRightGroupbox("Auto-Chat", "message-square")

local autoChatEnabled = false
local autoChatDelay = 1
local autoChatMessage = "hi!"
local autoChatType = "Infinite"
local autoChatLimit = 10

AutoChatGroupBox:AddToggle("AutoChat", {Text="Auto Chat", Default=false, Callback=function(v) autoChatEnabled = v end})
AutoChatGroupBox:AddSlider("AutoChatDelay", {Text="Auto Chat Delay", Default=1, Min=0, Max=5, Rounding=2, Callback=function(v) autoChatDelay = v end})
AutoChatGroupBox:AddInput("AutoChatMessage", {Text="Auto Chat Message", Default="hi!", Callback=function(v) autoChatMessage = v end})
AutoChatGroupBox:AddDropdown("AutoChatType", {Text="Auto Chat Type", Values={"Infinite", "Times", "Seconds"}, Default="Infinite", Callback=function(v) autoChatType = v end})
AutoChatGroupBox:AddInput("AutoChatLimit", {Text="Times / Seconds", Default="10", Callback=function(v) autoChatLimit = tonumber(v) or 10 end})

local chatChannel = TextChatService.TextChannels:WaitForChild("RBXGeneral")

spawn(function()
	while task.wait(autoChatDelay) do
		if not autoChatEnabled then continue end
		if autoChatMessage == "" then continue end

		if autoChatType == "Infinite" then
			chatChannel:SendAsync(autoChatMessage)
		elseif autoChatType == "Times" then
			if autoChatLimit > 0 then
				chatChannel:SendAsync(autoChatMessage)
				autoChatLimit -= 1
			else
				Toggles.AutoChat:SetValue(false)
			end
		elseif autoChatType == "Seconds" then
			local start = tick()
			repeat
				chatChannel:SendAsync(autoChatMessage)
				task.wait(autoChatDelay)
			until tick() - start >= autoChatLimit or not autoChatEnabled
			Toggles.AutoChat:SetValue(false)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	if not character or not humanoid or not rootpart then return end

	if Toggles.Noclip and Toggles.Noclip.Value then
		for _, p in ipairs(character:GetChildren()) do
			if p:IsA("BasePart") and p ~= rootpart then p.CanCollide = false end
		end
	end

	if Toggles.ForceThirdPerson and Toggles.ForceThirdPerson.Value then
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = Options.MaxZoom.Value
	end

	humanoid.WalkSpeed = Options.Walkspeed.Value
	humanoid.JumpPower = Options.Jumppower.Value
	player.CameraMaxZoomDistance = Options.MaxZoom.Value
	Workspace.Gravity = Options.Gravity.Value
	camera.FieldOfView = Options.FieldOfView.Value

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
		Lighting.FogStart = 0
	end
end)

UserInputService.JumpRequest:Connect(function()
	if Toggles.InfiniteJump and Toggles.InfiniteJump.Value and humanoid then
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")
MenuGroup:AddToggle("KeybindMenuOpen", {Default=Library.KeybindFrame.Visible, Text="Open Keybind Menu", Callback=function(v) Library.KeybindFrame.Visible = v end})
MenuGroup:AddToggle("ShowCustomCursor", {Text="Custom Cursor", Default=true, Callback=function(v) Library.ShowCustomCursor = v end})
MenuGroup:AddDropdown("NotificationSide", {Values={"Left","Right"}, Default="Right", Text="Notification Side", Callback=function(v) Library:SetNotifySide(v) end})
MenuGroup:AddDropdown("DPIDropdown", {Values={"50%","75%","100%","125%","150%","175%","200%"}, Default="100%", Text="DPI Scale", Callback=function(v) Library:SetDPIScale(tonumber(v:gsub("%%",""))/100) end})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {Default="U", NoUI=true, Text="Menu keybind"})
MenuGroup:AddButton("Unload", function() Library:Unload() end)
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("MyScriptHub/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()

spawn(function()
	while task.wait(0.1) do
		if Options.RainbowSpeed then rainbowSpeed = Options.RainbowSpeed.Value end
		if Options.ESPSize then espSize = Options.ESPSize.Value end
		if Options.ESPFont then espFont = ({UI=0,System=1,Plex=2,Monospace=3})[Options.ESPFont.Value] or 1 end
		if Options.ShowDistance then showDistance = Options.ShowDistance.Value end
		if Options.ShowPlayerName then showPlayerName = Options.ShowPlayerName.Value end
		if Options.OutlineFillTransparency then outlineFillTransparency = Options.OutlineFillTransparency.Value/100 end
		if Options.OutlineTransparency then outlineTransparency = Options.OutlineTransparency.Value/100 end
	end
end)

local function refreshPlayers()
	task.wait(1)
	if Options.TeleportPlayer then Options.TeleportPlayer:SetValues(getPlayerList()) end
end

Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(refreshPlayers)
refreshPlayers()
