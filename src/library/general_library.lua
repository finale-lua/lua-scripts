--[[
$module Library
]] --
local library = {}

local client = require("library.client")

--[[
% group_overlaps_region

Returns true if the input staff group overlaps with the input music region, otherwise false.

@ staff_group (FCGroup)
@ region (FCMusicRegion)
: (boolean)
]]
function library.group_overlaps_region(staff_group, region)
    if region:IsFullDocumentSpan() then
        return true
    end
    local staff_exists = false
    local sys_staves = finale.FCSystemStaves()
    sys_staves:LoadAllForRegion(region)
    for sys_staff in each(sys_staves) do
        if staff_group:ContainsStaff(sys_staff:GetStaff()) then
            staff_exists = true
            break
        end
    end
    if not staff_exists then
        return false
    end
    if (staff_group.StartMeasure > region.EndMeasure) or (staff_group.EndMeasure < region.StartMeasure) then
        return false
    end
    return true
end

--[[
% group_is_contained_in_region

Returns true if the entire input staff group is contained within the input music region.
If the start or end staff are not visible in the region, it returns false.

@ staff_group (FCGroup)
@ region (FCMusicRegion)
: (boolean)
]]
function library.group_is_contained_in_region(staff_group, region)
    if not region:IsStaffIncluded(staff_group.StartStaff) then
        return false
    end
    if not region:IsStaffIncluded(staff_group.EndStaff) then
        return false
    end
    return true
end

--[[
% staff_group_is_multistaff_instrument

Returns true if the entire input staff group is a multistaff instrument.

@ staff_group (FCGroup)
: (boolean)
]]
function library.staff_group_is_multistaff_instrument(staff_group)
    local multistaff_instruments = finale.FCMultiStaffInstruments()
    multistaff_instruments:LoadAll()
    for inst in each(multistaff_instruments) do
        if inst:ContainsStaff(staff_group.StartStaff) and (inst.GroupID == staff_group:GetItemID()) then
            return true
        end
    end
    return false
end

--[[
% get_selected_region_or_whole_doc

Returns a region that contains the selected region if there is a selection or the whole document if there isn't.
SIDE-EFFECT WARNING: If there is no selected region, this function also changes finenv.Region() to the whole document.

: (FCMusicRegion)
]]
function library.get_selected_region_or_whole_doc()
    local sel_region = finenv.Region()
    if sel_region:IsEmpty() then
        sel_region:SetFullDocument()
    end
    return sel_region
end

--[[
% get_first_cell_on_or_after_page

Returns the first FCCell at the top of the input page. If the page is blank, it returns the first cell after the input page.

@ page_num (number)
: (FCCell)
]]
function library.get_first_cell_on_or_after_page(page_num)
    local curr_page_num = page_num
    local curr_page = finale.FCPage()
    local got1 = false
    -- skip over any blank pages
    while curr_page:Load(curr_page_num) do
        if curr_page:GetFirstSystem() > 0 then
            got1 = true
            break
        end
        curr_page_num = curr_page_num + 1
    end
    if got1 then
        local staff_sys = finale.FCStaffSystem()
        staff_sys:Load(curr_page:GetFirstSystem())
        return finale.FCCell(staff_sys.FirstMeasure, staff_sys.TopStaff)
    end
    -- if we got here there were nothing but blank pages left at the end
    local end_region = finale.FCMusicRegion()
    end_region:SetFullDocument()
    return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
end

--[[
% get_top_left_visible_cell

Returns the topmost, leftmost visible FCCell on the screen, or the closest possible estimate of it.

: (FCCell)
]]
function library.get_top_left_visible_cell()
    if not finenv.UI():IsPageView() then
        local all_region = finale.FCMusicRegion()
        all_region:SetFullDocument()
        return finale.FCCell(finenv.UI():GetCurrentMeasure(), all_region.StartStaff)
    end
    return library.get_first_cell_on_or_after_page(finenv.UI():GetCurrentPage())
end

