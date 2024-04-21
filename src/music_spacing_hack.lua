function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.03"
    finaleplugin.Date = "2024/04/21"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        There's a couple of __Music Spacing__ options that I need to 
        change frequently for different spacing scenarios. 
        This is a little hack using a couple of hotkeys 
        to do that very quickly, without a mouse and without navigating 
        the whole __Document__ → __Document Options__ → 
        __Music Spacing__ → __Avoid Collision of__ → menu/dialog system.
    ]]
    return "Music Spacing Hack...",
        "Music Spacing Hack",
        "A keyboard hack to quickly change music spacing options"
end

local config = {
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    window_pos_x = false,
    window_pos_y = false,
}
local checks = { -- property key; hotkey; text description; type
    { "AvoidArticulations", "A", "Articulations" },
    { "AvoidChords",      "S", "Chords" },
    { "AvoidClefs",       "D", "Clefs" },
    { "AvoidHiddenNotes", "W", "Hidden Notes" },
    { "AvoidLedgerLines", "E", "Ledger Lines" },
    { "AvoidLyrics",      "R", "Lyrics" },
}
local unisons = {
    { finale.UNISSPACE_NONE,               "Z", "None" },
    { finale.UNISSPACE_DIFFERENTNOTEHEADS, "X", "Different Noteheads" },
    { finale.UNISSPACE_ALLNOTEHEADS,       "C", "All Noteheads" },
}
-- copy hotkeys to config
for _, v in ipairs(checks)  do config[v[1]] = v[2] end
for _, v in ipairs(unisons) do config[tostring(v[1])] = v[2] end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local name = plugindef():gsub("%.%.%.", "")
local refocus_document = false
local prefs = finale.FCMusicSpacingPrefs()
prefs:LoadFirst()
configuration.get_user_settings(script_name, config)

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

local function change_hotkeys(parent)
    local x_wide = 120
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors, assigned = false, {}, {}
    local y = 3
    local saved = {}

    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Change Hotkeys")
        local function dy(diff)
            y = y + (diff and diff or 18)
        end
        local function cstat(cx, cy, ctext, cwide)
            dialog:CreateStatic(cx, cy):SetText(ctext):SetWidth(cwide)
        end
        local function key_check(ctl, id)
            local s = ctl:GetText():sub(-1):upper()
            if s:find("[ .P0-9]") then s = saved[id]
            else saved[id] = s
            end
            ctl:SetText(s)
        end
        local function check_line(array)
            for _, v in ipairs(array) do -- add all options with keycodes
                local id = tostring(v[1])
                saved[id] = config[id]
                dialog:CreateEdit(0, y - offset, id):SetText(config[id]):SetWidth(20)
                    :AddHandleCommand(function(self) key_check(self, v[1]) end)
                dialog:CreateStatic(25, y):SetText(v[3]):SetWidth(x_wide)
                dy()
            end
        end
        local function error_check(array, suffix)
            for _, v in ipairs(array) do
                local key = dialog:GetControl(tostring(v[1])):GetText()
                if key == "" then key = "?" end -- not null
                config[tostring(v[1])] = key -- save for the next run-through
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], suffix .. v[3])
                else
                    assigned[key] = suffix .. v[3] -- flag key assigned
                end
            end
        end
    check_line(checks)
    cstat(0, y, "Unison Noteheads:", x_wide)
    dy()
    check_line(unisons)
    dy(7)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
            self:GetControl("AvoidArticulations"):SetKeyboardFocus()
        end
    )
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        error_check(checks, "")
        error_check(unisons, "Unisons ")
        if is_duplicate then -- list reassignment duplications
            local msg = ""
            for k, v in pairs(errors) do
                if msg ~= "" then msg = msg .. "\n\n" end
                msg = msg .. "Key \"" .. k .. "\" is assigned to: "
                for i, w in ipairs(v) do
                    if i > 1 then msg = msg .. " and " end

                    msg = msg .. "\"" .. w .. "\""
                end
            end
            dialog:CreateChildUI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(parent) == finale.EXECMODAL_OK)
    refocus_document = true
    return ok, is_duplicate
end

