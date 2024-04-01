function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.15" -- MODELESS/MODAL
    finaleplugin.Date = "2024/03/01"
    finaleplugin.AdditionalMenuOptions = [[
        Double Diatonic Repeat
    ]]
    finaleplugin.AdditionalUndoText = [[
        Double Diatonic Repeat
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Repeat the last diatonic doubling (no dialog)
    ]]
    finaleplugin.AdditionalPrefixes = [[
        no_dialog = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.CategoryTags = "Pitch, Transposition"
    finaleplugin.ScriptGroupName = "Double Diatonic"
    finaleplugin.ScriptGroupDescription = "Double notes and chords up or down by a chosen diatonic interval"
    finaleplugin.Notes = [[
        Notes and chords in the current music selection are __doubled__ 
        (duplicated) either up or down by the chosen diatonic interval. 
        Affect all layers or just one. 
        To repeat the last action without a confirmation dialog use 
        the _Repeat_ menu or hold down [Shift] when starting the script. 

        Select __Modeless__ if you prefer the dialog window to 
        "float" above your score and you can change the score selection 
        while it floats. In this mode click __Apply__ 
        [Return/Enter] to double pitches and __Cancel__ [Escape] 
        to close the window. 
        Cancelling __Modeless__ will apply the _next_ 
        time you use the script.

        > These key commands are available  
        > if a "numeric" field is highlighted: 

        > - __z__: toggle up/down
        > - __1-8__: interval (unison, 2nd, 3rd, .. 8ve) 
        > - __0-8__: extra octave 
        > - __0-4__: layer number (__0__ = all layers) 
        > - __q__: show this script information 
        > - (delete key not needed in numeric fields) 
	]]
   return "Double Diatonic...", "Double Diatonic",
        "Double notes and chords up or down by a chosen diatonic interval"
end

no_dialog = no_dialog or false

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local transposition = require("library.transposition")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false
local selection
local saved_bounds = {}
local bounds = { -- primary region selection boundaries
    "StartStaff", "StartMeasure", "StartMeasurePos",
    "EndStaff",   "EndMeasure",   "EndMeasurePos",
}

local config = {
    layer     = 0,
    interval  = 1,  -- 1 = unison
    octave    = 0,
    direction = 0,  -- 0 = up / 1 = down (popup item no)
    timer_id  = 1,
    modeless  = false, -- false = modal / true = modeless
    window_pos_x = false,
    window_pos_y = false,
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
    for _, prop in ipairs(bounds) do
        saved_bounds[prop] = rgn[prop]
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

local function do_double_diatonic()
    finenv.StartNewUndoBlock(finaleplugin.ScriptGroupName .. " " .. selection.region, false)
    local direction = (config.direction * -2) + 1
    local shift = ((config.octave * 7) + config.interval - 1) * direction
    if shift ~= 0 then
        for entry in eachentrysaved(finenv.Region(), config.layer) do
            transposition.entry_diatonic_transpose(entry, shift, true)
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local max = finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4
    local y, y_inc = 0, 21
    local pop_wide, x_step = 55, 105
    local interval_names = { "unis.", "2nd", "3rd", "4th", "5th", "6th", "7th", "8ve"}
    local options = {"layer", "interval", "octave", "direction"}
    local save, answer = {}, {}
    for _, v in ipairs(options) do save[v] = config[v] end

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. finaleplugin.ScriptGroupName, 400, 315)
            refocus_document = true
        end
        local function dy(diff) y = diff and (y + diff) or (y + y_inc) end
        local function cs(cx, cy, ctext, cwide)
            return dialog:CreateStatic(cx, cy):SetText(ctext):SetWidth(cwide)
        end
        local function key_command(id) -- key command replacements
            local ctl = answer[id]
            local val = ctl:GetText():lower()
            if     val:find("[^0-8]")
                or (id == "layer" and val:find("[" .. (max + 1) .. "-8]"))
                or (id == "interval" and val:find("0"))
                    then
                if val:find("z") then -- flip direction
                    local n = answer.direction:GetSelectedItem()
                    answer.direction:SetSelectedItem((n + 1) % 2)
                elseif val:find("m") then -- toggle modeless
                    local m = answer.modeless:GetCheck()
                    answer.modeless:SetCheck((m + 1) % 2)
                elseif val:find("[?q]") then
                    show_info()
                end
            elseif val ~= "" then
                save[id] = val:sub(-1)
                if id == "interval" then
                    local n = tonumber(save[id]) or 1
                    answer.msg:SetText(interval_names[n])
                end
            end
            ctl:SetText(save[id]):SetKeyboardFocus()
        end
        local function on_timer() -- look for changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    initialise_parameters() -- update selection tracker
                    answer.info1:SetText(selection.staff)
                    answer.info2:SetText(selection.region)
                    break -- all done
                end
            end
        end

    answer.a = cs(0, y, "Direction:", 60)
    cs(60, y, "(z)", 25)
    answer.direction = dialog:CreatePopup(x_step - 15, y - offset + 1)
        :AddStrings("Up", "Down"):SetWidth(55)
        :SetSelectedItem(save.direction)
    dy()
    answer.b = cs(0, y, "Diatonic Interval:", x_step)
    answer.interval = dialog:CreateEdit(x_step, y - offset)
        :SetText(save.interval):SetWidth(20)
        :AddHandleCommand(function() key_command("interval") end)
    answer.msg = cs(x_step + 25, y, interval_names[save.interval], pop_wide - 20)
    dy()
    answer.c = cs(0, y, "Extra Octaves:", x_step)
    answer.octave = dialog:CreateEdit(x_step, y - offset):SetText(save.octave):SetWidth(20)
        :AddHandleCommand(function() key_command("octave") end)
    dy()
    answer.d = cs(0, y, "Layer Number:", x_step)
    answer.layer = dialog:CreateEdit(x_step, y - offset):SetWidth(20):SetText(save.layer)
        :AddHandleCommand(function() key_command("layer") end)
    dy()
    answer.modeless = dialog:CreateCheckbox(0, y):SetWidth(x_step + 15)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    answer.q = dialog:CreateButton(x_step + pop_wide - 37, y - 1):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    -- modeless selection info
    if config.modeless then -- include selection info
        dy(15)
        answer.info1 = cs(0, y, selection.staff, x_step + pop_wide)
        dy(15)
        answer.info2 = cs(0, y, selection.region, x_step + pop_wide)
    end
    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterInitWindow(function(self)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
        local bold = answer.a:CreateFontInfo():SetBold(true)
        for _, v in ipairs{"a", "b", "c", "d", "q", "msg"} do
            answer[v]:SetFont(bold)
        end
        answer.interval:SetKeyboardFocus()
        dialog:SetOkButtonCanClose(not config.modeless)
    end)
    local change_mode = false
    dialog:RegisterHandleOkButtonPressed(function()
        config.interval = tonumber(save.interval) -- 1-8 ("shift" interval value PLUS 1)
        config.octave = answer.octave:GetInteger()
        config.layer = answer.layer:GetInteger()
        config.direction = answer.direction:GetSelectedItem()
        do_double_diatonic()
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

function interval_doubler()
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
    local mode_change = true

    initialise_parameters()
    if no_dialog or mod_key then
        do_double_diatonic()
    else
        while mode_change do
            mode_change = run_the_dialog()
        end
    end
end

interval_doubler()
