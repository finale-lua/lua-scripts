function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine after Michael McClennan & Jacob Winkler"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.13"
    finaleplugin.Date = "2024/01/15"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        Copy the current selection and paste it consecutively 
        to the right a nominated number of times. 
        The replicas can span barlines ignoring time signatures. 
        The same effect can be achieved with Edit → Paste Multiple 
        but this script is simpler to use and works intuitively 
        on the current music selection in a single step. 

        To repeat the last action without confirmation 
        dialog hold down [shift] when starting the script. 
        Choose to independently include or remove articulations, 
        expressions, smartshapes, lyrics or chords from the repeats. 

        This script grew from the "region_replicate_music.lua" script in 
        the FinaleLua.com repository by Michael McClennan and Jacob Winkler.
    ]]
    return "Ostinato Maker...", "Ostinato Maker",
        "Copy the current selection and paste it consecutively to the right a number of times"
end

local info_notes = [[
Copy the current selection and paste it consecutively
to the right a nominated number of times.
The replicas can span barlines ignoring time signatures.
The same effect can be achieved with Edit → Paste Multiple
but this script is simpler to use and works intuitively
on the current music selection in a single step.
**
To repeat the last action without confirmation
dialog hold down [shift] when starting the script.
Choose to independently include or remove articulations,
expressions, smartshapes, lyrics or chords from the repeats.
**
This script grew from the "region_replicate_music.lua" script in
the FinaleLua.com repository by Michael McClennan and Jacob Winkler.
**
Key Commands:
*• q @t show these script notes
*• w @t flip [copy articulations]
*• e @t flip [copy expressions]
*• r @t flip [copy smartshapes]
*• t @t flip [copy lyrics]
*• y @t flip [copy chords]
*– – –
*• a @t copy all
*• z @t copy none
]]
info_notes = info_notes:gsub("\n%s*", " "):gsub("*", "\n"):gsub("@t", "\t")
    .. "\n(" .. finaleplugin.Version .. ")"

global_timer_id = 1

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local script_name = "ostinato_maker"

local config = {
    num_repeats  =   1,
    window_pos_x = false,
    window_pos_y = false,
}
local dialog_options = { -- and populate config values (unchecked)
    "copy_articulations", "copy_expressions", "copy_smartshapes", "copy_lyrics", "copy_chords"
}
for _, v in ipairs(dialog_options) do config[v] = 0 end -- (default unchecked)

local bounds = { -- primary region selection boundary
    "StartStaff", "StartMeasure", "StartMeasurePos",
    "EndStaff",   "EndMeasure",   "EndMeasurePos",
}

local function copy_region_bounds()
    local copy = {}
    for _, v in ipairs(bounds) do
        copy[v] = finenv.Region()[v]
    end
    return copy
end

function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function measure_duration(measure_number)
    local m = finale.FCMeasure()
    return m:Load(measure_number) and m:GetDuration() or 0
end

local function selection_id()
    if finenv.Region():IsEmpty() then return " - no selection - " end
    local rgn = finenv.Region()
    local ratio = rgn.StartMeasure + (rgn.StartMeasurePos / measure_duration(rgn.StartMeasure))
    local id = "m" .. string.format("%.2f", ratio) .. "-"
    local m = measure_duration(rgn.EndMeasure)
    ratio = rgn.EndMeasure + (math.min(rgn.EndMeasurePos, m) / m)
    id = id .. "m" .. string.format("%.2f", ratio)
    return id
end

local function staff_id()
    if finenv.Region():IsEmpty() then return "" end
    local staff = finale.FCStaff()
    staff:Load(finenv.Region().StartStaff)
    local str = finale.FCString()
    str = staff:CreateDisplayFullNameString()
    local id = "Staff: " .. str.LuaString .. " → "
    staff:Load(finenv.Region().EndStaff)
    str = staff:CreateDisplayFullNameString()
    return id .. str.LuaString
end

local function add_duration(measure_number, position, add_edu)
    local m_width = measure_duration(measure_number)
    if m_width == 0 then -- measure didn't load
        return 0, 0
    end
    if position > m_width then
        position = m_width
    end
    local remaining_to_add = position + add_edu
    while remaining_to_add > m_width do
        remaining_to_add = remaining_to_add - m_width
        local next_width = measure_duration(measure_number + 1) -- another measure?
        if next_width == 0 then -- no more measures
            remaining_to_add = m_width -- finished calculating
        else
            measure_number = measure_number + 1 -- next measure
            m_width = next_width
        end
    end
    return measure_number, remaining_to_add
end

