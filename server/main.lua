-- ─── Création d'un personnage ──────────────────────────────────────────────────
RegisterNetEvent("kt_character:createCharacter", function(data)
    local src = source

    -- Validation basique côté serveur
    if not data.firstname or #data.firstname < 2 then
        TriggerClientEvent("kt_character:error", src, "Prénom invalide")
        return
    end

    if not data.lastname or #data.lastname < 2 then
        TriggerClientEvent("kt_character:error", src, "Nom invalide")
        return
    end

    if not data.dateofbirth then
        TriggerClientEvent("kt_character:error", src, "Date de naissance manquante")
        return
    end

    if data.gender ~= "mp_m_freemode_01" and data.gender ~= "mp_f_freemode_01" then
        TriggerClientEvent("kt_character:error", src, "Genre invalide")
        return
    end

    -- Récupérer l'identifier FiveM
    local identifiers = GetPlayerIdentifiers(src)
    local license = ""
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            license = id
            break
        end
    end

    -- Générer un unique_id si absent
    local unique_id = data.unique_id
    if not unique_id or unique_id == "" then
        unique_id = string.format("%s_%d", license:gsub("license:", ""), os.time())
    end

    local character = {
        identifier  = license,
        unique_id   = unique_id,
        firstname   = data.firstname,
        lastname    = data.lastname,
        dateofbirth = data.dateofbirth,
        gender      = data.gender,
        skin        = json.encode({
            hair      = data.hair      or 0,
            beard     = data.beard     or 0,
            hairColor = data.hairColor or 0,
        }),
    }

    print(string.format("[kt_character] Nouveau personnage: %s %s (%s) — %s",
        character.firstname,
        character.lastname,
        character.unique_id,
        character.gender
    ))

    -- Exemple oxmysql:
    -- exports.oxmysql:execute(
    --     "INSERT INTO characters (identifier, unique_id, firstname, lastname, dateofbirth, gender, skin) VALUES (?, ?, ?, ?, ?, ?, ?)",
    --     { character.identifier, character.unique_id, character.firstname, character.lastname, character.dateofbirth, character.gender, character.skin },
    --     function(result)
    --         if result and result.affectedRows > 0 then
    --             TriggerClientEvent("kt_character:created", src, character)
    --         end
    --     end
    -- )

    -- Pour l'instant on trigger directement le client
    TriggerClientEvent("kt_character:created", src, character)
end)

-- ─── Mise à jour de l'apparence ────────────────────────────────────────────────
RegisterNetEvent("kt_character:updateAppearance", function(data)
    local src = source

    -- Exemple: mise à jour en DB
    -- exports.oxmysql:execute(
    --     "UPDATE characters SET skin = ? WHERE unique_id = ?",
    --     { json.encode(data), data.unique_id }
    -- )

    print("[kt_character] Apparence mise à jour pour " .. tostring(GetPlayerName(src)))
end)

-- ─── Envoyer l'identifier au NUI ───────────────────────────────────────────────
-- À appeler depuis le client quand le NUI est ouvert
RegisterNetEvent("kt_character:requestIdentifier", function()
    local src = source
    local identifiers = GetPlayerIdentifiers(src)
    local license = ""
    for _, id in ipairs(identifiers) do
        if string.sub(id, 1, 8) == "license:" then
            license = id
            break
        end
    end
    TriggerClientEvent("kt_character:sendIdentifier", src, license)
end)