Identifiers = {}

function Identifiers.getLicense(src)
    local ok, result = pcall(function()
        return exports["union"]:GetPlayerFromId(src)
    end)

    if ok and result and result.license then
        return result.license
    end

    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(id, 1, 8) == "license:" then
            return id
        end
    end

    return nil
end