local function shift_region_by_EDU(rgn, add_edu)
    rgn.EndMeasure, rgn.EndMeasurePos =
            add_duration(rgn.EndMeasure, rgn.EndMeasurePos, add_edu)
    if rgn.EndMeasure == 0 then return false end
    rgn.StartMeasure, rgn.StartMeasurePos =
            add_duration(rgn.StartMeasure, rgn.StartMeasurePos, add_edu)
    if rgn.StartMeasure == 0 then return false end
    return true
end

local function round_measure_position(measure_num, pos)
    -- round off measure position to nearest reasonable sub-beat
    local measure = finale.FCMeasure()
    local beat_edu = finale.NOTE_QUARTER -- default for composite T_Sig
    measure:Load(measure_num)
    local time_sig = measure:GetTimeSignature()

    if not time_sig.CompositeTop then -- simple T_Sig beat value
        beat_edu = time_sig.BeatDuration
        if (beat_edu % 3 == 0) then beat_edu = beat_edu / 3 end -- compound
    end
    local ok, count = false, 1
    while not ok and count <= 3 do -- scan down to 1/8th sub-beat
        local remainder = pos % beat_edu
        if remainder == 0 then
            ok = true -- found integer multiple
        else
            local ratio = remainder / beat_edu
            local num_beats = math.floor(pos / beat_edu)
            if ratio >= 7/8 or ratio <= 1/8 then
                if ratio >= 7/8 then num_beats = num_beats + 1 end
                pos = num_beats * beat_edu
                ok = true -- within 1/8th of total beat
            end
        end
        if not ok then
            count = count + 1 -- one more cycle
            beat_edu = beat_edu / 2 -- halve note value
        end
    end
    return pos
end

local function region_duration(rgn)
    local meas = {
        start = rgn.StartMeasure,
        stop = rgn.EndMeasure
    }
    local pos = {
        start = round_measure_position(meas.start, rgn.StartMeasurePos),
        stop = round_measure_position(meas.stop, rgn.EndMeasurePos)
    }
    local diff, duration = 0, 0
    if meas.start == meas.stop then -- simple EDU offset
        diff = pos.stop - pos.start
    else
        duration = -pos.start
        while meas.start < meas.stop do
            duration = duration + measure_duration(meas.start)
            meas.start = meas.start + 1
        end
        diff = duration + pos.stop
    end
    return diff
end

local function region_erasures(rgn)
    -- region-based markings
    if config.copy_smartshapes == 0 then -- erase SMART SHAPES
        local sh_rgn = finale.FCMusicRegion()
        sh_rgn:SetRegion(rgn) -- extend erasure region for stray hairpins
        sh_rgn.EndMeasure, sh_rgn.EndMeasurePos =
            add_duration(sh_rgn.EndMeasure, sh_rgn.EndMeasurePos, 256)
        for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), sh_rgn) do
            local shape = mark:CreateSmartShape()
            if shape then shape:DeleteData() end
        end
    end
    if config.copy_expressions == 0 then -- erase EXPRESSIONS
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(rgn)
        for exp in eachbackwards(expressions) do
            if exp.StaffGroupID == 0 then exp:DeleteData() end
        end
    end
    if config.copy_chords == 0 then  -- erase CHORDS
        local chords = finale.FCChords()
        chords:LoadAllForRegion(rgn)
        for chord in eachbackwards(chords) do
            if chord then chord:DeleteData() end
        end
    end
    -- then entry-based markings
    if config.copy_articulations == 0 or config.copy_lyrics == 0 then
        for entry in eachentrysaved(rgn) do
            if entry.ArticulationFlag and config.copy_articulations == 0 then -- erase ARTICULATIONS
                for articulation in eachbackwards(entry:CreateArticulations()) do
                    articulation:DeleteData()
                end
                entry:SetArticulationFlag(false)
            end
            if entry.LyricFlag and config.copy_lyrics == 0 then -- erase LYRICS
                for _, v in ipairs{"FCChorusSyllable", "FCSectionSyllable", "FCVerseSyllable"} do
                    local lyric = finale[v]()
                    lyric:SetNoteEntry(entry)
                    while lyric:LoadFirst() do
                        lyric:DeleteData()
                    end
                end
            end
        end
    end
end