--[[
% get_top_left_selected_or_visible_cell

If there is a selection, returns the topmost, leftmost cell in the selected region.
Otherwise returns the best estimate for the topmost, leftmost currently visible cell.

: (FCCell)
]]
function library.get_top_left_selected_or_visible_cell()
    local sel_region = finenv.Region()
    if not sel_region:IsEmpty() then
        return finale.FCCell(sel_region.StartMeasure, sel_region.StartStaff)
    end
    return library.get_top_left_visible_cell()
end

--[[
% is_default_measure_number_visible_on_cell

Returns true if measure numbers for the input region are visible on the input cell for the staff system.

@ meas_num_region (FCMeasureNumberRegion)
@ cell (FCCell)
@ staff_system (FCStaffSystem)
@ current_is_part (boolean) true if the current view is a linked part, otherwise false
: (boolean)
]]
function library.is_default_measure_number_visible_on_cell(meas_num_region, cell, staff_system, current_is_part)
    local staff = finale.FCCurrentStaffSpec()
    if not staff:LoadForCell(cell, 0) then
        return false
    end
    if meas_num_region:GetShowOnTopStaff() and (cell.Staff == staff_system.TopStaff) then
        return true
    end
    if meas_num_region:GetShowOnBottomStaff() and (cell.Staff == staff_system:CalcBottomStaff()) then
        return true
    end
    if staff.ShowMeasureNumbers then
        return not meas_num_region:GetExcludeOtherStaves(current_is_part)
    end
    return false
end

--[[
% calc_parts_boolean_for_measure_number_region

Returns the correct boolean value to use when requesting information about a measure number region.

@ meas_num_region (FCMeasureNumberRegion)
@ [for_part] (boolean) true if requesting values for a linked part, otherwise false. If omitted, this value is calculated.
: (boolean) the value to pass to FCMeasureNumberRegion methods with a parts boolean
]]
function library.calc_parts_boolean_for_measure_number_region(meas_num_region, for_part)
    if meas_num_region.UseScoreInfoForParts then
        return false
    end
    if nil == for_part then
        return finenv.UI():IsPartView()
    end
    return for_part
end

--[[
% is_default_number_visible_and_left_aligned

Returns true if measure number for the input cell is visible and left-aligned.

@ meas_num_region (FCMeasureNumberRegion)
@ cell (FCCell)
@ system (FCStaffSystem)
@ current_is_part (boolean) true if the current view is a linked part, otherwise false
@ is_for_multimeasure_rest (boolean) true if the current cell starts a multimeasure rest
: (boolean)
]]
function library.is_default_number_visible_and_left_aligned(meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
    current_is_part = library.calc_parts_boolean_for_measure_number_region(meas_num_region, current_is_part)
    if is_for_multimeasure_rest and meas_num_region:GetShowOnMultiMeasureRests(current_is_part) then
        if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultiMeasureAlignment(current_is_part)) then
            return false
        end
    elseif (cell.Measure == system.FirstMeasure) then
        if not meas_num_region:GetShowOnSystemStart() then
            return false
        end
        if (finale.MNALIGN_LEFT ~= meas_num_region:GetStartAlignment(current_is_part)) then
            return false
        end
    else
        if not meas_num_region:GetShowMultiples(current_is_part) then
            return false
        end
        if (finale.MNALIGN_LEFT ~= meas_num_region:GetMultipleAlignment(current_is_part)) then
            return false
        end
    end
    return library.is_default_measure_number_visible_on_cell(meas_num_region, cell, system, current_is_part)
end

--[[
% update_layout

Updates the page layout.

@ [from_page] (number) page to update from, defaults to 1
@ [unfreeze_measures] (boolean) defaults to false
]]
function library.update_layout(from_page, unfreeze_measures)
    from_page = from_page or 1
    unfreeze_measures = unfreeze_measures or false
    local page = finale.FCPage()
    if page:Load(from_page) then
        page:UpdateLayout(unfreeze_measures)
    end
end

--[[
% get_current_part

Returns the currently selected part or score.

: (FCPart)
]]
function library.get_current_part()
    local part = finale.FCPart(finale.PARTID_CURRENT)
    part:Load(part.ID)
    return part
end

--[[
% get_score

Returns an `FCPart` instance that represents the score.

: (FCPart)
]]
function library.get_score()
    local part = finale.FCPart(finale.PARTID_SCORE)
    part:Load(part.ID)
    return part
end

