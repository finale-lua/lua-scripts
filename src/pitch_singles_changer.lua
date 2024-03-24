function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.14"
    finaleplugin.Date = "2024/03/24"
    finaleplugin.CategoryTags = "Entries, Pitch, Transposition"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = [[
        Change up to four specific pitches to other specific pitches. 
        Pitch specification is exact and immutable: 

        > • First character: note name __A__-__G__  
        > &nbsp;  (Lower case will be replaced by upper case)  
        > • Last character: octave number __0__-__9__  
        > • In between: accidentals if any (__b/bb/bbb__ ... __#/##/###__)  
        > &nbsp;  (you can use __s__ instead of __#__) 

        __C4__ is middle C. __B4__ is a major seventh above that. 
        Mistakes in the pitch name format must be corrected 
        before pitches will be changed. 
        For transposing instruments on transposing scores select 
        __Written Pitch__ to affect the pitch you see on screen. 

        Select __Modeless__ if you prefer the dialog window to 
        "float" above your score so you can change the score selection 
        while it's active. In this mode, click __Apply__ [Return/Enter] 
        to make changes and __Cancel__ [Escape] to close the window. 
        Cancelling __Modeless__ will apply the _next_ time you use the script.
    ]]
    return "Pitch Singles Changer...",
        "Pitch Singles Changer",
        "Change up to four specific pitches to other specific pitches"
end

local config = {
    pitch_set = '["C4", "C5"]', -- JSON encoded pitch replacement set
    layer_num   = 0,
    timer_id    = 1,
    modeless    = false, -- false = modal / true = modeless
    written_pitch = false,
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local cjson = require("cjson")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local selection
local refocus_document = false -- set to true if utils.show_notes_dialog is used
local saved_bounds = {}
local bounds = { -- primary region selection boundaries
    "StartStaff", "StartMeasure", "StartMeasurePos",
    "EndStaff",   "EndMeasure",   "EndMeasurePos",
}

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

local function track_selection()
    -- set_saved_bounds
    local rgn = finenv.Region()
    for _, property in ipairs(bounds) do
        saved_bounds[property] = rgn:IsEmpty() and 0 or rgn[property]
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

local function extract_pitch(p)
    if not p or p == "" then return "", "", "" end
    return p:sub(1, 1):upper(), p:sub(2, -2):lower():gsub("s", "#"), p:sub(-1)
end

local function rewrite_pitch(p)
    local a, b, c = extract_pitch(p)
    return a .. b .. c
end

local function is_error(p)
    local a, b, c = extract_pitch(p)
    if      a:find("[^A-G]") or c:find("[^0-9]") or p:find("%d") < p:len()
        or  b:find("[^b#]") or  (b:find("b") and b:find("#")) then
        return true
    end
    return false
end

local function make_the_changes(pitches)
    local undo_str = "Pitch Change "
    for i = 1, 7, 2 do -- run through pitch pairs provided
        if pitches[i] ~= "" and pitches[i + 1] ~= "" then
            undo_str = undo_str .. string.format("%s-%s ", pitches[i], pitches[i + 1])
        end
    end
    finenv.StartNewUndoBlock(undo_str .. selection.region)
    local m = finale.FCMeasure()
    local pitch_str = finale.FCString()
    for entry in eachentrysaved(finenv.Region(), config.layer_num) do
        m:Load(entry.Measure)
        local keysig = m.KeySignature

        for note in each(entry) do
            note:GetString(pitch_str, keysig, false, config.written_pitch)
            for i = 1, 7, 2 do
                local a, b = pitches[i], pitches[i + 1]
                if pitch_str.LuaString == a  and a ~= "" and b~= "" then
                    pitch_str.LuaString = b
                    note:SetString(pitch_str, keysig, config.written_pitch)
                end
            end
        end
    end
    finenv.EndUndoBlock(true)
    if config.modeless then finenv.Region():Redraw() end
end

local function run_the_dialog()
    local pitches = cjson.decode(config.pitch_set)
    local y, y_diff = 0, 25
    local x = { 81, 128, 150 }
    local answer, ctl, save = {}, {}, {}
    local name = plugindef():gsub("%.%.%.", "")
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)

        -- local functions
        local function yd(diff) y = y + (diff or y_diff) end
        local function cstat(dx, dy, txt, width, id)
            dialog:CreateStatic(dx, dy, id):SetText(txt):SetWidth(width)
        end
        local function cedit(dx, dy, txt, width)
            local y_off = finenv.UI():IsOnMac() and 3 or 0
            return dialog:CreateEdit(dx, dy - y_off):SetWidth(width):SetText(txt)
        end
        local function on_timer() -- look for changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    track_selection() -- update selection tracker
                    ctl.info1:SetText(selection.staff)
                    ctl.info2:SetText(selection.region)
                    break -- all done
                end
            end
        end
        local function toggle_check(id)
            ctl[id]:SetCheck((ctl[id]:GetCheck() + 1) % 2)
        end
        local function clear_all()
            for i = 1, 8 do answer[i]:SetText("") end
        end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 400, 280)
            refocus_document = true
        end
        local function key_substitutions(id)
            local s = answer[id]:GetText():upper()
            if (id == 0 and s:find("[^0-4]"))
              or (id > 0 and s:find("[^#SA-G0-9]")) then
                if s:find("X") then
                    clear_all()
                else
                    if     s:find("M") then toggle_check("modeless")
                    elseif s:find("W") then toggle_check("written_pitch")
                    elseif  s:find("[?Q]") then show_info()
                    end
                    answer[id]:SetText(save[id])
                end
            else
                save[id] = (id == 0) and s:sub(-1) -- layer number
                    or (s:sub(1, 1) .. s:sub(2):lower():gsub("s", "#"))
                answer[id]:SetText(save[id])
            end
        end
    for i = 1, 7, 2 do
        cstat(0, y, "Change From:", 100)
        answer[i] = cedit(x[1], y, pitches[i], 45)
        answer[i]:AddHandleCommand(function() key_substitutions(i) end)
        cstat(x[2], y, "To:", 20)
        answer[i + 1] = cedit(x[3], y, pitches[i + 1], 45)
        answer[i + 1]:AddHandleCommand(function() key_substitutions(i + 1) end)
        save[i] = pitches[i]
        save[i + 1] = pitches[i + 1]
        yd()
    end
    cstat(0, y, "Layer (0-4):", 78)
    answer[0] = cedit(x[1] - 11, y, config.layer_num, 20) -- LAYER NUMBER
    answer[0]:AddHandleCommand(function() key_substitutions(0) end)
    ctl.written_pitch = dialog:CreateCheckbox(x[1] + 30, y):SetWidth(85)
        :SetCheck(config.written_pitch and 1 or 0):SetText("Written Pitch")
    yd(22)
    dialog:CreateHorizontalLine(0, y - 3, x[3] + 50)
    cstat(0, y, "Pitch examples: C4 / G#5 / Abb2", 180)
    yd(16)
    cstat(0, y, "(C4 = middle C)", 110)
    ctl.q = dialog:CreateButton(x[3] + 25, y - 3):SetWidth(20):SetText("?")
        :AddHandleCommand(function() show_info() end)
    yd(24)
    dialog:CreateHorizontalLine(0, y - 6, x[3] + 50)
    ctl.modeless = dialog:CreateCheckbox(0, y):SetWidth(x[3] - 20)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    dialog:CreateButton(x[3] - 25, y - 1):SetText("Clear All (x)"):SetWidth(70)
        :AddHandleCommand(function() clear_all() end)
    -- modeless selection info
    if config.modeless then
        yd(15)
        ctl.info1 = cstat(16, y, selection.staff, 170)
        yd(15)
        ctl.info2 = cstat(16, y, selection.region, 170)
    end

    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "Change")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterInitWindow(function(self)
        self:SetOkButtonCanClose(not config.modeless)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
    end)
    local user_error
    local pitch_set = {}
    dialog:RegisterHandleOkButtonPressed(function(self)
        user_error = false
        local errors = {}
        for i = 1, 8 do
            local s = answer[i]:GetText()
            if s and s ~= "" then
                if is_error(s) then
                    user_error = true
                    pitch_set[i] = s
                    table.insert(errors, s or "(blank entry)")
                else
                    pitch_set[i] = rewrite_pitch(s)
                    if config.modeless then answer[i]:SetText(pitch_set[i]) end
                end
            end
        end
        config.pitch_set = cjson.encode(pitch_set) -- save the bad with the good
        config.layer_num = answer[0]:GetInteger()
        config.written_pitch = (ctl.written_pitch:GetCheck() == 1)
        configuration.save_user_settings(script_name, config)
        if user_error then -- errors to be flagged
            self:CreateChildUI():AlertError(
                "These pitch names are invalid:\n"
                .. table.concat(errors, "; "), "Error: " .. name)
        else -- everything OK
            make_the_changes(pitch_set)
        end
    end)
    local change_mode = false
    dialog:RegisterCloseWindow(function(self)
        if config.modeless then self:StopTimer(config.timer_id) end
        local mode = (ctl.modeless:GetCheck() == 1)
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
    return change_mode or user_error -- (re-enter if modal condition)
end

local function change_pitches()
    configuration.get_user_settings(script_name, config, true)
    if not config.modeless and finenv.Region():IsEmpty() then
        finenv.UI():AlertError(
            "Please select some music\nbefore running this script.",
            finaleplugin.ScriptGroupName
        )
        return
    end
    track_selection()
    while run_the_dialog() do end
end

change_pitches()
