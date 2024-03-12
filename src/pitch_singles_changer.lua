function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.12"
    finaleplugin.Date = "2024/03/12"
    finaleplugin.CategoryTags = "Entries, Pitch, Transposition"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = [[
        Change up to four specific pitches to other specific pitches. 
        Pitch specification is exact and immutable: 

        > 1. First character: pitch name __A__-__G__  
        > (Lower case will be replaced automatically with upper case)  
        > 2. Last character: octave number __0__-__9__  
        > 3. In between: accidentals if needed  
        > b / bb / bbb / # / ## / ###  
        > (you can use __s__ instead of __#__ - automatic replacement) 

        Mistakes in the pitch format must be corrected before pitches will be changed. 
        __C4__ is middle C. __B4__ is a major seventh above that. 
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
local library = require("library.general_library")
local script_name = library.calc_script_name()
local selection
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

local function initialise_parameters()
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
    return p:sub(1, 1):upper(), p:sub(2, -2):lower():gsub("s", "#"), p:sub(-1):lower()
end

local function rewrite_pitch(p)
    local a, b, c = extract_pitch(p)
    return a .. b .. c
end

local function is_error(p)
    if p == nil or p == "" then return false end
    local a, b, c = extract_pitch(p)
    if a:find("[^A-G]") then return true end
    if b:find("[^b#]") then return true end
    if c:find("[^0-9]") then return true end
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
                if a ~= "" and b~= "" and pitch_str.LuaString == a then
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
    local answer = {}
    local name = plugindef():gsub("%.%.%.", "")
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)

        -- local functions
        local function yd(diff) y = y + (diff or y_diff) end
        local function cstat(dx, dy, txt, wid)
            return dialog:CreateStatic(dx, dy):SetText(txt):SetWidth(wid)
        end
        local function cedit(dx, dy, txt, wid, id)
            local y_off = finenv.UI():IsOnMac() and 3 or 0
            return dialog:CreateEdit(dx, dy - y_off, id):SetWidth(wid):SetText(txt)
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
    for i = 1, 7, 2 do
        cstat(0, y, "Change From:", 100)
        answer[i] = cedit(x[1], y, pitches[i], 45)
        cstat(x[2], y, "To:", 20)
        answer[i + 1] = cedit(x[3], y, pitches[i + 1], 45)
        yd()
    end
    cstat(0, y, "Layer (0-4):", 78)
    cedit(x[1] - 11, y, config.layer_num, 20, "layer_num")
    dialog:CreateCheckbox(x[1] + 30, y, "written_pitch"):SetWidth(85)
        :SetCheck(config.written_pitch and 1 or 0):SetText("Written Pitch")
    yd(24)
    dialog:CreateHorizontalLine(0, y - 3, x[3] + 50)
    cstat(5, y, "Pitch examples: C4 / G#5 / Abb2", 180)
    yd(14)
    cstat(50, y, "(C4 = middle C)", 110)
    yd(22)
    dialog:CreateHorizontalLine(0, y - 6, x[3] + 50)
    dialog:CreateCheckbox(0, y, "modeless"):SetWidth(x[3] - 20)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    dialog:CreateButton(x[3] - 20, y - 1):SetText("Clear All"):SetWidth(60)
        :AddHandleCommand(function()
            for i = 1, 8 do answer[i]:SetText("") end
        end)
    -- modeless selection info
    if config.modeless then
        yd(17)
        dialog:CreateStatic(16, y, "info1"):SetText(selection.staff):SetWidth(170)
        yd(14)
        dialog:CreateStatic(16, y, "info2"):SetText(selection.region):SetWidth(170)
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
            if is_error(s) then
                user_error = true
                pitch_set[i] = s
                table.insert(errors, s)
            else
                pitch_set[i] = rewrite_pitch(s)
                if config.modeless then answer[i]:SetText(pitch_set[i]) end
            end
        end
        config.pitch_set = cjson.encode(pitch_set) -- save the bad with the good
        config.layer_num = self:GetControl("layer_num"):GetInteger()
        config.written_pitch = (self:GetControl("written_pitch"):GetCheck() == 1)
        configuration.save_user_settings(script_name, config)
        if user_error then -- errors to be flagged
            self:CreateChildUI():AlertError(
                "These pitch names are unrecognisable:\n"
                .. table.concat(errors, "; "), "Error: " .. name)
        else -- everything OK
            make_the_changes(pitch_set)
        end
    end)
    local change_mode
    dialog:RegisterCloseWindow(function(self)
        if config.modeless then self:StopTimer(config.timer_id) end
        local mode = (self:GetControl("modeless"):GetCheck() == 1)
        change_mode = (mode and not config.modeless) -- modal -> modeless?
        config.modeless = mode
        dialog_save_position(self)
    end)
    local ok = true
    if config.modeless then   -- "modeless"
        dialog:RunModeless()
    else
        ok = dialog:ExecuteModal() -- "modal"
    end
    return ok, (change_mode or user_error) -- (re-enter if modal operation)
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
    initialise_parameters()
    local ok, unfinished = true, true
    while ok and unfinished do -- loop for modal dialog
        ok, unfinished = run_the_dialog()
    end
end

change_pitches()
