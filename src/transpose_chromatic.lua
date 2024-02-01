function plugindef(locale)
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true -- not recognized by JW Lua or RGP Lua v0.55
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.2"
    finaleplugin.Date = "January 9, 2024"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.Notes = [[
        This script transposes the selected region by a chromatic interval. It works correctly even with
        microtone scales defined by custom key signatures.

        Normally the script opens a modeless window. However, if you invoke the plugin with a shift, option, or
        alt key pressed, it skips opening a window and uses the last settings you entered into the window.
        (This works with RGP Lua version 0.60 and higher.)

        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a custom_key_sig.config.txt file in a folder called `script_settings` within the same folder as the script.
        It should contains the following two lines that define the custom key signature you are using. Unfortunately,
        the JW Lua and early versions of RGP Lua do not allow scripts to read this information from the Finale document.

        (This example is for 31-EDO.)

        ```
        number_of_steps = 31
        diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
        ```

        Later versions of RGP Lua (0.58 or higher) ignore this configuration file (if it exists) and read the correct
        information from the Finale document.
    ]]
    local loc = {}
    loc.en = {
        menu = "Transpose Chromatic",
        desc = "Chromatic transposition of selected region (supports microtone systems)."
    }
    loc.es = {
        menu = "Trasponer cromático",
        desc = "Trasposición cromática de la región seleccionada (soporta sistemas de microtono)."
    }
    loc.de = {
        menu = "Transponieren chromatisch",
        desc = "Chromatische Transposition des ausgewählten Abschnittes (unterstützt Mikrotonsysteme)."
    }
    local t = locale and loc[locale:sub(1,2)] or loc.en
    return t.menu .. "...", t.menu, t.desc
end

-- luacheck: ignore 11./global_dialog

if not finenv.IsRGPLua then
    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    package.path = package.path .. ";" .. path.LuaString .. "?.lua"
end

local transposition = require("library.transposition")
local mixin = require("library.mixin")
local loc = require("library.localization")
local utils = require("library.utils")

interval_names = interval_names or {
    "Perfect Unison",
    "Augmented Unison",
    "Diminished Second",
    "Minor Second",
    "Major Second",
    "Augmented Second",
    "Diminished Third",
    "Minor Third",
    "Major Third",
    "Augmented Third",
    "Diminished Fourth",
    "Perfect Fourth",
    "Augmented Fourth",
    "Diminished Fifth",
    "Perfect Fifth",
    "Augmented Fifth",
    "Diminished Sixth",
    "Minor Sixth",
    "Major Sixth",
    "Augmented Sixth",
    "Diminished Seventh",
    "Minor Seventh",
    "Major Seventh",
    "Augmented Seventh",
    "Diminished Octave",
    "Perfect Octave"
}

interval_disp_alts = interval_disp_alts or {
    {0,0},  {0,1},                      -- unisons
    {1,-2}, {1,-1}, {1,0}, {1,1},       -- 2nds
    {2,-2}, {2,-1}, {2,0}, {2,1},       -- 3rds
    {3,-1}, {3,0},  {3,1},              -- 4ths
    {4,-1}, {4,0},  {4,1},              -- 5ths
    {5,-2}, {5,-1}, {5,0}, {5,1},       -- 6ths
    {6,-2}, {6,-1}, {6,0}, {6,1},       -- 7ths
    {7,-1}, {7,0}                       -- octaves
}

function do_transpose_chromatic(direction, interval_index, simplify, plus_octaves, preserve_originals)
    if finenv.Region():IsEmpty() then
        return
    end
    local interval = direction * interval_disp_alts[interval_index][1]
    local alteration = direction * interval_disp_alts[interval_index][2]
    plus_octaves = direction * plus_octaves
    local undostr = ({plugindef(loc.get_locale())})[2] .. " " .. tostring(finenv.Region().StartMeasure)
    if finenv.Region().StartMeasure ~= finenv.Region().EndMeasure then
        undostr = undostr .. " - " .. tostring(finenv.Region().EndMeasure)
    end
    finenv.StartNewUndoBlock(undostr, false) -- this works on both JW Lua and RGP Lua
    local success = true
    for entry in eachentrysaved(finenv.Region()) do
        if not transposition.entry_chromatic_transpose(entry, interval, alteration, simplify, plus_octaves, preserve_originals) then
            success = false
        end
    end
    if finenv.EndUndoBlock then -- EndUndoBlock only exists on RGP Lua 0.56 and higher
        finenv.EndUndoBlock(true)
        finenv.Region():Redraw()
    else
        finenv.StartNewUndoBlock(undostr, true) -- JW Lua automatically terminates the final undo block we start here
    end
    if not success then
        global_dialog:CreateUI():AlertLocalizedError(
            "Finale is unable to represent some of the transposed pitches. These pitches were left unchanged.",
            "Transposition Error"
        )
    end
    return success
