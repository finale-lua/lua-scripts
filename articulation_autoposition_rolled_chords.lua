function plugindef()
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "March 9, 2020"
    finaleplugin.CategoryTags = "Articulation"
    return "Autoposition Rolled Chord Articulations", "Autoposition Rolled Chord Articulations", "Autoposition Rolled Chord Articulations"
end

local path = finale.FCString()
path:SetRunningLuaFolderPath()
package.path = package.path .. ";" .. path.LuaString .. "?.lua"
local note_entry = require("library.note_entry")

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
            if em.TopPosition > top_page_pos then
                top_page_pos = em.TopPosition
            end
            if em.BottomPosition < bot_page_pos then
                bot_page_pos = em.BottomPosition
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
            local artic_def = artic:CreateArticulationDef()
            if artic_def.CopyMainSymbol and not artic_def.CopyMainSymbolHorizontally then
                local search_region = note_entry.get_music_region(entry)
                if config.extend_across_staves then
                    search_region.EndStaff = finenv.Region().EndStaff
                end
                local success, top_page_pos, bot_page_pos, left_page_pos = calc_top_bot_page_pos(search_region)
                if success then

--                    finenv.UI():AlertInfo("t: " .. tostring(top_page_pos) .. " b: " .. tostring(bot_page_pos) .. " l: " .. tostring(left_page_pos), "articulation_autoposition_rolled_chords")
                end
            end
        end
    end
end

articulation_autoposition_rolled_chords()
