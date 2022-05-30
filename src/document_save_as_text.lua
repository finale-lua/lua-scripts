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
    print(path_name.LuaString)
    print(file_name.LuaString)
    local extension = finale.FCString()
    extension.LuaString = file_name.LuaString
    extension:ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("."..extension.LuaString))
    end
    file_name:AppendLuaString(text_extension)
    local save_dialog = mixin.FCMFileSaveAsDialog(finenv.UI())
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

function write_measure(file, measure, measure_number_regions)
    local display_text = finale.FCString()
    local region_number = measure_number_regions:CalcStringFromNumber(measure.ItemNo, display_text)
    if region_number < 0 then
        display_text.LuaString = "#"..tostring(measure.ItemNo)        
    end
    file:write("\n")
    file:write("Measure ", measure.ItemNo, " [", display_text.LuaString, "]\n")
end

function document_save_as_text()
    require('mobdebug').start()
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
