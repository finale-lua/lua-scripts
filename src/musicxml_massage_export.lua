function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson and Carl Vine"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "2.0"
    finaleplugin.Date = "October 6, 2024"
    finaleplugin.LoadLuaOSUtils = true
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.75
    finaleplugin.AdditionalMenuOptions = [[
        Massage MusicXML Single File...
    ]]
    finaleplugin.AdditionalUndoText = [[
        Massage MusicXML Single File
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Massage a MusicXML file to improve importing to Dorico and MuseScore
    ]]
    finaleplugin.AdditionalPrefixes = [[
        do_single_file = true
    ]]
    finaleplugin.ScriptGroupName = "Staff Explode"
    finaleplugin.Notes = [[
        This script reads musicxml files exported from Finale and modifies them to
        improve importing into Dorico or MuseScore. The best process is as follows:

        1. Export your document as uncompressed MusicXML.
        2. Run this plugin on the output *.musicxml document.
        3. The massaged file name has " massaged" appended to the file name.
        3. Import the massaged *.musicxml file into Dorico or MuseScore.

        Here is a list of some of the changes the script makes:

        - 8va/8vb and 15ma/15mb symbols are extended to include the last note and extended left to include leading grace notes.
        - Remove "real" whole rests from fermata measures. This issue arises when the fermata was attached to a "real" whole rest.
        The fermata is retained in the MusicXML, but the whole rest is removed. This makes for a better import, especially into MuseScore 4.
        - When a parallel `.musx` or `.mus` file is found, changes all rests in the MusicXML to floating if they were floating rests
        in the original Finale file.

        Due to a limitation in the xml parser, all xml processing instructions are removed. These are metadata that neither
        Dorico nor MuseScore use, so their removal should not affect importing into those programs.
    ]]
    return "Massage MusicXML Folder...",
        "Massage MusicXML Folder",
        "Massage a folder of MusicXML files to improve importing to Dorico and MuseScore."
end

local lfs = require("lfs")
local text = require("luaosutils").text

local utils = require("library.utils")

do_single_file = do_single_file or false
local XML_EXTENSION <const> = ".musicxml"
local ADD_TO_FILENAME <const> = " massaged"
local EDU_PER_QUARTER <const> = 1024

local LOGFILE_NAME <const> = "FinaleMassageMusicXMLLog.txt"
local logfile_path
local error_occured = false
local error_count = 0
local currently_processing
local current_staff
local current_measure

function log_message(msg, is_error)
    if is_error then
        error_occured = true
        error_count = error_count + 1
    end
    local log_entry = "[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] " .. currently_processing .. " "
    if current_staff > 0 and current_measure > 0 then
        local staff_text = (function()
            local retval = "p" .. current_staff
            local staff = finale:FCStaff()
            if staff:Load(finale.FCMusicRegion():CalcStaffNumber(current_staff)) then
                local name = staff:CreateTrimmedFullNameString()
                retval = retval .. "[" .. name.LuaString .. "]"
            end
            return retval
        end)()
        log_entry = log_entry .. "(" .. staff_text .. " m" .. current_measure .. ") "
    end
    if is_error then
        log_entry = log_entry .. "ERROR: "
    end
    log_entry = log_entry .. msg
    if finenv.ConsoleIsAvailable then
        print(log_entry)
    end
    local file <close> = io.open(logfile_path, "a")
    if not file then
        error("unable to append to logfile " .. logfile_path)
    end
    file:write(log_entry .. "\n")
    file:close()
end

local function remove_processing_instructions(input_name, output_name)
    local input_file <close> = io.open(text.convert_encoding(input_name, text.get_utf8_codepage(), text.get_default_codepage()), "r")
    if not input_file then
        error("Cannot open file: " .. input_name)
    end
    local lines = {} -- assemble the output file line by line
    local number_removed = 0
    for line in input_file:lines() do
        if line:match("^%s*<%?xml") or not line:match("^%s*<%?.*%?>") then
            table.insert(lines, line)
        else
            number_removed = number_removed + 1
        end
    end
    input_file:close()
    local output_file <close> = io.open(text.convert_encoding(output_name, text.get_utf8_codepage(), text.get_default_codepage()), "w")
    if not output_file then
        error("Cannot open file for writing: " .. output_name)
    end
    for _, line in ipairs(lines) do
        output_file:write(line .. "\n")
    end
    output_file:close()
    if number_removed > 0 then
        log_message("removed " .. number_removed .. " processing instructions.")
    end
