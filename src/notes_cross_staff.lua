function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.95g"
    finaleplugin.Date = "2024/05/17"
    finaleplugin.MinJWLuaVersion = 0.74
    finaleplugin.ScriptGroupDescription = "Selected notes are cross-staffed to the next staff above or below"
	finaleplugin.Notes = [[
        Selected notes are __crossed__ to the next staff above or below the selection. 
        This mimics Finale's inbuilt __TG Tools__ _Cross-Staff_ plugin, which in my 
        experience malfunctions periodically. 
        This script doesn't, but also offers options for layer filtering, 
        stem reversal, horizontal note shift (to counteract stem reversal), 
        note pattern matching and beam height adjustment. 

        Hold [Shift] when starting the script to quickly cross staves 
        without a confirmation dialog, with the settings last used. 
        Select __Modeless Dialog__ if you want the dialog window to persist 
        on-screen for repeated use until you click _Cancel_ [Escape].

        __Reverse Stems For Mid-Staff Beams__  
        To centre beams _between_ the staves, the stems of __Crossed__ 
        notes must be __Reversed__. 
        The midpoint between staves is measured from __Page View__ which 
        may look different in __Scroll View__. 
        If using the __Reverse__ option you can also __shift notes horizontally__ 
        to correct uneven stem spacing caused by the reversal. 

        __Shift Horizontals Across Whole Measure__  
        Horizontal shift is normally applied only to notes within a 
        beam group containing __cross-staff__ notes.  This can sometimes 
        conflict with notes either side of the selection and it looks 
        better if all notes in the source measure are shifted at once. 

        > __Key Commands__: 

        > - __d__ - __f__ - __g__ - __h__: toggle the checkboxes 
        > - __z__: toggle __Up/Down__ direction
        > - __x__: set default __shift__ values 
        > - __v__: set zero __shift__ values 
        > - __m__: toggle __Modeless__ 
        > - __q__: display these script notes  
        > - To change measurement units: 
        > - __e__: EVPU / __i__: Inches / __c__: Centimeters 
        > - __o__: Points / __a__: Picas / __s__: Spaces 
	]]
    return "Notes Cross-Staff...", "Test Notes Cross-Staff", "Selected notes are cross-staffed to the next staff above or below"
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local measurement = require("library.measurement")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false
local name = plugindef():gsub("%.%.%.", "")
local units = { -- map keystrokes onto Measurement Unit ENUMs
    e = finale.MEASUREMENTUNIT_EVPUS,       i = finale.MEASUREMENTUNIT_INCHES,
    c = finale.MEASUREMENTUNIT_CENTIMETERS, o = finale.MEASUREMENTUNIT_POINTS,
    a = finale.MEASUREMENTUNIT_PICAS,       s = finale.MEASUREMENTUNIT_SPACES,
}
local hotkey = { -- customise Key Commands (lower case only)
    rest_fill     = "d",
    not_unbeamed  = "f",
    reversing     = "g",
    whole_measure = "h",
    direction     = "z",
    set_default   = "x",
    set_zero      = "v",
    modeless      = "m",
    script_info   = "q",
    -- optionally re-map MEASUREMENTUNIT hotkeys:
    e =   "e",
    i =   "i",
    c =   "c",
    o =   "o",
    a =   "a",
    s =   "s",
}
local config = {
    rest_fill     = true, -- fill destination with invisible rest
    not_unbeamed  = true, -- true to prevent unbeamed notes
    reversing     = true, -- true to allow reversing cross-note stems
    whole_measure = false, -- horizontal shift across whole measure
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    layer_num     = 0,
    direction     = "Up", -- (or "Down")
    modeless      = false,
    count_notes   = 1, -- "Cross" x notes
    count_out_of  = 1, -- "out of" y notes
    window_pos_x  = false,
    window_pos_y  = false,
}

local offsets = { -- (ordered) name; default value; text description
    { "Up_Crossed",     12, "Cross Up:", 79 },
    { "Up_Uncrossed",  -12 },
    { "Down_Crossed",  -12, "Cross Down:", 65 },
    { "Down_Uncrossed", 12 },
    { "beam_vertical",  0,  "Beam Vertical Adjust:", 20 }
}
-- copy default offset values to config
for _, v in ipairs(offsets) do config[v[1]] = v[2] end

