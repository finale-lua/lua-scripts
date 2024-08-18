function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.47" -- reverting to MODAL-only operation
    finaleplugin.Date = "2024/08/18"
    finaleplugin.CategoryTags = "Rests, Selection"
    finaleplugin.MinJWLuaVersion = 0.72
    finaleplugin.Notes = [[
        Slide rests up and down on the nominated layer with continuous visual feedback. 
        If a single staff is selected then the __Mid-Staff Above__ and __Mid-Staff Below__ 
        buttons align rests midway between adjacent staves with one click. 
        (The __midpoint__ is measured in __Page View__ and may look different 
        in __Scroll View__). __Cancel__ the action to leave rests unchanged. 

        __Reset Zero__ sets nil offset. 
        On transposing instruments this is __not__ the middle 
        of the staff if _Display in Concert Pitch_ is selected. 
        In those cases use _Floating Rests_ to return them to 
        their virgin state where the offset is determined by  
        _Document_ → _Document Options_ → _Layers_ → _Adjust Floating Rests by..._

        At startup all rests in the chosen layer are moved to the 
        same offset as the first rest on that layer. 
        Rests can be changed on multiple layers in the one action. 

        > If __Layer Number__ is highlighted these __Key Commands__ are available: 

        > - __a__ (__-__): move rests down one step 
        > - __s__ (__+__): move rests up one step 
        > - __d__: shift to mid-staff above (if one staff selected) 
        > - __f__: shift to mid-staff below (if one staff selected) 
        > - __z__: reset to "zero" shift (not floating) 
        > - __x__: make floating
        > - __c__: invert shift direction 
        > - __q__: show these script notes 
        > - __0-4__: layer number (delete key not needed) 
    ]]
    return "Rest Slider...",
        "Rest Slider",
        "Slide rests up and down with continuous visual feedback"
end

local hotkeys = { -- customise command hotkeys
    downstep  = "[-a]", -- either "-" or "a"
    upstep    = "[+s]", -- either "+" or "s"
    mid_above = "d",
    mid_below = "f",
    zero      = "z",
    float     = "x",
    invert    = "c",
    show_info = "q",
}
local config = {
    layer_num = 0,
    window_pos_x = false,
    window_pos_y = false
}
local mixin = require("library.mixin")
local layer = require("library.layer")
local configuration = require("library.configuration")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()

local first_offset = 0 -- set to real offset of first rest (in layer_num) in selection
local refocus_document = false
local adjacent_offsets, save_displacement = {}, {}
local name = plugindef():gsub("%.%.%.", "")
local save_layer = 0
local rgn = finenv.Region() -- current selection is the only region required

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

local function get_selection_text()
    local s = get_staff_name(rgn.StartStaff)
    if rgn.EndStaff ~= rgn.StartStaff then
        s = s .. "-" .. get_staff_name(rgn.EndStaff)
    end
    s = s .. " m." .. rgn.StartMeasure
    if rgn.StartMeasure ~= rgn.EndMeasure then
        s = s .. "-" .. rgn.EndMeasure
    end
    return s
end

local function get_rest_offset(entry)
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

local function set_first_offset()
    first_offset = 0
    for entry in eachentry(rgn, save_layer) do
        if entry:IsRest() then
            if not entry.FloatingRest then
                first_offset = entry:GetRestDisplacement() + get_rest_offset(entry)
            end
            break -- only need the first offset rest
        end
    end
end

local function save_rest_positions()
    save_displacement = {} -- empty the table
    for entry in eachentry(rgn) do -- all rests in all layers
        if entry:IsRest() then
            save_displacement[entry.EntryNumber] = {
                entry:GetRestDisplacement(), entry.FloatingRest
            }
        end
    end
end

local function restore_rest_positions()
    for entry in eachentrysaved(rgn) do
        if entry:IsRest() then
            local disp = save_displacement[entry.EntryNumber]
            if disp then
                entry:SetRestDisplacement(disp[1])
                entry:SetFloatingRest(disp[2])
            end
        end
    end
    rgn:Redraw()
end

local function set_adjacent_offsets()
    if rgn.StartStaff ~= rgn.EndStaff then return end
    -- "Adjacent Offsets" require selection on a single staff
    local start_slot = rgn.StartSlot
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
    local sys_staff = system_staves:FindStaff(rgn.StartStaff)
    if sys_staff then
        local start_position = sys_staff.Distance
        for key, staff_num in pairs(next_staff) do -- find 0, 1 or 2 adjacent_offsets
            sys_staff = system_staves:FindStaff(staff_num)
            local n = start_position - sys_staff.Distance
            adjacent_offsets[key] = math.floor(n / 24) -- convert EVPU to HALF steps
        end
    end
