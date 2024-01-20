function plugindef(locale)
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "January 9, 2024"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.Notes = [[
        In normal 12-note music, enharmonically transposing is the same as transposing by a diminished 2nd.
        However, in some microtone systems (specifically 19-EDO and 31-EDO), enharmonic transposition produces a different result
        than chromatic transposition. As an example, C is equivalent to Dbb in 12-tone systems. But in 31-EDO, C is five microsteps
        lower than D whereas Dbb is four microsteps lower than D. Transposing C up a diminished 2nd gives Dbb in either system, but
        in 31-EDO, Dbb is not the same pitch as C.
        
        If you are using custom key signatures with JW Lua or an early version of RGP Lua, you must create
        a `custom_key_sig.config.txt` file in a folder called `script_settings` within the same folder as the script.
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
        menu = "Enharmonic Transpose Up",
        desc = "Transpose up enharmonically all notes in the selected region."
    }
    loc.es = {
        menu = "Trasposición enarmónica hacia arriba",
        desc = "Trasponer hacia arriba enarmónicamente todas las notas en la región seleccionada.",
    }
    loc.de = {
        menu = "Enharmonische Transposition nach oben",
        desc = "Transponieren alle Noten im ausgewählten Abschnitt enharmonisch nach oben.",
    }
    local t = locale and loc[locale:sub(1,2)] or loc.en
    return t.menu, t.menu, t.desc
end

local transposition = require("library.transposition")
local loc = require('library.localization')

loc.en = loc.en or {
    ["Finale is unable to represent some of the transposed pitches. These pitches were left unchanged."] =
        "Finale is unable to represent some of the transposed pitches. These pitches were left unchanged.",
    ["Transposition Error"] = "Transposition Error",
}

loc.es = loc.es or {
    ["Finale is unable to represent some of the transposed pitches. These pitches were left unchanged."] =
        "Finale no puede representar algunas de las notas traspuestas. Estas notas no se han cambiado.",
    ["Transposition Error"] = "Error de trasposición",
}

loc.de = loc.de or {
    ["Finale is unable to represent some of the transposed pitches. These pitches were left unchanged."] =
        "Finale kann einige der transponierten Tönhöhen nicht darstellen. Diese Tönhöhen wurden unverändert gelassen.",
    ["Transposition Error"] = "Transpositionsfehler",
}

function transpose_enharmonic_up()
    local success = true
    for entry in eachentrysaved(finenv.Region()) do
        if not transposition.entry_enharmonic_transpose(entry, 1) then
            success = false
        end
    end
    if not success then
        finenv.UI():AlertError(
            loc.localize(
                "Finale is unable to represent some of the transposed pitches. These pitches were left unchanged."),
            loc.localize("Transposition Error")
        )
    end
end

transpose_enharmonic_up()
