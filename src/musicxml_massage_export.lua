function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "September 24, 2024"
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.74
    finaleplugin.Notes = [[
        This script reads a musicxml file exported from the current open document and makes changes to
        improve the xml over what Finale produces. The best process is as follows:

        1. Export the current open document as uncompressed MusicXML.
        2. Keeping your document open, run this plugin on the output *.musicxml document.
        3. Import the massaged *.musicxml into a different program.

        Here is a list of some of the changes the script makes:

        - 8va/8vb and 15ma/15mb symbols are extended to include the last note and extended left to include leading grace notes.
    ]]
    return "Massage MusicXML...", "", "Massages the MusicXML for the current open document."
end

local mixin = require("library.mixin")

local text_extension = ".musicxml"

function do_open_dialog(document)
    local path_name = finale.FCString()
    local file_name = finale.FCString()
    local file_path = finale.FCString()
    if document then
        document:GetPath(file_path)
        file_path:SplitToPathAndFile(path_name, file_name)
    end
    local full_file_name = file_name.LuaString
    local extension = mixin.FCMString()
        :SetLuaString(file_name.LuaString)
        :ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("." .. extension.LuaString))
    end
    file_name:AppendLuaString(text_extension)
    local open_dialog = mixin.FCMFileOpenDialog(finenv.UI())
        :SetWindowTitle(finale.FCString("Open MusicXML for " .. full_file_name))
        :AddFilter(finale.FCString("*" .. text_extension), finale.FCString("MusicXML File"))
        :SetInitFolder(path_name)
        :SetFileName(file_name)
    open_dialog:AssureFileExtension(text_extension)
    if not open_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    open_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
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
                    local sign = shift_type == "down" and 1 or -1 -- direction to transpose grace notes
                    local octaves = (octave_shift:IntAttribute("size", 8) - 1) / 7
                    print (sign, octaves, "size:", octave_shift:IntAttribute("size", 8))
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

function music_xml_massage_export()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local document = documents:FindCurrent()
    local xml_file = do_open_dialog(document)
    if not xml_file then
        return
    end
    local musicxml = tinyxml2.XMLDocument()
    local result = musicxml:LoadFile(xml_file)
    if result ~= tinyxml2.XML_SUCCESS then
        error("Unable to process " .. xml_file .. ". " .. musicxml:ErrorStr())
        return
    end
    local score_partwise = musicxml:FirstChildElement("score-partwise")
    if not score_partwise then
        error("File " .. xml_file .. " does not appear to be a Finale-exported MusicXML file.")
    end
    process_xml(score_partwise)
    musicxml:SaveFile(xml_file)
end

music_xml_massage_export()
