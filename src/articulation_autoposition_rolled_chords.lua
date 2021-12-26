function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "December 26, 2021"
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.MinJWLuaVersion = 0.59
    return "Autoposition Rolled Chord Articulations", "Autoposition Rolled Chord Articulations", "Autoposition Rolled Chord Articulations"
end

require('mobdebug').start()

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local note_entry = require("library.note_entry")
local articulation = require("library.articulation")

local config = {
    extend_across_staves = true
}

function calc_top_bot_page_pos(search_region)
    local success = false
    local top_page_pos = -math.huge
    local bot_page_pos = math.huge
    local left_page_pos = math.huge
    for entry in eachentry(search_region) do
        if entry:IsRest() then
            break
        end
        local em = finale.FCEntryMetrics()
        if em:Load(entry) then
            success = true
            local this_top = note_entry.get_top_note_position(entry,em)
            if this_top > top_page_pos then
                top_page_pos = this_top
            end
            local this_bottom = note_entry.get_bottom_note_position(entry,em)
            if this_bottom < bot_page_pos then
                bot_page_pos = this_bottom
            end
            if em.FirstAccidentalPosition < left_page_pos then
                left_page_pos = em.FirstAccidentalPosition
            end
            em:FreeMetrics()
        end
    end
    return success, top_page_pos, bot_page_pos, left_page_pos
end

function articulation_autoposition_rolled_chords()
    for entry in eachentry(finenv.Region()) do
        local artics = entry:CreateArticulations()
        for artic in each(artics) do
            if artic.Visible then
                local artic_def = artic:CreateArticulationDef()
                if artic_def.CopyMainSymbol and not artic_def.CopyMainSymbolHorizontally then
                    local save_it = false
                    local search_region = note_entry.get_music_region(entry)
                    if config.extend_across_staves then
                        if search_region.StartStaff ~= finenv.Region().StartStaff then
                            artic.Visible = false
                            save_it = true
                        else
                            search_region.EndStaff = finenv.Region().EndStaff
                        end
                    end
                    if artic.Visible then
                        local success, top_page_pos, bot_page_pos, left_page_pos = calc_top_bot_page_pos(search_region)
                        local char_width, char_height = articulation.calc_main_character_dimensions(artic_def)
                        if success then
        --                    finenv.UI():AlertInfo("t: " .. tostring(top_page_pos) .. " b: " .. tostring(bot_page_pos) .. " l: " .. tostring(left_page_pos), "articulation_autoposition_rolled_chords")
                        end
                    end
                    if save_it then
                        artic:Save()
                    end
                end
            end
        end
    end
end

articulation_autoposition_rolled_chords()