end

function fix_octave_shift(xml_measure)
    for xml_direction in xmlelements(xml_measure, "direction") do
        local xml_direction_type = xml_direction:FirstChildElement("direction-type")
        if xml_direction_type then
            local octave_shift = xml_direction_type:FirstChildElement("octave-shift")
            if octave_shift then
                local direction_copy = xml_direction:DeepClone(xml_direction:GetDocument())
                local shift_type = octave_shift:Attribute("type")
                if shift_type == "stop" then
                    local next_note = xml_direction:NextSiblingElement("note")
                    if next_note and not next_note:FirstChildElement("rest") then
                        xml_measure:DeleteChild(xml_direction)
                        xml_measure:InsertAfterChild(next_note, direction_copy)
                        log_message("extended octave_shift element of size " .. octave_shift:IntAttribute("size", 8) .. " by one note.")
                    end
                elseif shift_type == "up" or shift_type == "down" then
                    local sign = shift_type == "down" and 1 or -1
                    local octaves = (octave_shift:IntAttribute("size", 8) - 1) / 7
                    local prev_grace_note
                    local prev_note = xml_direction:PreviousSiblingElement("note")
                    while prev_note do
                        if not prev_note:FirstChildElement("rest") and prev_note:FirstChildElement("grace") then
                            prev_grace_note = prev_note
                            local pitch = prev_note:FirstChildElement("pitch")
                            local octave = pitch and pitch:FirstChildElement("octave")
                            if octave then
                                octave:SetIntText(octave:IntText() + sign*octaves)
                            end
                        else
                            break
                        end
                        prev_note = prev_note:PreviousSiblingElement("note")
                    end
                    if prev_grace_note then
                        xml_measure:DeleteChild(xml_direction)
                        local prev_element = prev_grace_note:PreviousSiblingElement()
                        if prev_element then
                            xml_measure:InsertAfterChild(prev_element, direction_copy)
                        else
                            xml_measure:InsertFirstChild(direction_copy)
                        end
                        log_message("adjusted octave_shift element of size " .. octave_shift:IntAttribute("size", 8) .. " for preceding grace notes.")
                    end
                end
            end
        end
    end
end

function fix_fermata_whole_rests(xml_measure)
    if xml_measure:ChildElementCount("note") == 1 then
        local xml_note = xml_measure:FirstChildElement("note")
        if xml_note:FirstChildElement("rest") then
            local note_type = xml_note:FirstChildElement("type")
            if note_type and note_type:GetText() == "whole" then
                for notations in xmlelements(xml_note, "notations") do
                    if notations:FirstChildElement("fermata") then
                        xml_note:DeleteChild(note_type)
                        log_message("removed real whole rest under fermata.")
                        break
                    end
                end
            end
        end
    end
end

local duration_types = {
    maxima = EDU_PER_QUARTER * 32,
    long = EDU_PER_QUARTER * 16,
    breve = EDU_PER_QUARTER * 8,
    whole = EDU_PER_QUARTER * 4,
    half = EDU_PER_QUARTER * 2,
    quarter = EDU_PER_QUARTER * 1,
    eighth = EDU_PER_QUARTER / 2,
    ["16th"] = EDU_PER_QUARTER / 4,
    ["32nd"] = EDU_PER_QUARTER / 8,
    ["64th"] = EDU_PER_QUARTER / 16,
    ["128th"] = EDU_PER_QUARTER / 32,
    ["256th"] = EDU_PER_QUARTER / 64,
    ["512th"] = EDU_PER_QUARTER / 128,
    ["1024th"] = EDU_PER_QUARTER / 256,
}

