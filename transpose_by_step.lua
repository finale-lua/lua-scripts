function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 25, 2020"
    finaleplugin.CategoryTags = "Note"
    return "Transpose By Steps...", "Transpose By Steps",
           "Transpose by the number of steps given, simplifying spelling as needed."
end

--[[
This function allows you to specify a number of chromatic steps by which to transpose and the script
simplifies the spelling. Chromatic steps are half-steps in 12-tone music, but they are smaller if you are
using a microtone sytem defined in a custom key signature.

For this script to function correctly with custom key signatures, you must create a custom_key_sig.config.txt file in the
the script_settings folder with the following two options for the custom key signature you are using. Unfortunately,
the current version of JW Lua does allow scripts to read this information from the finale document.

(This example is for 31-EDO.)

number_of_steps = 31
diatonic_steps = {0, 5, 10, 13, 18, 23, 28}
]]

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local transposition = require("library.transposition")

function do_transpose_by_step(number_of_steps)
    local success = true
    for entry in eachentrysaved(finenv.Region()) do
        for note in each(entry) do
            if not transposition.stepwise_transpose(note, number_of_steps) then
                success = false
            end
        end
    end
    return success
end

function transpose_by_step()
    if not do_transpose_by_step(17) then
       finenv.UI():AlertError("Finale is unable to represent some of the transposed pitches. These pitches were left at their original value.", "Transposition Error")
    end
end

transpose_by_step()
