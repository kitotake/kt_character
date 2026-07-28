-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — SERVER UTILS
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Utils = {}

function Utils.debug(message, level)
    if not KT.Config.DEBUG then return end
    level = level or "INFO"
    print(("^2[kt_character:%s]^7 %s"):format(level, message))
end

function Utils.normalizePedModel(input)
    if input == "f" or input == "mp_f_freemode_01" then
        return "mp_f_freemode_01"
    end
    return "mp_m_freemode_01"
end

function Utils.modelToGender(model)
    if model == "mp_f_freemode_01" then return "f" end
    return "m"
end

function Utils.genderToModel(gender)
    return Utils.normalizePedModel(gender)
end

function string.trim(s)
    if not s then return "" end
    return s:match("^%s*(.-)%s*$")
end

-- UUID v4 fallback
function Utils.generateUUID()
    local ok, result = pcall(function()
        return exports["union"]:generateUniqueId()
    end)
    if ok and result and result ~= "" then return result end

    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return string.gsub(template, "[xy]", function(c)
        local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
        return string.format("%x", v)
    end)
end

function Utils.isValidDate(dateStr)
    if not dateStr then return false end
    local s = tostring(dateStr)
    if not s:match("^%d%d%d%d%-%d%d%-%d%d$") then return false end
    local y = tonumber(s:sub(1, 4))
    local m = tonumber(s:sub(6, 7))
    local d = tonumber(s:sub(9, 10))
    if not y or not m or not d then return false end
    if m < 1 or m > 12 then return false end
    if d < 1 or d > 31 then return false end
    local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if (y % 4 == 0 and y % 100 ~= 0) or (y % 400 == 0) then daysInMonth[2] = 29 end
    if d > daysInMonth[m] then return false end
    return true
end

function Utils.decodeJSON(raw)
    if not raw then return {} end
    local ok, result = pcall(json.decode, tostring(raw))
    return (ok and result) or {}
end

function Utils.encodeJSON(data)
    return json.encode(data or {})
end
