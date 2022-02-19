function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "CJ Garcia"
    finaleplugin.Copyright = "© 2021 CJ Garcia Music"
    finaleplugin.Version = "1.2"
    finaleplugin.Date = "2/29/2021"
    return "Hairpin and Dynamic Adjustments", "Hairpin and Dynamic Adjustments", "Adjusts hairpins to remove collisions with dynamics and aligns hairpins with dynamics."
end

--[[
$module Expression
]]
local expression = {}

--[[
$module Library
]]
local library = {}

--[[
% finale_version(major, minor, build)

Returns a raw Finale version from major, minor, and (optional) build parameters. For 32-bit Finale
this is the internal major Finale version, not the year.

@ major (number) Major Finale version
@ minor (number) Minor Finale version
@ [build] (number) zero if omitted
: (number)
]]
function library.finale_version(major, minor, build)
    local retval = bit32.bor(bit32.lshift(math.floor(major), 24), bit32.lshift(math.floor(minor), 20))
    if build then
        retval = bit32.bor(retval, math.floor(build))
    end
    return retval
end

--[[
% group_overlaps_region(staff_group, region)

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
% group_is_contained_in_region(staff_group, region)

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
% staff_group_is_multistaff_instrument(staff_group)

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
% get_selected_region_or_whole_doc()

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
% get_first_cell_on_or_after_page(page_num)

Returns the first FCCell at the top of the input page. If the page is blank, it returns the first cell after the input page.

@ page_num (number)
: (FCCell)
]]
function library.get_first_cell_on_or_after_page(page_num)
    local curr_page_num = page_num
    local curr_page = finale.FCPage()
    local got1 = false
    --skip over any blank pages
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
    --if we got here there were nothing but blank pages left at the end
    local end_region = finale.FCMusicRegion()
    end_region:SetFullDocument()
    return finale.FCCell(end_region.EndMeasure, end_region.EndStaff)
end

--[[
% get_top_left_visible_cell()

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
% get_top_left_selected_or_visible_cell()

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
% is_default_measure_number_visible_on_cell (meas_num_region, cell, staff_system, current_is_part)

Returns true if measure numbers for the input region are visible on the input cell for the staff system.

@ meas_num_region (FCMeasureNumberRegion)
@ cell (FCCell)
@ staff_system (FCStaffSystem)
@ current_is_part (boolean) true if the current view is a linked part, otherwise false
: (boolean)
]]
function library.is_default_measure_number_visible_on_cell (meas_num_region, cell, staff_system, current_is_part)
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
% is_default_number_visible_and_left_aligned (meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)

Returns true if measure number for the input cell is visible and left-aligned.

@ meas_num_region (FCMeasureNumberRegion)
@ cell (FCCell)
@ system (FCStaffSystem)
@ current_is_part (boolean) true if the current view is a linked part, otherwise false
@ is_for_multimeasure_rest (boolean) true if the current cell starts a multimeasure rest
: (boolean)
]]
function library.is_default_number_visible_and_left_aligned (meas_num_region, cell, system, current_is_part, is_for_multimeasure_rest)
    if meas_num_region.UseScoreInfoForParts then
        current_is_part = false
    end
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
    return library.is_default_measure_number_visible_on_cell (meas_num_region, cell, system, current_is_part)
end

--[[
% update_layout(from_page, unfreeze_measures)

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
% get_current_part()

Returns the currently selected part or score.

: (FCPart)
]]
function library.get_current_part()
    local parts = finale.FCParts()
    parts:LoadAll()
    return parts:GetCurrent()
end

--[[
% get_page_format_prefs()

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

--[[
% get_smufl_metadata_file(font_info)

@ [font_info] (FCFontInfo) if non-nil, the font to search for; if nil, search for the Default Music Font
: (file handle|nil)
]]
function library.get_smufl_metadata_file(font_info)
    if nil == font_info then
        font_info = finale.FCFontInfo()
        font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    end

    local try_prefix = function(prefix, font_info)
        local file_path = prefix .. "/SMuFL/Fonts/" .. font_info.Name .. "/" .. font_info.Name .. ".json"
        return io.open(file_path, "r")
    end

    local smufl_json_user_prefix = ""
    if finenv.UI():IsOnWindows() then
        smufl_json_user_prefix = os.getenv("LOCALAPPDATA")
    else
        smufl_json_user_prefix = os.getenv("HOME") .. "/Library/Application Support"
    end
    local user_file = try_prefix(smufl_json_user_prefix, font_info)
    if nil ~= user_file then
        return user_file
    end

    local smufl_json_system_prefix = "/Library/Application Support"
    if finenv.UI():IsOnWindows() then
        smufl_json_system_prefix = os.getenv("COMMONPROGRAMFILES") 
    end
    return try_prefix(smufl_json_system_prefix, font_info)
end

--[[
% is_font_smufl_font(font_info)

@ [font_info] (FCFontInfo) if non-nil, the font to check; if nil, check the Default Music Font
: (boolean)
]]
function library.is_font_smufl_font(font_info)
    if nil == font_info then
        font_info = finale.FCFontInfo()
        font_info:LoadFontPrefs(finale.FONTPREF_MUSIC)
    end
    
    if finenv.RawFinaleVersion >= library.finale_version(27, 1) then
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
% simple_input(title, text)

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
  if title_width > min_width then min_width = title_width end
  text_width = string.len(text) * 6
  if text_width > min_width then min_width = text_width end
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
    --print(return_value.LuaString)
    return return_value.LuaString
  -- OK button was pressed
  end
end -- function simple_input







--[[
$module Note Entry
]]
local note_entry = {}

--[[
% get_music_region(entry)

Returns an intance of `FCMusicRegion` that corresponds to the metric location of the input note entry.

@ entry (FCNoteEntry)
: (FCMusicRegion)
]]
function note_entry.get_music_region(entry)
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection() -- called to match the selected IU list (e.g., if using Staff Sets)
    exp_region.StartStaff = entry.Staff
    exp_region.EndStaff = entry.Staff
    exp_region.StartMeasure = entry.Measure
    exp_region.EndMeasure = entry.Measure
    exp_region.StartMeasurePos = entry.MeasurePos
    exp_region.EndMeasurePos = entry.MeasurePos
    return exp_region
end

--entry_metrics can be omitted, in which case they are constructed and released here
--return entry_metrics, loaded_here
local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
    if nil ~= entry_metrics then
        return entry_metrics, false
    end
    entry_metrics = finale.FCEntryMetrics()
    if entry_metrics:Load(entry) then
        return entry_metrics, true
    end
    return nil, false
end

--[[
% get_evpu_notehead_height(entry)

Returns the calculated height of the notehead rectangle.

@ entry (FCNoteEntry)

: (number) the EVPU height
]]
function note_entry.get_evpu_notehead_height(entry)
    local highest_note = entry:CalcHighestNote(nil)
    local lowest_note = entry:CalcLowestNote(nil)
    local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12 -- 12 evpu per staff step; add 2 staff steps to accommodate for notehead height at top and bottom
    return evpu_height
end

--[[
% get_top_note_position(entry, entry_metrics)

Returns the vertical page coordinate of the top of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_top_note_position(entry, entry_metrics)
    local retval = -math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if not entry:CalcStemUp() then
        retval = entry_metrics.TopPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling*evpu_height)/10000) + 0.5)
            retval = entry_metrics.BottomPosition + scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% get_bottom_note_position(entry, entry_metrics)

Returns the vertical page coordinate of the bottom of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_bottom_note_position(entry, entry_metrics)
    local retval = math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if entry:CalcStemUp() then
        retval = entry_metrics.BottomPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling*evpu_height)/10000) + 0.5)
            retval = entry_metrics.TopPosition - scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% calc_widths(entry)

