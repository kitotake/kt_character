RegisterNetEvent("kt_appearance:save", function(data)
    local src = source

    -- JSON encode
    local json = json.encode(data)

    -- Exemple DB
    -- exports.oxmysql:execute("UPDATE users SET skin = ? WHERE identifier = ?", {
    --     json, identifier
    -- })

    print("Saved appearance:", json)
end)