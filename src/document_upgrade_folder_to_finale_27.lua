function plugindef()
    finaleplugin.RequireDocument = false
    finaleplugin.RequireSelection = false
    finaleplugin.CategoryTags = "Document"
    finaleplugin.MinJWLuaVersion = 0.76
    finaleplugin.Version = "1.0.0"
    finaleplugin.Notes = [[
        Recursively upgrades every .mus or .musx file in a selected folder tree to Finale 27 .musx format.

        Upgraded files are written into a sibling subfolder named "-finale27" inside each source folder.
        That subfolder is skipped during traversal, so rerunning the script will not reprocess prior output.

        The script leaves source files unchanged. Existing upgraded files are overwritten on each run.
    ]]
    return "Upgrade Folder To Finale 27...", "Upgrade Folder To Finale 27",
        "Upgrade every .mus or .musx file in a folder tree to Finale 27 .musx copies"
end

local client = require("library.client")
local mixin = require("library.mixin")
local utils = require("library.utils")

local lfs = require("lfs")
local text = require("luaosutils").text

local OUTPUT_SUBFOLDER_NAME <const> = "-finale27"
local OUTPUT_EXTENSION <const> = ".musx"
local MUS_EXTENSION <const> = ".mus"
local MUSX_EXTENSION <const> = ".musx"
local TIMER_ID <const> = 1
local COPY_CHUNK_SIZE <const> = 65536
local PATH_DELIMITER <const> = finenv.UI():IsOnWindows() and "\\" or "/"
local LOGFILE_NAME <const> = "finale27-upgrade.log"

local function to_os_path(utf8_path)
    return client.encode_with_client_codepage(utf8_path)
end

local function get_file_attributes(path)
    return lfs.attributes(to_os_path(path))
end

local function select_directory()
    local default_folder_path = finale.FCString()
    default_folder_path:SetMusicFolderPath()
    local open_dialog = finale.FCFolderBrowseDialog(finenv.UI())
    open_dialog:SetWindowTitle(finale.FCString("Select folder containing Finale files"))
    open_dialog:SetFolderPath(default_folder_path)
    open_dialog:SetUseFinaleAPI(finenv.UI():IsOnMac())
    if not open_dialog:Execute() then
        return nil
    end
    local selected_folder = finale.FCString()
    open_dialog:GetFolderPath(selected_folder)
    selected_folder:AssureEndingPathDelimiter()
    return selected_folder.LuaString
end

local function format_raw_finale_version(raw_version)
    local major = bit32.rshift(raw_version, 24)
    local minor = bit32.band(bit32.rshift(raw_version, 20), 0x0f)
    return string.format("%d.%d", major, minor)
end

local function warn_if_not_finale_27_4()
    local target_version = client.get_raw_finale_version(27, 4)
    if finenv.RawFinaleVersion ~= target_version then
        finenv.UI():AlertInfo(
            "This script is intended to run in Finale 27.4. You may use it in this version (" ..
                format_raw_finale_version(finenv.RawFinaleVersion) ..
                "), but the .musx files will not be upgraded to the final Finale version.",
            "Finale Version Warning"
        )
    end
end

