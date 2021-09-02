--[[
$module Score
]] --
local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local measurement = require("library.measurement")
local configuration = require("library.configuration")

local config = {use_uppercase_staff_names = false, hide_default_whole_rests = false}

configuration.get_parameters("score.config.txt", config)

local score = {}

local CLEF_MAP = {treble = 0, alto = 1, tenor = 2, bass = 3}

--[[
% delete_all_staves()

Deletes all staves in the current document.
]]
function score.delete_all_staves()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        staff:DeleteData()
    end
    staves:SaveAll()
end

function score.set_show_staff_time_signature(staff_id, show_time_signature)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    if show_time_signature == nil then
        staff.ShowScoreTimeSignatures = true
    else
        staff.ShowScoreTimeSignatures = show_time_signature
    end
    staff:Save()
    return staff_id
end

function score.set_staff_transposition(staff_id, key, interval, clef)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.TransposeAlteration = key or 0
    staff.TransposeInterval = interval or 0
    if clef then
        staff.TransposeClefIndex = CLEF_MAP[clef]
        staff.TransposeUseClef = true
    end
    staff:Save()
    return staff_id
end

function score.set_staff_allow_hiding(staff_id, allow_hiding)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.AllowHiding = allow_hiding or true
    staff:Save()
    return staff_id
end

function score.set_staff_keyless(staff_id, allow_keyless)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.NoKeySigShowAccidentals = allow_keyless or true
    staff:Save()
    return staff_id
end

function score.add_space_above_staff(staff_id)
    local lists = finale.FCStaffLists()
    lists:SetMode(finale.SLMODE_CATEGORY_SCORE)
    lists:LoadAll()
    local list = lists:GetItemAt(0)
    list:AddStaff(staff_id)
    list:Save()

    -- could be faster
    local system_staves = finale.FCSystemStaves()
    system_staves:LoadAllForItem(1)
    for system_staff in each(system_staves) do
        if system_staff.Staff == staff_id then
            system_staff.Distance = system_staff.Distance + measurement.convert_to_EVPUs(tostring("6s"))
        end
        system_staff:Save()
    end
end

function score.set_staff_full_name(staff, full_name, double)
    local str = finale.FCString()
    if config.use_uppercase_staff_names then
        str.LuaString = string.upper(full_name):gsub("%^FLAT%(%)", "^flat()")
    else
        str.LuaString = full_name
    end
    if (double ~= nil) then
        str.LuaString = str.LuaString .. "^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. double ..
                            "\r^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. (double + 1)
    end
    staff:SaveNewFullNameString(str)
end

function score.set_staff_short_name(staff, short_name, double)
    local str = finale.FCString()
    if config.use_uppercase_staff_names then
        str.LuaString = string.upper(short_name):gsub("%^FLAT%(%)", "^flat()")
    else
        str.LuaString = short_name
    end
    if (double ~= nil) then
        str.LuaString = str.LuaString .. "^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. double ..
                            "\r^baseline(" .. measurement.convert_to_EVPUs("1s") .. ") " .. (double + 1)
    end
    staff:SaveNewAbbreviatedNameString(str)
end

function score.create_staff(full_name, short_name, type, clef, double)
    local staff_id = finale.FCStaves.Append()
    if staff_id then
        -- Load the created staff
        local staff = finale.FCStaff()
        staff:Load(staff_id)

        staff.InstrumentUUID = type
        staff:SetDefaultClef(CLEF_MAP[clef])

        if config.hide_default_whole_rests then
            staff:SetDisplayEmptyRests(false)
        end

        score.set_staff_full_name(staff, full_name, double)
        score.set_staff_short_name(staff, short_name, double)

        -- Save and return
        staff:Save()
        return staff:GetItemNo()
    end
    return -1
end

function score.create_staff_spaced(full_name, short_name, type, clef)
    local staff_id = score.create_staff(full_name, short_name, type, clef)
    score.add_space_above_staff(staff_id)
    return staff_id
end

function score.create_staff_percussion(full_name, short_name, type, clef)
    local staff_id = score.create_staff(full_name, short_name, type, clef)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff:SetNotationStyle(finale.STAFFNOTATION_PERCUSSION)
    staff:SavePercussionLayout(1, 0)
    return staff_id
end

