function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "May 30, 2022"
    finaleplugin.CategoryTags = "Document"
    finaleplugin.Notes = [[
        This script writes the current document to a text file in a human readable format. The primary purpose is to find changes
        between one version of a document and another. The idea is to write each version out to a text file and then
        use a comparison tool like kdiff3 to find differences.
    ]]
    return "Save Document As Text File...", "", "Write current document to text file."
end

local text_extension = ".txt"

local note_entry = require('library.note_entry')
local mixin = require('library.mixin')

local fcstr = function(str)
    local retval = finale.FCString()
    retval.LuaString = str
    return retval
end

function do_save_as_dialog(document)
    local path_name = finale.FCString()
    local file_name = finale.FCString()
    local file_path = finale.FCString()
    document:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
    local full_file_name = file_name.LuaString
    local extension = finale.FCString()
    extension.LuaString = file_name.LuaString
    extension:ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("."..extension.LuaString))
    end
    file_name:AppendLuaString(text_extension)
    local save_dialog = mixin.FCMFileSaveAsDialog(finenv.UI())
            :SetWindowTitle(fcstr("Save "..full_file_name.." As"))
            :AddFilter(fcstr("*"..text_extension), fcstr("Text File"))
            :SetInitFolder(path_name)
            :SetFileName(file_name)
    save_dialog:AssureFileExtension(text_extension)
    if not save_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    save_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end

-- known_chars includes SMuFL characters and other non-ASCII characters that are known
-- to represent common articulations and dynamics
local known_chars = {
    [0xe4a0] = ">",  
    [0xe4a2] = ".",
}

function get_char_string(char)
    if known_chars[char] then
        return known_chars[char]
    end
    if char > 255 then
        return "#"..string.format("%x", char)
    end
    return string.char(char)
end

function entry_string(entry)
    local retval = ""
    -- ToDo: write entry-attached items (articulations done)
    local articulations = entry:CreateArticulations()
    for articulation in each(articulations) do
        local articulation_def = articulation:CreateArticulationDef()
        retval = retval .. " " .. get_char_string(articulation_def.MainSymbolChar)
    end
    if entry:IsRest() then
        retval = retval .. " RR"
    else
        for note_index = 0,entry.Count-1 do
            local note = entry:GetItemAt(note_index)
            retval = retval .. " " .. note_entry.calc_pitch_string(note).LuaString
        end
    end
    return retval
end

function create_measure_table(measure_region)
    local measure_table = {}
    for entry in eachentry(measure_region) do
        if not measure_table[entry.Staff] then
            measure_table[entry.Staff] = {}
        end
        local staff_table = measure_table[entry.Staff]
        if not staff_table[entry.MeasurePos] then
            staff_table[entry.MeasurePos] = {}
        end
        local edupos_table = staff_table[entry.MeasurePos]
        if not edupos_table.entries then
            edupos_table.entries = {}
        end
        table.insert(edupos_table.entries, entry_string(entry))
    end
    return measure_table
end

function write_measure(file, measure, measure_number_regions)
    local display_text = finale.FCString()
    local region_number = measure_number_regions:CalcStringFromNumber(measure.ItemNo, display_text)
    if region_number < 0 then
        display_text.LuaString = "#"..tostring(measure.ItemNo)
    end
    file:write("\n")
    file:write("Measure ", measure.ItemNo, " [", display_text.LuaString, "]\n")
    local measure_region = finale.FCMusicRegion()
    measure_region:SetFullDocument()
    measure_region.StartMeasure = measure.ItemNo
    measure_region.EndMeasure = measure.ItemNo
    local measure_table = create_measure_table(measure_region)
    for slot = 1, measure_region.EndSlot do
        local staff_number = measure_region:CalcStaffNumber(slot)
        local staff_table = measure_table[staff_number]
        if staff_table then
            --require('mobdebug').start()
            local staff = finale.FCCurrentStaffSpec()
            local staff_name = ""
            if staff:LoadForCell(finale.FCCell(measure.ItemNo, staff_number), 0) then
                staff_name = staff:CreateDisplayFullNameString().LuaString
            end 
            if staff_name == "" then
                staff_name = "Staff " .. staff_number
            end
            file:write("  ", staff_name, ":")
            for edupos, edupos_table in pairsbykeys(staff_table) do
                file:write(" ["..tostring(edupos).."]")
                -- ToDo: write expressions, smart shapes first
                if edupos_table.entries then
                    for _, entry_string in ipairs(edupos_table.entries) do
                        file:write(entry_string)
                    end
                end
            end
            file:write("\n")
        end
    end
end

function document_save_as_text()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()
    local file_to_write = do_save_as_dialog(document)
    if not file_to_write then
        return
    end
    local file = io.open(file_to_write, "w")
    if not file then
        finenv.UI():AlertError("Unable to open " .. file_to_write .. ". Please check folder permissions.", "")
        return
    end
    local document_path = finale.FCString()
    document:GetPath(document_path)
    file:write("Script document_save_as_text.lua version ", finaleplugin.Version, "\n")
    file:write(document_path.LuaString, "\n")
    file:write("Saving as ", file_to_write, "\n")
    local measures = finale.FCMeasures()
    measures:LoadAll()
    local measure_number_regions = finale.FCMeasureNumberRegions()
    measure_number_regions:LoadAll()
    for measure in each(measures) do
        write_measure(file, measure, measure_number_regions)
    end
    file:close()
end

document_save_as_text()
