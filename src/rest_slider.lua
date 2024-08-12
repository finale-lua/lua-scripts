function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.45"
    finaleplugin.Date = "2024/08/06" -- had to remove "RegisterMouseTracking()" process
    finaleplugin.CategoryTags = "Rests, Selection"
    finaleplugin.MinJWLuaVersion = 0.72
    finaleplugin.Notes = [[
        Slide rests up and down on the nominated layer with continuous visual feedback. 
        If a single staff is selected, the __Mid-Staff Above__ and __Mid-Staff Below__ 
        buttons align rests midway between adjacent staves with one click. 
        (The __midpoint__ is measured in __Page View__ and may look different 
        in __Scroll View__). _Cancel_ or _Close_ the script to leave rests unchanged. 

        __Reset Zero__ sets nil offset. 
        On transposing instruments this is __not__ the middle 
        of the staff if _Display in Concert Pitch_ is selected. 
        In those cases use _Floating Rests_ to return them to 
        their virgin state where the offset is determined by  
        _Document_ → _Document Options_ → _Layers_ → _Adjust Floating Rests by..._

        At startup all rests in the chosen layer are moved to the 
        same offset as the first rest on that layer. 
        Layer numbers can be changed _on the fly_ to balance rests across multiple layers. 
        Select __Modeless Dialog__ if you want the dialog window to persist 
        on-screen for repeated use until you click __Close__ [_Escape_]. 
        Rests on the current layer are then only __fixed__ in their new 
        position after clicking __Apply__, 
        otherwise they will revert to their _original_ state when 
        the selected region or layer changes, or the dialog is closed. 
        Cancelling __Modeless__ will apply the _next_ time you use the script.

        > If __Layer Number__ is highlighted these __Key Commands__ are available: 

        > - __a__ (__-__): move rests down one step 
        > - __s__ (__+__): move rests up one step 
        > - __d__: move to mid-staff above (if one staff selected) 
        > - __f__: move to mid-staff below (if one staff selected) 
        > - __z__: reset to "zero" shift (not floating) 
        > - __x__: floating rests 
        > - __c__: invert shift direction 
        > - __q__: show these script notes 
        > - __m__: toggle __Modeless__ 
        > - __0-4__: layer number (delete key not needed) 
    ]]
    return "Rest Slider...", "Rest Slider", "Slide rests up and down with continuous visual feedback"
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
    modeless  = "m",
}
local config = {
    layer_num = 0,
    timer_id = 1,
    modeless = false, -- false = modal / true = modeless operation
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
local save_displacement, adjacent_offsets = {}, {}
local selection, empty_region
local name = plugindef():gsub("%.%.%.", "")
local save_rgn = finale.FCMusicRegion()
local save_layer = 0

local function nil_region_error(dialog)
    if finenv.Region():IsEmpty() then
        local ui = dialog and dialog:CreateChildUI() or finenv.UI()
        ui:AlertError("Please select some music\nbefore running this script.", name)
        return true
    end
    return false
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


local function start_undo_block(shift)
    local id = string.format("RestSlide %s L%d", selection, save_layer)
    if shift and shift ~= 0 then
        id = id .. (shift > 0 and " +" or " ") .. shift
    end
    finenv.StartNewUndoBlock(id, false)
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

local function save_rest_positions(layer_num)
    first_offset = 0
    save_displacement = {} -- start with empty table
    if empty_region then return end

    local got_first = false
    for entry in eachentry(finenv.Region(), layer_num) do
        if entry:IsRest() then
            local disp = entry:GetRestDisplacement()
            if not got_first then
                got_first = true
                if not entry.FloatingRest then
                    first_offset = disp + get_rest_offset(entry)
                end
            end
            save_displacement[entry.EntryNumber] = { disp, entry.FloatingRest }
        end
    end
end

local function restore_rest_positions()
    if save_rgn:IsEmpty() then return end
    start_undo_block()
    for entry in eachentrysaved(save_rgn, save_layer) do
        if entry:IsRest() then
            local disp = save_displacement[entry.EntryNumber]
            if disp then
                entry:SetRestDisplacement(disp[1])
                entry:SetFloatingRest(disp[2])
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
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

local function setup_data()
    save_rgn:SetCurrentSelection() -- update "saved" region
    selection = "no selection" -- default listing
    adjacent_offsets = {} -- start with blank collection
    if empty_region then return end -- nothing else to set up

    -- measures
    local rgn = finenv.Region()
    selection = "m." .. rgn.StartMeasure
    if rgn.StartMeasure ~= rgn.EndMeasure then
        selection = selection .. "-" .. rgn.EndMeasure
    end
    -- staves
    selection = selection .. " " .. get_staff_name(rgn.StartStaff)
    if rgn.StartStaff ~= rgn.EndStaff then
        selection = selection .. "-" .. get_staff_name(rgn.EndStaff)
        return -- all done for single staff selection
    end

    -- set_adjacent_offsets (single staff required)
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
    local x =  { 0, 107, max_thumb * 2.5, max_thumb * 5 }
    local y_off = finenv.UI():IsOnMac() and 3 or 0
    local max, button_wide = layer.max_layers(), 107
    local answer = {}

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 450, 480)
            refocus_document = true
        end
        local function yd(diff) y = y + (diff or 25) end
        local function shift_rests(shift, float)
            if nil_region_error(dialog) then return end
            start_undo_block(shift)
            for entry in eachentrysaved(finenv.Region(), save_layer) do
                if entry:IsRest() then
                    if float then
                        entry:SetFloatingRest(true)
                    else
                        local offset = get_rest_offset(entry)
                        entry:SetRestDisplacement(entry:GetRestDisplacement() + shift - offset)
                    end
                end
            end
            finenv.EndUndoBlock(true)
            finenv.Region():Redraw()
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
        local function reset_all_values(new_layer)
            restore_rest_positions() -- on "old" region
            setup_data() -- reset all selection variables with new selection/layer
            save_layer = new_layer
            save_rest_positions(new_layer)
            if not empty_region then
                set_value(first_offset + center, false, true)
            end
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
                elseif val:find(hotkeys.modeless)  then
                    answer.modeless:SetCheck((answer.modeless:GetCheck() + 1) % 2)
                end
            else
                local new_layer = tonumber(val:sub(-1)) or 0
                if new_layer ~= save_layer then reset_all_values(new_layer) end
            end
            answer.layer_num:SetInteger(save_layer):SetKeyboardFocus()
        end
        local function on_timer() -- find changes in selected region
            local update = false
            empty_region = finenv.Region():IsEmpty()
            if empty_region ~= save_rgn:IsEmpty() then -- just became empty or full
                update = true
            else
                for _, v in ipairs{ -- region bounds
                        "StartStaff", "StartMeasure", "StartMeasurePos",
                        "EndStaff",   "EndMeasure",   "EndMeasurePos",
                    } do
                    if finenv.Region()[v] ~= save_rgn[v] then
                        update = true
                        break -- all done
                    end
                end
            end
            if update then
                reset_all_values(save_layer)
                dialog:GetControl("info"):SetText(selection)
                dialog:GetControl("above"):SetEnable(adjacent_offsets.above ~= nil)
                dialog:GetControl("below"):SetEnable(adjacent_offsets.below ~= nil)
            end
        end
    -- draw dialog contents
    dialog:CreateStatic(0, y, "info"):SetWidth(x[4]):SetText(selection)
    yd()
    answer.slider = dialog:CreateSlider(0, y):SetMinValue(0):SetMaxValue(max_thumb)
        :SetWidth(x[4]):SetThumbPosition(first_offset + center)
        :AddHandleCommand(function(self) set_value(self:GetThumbPosition(), false, false) end)
    yd(32)
    dialog:CreateStatic(0, y):SetWidth(x[2]):SetText("Layer 1-" .. max .. " (0 = all):")
    answer.layer_num = dialog:CreateEdit(x[2], y - y_off):SetWidth(20):SetInteger(save_layer)
        :AddHandleCommand(function() key_change() end )
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
    yd()
    answer.modeless = dialog:CreateCheckbox(0, y):SetWidth(x[4]):SetCheck(config.modeless and 1 or 0)
        :SetText("Modeless Operation (" .. hotkeys.modeless .. ")")
    -- wrap it up
    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton():SetText(config.modeless and "Close" or "Cancel")
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterInitWindow(function(self)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
        answer.q:SetFont(answer.q:CreateFontInfo():SetBold(true))
        answer.layer_num:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function() save_rest_positions(save_layer) end)
    local change_mode = false
    dialog:RegisterCloseWindow(function(self)
        if config.modeless then self:StopTimer(config.timer_id) end
        restore_rest_positions()
        local mode = (answer.modeless:GetCheck() == 1)
        change_mode = (mode and not config.modeless) -- modal -> modeless?
        config.modeless = mode
        config.layer_num = answer.layer_num:GetInteger()
        dialog_save_position(self)
        finenv.EndUndoBlock(true)
    end)
    if config.modeless then
        dialog:RunModeless()
    else
        dialog:ExecuteModal()
        if refocus_document then finenv.UI():ActivateDocumentWindow() end
    end
    return change_mode
end

local function slide_rests()
    configuration.get_user_settings(script_name, config)
    empty_region = finenv.Region():IsEmpty()
    if not config.modeless and nil_region_error() then return end

    save_layer = config.layer_num
    setup_data()
    save_rest_positions(save_layer)
    while run_user_dialog() do end
end

slide_rests()