local function paste_many_copies()
    if finenv.Region():IsEmpty() then
        finenv.UI():AlertError("Please select some music before\n"
            .. "running this script.", plugindef() .. " Error" )
        return
    end
    local rgn = finenv.Region()
    local origin = copy_region_bounds() -- copy current bounds
    local undo_str = "Ostinato Maker " .. selection_id()
    finenv.StartNewUndoBlock(undo_str, false)
    --  ---- DO THE WORK
    if rgn.EndMeasurePos >= measure_duration(rgn.EndMeasure) then
        rgn.EndMeasurePos = measure_duration(rgn.EndMeasure) - 1
    end
    rgn:CopyMusic() -- save a copy of the current selection
    local duration = region_duration(rgn)
    local first_rpt = nil -- save start position of first repeat
    for _ = 1, config.num_repeats do
        if not shift_region_by_EDU(rgn, duration) then break end
        rgn:PasteMusic()
        if not first_rpt then -- only save the first repeat region
            first_rpt = { measure = rgn.StartMeasure, pos = rgn.StartMeasurePos }
        end
    end
    rgn:ReleaseMusic()
    -- erase unwanted markings across whole ostinato passage
    rgn.StartMeasure = first_rpt.measure
    rgn.StartMeasurePos = first_rpt.pos
    region_erasures(rgn)
    -- reset to start of operation
    for _, v in ipairs(bounds) do rgn[v] = origin[v] end
    rgn:SetInDocument()
    --  ----
    if finenv.EndUndoBlock then
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock(undo_str, true)
    end
end

local function on_timer()
    local changed = false
    for _, v in ipairs(bounds) do
        if global_selection[v] ~= finenv.Region()[v] then
            changed = true
            break
        end
    end
    if changed then
        global_selection = copy_region_bounds()
        global_dialog:GetControl("info")
            :SetText("Selection " .. selection_id() .. "\n" .. staff_id())
    end
end

local function create_dialog_box()
    local edit_x, e_wide, y_step = 110, 40, 18
    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    local save_rpt, answer = config.num_repeats, {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    local y = 0
    local function flip_check(id)
        local ctl = answer[dialog_options[id]]
        ctl:SetCheck((ctl:GetCheck() + 1) % 2)
    end
    local function check_all_state(state)
        for _, v in ipairs(dialog_options) do
            answer[v]:SetCheck(state)
        end
    end
    local function info_dialog()
        finenv.UI():AlertInfo(info_notes, "About " .. plugindef())
    end
    local function key_check(ctl) -- some stray key commands
        local s = ctl:GetText():lower()
        if s:find("[^0-9]") then
            if s:find("q") then info_dialog()
            elseif s:find("w") then flip_check(1)
            elseif s:find("e") then flip_check(2)
            elseif s:find("r") then flip_check(3)
            elseif s:find("t") then flip_check(4)
            elseif s:find("y") then flip_check(5)
            elseif s:find("a") then check_all_state(1)
            elseif s:find("z") then check_all_state(0)
            end
            ctl:SetText(save_rpt):SetKeyboardFocus()
        else
            s = s:sub(-3) -- 3-digit limit
            ctl:SetText(s)
            save_rpt = s
        end
    end
    dialog:CreateStatic(0, y, "info")
        :SetText("Selection " .. selection_id() .. "\n" .. staff_id())
        :SetWidth(edit_x * 2):SetHeight(30)
    y = y + 35
    dialog:CreateStatic(0, y):SetText("Repeat ostinato:"):SetWidth(edit_x)
    dialog:CreateStatic(edit_x, y):SetText("Include:"):SetWidth(90)
    y = y + y_step
    local num_repeats = dialog:CreateEdit(0, y + 2 - y_offset)
        :SetWidth(e_wide - 4):SetText(config.num_repeats)
        :AddHandleCommand(function(self) key_check(self) end)
    dialog:CreateStatic(e_wide, y + 2):SetText("times"):SetWidth(edit_x)
    for _, v in ipairs(dialog_options) do
        answer[v] = dialog:CreateCheckbox(edit_x, y):SetCheck(config[v])
           :SetText(v:sub(6, -1):gsub("^%l", string.upper)):SetWidth(90)
        y = y + y_step
    end
    local q = dialog:CreateButton(0, y - 19):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() info_dialog() end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleTimer(on_timer)
    dialog:RegisterInitWindow(function()
        q:SetFont(q:CreateFontInfo():SetBold(true))
        num_repeats:SetKeyboardFocus()
        dialog:SetTimer(global_timer_id, 125)
    end)
    dialog:RegisterCloseWindow(function()
        dialog_save_position(dialog)
        dialog:StopTimer(global_timer_id)
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.num_repeats = num_repeats:GetInteger()
        for _, v in ipairs(dialog_options) do
            config[v] = answer[v]:GetCheck()
        end
        paste_many_copies()
    end)
    return dialog
end

local function make_ostinato()
    configuration.get_user_settings(script_name, config, true)
    global_selection = global_selection or copy_region_bounds()
    global_dialog = global_dialog or create_dialog_box()
    --finenv.RegisterModelessDialog(global_dialog)
    --global_dialog:ShowModeless()
    global_dialog:RunModeless()
end

make_ostinato()
