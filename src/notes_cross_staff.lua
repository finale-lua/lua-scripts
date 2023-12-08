function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.51"
    finaleplugin.Date = "2023/12/03"
    finaleplugin.AdditionalMenuOptions = [[
        Notes Cross-Staff Up
        Notes Cross-Staff Configuration...
    ]]
    finaleplugin.AdditionalUndoText = [[
        Notes Cross-Staff Up
        Notes Cross-Staff Configuration
    ]]
    finaleplugin.AdditionalPrefixes = [[
        direction = "Up"
        direction = "Configuration"
    ]]
    finaleplugin.AdditionalDescriptions = [[ 
        Selected notes are cross-staffed to the next higher staff
        Set the horizontal offsets and active layer that will be applied to cross-staffed notes
    ]]
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.ScriptGroupName = "Notes Cross-Staff"
    finaleplugin.ScriptGroupDescription = "Selected notes are cross-staffed to the next staff above or below the selection"
	finaleplugin.Notes = [[ 
        Selected notes are "crossed" to the next staff above or below the selection. 
        This duplicates Finale's inbuilt ALT (option) up/down arrow 
        shortcuts for cross-staff entries, but in my 
        experience these malfunction at random. 
        This script doesn't, but also offers filtering by layer, optional 
        stem reversal and horizontal note shift to counteract stem reversal. 
        Tobias Giesen's TGTools -> Cross Staff is great for 
        more complex tasks, but this is slicker for simple ones 
        than the inbuilt shortcuts (and has more options).  

        To change options use the "Notes Cross-Staff Configuration..." 
        menu or hold down the SHIFT key when starting the script. 
        When crossing with stem reversal to the staff ABOVE try 
        EVPU offsets of 12 (crossed) and -12 (not crossed), or 24/0. 
        Crossing to the staff BELOW try offsets of -12/12 or -24/0 EVPUs. 

        By default only notes within the selection or part of the 
        beam groups it contains will be shifted horizontally. 
        Select "whole measure" (g) to shift every note in the selected measure.  

        Key Commands (in the Configuration window):  
        [d] [f] [g] [h] toggle the checkboxes  
        [z] reset to default values  
        [q] display these notes  
        To change measurement units type:  
        [e] EVPUs  [i] Inches [c] Centimeters  
        [o] Points [a] Picas  [s] Spaces  
        Layer number:  
        [0]-[4] (delete key not needed)
	]]
    return "Notes Cross-Staff Down", "Notes Cross-Staff Down", "Selected notes are cross-staffed to the next lower staff"
end

local info_notes = [[
Selected notes are "crossed" to the next staff above or below the selection. 
This duplicates Finale's inbuilt ALT (option) up/down arrow 
shortcuts for cross-staff entries, but in my 
experience these malfunction at random. 
This script doesn't, but also offers filtering by layer, optional 
stem reversal and horizontal note shift to counteract stem reversal. 
Tobias Giesen's TGTools -> Cross Staff is great for 
more complex tasks, but this is slicker for simple ones 
than the inbuilt shortcuts (and has more options).  
]] .. "\n" .. [[
To change options use the "Notes Cross-Staff Configuration..." 
menu or hold down the SHIFT key when starting the script. 
When crossing with stem reversal to the staff ABOVE try 
EVPU offsets of 12 (crossed) and -12 (not crossed), or 24/0. 
Crossing to the staff BELOW try offsets of -12/12 or -24/0 EVPUs. 
]] .. "\n" .. [[
By default only notes within the selection or part of the 
beam groups it contains will be shifted horizontally. 
Select "whole measure" (g) to shift every note in the selected measure.  
]] .. "\n" .. [[
Key Commands (in the Configuration window):  
[d] [f] [g] [h] toggle the checkboxes  
[z] reset to default values  
[q] display these notes  
To change measurement units type:  
[e] EVPUs  [i] Inches [c] Centimeters  
[o] Points [a] Picas  [s] Spaces  
Layer number:  
[0]-[4] (delete key not needed)
]]
info_notes = info_notes:gsub("  \n",  "\n"):gsub(" %s+", " "):gsub("\n ", "\n")

direction = direction or "Down"
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local measurement = require("library.measurement")
local script_name = "notes_cross_staff"

local config = {
    Up_Crossed = 12,
    Up_Uncrossed = -12,
    Down_Crossed = -12,
    Down_Uncrossed = 12,
    no_reverse    = false, -- true to prevent stem reversal
    not_unbeamed  = false, -- true to prevent crossing unbeamed notes
    no_shift      = false, -- true to prevent horizontal offsets
    whole_measure  = true,  -- horizontal shift across whole measure
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    layer_num     = 0,
    window_pos_x  = false,
    window_pos_y  = false,
}