local function run_the_dialog()
    local x = { 20, 40, 125 }
    local y = 0
    local m_offset = finenv.UI():IsOnMac() and 3 or 0
    local saved

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
    dialog:SetMeasurementUnit(config.measurement_unit)
        -- local functions
        local function dy(diff)
            y = y + (diff and diff or 17)
        end
        local function cstat(cx, cy, ctext, cwide, cname)
            dialog:CreateStatic(cx, cy, cname):SetText(ctext):SetWidth(cwide)
        end
        local function ccheck(cx, cy, cname, ctext, cwide, check)
            dialog:CreateCheckbox(cx, cy, cname):SetText(ctext):SetWidth(cwide):SetCheck(check)
        end
        local function toggle_check(id)
            local ctl = dialog:GetControl(id)
            ctl:SetCheck((ctl:GetCheck() + 1) % 2)
        end
        local function toggle_unison(id)
            for i = unisons[1][1], unisons[3][1] do
                dialog:GetControl(tostring(i)):SetCheck(i == id and 1 or 0)
            end
        end
        local function key_check(ctl)
            local s = ctl:GetText():upper()
            if s:find("[^.P0-9]") then
                local got = false
                for _, v in ipairs(checks) do
                    if s:find(config[v[1]]) then
                        toggle_check(v[1])
                        got = true
                        break
                    end
                end
                if not got then
                    for _, v in ipairs(unisons) do
                        if s:find(config[tostring(v[1])]) then
                            toggle_unison(v[1])
                            break
                        end
                    end
                end
            else -- save new "clean" numnber
                saved = s:sub(1, 7):lower() -- 7-chars max
            end
            ctl:SetText(saved)
        end
    cstat(0, y, "Avoid Collisions of:", x[3])
    dialog:CreateButton(x[2] + x[3] - 25, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function()
            utils.show_notes_dialog(dialog, "About " .. name, 300, 150)
            refocus_document = true
        end)
    dy()
    for _, v in ipairs(checks) do
        cstat(0, y, config[v[1]], x[1], "T" .. v[1])
        ccheck(x[1], y, v[1], v[3], x[3], (prefs[v[1]] and 1 or 0))
        dy()
    end
    cstat(x[1], y, "Unison Noteheads:", x[3])
    dy()
    for _, v in ipairs(unisons) do
        cstat(x[1], y, config[tostring(v[1])], x[2], "T" .. v[1])
        local check = (prefs.UnisonsMode == v[1]) and 1 or 0
        ccheck(x[2], y, tostring(v[1]), v[3], x[3], check)
        dy()
    end
    dy(8)
    cstat(0, y, "Max Width:", x[2] + 25)
    dialog:CreateMeasurementEdit(x[2] + 27, y - m_offset, "max_width")
        :SetWidth(70):SetMeasurementInteger(prefs.MaxMeasureWidth)
        :AddHandleCommand(function(self) key_check(self) end)
    saved = dialog:GetControl("max_width"):GetText()
    dy(22)
    cstat(x[2] - 10, y, "Units:", 37)
    dialog:CreateMeasurementUnitPopup(x[2] + 27, y, "popup"):SetWidth(97)
        :AddHandleCommand(function()
            saved = dialog:GetControl("max_width"):GetText()
        end)
    dy(22)
    local function rename_checkboxes(array)
        for _, v in ipairs(array) do
            dialog:GetControl("T" .. v[1]):SetText(config[tostring(v[1])])
        end
    end
    dialog:CreateButton(x[2], y):SetText("Change Hotkeys"):SetWidth(97)
        :AddHandleCommand(function()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for good choice in reassign()
                ok, is_duplicate = change_hotkeys(dialog)
            end
            if ok then
                rename_checkboxes(checks)
                rename_checkboxes(unisons)
                configuration.save_user_settings(script_name, config)
            else
                configuration.get_user_settings(script_name, config)
            end
        end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        for _, v in ipairs(checks) do
            prefs[v[1]] = (self:GetControl(v[1]):GetCheck() == 1)
        end
        for _, v in ipairs(unisons) do
            if (self:GetControl(tostring(v[1])):GetCheck() == 1) then
                prefs.UnisonsMode = v[1] -- matched the active Mode setting
                break
            end
        end
        prefs.MaxMeasureWidth = self:GetControl("max_width"):GetMeasurementInteger()
        prefs:Save()
        config.measurement_unit = self:GetMeasurementUnit()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:ExecuteModal()
end

local function spacing_hack()
    while run_the_dialog() do end
    if refocus_document then
        finenv.UI():ActivateDocumentWindow()
    end
end

spacing_hack()
