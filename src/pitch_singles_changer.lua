function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.04"
    finaleplugin.Date = "2024/01/11"
    finaleplugin.CategoryTags = "Entries, Pitch, Transposition"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = [[
        Change up to four specific pitches to other specific pitches. 
        Pitch specification is exact and immutable:

        First character: pitch name A-G. 
        (Lower case will be replaced automatically with upper case)

        Last character: octave number 0-9.

        In between: accidentals if needed. 
        b / bb / bbb / # / ## / ### 
        (you can use "s" instead of "#" - automatic replacement)

        If you make a mistake with the pitch format you will be asked to 
        "FIX" the mistake before the pitch change can take place.
    ]]
    return "Pitch Singles Changer...", "Pitch Singles Changer", "Change up to four specific pitches to other specific pitches"
end

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local cjson = require("cjson")
local script_name = "pitch_singles_changer"

local config = {
    pitch_set = '[["C4","C5"]]', -- JSON encoded pitch replacement set
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

local function extract_pitch(p)
    if p == nil or p == "" then return "", "", "" end
    return p:sub(1, 1):upper(), p:sub(2, -2):lower():gsub("s", "#"), p:sub(-1)
end

local function rewrite_pitch(p)
    local a, b, c = extract_pitch(p)
    return a .. b .. c
end

local function is_error(p)
    if p == nil or p == "" then return false end
    local a, b, c = extract_pitch(p)
    if a:find("[^A-G]") then return true end
    if b:find("[^b#]") then return true end
    if c:find("[^0-9]") then return true end
    return false
end

local function user_selects_pitches(pitches)
    local y, yd, x = 0, 25, { 83, 126, 150 }
    local answer = {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
        local function cstat(dx, dy, txt, wid)
            local y_off = finenv.UI():IsOnMac() and 3 or 0
            return dialog:CreateStatic(dx, dy + y_off):SetText(txt):SetWidth(wid)
        end
        local function cedit(dx, dy, txt, wid)
            return dialog:CreateEdit(dx, dy):SetWidth(wid):SetText(txt)
        end
    for bank = 1, 4 do
        answer[bank] = {}
        cstat(0, y, "Change From:", 100)
        local pb = pitches[bank] and {pitches[bank][1], pitches[bank][2]} or {"", ""}
        answer[bank][1] = cedit(x[1], y, pb[1], 40)
        cstat(x[2], y, "To:", 20)
        answer[bank][2] = cedit(x[3], y, pb[2], 40)
        local bad = {is_error(pb[1]), is_error(pb[2])}
        if bad[1] or bad[2] then
            y = y + yd
            if bad[1] then
                answer[bank][1]:SetText("")
                cstat(60, y, "FIX: " .. pb[1], 100)
            end
            if bad[2] then
                answer[bank][2]:SetText("")
                cstat(x[2], y, "FIX: " .. pb[2], 100)
            end
        end
        y = y + yd
    end
    y = y + 10
    cstat(5, y, "Pitch examples: C4 / G#5 / Abb2", 180)
    y = y + 14
    cstat(50, y, "(C4 = middle C)", 110)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local pitch_set = {}
    local user_error = false
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        for bank = 1, 4 do
            local s = answer[bank][1]:GetText()
            pitch_set[bank] = { rewrite_pitch(s) }
            if is_error(s) then user_error = true end
            s = answer[bank][2]:GetText()
            pitch_set[bank][2] = rewrite_pitch(s)
            if is_error(s) then user_error = true end
        end
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    local ok = (dialog:ExecuteModal() == finale.EXECMODAL_OK)
    return ok, user_error, pitch_set
end

local function change_pitches()
    if finenv.Region():IsEmpty() then
        finenv.UI():AlertError("Please select some music before\n"
            .. "running this script.", plugindef() .. " Error" )
        return
    end
    configuration.get_user_settings(script_name, config, true)
    local pitch_set = cjson.decode(config.pitch_set)
    local m = finale.FCMeasure()
    local pitch_str = finale.FCString()
    local ok, user_error = true, true
    while ok and user_error do
        ok, user_error, pitch_set = user_selects_pitches(pitch_set)
    end
    if not ok then return end -- user cancelled

    config.pitch_set = cjson.encode(pitch_set)
    configuration.save_user_settings(script_name, config)
    for entry in eachentrysaved(finenv.Region()) do
        m:Load(entry.Measure)
        local keysig = m.KeySignature

        for note in each(entry) do
            note:GetString(pitch_str, keysig, false, false)
            for i, v in ipairs(pitch_set) do
                if pitch_str.LuaString == v[1] then
                    pitch_str.LuaString = v[2]
                    note:SetString(pitch_str, keysig, false)
                end
            end
        end
    end
end

change_pitches()
