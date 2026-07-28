-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- KT_CHARACTER — VALIDATOR
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Validator = {}

function Validator.character(data)
    if not data then return false, "Données invalides" end

    if not data.firstname or string.len(string.trim(data.firstname)) < 2 then
        return false, "Prénom invalide (2 caractères minimum)"
    end
    if not data.lastname or string.len(string.trim(data.lastname)) < 2 then
        return false, "Nom invalide (2 caractères minimum)"
    end

    local dateStr = tostring(data.dateofbirth or "")
    if not dateStr:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return false, "Format date invalide (YYYY-MM-DD)"
    end

    local year  = tonumber(dateStr:sub(1, 4))
    local month = tonumber(dateStr:sub(6, 7))
    local day   = tonumber(dateStr:sub(9, 10))
    if not year or not month or not day then return false, "Date invalide" end
    if month < 1 or month > 12 then return false, "Mois invalide" end

    local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then daysInMonth[2] = 29 end
    if day < 1 or day > daysInMonth[month] then return false, "Jour invalide" end

    local currentYear = tonumber(os.date("%Y"))
    if year < 1900 or year > currentYear then return false, "Année invalide" end
    if (currentYear - year) < KT.Config.MIN_AGE then
        return false, KT.Config.MIN_AGE .. " ans minimum requis"
    end

    return true, "OK"
end

function Validator.outfitData(data)
    if not data then return false, "Données manquantes" end
    if not data.unique_id or data.unique_id == "" then return false, "unique_id manquant" end
    local name = string.trim(data.name or "")
    if name == "" then return false, "Nom invalide" end
    if #name > 50 then return false, "Nom trop long" end
    return true
end
