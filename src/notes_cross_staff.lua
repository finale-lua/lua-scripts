function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.85"
    finaleplugin.Date = "2024/04/22"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.ScriptGroupDescription = "Selected notes are cross-staffed to the next staff above or below the selection"
	finaleplugin.Notes = [[
        Selected notes are "crossed" to the next staff above or below the selection. 
        This mimics Finale's inbuilt __TG Tools__ _Cross-Staff_ plugin, which in my 
        experience malfunctions periodically. 
        This script doesn't, but also offers options for layer filtering, 
        stem reversal, horizontal note shift (to counteract stem reversal) 
        and note pattern matching. 

        Hold down [Shift] when starting the script to quickly cross staves 
        without a confirmation dialog, with the settings last used. 
        Select __Modeless Dialog__ if you want the dialog window to persist 
        on-screen for repeated use until you click _Cancel_ [Escape].

        __Reverse Stems of Crossed Notes__  
        For stems to sit in between the staves the stems of _crossed_ 
        notes must be reversed. With this option selected you may also shift notes 
        horizontally to compensate for uneven spacing caused by stem reversal. 

        __Shift Horizontals Across Whole Measure__  
        Horizontal shift is normally applied only to notes that are part of a 
        _crossing_ beam group.  This can sometimes conflict with notes either side 
        of the selection and it looks better if all notes in the source measure are shifted equally. 

        > __Key Commands__ (in the Configuration window): 

        > - __d__ - __f__ - __g__ - __h__: toggle the checkboxes 
        > - __z__: toggle __Up/Down__ direction
        > - __x__: reset default __shift__ values 
        > - __q__: display these script notes 
        > - __m__: toggle __Modeless__  
        > - To change measurement units: 
        > - __e__: EVPU / __i__: Inches / __c__: Centimeters 
        > - __o__: Points / __a__: Picas / __s__: Spaces 
	]]
    return "Notes Cross-Staff",
        "Notes Cross-Staff Down",
        "Selected notes are cross-staffed to the next lower staff"
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local measurement = require("library.measurement")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

local config = {
    rest_fill     = true, -- fill destination with invisible rest
    not_unbeamed  = true, -- true to prevent unbeamed notes
    reversing     = true, -- true to allow reversing cross-note stems
    whole_measure = false, -- horizontal shift across whole measure
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    layer_num     = 0,
    direction     = "Up", -- (or "Down")
    modeless      = false,
    count_set     = 1, -- "Cross" x notes
    count_group   = 1, -- "out of" y notes
    window_pos_x  = false,
    window_pos_y  = false,
}

local offsets = { -- ordered: id; default value; text label (if any)
    { "Up_Crossed",     12, "Cross Up Offset:" },
    { "Up_Uncrossed",  -12 },
    { "Down_Crossed",  -12, "Cross Down Offset:" },
    { "Down_Uncrossed", 12 }
}
-- also pre-populate config values
for _, v in ipairs(offsets) do config[v[1]] = v[2] end

