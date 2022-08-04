function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "May 30, 2022"
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.63
    finaleplugin.Notes = [[
        This script encodes the current document to a utf-8 text file. The primary purpose is to find changes
        between one version of a document and another. One would then write each version out to a text file and then
        use a comparison tool like kdiff3 to find differences. The text files could also be used to track changes with a tool like Git.

        The specifics of the shorthand for how the music is represented may not be that important.
        The idea is to identify the measures and staves that are different and then look at the score to see the differences.

        The following are encoded in such a way that if they are different, a comparison tool will flag them.

        - notes and rhythms
        - articulations
        - expressions (both text and shape)
        - ties
        - smart shapes
        - lyric assignments

        Chord symbols are currently not encoded, due to the lack of a simple way to generate a string for them. This is a needed
        future enhancement.

        The goal of this script is to assist in finding *substantive* differences that would affect how a player would play the piece.
        The script encodes the items above but not small engraving differences such as placement coordinates. One hopes, for example,
        that if there were a printed score that were out of date, this tool would flag the minimum number of changes that needed to
        be hand-corrected in the older score.
    ]]
    return "Save Document As Text File...", "", "Write current document to text file."
end

local library = require("library.general_library")

local text_extension = ".txt"

local note_entry = require('library.note_entry')
local expression = require('library.expression')
local enigma_string = require('library.enigma_string')
local mixin = require('library.mixin')

local fcstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end

function do_save_as_dialog(document)
    local path_name = finale.FCString()
    local file_name = finale.FCString()
    local file_path = finale.FCString()
    document:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
    local full_file_name = file_name.LuaString
    local extension = mixin.FCMString()
                            :SetLuaString(file_name.LuaString)
                            :ExtractFileExtension()
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

local smart_shape_codes = {
    [finale.SMARTSHAPE_SLURDOWN] = "SU",
    [finale.SMARTSHAPE_DIMINUENDO] = "DM",
    [finale.SMARTSHAPE_CRESCENDO] = "CR",
    [finale.SMARTSHAPE_OCTAVEDOWN ] = "8B",
    [finale.SMARTSHAPE_OCTAVEUP] = "8V",
    [finale.SMARTSHAPE_DASHLINEUP] = "DU",
    [finale.SMARTSHAPE_DASHLINEDOWN] = "DD",
    [finale.SMARTSHAPE_DASHCURVEDOWN] = "DCU",
    [finale.SMARTSHAPE_DASHCURVEUP] = "DCU",
    [finale.SMARTSHAPE_DASHLINE ] = "DL",
    [finale.SMARTSHAPE_SOLIDLINE] = "SL",
    [finale.SMARTSHAPE_SOLIDLINEDOWN] = "SLD",
    [finale.SMARTSHAPE_SOLIDLINEUP] = "SLU",
    [finale.SMARTSHAPE_SLURAUTO] = "SS",
    [finale.SMARTSHAPE_DASHCURVEAUTO] = "DC",
    [finale.SMARTSHAPE_TRILLEXT] = "TE",
    [finale.SMARTSHAPE_SOLIDLINEDOWN2] = "SLD2",
    [finale.SMARTSHAPE_SOLIDLINEUP2] = "SLU2",
    [finale.SMARTSHAPE_TWOOCTAVEDOWN] = "15B",
    [finale.SMARTSHAPE_TWOOCTAVEUP] = "15V",
    [finale.SMARTSHAPE_DASHLINEDOWN2] = "DLD2",
    [finale.SMARTSHAPE_DASHLINEUP2] = "DLU2",
    [finale.SMARTSHAPE_GLISSANDO] = "GL",
    [finale.SMARTSHAPE_TABSLIDE] = "TS",
    [finale.SMARTSHAPE_BEND_HAT] = "BH",
    [finale.SMARTSHAPE_BEND_CURVE] = "BC",
    [finale.SMARTSHAPE_CUSTOM] = "CU",
    [finale.SMARTSHAPE_SOLIDLINEUPLEFT] = "SLUL",
    [finale.SMARTSHAPE_SOLIDLINEDOWNLEFT] = "SLDL",
    [finale.SMARTSHAPE_DASHLINEUPLEFT ] = "DLUL",
    [finale.SMARTSHAPE_DASHLINEDOWNLEFT ] = "DLDL",
    [finale.SMARTSHAPE_SOLIDLINEUPDOWN ] = "SLUD",
    [finale.SMARTSHAPE_SOLIDLINEDOWNUP] = "SLDU",
    [finale.SMARTSHAPE_DASHLINEUPDOWN] = "DLUD",
    [finale.SMARTSHAPE_DASHLINEDOWNUP] = "DLDU",
    [finale.SMARTSHAPE_HYPHEN] = "HY",
    [finale.SMARTSHAPE_WORD_EXT] = "WE",
    [finale.SMARTSHAPE_DASHEDSLURDOWN] = "DSD",
    [finale.SMARTSHAPE_DASHEDSLURUP] = "DSU",
    [finale.SMARTSHAPE_DASHEDSLURAUTO] = "DS"
}

