function plugindef(locale)
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true -- not recognized by JW Lua or RGP Lua v0.55
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.2"
    finaleplugin.Date = "January 9, 2024"
    finaleplugin.CategoryTags = "Note"
    finaleplugin.Notes = [[
        This script allows you to specify a number of chromatic steps by which to transpose and the script
        simplifies the spelling. Chromatic steps are half-steps in a standard 12-tone scale, but they are smaller
        if you are using a microtone sytem defined in a custom key signature.

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
        menu = "Transpose By Steps",
        desc = "Transpose by the number of steps given, simplifying the note spelling as needed."
    }
    loc.es = {
        menu = "Transponer Por Pasos",
        desc = "Transponer por el número de pasos dado, simplificando la enarmonización según sea necesario.",
    }
    loc.de = {
        menu = "Transponieren nach Schritten",
        desc = "Transponieren nach der angegebenen Anzahl von Schritten und vereinfachen die Notation nach Bedarf.",
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

if finenv.IsRGPLua then
    loc.en = loc.en or {
        ["Finale is unable to represent some of the transposed pitches. These pitches were left at their original value."] =
            "Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.",
        ["Number Of Steps"] = "Number Of Steps",
        ["Transpose By Steps"] = "Transpose By Steps",
        ["Transposition Error"] = "Transposition Error",
        ["OK"] = "OK",
        ["Cancel"] = "Cancel",
    }

    loc.es = loc.es or {
        ["Finale is unable to represent some of the transposed pitches. These pitches were left at their original value."] =
            "Finale no puede representar algunas de las notas traspuestas. Estas notas no se han cambiado.",
        ["Number Of Steps"] = "Número De Pasos",
        ["Transpose By Steps"] = "Trasponer Por Pasos",
        ["Transposition Error"] = "Error De Trasposición",
        ["OK"] = "Aceptar",
        ["Cancel"] = "Cancelar",
    }

    loc.de = loc.de or {
        ["Finale is unable to represent some of the transposed pitches. These pitches were left at their original value."] =
            "Finale kann einige der transponierten Töne nicht darstellen. Diese Töne wurden auf ihren ursprünglichen Wert belassen.",
        ["Number Of Steps"] = "Anzahl der Schritte",
        ["Transpose By Steps"] = "Transponieren nach Schritten",
        ["Transposition Error"] = "Transpositionsfehler",
        ["OK"] = "OK",
        ["Cancel"] = "Abbrechen",
    }
end

function do_transpose_by_step(global_number_of_steps_edit)
    if finenv.Region():IsEmpty() then
        return
    end
    local undostr = loc.localize("Transpose By Steps") .. " " .. tostring(finenv.Region().StartMeasure)
    if finenv.Region().StartMeasure ~= finenv.Region().EndMeasure then
        undostr = undostr .. " - " .. tostring(finenv.Region().EndMeasure)
    end
    local success = true
    finenv.StartNewUndoBlock(undostr, false) -- this works on both JW Lua and RGP Lua
    for entry in eachentrysaved(finenv.Region()) do
        if not transposition.entry_stepwise_transpose(entry, global_number_of_steps_edit) then
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
        finenv.UI():AlertError(
            loc.localize(
                "Finale is unable to represent some of the transposed pitches. These pitches were left at their original value."),
            loc.localize("Transposition Error")
        )
    end
    return success
end

function create_dialog_box()
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle(loc.localize("Transpose By Steps"))
    local current_y = 0
    local x_increment = 105
    -- number of steps
    dialog:CreateStatic(0, current_y + 2, "steps_label")
        :SetText(loc.localize("Number Of Steps"))
        :fallback_call("DoAutoResizeWidth", nil, true)
    local edit_x = x_increment + utils.win_mac(0, 4)
    dialog:CreateEdit(edit_x, current_y, "num_steps")
        :SetText("")
        :fallback_call("AssureNoHorizontalOverlap", nil, dialog:GetControl("steps_label"), 10)
    -- ok/cancel
    dialog:CreateOkButton()
        :SetText(loc.localize("OK"))
        :fallback_call("DoAutoResizeWidth", nil, true)
    dialog:CreateCancelButton()
        :SetText(loc.localize("Cancel"))
        :fallback_call("DoAutoResizeWidth", nil, true)
    dialog:RegisterHandleOkButtonPressed(function(self)
            do_transpose_by_step(self:GetControl("num_steps"):GetInteger())
        end
    )
    return dialog
end

function transpose_by_step()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

transpose_by_step()
