function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "December 26, 2021"
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.MinJWLuaVersion = 0.59
    return "Autoposition Rolled Chord Articulations", "Autoposition Rolled Chord Articulations",
            "Creates rolled chords across multiple staves unless shift or option(alt) key is pressed when selecting menu item."
end

-- This script requires the VerticalCopyToPos property on FCArticulation, which was added in v0.59 of RGP Lua
-- Therefore, it is marked not to load in any earlier version.

--require('mobdebug').start()

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local note_entry = require("library.note_entry")
local articulation = require("library.articulation")

local config = {
    extend_across_staves = true,
    -- per Ted Ross p. 198-9, the vertical extent is "approximately 1 space above and below" (counted from the staff position),
    --    which means a half space from the note tips. But Gould has them closer, so we'll compromise here.
     vertical_padding = 6,           -- 1/4 space
    -- per Ted Ross p. 198-9, the rolled chord mark precedes the chord by 3/4 space, and Gould (p. 131ff.) seems to agree
    --    from looking at illustrations
     horizontal_padding = 18         -- 3/4 space
}

if finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT) then
    config.extend_across_staves = false
end

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
                    local metric_pos = finale.FCPoint(0, 0)
                    local mm = finale.FCCellMetrics()
                    if artic.Visible and artic:CalcMetricPos(metric_pos) and mm:LoadAtEntry(entry) then
                        local success, top_page_pos, bottom_page_pos, left_page_pos = calc_top_bot_page_pos(search_region)
                        local this_bottom = note_entry.get_bottom_note_position(entry)
                        staff_scale = mm.StaffScaling / 10000
                        top_page_pos = top_page_pos / staff_scale
                        bottom_page_pos = bottom_page_pos / staff_scale
                        left_page_pos = left_page_pos / staff_scale
                        this_bottom = this_bottom / staff_scale
                        local char_width, char_height = articulation.calc_main_character_dimensions(artic_def)
                        local half_char_height = char_height/2
                        local horz_diff = left_page_pos - metric_pos.X
                        local vert_diff = top_page_pos - metric_pos.Y
                        artic.HorizontalPos = artic.HorizontalPos + math.floor(horz_diff - char_width - config.horizontal_padding + 0.5)
                        artic.VerticalPos = artic.VerticalPos + math.floor(vert_diff - char_height + 2*config.vertical_padding + 0.5)
                        artic.VerticalCopyToPos = math.floor(bottom_page_pos - this_bottom - config.vertical_padding - half_char_height + 0.5)
                        save_it = true
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