local function make_relative_path(root_folder, full_path)
    if full_path:sub(1, #root_folder) == root_folder then
        return full_path:sub(#root_folder + 1)
    end
    return full_path
end

local function quote_if_needed(path)
    if path:find("%s") then
        return "\"" .. path .. "\""
    end
    return path
end

local function append_to_log(logfile_path, message)
    local file <close> = io.open(to_os_path(logfile_path), "a")
    if not file then
        error("unable to append to logfile " .. logfile_path)
    end
    file:write(message .. "\n")
    file:close()
end

local function log_message(logfile_path, message, label)
    append_to_log(logfile_path, os.date("%Y-%m-%d %H:%M:%S") .. " " .. label .. " " .. message)
end

local function initialize_logfile(selected_directory)
    local logfile_path = selected_directory .. LOGFILE_NAME
    local file <close> = io.open(to_os_path(logfile_path), "w")
    if not file then
        error("unable to create logfile " .. logfile_path)
    end
    file:write("Finale 27 Upgrade Log\n")
    file:write("Started: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n")
    file:write("Root Folder: " .. selected_directory .. "\n")
    file:write("Running Finale Version: " .. format_raw_finale_version(finenv.RawFinaleVersion) .. "\n\n")
    file:close()
    return logfile_path
end

local function copy_file_binary(source_path, destination_path)
    local input, input_err = io.open(to_os_path(source_path), "rb")
    if not input then
        return false, "unable to open source file: " .. tostring(input_err)
    end

    local output, output_err = io.open(to_os_path(destination_path), "wb")
    if not output then
        input:close()
        return false, "unable to create temporary file: " .. tostring(output_err)
    end

    while true do
        local chunk = input:read(COPY_CHUNK_SIZE)
        if not chunk then
            break
        end
        local success, write_err = output:write(chunk)
        if not success then
            input:close()
            output:close()
            os.remove(to_os_path(destination_path))
            return false, "unable to write temporary file: " .. tostring(write_err)
        end
    end

    input:close()
    output:close()
    return true
end

local function assure_output_folder_exists(folder_path)
    local output_folder_path = folder_path .. OUTPUT_SUBFOLDER_NAME
    local attr = get_file_attributes(output_folder_path)
    if not attr then
        local success, err = lfs.mkdir(to_os_path(output_folder_path))
        if not success then
            return nil, "unable to create output folder: " .. tostring(err)
        end
    elseif attr.mode ~= "directory" then
        return nil, "output path exists but is not a directory"
    end
    return output_folder_path .. PATH_DELIMITER
end

local function make_temp_copy_path(output_folder_path, file_name, extension)
    local candidate = output_folder_path .. file_name .. ".rgplua-upgrade-temp" .. extension
    local index = 1
    while get_file_attributes(candidate) do
        candidate = output_folder_path .. file_name .. ".rgplua-upgrade-temp-" .. tostring(index) .. extension
        index = index + 1
    end
    return candidate
end

local function resolve_output_names(tasks)
    local grouped = {}
    for _, task in ipairs(tasks) do
        local key = task.folder .. "\0" .. task.file_name
        grouped[key] = grouped[key] or {}
        table.insert(grouped[key], task)
    end

    for _, group in pairs(grouped) do
        if #group == 1 then
            group[1].output_name = group[1].file_name .. OUTPUT_EXTENSION
        else
            for _, task in ipairs(group) do
                local suffix = (task.extension == MUS_EXTENSION) and ".from-mus" or ".from-musx"
                task.output_name = task.file_name .. suffix .. OUTPUT_EXTENSION
            end
        end
    end
end

local function collect_upgrade_tasks(root_folder)
    local tasks = {}
    local root_folder_os = text.convert_encoding(root_folder, text.get_utf8_codepage(), text.get_default_codepage())

    local function visit_directory(folder_utf8, folder_os)
        for lfs_file in lfs.dir(folder_os) do
            if lfs_file ~= "." and lfs_file ~= ".." and lfs_file:sub(1, 2) ~= "._" then
                local item_mode = lfs.attributes(folder_os .. lfs_file, "mode")
                local item_utf8 = text.convert_encoding(lfs_file, text.get_default_codepage(), text.get_utf8_codepage())
                if item_mode == "directory" then
                    if item_utf8 ~= OUTPUT_SUBFOLDER_NAME then
                        visit_directory(folder_utf8 .. item_utf8 .. PATH_DELIMITER, folder_os .. lfs_file .. PATH_DELIMITER)
                    end
                elseif item_mode == "file" or item_mode == "link" then
                    local _, file_name, extension = utils.split_file_path(item_utf8)
                    local normalized_extension = extension and extension:lower() or ""
                    if normalized_extension == MUS_EXTENSION or normalized_extension == MUSX_EXTENSION then
                        table.insert(tasks, {
                            folder = folder_utf8,
                            file_name = file_name,
                            extension = normalized_extension,
                            source_name = item_utf8,
                            source_path = folder_utf8 .. item_utf8,
                        })
                    end
                end
            end
        end
    end

    visit_directory(root_folder, root_folder_os)
    table.sort(tasks, function(left, right)
        if left.folder == right.folder then
            if left.file_name == right.file_name then
                return left.extension < right.extension
            end
            return left.file_name < right.file_name
        end
        return left.folder < right.folder
    end)
    resolve_output_names(tasks)
    return tasks
end

local function close_batch_document(document, state)
    if finenv.UI():IsOnWindows() and not state.first_document then
        state.first_document = document
    else
        document.Dirty = false
        document:CloseCurrentDocumentAndWindow(false)
    end
    document:SwitchBack()
end

local function release_first_document(state)
    if state.first_document then
        state.first_document.Dirty = false
        state.first_document:CloseCurrentDocumentAndWindow(false)
        state.first_document:SwitchBack()
        state.first_document = nil
    end
end

local function upgrade_document(task, state)
    local output_folder_path, folder_err = assure_output_folder_exists(task.folder)
    if not output_folder_path then
        return false, folder_err
    end

    local output_path = output_folder_path .. task.output_name
    local temp_copy_path = make_temp_copy_path(output_folder_path, task.file_name, task.extension)
    local copy_success, copy_err = copy_file_binary(task.source_path, temp_copy_path)
    if not copy_success then
        return false, copy_err
    end

    local document = finale.FCDocument()
    local opened = document:Open(finale.FCString(temp_copy_path), true, nil, true, false, true)
    if not opened then
        os.remove(to_os_path(temp_copy_path))
        return false, "unable to open temporary copy in Finale"
    end

    local saved = document:Save(finale.FCString(output_path))
    close_batch_document(document, state)
    os.remove(to_os_path(temp_copy_path))

    if not saved then
        return false, "unable to save upgraded document"
    end
    return true, output_path
end

local function build_summary_text(state)
    return string.format(
        "Done. Upgraded: %d  Failed: %d",
        state.upgraded_count,
        state.failed_count
    )
end

local function run_status_dialog(selected_directory, tasks, logfile_path)
    local state = {
        upgraded_count = 0,
        failed_count = 0,
        first_document = nil,
        canceled = false,
        logfile_path = logfile_path,
    }

    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle("Upgrade Folder To Finale 27")

    local current_y = 0
    dialog:CreateStatic(0, current_y + 2, "folder_label")
        :SetText("Folder:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "folder")
        :SetText("")
        :SetWidth(420)
        :AssureNoHorizontalOverlap(dialog:GetControl("folder_label"), 5)
        :StretchToAlignWithRight()

    current_y = current_y + 20
    dialog:CreateStatic(0, current_y + 2, "file_label")
        :SetText("File:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "file")
        :SetText("")
        :SetWidth(420)
        :AssureNoHorizontalOverlap(dialog:GetControl("file_label"), 5)
        :HorizontallyAlignLeftWith(dialog:GetControl("folder"))
        :StretchToAlignWithRight()

    current_y = current_y + 20
    dialog:CreateStatic(0, current_y + 2, "status_label")
        :SetText("Status:")
        :DoAutoResizeWidth(0)
    dialog:CreateStatic(0, current_y + 2, "status")
        :SetText("Preparing...")
        :SetWidth(420)
        :AssureNoHorizontalOverlap(dialog:GetControl("status_label"), 5)
        :HorizontallyAlignLeftWith(dialog:GetControl("folder"))
        :StretchToAlignWithRight()

    dialog:CreateCancelButton("cancel")

    dialog:RegisterInitWindow(function(self)
        self:SetTimer(TIMER_ID, 100)
    end)

    dialog:RegisterHandleTimer(function(self, timer)
        assert(timer == TIMER_ID, "incorrect timer id value " .. timer)

        if #tasks == 0 then
            self:StopTimer(TIMER_ID)
            release_first_document(state)
            log_message(state.logfile_path, build_summary_text(state), "Info")
            self:GetControl("folder"):SetText(selected_directory)
            self:GetControl("file"):SetText(state.canceled and "(canceled)" or "(complete)")
            self:GetControl("status"):SetText(build_summary_text(state))
            self:GetControl("cancel"):SetText("Close")
            return
        end

        local task = tasks[1]
        self:GetControl("folder"):SetText("..." .. task.folder:sub(#selected_directory + 1))
            :RedrawImmediate()
        self:GetControl("file"):SetText(task.source_name)
            :RedrawImmediate()

        local success, result = upgrade_document(task, state)
        local relative_source_path = quote_if_needed(make_relative_path(selected_directory, task.source_path))
        if success == true then
            state.upgraded_count = state.upgraded_count + 1
            log_message(
                state.logfile_path,
                relative_source_path .. " -> " .. quote_if_needed(make_relative_path(selected_directory, result)),
                "SUCCESS"
            )
            self:GetControl("status"):SetText("Upgraded to " .. task.output_name)
        else
            state.failed_count = state.failed_count + 1
            self:GetControl("status"):SetText("Failed: " .. result)
            log_message(state.logfile_path, relative_source_path .. " -> " .. tostring(result), "ERROR")
        end
        self:GetControl("status"):RedrawImmediate()

        table.remove(tasks, 1)
    end)

    dialog:RegisterCloseWindow(function(self)
        self:StopTimer(TIMER_ID)
        if #tasks > 0 then
            state.canceled = true
            log_message(state.logfile_path, "Batch upgrade canceled by user.", "Info")
        end
        release_first_document(state)
        finenv.RetainLuaState = false
    end)

    dialog:RunModeless()
end

local function verify_no_open_documents()
    local documents = finale.FCDocuments()
    return documents:LoadAll() == 0
end

local function upgrade_folder_to_finale_27()
    warn_if_not_finale_27_4()

    if not verify_no_open_documents() then
        finenv.UI():AlertInfo("Run this plugin with no documents open.", "")
        return
    end

    local selected_directory = select_directory()
    if not selected_directory then
        return
    end

    local logfile_path = initialize_logfile(selected_directory)
    local tasks = collect_upgrade_tasks(selected_directory)
    if #tasks == 0 then
        log_message(logfile_path, "No Finale .mus or .musx files found.", "Info")
        finenv.UI():AlertInfo("No Finale .mus or .musx files found in " .. selected_directory, "Nothing To Process")
        return
    end

    log_message(logfile_path, "Queued " .. tostring(#tasks) .. " Finale files for upgrade.", "Info")
    run_status_dialog(selected_directory, tasks, logfile_path)
end

upgrade_folder_to_finale_27()