end

local function run_user_dialog()
    local y, max_thumb, center = 0, 72, 36
    local x =  { 62, 108, max_thumb * 2.5, max_thumb * 5 }
    local y_off = finenv.UI():IsOnMac() and 3 or 0
    local max, button_wide = layer.max_layers(), 107
    local answer = {}

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 450, 370)
            refocus_document = true
        end
        local function yd(diff) y = y + (diff or 25) end
        local function shift_rests(shift, float)
            for entry in eachentrysaved(rgn, save_layer) do
                if entry:IsRest() then
                    if float then
                        entry:SetFloatingRest(true)
                    else
                        local off = shift - get_rest_offset(entry)
                        entry:SetRestDisplacement(entry:GetRestDisplacement() + off)
                    end
                end
            end
            rgn:Redraw()
        end
        local function set_value(thumb, float, set_thumb)
            local pos = thumb - center
            local sign = (pos > 0) and "[ +" or "[ "
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
        local function set_midstaff(direction) -- "above" or "below"
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
            if val:find("[^0-" .. max .. "]") then
                if     val:find(hotkeys.show_info) then show_info()
                elseif val:find(hotkeys.mid_above) then set_midstaff("above")
                elseif val:find(hotkeys.mid_below) then set_midstaff("below")
                elseif val:find(hotkeys.zero)      then set_zero(false)
                elseif val:find(hotkeys.float)     then set_zero(true)
                elseif val:find(hotkeys.invert)    then invert_shift()
                elseif val:find(hotkeys.downstep)  then nudge_thumb(-1)
                elseif val:find(hotkeys.upstep)    then nudge_thumb( 1)
                end
            else
                local new_layer = tonumber(val:sub(-1)) or 0
                if new_layer ~= save_layer then
                    save_layer = new_layer
                    set_first_offset() -- check disposition of new layer
                    set_value(first_offset + center, false, true)
                end
            end
            answer.layer_num:SetInteger(save_layer):SetKeyboardFocus()
        end

    -- draw dialog contents
    dialog:CreateStatic(0, y):SetWidth(x[4]):SetText(get_selection_text())
    yd(18)
    answer.slider = dialog:CreateSlider(0, y):SetMinValue(0):SetMaxValue(max_thumb)
        :SetWidth(x[4]):SetThumbPosition(first_offset + center)
        :AddHandleCommand(function(self) set_value(self:GetThumbPosition(), false, false) end)
    yd()
    dialog:CreateStatic(0, y):SetWidth(x[1]):SetText("Layer 1-" .. max .. ":")
    answer.layer_num = dialog:CreateEdit(x[1], y - y_off):SetWidth(20):SetInteger(save_layer)
        :AddHandleCommand(function() key_change() end )
    dialog:CreateStatic(x[1] + 23, y):SetWidth(x[2]):SetText("(0 = all)")
    answer.value = dialog:CreateStatic(x[3] - 12, y):SetWidth(75)
    set_value(first_offset + center, false, false) -- preset slider and all selected rests

    dialog:CreateButton(x[4] - 110, y):SetText("Reset Zero (" .. hotkeys.zero .. ")")
        :AddHandleCommand(function() set_zero(false) end):SetWidth(button_wide)
    yd()
    answer.q = dialog:CreateButton(0, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateButton(25, y, "above"):SetText("mid-staff above (" .. hotkeys.mid_above .. ")")
        :SetEnable(adjacent_offsets.above ~= nil):SetWidth(button_wide)
        :AddHandleCommand(function() set_midstaff("above") end)
    dialog:CreateButton(137, y, "below"):SetText("mid-staff below (" .. hotkeys.mid_below .. ")")
        :SetEnable(adjacent_offsets.below ~= nil):SetWidth(button_wide)
        :AddHandleCommand(function() set_midstaff("below") end)
    dialog:CreateButton(x[4] - 110, y):SetText("Floating Rests (" .. hotkeys.float .. ")")
        :SetWidth(button_wide):AddHandleCommand(function() set_zero(true) end)
    -- wrap it up
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function()
        answer.q:SetFont(answer.q:CreateFontInfo():SetBold(true))
        answer.layer_num:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.layer_num = answer.layer_num:GetInteger()
    end)
    dialog:RegisterHandleCancelButtonPressed(function() restore_rest_positions() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:ExecuteModal()
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

local function slide_rests()
    if rgn:IsEmpty() then
        finenv.UI():AlertError("Please select some music\nbefore running this script.", name)
        return
    end
    configuration.get_user_settings(script_name, config)
    save_layer = config.layer_num
    set_first_offset()
    set_adjacent_offsets()
    save_rest_positions()
    run_user_dialog()
end

slide_rests()