--[[
% get_page_format_prefs

Returns the default page format prefs for score or parts based on which is currently selected.

: (FCPageFormatPrefs)
]]
function library.get_page_format_prefs()
    local current_part = library.get_current_part()
    local page_format_prefs = finale.FCPageFormatPrefs()
    local success = false
    if current_part:IsScore() then
        success = page_format_prefs:LoadScore()
    else
        success = page_format_prefs:LoadParts()
    end
    return page_format_prefs, success
end

local calc_smufl_directory = function(for_user)
    local is_on_windows = finenv.UI():IsOnWindows()
    local do_getenv = function(win_var, mac_var)
        if finenv.UI():IsOnWindows() then
            return win_var and os.getenv(win_var) or ""
        else
            return mac_var and os.getenv(mac_var) or ""
        end
    end
    local smufl_directory = for_user and do_getenv("LOCALAPPDATA", "HOME") or do_getenv("COMMONPROGRAMFILES")
    if not is_on_windows then
        smufl_directory = smufl_directory .. "/Library/Application Support"
    end
    smufl_directory = smufl_directory .. "/SMuFL/Fonts/"
    return smufl_directory
end

--[[
% get_smufl_font_list

Returns table of installed SMuFL font names by searching the directory that contains
the .json files for each font. The table is in the format:

```lua
<font-name> = "user" | "system"
```

: (table) an table with SMuFL font names as keys and values "user" or "system"
]]

function library.get_smufl_font_list()
    local font_names = {}
    local add_to_table = function(for_user)
        local smufl_directory = calc_smufl_directory(for_user)
        local get_dirs = function()
            if finenv.UI():IsOnWindows() then
                return io.popen("dir \"" .. smufl_directory .. "\" /b /ad")
            else
                return io.popen("ls \"" .. smufl_directory .. "\"")
            end
        end
        local is_font_available = function(dir)
            local fc_dir = finale.FCString()
            fc_dir.LuaString = dir
            return finenv.UI():IsFontAvailable(fc_dir)
        end
        for dir in get_dirs():lines() do
            if not dir:find("%.") then
                dir = dir:gsub(" Bold", "")
                dir = dir:gsub(" Italic", "")
                local fc_dir = finale.FCString()
                fc_dir.LuaString = dir
                if font_names[dir] or is_font_available(dir) then
                    font_names[dir] = for_user and "user" or "system"
                end
            end
        end
    end
    add_to_table(true)
    add_to_table(false)
    return font_names
end

--[[
% get_smufl_metadata_file

@ [font_info] (FCFontInfo) if non-nil, the font to search for; if nil, search for the Default Music Font
: (file handle|nil)
]]
function library.get_smufl_metadata_file(font_info)
    if not font_info then
        font_info = finale.FCFontInfo()
        font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    end

    local try_prefix = function(prefix, font_info)
        local file_path = prefix .. font_info.Name .. "/" .. font_info.Name .. ".json"
        return io.open(file_path, "r")
    end

    local user_file = try_prefix(calc_smufl_directory(true), font_info)
    if user_file then
        return user_file
    end

    return try_prefix(calc_smufl_directory(false), font_info)
end

--[[
% is_font_smufl_font

@ [font_info] (FCFontInfo) if non-nil, the font to check; if nil, check the Default Music Font
: (boolean)
]]
function library.is_font_smufl_font(font_info)
    if not font_info then
        font_info = finale.FCFontInfo()
        font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    end

    if client.supports("smufl") then
        if nil ~= font_info.IsSMuFLFont then -- if this version of the lua interpreter has the IsSMuFLFont property (i.e., RGP Lua 0.59+)
            return font_info.IsSMuFLFont
        end
    end

    local smufl_metadata_file = library.get_smufl_metadata_file(font_info)
    if nil ~= smufl_metadata_file then
        io.close(smufl_metadata_file)
        return true
    end
    return false
end

