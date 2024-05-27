function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine after Michael McClennan & Jacob Winkler"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.31"
    finaleplugin.Date = "2024/05/27"
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

        > These __Key Commands__ are available when the __times__ field is highlighted: 

        > - __q__: show these script notes 
        > - __w__: flip [copy Articulations] 
        > - __e__: flip [copy Expressions] 
        > - __r__: flip [copy Slurs] 
        > - __t__: flip [copy Other Smartshapes] 
        > - __y__: flip [copy Lyrics] 
        > - __u__: flip [copy Chords]  
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
local hotkey = { -- customise hotkeys (lowercase only)
    copy_articulations = "w",
    copy_expressions = "e",
    copy_slurs       = "r",
    copy_smartshapes = "t",
    copy_lyrics      = "y",
    copy_chords      = "u",
    copy_all         = "a",
    copy_none        = "z",
    modeless         = "m",
    show_info        = "q",
}

local config = {
    num_repeats  = 1,
    timer_id    = 1,
    modeless    = false, -- false = modal / true = modeless
    window_pos_x = false,
    window_pos_y = false,
}
local dialog_options = { -- and populate config values (unchecked)
    "copy_articulations", "copy_expressions", "copy_slurs",
    "copy_smartshapes",   "copy_lyrics",      "copy_chords"
}
for _, v in ipairs(dialog_options) do config[v] = 0 end -- (default all unchecked)

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
    local str = staff:CreateDisplayAbbreviatedNameString().LuaString
    if not str or str == "" then
        str = "Staff" .. staff_num
    end
    return str
end

local function initialise_parameters()
    local rgn = finenv.Region()
    selection = { staff = "no staff", region = "no selection"} -- default
    -- saved_bounds
    for _, property in ipairs(bounds) do
        saved_bounds[property] = rgn:IsEmpty() and 0 or rgn[property]
    end
    -- selection_id
    if not rgn:IsEmpty() then
        -- staves
        selection.staff = get_staff_name(rgn.StartStaff)
        if rgn.EndStaff ~= rgn.StartStaff then
            selection.staff = selection.staff .. "-" .. get_staff_name(rgn.EndStaff) .. " "
        end
        -- measures
        local r1 = rgn.StartMeasure + (rgn.StartMeasurePos / measure_duration(rgn.StartMeasure))
        local m = measure_duration(rgn.EndMeasure)
        local r2 = rgn.EndMeasure + (math.min(rgn.EndMeasurePos, m) / m)
        selection.region = string.format("m%.2f-%.2f", r1, r2)
        
    end
end

local function add_duration(measure_number, position, add_edu)
    local m_width = measure_duration(measure_number)
    if m_width == 0 then return 0, 0 end -- measure didn't load
    if position > m_width then
        position = m_width -- override faulty measure positioning
    end
    local remaining_to_add = position + add_edu
    while remaining_to_add >= m_width do
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
    measure:Load(measure_num)
    local beat_edu = measure:GetTimeSignature():CalcLargestBeatDuration()
    if (beat_edu % 3 == 0) then beat_edu = beat_edu / 3 end -- compound meter

    local ok, count = false, 0
    while not ok and count < 4 do -- scan down to 1/16th sub-beat
        local remainder = pos % beat_edu
        if remainder == 0 then
            ok = true -- found integer multiple
        else
            local ratio = remainder / beat_edu
            local num_beats = math.floor(pos / beat_edu)
            if ratio >= 15/16 or ratio <= 1/16 then
                if ratio >= 15/16 then num_beats = num_beats + 1 end
                pos = num_beats * beat_edu
                ok = true -- within 1/16th of total beat
            end
        end
        if not ok then
            count = count + 1 -- one more cycle
            beat_edu = beat_edu / 2 -- halve note value
        end
    end
    return pos
end

local function region_duration(rgn, rounded_end_pos)
    local measure = {
        start = rgn.StartMeasure,
        stop  = rgn.EndMeasure
    }
    local pos = {
        start = rgn.StartMeasurePos,
        stop  = rounded_end_pos
    }
    local diff = pos.stop - pos.start -- simple EDU offset
    if measure.start ~= measure.stop then
        local duration = pos.start * -1
        while measure.start < measure.stop do
            duration = duration + measure_duration(measure.start)
            measure.start = measure.start + 1
        end
        diff = duration + pos.stop
    end
    return diff
end

local function region_erasures(rgn)
    -- region-based markings
    if config.copy_smartshapes == 0 or config.copy_slurs == 0 then -- erase SMART SHAPES
        local sh_rgn = finale.FCMusicRegion()
        sh_rgn:SetRegion(rgn) -- extend erasure region for stray hairpins
        sh_rgn.EndMeasure, sh_rgn.EndMeasurePos =
            add_duration(sh_rgn.EndMeasure, sh_rgn.EndMeasurePos, finale.NOTE_8TH)
        for mark in loadallforregion(finale.FCSmartShapeMeasureMarks(), sh_rgn) do
            local shape = mark:CreateSmartShape()
            if shape and
                (   (not shape:IsSlur() and config.copy_smartshapes == 0) or
                    (shape:IsSlur() and config.copy_slurs == 0)
                )   then
                shape:DeleteData()
            end
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
            if config.copy_articulations == 0 and entry.ArticulationFlag then -- erase ARTICULATIONS
                for articulation in eachbackwards(entry:CreateArticulations()) do
                    articulation:DeleteData()
                end
                entry:SetArticulationFlag(false)
            end
            if config.copy_lyrics == 0 and entry.LyricFlag then -- erase LYRICS
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

