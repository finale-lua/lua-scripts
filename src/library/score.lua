--[[
$module Score
]] --
local library = require("library.general_library")
local configuration = require("library.configuration")
local measurement = require("library.measurement")

local config = {use_uppercase_staff_names = false, hide_default_whole_rests = false}

configuration.get_parameters("score.config.txt", config)

local score = {}

local CLEF_MAP = {treble = 0, alto = 1, tenor = 2, bass = 3, percussion = 12, grand_staff = {0, 3}, organ = {0, 3, 3}, treble_8ba = 5, tenor_voice = 5}
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
local KEY_MAP = {} -- defined verbosely to be able to use "#" in key names
KEY_MAP.c = 0
KEY_MAP.g = -1
KEY_MAP.d = -2
KEY_MAP.a = -3
KEY_MAP.e = -4
KEY_MAP.b = -5
KEY_MAP["f#"] = -6
KEY_MAP["c#"] = -7
KEY_MAP["g#"] = -8
KEY_MAP["d#"] = -9
KEY_MAP["a#"] = -10
KEY_MAP["e#"] = -11
KEY_MAP["b#"] = -12
KEY_MAP.f = 1
KEY_MAP.bb = 2 -- Bb, just lowercase
KEY_MAP.eb = 3 -- Eb, just lowercase
KEY_MAP.ab = 4 -- Ab, just lowercase
KEY_MAP.db = 5 -- Db, just lowercase
KEY_MAP.gb = 6 -- Gb, just lowercase
KEY_MAP.cb = 7 -- Cb, just lowercase
KEY_MAP.fb = 8 -- Fb, just lowercase
 
local VOICE_INSTRUMENTS = {
    finale.FFUUID_ALTOVOICE, 
    finale.FFUUID_BARITONEVOICE, 
    finale.FFUUID_BASSBAROTONEVOICE, 
    finale.FFUUID_BASSVOICE, 
    finale.FFUUID_BEATBOX, 
    finale.FFUUID_CHOIRAAHS, 
    finale.FFUUID_CHOIROOHS, 
    finale.FFUUID_CONTRALTOVOICE, 
    finale.FFUUID_COUNTERTENORVOICE, 
    finale.FFUUID_MEZZOSOPRANOVOICE, 
    finale.FFUUID_SOPRANOVOICE, 
    finale.FFUUID_TALKBOX, 
    finale.FFUUID_TENORVOICE, 
    finale.FFUUID_VOCALPERCUSSION, 
    finale.FFUUID_VOCALS, 
    finale.FFUUID_VOICE, 
    finale.FFUUID_YODEL
}

--[[
% create_default_config

Many of the "create ensemble" plugins use the same configuration. This function
creates that configuration object.

: (table) the configuration object
]]
function score.create_default_config()
    local default_config = {
        use_large_time_signatures = false,
        use_large_measure_numbers = false,
        use_keyless_staves = false,
        show_default_whole_rests = true,
        score_page_width = "8.5i",
        score_page_height = "11i",
        part_page_width = "8.5i",
        part_page_height = "11i",
        systems_per_page = 1,
        max_measures_per_system = 0, -- 0 means "as many as possible"
        large_measure_number_space = "14s",
    }
    configuration.get_parameters("score_create_new_score_defaults.config.txt", default_config)
    return default_config
end

