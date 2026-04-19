RegisterNetEvent("kt_character:updatePed", function(data)
    local ped = PlayerPedId()

    if data.gender == "male" then
        SetPlayerModel(PlayerId(), GetHashKey("mp_m_freemode_01"))
    else
        SetPlayerModel(PlayerId(), GetHashKey("mp_f_freemode_01"))
    end

    ped = PlayerPedId()

    -- Exemple visage
    SetPedHeadBlendData(ped, data.face, data.face, 0, data.face, data.face, 0, 1.0, 1.0, 0.0, false)

    -- Exemple cheveux
    SetPedComponentVariation(ped, 2, data.hair, 0, 0)
end)