function score.create_group(start_staff, end_staff, brace_name, has_barline, level, full_name, short_name)
    local BRACE_MAP = {
        none = finale.GRBRAC_NONE,
        plain = finale.GRBRAC_PLAIN,
        chorus = finale.GRBRAC_CHORUS,
        piano = finale.GRBRAC_PIANO,
        reverse_chorus = finale.GRBRAC_REVERSECHORUS,
        reverse_piano = finale.GRBRAC_REVERSEPIANO,
        curved_chorus = finale.GRBRAC_CURVEDCHORUS,
        reverse_curved_chorus = finale.GRBRAC_REVERSECURVEDCHORUS,
        desk = finale.GRBRAC_DESK,
        reverse_desk = finale.GRBRAC_REVERSEDESK,
    }
    local sg_cmper = {}
    local sg = finale.FCGroup()
    local staff_groups = finale.FCGroups()
    staff_groups:LoadAll()
    for sg in each(staff_groups) do
        table.insert(sg_cmper, sg:GetItemID())
    end
    table.sort(sg_cmper)
    sg:SetStartStaff(start_staff)
    sg:SetEndStaff(end_staff)
    sg:SetStartMeasure(1)
    sg:SetEndMeasure(32767)
    sg:SetBracketStyle(BRACE_MAP[brace_name])
    if start_staff == end_staff then
        sg:SetBracketSingleStaff(true)
    end
    if (has_barline) then
        sg:SetDrawBarlineMode(finale.GROUPBARLINESTYLE_THROUGH)
    end
    sg:SetBracketHorizontalPos(-12 * level)

    -- names
    if full_name then
        local str = finale.FCString()
        str.LuaString = full_name
        sg:SaveNewFullNameBlock(str)
        sg:SetShowGroupName(true)
        sg:SetFullNameHorizontalOffset(measurement.convert_to_EVPUs("2s"))
    end
    if short_name then
        local str = finale.FCString()
        str.LuaString = short_name
        sg:SaveNewAbbreviatedNameBlock(str)
        sg:SetShowGroupName(true)
    end

    if sg_cmper[1] == nil then
        sg:SaveNew(1)
    else
        local save_num = sg_cmper[1] + 1
        sg:SaveNew(save_num)
    end
end

function score.create_group_primary(start, last, fullName, shortName)
    score.create_group(start, last, "curved_chorus", true, 1, fullName, shortName)
end

function score.create_group_secondary(start, last, fullName, shortName)
    score.create_group(start, last, "desk", false, 2, fullName, shortName)
end

function score.set_global_system_scaling(scaling)
    local format = finale.FCPageFormatPrefs()
    format:LoadScore()
    format:SetSystemScaling(scaling)
    format:Save()
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    for system in each(staff_systems) do
        system:SetResize(scaling)
        system:Save()
    end
    finale.FCStaffSystems.UpdateFullLayout()
end

function score.set_single_system_scaling(system_number, scaling)
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    local system = staff_systems:GetItemAt(system_number)
    if system then
        system:SetResize(scaling)
        system:Save()
    end
end

function score.use_large_time_signatures()
    local font_preferences = finale.FCFontPrefs()
    font_preferences:Load(finale.FONTPREF_TIMESIG)
    local font_info = font_preferences:CreateFontInfo()
    font_info:SetSize(40)
    font_info.Name = "EngraverTime"
    font_preferences:SetFontInfo(font_info)
    font_preferences:Save()
    local distance_preferences = finale.FCDistancePrefs()
    distance_preferences:Load(1)
    distance_preferences:SetTimeSigBottomVertical(-290)
    distance_preferences:Save()
end

function score.use_large_measure_numbers(distance)
    local systems = finale.FCStaffSystem()
    systems:Load(1)

    for m in loadall(finale.FCMeasureNumberRegions()) do
        m:SetUseScoreInfoForParts(false)
        local font_preferences = finale.FCFontPrefs()
        font_preferences:Load(finale.FONTPREF_MEASURENUMBER)
        local font = font_preferences:CreateFontInfo()
        m:SetMultipleFontInfo(font, false)
        m:SetShowOnTopStaff(false, false)
        m:SetShowOnSystemStart(false, false)
        m:SetShowOnBottomStaff(true, false)
        m:SetExcludeOtherStaves(true, false)
        m:SetShowMultiples(true, false)
        m:SetHideFirstNumber(false, false)
        m:SetMultipleAlignment(finale.MNALIGN_CENTER, false)
        m:SetMultipleJustification(finale.MNJUSTIFY_CENTER, false)

        -- Sets the position in accordance to the system scaling
        local position = -1 * measurement.convert_to_EVPUs(distance)
        m:SetMultipleVerticalPosition(position, false)
        m:Save()
    end
end

function score.set_minimum_measure_width(width)
    local music_spacing_preferences = finale.FCMusicSpacingPrefs()
    music_spacing_preferences:Load(1)
    music_spacing_preferences:SetMinMeasureWidth(measurement.convert_to_EVPUs(width))
    music_spacing_preferences:Save()
end

return score
