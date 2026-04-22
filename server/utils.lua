-- server/utils.lua (kt_character)
-- FIX: genderEnumToModel("m") retournait "m" → doit retourner "mp_m_freemode_01"
-- FIX: suppression UPDATE last_login (ping inutile)

Utils = {}

function Utils.debug(message, level)
    if not Config.DEBUG then return end
    level = level or "INFO"
    print(("^2[kt_character:%s]^7 %s"):format(level, message))
end

function string.trim(s)
    return s:match("^%s*(.-)%s*$")
end

function Utils.modelToGenderEnum(model)
    if model == "mp_f_freemode_01" then return "f" end
    return "m"
end

-- FIX: retourne toujours un model GTA V valide, jamais "m" ou "f" seul
function Utils.genderEnumToModel(enum)
    if enum == "f" or enum == "mp_f_freemode_01" then
        return "mp_f_freemode_01"
    end
    return "mp_m_freemode_01"
end