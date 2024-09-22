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
    document:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
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

function process_document(score_partwise)
    local doc_region = finale.FCMusicRegion()
    doc_region:SetFullDocument()
    -- Finale-exported musicxml files are score-partwise, as is the eachcell() function
    local xml_part = score_partwise:FirstChildElement("part")
    for staff in eachstaff(doc_region) do
        if not xml_part then
            error("No xml part element found for staff " .. staff .. ".")
        end
        local staff_region = finale.FCMusicRegion()
        staff_region:SetFullDocument()
        staff_region:SetStartStaff(staff)
        staff_region:SetEndStaff(staff)
        local xml_measure = xml_part:FirstChildElement("measure")
        for measure in eachcell(staff_region) do
            if not xml_measure or xml_measure:IntAttribute("number") ~= measure then
                error("No xml measure element found for measure " .. measure .. " in staff " .. staff .. ".")
            end
            print("staff", staff, "measure", measure)
            xml_measure = xml_measure:NextSiblingElement("measure")
        end
        xml_part = xml_part:NextSiblingElement("part")
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
        error("Unable to open " .. xml_file .. ".")
        return
    end
    local score_partwise = musicxml:FirstChildElement("score-partwise")
    if not score_partwise then
        error("File " .. xml_file .. " does not appear to be a Finale-exported MusicXML file.")
    end
    process_document(score_partwise)
    musicxml:SaveFile(xml_file)
end

music_xml_massage_export()
