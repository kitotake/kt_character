local cam

function CreateCharacterCam()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam, coords.x + 1.0, coords.y, coords.z + 0.7)
    PointCamAtEntity(cam, ped, 0.0, 0.0, 0.6, true)

    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
end

function FocusFace()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)

    SetCamCoord(cam, coords.x + 0.5, coords.y, coords.z + 0.7)
    PointCamAtEntity(cam, ped, 0.0, 0.0, 0.65, true)
end