end

function create_dialog_box()
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle(plugindef(loc.get_locale()):gsub("%.%.%.", ""))
    local current_y = 0
    local y_increment = 26
    local x_increment = 85
    -- direction
    dialog:CreateStatic(0, current_y + 2, "direction_label")
        :SetLocalizedText("Direction")
        :SetWidth(x_increment - 5)
        :_FallbackCall("DoAutoResizeWidth", nil, true)
    dialog:CreatePopup(x_increment, current_y, "direction_choice")
        :AddLocalizedStrings("Up", "Down"):SetWidth(x_increment)
        :SetSelectedItem(0)
        :_FallbackCall("DoAutoResizeWidth", nil, true)
        :_FallbackCall("AssureNoHorizontalOverlap", nil, dialog:GetControl("direction_label"), 5)
    current_y = current_y + y_increment
    -- interval
    dialog:CreateStatic(0, current_y + 2, "interval_label")
        :SetLocalizedText("Interval")
        :SetWidth(x_increment - 5)
        :_FallbackCall("DoAutoResizeWidth", nil, true)
    dialog:CreatePopup(x_increment, current_y, "interval_choice")
        :AddLocalizedStrings(table.unpack(interval_names))
        :SetWidth(140)
        :SetSelectedItem(0)
        :_FallbackCall("DoAutoResizeWidth", nil, true)
        :_FallbackCall("AssureNoHorizontalOverlap", nil, dialog:GetControl("interval_label"), 5)
        :_FallbackCall("HorizontallyAlignLeftWith", nil, dialog:GetControl("direction_choice"))
    current_y = current_y + y_increment
    -- simplify checkbox
    dialog:CreateCheckbox(0, current_y + 2, "do_simplify")
        :SetLocalizedText("Simplify Spelling")
        :SetWidth(140)
        :SetCheck(0)
        :_FallbackCall("DoAutoResizeWidth", nil, true)
    current_y = current_y + y_increment
    -- plus octaves
    dialog:CreateStatic(0, current_y + 2, "plus_octaves_label")
        :SetLocalizedText("Plus Octaves")
        :SetWidth(x_increment - 5)
        :_FallbackCall("DoAutoResizeWidth", nil, true)
    local edit_offset_x = utils.win_mac(0, 4)
    dialog:CreateEdit(x_increment + edit_offset_x, current_y, "plus_octaves")
        :SetText("")
        :_FallbackCall("AssureNoHorizontalOverlap", nil, dialog:GetControl("plus_octaves_label"), 5)
        :_FallbackCall("HorizontallyAlignLeftWith", nil, dialog:GetControl("direction_choice"), edit_offset_x)
    current_y = current_y + y_increment
    -- preserve existing notes
    dialog:CreateCheckbox(0, current_y + 2, "do_preserve")
        :SetLocalizedText("Preserve Existing Notes")
        :SetWidth(140)
        :SetCheck(0)
        :_FallbackCall("DoAutoResizeWidth", nil, true)
    current_y = current_y + y_increment -- luacheck: ignore
    -- OK/Cxl
    dialog:CreateOkButton()
        :SetLocalizedText("OK")
        :_FallbackCall("DoAutoResizeWidth", nil, true)
    dialog:CreateCancelButton()
        :SetLocalizedText("Cancel")
        :_FallbackCall("DoAutoResizeWidth", nil, true)
    -- registrations
    dialog:RegisterHandleOkButtonPressed(function(self)
            local direction = 1 -- up
            if self:GetControl("direction_choice"):GetSelectedItem() > 0 then
                direction = -1 -- down
            end
            local interval_choice = 1 + self:GetControl("interval_choice"):GetSelectedItem()
            local do_simplify = (0 ~= self:GetControl("do_simplify"):GetCheck())
            local plus_octaves = self:GetControl("plus_octaves"):GetInteger()
            local preserve_originals = (0 ~= self:GetControl("do_preserve"):GetCheck())
            do_transpose_chromatic(direction, interval_choice, do_simplify, plus_octaves, preserve_originals)
        end
    )
    return dialog
end

function transpose_chromatic()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

transpose_chromatic()
