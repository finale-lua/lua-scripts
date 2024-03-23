function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.32"
    finaleplugin.Date = "2024/03/23"
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
        This script revives Jari Williamsson's _JW Change Pitches_ 
        2017 plug-in to work on Macs with non-Intel processors.

        Identify __from__ and __to__ pitches by note name (__a-g__ or __A-G__) 
        followed by accidental (#-##-###, b-bb-bbb) as required. 
        Matching pitches will be changed in every octave. 
        For transposing instruments on transposing scores select 
        __Written Pitch__ to affect the pitch you see on screen. 
        To repeat the last change without a confirmation dialog use 
        the _Pitch Changer Repeat_ menu or hold down [Shift] when opening the script. 

        Select __Modeless__ if you prefer the dialog window to 
        "float" above your score so you can change the score selection 
        while it remains active. In this mode, click __Apply__ [Return/Enter] 
        to make changes and __Cancel__ [Escape] to close the window. 
        Cancelling __Modeless__ will apply the _next_ time you use the script.

        > __Key Commands:__ 

        > - __a-g__ (__A-G__): Note Names
        > - __0-4__: Layer number (delete key not needed)
        > - __z__: Direction Closest 
        > - __x__: Direction Up 
        > - __v__: Direction Down  
        > - __w__: Swap the __From:__ and __To:__ values 
        > - __s__: Shortcut for __#__ 
        > - __m__: Toggle the __Modeless__ setting 
        > - __r__: Toggle the __Written Pitch__ setting 
        > - __q__: Display these script notes 
	]]
    return "Pitch Changer...", "Pitch Changer", "Change all notes of one pitch in the region to another pitch"
end

repeat_change = repeat_change or false

local config = {
    find_string = "F#", -- find this note
    find_pitch = "F", -- its pitch name
    find_offset = 1, -- its raise/lower value
    new_string = "Eb", -- replace with this note
    new_pitch = "E", -- its pitch name
    new_offset = -1, -- its raise/lower value
    direction = 1, -- one-based index of "direction" name [Closest/Up/Down]
    layer_num = 0,
    written_pitch = false,
    timer_id    = 1,
    modeless    = false, -- false = modal / true = modeless
    window_pos_x = false,
    window_pos_y = false,
}

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
local directions = { "Closest (z)", "Up (x)", "Down (v)" } -- 1 / 2 / 3

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

local function decode_note_string(str)
    local pitch = str:upper():sub(1, 1)
    local acci = str:sub(2):lower():gsub("s", "#")
    if str == "" or pitch:find("[^A-G]") or
        (acci:find("[^b#]") or (acci:find("b") and acci:find("#"))) then
            return "", 0
    end
    local raise_lower = 0 -- count flats and sharps
    for _ in acci:gmatch("b") do raise_lower = raise_lower - 1 end
    for _ in acci:gmatch("#") do raise_lower = raise_lower + 1 end
    return pitch, raise_lower
end

local function octave_direction()
    local find = string.byte(config.find_pitch) - 67 -- "A" = -2, "C" = 0
    local new = string.byte(config.new_pitch) - 67
    local find_off, new_off = config.find_offset, config.new_offset
    local oct = 0 -- octave change

    if config.direction == 1 then -- "Closest"
        if ((find - new) > 3 and (new_off < 0)) then
            oct = 1
        elseif ((new - find) > 3 and (find_off < 0)) then
            oct = -1
        end
    elseif config.direction == 2 then -- "Up"
        if  (find < 0 and new > 0) or -- octave jumps around C
            (new < find and (find < 0 or new >= 0)) or
            (new == find and new_off < find_off) then
            oct = 1 -- shift up octave
        end
    else -- config.direction == 3 -- "Down"
        if  (new < 0 and find > 0) or
            (new > find and (find >= 0 or new < 0)) or
            (new == find and new_off > find_off) then
            oct = -1 -- shift down octave
        end
    end
    return oct
end

