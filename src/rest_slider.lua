function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.25 modal option"
    finaleplugin.Date = "2024/02/15"
    finaleplugin.CategoryTags = "Rests, Selection"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        Slide rests up and down on the nominated layer with continuous visual feedback. 
        This was designed especially to help align rests midway 
        between staves with cross-staff notes. 
        The _Mid-Staff Above_ and _Mid-Staff Below_ buttons achieve this with one click. 
        Cancel the script to leave rests unchanged. 

        _Reset Zero_ sets nil offset. 
        Note that on transposing instruments this is NOT the middle 
        of the staff if _Display in Concert Pitch_ is selected. 
        In those instances use _Floating Rests_ to return them to 
        their virgin state where the only offset is that set at 
        _Document_ → _Document Options_ → _Layers_ → _Adjust Floating Rests by..._

        At startup all rests in the chosen layer are moved to the 
        same offset as the first rest on that layer in the selection. 
        Layer numbers can be changed "on the fly" to help 
        balance rests across multiple layers. 
        Select __Modeless__ if you prefer the dialog window to 
        "float" above your score. In this mode you must 
        click __Apply__ [Return/Enter] to "set" new rest positions 
        and __Cancel__ [Escape] to close the window. 
        __Modeless__ will apply _next_ time you use the script.

        > If __Layer Number__ is highlighted these __Key Commands__ are available: 

        > - __a__ (__-__): move rests down one step 
        > - __s__ (__+__): move rests up one step 
        > - __d__: move to mid-staff above (if one staff selected) 
        > - __f__: move to mid-staff below (if one staff selected) 
        > - __z__: reset to "zero" shift (not floating) 
        > - __x__: floating rests 
        > - __i__: invert shift direction 
        > - __q__: show these script notes 
        > - __0-4__: layer number (delete key not needed) 
    ]]
    return "Rest Slider...", "Rest Slider", "Slide rests up and down with continuous visual feedback"
end

local config = {
    layer_num = 0,
    timer_id = 1,
    modeless = 0, -- 0 = modal / 1 = modeless
    window_pos_x = false,
    window_pos_y = false
}
local mixin = require("library.mixin")
local layer = require("library.layer")
local configuration = require("library.configuration")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()

local first_offset = 0 -- set to real offset of first rest in selection
local refocus_document = false
local save_displacement, adjacent_offsets, saved_bounds = {}, {}, {}
local name = plugindef():gsub("%.%.%.", "")
local bounds = { -- primary region selection boundaries
    "StartStaff", "StartMeasure", "StartMeasurePos",
    "EndStaff",   "EndMeasure",   "EndMeasurePos",
}
local selection = { staff = "no staff", region = "no selection"}

local function set_saved_bounds()
    for _, prop in ipairs(bounds) do
        saved_bounds[prop] = finenv.Region()[prop]
    end
end

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

local function update_selection()
    local rgn = finenv.Region()
    if rgn:IsEmpty() then
        selection = { staff = "no staff", region = " no selection"}
        return
    end
    local r1 = rgn.StartMeasure + (rgn.StartMeasurePos / measure_duration(rgn.StartMeasure))
    local m = measure_duration(rgn.EndMeasure)
    local r2 = rgn.EndMeasure + (math.min(rgn.EndMeasurePos, m) / m)
    selection.region = string.format("m%.2f-m%.2f", r1, r2)

    local staff = finale.FCStaff()
    staff:Load(rgn.StartStaff)
    local s1 = staff:CreateDisplayFullNameString()
    staff:Load(rgn.EndStaff)
    local s2 = staff:CreateDisplayFullNameString()
    selection.staff = string.format("%s → %s", s1.LuaString, s2.LuaString)
end

local function get_rest_offset(entry)
    if entry:IsNote() then return 0 end -- only rests wanted
    local spec = finale.FCCurrentStaffSpec()
    spec:LoadForEntry(entry)
    local rest_pos = spec.OtherRestPosition
    if entry.Duration >= finale.BREVE then
        rest_pos = spec.DoubleWholeRestPosition
    elseif entry.Duration >= finale.WHOLE_NOTE then
        rest_pos = spec.WholeRestPosition
    elseif entry.Duration >= finale.HALF_NOTE then
        rest_pos = spec.HalfRestPosition
    end
    entry:MakeMovableRest()
    local rest = entry:GetItemAt(0)
    return rest:CalcStaffPosition() - rest_pos
end

local function offset_rest(entry, shift, float)
    if float then
        entry:SetFloatingRest(true)
    else
        local offset = get_rest_offset(entry)
        entry:SetRestDisplacement(entry:GetRestDisplacement() + shift - offset)
    end
end