Get the widest left-side notehead width and widest right-side notehead width.

@ entry (FCNoteEntry)
: (number, number) widest left-side notehead width and widest right-side notehead width
]]
function note_entry.calc_widths(entry)
    local left_width = 0
    local right_width = 0
    for note in each(entry) do
        local note_width = note:CalcNoteheadWidth()
        if note_width > 0 then
            if note:CalcRightsidePlacement() then
                if note_width > right_width then
                    right_width = note_width
                end
            else
                if note_width > left_width then
                    left_width = note_width
                end
            end
        end
    end
    return left_width, right_width
end

-- These functions return the offset for an expression handle.
-- Expression handles are vertical when they are left-aligned
-- with the primary notehead rectangle.

--[[
% calc_left_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Left of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_all_noteheads(entry)
    if entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return -left
end

--[[
% calc_left_of_primary_notehead(entry)

Calculates the handle offset for an expression with "Left of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_primary_notehead(entry)
    return 0
end

--[[
% calc_center_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Center of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    local width_centered = (left + right) / 2
    if not entry:CalcStemUp() then
        width_centered = width_centered - left
    end
    return width_centered
end

--[[
% calc_center_of_primary_notehead(entry)

Calculates the handle offset for an expression with "Center of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_primary_notehead(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left / 2
    end
    return right / 2
end

--[[
% calc_stem_offset(entry)

Calculates the offset of the stem from the left edge of the notehead rectangle. Eventually the PDK Framework may be able to provide this instead.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset of stem from the left edge of the notehead rectangle.
]]
function note_entry.calc_stem_offset(entry)
    if not entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return left
end

--[[
% calc_right_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Right of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_right_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left + right
    end
    return right
end

--[[
% calc_note_at_index(entry, note_index)

This function assumes `for note in each(note_entry)` always iterates in the same direction.
(Knowing how the Finale PDK works, it probably iterates from bottom to top note.)
Currently the PDK Framework does not seem to offer a better option.

@ entry (FCNoteEntry)
@ note_index (number) the zero-based index
]]
function note_entry.calc_note_at_index(entry, note_index)
    local x = 0
    for note in each(entry) do
        if x == note_index then
            return note
        end
        x = x + 1
    end
    return nil
end

--[[
% stem_sign(entry)

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

@ entry (FCNoteEntry)
: (number) 1 if upstem, -1 otherwise
]]
function note_entry.stem_sign(entry)
    if entry:CalcStemUp() then
        return 1
    end
    return -1
end

--[[
% duplicate_note(note)

@ note (FCNote)
: (FCNote | nil) reference to added FCNote or `nil` if not success
]]
function note_entry.duplicate_note(note)
    local new_note = note.Entry:AddNewNote()
    if nil ~= new_note then
        new_note.Displacement = note.Displacement
        new_note.RaiseLower = note.RaiseLower
        new_note.Tie = note.Tie
        new_note.TieBackwards = note.TieBackwards
    end
    return new_note
end

--[[
% delete_note(note)

Removes the specified FCNote from its associated FCNoteEntry.

@ note (FCNote)
: (boolean) true if success
]]
function note_entry.delete_note(note)
    local entry = note.Entry
    if nil == entry then
        return false
    end

    -- attempt to delete all associated entry-detail mods, but ignore any failures
    finale.FCAccidentalMod():EraseAt(note)
    finale.FCCrossStaffMod():EraseAt(note)
    finale.FCDotMod():EraseAt(note)
    finale.FCNoteheadMod():EraseAt(note)
    finale.FCPercussionNoteMod():EraseAt(note)
    finale.FCTablatureNoteMod():EraseAt(note)
    --finale.FCTieMod():EraseAt(note)  -- FCTieMod is not currently lua supported, but leave this here in case it ever is

    return entry:DeleteNote(note)
end

--[[
% calc_spans_number_of_octaves(entry)

Calculates the numer of octaves spanned by a chord (considering only staff positions, not accidentals).

@ entry (FCNoteEntry) the entry to calculate from
: (number) of octaves spanned
]]
function note_entry.calc_spans_number_of_octaves(entry)
    local top_note = entry:CalcHighestNote(nil)
    local bottom_note = entry:CalcLowestNote(nil)
    local displacement_diff = top_note.Displacement - bottom_note.Displacement
    local num_octaves = math.ceil(displacement_diff / 7)
    return num_octaves
end

--[[
% add_augmentation_dot(entry)

Adds an augentation dot to the entry. This works even if the entry already has one or more augmentation dots.

@ entry (FCNoteEntry) the entry to which to add the augmentation dot
]]
function note_entry.add_augmentation_dot(entry)
    -- entry.Duration = entry.Duration | (entry.Duration >> 1) -- For Lua 5.3 and higher
    entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
end

--[[
% get_next_same_v(entry)

Returns the next entry in the same V1 or V2 as the input entry.
If the input entry is V2, only the current V2 launch is searched.
If the input entry is V1, only the current measure and layer is searched.

@ entry (FCNoteEntry) the entry to process
: (FCNoteEntry) the next entry or `nil` in none
]]
function note_entry.get_next_same_v(entry)
    local next_entry = entry:Next()
    if entry.Voice2 then
        if (nil ~= next_entry) and next_entry.Voice2 then
            return next_entry
        end
        return nil
    end
    if entry.Voice2Launch then
        while (nil ~= next_entry) and next_entry.Voice2 do
            next_entry = next_entry:Next()
        end
    end
    return next_entry
end



--[[
$module Enigma String
]]
local enigma_string = {}

local starts_with_font_command = function(string)
    local text_cmds = {"^font", "^Font", "^fontMus", "^fontTxt", "^fontNum", "^size", "^nfx"}
    for i, text_cmd in ipairs(text_cmds) do
        if string:StartsWith(text_cmd) then
            return true
        end
    end
    return false
end

--[[
The following implements a hypothetical FCString.TrimFirstEnigmaFontTags() function
that would preferably be in the PDK Framework. Trimming only first allows us to
preserve style changes within the rest of the string, such as changes from plain to
italic. Ultimately this seems more useful than trimming out all font tags.
If the PDK Framework is ever changed, it might be even better to create replace font
functions that can replace only font, only size, only style, or all three together.
]]

--[[
% trim_first_enigma_font_tags(string)

Trims the first font tags and returns the result as an instance of FCFontInfo.

@ string (FCString) this is both the input and the trimmed output result
: (FCFontInfo | nil) the first font info that was stripped or `nil` if none
]]
function enigma_string.trim_first_enigma_font_tags(string)
    local font_info = finale.FCFontInfo()
    local found_tag = false
    while true do
        if not starts_with_font_command(string) then
            break
        end
        local end_of_tag = string:FindFirst(")")
        if end_of_tag < 0 then
            break
        end
        local font_tag = finale.FCString()
        if string:SplitAt(end_of_tag, font_tag, nil, true) then
            font_info:ParseEnigmaCommand(font_tag)
        end
        string:DeleteCharactersAt(0, end_of_tag+1)
        found_tag = true
    end
    if found_tag then
        return font_info
    end
    return nil
end

--[[
% change_first_string_font (string, font_info)

Replaces the first enigma font tags of the input enigma string.

@ string (FCString) this is both the input and the modified output result
@ font_info (FCFontInfo) replacement font info
: (boolean) true if success
]]
function enigma_string.change_first_string_font (string, font_info)
    local final_text = font_info:CreateEnigmaString(nil)
    local current_font_info = enigma_string.trim_first_enigma_font_tags(string)
    if (current_font_info == nil) or not font_info:IsIdenticalTo(current_font_info) then
        final_text:AppendString(string)
        string:SetString (final_text)
        return true
    end
    return false
end

--[[
% change_first_text_block_font (text_block, font_info)

Replaces the first enigma font tags of input text block.

@ text_block (FCTextBlock) this is both the input and the modified output result
@ font_info (FCFontInfo) replacement font info
: (boolean) true if success
]]
function enigma_string.change_first_text_block_font (text_block, font_info)
    local new_text = text_block:CreateRawTextString()
    if enigma_string.change_first_string_font(new_text, font_info) then
        text_block:SaveRawTextString(new_text)
        return true
    end
    return false
end

--These implement a complete font replacement using the PDK Framework's
--built-in TrimEnigmaFontTags() function.
 
--[[
% change_string_font (string, font_info)

Changes the entire enigma string to have the input font info.

@ string (FCString) this is both the input and the modified output result
@ font_info (FCFontInfo) replacement font info
]]
function enigma_string.change_string_font (string, font_info)
    local final_text = font_info:CreateEnigmaString(nil)
    string:TrimEnigmaFontTags()
    final_text:AppendString(string)
    string:SetString (final_text)
end

--[[
% change_text_block_font (text_block, font_info)

Changes the entire text block to have the input font info.

@ text_block (FCTextBlock) this is both the input and the modified output result
@ font_info (FCFontInfo) replacement font info
]]
function enigma_string.change_text_block_font (text_block, font_info)
    local new_text = text_block:CreateRawTextString()
    enigma_string.change_string_font(new_text, font_info)
    text_block:SaveRawTextString(new_text)
end

--[[
% remove_inserts (fcstring, replace_with_generic)

Removes text inserts other than font commands and replaces them with 

@ fcstring (FCString) this is both the input and the modified output result
@ replace_with_generic (boolean) if true, replace the insert with the text of the enigma command
]]
function enigma_string.remove_inserts (fcstring, replace_with_generic)
    -- so far this just supports page-level inserts. if this ever needs to work with expressions, we'll need to
    -- add the last three items in the (Finale 26) text insert menu, which are playback inserts not available to page text
    local text_cmds = {"^arranger", "^composer", "^copyright", "^date", "^description", "^fdate", "^filename",
                        "^lyricist", "^page", "^partname", "^perftime", "^subtitle", "^time", "^title", "^totpages"}
    local lua_string = fcstring.LuaString
    for i, text_cmd in ipairs(text_cmds) do
        local starts_at = string.find(lua_string, text_cmd, 1, true) -- true: do a plain search
        while nil ~= starts_at do
            local replace_with = ""
            if replace_with_generic then
                replace_with = string.sub(text_cmd, 2)
            end
            local after_text_at = starts_at+string.len(text_cmd)
            local next_at = string.find(lua_string, ")", after_text_at, true)
            if nil ~= next_at then
                next_at = next_at + 1
            else
                next_at = starts_at
            end
            lua_string = string.sub(lua_string, 1, starts_at-1) .. replace_with .. string.sub(lua_string, next_at)
            starts_at = string.find(lua_string, text_cmd, 1, true)
        end
    end
    fcstring.LuaString = lua_string
end

--[[
% expand_value_tag(fcstring, value_num)

Expands the value tag to the input value_num.

@ fcstring (FCString) this is both the input and the modified output result
@ value_num (number) the value number to replace the tag with
]]
function enigma_string.expand_value_tag(fcstring, value_num)
    value_num = math.floor(value_num +0.5) -- in case value_num is not an integer
    fcstring.LuaString = fcstring.LuaString:gsub("%^value%(%)", tostring(value_num))
end

--[[
% calc_text_advance_width(inp_string)

Calculates the advance width of the input string taking into account all font and style changes within the string.

@ inp_string (FCString) this is an input-only value and is not modified
: (number) the width of the string
]]
function enigma_string.calc_text_advance_width(inp_string)
    local accumulated_string = ""
    local accumulated_width = 0
    local enigma_strings = inp_string:CreateEnigmaStrings(true) -- true: include non-commands
    for str in each(enigma_strings) do
        accumulated_string = accumulated_string .. str.LuaString
        if string.sub(str.LuaString, 1, 1) ~= "^" then -- if this string segment is not a command, calculate its width
            local fcstring = finale.FCString()
            local text_met = finale.FCTextMetrics()
            fcstring.LuaString = accumulated_string
            local font_info = fcstring:CreateLastFontInfo()
            fcstring.LuaString = str.LuaString
            fcstring:TrimEnigmaTags()
            text_met:LoadString(fcstring, font_info, 100)
            accumulated_width = accumulated_width + text_met:GetAdvanceWidthEVPUs()
        end
    end
    return accumulated_width
end




--[[
% get_music_region(exp_assign)

Returns a music region corresponding to the input expression assignment.

@ exp_assign (FCExpression)
: (FCMusicRegion)
]]
function expression.get_music_region(exp_assign)
    if not exp_assign:IsSingleStaffAssigned() then
        return nil
    end
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection() -- called to match the selected IU list (e.g., if using Staff Sets)
    exp_region.StartStaff = exp_assign.Staff
    exp_region.EndStaff = exp_assign.Staff
    exp_region.StartMeasure = exp_assign.Measure
    exp_region.EndMeasure = exp_assign.Measure
    exp_region.StartMeasurePos = exp_assign.MeasurePos
    exp_region.EndMeasurePos = exp_assign.MeasurePos
    return exp_region
end

--[[
% get_associated_entry(exp_assign)

Returns the note entry associated with the input expression assignment, if any.

@ exp_assign (FCExpression)
: (FCNoteEntry) associated entry or nil if none
]]
function expression.get_associated_entry(exp_assign)
    local exp_region = expression.get_music_region(exp_assign)
    if nil == exp_region then
        return nil
    end
    for entry in eachentry(exp_region) do
        if (0 == exp_assign.LayerAssignment) or (entry.LayerNumber == exp_assign.LayerAssignment) then
            if not entry:GetGraceNote() then -- for now skip all grace notes: we can revisit this if need be
                return entry
            end
        end
    end
    return nil
end

--[[
% calc_handle_offset_for_smart_shape(exp_assign)

Returns the horizontal EVPU offset for a smart shape endpoint to align exactly with the handle of the input expression, given that they both have the same EDU position.

@ exp_assign (FCExpression)
: (number)
]]
function expression.calc_handle_offset_for_smart_shape(exp_assign)
    local manual_horizontal = exp_assign.HorizontalPos
    local def_horizontal = 0 
    local alignment_offset = 0
    local exp_def = exp_assign:CreateTextExpressionDef()
    if nil ~= exp_def then
        def_horizontal = exp_def.HorizontalOffset
    end
    local exp_entry = expression.get_associated_entry(exp_assign)
    if (nil ~= exp_entry) and (nil ~= exp_def) then
        if finale.ALIGNHORIZ_LEFTOFALLNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_left_of_all_noteheads(exp_entry)
        elseif finale.ALIGNHORIZ_LEFTOFPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_left_of_primary_notehead(exp_entry)
        elseif finale.ALIGNHORIZ_STEM == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_stem_offset(exp_entry)
        elseif finale.ALIGNHORIZ_CENTERPRIMARYNOTEHEAD == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_center_of_primary_notehead(exp_entry)
        elseif finale.ALIGNHORIZ_CENTERALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_center_of_all_noteheads(exp_entry)
        elseif finale.ALIGNHORIZ_RIGHTALLNOTEHEADS == exp_def.HorizontalAlignmentPoint then
            alignment_offset = note_entry.calc_right_of_all_noteheads(exp_entry)
        end
    end
    return (manual_horizontal + def_horizontal + alignment_offset)
end

--[[
% calc_text_width(expression_def, expand_tags)

Returns the text advance width of the input expression definition.

@ expression_def (FCTextExpessionDef)
@ [expand_tags] (boolean) defaults to false, currently only supports `^value()`
: (number)
]]
function expression.calc_text_width(expression_def, expand_tags)
    expand_tags = expand_tags or false
    local fcstring = expression_def:CreateTextString()
    if expand_tags then
        enigma_string.expand_value_tag(fcstring, expression_def:GetPlaybackTempoValue())
    end
    local retval = enigma_string.calc_text_advance_width(fcstring)
    return retval
end

--[[
% is_for_current_part(exp_assign, current_part)

Returns true if the expression assignment is assigned to the current part or score.

@ exp_assign (FCExpression)
@ [current_part] (FCPart) defaults to current part, but it can be supplied if the caller has already calculated it.
: (boolean)
]]
function expression.is_for_current_part(exp_assign, current_part)
    current_part = current_part or library.get_current_part()
    if current_part:IsScore() and exp_assign.ScoreAssignment then
        return true
    elseif current_part:IsPart() and exp_assign.PartAssignment then
        return true
    end
    return false
end



--[[
$module Note Entry
]]
local note_entry = {}

--[[
% get_music_region(entry)

Returns an intance of `FCMusicRegion` that corresponds to the metric location of the input note entry.

@ entry (FCNoteEntry)
: (FCMusicRegion)
]]
function note_entry.get_music_region(entry)
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection() -- called to match the selected IU list (e.g., if using Staff Sets)
    exp_region.StartStaff = entry.Staff
    exp_region.EndStaff = entry.Staff
    exp_region.StartMeasure = entry.Measure
    exp_region.EndMeasure = entry.Measure
    exp_region.StartMeasurePos = entry.MeasurePos
    exp_region.EndMeasurePos = entry.MeasurePos
    return exp_region
end

--entry_metrics can be omitted, in which case they are constructed and released here
--return entry_metrics, loaded_here
local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
    if nil ~= entry_metrics then
        return entry_metrics, false
    end
    entry_metrics = finale.FCEntryMetrics()
    if entry_metrics:Load(entry) then
        return entry_metrics, true
    end
    return nil, false
end

--[[
% get_evpu_notehead_height(entry)

Returns the calculated height of the notehead rectangle.

@ entry (FCNoteEntry)

: (number) the EVPU height
]]
function note_entry.get_evpu_notehead_height(entry)
    local highest_note = entry:CalcHighestNote(nil)
    local lowest_note = entry:CalcLowestNote(nil)
    local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12 -- 12 evpu per staff step; add 2 staff steps to accommodate for notehead height at top and bottom
    return evpu_height
end

--[[
% get_top_note_position(entry, entry_metrics)

Returns the vertical page coordinate of the top of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_top_note_position(entry, entry_metrics)
    local retval = -math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if not entry:CalcStemUp() then
        retval = entry_metrics.TopPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling*evpu_height)/10000) + 0.5)
            retval = entry_metrics.BottomPosition + scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% get_bottom_note_position(entry, entry_metrics)

Returns the vertical page coordinate of the bottom of the notehead rectangle, not including the stem.

@ entry (FCNoteEntry)
@ [entry_metrics] (FCEntryMetrics) entry metrics may be supplied by the caller if they are already available
: (number)
]]
function note_entry.get_bottom_note_position(entry, entry_metrics)
    local retval = math.huge
    local loaded_here = false
    entry_metrics, loaded_here = use_or_get_passed_in_entry_metrics(entry, entry_metrics)
    if nil == entry_metrics then
        return retval
    end
    if entry:CalcStemUp() then
        retval = entry_metrics.BottomPosition
    else
        local cell_metrics = finale.FCCell(entry.Measure, entry.Staff):CreateCellMetrics()
        if nil ~= cell_metrics then
            local evpu_height = note_entry.get_evpu_notehead_height(entry)
            local scaled_height = math.floor(((cell_metrics.StaffScaling*evpu_height)/10000) + 0.5)
            retval = entry_metrics.TopPosition - scaled_height
            cell_metrics:FreeMetrics()
        end
    end
    if loaded_here then
        entry_metrics:FreeMetrics()
    end
    return retval
end

--[[
% calc_widths(entry)

Get the widest left-side notehead width and widest right-side notehead width.

@ entry (FCNoteEntry)
: (number, number) widest left-side notehead width and widest right-side notehead width
]]
function note_entry.calc_widths(entry)
    local left_width = 0
    local right_width = 0
    for note in each(entry) do
        local note_width = note:CalcNoteheadWidth()
        if note_width > 0 then
            if note:CalcRightsidePlacement() then
                if note_width > right_width then
                    right_width = note_width
                end
            else
                if note_width > left_width then
                    left_width = note_width
                end
            end
        end
    end
    return left_width, right_width
end

-- These functions return the offset for an expression handle.
-- Expression handles are vertical when they are left-aligned
-- with the primary notehead rectangle.

--[[
% calc_left_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Left of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_all_noteheads(entry)
    if entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return -left
end

--[[
% calc_left_of_primary_notehead(entry)

Calculates the handle offset for an expression with "Left of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_left_of_primary_notehead(entry)
    return 0
end

--[[
% calc_center_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Center of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    local width_centered = (left + right) / 2
    if not entry:CalcStemUp() then
        width_centered = width_centered - left
    end
    return width_centered
end

--[[
% calc_center_of_primary_notehead(entry)

Calculates the handle offset for an expression with "Center of Primary Notehead" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_center_of_primary_notehead(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left / 2
    end
    return right / 2
end

--[[
% calc_stem_offset(entry)

Calculates the offset of the stem from the left edge of the notehead rectangle. Eventually the PDK Framework may be able to provide this instead.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset of stem from the left edge of the notehead rectangle.
]]
function note_entry.calc_stem_offset(entry)
    if not entry:CalcStemUp() then
        return 0
    end
    local left, right = note_entry.calc_widths(entry)
    return left
end

--[[
% calc_right_of_all_noteheads(entry)

Calculates the handle offset for an expression with "Right of All Noteheads" horizontal positioning.

@ entry (FCNoteEntry) the entry to calculate from
: (number) offset from left side of primary notehead rectangle
]]
function note_entry.calc_right_of_all_noteheads(entry)
    local left, right = note_entry.calc_widths(entry)
    if entry:CalcStemUp() then
        return left + right
    end
    return right
end

--[[
% calc_note_at_index(entry, note_index)

This function assumes `for note in each(note_entry)` always iterates in the same direction.
(Knowing how the Finale PDK works, it probably iterates from bottom to top note.)
Currently the PDK Framework does not seem to offer a better option.

@ entry (FCNoteEntry)
@ note_index (number) the zero-based index
]]
function note_entry.calc_note_at_index(entry, note_index)
    local x = 0
    for note in each(entry) do
        if x == note_index then
            return note
        end
        x = x + 1
    end
    return nil
end

--[[
% stem_sign(entry)

This is useful for many x,y positioning fields in Finale that mirror +/-
based on stem direction.

@ entry (FCNoteEntry)
: (number) 1 if upstem, -1 otherwise
]]
function note_entry.stem_sign(entry)
    if entry:CalcStemUp() then
        return 1
    end
    return -1
end

--[[
% duplicate_note(note)

@ note (FCNote)
: (FCNote | nil) reference to added FCNote or `nil` if not success
]]
function note_entry.duplicate_note(note)
    local new_note = note.Entry:AddNewNote()
    if nil ~= new_note then
        new_note.Displacement = note.Displacement
        new_note.RaiseLower = note.RaiseLower
        new_note.Tie = note.Tie
        new_note.TieBackwards = note.TieBackwards
    end
    return new_note
end

--[[
% delete_note(note)

Removes the specified FCNote from its associated FCNoteEntry.

@ note (FCNote)
: (boolean) true if success
]]
function note_entry.delete_note(note)
    local entry = note.Entry
    if nil == entry then
        return false
    end

    -- attempt to delete all associated entry-detail mods, but ignore any failures
    finale.FCAccidentalMod():EraseAt(note)
    finale.FCCrossStaffMod():EraseAt(note)
    finale.FCDotMod():EraseAt(note)
    finale.FCNoteheadMod():EraseAt(note)
    finale.FCPercussionNoteMod():EraseAt(note)
    finale.FCTablatureNoteMod():EraseAt(note)
    --finale.FCTieMod():EraseAt(note)  -- FCTieMod is not currently lua supported, but leave this here in case it ever is

    return entry:DeleteNote(note)
end

--[[
% calc_spans_number_of_octaves(entry)

Calculates the numer of octaves spanned by a chord (considering only staff positions, not accidentals).

@ entry (FCNoteEntry) the entry to calculate from
: (number) of octaves spanned
]]
function note_entry.calc_spans_number_of_octaves(entry)
    local top_note = entry:CalcHighestNote(nil)
    local bottom_note = entry:CalcLowestNote(nil)
    local displacement_diff = top_note.Displacement - bottom_note.Displacement
    local num_octaves = math.ceil(displacement_diff / 7)
    return num_octaves
end

--[[
% add_augmentation_dot(entry)

Adds an augentation dot to the entry. This works even if the entry already has one or more augmentation dots.

@ entry (FCNoteEntry) the entry to which to add the augmentation dot
]]
function note_entry.add_augmentation_dot(entry)
    -- entry.Duration = entry.Duration | (entry.Duration >> 1) -- For Lua 5.3 and higher
    entry.Duration = bit32.bor(entry.Duration, bit32.rshift(entry.Duration, 1))
end

--[[
% get_next_same_v(entry)

Returns the next entry in the same V1 or V2 as the input entry.
If the input entry is V2, only the current V2 launch is searched.
If the input entry is V1, only the current measure and layer is searched.

@ entry (FCNoteEntry) the entry to process
: (FCNoteEntry) the next entry or `nil` in none
]]
function note_entry.get_next_same_v(entry)
    local next_entry = entry:Next()
    if entry.Voice2 then
        if (nil ~= next_entry) and next_entry.Voice2 then
            return next_entry
        end
        return nil
    end
    if entry.Voice2Launch then
        while (nil ~= next_entry) and next_entry.Voice2 do
            next_entry = next_entry:Next()
        end
    end
    return next_entry
end



--  Author: Robert Patterson
--  Date: March 5, 2021

--[[
$module Configuration

This library implements a UTF-8 text file scheme for configuration as follows:

- Comments start with `--`
- Leading, trailing, and extra whitespace is ignored
- Each parameter is named and delimited as follows:
`<parameter-name> = <parameter-value>`

Parameter values may be:

- Strings delimited with either single- or double-quotes
- Tables delimited with `{}` that may contain strings, booleans, or numbers
- Booleans (`true` or `false`)
- Numbers

Currently the following are not supported:

- Tables embedded within tables
- Tables containing strings that contain commas

A sample configuration file might be:

```lua
-- Configuration File for "Hairpin and Dynamic Adjustments" script
--
left_dynamic_cushion 		= 12		--evpus
right_dynamic_cushion		= -6		--evpus
```

Configuration files must be placed in a subfolder called `script_settings` within
the folder of the calling script. Each script that has a configuration file
defines its own configuration file name.
]]

local configuration = {}

local script_settings_dir = "script_settings" -- the parent of this directory is the running lua path
local comment_marker = "--"
local parameter_delimiter = "="
local path_delimiter = "/"

local file_exists = function(file_path)
    local f = io.open(file_path,"r")
    if nil ~= f then
        io.close(f)
        return true
    end
    return false
end

local strip_leading_trailing_whitespace = function (str)
    return str:match("^%s*(.-)%s*$") -- lua pattern magic taken from the Internet
end

local parse_parameter -- forward function declaration

local parse_table = function(val_string)
    local ret_table = {}
    for element in val_string:gmatch('[^,%s]+') do  -- lua pattern magic taken from the Internet
        local parsed_element = parse_parameter(element)
        table.insert(ret_table, parsed_element)
    end
    return ret_table
end

parse_parameter = function(val_string)
    if '"' == val_string:sub(1,1) and '"' == val_string:sub(#val_string,#val_string) then -- double-quote string
        return string.gsub(val_string, '"(.+)"', "%1") -- lua pattern magic: "(.+)" matches all characters between two double-quote marks (no escape chars)
    elseif "'" == val_string:sub(1,1) and "'" == val_string:sub(#val_string,#val_string) then -- single-quote string
        return string.gsub(val_string, "'(.+)'", "%1") -- lua pattern magic: '(.+)' matches all characters between two single-quote marks (no escape chars)
    elseif "{" == val_string:sub(1,1) and "}" == val_string:sub(#val_string,#val_string) then
        return parse_table(string.gsub(val_string, "{(.+)}", "%1"))
    elseif "true" == val_string then
        return true
    elseif "false" == val_string then
        return false
    end
    return tonumber(val_string)
end

local get_parameters_from_file = function(file_name)
    local parameters = {}

    local path = finale.FCString()
    path:SetRunningLuaFolderPath()
    local file_path = path.LuaString .. path_delimiter .. file_name
    if not file_exists(file_path) then
        return parameters
    end

    for line in io.lines(file_path) do
        local comment_at = string.find(line, comment_marker, 1, true) -- true means find raw string rather than lua pattern
        if nil ~= comment_at then
            line = string.sub(line, 1, comment_at-1)
        end
        local delimiter_at = string.find(line, parameter_delimiter, 1, true)
        if nil ~= delimiter_at then
            local name = strip_leading_trailing_whitespace(string.sub(line, 1, delimiter_at-1))
            local val_string = strip_leading_trailing_whitespace(string.sub(line, delimiter_at+1))
            parameters[name] = parse_parameter(val_string)
        end
    end
    
    return parameters
end

--[[
% get_parameters(file_name, parameter_list)

Searches for a file with the input filename in the `script_settings` directory and replaces the default values in `parameter_list` with any that are found in the config file.

@ file_name (string) the file name of the config file (which will be prepended with the `script_settings` directory)
@ parameter_list (table) a table with the parameter name as key and the default value as value
]]
function configuration.get_parameters(file_name, parameter_list)
    local file_parameters = get_parameters_from_file(script_settings_dir .. path_delimiter .. file_name)
    if nil ~= file_parameters then
        for param_name, def_val in pairs(parameter_list) do
            local param_val = file_parameters[param_name]
            if nil ~= param_val then
                parameter_list[param_name] = param_val
            end
        end
    end
end




-- These parameters can be changed with a config.txt file

local config = {
    left_dynamic_cushion = 9,                   -- space between a dynamic and a hairpin on the left (evpu)
    right_dynamic_cushion = -9,                 -- space between a dynamic and a haripin on the right (evpu)
    left_selection_cushion = 0,                 -- currently not used
    right_selection_cushion = 0,                -- additional space between a hairpin and the end of its beat region (evpu)
    extend_to_end_of_right_entry = true,        -- if true, extend hairpins through the end of their right note entries
    limit_to_hairpins_on_notes = true,          -- if true, only hairpins attached to notes are considered
    vertical_adjustment_type = "far",           -- possible values: "near", "far", "none"
    horizontal_adjustment_type = "both",        -- possible values: "both", "left", "right", "none"
    vertical_displacement_for_hairpins = 12     -- alignment displacement for hairpins relative to dynamics handle (evpu)
}

configuration.get_parameters("standalone_hairpin_adjustment.config.txt", config)

-- In RGP Lua, flip vertical_adjustment_type based on alt/option key when invoked

if finenv.IsRGPLua and finenv.QueryInvokedModifierKeys then
    if finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) then
        if config.vertical_adjustment_type == "far" then
            config.vertical_adjustment_type = "near"
        elseif config.vertical_adjustment_type == "near" then
            config.vertical_adjustment_type = "far"
        end
    end
end

-- end of parameters

function calc_cell_relative_vertical_position(fccell, page_offset)
    local relative_position = page_offset
    local cell_metrics = fccell:CreateCellMetrics()
    if nil ~= cell_metrics then
        relative_position = page_offset - cell_metrics.ReferenceLinePos
        cell_metrics:FreeMetrics()
    end
    return relative_position
end

function expression_calc_relative_vertical_position(fcexpression)
    local arg_point = finale.FCPoint(0, 0)
    if not fcexpression:CalcMetricPos(arg_point) then
        return false, 0
    end
    local cell = finale.FCCell(fcexpression.Measure, fcexpression.Staff)
    local vertical_pos = calc_cell_relative_vertical_position(cell, arg_point:GetY())
    return true, vertical_pos
end

function smartshape_calc_relative_vertical_position(fcsmartshape)
    local arg_point = finale.FCPoint(0, 0)
    -- due to a limitation in Finale, CalcRightCellMetricPos is not reliable, so only check CalcLeftCellMetricPos
    if not fcsmartshape:CalcLeftCellMetricPos(arg_point) then
        return false, 0
    end
    local ss_seg = fcsmartshape:GetTerminateSegmentLeft()
    local cell = finale.FCCell(ss_seg.Measure, ss_seg.Staff)
    local vertical_pos = calc_cell_relative_vertical_position(cell, arg_point:GetY())
    return true, vertical_pos
end

function vertical_dynamic_adjustment(region, direction)
    local lowest_item = {}
    local staff_pos = {}
    local has_dynamics = false
    local has_hairpins = false

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                local success, staff_offset = expression_calc_relative_vertical_position(e)
                if success then
                    has_dynamics = true
                    table.insert(lowest_item, staff_offset)
                end
            end
        end
    end

    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(region, true)
    for mark in each(ssmm) do
        local smart_shape = mark:CreateSmartShape()
        if smart_shape:IsHairpin() then
            has_hairpins = true
            local success, staff_offset = smartshape_calc_relative_vertical_position(smart_shape)
            if success then
                table.insert(lowest_item, staff_offset - config.vertical_displacement_for_hairpins)
            end
        end
    end

    table.sort(lowest_item)

    if has_dynamics then
        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(region)
        for e in each(expressions) do
            local create_def = e:CreateTextExpressionDef()
            local cd = finale.FCCategoryDef()
            if cd:Load(create_def:GetCategoryID()) then
                if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                    local success, staff_offset = expression_calc_relative_vertical_position(e)
                    if success then
                        local difference_pos =  staff_offset - lowest_item[1]
                        if direction == "near" then
                            difference_pos = lowest_item[#lowest_item] - staff_offset
                        end
                        local current_pos = e:GetVerticalPos()
                        if direction == "far" then
                            e:SetVerticalPos(current_pos - difference_pos)
                        else
                            e:SetVerticalPos(current_pos + difference_pos)
                        end
                        e:Save()
                    end
                end
            end
        end
    else
        for noteentry in eachentry(region) do
            if noteentry:IsNote() then
                for note in each(noteentry) do
                    table.insert(staff_pos, note:CalcStaffPosition())
                end
            end
        end

        table.sort(staff_pos)

        if (nil ~= staff_pos[1]) and ("far" == direction) and (#lowest_item > 0) then
            local min_lowest_position = lowest_item[1]
            if staff_pos[1] > -7 then
                min_lowest_position = -160
            else
                local below_note_cushion = 45
                min_lowest_position = (staff_pos[1] * 12) - below_note_cushion -- multiply by 12 to convert staff position to evpu
            end
            if lowest_item[1] > min_lowest_position then
                lowest_item[1] = min_lowest_position
            end
        end
    end

    if has_hairpins then
        local ssmm = finale.FCSmartShapeMeasureMarks()
        ssmm:LoadAllForRegion(region, true)
        for mark in each(ssmm) do
            local smart_shape = mark:CreateSmartShape()
            if smart_shape:IsHairpin() then
                local success, staff_offset = smartshape_calc_relative_vertical_position(smart_shape)
                if success then
                    local left_seg = smart_shape:GetTerminateSegmentLeft()
                    local right_seg = smart_shape:GetTerminateSegmentRight()
                    local current_pos = left_seg:GetEndpointOffsetY()
                    local difference_pos = staff_offset - lowest_item[1]
                    if direction == "near" then
                        difference_pos = lowest_item[#lowest_item] - staff_offset
                    end
                    if has_dynamics then
                        if direction == "far" then
                            left_seg:SetEndpointOffsetY((current_pos - difference_pos) + config.vertical_displacement_for_hairpins)
                            right_seg:SetEndpointOffsetY((current_pos - difference_pos) + config.vertical_displacement_for_hairpins)
                        else
                            left_seg:SetEndpointOffsetY((current_pos + difference_pos) + config.vertical_displacement_for_hairpins)
                            right_seg:SetEndpointOffsetY((current_pos + difference_pos) + config.vertical_displacement_for_hairpins)
                        end
                    else
                        if "far" == direction then
                            left_seg:SetEndpointOffsetY(lowest_item[1])
                            right_seg:SetEndpointOffsetY(lowest_item[1])
                        elseif "near" == direction then
                            left_seg:SetEndpointOffsetY(lowest_item[#lowest_item])
                            right_seg:SetEndpointOffsetY(lowest_item[#lowest_item])
                        end
                    end
                    smart_shape:Save()
                end
            end
        end
    end
end

function horizontal_hairpin_adjustment(left_or_right, hairpin, region_settings, cushion_bool, multiple_hairpin_bool)
    local the_seg = hairpin:GetTerminateSegmentLeft()

    if left_or_right == "left" then
        the_seg = hairpin:GetTerminateSegmentLeft()
    end
    if left_or_right == "right" then
        the_seg = hairpin:GetTerminateSegmentRight()
    end

    local region = finale.FCMusicRegion()
    region:SetStartStaff(region_settings[1])
    region:SetEndStaff(region_settings[1])

    if multiple_hairpin_bool or not config.limit_to_hairpins_on_notes then
        region:SetStartMeasure(the_seg:GetMeasure())
        region:SetStartMeasurePos(the_seg:GetMeasurePos())
        region:SetEndMeasure(the_seg:GetMeasure())
        region:SetEndMeasurePos(the_seg:GetMeasurePos())
    else
        region:SetStartMeasure(region_settings[2])
        region:SetEndMeasure(region_settings[2])
        region:SetStartMeasurePos(region_settings[3])
        region:SetEndMeasurePos(region_settings[3])
        the_seg:SetMeasurePos(region_settings[3])
    end

    local expressions = finale.FCExpressions()
    expressions:LoadAllForRegion(region)
    local expression_list = {}
    for e in each(expressions) do
        local create_def = e:CreateTextExpressionDef()
        local cd = finale.FCCategoryDef()
        if cd:Load(create_def:GetCategoryID()) then
            if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                table.insert(expression_list, {expression.calc_text_width(create_def), e, e:GetItemInci()})
            end
        end
    end
    if #expression_list > 0 then
        local dyn_exp = expression_list[1][2]
        local dyn_def = dyn_exp:CreateTextExpressionDef()
        local dyn_width = expression_list[1][1] -- the full value is needed for finale.EXPRJUSTIFY_LEFT
        if finale.EXPRJUSTIFY_CENTER == dyn_def.HorizontalJustification then
            dyn_width = dyn_width / 2
        elseif finale.EXPRJUSTIFY_RIGHT == dyn_def.HorizontalJustification then
            dyn_width = 0
        end
        local total_offset = expression.calc_handle_offset_for_smart_shape(dyn_exp)
        if left_or_right == "left" then
            local total_x = dyn_width + config.left_dynamic_cushion + total_offset
            the_seg:SetEndpointOffsetX(total_x)
        elseif left_or_right == "right" then
            cushion_bool = false
            local total_x = (0 - dyn_width) + config.right_dynamic_cushion + total_offset
            the_seg:SetEndpointOffsetX(total_x)
        end
    end
    if cushion_bool then
        the_seg = hairpin:GetTerminateSegmentRight()
        local entry_width = 0
        if config.extend_to_end_of_right_entry then
            region:SetStartMeasure(the_seg:GetMeasure())
            region:SetStartMeasurePos(the_seg:GetMeasurePos())
            region:SetEndMeasure(the_seg:GetMeasure())
            region:SetEndMeasurePos(the_seg:GetMeasurePos())
            for noteentry in eachentry(region) do
                local this_width =  note_entry.calc_right_of_all_noteheads(noteentry)
                if this_width > entry_width then
                    entry_width = this_width
                end
            end
        end
        the_seg:SetEndpointOffsetX(config.right_selection_cushion + entry_width)
    end
    hairpin:Save()
end

function hairpin_adjustments(range_settings)

    local music_reg = finale.FCMusicRegion()
    music_reg:SetCurrentSelection()
    music_reg:SetStartStaff(range_settings[1])
    music_reg:SetEndStaff(range_settings[1])

    local hairpin_list = {}

    local ssmm = finale.FCSmartShapeMeasureMarks()
    ssmm:LoadAllForRegion(music_reg, true)
    for mark in each(ssmm) do
        local smartshape = mark:CreateSmartShape()
        if smartshape:IsHairpin() then
            table.insert(hairpin_list, smartshape)
        end
    end

    function has_dynamic(region)

        local expressions = finale.FCExpressions()
        expressions:LoadAllForRegion(region)
        local expression_list = {}
        for e in each(expressions) do
            local create_def = e:CreateTextExpressionDef()
            local cd = finale.FCCategoryDef()
            if cd:Load(create_def:GetCategoryID()) then
                if ((cd:GetID() == finale.DEFAULTCATID_DYNAMICS) or (string.find(cd:CreateName().LuaString, "Dynamic"))) then
                    table.insert(expression_list, e)
                end
            end
        end
        if #expression_list > 0 then
            return true
        else
            return false
        end
    end

    local end_pos = range_settings[5]
    local end_cushion = not config.limit_to_hairpins_on_notes

    local notes_in_region = {}
    for noteentry in eachentry(music_reg) do
        if noteentry:IsNote() then
            table.insert(notes_in_region, noteentry)
        end
    end

    if #notes_in_region > 0 then
        music_reg:SetStartMeasure(notes_in_region[#notes_in_region]:GetMeasure())
        music_reg:SetEndMeasure(notes_in_region[#notes_in_region]:GetMeasure())
        music_reg:SetStartMeasurePos(notes_in_region[#notes_in_region]:GetMeasurePos())
        music_reg:SetEndMeasurePos(notes_in_region[#notes_in_region]:GetMeasurePos())
        if (has_dynamic(music_reg)) and (#notes_in_region > 1) then
            local last_note = notes_in_region[#notes_in_region]
            end_pos = last_note:GetMeasurePos() + last_note:GetDuration()
        elseif (has_dynamic(music_reg)) and (#notes_in_region == 1) then
            end_pos = range_settings[5]
        else
            end_cushion = true
        end
    else
        end_cushion = true
    end

    music_reg:SetStartStaff(range_settings[1])
    music_reg:SetEndStaff(range_settings[1])
    music_reg:SetStartMeasure(range_settings[2])
    music_reg:SetEndMeasure(range_settings[3])
    music_reg:SetStartMeasurePos(range_settings[4])
    music_reg:SetEndMeasurePos(end_pos)

    if "none" ~= config.horizontal_adjustment_type then
        local multiple_hairpins = (#hairpin_list > 1)
        for key, value in pairs(hairpin_list) do
            if ("both" == config.horizontal_adjustment_type) or ("left" == config.horizontal_adjustment_type) then
                horizontal_hairpin_adjustment("left", value, {range_settings[1], range_settings[2], range_settings[4]}, end_cushion, multiple_hairpins)
            end
            if ("both" == config.horizontal_adjustment_type) or ("right" == config.horizontal_adjustment_type) then
                horizontal_hairpin_adjustment("right", value, {range_settings[1], range_settings[3], end_pos}, end_cushion, multiple_hairpins)
            end
        end
    end
    if "none" ~= config.vertical_adjustment_type then
        if ("both" == config.vertical_adjustment_type) or ("far" == config.vertical_adjustment_type) then
            vertical_dynamic_adjustment(music_reg, "far")
        end
        if ("both" == config.vertical_adjustment_type) or ("near" == config.vertical_adjustment_type) then
            vertical_dynamic_adjustment(music_reg, "near")
        end
    end
end

function set_first_last_note_in_range(staff)

    local music_region = finale.FCMusicRegion()
    local range_settings = {}
    music_region:SetCurrentSelection()
    music_region:SetStartStaff(staff)
    music_region:SetEndStaff(staff)

    if not config.limit_to_hairpins_on_notes then
        local end_meas_pos = music_region.EndMeasurePos
        local meas = finale.FCMeasure()
        meas:Load(music_region.EndMeasure)
        if end_meas_pos > meas:GetDuration() then
            end_meas_pos = meas:GetDuration()
        end
        return {staff, music_region.StartMeasure, music_region.EndMeasure, music_region.StartMeasurePos, end_meas_pos}
    end

    local notes_in_region = {}

    for noteentry in eachentry(music_region) do
        if noteentry:IsNote() then
            table.insert(notes_in_region, noteentry)
        end
    end

    if #notes_in_region > 0 then

        local start_pos = notes_in_region[1]:GetMeasurePos()

        local end_pos = notes_in_region[#notes_in_region]:GetMeasurePos()

        local start_measure = notes_in_region[1]:GetMeasure()

        local end_measure = notes_in_region[#notes_in_region]:GetMeasure()

        if notes_in_region[#notes_in_region]:GetDuration() >= 2048 then
            end_pos = end_pos + notes_in_region[#notes_in_region]:GetDuration()
        end

        return {staff, start_measure, end_measure, start_pos, end_pos}
    end
    return nil
end

function dynamics_align_hairpins_and_dynamics()
    local staves = finale.FCStaves()
    staves:LoadAll()
    for staff in each(staves) do
        local music_region = finale.FCMusicRegion()
        music_region:SetCurrentSelection()
        if music_region:IsStaffIncluded(staff:GetItemNo()) then
            local range_settings = set_first_last_note_in_range(staff:GetItemNo())
            if nil ~= range_settings then
                hairpin_adjustments(range_settings)
            end
        end
    end
end

dynamics_align_hairpins_and_dynamics()