function process_xml_with_finale_document(xml_measure, staff_slot, measure, duration_unit)
    local region = finale.FCMusicRegion()
    region.StartSlot = staff_slot
    region.StartMeasure = measure
    region:SetStartMeasurePosLeft()
    region.EndSlot = staff_slot
    region.EndMeasure = measure
    region:SetEndMeasurePosRight()
    local next_note
    for entry in eachentry(region) do
        if entry.Visible then -- Dolet does not create note elements for invisible entries
            if not next_note then
                next_note = xml_measure:FirstChildElement("note")
            else
                next_note = next_note:NextSiblingElement("note")
            end
            if not next_note then
                log_message("xml notes do not match open document", true)
                return false
            end
            local note_type_node = next_note:FirstChildElement("type")
            local note_type_duration = note_type_node and duration_types[note_type_node:GetText()]
            local num_dots = next_note:ChildElementCount("dot")
            note_type_duration = note_type_duration * (2 - 1 / (2 ^ num_dots))
            if not note_type_duration or note_type_duration ~= entry.Duration then
                -- try actual durations
                local EPSILON <const> = 1.001 -- allow actual durations to be off by a single EDU, to account for tuplets, plus 0.001 rounding slop
                local duration_node = next_note:FirstChildElement("duration")
                local xml_duration = (duration_node and duration_node:DoubleText() or 0) * duration_unit
                if math.abs(entry.ActualDuration - xml_duration) > EPSILON then
                    log_message("xml durations do not match document: [" .. entry.Duration .. ", " .. note_type_duration .. "])", true)
                    return false
                end    
            end
            -- refloat floating rests
            if entry:IsRest() then
                local rest_element = next_note:FirstChildElement("rest")
                if not rest_element then
                    log_message("xml corresponding note value in document is not a rest", true)
                    return false
                end
                if entry.FloatingRest then
                    local function delete_element(element_name)
                        local element = rest_element:FirstChildElement(element_name)
                        if element then
                            rest_element:DeleteChild(element)
                            return true
                        end
                        return false
                    end
                    local deleted_pitch = delete_element("display-step")
                    local deleted_octave = delete_element("display-octave")
                    if deleted_pitch or deleted_octave then
                        log_message("refloated rest of duration " ..
                            entry.Duration / EDU_PER_QUARTER .. " quarter notes.")
                    end
                end
            end
            -- skip over extra notes in chords
            local chord_check = next_note:NextSiblingElement("note")
            while chord_check and chord_check:FirstChildElement("chord") do
                next_note = chord_check
                chord_check = chord_check:NextSiblingElement("note")
            end
        end
    end
    return true
end

function process_xml(score_partwise, document)
    if not document then
        log_message("WARNNG: corresponding Finale document not found")
    end
    current_staff = 0
    for xml_part in xmlelements(score_partwise, "part") do
        current_staff = current_staff + 1
        current_measure = 0
        local duration_unit = EDU_PER_QUARTER
        for xml_measure in xmlelements(xml_part, "measure") do
            local divisions = tinyxml2.XMLHandle(xml_measure)
                :FirstChildElement("attributes")
                :FirstChildElement("divisions")
                :ToElement()
            if divisions then
                duration_unit = EDU_PER_QUARTER / divisions:DoubleText(1)
            end
            current_measure = current_measure + 1
            if document then
                process_xml_with_finale_document(xml_measure, current_staff, current_measure, duration_unit)
            end
            fix_octave_shift(xml_measure)
            fix_fermata_whole_rests(xml_measure)
        end
    end
    current_staff = 0
    current_measure = 0
end

-- return document, close_required, switchback_required
function open_finale_document(document_path)
    local documents = finale.FCDocuments()
    documents:LoadAll()
    for document in each(documents) do
        local this_path = finale.FCString()
        document:GetPath(this_path)
        if this_path:IsEqual(document_path) then
            local switchback_required = false
            if not document:IsCurrent() then
                document:SwitchTo()
                document:DisplayVisually()
                switchback_required = true
            end
            return document, false, switchback_required
        end
    end
    local document = finale.FCDocument()
    if not document:Open(finale.FCString(document_path), true, nil, false, false, true) then
        log_message("unable to open corresponding Finale document", true)
        return nil, false, false
    end
    return document, true, true
end