function get_smartshape_string(smart_shape, beg_mark, end_mark)
    local desc = smart_shape_codes[smart_shape.ShapeType]
    if not desc then
        return "S"..tostring(smart_shape.ShapeType)
    end
    if smart_shape.ShapeType == finale.SMARTSHAPE_CUSTOM then
        desc = desc .. tostring(smart_shape.LineID)
    end
    if end_mark then
        desc = "<-" .. desc
    end
    if beg_mark then
        desc = desc .. "->"
    end
    return desc
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
    if char < 32 then
        return " "
    end
    return utf8.char(char)
end

function entry_string(entry)
    local retval = ""
    -- ToDo: write entry-attached items (articulations, lyrics done)
    local articulations = entry:CreateArticulations()
    for articulation in each(articulations) do
        local articulation_def = articulation:CreateArticulationDef()
        if articulation_def.MainSymbolIsShape then
            retval = retval .. " sa" .. tostring(articulation_def.MainSymbolShapeID)
        else
            retval = retval .. " " .. get_char_string(articulation_def.MainSymbolChar)
        end
    end
    local smart_shape_marks = finale.FCSmartShapeEntryMarks(entry)
    local already_processed = {}
    if smart_shape_marks:LoadAll() then
        for mark in each(smart_shape_marks) do
            if not already_processed[mark.ShapeNumber] then
                already_processed[mark.ShapeNumber] = true
                local beg_mark = mark:CalcLeftMark()
                local end_mark = mark:CalcRightMark()
                if beg_mark or end_mark then
                    local smart_shape = mark:CreateSmartShape()
                    if not smart_shape:CalcLyricBased() then
                        retval = retval .. " " .. get_smartshape_string(smart_shape, beg_mark, end_mark)
                    end
                end
            end
        end
    end
    if entry:IsRest() then
        retval = retval .. " RR"
    else
        for note_index = 0,entry.Count-1 do
            local note = entry:GetItemAt(note_index)
            retval = retval .. " "
            if note.TieBackwards then
                retval = retval .. "<-"
            end
            retval = retval .. note_entry.calc_pitch_string(note).LuaString
            if note.Tie then
                retval = retval .. "->"
            end
        end
    end
    for _, syllables in ipairs({finale.FCVerseSyllables(entry), finale.FCChorusSyllables(entry), finale.FCSectionSyllables(entry)}) do
        if syllables:LoadAll() then
            for syllable in each(syllables) do
                local syllable_text = finale.FCString()
                if syllable:GetText(syllable_text) then
                    syllable_text:TrimEnigmaTags()
                    retval = retval .. " " .. syllable_text.LuaString
                end
            end
        end
    end
    return retval
end

local get_edupos_table = function(measure_table, staff_number, edupos)
    if not measure_table[staff_number] then
        measure_table[staff_number] = {}
    end
    local staff_table = measure_table[staff_number]
    if not staff_table[edupos] then
        staff_table[edupos] = {}
    end
    return staff_table[edupos]
end