local function change_the_pitches()
    finenv.StartNewUndoBlock(
        string.format("Pitch Change %s to %s %s",
            config.find_string, config.new_string, selection.region)
    )
    local octave_change = octave_direction() -- get "direction" octave choice
    local s = finale.FCString()

    for entry in eachentrysaved(finenv.Region(), config.layer_num) do
        local key_sig = finale.FCCell(entry.Measure, entry.Staff):GetKeySignature()
        if entry:IsNote() then
            for note in each(entry) do
                note:GetString(s, key_sig, false, config.written_pitch)
                local pitch_string = s.LuaString
                local octave = pitch_string:sub(-1)
                if config.find_string == pitch_string:sub(1, -2) then
                    s.LuaString = config.new_string .. (octave + octave_change)
                    note:SetString(s, key_sig, config.written_pitch)
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
    local pitch, ctl, errors = {}, {}, {}
    local save_text = { find = config.find_string, new = config.new_string }

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function yd(diff) y = y + (diff or 25) end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 420, 430)
            refocus_document = true
        end
        local function cstat(horiz, vert, wide, str) -- dialog static text
            return dialog:CreateStatic(horiz, vert):SetWidth(wide):SetText(str)
        end
        local function value_swap()
            pitch.new:SetText(save_text.find)
            pitch.find:SetText(save_text.new)
            save_text.find = save_text.new
            save_text.new = pitch.new:GetText()
        end
        local function toggle_check(id)
            ctl[id]:SetCheck((ctl[id]:GetCheck() + 1) % 2)
        end
        local function key_substitutions(kind)
            local s = pitch[kind]:GetText():upper()
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
            else
                s = (kind == "layer") and s:sub(-1) or (s:sub(1, 1) .. s:sub(2):lower())
                save_text[kind] = s
                pitch[kind]:SetText(s)
            end
        end
        local function encode_pitches(kind)
            local s = pitch[kind]:GetText()
            local note, raise_lower = decode_note_string(s)
            if note == "" then -- pitch name error
                table.insert(errors, s) -- add error to list
                return false -- flag user input error
            end
            config[kind .. "_pitch"] = note
            config[kind .. "_offset"] = raise_lower
            config[kind .. "_string"] = s
            pitch[kind]:SetText(s)
            save_text[kind] = s
            return true -- no errors
        end
        local function on_timer() -- track changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    track_selection() -- update selection tracker
                    ctl.info1:SetText(selection.staff)
                    ctl.info2:SetText(selection.region)
                    break -- all done
                end
            end
        end
    ctl.from = cstat(x_pos[1], y, 50, "From:")
    ctl.to = cstat(x_pos[3], y, 50, "To:")
    ctl.direction = cstat(x_pos[4], y, 60, "Direction:")
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
    ctl.written_pitch = dialog:CreateCheckbox(x_pos[3] + 12, y):SetWidth(85)
        :SetCheck(config.written_pitch and 1 or 0):SetText("Written Pitch")
    ctl.q = dialog:CreateButton(x_pos[4] + 60, y):SetText("?"):SetWidth(20)
       :AddHandleCommand(function() show_info() end)
    yd()
    ctl.modeless = dialog:CreateCheckbox(0, y):SetWidth(x_pos[4] + 80)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    -- modeless selection info
    if config.modeless then
        yd(14)
        ctl.info1 = dialog:CreateStatic(16, y):SetText(selection.staff):SetWidth(x_pos[4] + 65)
        yd(14)
        ctl.info2 = dialog:CreateStatic(16, y):SetText(selection.region):SetWidth(x_pos[4] + 65)
    end
    -- wrap it up
    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "Change")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:SetOkButtonCanClose(not config.modeless)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
        local bold = ctl.from:CreateFontInfo():SetBold(true)
        ctl.from:SetFont(bold)
        ctl.to:SetFont(bold)
        ctl.direction:SetFont(bold)
        pitch.find:SetKeyboardFocus()
    end)
    local change_mode, user_error = false, false
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterHandleOkButtonPressed(function()
        errors = {} -- empty error list
        local good_name1, good_name2 = encode_pitches("find"), encode_pitches("new")
        if good_name1 and good_name2 then -- no pitch name errors
            config.layer_num = pitch.layer:GetInteger()
            config.direction = pitch.popup:GetSelectedItem() + 1 -- one-based index
            config.written_pitch = (ctl.written_pitch:GetCheck() == 1)
            change_the_pitches()
        else
            dialog:CreateChildUI():AlertError( -- **ERROR!**
                "Pitch names cannot be empty and must start with a single "
                .. "note name (a-g or A-G) followed by accidentals "
                .. "(#-###, b-bbb) as required.\n\n"
                .. "These pitch names are invalid:\n"
                .. table.concat(errors, "; "),
                name .. " Error"
            )
            user_error = true
        end
    end)
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
        dialog:ExecuteModal()
        if refocus_document then finenv.UI():ActivateDocumentWindow() end
    end
    return (change_mode or user_error) -- something still to change
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

    track_selection() -- track current selected region
    if mod_key or repeat_change then
        change_the_pitches()
    else
        while run_the_dialog() do end
    end
end

change_pitch()