local checks = { -- key; text description (ordered) of the checkboxes
    { "rest_fill",    "Put invisible rest in empty destination (d)" },
    { "not_unbeamed", "Don't cross unbeamed notes (f)" },
    { "reversing",    "Reverse stems of crossed notes (g)" },
    { "whole_measure", "Shift horizontals across whole measure (h)" }
}
local entry_text = { "note", "notes" }
local pattern = {
    { "count_set", "Cross", 37 },
    { "count_group", entry_text[1], 68 }
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

local function get_staff_name(staff_num)
    local staff = finale.FCStaff()
    staff:Load(staff_num)
    local str = staff:CreateDisplayAbbreviatedNameString().LuaString
    if not str or str == "" then
        str = "Staff" .. staff_num
    end
    return str
end

local function next_staff_or_error(rgn, dialog)
    local msg = ""
    local stack = mixin.FCMMusicRegion()
    stack:SetRegion(rgn):SetFullMeasureStack()
    local next_slot = rgn.StartSlot

    if rgn:IsEmpty() then
        msg = "Please select some music\nbefore running this script"
    elseif rgn.StartStaff ~= rgn.EndStaff then
        msg = "This script will only work\nwith one staff selected"
    else
        if config.direction == "Down" then
            next_slot = next_slot + 1
            if next_slot > stack.EndSlot then msg = "below" end
        else -- config.direction == "Up"
            next_slot = next_slot - 1
            if next_slot < 1 then msg = "above" end
        end
        if msg ~= "" then
            msg = "You can't cross notes to the staff " .. msg
                .. " because there is no staff " .. msg .. " the selected music."
        end
    end
    if msg ~= "" then
        if dialog then
            dialog:CreateChildUI():AlertError(msg, plugindef() .. ": Error")
        else
            finenv.UI():AlertError(msg, plugindef() .. ": Error")
        end
        return -1 -- signal error
    end
    return stack:CalcStaffNumber(next_slot) -- success
end

local function clear_mods(entry, type)
    local mods = finale[type](entry)
    mods:LoadAll()
    for m in eachbackwards(mods) do m:DeleteData() end
end

local function clean_entry(entry) -- erase pre-exisiting conditions
    if entry:IsNote() then
        clear_mods(entry, "FCCrossStaffMods")
        clear_mods(entry, "FCPrimaryBeamMods")
        entry.ReverseUpStem = false
        entry.ReverseDownStem = false
        entry.FreezeBeam = false
        entry.FreezeStem = false
    else
        entry:SetRestDisplacement(0)
        entry.FloatingRest = true
    end
    entry.ManualPosition = 0
end

local function destination_rests(rgn, dest_staff)
    if config.rest_fill then -- insert invisible rest into "empty" destination
        for measurenum = rgn.StartMeasure, rgn.EndMeasure do
            local layer_num = math.max(config.layer_num, 1) -- NOT layer "0"!
            local notecell = mixin.FCMNoteEntryCell(measurenum, dest_staff)
            notecell:Load()
            if notecell.Count == 0 then -- destination empty so proceed
                local m = finale.FCMeasure()
                local m_duration = m:Load(measurenum) and m:GetDuration() or finale.WHOLE_NOTE
                local new_rest = notecell:AppendEntriesInLayer(layer_num, 1)
                if new_rest then
                    new_rest:MakeRest():SetDuration(m_duration):SetLegality(true):SetVisible(false)
                    notecell:Save()
                end
            end
        end
    end
end

local function set_manual_pos(entry)
    local type = config.direction .. (entry.CrossStaff and "_Crossed" or "_Uncrossed")
    entry.ManualPosition = config[type]
end

local function cross_entry(entry, dest_staff)
    local cross_mod = finale.FCCrossStaffMod()
    cross_mod:SetNoteEntry(entry)
    local loaded = cross_mod:LoadFirst()
    cross_mod.Staff = dest_staff
    for note in each(entry) do cross_mod:SaveAt(note) end
    local _ = loaded and cross_mod:Save() or cross_mod:SaveNew()
end

local function cross_staff(dialog)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(finenv.Region())
    local next_staff = next_staff_or_error(rgn, dialog)
    if next_staff < 0 then return false end -- error finding "next staff"

    -- ready to cross
    finenv.StartNewUndoBlock(string.format("Cross-Staff %s -> %s m.%d-%d",
        get_staff_name(rgn.StartStaff), get_staff_name(next_staff), rgn.StartMeasure, rgn.EndMeasure)
    )
    destination_rests(rgn, next_staff) -- add invisible rests to destination if requested
    local beam_start = {} -- track first note in each beam group
    local count, active_beam = 0, nil -- track the current start entry of beam

    for entry in eachentrysaved(rgn, config.layer_num) do
        count = count + 1
        clean_entry(entry) -- erase old beam/stem settings

        -- beamed or due to cross?
        local beamed = not entry:CalcUnbeamedNote()
        if entry:IsNote() then
            if (beamed or not config.not_unbeamed) then
                if beamed and not active_beam then
                    active_beam = entry:CalcBeamStartEntry().EntryNumber
                    beam_start[active_beam] = {} -- start new beam group
                end
                if (count <= config.count_set) then -- ("eligible")
                    if config.reversing then -- reverse stem requested?
                        entry["Reverse" .. config.direction .. "Stem"] = true
                    end
                    entry.StemUp = (config.direction == "Up")
                    entry.FreezeStem = true
                    cross_entry(entry, next_staff)
                end
            end
        end
        if active_beam and entry:CalcBeamedGroupEnd() then -- active beam ends, even on rests
            beam_start[active_beam].stop = entry.EntryNumber
            active_beam = nil
        end
        if count >= config.count_group then count = 0 end -- start new note group
    end

    -- now check entire measure(s) for whole-beam crossings
    active_beam = nil
    local bsab
    local whole_measure = mixin.FCMMusicRegion()
    whole_measure:SetRegion(rgn):SetStartMeasurePosLeft():SetEndMeasurePosRight()

    for entry in eachentrysaved(whole_measure, config.layer_num) do
        local enum = entry.EntryNumber
        if beam_start[enum] then -- start of a new "crossing" beam-group
            active_beam = enum
            bsab = beam_start[active_beam] -- abbreviation
        end
        if active_beam then -- continuing beam-group
            bsab[entry.CrossStaff and "cross" or "stay"] = true
            entry.FreezeStem = entry.CrossStaff -- uncrossed = unfrozen
            entry.ManualPosition = 0
            if enum == bsab.stop or entry:CalcBeamedGroupEnd() then
                bsab.stop = enum
                active_beam = nil -- beam ended
            end
        end
    end
    -- if beam not "mixed" then prevent stem reversals
    active_beam = nil
    for entry in eachentrysaved(whole_measure, config.layer_num) do
        local enum = entry.EntryNumber
        if beam_start[enum] then
            active_beam = enum
            bsab = beam_start[active_beam]
            bsab.mixed = bsab.cross and bsab.stay and config.reversing
        end
        if active_beam then
            if bsab.mixed then
                if config.reversing then set_manual_pos(entry) end
            else -- not mixed -> no stem reversal
                entry.ReverseUpStem = false
                entry.ReverseDownStem = false
                entry.FreezeStem = false
                entry.ManualPosition = 0
            end
            if enum == bsab.stop then active_beam = nil end -- beam ended
        elseif config.reversing and config.whole_measure then
            set_manual_pos(entry)  -- outside "crossing" beam
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
    return true
end

local function submission_error()
    local msg, str = "", finale.FCString()
    if config.reversing then -- offsets matter
        local max_evpu = 576 -- who would want more than 2 inches?
        local m_unit = config.measurement_unit
        local u_name = " " .. measurement.get_unit_name(m_unit)
        local function us(evpu)
            str:SetMeasurement(evpu, m_unit)
            return str.LuaString
        end
        local function usi(idx)
            return us(config[offsets[idx][1]])
        end
        for i, v in ipairs(offsets) do -- any offset error?
            if i < 5 then -- omit vertical beam
                if math.abs(tonumber(config[v[1]]) or 0) > max_evpu then
                    msg = msg .. "Choose realistic entry offset values, \nsay from -"
                        .. us(max_evpu) .. " to " .. us(max_evpu) .. u_name .. ", not:\n"
                        .. usi(1) .. " ... " .. usi(2) .. u_name .. " (upwards)\n"
                        .. usi(3) .. " ... " .. usi(4) .. u_name .. " (downwards)"
                    break -- one bad offset ruins it for everyone
                end
            end
        end
    end
    if config.count_set > config.count_group then
        if msg ~= "" then msg = msg .. "\n\n" end
        msg = msg .. "The \"Cross ___ notes\" number (" .. config.count_set
        .. ")\nmust not be larger than the \n\"out of\" number ("
        .. config.count_group .. ")"
    end
    if msg ~= "" then
        finenv.UI():AlertError(msg, plugindef() .. " Error")
        return true
    end
    return false
end

local function run_the_dialog()
    local max = layer.max_layers()
    local x = { 140, 210, 245 }
    local y = 0
    local units = { -- map keystrokes onto Measurement Unit ENUMs
        e = finale.MEASUREMENTUNIT_EVPUS,       i = finale.MEASUREMENTUNIT_INCHES,
        c = finale.MEASUREMENTUNIT_CENTIMETERS, o = finale.MEASUREMENTUNIT_POINTS,
        a = finale.MEASUREMENTUNIT_PICAS,       s = finale.MEASUREMENTUNIT_SPACES,
    }
    local answer, save_value = {}, {} -- "Edit" controls / saved "text" values
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:SetMeasurementUnit(config.measurement_unit)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. plugindef(), 500, 400)
            refocus_document = true
        end
        local function dy(diff)
            y = diff and (y + diff) or (y + 25)
        end
        local function cstat(cx, cy, ctext, cwide)
            local stat = dialog:CreateStatic(cx, cy):SetText(ctext)
            if cwide then stat:SetWidth(cwide) end
            return stat
        end
        local function toggle_check(id)
            local name = checks[id][1]
            answer[name]:SetCheck((answer[name]:GetCheck() + 1) % 2)
        end
        local function set_offset_disable(enable)
            answer.whole_measure:SetEnable(enable)
            for i = 1, 4 do answer[offsets[i][1]]:SetEnable(enable) end
            answer.popup:SetEnable(enable)
            answer.default:SetEnable(enable)
        end
        local function update_saved()
            for _, v in ipairs(offsets) do save_value[v[1]] = answer[v[1]]:GetText() end
            for _, v in ipairs(pattern) do save_value[v[1]] = answer[v[1]]:GetText() end
            save_value.layer_num = answer.layer_num:GetText()
        end
        local function set_default_values()
            for _, v in ipairs(offsets) do answer[v[1]]:SetMeasurementInteger(v[2]) end
            update_saved()
        end
        local function flip_direction()
            local n = answer.direction:GetSelectedItem()
            answer.direction:SetSelectedItem((n + 1) % 2)
        end
        local function key_check(id)
            local ctl = answer[id]
            local s = ctl:GetText():lower()
            if  (s:find("p") and dialog:GetMeasurementUnit() ~= finale.MEASUREMENTUNIT_PICAS)
                or s:find("[^-.p0-9]")
                or (id == "layer_num" and s:find("[^0-" .. max .. "]"))
                or (id:find("count") and s:find("[^1-9]"))
                then
                local reversing = (answer.reversing:GetCheck() == 1)
                if     s:find("d") then toggle_check(1) -- rest_fill
                elseif s:find("f") then toggle_check(2) -- not_unbeamed
                elseif s:find("g") then toggle_check(3) -- reversing
                    set_offset_disable(not reversing)
                elseif s:find("h") and reversing then toggle_check(4) -- whole_measure
                elseif s:find("x") then set_default_values()
                elseif s:find("z") then flip_direction()
                elseif s:find("m") then -- toggle modeless
                    local m = answer.modeless:GetCheck()
                    answer.modeless:SetCheck((m + 1) % 2)
                elseif s:find("[?q]") then show_info()
                elseif reversing and s:find("[eicoas]") then -- change UNITS
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
            elseif s ~= "" then
                if id == "layer_num" or id:find("count") then
                    s = s:sub(-1) -- one char only
                    if id == "count_set" then
                        local n = tonumber(s) or 1
                        answer.entry2:SetText(n == 1 and entry_text[1] or entry_text[2])
                    end
                else
                    if s == "." then s = "0." -- leading zero
                    elseif s == "-." then s = "-0."
                    end
                end
                save_value[id] = s
            end
            ctl:SetText(save_value[id])
        end
    local y_off = finenv.UI():IsOnMac() and 3 or 0 -- y-offset for Mac edit box
    answer.direction = dialog:CreatePopup(0, y - 1):SetWidth(90)
        :AddStrings("Cross Up", "Cross Down")  -- == 0 ... 1
        :SetSelectedItem(config.direction == "Up" and 0 or 1)
    answer.modeless = dialog:CreateCheckbox(131, y):SetWidth(120)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    answer.q = dialog:CreateButton(x[2] + 44, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dy()
    local x_off = 0
    for i, v in ipairs(pattern) do -- PATTERN MATCH
        if i == 2 then cstat(x_off + v[3] - 37, y, "out of", 50) end
        answer["entry" .. i] = cstat(x_off, y, v[2], v[3])
        answer[v[1]] = dialog:CreateEdit(x_off + v[3], y - y_off):SetInteger(config[v[1]])
            :AddHandleCommand(function() key_check(v[1]) end):SetWidth(17)
        x_off = x_off + v[3] + 19
    end
    answer.entry2:SetText(config.count_set == 1 and entry_text[1] or entry_text[2])

    cstat(x[2] - 18, y, "Layer 0-" .. max .. ":", 60)
    answer.layer_num = dialog:CreateEdit(x[2] + 44, y - y_off):SetText(config.layer_num)
        :AddHandleCommand(function() key_check("layer_num") end):SetWidth(20)
    dy()
    for _, v in ipairs(checks) do -- CHECKBOXES
        answer[v[1]] = dialog:CreateCheckbox(20, y):SetText(v[2])
            :SetCheck(config[v[1]] and 1 or 0):SetWidth(x[3])
        dy(18)
    end
    answer.reversing:AddHandleCommand(function(self)
        set_offset_disable(self:GetCheck() == 1)
    end)
    dy(12)
    dialog:CreateHorizontalLine(0, y - 9, x[2] + 64)
    dialog:CreateHorizontalLine(0, y - 8, x[2] + 64)
    cstat(0, y, "Units:", 37)
    answer.popup = dialog:CreateMeasurementUnitPopup(37, y - 1):SetWidth(90)
        :AddHandleCommand(function() update_saved() end)
    cstat(x[1], y, "Crossed", 70)
    cstat(x[2] - 4, y, "Not Crossed", 70)

    for i, v in ipairs(offsets) do -- OFFSET MEASUREMENTS
        if i % 2 == 1 then dy(22) end
        if v[3] then cstat(20, y, v[3], x[1]) end -- describe the entry values
        local x_pos = (i % 2 == 1) and x[1] or x[2]
        answer[v[1]] = dialog:CreateMeasurementEdit(x_pos, y - y_off)
            :SetMeasurementInteger(config[v[1]]):SetWidth(64)
            :AddHandleCommand(function() key_check(v[1]) end)
    end
    dy(22)
    answer.default = dialog:CreateButton(x[1] - 52, y):SetText("Default Values (x)"):SetWidth(105)
        :AddHandleCommand(function() set_default_values() end)
    update_saved()

    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local change_mode, user_error = false, false
    dialog:RegisterInitWindow(function(self)
        set_offset_disable(config.reversing)
        self:SetOkButtonCanClose(not config.modeless)
        answer.q:SetFont(answer.q:CreateFontInfo():SetBold(true))
        answer.count_set:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        for _, v in ipairs(offsets) do config[v[1]] = answer[v[1]]:GetMeasurementInteger() end
        for _, v in ipairs(checks) do config[v[1]] = (answer[v[1]]:GetCheck() == 1) end
        for _, v in ipairs(pattern) do config[v[1]] = answer[v[1]]:GetInteger() end
        config.layer_num = answer.layer_num:GetInteger()
        config.measurement_unit = self:GetMeasurementUnit()
        config.direction = (answer.direction:GetSelectedItem() == 0) and "Up" or "Down"
        user_error = submission_error() or (not cross_staff(self)) -- error if eligible failed
    end)
    dialog:RegisterCloseWindow(function(self)
        local mode = (answer.modeless:GetCheck() == 1)
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
    return (change_mode or user_error) -- something still to change
end

local function cross_some_staves()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if mod_key then -- use last config values
        cross_staff()
    else
        while run_the_dialog() do end
    end
end

cross_some_staves()
