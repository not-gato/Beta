local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MODEL_ID = "gemini-2.5-flash" 
local FILENAME = "APIKey_Executor_Mode.gem"
local URL = "https://generativelanguage.googleapis.com/v1beta/models/" .. MODEL_ID .. ":generateContent"
local MAX_AI_HISTORY = 8
local MAX_CHAT_LOGS = 30

local Settings = {
    ChatLogs = true,
    History = true,
    PlayerInfo = true,
    GameInfo = true,
    CodeExec = true,
    ExecutorInfo = true,
    PublicAI = true,
    CustomInstructions = "" 
}

if not _G.GeminiHistory then _G.GeminiHistory = {} end
if not _G.ServerChatLogs then _G.ServerChatLogs = {} end
_G.IsGeminiThinking = false

local performRequest = nil
if type(request) == "function" then performRequest = request
elseif type(http_request) == "function" then performRequest = http_request
elseif type(syn) == "table" and type(syn.request) == "function" then performRequest = syn.request
elseif type(fluxus) == "table" and type(fluxus.request) == "function" then performRequest = fluxus.request
end

local hasFileAccess = (type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function")
local getExecutorName = (identifyexecutor and identifyexecutor) or (getexecutorname and getexecutorname) or function() return "Executor Genérico" end

if not performRequest then return end

local function createUI()
    if _G.GeminiUIInstance then _G.GeminiUIInstance:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GeminiAI_UI"
    ScreenGui.ResetOnSpawn = false
    if pcall(function() ScreenGui.Parent = CoreGui end) then else ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui") end
    _G.GeminiUIInstance = ScreenGui

    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Name = "ToggleAI"
    ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
    ToggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ToggleBtn.Text = "🧠"
    ToggleBtn.TextSize = 25
    ToggleBtn.AutoButtonColor = true
    ToggleBtn.Parent = ScreenGui
    
    local UICornerBtn = Instance.new("UICorner")
    UICornerBtn.CornerRadius = UDim.new(1, 0)
    UICornerBtn.Parent = ToggleBtn
    
    local StatusDot = Instance.new("Frame")
    StatusDot.Size = UDim2.new(0, 10, 0, 10)
    StatusDot.Position = UDim2.new(1, -12, 0, 2)
    StatusDot.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    StatusDot.Parent = ToggleBtn
    local DotCorner = Instance.new("UICorner")
    DotCorner.CornerRadius = UDim.new(1,0)
    DotCorner.Parent = StatusDot

    task.spawn(function()
        while task.wait(0.5) do
            StatusDot.BackgroundColor3 = _G.IsGeminiThinking and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(0, 255, 0)
        end
    end)

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "SettingsPanel"
    MainFrame.Size = UDim2.new(0, 320, 0, 520)
    MainFrame.Position = UDim2.new(0, 70, 0.5, -260)
    MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    MainFrame.Visible = false
    MainFrame.Parent = ScreenGui
    
    local UICornerMain = Instance.new("UICorner")
    UICornerMain.CornerRadius = UDim.new(0, 10)
    UICornerMain.Parent = MainFrame

    local Title = Instance.new("TextLabel")
    Title.Text = "CONFIGURACIÓN IA"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = MainFrame

    local ScrollContainer = Instance.new("ScrollingFrame")
    ScrollContainer.Size = UDim2.new(0.9, 0, 0.82, 0)
    ScrollContainer.Position = UDim2.new(0.05, 0, 0.10, 0)
    ScrollContainer.BackgroundTransparency = 1
    ScrollContainer.ScrollBarThickness = 4
    ScrollContainer.Parent = MainFrame
    
    local UIList = Instance.new("UIListLayout")
    UIList.Padding = UDim.new(0, 8)
    UIList.SortOrder = Enum.SortOrder.LayoutOrder
    UIList.Parent = ScrollContainer

    local function createToggle(text, settingKey)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
        ToggleFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        ToggleFrame.Parent = ScrollContainer
        
        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 6)
        Corner.Parent = ToggleFrame

        local Label = Instance.new("TextLabel")
        Label.Text = text
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.Position = UDim2.new(0.05, 0, 0, 0)
        Label.BackgroundTransparency = 1
        Label.TextColor3 = Color3.fromRGB(220, 220, 220)
        Label.Font = Enum.Font.GothamSemibold
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.TextSize = 13
        Label.Parent = ToggleFrame

        local Switch = Instance.new("TextButton")
        Switch.Text = ""
        Switch.Size = UDim2.new(0, 40, 0, 20)
        Switch.Position = UDim2.new(0.8, 0, 0.5, -10)
        Switch.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(200, 50, 50)
        Switch.Parent = ToggleFrame
        
        local SwitchCorner = Instance.new("UICorner")
        SwitchCorner.CornerRadius = UDim.new(1, 0)
        SwitchCorner.Parent = Switch

        Switch.MouseButton1Click:Connect(function()
            Settings[settingKey] = not Settings[settingKey]
            TweenService:Create(Switch, TweenInfo.new(0.2), {BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(50, 200, 100) or Color3.fromRGB(200, 50, 50)}):Play()
        end)
    end

    createToggle("1. Leer Chat Global", "ChatLogs")
    createToggle("2. Historial de Chat", "History")
    createToggle("3. Info Detallada Jugadores", "PlayerInfo")
    createToggle("4. Info Juego/Tiempo", "GameInfo")
    createToggle("5. Permitir Ejecutar Código", "CodeExec")
    createToggle("6. Info del Ejecutor", "ExecutorInfo")
    createToggle("7. Permitir a Todos Usar IA", "PublicAI")

    local InstructionLabel = Instance.new("TextLabel")
    InstructionLabel.Text = "Instrucciones Personalizadas:"
    InstructionLabel.Size = UDim2.new(1, 0, 0, 25)
    InstructionLabel.BackgroundTransparency = 1
    InstructionLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
    InstructionLabel.Font = Enum.Font.GothamBold
    InstructionLabel.TextSize = 14
    InstructionLabel.Parent = ScrollContainer

    local CustomBox = Instance.new("TextBox")
    CustomBox.Size = UDim2.new(1, 0, 0, 80)
    CustomBox.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    CustomBox.TextColor3 = Color3.fromRGB(200, 200, 200)
    CustomBox.TextXAlignment = Enum.TextXAlignment.Left
    CustomBox.TextYAlignment = Enum.TextYAlignment.Top
    CustomBox.TextWrapped = true
    CustomBox.PlaceholderText = "Ej: Sé sarcástico, habla como pirata..."
    CustomBox.Text = Settings.CustomInstructions
    CustomBox.Parent = ScrollContainer
    
    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 6)
    BoxCorner.Parent = CustomBox

    CustomBox.FocusLost:Connect(function()
        Settings.CustomInstructions = CustomBox.Text
    end)

    local ResetBtn = Instance.new("TextButton")
    ResetBtn.Text = "⚠️ REINICIAR SISTEMA (Desbloquear)"
    ResetBtn.Size = UDim2.new(0.9, 0, 0, 35)
    ResetBtn.Position = UDim2.new(0.05, 0, 0.92, 0)
    ResetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    ResetBtn.TextColor3 = Color3.new(1,1,1)
    ResetBtn.Font = Enum.Font.GothamBold
    ResetBtn.Parent = MainFrame
    
    local ResetCorner = Instance.new("UICorner")
    ResetCorner.Parent = ResetBtn

    ResetBtn.MouseButton1Click:Connect(function()
        _G.IsGeminiThinking = false
        _G.GeminiHistory = {}
        StarterGui:SetCore("SendNotification", {Title="Sistema", Text="IA Reiniciada con Éxito."})
    end)

    ToggleBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)
    
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        ToggleBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    ToggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = ToggleBtn.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    ToggleBtn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then update(input) end end)
end

