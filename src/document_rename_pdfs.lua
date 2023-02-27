function plugindef()
    finaleplugin.RequireScore = false
    finaleplugin.RequireSelection = false
    finaleplugin.RequireDocument = true
    finaleplugin.Author = "Aaron Sherber"
    finaleplugin.AuthorURL = "https://aaron.sherber.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.0.1"
    finaleplugin.Date = "2023-02-26"
    finaleplugin.Id = "d9282b18-12ed-488a-b0e2-011a1ba7d5b4" 
    finaleplugin.RevisionNotes = [[
        v1.0.1      First public release
    ]]
    finaleplugin.Notes = [[
        The main goal of this script is to emulate the tokens that Sibelius allows when exporting PDFs.
        Using this script, you can change the names of your PDFs, after they have been created,
        to include any combination of the score filename, score title, part name, part number, 
        total number of parts, current date, and current time.

        A simple use of the script would be to prepend the part number so that your PDFs can be sorted in 
        score order.

        The script will also fix filename artifacts that result from certain Finale versions and
        PDF drivers – for example, an extra "x" after the score filename or a truncated filename
        if the part names contains a "/".

        The script assumes that PDFs currently have the default names assigned by Finale – generally,
        "[score filename] - [part name].pdf".
    ]]

    return "Rename PDFs...", "", "Renames all PDFs for the current document"
end


local mixin = require("library.mixin")
local configuration = require("library.configuration")

local config = {
    last_template = "%n %t - %p.pdf"
}
local script_name = "document_rename_pdfs"
configuration.get_user_settings(script_name, config)

local function get_current_path_file_and_extension()
    local documents = finale.FCDocuments()
    documents:LoadAll()
    local doc = documents:FindCurrent()

    local file_name = mixin.FCMString()
    local path_name = mixin.FCMString()
    local file_path = mixin.FCMString()

    doc:GetPath(file_path)
    file_path:SplitToPathAndFile(path_name, file_name)
    local extension = mixin.FCMString()
                            :SetString(file_name)
                            :ExtractFileExtension()
    if extension.Length > 0 then
        file_name:TruncateAt(file_name:FindLast("." .. extension.LuaString))
    end

    return path_name.LuaString, file_name.LuaString, extension.LuaString
end

local fcmstr = function(str)
    return mixin.FCMString():SetLuaString(str)
end

local function browse_for_path(path_name, file_name)
    local result = nil
    local dlg = mixin.FCMFolderBrowseDialog(finenv.UI())
        :SetFolderPath(fcmstr(path_name))
        :SetUseFinaleAPI(false)
        :SetWindowTitle(fcmstr("Select Folder for " .. file_name .. " PDFs"))

    if dlg:Execute() then
        local str = mixin.FCMString()
        dlg:GetFolderPath(str)
        result = str:AssureEndingPathDelimiter().LuaString
    end
    
    return result
end

local function get_template(file_name)
    local dialog_title = "Rename " .. file_name .. " PDFs"
    local dialog = mixin.FCMCustomWindow()
        :SetTitle(dialog_title)

    local max_width      = math.max(#dialog_title, 42) * 6
    local first_label_y  = 53      -- "You can include"
    local label_y_offset = 17      -- line spacing
    local placeholder_x  = 12      -- "%f"
    local description_x  = 36      -- "Score filename"

    dialog:CreateStatic(0, 0)
        :SetText("New filename template")
        :SetWidth(max_width)
    dialog:CreateEdit(0, label_y_offset, "template")
        :SetText(config.last_template)
        :SetWidth(max_width)
    dialog:CreateHorizontalLine(0, 44, max_width)
    dialog:CreateStatic(0, first_label_y)
        :SetText("You can include the following placeholders:")
        :SetWidth(max_width)

    local counter = 2
    local function add_placeholder_and_description(ph, desc)
        local y = first_label_y + (counter * label_y_offset) - 12
        dialog:CreateStatic(placeholder_x, y):SetText(ph):SetWidth(16)
        dialog:CreateStatic(description_x, y):SetText(desc):SetWidth(#desc * 6)
        counter = counter + 1
    end

    add_placeholder_and_description("%f", "Score filename")
    add_placeholder_and_description("%t", "Score title")
    add_placeholder_and_description("%p", "Part name")
    add_placeholder_and_description("%n", "Part number")
    add_placeholder_and_description("%o", "Total number of parts")
    add_placeholder_and_description("%d", "Date (format YYYY-MM-DD)")
    add_placeholder_and_description("%h", "Time (format HHNN)")

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    if dialog:ExecuteModal() == finale.EXECMODAL_OK then
        local template = dialog:GetControl("template"):GetText()
        if not template:find("%.pdf$") then
            template = template .. ".pdf"
        end
        config.last_template = template
        configuration.save_user_settings(script_name, config)
        return template
    end 
end

local function rename_one_pdf(path, old_name, template, template_data)
    for k, v in pairs(template_data) do
        template = template:gsub("%%" .. k, v)
    end

    return os.rename(
        path .. old_name .. ".pdf", 
        path .. template
    )
end

local function rename_all_pdfs()
    local path_name, file_name = get_current_path_file_and_extension()
    path_name = browse_for_path(path_name, file_name)
    if not path_name then return end

    local template = get_template(file_name)
    if not template then return end

    local template_data = {
        f = file_name,
        d = os.date("%Y-%m-%d"),
        h = os.date("%H%M")
    }
 
    local str = finale.FCString()
    local file_info = finale.FCFileInfoText()
    file_info:LoadTitle(str)
    file_info:GetText(str)
    template_data.t = str.LuaString

    local parts = finale.FCParts()
    parts:LoadAll()
    template_data.o = string.format("%.2d", parts:GetCount())
    
    for part in each(parts) do
        part:GetName(str)
        local part_name = str.LuaString
        template_data.n = string.format("%.2d", part.OrderID)
        
        if part:IsScore() then
            template_data.p = part_name
            rename_one_pdf(path_name, file_name, template, template_data)
        else
            local escaped_name = part_name:gsub("/", "_")
            local truncated_name = part_name:gsub("^.*/", "")
            template_data.p = escaped_name
            
            local possible_names = {
                -- normal
                string.format("%s - %s", file_name, escaped_name),
                -- "x" added to filename
                string.format("%sx - %s", file_name, escaped_name),
                -- "Filename - Flute/Piccolo" truncated to "Piccolo"      
                truncated_name,         
            }

            for _, possible_name in pairs(possible_names) do
                if rename_one_pdf(path_name, possible_name, template, template_data) then
                    break
                end
            end
        end   
    end
end


rename_all_pdfs()