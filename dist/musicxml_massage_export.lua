function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson (folder scanning added by Carl Vine)"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.7"
    finaleplugin.Date = "October 6, 2024"
    finaleplugin.LoadLuaOSUtils = true
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.74
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
    finaleplugin.ScriptGroupName = "Massage MusicXML"
    finaleplugin.Notes = [[
        This script reads musicxml files exported from Finale and modifies them to
        improve importing into Dorico or MuseScore. The best process is as follows:

        1. Export your document as uncompressed MusicXML.
        2. Run this plugin on the output *.musicxml document.
        3. The massaged file name has " massaged" appended to the file name.
        3. Import the massaged *.musicxml file into Dorico or MuseScore.

        Here is a list of some of the changes the script makes:

        - 8va/8vb and 15ma/15mb symbols are extended to include the last note and extended left to include leading grace notes.

        Due to a limitation in the xml parser, all xml processing instructions are removed. These are metadata that neither
        Dorico nor MuseScore use, so their removal should not affect importing into those programs.
    ]]
    finaleplugin.RTFNotes = [[
        {\rtf1\ansi\deff0{\fonttbl{\f0 \fswiss Helvetica;}{\f1 \fmodern Courier New;}}
        {\colortbl;\red255\green0\blue0;\red0\green0\blue255;}
        \widowctrl\hyphauto
        \fs18
        {\info{\comment "os":"mac","fs18":"fs24","fs26":"fs32","fs23":"fs29","fs20":"fs26"}}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 This script reads musicxml files exported from Finale and modifies them to improve importing into Dorico or MuseScore. The best process is as follows:\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 1.\tx360\tab Export your document as uncompressed MusicXML.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 2.\tx360\tab Run this plugin on the output *.musicxml document.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 3.\tx360\tab The massaged file name has " massaged" appended to the file name.\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 4.\tx360\tab Import the massaged *.musicxml file into Dorico or MuseScore.\sa180\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Here is a list of some of the changes the script makes:\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa0 \li360 \fi-360 \bullet \tx360\tab 8va/8vb and 15ma/15mb symbols are extended to include the last note and extended left to include leading grace notes.\sa180\par}
        {\pard \sl264 \slmult1 \ql \f0 \sa180 \li0 \fi0 Due to a limitation in the xml parser, all xml processing instructions are removed. These are metadata that neither Dorico nor MuseScore use, so their removal should not affect importing into those programs.\par}
        }
    ]]
    finaleplugin.HashURL = "https://raw.githubusercontent.com/finale-lua/lua-scripts/master/hash/musicxml_massage_export.hash"
    return "Massage MusicXML Folder...",
        "Massage MusicXML Folder",
        "Massage a folder of MusicXML files to improve importing to Dorico and MuseScore."
end
do_single_file = do_single_file or false
local xml_extension = ".musicxml"
local add_to_filename = " massaged"
local function alert_error(file_list)
    local msg = (#file_list > 1 and "These files do not " or "This file does not ")
        .. "appear to be MusicXML exported from Finale:\n\n"
        .. table.concat(file_list, "\n")
    finenv.UI():AlertError(msg, plugindef())
end
local function remove_processing_instructions(input_name, output_name)
    local input_file <close> = io.open(input_name, "r")
    if not input_file then
        error("Cannot open file: " .. input_name)
    end
    local lines = {}
    for line in input_file:lines() do
        if line:match("^%s*<%?xml") or not line:match("^%s*<%?.*%?>") then
            table.insert(lines, line)
        end
    end
    input_file:close()
    local output_file <close> = io.open(output_name, "w")
    if not output_file then
        error("Cannot open file for writing: " .. output_name)
    end
    for _, line in ipairs(lines) do
        output_file:write(line .. "\n")
    end
    output_file:close()
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
                    end
                end
            end
        end
    end
end
function process_xml(score_partwise)
    for xml_part in xmlelements(score_partwise, "part") do
        for xml_measure in xmlelements(xml_part, "measure") do
            fix_octave_shift(xml_measure)
        end
    end
end
function process_one_file(input_file)
    local path, filename, extension = input_file:match("^(.-)([^\\/]-)%.([^\\/%.]+)$")
    if not path or not filename or not extension then
        error("Invalid file path format")
    end
    local output_file = path .. filename .. add_to_filename .. xml_extension
    remove_processing_instructions(input_file, output_file)
    local musicxml = tinyxml2.XMLDocument()
    local result = musicxml:LoadFile(output_file)
    if result ~= tinyxml2.XML_SUCCESS then
        os.remove(output_file)
        return input_file
    end
    local score_partwise = musicxml:FirstChildElement("score-partwise")
    if not score_partwise then
        os.remove(output_file)
        return input_file
    end
    process_xml(score_partwise)
    musicxml:SaveFile(output_file)
    return ""
end
function process_directory(path_name)
    local folder_dialog = finale.FCFolderBrowseDialog(finenv.UI())
    folder_dialog:SetWindowTitle(finale.FCString("Select Folder of MusicXML Files:"))
    folder_dialog:SetFolderPath(path_name)
    if not folder_dialog:Execute() then
        return nil
    end
    local selected_directory = finale.FCString()
    folder_dialog:GetFolderPath(selected_directory)
    local src_dir = selected_directory.LuaString

    local error_list = {}
    local lfs = require("lfs")
    for file in lfs.dir(src_dir) do
        if file ~= "." and file ~= ".." and file:sub(-xml_extension:len()) == xml_extension then
            local file_error = process_one_file(src_dir .. "/" .. file)
            if file_error ~= "" then
                table.insert(error_list, file_error)
            end
        end
    end
    if #error_list > 0 then
        alert_error(error_list)
    end
end
function do_open_dialog(path_name)
    local open_dialog = finale.FCFileOpenDialog(finenv.UI())
    open_dialog:SetWindowTitle(finale.FCString("Select a MusicXML File:"))
    open_dialog:AddFilter(finale.FCString("*" .. xml_extension), finale.FCString("MusicXML File"))
    open_dialog:SetInitFolder(path_name)
    open_dialog:AssureFileExtension(xml_extension)
    if not open_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    open_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end
function music_xml_massage_export()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()
    local path_name = finale.FCString()
    if document then
        document:GetPath(path_name)
        path_name:SplitToPathAndFile(path_name, nil)
    end
    if do_single_file then
        local xml_file = do_open_dialog(path_name)
        if xml_file then
            local file_error = process_one_file(xml_file)
            if file_error ~= "" then
                alert_error{file_error}
            end
        end
    else
        process_directory(path_name)
    end
end
music_xml_massage_export()
