function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine after Michael McClennan & Jacob Winkler"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.23" -- MODAL/MODELESS optional
    finaleplugin.Date = "2024/03/01"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        Copy the current selection and paste it consecutively 
        to the right a nominated number of times. 
        The replicas can span barlines ignoring time signatures. 
        The same effect can be achieved with _Edit_ → _Paste Multiple_, 
        but this script is simpler to use and works intuitively 
        on the current music selection in a single step. 

        To repeat the last action without a confirmation 
        dialog hold down [Shift] when starting the script. 
        Independently include or remove articulations, 
        expressions, smartshapes, lyrics or chords from the repeats. 
        Your choice at _Finale_ → _Settings..._ → _Edit_ → _Automatic Music Spacing_ 
        determines whether or not the music is _respaced_ on completion. 

        Select __Modeless__ if you prefer the dialog window to 
        "float" above your score so you can change the score selection 
        while the script is active. In this mode, click __Apply__ [Return/Enter] 
        to create an ostinato and __Cancel__ [Escape] to close the window. 
        Cancelling __Modeless__ will apply the _next_ time you use the script.

        This script grew out of the _region_replicate_music.lua_ script 
        by Michael McClennan and Jacob Winkler in the 
        [FinaleLua.com](https://FinaleLua.com) repository. 

        > __Key Commands__: 

        > - __q__: show these script notes 
        > - __w__: flip [copy Articulations] 
        > - __e__: flip [copy Expressions] 
        > - __r__: flip [copy Smartshapes] 
        > - __t__: flip [copy Lyrics] 
        > - __y__: flip [copy Chords]  
        > - __a__: copy all 
        > - __z__: copy none 
        > - __m__: flip [Modeless] 
    ]]
    return "Ostinato Maker...", "Ostinato Maker",
        "Copy the current selection and paste it consecutively to the right a number of times"
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used
local selection
local saved_bounds = {}
local bounds = { -- primary region selection boundaries
    "StartStaff", "StartMeasure", "StartMeasurePos",
    "EndStaff",   "EndMeasure",   "EndMeasurePos",
}

local config = {
    num_repeats  = 1,
    timer_id    = 1,
    modeless    = false, -- false = modal / true = modeless
    window_pos_x = false,
    window_pos_y = false,
}
local dialog_options = { -- and populate config values (unchecked)
    "copy_articulations", "copy_expressions", "copy_smartshapes",
    "copy_lyrics", "copy_chords"
}
for _, v in ipairs(dialog_options) do config[v] = 0 end -- (default unchecked)

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function measure_duration(measure_number)
    local m = finale.FCMeasure()
    return m:Load(measure_number) and m:GetDuration() or 0
end

local function get_staff_name(staff_num)
    local staff = finale.FCStaff()
    staff:Load(staff_num)
    local str = staff:CreateDisplayFullNameString().LuaString
    if not str or str == "" then
        str = "Staff " .. staff_num
    end
    return str
end

local function initialise_parameters()
    -- set_saved_bounds
    local rgn = finenv.Region()
    for _, property in ipairs(bounds) do
        saved_bounds[property] = rgn[property]
    end
    -- update_selection_id
    selection = { staff = "no staff", region = "no selection"} -- default
    if not rgn:IsEmpty() then
        -- measures
        local r1 = rgn.StartMeasure + (rgn.StartMeasurePos / measure_duration(rgn.StartMeasure))
        local m = measure_duration(rgn.EndMeasure)
        local r2 = rgn.EndMeasure + (math.min(rgn.EndMeasurePos, m) / m)
        selection.region = string.format("m%.2f-m%.2f", r1, r2)
        -- staves
        selection.staff = get_staff_name(rgn.StartStaff)
        if rgn.EndStaff ~= rgn.StartStaff then
            selection.staff = selection.staff .. " → " .. get_staff_name(rgn.EndStaff)
        end
    end
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
    local diff, duration
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

