function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Version = "220718"
    finaleplugin.Date = "07/218/2022"
    return "JetStream Finale Controller", "JetStream Finale Controller", "Input four digit codes to access JetStream Finale Controller features."
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = path.LuaString .. "?.lua;" .. package.path

function add_library_directory()
    local is_on_windows = finenv.UI():IsOnWindows()
    local do_getenv = function(win_var, mac_var)
        if finenv.UI():IsOnWindows() then
            return win_var and os.getenv(win_var) or ""
        else
            return mac_var and os.getenv(mac_var) or ""
        end
    end
    local library_directory = do_getenv("COMMONPROGRAMFILES", "HOME") or do_getenv("LOCALAPPDATA") -- borrowed from library SMuFL function, but swapped COMMONPROGRAMFILES and LOCALAPPDATA
    if not is_on_windows then
        library_directory = library_directory .. [[/Library/Application Support/JetStream Finale Controller/lua_libraries/?.lua;/Library/Application Support]]
    end
    library_directory = library_directory .. "/JetStream Finale Controller/lua_libraries/"
    package.path = library_directory .. [[?.lua;]] .. package.path
end
add_library_directory()

local library = require("library.general_library")
local configuration = require("library.configuration")
require("jetstream_config")
--
config = {
    tacet_text = "Tacet",
    al_fine_text = "Tacet al fine",
    play_x_bars_prefix = "PLAY",
    play_x_bars_suffix = "BARS",
    play_x_more_prefix = "PLAY",
    play_x_more_suffix = "MORE",
    dynamic_L_cushion = 18,
    dynamic_R_cushion = 18,
    noteentry_cushion = 30,
    staff_cushion = 40,
    dynamic_above_cushion = 24,
    nudge_normal = 12,
    nudge_large = 24,
    x_type = 0,
    lyrics_all = "true",
}

configuration.get_user_settings("jetstream_config", config, create_automatically)
--
local init_region = finenv.Region()
init_region:SetCurrentSelection()

function run_file(filename)
    local is_on_windows = finenv.UI():IsOnWindows()
    local do_getenv = function(win_var, mac_var)
        if finenv.UI():IsOnWindows() then
            return win_var and os.getenv(win_var) or ""
        else
            return mac_var and os.getenv(mac_var) or ""
        end
    end
    local library_directory = do_getenv("COMMONPROGRAMFILES", "HOME") or do_getenv("LOCALAPPDATA") -- borrowed from library SMuFL function, but swapped COMMONPROGRAMFILES and LOCALAPPDATA
    if not is_on_windows then
        library_directory = "/Library/Application Support/" -- I know I'm overriding  the os.getenv stuff above... but this is what I need :)
    end
    library_directory = library_directory .. "/JetStream Finale Controller/lua_libraries/"
    dofile(library_directory .. filename .. ".lua")
end

function split(s, delimiter)
    result = {};
    if s == nil then
        s = ""
    end
    for match in (s .. delimiter):gmatch("(.-)" .. delimiter) do
        match = string.lower(match)
        if match ~= "" then
            table.insert(result, match);
        end
    end
    return result;
end

function trim(s)
    return s:match "^()%s*$" and "" or s:match "^%s*(.*%S)"
end

function compare_values(source, compare_to)
    local result = false
    for i, k in pairs(compare_to) do
        if source == compare_to[i] then
            result = true
        end
    end
    return result
end

function simple_input(title, text)
    local return_value = finale.FCString()
    return_value.LuaString = ""
    local str = finale.FCString()
    local min_width = 160

    function format_ctrl(ctrl, h, w, st)
        ctrl:SetHeight(h)
        ctrl:SetWidth(w)
        str.LuaString = st
        ctrl:SetText(str)
    end

    title_width = string.len(title) * 6 + 54
    if title_width > min_width then
        min_width = title_width
    end
    text_width = string.len(text) * 6
    if text_width > min_width then
        min_width = text_width
    end

    str.LuaString = title
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(str)
    local descr = dialog:CreateStatic(0, 0)
    format_ctrl(descr, 16, min_width, text)
    local input = dialog:CreateEdit(0, 20)
    format_ctrl(input, 20, min_width, "")
    local ok = dialog:CreateOkButton()
    str.LuaString = "OK"
    ok:SetText(str)
    dialog:CreateCancelButton()

    function callback(ctrl)
    end

    dialog:RegisterHandleCommand(callback)
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        return_value.LuaString = input:GetText(return_value)
        return return_value.LuaString
    end
end

function get_region(per_system_bool)
    local single_region = {}
    local music_region = finale.FCMusicRegion()
    music_region:SetCurrentSelection()

    local first_meas = music_region:GetStartMeasure()
    local last_meas = music_region:GetEndMeasure()

    local system_measure_span = {}
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    systems:LoadAll()

    for system in each(systems) do
        local sys_first = system:GetFirstMeasure()
        local sys_last = system:GetNextSysMeasure() - 1
        local measure_att = finale.FCMeasure()
        if ((system:ContainsMeasure(first_meas)) and (system:ContainsMeasure(last_meas) == false)) then
            measure_att:Load(sys_last)
            table.insert(system_measure_span, {first_meas, sys_last, music_region:GetStartMeasurePos(), measure_att:GetDuration()})
        end
        if ((system:ContainsMeasure(first_meas) == false) and (system:ContainsMeasure(last_meas))) then
            table.insert(system_measure_span, {sys_first, last_meas, 0, music_region:GetEndMeasurePos()})
        end
        if ((system:ContainsMeasure(first_meas)) and (system:ContainsMeasure(last_meas))) then
            table.insert(system_measure_span, {first_meas, last_meas, music_region:GetStartMeasurePos(), music_region:GetEndMeasurePos()})
        end
        if ((system:ContainsMeasure(first_meas) == false) and (system:ContainsMeasure(last_meas) == false)) then
            if (sys_first > first_meas) and (sys_last < last_meas) then
                measure_att:Load(sys_last)
                table.insert(system_measure_span, {sys_first, sys_last, 0, measure_att:GetDuration()})
            end
        end
    end

    local music_regions = {}

    for k, v in pairs(system_measure_span) do
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            local staff_num = staff:GetItemNo()
            if music_region:IsStaffIncluded(staff_num) then
                local individual_region = finale.FCMusicRegion()
                individual_region:SetStartStaff(staff_num)
                individual_region:SetEndStaff(staff_num)
                individual_region:SetStartMeasure(v[1])
                individual_region:SetEndMeasure(v[2])
                individual_region:SetStartMeasurePos(v[3])
                individual_region:SetEndMeasurePos(v[4])
                table.insert(music_regions, individual_region)
            end
        end
    end

    local return_region = nil

    if per_system_bool then
        return_region = music_regions
    else
        local staves = finale.FCStaves()
        staves:LoadAll()
        for staff in each(staves) do
            local staff_num = staff:GetItemNo()
            if music_region:IsStaffIncluded(staff_num) then
                local individual_single_region = finale.FCMusicRegion()
                individual_single_region:SetCurrentSelection()
                individual_single_region:SetStartStaff(staff_num)
                individual_single_region:SetEndStaff(staff_num)
                table.insert(single_region, individual_single_region)
            end
        end
        return_region = single_region
    end

    return return_region

end

function to_EVPUs(text)
    local str = finale.FCString()
    str.LuaString = text
    return str:GetMeasurement(finale.MEASUREMENTUNIT_DEFAULT)
end

function getUsedFontName(standard_name)
    local font_name = standard_name
    if string.find(os.tmpname(), "/") then
        font_name = standard_name
    elseif string.find(os.tmpname(), "\\") then
        font_name = string.gsub(standard_name, "%s", "")
    end
    return font_name
end

function check_SMuFL(what_to_check)
    local font_check = {"Maestro", "Engraver Font Set", "Broadway Copyist", "Jazz"}
    local is_SMuFL = true
    if what_to_check ~= nil then
        if what_to_check[1] == "Expression" then
            local cd = finale.FCCategoryDef()
            if cd:Load(what_to_check[2]) then
                local fontinfo = finale.FCFontInfo()
                if cd:GetMusicFontInfo(fontinfo) then
                    for k, v in pairs(font_check) do
                        if fontinfo:GetName() == getUsedFontName(v) then
                            is_SMuFL = false
                            break
                        end
                    end
                end
            end
        end
    else
        local fontinfo = finale.FCFontInfo()
        if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
            for k, v in pairs(font_check) do
                if fontinfo:GetName() == getUsedFontName(v) then
                    is_SMuFL = false
                    break
                end
            end
        end
    end

    return is_SMuFL
end

function get_def_mus_font()
    local fontinfo = finale.FCFontInfo()
    if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
        return getUsedFontName(fontinfo:GetName())
    end
end

local default_music_font = get_def_mus_font()

local full_art_table = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}

function tremolo_assignment(tremolo_type)
    if tremolo_type == "metered tremolo" then
        for noteentry in eachentrysaved(finenv.Region()) do
            if noteentry:IsNote() then
                local articulation = finale.FCArticulation()
                articulation:SetNoteEntry(noteentry)
                if noteentry.Duration < 512 then
                    articulation:SetID(full_art_table[7])
                    articulation:SaveNew()
                elseif (noteentry.Duration >= 512) and (noteentry.Duration < 1024) then
                    articulation:SetID(full_art_table[8])
                    articulation:SaveNew()
                elseif noteentry.Duration >= 1024 then
                    articulation:SetID(full_art_table[9])
                    articulation:SaveNew()
                end
            end
        end
    else
        for noteentry in eachentrysaved(finenv.Region()) do
            if noteentry:IsNote() then
                local articulation = finale.FCArticulation()
                articulation:SetNoteEntry(noteentry)
                articulation:SetID(tremolo_type)
                articulation:SaveNew()
            end
        end
    end
end

function roll_articulation_assignment(defualt_roll_num)

    local has_acc = false
    local is_polyphony = false
    for note_entry in eachentry(finenv.Region()) do
        has_acc = false
        is_polyphony = false
        for note in each(note_entry) do
            if (note:CalcAccidental()) then
                has_acc = true
            end
        end
        if note_entry:GetCount() > 1 then
            is_polyphony = true
        end
        if is_polyphony then
            if has_acc then
                local entry_artics = note_entry:CreateArticulations()
                entry_artics:LoadAll()
                for art in each(entry_artics) do
                    local art_def = art:CreateArticulationDef()
                    if (art_def:GetAboveSymbolChar() == defualt_roll_num) then
                        local entry_metrics = finale.FCEntryMetrics()
                        if note_entry:IsNote() then
                            local arg_point = finale.FCPoint(0, 0)
                            entry_metrics:Load(note_entry)
                            local artic_pos = 0
                            if note_entry:CalcStemUp() then
                                artic_pos = entry_metrics:GetStemLeftPosition() - note_entry:CalcWidestNoteheadWidth()
                            else
                                artic_pos = entry_metrics:GetStemLeftPosition() - 6
                            end
                            local roll_cushion = 9
                            local accidental_pos = entry_metrics:GetFirstAccidentalPosition()
                            local distance = artic_pos - entry_metrics:GetFirstAccidentalPosition()
                            art:SetHorizontalPos(0 - (distance + roll_cushion))
                            art:Save()
                        end
                    end
                end
            end
        end
    end
end

function assignArticulation(art_id)
    if (art_id == "metered tremolo") or (art_id == full_art_table[7]) or (art_id == full_art_table[8]) or (art_id == full_art_table[9]) then
        tremolo_assignment(art_id)
    else
        for noteentry in eachentrysaved(finenv.Region()) do
            local a = finale.FCArticulation()
            a:SetNoteEntry(noteentry)
            local ad = finale.FCArticulationDef()
            if (art_id == full_art_table[20]) or (art_id == full_art_table[21]) or (art_id == full_art_table[25]) or (art_id == full_art_table[26]) then
                if (noteentry:IsNote()) and (noteentry:IsTied() == false) then
                    a:SetID(art_id)
                    a:SaveNew()
                end
            elseif (art_id == full_art_table[12]) or (art_id == full_art_table[11]) then
                if noteentry:IsNote() then
                    a:SetID(art_id)
                    a:SaveNew()
                end
            else
                if (noteentry:IsNote()) and (noteentry:IsTiedBackwards() == false) then
                    a:SetID(art_id)
                    a:SaveNew()
                else
                    if ad:GetAboveSymbolChar() == 85 then
                        a:SetID(art_id)
                        a:SaveNew()
                    end
                end
            end
        end
    end
end

function assignNewArticulation(noteentry, art_id)
    local a = finale.FCArticulation()
    a:SetNoteEntry(noteentry)
    if (art_id == full_art_table[27]) or (art_id == full_art_table[28]) or (art_id == full_art_table[29]) or (art_id == full_art_table[30]) then
        if noteentry:IsTiedBackwards() == false then
            a:SetID(art_id)
            a:SaveNew()
        end
    elseif (art_id == full_art_table[31]) or (art_id == full_art_table[32]) or (art_id == full_art_table[33]) or (art_id == full_art_table[34]) then
        if noteentry:IsTied() == false then
            a:SetID(art_id)
            a:SaveNew()
        end
    elseif noteentry:IsTiedBackwards() == false then
        a:SetID(art_id)
        a:SaveNew()
    end
end

function createArticulation(table_placement, MainSymbolChar, MainSymbolFont, AboveSymbolChar, AboveUsesMain, AlwaysPlaceOutsideStaff, AttachToTopNote, AttackIsPercent, AutoPosSide,
                            AvoidStaffLines, BelowSymbolChar, BelowUsesMain, BottomAttack, BottomDuration, BottomVelocity, CenterHorizontally, CopyMainSymbol,
                            CopyMainSymbolHorizontally, DefaultVerticalPos, DurationIsPercent, MainHandleHorizontalOffset, MainHandleVerticalOffset, FlippedHandleHorizontalOffset,
                            FlippedHandleVerticalOffset, FlippedSymbolChar, FlippedSymbolFont, InsideSlurs, OnScreenOnly, Playback, TopAttack, TopDuration, TopVelocity,
                            VelocityIsPercent, fm_Absolute, fm_Bold, fm_EnigmaStyles, fm_Hidden, fm_Italic, fm_Name, fm_Size, fm_SizeFloat, fm_StrikeOut, fm_Underline, ff_Absolute,
                            ff_Bold, ff_EnigmaStyles, ff_Hidden, ff_Italic, ff_Name, ff_Size, ff_SizeFloat, ff_StrikeOut, ff_Underline)
    local ad = finale.FCArticulationDef()
    ad:SetMainSymbolChar(MainSymbolChar)
    ad:SetMainSymbolFont(MainSymbolFont)
    ad:SetAboveSymbolChar(AboveSymbolChar)
    ad:SetAboveUsesMain(AboveUsesMain)
    ad:SetAlwaysPlaceOutsideStaff(AlwaysPlaceOutsideStaff)
    ad:SetAttachToTopNote(AttachToTopNote)
    ad:SetAttackIsPercent(AttackIsPercent)
    ad:SetAutoPosSide(AutoPosSide)
    ad:SetAvoidStaffLines(AvoidStaffLines)
    -- ad:SetBelowSymbolChar(BelowSymbolChar)
    ad:SetBelowUsesMain(BelowUsesMain)
    ad:SetBottomAttack(BottomAttack)
    ad:SetBottomDuration(BottomDuration)
    ad:SetBottomVelocity(BottomVelocity)
    ad:SetCenterHorizontally(CenterHorizontally)
    ad:SetCopyMainSymbol(CopyMainSymbol)
    ad:SetCopyMainSymbolHorizontally(CopyMainSymbolHorizontally)
    ad:SetDefaultVerticalPos(DefaultVerticalPos)
    ad:SetDurationIsPercent(DurationIsPercent)
    ad:SetMainHandleHorizontalOffset(MainHandleHorizontalOffset)
    ad:SetMainHandleVerticalOffset(MainHandleVerticalOffset)
    ad:SetFlippedHandleHorizontalOffset(FlippedHandleHorizontalOffset)
    ad:SetFlippedHandleVerticalOffset(FlippedHandleVerticalOffset)
    ad:SetFlippedSymbolChar(FlippedSymbolChar)
    ad:SetFlippedSymbolFont(FlippedSymbolFont)
    ad:SetInsideSlurs(InsideSlurs)
    ad:SetOnScreenOnly(OnScreenOnly)
    ad:SetPlayback(Playback)
    ad:SetTopAttack(TopAttack)
    ad:SetTopDuration(TopDuration)
    ad:SetTopVelocity(TopVelocity)
    ad:SetVelocityIsPercent(VelocityIsPercent)
    local fonti = ad:CreateMainSymbolFontInfo()
    fonti:SetAbsolute(fm_Absolute)
    fonti:SetBold(fm_Bold)
    fonti:SetEnigmaStyles(fm_EnigmaStyles)
    fonti:SetHidden(fm_Hidden)
    fonti:SetItalic(fm_Italic)
    fonti:SetName(fm_Name)
    fonti:SetSize(fm_Size)
    fonti:SetSizeFloat(fm_SizeFloat)
    fonti:SetStrikeOut(fm_StrikeOut)
    fonti:SetUnderline(fm_Underline)
    ad:SetMainSymbolFontInfo(fonti)
    local fontif = ad:CreateFlippedSymbolFontInfo()
    fontif:SetAbsolute(ff_Absolute)
    fontif:SetBold(ff_Bold)
    fontif:SetEnigmaStyles(ff_EnigmaStyles)
    fontif:SetHidden(ff_Hidden)
    fontif:SetItalic(ff_Italic)
    fontif:SetName(ff_Name)
    fontif:SetSize(ff_Size)
    fontif:SetSizeFloat(ff_SizeFloat)
    fontif:SetStrikeOut(ff_StrikeOut)
    fontif:SetUnderline(ff_Underline)
    ad:SetFlippedSymbolFontInfo(fontif)
    ad:SaveNew()
    full_art_table[table_placement] = ad:GetItemNo()
    assignArticulation(full_art_table[table_placement])
end

function createNewArticulation(table_placement, MainSymbolChar, MainSymbolFont, AboveSymbolChar, AboveUsesMain, AlwaysPlaceOutsideStaff, AttachToTopNote, AttackIsPercent,
                               AutoPosSide, AvoidStaffLines, BelowSymbolChar, BelowUsesMain, BottomAttack, BottomDuration, BottomVelocity, CenterHorizontally, CopyMainSymbol,
                               CopyMainSymbolHorizontally, DefaultVerticalPos, DurationIsPercent, MainHandleHorizontalOffset, MainHandleVerticalOffset,
                               FlippedHandleHorizontalOffset, FlippedHandleVerticalOffset, FlippedSymbolChar, FlippedSymbolFont, InsideSlurs, OnScreenOnly, Playback, TopAttack,
                               TopDuration, TopVelocity, VelocityIsPercent, fm_Absolute, fm_Bold, fm_EnigmaStyles, fm_Hidden, fm_Italic, fm_Name, fm_Size, fm_SizeFloat,
                               fm_StrikeOut, fm_Underline, ff_Absolute, ff_Bold, ff_EnigmaStyles, ff_Hidden, ff_Italic, ff_Name, ff_Size, ff_SizeFloat, ff_StrikeOut, ff_Underline)
    local ad = finale.FCArticulationDef()
    ad:SetMainSymbolChar(MainSymbolChar)
    ad:SetMainSymbolFont(MainSymbolFont)
    ad:SetAboveSymbolChar(AboveSymbolChar)
    ad:SetAboveUsesMain(AboveUsesMain)
    ad:SetAlwaysPlaceOutsideStaff(AlwaysPlaceOutsideStaff)
    ad:SetAttachToTopNote(AttachToTopNote)
    ad:SetAttackIsPercent(AttackIsPercent)
    ad:SetAutoPosSide(AutoPosSide)
    ad:SetAvoidStaffLines(AvoidStaffLines)
    -- ad:SetBelowSymbolChar(BelowSymbolChar)
    ad:SetBelowUsesMain(BelowUsesMain)
    ad:SetBottomAttack(BottomAttack)
    ad:SetBottomDuration(BottomDuration)
    ad:SetBottomVelocity(BottomVelocity)
    ad:SetCenterHorizontally(CenterHorizontally)
    ad:SetCopyMainSymbol(CopyMainSymbol)
    ad:SetCopyMainSymbolHorizontally(CopyMainSymbolHorizontally)
    ad:SetDefaultVerticalPos(DefaultVerticalPos)
    ad:SetDurationIsPercent(DurationIsPercent)
    ad:SetMainHandleHorizontalOffset(MainHandleHorizontalOffset)
    ad:SetMainHandleVerticalOffset(MainHandleVerticalOffset)
    ad:SetFlippedHandleHorizontalOffset(FlippedHandleHorizontalOffset)
    ad:SetFlippedHandleVerticalOffset(FlippedHandleVerticalOffset)
    ad:SetFlippedSymbolChar(FlippedSymbolChar)
    ad:SetFlippedSymbolFont(FlippedSymbolFont)
    ad:SetInsideSlurs(InsideSlurs)
    ad:SetOnScreenOnly(OnScreenOnly)
    ad:SetPlayback(Playback)
    ad:SetTopAttack(TopAttack)
    ad:SetTopDuration(TopDuration)
    ad:SetTopVelocity(TopVelocity)
    ad:SetVelocityIsPercent(VelocityIsPercent)
    local fonti = ad:CreateMainSymbolFontInfo()
    fonti:SetAbsolute(fm_Absolute)
    fonti:SetBold(fm_Bold)
    fonti:SetEnigmaStyles(fm_EnigmaStyles)
    fonti:SetHidden(fm_Hidden)
    fonti:SetItalic(fm_Italic)
    fonti:SetName(fm_Name)
    fonti:SetSize(fm_Size)
    fonti:SetSizeFloat(fm_SizeFloat)
    fonti:SetStrikeOut(fm_StrikeOut)
    fonti:SetUnderline(fm_Underline)
    ad:SetMainSymbolFontInfo(fonti)
    local fontif = ad:CreateFlippedSymbolFontInfo()
    fontif:SetAbsolute(ff_Absolute)
    fontif:SetBold(ff_Bold)
    fontif:SetEnigmaStyles(ff_EnigmaStyles)
    fontif:SetHidden(ff_Hidden)
    fontif:SetItalic(ff_Italic)
    fontif:SetName(ff_Name)
    fontif:SetSize(ff_Size)
    fontif:SetSizeFloat(ff_SizeFloat)
    fontif:SetStrikeOut(ff_StrikeOut)
    fontif:SetUnderline(ff_Underline)
    ad:SetFlippedSymbolFontInfo(fontif)
    ad:SaveNew()
    full_art_table[table_placement] = ad:GetItemNo()
end

function deleteArticulation(id_num)
    for noteentry in eachentrysaved(finenv.Region()) do
        local artics = noteentry:CreateArticulations()
        for a in eachbackwards(artics) do
            local defs = a:CreateArticulationDef()
            if defs:GetItemNo() == id_num then
                a:DeleteData()
            end
        end
    end
end

function deleteNewArticulation(noteentry, id_num)
    local artics = noteentry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetItemNo() == id_num then
            a:DeleteData()
        end
    end
end

function addArticulation(art_id)
    local artic_ids = {}
    for noteentry in eachentrysaved(finenv.Region()) do
        local artics = noteentry:CreateArticulations()
        for a in each(artics) do
            local defs = a:CreateArticulationDef()
            table.insert(artic_ids, defs:GetItemNo())
        end
    end

    local found_artic = 0

    for key, value in pairs(artic_ids) do
        if value == art_id then
            found_artic = 1
        end
    end

    if found_artic ~= 0 then
        deleteArticulation(art_id)
    else
        assignArticulation(art_id)
    end
end

function addNewArticulation(note_entry, art_id)
    local artic_ids = {}
    local artics = note_entry:CreateArticulations()
    for a in each(artics) do
        local defs = a:CreateArticulationDef()
        table.insert(artic_ids, defs:GetItemNo())
    end

    local found_artic = 0

    for key, value in pairs(artic_ids) do
        if value == art_id then
            found_artic = 1
        end
    end

    if found_artic ~= 0 then
        deleteNewArticulation(note_entry, art_id)
    else
        assignNewArticulation(note_entry, art_id)
    end
end

function findArticulation(table_placement, AboveSymbolChar, font_name)
    local articulationdefs = finale.FCArticulationDefs()
    articulationdefs:LoadAll()
    local first_id_table = {}
    for ad in each(articulationdefs) do
        if font_name == "" then
            if (ad:GetAboveSymbolChar() == AboveSymbolChar) then
                table.insert(first_id_table, ad.ItemNo)
            end
        else
            if (ad:GetAboveSymbolChar() == AboveSymbolChar) and (ad:GetMainSymbolFont() == font_name) then
                table.insert(first_id_table, ad.ItemNo)
            end
        end
    end
    if first_id_table[1] ~= nil then
        full_art_table[table_placement] = first_id_table[1]
    end
end

function articulations_lv_poly()
    local region = finenv.Region()
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local sys_staves = finale.FCSystemStaves()
    sys_staves:LoadAllForRegion(region)

    local lv_up = 0
    local lv_down = 0
    local lv_auto = 0
    local articulationdefs = finale.FCArticulationDefs()

    local horz = 39
    local vert = 0
    avoid = false
    auto_avoid = true

    articulationdefs:LoadAll()
    for ad in each(articulationdefs) do
        if (ad:GetMainSymbolFont() == "Engraver Font Set") then
            if (ad:GetAboveSymbolChar() == 105 and ad:GetBelowSymbolChar() == 105 and ad.AvoidStaffLines == avoid) then
                lv_up = ad.ItemNo
            elseif (ad:GetAboveSymbolChar() == 73 and ad:GetBelowSymbolChar() == 73 and ad.AvoidStaffLines == avoid) then
                lv_down = ad.ItemNo
            elseif (ad:GetAboveSymbolChar() == 105 and ad:GetBelowSymbolChar() == 73 and ad.AvoidStaffLines == auto_avoid) then
                lv_auto = ad.ItemNo
            end
        end
    end
    if lv_up == 0 then
        local ad = finale.FCArticulationDef()
        ad.MainSymbolChar = 105
        ad.MainSymbolFont = "Engraver Font Set"
        ad.MainSymbolIsShape = false
        ad.MainSymbolSize = 24
        ad.FlippedSymbolChar = 105
        ad.FlippedSymbolFont = "Engraver Font Set"
        ad.FlippedSymbolIsShape = false
        ad.FlippedSymbolSize = 24
        ad.AboveSymbolChar = 105
        ad.AboveUsesMain = true
        ad.BelowSymbolChar = 105
        ad.BelowUsesMain = true

        ad.DefaultVerticalPos = 0
        ad.MainHandleHorizontalOffset = horz
        ad.MainHandleVerticalOffset = vert
        ad.FlippedHandleHorizontalOffset = horz
        ad.FlippedHandleVerticalOffset = vert

        ad.AlwaysPlaceOutsideStaff = false
        ad.AttachToTopNote = false
        ad.AutoPosSide = 0
        ad.AvoidStaffLines = avoid
        ad.CenterHorizontally = false
        ad.CopyMainSymbol = false
        ad.CopyMainSymbolHorizontally = false

        ad.InsideSlurs = false
        ad.OnScreenOnly = false
        ad.Playback = false
        ad.AttackIsPercent = false
        ad.TopAttack = 0
        ad.BottomAttack = 0
        ad.DurationIsPercent = false
        ad.TopDuration = 0
        ad.BottomDuration = 0
        ad.TopVelocity = 0
        ad.BottomVelocity = 0
        ad:SaveNew()
        lv_up = ad.ItemNo
    end
    if lv_down == 0 then
        local ad = finale.FCArticulationDef()
        ad.MainSymbolChar = 73
        ad.MainSymbolFont = "Engraver Font Set"
        ad.MainSymbolIsShape = false
        ad.MainSymbolSize = 24
        ad.FlippedSymbolChar = 73
        ad.FlippedSymbolFont = "Engraver Font Set"
        ad.FlippedSymbolIsShape = false
        ad.FlippedSymbolSize = 24
        ad.AboveSymbolChar = 73
        ad.AboveUsesMain = true
        ad.BelowSymbolChar = 73
        ad.BelowUsesMain = true

        ad.DefaultVerticalPos = 0
        ad.MainHandleHorizontalOffset = horz
        ad.MainHandleVerticalOffset = -vert
        ad.FlippedHandleHorizontalOffset = horz
        ad.FlippedHandleVerticalOffset = vert

        ad.AlwaysPlaceOutsideStaff = false
        ad.AttachToTopNote = false
        ad.AutoPosSide = 0
        ad.AvoidStaffLines = avoid
        ad.CenterHorizontally = false
        ad.CopyMainSymbol = false
        ad.CopyMainSymbolHorizontally = false

        ad.InsideSlurs = false
        ad.OnScreenOnly = false
        ad.Playback = false
        ad.AttackIsPercent = false
        ad.TopAttack = 0
        ad.BottomAttack = 0
        ad.DurationIsPercent = false
        ad.TopDuration = 0
        ad.BottomDuration = 0
        ad.TopVelocity = 0
        ad.BottomVelocity = 0
        ad:SaveNew()
        lv_down = ad.ItemNo
    end
    if lv_auto == 0 then
        local ad = finale.FCArticulationDef()
        -- ad.MainSymbolChar = 105
        ad.MainSymbolFont = "Engraver Font Set"
        ad.MainSymbolIsShape = false
        ad.MainSymbolSize = 24
        ad.FlippedSymbolChar = 73
        ad.FlippedSymbolFont = "Engraver Font Set"
        ad.FlippedSymbolIsShape = false
        ad.FlippedSymbolSize = 24
        ad.AboveSymbolChar = 105
        ad.AboveUsesMain = true
        ad.BelowSymbolChar = 73
        ad.BelowUsesMain = false

        ad.DefaultVerticalPos = 0
        ad.MainHandleHorizontalOffset = horz
        ad.MainHandleVerticalOffset = -6
        ad.FlippedHandleHorizontalOffset = horz
        ad.FlippedHandleVerticalOffset = 7

        ad.AlwaysPlaceOutsideStaff = false
        ad.AttachToTopNote = false
        ad.AutoPosSide = 2
        -- ad.AvoidStaffLines = avoid
        ad.AvoidStaffLines = auto_avoid
        ad.CenterHorizontally = true
        ad.CopyMainSymbol = false
        ad.CopyMainSymbolHorizontally = false

        ad.InsideSlurs = false
        ad.OnScreenOnly = false
        ad.Playback = false
        ad.AttackIsPercent = false
        ad.TopAttack = 0
        ad.BottomAttack = 0
        ad.DurationIsPercent = false
        ad.TopDuration = 0
        ad.BottomDuration = 0
        ad.TopVelocity = 0
        ad.BottomVelocity = 0
        ad:SaveNew()
        ad.MainSymbolChar = 105
        ad:Save()
        lv_auto = ad.ItemNo
    end
    local found = 0

    for noteentry in eachentrysaved(finenv.Region()) do
        noteentry:TieAll(false)
        local artics = noteentry:CreateArticulations()
        for a in each(artics) do
            local defs = a:CreateArticulationDef()
            if defs:GetItemNo() == lv_auto or defs:GetItemNo() == lv_up or defs:GetItemNo() == lv_down then
                found = 1
            end
        end
    end

    if found ~= 0 then
        deleteArticulation(lv_auto)
        deleteArticulation(lv_up)
        deleteArticulation(lv_down)
        goto continue
    end

    local count = 0

    for noteentry in eachentrysaved(finenv.Region()) do
        local interval = {}
        local tiedir = {}
        local i = 1

        if noteentry:IsNote() and noteentry:IsTied() == false then
            local horz_pad = 24 * noteentry:CalcDots()
            local a = finale.FCArticulation()
            a:SetNoteEntry(noteentry)

            local rightside_note = false
            local ledger = false
            count = noteentry.Count
            local middle = 0
            local clashes = 0
            if count % 2 == 1 then
                middle = count / 2 + .5
            end
            local lowestnote = noteentry:CalcHighestStaffPosition() - noteentry:CalcDisplacementRange()
            local lastnote = lowestnote

            for note in each(noteentry) do
                interval[i] = note:CalcStaffPosition() - lastnote
                lastnote = note:CalcStaffPosition()
                if i > 1 and interval[i] <= 1 then
                    clashes = clashes + 1
                end

                if i > 1 and interval[i] >= 3 and interval[i - 1] <= 1 then
                    clashes = clashes - 1
                end

                if note:CalcRightsidePlacement() and noteentry:CalcStemUp() then
                    rightside_note = true
                end
                if note:CalcOnLedgerLine() then
                    ledger = true
                end
                i = i + 1
            end
            if rightside_note then
                horz_pad = horz_pad + 28
            end
            if ledger then
                horz_pad = horz_pad + 6
            end

            a.HorizontalPos = a.HorizontalPos + horz_pad
            i = 1
            for note in each(noteentry) do
                if count == 1 then
                    tiedir[i] = "a"
                elseif count > 1 then
                    if i <= count / 2 and j ~= middle then
                        tiedir[i] = "d"
                    else
                        tiedir[i] = "u"
                    end -- if
                    if i == middle and noteentry:CalcStemUp() then
                        tiedir[i] = "d"
                    end
                    if i > 1 and interval[i] <= 1 and clashes < 2 then
                        tiedir[i] = "fu"
                        tiedir[i - 1] = "fd"
                    end
                    i = i + 1
                end
            end

            i = 1
            for note in each(noteentry) do
                local cell = finale.FCNoteEntryCell(noteentry.Measure, noteentry.Staff)
                cell:Load()
                if cell:CalcEntriesInMultiLayers() then
                    if noteentry.LayerNumber % 2 == 1 then
                        tiedir[i] = "u"
                    else
                        tiedir[i] = "d"
                    end
                end
                i = i + 1
            end

            for i = i, 1, -1 do
                if tiedir[i] == "fd" and tiedir[i - 1] == "u" then
                    tiedir[i - 1] = "fd"
                end

            end

            i = 1
            for note in each(noteentry) do -- 3rd...
                local vert_pad = 0
                if tiedir[i] == "a" then
                    a:SetID(lv_auto)
                elseif tiedir[i] == "d" or tiedir[i] == "fd" then
                    a:SetID(lv_down)
                else
                    a:SetID(lv_up)
                end

                local staffpos = note:CalcStaffPosition()
                if staffpos < -9 or staffpos > 1 then
                    -- print("Note is outside staff. No adjustment necessary")
                elseif staffpos % 2 == 1 then
                    if (tiedir[i] == "d" or tiedir[i] == "fd") then
                        vert_pad = vert_pad + 4
                    elseif (tiedir[i] == "u" or tiedir[i] == "fu") then
                        vert_pad = vert_pad - 3
                    end
                else
                    if (tiedir[i] == "d" or tiedir[i] == "fd") then
                        vert_pad = vert_pad - 4
                    elseif (tiedir[i] == "u" or tiedir[i] == "fu") then
                        vert_pad = vert_pad + 4
                    end
                end

                if (tiedir[i] == "d" or tiedir[i] == "fd") and (tiedir[i + 1] == "d" or tiedir[i + 1] == "fd") and interval[i + 1] <= 1 then
                    vert_pad = vert_pad - 6
                    if staffpos >= -9 and staffpos % 2 == 1 then
                        vert_pad = vert_pad - 12
                    end
                elseif (tiedir[i] == "u" or tiedir[i] == "fu") and (tiedir[i - 1] == "u" or tiedir[i - 1] == "fu") and interval[i] <= 1 then
                    vert_pad = vert_pad + 6
                    if staffpos <= 1 and staffpos % 2 == 1 then
                        vert_pad = vert_pad + 10
                    end
                end
                a.VerticalPos = (note:CalcStaffPosition() - lowestnote) * 12 + vert_pad
                a:SaveNew()
                i = i + 1
            end
        end
    end
    ::continue::
end

function delete_duplicate_articulations(note_entry)
    local art_list = {}
    local arts = note_entry:CreateArticulations()
    for a in each(arts) do
        table.insert(art_list, a:GetID())
    end

    local sort_list = {}
    local unique_list = {}
    for k, v in ipairs(art_list) do
        if (not sort_list[v]) then
            unique_list[#unique_list + 1] = v
            sort_list[v] = true
        end
    end
    for key, value in pairs(art_list) do
        for a in each(arts) do
            a:DeleteData()
        end
    end
    for key, value in pairs(unique_list) do
        local art = finale.FCArticulation()
        art:SetNoteEntry(note_entry)
        art:SetID(value)
        art:SaveNew()
    end
end

function split_articulations()
    local articulationdefs = finale.FCArticulationDefs()
    articulationdefs:LoadAll()
    local art_table = {0, 0, 0, 0}
    local pairs_to_use = {}
    local accent_staccato = 0
    local accent_tenuto_def = 0
    local accent_tenuto_eng = 0
    local tenuto_staccato = 0
    local marcato_staccato = 0

    if check_SMuFL(nil) then
        pairs_to_use = {58530, 58528, 58532, 58540}
        accent_staccato = 58544
        accent_tenuto_def = 58548
        accent_tenuto_eng = accent_tenuto_def
        tenuto_staccato = 58546
        marcato_staccato = 58542
    else
        pairs_to_use = {46, 62, 45, 94}
        accent_staccato = 249
        accent_tenuto_def = 138
        accent_tenuto_eng = 251
        tenuto_staccato = 248
        marcato_staccato = 172
    end

    for k, v in pairs(pairs_to_use) do
        local first_id_table = {}
        for ad in each(articulationdefs) do
            if (ad:GetAboveSymbolChar() == v) and (ad:GetFlippedSymbolChar() > 0) then
                table.insert(first_id_table, ad.ItemNo)
            end
        end
        if first_id_table[1] ~= nil then
            art_table[k] = first_id_table[1]
        end
    end

    for noteentry in eachentry(finenv.Region()) do
        local remove_duplicates = 0
        local arts = noteentry:CreateArticulations()
        for a in each(arts) do
            local ad = finale.FCArticulationDef()
            if ad:Load(a:GetID()) then
                if ad:GetAboveSymbolChar() == accent_staccato then
                    a:SetID(art_table[2])
                    a:Save()
                    a:SetID(art_table[1])
                    a:SaveNew()
                    remove_duplicates = remove_duplicates + 1
                end
                if (ad:GetAboveSymbolChar() == accent_tenuto_def) or (ad:GetAboveSymbolChar() == accent_tenuto_eng) then
                    a:SetID(art_table[2])
                    a:Save()
                    a:SetID(art_table[3])
                    a:SaveNew()
                    remove_duplicates = remove_duplicates + 1
                end
                if ad:GetAboveSymbolChar() == tenuto_staccato then
                    a:SetID(art_table[3])
                    a:Save()
                    a:SetID(art_table[1])
                    a:SaveNew()
                    remove_duplicates = remove_duplicates + 1
                end
                if ad:GetAboveSymbolChar() == marcato_staccato then
                    a:SetID(art_table[4])
                    a:Save()
                    a:SetID(art_table[1])
                    a:SaveNew()
                    remove_duplicates = remove_duplicates + 1
                end
            end
        end
        if remove_duplicates > 0 then
            delete_duplicate_articulations(noteentry)
        end
    end
end

function get_current_page_height(measure_num)
    local pages = finale.FCPages()
    pages:LoadAll()
    local page_height = nil
    for p in each(pages) do
        -- finenv.UI():AlertInfo(p:GetPercent(), nil)
        local start_meas = p:CalcFirstMeasure()
        local end_meas = p:CalcLastMeasure()
        if ((start_meas <= measure_num) and (end_meas >= measure_num)) then
            page_height = p:GetHeight()
        end
    end
    return page_height
end

function get_system_scaling(region)
    local cell = finale.FCCell(region:GetStartMeasure(), region:GetStartStaff())
    local metrics = cell:CreateCellMetrics()
    local scaling = metrics:GetSystemScaling() / 10000
    return scaling
end

function find_lowest_item_in_region(region, list_of_items)
    local page_height = get_current_page_height(region:GetStartMeasure())
    local system_scale = get_system_scaling(region)
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    systems:LoadAll()
    local current_lowest_item = page_height

    if (list_of_items[1]) then
        -- expressions
        if (list_of_items[1]:ClassName() == "FCExpression") then
            for k, expression in pairs(list_of_items) do
                if (systems:FindMeasureNumber(expression:GetMeasure())) then
                    local arg_point_exp = finale.FCPoint(0, 0)
                    if expression:CalcMetricPos(arg_point_exp) then
                        local exp_x, exp_y = math.floor(arg_point_exp.X * system_scale), math.floor(arg_point_exp.Y * system_scale)
                        if exp_y < current_lowest_item then
                            -- local exp_ted = expression:CreateTextExpressionDef()
                            -- local exp_string = exp_ted:CreateTextString()
                            -- local font_info = exp_string:CreateLastFontInfo()
                            -- exp_string:TrimEnigmaTags()
                            -- local text_met = finale.FCTextMetrics()
                            -- text_met:LoadString(exp_string, font_info, 100)
                            -- local expression_height = (text_met:CalcHeightEVPUs() / 6)
                            current_lowest_item = exp_y
                            -- finenv.UI():AlertInfo("Expression Pos: "..exp_y.."\rLowest Item So Far: "..current_lowest_item, nil)
                        end
                    end
                end
            end
        end
        -- hairpins
        if (list_of_items[1]:ClassName() == "FCSmartShape") then
            for k, smartshape in pairs(list_of_items) do
                local left_seg = smartshape:GetTerminateSegmentLeft()
                local right_seg = smartshape:GetTerminateSegmentRight()
                local hairpin_start_system = systems:FindMeasureNumber(left_seg:GetMeasure())
                local hairpin_end_system = systems:FindMeasureNumber(right_seg:GetMeasure())
                local region_system = systems:FindMeasureNumber(region:GetStartMeasure())

                -- has full hairpin
                if ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
                    -- finenv.UI():AlertInfo("Hairpin on one system", nil)
                    local arg_point_hairpin_both = finale.FCPoint(0, 0)
                    local hairpin_left_term = smartshape:CalcLeftCellMetricPos(arg_point_hairpin_both)
                    local hairpin_x, hairpin_y = math.floor(arg_point_hairpin_both.X * system_scale), math.floor(arg_point_hairpin_both.Y * system_scale)

                    if (hairpin_y < current_lowest_item) then
                        current_lowest_item = hairpin_y
                    end
                end
                -- broken over system - left side
                if ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo > region_system.ItemNo)) then
                    -- finenv.UI():AlertInfo("Hairpin broken: this is the left seg", nil)
                    local arg_point_hairpin_left = finale.FCPoint(0, 0)
                    local hairpin_left_term = smartshape:CalcLeftCellMetricPos(arg_point_hairpin_left)
                    local hairpin_x, hairpin_y = math.floor(arg_point_hairpin_left.X * system_scale), math.floor(arg_point_hairpin_left.Y * system_scale)
                    if (hairpin_y < current_lowest_item) then
                        current_lowest_item = hairpin_y
                    end
                end
                -- broken over system - right side
                if ((hairpin_start_system.ItemNo <= region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
                    -- finenv.UI():AlertInfo("Hairpin broken: this is the right seg", nil)
                    local cell = finale.FCCell(right_seg:GetMeasure(), right_seg:GetStaff())
                    local cell_metrics = cell:CreateCellMetrics()
                    local highest_staff_line = math.floor(cell_metrics:GetTopStafflinePos() * system_scale)
                    local right_offset = right_seg:GetEndpointOffsetY()
                    local right_seg_pos = highest_staff_line - right_offset
                    if (right_seg_pos < current_lowest_item) then
                        current_lowest_item = right_seg_pos
                    end
                end
            end
        end
        -- entries
        if (list_of_items[1]:ClassName() == "FCNoteEntry") then
            for k, noteentry in pairs(list_of_items) do
                if (systems:FindMeasureNumber(noteentry:GetMeasure())) then
                    local entry_metrics = finale.FCEntryMetrics()
                    entry_metrics:Load(noteentry)
                    local current_entry_pos = entry_metrics:GetBottomPosition()
                    if (current_entry_pos < current_lowest_item) then
                        current_lowest_item = current_entry_pos - config.noteentry_cushion
                    end
                end
            end
        end
    else
        if (list_of_items == "Staff Lines") then
            for region_measure = region:GetStartMeasure(), region:GetEndMeasure() do
                local cell = finale.FCCell(region_measure, region:GetStartStaff())
                local cell_metrics = cell:CreateCellMetrics()
                local lowest_staff_line = math.floor(cell_metrics:GetBottomStafflinePos() * system_scale)
                if (lowest_staff_line < current_lowest_item) then
                    current_lowest_item = lowest_staff_line - config.staff_cushion
                end
            end
        end
    end

    if ((current_lowest_item == page_height) or (current_lowest_item == 0)) then
        return nil
    else
        return current_lowest_item
    end
end

local expression_midpoint = 0

function set_vertical_pos(region, list_of_items, lowest_item_type, lowest_item, direction)
    local page_height = get_current_page_height(region:GetStartMeasure())
    local system_scale = get_system_scaling(region)
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    systems:LoadAll()

    if (list_of_items[1]) then
        -- expressions
        if (list_of_items[1]:ClassName() == "FCExpression") then
            for k, expression in pairs(list_of_items) do
                if (systems:FindMeasureNumber(expression:GetMeasure())) then
                    local arg_point_exp = finale.FCPoint(0, 0)
                    if expression:CalcMetricPos(arg_point_exp) then
                        local exp_ted = expression:CreateTextExpressionDef()
                        local exp_string = exp_ted:CreateTextString()
                        local font_info = exp_string:CreateLastFontInfo()
                        exp_string:TrimEnigmaTags()
                        local text_met = finale.FCTextMetrics()
                        text_met:LoadString(exp_string, font_info, 100)
                        if (text_met) then
                            expression_top = math.floor(text_met:GetTopEVPUs() * system_scale)
                            expression_bottom = math.floor(text_met:GetBottomEVPUs() * system_scale)
                        end
                        local exp_x, exp_y = math.floor(arg_point_exp.X * system_scale), math.floor(arg_point_exp.Y * system_scale)
                        local top_y = exp_y + expression_top
                        local bottom_y = exp_y + expression_bottom
                        -- expression_midpoint = bottom_y + ((top_y - bottom_y) / 2)
                        expression_midpoint = (bottom_y + math.floor((top_y - bottom_y) / 2)) - exp_y
                        -- finenv.UI():AlertInfo("Expression Handle: "..exp_y.."\rExpression Top: "..expression_top.."\rExpression Bottom: "..expression_bottom, nil)
                        -- finenv.UI():AlertInfo("Expression Handle: "..exp_y.."\rExpression Top: "..top_y.."\rExpression Bottom: "..bottom_y, nil)
                        -- finenv.UI():AlertInfo("Middle of Expression: "..mid_point, nil)
                        local difference_far = math.floor(math.abs(exp_y - lowest_item) / system_scale)
                        -- local difference_near = math.floor(math.abs(exp_y - nearest_item) / system_scale)
                        if direction == "far" then
                            -- finenv.UI():AlertInfo("Exp: "..expression:GetVerticalPos().."\rdiff: -"..difference_far, nil)
                            expression:SetVerticalPos(expression:GetVerticalPos() - difference_far)
                        else
                            expression:SetVerticalPos(expression:GetVerticalPos() + difference_near)
                        end
                        expression:Save()
                    end
                end
            end
        end
        -- hairpins
        if (list_of_items[1]:ClassName() == "FCSmartShape") then

            -- this is a weird, arbitrary amount.
            if (expression_midpoint ~= 0) then
                -- expression_midpoint = math.floor(expression_midpoint / system_scale)
                -- finenv.UI():AlertInfo("Midpoint? "..expression_midpoint, nil)
                -- expression_midpoint = 11 * system_scale
                expression_midpoint = 10
                -- expression_midpoint = 0
            end

            for k, smartshape in pairs(list_of_items) do
                local left_seg = smartshape:GetTerminateSegmentLeft()
                local right_seg = smartshape:GetTerminateSegmentRight()
                local hairpin_start_system = systems:FindMeasureNumber(left_seg:GetMeasure())
                local hairpin_end_system = systems:FindMeasureNumber(right_seg:GetMeasure())
                local region_system = systems:FindMeasureNumber(region:GetStartMeasure())

                -- has full hairpin
                if ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
                    -- finenv.UI():AlertInfo("Hairpin on one system", nil)
                    local arg_point_hairpin_both = finale.FCPoint(0, 0)
                    local hairpin_left_term = smartshape:CalcLeftCellMetricPos(arg_point_hairpin_both)
                    local hairpin_x, hairpin_y = math.floor(arg_point_hairpin_both.X * system_scale), math.floor(arg_point_hairpin_both.Y * system_scale)

                    local difference_far = math.floor(math.abs(hairpin_y - lowest_item) / system_scale)
                    -- local difference_near = math.floor(math.abs(hairpin_y - nearest_item))
                    if direction == "far" then
                        left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() - difference_far + expression_midpoint)
                        right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY() - difference_far + expression_midpoint)
                    else
                        left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() + difference_near - expression_midpoint)
                        right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY() + difference_near - expression_midpoint)
                    end

                end
                -- broken over system - left side
                if ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo > region_system.ItemNo)) then
                    -- finenv.UI():AlertInfo("Hairpin broken: this is the left seg", nil)
                    local arg_point_hairpin_left = finale.FCPoint(0, 0)
                    local hairpin_left_term = smartshape:CalcLeftCellMetricPos(arg_point_hairpin_left)
                    local hairpin_x, hairpin_y = math.floor(arg_point_hairpin_left.X * system_scale), math.floor(arg_point_hairpin_left.Y * system_scale)

                    local difference_far = math.floor(math.abs(hairpin_y - lowest_item) / system_scale)
                    -- local difference_near = math.floor(math.abs(hairpin_y - nearest_item))
                    if direction == "far" then
                        -- finenv.UI():AlertInfo("Left seg: "..left_seg:GetEndpointOffsetY().."\rdiff: -"..difference_far, nil)
                        left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() - difference_far + expression_midpoint)
                    else
                        left_seg:SetEndpointOffsetY(left_seg:GetEndpointOffsetY() + difference_near - expression_midpoint)
                    end
                end
                -- broken over system - right side
                if ((hairpin_start_system.ItemNo < region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
                    -- finenv.UI():AlertInfo("Hairpin broken: this is the right seg", nil)

                    local cell = finale.FCCell(right_seg:GetMeasure(), right_seg:GetStaff())
                    local cell_metrics = cell:CreateCellMetrics()
                    local highest_staff_line = math.floor(cell_metrics:GetTopStafflinePos() * system_scale)
                    local right_offset = math.floor(right_seg:GetEndpointOffsetY() * system_scale)
                    local right_seg_pos = highest_staff_line + right_offset
                    -- finenv.UI():AlertInfo("Real Pos: "..right_seg_pos, nil)
                    -- finenv.UI():AlertInfo("Right Pos: "..right_seg_pos.."\rLowest Item: "..lowest_item, nil)
                    local difference_far = math.abs(math.floor(right_seg_pos - lowest_item) / system_scale)
                    -- local difference_near = math.floor(math.abs(hairpin_y - nearest_item))
                    -- finenv.UI():AlertInfo("Current Pos: "..right_seg_pos.."\rLowest Item: "..lowest_item.."\rFinal Pos: "..(right_seg_pos - difference_far).."\r(difference): "..difference_far, nil)
                    if direction == "far" then
                        -- finenv.UI():AlertInfo("Right seg: "..right_seg:GetEndpointOffsetY().."\rdiff: -"..difference_far, nil)
                        right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY() - difference_far + expression_midpoint)
                    else
                        right_seg:SetEndpointOffsetY(right_seg:GetEndpointOffsetY() + difference_near - expression_midpoint)
                    end
                end
                smartshape:Save()
            end
        end
    end
end

function vertical_dynamic_adjustment(region, expression_list, hairpin_list, notes_in_region_list, direction)
    local lowest_exp = find_lowest_item_in_region(region, expression_list)
    local lowest_hairpin = find_lowest_item_in_region(region, hairpin_list)
    local lowest_entry = find_lowest_item_in_region(region, notes_in_region_list)
    local lowest_staff_line = find_lowest_item_in_region(region, "Staff Lines")
    local lowest_item_list = {Expression = lowest_exp, Hairpin = lowest_hairpin, Entry = lowest_entry, StaffLine = lowest_staff_line}

    local sorted = {}
    for k, v in pairs(lowest_item_list) do
        table.insert(sorted, {k, v})
    end

    table.sort(
        sorted, function(a, b)
            return a[2] < b[2]
        end)

    lowest_item = sorted[1][2]
    lowest_item_type = sorted[1][1]
    -- finenv.UI():AlertInfo("Lowest Item: "..sorted[1][1]..": "..sorted[1][2], nil)
    set_vertical_pos(region, expression_list, lowest_item_type, lowest_item, direction)
    set_vertical_pos(region, hairpin_list, lowest_item_type, lowest_item, direction)

    -- attempted to revamp old version
    --[[
    local lowest_item = {}
    local staff_pos = {}
    local entry_pos = {}
    local has_dynamics = false
    local has_hairpins = false
    local arg_point = finale.FCPoint(0, 0)
    local system_scale = get_system_scaling(region)
    local systems = finale.FCStaffSystemsLookup():GetCurrentPartStaffSystems()
    systems:LoadAll()

    local below_note_cushion = 45

    for k, e in pairs(expression_list) do
        if e:CalcMetricPos(arg_point) then
            has_dynamics = true
            table.insert(lowest_item, math.floor(arg_point:GetY() * system_scale))
        end
    end

    for k, smart_shape in pairs(hairpin_list) do
        has_hairpins = true
        local left_seg = smart_shape:GetTerminateSegmentLeft()
        local right_seg = smart_shape:GetTerminateSegmentRight()
        local hairpin_start_system = systems:FindMeasureNumber(left_seg:GetMeasure())
        local hairpin_end_system = systems:FindMeasureNumber(right_seg:GetMeasure())
        local region_system = systems:FindMeasureNumber(region:GetStartMeasure())
        if ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
            table.insert(lowest_item, math.floor(arg_point:GetY() * system_scale))
        elseif ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo > region_system.ItemNo)) then
            table.insert(lowest_item, math.floor(arg_point:GetY() * system_scale))
        elseif ((hairpin_start_system.ItemNo < region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
            local cell = finale.FCCell(right_seg:GetMeasure(), right_seg:GetStaff())
            local cell_metrics = cell:CreateCellMetrics()
            local highest_staff_line = math.floor(cell_metrics:GetTopStafflinePos() * system_scale)
            local right_offset = math.floor(right_seg:GetEndpointOffsetY() * system_scale)
            local right_seg_pos = highest_staff_line + right_offset
            table.insert(lowest_item, right_seg_pos)
        end
    end

    table.sort(lowest_item)
    finenv.UI():AlertInfo(lowest_item[1], nil)
    -- finenv.UI():AlertInfo("Lowest Item: "..lowest_item[1], nil)
    if has_dynamics then
        for k, e in pairs(expression_list) do
            if (systems:FindMeasureNumber(e:GetMeasure())) then

                if e:CalcMetricPos(arg_point) then
                    local difference_pos =  math.floor(arg_point:GetY() * system_scale) - lowest_item[1]
                    if direction == "near" then
                        difference_pos = lowest_item[#lowest_item] - math.floor(arg_point:GetY() * system_scale)
                    end
                        local current_pos = e:GetVerticalPos()
                    if direction == "far" then
                        e:SetVerticalPos(current_pos - (difference_pos / system_scale))
                    else
                        e:SetVerticalPos(current_pos + (difference_pos / system_scale))
                    end
                    e:Save()
                end
            end
        end
    else
        for k, noteentry in pairs(notes_in_region_list) do
            if (systems:FindMeasureNumber(noteentry:GetMeasure())) then
                local entry_metrics = finale.FCEntryMetrics()
                entry_metrics:Load(noteentry)
                local current_entry_pos = entry_metrics:GetBottomPosition()
                table.insert(entry_pos, current_entry_pos)
                local entry_cell = finale.FCCell(noteentry:GetMeasure(), noteentry:GetStaff())
                local entry_cell_metrics = entry_cell:CreateCellMetrics()
                local lowest_staff_line = math.floor(entry_cell_metrics:GetBottomStafflinePos() * system_scale)
                table.insert(staff_pos, lowest_staff_line)
            end
        end
        table.sort(entry_pos)
        table.sort(staff_pos)

        if ((entry_pos[1] ~= nil) and (staff_pos[1] ~= nil)) then
            if entry_pos[1] < staff_pos[1] then
                lowest_item[1] = entry_pos[1] - below_note_cushion
            else
                lowest_item[1] = staff_pos[1]
            end
        end
    end

    if has_hairpins then
        for k, smart_shape in pairs(hairpin_list) do
            local left_seg = smart_shape:GetTerminateSegmentLeft()
            local right_seg = smart_shape:GetTerminateSegmentRight()
            local hairpin_start_system = systems:FindMeasureNumber(left_seg:GetMeasure())
            local hairpin_end_system = systems:FindMeasureNumber(right_seg:GetMeasure())
            local region_system = systems:FindMeasureNumber(region:GetStartMeasure())
            if ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
                local current_pos = left_seg:GetEndpointOffsetY()
                local difference_pos = math.floor(arg_point:GetY() * system_scale) - lowest_item[1]
                if direction == "near" then
                    difference_pos = lowest_item[#lowest_item] - math.floor(arg_point:GetY() * system_scale)
                end
                if has_dynamics then
                    if direction == "far" then
                        -- finenv.UI():AlertInfo(current_pos.." "..difference_pos, nil)
                        -- I think this + 12 is the difference between the handle of the dynamic and the middle of the dynamic
                        left_seg:SetEndpointOffsetY((current_pos - (difference_pos / system_scale)) + 12)
                        right_seg:SetEndpointOffsetY((current_pos - (difference_pos / system_scale)) + 12)
                    else
                        left_seg:SetEndpointOffsetY((current_pos + (difference_pos / system_scale)) + 12)
                        right_seg:SetEndpointOffsetY((current_pos + (difference_pos / system_scale)) + 12)
                    end
                else
                    left_seg:SetEndpointOffsetY(lowest_item[1])
                    right_seg:SetEndpointOffsetY(lowest_item[1])
                end
                smart_shape:Save()
            elseif ((hairpin_start_system.ItemNo == region_system.ItemNo) and (hairpin_end_system.ItemNo > region_system.ItemNo)) then
                local current_pos = left_seg:GetEndpointOffsetY()
                local difference_pos = math.floor(arg_point:GetY() * system_scale) - lowest_item[1]
                if direction == "near" then
                    difference_pos = lowest_item[#lowest_item] - math.floor(arg_point:GetY() * system_scale)
                end
                if has_dynamics then
                    if direction == "far" then
                        -- finenv.UI():AlertInfo(current_pos.." "..difference_pos, nil)
                        left_seg:SetEndpointOffsetY((current_pos - (difference_pos / system_scale)) + 12)
                    else
                        left_seg:SetEndpointOffsetY((current_pos + (difference_pos / system_scale)) + 12)
                    end
                else
                    left_seg:SetEndpointOffsetY(lowest_item[1])
                end
                smart_shape:Save()
            elseif ((hairpin_start_system.ItemNo < region_system.ItemNo) and (hairpin_end_system.ItemNo == region_system.ItemNo)) then
                local cell = finale.FCCell(right_seg:GetMeasure(), right_seg:GetStaff())
                local cell_metrics = cell:CreateCellMetrics()
                local highest_staff_line = math.floor(cell_metrics:GetTopStafflinePos() * system_scale)
                local right_offset = math.floor(right_seg:GetEndpointOffsetY() * system_scale)
                local right_seg_pos = highest_staff_line + right_offset

                local current_pos = right_offset
                local difference_pos = right_seg_pos - lowest_item[1]
                if direction == "near" then
                    difference_pos = lowest_item[#lowest_item] - right_seg_pos
                end

                if has_dynamics then
                    if direction == "far" then
                        -- finenv.UI():AlertInfo(current_pos.." "..difference_pos, nil)
                        right_seg:SetEndpointOffsetY((current_pos - (difference_pos / system_scale)) + 12)
                    else
                        right_seg:SetEndpointOffsetY((current_pos + (difference_pos / system_scale)) + 12)
                    end
                else
                    right_seg:SetEndpointOffsetY(lowest_item[1])
                end
                smart_shape:Save()
            end
        end
    end ]]
end

function horizontal_hairpin_adjustment(left_or_right, hairpin, hairpin_region, cushion_bool, multiple_hairpin_bool)
    local the_seg = hairpin:GetTerminateSegmentLeft()
    local left_dynamic_cushion = config.dynamic_L_cushion
    local right_dynamic_cushion = -config.dynamic_R_cushion
    local left_selection_cushion = 0
    local right_selection_cushion = -18

    if left_or_right == "left" then
        the_seg = hairpin:GetTerminateSegmentLeft()
    end
    if left_or_right == "right" then
        the_seg = hairpin:GetTerminateSegmentRight()
    end

    local region = hairpin_region

    if multiple_hairpin_bool == false then
        the_seg:SetMeasurePos(region:GetStartMeasurePos())
    else
        region:SetStartMeasure(the_seg:GetMeasure())
        region:SetStartMeasurePos(the_seg:GetMeasurePos())
        region:SetEndMeasure(the_seg:GetMeasure())
        region:SetEndMeasurePos(the_seg:GetMeasurePos())
    end

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    local expression_list = {}
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                local text_met = finale.FCTextMetrics()
                local string = create_def:CreateTextString()
                string:TrimEnigmaTags()
                text_met:LoadString(string, create_def:CreateTextString():CreateLastFontInfo(), 100)
                table.insert(expression_list, {text_met:CalcWidthEVPUs(), e, e:GetItemInci()})
            end
        end
    end
    if #expression_list > 0 then
        local dyn_width = (expression_list[1][1] / 2)
        local dyn_def = expression_list[1][2]:CreateTextExpressionDef()
        local manual_horizontal = expression_list[1][2]:GetHorizontalPos()
        local horizontal_offset = dyn_def:GetHorizontalOffset()
        local total_offset = manual_horizontal + horizontal_offset
        if left_or_right == "left" then
            local total_x = dyn_width + left_dynamic_cushion + total_offset
            the_seg:SetEndpointOffsetX(total_x)
        elseif left_or_right == "right" then
            cushion_bool = false
            local total_x = (0 - dyn_width) + right_dynamic_cushion + total_offset
            the_seg:SetEndpointOffsetX(total_x)
        end
    end
    if cushion_bool then
        the_seg = hairpin:GetTerminateSegmentRight()
        the_seg:SetEndpointOffsetX(right_selection_cushion)
    end
    hairpin:Save()
end

function hairpin_adjustments(region_settings, adjustment_type)

    local start_region = finale.FCMusicRegion()
    start_region:SetStartStaff(region_settings[1])
    start_region:SetEndStaff(region_settings[1])
    start_region:SetStartMeasure(region_settings[2])
    start_region:SetEndMeasure(region_settings[2])
    start_region:SetStartMeasurePos(region_settings[4])
    start_region:SetEndMeasurePos(region_settings[4])

    local end_region = finale.FCMusicRegion()
    end_region:SetStartStaff(region_settings[1])
    end_region:SetEndStaff(region_settings[1])
    end_region:SetStartMeasure(region_settings[3])
    end_region:SetEndMeasure(region_settings[3])
    end_region:SetStartMeasurePos(region_settings[5])
    end_region:SetEndMeasurePos(region_settings[5])

    local full_region = finale.FCMusicRegion()
    full_region:SetStartStaff(region_settings[1])
    full_region:SetEndStaff(region_settings[1])
    full_region:SetStartMeasure(region_settings[2])
    full_region:SetEndMeasure(region_settings[3])
    full_region:SetStartMeasurePos(region_settings[4])
    full_region:SetEndMeasurePos(region_settings[5])

    local hairpin_list = {}
    local hairpin_count = 0
    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAll()
    for mark in each(ssmm) do
        local smartshape = mark:CreateSmartShape()
        if smartshape:IsHairpin() then
            if (((mark:GetMeasure() == region_settings[3]) or (mark:GetMeasure() == region_settings[4])) and
                ((smartshape:GetTerminateSegmentRight():GetStaff() == region_settings[1]))) then
                table.insert(hairpin_list, smartshape)
                hairpin_count = hairpin_count + 1
            end
        end
    end

    local expression_list = {}

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(full_region)
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                table.insert(expression_list, e)
            end
        end
    end

    local end_cushion = region_settings[6]
    local notes_in_region_list = region_settings[7]

    if adjustment_type == "both" then
        if hairpin_count == 1 then
            horizontal_hairpin_adjustment("left", hairpin_list[1], start_region, end_cushion, false)
            horizontal_hairpin_adjustment("right", hairpin_list[1], end_region, end_cushion, false)
        elseif hairpin_count > 1 then
            for key, value in pairs(hairpin_list) do
                horizontal_hairpin_adjustment("left", value, start_region, end_cushion, true)
                horizontal_hairpin_adjustment("right", value, end_region, end_cushion, true)
            end
        end
        vertical_dynamic_adjustment(full_region, expression_list, hairpin_list, notes_in_region_list, "far")
    else
        vertical_dynamic_adjustment(full_region, expression_list, hairpin_list, notes_in_region_list, adjustment_type)
    end
end

function halfway_point(current_staff, first_pin, second_pin)

    function mdv_has_dynamic(last_measure, last_pos)

        local region = finenv.Region()
        region:SetStartStaff(current_staff)
        region:SetEndStaff(current_staff)
        local expression_list = {}
        local new_end = finale.FCMeasure()
        new_start_pos = last_pos - 256
        new_end_pos = last_pos + 256
        new_start_meas = last_measure
        new_end_meas = last_measure
        if new_start_pos < 0 then
            last_measure = last_measure - 1
            if new_end:Load(last_measure) then
                new_start_pos = new_end:GetDuration() - 256
                new_start_meas = last_measure
            end
        else
            new_end:Load(last_measure)
            if new_end_pos > (new_end:GetDuration()) then
                last_measure = last_measure + 1
                if new_end:Load(last_measure) then
                    new_end_pos = 256
                    new_end_meas = last_measure
                end
            end
        end
        region:SetStartMeasure(new_start_meas)
        region:SetEndMeasure(new_end_meas)
        region:SetStartMeasurePos(new_start_pos)
        region:SetEndMeasurePos(new_end_pos)
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(region)
        for e in each(expressions) do
            local create_def = e:CreateTextExpressionDef()
            local cd = finale.FCCategoryDef()
            if cd:Load(create_def:GetCategoryID()) then
                if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                    table.insert(expression_list, {e:GetMeasure(), e:GetMeasurePos()})
                end
            end
        end
        if #expression_list > 0 then
            return expression_list[1]
        else
            return false
        end
    end

    local music_region = finenv.Region()
    music_region:SetCurrentSelection()
    music_region:SetStartStaff(current_staff)
    music_region:SetEndStaff(current_staff)
    local count = 0
    local halfway_measure_pos = 0
    local halfway_measure = 0
    local start_measure = 0
    local start_measure_pos = 0
    local end_measure = 0
    local end_measure_pos = 0
    local notes_in_region = {}
    for noteentry in eachentrysaved(music_region) do
        if noteentry:IsNote() then
            table.insert(notes_in_region, noteentry)
        end
    end
    if #notes_in_region > 0 then
        start_measure = notes_in_region[1]:GetMeasure()
        start_measure_pos = notes_in_region[1]:GetMeasurePos()
        end_measure = notes_in_region[#notes_in_region]:GetMeasure()
        end_measure_pos = notes_in_region[#notes_in_region]:GetMeasurePos()
        hairpin_end_measure_pos = notes_in_region[#notes_in_region]:GetMeasurePos()
        local halfway_to_end = mdv_has_dynamic(end_measure, hairpin_end_measure_pos)
        if notes_in_region[#notes_in_region]:GetDuration() > 1536 then
            end_measure_pos = end_measure_pos + notes_in_region[#notes_in_region]:GetDuration()
        end
        if halfway_to_end ~= false then
            end_measure = halfway_to_end[1]
            hairpin_end_measure_pos = halfway_to_end[2]
        else
            if notes_in_region[#notes_in_region]:GetDuration() > 1536 then
                hairpin_end_measure_pos = hairpin_end_measure_pos + notes_in_region[#notes_in_region]:GetDuration()
            end
        end

        halfway_measure = math.floor((((end_measure - start_measure) / 2) + start_measure))
        music_region:SetStartMeasure(start_measure)
        music_region:SetStartMeasurePos(start_measure_pos)
        music_region:SetEndMeasure(end_measure)
        music_region:SetEndMeasurePos(end_measure_pos)
        local full_duration = music_region:CalcDuration()
        local half_duration = math.floor(full_duration / 2)
        music_region:SetStartMeasurePos(start_measure_pos + half_duration)
        halfway_measure = music_region:GetStartMeasure()
        halfway_measure_pos = music_region:GetStartMeasurePos()

        local beginning_to_halfway = mdv_has_dynamic(halfway_measure, halfway_measure_pos)
        if beginning_to_halfway ~= false then
            halfway_measure = beginning_to_halfway[1]
            halfway_measure_pos = beginning_to_halfway[2]
        end

        createHairpin({current_staff, start_measure, halfway_measure, start_measure_pos, halfway_measure_pos}, first_pin)
        createHairpin({current_staff, halfway_measure, end_measure, halfway_measure_pos, hairpin_end_measure_pos}, second_pin)
    else
        return
    end
end

function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = "\"" .. k .. "\""
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

function createHairpin(range_settings, shape)
    local smartshape = finale.FCSmartShape()
    smartshape.ShapeType = shape
    smartshape.EntryBased = false
    smartshape.MakeHorizontal = true
    smartshape.BeatAttached = true
    smartshape.PresetShape = true
    smartshape.Visible = true
    smartshape.LineID = shape
    smartshape:SetHairpinFlags()
    smartshape:SetMeasureAttachedFlags(true, true)

    local leftseg = smartshape:GetTerminateSegmentLeft()
    leftseg:SetMeasure(range_settings[2])
    leftseg.Staff = range_settings[1]
    leftseg:SetCustomOffset(false)
    leftseg:SetEndpointOffsetY(0)
    leftseg:SetEndpointOffsetX(0)
    leftseg:SetMeasurePos(range_settings[4])

    local rightseg = smartshape:GetTerminateSegmentRight()
    rightseg:SetMeasure(range_settings[3])
    rightseg.Staff = range_settings[1]
    rightseg:SetCustomOffset(false)
    rightseg:SetEndpointOffsetX(0)
    rightseg:SetEndpointOffsetY(0)
    rightseg:SetMeasurePos(range_settings[5])
    smartshape:SaveNewEverything(nil, nil)
end

function messa_di_voce(staff_num, beginning_shape, end_shape)
    local function measureDuration(m)
        local get_time = finale.FCMeasure()
        get_time:Load(m)
        local pos = get_time:GetTimeSignature()
        local beat = pos:GetBeats()
        local duration = pos:GetBeatDuration()
        return beat * duration
    end

    local function setRange()
        local rgn = finenv.Region()
        local arc1 = {rgn.StartMeasure, 0, rgn.EndMeasure, 0}
        local arc2 = {arc1[3], 0, arc1[3], 0}
        local bars = {}
        local accum = 0
        local buffer = 128

        for i = arc1[1], arc1[3] do
            local durn = measureDuration(i)
            if i == arc1[1] then
                local start_pos = rgn.StartMeasurePos
                arc1[2] = start_pos
                durn = durn - start_pos
            end
            if i == arc1[3] then
                local time = durn
                local m = rgn.EndMeasurePos
                if m < 999999 then
                    time = m
                end
                arc2[4] = time - buffer
                durn = time
            end
            accum = accum + durn
            table.insert(bars, {i, durn, accum})
        end

        local halfway = math.floor(accum / 2)
        for i, v in ipairs(bars) do
            if halfway <= v[3] then
                arc1[3] = v[1]
                arc1[4] = halfway - buffer
                arc2[1] = v[1]
                arc2[2] = halfway + buffer
                break
            else
                halfway = halfway - v[2]
            end
        end

        createHairpin({staff_num, arc1[1], arc1[3], arc1[2], arc1[4]}, beginning_shape)
        createHairpin({staff_num, arc2[1], arc2[3], arc2[2], arc2[4]}, end_shape)
    end

    setRange()
end

function nudge_dynamics_and_hairpins(hairpin, region, nudge_value)
    local arg_point = finale.FCPoint(0, 0)
    local left_seg = hairpin:GetTerminateSegmentLeft()
    local right_seg = hairpin:GetTerminateSegmentRight()

    region:SetStartMeasure(left_seg:GetMeasure())
    region:SetEndMeasure(right_seg:GetMeasure())
    region:SetStartMeasurePos(left_seg:GetMeasurePos())
    region:SetEndMeasurePos(right_seg:GetMeasurePos())
    region:SetStartStaff(left_seg:GetStaff())
    region:SetEndStaff(right_seg:GetStaff())

    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(region, true)
    for mark in each(ssmm) do
        local smart_shape = mark:CreateSmartShape()
        if smart_shape:IsHairpin() then
            local left_seg = smart_shape:GetTerminateSegmentLeft()
            local current_pos = left_seg:GetEndpointOffsetY()
            left_seg:SetEndpointOffsetY(current_pos + nudge_value)
            local right_seg = smart_shape:GetTerminateSegmentRight()
            current_pos = right_seg:GetEndpointOffsetY()
            right_seg:SetEndpointOffsetY(current_pos + nudge_value)
            smart_shape:Save()
        end
    end
end

function deleteHairpins()
    local del_haripin_region = finale.FCMusicRegion()
    del_haripin_region:SetCurrentSelection()
    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(del_haripin_region, true)
    for mark in eachbackwards(ssmm) do
        local sm = mark:CreateSmartShape()
        if sm ~= nil then
            if sm:IsHairpin() then
                sm:DeleteData()
            end
        end
    end
end

function createEntryBasedSL(staff, measure_start, measure_end, leftnote, rightnote, shape)
    local smartshape = finale.FCSmartShape()
    smartshape.ShapeType = shape
    smartshape:SetEntryAttachedFlags(true)
    if smartshape:IsAutoSlur() then
        smartshape:SetSlurFlags(true)
    end
    smartshape.EntryBased = true
    smartshape.PresetShape = true
    smartshape.Visible = true

    local leftseg = smartshape:GetTerminateSegmentLeft()
    leftseg:SetMeasure(measure_start)
    leftseg:SetStaff(staff)
    leftseg:SetEntry(leftnote)

    local rightseg = smartshape:GetTerminateSegmentRight()
    rightseg:SetMeasure(measure_end)
    rightseg:SetStaff(staff)
    rightseg:SetEntry(rightnote)
    if (shape == 26) or (shape == 25) then
        if (shape == 25) then
            smartshape.LineID = 1
        end
        leftseg.NoteID = 1
        rightseg.NoteID = 1
    end
    smartshape:SaveNewEverything(leftnote, rightnote)
end

function setFirstLastNoteRangeEntry(smart_shape)
    local music_region = finenv.Region()
    local range_settings = {}
    music_region:SetCurrentSelection()
    for addstaff = music_region:GetStartStaff(), music_region:GetEndStaff() do
        music_region:SetStartStaff(addstaff)
        music_region:SetEndStaff(addstaff)

        local measure_pos_table = {}
        local measure_table = {}

        local count = 0

        for noteentry in eachentrysaved(music_region) do
            if noteentry:IsNote() then
                table.insert(measure_pos_table, noteentry)
                table.insert(measure_table, noteentry:GetMeasure())
                count = count + 1
            end
        end

        local start_pos = measure_pos_table[1]
        local end_pos = measure_pos_table[count]
        local start_measure = measure_table[1]
        local end_measure = measure_table[count]

        if count ~= 0 then
            range_settings[addstaff] = {addstaff, start_measure, end_measure, start_pos, end_pos}
        end
    end

    for key, value in pairs(range_settings) do
        createEntryBasedSL(value[1], value[2], value[3], value[4], value[5], smart_shape)
    end
end

function set_first_last_note_in_range(region)

    local range_settings = false

    local notes_in_region = {}
    local note_count = 0
    for noteentry in eachentrysaved(region) do
        if noteentry:IsNote() then
            table.insert(notes_in_region, noteentry)
            note_count = note_count + 1
        end
    end

    if note_count > 0 then

        local end_cushion = false

        local start_pos = notes_in_region[1]:GetMeasurePos()

        local end_pos = notes_in_region[note_count]:GetMeasurePos()

        local start_measure = notes_in_region[1]:GetMeasure()

        local end_measure = notes_in_region[note_count]:GetMeasure()

        local staff = region:GetStartStaff()

        if notes_in_region[note_count]:GetDuration() >= 2048 then
            end_pos = end_pos + notes_in_region[note_count]:GetDuration()
            end_cushion = true
        end

        range_settings = {staff, start_measure, end_measure, start_pos, end_pos, end_cushion, notes_in_region}
    end

    return range_settings
end

function createBBSL(staff, measure_start, measure_end, leftpos, rightpos, shape, above_staff)
    local smartshape = finale.FCSmartShape()
    smartshape.ShapeType = shape
    smartshape.EntryBased = false
    smartshape.MakeHorizontal = true
    smartshape.BeatAttached = true
    smartshape.PresetShape = true
    smartshape.Visible = true
    if shape == finale.SMARTSHAPE_CUSTOM then
        local smartshapeprefs = finale.FCSmartShapePrefs()
        smartshapeprefs:Load(1)
        smartshape.LineID = smartshapeprefs:GetCustomLineDefID()
    else
        smartshape.LineID = shape
    end

    if rightpos ~= nil then
        if rightpos > 1000000 then
            local get_time = finale.FCMeasure()
            get_time:Load(measure_end)
            local new_right_end = get_time:GetTimeSignature()
            local beat = new_right_end:GetBeats()
            local duration = new_right_end:GetBeatDuration()
            rightpos = (beat * duration)
        end
    end

    local staff_pos = {}
    local count = 0
    local music_reg = finenv.Region()
    music_reg:SetStartStaff(staff)
    music_reg:SetEndStaff(staff)

    for noteentry in eachentrysaved(music_reg) do
        if noteentry:IsNote() then
            for note in each(noteentry) do
                table.insert(staff_pos, note:CalcStaffPosition())
                count = count + 1
            end
        end
    end

    local base_line_offset = 36
    local entry_offset = 36

    table.sort(staff_pos)

    if above_staff then
        if staff_pos[count] == nil then
            y_value = base_line_offset
        else
            if staff_pos[count] >= 0 then
                y_value = (staff_pos[count] * 12) + entry_offset
            else
                y_value = base_line_offset
            end
        end
    else
        base_line_offset = 54
        entry_offset = 54
        if staff_pos[1] == nil then
            y_value = 0 - (108 + base_line_offset)
        else
            if staff_pos[1] <= -9 then
                y_value = ((staff_pos[1] * 12) - entry_offset)
            else
                y_value = 0 - (108 + base_line_offset)
            end
        end
    end

    local leftseg = smartshape:GetTerminateSegmentLeft()
    leftseg:SetMeasure(measure_start)
    leftseg.Staff = staff
    leftseg:SetCustomOffset(false)
    leftseg:SetEndpointOffsetY(y_value)
    leftseg:SetMeasurePos(leftpos)

    local rightseg = smartshape:GetTerminateSegmentRight()
    rightseg:SetMeasure(measure_end)
    rightseg.Staff = staff
    rightseg:SetCustomOffset(false)
    rightseg:SetEndpointOffsetY(y_value)
    rightseg:SetMeasurePos(rightpos)
    smartshape:SaveNewEverything(nil, nil)
end

function createBeatBasedSL(smart_shape, place_above)
    local music_region = finenv.Region()
    local range_settings = {}
    music_region:SetCurrentSelection()
    for addstaff = music_region:GetStartStaff(), music_region:GetEndStaff() do
        music_region:SetStartStaff(addstaff)
        music_region:SetEndStaff(addstaff)

        local measure_pos_table = {}
        local measure_table = {}

        local count = 0

        for noteentry in eachentrysaved(music_region) do
            if noteentry:IsNote() then
                table.insert(measure_pos_table, noteentry:GetMeasurePos())
                table.insert(measure_table, noteentry:GetMeasure())
                count = count + 1
            end
        end

        local start_pos = measure_pos_table[1]
        if start_pos == nil then
            start_pos = music_region:GetStartMeasurePos()
        end

        local end_pos = measure_pos_table[count]
        if end_pos == nil then
            end_pos = music_region:GetEndMeasurePos()
        end

        local start_measure = measure_table[1]
        if start_measure == nil then
            start_measure = music_region:GetStartMeasure()
        end

        local end_measure = measure_table[count]
        if end_measure == nil then
            end_measure = music_region:GetEndMeasure()
        end

        if count == 1 then
            end_pos = music_region:GetEndMeasurePos()
        end

        range_settings[addstaff] = {addstaff, start_measure, end_measure, start_pos, end_pos}
    end

    for key, value in pairs(range_settings) do
        createBBSL(value[1], value[2], value[3], value[4], value[5], smart_shape, place_above)
    end
end

local text_expression = {}

function CreateTextExpression(exp_string_list, table_name, exp_description, category_number)
    local ex_ted = finale.FCTextExpressionDef()
    local ex_textstr = finale.FCString()
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    local fonti = cat_def:CreateTextFontInfo()
    local text_font = "^fontTxt" .. fonti:CreateEnigmaString(finale.FCString()).LuaString
    cat_def:GetMusicFontInfo(fonti)
    local music_font = "^fontMus" .. fonti:CreateEnigmaString(finale.FCString()).LuaString
    if exp_string_list[2] ~= nil then
        if tonumber(exp_string_list[2]) ~= nil then
            local exp_string_p2 = finale.FCString()
            exp_string_p2.LuaString = music_font
            exp_string_p2:AppendCharacter(exp_string_list[2])
            ex_textstr.LuaString = text_font .. exp_string_list[1] .. " " .. exp_string_p2.LuaString
        elseif tonumber(exp_string_list[1]) ~= nil then
            local exp_string_p1 = finale.FCString()
            exp_string_p1.LuaString = music_font
            exp_string_p1:AppendCharacter(exp_string_list[1])
            ex_textstr.LuaString = exp_string_p1.LuaString .. text_font .. " " .. exp_string_list[2]
        end
    else
        ex_textstr.LuaString = text_font .. exp_string_list[1]
    end
    ex_ted:SaveNewTextBlock(ex_textstr)

    local and_descriptionstr = finale.FCString()
    and_descriptionstr.LuaString = exp_description
    ex_ted:SetDescription(and_descriptionstr)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    ex_ted:AssignToCategory(cat_def)
    ex_ted:SetUseCategoryPos(true)
    ex_ted:SetUseCategoryFont(true)
    ex_ted:SaveNew()
    table.insert(table_name, ex_ted:GetItemNo())
end

function findTextExpression(exp_string_list, table_name, description_text, category_num)
    local matching_glyphs = {}
    local exp_defs = finale.FCTextExpressionDefs()
    local exp_def = finale.FCTextExpressionDef()
    exp_defs:LoadAll()
    for exp in each(exp_defs) do
        if exp:GetCategoryID() == category_num then
            local current_string = exp:CreateTextString()
            current_string:TrimEnigmaTags()
            if exp_string_list[2] ~= nil then
                if tonumber(exp_string_list[2]) ~= nil then
                    local exp_string_p2 = finale.FCString()
                    exp_string_p2.LuaString = ""
                    exp_string_p2:AppendCharacter(exp_string_list[2])
                    if current_string.LuaString == exp_string_list[1] .. " " .. exp_string_p2.LuaString then
                        table.insert(matching_glyphs, exp:GetItemNo())
                    end
                elseif tonumber(exp_string_list[1]) ~= nil then
                    local text_enigma = ""
                    local cat_def = finale.FCCategoryDef()
                    if cat_def:Load(category_num) then
                        local fonti = cat_def:CreateTextFontInfo()
                        text_enigma = fonti:CreateEnigmaString(nil).LuaString
                    end
                    local exp_string_p1 = finale.FCString()
                    exp_string_p1.LuaString = ""
                    exp_string_p1:AppendCharacter(exp_string_list[1])
                    if current_string.LuaString == exp_string_p1.LuaString .. " " .. exp_string_list[2] then
                        table.insert(matching_glyphs, exp:GetItemNo())
                    end
                end
            else
                if current_string.LuaString == exp_string_list[1] then
                    table.insert(matching_glyphs, exp:GetItemNo())
                end
            end
        end
    end
    if matching_glyphs[1] == nil then
        CreateTextExpression(exp_string_list, table_name, description_text, category_num)
    else
        exp_def:Load(matching_glyphs[1])
        table.insert(table_name, exp_def:GetItemNo())
    end
end

function multi_character_dynamic(the_expression, direction)
    local dyn_char = {150, 175, 184, 185, 112, 80, 70, 102, 196, 236, 235}
    local exp_def = the_expression:CreateTextExpressionDef()
    local exp_string = exp_def:CreateTextString()
    exp_string:TrimEnigmaTags()
    local char_to_change = 0
    local new_char = 0
    local first, last = string.find(exp_string.LuaString, "%s?sub[.]?[ito]?%s?")

    if first ~= nil then
        for index = 0, string.len(exp_string.LuaString) do
            for key, value in pairs(dyn_char) do
                if exp_string:GetCharacterAt(index) == value then
                    if direction == "increase" then
                        if key < 11 then
                            new_char = dyn_char[key + 1]
                        end
                    elseif direction == "decrease" then
                        if key > 1 then
                            new_char = dyn_char[key - 1]
                        end
                    end
                    char_to_change = index
                end
            end
        end
    end

    exp_string:DeleteCharacterAt(char_to_change)
    exp_string.LuaString = string.gsub(exp_string.LuaString, "%s", "")
    local new_description = exp_def:CreateDescription().LuaString
    new_description = string.gsub(new_description, " JetStream Addition", "")

    if first ~= 1 then
        findSpecialExpression({new_char, exp_string.LuaString}, {nil}, text_expression, new_description .. " (JetStream)", 1)
    else
        findSpecialExpression({exp_string.LuaString, new_char}, {nil}, text_expression, new_description .. " (JetStream)", 1)
    end
    addTextExpression(the_expression:GetStaff(), the_expression:GetMeasure(), the_expression:GetMeasurePos())
end

function increase_decrease_dynamics(direction)
    local single_dyn_char = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
    local dyn_char = {58662, 58665, 58666, 58667, 58656, 58668, 58669, 58658, 58671, 58672, 58673}
    local char_check = 3
    if not check_SMuFL(nil) then
        dyn_char = {150, 175, 184, 185, 112, 80, 70, 102, 196, 236, 235}
        char_check = 2
    end

    local expressions = finale.FCTextExpressionDefs()
    expressions:LoadAll()
    for exp in each(expressions) do
        if exp:GetCategoryID() == 1 then
            local exp_string = exp:CreateTextString()
            exp_string:TrimEnigmaTags()
            if string.len(exp_string.LuaString) <= char_check then
                for key, value in pairs(dyn_char) do
                    if (exp_string:GetCharacterAt(0) == value) and (exp_string:GetCharacterAt(1) == 0) then
                        single_dyn_char[key] = exp:GetItemNo()
                    end
                end
            end
        end
    end

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(finenv.Region())
    for exp in each(expressions) do
        local ex_def = exp:CreateTextExpressionDef()
        if ex_def:GetCategoryID() == 1 then
            local exp_string = ex_def:CreateTextString()
            exp_string:TrimEnigmaTags()
            if string.len(exp_string.LuaString) > char_check then
                multi_character_dynamic(exp, direction)
            else
                for key, value in pairs(dyn_char) do
                    if direction == "increase" then
                        if key < 11 then
                            if (exp_string:GetCharacterAt(0) == value) and (exp_string:GetCharacterAt(1) == 0) then
                                exp:SetID(single_dyn_char[key + 1])
                                exp:Save()
                            end
                        end
                    elseif direction == "decrease" then
                        if key > 1 then
                            if (exp_string:GetCharacterAt(0) == value) and (exp_string:GetCharacterAt(1) == 0) then
                                exp:SetID(single_dyn_char[key - 1])
                                exp:Save()
                            end
                        end
                    end
                end
            end
        end
    end
end

function dynamics_align_hairpins_and_dynamics()
    for key, region in pairs(get_region(true)) do
        local return_dynamic_region = set_first_last_note_in_range(region)
        if return_dynamic_region ~= false then
            hairpin_adjustments(return_dynamic_region, "both")
        end
    end
end

function dynamics_align_far()
    for key, region in pairs(get_region(true)) do
        local return_dynamic_region = set_first_last_note_in_range(region)
        if return_dynamic_region ~= false then
            hairpin_adjustments(return_dynamic_region, "far")
        end
    end
end

function dynamics_align_near()
    for key, region in pairs(get_region(true)) do
        local return_dynamic_region = set_first_last_note_in_range(region)
        if return_dynamic_region ~= false then
            hairpin_adjustments(return_dynamic_region, "near")
        end
    end
end

function deleteDynamics()
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(finenv.Region())
    for exp in eachbackwards(expressions) do
        local ex_def = exp:CreateTextExpressionDef()
        local cat_num = finale.FCCategoryDef()
        cat_num:Load(1)
        if ex_def:GetCategoryID(cat_num) then
            exp:DeleteData()
        end
    end
end

function deleteBeatSmartShape(shape_num)
    local music_region = finenv.Region()
    for addstaff = music_region:GetStartStaff(), music_region:GetEndStaff() do
        music_region:SetStartStaff(addstaff)
        music_region:SetEndStaff(addstaff)
        local ssmm = finale.FCSmartShapeMeasureMarks()
        ssmm:LoadAllForRegion(music_region, true)
        for mark in each(ssmm) do
            local sm = mark:CreateSmartShape()
            if sm ~= nil then
                if sm.ShapeType == shape_num then
                    if shape_num == finale.SMARTSHAPE_CUSTOM then
                        local smartshapeprefs = finale.FCSmartShapePrefs()
                        smartshapeprefs:Load(1)
                        current_custom = smartshapeprefs:GetCustomLineDefID()
                        if sm.LineID == current_custom then
                            sm:DeleteData()
                        end
                    else
                        sm:DeleteData()
                    end
                end
            end
        end
    end
end

function deleteEntrySmartShape(shape_num)
    local music_region = finenv.Region()
    for addstaff = music_region:GetStartStaff(), music_region:GetEndStaff() do
        music_region:SetStartStaff(addstaff)
        music_region:SetEndStaff(addstaff)
        for noteentry in eachentrysaved(music_region) do
            local ssmms = finale.FCSmartShapeEntryMarks(noteentry)
            ssmms:LoadAll(music_region)
            for ssmm in each(ssmms) do
                local sm = ssmm:CreateSmartShape()
                if sm ~= nil then
                    if ssmm:CalcLeftMark() or (ssmm:CalcRightMark()) then
                        if sm.ShapeType == shape_num then
                            sm:DeleteData()
                        end
                    end
                end
            end
        end
    end
end

local first_expression = {}

function add_dynamic(staff_num, measure_num, measure_pos)
    local del_region = finale.FCMusicRegion()
    del_region:SetStartStaff(staff_num)
    del_region:SetEndStaff(staff_num)
    del_region:SetStartMeasure(measure_num)
    del_region:SetEndMeasure(measure_num)
    del_region:SetStartMeasurePos(measure_pos)
    del_region:SetEndMeasurePos(measure_pos)

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(del_region)

    for e in eachbackwards(expressions) do
        local ex_def = finale.FCTextExpressionDef()
        ex_def:Load(e.ID)
        if ex_def:GetCategoryID() == 1 then
            e:DeleteData()
        end
    end

    add_expression = finale.FCExpression()
    add_expression:SetStaff(staff_num)
    add_expression:SetVisible(true)
    add_expression:SetMeasurePos(measure_pos)
    add_expression:SetScaleWithEntry(true)
    add_expression:SetPartAssignment(true)
    add_expression:SetScoreAssignment(true)
    add_expression:SetID(first_expression[1])
    local and_cell = finale.FCCell(measure_num, staff_num)
    add_expression:SaveNewToCell(and_cell)

end

function dynamic_region(note_range)
    for key, region in pairs(get_region(false)) do
        local return_dynamic_region = set_first_last_note_in_range(region)
        if return_dynamic_region ~= false then
            if note_range == "Start" then
                add_dynamic(return_dynamic_region[1], return_dynamic_region[2], return_dynamic_region[4])
            end
            if note_range == "End" then
                add_dynamic(return_dynamic_region[1], return_dynamic_region[3], return_dynamic_region[5])
            end
        end
    end
    first_expression = {}
    for key, region in pairs(get_region(true)) do
        local return_dynamic_region = set_first_last_note_in_range(region)
        if return_dynamic_region ~= false then
            hairpin_adjustments(return_dynamic_region, "both")
        end
    end
end

function create_dynamic(glyph_list, table_name, exp_description)
    local ex_ted = finale.FCTextExpressionDef()
    local ex_textstr = finale.FCString()
    ex_textstr.LuaString = "^fontMus(Font0,0)^size(24)^nfx(0)"
    for key, value in pairs(glyph_list) do
        ex_textstr:AppendCharacter(value)
    end
    ex_ted:SaveNewTextBlock(ex_textstr)

    local and_descriptionstr = finale.FCString()
    and_descriptionstr.LuaString = exp_description
    ex_ted:SetDescription(and_descriptionstr)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(1)
    ex_ted:AssignToCategory(cat_def)
    ex_ted:SetUseCategoryPos(true)
    ex_ted:SetUseCategoryFont(true)
    ex_ted:SaveNew()
    table.insert(table_name, ex_ted:GetItemNo())
end

function find_dynamic(glyph_nums, table_name, description_text, uses_smufl)
    local matching_glyphs = {}
    local exp_defs = finale.FCTextExpressionDefs()
    local exp_def = finale.FCTextExpressionDef()
    exp_defs:LoadAll()
    for exp in each(exp_defs) do
        if exp:GetCategoryID() == 1 then
            local exp_string = finale.FCString()
            exp_string.LuaString = ""
            for key, value in pairs(glyph_nums) do
                exp_string:AppendCharacter(value)
            end
            local current_string = exp:CreateTextString()
            current_string:TrimEnigmaTags()
            if uses_smufl then
                if string.len(exp_string.LuaString) > 3 then
                    if ((current_string:GetCharacterAt(3) == glyph_nums[2]) and (current_string:GetCharacterAt(0) == glyph_nums[1])) then
                        table.insert(matching_glyphs, exp:GetItemNo())
                    end
                else

                    if (current_string:GetCharacterAt(0) == glyph_nums[1]) and (string.len(current_string.LuaString) == 3) then
                        table.insert(matching_glyphs, exp:GetItemNo())
                    end
                end
            else
                if string.len(exp_string.LuaString) > 1 then
                    if ((current_string:GetCharacterAt(1) == glyph_nums[2]) and (current_string:GetCharacterAt(0) == glyph_nums[1])) then
                        table.insert(matching_glyphs, exp:GetItemNo())
                    end
                else
                    if (current_string:GetCharacterAt(0) == glyph_nums[1]) and (string.len(current_string.LuaString) == 1) then
                        table.insert(matching_glyphs, exp:GetItemNo())
                    end
                end
            end
        end
    end
    if matching_glyphs[1] == nil then
        create_dynamic(glyph_nums, table_name, description_text)
    else
        exp_def:Load(matching_glyphs[1])
        table.insert(table_name, exp_def:GetItemNo())
    end
end

function changeNoteheads(font_name, quarter_glyph, half_glyph, whole_glyph, breve_glyph)
    local use_custom = false
    if font_name == "" then
        local fontinfo = finale.FCFontInfo()
        if fontinfo:LoadFontPrefs(23) then
            font_name = getUsedFontName(fontinfo:GetName())
        end
    else
        -- font_name = getUsedFontName(font_name)
        use_custom = true
    end

    local nm = finale.FCNoteheadMod()
    nm:SetUseCustomFont(use_custom)
    if use_custom then
        nm.FontName = font_name
    end

    for noteentry in eachentrysaved(finenv.Region()) do
        nm:SetNoteEntry(noteentry)
        for note in each(noteentry) do
            nm:SetVerticalPos(0)
            if noteentry.Duration < 2048 then
                nm.CustomChar = quarter_glyph
            end
            if (noteentry.Duration >= 2048) and (noteentry.Duration < 4096) then
                nm.CustomChar = half_glyph
                if half_glyph == 124 then
                    nm:SetUseDefaultVerticalPos(false)
                    nm:SetVerticalPos(-24)
                end
            end
            if (noteentry.Duration >= 4096) and (noteentry.Duration < 8192) then
                nm.CustomChar = whole_glyph
                if half_glyph == 124 then
                    nm:SetUseDefaultVerticalPos(false)
                    nm:SetVerticalPos(-24)
                end
            end
            if (noteentry.Duration >= 8192) then
                nm.CustomChar = breve_glyph
            end
            nm:SaveAt(note)
        end
    end
end

function change_notehead_size(layer, size, resize_top_bottom)
    for noteentry in eachentrysaved(finenv.Region()) do
        if noteentry.LayerNumber == layer then
            if resize_top_bottom ~= nil then
                local nm = finale.FCNoteheadMod()
                nm:SetNoteEntry(noteentry)
                for note in each(noteentry) do
                    local top_note = noteentry:CalcHighestNote(nil)
                    local bottom_note = noteentry:CalcLowestNote(nil)
                    local note_exception = bottom_note
                    if resize_top_bottom then
                        note_exception = top_note
                    end
                    if note:CalcMIDIKey() ~= note_exception:CalcMIDIKey() then
                        nm:LoadAt(note)
                        nm:SetResize(size)
                        nm:SaveAt(note)
                    else
                        nm:LoadAt(note)
                        nm:SetResize(100)
                        nm:SaveAt(note)
                    end
                end
            else
                noteentry:SetNoteDetailFlag(true)
                local entry_mod = finale.FCEntryAlterMod()
                entry_mod:SetNoteEntry(noteentry)
                entry_mod:SetResize(size)
                entry_mod:Save()
            end
        end
    end
end

function addTextExpression(staff_num, measure_num, measure_pos)
    local del_region = finenv.Region()
    del_region:SetStartStaff(staff_num)
    del_region:SetEndStaff(staff_num)
    del_region:SetStartMeasure(measure_num)
    del_region:SetEndMeasure(measure_num)
    del_region:SetStartMeasurePos(measure_pos)
    del_region:SetEndMeasurePos(measure_pos)
    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(del_region)
    for e in each(expressions) do

        if e.ID == text_expression[1] then
            e:DeleteData()
            return
        else
            local ted = e:CreateTextExpressionDef()
            ted:Load(text_expression[1])
            if ted:GetCategoryID() == 1 then
                e:DeleteData()
            end
        end
    end
    add_expression = finale.FCExpression()
    add_expression:SetStaff(staff_num)
    add_expression:SetVisible(true)

    add_expression:SetMeasurePos(measure_pos)
    add_expression:SetScaleWithEntry(true)
    add_expression:SetPartAssignment(true)
    add_expression:SetScoreAssignment(true)
    add_expression:SetID(text_expression[1])
    local and_cell = finale.FCCell(measure_num, staff_num)
    add_expression:SaveNewToCell(and_cell)
end

function getFirstNoteInRegionText(note_range)
    local music_region = finenv.Region()
    local range_settings = {}
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            if set_first_last_note_in_range(staff:GetItemNo()) ~= false then
                music_region:SetStartStaff(staff:GetItemNo())
                music_region:SetEndStaff(staff:GetItemNo())

                local measure_pos_table = {}
                local measure_table = {}

                local count = 0

                for noteentry in eachentrysaved(music_region) do
                    if noteentry:IsNote() then
                        table.insert(measure_pos_table, noteentry:GetMeasurePos())
                        table.insert(measure_table, noteentry:GetMeasure())
                        count = count + 1
                    end
                end

                local start_pos = measure_pos_table[1]
                local start_measure = measure_table[1]
                if (note_range == "Region Start") or (start_pos == nil) then
                    start_pos = music_region:GetStartMeasurePos()
                    start_measure = music_region:GetStartMeasure()
                end
                local end_pos = measure_pos_table[count]
                local end_measure = measure_table[count]
                if (note_range == "Region End") or (end_pos == nil) then
                    end_measure = music_region:GetEndMeasure()
                    end_pos = music_region:GetEndMeasurePos()
                    if end_pos > 1000000 then
                        local get_time = finale.FCMeasure()
                        get_time:Load(end_measure)
                        local new_right_end = get_time:GetTimeSignature()
                        local beat = new_right_end:GetBeats()
                        local duration = new_right_end:GetBeatDuration()
                        end_pos = beat * duration
                    end
                end

                if count == 1 then
                    end_pos = music_region:GetEndMeasurePos()
                end

                if (start_pos ~= nil) or (end_pos ~= nil) or (start_measure ~= nil) or (end_measure ~= nil) then
                    range_settings[staff:GetItemNo()] = {staff:GetItemNo(), start_measure, end_measure, start_pos, end_pos}
                end
            end
        end
    end

    for key, value in pairs(range_settings) do
        if (note_range == "Start") or (note_range == "Region Start") then
            addTextExpression(value[1], value[2], value[4])
        end
        if (note_range == "End") or (note_range == "Region End") then
            addTextExpression(value[1], value[3], value[5])
        end
    end
end

function CreateSpecialTextExpression(exp_string, table_name, exp_description, category_number)
    local ex_ted = finale.FCTextExpressionDef()
    local ex_textstr = finale.FCString()
    ex_textstr.LuaString = exp_string

    ex_ted:SaveNewTextBlock(ex_textstr)

    local and_descriptionstr = finale.FCString()
    and_descriptionstr.LuaString = exp_description
    ex_ted:SetDescription(and_descriptionstr)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(category_number)
    ex_ted:AssignToCategory(cat_def)
    ex_ted:SetUseCategoryPos(true)
    ex_ted:SetUseCategoryFont(false)
    ex_ted:SaveNew()
    table.insert(table_name, ex_ted:GetItemNo())
end

function findSpecialExpression(exp_string_list, font_details, table_name, description_text, category_num)
    local matching_glyphs = {}
    local exp_defs = finale.FCTextExpressionDefs()
    local exp_def = finale.FCTextExpressionDef()
    local music_font_string = finale.FCString()
    local text_font_string = finale.FCString()
    local full_string = ""

    if font_details[1] == nil then
        local cat_def = finale.FCCategoryDef()
        if cat_def:Load(category_num) then
            local fonti = finale.FCFontInfo()
            if cat_def:GetMusicFontInfo(fonti) then
                music_font_string.LuaString = fonti:CreateEnigmaString(nil).LuaString
            end
            if cat_def:GetTextFontInfo(fonti) then
                text_font_string.LuaString = fonti:CreateEnigmaString(nil).LuaString
            end
        end
    end

    exp_defs:LoadAll()
    local already_exists = 0

    if #exp_string_list == 1 then
        if tonumber(exp_string_list[1]) ~= nil then
            if font_details[1] ~= nil then
                music_font_string.LuaString = "%^fontMus%(" .. font_details[1] .. "," .. font_details[2] .. "%)%^size%(" .. font_details[3] .. "%)%^nfx%(" .. font_details[4] ..
                                                  "%)"
                music_font_string:AppendCharacter(exp_string_list[1])
                full_string = string.gsub(music_font_string.LuaString, "%%", "")
            else
                music_font_string:AppendCharacter(exp_string_list[1])
                full_string = music_font_string.LuaString
            end
        else
            if font_details[1] ~= nil then
                text_font_string.LuaString =
                    "%^fontTxt%(" .. font_details[1] .. "," .. font_details[2] .. "%)%^size%(" .. font_details[3] .. "%)%^nfx%(" .. font_details[4] .. "%)" .. exp_string_list[1]
                full_string = string.gsub(text_font_string.LuaString, "%%", "")
            else
                text_font_string.LuaString = text_font_string.LuaString .. exp_string_list[1]
                full_string = text_font_string.LuaString
            end
        end
    else
        if tonumber(exp_string_list[1]) ~= nil then
            if font_details[1] ~= nil then
                music_font_string.LuaString = "%^fontMus%(" .. font_details[1] .. "," .. font_details[2] .. "%)%^size%(" .. font_details[3] .. "%)%^nfx%(" .. font_details[4] ..
                                                  "%)"
                music_font_string:AppendCharacter(exp_string_list[1])
                text_font_string.LuaString =
                    "%^fontTxt%(" .. font_details[1] .. "," .. font_details[2] .. "%)%^size%(" .. font_details[3] .. "%)%^nfx%(" .. font_details[4] .. "%)" .. exp_string_list[2]
                full_string = string.gsub(music_font_string.LuaString .. " " .. text_font_string.LuaString, "%%", "")
            else
                music_font_string:AppendCharacter(exp_string_list[1])
                text_font_string.LuaString = text_font_string.LuaString .. exp_string_list[2]
                full_string = music_font_string.LuaString .. " " .. text_font_string.LuaString
            end
        else
            if font_details[1] ~= nil then
                text_font_string.LuaString =
                    "%^fontTxt%(" .. font_details[1] .. "," .. font_details[2] .. "%)%^size%(" .. font_details[3] .. "%)%^nfx%(" .. font_details[4] .. "%)" .. exp_string_list[1]
                music_font_string.LuaString = "%^fontMus%(" .. font_details[1] .. "," .. font_details[2] .. "%)%^size%(" .. font_details[3] .. "%)%^nfx%(" .. font_details[4] ..
                                                  "%)"
                music_font_string:AppendCharacter(exp_string_list[2])
                full_string = string.gsub(text_font_string.LuaString .. " " .. music_font_string.LuaString, "%%", "")

            else
                text_font_string.LuaString = text_font_string.LuaString .. exp_string_list[1]
                music_font_string:AppendCharacter(exp_string_list[2])
                full_string = text_font_string.LuaString .. " " .. music_font_string.LuaString
            end
        end
    end

    local full_enigma_string = finale.FCString()
    full_enigma_string.LuaString = full_string
    full_enigma_string:TrimEnigmaTags()

    for exp in each(exp_defs) do
        if exp:GetCategoryID() == category_num then
            local exp_string = exp:CreateTextString()
            exp_string:TrimEnigmaTags()
            if exp_string.LuaString == full_enigma_string.LuaString then
                already_exists = exp:GetItemNo()
                table.insert(matching_glyphs, already_exists)
            end
        end
    end

    if matching_glyphs[1] == nil then
        CreateSpecialTextExpression(full_string, table_name, description_text, category_num)
    else
        exp_def:Load(matching_glyphs[1])
        table.insert(table_name, exp_def:GetItemNo())
    end
end

function barline_change(style, bookend)
    local measure = finale.FCMeasure()
    local music_region = finenv.Region()
    if bookend then
        measure:Load(music_region:GetStartMeasure() - 1)
        measure.Barline = style
        measure:Save()
    end
    measure:Load(music_region:GetEndMeasure())
    measure.Barline = style
    measure:Save()
end

function add_rehearsal_marks(measure_num, reh_type)
    local teds = finale.FCTextExpressionDefs()
    teds:LoadAll()
    local rehearsal_letters = {}
    local rehearsal_numbers = {}
    local rehearsal_measures = {}
    for ted in each(teds) do
        if ted:GetCategoryID() == 6 then
            if (ted:IsAutoRehearsalMark()) and (ted:GetRehearsalMarkStyle() == 1) then
                table.insert(rehearsal_letters, ted.ItemNo)
            end
            if (ted:IsAutoRehearsalMark()) and (ted:GetRehearsalMarkStyle() == 5) then
                table.insert(rehearsal_numbers, ted.ItemNo)
            end
            if (ted:IsAutoRehearsalMark()) and (ted:GetRehearsalMarkStyle() == 6) then
                table.insert(rehearsal_measures, ted.ItemNo)
            end
        end
    end

    local rehearsal_staff = {}

    function get_rehearsal_staves()
        local item_num = 0
        local sll = finale.FCStaffListLookup()
        if (sll:LoadCategoryList(6)) then
            local sl = finale.FCStaffList()
            sl:SetMode(finale.SLMODE_CATEGORY_SCORE)
            if sl:LoadFirst() then
                item_num = sl:GetItemNo()
                if (sl:IncludesTopStaff()) then
                    table.insert(rehearsal_staff, 1)
                end
                local staves = finale.FCStaves()
                staves:LoadAll()
                for staff in each(staves) do
                    if sl:IncludesStaff(staff:GetItemNo()) then
                        table.insert(rehearsal_staff, staff:GetItemNo())
                    end
                end
            end
        end
    end

    function add_marks(exp_id)
        local add_expression = finale.FCExpression()
        for key, value in pairs(rehearsal_staff) do
            add_expression:SetPartAssignment(false)
            add_expression:SetScoreAssignment(true)
            add_expression:SetStaff(value)
            add_expression:SetStaffGroupID(1)
            add_expression:SetStaffListID(1)
            add_expression:SetVisible(true)
            add_expression:SetID(exp_id)
            local and_cell = finale.FCCell(measure_num, value)
            add_expression:SaveNewToCell(and_cell)
        end
        add_expression:SetPartAssignment(true)
        add_expression:SetScoreAssignment(false)
        add_expression:SetStaff(-1)
        add_expression:SetStaffGroupID(1)
        add_expression:SetStaffListID(1)
        add_expression:SetVisible(true)
        add_expression:SetID(exp_id)
        local and_cell = finale.FCCell(measure_num, -1)
        add_expression:SaveNewToCell(and_cell)
    end

    if reh_type == "Letter" then
        if rehearsal_letters[1] == nil then
            finenv.UI():AlertInfo("There doesn't appear to be any Auto-Rehearsal Marks using Letters in the Rehearsal Marks Category. Please create one and try again.", NULL)
        else
            get_rehearsal_staves()
            add_marks(rehearsal_letters[1])
        end
    end
    if reh_type == "Number" then
        if rehearsal_numbers[1] == nil then
            finenv.UI():AlertInfo("There doesn't appear to be any Auto-Rehearsal Marks using Numbers in the Rehearsal Marks Category. Please create one and try again.", NULL)
        else
            get_rehearsal_staves()
            add_marks(rehearsal_numbers[1])
        end
    end
    if reh_type == "Measure" then
        if rehearsal_measures[1] == nil then
            finenv.UI():AlertInfo(
                "There doesn't appear to be any Auto-Rehearsal Marks using Measure Numbers in the Rehearsal Marks Category. Please create one and try again.", NULL)
        else
            get_rehearsal_staves()
            add_marks(rehearsal_measures[1])
        end
    end
end

function delete_rehearsal_marks()
    local expressions = finale.FCExpressions()
    local music_reg = finenv.Region()
    expressions:LoadAllForItem(music_reg:GetEndMeasure() + 1)
    for e in each(expressions) do
        local ex_def = finale.FCTextExpressionDef()
        ex_def:Load(e.ID)
        if ex_def:GetCategoryID() == 6 then
            local the_staves = finenv.Region()
            the_staves:SetFullDocument()
            for addstaff = the_staves.StartStaff, the_staves.EndStaff do
                if music_reg:IsStaffIncluded(addstaff) then
                    e:DeleteData()
                end
            end
        end
    end
end

function find_double_barlines(rehearsal_mark_type)
    delete_rehearsal_marks()
    local measures = finale.FCMeasures()
    local the_region = finenv.Region()
    the_region:SetCurrentSelection()
    measures:LoadRegion(the_region)
    for m in each(measures) do
        if m.Barline == 2 then
            add_rehearsal_marks(m.ItemNo + 1, rehearsal_mark_type)
        end
    end
end

function alter_bass(placement)
    local chords = finale.FCChords()
    chords:LoadAllForRegion(finenv.Region())
    for c in each(chords) do
        c.ChordAlternateBassPlacement = placement
        c:Save()
    end
end

function set_time(beat_num, beat_dur, beat_abbr)

    local function make_change(beat_number, beat_duration, the_measure, abbr_bool)
        local time_sig = the_measure:GetTimeSignature()
        time_sig:SetBeats(beat_number)
        time_sig:SetBeatDuration(beat_duration)
        if ((beat_number == 2 and beat_duration == 2048) or (beat_number == 4 and beat_duration == 1024)) then
            local miscdocprefs = finale.FCMiscDocPrefs()
            miscdocprefs:Load(1)
            if beat_number == 2 then
                miscdocprefs:SetAbbreviateCutTimeSig(abbr_bool)
            elseif beat_number == 4 then
                miscdocprefs:SetAbbreviateCommonTimeSig(abbr_bool)
            end
            miscdocprefs:Save()
        end
        time_sig:SetAbbreviate(abbr_bool)
        time_sig:Save()
        the_measure:Save()
    end

    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())
    if measures.Count > 1 then
        for measure in each(measures) do
            make_change(beat_num, beat_dur, measure, beat_abbr)
        end
    else
        local all_measures = finale.FCMeasures()
        all_measures:LoadAll()
        for measure in each(all_measures) do
            local selected_measure = measures:GetItemAt(0)
            if (measure.ItemNo >= selected_measure.ItemNo) then
                make_change(beat_num, beat_dur, measure, beat_abbr)
            end
        end
    end
end

function applyStaffStyle(StaffStyleType)
    local ssds = finale.FCStaffStyleDefs()
    ssds:LoadAll()
    style_table = {}
    for ssd in each(ssds) do
        if StaffStyleType == "Slash Notation" then
            if ssd:GetAltNotationStyle() == 1 then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Rythmic Notation" then
            if ssd:GetAltNotationStyle() == 2 then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Blank Notation: Layer 1" then
            if (ssd:GetAltNotationStyle() == 6) and (ssd:GetAltNotationLayer() == 1) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Blank Notation with Rests: Layer 1" then
            if (ssd:GetAltNotationStyle() == 5) and (ssd:GetAltNotationLayer() == 1) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Blank Notation: Layer 4" then
            if (ssd:GetAltNotationStyle() == 6) and (ssd:GetAltNotationLayer() == 4) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Blank Notation with Rests: Layer 4" then
            if (ssd:GetAltNotationStyle() == 5) and (ssd:GetAltNotationLayer() == 4) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Blank Notation: All Layers" then
            if (ssd:GetAltNotationStyle() == 6) and (ssd:GetShowChords() == false) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "One Bar Repeat" then
            if (ssd:GetAltNotationStyle() == 3) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Two Bar Repeat" then
            if (ssd:GetAltNotationStyle() == 4) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Stemless Notes" then
            if (ssd:GetShowStems() == false) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Cutaway" then
            if (ssd:GetUseHideMode() == true) and (ssd:GetHideMode() == 3) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
        if StaffStyleType == "Collapse" then
            if (ssd:GetUseHideMode() == true) and (ssd:GetHideMode() == 2) then
                table.insert(style_table, ssd:GetItemNo())
            end
        end
    end

    local staff_style_ID = style_table[1]

    if staff_style_ID == nil then
        finenv.UI():AlertInfo("That kind of staff style couldn't be found...\n\nPlease try creating it or uploading the default staff style library and try again.", nil)
        return
    else
        local music_region = finenv.Region()
        for addstaff = music_region:GetStartStaff(), music_region:GetEndStaff() do
            if music_region:IsStaffIncluded(addstaff) then
                local start_meas = music_region:GetStartMeasure()
                local end_meas = music_region:GetEndMeasure()
                local start_pos = music_region:GetStartMeasurePos()
                local end_pos = music_region:GetEndMeasurePos()
                music_region:SetStartStaff(addstaff)
                music_region:SetEndStaff(addstaff)
                local staff_style = finale.FCStaffStyleAssign()
                staff_style:SetStartMeasure(start_meas)
                staff_style:SetEndMeasure(end_meas)
                staff_style:SetStartMeasurePos(start_pos)
                staff_style:SetEndMeasurePos(end_pos)
                staff_style:SetStyleID(staff_style_ID)
                staff_style:SaveNew(addstaff)
            end
        end
    end
end

function playback_type(start_meas, end_meas, playback_staves)
    local pbs = finale.FCPlaybackPrefs()
    local mus_reg = finenv.Region()
    pbs:Load(1)
    if start_meas == "Region" then
        mus_reg:SetCurrentSelection()
        pbs:SetStartMeasure(mus_reg:GetStartMeasure())
    elseif start_meas == "Document" then
        mus_reg:SetFullDocument()
        pbs:SetStartMeasure(mus_reg:GetStartMeasure())
    end
    if end_meas == "Region" then
        mus_reg:SetCurrentSelection()
        pbs:SetStopMeasure(mus_reg:GetEndMeasure())
    elseif end_meas == "Document" then
        mus_reg:SetFullDocument()
        pbs:SetStopMeasure(mus_reg:GetEndMeasure())
    end
    pbs:Save()
    pbs:Reload()
    mus_reg:SetCurrentSelection()
    local fulldocregion = finale.FCMusicRegion()
    fulldocregion:SetFullDocument()
    for slot = fulldocregion.StartSlot, fulldocregion.EndSlot do
        local staffnumber = mus_reg:CalcStaffNumber(slot)
        local staff = finale.FCStaff()
        staff:Load(staffnumber)
        local playbackdata = staff:CreateInstrumentPlaybackData()
        for layer = 1, 4 do
            local layerdef = playbackdata:GetNoteLayerData(layer)
            if playback_staves == "Document" then
                layerdef.Play = true
            elseif playback_staves == "Region" then
                layerdef.Play = mus_reg:IsStaffIncluded(staffnumber)
            end
        end
        playbackdata:Save()
    end
end

function measureWidth(direction_change)
    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())

    for m in each(measures) do
        if direction_change == "Increase" then
            m:SetWidth(m:GetWidth() / 0.95)
        elseif direction_change == "Decrease" then
            m:SetWidth(m:GetWidth() * 0.95)
        end
        m:Save()
    end
end

function tuplet_options(tuplet_parameters)
    for noteentry in eachentry(finenv.Region()) do
        local t = finale.FCTuplet()
        t:SetNoteEntry(noteentry)
        if t:LoadFirst() then
            for key, value in pairs(tuplet_parameters) do
                if value == "Always Flat On" then
                    t:SetAlwaysFlat(true)
                elseif value == "Always Flat Off" then
                    t:SetAlwaysFlat(false)
                elseif value == "Allow Horizontal Drag On" then
                    t:SetAllowHorizontalDrag(true)
                elseif value == "Allow Horizontal Drag Off" then
                    t:SetAllowHorizontalDrag(false)
                elseif value == "Bottom Note On" then
                    t:SetUseBottomNote(true)
                elseif value == "Bottom Note Off" then
                    t:SetUseBottomNote(false)
                elseif value == "Engraver On" then
                    t:SetEngraverTuplet(true)
                elseif value == "Engraver Off" then
                    t:SetEngraverTuplet(false)
                elseif value == "Avoid Staff On" then
                    t:SetAvoidStaff(true)
                elseif value == "Avoid Staff Off" then
                    t:SetAvoidStaff(false)
                elseif value == "Bracket Always" then
                    t:SetBracketMode(0)
                elseif value == "Center Duration On" then
                    t:SetCenterUsingDuration(true)
                elseif value == "Center Duration Off" then
                    t:SetCenterUsingDuration(false)
                elseif value == "Ignore Horizontal On" then
                    t:SetIgnoreNumberOffset(true)
                elseif value == "Ignore Horizontal Off" then
                    t:SetIgnoreNumberOffset(false)
                elseif value == "Full Duration On" then
                    t:SetBracketFullDuration(true)
                elseif value == "Full Duration Off" then
                    t:SetBracketFullDuration(false)
                elseif value == "Match Hooks On" then
                    t:SetMatchHookLengths(true)
                elseif value == "Match Hooks Off" then
                    t:SetMatchHookLengths(false)
                elseif value == "Bracket Unbeamed" then
                    t:SetBracketMode(1)
                elseif value == "Bracket Never Beamed" then
                    t:SetBracketMode(2)
                elseif value == "Placement Manual" then
                    t:SetPlacementMode(0)
                elseif value == "Placement Stem" then
                    t:SetPlacementMode(1)
                elseif value == "Placement Note" then
                    t:SetPlacementMode(2)
                elseif value == "Placement Above" then
                    t:SetPlacementMode(3)
                elseif value == "Placement Below" then
                    t:SetPlacementMode(4)
                elseif value == "Increase Space" then
                    t:SetVerticalOffset(t:GetVerticalOffset() + 9)
                elseif value == "Decrease Space" then
                    if (t:GetVerticalOffset() - 9) > 0 then
                        t:SetVerticalOffset(t:GetVerticalOffset() - 9)
                    end
                elseif value == "Increase Bracket" then
                    if t:GetVerticalOffset() == 24 then
                        t:SetVerticalOffset(t:GetVerticalOffset() + 18)
                    end
                    t:SetLeftHookLength(t:GetLeftHookLength() + 9)
                    t:SetRightHookLength(t:GetRightHookLength() + 9)
                    t:SetVerticalOffset(t:GetVerticalOffset() + 9)
                elseif value == "Decrease Bracket" then
                    if (t:GetVerticalOffset() - 9) > 24 then
                        t:SetVerticalOffset(t:GetVerticalOffset() - 9)
                    end
                    if (t:GetLeftHookLength() - 9) > 12 then
                        t:SetLeftHookLength(t:GetLeftHookLength() - 9)
                    end
                    if (t:GetRightHookLength() - 9) > 12 then
                        t:SetRightHookLength(t:GetRightHookLength() - 9)
                    end
                elseif value == "Shape None" then
                    t:SetShapeStyle(0)
                elseif value == "Shape Bracket" then
                    t:SetShapeStyle(1)
                elseif value == "Shape Slur" then
                    t:SetShapeStyle(2)
                elseif value == "Number None" then
                    t:SetNumberStyle(0)
                elseif value == "Number Regular" then
                    t:SetNumberStyle(1)
                elseif value == "Number Ratio" then
                    t:SetNumberStyle(2)
                elseif value == "Number Ratio Last" then
                    t:SetNumberStyle(3)
                elseif value == "Number Ratio Both" then
                    t:SetNumberStyle(4)
                end
            end
            t:Save()
        end
    end
end

function clef_change_pre(clef)
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            clef_change(clef, staff:GetItemNo(), music_region)
        end
    end
end

function clef_change(clef_type, staff, region)
    local cell_frame = finale.FCCellFrameHold()
    for i, j in eachcell(region) do
        local cell = finale.FCCell(i, j)
        if (region:IsFullMeasureIncluded(region:GetStartMeasure()) == false) or (region:IsFullMeasureIncluded(region:GetEndMeasure()) == false) then
            cell_frame:ConnectCell(cell)
            if cell_frame:Load() then
                local mid_measure_clef = cell_frame:CreateCellClefChanges()
                if mid_measure_clef == nil then
                    mid_measure_clef:SaveNew(2)
                end
                for item in each(mid_measure_clef) do
                    if (item:GetMeasurePos() ~= 0) or (item:GetMeasurePos() ~= region:GetEndMeasurePos()) then
                        item:SetMeasurePos(item:GetMeasurePos())
                        item:SetClefIndex(clef_type)
                        item:Save()
                    end
                end
            end
        else
            cell_frame:ConnectCell(cell)
            if cell_frame:Load() then
                cell_frame:SetClefIndex(clef_type)
                cell_frame:Save()
            else
                cell_frame:SetClefIndex(clef_type)
                cell_frame:SaveNew()
            end
        end
    end
end

function clef_change_bass()

    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            clef_change(3, staff:GetItemNo(), music_region)
        end
    end
end

function single_pitch(pitch)
    pitchstring = finale.FCString()
    pitchstring.LuaString = pitch
    writtenpitch = true
    for e in eachentrysaved(finenv.Region()) do
        if e:IsNote() then
            local note_count = e.Count
            while e.Count > 1 do
                local lowestnote = e:CalcLowestNote(nil)
                e:DeleteNote(lowestnote)
            end
            e:GetItemAt(0):SetString(pitchstring, nil, writtenpitch)
            e.CheckAccidentals = true
        end
    end
end

function transpose_semitones(pitch_difference)
    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            for note in each(entry) do
                local midi = note:CalcMIDIKey()
                note:SetMIDIKey(midi + pitch_difference)
            end
        end
    end
end

-- function move_markers(marker_pos)

--     function first_and_last()
--         local selected_measures = {}
--         local systems_selected = {}
--         local music_region = finenv.Region()
--         music_region:SetCurrentSelection()
--         for i = music_region:GetStartMeasure(), music_region:GetEndMeasure() do
--            table.insert(selected_measures, i)
--         end

--         local staff_sys = finale.FCStaffSystems()
--         staff_sys:LoadAll()
--         for sys in each(staff_sys) do
--             for key, value in pairs(selected_measures) do
--                 if sys:GetFirstMeasure() == value then
--                     table.insert(systems_selected, sys:GetItemNo())
--                 end
--             end
--         end
--         if finenv.Region():IsEmpty() ~= nil then
--             if (#systems_selected > 0) then
--                 local m, n = systems_selected[1], systems_selected[#systems_selected]
--                 return m, n
--             else
--                 finenv.UI():AlertInfo("Please either select a region that has rehearsal markers or deselect your region to apply to the entire document and try again.", "No Rehearsal Markers in Region")
--                 return false
--             end
--         elseif (#systems_selected > 0) and (finenv.Region():IsEmpty() == nil) then
--             local m, n = 1, staff_sys:LoadAll()
--             return m, n
--         end
--     end
--     print("blah!", first_and_last(0), first_and_last())
--    --[[ if first_and_last() ~= false then
--         local sys = finale.FCStaffSystem()
--         for i = (start, last = first_and_last()) do
--             sys:Load(i)
--             local exps = finale.FCExpressions()
--             local first_meas = sys:GetFirstMeasure()
--             local first_staff = sys:CalcTopStaff()
--             exps:LoadAllForItem(sys:GetFirstMeasure())
--             local distanceprefs = finale.FCDistancePrefs()
--             distanceprefs:Load(1)
--             local space_before_clef = distanceprefs:GetClefSpaceBefore()
--             for exp in each(exps) do
--                 local ted = finale.FCTextExpressionDef()
--                 ted:Load(exp:GetID())
--                 if ted:IsAutoRehearsalMark() then
--                     local first_region = finenv.Region()
--                     first_region:SetStartMeasure(first_meas)
--                     first_region:SetEndMeasure(first_meas)
--                     first_region:SetStartStaff(first_staff)
--                     first_region:SetEndStaff(first_staff)
--                     for m, s in eachcell(first_region) do
--                        local cellpos = finale.FCCellPos(m, s, 0)
--                        local clef_id = cellpos:CalcClefIndex()
--                         if (clef_id == 0) or (clef_id == 5) or (clef_id == 8) or (clef_id == 13) then
--                             if marker_pos == "Clef Center" then
--                                 exp:SetHorizontalPos(space_before_clef + 42)
--                             end
--                         elseif (clef_id == 3) or (clef_id == 6) or (clef_id == 7) or (clef_id == 14) then
--                             if marker_pos == "Clef Center" then
--                                 exp:SetHorizontalPos(space_before_clef + 32)
--                             end
--                          elseif clef_id == 12 then
--                             if marker_pos == "Clef Center" then
--                                 exp:SetHorizontalPos(space_before_clef + 16)
--                             end
--                          elseif (clef_id == 1) or (clef_id == 2) or (clef_id == 9) or (clef_id == 10) or (clef_id == 11) then
--                             if marker_pos == "Clef Center" then
--                                 exp:SetHorizontalPos(space_before_clef + 31)
--                             end
--                         end
--                     end
--                     exp:Save()
--                 end
--             end
--         end
--     end]]--
-- end

-- move_markers("Clef Center")

function staff_spacing_adjust(moveBy)
    local music_region = finenv.Region()
    local regionCount = 1
    local staffCount = 1
    local moveCount = 1
    local totalMove = 0
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(music_region)
    local allstaves = finale.FCSystemStaves()
    local regionStaves = {}

    local start_measure = music_region:GetStartMeasure()
    local end_measure = music_region:GetEndMeasure()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()

    for sys in each(sysstaves) do
        local staffNum = sys.Staff
        table.insert(regionStaves, staffNum)
        regionCount = regionCount + 1
    end

    for i = system_number, lastSys_number do
        allstaves:LoadAllForItem(i)
        staffCount = 1
        moveCount = 1
        totalMove = 0
        for sys in each(allstaves) do
            local staffNum = sys.Staff
            for j = 1, regionCount, 1 do
                if staffNum == regionStaves[j] then
                    staffCount = j
                end
            end
            if staffNum == regionStaves[staffCount] then
                local ss = finale.FCStaffSystem()
                ss:Load(sys:GetItemCmper())
                if sys:GetStaff() ~= ss:CalcTopStaff() then
                    sys:SetDistance(sys:GetDistance() + (moveBy * moveCount))
                    sys:Save()
                    totalMove = totalMove + moveBy
                    moveCount = moveCount + 1
                end
                staffCount = staffCount + 1
            elseif regionStaves[staffCount] == nil then
                local moveTo = sys:GetDistance() + totalMove
                sys.Distance = moveTo
                sys:Save()
            else
            end
        end
    end
end

function swap_layers(swap_first, swap_second)
    local region = finenv.Region()
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local sys_staves = finale.FCSystemStaves()
    sys_staves:LoadAllForRegion(region)

    swap_first = swap_first - 1
    swap_second = swap_second - 1

    for sys_staff in each(sys_staves) do
        staff_num = sys_staff.Staff
        local noteentry_layer_first = finale.FCNoteEntryLayer(swap_first, staff_num, start, stop)
        noteentry_layer_first:SetUseVisibleLayer(false)
        if noteentry_layer_first:Load() then
            noteentry_layer_first.LayerIndex = swap_second
        end

        local noteentry_layer_second = finale.FCNoteEntryLayer(swap_second, staff_num, start, stop)
        noteentry_layer_second:SetUseVisibleLayer(false)
        if noteentry_layer_second:Load() then
            noteentry_layer_second.LayerIndex = swap_first
        end
        noteentry_layer_first:Save()
        noteentry_layer_second:Save()
    end
end

function clear_Layer(lyr)
    lyr = lyr - 1
    local region = finenv.Region()
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local sysstaves = finale.FCSystemStaves()
    sysstaves:LoadAllForRegion(region)
    for sysstaff in each(sysstaves) do
        staffNum = sysstaff.Staff
        local noteentrylayer = finale.FCNoteEntryLayer(lyr, staffNum, start, stop)
        noteentrylayer:Load()
        noteentrylayer:ClearAllEntries()
    end
end

function user_expression_input(the_expression)
    local text_expression = {}

    function add_text_expression(staff_num, measure_num, measure_pos)
        local del_region = finenv.Region()
        del_region:SetStartStaff(staff_num)
        del_region:SetEndStaff(staff_num)
        del_region:SetStartMeasure(measure_num)
        del_region:SetEndMeasure(measure_num)
        del_region:SetStartMeasurePos(measure_pos)
        del_region:SetEndMeasurePos(measure_pos)
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(del_region)
        for e in each(expressions) do
            if e.ID == text_expression[1] then
                e:DeleteData()
                return
            end
        end
        local add_expression = finale.FCExpression()
        add_expression:SetStaff(staff_num)
        add_expression:SetVisible(true)
        add_expression:SetMeasurePos(measure_pos)
        add_expression:SetScaleWithEntry(true)
        add_expression:SetPartAssignment(true)
        add_expression:SetScoreAssignment(true)
        add_expression:SetID(text_expression[1])
        local and_cell = finale.FCCell(measure_num, staff_num)
        add_expression:SaveNewToCell(and_cell)
    end

    local staff_list = {}

    function get_tempo_staves()
        local item_num = 0
        local sll = finale.FCStaffListLookup()
        if (sll:LoadCategoryList(2)) then
            local sl = finale.FCStaffList()
            sl:SetMode(finale.SLMODE_CATEGORY_SCORE)
            if sl:LoadFirst() then
                item_num = sl:GetItemNo()
                if (sl:IncludesTopStaff()) then
                    table.insert(staff_list, 1)
                end
                local staves = finale.FCStaves()
                staves:LoadAll()
                for staff in each(staves) do
                    if sl:IncludesStaff(staff:GetItemNo()) then
                        table.insert(staff_list, staff:GetItemNo())
                    end
                end
            end
        end
    end

    function add_tempo(measure_num)
        local count = 0
        local add_expression = finale.FCExpression()
        for key, value in pairs(staff_list) do
            add_expression:SetPartAssignment(false)
            add_expression:SetScoreAssignment(true)
            add_expression:SetStaff(value)
            add_expression:SetStaffGroupID(1)
            add_expression:SetStaffListID(1)
            add_expression:SetVisible(true)
            add_expression:SetID(text_expression[1])
            local and_cell = finale.FCCell(measure_num, value)
            add_expression:SaveNewToCell(and_cell)
            count = count + 1
        end
        add_expression:SetPartAssignment(true)
        add_expression:SetScoreAssignment(false)
        add_expression:SetStaff(-1)
        add_expression:SetStaffGroupID(1)
        add_expression:SetStaffListID(1)
        add_expression:SetVisible(true)
        add_expression:SetID(text_expression[1])
        local and_cell = finale.FCCell(measure_num, -1)
        add_expression:SaveNewToCell(and_cell)
    end

    function text_expression_region(note_range)
        local music_region = finenv.Region()
        local range_settings = {}

        for addstaff = music_region:GetStartStaff(), music_region:GetEndStaff() do
            if music_region:IsStaffIncluded(addstaff) then

                music_region:SetStartStaff(addstaff)
                music_region:SetEndStaff(addstaff)

                local measure_pos_table = {}
                local measure_table = {}

                local count = 0

                for noteentry in eachentrysaved(music_region) do
                    if noteentry:IsNote() then
                        table.insert(measure_pos_table, noteentry:GetMeasurePos())
                        table.insert(measure_table, noteentry:GetMeasure())
                        count = count + 1
                    end
                end

                local start_pos = measure_pos_table[1]
                local start_measure = measure_table[1]
                if (note_range == "Region Start") or (start_pos == nil) then
                    start_pos = music_region:GetStartMeasurePos()
                    start_measure = music_region:GetStartMeasure()
                elseif note_range == "Tempo" then
                    start_measure = music_region:GetStartMeasure()
                    start_pos = 0
                end
                local end_pos = measure_pos_table[count]
                local end_measure = measure_table[count]
                if (note_range == "Region End") or (end_pos == nil) then
                    end_measure = music_region:GetEndMeasure()
                    end_pos = music_region:GetEndMeasurePos()
                    if end_pos > 1000000 then
                        local get_time = finale.FCMeasure()
                        get_time:Load(end_measure)
                        local new_right_end = get_time:GetTimeSignature()
                        local beat = new_right_end:GetBeats()
                        local duration = new_right_end:GetBeatDuration()
                        end_pos = beat * duration
                    end
                end

                if count == 1 then
                    end_pos = music_region:GetEndMeasurePos()
                end

                if (start_pos ~= nil) or (end_pos ~= nil) or (start_measure ~= nil) or (end_measure ~= nil) then
                    range_settings[addstaff] = {addstaff, start_measure, end_measure, start_pos, end_pos}
                end
            end
        end

        for key, value in pairs(range_settings) do
            if (note_range == "Start") or (note_range == "Region Start") then
                add_text_expression(value[1], value[2], value[4])
            end
            if (note_range == "End") or (note_range == "Region End") then
                add_text_expression(value[1], value[3], value[5])
            end
            if note_range == "Tempo" then
                get_tempo_staves()
                add_tempo(value[2])
            end
        end
    end

    function create_text_expression(text, category)
        local cat_def = finale.FCCategoryDef()
        cat_def:Load(category)
        local fonti = cat_def:CreateTextFontInfo()
        local text_font = "^fontTxt" .. fonti:CreateEnigmaString(finale.FCString()).LuaString
        local full_string = text_font .. text

        local exp_ted = finale.FCTextExpressionDef()
        local exp_str = finale.FCString()
        exp_str.LuaString = full_string
        exp_ted:SaveNewTextBlock(exp_str)
        local and_descriptionstr = finale.FCString()
        and_descriptionstr.LuaString = text
        exp_ted:SetDescription(and_descriptionstr)
        local cat_def = finale.FCCategoryDef()
        cat_def:Load(category)
        exp_ted:AssignToCategory(cat_def)
        exp_ted:SetUseCategoryPos(true)
        exp_ted:SaveNew()
        local item_no = exp_ted:GetItemNo()
        table.insert(text_expression, item_no)
    end

    function create_tempo_expression(text, category)
        local exp_ted = finale.FCTextExpressionDef()
        local exp_str = finale.FCString()
        exp_str.LuaString = text
        exp_ted:SaveNewTextBlock(exp_str)
        local and_descriptionstr = finale.FCString()
        local description_text = ""
        and_descriptionstr.LuaString = description_text
        exp_ted:SetDescription(and_descriptionstr)
        local cat_def = finale.FCCategoryDef()
        cat_def:Load(category)
        exp_ted:AssignToCategory(cat_def)
        exp_ted:SetUseCategoryPos(true)
        exp_ted:SaveNew()
        local item_no = exp_ted:GetItemNo()
        table.insert(text_expression, item_no)
    end

    function create_tempo_string(tempo_text, beat_duration, beat_number, parenthetical_bool)
        local cat_def = finale.FCCategoryDef()
        cat_def:Load(2)
        local staff_id = cat_def:GetStaffListID()
        local fonti = cat_def:CreateTextFontInfo()
        cat_def:GetMusicFontInfo(fonti)
        local music_font = "^fontMus" .. fonti:CreateEnigmaString(finale.FCString()).LuaString
        cat_def:GetTextFontInfo(fonti)
        local text_font = "^fontTxt" .. fonti:CreateEnigmaString(finale.FCString()).LuaString
        cat_def:GetNumberFontInfo(fonti)
        local number_font = "^fontNum" .. fonti:CreateEnigmaString(finale.FCString()).LuaString
        local user_text = tempo_text
        local user_duration = beat_duration
        local user_number = beat_number
        local user_parentheses = parenthetical_bool
        local start_parentheses = "("
        local end_parentheses = text_font .. ")"

        if user_text ~= "" then
            user_text = text_font .. user_text
        end

        if user_duration ~= "" then
            user_duration = music_font .. user_duration
        end

        if user_number ~= "" then
            if string.find(user_number, "%s?[qQhHwWeEsSxX][.]?%s?%)?") then
                user_number = number_font .. " = " .. music_font .. user_number
            else
                user_number = number_font .. " = " .. user_number
            end
        end

        if user_parentheses == false then
            if beat_duration ~= "" then
                if (user_text:sub(-1) == " ") or (user_text == "") then
                    start_parentheses = ""
                else
                    start_parentheses = " "
                end
            else
                start_parentheses = ""
            end
            end_parentheses = ""
        else
            local unbold_text = string.gsub(text_font, "nfx%(%d+%)", "nfx(0)")
            if user_text:sub(-1) == " " then
                start_parentheses = unbold_text .. "("
            elseif user_text == "" then
                start_parentheses = unbold_text .. "("
            else
                start_parentheses = unbold_text .. " ("
            end
            end_parentheses = unbold_text .. ")"
        end

        local full_string = user_text .. start_parentheses .. user_duration .. user_number .. end_parentheses
        create_tempo_expression(full_string, 2)
    end

    local tempo_string = ""

    function create_tempo_string2(tempo_text, beat_duration, beat_number, parenthetical_bool)
        local user_text = tempo_text
        local user_duration = beat_duration
        local user_number = beat_number
        local user_parentheses = parenthetical_bool
        local start_parentheses = "("
        local end_parentheses = ")"

        if user_number ~= "" then
            user_number = " = " .. user_number
        end

        if user_parentheses == false then
            if beat_duration ~= "" then
                if (user_text:sub(-1) == " ") or (user_text == "") then
                    start_parentheses = ""
                else
                    start_parentheses = " "
                end
            else
                start_parentheses = ""
            end
            end_parentheses = ""
        else
            if user_text:sub(-1) == " " then
                start_parentheses = "("
            elseif user_text == "" then
                start_parentheses = "("
            else
                start_parentheses = " ("
            end
            end_parentheses = ")"
        end
        tempo_string = user_text .. start_parentheses .. user_duration .. user_number .. end_parentheses
    end

    function find_text_expression(exp_text, cat_id)
        local theID = {}
        local teds = finale.FCTextExpressionDefs()
        teds:LoadAll()
        for ted in each(teds) do
            if ted.CategoryID == cat_id then
                local ted_str = ted:CreateTextString()
                ted_str:TrimEnigmaTags()
                if ted_str.LuaString == exp_text then
                    table.insert(theID, ted:GetItemNo())
                end
            end
        end
        if theID[1] == nil then
            if cat_id == 2 then
                return false
            else
                create_text_expression(exp_text, cat_id, staff_id)
            end
        else
            table.insert(text_expression, theID[1])
        end
    end

    function parse_tempo(the_string, find_string)
        local tempo_text = ""
        local beat_duration = ""
        local beat_number = ""
        local parenthetical_bool = false
        if (string.match(the_string, "%(?%s?[qQhHwWeEsSxX][.]?%s?=%s?%d+%s?[%-%–%—]?%s?%d+%s?%)?")) then
            local new_string = string.find(the_string, "%(?%s?[qQhHwWeEsSxX][.]?%s?=%s?%d+%s?[%-%–%—]?%s?%d+%s?%)?")
            if (new_string) > 1 then
                tempo_text = the_string:sub(1, (new_string - 1))
            else
                tempo_text = ""
            end
            local metronome_text = the_string:sub(new_string)
            if string.find(metronome_text, "%(") then
                parenthetical_bool = true
            end
            if string.find(metronome_text, "[qQhHwWeEsSxX][.]?") then
                beat_duration = metronome_text:sub(string.find(metronome_text, "[qQhHwWeEsSxX][.]?"))
            end
            if string.find(metronome_text, "%d+%s?[%-%–%—]?%s?%d+") then
                beat_number = metronome_text:sub(string.find(metronome_text, "%d+%s?[%-%–%—]?%s?%d+"))
            end
        elseif (string.match(the_string, "%(?%s?[qQhHwWeEsSxX][.]?%s?=%s?[qQhHwWeEsSxX][.]?%s?%)?")) then
            if string.find(the_string, "%(") then
                parenthetical_bool = true
            end
            if string.find(the_string, "%(?%s?[qQhHwWeEsSxX][.]?%s?=") then
                beat_duration = the_string:sub(string.find(the_string, "%(?%s?[qQhHwWeEsSxX][.]?%s?="))
                beat_duration = string.gsub(beat_duration, "[%s?=%s?]", "")
                beat_duration = string.gsub(beat_duration, "%(?", "")
            end
            if string.find(the_string, "=%s?[qQhHwWeEsSxX][.]?%s?%)?") then
                beat_number = the_string:sub(string.find(the_string, "=%s?[qQhHwWeEsSxX][.]?%s?%)?"))
                beat_number = string.gsub(beat_number, "[%s?=%s?]", "")
                beat_number = string.gsub(beat_number, "%)?", "")
            end
        else
            if string.match(the_string, "%a*") then
                tempo_text = the_string
            end
        end
        if find_string then
            create_tempo_string2(tempo_text, beat_duration, beat_number, parenthetical_bool)
        else
            create_tempo_string(tempo_text, beat_duration, beat_number, parenthetical_bool)
        end
    end

    function parse_dynamics(return_string)
        local start_dynamic = ""
        local hairpin = ""
        local end_dynamic = ""
        local dyn_start_table = {
            dynamics_n_start, dynamics_pppp_start, dynamics_ppp_start, dynamics_pp_start, dynamics_p_start, dynamics_mp_start, dynamics_mf_start, dynamics_f_start,
            dynamics_ff_start, dynamics_fff_start, dynamics_ffff_start,
        }
        local dyn_end_table = {
            dynamics_n_end, dynamics_pppp_end, dynamics_ppp_end, dynamics_pp_end, dynamics_p_end, dynamics_mp_end, dynamics_mf_end, dynamics_f_end, dynamics_ff_end,
            dynamics_fff_end, dynamics_ffff_end,
        }
        local dyn_char = {"n", "pppp", "ppp", "pp", "p", "mp", "mf", "f", "ff", "fff", "ffff"}
        if (string.match(return_string, "[pPfFmMzZsS]*%-?<?>?[pPfPmMsSzZ]?")) then
            if string.find(return_string, "[pPfFmMzZsS]*") then
                local i, j = string.find(return_string, "[pPfFmMzZsS]*")
                start_dynamic = return_string:sub(i, j)
            end
            if string.find(return_string, "[<>]+") then
                local i, j = string.find(return_string, "[<>]+")

                if j == 0 then
                    hairpin = return_string:sub(i + 1, i + 1)
                else
                    hairpin = return_string:sub(i, j)
                end
            end
            if hairpin == "" then
                if string.find(return_string, "%-") then
                    local i, j = string.find(return_string, "%-[pPfPmMsSzZ]*")
                    end_dynamic = return_string:sub(i + 1, j)
                end
            else
                i, j = string.find(return_string, "[<>]+")
                end_dynamic = return_string:sub(j + 1, string.len(return_string))
            end
        end
        if start_dynamic ~= "" then
            for key, value in pairs(dyn_char) do
                if value == start_dynamic then
                    dyn_start_table[key]()
                    first_expression = {}
                end
            end
        end
        if end_dynamic ~= "" then
            for key, value in pairs(dyn_char) do
                if value == end_dynamic then
                    dyn_end_table[key]()
                end
            end
        end
        if hairpin == ">" then
            dynamics_decrescendo()
        elseif hairpin == "<" then
            dynamics_crescendo()
        end
    end

    function user_input(display_type)
        --[[
        local input_dialog = finenv.UserValueInput()
        input_dialog.Title = "JetStream Expression Input"
        input_dialog:SetTypes("String")
        input_dialog:SetDescriptions("Please Enter Your "..display_type.." Text")
        local return_values = input_dialog:Execute()
        ]]
        local return_values = {}
        return_values[1] = userValueInput("JetStream Expression Input", "Please Enter Your " .. display_type .. " Text").LuaString

        if return_values ~= nil then
            if return_values[1] ~= "" then
                if display_type == "Tempo" then
                    parse_tempo(return_values[1], true)
                    if find_text_expression(tempo_string, 2) == false then
                        parse_tempo(return_values[1], false)
                    end
                    text_expression_region("Tempo")
                elseif display_type == "Expressive" then
                    find_text_expression(return_values[1], 4)
                    text_expression_region("Start")
                elseif display_type == "Technique" then
                    find_text_expression(return_values[1], 5)
                    text_expression_region("Start")
                elseif display_type == "Dynamic" then
                    parse_dynamics(return_values[1])
                end
            end
        end
    end
    user_input(the_expression)
end

function make_x(bool_kind)
    local nudge = -24
    function playX_mm(more)
        local region = finenv.Region()
        local mmrestprefs = finale.FCMultiMeasureRestPrefs()
        mmrestprefs:Load(1)
        local ui = finenv.UI()
        local mmupdate = false
        local process_all = 0
        if region.StartMeasure == 0 then
            process_all = ui:AlertYesNo("There is no active selection. Would you like to process the current part?", "No Selection:")
            if process_all == 3 then
                return
            elseif process_all == 2 then
                region:SetFullDocument()
            end
        end

        if mmrestprefs.AutoUpdate then
            mmupdate = ui:AlertYesNo("Automatic Update is ON in the multimeasure preferences. Would you like to turn it OFF and proceed?", "Unable to create marking:")
            if mmupdate == 3 then
                return
            elseif mmupdate == 2 then
                mmrestprefs.AutoUpdate = false
                mmrestprefs:Save()
            end
        end

        local mmrests = finale.FCMultiMeasureRests()
        mmrests:LoadAll()
        for mm in each(mmrests) do
            if region:IsMeasureIncluded(mm.StartMeasure) or region:IsMeasureIncluded(mm.EndMeasure) then
                mm:DeleteData()
            end
        end

        local mm = finale.FCMultiMeasureRest()
        mm.StartMeasure = region.StartMeasure
        mm.EndMeasure = region.EndMeasure
        mm.NumberHorizontalAdjust = mmrestprefs.NumberHorizontalAdjust
        mm.NumberVerticalAdjust = mmrestprefs.NumberVerticalAdjust
        mm.ShapeEndAdjust = mmrestprefs.ShapeEndAdjust
        mm.ShapeID = 0
        mm.ShapeStartAdjust = mmrestprefs.ShapeStartAdjust
        mm.StartNumberingAt = 20000
        mm.SymbolSpace = mmrestprefs.SymbolSpace
        mm.UseSymbols = mmrestprefs.UseSymbols
        mm.UseSymbolsLessThan = mmrestprefs.UseSymbolsLessThan
        mm.Width = 408
        mm:Save()
        finale.FCStaffSystems.UpdateFullLayout()
        playX_expr(more)
    end

    function playX_expr(more)
        local region = finenv.Region()
        local x = (region.EndMeasure + 1) - region.StartMeasure
        local playX_text = config.play_x_bars_prefix .. x .. config.play_x_bars_suffix
        if more then
            playX_text = config.play_x_more_prefix .. x .. config.play_x_more_suffix
        end
        local font = finale.FCFontInfo()
        local categorydefs = finale.FCCategoryDefs()
        local misc_cat = finale.FCCategoryDef()
        categorydefs:LoadAll()
        local misc = 0
        local tempo = 0
        for cat in eachbackwards(categorydefs) do
            if cat:CreateName().LuaString == "Miscellaneous" and misc == 0 then
                misc = cat.ID
                misc_cat = cat
            elseif cat:CreateName().LuaString == "Play X Bars" then
                misc = cat.ID
                misc_cat = cat
            elseif cat:CreateName().LuaString == "Tempo Marks" and tempo == 0 then
                tempo = cat.ID
                font = cat:CreateTextFontInfo()
            end
        end

        local textexpressiondefs = finale.FCTextExpressionDefs()
        textexpressiondefs:LoadAll()
        local playX_ted = 0
        for ted in each(textexpressiondefs) do
            if ted.CategoryID == misc and ted:CreateDescription().LuaString == playX_text then
                playX_ted = ted.ItemNo
            end
        end

        if playX_ted == 0 then
            local ex_ted = finale.FCTextExpressionDef()
            local ted_descr = finale.FCString()
            ted_descr.LuaString = playX_text
            local ted_text = finale.FCString()
            local text_font = "^fontTxt" .. font:CreateEnigmaString(finale.FCString()).LuaString
            ted_text.LuaString = text_font .. playX_text
            ex_ted:AssignToCategory(misc_cat)
            ex_ted:SetDescription(ted_descr)
            ex_ted:SaveNewTextBlock(ted_text)
            ex_ted.HorizontalJustification = 1
            ex_ted.HorizontalAlignmentPoint = 5
            ex_ted.HorizontalOffset = nudge
            ex_ted.VerticalAlignmentPoint = 3
            ex_ted.VerticalBaselineOffset = -66
            ex_ted:SaveNew()
            playX_ted = ex_ted.ItemNo
        end

        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadScrollView()
        local first_staff = 1
        for sys in each(sysstaves) do
            local staff_num = sys.Staff
            if first_staff == 1 then
                region:SetStartStaff(sys.Staff)
                first_staff = 0
            end
        end

        local sysstaff = finale.FCSystemStaff()
        local measure_num = region.StartMeasure
        local measure_pos = region.StartMeasurePos
        local add_expression = finale.FCExpression()
        local staff_num = region.StartStaff
        add_expression:SetStaff(staff_num)
        add_expression:SetMeasurePos(measure_pos)
        add_expression:SetID(playX_ted)
        local and_cell = finale.FCCell(measure_num, staff_num)
        add_expression:SaveNewToCell(and_cell)
    end

    playX_mm(bool_kind)
end

function baseline_reset(baseline_type)
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()
    local start_staff = region:GetStartStaff()
    local end_staff = region:GetEndStaff()

    for i = system_number, lastSys_number, 1 do
        local baselines = finale.FCBaselines()
        baselines:LoadAllForSystem(baseline_type, i)
        for j = start_staff, end_staff, 1 do
            bl = baselines:AssureSavedStaff(baseline_type, i, j)
            bl.VerticalOffset = 0
            bl:Save()
        end
    end
end

function move_baseline(staff, baseline, direction)

    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local first_sys = system:GetItemNo()
    local last_sys = lastSys:GetItemNo()

    for i = first_sys, last_sys, 1 do
        local baselines = finale.FCBaselines()
        baselines:LoadAllForSystem(baseline, i)
        local bl = baselines:AssureSavedStaff(baseline, i, staff:GetItemNo())
        if (baseline == finale.BASELINEMODE_LYRICSCHORUS) or (baseline == finale.BASELINEMODE_LYRICSSECTION) or (baseline == finale.BASELINEMODE_LYRICSVERSE) then
            for k = 1, 100, 1 do
                bl = baselines:AssureSavedLyricNumber(finale.BASELINEMODE_LYRICSVERSE, i, staff:GetItemNo(), k)
                if direction == "up" then
                    bl.VerticalOffset = bl.VerticalOffset + to_EVPUs("1s")
                else
                    bl.VerticalOffset = bl.VerticalOffset + to_EVPUs("-1s")
                end
                bl:Save()
            end
        else
            if direction == "up" then
                bl.VerticalOffset = bl.VerticalOffset + to_EVPUs("1s")
            else
                bl.VerticalOffset = bl.VerticalOffset + to_EVPUs("-1s")
            end
            bl:Save()
        end
    end
end

function chords_move_baseline_down()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            move_baseline(staff, finale.BASELINEMODE_CHORD, "down")
        end
    end
end

function chords_move_baseline_up()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            move_baseline(staff, finale.BASELINEMODE_CHORD, "up")
        end
    end
end

function expressions_move_baseline_down()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            move_baseline(staff, finale.BASELINEMODE_EXPRESSIONABOVE, "down")
            move_baseline(staff, finale.BASELINEMODE_EXPRESSIONBELOW, "down")
        end
    end
end

function expressions_move_baseline_up()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            move_baseline(staff, finale.BASELINEMODE_EXPRESSIONABOVE, "up")
            move_baseline(staff, finale.BASELINEMODE_EXPRESSIONBELOW, "up")
        end
    end
end

function lyrics_move_baseline_down()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            move_baseline(staff, finale.BASELINEMODE_LYRICSVERSE, "down")
            -- move_baseline(staff, finale.BASELINEMODE_LYRICSCHORUS, "down")
            -- move_baseline(staff, finale.BASELINEMODE_LYRICSSECTION, "down")
        end
    end
end

function lyrics_move_baseline_up()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            move_baseline(staff, finale.BASELINEMODE_LYRICSVERSE, "up")
            move_baseline(staff, finale.BASELINEMODE_LYRICSCHORUS, "up")
            move_baseline(staff, finale.BASELINEMODE_LYRICSSECTION, "up")
        end
    end
end

function remove_lyrics_from_document()
    local verse_lyrics = finale.FCVerseLyricsText()
    local chorus_lyrics = finale.FCChorusLyricsText()
    local section_lyrics = finale.FCSectionLyricsText()

    for i = 0, 999 do
        if verse_lyrics:Load(i) then
            verse_lyrics:DeleteData()
        end
        if chorus_lyrics:Load(i) then
            chorus_lyrics:DeleteData()
        end
        if section_lyrics:Load(i) then
            section_lyrics:DeleteData()
        end
    end

    local fullregion = finale.FCMusicRegion()

    fullregion:SetFullDocument()

    for e in eachentrysaved(fullregion) do
        e.LyricFlag = false
    end
end

function staff_groups(bracket_style, barline_mode)
    local music_region = finenv.Region()
    if (music_region:IsEmpty()) ~= true then
        local top_staff = music_region:GetStartStaff()
        local bottom_staff = music_region:GetEndStaff()
        local sg_cmper = {}
        local sg = finale.FCGroup()
        if bracket_style ~= finale.GRBRAC_DESK then
            local staff_groups = finale.FCGroups()
            staff_groups:LoadAll()
            for sg in each(staff_groups) do
                table.insert(sg_cmper, sg:GetItemID())
                for addstaff = top_staff, bottom_staff do
                    if sg:ContainsStaff(addstaff) then
                        sg:DeleteData()
                    end
                end
            end
            table.sort(sg_cmper)
            sg:SetStartStaff(top_staff)
            sg:SetEndStaff(bottom_staff)
            sg:SetStartMeasure(1)
            sg:SetEndMeasure(32767)
            sg:SetBracketStyle(bracket_style)
            if top_staff == bottom_staff then
                sg:SetBracketSingleStaff(true)
            end
            sg:SetDrawBarlineMode(barline_mode)
            sg:SetBracketHorizontalPos(-12)
            if sg_cmper[1] == nil then
                sg:SaveNew(1)
            else
                local save_num = sg_cmper[1] + 1
                sg:SaveNew(save_num)
            end
        else
            local sub_list = {}
            local staff_groups = finale.FCGroups()
            staff_groups:LoadAll()
            for sg in each(staff_groups) do
                table.insert(sg_cmper, sg:GetItemID())
                for addstaff = top_staff, bottom_staff do
                    if sg:ContainsStaff(addstaff) then
                        if sg:GetBracketStyle() == 8 then
                            table.insert(sub_list, sg:GetItemID())
                            sg:DeleteData()
                        end
                    end
                end
            end
            if sub_list[1] == nil then
                sg:SetStartStaff(top_staff)
                sg:SetEndStaff(bottom_staff)
                sg:SetStartMeasure(1)
                sg:SetEndMeasure(32767)
                sg:SetBracketStyle(bracket_style)
                if top_staff == bottom_staff then
                    sg:SetBracketSingleStaff(true)
                end
                sg:SetBracketHorizontalPos(-30)
                table.sort(sg_cmper)
                if sg_cmper[2] ~= nil or sg_cmper[1] ~= nil then
                    local save_num = sg_cmper[1] + 1
                    sg:SaveNew(save_num)
                else
                    sg:SaveNew(1)
                end
            else
                sg:Load(sub_list[1], sub_list[2])
                sg:SetStartStaff(top_staff)
                sg:SetEndStaff(bottom_staff)
                sg:SetStartMeasure(1)
                sg:SetEndMeasure(32767)
                sg:SetBracketStyle(bracket_style)
                if top_staff == bottom_staff then
                    sg:SetBracketSingleStaff(true)
                end
                if sg_cmper[2] ~= nil or sg_cmper[1] ~= nil then
                    local save_num = sg_cmper[1] + 1
                    sg:SaveNew(save_num)
                else
                    sg:SaveNew(1)
                end
            end
        end
    end
end

function change_key_signature(major_minor, alteration_num)
    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())

    for m in each(measures) do
        local key_sig = m:GetKeySignature()
        if major_minor == "Major" then
            m:SetKeyless(false)
            m:SetHideKeySigShowAccis(false)
            key_sig:SetMajorKey(alteration_num)
            key_sig:Save()
        elseif major_minor == "Minor" then
            m:SetKeyless(false)
            m:SetHideKeySigShowAccis(false)
            key_sig:SetMinorKey(alteration_num)
            key_sig:Save()
        elseif major_minor == "Keyless" then
            m:SetHideKeySigShowAccis(false)
            m:SetKeyless(true)
        elseif major_minor == "HideShow" then
            m:SetKeyless(false)
            m:SetHideKeySigShowAccis(true)
        end
        m:Save()
    end
end

function simple_art_to_exp_swap(art_to_find, description, char_num)
    local breath_mark_id = {}

    local function swap_artic_for_exp()
        local music_region = finenv.Region()
        for noteentry in eachentrysaved(music_region) do
            local artics = noteentry:CreateArticulations()
            for a in each(artics) do
                local def = a:CreateArticulationDef()
                if def:GetAboveSymbolChar() == char_num then
                    a:DeleteData()
                    local and_expression = finale.FCExpression()
                    and_expression:SetStaff(noteentry.Staff)
                    and_expression:SetVisible(true)
                    local pos = 0
                    if noteentry:GetActualDuration() >= 2048 then
                        pos = noteentry.MeasurePos + (noteentry:GetActualDuration() * 7 / 8)
                    else
                        pos = noteentry.MeasurePos + (noteentry:GetActualDuration() * 3 / 4)
                    end
                    and_expression:SetMeasurePos(pos)
                    and_expression:SetScaleWithEntry(true)
                    and_expression:SetLayerAssignment(noteentry.LayerNumber)
                    and_expression:SetPartAssignment(true)
                    and_expression:SetScoreAssignment(true)
                    and_expression:SetPlaybackLayerAssignment(1)
                    and_expression:SetID(breath_mark_id[1])
                    local and_cell = finale.FCCell(noteentry.Measure, noteentry.Staff)
                    and_expression:SaveNewToCell(and_cell)
                end
            end
        end
    end

    local function createBreathMark()
        local exp_def = finale.FCTextExpressionDef()
        local textstr = finale.FCString()
        if art_to_find == nil then
            textstr.LuaString = "^fontMus(Font0,0)^size(24)^nfx(0)"
            textstr:AppendCharacter(char_num)
        else
            textstr.LuaString = "^fontMus(Font0,0)^size(24)^nfx(0)" .. art_to_find
        end
        exp_def:SaveNewTextBlock(textstr)
        local descriptionstr = finale.FCString()
        descriptionstr.LuaString = description
        exp_def:SetDescription(descriptionstr)
        local cat_def = finale.FCCategoryDef()
        cat_def:Load(7)
        exp_def:AssignToCategory(cat_def)
        exp_def:SetUseCategoryPos(false)
        exp_def:SetVerticalAlignmentPoint(finale.ALIGNVERT_STAFF_REFERENCE_LINE)
        exp_def:SetVerticalBaselineOffset(36)
        exp_def:SetHorizontalJustification(finale.EXPRJUSTIFY_LEFT)
        exp_def:SetHorizontalAlignmentPoint(finale.ALIGNHORIZ_RIGHTALLNOTEHEADS)
        exp_def:SetHorizontalOffset(48)
        exp_def:SetBreakMMRest(false)
        exp_def:SaveNew()
        breath_mark_id[1] = exp_def:GetItemNo()
        swap_artic_for_exp()
    end

    local function getBreathID()
        local exp_defs = finale.FCTextExpressionDefs()
        exp_defs:LoadAll()
        for ted in each(exp_defs) do
            local current_exp = ted:CreateTextString()
            current_exp:TrimEnigmaTags()
            if art_to_find == nil then
                if current_exp:GetCharacterAt(0) == char_num then
                    table.insert(breath_mark_id, ted:GetItemNo())
                end
            else
                if current_exp.LuaString == art_to_find then
                    table.insert(breath_mark_id, ted:GetItemNo())
                end
            end
        end
        if breath_mark_id[1] == nil then
            createBreathMark()
        else
            swap_artic_for_exp()
        end
    end

    getBreathID()
end

function change_octave(pitch_string, n)
    pitch_string.LuaString = pitch_string.LuaString:sub(1, -2) .. (tonumber(string.sub(pitch_string.LuaString, -1)) + n)
    return pitch_string
end

function down_diatonic_fifth(pitch_string)
    local letters = "ABCDEFGABCDEFG"
    local note_name_pos = letters:find(pitch_string.LuaString:sub(1, 1))
    local new_note = letters:sub(note_name_pos + 3, note_name_pos + 3)
    pitch_string.LuaString = new_note .. pitch_string.LuaString:sub(2)

    if (note_name_pos < 7) and (note_name_pos > 2) then
        pitch_string = change_octave(pitch_string, -1)
    end
    return pitch_string
end

function delete_circle_articulation(entry)
    local artics = entry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetAboveSymbolChar() == 111 then
            a:DeleteData()
        end
    end
end

function down_diatonic_third(pitch_string)
    local letters = "ABCDEFGABCDEFG"
    local note_name_pos = letters:find(pitch_string.LuaString:sub(1, 1))
    local new_note = letters:sub(note_name_pos + 5, note_name_pos + 5)
    pitch_string.LuaString = new_note .. pitch_string.LuaString:sub(2)

    if (note_name_pos < 5) and (note_name_pos > 2) then
        pitch_string = change_octave(pitch_string, -1)
    end
    return pitch_string
end

function up_diatonic_third(pitch_string)
    local letters = "ABCDEFGABCDEFG"
    local note_name_pos = letters:find(pitch_string.LuaString:sub(1, 1))
    local new_note = letters:sub(note_name_pos + 2, note_name_pos + 2)
    pitch_string.LuaString = new_note .. pitch_string.LuaString:sub(2)

    if (note_name_pos >= 8) or (note_name_pos <= 2) then
        pitch_string = change_octave(pitch_string, 1)
    end
    return pitch_string
end

function up_diatonic_fourth(pitch_string)
    local letters = "ABCDEFGABCDEFG"
    local note_name_pos = letters:find(pitch_string.LuaString:sub(1, 1))
    local new_note = letters:sub(note_name_pos + 3, note_name_pos + 3)
    pitch_string.LuaString = new_note .. pitch_string.LuaString:sub(2)

    if (note_name_pos >= 7) or (note_name_pos <= 2) then
        pitch_string = change_octave(pitch_string, 1)
    end
    return pitch_string
end

function chord_line_delete_bottom()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local bottom_note = entry:CalcLowestNote(nil)
            entry:DeleteNote(bottom_note)
        end
    end
end

function chord_line_delete_top()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local top_note = entry:CalcHighestNote(nil)
            entry:DeleteNote(top_note)
        end
    end
end

function chord_line_keep_top()
    for entry in eachentrysaved(finenv.Region()) do
        while (entry.Count >= 2) do
            local bottom_note = entry:CalcLowestNote(nil)
            entry:DeleteNote(bottom_note)
        end
    end
end

function chord_line_keep_bottom()
    for entry in eachentrysaved(finenv.Region()) do
        while (entry.Count >= 2) do
            local top_note = entry:CalcHighestNote(nil)
            entry:DeleteNote(top_note)
        end
    end
end

function double_octave(direction)
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            local note = entry:CalcLowestNote(nil)
            local pitch_string = finale.FCString()
            local measure = entry:GetMeasure()
            measure_object = finale.FCMeasure()
            measure_object:Load(measure)
            local key_sig = measure_object:GetKeySignature()
            note:GetString(pitch_string, key_sig, false, true)
            pitch_string = change_octave(pitch_string, direction)
            local new_note = entry:AddNewNote()
            new_note:SetString(pitch_string, key_sig, true)
        end
    end
end

function double_third_higher()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            local note = entry:CalcLowestNote(nil)
            local pitch_string = finale.FCString()
            local measure = entry:GetMeasure()
            measure_object = finale.FCMeasure()
            measure_object:Load(measure)
            local key_sig = measure_object:GetKeySignature()
            note:GetString(pitch_string, key_sig, false, true)
            pitch_string = up_diatonic_third(pitch_string)
            local new_note = entry:AddNewNote()
            new_note:SetString(pitch_string, key_sig, true)
            new_note.RaiseLower = note.RaiseLower
        end
    end
end

function double_third_lower()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            local note = entry:CalcLowestNote(nil)
            local pitch_string = finale.FCString()
            local measure = entry:GetMeasure()
            measure_object = finale.FCMeasure()
            measure_object:Load(measure)
            local key_sig = measure_object:GetKeySignature()
            note:GetString(pitch_string, key_sig, false, true)
            pitch_string = down_diatonic_third(pitch_string)
            local new_note = entry:AddNewNote()
            new_note:SetString(pitch_string, key_sig, true)
            new_note.RaiseLower = note.RaiseLower
        end
    end
end

function rotate_chord_up()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local note = entry:CalcLowestNote(nil)
            local top_note = entry:CalcHighestNote(nil)

            local pitch_string = finale.FCString()
            local measure = entry:GetMeasure()
            measure_object = finale.FCMeasure()
            measure_object:Load(measure)
            local key_sig = measure_object:GetKeySignature()
            note:GetString(pitch_string, key_sig, false, true)

            while note:CalcMIDIKey() < top_note:CalcMIDIKey() do
                pitch_string = change_octave(pitch_string, 1)
                note:SetString(pitch_string, key_sig, true)
            end
        end
    end
end

function rotate_chord_down()
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local note = entry:CalcHighestNote(nil)
            local bottom_note = entry:CalcLowestNote(nil)

            local pitch_string = finale.FCString()
            local measure = entry:GetMeasure()
            measure_object = finale.FCMeasure()
            measure_object:Load(measure)
            local key_sig = measure_object:GetKeySignature()
            note:GetString(pitch_string, key_sig, false, true)

            while note:CalcMIDIKey() > bottom_note:CalcMIDIKey() do
                pitch_string = change_octave(pitch_string, -1)
                note:SetString(pitch_string, key_sig, true)
            end
        end
    end
end

function string_harmonics_touch(interval_num)
    local ran = false
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count == 1) then
            ran = true

            delete_circle_articulation(entry)

            local note = entry:CalcLowestNote(nil)
            local pitch_string = finale.FCString()
            local measure = entry:GetMeasure()
            measure_object = finale.FCMeasure()
            measure_object:Load(measure)
            local key_sig = measure_object:GetKeySignature()
            note:GetString(pitch_string, key_sig, false, false)
            if (interval_num == 3) or (interval_num == 4) then
                pitch_string = change_octave(pitch_string, -2)
            elseif interval_num == 5 then
                pitch_string = change_octave(pitch_string, -1)
            end

            local new_note = entry:AddNewNote()

            new_note.Tie = note.Tie

            if interval_num == 3 then
                new_note:SetString(pitch_string, key_sig, false)
                note:SetString(down_diatonic_third(pitch_string), key_sig, false)
                if (new_note:CalcMIDIKey() - note:CalcMIDIKey() ~= 4) then
                    local error = new_note:CalcMIDIKey() - note:CalcMIDIKey() - 4
                    note.RaiseLower = note.RaiseLower + error
                end
            elseif interval_num == 4 then
                note:SetString(pitch_string, key_sig, false)
                new_note:SetString(up_diatonic_fourth(pitch_string), key_sig, false)
                if (new_note:CalcMIDIKey() - note:CalcMIDIKey() ~= 5) then
                    local error = new_note:CalcMIDIKey() - note:CalcMIDIKey() - 5
                    note.RaiseLower = note.RaiseLower + error
                end
            elseif interval_num == 5 then
                new_note:SetString(pitch_string, key_sig, false)
                note:SetString(down_diatonic_fifth(pitch_string), key_sig, false)
                if (new_note:CalcMIDIKey() - note:CalcMIDIKey() ~= 7) then
                    local error = new_note:CalcMIDIKey() - note:CalcMIDIKey() - 7
                    note.RaiseLower = note.RaiseLower + error
                end
            end

            local notehead = finale.FCNoteheadMod()
            notehead:EraseAt(new_note)
            if check_SMuFL(nil) then
                notehead.CustomChar = 57562
            else
                notehead.CustomChar = 79
            end
            notehead.Resize = 110
            if entry:GetDuration() == 4096 then
                finenv.UI():AlertInfo(tostring(entry:CalcStemUp()), "Stem up?")
                if entry:CalcStemUp() == false then
                    notehead.HorizontalPos = 5
                else
                    notehead.HorizontalPos = -5
                end
            end
            notehead:SaveAt(new_note)
        end
    end
    if not ran then
        local dialog = finale.FCCustomWindow()
        local str = finale.FCString()
        str.LuaString = "String Harmonics 5th - Sounding Pitch"
        dialog:SetTitle(str)
        local static = dialog:CreateStatic(0, 0)
        str.LuaString = "No eligible notes to create a harmonic"
        static:SetText(str)
        dialog:CreateHorizontalLine(0, 16, 390)
        dialog:CreateOkButton()
        dialog:ExecuteModal(nil)
    end
end

function entries_mute(layers_input)
    local layers_input = layers_input or {1, 2, 3, 4}
    local layers = {[1] = true, [2] = true, [3] = true, [4] = true}

    for k, v in ipairs(layers_input) do
        layers[v] = false
    end

    for entry in eachentrysaved(finenv.Region()) do
        entry.Playback = layers[entry.LayerNumber]
    end
end

function flip_enharmonic()
    for entry in eachentrysaved(finenv.Region()) do
        if entry:IsNote() then
            local pitch_string = finale.FCString()
            local measure = finale.FCMeasure()
            measure:Load(entry.Measure)
            local key = measure:GetKeySignature()
            for note in each(entry) do
                note:GetString(pitch_string, key, false, false)
                local length = (string.len(pitch_string.LuaString))
                local pitch = string.sub(pitch_string.LuaString, 1, length - 1)
                local octave = note:CalcOctave(key, 0)
                if pitch == "C" then
                    pitch = "B#"
                    octave = octave - 1
                elseif pitch == "C#" then
                    pitch = "Db"
                elseif pitch == "Db" then
                    pitch = "C#"
                elseif pitch == "D#" then
                    pitch = "Eb"
                elseif pitch == "Eb" then
                    pitch = "D#"
                elseif pitch == "E" then
                    pitch = "Fb"
                elseif pitch == "Fb" then
                    pitch = "E"
                elseif pitch == "F" then
                    pitch = "E#"
                elseif pitch == "E#" then
                    pitch = "F"
                elseif pitch == "F#" then
                    pitch = "Gb"
                elseif pitch == "Gb" then
                    pitch = "F#"
                elseif pitch == "G#" then
                    pitch = "Ab"
                elseif pitch == "Ab" then
                    pitch = "G#"
                elseif pitch == "A#" then
                    pitch = "Bb"
                elseif pitch == "Bb" then
                    pitch = "A#"
                elseif pitch == "B" then
                    pitch = "Cb"
                    octave = octave + 1
                elseif pitch == "Cb" then
                    pitch = "B"
                    octave = octave - 1
                elseif pitch == "B#" then
                    pitch = "C"
                    octave = octave + 1
                end
                pitch_string.LuaString = pitch .. octave
                note:SetString(pitch_string, key, false)
            end
        end
    end
end

function cluster_indeterminate()
    local distance_prefs = finale.FCDistancePrefs()
    distance_prefs:Load(1)
    local dot_horz = distance_prefs.AugmentationDotNoteSpace
    local dot_vert = distance_prefs.AugmentationDotVerticalAdjust
    local sizeprefs = finale.FCSizePrefs()
    sizeprefs:Load(1)
    local stem_thickness = sizeprefs.StemLineThickness
    stem_thickness = stem_thickness / 64

    for noteentry in eachentrysaved(finenv.Region()) do
        if noteentry:IsNote() and noteentry.Count > 1 then
            local max = noteentry.Count
            local n = 1
            local dot = finale.FCDotMod()
            local lowest_note = noteentry:CalcLowestNote(nil)
            local lowest_note_pos = lowest_note:CalcStaffPosition()
            local low_space = lowest_note_pos % 2
            local low_span = 0
            local adjust_dots = false

            local i = 1
            for note in each(noteentry) do
                local stemDir = noteentry:CalcStemUp()
                local rightside = note:CalcRightsidePlacement()
                if (stemDir == true and rightside == true) then
                    adjust_dots = true
                end
                if i == 2 then
                    low_span = note:CalcStaffPosition() - lowest_note_pos
                end
                i = i + 1
            end

            for note in each(noteentry) do
                local stemDir = noteentry:CalcStemUp()
                local notehead = finale.FCNoteheadMod()
                notehead:EraseAt(note)
                notehead:SetUseCustomFont(true)
                notehead.FontName = "Engraver Font Set"
                local noteheadOffset = 35
                local rightside = note:CalcRightsidePlacement()

                if noteentry.Duration < 2048 then
                    notehead.CustomChar = 242
                    if stemDir == true and rightside then
                        notehead.HorizontalPos = -noteheadOffset
                    end
                    if stemDir == false and rightside == false then
                        notehead.HorizontalPos = noteheadOffset
                    end
                end

                if (noteentry.Duration >= 2048) and (noteentry.Duration < 4096) then
                    if n == 1 then
                        notehead.CustomChar = 201
                    elseif n == max then
                        notehead.CustomChar = 59
                    else
                        notehead.CustomChar = 58
                    end
                    if stemDir == true and rightside then
                        notehead.HorizontalPos = -noteheadOffset
                    end
                    if stemDir == false and rightside == false then
                        notehead.HorizontalPos = noteheadOffset
                    end
                end

                if (noteentry.Duration >= 4096) then
                    if n == 1 then
                        notehead.CustomChar = 201
                    elseif n == max then
                        notehead.CustomChar = 59
                    else
                        notehead.CustomChar = 58
                    end
                    noteheadOffset = 32
                    if stemDir == true and rightside then
                        notehead.HorizontalPos = -noteheadOffset
                    end
                    if stemDir == false and rightside == false then
                        notehead.HorizontalPos = noteheadOffset
                    end
                end

                if n > 1 and n < max then
                    note.Tie = false
                end

                if noteentry:IsDotted() then
                    local horz = 0
                    if adjust_dots then
                        horz = -noteheadOffset
                    end
                    if n == 1 and low_span <= 1 and low_space == 1 then
                        dot.VerticalPos = 24
                    elseif n > 1 and n < max then
                        dot.VerticalPos = 10000
                        dot.HorizontalPos = 10000
                    else
                        dot.VerticalPos = 0
                    end
                    dot.HorizontalPos = horz
                    dot:SaveAt(note)
                end

                note.AccidentalFreeze = true
                note.Accidental = false
                notehead:SaveAt(note)
                n = n + 1
            end
            noteentry.LedgerLines = false
        end
    end
end

function cluster_determinate()
    local region = finenv.Region()

    local layer1note = {}
    local layer2note = {}
    local measure = {}

    local stemDir = false

    local horz_off = -20

    local function ProcessNotes(music_region)
        local stem_dir = {}
        for entry in eachentrysaved(region) do
            entry.FreezeStem = false
            table.insert(stem_dir, entry:CalcStemUp())
        end

        CopyLayer(1, 2)
        CopyLayer(1, 3)

        local i = 1
        local j = 1
        local stemDir = stem_dir[i]

        for noteentry in eachentrysaved(music_region) do
            local span = noteentry:CalcDisplacementRange(nil)
            local stemDir = stem_dir[i]
            if noteentry.LayerNumber == 1 then
                stemDir = stem_dir[i]
                if noteentry:IsNote() then
                    if span > 2 then
                        DeleteBottomNotes(noteentry)
                    else
                        DeleteMiddleNotes(noteentry)
                        noteentry.FreezeStem = true
                        noteentry.StemUp = stemDir
                    end
                elseif noteentry:IsRest() then
                    noteentry:SetRestDisplacement(6)
                end
                if stemDir == false and span > 2 then
                    HideStems(noteentry, stemDir)
                end
                i = i + 1
            elseif noteentry.LayerNumber == 2 then
                stemDir = stem_dir[j]
                if noteentry:IsNote() and span > 2 then
                    DeleteTopNotes(noteentry)
                else
                    noteentry:MakeRest()
                    noteentry.Visible = false
                    noteentry:SetRestDisplacement(4)
                end
                if stemDir then
                    HideStems(noteentry, stemDir)
                end
                j = j + 1
            elseif noteentry.LayerNumber == 3 then
                if noteentry:IsNote() then
                    for note in each(noteentry) do
                        note.AccidentalFreeze = true
                        note.Accidental = false
                    end
                    noteentry.FreezeStem = true
                    noteentry.StemUp = true
                    HideStems(noteentry, true)
                    DeleteTopBottomNotes(noteentry)
                elseif noteentry:IsRest() then
                    noteentry:SetRestDisplacement(2)
                end
                noteentry.Visible = false
            end
            noteentry.CheckAccidentals = true
            if noteentry:IsNote() then
                n = 1
                for note in each(noteentry) do
                    note.NoteID = n
                    n = n + 1
                end
            end
        end
    end

    function HideStems(entry, stemDir)
        local stem = finale.FCCustomStemMod()
        stem:SetNoteEntry(entry)
        if stemDir then
            stemDir = false
        else
            stemDir = true
        end
        stem:UseUpStemData(stemDir)
        if stem:LoadFirst() then
            stem.ShapeID = 0
            stem:Save()
        else
            stem.ShapeID = 0
            stem:SaveNew()
        end
        entry:SetBeamBeat(true)
    end

    function CopyLayer(src, dest)
        local region = finenv.Region()
        local start = region.StartMeasure
        local stop = region.EndMeasure
        local sysstaves = finale.FCSystemStaves()
        sysstaves:LoadAllForRegion(region)
        src = src - 1
        dest = dest - 1
        for sysstaff in each(sysstaves) do
            staffNum = sysstaff.Staff
            local noteentrylayerSrc = finale.FCNoteEntryLayer(src, staffNum, start, stop)
            noteentrylayerSrc:Load()
            local noteentrylayerDest = noteentrylayerSrc:CreateCloneEntries(dest, staffNum, start)
            noteentrylayerDest:Save()
            noteentrylayerDest:CloneTuplets(noteentrylayerSrc)
            noteentrylayerDest:Save()
        end
    end

    function DeleteBottomNotes(entry)
        while entry.Count > 1 do
            local lowestnote = entry:CalcLowestNote(nil)
            entry:DeleteNote(lowestnote)
        end
    end

    function DeleteTopNotes(entry)
        while entry.Count > 1 do
            local highestnote = entry:CalcHighestNote(nil)
            entry:DeleteNote(highestnote)
        end
    end

    function DeleteTopBottomNotes(entry)
        local highestnote = entry:CalcHighestNote(nil)
        entry:DeleteNote(highestnote)
        local lowestnote = entry:CalcLowestNote(nil)
        entry:DeleteNote(lowestnote)
    end

    function DeleteMiddleNotes(entry)
        while entry.Count > 2 do
            local n = 1
            for note in each(entry) do
                note.NoteID = n
                n = n + 1
            end
            for note in each(entry) do
                if note.NoteID == 2 then
                    entry:DeleteNote(note)
                end
            end
        end
    end

    local function create_cluster_line()
        local lineExists = false
        local myLine = 0
        local myLineWidth = 64 * 24 * 0.5
        local customsmartlinedefs = finale.FCCustomSmartLineDefs()
        customsmartlinedefs:LoadAll()
        for csld in each(customsmartlinedefs) do
            if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == myLineWidth then
                if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then
                    if csld.Horizontal == false then
                        myLine = csld.ItemNo
                        lineExists = true
                    end
                end
            end
        end

        if lineExists == false then
            local csld = finale.FCCustomSmartLineDef()
            csld.Horizontal = false
            csld.LineStyle = finale.CUSTOMLINE_SOLID
            csld.StartArrowheadStyle = finale.CLENDPOINT_NONE
            csld.EndArrowheadStyle = finale.CLENDPOINT_NONE
            csld.LineWidth = myLineWidth
            csld:SaveNew()
            myLine = csld.ItemNo
        end
        return myLine
    end

    local function create_short_cluster_line()
        local lineExists = false
        local myLine = 0
        local myLineWidth = 64 * 24 * 0.333
        local customsmartlinedefs = finale.FCCustomSmartLineDefs()
        customsmartlinedefs:LoadAll()
        for csld in each(customsmartlinedefs) do
            if csld.LineStyle == finale.CUSTOMLINE_SOLID and csld.LineWidth == myLineWidth then
                if csld.StartArrowheadStyle == finale.CLENDPOINT_NONE and csld.EndArrowheadStyle == finale.CLENDPOINT_NONE then
                    if csld.Horizontal == false then
                        myLine = csld.ItemNo
                        lineExists = true
                    end
                end
            end
        end

        if lineExists == false then
            local csld = finale.FCCustomSmartLineDef()
            csld.Horizontal = false
            csld.LineStyle = finale.CUSTOMLINE_SOLID
            csld.StartArrowheadStyle = finale.CLENDPOINT_NONE
            csld.EndArrowheadStyle = finale.CLENDPOINT_NONE
            csld.LineWidth = myLineWidth
            csld:SaveNew()
            myLine = csld.ItemNo
        end
        return myLine
    end

    function add_cluster_line(leftnote, rightnote, lineID)
        if leftnote:IsNote() and leftnote.Count == 1 and rightnote:IsNote() then
            local smartshape = finale.FCSmartShape()
            local layer1highest = leftnote:CalcHighestNote(nil)
            local noteWidth = layer1highest:CalcNoteheadWidth()
            local layer1noteY = layer1highest:CalcStaffPosition()

            local layer2highest = rightnote:CalcHighestNote(nil)
            local layer2noteY = layer2highest:CalcStaffPosition()

            local topPad = 0
            local bottomPad = 0
            if leftnote.Duration >= 2048 and leftnote.Duration < 4096 then
                topPad = 9
                bottomPad = topPad
            elseif leftnote.Duration >= 4096 then
                topPad = 10
                bottomPad = 11.5
            end
            layer1noteY = (layer1noteY * 12) - topPad
            layer2noteY = (layer2noteY * 12) + bottomPad

            smartshape.ShapeType = finale.SMARTSHAPE_CUSTOM
            smartshape.EntryBased = false
            smartshape.MakeHorizontal = false
            smartshape.BeatAttached = true
            smartshape.PresetShape = true
            smartshape.Visible = true
            smartshape.LineID = lineID

            local leftseg = smartshape:GetTerminateSegmentLeft()
            leftseg:SetMeasure(leftnote.Measure)
            leftseg:SetStaff(leftnote.Staff)
            leftseg:SetMeasurePos(leftnote.MeasurePos)
            leftseg:SetEndpointOffsetX(noteWidth / 2)
            leftseg:SetEndpointOffsetY(layer1noteY)

            local rightseg = smartshape:GetTerminateSegmentRight()
            rightseg:SetMeasure(rightnote.Measure)
            rightseg:SetStaff(rightnote.Staff)
            rightseg:SetMeasurePos(rightnote.MeasurePos)
            rightseg:SetEndpointOffsetX(noteWidth / 2)
            rightseg:SetEndpointOffsetY(layer2noteY)

            smartshape:SaveNewEverything(NULL, NULL)
        end
    end

    function add_short_cluster_line(entry, short_lineID)
        if entry:IsNote() and entry.Count > 1 then
            local smartshape = finale.FCSmartShape()
            local leftnote = entry:CalcHighestNote(nil)
            local leftnoteY = leftnote:CalcStaffPosition() * 12 + 12

            local rightnote = entry:CalcLowestNote(nil)
            local rightnoteY = rightnote:CalcStaffPosition() * 12 - 12

            smartshape.ShapeType = finale.SMARTSHAPE_CUSTOM
            smartshape.EntryBased = false
            smartshape.MakeHorizontal = false
            smartshape.PresetShape = true
            smartshape.Visible = true
            smartshape.BeatAttached = true
            smartshape.LineID = short_lineID

            local leftseg = smartshape:GetTerminateSegmentLeft()
            leftseg:SetMeasure(entry.Measure)
            leftseg:SetStaff(entry.Staff)
            leftseg:SetMeasurePos(entry.MeasurePos)
            leftseg:SetEndpointOffsetX(horz_off)
            leftseg:SetEndpointOffsetY(leftnoteY)

            local rightseg = smartshape:GetTerminateSegmentRight()
            rightseg:SetMeasure(entry.Measure)
            rightseg:SetStaff(entry.Staff)
            rightseg:SetMeasurePos(entry.MeasurePos)
            rightseg:SetEndpointOffsetX(horz_off)
            rightseg:SetEndpointOffsetY(rightnoteY)

            smartshape:SaveNewEverything(NULL, NULL)
        end
    end

    local lineID = create_cluster_line()
    local short_lineID = create_short_cluster_line()

    for addstaff = region:GetStartStaff(), region:GetEndStaff() do
        local count = 0

        for k, v in pairs(layer1note) do
            layer1note[k] = nil
        end
        for k, v in pairs(layer2note) do
            layer2note[k] = nil
        end
        for k, v in pairs(measure) do
            measure[k] = nil
        end

        region:SetStartStaff(addstaff)
        region:SetEndStaff(addstaff)
        local measures = finale.FCMeasures()
        measures:LoadRegion(region)
        ProcessNotes(region)

        for entry in eachentrysaved(region) do
            if entry.LayerNumber == 1 then
                table.insert(layer1note, entry)
                table.insert(measure, entry.Measure)
                staff = entry.Staff
                count = count + 1
            elseif entry.LayerNumber == 2 then
                table.insert(layer2note, entry)
            end
        end

        for i = 1, count do
            add_short_cluster_line(layer1note[i], short_lineID)
            add_cluster_line(layer1note[i], layer2note[i], lineID)
        end
    end

    for noteentry in eachentrysaved(finenv.Region()) do
        if noteentry:IsNote() and noteentry.Count > 1 then
            for note in each(noteentry) do
                if note.Accidental then
                    local am = finale.FCAccidentalMod()
                    am:SetNoteEntry(noteentry)
                    am:SetUseCustomVerticalPos(true)
                    am:SetHorizontalPos(horz_off * 1.5)
                    am:SaveAt(note)
                end
            end
        end
    end
end

function create_centered_triangles()
    local solid_tri_up = 49
    local hollow_tri_up = 33
    local solid_tri_down = 45
    local hollow_tri_down = 95

    local nm = finale.FCNoteheadMod()
    nm:SetUseCustomFont(true)
    nm.FontName = "Maestro Percussion"

    for noteentry in eachentrysaved(finenv.Region()) do
        local stem = noteentry:CalcStemUp()
        noteentry:SetLedgerLines(false)
        nm:SetNoteEntry(noteentry)
        for note in each(noteentry) do
            nm:SetVerticalPos(0)
            if noteentry.Duration < 2048 then
                if note:CalcStaffPosition() >= -4 then
                    nm.CustomChar = solid_tri_up
                else
                    nm.CustomChar = solid_tri_down
                end
            end
            if noteentry.Duration >= 2048 then
                if note:CalcStaffPosition() >= -4 then
                    nm.CustomChar = hollow_tri_up
                else
                    nm.CustomChar = hollow_tri_down
                end
            end
            nm:SaveAt(note)
            local off = 0
            local notehead = finale.FCNoteheadMod()
            notehead:LoadAt(note)
            local width = note:CalcNoteheadWidth()
            if note:CalcRightsidePlacement() then
                off = -width / 2
            else
                off = width / 2
            end
            notehead.HorizontalPos = notehead.HorizontalPos + off
            notehead:SaveAt(note)
        end
    end
end

function create_kicklink_layer_4()
    local music_region = finenv.Region()
    music_region:SetCurrentSelection()
    local staves = finale.FCStaves()
    local perc_layout = finale.FCPercussionLayoutNotes()
    local rhythmcue = finale.FCPercussionLayoutNote()
    staves:LoadAll()

    local ssds = finale.FCStaffStyleDefs()
    ssds:LoadAll()
    local slash = 0
    local onebar = 0
    local twobar = 0
    for ssd in each(ssds) do
        if ssd:GetAltNotationStyle() == 1 and ssd:GetAltNotationLayer() == 1 and ssd:GetAltShowOtherNotes() == true and ssd:GetAltShowOtherArticulations() then
            slash = ssd:GetItemNo()
        elseif ssd:GetAltNotationStyle() == 3 and ssd:GetAltNotationLayer() == 1 and ssd:GetAltShowOtherNotes() == true and ssd:GetAltShowOtherArticulations() then
            onebar = ssd:GetItemNo()
        elseif ssd:GetAltNotationStyle() == 4 and ssd:GetAltNotationLayer() == 1 and ssd:GetAltShowOtherNotes() == true and ssd:GetAltShowOtherArticulations() then
            twobar = ssd:GetItemNo()
        end
    end

    function find_ssd(style, style_name)
        local ssd = finale.FCStaffStyleDef()
        local name = finale.FCString()
        name.LuaString = style_name
        ssd:SetUseAltNotationStyle(true)
        ssd:SetAltNotationStyle(style)
        ssd:SetAltSlashDots(true)
        ssd:SetAltShowOtherNotes(true)
        ssd:SetAltShowOtherArticulations(true)
        ssd:SetAltShowExpression(true)
        ssd:SetAltShowOtherExpressions(true)
        ssd:SetAltShowOtherSmartShapes(true)
        ssd:SetAltShowOtherLyrics(true)
        ssd:SetShowChords(true)
        ssd:SetAltNotationLayer(1)
        ssd:SetName(name)
        ssd:SetCopyable(true)
        ssd:SaveNew()
        return ssd:GetItemNo()
    end

    if slash == 0 then
        slash = find_ssd(1, "Slash Notation + Notes")
    end
    if onebar == 0 then
        onebar = find_ssd(3, "One-bar Repeat + Notes")
    end
    if twobar == 0 then
        twobar = find_ssd(4, "Two-bar Repeat + Notes")
    end

    local region = finenv.Region()
    local start = region.StartMeasure
    local stop = region.EndMeasure
    local sys_staves = finale.FCSystemStaves()
    sys_staves:LoadAllForRegion(region)

    for staff in each(staves) do
        if music_region:IsStaffIncluded(staff.ItemNo) then
            local start_meas = music_region:GetStartMeasure()
            local end_meas = music_region:GetEndMeasure()
            local start_pos = music_region:GetStartMeasurePos()
            local end_pos = music_region:GetEndMeasurePos()
            local staff_style = finale.FCStaffStyleAssign()
            staff_style:SetStartMeasure(start_meas)
            staff_style:SetEndMeasure(end_meas)
            staff_style:SetStartMeasurePos(start_pos)
            staff_style:SetEndMeasurePos(end_pos)
            staff_style:SetStyleID(slash)
            staff_style:SaveNew(staff.ItemNo)
        end
    end

    for sys_staff in each(sys_staves) do
        local staff_num = sys_staff.Staff
        local cue_source = 1

        local staff_num = sys_staff.Staff
        for i = 3, 0, -1 do
            local layer = finale.FCNoteEntryLayer(i, staff_num, start, stop)
            layer:Load()
            if layer.Count > 0 then
                cue_source = i + 1
                if cue_source == 4 then
                    goto continue
                end
            end
        end

        swap_first = cue_source - 1
        swap_second = 3
        noteentry_layer_first = finale.FCNoteEntryLayer(swap_first, staff_num, start, stop)
        noteentry_layer_first:SetUseVisibleLayer(false)
        if noteentry_layer_first:Load() then
            noteentry_layer_first.LayerIndex = swap_second
        end

        noteentry_layer_second = finale.FCNoteEntryLayer(swap_second, staff_num, start, stop)
        noteentry_layer_second:SetUseVisibleLayer(false)

        if noteentry_layer_second:Load() then
            noteentry_layer_second.LayerIndex = swap_first
        end

        noteentry_layer_first:Save()
        noteentry_layer_second:Save()

        ::continue::

        for entry in eachentrysaved(music_region) do
            for j = 1, 2, 1 do
                if entry:IsNote() and entry.LayerNumber == 4 then
                    local i = 1
                    entry.FreezeStem = true
                    entry.StemUp = true
                    entry.FlipTie = true
                    entry.Playback = false

                    for note in each(entry) do
                        if i == 1 then
                            note:SetMIDIKey(79)
                            note.Displacement = 11
                            local pnm = finale.FCPercussionNoteMod()
                            pnm:SetNoteEntry(entry)
                            pnm:SetNoteType(235)
                            note.AccidentalFreeze = true
                            note.Accidental = false
                            pnm:Save()
                        elseif i > 1 then
                            entry:DeleteNote(note)
                        end
                        i = i + 1
                    end

                else
                    entry:SetRestDisplacement(11)
                end
            end
        end
        change_notehead_size(4, 75, nil)
    end
end

function top_line()
    function changeoctave(pitchstring, n)
        pitchstring.LuaString = pitchstring.LuaString:sub(1, -2) .. (tonumber(string.sub(pitchstring.LuaString, -1)) + n)
        return pitchstring
    end

    function add8vb(entry)
        local region = finenv.Region()
        local hi_note = entry:CalcHighestNote(nil)
        local pitchstring = finale.FCString()
        local measure = entry:GetMeasure()
        measureobject = finale.FCMeasure()
        measureobject:Load(measure)
        local keysig = measureobject:GetKeySignature()
        hi_note:GetString(pitchstring, keysig, false, true)
        pitchstring = changeoctave(pitchstring, -1)
        local newnote = entry:AddNewNote()
        newnote:SetPlayback(false)
        newnote:SetString(pitchstring, keysig, true)
    end

    local reset_flag = false
    local nm = finale.FCNoteheadMod()

    for noteentry in eachentrysaved(finenv.Region()) do
        for note in each(noteentry) do
            nm:SetNoteEntry(noteentry)
            nm:LoadAt(note)
            if nm.CustomChar == 32 then
                reset_flag = true
                goto reset
            end
        end
    end

    for noteentry in eachentrysaved(finenv.Region()) do
        if noteentry:IsNote() then
            if noteentry:CalcDisplacementRange() < 7 then
                add8vb(noteentry)
            end
            local hi_note_ID = noteentry:CalcHighestNote(NULL)
            local hi_note = hi_note_ID:CalcMIDIKey()
            noteentry.StemUp = true
            noteentry.FreezeStem = true
            noteentry.FlipTie = true
            nm:SetUseCustomFont(true)
            nm.FontName = Maestro
            for note in each(noteentry) do
                if note:CalcMIDIKey() ~= hi_note then
                    note.Tie = false
                    note.AccidentalFreeze = true
                    note.Accidental = false
                    nm:SetVerticalPos(0)
                    nm.CustomChar = 32
                    nm:SaveAt(note)
                end
            end
        end
    end

    ::reset::

    if reset_flag then
        for noteentry in eachentrysaved(finenv.Region()) do
            local hi_note_ID = noteentry:CalcHighestNote(NULL)
            local tie_status = hi_note_ID.Tie
            noteentry.FlipTie = false
            noteentry.FreezeStem = false
            for note in each(noteentry) do
                if note.Playback == false then
                    noteentry:DeleteNote(note)
                end
                note.AccidentalFreeze = false
                noteheads_default()
            end
            for note in each(noteentry) do
                note.Tie = tie_status
            end
        end

    end
end

function ui_switch_to_selected_part()

    function get_top_left_selected_or_visible_cell()
        local sel_region = finenv.Region()
        if not sel_region:IsEmpty() then
            return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
        end
        return false
    end

    local music_region = finenv.Region()
    local selection_exists = not music_region:IsEmpty()
    local ui = finenv.UI()

    local top_cell = get_top_left_selected_or_visible_cell()
    local parts = finale.FCParts()
    parts:LoadAll()
    local current_part = parts:GetCurrent()
    if current_part:IsScore() then
        local part_ID = nil
        parts:SortByOrderID()
        for part in each(parts) do
            if (not part:IsScore()) and part:IsStaffIncluded(top_cell.Staff) then
                part_ID = part:GetID()
                break
            end
        end
        if part_ID ~= nil then
            local part = finale.FCPart(part_ID)
            part:ViewInDocument()
            if selection_exists then
                music_region:SetInstrumentList(0)
                music_region:SetStartStaff(top_cell.Staff)
                music_region:SetEndStaff(top_cell.Staff)
                music_region:SetInDocument()
            end
            ui:MoveToMeasure(top_cell.Measure, music_region.StartStaff)
        else
            finenv.UI():AlertInfo("Hmm, this part doesn't seem to be generated.\nTry generating parts and try again", "No Part Detected")
        end
    else
        local score_ID = parts:GetScore()
        local part = finale.FCPart(score_ID:GetID())
        part:ViewInDocument()
        ui:MoveToMeasure(top_cell.Measure, top_cell.Staff)
    end

    finenv.StartNewUndoBlock("Switch To Selected Part", false)
end

--[[
--Disabled by Jake: too many parameters to easily convert to easily convert to FCCustomWindow.
function user_configuration()
    package.path = "/Library/Application Support/MakeMusic/Finale 26/JetStreamConfig.lua"
    local config = require "JetStreamConfig"
    local dialog = finenv.UserValueInput()
    dialog:SetTypes(
        --hairpins
        "Number", "NumberedList",
        --fonts
        "NumberedList", "NumberedList",
        --Save?
        "Boolean")
    dialog:SetDescriptions(
        --hairpins
        "Cushion", "Apply To:",
        --fonts
        "Notehead Font", "Page Text Font",
        --Save?
        "Save Settings?")
    dialog:SetLists(
    nil, config.hairpin.region_or_notes,
    config.fonts.notehead_font, config.fonts.page_text_font,
    nil)
    dialog:SetInitValues(
        config.hairpin.cushion, config.hairpin.region_or_notes[1],
        config.fonts.notehead_font[1], config.fonts.page_text_font[1],
        true)

    local return_values = dialog:Execute()

    if return_values ~= nil then
        if return_values[#return_values] then
            config.hairpin.cushion = return_values[1]
            config.hairpin.region_or_notes = return_values[2]
            config.fonts.notehead_font = return_values[3]
            config.fonts.page_text_font = return_values[4]
        end
    end
end
]]

function check_for_update(temp_dir, sd_type)
    local temp_dir = ""
    local check_string = ""
    local current_file = ""
    local open_command = ""
    if string.find(sd_type, "mac") then
        temp_dir = "/tmp/"
        current_file = temp_dir .. "/jetstream_update.html"
        open_command = "open "
        if string.find(sd_type, "XL") then
            check_string = "https://www.dropbox.com/s/.*/JetStream%%20Mac%%20proXL%%20"
        elseif string.find(sd_type, "standard") then
            check_string = "https://www.dropbox.com/s/.*/JetStream%%20Mac%%20"
        elseif string.find(sd_type, "km") then
            check_string = "https://www.dropbox.com/s/.*/JetStream%%20KM%%20"
        end
    elseif string.find(sd_type, "win") then
        temp_dir = "\\Windows\\Temp\\"
        current_file = temp_dir .. "\\jetstream_update.html"
        open_command = "start "
        if string.find(sd_type, "XL") then
            check_string = "https://www.dropbox.com/s/.*/JetStream%%20Win%%20proXL%%20"
        elseif string.find(sd_type, "standard") then
            check_string = "https://www.dropbox.com/s/.*/JetStream%%20Win%%20"
        elseif string.find(sd_type, "ahk") then
            check_string = "https://www.dropbox.com/s/.*/JetStream%%20AHK%%20"
        end
    end
    os.execute("cd " .. temp_dir .. " && curl http://jetstreamfinale.com/twdmmfc0z1g345d7s5/ --output jetstream_update.html")
    for line in io.lines(current_file) do
        if string.find(line, check_string) then
            local version_check = string.gsub(line, check_string, "")
            version_check = (string.match(version_check, "%d*.zip"))
            version_check = string.gsub(version_check, ".zip", "")
            if version_check > (finaleplugin.Version) then
                local update_window = finenv.UI():AlertYesNo(
                                          "You currently have version: " .. finaleplugin.Version .. "\nWould you like to update to version " .. version_check .. "?",
                                          "An update is available!")
                if update_window == 2 then
                    local download_string = string.match(line, check_string .. "%d*%.zip%?dl=1")
                    os.execute(open_command .. download_string)
                else
                    return
                end
            elseif version_check < (finaleplugin.Version) then
                finenv.UI():AlertInfo("Um, you somehow have a build newer than the one we are currently offering... How'd you do that?", "Update Error")
            elseif version_check == (finaleplugin.Version) then
                finenv.UI():AlertInfo(
                    "You are up to date with the current version: " .. finaleplugin.Version .. "\nPlease check back soon for a new version!", "No Update Available")
            end
        end
    end
end

local dyn_smufl = check_SMuFL({"Expression", finale.DEFAULTCATID_DYNAMICS})

function staff_check()
    local staff_list = {}
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local staff_num = staff:GetItemNo()
        local music_region = finale.FCMusicRegion()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            table.insert(staff_list, staff_num)
        end
    end
    return staff_list
end

function dynamics_ffff_start()
    if dyn_smufl then
        find_dynamic({58673}, first_expression, "fortissississimo (velocity = 127)", dyn_smufl)
    else
        find_dynamic({235}, first_expression, "fortissississimo (velocity = 127)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_fff_start()
    if dyn_smufl then
        find_dynamic({58672}, first_expression, "fortississimo (velocity = 114)", dyn_smufl)
    else
        find_dynamic({236}, first_expression, "fortississimo (velocity = 114)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_ff_start()
    if dyn_smufl then
        find_dynamic({58671}, first_expression, "fortissimo (velocity = 101)", dyn_smufl)
    else
        find_dynamic({196}, first_expression, "fortissimo (velocity = 101)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_f_start()
    if dyn_smufl then
        find_dynamic({58658}, first_expression, "forte (velocity = 88)", dyn_smufl)
    else
        find_dynamic({102}, first_expression, "forte (velocity = 88)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_mf_start()
    if dyn_smufl then
        find_dynamic({58669}, first_expression, "mezzo forte (velocity = 75)", dyn_smufl)
    else
        find_dynamic({70}, first_expression, "mezzo forte (velocity = 75)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_mp_start()
    if dyn_smufl then
        find_dynamic({58668}, first_expression, "mezzo piano (velocity = 62)", dyn_smufl)
    else
        find_dynamic({80}, first_expression, "mezzo piano (velocity = 62)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_p_start()
    if dyn_smufl then
        find_dynamic({58656}, first_expression, "piano (velocity = 49)", dyn_smufl)
    else
        find_dynamic({112}, first_expression, "piano (velocity = 49)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_pp_start()
    if dyn_smufl then
        find_dynamic({58667}, first_expression, "pianissimo (velocity = 36)", dyn_smufl)
    else
        find_dynamic({185}, first_expression, "pianissimo (velocity = 36)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_ppp_start()
    if dyn_smufl then
        find_dynamic({58666}, first_expression, "pianississimo (velocity = 23)", dyn_smufl)
    else
        find_dynamic({184}, first_expression, "pianississimo (velocity = 23)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_pppp_start()
    if dyn_smufl then
        find_dynamic({58665}, first_expression, "pianissississimo (velocity = 10)", dyn_smufl)
    else
        find_dynamic({175}, first_expression, "pianissississimo (velocity = 10)", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_fp_start()
    if dyn_smufl then
        find_dynamic({58676}, first_expression, "forte piano", dyn_smufl)
    else
        find_dynamic({234}, first_expression, "forte piano", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_fz_start()
    if dyn_smufl then
        find_dynamic({58677}, first_expression, "forzando", dyn_smufl)
    else
        find_dynamic({90}, first_expression, "forzando", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_n_start()
    if dyn_smufl then
        find_dynamic({58662}, first_expression, "niente (velocity = 0)", dyn_smufl)
    else
        findSpecialExpression({150}, {"Font0", 0, 24, 0}, first_expression, "niente (velocity = 0)", 1)
    end
    dynamic_region("Start")
end

function dynamics_rf_start()
    if dyn_smufl then
        find_dynamic({58659}, first_expression, "rinforte", dyn_smufl)
    else
        find_dynamic({142, 102}, first_expression, "rinforte", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_rfz_start()
    if dyn_smufl then
        find_dynamic({58659}, first_expression, "rinforzando", dyn_smufl)
    else
        find_dynamic({142, 90}, first_expression, "rinforzando", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_sf_start()
    if dyn_smufl then
        find_dynamic({58678}, first_expression, "sforzando", dyn_smufl)
    else
        find_dynamic({83}, first_expression, "sforzando", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_sffz_start()
    if dyn_smufl then
        find_dynamic({58683}, first_expression, "sforzato", dyn_smufl)
    else
        find_dynamic({141}, first_expression, "sforzato", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_sfp_start()
    if dyn_smufl then
        find_dynamic({58679}, first_expression, "sforzato piano", dyn_smufl)
    else
        find_dynamic({130}, first_expression, "sforzato piano", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_sfpp_start()
    if dyn_smufl then
        find_dynamic({58680}, first_expression, "sforzato pianissimo", dyn_smufl)
    else
        find_dynamic({182}, first_expression, "sforzato pianissimo", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_sfz_start()
    if dyn_smufl then
        find_dynamic({58681}, first_expression, "sforzato", dyn_smufl)
    else
        find_dynamic({167}, first_expression, "sforzato", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_sfzp_start()
    if dyn_smufl then
        find_dynamic({58681, 58656}, first_expression, "sforzando piano", dyn_smufl)
    else
        find_dynamic({167, 112}, first_expression, "sforzando piano", dyn_smufl)
    end
    dynamic_region("Start")
end

function dynamics_crescendo()
    deleteHairpins()
    for key, region in pairs(get_region(false)) do
        local return_dynamic_region = set_first_last_note_in_range(region)
        if return_dynamic_region ~= false then
            createHairpin(return_dynamic_region, finale.SMARTSHAPE_CRESCENDO)
        end
    end
    dynamics_align_hairpins_and_dynamics()
end

function dynamics_decrescendo()
    deleteHairpins()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            if set_first_last_note_in_range(music_region) ~= false then
                createHairpin(set_first_last_note_in_range(music_region), finale.SMARTSHAPE_DIMINUENDO)
            end
        end
    end
    dynamics_align_hairpins_and_dynamics()
end

function dynamics_messa_di_voce_up()
    deleteHairpins()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            if set_first_last_note_in_range(staff:GetItemNo()) ~= false then
                messa_di_voce(staff:GetItemNo(), finale.SMARTSHAPE_CRESCENDO, finale.SMARTSHAPE_DIMINUENDO)
            end
        end
    end
    dynamics_align_hairpins_and_dynamics()
end

function dynamics_messa_di_voce_down()
    deleteHairpins()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finenv.Region()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            if set_first_last_note_in_range(staff:GetItemNo()) ~= false then
                messa_di_voce(staff:GetItemNo(), finale.SMARTSHAPE_DIMINUENDO, finale.SMARTSHAPE_CRESCENDO)
            end
        end
    end
    dynamics_align_hairpins_and_dynamics()
end

function dynamics_nudge_up()
    local music_reg = finenv.Region()
    music_reg:SetCurrentSelection()

    local hairpin_list = {}

    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(music_reg, true)
    for mark in each(ssmm) do
        local smartshape = mark:CreateSmartShape()
        if smartshape:IsHairpin() then
            table.insert(hairpin_list, smartshape)
        end
    end

    --    local config = config_load()
    local nudge = config.nudge_normal

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(music_reg)
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                --        e:SetVerticalPos(e:GetVerticalPos() + 9)
                e:SetVerticalPos(e:GetVerticalPos() + nudge)
                e:Save()
            end
        end
    end

    for key, value in pairs(hairpin_list) do
        --    nudge_dynamics_and_hairpins(value, music_reg, 9)
        nudge_dynamics_and_hairpins(value, music_reg, nudge)
    end
end

function dynamics_nudge_down()
    local music_reg = finenv.Region()
    music_reg:SetCurrentSelection()

    local hairpin_list = {}

    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(music_reg, true)
    for mark in each(ssmm) do
        local smartshape = mark:CreateSmartShape()
        if smartshape:IsHairpin() then
            table.insert(hairpin_list, smartshape)
        end
    end

    --    local config = config_load()
    local nudge = config.nudge_normal

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(music_reg)
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                --        e:SetVerticalPos(e:GetVerticalPos() -9)
                e:SetVerticalPos(e:GetVerticalPos() - nudge)
                e:Save()
            end
        end
    end

    for key, value in pairs(hairpin_list) do
        --    nudge_dynamics_and_hairpins(value, music_reg, -9)
        nudge_dynamics_and_hairpins(value, music_reg, -nudge)
    end
end

function dynamics_delete_hairpins()
    deleteHairpins()
end

function dynamics_delete_dynamics()
    deleteDynamics()
end

function dynamics_ffff_end()
    if dyn_smufl then
        find_dynamic({58673}, first_expression, "fortissississimo (velocity = 127)", dyn_smufl)
    else
        find_dynamic({235}, first_expression, "fortissississimo (velocity = 127)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_fff_end()
    if dyn_smufl then
        find_dynamic({58672}, first_expression, "fortississimo (velocity = 114)", dyn_smufl)
    else
        find_dynamic({236}, first_expression, "fortississimo (velocity = 114)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_ff_end()
    if dyn_smufl then
        find_dynamic({58671}, first_expression, "fortissimo (velocity = 101)", dyn_smufl)
    else
        find_dynamic({196}, first_expression, "fortissimo (velocity = 101)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_f_end()
    if dyn_smufl then
        find_dynamic({58658}, first_expression, "forte (velocity = 88)", dyn_smufl)
    else
        find_dynamic({102}, first_expression, "forte (velocity = 88)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_mf_end()
    if dyn_smufl then
        find_dynamic({58669}, first_expression, "mezzo forte (velocity = 75)", dyn_smufl)
    else
        find_dynamic({70}, first_expression, "mezzo forte (velocity = 75)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_mp_end()
    if dyn_smufl then
        find_dynamic({58668}, first_expression, "mezzo piano (velocity = 62)", dyn_smufl)
    else
        find_dynamic({80}, first_expression, "mezzo piano (velocity = 62)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_p_end()
    if dyn_smufl then
        find_dynamic({58656}, first_expression, "piano (velocity = 49)", dyn_smufl)
    else
        find_dynamic({112}, first_expression, "piano (velocity = 49)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_pp_end()
    if dyn_smufl then
        find_dynamic({58667}, first_expression, "pianissimo (velocity = 36)", dyn_smufl)
    else
        find_dynamic({185}, first_expression, "pianissimo (velocity = 36)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_ppp_end()
    if dyn_smufl then
        find_dynamic({58666}, first_expression, "pianississimo (velocity = 23)", dyn_smufl)
    else
        find_dynamic({184}, first_expression, "pianississimo (velocity = 23)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_pppp_end()
    if dyn_smufl then
        find_dynamic({58665}, first_expression, "pianissississimo (velocity = 10)", dyn_smufl)
    else
        find_dynamic({175}, first_expression, "pianissississimo (velocity = 10)", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_fp_end()
    if dyn_smufl then
        find_dynamic({58676}, first_expression, "forte piano", dyn_smufl)
    else
        find_dynamic({234}, first_expression, "forte piano", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_fz_end()
    if dyn_smufl then
        find_dynamic({58677}, first_expression, "forzando", dyn_smufl)
    else
        find_dynamic({90}, first_expression, "forzando", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_n_end()
    if dyn_smufl then
        find_dynamic({58662}, first_expression, "niente (velocity = 0)", dyn_smufl)
    else
        findSpecialExpression({150}, {"Font0", 0, 24, 0}, first_expression, "niente (velocity = 0)", 1)
    end
    dynamic_region("End")
end

function dynamics_rf_end()
    if dyn_smufl then
        find_dynamic({58659}, first_expression, "rinforte", dyn_smufl)
    else
        find_dynamic({142, 102}, first_expression, "rinforte", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_rfz_end()
    if dyn_smufl then
        find_dynamic({58659}, first_expression, "rinforzando", dyn_smufl)
    else
        find_dynamic({142, 90}, first_expression, "rinforzando", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_sf_end()
    if dyn_smufl then
        find_dynamic({58678}, first_expression, "sforzando", dyn_smufl)
    else
        find_dynamic({83}, first_expression, "sforzando", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_sffz_end()
    if dyn_smufl then
        find_dynamic({58683}, first_expression, "sforzato", dyn_smufl)
    else
        find_dynamic({141}, first_expression, "sforzato", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_sfp_end()
    if dyn_smufl then
        find_dynamic({58679}, first_expression, "sforzato piano", dyn_smufl)
    else
        find_dynamic({130}, first_expression, "sforzato piano", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_sfpp_end()
    if dyn_smufl then
        find_dynamic({58680}, first_expression, "sforzato pianissimo", dyn_smufl)
    else
        find_dynamic({182}, first_expression, "sforzato pianissimo", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_sfz_end()
    if dyn_smufl then
        find_dynamic({58681}, first_expression, "sforzato", dyn_smufl)
    else
        find_dynamic({167}, first_expression, "sforzato", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_sfzp_end()
    if dyn_smufl then
        find_dynamic({58681, 58656}, first_expression, "sforzando piano", dyn_smufl)
    else
        find_dynamic({167, 112}, first_expression, "sforzando piano", dyn_smufl)
    end
    dynamic_region("End")
end

function dynamics_increase_dynamic()
    increase_decrease_dynamics("increase")
    dynamics_align_hairpins_and_dynamics()
end

function dynamics_decrease_dynamic()
    increase_decrease_dynamics("decrease")
    dynamics_align_hairpins_and_dynamics()
end

function articulations_accent()
    if check_SMuFL(nil) then
        findArticulation(1, 58528, "")
        if full_art_table[1] == 0 then
            createArticulation(
                1, 58528, default_music_font, 58528, true, true, false, false, 1, false, 58529, false, 0, 0, 125, true, false, false, 14, false, 0, 0, 0, 0, 58529,
                default_music_font, false, false, true, 0, 0, 125, true, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[1])
        end
    else
        findArticulation(1, 62, "")
        if full_art_table[1] == 0 then
            createArticulation(
                1, 62, "Maestro", 62, true, true, false, false, 1, false, 62, false, 0, 0, 125, true, false, false, 14, false, 0, -4, 0, -25, 62, "Maestro", false, false, true, 0,
                0, 125, true, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[1])
        end
    end
end

function articulations_marcato()
    if check_SMuFL(nil) then
        findArticulation(2, 58540, "")
        if full_art_table[2] == 0 then
            createArticulation(
                2, 58540, default_music_font, 58540, true, true, false, false, 5, false, 58541, false, 0, 0, 140, true, false, false, 16, false, 0, 0, 0, 0, 58541,
                default_music_font, false, false, true, 0, 0, 140, true, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[2])
        end
    else
        findArticulation(2, 94, "")
        if full_art_table[2] == 0 then
            createArticulation(
                2, 94, "Maestro", 94, true, true, false, false, 5, false, 118, false, 0, 0, 140, true, false, false, 16, false, 0, -4, 0, -18, 118, "Maestro", false, false, true,
                0, 0, 140, true, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[2])
        end
    end
end

function articulations_staccato()
    if check_SMuFL(nil) then
        findArticulation(3, 58530, "")
        if full_art_table[3] == 0 then
            createArticulation(
                3, 58530, default_music_font, 58530, true, false, false, false, 1, true, 58531, false, 0, 40, 0, true, false, false, 16, true, 0, -4, 0, 4, 58531,
                default_music_font, true, false, true, 0, 40, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[3])
        end
    else
        findArticulation(3, 46, "")
        if full_art_table[3] == 0 then
            createArticulation(
                3, 46, "Maestro", 46, true, false, false, false, 1, true, 46, false, 0, 40, 0, true, false, false, 16, true, 0, -3, 0, -3, 46, "Maestro", true, false, true, 0, 40,
                0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[3])
        end
    end
end

function articulations_tenuto()
    if check_SMuFL(nil) then
        findArticulation(4, 58532, "")
        if full_art_table[4] == 0 then
            createArticulation(
                4, 58532, default_music_font, 58532, true, false, false, false, 1, true, 58533, false, 0, 0, 0, true, false, false, 14, false, 0, -2, 0, 2, 58533,
                default_music_font, true, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 26, 26, false, false, false, false, 0, false, false,
                default_music_font, 26, 26, false, false)
        else
            addArticulation(full_art_table[4])
        end
    else
        findArticulation(4, 45, "")
        if full_art_table[4] == 0 then
            createArticulation(
                4, 45, "Maestro", 45, true, false, false, false, 1, true, 45, false, 0, 0, 0, true, false, false, 14, false, 0, -3, 0, -3, 45, "Maestro", true, false, false, 0, 0,
                0, false, false, false, 0, false, false, "Maestro", 26, 26, false, false, false, false, 0, false, false, "Maestro", 26, 26, false, false)
        else
            addArticulation(full_art_table[4])
        end
    end
end

function articulations_flat_wedge()
    if check_SMuFL(nil) then
        findArticulation(5, 58536, "")
        if full_art_table[5] == 0 then
            createArticulation(
                5, 58536, default_music_font, 58536, true, true, false, false, 1, true, 58537, false, 0, 30, 0, true, false, false, 12, true, 0, 0, 0, 0, 58537, default_music_font,
                false, false, true, 0, 30, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false, default_music_font, 24,
                24, false, false)
        else
            addArticulation(full_art_table[5])
        end
    else
        findArticulation(5, 171, "")
        if full_art_table[5] == 0 then
            createArticulation(
                5, 171, "Maestro", 171, true, true, false, false, 1, true, 216, false, 0, 30, 0, true, false, false, 12, true, 0, 12, 0, -22, 216, "Maestro", false, false, true, 0,
                30, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[5])
        end
    end
end

function articulations_round_wedge()
    if check_SMuFL(nil) then
        findArticulation(6, 58534, "")
        if full_art_table[6] == 0 then
            createArticulation(
                6, 58534, default_music_font, 58534, true, true, false, false, 1, true, 58535, false, 0, 30, 0, true, false, false, 12, true, 0, 0, 0, 0, 58535, default_music_font,
                false, false, true, 0, 30, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false, default_music_font, 24,
                24, false, false)
        else
            addArticulation(full_art_table[6])
        end
    else
        findArticulation(6, 174, "")
        if full_art_table[6] == 0 then
            createArticulation(
                6, 174, "Maestro", 174, true, true, false, false, 1, true, 39, false, 0, 30, 0, true, false, false, 12, true, 0, 12, 0, -22, 39, "Maestro", false, false, true, 0,
                30, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[6])
        end
    end
end

function articulations_metered_tremolo()
    if check_SMuFL(nil) then
        findArticulation(7, 57888, "")
        findArticulation(8, 57889, "")
        findArticulation(9, 57890, "")
        if full_art_table[7] == 0 then
            createArticulation(
                7, 57888, default_music_font, 57888, true, false, false, false, 0, false, 57888, false, 0, 0, 0, true, false, false, 21, false, 0, 0, 0, 0, 57888,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        end
        if full_art_table[8] == 0 then
            createArticulation(
                8, 57889, default_music_font, 57889, true, false, false, false, 0, false, 57889, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 57889,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        end
        if full_art_table[9] == 0 then
            createArticulation(
                9, 57890, default_music_font, 57890, true, false, false, false, 0, false, 57890, false, 0, 0, 0, true, false, false, 11, false, 0, 0, 0, 0, 57890,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        end
        deleteArticulation(full_art_table[7])
        deleteArticulation(full_art_table[8])
        deleteArticulation(full_art_table[9])
        addArticulation("metered tremolo")
    else
        findArticulation(7, 33, "")
        findArticulation(8, 64, "")
        findArticulation(9, 190, "")
        if full_art_table[7] == 0 then
            createArticulation(
                7, 33, "Maestro", 33, true, false, false, false, 0, false, 33, false, 0, 0, 0, true, false, false, 21, false, 0, 0, 0, 0, 33, "Maestro", false, false, false, 0, 0,
                0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        end
        if full_art_table[8] == 0 then
            createArticulation(
                8, 64, "Maestro", 64, true, false, false, false, 0, false, 64, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 64, "Maestro", false, false, false, 0, 0,
                0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        end
        if full_art_table[9] == 0 then
            createArticulation(
                9, 190, "Maestro", 190, true, false, false, false, 0, false, 190, false, 0, 0, 0, true, false, false, 11, false, 0, 0, 0, 0, 190, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        end
        deleteArticulation(full_art_table[7])
        deleteArticulation(full_art_table[8])
        deleteArticulation(full_art_table[9])
        addArticulation("metered tremolo")
    end
end

function articulations_tremolo_single()
    if check_SMuFL(nil) then
        findArticulation(7, 57888, "")
        if full_art_table[7] == 0 then
            createArticulation(
                7, 57888, default_music_font, 57888, true, false, false, false, 0, false, 57888, false, 0, 0, 0, true, false, false, 21, false, 0, 0, 0, 0, 57888,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            findArticulation(8, 57889, "")
            deleteArticulation(full_art_table[8])
            findArticulation(9, 57890, "")
            deleteArticulation(full_art_table[9])
            assignArticulation(full_art_table[7])
        end
    else
        findArticulation(7, 33, "")
        if full_art_table[7] == 0 then
            createArticulation(
                7, 33, "Maestro", 33, true, false, false, false, 0, false, 33, false, 0, 0, 0, true, false, false, 21, false, 0, 0, 0, 0, 33, "Maestro", false, false, false, 0, 0,
                0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            findArticulation(8, 64, "")
            deleteArticulation(full_art_table[8])
            findArticulation(9, 190, "")
            deleteArticulation(full_art_table[9])
            assignArticulation(full_art_table[7])
        end
    end
end

function articulations_tremolo_double()
    if check_SMuFL(nil) then
        findArticulation(8, 57889, "")
        if full_art_table[8] == 0 then
            createArticulation(
                8, 57889, default_music_font, 57889, true, false, false, false, 0, false, 57889, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 57889,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            findArticulation(7, 57888, "")
            deleteArticulation(full_art_table[7])
            findArticulation(9, 57890, "")
            deleteArticulation(full_art_table[9])
            assignArticulation(full_art_table[8])
        end
    else
        findArticulation(8, 64, "")
        if full_art_table[8] == 0 then
            createArticulation(
                8, 64, "Maestro", 64, true, false, false, false, 0, false, 64, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 64, "Maestro", false, false, false, 0, 0,
                0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            findArticulation(7, 33, "")
            deleteArticulation(full_art_table[7])
            findArticulation(9, 190, "")
            deleteArticulation(full_art_table[9])
            assignArticulation(full_art_table[8])
        end
    end
end

function articulations_tremolo_triple()
    if check_SMuFL(nil) then
        findArticulation(9, 57890, "")
        if full_art_table[9] == 0 then
            createArticulation(
                9, 57890, default_music_font, 57890, true, false, false, false, 0, false, 57890, false, 0, 0, 0, true, false, false, 11, false, 0, 0, 0, 0, 57890,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            findArticulation(7, 57888, "")
            deleteArticulation(full_art_table[7])
            findArticulation(8, 57889, "")
            deleteArticulation(full_art_table[8])
            assignArticulation(full_art_table[9])
        end
    else
        findArticulation(9, 190, "")
        if full_art_table[9] == 0 then
            createArticulation(
                9, 190, "Maestro", 190, true, false, false, false, 0, false, 190, false, 0, 0, 0, true, false, false, 11, false, 0, 0, 0, 0, 190, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            findArticulation(7, 33, "")
            deleteArticulation(full_art_table[7])
            findArticulation(8, 64, "")
            deleteArticulation(full_art_table[8])
            assignArticulation(full_art_table[9])
        end
    end
end

function articulations_fermata()
    if check_SMuFL(nil) then
        findArticulation(10, 58560, "")
        if full_art_table[10] == 0 then
            createArticulation(
                10, 58560, default_music_font, 58560, true, true, false, false, 5, false, 58561, false, 0, 0, 0, true, false, false, 14, false, 0, 0, 0, 0, 58561,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 22, 22, false, false, false, false, 0, false, false,
                default_music_font, 22, 22, false, false)
        else
            addArticulation(full_art_table[10])
        end
    else
        findArticulation(10, 85, "")
        if full_art_table[10] == 0 then
            createArticulation(
                10, 85, "Maestro", 85, true, true, false, false, 5, false, 117, false, 0, 0, 0, true, false, false, 14, false, 0, 0, 0, 0, 117, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 22, 22, false, false, false, false, 0, false, false, "Maestro", 22, 22, false, false)
        else
            addArticulation(full_art_table[10])
        end
    end
end

function articulations_closed()
    if check_SMuFL(nil) then
        findArticulation(11, 58853, "")
        if full_art_table[11] == 0 then
            createArticulation(
                11, 58853, default_music_font, 58853, true, true, false, false, 5, true, 58853, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 58853,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[11])
        end
    else
        findArticulation(11, 43, "")
        if full_art_table[11] == 0 then
            createArticulation(
                11, 43, "Maestro", 43, true, true, false, false, 5, true, 43, false, 0, 0, 0, true, false, false, 12, false, 0, 12, 0, -12, 43, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[11])
        end
    end
end

function articulations_open()
    if check_SMuFL(nil) then
        findArticulation(12, 58900, "")
        if full_art_table[12] == 0 then
            createArticulation(
                12, 58900, default_music_font, 58900, true, true, false, false, 5, true, 58900, false, 0, 0, 0, true, false, false, 20, false, 0, 0, 0, 0, 58900,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[12])
        end
    else
        findArticulation(12, 111, "")
        if full_art_table[12] == 0 then
            createArticulation(
                12, 111, "Maestro", 111, true, true, false, false, 5, true, 111, false, 0, 0, 0, true, false, false, 14, false, 0, 8, 0, 0, 111, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[12])
        end
    end
end

function articulations_upbow()
    if check_SMuFL(nil) then
        findArticulation(13, 58898, "")
        if full_art_table[13] == 0 then
            createArticulation(
                13, 58898, default_music_font, 58898, true, true, false, false, 5, false, 58898, true, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 58898,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[13])
        end
    else
        findArticulation(13, 178, "")
        if full_art_table[13] == 0 then
            createArticulation(
                13, 178, "Maestro", 178, true, true, false, false, 5, false, 178, true, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 178, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[13])
        end
    end
end

function articulations_downbow()
    if check_SMuFL(nil) then
        findArticulation(14, 58896, "")
        if full_art_table[14] == 0 then
            createArticulation(
                14, 58896, default_music_font, 58896, true, true, false, false, 5, false, 58896, true, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 58896,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[14])
        end
    else
        findArticulation(14, 179, "")
        if full_art_table[14] == 0 then
            createArticulation(
                14, 179, "Maestro", 179, true, true, false, false, 5, false, 179, true, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 179, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[14])
        end
    end
end

function articulations_trill()
    if check_SMuFL(nil) then
        findArticulation(15, 58726, "")
        if full_art_table[15] == 0 then
            createArticulation(
                15, 58726, default_music_font, 58726, true, true, false, false, 5, true, 58726, false, 0, 0, 0, true, false, false, 14, false, 3, 0, -3, 0, 58726,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[15])
        end
    else
        findArticulation(15, 217, "")
        if full_art_table[15] == 0 then
            createArticulation(
                15, 217, "Maestro", 217, true, true, false, false, 5, true, 217, false, 0, 0, 0, true, false, false, 14, false, 3, 12, -3, -20, 217, "Maestro", false, false, false,
                0, 0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[15])
        end
    end
end

function articulations_short_trill()
    if check_SMuFL(nil) then
        findArticulation(16, 58732, "")
        if full_art_table[16] == 0 then
            createArticulation(
                16, 58732, default_music_font, 58732, true, true, false, false, 5, true, 58732, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 58732,
                default_music_font, true, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[16])
        end
    else
        findArticulation(16, 109, "")
        if full_art_table[16] == 0 then
            createArticulation(
                16, 109, "Maestro", 109, true, true, false, false, 5, true, 109, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, -28, 109, "Maestro", true, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[16])
        end
    end
end

function articulations_mordent()
    if check_SMuFL(nil) then
        findArticulation(17, 58733, "")
        if full_art_table[17] == 0 then
            createArticulation(
                17, 58733, default_music_font, 58733, true, true, false, false, 5, true, 58733, false, 0, 0, 0, true, false, false, 16, false, 0, 0, 0, 0, 58733,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[17])
        end
    else
        findArticulation(17, 77, "")
        if full_art_table[17] == 0 then
            createArticulation(
                17, 77, "Maestro", 77, true, true, false, false, 5, true, 77, false, 0, 0, 0, true, false, false, 16, false, 0, 4, 0, -28, 77, "Maestro", false, false, false, 0, 0,
                0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[17])
        end
    end
end

function articulations_turn()
    if check_SMuFL(nil) then
        findArticulation(18, 58727, "")
        if full_art_table[18] == 0 then
            createArticulation(
                18, 58727, default_music_font, 58727, true, true, false, false, 5, true, 58727, false, 0, 0, 0, true, false, false, 12, false, 0, 0, 0, 0, 58727,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[18])
        end
    else
        findArticulation(18, 84, "")
        if full_art_table[18] == 0 then
            createArticulation(
                18, 84, "Maestro", 84, true, true, false, false, 5, true, 84, false, 0, 0, 0, true, false, false, 12, false, 0, 18, 0, -18, 84, "Maestro", false, false, false, 0,
                0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[18])
        end
    end
end

function articulations_roll()
    if check_SMuFL(nil) then
        findArticulation(19, 63232, "")
        if full_art_table[19] == 0 then
            createArticulation(
                19, 63232, default_music_font, 63232, true, false, false, false, 0, false, 63232, true, -256, 0, 0, false, true, false, 0, false, -28, -28, -22, 0, 63232,
                default_music_font, false, false, true, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[19])
        end
        roll_articulation_assignment(63232)
    else
        findArticulation(19, 103, "")
        if full_art_table[19] == 0 then
            createArticulation(
                19, 103, "Maestro", 103, true, false, false, false, 0, false, 103, true, -256, 0, 0, false, true, false, 0, false, -28, -28, -22, 0, 103, "Maestro", false, false,
                true, 0, 0, 0, false, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[19])
        end
        roll_articulation_assignment(103)
    end
end

function articulations_fall_short()
    if check_SMuFL(nil) then
        findArticulation(20, 58839, "")
        if full_art_table[20] == 0 then
            createArticulation(
                20, 58839, default_music_font, 58839, true, false, false, false, 2, false, 58839, false, 0, 0, 0, true, false, false, 0, false, 42, -12, 42, 12, 58839,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[20])
        end
    else
        findArticulation(20, 152, "Broadway Copyist")
        if full_art_table[20] == 0 then
            createArticulation(
                20, 152, "Broadway Copyist", 152, true, false, false, false, 2, false, 152, false, 0, 0, 0, true, false, false, 0, false, 36, -30, 36, 0, 152, "Broadway Copyist",
                false, false, false, 0, 0, 0, false, false, false, 0, false, false, "Broadway Copyist", 20, 20, false, false, false, false, 0, false, false, "Broadway Copyist", 20,
                20, false, false)
        else
            addArticulation(full_art_table[20])
        end
    end
end

function articulations_fall_long()
    if check_SMuFL(nil) then
        findArticulation(21, 58846, "")
        if full_art_table[21] == 0 then
            createArticulation(
                21, 58846, default_music_font, 58846, true, false, false, false, 2, false, 58846, false, 0, 0, 0, true, false, false, 0, false, 72, -76, 72, -48, 58846,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[21])
        end
    else
        findArticulation(21, 92, "Broadway Copyist")
        if full_art_table[21] == 0 then
            createArticulation(
                21, 92, "Broadway Copyist", 92, true, false, false, false, 2, false, 92, false, 0, 0, 0, true, false, false, 0, false, 54, -54, 54, -30, 92, "Broadway Copyist",
                false, false, false, 0, 0, 0, false, false, false, 0, false, false, "Broadway Copyist", 24, 24, false, false, false, false, 0, false, false, "Broadway Copyist", 24,
                24, false, false)
        else
            addArticulation(full_art_table[21])
        end
    end
end

function articulations_rip_straight()
    if check_SMuFL(nil) then
        findArticulation(22, 58833, "")
        if full_art_table[22] == 0 then
            createArticulation(
                22, 58833, default_music_font, 58833, true, false, false, false, 2, false, 58833, false, 0, 0, 0, true, false, false, 0, false, -54, -60, -54, -26, 58833,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[22])
        end
    else
        findArticulation(22, 151, "Broadway Copyist")
        if full_art_table[22] == 0 then
            createArticulation(
                22, 151, "Broadway Copyist", 151, true, false, false, false, 2, false, 151, false, 0, 0, 0, true, false, false, 0, false, -48, -36, -48, -6, 151,
                "Broadway Copyist", false, false, false, 0, 0, 0, false, false, false, 0, false, false, "Broadway Copyist", 18, 18, false, false, false, false, 0, false, false,
                "Broadway Copyist", 18, 18, false, false)
        else
            addArticulation(full_art_table[22])
        end
    end
end

function articulations_rip_long()
    if check_SMuFL(nil) then
        findArticulation(23, 58834, "")
        if full_art_table[23] == 0 then
            createArticulation(
                23, 58834, default_music_font, 58834, true, false, false, false, 2, false, 58834, false, 0, 0, 0, true, false, false, 0, false, -70, -80, -70, -48, 58834,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[23])
        end
    else
        findArticulation(23, 149, "Broadway Copyist")
        if full_art_table[23] == 0 then
            createArticulation(
                23, 149, "Broadway Copyist", 149, true, false, false, false, 2, false, 149, false, 0, 0, 0, true, false, false, 0, false, -54, -36, -54, -12, 149,
                "Broadway Copyist", false, false, false, 0, 0, 0, false, false, false, 0, false, false, "Broadway Copyist", 18, 18, false, false, false, false, 0, false, false,
                "Broadway Copyist", 18, 18, false, false)
        else
            addArticulation(full_art_table[23])
        end
    end
end

function articulations_scoop_short()
    if check_SMuFL(nil) then
        findArticulation(24, 58834, "")
        if full_art_table[24] == 0 then
            createArticulation(
                24, 58832, default_music_font, 58832, true, false, false, false, 1, false, 58832, false, 0, 0, 0, false, false, false, 0, false, -48, -18, -48, 0, 58832,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[24])
        end
    else
        findArticulation(24, 155, "Broadway Copyist")
        if full_art_table[24] == 0 then
            createArticulation(
                24, 155, "Broadway Copyist", 155, true, false, false, false, 2, false, 155, false, 0, 0, 0, true, false, false, 0, false, -36, -24, -36, 0, 155, "Broadway Copyist",
                false, false, false, 0, 0, 0, false, false, false, 0, false, false, "Broadway Copyist", 18, 18, false, false, false, false, 0, false, false, "Broadway Copyist", 18,
                18, false, false)
        else
            addArticulation(full_art_table[24])
        end
    end
end

function articulations_doit()
    if check_SMuFL(nil) then
        findArticulation(25, 58860, "")
        if full_art_table[25] == 0 then
            createArticulation(
                25, 58860, default_music_font, 58860, true, false, false, false, 2, false, 58860, false, 0, 0, 0, true, false, false, 0, false, 44, 0, 44, 12, 58860,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[25])
        end
    else
        findArticulation(25, 243, "Broadway Copyist")
        if full_art_table[25] == 0 then
            createArticulation(
                25, 243, "Broadway Copyist", 243, true, false, false, false, 2, false, 243, false, 0, 0, 0, true, false, false, 0, false, 42, 6, 42, 30, 243, "Broadway Copyist",
                false, false, false, 0, 0, 0, false, false, false, 0, false, false, "Broadway Copyist", 20, 20, false, false, false, false, 0, false, false, "Broadway Copyist", 20,
                20, false, false)
        else
            addArticulation(full_art_table[25])
        end
    end
end

function articulations_lv()
    if check_SMuFL(nil) then
        findArticulation(26, 58554, "")
        if full_art_table[26] == 0 then
            createArticulation(
                26, 58554, default_music_font, 58554, true, false, false, false, 2, true, 58555, false, 0, 0, 0, true, false, false, 0, false, 39, -6, 39, 7, 58555,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 28, 28, false, false, false, false, 0, false, false,
                default_music_font, 28, 28, false, false)
        else
            addArticulation(full_art_table[26])
        end
    else
        local font_name = getUsedFontName("Engraver Font Set")
        findArticulation(26, 105, font_name)
        if full_art_table[26] == 0 then
            createArticulation(
                26, 105, font_name, 105, true, false, false, false, 2, true, 73, false, 0, 0, 0, true, false, false, 0, false, 39, -6, 39, 7, 73, font_name, false, false, false, 0,
                0, 0, false, false, false, 0, false, false, font_name, 28, 28, false, false, false, false, 0, false, false, font_name, 28, 28, false, false)
        else
            addArticulation(full_art_table[26])
        end
    end
end

function articulations_split_articulations()
    split_articulations()
end

function articulations_delete_articulations()
    for noteentry in eachentrysaved(finenv.Region()) do
        local a = finale.FCArticulation()
        a:SetNoteEntry(noteentry)
        while a:LoadFirst() do
            a:DeleteData()
        end
    end
end

function articulations_left_bracket_1(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(27, 193, font_name)
    if full_art_table[27] == 0 then
        createNewArticulation(
            27, 193, font_name, 193, true, false, false, false, 2, false, 193, false, 0, 0, 0, true, false, false, 0, false, -66, -12, -36, 24, 193, font_name, true, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[27])
    else
        addNewArticulation(noteentry, full_art_table[27])
    end
end

function articulations_left_bracket_2(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(28, 170, font_name)
    if full_art_table[28] == 0 then
        createNewArticulation(
            28, 170, font_name, 170, true, false, false, false, 2, false, 170, false, 0, 0, 0, true, false, false, 0, false, -36, -12, -36, 42, 170, font_name, false, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[28])
    else
        addNewArticulation(noteentry, full_art_table[28])
    end
end

function articulations_left_bracket_3(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(29, 163, font_name)
    if full_art_table[29] == 0 then
        createNewArticulation(
            29, 163, font_name, 163, true, false, false, false, 2, false, 163, false, 0, 0, 0, true, false, false, 0, false, -36, -18, -36, 66, 163, font_name, false, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[29])
    else
        addNewArticulation(noteentry, full_art_table[29])
    end
end

function articulations_left_bracket_4(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(30, 162, font_name)
    if full_art_table[30] == 0 then
        createNewArticulation(
            30, 162, font_name, 162, true, false, false, false, 2, false, 162, false, 0, 0, 0, true, false, false, 0, false, -36, -18, -36, 90, 162, font_name, false, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[30])
    else
        addNewArticulation(noteentry, full_art_table[30])
    end
end

function articulations_left_brackets()
    for noteentry in eachentrysaved(finenv.Region()) do
        local note_range = noteentry:CalcDisplacementRange()
        if (note_range == 1) then
            articulations_left_bracket_1(noteentry)
        end
        if (note_range == 2) or (note_range == 3) then
            articulations_left_bracket_2(noteentry)
        end
        if (note_range == 4) or (note_range == 5) then
            articulations_left_bracket_3(noteentry)
        end
        if (note_range == 6) or (note_range == 7) then
            articulations_left_bracket_4(noteentry)
        end
    end
end

function articulations_right_bracket_1(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(31, 176, font_name)
    if full_art_table[31] == 0 then
        createNewArticulation(
            31, 176, font_name, 176, true, false, false, false, 2, false, 176, false, 0, 0, 0, true, false, false, 0, false, 36, -12, 66, 24, 176, font_name, false, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[31])
    else
        addNewArticulation(noteentry, full_art_table[31])
    end
end

function articulations_right_bracket_2(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(32, 164, font_name)
    if full_art_table[32] == 0 then
        createNewArticulation(
            32, 164, font_name, 164, true, false, false, false, 2, false, 164, false, 0, 0, 0, true, false, false, 0, false, 36, -12, 36, 42, 164, font_name, false, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[32])
    else
        addNewArticulation(noteentry, full_art_table[32])
    end
end

function articulations_right_bracket_3(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(33, 166, font_name)
    if full_art_table[33] == 0 then
        createNewArticulation(
            33, 166, font_name, 166, true, false, false, false, 2, false, 166, false, 0, 0, 0, true, false, false, 0, false, 36, -18, 36, 66, 166, font_name, false, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[33])
    else
        addNewArticulation(noteentry, full_art_table[33])
    end
end

function articulations_right_bracket_4(noteentry)
    local font_name = getUsedFontName("Engraver Font Set")
    findArticulation(34, 165, font_name)
    if full_art_table[34] == 0 then
        createNewArticulation(
            34, 165, font_name, 165, true, false, false, false, 2, false, 165, false, 0, 0, 0, true, false, false, 0, false, 36, -18, 36, 90, 165, font_name, false, false, false,
            0, 0, 0, false, false, false, 0, false, false, font_name, 24, 24, false, false, false, false, 0, false, false, font_name, 24, 24, false, false)
        assignNewArticulation(noteentry, full_art_table[34])
    else
        addNewArticulation(noteentry, full_art_table[34])
    end
end

function articulations_right_brackets()
    for noteentry in eachentrysaved(finenv.Region()) do
        local note_range = noteentry:CalcDisplacementRange()
        if (note_range == 1) then
            articulations_right_bracket_1(noteentry)
        end
        if (note_range == 2) or (note_range == 3) then
            articulations_right_bracket_2(noteentry)
        end
        if (note_range == 4) or (note_range == 5) then
            articulations_right_bracket_3(noteentry)
        end
        if (note_range == 6) or (note_range == 7) then
            articulations_right_bracket_4(noteentry)
        end
    end
end

function articulations_combo_tenuto_staccato()
    if check_SMuFL(nil) then
        findArticulation(35, 58546, "")
        if full_art_table[35] == 0 then
            createArticulation(
                35, 58546, default_music_font, 58546, true, true, false, false, 1, true, 58547, false, 0, 75, 110, true, false, false, 16, true, 0, 0, 0, 0, 58547,
                default_music_font, true, false, true, 0, 75, 110, true, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[35])
        end
    else
        findArticulation(35, 248, "")
        if full_art_table[35] == 0 then
            createArticulation(
                35, 248, "Maestro", 248, true, true, false, false, 1, true, false, 0, 75, 110, true, false, false, 16, true, 0, -2, 0, -21, 60, "Maestro", true, false, true, 0, 75,
                110, true, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[35])
        end
    end
end

function articulations_combo_accent_staccato()
    if check_SMuFL(nil) then
        findArticulation(36, 58544, "")
        if full_art_table[36] == 0 then
            createArticulation(
                36, 58544, default_music_font, 58544, true, true, false, false, 1, false, 58545, false, 0, 50, 125, true, false, false, 19, true, 0, 0, 0, 0, 58545,
                default_music_font, false, false, true, 0, 50, 125, true, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[36])
        end
    else
        findArticulation(36, 249, "")
        if full_art_table[36] == 0 then
            createArticulation(
                36, 249, "Maestro", 249, true, true, false, false, 1, false, false, 0, 50, 125, true, false, false, 19, true, 0, 0, 0, -35, 223, "Maestro", false, false, true, 0,
                50, 125, true, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[36])
        end
    end
end

function articulations_combo_accent_tenuto()
    if check_SMuFL(nil) then
        findArticulation(37, 58548, "")
        if full_art_table[37] == 0 then
            createArticulation(
                37, 58548, default_music_font, 58548, true, true, false, false, 1, false, 58549, false, 0, 0, 125, true, false, false, 12, false, 0, 0, 0, 0, 58549,
                default_music_font, false, false, true, 0, 0, 125, true, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[37])
        end
    else
        findArticulation(37, 138, "")
        if full_art_table[37] == 0 then
            local font_name = getUsedFontName("Engraver Font Set")
            findArticulation(37, 251, font_name)
            if full_art_table[37] == 0 then
                createArticulation(
                    37, 138, "Maestro", 138, true, true, false, false, 1, false, false, 0, 0, 125, true, false, false, 12, false, 0, 0, 0, -30, 137, "Maestro", false, false, true,
                    0, 0, 125, true, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
            end
        else
            addArticulation(full_art_table[37])
        end
    end
end

function articulations_combo_marcato_staccato()
    if check_SMuFL(nil) then
        findArticulation(38, 58542, "")
        if full_art_table[38] == 0 then
            createArticulation(
                38, 58542, default_music_font, 58542, true, true, false, false, 5, false, 58543, false, 0, 75, 140, true, false, false, 16, true, 0, 0, 0, 0, 58543,
                default_music_font, false, false, true, 0, 75, 140, true, false, false, 0, false, false, default_music_font, 24, 24, false, false, false, false, 0, false, false,
                default_music_font, 24, 24, false, false)
        else
            addArticulation(full_art_table[38])
        end
    else
        findArticulation(38, 172, "")
        if full_art_table[38] == 0 then
            createArticulation(
                38, 172, "Maestro", 172, true, true, false, false, 5, false, false, 0, 75, 140, true, false, false, 16, true, 0, -4, 0, -18, 232, "Maestro", false, false, true, 0,
                75, 140, true, false, false, 0, false, false, "Maestro", 24, 24, false, false, false, false, 0, false, false, "Maestro", 24, 24, false, false)
        else
            addArticulation(full_art_table[38])
        end
    end
end

function articulations_tremolo_z()
    if check_SMuFL(nil) then
        findArticulation(39, 57898, "")
        if full_art_table[39] == 0 then
            createArticulation(
                39, 57898, default_music_font, 57898, true, false, false, false, 0, false, 57898, false, 0, 0, 0, true, false, false, 10, false, 0, 0, 0, 0, 57898,
                default_music_font, false, false, false, 0, 0, 0, false, false, false, 0, false, false, default_music_font, 30, 30, false, false, false, false, 0, false, false,
                default_music_font, 30, 30, false, false)
        else
            addArticulation(full_art_table[39])
        end
    else
        findArticulation(39, 122, "")
        if full_art_table[39] == 0 then
            createArticulation(
                39, 122, "Maestro", 122, true, false, false, false, 0, false, false, 0, 0, 0, true, false, false, 10, false, 0, 0, 0, -9, 122, "Maestro", false, false, false, 0, 0,
                0, false, false, false, 0, false, false, "Maestro", 30, 30, false, false, false, false, 0, false, false, "Maestro", 30, 30, false, false)
        else
            addArticulation(full_art_table[39])
        end
    end
end

function articulations_delete_duplicate_articulations()
    for noteentry in eachentrysaved(finenv.Region()) do
        delete_duplicate_articulations(noteentry)
    end
end

function noteheads_x_circle()
    if check_SMuFL(nil) then
        changeNoteheads("", 57513, 57523, 57523, 57523)
    else
        changeNoteheads("Maestro Percussion", 120, 88, 88, 88)
    end
end

function noteheads_cross_circle()
    if check_SMuFL(nil) then
        changeNoteheads("", 57514, 57515, 57515, 57515)
    else
        changeNoteheads("Maestro Percussion", 122, 90, 90, 90)
    end
end

function noteheads_x_default()
    --    local config = config_load()
    local x_type = tonumber(config.x_type)
    if x_type == 0 then
        noteheads_x_circle()
    elseif x_type == 1 then
        noteheads_x_diamond()
    end
end

function noteheads_x_above_staff()
    local nm = finale.FCNoteheadMod()
    nm:SetUseCustomFont(true)
    nm.FontName = default_music_font
    --    local config = config_load()
    local x_type = tonumber(config.x_type)
    local closed_note = 57513
    local half_note = 0
    if x_type == 0 then
        half_note = 57523
    elseif x_type == 1 then
        half_note = 57562
    end

    if not check_SMuFL(nil) then
        nm.FontName = "Maestro Percussion"
        closed_note = 120
        if x_type == 0 then
            half_note = 88
        elseif x_type == 1 then
            half_note = 84
        end
    end

    for noteentry in eachentrysaved(finenv.Region()) do
        nm:SetNoteEntry(noteentry)
        for note in each(noteentry) do
            if note:CalcStaffPosition() >= -1 then
                if noteentry.Duration < 2048 then
                    nm.CustomChar = closed_note
                    -- nm:SetResize(100)
                end
                if (noteentry.Duration > 1536) then
                    nm.CustomChar = half_note
                    -- nm:SetResize(130)
                end
                nm:SaveAt(note)
            end
        end
    end
end

function noteheads_triangle_up()
    if check_SMuFL(nil) then
        changeNoteheads("", 57534, 57533, 57533, 57533)
    else
        changeNoteheads("Maestro Percussion", 49, 33, 33, 33)
    end
end

function noteheads_triangle_down()
    if check_SMuFL(nil) then
        changeNoteheads("", 57543, 57542, 57542, 57542)
    else
        changeNoteheads("Maestro Percussion", 45, 95, 95, 95)
    end
end

function noteheads_diamond()
    if check_SMuFL(nil) then
        changeNoteheads("", 57564, 57566, 57566, 57566)
    else
        changeNoteheads("Maestro Percussion", 51, 35, 35, 35)
    end
end

function noteheads_ghost()
    if check_SMuFL(nil) then
        changeNoteheads("", 62929, 62930, 62931, 62931)
    else
        changeNoteheads("Maestro Percussion", 101, 69, 69, 69)
    end
end

function noteheads_cross_stick()
    if check_SMuFL(nil) then
        changeNoteheads("", 57576, 57577, 57578, 57578)
    else
        changeNoteheads("Maestro Percussion", 102, 70, 70, 70)
    end
end

function noteheads_small_slash()
    if check_SMuFL(nil) then
        changeNoteheads("", 57600, 57604, 57604, 57604)
    else
        changeNoteheads("Maestro", 243, 124, 124, 218)
    end
end

function noteheads_square()
    if check_SMuFL(nil) then
        changeNoteheads("", 57529, 57528, 57528, 57528)
    else
        changeNoteheads("Maestro Percussion", 54, 94, 94, 94)
    end
end

function noteheads_rim()
    if check_SMuFL(nil) then
        changeNoteheads("", 57552, 57554, 57556, 57556)
    else
        changeNoteheads("Maestro Percussion", 104, 72, 72, 72)
    end
end

function noteheads_no_notehead()
    if check_SMuFL(nil) then
        changeNoteheads("", 57509, 57509, 57509, 57509)
    else
        changeNoteheads("Maestro", 32, 32, 32, 32)
    end
end

function noteheads_default()
    local nm = finale.FCNoteheadMod()
    nm:SetUseCustomFont(false)

    for noteentry in eachentrysaved(finenv.Region()) do
        noteentry:SetLedgerLines(true)
        nm:SetNoteEntry(noteentry)
        for note in each(noteentry) do
            nm:ClearChar()
            local notehead = finale.FCNoteheadMod()
            notehead:LoadAt(note)
            notehead.HorizontalPos = 0
            notehead.VerticalPos = 0
            notehead:SaveAt(note)
            nm:SaveAt(note)
        end
    end
end

function reset_rests()
    for noteentry in eachentrysaved(finenv.Region()) do
        if noteentry:IsRest() then
            noteentry:SetFloatingRest(true)
        end
    end
end

function layers_one_reduce()
    change_notehead_size(1, 75, nil)
end

function layers_two_reduce()
    change_notehead_size(2, 75, nil)
end

function layers_three_reduce()
    change_notehead_size(3, 75, nil)
end

function layers_four_reduce()
    change_notehead_size(4, 75, nil)
end

function layers_one_melody_top()
    change_notehead_size(1, 75, true)
end

function layers_two_melody_top()
    change_notehead_size(2, 75, true)
end

function layers_three_melody_top()
    change_notehead_size(3, 75, true)
end

function layers_four_melody_top()
    change_notehead_size(4, 75, true)
end

function layers_one_melody_bottom()
    change_notehead_size(1, 75, false)
end

function layers_two_melody_bottom()
    change_notehead_size(2, 75, false)
end

function layers_three_melody_bottom()
    change_notehead_size(3, 75, false)
end

function layers_four_melody_bottom()
    change_notehead_size(4, 75, false)
end

function layers_all_reset()
    change_notehead_size(1, 100, nil)
    change_notehead_size(2, 100, nil)
    change_notehead_size(3, 100, nil)
    change_notehead_size(4, 100, nil)
end

function layers_all_reduce()
    change_notehead_size(1, 75, nil)
    change_notehead_size(2, 75, nil)
    change_notehead_size(3, 75, nil)
    change_notehead_size(4, 75, nil)
end

function noteheads_x_diamond()
    if check_SMuFL(nil) then
        changeNoteheads("", 57513, 57565, 57565, 57565)
    else
        changeNoteheads("Maestro Percussion", 120, 84, 84, 84)
    end

    local nm = finale.FCNoteheadMod()
    for noteentry in eachentrysaved(finenv.Region()) do
        nm:SetNoteEntry(noteentry)
        if noteentry.Duration > 1536 then
            for note in each(noteentry) do
                nm:LoadAt(note)
                nm:SetResize(130)
                nm:SaveAt(note)
            end
        else
            for note in each(noteentry) do
                nm:LoadAt(note)
                nm:SetResize(100)
                nm:SaveAt(note)
            end
        end
    end
end

function noteheads_x_diamond_above_staff()
    local nm = finale.FCNoteheadMod()
    nm:SetUseCustomFont(true)
    nm.FontName = default_music_font
    local standard_note = 57513
    local open_note = 57565

    if not check_SMuFL(nil) then
        nm.FontName = "Maestro Percussion"
        standard_note = 120
        open_note = 84
    end

    for noteentry in eachentrysaved(finenv.Region()) do
        nm:SetNoteEntry(noteentry)
        for note in each(noteentry) do
            if note:CalcStaffPosition() >= -1 then
                if noteentry.Duration < 2048 then
                    nm.CustomChar = 120
                    nm:SetResize(100)
                end
                if (noteentry.Duration > 1536) then
                    nm.CustomChar = 84
                    nm:SetResize(130)
                end
                nm:SaveAt(note)
            end
        end
    end
end

function noteheads_center_noteheads()
    local region = finenv.Region()
    for entry in eachentrysaved(region) do
        for note in each(entry) do
            local off = 0
            local notehead = finale.FCNoteheadMod()
            notehead:LoadAt(note)
            local width = note:CalcNoteheadWidth()
            if note:CalcRightsidePlacement() then
                off = -width / 2 + 1
            else
                off = width / 2 - 1
            end
            notehead.HorizontalPos = notehead.HorizontalPos + off
            notehead:SaveAt(note)
        end
    end
end

function transform_harmonics_thrid()
    string_harmonics_touch(3)
end

function transform_harmonics_fourth()
    string_harmonics_touch(4)
end

function transform_harmonics_fifth()
    string_harmonics_touch(5)
end

function lyrics_clear_lyrics()
    for noteentry in eachentry(finenv.Region()) do
        local cs = finale.FCChorusSyllable()
        cs:SetNoteEntry(noteentry)
        if cs:LoadFirst() then
            cs:DeleteData()
        end
        local vs = finale.FCVerseSyllable()
        vs:SetNoteEntry(noteentry)
        if vs:LoadFirst() then
            vs:DeleteData()
        end
        local ss = finale.FCSectionSyllable()
        ss:SetNoteEntry(noteentry)
        if ss:LoadFirst() then
            ss:DeleteData()
        end
    end
end

function reset_baselines_lyrics()
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()
    local start_staff = region:GetStartStaff()
    local end_staff = region:GetEndStaff()

    for i = system_number, lastSys_number, 1 do
        local baselines_verse = finale.FCBaselines()
        local baselines_chorus = finale.FCBaselines()
        local baselines_section = finale.FCBaselines()
        local lyric_number = 1
        baselines_verse:LoadAllForSystem(finale.BASELINEMODE_LYRICSVERSE, i)
        baselines_chorus:LoadAllForSystem(finale.BASELINEMODE_LYRICSCHORUS, i)
        baselines_section:LoadAllForSystem(finale.BASELINEMODE_LYRICSSECTION, i)
        for j = start_staff, end_staff, 1 do
            for k = lyric_number, 100, 1 do
                bl_v = baselines_verse:AssureSavedLyricNumber(finale.BASELINEMODE_LYRICSVERSE, i, j, k)
                bl_v.VerticalOffset = 0
                bl_v:Save()
                bl_c = baselines_chorus:AssureSavedLyricNumber(finale.BASELINEMODE_LYRICSCHORUS, i, j, k)
                bl_c.VerticalOffset = 0
                bl_c:Save()
                bl_s = baselines_section:AssureSavedLyricNumber(finale.BASELINEMODE_LYRICSSECTION, i, j, k)
                bl_s.VerticalOffset = 0
                bl_s:Save()
            end
        end
    end
end

function lyrics_delete_lyrics()
    local confirm_delete = finenv.UI():AlertYesNo(
                               "This will completely remove all Verse, Chorus and Section Lyrics from the current document. (To erase lyrics from the score without removing them from the file, use Clear Lyrics.) Are you sure you want to proceed?",
                               "WARNING!")

    if confirm_delete == 2 then
        remove_lyrics_from_document()
    else
        return
    end
end

function barline_right_invisible()
    barline_change(0, false)
end

function barline_right_single()
    barline_change(1, false)
end

function barline_right_double()
    barline_change(2, false)
end

function barline_right_dashed()
    barline_change(3, false)
end

function barline_right_thick()
    barline_change(4, false)
end

function barline_right_final()
    barline_change(5, false)
end

function barline_right_tick()
    barline_change(6, false)
end

function barline_right_custom()
    barline_change(7, false)
end

function barline_bookend_invisible()
    barline_change(0, true)
end

function barline_bookend_single()
    barline_change(1, true)
end

function barline_bookend_double()
    barline_change(2, true)
end

function barline_bookend_dashed()
    barline_change(3, true)
end

function barline_bookend_thick()
    barline_change(4, true)
end

function barline_bookend_final()
    barline_change(5, true)
end

function barline_bookend_tick()
    barline_change(6, true)
end

function barline_bookend_custom()
    barline_change(7, true)
end

function reset_barlines()
    local measures = finale.FCMeasures()
    measures:LoadRegion(finenv.Region())
    for measure in each(measures) do
        measure.Barline = 1
        measure:Save()
    end
end

function barline_add_at_double_rehearsal_letter()
    find_double_barlines("Letter")
end

function barline_add_at_double_rehearsal_number()
    find_double_barlines("Number")
end

function barline_add_at_double_rehearsal_measure()
    find_double_barlines("Measure")
end

function barline_clear_rehearsal()
    delete_rehearsal_marks()
end

function chords_altered_bass_after()
    alter_bass(0)
end

function chords_altered_bass_under()
    alter_bass(1)
end

function chords_altered_bass_subtext()
    alter_bass(2)
end

function reset_chord_symbol_pos()
    local chords = finale.FCChords()
    chords:LoadAllForRegion(finenv.Region())
    for c in each(chords) do
        c:SetChordVerticalPos(0)
        c:SetChordHorizontalPos(0)
        c:Save()
    end
end

function polyphony_add_octave_up()
    double_octave(1)
end

function polyphony_add_octave_down()
    double_octave(-1)
end

function polyphony_add_diatonic_third_up()
    double_third_higher()
end

function polyphony_add_diatonic_third_down()
    double_third_lower()
end

function polyphony_rotate_up()
    rotate_chord_up()
end

function polyphony_rotate_down()
    rotate_chord_down()
end

function polyphony_delete_top_note()
    chord_line_delete_top()
end

function polyphony_delete_bottom_note()
    chord_line_delete_bottom()
end

function polyphony_keep_top_note()
    chord_line_keep_top()
end

function polyphony_keep_bottom_note()
    chord_line_keep_bottom()
end

function meter_2_4()
    set_time(2, 1024, false)
end

function meter_2_2()
    set_time(2, 2048, false)
end

function meter_3_2()
    set_time(3, 2048, false)
end

function meter_3_4()
    set_time(3, 1024, false)
end

function meter_3_8()
    set_time(1, 1536, false)
end

function meter_4_4()
    set_time(4, 1024, false)
end

function meter_5_4()
    set_time(5, 1024, false)
end

function meter_5_8()
    set_time(5, 512, false)
end

function meter_6_8()
    set_time(2, 1536, false)
end

function meter_7_8()
    set_time(7, 512, false)
end

function meter_9_8()
    set_time(3, 1536, false)
end

function meter_12_8()
    set_time(4, 1536, false)
end

function meter_6_4()
    set_time(6, 1024, false)
end

function meter_common_time()
    set_time(4, 1024, true)
end

function meter_cut_time()
    set_time(2, 2048, true)
end

function smartshape_trill()
    deleteBeatSmartShape(finale.SMARTSHAPE_TRILLEXT)
    deleteBeatSmartShape(finale.SMARTSHAPE_TRILL)
    createBeatBasedSL(finale.SMARTSHAPE_TRILL, true)
end

function smartshape_trill_extension()
    deleteBeatSmartShape(finale.SMARTSHAPE_TRILL)
    deleteBeatSmartShape(finale.SMARTSHAPE_TRILLEXT)
    createBeatBasedSL(finale.SMARTSHAPE_TRILLEXT, true)
end

function smartshape_dashed_line()
    deleteBeatSmartShape(finale.SMARTSHAPE_DASHLINE)
    createBeatBasedSL(finale.SMARTSHAPE_DASHLINE, true)
end

function smartshape_solid_line()
    deleteBeatSmartShape(finale.SMARTSHAPE_SOLIDLINE)
    createBeatBasedSL(finale.SMARTSHAPE_SOLIDLINE, true)
end

function smartshape_tab_slide()
    deleteEntrySmartShape(finale.SMARTSHAPE_TABSLIDE)
    setFirstLastNoteRangeEntry(finale.SMARTSHAPE_TABSLIDE)
end

function smartshape_glissando()
    deleteEntrySmartShape(finale.SMARTSHAPE_GLISSANDO)
    setFirstLastNoteRangeEntry(finale.SMARTSHAPE_GLISSANDO)
end

function smartshape_dashed_bracket()
    deleteBeatSmartShape(finale.SMARTSHAPE_SOLIDLINEDOWN)
    deleteBeatSmartShape(finale.SMARTSHAPE_DASHLINEDOWN)
    createBeatBasedSL(finale.SMARTSHAPE_DASHLINEDOWN, true)
end

function smartshape_solid_bracket()
    deleteBeatSmartShape(finale.SMARTSHAPE_DASHLINEDOWN)
    deleteBeatSmartShape(finale.SMARTSHAPE_SOLIDLINEDOWN)
    createBeatBasedSL(finale.SMARTSHAPE_SOLIDLINEDOWN, true)
end

function smartshape_custom()
    deleteBeatSmartShape(finale.SMARTSHAPE_CUSTOM)
    createBeatBasedSL(finale.SMARTSHAPE_CUSTOM, true)
end

function smartshape_slur_solid()
    deleteEntrySmartShape(finale.SMARTSHAPE_DASHEDSLURAUTO)
    deleteEntrySmartShape(finale.SMARTSHAPE_SLURAUTO)
    setFirstLastNoteRangeEntry(finale.SMARTSHAPE_SLURAUTO)
end

function smartshape_slur_dashed()
    deleteEntrySmartShape(finale.SMARTSHAPE_SLURAUTO)
    deleteEntrySmartShape(finale.SMARTSHAPE_DASHEDSLURAUTO)
    setFirstLastNoteRangeEntry(finale.SMARTSHAPE_DASHEDSLURAUTO)
end

function smartshape_dashed_double_bracket()
    deleteBeatSmartShape(finale.SMARTSHAPE_SOLIDLINEDOWN2)
    deleteBeatSmartShape(finale.SMARTSHAPE_DASHLINEDOWN2)
    createBeatBasedSL(finale.SMARTSHAPE_DASHLINEDOWN2, true)
end

function smartshape_solid_double_bracket()
    deleteBeatSmartShape(finale.SMARTSHAPE_DASHLINEDOWN2)
    deleteBeatSmartShape(finale.SMARTSHAPE_SOLIDLINEDOWN2)
    createBeatBasedSL(finale.SMARTSHAPE_SOLIDLINEDOWN2, true)
end

function smartshape_8va()
    deleteBeatSmartShape(finale.SMARTSHAPE_TWOOCTAVEUP)
    deleteBeatSmartShape(finale.SMARTSHAPE_OCTAVEUP)
    createBeatBasedSL(finale.SMARTSHAPE_OCTAVEUP, true)
end

function smartshape_15ma()
    deleteBeatSmartShape(finale.SMARTSHAPE_OCTAVEUP)
    deleteBeatSmartShape(finale.SMARTSHAPE_TWOOCTAVEUP)
    createBeatBasedSL(finale.SMARTSHAPE_TWOOCTAVEUP, true)
end

function smartshape_8vb()
    deleteBeatSmartShape(finale.SMARTSHAPE_TWOOCTAVEDOWN)
    deleteBeatSmartShape(finale.SMARTSHAPE_OCTAVEDOWN)
    createBeatBasedSL(finale.SMARTSHAPE_OCTAVEDOWN, false)
end

function smartshape_15mb()
    deleteBeatSmartShape(finale.SMARTSHAPE_OCTAVEDOWN)
    deleteBeatSmartShape(finale.SMARTSHAPE_TWOOCTAVEDOWN)
    createBeatBasedSL(finale.SMARTSHAPE_TWOOCTAVEDOWN, false)
end

function staff_styles_slash()
    applyStaffStyle("Slash Notation")
end

function staff_styles_rhythm()
    applyStaffStyle("Rythmic Notation")
end

function staff_styles_blank_ly1()
    applyStaffStyle("Blank Notation: Layer 1")
end

function staff_styles_blank_rests_ly1()
    applyStaffStyle("Blank Notation with Rests: Layer 1")
end

function staff_styles_blank_ly4()
    applyStaffStyle("Blank Notation: Layer 4")
end

function staff_styles_blank_rests_ly4()
    applyStaffStyle("Blank Notation with Rests: Layer 4")
end

function staff_styles_blank_all()
    applyStaffStyle("Blank Notation: All Layers")
end

function staff_styles_repeat_one()
    applyStaffStyle("One Bar Repeat")
end

function staff_styles_repeat_two()
    applyStaffStyle("Two Bar Repeat")
end

function staff_styles_stemless()
    applyStaffStyle("Stemless Notes")
end

function staff_styles_cutaway()
    applyStaffStyle("Cutaway")
end

function staff_styles_collapse()
    applyStaffStyle("Collapse")
end

function dynamics_cresc()
    findTextExpression({"cresc."}, text_expression, "crescendo", 4)
    getFirstNoteInRegionText("Start")
end

function dynamics_dim()
    findTextExpression({"dim."}, text_expression, "diminuendo", 4)
    getFirstNoteInRegionText("Start")
end

function expressions_espr()
    findTextExpression({"espr."}, text_expression, "espressivo", 4)
    getFirstNoteInRegionText("Start")
end

function expressions_poco()
    findTextExpression({"poco"}, text_expression, "poco", 4)
    getFirstNoteInRegionText("Start")
end

function expressions_pocoapoco()
    findTextExpression({"poco a poco"}, text_expression, "poco a poco", 4)
    getFirstNoteInRegionText("Start")
end

function expressions_molto()
    findTextExpression({"molto"}, text_expression, "molto", 4)
    getFirstNoteInRegionText("Start")
end

function dynamics_piu_f()
    if check_SMuFL(nil) then
        findTextExpression({"più", 58658}, text_expression, "piu forte", 1)
    else
        findTextExpression({"più", 102}, text_expression, "piu forte", 1)
    end
    getFirstNoteInRegionText("Start")
end

function dynamics_pp_sub()
    if check_SMuFL(nil) then
        findTextExpression({58667, "sub."}, text_expression, "pianissimo subito", 1)
    else
        findTextExpression({185, "sub."}, text_expression, "pianissimo subito", 1)
    end
    getFirstNoteInRegionText("Start")
end

function dynamics_p_sub()
    if check_SMuFL(nil) then
        findTextExpression({58656, "sub."}, text_expression, "piano subito", 1)
    else
        findTextExpression({112, "sub."}, text_expression, "piano subito", 1)
    end
    getFirstNoteInRegionText("Start")
end

function dynamics_mp_sub()
    if check_SMuFL(nil) then
        findTextExpression({58668, "sub."}, text_expression, "mezzo piano subito", 1)
    else
        findTextExpression({80, "sub."}, text_expression, "mezzo piano subito", 1)
    end
    getFirstNoteInRegionText("Start")
end

function dynamics_mf_sub()
    if check_SMuFL(nil) then
        findTextExpression({58669, "sub."}, text_expression, "mezzo forte subito", 1)
    else
        findTextExpression({70, "sub."}, text_expression, "mezzo forte subito", 1)
    end
    getFirstNoteInRegionText("Start")
end

function dynamics_f_sub()
    if check_SMuFL(nil) then
        findTextExpression({58658, "sub."}, text_expression, "forte subito", 1)
    else
        findTextExpression({102, "sub."}, text_expression, "forte subito", 1)
    end
    getFirstNoteInRegionText("Start")
end

function dynamics_ff_sub()
    if check_SMuFL(nil) then
        findTextExpression({58671, "sub."}, text_expression, "fortissimo subito", 1)
    else
        findTextExpression({196, "sub."}, text_expression, "fortissimo subito", 1)
    end
    getFirstNoteInRegionText("Start")
end

function expressions_solo()
    findTextExpression({"solo"}, text_expression, "solo", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_unis()
    findTextExpression({"unis."}, text_expression, "unis", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_tutti()
    findTextExpression({"tutti"}, text_expression, "tutti", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_loco()
    findTextExpression({"loco"}, text_expression, "loco", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_breath()
    if check_SMuFL(nil) then
        findSpecialExpression({58574}, {nil, 0, 24, 0}, text_expression, "Breath Mark", 7)
    else
        findSpecialExpression({44}, {"Font0", 0, 24, 0}, text_expression, "Breath Mark", 5)
    end
    getFirstNoteInRegionText("End")
end

function expressions_caesura()
    if check_SMuFL(nil) then
        findSpecialExpression({58577}, {nil, 0, 24, 0}, text_expression, "Caesura", 7)
    else
        findSpecialExpression({34}, {"Font0", 0, 24, 0}, text_expression, "Caesura", 5)
    end
    getFirstNoteInRegionText("Region End")
end

function expressions_glasses()
    if check_SMuFL(nil) then
        findSpecialExpression({60514}, {nil, 0, 24, 0}, text_expression, "Eyeglasses (WATCH!)", 5)
    else
        findSpecialExpression({59}, {"Broadway Copyist", 8191, 24, 0}, text_expression, "Eyeglasses (WATCH!)", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mute()
    findTextExpression({"mute"}, text_expression, "mute", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_open()
    findTextExpression({"open"}, text_expression, "open", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_cup_mute()
    findTextExpression({"Cup Mute"}, text_expression, "Cup Mute", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_straight_mute()
    findTextExpression({"Straight Mute"}, text_expression, "Straight Mute", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_one()
    findTextExpression({"1°"}, text_expression, "1°", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_two()
    findTextExpression({"2°"}, text_expression, "2°", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_a2()
    findTextExpression({"a2"}, text_expression, "a2", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_a3()
    findTextExpression({"a3"}, text_expression, "a3", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_a4()
    findTextExpression({"a4"}, text_expression, "a4", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_arco()
    findTextExpression({"arco"}, text_expression, "arco", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_pizz()
    findTextExpression({"pizz."}, text_expression, "pizz.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_spicc()
    findTextExpression({"spicc."}, text_expression, "spicc.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_col_lengo()
    findTextExpression({"col legno"}, text_expression, "col legno", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_con_sord()
    findTextExpression({"con sord."}, text_expression, "con sord", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_ord()
    findTextExpression({"ord."}, text_expression, "ord.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_sul_pont()
    findTextExpression({"sul pont."}, text_expression, "sul pont.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_sul_tasto()
    findTextExpression({"sul tasto"}, text_expression, "sul tasto", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_senza_sord()
    findTextExpression({"senza sord."}, text_expression, "senza sord.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_trem()
    findTextExpression({"trem."}, text_expression, "trem.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_half_pizz()
    findTextExpression({"½ pizz. ½ arco"}, text_expression, "half pizz. half arco", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_half_trem()
    findTextExpression({"½ trem. ½ ord."}, text_expression, "half trem. half ord.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_BD_hard()
    if check_SMuFL(nil) then
        findSpecialExpression({59292}, {nil, 0, 24, 0}, text_expression, "Bass Drum, hard", 5)
    else
        findSpecialExpression({100}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Bass Drum, hard", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_BD_medium()
    if check_SMuFL(nil) then
        findSpecialExpression({59290}, {nil, 0, 24, 0}, text_expression, "Bass Drum, medium", 5)
    else
        findSpecialExpression({115}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Bass Drum, medium", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_BD_soft()
    if check_SMuFL(nil) then
        findSpecialExpression({59288}, {nil, 0, 24, 0}, text_expression, "Bass Drum, soft", 5)
    else
        findSpecialExpression({97}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Bass Drum, soft", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_brass()
    if check_SMuFL(nil) then
        findSpecialExpression({59353}, {nil, 0, 24, 0}, text_expression, "Brass Mallet", 5)
    else
        findSpecialExpression({106}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Brass Mallet", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_sticks()
    if check_SMuFL(nil) then
        findSpecialExpression({59345}, {nil, 0, 24, 0}, text_expression, "Sticks", 5)
    else
        findSpecialExpression({103}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Sticks", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_timp_hard()
    if check_SMuFL(nil) then
        findSpecialExpression({59280}, {nil, 0, 24, 0}, text_expression, "Timpani Mallet, hard", 5)
    else
        findSpecialExpression({101}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Timpani Mallet, hard", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_timp_medium()
    if check_SMuFL(nil) then
        findSpecialExpression({59276}, {nil, 0, 24, 0}, text_expression, "Timpani Mallet, medium", 5)
    else
        findSpecialExpression({119}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Timpani Mallet, medium", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_timp_soft()
    if check_SMuFL(nil) then
        findSpecialExpression({59272}, {nil, 0, 24, 0}, text_expression, "Timpani Mallet, soft", 5)
    else
        findSpecialExpression({113}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Timpani Mallet, soft", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_timp_wood()
    if check_SMuFL(nil) then
        findSpecialExpression({59284}, {nil, 0, 24, 0}, text_expression, "Timpani Mallet, wood", 5)
    else
        findSpecialExpression({114}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Timpani Mallet, wood", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_xylo_hard()
    if check_SMuFL(nil) then
        findSpecialExpression({59256}, {nil, 0, 24, 0}, text_expression, "Xylophone, hard", 5)
    else
        findSpecialExpression({117}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Xylophone, hard", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_xylo_medium()
    if check_SMuFL(nil) then
        findSpecialExpression({59252}, {nil, 0, 24, 0}, text_expression, "Xylophone, medium", 5)
    else
        findSpecialExpression({121}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Xylophone, medium", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_xylo_soft()
    if check_SMuFL(nil) then
        findSpecialExpression({59248}, {nil, 0, 24, 0}, text_expression, "Xylophone, soft", 5)
    else
        findSpecialExpression({116}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Xylophone, soft", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_yarn_med()
    if check_SMuFL(nil) then
        findSpecialExpression({59302}, {nil, 0, 24, 0}, text_expression, "Yarn Mallet, medium", 5)
    else
        findSpecialExpression({112}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Yarn Mallet, medium", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_mallet_yarn_soft()
    if check_SMuFL(nil) then
        findSpecialExpression({59298}, {nil, 0, 24, 0}, text_expression, "Yarn Mallet, soft", 5)
    else
        findSpecialExpression({111}, {"Finale Percussion", 8191, 24, 0}, text_expression, "Yarn Mallet, soft", 5)
    end
    getFirstNoteInRegionText("Region Start")
end

function expressions_div()
    findTextExpression({"div."}, text_expression, "div.", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_three()
    findTextExpression({"3°"}, text_expression, "3°", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_four()
    findTextExpression({"4°"}, text_expression, "4°", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_marc()
    findTextExpression({"marc."}, text_expression, "marcato", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_stacc()
    findTextExpression({"stacc."}, text_expression, "staccato", 5)
    getFirstNoteInRegionText("Region Start")
end

function expressions_straight_jazz()
    findSpecialExpression({"[S\\T\\R\\A\\I\\G\\\\HT]"}, {"Finale Copyist Text", 4096, 14, 0}, text_expression, "Straight mute", 5)
    getFirstNoteInRegionText("Region Start")
end

function tuplet_manual()
    tuplet_options({"Placement Manual"})
end

function tuplet_stem_beam_side()
    tuplet_options({"Placement Stem"})
end

function tuplet_note_side()
    tuplet_options({"Placement Note"})
end

function tuplet_above()
    tuplet_options({"Placement Above"})
end

function tuplet_below()
    tuplet_options({"Placement Below"})
end

function tuplet_flip()
    for noteentry in eachentry(finenv.Region()) do
        local t = finale.FCTuplet()
        t:SetNoteEntry(noteentry)
        if t:LoadFirst() then
            if t:GetPlacementMode() == 1 then
                t:SetPlacementMode(2)
            elseif t:GetPlacementMode() == 2 then
                t:SetPlacementMode(1)
            elseif t:GetPlacementMode() == 3 then
                t:SetPlacementMode(4)
            elseif t:GetPlacementMode() == 4 then
                t:SetPlacementMode(3)
            elseif t:GetPlacementMode() == 0 then
                finenv.UI():AlertInfo("There is a tuplet with the placement style of \"Manual\" in this region. This will be changed to Stem/Beam side.", nil)
                t:SetPlacementMode(1)
            end
            t:Save()
        end
    end
end

function tuplet_flat_on()
    tuplet_options({"Always Flat On"})
end

function tuplet_flat_off()
    tuplet_options({"Always Flat Off"})
end

function tuplet_avoid_staff_on()
    tuplet_options({"Avoid Staff On"})
end

function tuplet_avoid_staff_off()
    tuplet_options({"Avoid Staff Off"})
end

function tuplet_bracket_always()
    tuplet_options({"Bracket Always"})
end

function tuplet_unbeamed()
    tuplet_options({"Bracket Unbeamed"})
end

function tuplet_bracket_never_beamed()
    tuplet_options({"Bracket Never Beamed"})
end

function tuplet_increase_space()
    tuplet_options({"Increase Space"})
end

function tuplet_decrease_space()
    tuplet_options({"Decrease Space"})
end

function tuplet_increase_bracket()
    tuplet_options({"Increase Bracket"})
end

function tuplet_decrease_bracket()
    tuplet_options({"Decrease Bracket"})
end

function tuplet_shape_none()
    tuplet_options({"Shape None"})
end

function tuplet_shape_bracket()
    tuplet_options({"Shape Bracket"})
end

function tuplet_shape_slur()
    tuplet_options({"Shape Slur"})
end

function tuplet_number_none()
    tuplet_options({"Number None"})
end

function tuplet_number_regular()
    tuplet_options({"Number Regular"})
end

function tuplet_number_ratio()
    tuplet_options({"Number Ratio"})
end

function tuplet_number_ratio_last()
    tuplet_options({"Number Ratio Last"})
end

function tuplet_number_ratio_both()
    tuplet_options({"Number Ration Both"})
end

function tuplet_combo_hide_num_shape()
    tuplet_options({"Number None", "Shape None"})
end

function tuplet_combo_num_in_staff()
    tuplet_options({"Placement Stem", "Number Regular", "Bracket Never Beamed", "Avoid Staff Off", "Allow Horizontal Drag On"})
end

function tuplet_combo_bracket_stem_side()
    tuplet_options({"Shape Bracket", "Bracket Always", "Always Flat Off", "Placement Stem"})
end

function tuplet_combo_bracket_flat_below_outside()
    tuplet_options({"Shape Bracket", "Bracket Always", "Always Flat On", "Placement Below", "Avoid Staff On"})
end

function tuplet_combo_bracket_flat_maintain()
    tuplet_options({"Shape Bracket", "Bracket Always", "Always Flat On"})
end

function tuplet_combo_bracket_flat_above_outside()
    tuplet_options({"Shape Bracket", "Bracket Always", "Always Flat On", "Placement Above", "Avoid Staff On"})
end

function tuplet_combo_number_beam_outside()
    tuplet_options({"Shape None", "Number Regular", "Placement Stem", "Avoid Staff On"})
end

function tuplet_combo_number_note_outside()
    tuplet_options({"Shape None", "Number Regular", "Placement Note", "Avoid Staff On"})
end

function tuplet_combo_number_beam_inside()
    tuplet_options({"Shape None", "Number Regular", "Placement Stem", "Avoid Staff Off"})
end

function tuplet_combo_number_note_inside()
    tuplet_options({"Shape None", "Number Regular", "Placement Note", "Avoid Staff Off"})
end

function tuplet_horizontal_drag_on()
    tuplet_options({"Allow Horizontal Drag On"})
end

function tuplet_horizontal_drag_off()
    tuplet_options({"Allow Horizontal Drag Off"})
end

function groups_none_on()
    staff_groups(finale.GRBRAC_NONE, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_none_between()
    staff_groups(finale.GRBRAC_NONE, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_none_through()
    staff_groups(finale.GRBRAC_NONE, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_plain_on()
    staff_groups(finale.GRBRAC_PLAIN, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_plain_between()
    staff_groups(finale.GRBRAC_PLAIN, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_plain_through()
    staff_groups(finale.GRBRAC_PLAIN, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_chorus_straight_on()
    staff_groups(finale.GRBRAC_CHORUS, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_chorus_straight_between()
    staff_groups(finale.GRBRAC_CHORUS, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_chorus_straight_through()
    staff_groups(finale.GRBRAC_CHORUS, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_piano_on()
    staff_groups(finale.GRBRAC_PIANO, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_piano_between()
    staff_groups(finale.GRBRAC_PIANO, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_piano_through()
    staff_groups(finale.GRBRAC_PIANO, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_reverse_chorus_on()
    staff_groups(finale.GRBRAC_REVERSECHORUS, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_reverse_chorus_between()
    staff_groups(finale.GRBRAC_REVERSECHORUS, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_reverse_chorus_through()
    staff_groups(finale.GRBRAC_REVERSECHORUS, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_reverse_piano_on()
    staff_groups(finale.GRBRAC_REVERSEPIANO, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_reverse_piano_between()
    staff_groups(finale.GRBRAC_REVERSEPIANO, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_reverse_piano_through()
    staff_groups(finale.GRBRAC_REVERSEPIANO, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_chorus_curved_on()
    staff_groups(finale.GRBRAC_CURVEDCHORUS, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_chorus_curved_between()
    staff_groups(finale.GRBRAC_CURVEDCHORUS, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_chorus_curved_through()
    staff_groups(finale.GRBRAC_CURVEDCHORUS, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_reverse_chorus_curved_on()
    staff_groups(finale.GRBRAC_REVERSECURVEDCHORUS, finale.GROUPBARLINESTYLE_ONLYBETWEEN)
end

function groups_reverse_chorus_curved_between()
    staff_groups(finale.GRBRAC_REVERSECURVEDCHORUS, finale.GROUPBARLINESTYLE_ONLYON)
end

function groups_reverse_chorus_curved_through()
    staff_groups(finale.GRBRAC_REVERSECURVEDCHORUS, finale.GROUPBARLINESTYLE_THROUGH)
end

function groups_sub_bracket()
    staff_groups(finale.GRBRAC_DESK, nil)
end

function groups_reverse_sub_bracket()
    staff_groups(finale.GRBRAC_REVERSEDESK, nil)
end

function key_A_flat_major()
    change_key_signature("Major", -4)
end

function key_A_flat_minor()
    change_key_signature("Minor", -7)
end

function key_A_major()
    change_key_signature("Major", 3)
end

function key_A_minor()
    change_key_signature("Minor", 0)
end

function key_A_sharp_minor()
    change_key_signature("Minor", 7)
end

function key_B_flat_major()
    change_key_signature("Major", -2)
end

function key_B_flat_minor()
    change_key_signature("Minor", -5)
end

function key_B_major()
    change_key_signature("Major", 5)
end

function key_B_minor()
    change_key_signature("Minor", 2)
end

function key_C_flat_major()
    change_key_signature("Major", -7)
end

function key_C_major()
    change_key_signature("Major", 0)
end

function key_C_minor()
    change_key_signature("Minor", -3)
end

function key_C_sharp_major()
    change_key_signature("Major", 7)
end

function key_C_sharp_minor()
    change_key_signature("Minor", 4)
end

function key_D_flat_major()
    change_key_signature("Major", -5)
end

function key_D_major()
    change_key_signature("Major", 2)
end

function key_D_minor()
    change_key_signature("Minor", -1)
end

function key_D_sharp_minor()
    change_key_signature("Minor", 6)
end

function key_E_flat_major()
    change_key_signature("Major", -3)
end

function key_E_flat_minor()
    change_key_signature("Minor", -6)
end

function key_E_major()
    change_key_signature("Major", 4)
end

function key_E_minor()
    change_key_signature("Minor", 1)
end

function key_F_major()
    change_key_signature("Major", -1)
end

function key_F_minor()
    change_key_signature("Minor", -4)
end

function key_F_sharp_major()
    change_key_signature("Major", 6)
end

function key_F_sharp_minor()
    change_key_signature("Minor", 3)
end

function key_G_flat_major()
    change_key_signature("Major", -6)
end

function key_G_major()
    change_key_signature("Major", 1)
end

function key_G_minor()
    change_key_signature("Minor", -2)
end

function key_G_sharp_minor()
    change_key_signature("Minor", 5)
end

function key_hide_key_show_acc()
    change_key_signature("HideShow", nil)
end

function key_keyless()
    change_key_signature("Keyless", nil)
end

function formatting_page_break_insert()
    local music_region = finenv.Region()
    local m = finale.FCMeasure()
    if m:Load(music_region:GetStartMeasure()) then
        m.PageBreak = true
        m:Save()
    end
end

function formatting_page_break_remove()
    local music_region = finenv.Region()
    local m = finale.FCMeasure()
    if m:Load(music_region:GetStartMeasure()) then
        m.PageBreak = false
        m:Save()
    end
end

function move_system(direction)
    local region = finenv.Region()
    local systems = finale.FCStaffSystems()
    systems:LoadAll()

    local start_measure = region:GetStartMeasure()
    local end_measure = region:GetEndMeasure()
    local system = systems:FindMeasureNumber(start_measure)
    local lastSys = systems:FindMeasureNumber(end_measure)
    local system_number = system:GetItemNo()
    local lastSys_number = lastSys:GetItemNo()

    for i = system_number, lastSys_number, 1 do
        local system = systems:GetItemAt(i - 1)
        if direction == "down" then
            system.TopMargin = system.TopMargin + to_EVPUs("-1s")
        else
            system.TopMargin = system.TopMargin + to_EVPUs("1s")
        end
        system:Save()
    end
end

function formatting_system_move_down()
    move_system("down")
end

function formatting_system_move_up()
    move_system("up")
end

function playback_all_staves_document_beginning_to_document_end()
    playback_type("Document", "Document", "Document")
end

function playback_selected_staves_document_beginning_to_document_end()
    solo_staves()
    playback_type("Document", "Document")
end

function playback_all_staves_document_beginning_to_region_end()
    unmute_staves()
    playback_type("Document", "Region")
end

function playback_selected_staves_document_beginning_to_region_end()
    solo_staves()
    playback_type("Document", "Region")
end

function playback_all_staves_region_beginning_to_document_end()
    unmute_staves()
    playback_type("Region", "Document")
end

function playback_selected_staves_region_beginning_to_document_end()
    solo_staves()
    playback_type("Region", "Document")
end

function playback_all_staves_region_beginning_to_region_end()
    unmute_staves()
    playback_type("Region", "Region")
end

function playback_selected_staves_region_beginning_to_region_end()
    playback_type("Region", "Region", "Region")
end

function playback_mute_cue_notes()
    local notesize_limit = 85

    for entry in eachentrysaved(finenv.Region()) do
        local playback = false
        local notehead_mod = finale.FCNoteheadMod()

        if entry:CalcResize() > notesize_limit then
            for note in each(entry) do
                notehead_mod:LoadAt(note)
                if (notehead_mod.Resize > notesize_limit) then
                    playback = true
                end
            end
        end
        entry.Playback = playback
    end
end

function playback_mute_all_notes()
    entries_mute({1, 2, 3, 4})
end

function playback_unmute_all_notes()
    entries_mute({})
end

function navigation_switch_to_slected_part()
    ui_switch_to_selected_part()
end

function noteheads_harmonics()
    local notes_changed = false
    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count ~= 2) then
            goto continue
        end
        notes_changed = true
        local highest_note = entry:CalcHighestNote(nil)
        local lowest_note = entry:CalcLowestNote(nil)
        local midi_diff = highest_note:CalcMIDIKey() - lowest_note:CalcMIDIKey()
        if (midi_diff ~= 12 and midi_diff > 7) or (3 > midi_diff or midi_diff == 6) then
            goto continue
        end
        local notehead = finale.FCNoteheadMod()
        notehead:EraseAt(lowest_note)
        notehead:EraseAt(highest_note)
        if check_SMuFL(nil) then
            notehead.CustomChar = 57562
        else
            notehead.CustomChar = 79
            notehead.Resize = 110
        end
        if entry:GetDuration() == 4096 then
            if entry:CalcStemUp() == false then
                notehead.HorizontalPos = 5
            else
                notehead.HorizontalPos = -5
            end
        end
        notehead:SaveAt(highest_note)
        ::continue::
    end
    if (notes_changed == false) then
        finenv.UI():AlertError(
            "No valid diads to convert to harmonics. Only affects one of the following intervals: m3, M3, P4, P5, or Octave. Use the haromonics scripts in the \"polyphony\" section to create harmonics from a single note.",
            "JetStream - Notehead Harmonics")
    end
end

function meter_beam_together()
    local count = 1
    for noteentry in eachentrysaved(finenv.Region()) do
        local nextentry = noteentry:Next()
        if count == 1 then
            noteentry:SetBeamBeat(true)
        else
            noteentry:SetBeamBeat(false)
            if nextentry then
                nextentry:SetBeamBeat(true)
            end
        end
        count = count + 1
    end
end

function formatting_measure_width_increase()
    measureWidth("Increase")
end

function formatting_measure_width_decrease()
    measureWidth("Decrease")
end

function plugin_center_rehearsal_marks()
    move_markers("Clef Center")
end

function formatting_staff_space_increase()
    staff_spacing_adjust(24)
end

function formatting_staff_space_decrease()
    staff_spacing_adjust(-24)
end

function layers_swap_one_two()
    swap_layers(1, 2)
end

function layers_swap_one_three()
    swap_layers(1, 3)
end

function layers_swap_one_four()
    swap_layers(1, 4)
end

function layers_swap_two_three()
    swap_layers(2, 3)
end

function layers_swap_two_four()
    swap_layers(2, 4)
end

function layers_swap_three_four()
    swap_layers(3, 4)
end

function layers_swap_one_three_two_four()
    swap_layers(1, 3)
    swap_layers(2, 4)
end

function layers_swap_one_two_three_four()
    swap_layers(1, 2)
    swap_layers(3, 4)
end

function layers_one_clear()
    clear_Layer(1)
end

function layers_two_clear()
    clear_Layer(2)
end

function layers_three_clear()
    clear_Layer(3)
end

function layers_four_clear()
    clear_Layer(4)
end

function layers_one_two_clear()
    clear_Layer(1)
    clear_Layer(2)
end

function layers_one_three_clear()
    clear_Layer(1)
    clear_Layer(3)
end

function layers_one_four_clear()
    clear_Layer(1)
    clear_Layer(4)
end

function layers_one_two_three_clear()
    clear_Layer(1)
    clear_Layer(2)
    clear_Layer(3)
end

function layers_one_three_four_clear()
    clear_Layer(1)
    clear_Layer(3)
    clear_Layer(4)
end

function layers_two_three_clear()
    clear_Layer(2)
    clear_Layer(3)
end

function layers_two_four_clear()
    clear_Layer(2)
    clear_Layer(4)
end

function layers_two_three_four_clear()
    clear_Layer(2)
    clear_Layer(3)
    clear_Layer(4)
end

function layers_three_four_clear()
    clear_Layer(3)
    clear_Layer(4)
end

function plugin_custom_text_expressive()
    user_expression_input("Expressive")
end

function plugin_custom_text_technique()
    user_expression_input("Technique")
end

function plugin_custom_text_tempo()
    user_expression_input("Tempo")
end

function plugin_custom_text_dynamics()
    user_expression_input("Dynamic")
end

function plugin_make_x_times()
    make_x(false)
end

function plugin_make_x_more()
    make_x(true)
end

function reset_baseline_expression_below()
    baseline_reset(finale.BASELINEMODE_EXPRESSIONBELOW)
end

function reset_baseline_expression_above()
    baseline_reset(finale.BASELINEMODE_EXPRESSIONABOVE)
end

function reset_baseline_expression_all()
    baseline_reset(finale.BASELINEMODE_EXPRESSIONBELOW)
    baseline_reset(finale.BASELINEMODE_EXPRESSIONABOVE)
end

function reset_baseline_chord()
    baseline_reset(finale.BASELINEMODE_CHORD)
end

function reset_baseline_fretboard()
    baseline_reset(finale.BASELINEMODE_FRETBOARD)
end

function reset_baseline_chord_fretboard()
    baseline_reset(finale.BASELINEMODE_CHORD)
    baseline_reset(finale.BASELINEMODE_FRETBOARD)
end

function transform_breath_to_expression()
    if check_SMuFL(nil) then
        simple_art_to_exp_swap(nil, "Breath Mark", 58574)
    else
        simple_art_to_exp_swap(",", "Breath Mark", 44)
    end
end

function transform_caesura_to_expression()
    if check_SMuFL(nil) then
        simple_art_to_exp_swap(nil, "Caesura", 58577)
    else
        simple_art_to_exp_swap("\"", "Caesura", 34)
    end
end

function articulations_delete_articulations_from_rests()
    for e in eachentrysaved(finenv.Region()) do
        if e:IsRest() then
            if e:GetArticulationFlag() then
                e:SetArticulationFlag(false)
            end
        end
    end
end

function transform_single_pitch_F4()
    single_pitch("F4")
end

function transform_single_pitch_F5()
    single_pitch("F5")
end

function transform_single_pitch_C5()
    single_pitch("C5")
end

function transform_single_pitch_G5()
    single_pitch("G5")
end

function transform_single_pitch_A5()
    single_pitch("A5")
end

function transform_semitone_up()
    transpose_semitones(1)
end

function transform_semitone_down()
    transpose_semitones(-1)
end

function transform_flip_enharmonic()
    flip_enharmonic()
end

function transform_cluster_indeterminate()
    cluster_indeterminate()
end

function transform_cluster_determinate()
    cluster_determinate()
end

function transform_toggle_ledger_lines()
    local region = finenv.Region()
    for entry in eachentrysaved(region) do
        if entry:GetLedgerLines() then
            entry:SetLedgerLines(false)
        else
            entry:SetLedgerLines(true)
        end
    end
end

function transform_highest_lowest_possible()
    create_centered_triangles()
end

function transform_create_kicks()
    create_kicklink_layer_4()
end

function transform_topline_notation()
    top_line()
end

function update_mac_48()
    check_for_update("/tmp/", "mac XL")
end

function update_mac_35()
    check_for_update("/tmp/", "mac standard")
end

function update_win_48()
    check_for_update("\\Windows\\Temp\\", "win XL")
end

function update_win_35()
    check_for_update("\\Windows\\Temp\\", "win standard")
end

function update_win_ahk()
    check_for_update("\\Windows\\Temp\\", "win ahk")
end

function update_mac_km()
    check_for_update("/tmp/", "mac km")
end

--[[
dialog:SetTypes("String")
dialog:SetDescriptions("Enter a JetStream Finale Controller code:")

local return_values = dialog:Execute()
]]

local return_value = simple_input("JetStream Finale Controller", "Enter a JetStream Finale Controller code:")
local execute_function = split(return_value, " ")

for i, k in pairs(execute_function) do
    finale.FCCellMetrics.MarkMetricsForRebuild()
    if execute_function ~= nil then
        local mr = finale.FCMusicRegion()
        mr:SetCurrentSelection()
        function compare(compare_to)
            local result = compare_values(k, compare_to)
            return result
        end

        if mr:IsEmpty() ~= true then
            if compare({"0001", "ffff"}) then
                dynamics_ffff_start()
            end
            if compare({"0002", "fff"}) then
                dynamics_fff_start()
            end
            if compare({"0003", "ff", "fortissimo"}) then
                dynamics_ff_start()
            end
            if compare({"0004", "f", "forte"}) then
                dynamics_f_start()
            end
            if compare({"0005", "mf", "mezzoforte"}) then
                dynamics_mf_start()
            end
            if compare({"0006", "mp", "mezzopiano"}) then
                dynamics_mp_start()
            end
            if compare({"0007", "p", "piano"}) then
                dynamics_p_start()
            end
            if compare({"0008", "pp", "pianissimo"}) then
                dynamics_pp_start()
            end
            if compare({"0009", "ppp"}) then
                dynamics_ppp_start()
            end
            if compare({"0010", "pppp"}) then
                dynamics_pppp_start()
            end
            if compare({"0011", "fp"}) then
                dynamics_fp_start()
            end
            if compare({"0012", "fz"}) then
                dynamics_fz_start()
            end
            if compare({"0013", "n", "niente"}) then
                dynamics_n_start()
            end
            if compare({"0014", "rf"}) then
                dynamics_rf_start()
            end
            if compare({"0015", "rfz"}) then
                dynamics_rfz_start()
            end
            if compare({"0016", "sf"}) then
                dynamics_sf_start()
            end
            if compare({"0017", "sffz"}) then
                dynamics_sffz_start()
            end
            if compare({"0018", "sfp"}) then
                dynamics_sfp_start()
            end
            if compare({"0019", "sfpp"}) then
                dynamics_sfpp_start()
            end
            if compare({"0020", "sfz"}) then
                dynamics_sfz_start()
            end
            if compare({"0021", "sfzp"}) then
                dynamics_sfzp_start()
            end
            if compare({"0022", "<"}) then
                dynamics_crescendo()
            end
            if compare({"0023", ">"}) then
                dynamics_decrescendo()
            end
            if compare({"0024", "<>"}) then
                dynamics_messa_di_voce_up()
            end
            if compare({"0025", "><"}) then
                dynamics_messa_di_voce_down()
            end
            if execute_function[i] == "0026" then
                dynamics_delete_hairpins()
            end
            if execute_function[i] == "0027" then
                dynamics_delete_dynamics()
            end
            if compare({"0028", "-ffff"}) then
                dynamics_ffff_end()
            end
            if compare({"0029", "-fff"}) then
                dynamics_fff_end()
            end
            if compare({"0030", "-ff"}) then
                dynamics_ff_end()
            end
            if compare({"0031", "-f"}) then
                dynamics_f_end()
            end
            if compare({"0032", "-mf"}) then
                dynamics_mf_end()
            end
            if compare({"0033", "-mp"}) then
                dynamics_mp_end()
            end
            if compare({"0034", "-p"}) then
                dynamics_p_end()
            end
            if compare({"0035", "-pp"}) then
                dynamics_pp_end()
            end
            if compare({"0036", "-ppp"}) then
                dynamics_ppp_end()
            end
            if compare({"0037", "-pppp"}) then
                dynamics_pppp_end()
            end
            if compare({"0038", "-fp"}) then
                dynamics_fp_end()
            end
            if compare({"0039", "-fz"}) then
                dynamics_fz_end()
            end
            if compare({"0040", "-n"}) then
                dynamics_n_end()
            end
            if compare({"0041", "-rf"}) then
                dynamics_rf_end()
            end
            if compare({"0042", "-rfz"}) then
                dynamics_rfz_end()
            end
            if compare({"0043", "-sf"}) then
                dynamics_sf_end()
            end
            if compare({"0044", "-sffz"}) then
                dynamics_sffz_end()
            end
            if compare({"0045", "-sfp"}) then
                dynamics_sfp_end()
            end
            if compare({"0046", "-sfpp"}) then
                dynamics_sfpp_end()
            end
            if compare({"0047", "-sfz"}) then
                dynamics_sfz_end()
            end
            if compare({"0048", "-sfzp"}) then
                dynamics_sfzp_end()
            end
            if compare({"0049", "dyn+", "louder"}) then
                dynamics_increase_dynamic()
            end
            if compare({"0050", "dyn-", "softer", "quieter"}) then
                dynamics_decrease_dynamic()
            end
            if compare({"0051", "alignfar", "align", "da"}) then
                dynamics_align_far()
            end
            --      if compare({"0052","alignnear"}) then
            --        dynamics_align_near()
            --      end
            if compare({"0053", "dyndn", "dd"}) then
                dynamics_align_far()
                dynamics_nudge_down()
            end
            if compare({"0054", "dynup", "du"}) then
                dynamics_align_far()
                dynamics_nudge_up()
            end
            if compare({"0055", "cresc", "crescendo"}) then
                dynamics_cresc()
            end
            if compare({"0056", "dim", "diminuendo"}) then
                dynamics_dim()
            end
            if compare({"0057", "piuf", "piu_f"}) then
                dynamics_piu_f()
            end
            if compare({"0058", "ppsub", "subpp", "pp_sub", "sub_pp"}) then
                dynamics_pp_sub()
            end
            if compare({"0059", "psub", "subp", "p_sub", "sub_p"}) then
                dynamics_p_sub()
            end
            if compare({"0060", "submp", "mpsub", "sub_mp", "mp_sub"}) then
                dynamics_mp_sub()
            end
            if compare({"0061", "mfsub", "mf_sub", "submf", "sub_mf"}) then
                dynamics_mf_sub()
            end
            if compare({"0062", "subf", "sub_f", "fsub", "f_sub"}) then
                dynamics_f_sub()
            end
            if compare({"0063", "ffsub", "ff_sub", "subff", "sub_ff"}) then
                dynamics_ff_sub()
            end
            if execute_function[i] == "0070" then
                dynamics_align_hairpins_and_dynamics()
            end
            if execute_function[i] == "0071" then
                dynamics_align_hairpins_and_dynamics()
                dynamics_nudge_down()
            end
            if execute_function[i] == "0072" then
                dynamics_align_hairpins_and_dynamics()
                dynamics_nudge_up()
            end
            if compare({"0100", "accent", "acc"}) then
                articulations_accent()
            end
            if compare({"0101", "marc"}) then
                articulations_marcato()
            end
            if compare({"0102", "stacc", "staccato", "stac"}) then
                articulations_staccato()
            end
            if compare({"0103", "ten", "tenuto", "-"}) then
                articulations_tenuto()
            end
            if execute_function[i] == "0104" then
                articulations_flat_wedge()
            end
            if execute_function[i] == "0105" then
                articulations_round_wedge()
            end
            if compare({"0106", "/"}) then
                articulations_tremolo_single()
            end
            if compare({"0107", "//"}) then
                articulations_tremolo_double()
            end
            if compare({"0108", "///"}) then
                articulations_tremolo_triple()
            end
            if compare({"0109", "fermata", "ferm"}) then
                articulations_fermata()
            end
            if compare({"0110", "closed", "+"}) then
                articulations_closed()
            end
            if compare({"0111", "open", "o"}) then
                articulations_open()
            end
            if compare({"0112", "upbow"}) then
                articulations_upbow()
            end
            if compare({"0113", "downbow"}) then
                articulations_downbow()
            end
            if execute_function[i] == "0114" then
                articulations_trill()
            end
            if execute_function[i] == "0115" then
                articulations_short_trill()
            end
            if execute_function[i] == "0116" then
                articulations_mordent()
            end
            if execute_function[i] == "0117" then
                articulations_turn()
            end
            if compare({"0118", "roll"}) then
                articulations_roll()
            end
            if execute_function[i] == "0119" then
                articulations_fall_short()
            end
            if execute_function[i] == "0120" then
                articulations_fall_long()
            end
            if execute_function[i] == "0121" then
                articulations_rip_straight()
            end
            if execute_function[i] == "0122" then
                articulations_rip_long()
            end
            if execute_function[i] == "0123" then
                articulations_scoop_short()
            end
            if execute_function[i] == "0124" then
                articulations_doit()
            end
            if compare({"0125", "split_art", "split"}) then
                articulations_split_articulations()
            end
            if execute_function[i] == "0126" then
                articulations_delete_articulations()
            end
            if execute_function[i] == "0127" then
                articulations_lv()
            end
            if compare({"0128", "lv", "let_vibrate"}) then
                articulations_lv_poly()
            end
            if compare({"0132", "["}) then
                articulations_left_brackets()
            end
            if compare({"0137", "]"}) then
                articulations_right_brackets()
            end
            if compare({"0138", "-.", ".-"}) then
                articulations_combo_tenuto_staccato()
            end
            if compare({"0139", ">.", ".>"}) then
                articulations_combo_accent_staccato()
            end
            if compare({"0140", ">-", "->"}) then
                articulations_combo_accent_tenuto()
            end
            if execute_function[i] == "0141" then
                articulations_combo_marcato_staccato()
            end
            if compare({"0142", "z"}) then
                articulations_tremolo_z()
            end
            if execute_function[i] == "0143" then
                articulations_delete_duplicate_articulations()
            end
            if execute_function[i] == "0144" then
                articulations_delete_articulations_from_rests()
            end
            if compare({"0145", "trem"}) then
                articulations_metered_tremolo()
            end
            if compare({"0200", "xo", "nh_xo", "nh_xcircle"}) then
                noteheads_x_circle()
            end
            if compare({"0201", "cross", "nh_cross"}) then
                noteheads_cross_circle()
            end
            if compare({"0202", "tri", "tri_up", "triup", "nh_tri"}) then
                noteheads_triangle_up()
            end
            if compare({"0203", "tri_dn", "tridn", "tri_down", "nh_tri_down"}) then
                noteheads_triangle_down()
            end
            if compare({"0204", "nh_dia", "nh_diamond", "diamond", "dia"}) then
                noteheads_diamond()
            end
            if compare({"x", "nh_x"}) then
                noteheads_x_default()
            end
            if compare({"0205", "ghost", "nh_ghost", "nh_gho", "nh_paren"}) then
                noteheads_ghost()
            end
            if compare({"0206", "xstick", "crossstick", "nh_xstick", "nh_circled"}) then
                noteheads_cross_stick()
            end
            if execute_function[i] == "0207" then
                noteheads_small_slash()
            end
            if execute_function[i] == "0208" then
                noteheads_square()
            end
            if compare({"0209", "rim", "rimshot", "nh_rim"}) then
                noteheads_rim()
            end
            if compare({"0210", "nonote", "nh_none", "nh_no"}) then
                noteheads_no_notehead()
            end
            if compare({"0211", "defualt", "def", "nh_def", "nh_default"}) then
                noteheads_default()
            end
            if compare({"0212", "nh_xd", "xd"}) then
                noteheads_x_diamond()
            end
            if compare({"0213", "touchharmonics", "touchharmx", "touch", "harm", "hrmx", "harmx"}) then
                noteheads_harmonics()
            end
            if compare({"0214", "pas", "drum"}) then
                noteheads_x_above_staff()
            end
            if compare({"0215", "nh_center"}) then
                noteheads_center_noteheads()
            end
            if execute_function[i] == "0300" then
                lyrics_clear_lyrics()
            end
            if execute_function[i] == "0302" then
                lyrics_move_baseline_down()
            end
            if execute_function[i] == "0303" then
                lyrics_move_baseline_up()
            end
            if execute_function[i] == "0400" then
                barline_right_invisible()
            end
            if compare({"0401", "|"}) then
                barline_right_single()
            end
            if compare({"0402", "||"}) then
                barline_right_double()
            end
            if execute_function[i] == "0403" then
                barline_right_dashed()
            end
            if execute_function[i] == "0404" then
                barline_right_thick()
            end
            if compare({"0405", "final", "fin"}) then
                barline_right_final()
            end
            if execute_function[i] == "0406" then
                barline_right_tick()
            end
            if execute_function[i] == "0407" then
                barline_right_custom()
            end
            if execute_function[i] == "0408" then
                barline_bookend_invisible()
            end
            if execute_function[i] == "0409" then
                barline_bookend_single()
            end
            if execute_function[i] == "0410" then
                barline_bookend_double()
            end
            if execute_function[i] == "0411" then
                barline_bookend_dashed()
            end
            if execute_function[i] == "0412" then
                barline_bookend_thick()
            end
            if execute_function[i] == "0413" then
                barline_bookend_final()
            end
            if execute_function[i] == "0414" then
                barline_bookend_tick()
            end
            if execute_function[i] == "0415" then
                barline_bookend_custom()
            end
            if execute_function[i] == "0416" then
                barline_add_at_double_rehearsal_letter()
            end
            if execute_function[i] == "0417" then
                barline_add_at_double_rehearsal_number()
            end
            if execute_function[i] == "0418" then
                barline_add_at_double_rehearsal_measure()
            end
            if execute_function[i] == "0419" then
                barline_clear_rehearsal()
            end
            if compare({"0500", "2/4"}) then
                meter_2_4()
            end
            if compare({"0501", "2/2"}) then
                meter_2_2()
            end
            if compare({"0502", "3/2"}) then
                meter_3_2()
            end
            if compare({"0503", "3/4"}) then
                meter_3_4()
            end
            if compare({"0504", "3/8"}) then
                meter_3_8()
            end
            if compare({"0505", "4/4"}) then
                meter_4_4()
            end
            if compare({"0506", "5/4"}) then
                meter_5_4()
            end
            if compare({"0507", "5/8", "5/8_23"}) then
                meter_5_8_23()
            end
            if compare({"0516", "5/8_32"}) then
                meter_5_8_32()
            end
            if compare({"0508", "6/8"}) then
                meter_6_8()
            end
            if compare({"0509", "7/8", "7/8_223"}) then
                meter_7_8_223()
            end
            if compare({"0517", "7/8_322"}) then
                meter_7_8_322()
            end
            if compare({"0510", "9/8"}) then
                meter_9_8()
            end
            if compare({"0511", "12/8"}) then
                meter_12_8()
            end
            if compare({"0512", "6/4"}) then
                meter_6_4()
            end
            if compare({"0513", "beam_together", "beam"}) then
                meter_beam_together()
            end
            if compare({"0514", "common", "c"}) then
                meter_common_time()
            end
            if compare({"0515", "cut"}) then
                meter_cut_time()
            end
            if compare({"0600", "trill", "tr"}) then
                smartshape_trill()
            end
            if execute_function[i] == "0601" then
                smartshape_trill_extension()
            end
            if execute_function[i] == "0602" then
                smartshape_dashed_line()
            end
            if execute_function[i] == "0603" then
                smartshape_solid_line()
            end
            if execute_function[i] == "0604" then
                smartshape_tab_slide()
            end
            if execute_function[i] == "0605" then
                smartshape_glissando()
            end
            if execute_function[i] == "0606" then
                smartshape_dashed_bracket()
            end
            if execute_function[i] == "0607" then
                smartshape_solid_bracket()
            end
            if execute_function[i] == "0608" then
                smartshape_custom()
            end
            if execute_function[i] == "0609" then
                smartshape_slur_solid()
            end
            if execute_function[i] == "0610" then
                smartshape_slur_dashed()
            end
            if execute_function[i] == "0611" then
                smartshape_dashed_double_bracket()
            end
            if execute_function[i] == "0612" then
                smartshape_solid_double_bracket()
            end
            if execute_function[i] == "0613" then
                smartshape_8va()
            end
            if execute_function[i] == "0614" then
                smartshape_15ma()
            end
            if execute_function[i] == "0615" then
                smartshape_8vb()
            end
            if execute_function[i] == "0616" then
                smartshape_15mb()
            end
            if compare({"0700", "slash", "////", "/s"}) then
                staff_styles_slash()
            end
            if compare({"0701", "rhythm", "rthm"}) then
                staff_styles_rhythm()
            end
            if compare({"0702", "blank"}) then
                staff_styles_blank_ly1()
            end
            if execute_function[i] == "0703" then
                staff_styles_blank_rests_ly1()
            end
            if execute_function[i] == "0704" then
                staff_styles_blank_ly4()
            end
            if execute_function[i] == "0705" then
                staff_styles_blank_rests_ly4()
            end
            if execute_function[i] == "0706" then
                staff_styles_blank_all()
            end
            if compare({"0707", "%", "1barrpt"}) then
                staff_styles_repeat_one()
            end
            if compare({"0708", "%%", "2barrpt"}) then
                staff_styles_repeat_two()
            end
            if compare({"0709", "stemless"}) then
                staff_styles_stemless()
            end
            if compare({"0710", "cutaway"}) then
                staff_styles_cutaway()
            end
            if compare({"0711", "collapse"}) then
                staff_styles_collapse()
            end
            if compare({"0800", "espr", "esp", "espressivo"}) then
                expressions_espr()
            end
            if compare({"0801", "poco"}) then
                expressions_poco()
            end
            if compare({"0802", "pocoapoco", "poco_a_poco"}) then
                expressions_pocoapoco()
            end
            if compare({"0803", "molto"}) then
                expressions_molto()
            end
            if execute_function[i] == "0804" then
                expressions_solo()
            end
            if execute_function[i] == "0805" then
                expressions_unis()
            end
            if execute_function[i] == "0806" then
                expressions_tutti()
            end
            if execute_function[i] == "0807" then
                expressions_loco()
            end
            if execute_function[i] == "0808" then
                expressions_breath()
            end
            if execute_function[i] == "0809" then
                expressions_caesura()
            end
            if execute_function[i] == "0810" then
                expressions_glasses()
            end
            if execute_function[i] == "0811" then
                expressions_mute()
            end
            if execute_function[i] == "0812" then
                expressions_open()
            end
            if execute_function[i] == "0813" then
                expressions_cup_mute()
            end
            if execute_function[i] == "0814" then
                expressions_straight_mute()
            end
            if execute_function[i] == "0815" then
                expressions_one()
            end
            if execute_function[i] == "0816" then
                expressions_two()
            end
            if execute_function[i] == "0817" then
                expressions_a2()
            end
            if execute_function[i] == "0818" then
                expressions_a3()
            end
            if execute_function[i] == "0819" then
                expressions_a4()
            end
            if compare({"0820", "arco"}) then
                expressions_arco()
            end
            if compare({"0821", "pizz"}) then
                expressions_pizz()
            end
            if execute_function[i] == "0822" then
                expressions_spicc()
            end
            if execute_function[i] == "0823" then
                expressions_col_legno()
            end
            if execute_function[i] == "0824" then
                expressions_con_sord()
            end
            if execute_function[i] == "0825" then
                expressions_ord()
            end
            if execute_function[i] == "0826" then
                expressions_sul_pont()
            end
            if execute_function[i] == "0827" then
                expressions_sul_tasto()
            end
            if execute_function[i] == "0828" then
                expressions_senza_sord()
            end
            if execute_function[i] == "0829" then
                expressions_trem()
            end
            if execute_function[i] == "0830" then
                expressions_half_pizz()
            end
            if execute_function[i] == "0831" then
                expressions_half_trem()
            end
            if execute_function[i] == "0832" then
                expressions_mallet_BD_hard()
            end
            if execute_function[i] == "0833" then
                expressions_mallet_BD_medium()
            end
            if execute_function[i] == "0834" then
                expressions_mallet_BD_soft()
            end
            if execute_function[i] == "0835" then
                expressions_mallet_brass()
            end
            if execute_function[i] == "0836" then
                expressions_mallet_sticks()
            end
            if execute_function[i] == "0837" then
                expressions_mallet_timp_hard()
            end
            if execute_function[i] == "0838" then
                expressions_mallet_timp_medium()
            end
            if execute_function[i] == "0839" then
                expressions_mallet_timp_soft()
            end
            if execute_function[i] == "0840" then
                expressions_mallet_timp_wood()
            end
            if execute_function[i] == "0841" then
                expressions_mallet_xylo_hard()
            end
            if execute_function[i] == "0842" then
                expressions_mallet_xylo_medium()
            end
            if execute_function[i] == "0843" then
                expressions_mallet_xylo_soft()
            end
            if execute_function[i] == "0844" then
                expressions_mallet_yarn_med()
            end
            if execute_function[i] == "0845" then
                expressions_mallet_yarn_soft()
            end
            if execute_function[i] == "0846" then
                expressions_div()
            end
            if execute_function[i] == "0847" then
                expressions_three()
            end
            if execute_function[i] == "0848" then
                expressions_four()
            end
            if execute_function[i] == "0849" then
                expressions_marc()
            end
            if execute_function[i] == "0850" then
                expressions_stacc()
            end
            if execute_function[i] == "0851" then
                expressions_straight_jazz()
            end
            if execute_function[i] == "0852" then
                expressions_move_baseline_down()
            end
            if execute_function[i] == "0853" then
                expressions_move_baseline_up()
            end
            if execute_function[i] == "0900" then
                tuplet_manual()
            end
            if execute_function[i] == "0901" then
                tuplet_stem_beam_side()
            end
            if execute_function[i] == "0902" then
                tuplet_note_side()
            end
            if execute_function[i] == "0903" then
                tuplet_above()
            end
            if execute_function[i] == "0904" then
                tuplet_below()
            end
            if execute_function[i] == "0905" then
                tuplet_flip()
            end
            if execute_function[i] == "0906" then
                tuplet_flat_on()
            end
            if execute_function[i] == "0907" then
                tuplet_flat_off()
            end
            if execute_function[i] == "0908" then
                tuplet_avoid_staff_on()
            end
            if execute_function[i] == "0909" then
                tuplet_avoid_staff_off()
            end
            if execute_function[i] == "0910" then
                tuplet_bracket_always()
            end
            if execute_function[i] == "0911" then
                tuplet_unbeamed()
            end
            if execute_function[i] == "0912" then
                tuplet_bracket_never_beamed()
            end
            if execute_function[i] == "0913" then
                tuplet_increase_space()
            end
            if execute_function[i] == "0914" then
                tuplet_decrease_space()
            end
            if execute_function[i] == "0915" then
                tuplet_increase_bracket()
            end
            if execute_function[i] == "0916" then
                tuplet_decrease_bracket()
            end
            if execute_function[i] == "0917" then
                tuplet_shape_none()
            end
            if execute_function[i] == "0918" then
                tuplet_shape_bracket()
            end
            if execute_function[i] == "0919" then
                tuplet_shape_slur()
            end
            if execute_function[i] == "0920" then
                tuplet_number_none()
            end
            if execute_function[i] == "0921" then
                tuplet_number_regular()
            end
            if execute_function[i] == "0922" then
                tuplet_number_ratio()
            end
            if execute_function[i] == "0923" then
                tuplet_number_ratio_last()
            end
            if execute_function[i] == "0924" then
                tuplet_number_ratio_both()
            end
            if execute_function[i] == "0925" then
                tuplet_combo_hide_num_shape()
            end
            if execute_function[i] == "0926" then
                tuplet_combo_num_in_staff()
            end
            if execute_function[i] == "0927" then
                tuplet_combo_bracket_stem_side()
            end
            if execute_function[i] == "0928" then
                tuplet_combo_bracket_flat_below_outside()
            end
            if execute_function[i] == "0929" then
                tuplet_combo_bracket_flat_maintain()
            end
            if execute_function[i] == "0930" then
                tuplet_combo_bracket_flat_above_outside()
            end
            if execute_function[i] == "0931" then
                tuplet_combo_number_beam_outside()
            end
            if execute_function[i] == "0932" then
                tuplet_combo_number_note_outside()
            end
            if execute_function[i] == "0933" then
                tuplet_combo_number_beam_inside()
            end
            if execute_function[i] == "0934" then
                tuplet_combo_number_note_inside()
            end
            if execute_function[i] == "0935" then
                tuplet_horizontal_drag_on()
            end
            if execute_function[i] == "0936" then
                tuplet_horizontal_drag_off()
            end
            if execute_function[i] == "1000" then
                groups_none_on()
            end
            if execute_function[i] == "1001" then
                groups_none_between()
            end
            if execute_function[i] == "1002" then
                groups_none_through()
            end
            if execute_function[i] == "1003" then
                groups_plain_on()
            end
            if execute_function[i] == "1004" then
                groups_plain_between()
            end
            if execute_function[i] == "1005" then
                groups_plain_through()
            end
            if execute_function[i] == "1006" then
                groups_chorus_straight_on()
            end
            if execute_function[i] == "1007" then
                groups_chorus_straight_between()
            end
            if execute_function[i] == "1008" then
                groups_chorus_straight_through()
            end
            if execute_function[i] == "1009" then
                groups_piano_on()
            end
            if execute_function[i] == "1010" then
                groups_piano_between()
            end
            if execute_function[i] == "1011" then
                groups_piano_through()
            end
            if execute_function[i] == "1012" then
                groups_reverse_chorus_on()
            end
            if execute_function[i] == "1013" then
                groups_reverse_chorus_between()
            end
            if execute_function[i] == "1014" then
                groups_reverse_chorus_through()
            end
            if execute_function[i] == "1015" then
                groups_reverse_piano_on()
            end
            if execute_function[i] == "1016" then
                groups_reverse_piano_between()
            end
            if execute_function[i] == "1017" then
                groups_reverse_piano_through()
            end
            if execute_function[i] == "1018" then
                groups_chorus_curved_on()
            end
            if execute_function[i] == "1019" then
                groups_chorus_curved_between()
            end
            if execute_function[i] == "1020" then
                groups_chorus_curved_through()
            end
            if execute_function[i] == "1021" then
                groups_reverse_chorus_curved_on()
            end
            if execute_function[i] == "1022" then
                groups_reverse_chorus_curved_between()
            end
            if execute_function[i] == "1023" then
                groups_reverse_chorus_curved_through()
            end
            if execute_function[i] == "1024" then
                groups_sub_bracket()
            end
            if execute_function[i] == "1025" then
                groups_reverse_sub_bracket()
            end
            if compare({"1100", "abmaj"}) then
                key_A_flat_major()
            end
            if compare({"1101", "abmin"}) then
                key_A_flat_minor()
            end
            if compare({"1103", "amaj"}) then
                key_A_major()
            end
            if compare({"1104", "amin"}) then
                key_A_minor()
            end
            if compare({"1104", "a#min"}) then
                key_A_sharp_minor()
            end
            if compare({"1105", "bbmaj"}) then
                key_B_flat_major()
            end
            if compare({"1106", "bbmin"}) then
                key_B_flat_minor()
            end
            if compare({"1107", "bmaj"}) then
                key_B_major()
            end
            if compare({"1108", "bmin"}) then
                key_B_minor()
            end
            if compare({"1109", "cbmaj"}) then
                key_C_flat_major()
            end
            if compare({"1110", "cmaj"}) then
                key_C_major()
            end
            if compare({"1111", "cmin"}) then
                key_C_minor()
            end
            if compare({"1112", "c#maj"}) then
                key_C_sharp_major()
            end
            if compare({"1113", "c#min"}) then
                key_C_sharp_minor()
            end
            if compare({"1114", "dbmaj"}) then
                key_D_flat_major()
            end
            if compare({"1115", "dmaj"}) then
                key_D_major()
            end
            if compare({"1116", "dmin"}) then
                key_D_minor()
            end
            if compare({"1117", "d#min"}) then
                key_D_sharp_minor()
            end
            if compare({"1118", "ebmaj"}) then
                key_E_flat_major()
            end
            if compare({"1119", "ebmin"}) then
                key_E_flat_minor()
            end
            if compare({"1120", "emaj"}) then
                key_E_major()
            end
            if compare({"1121", "emin"}) then
                key_E_minor()
            end
            if compare({"1122", "fmaj"}) then
                key_F_major()
            end
            if compare({"1123", "fmin"}) then
                key_F_minor()
            end
            if compare({"1124", "f#maj"}) then
                key_F_sharp_major()
            end
            if compare({"1125", "f#min"}) then
                key_F_sharp_minor()
            end
            if compare({"1126", "gbmaj"}) then
                key_G_flat_major()
            end
            if compare({"1127", "gmaj"}) then
                key_G_major()
            end
            if compare({"1128", "gmin"}) then
                key_G_minor()
            end
            if compare({"1129", "g#min"}) then
                key_G_sharp_minor()
            end
            if execute_function[i] == "1130" then
                key_hide_key_show_acc()
            end
            if compare({"1131", "atonal", "keyless"}) then
                key_keyless()
            end
            if execute_function[i] == "1200" then
                formatting_page_break_insert()
            end
            if execute_function[i] == "1201" then
                formatting_page_break_remove()
            end
            if execute_function[i] == "1202" then
                formatting_measure_width_increase()
            end
            if execute_function[i] == "1203" then
                formatting_measure_width_decrease()
            end
            if execute_function[i] == "1204" then
                formatting_staff_space_increase()
            end
            if execute_function[i] == "1205" then
                formatting_staff_space_decrease()
            end
            if execute_function[i] == "1206" then
                formatting_system_move_down()
            end
            if execute_function[i] == "1207" then
                formatting_system_move_up()
            end
            if execute_function[i] == "1300" then
                layers_one_reduce()
            end
            if execute_function[i] == "1301" then
                layers_two_reduce()
            end
            if execute_function[i] == "1302" then
                layers_three_reduce()
            end
            if execute_function[i] == "1303" then
                layers_four_reduce()
            end
            if execute_function[i] == "1304" then
                layers_one_melody_top()
            end
            if execute_function[i] == "1305" then
                layers_two_melody_top()
            end
            if execute_function[i] == "1306" then
                layers_three_melody_top()
            end
            if execute_function[i] == "1307" then
                layers_four_melody_top()
            end
            if execute_function[i] == "1308" then
                layers_one_melody_bottom()
            end
            if execute_function[i] == "1309" then
                layers_two_melody_bottom()
            end
            if execute_function[i] == "1310" then
                layers_three_melody_bottom()
            end
            if execute_function[i] == "1311" then
                layers_four_melody_bottom()
            end
            if execute_function[i] == "1312" then
                layers_all_reset()
            end
            if execute_function[i] == "1313" then
                layers_all_reduce()
            end
            if execute_function[i] == "1314" then
                layers_swap_one_two()
            end
            if execute_function[i] == "1315" then
                layers_swap_one_three()
            end
            if execute_function[i] == "1316" then
                layers_swap_one_four()
            end
            if execute_function[i] == "1317" then
                layers_swap_two_three()
            end
            if execute_function[i] == "1318" then
                layers_swap_two_four()
            end
            if execute_function[i] == "1319" then
                layers_swap_three_four()
            end
            if execute_function[i] == "1320" then
                layers_swap_one_three_two_four()
            end
            if execute_function[i] == "1321" then
                layers_swap_one_two_three_four()
            end
            if execute_function[i] == "1322" then
                layers_one_clear()
            end
            if execute_function[i] == "1323" then
                layers_two_clear()
            end
            if execute_function[i] == "1324" then
                layers_three_clear()
            end
            if execute_function[i] == "1325" then
                layers_four_clear()
            end
            if execute_function[i] == "1326" then
                layers_one_two_clear()
            end
            if execute_function[i] == "1327" then
                layers_one_three_clear()
            end
            if execute_function[i] == "1328" then
                layers_one_four_clear()
            end
            if execute_function[i] == "1329" then
                layers_one_two_three_clear()
            end
            if execute_function[i] == "1330" then
                layers_one_three_four_clear()
            end
            if execute_function[i] == "1331" then
                layers_two_three_clear()
            end
            if execute_function[i] == "1332" then
                layers_two_four_clear()
            end
            if execute_function[i] == "1333" then
                layers_two_three_four_clear()
            end
            if execute_function[i] == "1334" then
                layers_three_four_clear()
            end
            if execute_function[i] == "1400" then
                polyphony_add_octave_up()
            end
            if execute_function[i] == "1401" then
                polyphony_add_octave_down()
            end
            if execute_function[i] == "1402" then
                polyphony_add_diatonic_third_up()
            end
            if execute_function[i] == "1403" then
                polyphony_add_diatonic_third_down()
            end
            if execute_function[i] == "1404" then
                polyphony_rotate_up()
            end
            if execute_function[i] == "1405" then
                polyphony_rotate_down()
            end
            if execute_function[i] == "1406" then
                polyphony_delete_top_note()
            end
            if execute_function[i] == "1407" then
                polyphony_delete_bottom_note()
            end
            if execute_function[i] == "1408" then
                polyphony_keep_top_note()
            end
            if execute_function[i] == "1409" then
                polyphony_keep_bottom_note()
            end
            if execute_function[i] == "1500" then
                transform_harmonics_third()
            end
            if execute_function[i] == "1501" then
                transform_harmonics_fourth()
            end
            if execute_function[i] == "1502" then
                transform_harmonics_fifth()
            end
            if execute_function[i] == "1503" then
                transform_breath_to_expression()
            end
            if execute_function[i] == "1504" then
                transform_caesura_to_expression()
            end
            if execute_function[i] == "1505" then
                transform_single_pitch_F4()
            end
            if execute_function[i] == "1506" then
                transform_single_pitch_F5()
            end
            if execute_function[i] == "1507" then
                transform_single_pitch_C5()
            end
            if execute_function[i] == "1508" then
                transform_single_pitch_G5()
            end
            if execute_function[i] == "1509" then
                transform_single_pitch_A5()
            end
            if execute_function[i] == "1510" then
                transform_semitone_up()
            end
            if execute_function[i] == "1511" then
                transform_semitone_down()
            end
            if execute_function[i] == "1512" then
                transform_flip_enharmonic()
            end
            if execute_function[i] == "1513" then
                transform_cluster_indeterminate()
            end
            if execute_function[i] == "1514" then
                transform_cluster_determinate()
            end
            if execute_function[i] == "1515" then
                transform_toggle_ledger_lines()
            end
            if execute_function[i] == "1516" then
                transform_highest_lowest_possible()
            end
            if compare({"1517", "kickline", "bandhits", "kick"}) then
                transform_create_kicks()
            end
            if compare({"1518", "topline"}) then
                transform_topline_notation()
            end
            if execute_function[i] == "1600" then
                chords_altered_bass_after()
            end
            if execute_function[i] == "1601" then
                chords_altered_bass_under()
            end
            if execute_function[i] == "1602" then
                chords_altered_bass_subtext()
            end
            if execute_function[i] == "1603" then
                chords_move_baseline_down()
            end
            if execute_function[i] == "1604" then
                chords_move_baseline_up()
            end
            if execute_function[i] == "1700" then
                reset_rests()
            end
            if execute_function[i] == "1701" then
                reset_baselines_lyrics()
            end
            if execute_function[i] == "1702" then
                reset_barlines()
            end
            if execute_function[i] == "1703" then
                reset_chord_symbol_pos()
            end
            if execute_function[i] == "1704" then
                reset_baseline_expression_below()
            end
            if execute_function[i] == "1705" then
                reset_baseline_expression_above()
            end
            if execute_function[i] == "1706" then
                reset_baseline_expression_all()
            end
            if execute_function[i] == "1707" then
                reset_baseline_chord()
            end
            if execute_function[i] == "1708" then
                reset_baseline_fretboard()
            end
            if execute_function[i] == "1709" then
                reset_baseline_chord_fretboard()
            end
            if execute_function[i] == "1802" then
                playback_all_staves_document_beginning_to_region_end()
            end
            if execute_function[i] == "1803" then
                playback_selected_staves_document_beginning_to_region_end()
            end
            if execute_function[i] == "1804" then
                playback_all_staves_region_beginning_to_document_end()
            end
            if execute_function[i] == "1805" then
                playback_selected_staves_region_beginning_to_document_end()
            end
            if execute_function[i] == "1806" then
                playback_all_staves_region_beginning_to_region_end()
            end
            if execute_function[i] == "1807" then
                playback_selected_staves_region_beginning_to_region_end()
            end
            if execute_function[i] == "1808" then
                playback_mute_cue_notes()
            end
            if execute_function[i] == "1809" then
                playback_mute_all_notes()
            end
            if execute_function[i] == "1810" then
                playback_unmute_all_notes()
            end
            if execute_function[i] == "1811" then
                navigation_switch_to_slected_part()
            end
            if compare({"1900", "treble"}) then
                clef_change_pre(0) -- treble clef
            end
            if compare({"1901", "alto"}) then
                clef_change_pre(1) -- alto clef
            end
            if compare({"1902", "tenor"}) then
                clef_change_pre(2) -- tenor clef
            end
            if compare({"1903", "bass"}) then
                clef_change_pre(3) -- bass clef
            end
            if compare({"1904", "treble8ba", "treble8vb", "treble_8vb", "treble_8ba", "treble8", "treb8"}) then
                clef_change_pre(5) -- treble_8ba clef
            end
            if compare({"1905", "perc"}) then
                clef_change_pre(12) -- perc clef (new style)
            end
            if execute_function[i] == "9000" then
                plugin_center_rehearsal_marks()
            end
            if execute_function[i] == "9001" then
                plugin_custom_text_expressive()
            end
            if execute_function[i] == "9002" then
                plugin_custom_text_technique()
            end
            if execute_function[i] == "9003" then
                plugin_custom_text_tempo()
            end
            if execute_function[i] == "9004" then
                plugin_custom_text_dynamics()
            end
            if compare({"9005", "tacet"}) then
                tacet_text = config.tacet_text
                al_fine_text = config.al_fine_text
                run_file("region_multimeasure_rest_tacet")
            end
            if compare({"9006", "playx", "playxtimes", "playxbars"}) then
                plugin_make_x_times()
            end
            if compare({"9007", "playxmore", "playmore", "more"}) then
                plugin_make_x_more()
            end
            if compare({"9008", "harp", "hp_ped", "hp_pedals"}) then
                run_file("harp_pedal_wizard")
            end
            if execute_function[i] == "9994" then
                update_win_ahk()
            end
            if execute_function[i] == "9995" then
                update_mac_km()
            end
            if execute_function[i] == "9996" then
                update_win_35()
            end
            if execute_function[i] == "9997" then
                update_win_48()
            end
            if execute_function[i] == "9998" then
                update_mac_35()
            end
            if execute_function[i] == "9999" then
                update_mac_35()
            end
            if compare({"0000", "config"}) then
                config_jetstream()
            end
        else
            if compare({"0000", "config"}) then
                config_jetstream()
            elseif execute_function[i] == "1800" then
                playback_all_staves_document_beginning_to_document_end()
            elseif execute_function[i] == "1801" then
                playback_selected_staves_document_beginning_to_document_end()
            elseif execute_function[i] == "9000" then
                plugin_center_rehearsal_marks()
            elseif execute_function[i] == "0301" then
                lyrics_delete_lyrics()
            elseif compare({"9008", "harp", "hp_ped", "hp_pedals"}) then
                run_file("harp_pedal_wizard")
            elseif execute_function[i] == "9994" then
                update_win_ahk()
            elseif execute_function[i] == "9995" then
                update_mac_km()
            elseif execute_function[i] == "9996" then
                update_win_35()
            elseif execute_function[i] == "9997" then
                update_win_48()
            elseif execute_function[i] == "9998" then
                update_mac_35()
            elseif execute_function[i] == "9999" then
                update_mac_35()
            else
                finenv.UI():AlertInfo("Please select a region and try again.", nil)
                return
            end
        end
    end
end
