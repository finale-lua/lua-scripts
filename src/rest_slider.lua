function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.09"
    finaleplugin.Date = "2023/12/03"
    finaleplugin.CategoryTags = "Rests, Selection"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = [[
        Slide rests up and down on the nominated layer with continuous visual feedback. 
        This was designed specifically to help align rests midway 
        between staves with cross-staff notes. 
        With music selected from one staff the "mid-staff above" and 
        "mid-staff below" buttons achieve this with one click. 
        Cancel the script to leave rests unchanged.

        "Reset Zero" sets nil offset. 
        With transposing instruments, however, this is NOT the middle 
        of the staff if "Display in Concert Pitch" is selected. 
        In those instances use "Floating Rests" to return them to 
        their virgin state where the only offset is that set at 
        Document → Document Options → Layers → Adjust Floating Rests by...  

        KEY COMMANDS:  
        - [a] [+] move rests up by single steps  
        - [s] [-] move rests down by single steps  
        - [d] move to mid-staff above (if one staff selected)
        - [f] move to mid-staff below (if one staff selected)
        - [z] reset to "zero" shift (not floating)  
        - [x] floating rests  
        - [q] show these script notes  
        - [0]-[4] layer number (delete key not needed)
    ]]
    return "Rest Slider...", "Rest Slider", "Slide rests up and down with continuous visual feedback"
end

local info_notes = [[
Slide rests up and down on the nominated layer with continuous visual feedback.
This was designed specifically to help align rests midway
between staves with cross-staff notes.
With music selected from one staff the "mid-staff above" and
"mid-staff below" buttons achieve this with one click.
Cancel the script to leave rests unchanged.
**
"Reset Zero" sets nil offset.
With transposing instruments, however, this is NOT the middle
of the staff if "Display in Concert Pitch" is selected.
In those instances use "Floating Rests" to return them to
their virgin state where the only offset is that set at
Document → Document Options → Layers → Adjust Floating Rests by...
**
Key Commands:
*• [a] [+] move rests up by single steps
*• [s] [-] move rests down by single steps
*• [d] move to mid-staff above (if one staff selected)
*• [f] move to mid-staff below (if one staff selected)
*• [z] reset to "zero" shift (not floating)
*• [x] floating rests  
*• [q] show these script notes  
*• [0]-[4] layer number (delete key not needed)
]]

info_notes = info_notes:gsub("\n%s*", " "):gsub("*", "\n")

local config = {
    layer_num = 0,
    offset = 0,
    window_pos_x = false,
    window_pos_y = false
}
local mixin = require("library.mixin")
local layer = require("library.layer")
local note_entry = require("library.note_entry")
local configuration = require("library.configuration")
local script_name = "rest_slider"
local save_displacement = {}

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

local function adjacent_staff_offsets(rgn)
    local start = {
        staff = rgn.StartStaff,
        slot  = rgn:CalcSlotNumber(rgn.StartStaff)
    }
    local adjacent, offset = {}, {}

    if rgn.StartStaff == rgn.EndStaff then -- single staff selection required
        local stack = mixin.FCMMusicRegion()
        stack:SetRegion(rgn):SetFullMeasureStack()
        if start.slot > 1 then
            adjacent.above = stack:CalcStaffNumber(start.slot - 1)
        end
        if start.slot < stack.EndSlot then
            adjacent.below = stack:CalcStaffNumber(start.slot + 1)
        end
        local system_staves = finale.FCSystemStaves()
        system_staves:LoadAllForRegion(stack)
        local sys_staff = system_staves:FindStaff(start.staff)
        start.position = sys_staff.Distance

        for key, staff_num in pairs(adjacent) do -- find 2(?) staff offsets
            sys_staff = system_staves:FindStaff(staff_num)
            local n = start.position - sys_staff.Distance
            offset[key] = math.floor(n / 24) -- convert EVPU to (half) steps
        end
    end
    return offset
end

local function save_rests(rgn)
    for entry in eachentrysaved(rgn) do
        if entry:IsRest() then
            save_displacement[entry.EntryNumber] = {
                entry:GetRestDisplacement(),
                entry.FloatingRest
            }
        end
    end
end

local function restore_rests(rgn)
    for entry in eachentrysaved(rgn) do
        local v = save_displacement[entry.EntryNumber]
        if entry:IsRest() and v ~= nil then
            entry:SetRestDisplacement(v[1])
            entry.FloatingRest = v[2]
        end
    end
    rgn:Redraw()
end