function process_one_file(input_file)
    currently_processing = input_file
    current_staff = 0
    current_measure = 0
    error_count = 0

    local path, filename, extension = utils.split_file_path(input_file)
    assert(#path > 0 and #filename > 0 and #extension > 0, "invalid file path format")
    local output_file = path .. filename .. ADD_TO_FILENAME .. XML_EXTENSION
    local document_path = (function()
        local function exist(try_path)
            local attr = lfs.attributes(text.convert_encoding(try_path, text.get_utf8_codepage(), text.get_utf8_codepage()))
            return attr and attr.mode == "file"
        end
        local try_path = path .. filename .. ".musx"
        if exist(try_path) then return try_path end
        try_path = path .. filename .. ".mus"
        if exist(try_path) then return try_path end
        return nil
    end)()
    
    local document, close_required, switchback_required
    if document_path then
        document, close_required, switchback_required = open_finale_document(document_path)
    end

    log_message("***** START OF PROCESSING *****")

    remove_processing_instructions(input_file, output_file)
    local musicxml = tinyxml2.XMLDocument()
    local result = musicxml:LoadFile(output_file)
    if result ~= tinyxml2.XML_SUCCESS then
        log_message("file does not appear to be exported from Finale", true)
        os.remove(text.convert_encoding(output_file, text.get_utf8_codepage(), text.get_default_codepage())) -- delete erroneous file
        return
    end
    local score_partwise = musicxml:FirstChildElement("score-partwise")
    if not score_partwise then
        log_message("file does not appear to be exported from Finale", true)
        os.remove(text.convert_encoding(output_file, text.get_utf8_codepage(), text.get_default_codepage())) -- delete erroneous file
        return
    end
    process_xml(score_partwise, document)
    currently_processing = output_file
    if musicxml:SaveFile(output_file) then
        if error_count > 0 then
            log_message("successfully saved file with " .. error_count .. " processing errors.")
        else
            log_message("successfully saved file")
        end
    else
        log_message("unable to save massaged file: " .. musicxml:ErrorStr(), true)
    end
    if document then
        if close_required then
            document:CloseCurrentDocumentAndWindow()
        end
        if switchback_required then
            document:SwitchBack()
        end
    end
end

function process_directory(path_name)
    local folder_dialog = finale.FCFolderBrowseDialog(finenv.UI())
    folder_dialog:SetWindowTitle(finale.FCString("Select Folder of MusicXML Files:"))
    folder_dialog:SetFolderPath(path_name)
    if not folder_dialog:Execute() then
        return false -- user cancelled
    end
    local selected_directory = finale.FCString()
    folder_dialog:GetFolderPath(selected_directory)
    folder_dialog:AssureEndingPathDelimiter()

    create_logfile(selected_directory.LuaString)

    for dir_name, file_name in utils.eachfile(selected_directory.LuaString, true) do
        if file_name:sub(-XML_EXTENSION:len()) == XML_EXTENSION then
            process_one_file(dir_name .. file_name)
        end
    end
    return true
end

function do_open_dialog(path_name)
    local open_dialog = finale.FCFileOpenDialog(finenv.UI())
    open_dialog:SetWindowTitle(finale.FCString("Select a MusicXML File:"))
    open_dialog:AddFilter(finale.FCString("*" .. XML_EXTENSION), finale.FCString("MusicXML File"))
    open_dialog:SetInitFolder(path_name)
    open_dialog:AssureFileExtension(XML_EXTENSION)
    if not open_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    open_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end

function create_logfile(path_name)
    logfile_path = text.convert_encoding(path_name, text.get_utf8_codepage(), text.get_default_codepage()) .. LOGFILE_NAME
    local file <close> = io.open(logfile_path, "w")
    if not file then
        error("unable to create logfile " .. logfile_path, 2)
    end
    file:close()
end

function music_xml_massage_export()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()
    local path_name = finale.FCString()
    if document then -- extract active pathname
        document:GetPath(path_name)
        path_name:SplitToPathAndFile(path_name, nil)
    else
        path_name:SetMusicFolderPath()
    end
    path_name:AssureEndingPathDelimiter()

    local massaged = false
    if do_single_file then
        local xml_file = do_open_dialog(path_name)
        if xml_file then
            create_logfile(utils.split_file_path(xml_file))
            process_one_file(xml_file)
            massaged = true
        end
    else
        massaged = process_directory(path_name)
    end
    
    if massaged then
        finenv.UI():AlertInfo(error_occured and "Processed with errors" or "Processed without errors", "Complete")
    end
end

music_xml_massage_export()