--[[
% delete_all_staves

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

--[[
% reset_and_clear_score

Resets and clears the score to begin creating a new ensemble
]]
function score.reset_and_clear_score()
    score.delete_all_staves()
end

--[[
% set_show_staff_time_signature

Sets whether or not to show the time signature on the staff.

@ staff_id (number) the staff_id for the staff
@ [show_time_signature] (boolean) whether or not to show the time signature, true if not specified

: (number) the staff_id for the staff
]]
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

--[[
% set_show_all_staves_time_signature

Sets whether or not to show the time signature on the staff.

@ [show_time_signature] (boolean) whether or not to show the time signature, true if not specified
]]
function score.set_show_all_staves_time_signature(show_time_signature)
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        score.set_show_staff_time_signature(staff:GetItemNo(), show_time_signature)
    end
end

--[[
% set_staff_transposition

Sets the transposition for a staff. Used for instruments that are not concert pitch (e.g., Bb Clarinet or F Horn)

@ staff_id (number) the staff_id for the staff
@ key (string) the key signature ("C", "F", "Bb", "C#" etc.)
@ interval (number) the interval number of steps to transpose the notes by
@ [clef] (string) the clef to set, "treble", "alto", "tenor", or "bass"

: (number) the staff_id for the staff
]]
function score.set_staff_transposition(staff_id, key, interval, clef)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.TransposeAlteration = KEY_MAP[key:lower()]
    staff.TransposeInterval = interval or 0
    if clef then
        staff.TransposeClefIndex = CLEF_MAP[clef]
        staff.TransposeUseClef = true
    end
    staff:Save()
    return staff_id
end

--[[
% set_staff_allow_hiding

Sets whether the staff is allowed to hide when it is empty.

@ staff_id (number) the staff_id for the staff
@ [allow_hiding] (boolean) whether or not to allow the staff to hide, true if not specified

: (number) the staff_id for the staff
]]
function score.set_staff_allow_hiding(staff_id, allow_hiding)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.AllowHiding = allow_hiding or true
    staff:Save()
    return staff_id
end

--[[
% set_staff_keyless

Sets whether or not the staff is keyless.

@ staff_id (number) the staff_id for the staff
@ [is_keyless] (boolean) whether the staff is keyless, true if not specified

: (number) the staff_id for the staff
]]
function score.set_staff_keyless(staff_id, is_keyless)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff.NoKeySigShowAccidentals = is_keyless or true
    staff:Save()
    return staff_id
end

--[[
% set_staff_keyless

Sets whether or not all staves are keyless.

@ [is_keyless] (boolean) whether the staff is keyless, true if not specified
]]
function score.set_all_staves_keyless(is_keyless)
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        score.set_staff_keyless(staff:GetItemNo(), is_keyless)
    end
end

--[[
% set_staff_show_default_whole_rests

Sets whether to show default whole rests on a particular staff.

@ staff_id (number) the staff_id for the staff
@ [show_whole_rests] (boolean) whether to show default whole rests, true if not specified

: (number) the staff_id for the staff
]]
function score.set_staff_show_default_whole_rests(staff_id, show_whole_rests)
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff:SetDisplayEmptyRests(show_whole_rests)
    staff:Save()
    return staff_id
end

--[[
% set_all_staves_show_default_whole_rests

Sets whether or not all staves show default whole rests.

@ [show_whole_rests] (boolean) whether to show default whole rests, true if not specified
]]
function score.set_all_staves_show_default_whole_rests(show_whole_rests)
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        score.set_staff_show_default_whole_rests(staff:GetItemNo(), show_whole_rests)
    end
end

--[[
% add_space_above_staff

This is the equivalent of "Add Vertical Space" in the Setup Wizard. It adds space above the staff as well as adds the staff to Staff List 1, which allows it to show tempo markings.

@ staff_id (number) the staff_id for the staff

: (number) the staff_id for the staff
]]
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

--[[
% set_staff_full_name

Sets the full name for the staff.

If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

@ staff (FCStaff) the staff
@ full_name (string) the full name to set
@ [double] (number) the number of the first instrument if two instruments share the staff
]]
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

--[[
% set_staff_short_name

Sets the abbreviated name for the staff.

If two instruments are on the same staff, this will also add the related numbers. For instance, if horn one and 2 are on the same staff, this will show Horn 1/2. `double` sets the first number. In this example, `double` should be `1` to show Horn 1/2. If the staff is for horn three and four, `double` should be `3`.

@ staff (FCStaff) the staff
@ short_name (string) the abbreviated name to set
@ [double] (number) the number of the first instrument if two instruments share the staff
]]
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

--[[
% create_staff

Creates a staff at the end of the score.

@ full_name (string) the abbreviated name
@ short_name (string) the abbreviated name
@ type (string) the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC)
@ clef (string) the clef for the staff (e.g., "treble", "bass", "tenor")
@ [double] (number) the number of the first instrument if two instruments share the staff

: (number) the staff_id for the new staff
]]
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

--[[
% create_staff_spaced

Creates a staff at the end of the score with a space above it. This is equivalent to using `score.create_staff` then `score.add_space_above_staff`.

@ full_name (string) the abbreviated name
@ short_name (string) the abbreviated name
@ type (string) the `__FCStaffBase` type (e.g., finale.FFUUID_TRUMPETC)
@ clef (string) the clef for the staff (e.g., "treble", "bass", "tenor")
@ [double] (number) the number of the first instrument if two instruments share the staff

: (number) the staff_id for the new staff
]]
function score.create_staff_spaced(full_name, short_name, type, clef)
    local staff_id = score.create_staff(full_name, short_name, type, clef)
    score.add_space_above_staff(staff_id)
    return staff_id
end

--[[
% create_staff_percussion

Creates a percussion staff at the end of the score.

@ full_name (string) the abbreviated name
@ short_name (string) the abbreviated name

: (number) the staff_id for the new staff
]]
function score.create_staff_percussion(full_name, short_name)
    local staff_id = score.create_staff(full_name, short_name, finale.FFUUID_PERCUSSIONGENERAL, "percussion")
    local staff = finale.FCStaff()
    staff:Load(staff_id)
    staff:SetNotationStyle(finale.STAFFNOTATION_PERCUSSION)
    staff:SavePercussionLayout(1, 0)
    return staff_id
end

--[[
% create_group

Creates a percussion staff at the end of the score.

@ start_staff (number) the staff_id for the first staff
@ end_staff (number) the staff_id for the last staff
@ brace_name (string) the name for the brace (e.g., "none", "plain", "piano")
@ has_barline (boolean) whether or not barlines should continue through all staves in the group
@ level (number) the indentation level for the group bracket
@ [full_name] (string) the full name for the group
@ [short_name] (string) the abbreviated name for the group
]]
function score.create_group(start_staff, end_staff, brace_name, has_barline, level, full_name, short_name)
    local sg_cmper = {}
    local staff_groups = finale.FCGroups()
    staff_groups:LoadAll()
    for sg in each(staff_groups) do
        table.insert(sg_cmper, sg:GetItemID())
    end
    table.sort(sg_cmper)
    local sg = finale.FCGroup()
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

    local bracket_position = -12 * level
    if brace_name == "desk" then
        bracket_position = bracket_position - 6
    end
    sg:SetBracketHorizontalPos(bracket_position)

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

--[[
% create_group_primary

Creates a primary group with the "curved_chorus" bracket.

@ start_staff (number) the staff_id for the first staff
@ end_staff (number) the staff_id for the last staff
@ [full_name] (string) the full name for the group
@ [short_name] (string) the abbreviated name for the group
]]
function score.create_group_primary(start_staff, end_staff, full_name, short_name)
    score.create_group(start_staff, end_staff, "curved_chorus", true, 1, full_name, short_name)
end

--[[
% create_group_secondary

Creates a primary group with the "desk" bracket.

@ start_staff (number) the staff_id for the first staff
@ end_staff (number) the staff_id for the last staff
@ [full_name] (string) the full name for the group
@ [short_name] (string) the abbreviated name for the group
]]
function score.create_group_secondary(start_staff, end_staff, full_name, short_name)
    score.create_group(start_staff, end_staff, "desk", false, 2, full_name, short_name)
end

--[[
% calc_system_scalings

_EXPERIMENTAL_

Calculates the system scaling to fit the desired number of systems on each page.

Currently produces the incorrect values. Should not be used in any production-ready
scripts.

@ systems_per_page (number) the number of systems that should fit on each page

: (number, number) the desired scaling factors—first_page_scaling, global_scaling
]]
function score.calc_system_scalings(systems_per_page)
    local score_page_format_prefs = finale.FCPageFormatPrefs()
    score_page_format_prefs:LoadScore()
    local page_height = score_page_format_prefs:GetPageHeight()
    local margin_top = score_page_format_prefs:GetLeftPageTopMargin()
    local margin_bottom = score_page_format_prefs:GetLeftPageBottomMargin()
    local available_height = page_height - margin_top - margin_bottom

    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    -- use first staff and not second in case second is not defined
    local system = staff_systems:GetItemAt(0)
    local first_system_height = system:CalcHeight(false)
    -- update margins to use second system height
    local system_height = first_system_height
    system_height = system_height - score_page_format_prefs:GetFirstSystemTop()
    system_height = system_height + score_page_format_prefs:GetSystemTop()
    -- apply staff scaling
    local staff_height = score_page_format_prefs:GetSystemStaffHeight() / 16
    local staff_scaling = staff_height / measurement.convert_to_EVPUs("4s")
    first_system_height = first_system_height * staff_scaling
    system_height = system_height * staff_scaling

    local total_systems_height = (system_height * (systems_per_page or 1))
    local first_page_total_systems_height = first_system_height + total_systems_height - system_height
    local global_scaling = available_height / total_systems_height
    local first_page_scaling = available_height / first_page_total_systems_height

    return math.floor(first_page_scaling * 100), math.floor(global_scaling * 100)
end

--[[
% set_global_system_scaling

Sets the system scaling for every system in the score.

@ scaling (number) the scaling factor
]]
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

--[[
% set_global_system_scaling

Sets the system scaling for a specific system in the score.

@ system_number (number) the system number to set the scaling for
@ scaling (number) the scaling factor
]]
function score.set_single_system_scaling(system_number, scaling)
    local staff_systems = finale.FCStaffSystems()
    staff_systems:LoadAll()
    local system = staff_systems:GetItemAt(system_number)
    if system then
        system:SetResize(scaling)
        system:Save()
    end
end

--[[
% set_large_time_signatures_settings

Updates the document settings for large time signatures.
]]
function score.set_large_time_signatures_settings()
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

--[[
% use_large_time_signatures

Sets the system scaling for a specific system in the score.

@ uses_large_time_signatures (boolean) the system number to set the scaling for
@ staves_with_time_signatures (table) a table where all values are the staff_id for every staff with a time signature
]]
function score.use_large_time_signatures(uses_large_time_signatures, staves_with_time_signatures)
    if not uses_large_time_signatures then
        return
    end
    score.set_large_time_signatures_settings()
    score.set_show_all_staves_time_signature(false)
    for _, staff_id in ipairs(staves_with_time_signatures) do
        score.set_show_staff_time_signature(staff_id, true)
    end
end

--[[
% use_large_measure_numbers

Adds large measure numbers below every measure in the score.

@ distance (string) the distance between the bottom staff and the measure numbers (e.g., "12s" for 12 spaces)
]]
function score.use_large_measure_numbers(distance)
    local systems = finale.FCStaffSystem()
    systems:Load(1)

    local font_size = 0
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

        font_size = font:GetSize()
    end

    -- extend bottom system margin to cover measure numbers if needed
    local score_page_format_prefs = finale.FCPageFormatPrefs()
    score_page_format_prefs:LoadScore()
    local system_margin_bottom = score_page_format_prefs:GetSystemBottom()
    local needed_margin = font_size * 4 + measurement.convert_to_EVPUs(distance)
    if system_margin_bottom < needed_margin then
        score_page_format_prefs:SetSystemBottom(needed_margin)
        score_page_format_prefs:Save()

        local staff_systems = finale.FCStaffSystems()
        staff_systems:LoadAll()
        for staff_system in each(staff_systems) do
            staff_system:SetBottomMargin(needed_margin)
            staff_system:Save()
        end
    end
end

--[[
% set_max_measures_per_system

Sets the maximum number of measures per system.

@ max_measures_per_system (number) maximum number of measures per system
]]
function score.set_max_measures_per_system(max_measures_per_system)
    if max_measures_per_system == 0 then
        return
    end
    local score_page_format_prefs = finale.FCPageFormatPrefs()
    score_page_format_prefs:LoadScore()
    local page_width = score_page_format_prefs:GetPageWidth()
    local page_margin_left = score_page_format_prefs:GetLeftPageLeftMargin()
    local page_margin_right = score_page_format_prefs:GetLeftPageRightMargin()
    local system_width = page_width - page_margin_left - page_margin_right

    local format = finale.FCPageFormatPrefs()
    format:LoadScore()
    local system_scaling = format:GetSystemScaling()

    local scaled_system_width = system_width / (system_scaling / 100)

    local music_spacing_preferences = finale.FCMusicSpacingPrefs()
    music_spacing_preferences:Load(1)
    music_spacing_preferences:SetMinMeasureWidth(scaled_system_width / max_measures_per_system)
    music_spacing_preferences:Save()
end

--[[
% set_score_page_size

Sets the score page size.

@ width (string) the page height (e.g., "8.5i" for 8.5 inches)
@ height (string) the page width (e.g., "11i" for 11 inches)
]]
function score.set_score_page_size(width, height)
    local score_page_format_prefs = finale.FCPageFormatPrefs()
    score_page_format_prefs:LoadScore()
    score_page_format_prefs.PageWidth = measurement.convert_to_EVPUs(width)
    score_page_format_prefs.PageHeight = measurement.convert_to_EVPUs(height)
    score_page_format_prefs:Save()

    local pages = finale.FCPages()
    pages:LoadAll()
    for page in each(pages) do
        page:SetWidth(measurement.convert_to_EVPUs(width))
        page:SetHeight(measurement.convert_to_EVPUs(height))
    end
    pages:SaveAll()
end

--[[
% set_all_parts_page_size

Sets the page size for all parts.

@ width (string) the page height (e.g., "8.5i" for 8.5 inches)
@ height (string) the page width (e.g., "11i" for 11 inches)
]]
function score.set_all_parts_page_size(width, height)
    local part_page_format_prefs = finale.FCPageFormatPrefs()
    part_page_format_prefs:LoadParts()
    part_page_format_prefs.PageWidth = measurement.convert_to_EVPUs(width)
    part_page_format_prefs.PageHeight = measurement.convert_to_EVPUs(height)
    part_page_format_prefs:Save()

    local parts = finale.FCParts()
    parts:LoadAll()
    local pages = finale.FCPages()
    for part in each(parts) do
        part:SwitchTo()
        if not part:IsScore() then
            pages:LoadAll()
            for page in each(pages) do
                page:SetWidth(measurement.convert_to_EVPUs(width))
                page:SetHeight(measurement.convert_to_EVPUs(height))
            end
            pages:SaveAll()
        end
    end
end

--[[
% apply_config

When creating an ensemble, this function is used to apply the configuration.

The inputted config file must have a all the fields in the default config file
(created with `score.create_default_config`).

The options field must contain the following items:

- `force_staves_show_time_signatures` (table) a table where all values are the staff_id for every staff with a time signature
used if `uses_large_time_signatures` is true

@ config (table) the config file
@ options (table) ensemble-specific options
]]
function score.apply_config(config, options)  -- luacheck: ignore config
    score.set_score_page_size(config.score_page_width, config.score_page_height)
    score.set_all_parts_page_size(config.part_page_width, config.part_page_height)
    library.update_layout()
    score.set_all_staves_keyless(config.use_keyless_staves)
    score.set_all_staves_show_default_whole_rests(config.show_default_whole_rests)
    score.use_large_time_signatures(config.use_large_time_signatures, options.force_staves_show_time_signatures)

    if config.use_large_measure_numbers then
        score.use_large_measure_numbers(config.large_measure_number_space)
    end

    local first_page_scaling, global_scaling = score.calc_system_scalings(config.systems_per_page)
    score.set_global_system_scaling(global_scaling)
    for i = 0, config.systems_per_page - 1, 1 do
        score.set_single_system_scaling(i, first_page_scaling)
    end
    score.set_max_measures_per_system(config.max_measures_per_system)
    library.update_layout()
end

--[[
% calc_voice_staff

Determines whether the staff is a voice instrument.

@ staff_num (number) The number of the staff to check.
: (boolean) True if the staff is a voice instrument.
]]
function score.calc_voice_staff(staff_num)
    local is_voice_staff = false
    local staff = finale.FCStaff()
    if staff:Load(staff_num) then
        local staff_instrument = staff:GetInstrumentUUID()
        local test = finale.FFUID_YODEL
        for k, v in pairs(VOICE_INSTRUMENTS) do
            if staff_instrument == v then
                is_voice_staff = true
            end
        end
    end
    return is_voice_staff
end

return score
