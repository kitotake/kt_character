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

function Utils.genderEnumToModel(enum)
    if enum == "f" then return "mp_f_freemode_01" end
    return "mp_m_freemode_01"
end