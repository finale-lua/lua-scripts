function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.NoStore = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "September 25, 2024"
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.74
    finaleplugin.Notes = [[
        Exports settings from the current document into a MuseScore `.mss` style file.
        Only a subset of possible MuseScore settings are exported. You can choose either to modify
        an existing file or create a new one with only the exported settings.
    ]]
    return "Export Settings to MuseScore...", "Export Settings to MuseScore", "Export document options from the current document to a MuseScore style file."
end

-- luacheck: ignore 11./global_dialog

local mixin = require("library.mixin")

local text_extension = ".mss"

function set_element_text(style_element, name, value, setter_func)
    local element = style_element:FirstChildElement(name)
    if not element then
        element = style_element:InsertNewChildElement(name)
    end
    element[setter_func](element, value)
end

function write_xml()
    local mssxml <close> = tinyxml2.XMLDocument()
    local existing_path = global_dialog:GetControl("file_path"):GetText()
    if #existing_path > 0 then
        local result = mssxml:LoadFile(existing_path)
        if result ~= tinyxml2.XML_SUCCESS then
            error("Unable to parse " .. existing_path .. ". " .. mssxml:ErrorStr())
            return
        end
    else
        mssxml:InsertEndChild(mssxml:NewDeclaration(nil))
        local ms_element = mssxml:NewElement("museScore")
        ms_element:SetAttribute("version", "4.40")
        mssxml:InsertEndChild(ms_element)
        ms_element:InsertNewChildElement("Style")
    end
    local style_element = tinyxml2.XMLHandle(mssxml):FirstChildElement("museScore"):FirstChildElement("Style"):ToElement()
    if not style_element then
        error(existing_path .. " is not a valid .mss file.")
    end
    set_element_text(style_element, "pageWidth", 8.5, "SetDoubleText")
    set_element_text(style_element, "pageHeight", 11, "SetDoubleText")
    local output_path = "/Users/robertpatterson/Desktop/xxx.mss"
    if mssxml:SaveFile(output_path) ~= tinyxml2.XML_SUCCESS then
        error("Unable to save " .. existing_path .. ". " .. mssxml:ErrorStr())
    end
end

function select_existing_target()
    local path_name = finale.FCString()
    local file_name = finale.FCString()
    local file_path = finale.FCString()
    global_dialog:GetControl("file_path"):GetText(file_path)
    if file_path.Length <= 0 then
        local documents = finale.FCDocuments()
        documents:LoadAll()
        local document = documents:FindCurrent()
            if document then
            document:GetPath(file_path)
        end
    end
    file_path:SplitToPathAndFile(path_name, file_name)
    local full_file_name = file_name.LuaString
    local extension = finale.FCString(file_name.LuaString)
    extension:ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("." .. extension.LuaString))
    end
    file_name:AppendLuaString(text_extension)
    local open_dialog = finale.FCFileOpenDialog(finenv.UI())
    open_dialog:SetWindowTitle(finale.FCString("Open MusicXML for " .. full_file_name))
    open_dialog:AddFilter(finale.FCString("*" .. text_extension), finale.FCString("MusicXML File"))
    open_dialog:SetInitFolder(path_name)
    open_dialog:SetFileName(file_name)
    open_dialog:AssureFileExtension(text_extension)
    if not open_dialog:Execute() then
        return nil
    end
    local selected_file_name = finale.FCString()
    open_dialog:GetFileName(selected_file_name)
    return selected_file_name.LuaString
end

function create_dialog_box()
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle("Export Settings to MuseScore")
    local current_y = 0
    -- file to process
    dialog:CreateStatic(0, current_y + 2, "file_path_label")
        :SetText("Use Existing:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "file_path")
        :SetText("")
        :SetWidth(400)
        :AssureNoHorizontalOverlap(dialog:GetControl("file_path_label"), 5)
    dialog:CreateButton(0, current_y, "choose_file")
        :SetText("Select...")
        :DoAutoResizeWidth(0)
        :AssureNoHorizontalOverlap(dialog:GetControl("file_path"), 5)
        :AddHandleCommand(function(_control)
            local filepath = select_existing_target()
            if filepath then
                dialog:GetControl("file_path"):SetText(filepath)
            end
        end)
    -- ok/cancel
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    -- registrations
    dialog:RegisterHandleOkButtonPressed(function(_self)
        write_xml()
    end)
    dialog:RegisterInitWindow(function(self)
        self:GetControl("file_path"):SetText("")
    end)
    return dialog
end

function document_options_to_musescore()
    global_dialog = global_dialog or create_dialog_box()
    global_dialog:RunModeless()
end

document_options_to_musescore()
