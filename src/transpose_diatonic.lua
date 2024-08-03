function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.18"
    finaleplugin.Date = "2024/07/29"
    finaleplugin.MinJWLuaVersion = 0.72
    finaleplugin.CategoryTags = "Pitch, Transposition"
    finaleplugin.ScriptGroupName = "Transpose Diatonic"
    finaleplugin.Notes = [[
        Notes and chords in the current music selection are 
        transposed up or down by the chosen diatonic interval. 
        Affect all layers or just one. 
        To repeat the last action without a confirmation dialog 
        hold down [Shift] when starting the script. 

        Select __Modeless Dialog__ if you want the dialog window to persist 
        on-screen for repeated use until you click __Close__ [_Escape_]. 
        Cancelling __Modeless__ will apply the _next_ 
        time you use the script.

        > These key commands are available  
        > if a _numeric_ field is highlighted: 

        > - __1-8__: interval (unison, 2nd, 3rd, .. 8ve) 
        > - __0-8__: extra octave 
        > - __0-4__: layer number (__0__ = all layers) 
        > - (delete key not needed in numeric fields)  
        > - __q__: show this script information 
        > - __z__: toggle _Up/Down_
        > - __x__: toggle _Preserve Existing Notes_
        > - __m__: toggle _Modeless_
	]]
   return "Transpose Diatonic...", "Transpose Diatonic",
        "Transpose notes and chords up or down by the chosen diatonic interval"
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local transposition = require("library.transposition")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false
local selection
local interval_names = { "unis.", "2nd", "3rd", "4th", "5th", "6th", "7th", "8ve"}
local saved_bounds = {}

