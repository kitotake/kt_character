Validator = {}

function Validator.character(data)
    if not data then return false, "Données invalides" end

    if not data.firstname or #data.firstname < 2 then
        return false, "Prénom invalide"
    end

    if not data.lastname or #data.lastname < 2 then
        return false, "Nom invalide"
    end

    local year = tonumber(string.sub(tostring(data.dateofbirth), 1, 4))
    local currentYear = tonumber(os.date("%Y"))

    if not year then return false, "Format date invalide" end
    if year < 1900 or year > currentYear then return false, "Date invalide" end
    if (currentYear - year) < 18 then return false, "18 ans minimum" end

    return true, "OK"
end