local function getGameInfo()
    if not Settings.GameInfo then return "Info Juego: APAGADO" end
    
    local dateTable = os.date("*t")
    local timeStr = string.format("%02d/%02d/%04d a las %02d:%02d:%02d", dateTable.day, dateTable.month, dateTable.year, dateTable.hour, dateTable.min, dateTable.sec)
    
    local info = { 
        Players = #Players:GetPlayers(),
        CurrentTime = timeStr,
        PlaceID = game.PlaceId
    }
    info.Executor = Settings.ExecutorInfo and getExecutorName() or "Oculto"
    pcall(function()
        local product = MarketplaceService:GetProductInfo(game.PlaceId)
        info.GameName = product.Name
    end)
    return HttpService:JSONEncode(info)
end

local function getDeepPlayerInfo()
    if not Settings.PlayerInfo then return "Lista Jugadores: APAGADO" end
    local list = {}
    local lp = Players.LocalPlayer
    local lpPos = Vector3.zero
    
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        lpPos = lp.Character.HumanoidRootPart.Position
    end
    
    for _, p in ipairs(Players:GetPlayers()) do
        local role = (p == lp) and "TÚ (Solicitante)" or "Otro Jugador"
        
        local dist = "Lejos/Muerto"
        local posStr = "Desconocido"
        local hp = "N/A"
        local speed = "N/A"
        local jump = "N/A"
        
        if p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChild("Humanoid")
            
            if root then
                local vectorDist = (root.Position - lpPos).Magnitude
                dist = math.floor(vectorDist) .. " studs"
                posStr = string.format("(%d, %d, %d)", math.floor(root.Position.X), math.floor(root.Position.Y), math.floor(root.Position.Z))
            end
            
            if hum then
                hp = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                speed = tostring(hum.WalkSpeed)
                jump = tostring(hum.JumpPower)
            end
        end

        local verif = p.HasVerifiedBadge and "SÍ" or "NO"

        table.insert(list, {
            Display = p.DisplayName,
            User = p.Name,
            ID = p.UserId,
            Verified = verif,
            Role = role,
            Pos = posStr,
            Dist = dist,
            Stats = { HP = hp, Spd = speed, Jump = jump }
        })
    end
    return HttpService:JSONEncode(list)
