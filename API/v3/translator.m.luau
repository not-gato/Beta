return function(addlog)
    local LocalizationService = game:GetService("LocalizationService")
    local HttpService = game:GetService("HttpService")
    
    local Translator = {}
    local LangData = {}
    local DefaultLangData = {}
    local currentLangCode = "en-us"

    local LangCodes = {
        ["Deutsch"] = "de-de",
        ["English"] = "en-us",
        ["Español"] = "es-es",
        ["Filipino"] = "fil-tg",
        ["Français"] = "fr-fr",
        ["Português"] = "pt-br",
        ["Tiếng Việt"] = "vi",
        ["Русский"] = "ru"
    }

    local LangURLs = {
        ["en-us"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/en-us.json",
        ["es-es"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/es-es.json",
        ["pt-br"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/pt-br.json",
        ["ru"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/ru.json",
        ["vi"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/vi.json",
        ["fil-tg"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/fil-tg.json",
        ["fr-fr"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/fr-fr.json",
        ["de-de"] = "https://raw.githubusercontent.com/not-gato/UNX/refs/heads/main/Modules/v3/Lang/de-de.json"
    }

    local function decodeJSON(str)
        str = str:gsub("^%s+", ""):gsub("%s+$", "")
        local pos = 1
        local function decode()
            local function skip_whitespace()
                while pos <= #str and str:sub(pos, pos):match("%s") do
                    pos = pos + 1
                end
            end
            local function decode_string()
                local result = ""
                pos = pos + 1
                while pos <= #str do
                    local c = str:sub(pos, pos)
                    if c == '"' then
                        pos = pos + 1
                        return result
                    elseif c == "\\" then
                        pos = pos + 1
                        local escape = str:sub(pos, pos)
                        if escape == "n" then result = result .. "\n"
                        elseif escape == "t" then result = result .. "\t"
                        elseif escape == "r" then result = result .. "\r"
                        elseif escape == "\\" then result = result .. "\\"
                        elseif escape == '"' then result = result .. '"'
                        else result = result .. escape end
                        pos = pos + 1
                    else
                        result = result .. c
                        pos = pos + 1
                    end
                end
                return result
            end
            local function decode_object()
                local obj = {}
                pos = pos + 1
                skip_whitespace()
                if str:sub(pos, pos) == "}" then
                    pos = pos + 1
                    return obj
                end
                while true do
                    skip_whitespace()
                    if str:sub(pos, pos) ~= '"' then break end
                    local key = decode_string()
                    skip_whitespace()
                    if str:sub(pos, pos) ~= ":" then break end
                    pos = pos + 1
                    skip_whitespace()
                    obj[key] = decode()
                    skip_whitespace()
                    local c = str:sub(pos, pos)
                    if c == "}" then
                        pos = pos + 1
                        return obj
                    elseif c == "," then
                        pos = pos + 1
                    else
                        break
                    end
                end
                return obj
            end
            skip_whitespace()
            local c = str:sub(pos, pos)
            if c == "{" then
                return decode_object()
            elseif c == '"' then
                return decode_string()
            end
            return nil
        end
        return decode()
    end

    local function safeDecode(content)
        content = content:gsub("^[\239\187\191]*", "")
        content = content:gsub("^%s+", ""):gsub("%s+$", "")
        local success, result = pcall(decodeJSON, content)
        if not success then
            addlog("JSON Parser Error: " .. tostring(result), "UNX_JSONPARSER")
            return {}
        end
        if type(result) == "table" and next(result) then
            return result
        else
            return {}
        end
    end

    function Translator.Init()
        if isfile("unxhub/language_config.txt") then
            local fileContent = readfile("unxhub/language_config.txt")
            currentLangCode = fileContent:match("^%s*(.-)%s*$")
            if not currentLangCode or not LangURLs[currentLangCode] then 
                currentLangCode = "en-us" 
            end
        else
            local success, localeId = pcall(function() return LocalizationService.RobloxLocaleId end)
            if success and localeId then
                localeId = localeId:lower()
                if LangURLs[localeId] then
                    currentLangCode = localeId
                else
                    local prefix = localeId:match("^(%a+)")
                    if prefix then
                        if prefix == "es" and LangURLs["es-es"] then currentLangCode = "es-es"
                        elseif prefix == "pt" and LangURLs["pt-br"] then currentLangCode = "pt-br"
                        elseif prefix == "ru" and LangURLs["ru"] then currentLangCode = "ru"
                        elseif prefix == "vi" and LangURLs["vi"] then currentLangCode = "vi"
                        elseif prefix == "fil" and LangURLs["fil-tg"] then currentLangCode = "fil-tg"
                        elseif prefix == "fr" and LangURLs["fr-fr"] then currentLangCode = "fr-fr"
                        elseif prefix == "de" and LangURLs["de-de"] then currentLangCode = "de-de"
                        end
                    end
                end
            end
            writefile("unxhub/language_config.txt", currentLangCode)
        end

        local enCache = "unxhub/cache/lang_en-us.json"
        if isfile(enCache) then
            local cached = readfile(enCache)
            DefaultLangData = safeDecode(cached)
        else
            local s, r = pcall(game.HttpGet, game, LangURLs["en-us"])
            if s then
                writefile(enCache, r)
                DefaultLangData = safeDecode(r)
            end
        end

        if currentLangCode ~= "en-us" then
            local cacheFile = "unxhub/cache/lang_" .. currentLangCode .. ".json"
            local targetData = {}
            local loaded = false
            if isfile(cacheFile) then
                local cached = readfile(cacheFile)
                targetData = safeDecode(cached)
                if next(targetData) then loaded = true end
            end
            if not loaded and LangURLs[currentLangCode] then
                local s, r = pcall(game.HttpGet, game, LangURLs[currentLangCode])
                if s then
                    writefile(cacheFile, r)
                    targetData = safeDecode(r)
                end
            end
            for k, v in pairs(targetData) do
                LangData[k] = v
            end
        end
    end

    function Translator.T(text)
        return LangData[text] or DefaultLangData[text] or text
    end
    
    function Translator.GetLangCode()
        return currentLangCode
    end
    
    function Translator.GetLangCodes()
        return LangCodes
    end

    function Translator.GetLangURLs()
        return LangURLs
    end

    return Translator
end
