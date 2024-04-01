function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Jacob Winkler, Nick Mazuk & Carl Vine"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.34"
    finaleplugin.Date = "2024-03-01"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.Notes = [[
        Select a note within each chord to either keep or delete, 
        numbered from either the top or bottom of each chord. 

        - __1__ deletes (or keeps) the top (or bottom) note 
        - __2__ deletes (or keeps) the 2nd note from the top (or bottom) 
        - etc. ...

        > If __Note Number__ or __Layer__ are highlighted  
        > then these __Key Commands__ are available:

        > - __z__: toggle keep/delete 
        > - __x__: toggle top/bottom 
        > - __m__: toggle "Modeless"
        > - __q__: show these notes 
        > - __1-9__: note number 
        > - __0-4__: layer number 
        > - (delete key not needed for number entry) 

        Select __Modeless__ if you prefer the dialog window to 
        "float" above your score and you can change the score selection 
        while it's active. In this mode, click __Apply__ [Return/Enter] 
        to make changes and __Cancel__ [Escape] to close the window. 
        Cancelling __Modeless__ will apply the _next_ time you use the script.

        To repeat the last action without a confirmation dialog 
        hold down [Shift] when starting the script. 
    ]]
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.CategoryTags = "Pitch, Transposition"
    return "Pitch: Chord Notes Keep-Delete...",
        "Pitch: Chord Notes Keep-Delete",
        "Keep or Delete selected notes from chords"
end

local configuration = require("library.configuration")
local note_entry = require("library.note_entry")
local mixin = require("library.mixin")
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


local config = { -- retained and over-written by the user's "settings" file
    number      = 1, -- which note to work on
    direction   = 0, -- 0 == from top / 1 == from bottom
    keep_delete = 0, -- 0 == keep / 1 == delete
    layer       = 0,
    timer_id    = 1,
    modeless    = false, -- false = modal / true = modeless
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
    for _, property in ipairs(bounds) do
        saved_bounds[property] = rgn[property]
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

local function make_changes()
    finenv.StartNewUndoBlock("Keep-Delete " .. selection.region, false)
    for entry in eachentrysaved(finenv.Region(), config.layer) do
        if (entry.Count >= 2) then
            local n = config.number
            local target = (config.direction == 0) and (n - 1) or (entry.Count - n)
            local i = 0
            for note in eachbackwards(entry) do -- scan pitches top to bottom
                if      (i == target and config.keep_delete == 1)
                    or  (i ~= target and config.keep_delete == 0) then
                    note_entry.delete_note(note)
                end
                i = i + 1
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local x, y, tag_wide = 84, 3, 23
    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    local answer = {}
    local saved = { number = config.number, layer = config.layer }
    local name = plugindef():gsub("%.%.%.", "")
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function cs(dx, dy, title, width)
            return dialog:CreateStatic(dx, dy):SetText(title):SetWidth(width)
        end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 400, 375)
            refocus_document = true
        end
        local function flip_radio(id)
            local n = answer[id]:GetSelectedItem()
            answer[id]:SetSelectedItem((n + 1) % 2)
        end
        local function key_check(id)
            local ctl = answer[id]
            local s = ctl:GetText():lower()
            if     (id == "number" and s:find("[^1-9]") )
                or (id == "layer" and s:find("[^0-4]"))
                    then
                if     s:find("z") then flip_radio("keep_delete")
                elseif s:find("x") then flip_radio("direction")
                elseif s:find("q") then show_info()
                elseif s:find("m") then -- toggle modeless
                    local m = answer.modeless:GetCheck()
                    answer.modeless:SetCheck((m + 1) % 2)
                end
            elseif s ~= "" then
                saved[id] = s:sub(-1) -- most recent digit only
            end
            ctl:SetText(saved[id]):SetKeyboardFocus()
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

    -- First Line
    answer.a = cs(0, y, "Note Number:", x)
    answer.number = dialog:CreateEdit(x, y - y_offset):SetInteger(config.number)
        :AddHandleCommand(function() key_check("number") end):SetWidth(20)
    answer.b = cs(x + 42, y, "Layer:", 40)
    answer.layer = dialog:CreateEdit(x + 82, y - y_offset):SetInteger(config.layer)
        :AddHandleCommand(function() key_check("layer") end):SetWidth(20)
    y = y + 22

    -- RadioButtonGroup
    local titles = { {"Keep", "Delete"}, {"From Top", "From Bottom"}}
    local tags   = {  "(z)",              "(x)"}
    local labels = finale.FCStrings()
    labels:CopyFromStringTable(titles[1])
    answer.keep_delete = dialog:CreateRadioButtonGroup(0, y, 2)
        :SetText(labels):SetWidth(x - 25)
        :SetSelectedItem(config.keep_delete)
    cs(x - 28, y + 5, tags[1], tag_wide)
    labels:CopyFromStringTable(titles[2])
    answer.direction = dialog:CreateRadioButtonGroup(x, y, 2)
        :SetText(labels):SetWidth(85)
        :SetSelectedItem(config.direction)
    cs(x + 85, y + 5, tags[2], tag_wide)
    y = y + 35
    answer.modeless = dialog:CreateCheckbox(0, y):SetWidth(x + 80)
        :SetCheck(config.modeless and 1 or 0):SetText("\"Modeless\" Dialog")
    answer.q = dialog:CreateButton(x + 82, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    -- modeless selection info
    if config.modeless then
        y = y + 15
        answer.info1 = cs(0, y, selection.staff, x + 105)
        y = y + 15
        answer.info2 = cs(0, y, selection.region, x + 105)
    end
    -- wrap it up
    dialog:CreateOkButton():SetText(config.modeless and "Apply" or "OK")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    if config.modeless then dialog:RegisterHandleTimer(on_timer) end
    dialog:RegisterInitWindow(function(self)
        dialog:SetOkButtonCanClose(not config.modeless)
        if config.modeless then self:SetTimer(config.timer_id, 125) end
        local bold = answer.a:CreateFontInfo():SetBold(true)
        answer.a:SetFont(bold)
        answer.b:SetFont(bold)
        answer.q:SetFont(bold)
        answer.number:SetKeyboardFocus()
    end)
    local change_mode = false
    dialog:RegisterHandleOkButtonPressed(function()
        config.number = answer.number:GetInteger()
        config.layer = answer.layer:GetInteger()
        config.direction = answer.direction:GetSelectedItem()
        config.keep_delete = answer.keep_delete:GetSelectedItem()
        make_changes()
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

local function keep_delete()
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
    if mod_key then
        make_changes()
    else
        while mode_change do
            mode_change = run_the_dialog()
        end
    end
end

keep_delete()
