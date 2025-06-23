function plugindef()
    finaleplugin.RequireDocument = true -- manipulating font information requires a document
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.3"
    finaleplugin.Date = "June 22, 2025"
    finaleplugin.MinJWLuaVersion = 0.75
    finaleplugin.Notes = [[
        A utility for mapping legacy music font glyphs to SMuFL glyphs. It emits a json
        file in the same format as those provided in the Finale installation for MakeMusic's
        legacy fonts.
    ]]
    return "Map Legacy Fonts to SMuFL...", "Map Legacy Fonts to SMuFL", "Map legacy font glyphs to SMuFL glyphs"
end

-- luacheck: ignore 11./global_dialog

local mixin = require("library.mixin")

local function select_font()
    local font_info = finale.FCFontInfo()
    font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    local font_dialog = finale.FCFontDialog(finenv.UI(), font_info)
    font_dialog.UseSizes = false
    font_dialog.UseStyles = false
    if font_dialog:Execute() then
        return font_dialog.FontInfo
    end
    return nil
end

function font_map_legacy()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Map Legacy Fonts to SMuFL")
    local current_y = 0
    -- font selection
    dialog:CreateButton(0, current_y + 2, "font_sel"):SetText("Font..."):DoAutoResizeWidth(0):AddHandleCommand(
        function(_self)
            local got_font = select_font()
            if got_font then
                print(got_font:GetName())
            else
                print("no selection")
            end
        end)
    --    current_y = current_y + 20
    -- processing folder
    -- close button
    dialog:CreateCancelButton("cancel"):SetText("Close")
    -- registrations
    dialog:ExecuteModal() -- modal dialog prevents document changes in modeless callbacks
end

font_map_legacy()
