function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.29"
    finaleplugin.Date = "2024/03/12"
    finaleplugin.AdditionalMenuOptions = [[
        Pitch Changer Repeat
    ]]
    finaleplugin.AdditionalUndoText = [[
        Pitch Changer Repeat
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Repeat the last pitch change without confirmation dialog
    ]]
    finaleplugin.AdditionalPrefixes = [[
        repeat_change = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.ScriptGroupName = "Pitch Changer"
    finaleplugin.ScriptGroupDescription = "Change all notes of one pitch in the region to another pitch"
    finaleplugin.Notes = [[
        This script was inspired by Jari Williamsson's _JW Change Pitches_ 
        plug-in (2017) revived to work on Macs with non-Intel processors.

        Identify __from__ and __to__ pitches by note name (__a-g__ or __A-G__) 
        followed by accidental (#-##-###, b-bb-bbb) as required. 
        Matching pitches will be changed in every octave. 
        For transposing instruments on transposing scores select 
        __Written Pitch__ to affect the pitch you see on screen. 
        To repeat the last change without a confirmation dialog use 
        the _Pitch Changer Repeat_ menu or hold down [Shift] when opening the script. 

        Select __Modeless__ if you prefer the dialog window to 
        "float" above your score so you can change the score selection 
        while it's active. In this mode, click __Apply__ [Return/Enter] 
        to make changes and __Cancel__ [Escape] to close the window. 
        Cancelling __Modeless__ will apply the _next_ time you use the script.

        > __Key Commands:__ 
 
        > - __a-g__ (__A-G__): Note Names
        > - __z__: Direction Closest 
        > - __x__: Direction Up 
        > - __v__: Direction Down 
        > - __q__: Display these script notes 
        > - __w__: Swap the __From:__ and __To:__ values 
        > - __s__: Shortcut for __#__ 
        > - __m__: Toggle the __Modeless__ setting 
        > - __r__: Toggle the __Written Pitch__ setting 
        > - __0-4__: Layer number (delete key not needed) 
	]]
    return "Pitch Changer...", "Pitch Changer", "Change all notes of one pitch in the region to another pitch"
end

repeat_change = repeat_change or false

local config = {
    find_string = "F#",
    find_pitch = "F",
    find_offset = 1, -- raise/lower value (to find)
    new_string = "eb",
    new_pitch = "E",
    new_offset = -1, -- raise/lower value (to replace)
    direction = 1, -- one-based index of "directions" choice
    layer_num = 0,
    written_pitch = false,
    timer_id    = 1,
    modeless    = false, -- false = modal / true = modeless
    window_pos_x = false,
    window_pos_y = false,
}
local directions = { "Closest (z)", "Up (x)", "Down (v)" } -- 1 / 2 / 3
local configuration = require("library.configuration")
local layer = require("library.layer")
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

local function calc_pitch_string(note)
    local pitch_string = finale.FCString()
    local cell = finale.FCCell(note.Entry.Measure, note.Entry.Staff)
    local key_signature = cell:GetKeySignature()
    note:GetString(pitch_string, key_signature, false, config.written_pitch)
    return pitch_string.LuaString
end

local function decode_note_string(str)
    local s = str:upper()
    local pitch = s:sub(1, 1)
    if s == "" or pitch:find("[^A-G]") then
        return "", 0, 0
    end
    local raise_lower = 0
    local acci = s:sub(2):gsub("S", "#")
    if acci:find("[B#S]") then
        for _ in acci:gmatch("B") do raise_lower = raise_lower - 1 end
        for _ in acci:gmatch("#") do raise_lower = raise_lower + 1 end
    end
    return pitch, raise_lower
end

local function displacement_direction(disp)
    local direction = config.direction
    if direction == 1 then -- "Closest"
        if disp < -3 then disp = disp + 7
        elseif disp > 3 then disp = disp - 7
        end
    elseif direction == 2 then -- "Up"
        if disp < 0 or (disp == 0 and config.new_offset < config.find_offset) then
            disp = disp + 7
        end
    elseif direction == 3 then -- "Down"
        if disp > 0 or (disp == 0 and config.new_offset > config.find_offset) then
            disp = disp - 7
        end
    end
    return disp
end

local function change_the_pitches()
    finenv.StartNewUndoBlock(string.format("Pitch Change %s to %s %s",
        config.find_string, config.new_string, selection.region)
    )
    local displacement = string.byte(config.new_pitch) - string.byte(config.find_pitch)
    displacement = displacement_direction(displacement) -- correct "direction" preference

    for entry in eachentrysaved(finenv.Region(), config.layer_num) do
        if entry:IsNote() then
            for note in each(entry) do
                local pitch_string = calc_pitch_string(note)
                local pitch, raise_lower = decode_note_string(pitch_string)
                if pitch == config.find_pitch and raise_lower == config.find_offset then
                    note.Displacement = note.Displacement + displacement
                    note.RaiseLower = config.new_offset
                end
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local max_layer = layer.max_layers()
    local x_pos = { 0, 47, 85, 130 }
    local m_offset = finenv.UI():IsOnMac() and 3 or 0
    local y = 0
    local name = finaleplugin.ScriptGroupName
    local pitch, errors = {}, {}
    local save_text = { find = config.find_string, new = config.new_string }

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function yd(diff) y = y + (diff or 25) end
        local function pitch_error_alert()
            dialog:CreateChildUI():AlertError(
                "Pitch names cannot be empty and must start with a single "
                .. "note name (a-g or A-G) followed by accidentals "
                .. "(#-###, b-bbb) as required.\n\n"
                .. "These pitch names are invalid:\n"
                .. table.concat(errors, "; "),
                name .. " Error"
            )
        end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 420, 415)
            refocus_document = true
        end
        local function cstat(horiz, vert, wide, str, id)
            dialog:CreateStatic(horiz, vert, id):SetWidth(wide):SetText(str)
        end
        local function value_swap()
            pitch.new:SetText(save_text.find)
            pitch.find:SetText(save_text.new)
            save_text.find = save_text.new
            save_text.new = pitch.new:GetText()
        end
        local function toggle_check(id)
            local m = dialog:GetControl(id)
            m:SetCheck((m:GetCheck() + 1) % 2)
        end
        local function key_substitutions(kind)
            local t = pitch[kind]:GetText()
            local s = t:upper()
            if (kind == "layer" and s:find("[^0-4]"))
              or (kind ~= "layer" and s:find("[^A-G#]")) then
                -- key substitutions:
                if      s:find("Z") then pitch.popup:SetSelectedItem(0) -- closest
                elseif  s:find("X") then pitch.popup:SetSelectedItem(1) -- up
                elseif  s:find("V") then pitch.popup:SetSelectedItem(2) -- down
                elseif  s:find("S") and kind ~= "layer" then
                    save_text[kind] = s:gsub("S", "#") -- substitute "#"
                elseif  s:find("W") then value_swap()
                elseif  s:find("[?Q]") then show_info()
                elseif s:find("M") then toggle_check("modeless")
                elseif s:find("R") then toggle_check("written_pitch")
                end
                if kind == "layer" or not s:find("W") then
                    pitch[kind]:SetText(save_text[kind])
                end
            elseif s ~= "" then
                s = (kind == "layer") and s:sub(-1) or (s:sub(1, 1) .. t:sub(2))
                save_text[kind] = s
                pitch[kind]:SetText(s)
            end
        end
        local function encode_pitches(kind)
            local s = pitch[kind]:GetText()
            local note, raise_lower = decode_note_string(s)
            if note == "" or s:sub(2):upper():find("[^B#S]") then -- pitch name error
                table.insert(errors, s) -- add error to list
                return false -- flag user input error
            end
            config[kind .. "_pitch"] = note
            config[kind .. "_offset"] = raise_lower
            config[kind .. "_string"] = s
            pitch[kind]:SetText(note .. s:sub(2))
            save_text[kind] = note .. s:sub(2)
            return true
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
    cstat(x_pos[1], y, 50, "From:", "from")
    cstat(x_pos[3], y, 50, "To:", "to")
    cstat(x_pos[4], y, 60, "Direction:", "direction")
    yd(20)
    pitch.find = dialog:CreateEdit(x_pos[1], y - m_offset):SetWidth(40):SetText(config.find_string)
        :AddHandleCommand(function() key_substitutions("find") end)
    dialog:CreateButton(x_pos[2], y):SetText("←→"):SetWidth(30)
        :AddHandleCommand(function() value_swap() end)
    pitch.new  = dialog:CreateEdit(x_pos[3], y - m_offset):SetWidth(40):SetText(config.new_string)
        :AddHandleCommand(function() key_substitutions("new") end)
    pitch.popup = dialog:CreatePopup(x_pos[4], y):SetWidth(80)
    for _, v in ipairs(directions) do
        pitch.popup:AddString(v)
    end
    pitch.popup:SetSelectedItem(config.direction - 1) -- 0-based index configure value
    yd()
    cstat(0, y, 60, "Layer 0-" .. max_layer .. ":")
    save_text.layer = tostring(config.layer_num)
    pitch.layer = dialog:CreateEdit(60, y - m_offset):SetWidth(20):SetText(config.layer_num)
        :AddHandleCommand(function() key_substitutions("layer") end)
    dialog:CreateCheckbox(x_pos[3] + 12, y, "written_pitch"):SetWidth(85)
        :SetCheck(config.written_pitch and 1 or 0):SetText("Written Pitch")
    dialog:CreateButton(x_pos[4] + 60, y, "q"):SetText("?"):SetWidth(20)
       :AddHandleCommand(function() show_info() end)
    yd()
    dialog:CreateCheckbox(0, y, "modeless"):SetWidth(x_pos[4] + 80)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    -- modeless selection info
    if config.modeless then
        yd(14)
        dialog:CreateStatic(16, y, "info1"):SetText(selection.staff):SetWidth(x_pos[4] + 65)
        yd(14)
        dialog:CreateStatic(16, y, "info2"):SetText(selection.region):SetWidth(x_pos[4] + 65)
    end
    -- wrap it up
    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "Change")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:SetOkButtonCanClose(not config.modeless)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
        local f = self:GetControl("from")
        local bold = f:CreateFontInfo():SetBold(true)
        f:SetFont(bold)
        self:GetControl("to"):SetFont(bold)
        self:GetControl("direction"):SetFont(bold)
        pitch.find:SetKeyboardFocus()
    end)
    local change_mode, user_error = false, false
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterHandleOkButtonPressed(function(self)
        errors = {} -- empty error list
        local good_name1, good_name2 = encode_pitches("find"), encode_pitches("new")
        if good_name1 and good_name2 then -- no pitch name errors
            config.layer_num = pitch.layer:GetInteger()
            config.direction = pitch.popup:GetSelectedItem() + 1 -- one-based index
            config.modeless = (self:GetControl("modeless"):GetCheck() == 1)
            config.written_pitch = (self:GetControl("written_pitch"):GetCheck() == 1)
            change_the_pitches()
        else
            pitch_error_alert()
            user_error = true
        end
    end)
    dialog:RegisterCloseWindow(function(self)
        if config.modeless then self:StopTimer(config.timer_id) end
        local mode = (self:GetControl("modeless"):GetCheck() == 1)
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
    return change_mode or user_error -- something still to change
end

local function change_pitch()
    configuration.get_user_settings(script_name, config, true)
    if not config.modeless and finenv.Region():IsEmpty() then
        finenv.UI():AlertError(
            "Please select some music\nbefore running this script.",
            finaleplugin.ScriptGroupName
        )
        return
    end
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    initialise_parameters()
    if mod_key or repeat_change then
        change_the_pitches()
    else
        local unfinished = true
        while unfinished do
            unfinished = run_the_dialog()
        end
    end
end

change_pitch()
