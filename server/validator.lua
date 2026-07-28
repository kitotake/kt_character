-- server/validator.lua (kt_character)
-- FIX : validation date complète — vérifie mois et jour en plus de l'année.

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

    -- FIX : validation format ET plages valides
    if not dateStr:match("^%d%d%d%d%-%d%d%-%d%d$") then
        return false, "Format date invalide (attendu : YYYY-MM-DD)"
    end

    local year  = tonumber(dateStr:sub(1, 4))
    local month = tonumber(dateStr:sub(6, 7))
    local day   = tonumber(dateStr:sub(9, 10))

    if not year or not month or not day then
        return false, "Date invalide"
    end

    -- FIX : vérification plage mois
    if month < 1 or month > 12 then
        return false, "Mois invalide"
    end

    -- FIX : vérification plage jour (avec bissextile)
    local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    if (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0) then
        daysInMonth[2] = 29
    end
    if day < 1 or day > daysInMonth[month] then
        return false, "Jour invalide pour ce mois"
    end

    local currentYear = tonumber(os.date("%Y"))
    if year < 1900 or year > currentYear then
        return false, "Année invalide"
    end
    if (currentYear - year) < 18 then
        return false, "18 ans minimum requis"
    end

    return true, "OK"
end