--[[
% simple_input

Creates a simple dialog box with a single 'edit' field for entering values into a script, similar to the old UserValueInput command. Will automatically resize the width to accomodate longer strings.

@ [title] (string) the title of the input dialog box
@ [text] (string) descriptive text above the edit field
: string
]]
function library.simple_input(title, text)
    local return_value = finale.FCString()
    return_value.LuaString = ""
    local str = finale.FCString()
    local min_width = 160
    --
    function format_ctrl(ctrl, h, w, st)
        ctrl:SetHeight(h)
        ctrl:SetWidth(w)
        str.LuaString = st
        ctrl:SetText(str)
    end -- function format_ctrl
    --
    title_width = string.len(title) * 6 + 54
    if title_width > min_width then
        min_width = title_width
    end
    text_width = string.len(text) * 6
    if text_width > min_width then
        min_width = text_width
    end
    --
    str.LuaString = title
    local dialog = finale.FCCustomLuaWindow()
    dialog:SetTitle(str)
    local descr = dialog:CreateStatic(0, 0)
    format_ctrl(descr, 16, min_width, text)
    local input = dialog:CreateEdit(0, 20)
    format_ctrl(input, 20, min_width, "") -- edit "" for defualt value
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    --
    function callback(ctrl)
    end -- callback
    --
    dialog:RegisterHandleCommand(callback)
    --
    if dialog:ExecuteModal(nil) == finale.EXECMODAL_OK then
        return_value.LuaString = input:GetText(return_value)
        -- print(return_value.LuaString)
        return return_value.LuaString
        -- OK button was pressed
    end
end -- function simple_input

--[[
% is_finale_object

Attempts to determine if an object is a Finale object through ducktyping

@ object (__FCBase)
: (bool)
]]
function library.is_finale_object(object)
    -- All finale objects implement __FCBase, so just check for the existence of __FCBase methods
    return object and type(object) == "userdata" and object.ClassName and object.GetClassID and true or false
end

--[[
% system_indent_set_to_prefs

Sets the system to match the indentation in the page preferences currently in effect. (For score or part.)
The page preferences may be provided optionally to avoid loading them for each call.

@ system (FCStaffSystem)
@ [page_format_prefs] (FCPageFormatPrefs) page format preferences to use, if supplied.
: (boolean) `true` if the system was successfully updated.
]]
function library.system_indent_set_to_prefs(system, page_format_prefs)
    page_format_prefs = page_format_prefs or library.get_page_format_prefs()
    local first_meas = finale.FCMeasure()
    local is_first_system = (system.FirstMeasure == 1)
    if (not is_first_system) and first_meas:Load(system.FirstMeasure) then
        if first_meas.ShowFullNames then
            is_first_system = true
        end
    end
    if is_first_system and page_format_prefs.UseFirstSystemMargins then
        system.LeftMargin = page_format_prefs.FirstSystemLeft
    else
        system.LeftMargin = page_format_prefs.SystemLeft
    end
    return system:Save()
end

--[[
% calc_script_name

Returns the running script name, with or without extension.

@ [include_extension] (boolean) Whether to include the file extension in the return value: `false` if omitted
: (string) The name of the current running script.
]]
function library.calc_script_name(include_extension)
    local fc_string = finale.FCString()
    if finenv.RunningLuaFilePath then
        -- Use finenv.RunningLuaFilePath() if available because it doesn't ever get overwritten when retaining state.
        fc_string.LuaString = finenv.RunningLuaFilePath()
    else
        -- This code path is only taken by JW Lua (and very early versions of RGP Lua).
        -- SetRunningLuaFilePath is not reliable when retaining state, so later versions use finenv.RunningLuaFilePath.
        fc_string:SetRunningLuaFilePath()
    end
    local filename_string = finale.FCString()
    fc_string:SplitToPathAndFile(nil, filename_string)
    local retval = filename_string.LuaString
    if not include_extension then
        retval = retval:match("(.+)%..+")
        if not retval or retval == "" then
            retval = filename_string.LuaString
        end
    end
    return retval
end

--[[
% get_default_music_font_name

Fetches the default music font from document options and processes the name into a usable format.

: (string) The name of the defalt music font.
]]
function library.get_default_music_font_name()
    local fontinfo = finale.FCFontInfo()
    local default_music_font_name = finale.FCString()
    if fontinfo:LoadFontPrefs(finale.FONTPREF_MUSIC) then
        fontinfo:GetNameString(default_music_font_name)
        return default_music_font_name.LuaString
    end
end

return library