function create_measure_table(measure_region, measure)
    local measure_table = {}
    -- ToDo: chords
    local expression_assignments = measure:CreateExpressions()
    for expression_assignment in each(expression_assignments) do
        local staff_num = expression_assignment:CalcStaffInPageView()
        if staff_num > 0 then
            if expression.is_for_current_part(expression_assignment) and expression_assignment.Visible then
                local edupos_table = get_edupos_table(measure_table, staff_num, expression_assignment.MeasurePos)
                if not edupos_table.expressions then
                    edupos_table.expressions = {}
                end
                if expression_assignment.Shape then
                    local shapeexp_def = expression_assignment:CreateShapeExpressionDef()
                    table.insert(edupos_table.expressions, " Shape "..tostring(shapeexp_def.ID))
                else
                    local textexp_def = expression_assignment:CreateTextExpressionDef()
                    local exp_text = textexp_def:CreateTextString()
                    enigma_string.expand_value_tag(exp_text, textexp_def:GetPlaybackTempoValue())
                    exp_text:TrimEnigmaTags()
                    table.insert(edupos_table.expressions, " " .. exp_text.LuaString)
                end
            end
        end
    end
    local smart_shape_marks = finale.FCSmartShapeMeasureMarks()
    local already_processed = {}
    if smart_shape_marks:LoadAllForRegion(measure_region) then
        for mark in each(smart_shape_marks) do
            local smart_shape = mark:CreateSmartShape()
            if not already_processed[smart_shape.ShapeNumber] and not smart_shape.EntryBased and not smart_shape:CalcLyricBased() then
                already_processed[mark.ShapeNumber] = true
                local lterm = smart_shape:GetTerminateSegmentLeft()
                local rterm = smart_shape:GetTerminateSegmentRight()
                local beg_mark = lterm.Measure == measure.ItemNo
                local end_mark = lterm.Measure == measure.ItemNo
                if beg_mark or end_mark then
                    if beg_mark then
                        local edupos_table = get_edupos_table(measure_table, lterm.Staff, lterm.MeasurePos)
                        if not edupos_table.smartshapes then
                            edupos_table.smartshapes = {}
                        end
                        local left_and_right = end_mark and rterm.Staff == lterm.Staff and rterm.Measure == lterm.Measure and rterm.MeasurePos == lterm.MeasurePos
                        local desc = get_smartshape_string(smart_shape, true, left_and_right)
                        if desc then
                            table.insert(edupos_table.smartshapes, " " .. desc)
                        end
                        if left_and_right then
                            end_mark = false
                        end
                    end
                    if end_mark then
                        -- if we get here, the shape has separate beg and end points, because of left_and_right check above
                        local edupos_table = get_edupos_table(measure_table, rterm.Staff, rterm.MeasurePos)
                        if not edupos_table.smartshapes then
                            edupos_table.smartshapes = {}
                        end
                        local desc = get_smartshape_string(smart_shape, false, true)
                        if desc then
                            table.insert(edupos_table.smartshapes, " " .. desc)
                        end
                    end
                end
            end
        end
    end
    for entry in eachentry(measure_region) do
        local edupos_table = get_edupos_table(measure_table, entry.Staff, entry.MeasurePos)
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
    local measure_table = create_measure_table(measure_region, measure)
    for slot = 1, measure_region.EndSlot do
        local staff_number = measure_region:CalcStaffNumber(slot)
        local staff_table = measure_table[staff_number]
        if staff_table then
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
                -- ToDo: chords first
                if edupos_table.smartshapes then
                    for _, ss_string in ipairs(edupos_table.smartshapes) do
                        file:write(ss_string)
                    end
                end
                if edupos_table.expressions then
                    for _, exp_string in ipairs(edupos_table.expressions) do
                        file:write(exp_string)
                    end
                end
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
    local score_part = nil
    if not library.get_current_part():IsScore() then
        score_part = library.get_score()
        score_part:SwitchTo()
    end
    -- no more return statements allowed in this function until
    -- scort_part checked below
    local document_path = finale.FCString()
    document:GetPath(document_path)
    file:write("Script document_save_as_text.lua version ", finaleplugin.Version, "\n")
    file:write(document_path.LuaString, "\n")
    file:write("Saving as ", file_to_write, "\n")
    local measure_number_regions = finale.FCMeasureNumberRegions()
    measure_number_regions:LoadAll()
    for measure in loadall(finale.FCMeasures()) do
        write_measure(file, measure, measure_number_regions)
    end
    file:close()
    if score_part then
        score_part:SwitchBack()
    end
end

document_save_as_text()