local function paste_copies(source_region)
    if source_region:IsEmpty() or config.num_repeats < 1 then return end -- no duplication
    local rpt_rgn = mixin.FCMMusicRegion()
    rpt_rgn:SetRegion(source_region)
    --
    finenv.StartNewUndoBlock(
        string.format("Ostinato %s x %d", selection.region, config.num_repeats),
        false
    )
    rpt_rgn.EndMeasurePos = math.min(rpt_rgn.EndMeasurePos, measure_duration(rpt_rgn.EndMeasure))
    local end_pos = rpt_rgn.EndMeasurePos
    local rounded_pos = round_measure_position(rpt_rgn.EndMeasure, end_pos)
    if end_pos >= rounded_pos and rounded_pos > 1 then
        rpt_rgn.EndMeasurePos = rounded_pos - 1
    end

    rpt_rgn:CopyMusic() -- save a copy of the current selection
    local duration = region_duration(rpt_rgn, rounded_pos) -- "full" duration of duplicate period
    local first_measure, first_pos = source_region.StartMeasure, source_region.StartMeasurePos
    for i = 1, config.num_repeats do
        if not shift_region_by_EDU(rpt_rgn, duration) then break end -- no more music
        rpt_rgn:PasteMusic()
        if i == 1 then -- save start of the first repeat region
            first_measure = rpt_rgn.StartMeasure
            first_pos = rpt_rgn.StartMeasurePos
        end
    end
    rpt_rgn:ReleaseMusic() -- finished pasting
    -- erase unwanted markings across whole ostinato passage
    rpt_rgn.StartMeasure = first_measure
    rpt_rgn.StartMeasurePos = first_pos
    region_erasures(rpt_rgn)  -- erase markings from full "duplicated" region
    source_region:SetInDocument() -- restore original selection
    finenv.EndUndoBlock(true)
    source_region:Redraw()
end

local function run_user_dialog()
    local edit_x, y_step = 105, 17
    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    local save_rpt = config.num_repeats
    local name = plugindef():gsub("%.%.%.", "")
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
    local y = 0
        -- local functions
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
            utils.show_notes_dialog(dialog, "About " .. name, 500, 420)
            refocus_document = true
        end
        local function key_check(ctl) -- key commands
            local s = ctl:GetText():lower()
            if s:find("[^0-9]") then
                if s:find(hotkey.copy_articulations)   then flip_check(1)
                elseif s:find(hotkey.copy_expressions) then flip_check(2)
                elseif s:find(hotkey.copy_slurs)       then flip_check(3)
                elseif s:find(hotkey.copy_smartshapes) then flip_check(4)
                elseif s:find(hotkey.copy_lyrics)      then flip_check(5)
                elseif s:find(hotkey.copy_chords)      then flip_check(6)
                elseif s:find(hotkey.copy_all)   then check_all_state(1)
                elseif s:find(hotkey.copy_none)  then check_all_state(0)
                elseif s:find(hotkey.show_info)  then info_dialog()
                elseif s:find(hotkey.modeless)   then
                    local mod = dialog:GetControl("modeless")
                    mod:SetCheck((mod:GetCheck() + 1) % 2)
                end
                ctl:SetText(save_rpt):SetKeyboardFocus()
            else
                if #s > 2 then
                    save_rpt = s:sub(-2)
                    ctl:SetText(save_rpt)
                end
            end
        end
        local function on_timer() -- look for changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    initialise_parameters() -- update selection tracker
                    dialog:GetControl("info"):SetText(selection.staff .. selection.region)
                    break -- all done
                end
            end
        end
    --
    dialog:CreateStatic(0, y):SetText("Repeat ostinato:"):SetWidth(edit_x)
    dialog:CreateStatic(edit_x, y):SetText("Include:"):SetWidth(90)
    y = y + y_step + 2
    local num_repeats = dialog:CreateEdit(0, y + 2 - y_offset)
        :SetWidth(30):SetText(config.num_repeats)
        :AddHandleCommand(function(self) key_check(self) end)
    dialog:CreateStatic(35, y + 2):SetText("times"):SetWidth(edit_x)
    for _, v in ipairs(dialog_options) do
        local id = v:sub(6):gsub("^%l", string.upper)
        if id == "Smartshapes" then id = "Other Smartshapes" end
        id = id .. " (" .. hotkey[v] .. ")"
        dialog:CreateCheckbox(edit_x, y, v):SetCheck(config[v])
           :SetText(id):SetWidth(135)
        y = y + y_step
    end
    dialog:CreateCheckbox(0, y, "modeless"):SetWidth(135)
        :SetCheck(config.modeless and 1 or 0)
        :SetText("\"Modeless\" Dialog (" .. hotkey.modeless .. ")")
    local q = dialog:CreateButton(edit_x + 100, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() info_dialog() end)
    -- modeless selection info
    y = y + 15
    dialog:CreateStatic(15, y, "info"):SetWidth(edit_x + 75)
        :SetText(selection.staff .. selection.region)
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
    dialog:RegisterHandleOkButtonPressed(function()
        config.num_repeats = num_repeats:GetInteger()
        for _, v in ipairs(dialog_options) do
            config[v] = dialog:GetControl(v):GetCheck()
        end
        paste_copies(finenv.Region())
    end)
    local change_mode = false
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
    return change_mode -- only functional in "modal" operation
end

local function make_ostinato()
    configuration.get_user_settings(script_name, config, true)
    if not config.modeless and finenv.Region():IsEmpty() then
        finenv.UI():AlertError(
            "Please select some music\nbefore running this script",
            plugindef():gsub("%.%.%.", "")
        )
        return
    end

    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))
    initialise_parameters()
    if mod_key then
        paste_copies(finenv.Region())
    else
        while run_user_dialog() do
        end
    end
end

make_ostinato()
