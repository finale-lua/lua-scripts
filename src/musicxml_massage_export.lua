function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson (folder scanning added by Carl Vine)"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.4"
    finaleplugin.Date = "October 1, 2024"
    finaleplugin.LoadLuaOSUtils = true
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.74
    finaleplugin.Notes = [[
        This script reads a musicxml file exported from Finale and modifies it to
        improve the importing into Dorico or MuseScore. The best process is as follows:

        1. Export your document as uncompressed MusicXML.
        2. Run this plugin on the output *.musicxml document.
        3. The massaged file name has " massaged" appended to the file name.
        3. Import the massaged *.musicxml into Dorico or MuseScore.

        Here is a list of some of the changes the script makes:

        - 8va/8vb and 15ma/15mb symbols are extended to include the last note and extended left to include leading grace notes.

        Due to a limitation in the xml parser, all xml processing instructions are removed. These are metadata that neither
        Dorico nor MuseScore use, so their removal should not affect importing into those programs.
    ]]
    return "Massage MusicXML...",
        "Massage MusicXML",
        "Massages MusicXML to make it easier to import to Dorico and MuseScore."
end

local xml_extension = ".musicxml"
local add_to_filename = "massaged"

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
    local lines = {} -- assemble the output file line by line
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

local function choose_extraction_method()
    local fs = finale.FCString
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(fs(plugindef()))
    local stat = dialog:CreateStatic(0, 0)
        stat:SetText(fs("Massage the MusicXML for:"))
        stat:SetWidth(150)
    local labels = finale.FCStrings()
    labels:CopyFromStringTable{ "one MusicXML file", "a folder of MusicXML files" }
    local method = dialog:CreateRadioButtonGroup(0, 20, 2)
        method:SetText(labels)
        method:SetWidth(160)
        method:SetSelectedItem(1) -- assume "folder"
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, (method:GetSelectedItem() == 1)
end

local function choose_new_folder_dialog()
    local fs = finale.FCString
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(fs(plugindef()))
    local stat = dialog:CreateStatic(0, 0)
        stat:SetText(fs("Select a Different Folder"))
        stat:SetWidth(150)
    stat = dialog:CreateStatic(0, 15)
        stat:SetText(fs("for the Massaged Files:"))
        stat:SetWidth(150)
    local labels = finale.FCStrings()
    labels:CopyFromStringTable{ "YES", "NO" }
    local new_folder = dialog:CreateRadioButtonGroup(0, 35, 2)
        new_folder:SetText(labels)
        new_folder:SetWidth(80)
        new_folder:SetSelectedItem(0)
    local add = dialog:CreateCheckbox(0, 85)
        add:SetText(fs("Don't Add \"" .. add_to_filename .. "\" to Filenames"))
        add:SetWidth(210)
        add:SetCheck(1)
    stat = dialog:CreateStatic(15, 100)
        stat:SetText(fs("When Using a Different Folder"))
        stat:SetWidth(180)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local do_change_filename = (add:GetCheck() == 0)
    local select_new_folder = (new_folder:GetSelectedItem() == 0)
    return ok, select_new_folder, do_change_filename
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

function process_one_file(input_file, output_file, do_change_filename)
    if do_change_filename then -- add "massaged" to output_file
        local path, filename, extension = output_file:match("^(.-)([^\\/]-)%.([^\\/%.]+)$")
        if not path or not filename or not extension then
            error("Invalid file path format")
        end
        output_file = path .. filename .. " " .. add_to_filename .. "." .. extension
    end

    remove_processing_instructions(input_file, output_file)
    local musicxml = tinyxml2.XMLDocument()
    local result = musicxml:LoadFile(output_file)
    if result ~= tinyxml2.XML_SUCCESS then
        os.remove(output_file) -- delete erroneous file
        return input_file -- XML error
    end
    local score_partwise = musicxml:FirstChildElement("score-partwise")
    if not score_partwise then
        os.remove(output_file) -- delete erroneous file
        return input_file -- massaging failed
    end
    process_xml(score_partwise)
    musicxml:SaveFile(output_file)
    return ""
end

function do_open_directory()
    local src_dialog = finale.FCFolderBrowseDialog(finenv.UI())
    src_dialog:SetWindowTitle(finale.FCString("Open Folder of MusicXML Files:"))
    if not src_dialog:Execute() then
        return nil -- user cancelled
    end
    local selected_directory = finale.FCString()
    src_dialog:GetFolderPath(selected_directory)
    local src_dir = selected_directory.LuaString
    local out_dir = src_dir -- duplicate source to output (for now)

    local ok, select_new_folder, do_change_filename = choose_new_folder_dialog()
    if not ok then return end -- cancelled
    if select_new_folder then -- choose alternate destination dir
        local out_dialog = finale.FCFolderBrowseDialog(finenv.UI())
        out_dialog:SetWindowTitle(finale.FCString("Choose Folder for Massaged Files:"))
        if not out_dialog:Execute() then return end  -- user cancelled

        out_dialog:GetFolderPath(selected_directory)
        out_dir = selected_directory.LuaString
    end
    if out_dir == src_dir then -- user might "choose" same folder as original
        do_change_filename = true -- always change filenames in same directory
    end
    local osutils = finenv.EmbeddedLuaOSUtils and require("luaosutils")
    if not osutils then return end -- can't get a directory listing
    local options = finenv.UI():IsOnWindows() and "/b /ad" or "-1"
    local file_list = osutils.process.list_dir(src_dir, options)
    if file_list == "" then return end -- empty directory

    -- run through the file list, identifying valid candidates
    local error_list = {}
    for x_file in file_list:gmatch("([^\r\n]*)[\r\n]?") do
        if x_file:sub(-xml_extension:len()) == xml_extension then
            local src_file = src_dir .. "/" .. x_file
            local dest_file = out_dir .. "/" .. x_file
            local file_error = process_one_file(src_file, dest_file, do_change_filename)
            if file_error ~= "" then
                table.insert(error_list, file_error)
            end
        end
    end
    if #error_list > 0 then
        alert_error(error_list)
    end
end

function do_open_dialog(document)
    local path_name = finale.FCString()
    local file_name = finale.FCString()
    local file_path = finale.FCString()
    if document then
        document:GetPath(file_path)
        file_path:SplitToPathAndFile(path_name, file_name)
    end
    local full_file_name = file_name.LuaString
    local extension = finale.FCString(file_name.LuaString)
    extension:ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("." .. extension.LuaString))
    end
    file_name:AppendLuaString(xml_extension)
    local open_dialog = finale.FCFileOpenDialog(finenv.UI())
    open_dialog:SetWindowTitle(finale.FCString("Open MusicXML for " .. full_file_name))
    open_dialog:AddFilter(finale.FCString("*" .. xml_extension), finale.FCString("MusicXML File"))
    open_dialog:SetInitFolder(path_name)
    open_dialog:SetFileName(file_name)
    open_dialog:AssureFileExtension(xml_extension)
    if not open_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    open_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end

function music_xml_massage_export()
    local ok, full_directory = choose_extraction_method()
    if not ok then return end -- user cancelled

    if full_directory then
        do_open_directory()
    else -- only one file
        local documents = finale.FCDocuments()
        documents:LoadAll()
        local document = documents:FindCurrent()
        local xml_file = do_open_dialog(document)
        if xml_file then
            local file_error = process_one_file(xml_file, xml_file, true)
            if file_error ~= "" then
                alert_error{file_error}
            end
        end
    end
end

music_xml_massage_export()