end

local function getChatHistoryBlock()
    if not Settings.ChatLogs then return "Historial Chat: APAGADO" end
    if #_G.ServerChatLogs == 0 then return "Vacío." end
    return table.concat(_G.ServerChatLogs, "\n")
end

local function chat(msg)
    if not msg then return end
    if #msg > 180 then msg = string.sub(msg, 1, 177) .. "..." end
    if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
        local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
        if channel then channel:SendAsync(msg) else game.Players.LocalPlayer.Chatted:Fire(msg) end
    elseif ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents") then
        local say = ReplicatedStorage.DefaultChatSystemChatEvents:FindFirstChild("SayMessageRequest")
        if say then say:FireServer(msg, "All") end
    else
        game.Players.LocalPlayer.Chatted:Fire(msg)
    end
end

local function logChatMessage(playerDisplayName, msg)
    local time = os.date("%H:%M")
    local logEntry = string.format("[%s] %s: %s", time, playerDisplayName, msg)
    table.insert(_G.ServerChatLogs, logEntry)
    if #_G.ServerChatLogs > MAX_CHAT_LOGS then table.remove(_G.ServerChatLogs, 1) end
end

local function askGemini(prompt, sender)
    if _G.IsGeminiThinking then return end
    local apiKey = _G.GeminiKey
    if not apiKey then chat(":: IA :: Error: Sin API Key."); return end
    
    _G.IsGeminiThinking = true
    
    task.spawn(function()
        local success, err = pcall(function()
            local gameData = getGameInfo()
            local playerData = getDeepPlayerInfo()
            local chatLogs = getChatHistoryBlock()
            local customRules = Settings.CustomInstructions or ""
            
            local senderContext = string.format(
                "PREGUNTA DE: %s (@%s). Si preguntan 'quién soy', busca sus datos en la lista.",
                sender.DisplayName, sender.Name
            )

            local systemPrompt = string.format([[
                Eres una Asistente IA dentro de Roblox. Responde corto (max 150 caracteres). Habla Español.
                
                === INSTRUCCIONES PERSONALIZADAS ===
                %s
                
                === TIEMPO E INFO JUEGO ===
                %s
                
                === LISTA DETALLADA JUGADORES ===
                %s
                
                === CONTEXTO ===
                %s
                Chat Reciente: %s
                
                REGLAS:
                1. Si piden "tp a alguien", genera código usando su Posición (Pos).
                2. Si piden "matar", genera código de Kill Aura o Tool Kill.
                3. El código debe estar en ```lua.
            ]], customRules, gameData, playerData, senderContext, chatLogs)

            local currentMessage = { role = "user", parts = {{ text = sender.Name .. ": " .. prompt }} }
            local payloadContents = {}
            if Settings.History then
                for _, msg in ipairs(_G.GeminiHistory) do table.insert(payloadContents, msg) end
            end
            table.insert(payloadContents, currentMessage)

            local body = {
                system_instruction = { parts = {{ text = systemPrompt }} },
                contents = payloadContents,
                safety_settings = {
                    { category = "HARM_CATEGORY_HARASSMENT", threshold = "BLOCK_NONE" },
                    { category = "HARM_CATEGORY_HATE_SPEECH", threshold = "BLOCK_NONE" },
                    { category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = "BLOCK_NONE" },
                    { category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = "BLOCK_NONE" }
                }
            }

            local response = performRequest({
                Url = URL .. "?key=" .. apiKey,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = HttpService:JSONEncode(body)
            })

            if response.StatusCode ~= 200 then
                chat(":: IA :: Error de API (" .. response.StatusCode .. ").")
                return
            end

            local result = HttpService:JSONDecode(response.Body)
            if result and result.candidates and result.candidates[1] and result.candidates[1].content then
                local aiText = result.candidates[1].content.parts[1].text
                
                if Settings.History then
                    table.insert(_G.GeminiHistory, currentMessage)
                    table.insert(_G.GeminiHistory, { role = "model", parts = {{ text = aiText }} })
                    while #_G.GeminiHistory > MAX_AI_HISTORY do table.remove(_G.GeminiHistory, 1) end
                end

                local codeContent = nil
                local chatContent = aiText
                local codeStart, codeEnd = string.find(aiText, "```lua")
                if codeStart then
                    local endBlock = string.find(aiText, "```", codeEnd + 1)
                    if endBlock then
                        codeContent = string.sub(aiText, codeEnd + 1, endBlock - 1)
                        chatContent = string.sub(aiText, 1, codeStart - 1)
                    end
                end
                
                chatContent = chatContent:gsub("\n", " "):gsub("```", ""):gsub("%s+", " ")
                if #chatContent > 1 then chat(":: IA :: " .. chatContent) end
                if codeContent and Settings.CodeExec and _G.AskConfirm then _G.AskConfirm(codeContent) end
            else
                chat(":: IA :: Nada que decir (Filtro/Error).")
            end
        end)

        if not success then
            warn(":: IA ERROR INTERNO ::", err)
            chat(":: IA :: Error Interno (Ver F9).")
        end
        _G.IsGeminiThinking = false
    end)
end

local function executeCode(code)
    local func, err = loadstring(code)
    if func then pcall(func); StarterGui:SetCore("SendNotification", {Title="Éxito", Text="Ejecutado."})
    else StarterGui:SetCore("SendNotification", {Title="Error", Text="Script Inválido."}) end
end

_G.AskConfirm = function(code)
    if not Settings.CodeExec then return end 
    local ScreenGui = _G.GeminiUIInstance or Instance.new("ScreenGui")
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 150)
    Frame.Position = UDim2.new(0.5, -150, 0.8, -160)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    Frame.BorderColor3 = Color3.fromRGB(255, 170, 0)
    Frame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Text = "IA quiere ejecutar código:"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Size = UDim2.new(1,0,0,30)
    Title.BackgroundTransparency = 1
    Title.Parent = Frame
    
    local Yes = Instance.new("TextButton")
    Yes.Text = "ACEPTAR"
    Yes.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
    Yes.Size = UDim2.new(0.4, 0, 0, 30)
    Yes.Position = UDim2.new(0.05, 0, 0.6, 0)
    Yes.Parent = Frame
    
    local No = Instance.new("TextButton")
    No.Text = "DENEGAR"
    No.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
    No.Size = UDim2.new(0.4, 0, 0, 30)
    No.Position = UDim2.new(0.55, 0, 0.6, 0)
    No.Parent = Frame

    Yes.MouseButton1Click:Connect(function() Frame:Destroy(); executeCode(code) end)
    No.MouseButton1Click:Connect(function() Frame:Destroy() end)
end

if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        local src = textChatMessage.TextSource
        if src then
            logChatMessage(src.Name, textChatMessage.Text)
            if string.sub(textChatMessage.Text:lower(), 1, 4) == "/ai " then
                local player = Players:GetPlayerByUserId(src.UserId)
                if player then
                    if Settings.PublicAI or (player.UserId == Players.LocalPlayer.UserId) then
                        local prompt = string.sub(textChatMessage.Text, 5)
                        if #prompt > 1 then askGemini(prompt, player) end
                    end
                end
            end
        end
    end)
else
    local function connectChatListener(player)
        player.Chatted:Connect(function(msg)
            logChatMessage(player.DisplayName, msg)
            if string.sub(msg:lower(), 1, 4) == "/ai " then
                if Settings.PublicAI or (player.UserId == Players.LocalPlayer.UserId) then
                    local prompt = string.sub(msg, 5)
                    if #prompt > 1 then askGemini(prompt, player) end
                end
            end
        end)
    end
    for _, p in ipairs(Players:GetPlayers()) do connectChatListener(p) end
    Players.PlayerAdded:Connect(connectChatListener)
end

local function startBot()
    createUI()
    chat('IA Cargada. Para usar, escribe "/ai" seguido de tu pregunta.')
end

if hasFileAccess and isfile(FILENAME) then
    _G.GeminiKey = readfile(FILENAME)
    startBot()
else
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = CoreGui
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 120)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -60)
    Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Frame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel"); Title.Text = "INTRODUCIR API KEY (GEMINI)"; Title.TextColor3 = Color3.new(1,1,1); Title.Size = UDim2.new(1,0,0,30); Title.BackgroundTransparency = 1; Title.Parent = Frame
    local Box = Instance.new("TextBox"); Box.Size = UDim2.new(0.9, 0, 0, 40); Box.Position = UDim2.new(0.05, 0, 0.4, 0); Box.PlaceholderText = "Pega la Key aquí..."; Box.Text = ""; Box.Parent = Frame
    local Save = Instance.new("TextButton"); Save.Text = "GUARDAR E INICIAR"; Save.Size = UDim2.new(1, 0, 0, 30); Save.Position = UDim2.new(0, 0, 0.8, 0); Save.BackgroundColor3 = Color3.fromRGB(50, 150, 255); Save.Parent = Frame
    
    Save.MouseButton1Click:Connect(function()
        if #Box.Text > 5 then
            if hasFileAccess then writefile(FILENAME, Box.Text) end
            _G.GeminiKey = Box.Text
            ScreenGui:Destroy()
            startBot()
        end
    end)
end
