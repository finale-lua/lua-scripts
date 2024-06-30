function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.18"
    finaleplugin.Date = "2024/06/30"
    finaleplugin.CategoryTags = "Entries, Pitch, Transposition"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = [[
        Change one specific pitch to another. 
        Pitch specification is precise and immutable: 

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
    ]]
    return "Pitch Singles Changer...",
        "Pitch Singles Changer",
        "Change one specific pitch to another"
end

local hotkey = { -- (uppercase only)
    written_pitch = "W",
    show_info     = "Q",
}
local config = {
    pitch_set = '["C4", "C5"]', -- JSON encoded pitch replacement set
    layer_num   = 0,
    timer_id    = 1,
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
local name = plugindef():gsub("%.%.%.", "")
local selection
local saved_bounds = {}
local naming_rules = [[
PITCH NAME RULES:
• First character: note name A-G  
(uppercase applied automatically)  
• Last character: octave number 0-9  
• In between: accidentals if any
(b/bb/bbb ... #/##/###)  
(you can use s instead of #)
]]
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

local function get_staff_name(staff_num)
    local staff = finale.FCStaff()
    staff:Load(staff_num)
    local str = staff:CreateDisplayAbbreviatedNameString().LuaString
    if not str or str == "" then
        str = "Staff" .. staff_num
    end
    return str
end

local function track_selection()
    local bounds = { -- primary region selection boundaries
        "StartStaff", "StartMeasure", "StartMeasurePos",
        "EndStaff",   "EndMeasure",   "EndMeasurePos",
    }
    local rgn = finenv.Region()
    for _, property in ipairs(bounds) do
        saved_bounds[property] = rgn[property]
    end
    -- update selection
    selection = "no staff, no selection" -- default
    if not rgn:IsEmpty() then
        selection = get_staff_name(rgn.StartStaff)
        if rgn.EndStaff ~= rgn.StartStaff then
            selection = selection .. "-" .. get_staff_name(rgn.EndStaff)
        end
        selection = selection .. " m." .. rgn.StartMeasure
        if rgn.StartMeasure ~= rgn.EndMeasure then
            selection = selection .. "-" .. rgn.EndMeasure
        end
    end
end

local function extract_pitch(test)
    local p = tostring(test)
    if not p or p == "" then return "", "", "" end
    return p:sub(1, 1):upper(), p:sub(2, -2):lower():gsub("s", "#"), p:sub(-1)
end

local function rewrite_pitch(p)
    local a, b, c = extract_pitch(p)
    return a .. b .. c
end

local function is_error(test)
    local p = tostring(test)
    if test == nil or p == "" then return true end
    local a, b, c = extract_pitch(p)
    if      a:find("[^A-G]") or c:find("[^0-9]") or p:find("%d") < p:len()
        or  b:find("[^b#]") or  (b:find("b") and b:find("#")) then
        return true
    end
    return false
end

local function make_the_changes(dialog)
    if finenv.Region():IsEmpty() then
        local ui = dialog and dialog:CreateChildUI() or finenv.UI()
        ui:AlertError("Please select some music\nbefore running this script", name)
        return
    end
    local pitches = cjson.decode(config.pitch_set)
    finenv.StartNewUndoBlock(string.format("Pitch Change %s %s-%s", selection, pitches[1], pitches[2]))
    local pitch_str = finale.FCString()
    local measure, staff, keysig = 0, 0, nil

    for entry in eachentrysaved(finenv.Region(), config.layer_num) do
        local e_m, e_s = entry.Measure, entry.Staff
        if measure ~= e_m and staff ~= e_s then
            measure = e_m
            staff = e_s
            keysig = finale.FCCell(e_m, e_s):GetKeySignature()
        end
        for note in each(entry) do
            note:GetString(pitch_str, keysig, false, config.written_pitch)
            local a, b = pitches[1], pitches[2]
            if pitch_str.LuaString == a  and a ~= "" and b~= "" then
                pitch_str.LuaString = b
                note:SetString(pitch_str, keysig, config.written_pitch)
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local y, y_diff = 0, 16
    local x = { 81, 128, 150 }
    local answer, ctl, save = {}, {}, {}
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
                    dialog:GetControl("info"):SetText(selection)
                    break -- all done
                end
            end
        end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 400, 200)
        end
        local function key_substitutions(id)
            local s = answer[id]:GetText():upper()
            if (id == 0 and s:find("[^0-4]"))
              or (id > 0 and s:find("[^#SA-G0-9]")) then
                if s:find(hotkey.written_pitch) then
                    local ch = ctl.written_pitch
                    ch:SetCheck((ch:GetCheck() + 1) % 2)
                elseif s:find(hotkey.show_info) then show_info()
                end
            else
                save[id] = (id == 0) and s:sub(-1) -- layer number
                    or (s:sub(1, 1) .. s:sub(2):lower():gsub("s", "#"))
            end
            answer[id]:SetText(save[id])
        end
    local pitches = cjson.decode(config.pitch_set)
    cstat(0, y, "Change From:", 100)
    save[1] = pitches[1]
    answer[1] = cedit(x[1], y, save[1], 45)
    answer[1]:AddHandleCommand(function() key_substitutions(1) end)
    cstat(x[2], y, "To:", 20)
    save[2] = pitches[2]
    answer[2] = cedit(x[3], y, save[2], 45)
    answer[2]:AddHandleCommand(function() key_substitutions(2) end)
    yd(25)
    --
    cstat(0, y, "Layer (0-4):", 78)
    answer[3] = cedit(x[1] - 11, y, config.layer_num, 20)
    answer[3]:AddHandleCommand(function() key_substitutions(3) end)
    ctl.written_pitch = dialog:CreateCheckbox(x[1] + 30, y):SetWidth(85)
        :SetCheck(config.written_pitch and 1 or 0):SetText("Written Pitch")
    yd(22)
    dialog:CreateHorizontalLine(0, y - 3, x[3] + 50)
    cstat(0, y, "Pitch examples: C4 / G#5 / Abb2", 180)
    yd()
    cstat(0, y, "(C4 = middle C)", 110)
    ctl.q = dialog:CreateButton(x[3] + 25, y - 3):SetWidth(20):SetText("?")
        :AddHandleCommand(function() show_info() end)
    yd()
    cstat(0, y, "Selected:", 54)
    cstat(54, y, selection, x[3] - 4, "info")

    dialog:CreateOkButton():SetText("Apply")
    dialog:CreateCancelButton():SetText("Close")
    dialog_set_position(dialog)
    dialog:RegisterHandleTimer(on_timer)
    dialog:RegisterInitWindow(function(self)
        ctl.q:SetFont(ctl.q:CreateFontInfo():SetBold(true))
        self:SetTimer(config.timer_id, 125)
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        local errors = {}
        for i = 1, 2 do
            local s = answer[i]:GetText()
            if s == "" or is_error(s) then
                pitches[i] = s
                table.insert(errors, (s ~= "" and s or "(blank entry)"))
            else
                pitches[i] = rewrite_pitch(s)
                answer[i]:SetText(pitches[i])
            end
        end
        config.pitch_set = cjson.encode(pitches) -- save the bad with the good
        config.layer_num = answer[3]:GetInteger()
        config.written_pitch = (ctl.written_pitch:GetCheck() == 1)
        if #errors > 0 then -- errors flagged
            local msg = (#errors > 1) and
                "These pitch names are invalid:\n"
                or "This pitch name is invalid:\n"
            msg = msg .. table.concat(errors, " / ") .. "\n\n" .. naming_rules
            dialog:CreateChildUI():AlertError(msg, "Error: " .. name)
        else -- everything OK
            make_the_changes(dialog)
        end
    end)
    dialog:RegisterCloseWindow(function(self)
        self:StopTimer(config.timer_id)
        dialog_save_position(self)
    end)
    dialog:RunModeless()
end

local function change_pitches()
    configuration.get_user_settings(script_name, config, true)
    track_selection()
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if mod_key then
        make_the_changes(nil)
    else
        while run_the_dialog() do end
    end
end

change_pitches()