local config = { -- over-written by saved user data
    interval     = 1,     -- 1 = unison; 2 = second etc.
    octave       = 0,
    layer        = 0,
    direction    = 0,     -- 0 = up / 1 = down (popup item number)
    modeless     = false, -- false = modal / true = modeless
    do_preserve  = false, -- bool "Preserve Exisiting Notes"
    timer_id     = 1,
    window_pos_x = false,
    window_pos_y = false,
}
local numerics = { -- edit boxes: key / text
    { "interval", "Diatonic Interval:" },
    { "octave", "Extra Octaves:" },
    { "layer",  "Layer Number:" },
}
local checks = { -- checkboxes: key / text
    { "do_preserve", "Preserve Existing Notes" },
    { "modeless",    "Modeless Dialog" }
}
local hotkey = { -- customise hotkeys
    show_info   = "q",
    direction   = "z",
    do_preserve = "x",
    modeless    = "m",
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

local function update_selection()
    local rgn = finenv.Region()
    selection = "no staff, no selection" -- empty default
    if not rgn:IsEmpty() then
        local bounds = { -- selection boundaries
            "StartStaff", "StartMeasure", "StartMeasurePos",
            "EndStaff",   "EndMeasure",   "EndMeasurePos",
        }
        for _, prop in ipairs(bounds) do
            saved_bounds[prop] = rgn[prop]
        end
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

local function nil_region_error(dialog)
    if finenv.Region():IsEmpty() then
        local ui = dialog and dialog:CreateChildUI() or finenv.UI()
        ui:AlertError(
            "Please select some music\nbefore running this script.",
            finaleplugin.ScriptGroupName
        )
        return true
    end
    return false
end

local function transpose_diatonic(dialog)
    if nil_region_error(dialog) then return end -- empty -> do nothing
    local direction = (config.direction * -2) + 1
    local shift = ((config.octave * 7) + config.interval - 1) * direction
    if shift ~= 0 then
        finenv.StartNewUndoBlock(
            string.format("Transp. Diat. %s %s",
                (config.direction == 0 and "Up" or "Dn"), selection),
            false
        )
        for entry in eachentrysaved(finenv.Region(), config.layer) do
            transposition.entry_diatonic_transpose(entry, shift, config.do_preserve)
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local max = finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4
    local y, y_inc, x_step = 0, 21, 95
    local save, answer = {}, {}
    for _, v in ipairs(numerics) do save[v[1]] = config[v[1]] end

    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Transpose")
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. finaleplugin.ScriptGroupName, 400, 320)
            refocus_document = true
        end
        local function dy(diff) y = y + (diff or y_inc) end
        local function cs(cx, cy, ctext, cwide)
            local stat = dialog:CreateStatic(cx, cy):SetText(ctext)
            local _ = cwide and stat:SetWidth(cwide) or stat:DoAutoResizeWidth()
            return stat
        end
        local function toggle_check(id)
            answer[id]:SetCheck((answer[id]:GetCheck() + 1) % 2)
        end
        local function key_command(id) -- key command replacements
            local s = answer[id]:GetText():lower()
            if     s:find("[^0-8]")
                or (id == "layer" and s:find("[^0-" .. max .. "]"))
                or (id == "interval" and s:find("0"))
                    then
                if s:find(hotkey.direction) then -- flip direction
                    local n = answer.direction:GetSelectedItem()
                    answer.direction:SetSelectedItem((n + 1) % 2)
                elseif s:find(hotkey.modeless) then toggle_check("modeless")
                elseif s:find(hotkey.do_preserve) then toggle_check("do_preserve")
                elseif s:find(hotkey.show_info) then show_info()
                end
            else
                save[id] = s:sub(-1)
                if save[id] == "" then save[id] = "0" end
                if id == "interval" then
                    if save[id] == "0" then save[id] = "1" end
                    answer.msg:SetText(interval_names[tonumber(save[id])])
                end
            end
            answer[id]:SetText(save[id]):SetKeyboardFocus()
        end
        local function on_timer() -- look for changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    update_selection() -- update selection tracker
                    answer.info:SetText(selection)
                    break -- all done
                end
            end
        end
    -- dialog contents
    answer.a = cs(10, y, "TRANSPOSE DIATONIC", 140)
    dy()
    cs(0, y, "Direction: (" .. hotkey.direction ..")")
    answer.direction = dialog:CreatePopup(x_step - 15, y):SetWidth(55)
        :AddStrings("Up", "Down"):SetSelectedItem(config.direction)
    answer.msg = cs(x_step + 25, y + y_inc + 2, interval_names[config.interval], 35)
    dy(y_inc + 2)
    for _, v in ipairs(numerics) do
        cs(0, y, v[2])
        answer[v[1]] = dialog:CreateEdit(x_step, y - offset)
            :SetText(config[v[1]]):SetWidth(20)
            :AddHandleCommand(function() key_command(v[1]) end)
        dy()
    end
    for _, v in ipairs(checks) do
        answer[v[1]] = dialog:CreateCheckbox(0, y):SetCheck(config[v[1]] and 1 or 0)
            :SetText(v[2] .. " (" .. hotkey[v[1]] ..")"):DoAutoResizeWidth()
        dy()
    end
    answer.q = dialog:CreateButton(x_step + 43, y - y_inc - 1):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    answer.info = cs(0, y, selection, x_step + 40)
    dialog:CreateOkButton()    :SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton():SetText(config.modeless and "Close" or "Cancel")
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterInitWindow(function(self)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
        local bold = answer.a:CreateFontInfo():SetBold(true)
        for _, v in ipairs{"a", "q", "msg"} do
            answer[v]:SetFont(bold)
        end
        answer.interval:SetKeyboardFocus()
    end)
    local change_mode = false
    dialog:RegisterHandleOkButtonPressed(function()
        for _, v in ipairs(numerics) do
            config[v[1]]  = answer[v[1]]:GetInteger()
        end
        config.direction = answer.direction:GetSelectedItem()
        config.do_preserve = (answer.do_preserve:GetCheck() == 1)
        transpose_diatonic(dialog)
    end)
    dialog:RegisterCloseWindow(function(self)
        if config.modeless then self:StopTimer(config.timer_id) end
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
    return change_mode
end

function do_diatonic()
    configuration.get_user_settings(script_name, config, true)
    if not config.modeless and nil_region_error() then return end

    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    update_selection()
    if mod_key then
        transpose_diatonic()
    else
        while run_the_dialog() do end
    end
end

do_diatonic()