local function user_chooses(rgn)
    local max_thumb, center = 72, 36
    local y, x =  0, { 0, 107, max_thumb * 2.5, max_thumb * 5 }
    local y_off = finenv.UI():IsOnMac() and 3 or 0
    local max, butt_wide = layer.max_layers(), 100
    local save_layer, answer = config.layer_num, {}
    local mid_offset = adjacent_staff_offsets(rgn)

        local function shift_rests(shift)
            for entry in eachentrysaved(rgn, save_layer) do
                if entry:IsRest() then
                    note_entry.rest_offset(entry, shift)
                end
            end
            rgn:Redraw()
        end
        local function set_value(thumb)
            local pos = thumb - center
            local sign = pos > 0 and "[ +" or "[ "
            answer.value:SetText(sign .. pos .. " ]")
            shift_rests(pos)
            if answer.layer_num:GetText() == "" then
                answer.layer_num:SetText("0")
                save_layer = 0
            end
        end
        local function set_zero()
            set_value(center)
            answer.slider:SetThumbPosition(center)
        end
        local function yd(diff)
            y = diff and y + diff or y + 25
        end
        local function show_info()
            finenv.UI():AlertInfo(info_notes, "About " .. plugindef())
        end
        local function increment(add)
            local thumb = answer.slider:GetThumbPosition()
            if (add < 0 and thumb > 0) or (add > 0 and thumb < max_thumb) then
                thumb = thumb + add
                answer.slider:SetThumbPosition(thumb)
                set_value(thumb)
            end
        end
        local function floating_rests()
            set_zero()
            for entry in eachentrysaved(rgn) do
                if entry:IsRest() then
                    entry.FloatingRest = true
                end
            end
            rgn:Redraw()
        end
        local function set_midstaff(direction)
            if mid_offset[direction] then
                local n = mid_offset[direction] + center
                set_value(n)
                answer.slider:SetThumbPosition(n)
            end
        end
        local function key_change(ctl) -- key command replacements in layer_num box
            local val = ctl:GetText():lower()
            if val:find("[^0-4]") then
                if val:find("[?q]") then show_info()
                elseif val:find("[-a]") then increment(-1)
                elseif val:find("[+s]") then increment(1)
                elseif val:find("d") then set_midstaff("above")
                elseif val:find("f") then set_midstaff("below")
                elseif val:find("z") then set_zero()
                elseif val:find("x") then floating_rests()
                end
                ctl:SetText(save_layer):SetKeyboardFocus()
            elseif val ~= "" then
                val = val:sub(-1)
                local n = tonumber(val) or 0
                if save_layer ~= 0 and save_layer ~= n then
                    save_layer = n
                    shift_rests(answer.slider:GetThumbPosition() - center)
                end
                ctl:SetText(val)
                save_layer = n
            end
        end

    -- start dialog
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    answer.slider = dialog:CreateSlider(0, y):SetMinValue(0):SetMaxValue(max_thumb)
        :SetWidth(x[4]):SetThumbPosition(config.offset + center)
        :AddHandleCommand(function(self) set_value(self:GetThumbPosition()) end)
    shift_rests(config.offset)
    yd()
    dialog:CreateStatic(0, y):SetWidth(x[2]):SetText("Layer 1-" .. max .. " (0 = all):")
    save_layer = config.layer_num
    answer.layer_num = dialog:CreateEdit(x[2], y - y_off):SetWidth(20):SetText(save_layer)
        :AddHandleCommand(function(self) key_change(self) end )
    answer.value = dialog:CreateStatic(x[3] - 12, y):SetWidth(75)
    dialog:CreateButton(x[4] - 110, y):SetText("reset zero (z)"):SetWidth(butt_wide)
        :AddHandleCommand(function() set_zero() end)
    yd()
    dialog:CreateButton(0, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateButton(x[4] - 110, y):SetText("floating rests (x)"):SetWidth(butt_wide)
        :AddHandleCommand(function() floating_rests() end)

    -- provide mid-staff buttons?
    if rgn.StartStaff ~= rgn.EndStaff then -- more than one staff selected
        dialog:CreateVerticalLine(45, y - 5, 30)
        dialog:CreateStatic(50, y - 5):SetWidth(x[4] - 50)
            :SetText("select music in a single staff to \n"
                ..   "enable auto mid-staff rest shifts"):SetHeight(35)
    else
        if mid_offset.above then
            dialog:CreateButton(30, y):SetText("mid-staff above"):SetWidth(butt_wide)
            :AddHandleCommand(function() set_midstaff("above") end)
        end
        if mid_offset.below then
            dialog:CreateButton(135, y):SetText("mid-staff below"):SetWidth(butt_wide)
            :AddHandleCommand(function() set_midstaff("below") end)
        end
    end

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function() set_value(config.offset + center) end)
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        config.offset = answer.slider:GetThumbPosition() - center
        config.layer_num = answer.layer_num:GetInteger()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function slide_rests()
    configuration.get_user_settings(script_name, config)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(finenv.Region())
    save_rests(rgn)
    if not user_chooses(rgn) then
        restore_rests(rgn)
    end
end

slide_rests()