local function set_adjacent_offsets()
    adjacent_offsets = {} -- start with blank collection
    local rgn = finenv.Region()
    local start_staff = rgn.StartStaff
    if start_staff ~= rgn.EndStaff then return end -- single staff required

    local start_slot = rgn:CalcSlotNumber(rgn.StartStaff)
    local next_staff = {} -- locate staff above/below
    local stack = mixin.FCMMusicRegion()
    stack:SetRegion(rgn):SetFullMeasureStack()
    if start_slot > 1 then
        next_staff.above = stack:CalcStaffNumber(start_slot - 1)
    end
    if start_slot < stack.EndSlot then
        next_staff.below = stack:CalcStaffNumber(start_slot + 1)
    end
    local system_staves = finale.FCSystemStaves()
    system_staves:LoadAllForRegion(stack)
    local sys_staff = system_staves:FindStaff(start_staff)
    if sys_staff then
        local start_position = sys_staff.Distance
        for key, staff_num in pairs(next_staff) do -- find 0, 1 or 2 adjacent_offsets
            sys_staff = system_staves:FindStaff(staff_num)
            local n = start_position - sys_staff.Distance
            adjacent_offsets[key] = math.floor(n / 24) -- convert EVPU to HALF steps
        end
    end
end

local function first_rest_offset(layer_num)
    local offset = 0
    for entry in eachentry(finenv.Region(), layer_num) do
        if entry:IsRest() then
            if not entry.FloatingRest then
                offset = entry:GetRestDisplacement() + get_rest_offset(entry)
            end
            break -- only need the first rest within layer_num
        end
    end
    return offset
end

local function save_rest_positions()
    first_offset = first_rest_offset(config.layer_num)
    for entry in eachentry(finenv.Region()) do
        if entry:IsRest() then
            save_displacement[entry.EntryNumber] = {
                entry:GetRestDisplacement(), entry.FloatingRest
            }
        end
    end
end

local function restore_rest_positions()
    if config.modeless == 1 then
        finenv.StartNewUndoBlock(name .. " " .. selection.region .. " reset", false)
    end
    for entry in eachentrysaved(finenv.Region()) do
        local v = save_displacement[entry.EntryNumber]
        if entry:IsRest() and v ~= nil then
            entry:SetRestDisplacement(v[1])
            entry:SetFloatingRest(v[2])
        end
    end
    if config.modeless == 1 then finenv.EndUndoBlock(true) end
    finenv.Region():Redraw()
end