local function paste_many_copies(region)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(region)
    finenv.StartNewUndoBlock("Ostinato " .. selection.region .. " x " .. config.num_repeats,
        false)
    local m_d = measure_duration(rgn.EndMeasure)
    if rgn.EndMeasurePos >= m_d then
        rgn.EndMeasurePos = m_d - 1
    end
    rgn:CopyMusic() -- save a copy of the current selection
    local duration = region_duration(rgn)
    local first_step
    for i = 1, config.num_repeats do
        if not shift_region_by_EDU(rgn, duration) then break end
        rgn:PasteMusic()
        if i == 1 then -- save start of the first repeat region
            first_step = { m = rgn.StartMeasure, pos = rgn.StartMeasurePos }
        end
    end
    rgn:ReleaseMusic()
    -- erase unwanted markings across whole ostinato passage
    if first_step then
        rgn.StartMeasure = first_step.m
        rgn.StartMeasurePos = first_step.pos
    end
    region_erasures(rgn)  -- erase markings from subset of full region
    rgn:SetRegion(region) -- reset to original selection
    rgn:SetInDocument()
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_user_dialog()
    local edit_x, e_wide, y_step = 110, 40, 18
    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    local save_rpt = config.num_repeats
    local name = plugindef():sub(1, -4)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
    local y = 0
    --
        local function flip_check(id)
            local ctl = dialog:GetControl(dialog_options[id])
            ctl:SetCheck((ctl:GetCheck() + 1) % 2)
        end
        local function check_all_state(state)
            for _, v in ipairs(dialog_options) do
                dialog:GetControl(v):SetCheck(state)
            end
        end
        local function info_dialog()
            utils.show_notes_dialog(dialog, "About " .. name)
            refocus_document = true
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
                elseif s:find("m") then
                    local mod = dialog:GetControl("modeless")
                    mod:SetCheck((mod:GetCheck() + 1) % 2)
                elseif s:find("a") then check_all_state(1)
                elseif s:find("z") then check_all_state(0)
                end
            else
                s = s:sub(-2) -- 2-digit limit
                save_rpt = s
            end
            ctl:SetText(save_rpt):SetKeyboardFocus()
        end
        local function on_timer() -- look for changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    initialise_parameters() -- update selection tracker
                    dialog:GetControl("info1"):SetText(selection.staff)
                    dialog:GetControl("info2"):SetText(selection.region)
                    break -- all done
                end
            end
        end
    --
    dialog:CreateStatic(0, y):SetText("Repeat ostinato:"):SetWidth(edit_x)
    dialog:CreateStatic(edit_x, y):SetText("Include:"):SetWidth(90)
    y = y + y_step + 2
    local num_repeats = dialog:CreateEdit(0, y + 2 - y_offset)
        :SetWidth(e_wide - 4):SetText(config.num_repeats)
        :AddHandleCommand(function(self) key_check(self) end)
    dialog:CreateStatic(e_wide, y + 2):SetText("times"):SetWidth(edit_x)
    for _, v in ipairs(dialog_options) do
        dialog:CreateCheckbox(edit_x, y, v):SetCheck(config[v])
           :SetText(v:sub(6, -1):gsub("^%l", string.upper)):SetWidth(90)
        y = y + y_step
    end
    dialog:CreateCheckbox(0, y, "modeless"):SetWidth(80)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    local q = dialog:CreateButton(edit_x + 70, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() info_dialog() end)
    -- modeless selection info
    if config.modeless then
        y = y + 15
        dialog:CreateStatic(20, y, "info1"):SetText(selection.staff):SetWidth(edit_x + 70)
        y = y + 15
        dialog:CreateStatic(20, y, "info2"):SetText(selection.region):SetWidth(edit_x + 70)
    end

    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterInitWindow(function(self)
        dialog:SetOkButtonCanClose(not config.modeless)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
        q:SetFont(q:CreateFontInfo():SetBold(true))
        num_repeats:SetKeyboardFocus()
    end)
    local change_mode = false
    dialog:RegisterHandleOkButtonPressed(function()
        config.num_repeats = num_repeats:GetInteger()
        for _, v in ipairs(dialog_options) do
            config[v] = dialog:GetControl(v):GetCheck()
        end
        paste_many_copies(finenv.Region())
    end)
    dialog:RegisterCloseWindow(function(self)
        if config.modeless then self:StopTimer(config.timer_id) end
        local mode = (dialog:GetControl("modeless"):GetCheck() == 1)
        change_mode = (mode and not config.modeless) -- modal -> modeless?
        config.modeless = mode
        dialog_save_position(self)
    end)
    if config.modeless then   -- "modeless"
        dialog:RunModeless()
    else
        dialog:ExecuteModal() -- "modal"
        if refocus_document then finenv.UI():ActivateDocumentWindow() end
    end
    return change_mode
end

local function make_ostinato()
    configuration.get_user_settings(script_name, config, true)
    if not config.modelss and finenv.Region():IsEmpty() then
        finenv.UI():AlertError(
            "Please select some music before\nrunning this script", plugindef()
        )
        return
    end

    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))
    local mode_change = true

    initialise_parameters()
    if mod_key then
        paste_many_copies(finenv.Region())
    else
        while mode_change do
            mode_change = run_user_dialog()
        end
    end
end

make_ostinato()
