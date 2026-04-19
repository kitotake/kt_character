local function applyAppearance(data)
    local ped = PlayerPedId()

    -- SEXE
    if data.model == "male" then
        SetPlayerModel(PlayerId(), `mp_m_freemode_01`)
    else
        SetPlayerModel(PlayerId(), `mp_f_freemode_01`)
    end

    ped = PlayerPedId()

    -- PARENTS (HEAD BLEND)
    SetPedHeadBlendData(
        ped,
        data.parents.mother,
        data.parents.father,
        0,
        data.parents.mother,
        data.parents.father,
        0,
        data.mixShape,
        data.mixSkin,
        0.0,
        false
    )

    -- VISAGE (traits)
    for i = 0, 19 do
        SetPedFaceFeature(ped, i, data.faceFeatures[i] or 0.0)
    end

    -- CHEVEUX
    SetPedComponentVariation(ped, 2, data.hair.style, 0, 0)
    SetPedHairColor(ped, data.hair.color, data.hair.highlight)

    -- OVERLAYS
    -- barbe
    SetPedHeadOverlay(ped, 1, data.beard.style, data.beard.opacity)
    SetPedHeadOverlayColor(ped, 1, 1, data.beard.color, data.beard.color)

    -- sourcils
    SetPedHeadOverlay(ped, 2, data.eyebrows.style, data.eyebrows.opacity)
    SetPedHeadOverlayColor(ped, 2, 1, data.eyebrows.color, data.eyebrows.color)

    -- maquillage
    SetPedHeadOverlay(ped, 4, data.makeup.style, data.makeup.opacity)
    SetPedHeadOverlayColor(ped, 4, 2, data.makeup.color, data.makeup.color)
end

RegisterNetEvent("kt_appearance:update", applyAppearance)