local offsets = { -- name, default value (ordered)
    { "Up_Crossed",     12 },
    { "Up_Uncrossed",  -12 },
    { "Down_Crossed",  -12 },
    { "Down_Uncrossed", 12 },
}
local checks = { -- name, text description (ordered)
    {"no_reverse", "Don't reverse note stems (d)" },
    {"not_unbeamed", "Don't cross unbeamed notes (f)" },
    {"whole_measure", "Shift horizontals across whole measure (g)" },
    {"no_shift", "No horizontal shift (h)" },
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

local function next_staff_or_error(rgn)
    local next_staff = -1 -- (assume error condition)
    local msg = ""
    local stack = mixin.FCMMusicRegion()
    stack:SetRegion(rgn):SetFullMeasureStack()
    local next_slot = rgn.StartSlot

    if rgn:IsEmpty() then
        msg = "Please select some music \nbefore running this script"
    elseif rgn.StartStaff ~= rgn.EndStaff then
        msg = "This script will only work \non a selection from one staff"
    else
        if direction == "Down" then
            next_slot = next_slot + 1
            if next_slot > stack.EndSlot then msg = "below" end
        else -- direction == "Up"
            next_slot = next_slot - 1
            if next_slot < 1 then msg = "above" end
        end
        if msg ~= "" then
            msg = "You can't cross notes to the staff " .. msg
                .. " because there is no staff " .. msg .. " the selected music."
        end
    end
    if msg ~= "" then
        finenv.UI():AlertError(msg, finaleplugin.ScriptGroupName .. ": Error")
    else
        next_staff = stack:CalcStaffNumber(next_slot)
    end
    return next_staff
end

local function cross_staff(next_staff, rgn)
    local beam_groups = {}

    for entry in eachentrysaved(rgn, config.layer_num) do
        if entry:IsNote() then -- cross it?
            local unbeamed = entry:CalcUnbeamedNote()
            if unbeamed and (config.not_unbeamed) then
                if not config.no_shift then -- unbeamed/excluded = not crossed
                    entry.ManualPosition = config[direction .. "_Uncrossed"]
                end
                entry.FreezeStem = false
            else -- beamed plus eligible unbeamed
                local cross_mod = finale.FCCrossStaffMod()
                cross_mod:SetNoteEntry(entry)
                local loaded = cross_mod:LoadFirst()
                cross_mod.Staff = next_staff
                for note in each(entry) do
                    cross_mod:SaveAt(note)
                end
                local _ = loaded and cross_mod:Save() or cross_mod:SaveNew()
                if not config.no_shift then
                    entry.ManualPosition = config[direction .. "_Crossed"]
                end
                if not unbeamed then -- reverse/stem direction?
                    if not config.no_reverse then
                        entry["Reverse" .. direction .. "Stem"] = true
                    end
                    entry.StemUp = (direction == "Up")
                    entry.FreezeStem = true
                end
            end

            if not (unbeamed or config.no_shift or config.whole_measure) then
                -- BEAMED: assemble the whole beam group
                local beam_start_entry = entry:CalcBeamStartEntry()
                if beam_start_entry ~= nil then
                    local start_number = beam_start_entry.EntryNumber
                    if beam_groups[start_number] == nil then -- NEW beam group
                        local next_entry = entry:Next()
                        local end_of_selection = (next_entry == nil) or (not rgn:IsEntryPosWithin(next_entry))
                        local end_of_group = entry:CalcBeamedGroupEnd()
                        --
                        if end_of_group or end_of_selection then
                            beam_groups[start_number] = {
                                StartStaff = entry.Staff,
                                EndStaff = entry.Staff,
                                StartMeasure = beam_start_entry.Measure,
                                EndMeasure = entry.Measure,
                                StartMeasurePos = beam_start_entry.MeasurePos,
                                EndMeasurePos = entry.MeasurePos
                            }
                        end
                        if end_of_selection and not end_of_group then -- more notes to come on the beam
                            local new_entry = entry
                            while new_entry and not new_entry:CalcUnbeamedNote() do
                                new_entry = new_entry:Next()
                                if new_entry and new_entry:CalcBeamedGroupEnd() then
                                    if new_entry and beam_groups[start_number] then
                                        beam_groups[start_number].EndMeasure = new_entry.Measure
                                        beam_groups[start_number].EndMeasurePos = new_entry.MeasurePos
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if not config.no_shift then -- adjust position of uncrossed entries
        if config.whole_measure then -- whole measure
            local whole_measure = mixin.FCMMusicRegion()
            whole_measure:SetRegion(rgn):SetStartMeasurePosLeft():SetEndMeasurePosRight()
            for entry in eachentrysaved(whole_measure, config.layer_num) do
                local crossing = entry.CrossStaff and "_Crossed" or "_Uncrossed"
                entry.ManualPosition = config[direction .. crossing]
            end
        elseif beam_groups ~= {} then -- just over beamed groups
            local beam_region = mixin.FCMMusicRegion()
            beam_region:SetRegion(rgn)
            for _, group in pairs(beam_groups) do
                for key, value in pairs(group) do
                    beam_region[key] = value -- copy beamed group boundary to region
                end
                for entry in eachentrysaved(beam_region, config.layer_num) do
                    if (entry.Staff == rgn.StartStaff) and (not entry.CrossStaff) then
                        entry.ManualPosition = config[direction .. "_Uncrossed"]
                    end
                end
            end
        end
    end
end

local function configuration_dialog()
    local max = layer.max_layers()
    local x = { 0, 140, 210, 245, 110, 260 }
    local units = { -- map keystrokes onto Measurement Unit ENUMs
        e = finale.MEASUREMENTUNIT_EVPUS,       i = finale.MEASUREMENTUNIT_INCHES,
        c = finale.MEASUREMENTUNIT_CENTIMETERS, o = finale.MEASUREMENTUNIT_POINTS,
        a = finale.MEASUREMENTUNIT_PICAS,       s = finale.MEASUREMENTUNIT_SPACES,
    }
    local answer, save_value = {}, {} -- "Edit" controls / saved "text" values
    local function show_info()
        finenv.UI():AlertInfo(info_notes, "About " .. finaleplugin.ScriptGroupName)
    end
    -- --
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle(finaleplugin.ScriptGroupName .. " Configuration")
    local y = 0
    dialog:SetMeasurementUnit(config.measurement_unit)

        local function dy(diff)
            y = diff and (y + diff) or (y + 25)
        end
        local function cstat(cx, cy, ctext, cwide, chigh)
            local stat = dialog:CreateStatic(cx, cy):SetText(ctext)
            if cwide then stat:SetWidth(cwide) end
            if chigh then stat:SetHeight(chigh) end
        end
        local function toggle(id)
            answer[id]:SetCheck((answer[id]:GetCheck() + 1) % 2)
        end
        local function toggle_offset_disable()
            local off = (answer.no_shift:GetCheck() == 0)
            for i = 1, 4 do answer[offsets[i][1]]:SetEnable(off) end
            answer[off and "Up_Crossed" or "layer_num"]:SetKeyboardFocus()
        end
        local function update_saved()
            for _, v in ipairs(offsets) do
                save_value[v[1]] = answer[v[1]]:GetText()
            end
        end
        local function set_default_values()
            for _, v in ipairs(offsets) do
                answer[v[1]]:SetMeasurementInteger(v[2])
            end
            update_saved()
        end
        local function key_check(id)
            local ctl = answer[id]
            local s = ctl:GetText():lower()
            if (    (s:find("p") and dialog:GetMeasurementUnit() ~= finale.MEASUREMENTUNIT_PICAS)
                    or s:find("[^-.p0-9]")
                    or (id == "layer_num" and s:find("[-.p5-9]"))
                )   then
                local test = "dfghq?z"
                if s:find("[" .. test .. "]") then
                    for i = 1, test:len() do -- check each test character
                        if s:find(test:sub(i, i)) then
                            if i <= 4 then
                                toggle(checks[i][1])
                                if i == 3 then
                                    answer.no_shift:SetCheck(0)
                                    toggle_offset_disable()
                                elseif i == 4 then
                                    answer.whole_measure:SetCheck(0)
                                    toggle_offset_disable()
                                end
                            elseif i == 5 or i == 6 then show_info()
                            elseif i == 7 then set_default_values()
                            end
                            break
                        end
                    end
                elseif s:find("[eicoas]") then -- change UNIT hotkeys
                    for k, v in pairs(units) do
                        if s:find(k) then
                            ctl:SetText(save_value[id])
                            dialog:SetMeasurementUnit(v) -- change UNIT
                            answer.popup:UpdateMeasurementUnit()
                            update_saved()
                            break
                        end
                    end
                end
                ctl:SetText(save_value[id])
            elseif s ~= "" then
                if id == "layer_num" then
                    s = s:sub(-1) -- one char only
                else
                    if s == "." then s = "0." -- leading zero
                    elseif s == "-." then s = "-0."
                    end
                end
                ctl:SetText(s)
                save_value[id] = s
            end
        end

    cstat(x[1], y, "HORIZONTAL ENTRY OFFSETS", 170)
    local y_off = finenv.UI():IsOnMac() and 3 or 0 -- y-offset for Mac edit box
    answer.popup = dialog:CreateMeasurementUnitPopup(x[3] - 26, y - 1):SetWidth(90)
        :AddHandleCommand(function() update_saved() end)
    dy()
    cstat(x[2], y, "Crossed", 70)
    cstat(x[3] - 4, y, "Not Crossed", 70)
    dy(20)
    cstat(20, y, "Cross to staff above:", x[2])

    for i, v in ipairs(offsets) do -- OFFSET MEASUREMENTS
        if i == 3 then y = y + 25 end
        local x_pos = (i % 2 == 1) and x[2] or x[3]
        answer[v[1]] = dialog:CreateMeasurementEdit(x_pos, y - y_off):SetWidth(64)
            :SetMeasurementInteger(config[v[1]])
            :AddHandleCommand(function() key_check(v[1]) end)
    end
    update_saved()
    cstat(20, y, "Cross to staff below:", x[2])
    dy(30)
    cstat(x[1], y, "Layer 1-" .. max .. ":", x[4])
    answer.layer_num = dialog:CreateEdit(60, y - y_off):SetText(config.layer_num)
        :AddHandleCommand(function() key_check("layer_num") end):SetWidth(20)
    save_value.layer_num = config.layer_num
    cstat(82, y, "(0 = all)", x[2])

    dialog:CreateButton(x[2], y):SetText("default values (z)"):SetWidth(105)
        :AddHandleCommand(function() set_default_values() end)
    dialog:CreateButton(x[3] + 44, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dy(20)
    for _, v in ipairs(checks) do -- CHECKBOXES
        answer[v[1]] = dialog:CreateCheckbox(20, y):SetText(v[2]):SetWidth(x[6])
            :SetCheck(config[v[1]] and 1 or 0)
        dy(18)
    end
    answer.whole_measure:AddHandleCommand(function()
            answer.no_shift:SetCheck(0)
            toggle_offset_disable()
        end)
    answer.no_shift:AddHandleCommand(function()
            answer.whole_measure:SetCheck(0)
            toggle_offset_disable()
        end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() toggle_offset_disable() end)
    dialog:RegisterHandleOkButtonPressed(function(self)
            for _, v in ipairs(offsets) do -- Offset Measurements
                config[v[1]] = answer[v[1]]:GetMeasurementInteger()
            end
            for _, v in ipairs(checks) do -- CheckBoxes
                config[v[1]] = (answer[v[1]]:GetCheck() == 1)
            end
            config.layer_num = answer.layer_num:GetInteger()
            config.measurement_unit = self:GetMeasurementUnit()
        end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function input_error()
    if not config.no_shift then -- offsets matter
        local max_evpu = 576 -- who would want more than 2 inches?
        local m_unit = config.measurement_unit
        local u_name = " " .. measurement.get_unit_name(m_unit)
        local msg, str = "", finale.FCString()

        local function us(evpu)
            str:SetMeasurement(evpu, m_unit)
            return str.LuaString
        end
        local function usi(idx)
            return us(config[offsets[idx][1]])
        end
        for _, v in ipairs(offsets) do -- any offset error?
            if math.abs(config[v[1]]) > max_evpu then
                msg = msg .. "Choose realistic entry offset values, \nsay from -"
                    .. us(max_evpu) .. " to " .. us(max_evpu) .. u_name .. ", not:\n"
                    .. usi(1) .. " ... " .. usi(2) .. u_name .. " (upwards)\n"
                    .. usi(3) .. " ... " .. usi(4) .. u_name .. " (downwards)"
                error = true
                break -- one bad offset ruins it for everyone
            end
        end
        if msg ~= "" then
            finenv.UI():AlertError(msg, finaleplugin.ScriptGroupName .. " Error")
            return true
        end
    end
    return false
end

local function choose_action()
    configuration.get_user_settings(script_name, config, true)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(finenv.Region())

    local qimk = finenv.QueryInvokedModifierKeys
    local mod_key = qimk and (qimk(finale.CMDMODKEY_ALT) or qimk(finale.CMDMODKEY_SHIFT))
    local change_values = (direction == "Configuration")
    local user_error = true
    while user_error and (mod_key or change_values) do
        if not configuration_dialog() then return end -- user cancelled
        user_error = input_error() -- wait for correct answer
    end
    if change_values then return end -- config only
    local next_staff = next_staff_or_error(rgn)
    if next_staff > 0 then cross_staff(next_staff, rgn) end
end

choose_action()