local checks = { -- checkbox key; text description (ordered)
    { "rest_fill",    "Add Invisible Rest To Empty Destination" },
    { "not_unbeamed", "Don't Cross Unbeamed Notes" },
    { "reversing",    "Reverse Stems For Mid-Staff Beams" },
    { "whole_measure", "Shift Horizontals Across Whole Measure" }
}
local entry_text = { "note", "notes" }
local pattern = {
    { "count_notes", "Cross", 37 },
    { "count_out_of", entry_text[1], 68 }
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
    if msg ~= "" then -- **ERROR**
        if dialog then
            dialog:CreateChildUI():AlertError(msg, name .. ": Error")
        else
            finenv.UI():AlertError(msg, name .. ": Error")
        end
        return -1 -- flag error
    end
    return stack:CalcStaffNumber(next_slot)
end

local function clean_beams(entry)
    local beam = finale.FCBeamMod(false)
    for _, v in ipairs{true, false} do
        beam:SetNoteEntry(entry)
        beam:UseUpStemData(v)
        if beam:LoadFirst() then
            beam:SetDefaultMode()
            beam.LeftVerticalOffset = 0
            beam.RightVerticalOffset = 0
            beam.LeftHorizontalOffset = 0
            beam.RightHorizontalOffset = 0
            beam.Thickness = -1
            beam:Save() -- it already exists
        end
    end
end

local function clean_entry(entry) -- erase pre-exisiting conditions
    if entry:IsNote() then
        for i = 1, entry.Count do
            finale.FCCrossStaffMod():EraseAt(entry:GetItemAt(i - 1))
        end
        local mods = finale.FCCrossStaffMods(entry)
        mods:LoadAll()
        for m in eachbackwards(mods) do m:DeleteData() end
        mods:ClearAll()
        entry.CrossStaff = false
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
    if not config.rest_fill then return end
    for measure_num = rgn.StartMeasure, rgn.EndMeasure do
        local layer_num = math.max(config.layer_num, 1) -- NOT layer "0"!
        local note_cell = mixin.FCMNoteEntryCell(measure_num, dest_staff)
        note_cell:Load()
        if note_cell.Count == 0 then -- destination empty so proceed
            local m = finale.FCMeasure()
            local m_duration = m:Load(measure_num) and m:GetDuration() or finale.WHOLE_NOTE
            local new_rest = note_cell:AppendEntriesInLayer(layer_num, 1)
            if new_rest then
                new_rest:MakeRest():SetDuration(m_duration):SetLegality(true):SetVisible(false)
                note_cell:Save()
            end
        end
    end
end

local function set_manual_pos(entry)
    local type = config.direction .. (entry.CrossStaff and "_Crossed" or "_Uncrossed")
    entry.ManualPosition = config.reversing and config[type] or 0
end

local function cross_entry(entry, dest_staff)
    local cross_mod = finale.FCCrossStaffMod()
    cross_mod:SetNoteEntry(entry)
    local loaded = cross_mod:LoadFirst()
    cross_mod.Staff = dest_staff
    for note in each(entry) do cross_mod:SaveAt(note) end
    local _ = loaded and cross_mod:Save() or cross_mod:SaveNew()
end

local function change_beam_height(entry, offset)
    local use_upstem = config.reversing and entry.StemUp and entry.ReverseUpStem
    if not entry.FreezeStem and config.direction == "Up" then
        use_upstem = true -- not at start of beam group
    end
    local beam = finale.FCBeamMod(false)
    beam:SetNoteEntry(entry)
    if config.reversing then beam:UseUpStemData(use_upstem) end
    local loaded = beam:LoadFirst()
    beam:SetDefaultMode()
    beam.LeftVerticalOffset = offset
    if loaded then beam:Save() else beam:SaveNew() end
end

local function entry_metrics(entry, scale)
    local em = finale.FCEntryMetrics() -- get BEAM metrics
    em:Load(entry)
    local lo = math.floor(em.BottomPosition / scale + 0.5)
    local hi = math.floor(em.TopPosition / scale + 0.5)
    em:FreeMetrics()
    return lo, hi
end

local function get_staff_metrics(measure, staff_number)
    local cell = finale.FCCell(measure, staff_number)
    local cell_metrics = cell:CreateCellMetrics()
    local staff_scale = cell_metrics.StaffScaling / 10000
    local staff_mid = cell_metrics.ReferenceLinePos - 48
    cell_metrics:FreeMetrics()
    return staff_mid, staff_scale
end

local function beam_vertical_adjust(entry, src_staff, dest_staff, scale)
    local beam_thickness = (entry:CalcBeamCount() - 1) * 9
    local mid_staff = math.floor((dest_staff - src_staff) / 2 + 0.5)
    local beam_lo, beam_hi = entry_metrics(entry, scale)
    local diff = 0
    if config.reversing then
        diff = src_staff + mid_staff
        if config.direction == "Up" then
            if entry.FreezeStem then diff = diff - beam_lo
            else diff = diff - beam_hi + beam_thickness
            end
        else -- direction == "Down"
            if entry.FreezeStem then diff = diff - beam_hi
            else diff = diff - beam_lo - beam_thickness
            end
        end
    end
    change_beam_height(entry, diff + config.beam_vertical)
end

local function cross_staff(dialog)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(finenv.Region())

    local next_staff = next_staff_or_error(rgn, dialog)
    if next_staff < 0 then return false end -- error finding "next staff"
    -- ready to cross staves
    finenv.StartNewUndoBlock(string.format("Cross-Staff %s -> %s m.%d",
        get_staff_name(rgn.StartStaff), get_staff_name(next_staff), rgn.StartMeasure)
    )
    destination_rests(rgn, next_staff)  -- add invisible rests to destination if requested
    local beam_start, crossing = {}, {} -- register first note in each beam group
    local whole_measure = mixin.FCMMusicRegion()
    whole_measure:SetRegion(rgn):SetStartMeasurePosLeft():SetEndMeasurePosRight()
    --
    local src_staff_top, scale = get_staff_metrics(rgn.StartMeasure, rgn.StartStaff)
    local dest_staff_top, _ = get_staff_metrics(rgn.StartMeasure, next_staff)

    -- pass 1 (selection) set {crossing} entries and {beam_start}
    local count, active_beam = 0, nil
    for entry in eachentrysaved(rgn, config.layer_num) do
        count = count + 1
        if entry:IsNote() then
            clean_entry(entry)
            local beamed = not entry:CalcUnbeamedNote()
            if (beamed or not config.not_unbeamed) then -- beamed plus eligible unbeamed
                if beamed and not active_beam then
                    active_beam = entry:CalcBeamStartEntry().EntryNumber
                    beam_start[active_beam] = {} -- start new beam group
                end
                if count <= config.count_notes then -- cross "cnt_notes" in "cnt_out_of" entries
                    crossing[entry.EntryNumber] = true
                end
            end
        end
        if active_beam and entry:CalcBeamedGroupEnd() then
            active_beam = nil -- active beam ends
        end
        if count >= config.count_out_of then count = 0 end -- restart note count
    end
    -- pass 2 (whole measure) clear affected beams
    local bsen
    for entry in eachentrysaved(whole_measure, config.layer_num) do
        local enum = entry.EntryNumber
        if beam_start[enum] then
            clean_beams(entry) -- erase beam offsets
            bsen = beam_start[enum] -- abbreviation
        end
        if bsen and entry:CalcBeamedGroupEnd() then
            bsen.stop = enum
            bsen = nil
        end
    end
    -- pass 3 (selection) stem freezing if stems reversed
    if config.reversing then
        for entry in eachentrysaved(rgn, config.layer_num) do
            if crossing[entry.EntryNumber] then
                entry.StemUp = (config.direction == "Up")
                entry.FreezeStem = true
            end
        end
        finale.FCNoteEntry.MarkEntryMetricsForUpdate()
    end

    -- pass 4 (measure) stem reversal & crossing
    bsen = nil
    for entry in eachentrysaved(whole_measure, config.layer_num) do
        if entry:IsNote() then
            local enum = entry.EntryNumber
            if crossing[enum] then -- marked for crossing in first pass
                if config.reversing then
                    entry["Reverse" .. config.direction .. "Stem"] = true
                end
                cross_entry(entry, next_staff)
            end
            if beam_start[enum] then -- start of a new "crossing" beam-group
                bsen = beam_start[enum] -- abbreviation
            end
            if bsen then -- continuing beam-group
                bsen[crossing[enum] and "cross" or "stay"] = true
                if bsen.stop == enum then bsen = nil end
            end
        end
    end
    bsen = nil
    -- pass 5 (measure) shift beam if "mixed" crossed-and-uncrossed
    for entry in eachentrysaved(whole_measure, config.layer_num) do
        if entry:IsNote() then
            local enum = entry.EntryNumber
            if beam_start[enum] then
                bsen = beam_start[enum]
                bsen.mixed = bsen.cross and bsen.stay
                if bsen.mixed then
                    beam_vertical_adjust(entry, src_staff_top, dest_staff_top, scale)
                end
            end
            if bsen then
                set_manual_pos(entry)
                if not bsen.mixed then -- no stem reversal
                    entry.ReverseUpStem = false
                    entry.ReverseDownStem = false
                    entry.FreezeStem = false
                    entry.ManualPosition = 0
                end
                if enum == bsen.stop then bsen = nil end
            elseif config.whole_measure then
                set_manual_pos(entry) -- not a "crossing" note
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
    return true
end

local function submission_error(dialog)
    local msg, str = "", finale.FCString()
    if not config.no_shift then -- offsets matter
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
            if i < 5 then -- omit beam height
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
    if msg ~= "" then
        dialog:CreateChildUI():AlertError(msg, name .. " Error")
        return true
    end
    return false
end

local function run_the_dialog()
    local max = layer.max_layers()
    local x = { 140, 210, 245}
    local y = 0
    local answer, save_value = {}, {} -- "Edit" controls / saved "text" values
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
    dialog:SetMeasurementUnit(config.measurement_unit)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 500, 455)
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
        local function set_offset_disable()
            local enable = answer.reversing:GetCheck() == 1
            for i = 1, 4 do answer[offsets[i][1]]:SetEnable(enable) end
            for _, v in ipairs{"whole_measure", "h1", "h2", "h3", "off1", "off3"} do
                answer[v]:SetEnable(enable)
            end
            answer[pattern[1][1]]:SetKeyboardFocus()
        end
        local function update_saved()
            for _, v in pairs(offsets) do
                save_value[v[1]] = answer[v[1]]:GetText()
            end
        end
        local function set_default_values(v)
            for i = 1, 4 do
                answer[offsets[i][1]]:SetMeasurementInteger(v or offsets[i][2])
            end
            answer.beam_vertical:SetText(save_value.beam_vertical)
            update_saved()
        end
        local function key_check(id)
            local ctl = answer[id]
            local s = ctl:GetText():lower()
            if  (s:find("p") and dialog:GetMeasurementUnit() ~= finale.MEASUREMENTUNIT_PICAS)
                or s:find("[^-.p0-9]")
                or (id == "layer_num" and s:find("[^0-" .. max .. "]"))
                or (id:find("count") and s:find("[^1-9]"))
                    then
                if s:find("[eicoas]") then -- change UNITS
                    for k, v in pairs(units) do
                        if s:find(hotkey[k]) then
                            ctl:SetText(save_value[id])
                            dialog:SetMeasurementUnit(v) -- change UNIT
                            answer.popup:UpdateMeasurementUnit()
                            update_saved()
                            break
                        end
                    end
                elseif s:find(hotkey.set_default) then set_default_values()
                elseif s:find(hotkey.set_zero)    then set_default_values(0)
                elseif s:find(hotkey.script_info) then show_info()
                elseif s:find(hotkey.direction)   then
                        local n = answer.direction:GetSelectedItem()
                        answer.direction:SetSelectedItem((n + 1) % 2)
                else -- remaining simple checkboxes
                    for k, v in pairs(hotkey) do
                        if s:find(v) then
                            answer[k]:SetCheck((answer[k]:GetCheck() + 1) % 2)
                            if k == "reversing" then set_offset_disable() end
                            break
                        end
                    end
                end
            else
                if id == "layer_num" or id:sub(1,5) == "count" then
                    s = s:sub(-1) -- one char only
                    if id == "count_notes" then
                        answer.entry2:SetText(s == "1" and entry_text[1] or entry_text[2])
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
    -- dialog contents
    local y_off = finenv.UI():IsOnMac() and 3 or 0 -- y-offset for Mac edit box
    answer.direction = dialog:CreatePopup(0, y - 1):SetWidth(90)
        :AddStrings("Cross Up", "Cross Down")  -- item# == 0 or 1
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
    answer.entry2:SetText(config.count_notes == 1 and entry_text[1] or entry_text[2])

    cstat(x[2] - 18, y, "Layer 0-" .. max .. ":", 60)
    answer.layer_num = dialog:CreateEdit(x[2] + 44, y - y_off):SetText(config.layer_num)
        :AddHandleCommand(function() key_check("layer_num") end):SetWidth(20)
    dy()
    for _, v in ipairs(checks) do -- CHECKBOXES
        answer[v[1]] = dialog:CreateCheckbox(20, y):SetWidth(x[3])
            :SetText(v[2] .. " (" .. hotkey[v[1]] .. ")")
            :SetCheck(config[v[1]] and 1 or 0)
        dy(18)
    end
    answer.reversing:AddHandleCommand(function() set_offset_disable() end)
    dy(8)
    dialog:CreateHorizontalLine(0, y - 5, x[2] + 64)
    dialog:CreateHorizontalLine(0, y - 4, x[2] + 64)
    answer.h1 = cstat(x[1] + 4, y + 2, "HORIZONTAL OFFSETS", 130)
    dy(12)
    cstat(0, y - 7, "Units:", 37)
    answer.popup = dialog:CreateMeasurementUnitPopup(37, y - 8):SetWidth(90)
        :AddHandleCommand(function() update_saved() end)
    answer.h2 = cstat(x[1], y + 2, "Crossed", 70)
    answer.h3 = cstat(x[2] - 4, y + 2, "Not Crossed", 70)

    for i, v in ipairs(offsets) do -- OFFSET MEASUREMENTS
        if i % 2 == 1 then dy(18) end
        local x_pos = (i % 2 == 1) and x[1] or x[2]
        answer[v[1]] = dialog:CreateMeasurementEdit(x_pos, y - y_off)
            :SetMeasurementInteger(config[v[1]]):SetWidth(64)
            :AddHandleCommand(function() key_check(v[1]) end)
        if v[3] then -- describe the entry values
            answer["off" .. i] = cstat(v[4], y, v[3], x[1])
        end
    end
    dy(20)
    dialog:CreateButton(x[1], y):SetWidth(105)
        :SetText("Zero Horiz. (" .. hotkey.set_zero .. ")")
        :AddHandleCommand(function() set_default_values(0) end)
    dialog:CreateButton(20, y):SetWidth(105)
        :SetText("Default Horiz. (" .. hotkey.set_default .. ")")
        :AddHandleCommand(function() set_default_values() end)
    -- set "saved" edit values
    update_saved()
    for _, v in ipairs(pattern) do save_value[v[1]] = answer[v[1]]:GetText() end
    save_value.layer_num = answer.layer_num:GetText()

    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local change_mode, user_error = false, false
    dialog:RegisterInitWindow(function(self)
        set_offset_disable()
        self:SetOkButtonCanClose(not config.modeless)
        answer.q:SetFont(answer.q:CreateFontInfo():SetBold(true))
    end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        for _, v in ipairs(offsets) do config[v[1]] =  answer[v[1]]:GetMeasurementInteger() end
        for _, v in ipairs(checks)  do config[v[1]] = (answer[v[1]]:GetCheck() == 1) end
        for _, v in ipairs(pattern) do config[v[1]] =  answer[v[1]]:GetInteger() end
        config.layer_num = answer.layer_num:GetInteger()
        config.measurement_unit = self:GetMeasurementUnit()
        config.direction = (answer.direction:GetSelectedItem() == 0) and "Up" or "Down"
        user_error = submission_error(self) or (not cross_staff(self))
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
    else -- offer options
        while run_the_dialog() do end
    end
end

cross_some_staves()