local function run_the_dialog_box()
    local y, max_thumb, center = 0, 72, 36
    local x =  { 0, 107, max_thumb * 2.5, max_thumb * 5 }
    local y_off = finenv.UI():IsOnMac() and 3 or 0
    local max, button_wide = layer.max_layers(), 107
    local save_layer = config.layer_num
    local answer = {}
    --
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Shift Rests")
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 500, 435)
            refocus_document = true
        end
        local function yd(diff)
            y = diff and (y + diff) or (y + 25)
        end
        local function shift_rests(shift, float)
            local id = string.format("%s %s L-%d pos%d", name, selection.region, save_layer, shift)
            if config.modeless == 1 then finenv.StartNewUndoBlock(id, false) end
            for entry in eachentrysaved(finenv.Region(), save_layer) do
                if entry:IsRest() then
                    offset_rest(entry, shift, float)
                end
            end
            if config.modeless == 1 then finenv.EndUndoBlock(true) end
            finenv.Region():Redraw()
        end
        local function set_value(thumb, float, set_thumb)
            local pos = thumb - center
            local sign = pos > 0 and "[ +" or "[ "
            answer.value:SetText(sign .. pos .. " ]")
            shift_rests(pos, float)
            if set_thumb then answer.slider:SetThumbPosition(thumb) end
        end
        local function set_zero(float)
            set_value(center, float, true)
        end
        local function nudge_thumb(add)
            local thumb = answer.slider:GetThumbPosition()
            if (add < 0 and thumb > 0) or (add > 0 and thumb < max_thumb) then
                thumb = thumb + add
                set_value(thumb, false, true)
            end
        end
        local function set_midstaff(direction)
            if adjacent_offsets[direction] then
                local n = adjacent_offsets[direction] + center
                set_value(n, false, true)
            end
        end
        local function invert_shift()
            local n = (answer.slider:GetThumbPosition() - center) * -1
            set_value(n + center, false, true)
        end
        local function key_change() -- key command replacements in layer_num box
            local val = answer.layer_num:GetText():lower()
            if val == "" then
                answer.layer_num:SetText("0")
                save_layer = 0
            else
                if val:find("[^0-" .. max .. "]") then
                    if val:find("[?q]") then show_info()
                    elseif val:find("[-a_%[]") then nudge_thumb(-1)
                    elseif val:find("[+s=%]]") then nudge_thumb(1)
                    elseif val:find("d") then set_midstaff("above")
                    elseif val:find("f") then set_midstaff("below")
                    elseif val:find("z") then set_zero(false)
                    elseif val:find("x") then set_zero(true)
                    elseif val:find("i") then invert_shift()
                    end
                    answer.layer_num:SetText(save_layer):SetKeyboardFocus()
                else
                    val = val:sub(-1)
                    local n = tonumber(val) or 0
                    if save_layer ~= 0 and save_layer ~= n then
                        save_layer = n
                        first_offset = first_rest_offset(n)
                        set_value(first_offset + center, false, true)
                    end
                    answer.layer_num:SetText(n)
                    save_layer = n
                end
            end
        end
        local function on_timer() -- look for changes in selected region
            for prop, value in pairs(saved_bounds) do
                if finenv.Region()[prop] ~= value then -- selection changed
                    set_saved_bounds() -- save new selection bounds
                    update_selection() -- update selection ID
                    dialog:GetControl("info"):SetText(selection.staff .. ": " .. selection.region)
                    set_adjacent_offsets() -- get new mid-staff offsets (if any)
                    dialog:GetControl("above"):SetEnable(adjacent_offsets.above ~= nil)
                    dialog:GetControl("below"):SetEnable(adjacent_offsets.below ~= nil)
                    break -- all done
                end
            end
        end
    -- draw dialog contents
    dialog:CreateStatic(0, y, "info"):SetWidth(x[4]):SetText(selection.staff .. ": " .. selection.region)
    yd()
    answer.slider = dialog:CreateSlider(0, y):SetMinValue(0):SetMaxValue(max_thumb)
        :SetWidth(x[4]):SetThumbPosition(first_offset + center)
        :AddHandleCommand(function(self) set_value(self:GetThumbPosition(), false, false) end)
    yd(32)
    dialog:CreateStatic(0, y):SetWidth(x[2]):SetText("Layer 1-" .. max .. " (0 = all):")
    answer.layer_num = dialog:CreateEdit(x[2], y - y_off):SetWidth(20):SetText(save_layer)
        :AddHandleCommand(function() key_change() end )
    answer.value = dialog:CreateStatic(x[3] - 12, y):SetWidth(75)
    set_value(first_offset + center, false, false) -- preset slider and all selected rests

    dialog:CreateButton(x[4] - 110, y):SetText("reset zero (z)"):SetWidth(button_wide)
        :AddHandleCommand(function() set_zero() end)
    yd()
    local q = dialog:CreateButton(0, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateButton(25, y, "above"):SetText("mid-staff above (d)"):SetWidth(button_wide)
        :SetEnable(adjacent_offsets.above ~= nil)
        :AddHandleCommand(function() set_midstaff("above") end)
    dialog:CreateButton(137, y, "below"):SetText("mid-staff below (f)"):SetWidth(button_wide)
        :SetEnable(adjacent_offsets.below ~= nil)
        :AddHandleCommand(function() set_midstaff("below") end)
    dialog:CreateButton(x[4] - 110, y):SetText("floating rests (x)")
        :SetWidth(button_wide):AddHandleCommand(function() set_zero(true) end)
    yd()
    answer.modeless = dialog:CreateCheckbox(0, y):SetWidth(x[4]):SetCheck(config.modeless)
        :SetText("Modeless Operation (\"floating\" dialog window)")
    -- wrap it up
    dialog:CreateOkButton():SetText(config.modeless == 0 and "OK" or "Apply")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    if config.modeless == 1 then
        dialog:RegisterHandleTimer(on_timer)
        dialog:RegisterHandleOkButtonPressed(function()
            save_rest_positions() -- save rest positions so "Close" leaves correct positions
        end)
    end
    dialog:RegisterInitWindow(function(self)
        if config.modeless == 1 then self:SetTimer(config.timer_id, 125) end
        q:SetFont(q:CreateFontInfo():SetBold(true))
        answer.layer_num:SetKeyboardFocus()
    end)
    dialog:SetOkButtonCanClose(config.modeless == 0)
    dialog:RegisterCloseWindow(function(self)
        config.layer_num = answer.layer_num:GetInteger()
        config.modeless = answer.modeless:GetCheck()
        dialog_save_position(self)
        if config.modeless == 1 then
            self:StopTimer(config.timer_id)
            restore_rest_positions()
        end
    end)
    if config.modeless == 1 then -- "modeless"
        dialog:RunModeless()
    else -- "modal"
        if (dialog:ExecuteModal() ~= finale.EXECMODAL_OK) then
            restore_rest_positions()
            if refocus_document then finenv.UI():ActivateDocumentWindow() end
        end
    end
end

local function slide_rests()
    configuration.get_user_settings(script_name, config)
    if finenv.Region():IsEmpty() then
        finenv.UI():AlertError(
            "Please select some music before\nrunning this script.",
            name
        )
        return
    end
    -- initialise parameters
    set_saved_bounds()
    update_selection()
    set_adjacent_offsets()
    save_rest_positions()
    run_the_dialog_box()
end

slide_rests()
