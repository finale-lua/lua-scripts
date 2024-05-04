function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.10"
    finaleplugin.Date = "2024/05/03"
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.Notes = [[
        There's a couple of __Music Spacing__ options that I 
        change frequently for different spacing scenarios. 
        This little hack uses a couple of hotkeys 
        to do that very quickly, without a mouse and without navigating 
        the whole __Document__ → __Document Options__ → 
        __Music Spacing__ → __Avoid Collision of__ → menu/dialog system.
    ]]
    return "Music Spacing Hack...",
        "Music Spacing Hack",
        "A keyboard hack to quickly change music spacing options"
end

local config = {
    window_pos_x = false,
    window_pos_y = false,
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
}
local checks = { -- prefs Property key; hotkey; text description; type
    { "AvoidArticulations", "A", "Articulations" },
    { "AvoidChords",      "S", "Chords" },
    { "AvoidClefs",       "D", "Clefs" },
    { "AvoidHiddenNotes", "W", "Hidden Notes" },
    { "AvoidLedgerLines", "E", "Ledger Lines" },
    { "AvoidLyrics",      "R", "Lyrics" },
}
local unisons = {
    { finale.UNISSPACE_NONE,               "X", "None" },
    { finale.UNISSPACE_DIFFERENTNOTEHEADS, "V", "Different Noteheads" },
    { finale.UNISSPACE_ALLNOTEHEADS,       "B", "All Noteheads" },
}
local others = {
    {"change_hotkeys",        "H", "Change Hotkeys"},
    {"AutomaticMusicSpacing", "Z", "Automatic Music Spacing"},
    {"script_info",           "Q", "Show Script Info"}
}
-- copy hotkeys to config
for _, t in ipairs{checks, unisons, others} do
    for _, v in ipairs(t) do
        config[tostring(v[1])] = v[2]
    end
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local name = plugindef():gsub("%.%.%.", "")
local refocus_document = false
local prefs = finale.FCMusicSpacingPrefs()
local gen_prefs = finale.FCGeneralPrefs()
prefs:LoadFirst()
gen_prefs:LoadFirst()
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

local function reassign_keys(parent)
    local x_wide = 140
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors, assigned = false, {}, {}
    local y = 3
    local saved = {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Change Hotkeys")
        local function dy(diff) y = y + (diff and diff or 18) end
        local function cstat(cx, cy, ctext, cwide)
            dialog:CreateStatic(cx, cy):SetText(ctext):SetWidth(cwide)
        end
        local function key_check(ctl, id)
            local s = ctl:GetText():sub(-1):upper()
            if s:find("[^ .P0-9]") then saved[id] = s end
            ctl:SetText(saved[id])
        end
        local function check_line(array)
            for _, v in ipairs(array) do -- add all options with keycodes
                local id = tostring(v[1])
                saved[id] = config[id]
                dialog:CreateEdit(0, y - offset, id):SetText(config[id]):SetWidth(20)
                    :AddHandleCommand(function(self) key_check(self, id) end)
                cstat(25, y, v[3], x_wide)
                dy()
            end
        end
        local function duplication_check(array)
            for _, v in ipairs(array) do
                local key = dialog:GetControl(tostring(v[1])):GetText()
                if key == "" then key = "?" end -- not null
                config[tostring(v[1])] = key -- save for the next run-through
                local suffix = (type(v[1]) == "number") and "Unisons " or ""
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
    cstat(25, y, "- - -", x_wide)
    dy()
    check_line(others)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:GetControl("AvoidArticulations"):SetKeyboardFocus()
    end)
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        for _, t in ipairs{checks, unisons, others} do
            duplication_check(t)
        end
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
    local x = { 20, 40, 150 }
    local y = 0
    local m_offset = finenv.UI():IsOnMac() and 3 or 0
    local saved

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name:sub(1, -5))
    dialog:SetMeasurementUnit(config.measurement_unit)
        -- local functions
        local function dy(diff) y = y + (diff and diff or 17) end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 300, 150)
            refocus_document = true
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
        local function change_keys()
            local ok, is_duplicate = true, true
            while ok and is_duplicate do -- wait for good choice in reassign()
                ok, is_duplicate = reassign_keys(dialog)
            end
            if ok then
                for _, t in ipairs{checks, unisons, others} do
                    for _, v in ipairs(t) do
                        if v[1] ~= "script_info" then
                            dialog:GetControl("T" .. v[1]):SetText(config[tostring(v[1])])
                        end
                    end
                end
            else -- re-seed hotkeys from user config
                configuration.get_user_settings(script_name, config)
            end
            dialog:GetControl("max_width"):SetKeyboardFocus()
        end
        local function key_check(ctl)
            local s = ctl:GetText():upper()
            if s:find("[^.P0-9]") then
                if s:find(config.change_hotkeys) then
                    change_keys()
                elseif s:find(config.AutomaticMusicSpacing) then
                    toggle_check("AutomaticMusicSpacing")
                elseif s:find(config.script_info) then show_info()
                else
                    local matched = false
                    for _, array in ipairs{{checks, toggle_check}, {unisons, toggle_unison}} do
                        if not matched then
                            for _, v in ipairs(array[1]) do
                                if s:find(config[tostring(v[1])]) then
                                    array[2](v[1])
                                    matched = true
                                    break
                                end
                            end
                        end
                    end
                end
            else -- save new "clean" numnber
                saved = s:sub(1, 8):lower() -- 8-chars max
            end
            ctl:SetText(saved)
        end
    cstat(0, y, "THE " .. name:upper(), 160, "title")
    dy(25)
    cstat(0, y, "Avoid Collisions of:", x[3])
    dialog:CreateButton(x[2] + x[3] - 50, y, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dy()
    for _, v in ipairs(checks) do
        cstat(0, y, config[v[1]], x[1], "T" .. v[1])
        ccheck(x[1], y, v[1], v[3], x[3], (prefs[v[1]] and 1 or 0))
        dy()
    end
    cstat(x[1], y, "Unison Noteheads:", x[3])
    dy()
    for _, v in ipairs(unisons) do
        local id = tostring(v[1])
        cstat(x[1], y, config[id], x[2], "T" .. v[1])
        ccheck(x[2], y, id, v[3], x[3] - x[1], (prefs.UnisonsMode == v[1]) and 1 or 0)
        dialog:GetControl(id)
            :AddHandleCommand(function() toggle_unison(v[1]) end)
        dy()
    end
    dy(8)
    cstat(0, y, "Max Width:", x[2] + 25)
    dialog:CreateMeasurementEdit(x[2] + 27, y - m_offset, "max_width")
        :SetWidth(90):SetMeasurementInteger(prefs.MaxMeasureWidth)
        :AddHandleCommand(function(self) key_check(self) end)
    saved = dialog:GetControl("max_width"):GetText()
    dy(25)
    cstat(x[2] - 10, y, "Units:", 37)
    dialog:CreateMeasurementUnitPopup(x[2] + 27, y, "popup"):SetWidth(90)
        :AddHandleCommand(function()
            saved = dialog:GetControl("max_width"):GetText()
        end)
    dy(25)
    cstat(0, y, config.change_hotkeys, x[2], "Tchange_hotkeys")
    dialog:CreateButton(x[1], y):SetText("Change Hotkeys"):SetWidth(100)
        :AddHandleCommand(function() change_keys() end)
    dy(22)
    local val = others[2]
    cstat(0, y, config[val[1]], x[1], "T" .. val[1])
    ccheck(x[1], y, val[1], val[3], x[3], (gen_prefs[val[1]] and 1 or 0))

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function(self)
        self:GetControl("max_width"):SetKeyboardFocus()
        local q = self:GetControl("q")
        local bold = q:CreateFontInfo():SetBold(true)
        q:SetFont(bold)
        self:GetControl("title"):SetFont(bold)
    end)
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
        local n = self:GetControl("max_width"):GetMeasurementInteger()
        prefs.MaxMeasureWidth = math.max(n, 50)
        prefs:Save()
        gen_prefs.AutomaticMusicSpacing = (self:GetControl("AutomaticMusicSpacing"):GetCheck() == 1)
        gen_prefs:Save()
        config.measurement_unit = self:GetMeasurementUnit()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:ExecuteModal()
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

run_the_dialog()
