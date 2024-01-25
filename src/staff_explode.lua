function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "1.69"
    finaleplugin.Date = "2024/01/21"
    finaleplugin.AdditionalMenuOptions = [[
        Staff Explode Pairs
        Staff Explode Pairs (Up)
        Staff Explode Split Pairs
        Staff Explode From Layers
        Staff Explode To Layers
    ]]
    finaleplugin.AdditionalUndoText = [[
        Staff Explode Pairs
        Staff Explode Pairs (Up)
        Staff Explode Split Pairs
        Staff Explode From Layers
        Staff Explode To Layers
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Explode chords from one staff into pairs of notes on consecutive staves
        Explode chords from one staff into pairs of notes from Bottom-Up on consecutive staves
        Explode chords from one staff into "split" pairs of notes on consecutive staves
        Explode multiple layers on one staff to single layers on consecutive staves
        Explode chords on each staff to multiple layers on the same staff
    ]]
    finaleplugin.AdditionalPrefixes = [[
        action = "pairs"
        action = "pairs_up"
        action = "split"
        action = "from_layer"
        action = "to_layer"
    ]]
    finaleplugin.MinJWLuaVersion = 0.68
    finaleplugin.ScriptGroupName = "Staff Explode"
    finaleplugin.ScriptGroupDescription = "Explode chords from the selection onto consecutive staves or layers"
    finaleplugin.Notes = [[
        This script "explodes" a set of chords on one staff into successive staves 
        either as single notes or pairs of notes. 
        If the selected chords contain different numbers of notes, 
        missing notes will be replaced by rests in the destination. 
        It can also explode chords in one layer on each staff into 
        different layers on the same staff, and explode multiple layers 
        from one staff onto successive staves. 

        Five menu items are created:  

        - Staff Explode Singles (single notes onto successive staves)
        - Staff Explode Pairs (pairs of notes, omitting odd notes from bottom staff)
        - Staff Explode Pairs Up (pairs, but omitting odd notes from top staff)
        - Staff Explode Split Pairs (pairs split: 1-3/2-4 | 1-4/2-5/3-6 ... etc)
        - Staff Explode From Layers (multiple layers on one staff to single layers on consecutive staves)
        - Staff Explode To Layers (chords on each staff split into layers on the same staff)
        
        "Staff Explode To Layers" works on one or more staves at once. 
        All other options require a single staff selection. 
        As a special case, if a staff contains only single-note entries, Explode To Layers 
        duplicates them in unison on layer 2 to create standard two-voice notation. 

        Your setting at Finale → Settings... → Edit → [Automatic Music Spacing] 
        determines whether or not the music is RESPACED after each explosion.
    ]]
    return "Staff Explode Singles", "Staff Explode Singles", "Explode chords from one staff into single notes on consecutive staves"
end

action = action or "singles"

local clef = require("library.clef")
local mixin = require("library.mixin")
local note_entry = require("library.note_entry")
local layer = require("library.layer")
local configuration = require("library.configuration")
local library = require("library.general_library")
local script_name = library.calc_script_name()

local config = {
    from_layers_destination = 0, -- saved destination layer choice for "Explode From Layers"
    copy_articulations = 0,
    copy_smartshapes = 0,
    window_pos_x = false,
    window_pos_y = false,
}
local layer_options = { "copy_articulations", "copy_smartshapes" }

local function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

local function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

local function show_error(error_code)
    local errors = {
        need_more_staves = "There are not enough empty\nstaves to explode onto",
        only_one_staff = "Please select only one\nstaff to explode!",
        empty_region = "Please select a region\nwith some notes in it!",
        three_or_more = "Exploding Pairs requires\nthree or more notes per chord",
        two_or_more = "Staff Explode Singles requires\ntwo or more notes per chord",
        not_enough_layers = "The selection must contain music \non two or more layers"
    }
    local msg = errors[error_code] or "Unknown Error"
    finenv.UI():AlertError(msg, finaleplugin.ScriptGroupName .. " Error")
    return -1
end

local function should_overwrite_existing_music()
    local alert = finenv.UI():AlertOkCancel("Overwrite existing music?", "Are you sure?")
    return (alert == 0)
end

local function simple_note_count(region, layer_num)
    local count = 0
    for entry in eachentry(region, layer_num) do
        if entry.Count > count then
            count = entry.Count
        end
    end
    return count
end

local function get_note_count(region)
    local note_count = simple_note_count(region, 0)
    if note_count == 0 then
        return show_error("empty_region")
    end
    if not action:find("layer") then
        if action == "singles" then
            if note_count < 2 then
                return show_error("two_or_more")
            end
        elseif note_count < 3 then -- all the "pairs" options
            return show_error("three_or_more")
        end
    end
    return note_count
end

local function not_enough_staves(slot, staff_count)
    local staves = finale.FCStaves()
    staves:LoadAll()
    if staff_count > staves.Count - slot + 1 then
        show_error("need_more_staves")
        return true
    end
    return false
end

local function clone_note_layer_details(src, dest)
    -- modify destination layer entry-by-entry within EXPLODE TO LAYERS
    -- given source and destination regions
    local shapes = { start = {}, stop = {} }
    for index = 0, src.Count - 1 do
        local src_entry = src:GetItemAt(index)
        local dest_entry = dest:GetItemAt(index)

        if src_entry.SecondaryBeamFlag then -- copy secondary beam breaks
            local bbm = mixin.FCMSecondaryBeamBreakMod()
            bbm:SetNoteEntry(src_entry):LoadFirst()
            bbm:SetNoteEntry(dest_entry):SaveNew()
        end
        if src_entry.NoteDetailFlag then -- copy note details
            local eam = mixin.FCMEntryAlterMod()
            eam:SetNoteEntry(src_entry):LoadFirst()
            eam:SetNoteEntry(dest_entry):SaveNew()
        end
        if config.copy_articulations == 1 then
            for articulation in eachbackwards(src_entry:CreateArticulations()) do
                articulation:SetNoteEntry(dest_entry)
                articulation:SaveNew()
            end
        end
        if config.copy_smartshapes == 1 then
            for mark in loadall(finale.FCSmartShapeEntryMarks(src_entry)) do
                local shape = mark:CreateSmartShape()
                if mark:CalcLeftMark() then shapes.start[shape.ItemNo] = index end
                if mark:CalcRightMark() then shapes.stop[shape.ItemNo] = index end
            end
        end
    end
    dest:Save()
    if config.copy_smartshapes == 1 then -- replicate smart shapes?
        for itemno, index in pairs(shapes.start) do
            local match = shapes.stop[itemno]
            if match then
                local shape = mixin.FCMSmartShape()
                shape:Load(itemno)
                local note = { left = dest:GetItemAt(index), right = dest:GetItemAt(match) }
                shape:GetTerminateSegmentLeft():SetEntry(note.left):SetStaff(note.left.Staff)
                shape:GetTerminateSegmentRight():SetEntry(note.right):SetStaff(note.right.Staff)
                shape:SaveNewEverything(note.left, note.right)
            end
        end
    end
end

local function explode_to_layers_dialog()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
    dialog:CreateStatic(0, 0):SetText("Explode Chords to Layers..."):SetWidth(210)
    local answer = {}
    local y = 17
    dialog:CreateStatic(40, y):SetText("Copy to each Layer:"):SetWidth(150)
    for _, v in ipairs(layer_options) do
        y = y + 17
        answer[v] = dialog:CreateCheckbox(60, y):SetCheck(config[v]):SetWidth(90)
            :SetText(v:sub(6, -1):gsub("^%l", string.upper)) -- capital case
    end
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        for _, v in ipairs(layer_options) do config[v] = answer[v]:GetCheck() end
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function explode_to_layers(region)
    local max = layer.max_layers()
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(region)

    if not explode_to_layers_dialog() then return end -- user cancelled
    for staff in eachstaff(region) do -- one staff at a time
        rgn:SetStartStaff(staff):SetEndStaff(staff)
        local start, stop = region.StartMeasure, region.EndMeasure
        local note_count, src_layer = 0, 0
        for i = 1, max do
            note_count = simple_note_count(rgn, i)
            if note_count > 0 then
                src_layer = i -- found active content
                break
            end
        end

        if note_count == 0 then
            show_error("empty_region")
        else -- this slot contains notes
            local unison_doubling = (note_count == 1) and 1 or 0
            local layer_1 = finale.FCNoteEntryLayer(src_layer - 1, staff, start, stop)
            layer_1:SetUseVisibleLayer(false)
            layer_1:Load()
            local dest_layer = (src_layer < max) and (src_layer + 1) or 1
            local layer_count = 0

            for _ = 2, (note_count + unison_doubling) do  -- copy to the other layers
                local destination = layer_1:CreateCloneEntries(dest_layer - 1, staff, start)
                destination:Save()
                destination:CloneTuplets(layer_1)
                destination:Save()
                clone_note_layer_details(layer_1, destination)
                dest_layer = (dest_layer < max) and (dest_layer + 1) or 1
                layer_count = layer_count + 1
                if layer_count > note_count then break end -- observe maximum layers
            end

            if note_count > 1 then  -- don't delete layer 2 if unison doubling
                for entry in eachentrysaved(rgn) do
                    if entry:IsNote() then
                        local n = entry.LayerNumber
                        local this_layer = n - src_layer + 1
                        if (n < src_layer) then this_layer = this_layer + max end
                        local from_top = this_layer - 1   -- delete how many notes from top?
                        local from_bottom = entry.Count - this_layer -- how many from bottom?

                        if from_top > 0 then -- delete TOP notes
                            for _ = 1, from_top do
                                local high = entry:CalcHighestNote(nil)
                                if high then note_entry.delete_note(high) end
                            end
                        end
                        if from_bottom > 0 and this_layer < max then -- delete BOTTOM notes
                            for _ = 1, from_bottom do
                                local low = entry:CalcLowestNote(nil)
                                if low then note_entry.delete_note(low) end
                            end
                        end
                    end
                end
            end
        end
    end
end

local function explode_from_layers_dialog()
    local max = layer.max_layers()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(finaleplugin.ScriptGroupName)
    dialog:CreateStatic(0, 0):SetText("Explode Layers to new Staves:"):SetWidth(210)
    local opt_list = dialog:CreateListBox(0, 20):SetWidth(210)
        :SetHeight((max + 1) * 17 + 2)
        :AddString("keep the same Layers as the original")
    for i = 1, max do -- add all names in the extant list
        opt_list:AddString("explode all to Layer " .. i)
    end
    opt_list:SetSelectedItem(config.from_layers_destination)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        config.from_layers_destination = opt_list:GetSelectedItem()
    end)
    dialog:RegisterInitWindow(function() opt_list:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

local function explode_from_layers(src_rgn)
    local max = layer.max_layers()
    local rgn = mixin.FCMMusicRegion()
    rgn:SetRegion(src_rgn)
    local first_slot = rgn.StartSlot
    local first_layer, num_layers, layer_active = 0, 0, {}
    for layer_num = 1, max do
        if simple_note_count(rgn, layer_num) > 0 then
            num_layers = num_layers + 1
            layer_active[layer_num] = true
            if (first_layer == 0) then first_layer = layer_num end
        end
    end
    if num_layers < 2 then show_error("not_enough_layers") return end
    if not_enough_staves(first_slot, num_layers) then return end
    if not explode_from_layers_dialog() then return end -- user cancelled

        local function clear_other_layers(layer_num)
            for i = 1, max do
                if i ~= layer_num and layer_active[i] then
                    layer.clear(rgn, i)
                end
            end
            local n = config.from_layers_destination
            if n > 0 and n ~= layer_num then layer.swap(rgn, layer_num, n) end
        end

    local destination_is_empty = true
    for slot = 2, num_layers do -- check destination staves
        rgn:SetStartSlot(first_slot + slot - 1):SetEndSlot(first_slot + slot - 1)
        for entry in eachentry(rgn) do
            if entry.Count > 0 then destination_is_empty = false break end
        end
    end
    if destination_is_empty or should_overwrite_existing_music() then
        local slot_count = first_slot
        rgn:SetStartSlot(slot_count):SetEndSlot(slot_count):CopyMusic()
        for layer_num = 1, max do
            if layer_num ~= first_layer and layer_active[layer_num] then
                slot_count = slot_count + 1
                rgn:SetStartSlot(slot_count):SetEndSlot(slot_count):PasteMusic()
                clear_other_layers(layer_num)
                clef.restore_default_clef(rgn.StartMeasure, rgn.EndMeasure, rgn.StartStaff)
            end
        end
        rgn:ReleaseMusic()
        rgn:SetStartSlot(first_slot):SetEndSlot(first_slot)
        clear_other_layers(first_layer)
    end
    rgn:SetInDocument()
end

-- primary explosion subroutines...
local function delete_redundant_notes(rgn, slot, staff_count)
    local from_top, from_bottom = slot - 1, 0
    for entry in eachentrysaved(rgn) do
        if entry:IsNote() then -- ignore rests
            if action == "split" then -- split pairs
                local index = 1
                for note in eachbackwards(entry) do -- (top-down scan)
                    if index ~= slot and index ~= (slot + staff_count) then -- want this one?
                        note_entry.delete_note(note)
                    end
                    index = index + 1
                end
            else -- singles / pairs / pairs_up
                if action == "singles" then
                    from_bottom = entry.Count - slot -- delete how many from the bottom?
                elseif action == "pairs_up" then -- strip missing notes from top staff, not bottom
                    from_bottom = (staff_count - slot) * 2
                    from_top = entry.Count - from_bottom - 2
                else -- "pairs"
                    from_bottom = entry.Count - (slot * 2) -- how many from the bottom?
                    from_top = (slot - 1) * 2 -- how many from the top?
                end
                for _ = 1, from_top do -- delete tops
                    local high = entry:CalcHighestNote(nil)
                    if high then note_entry.delete_note(high) end
                end
                for _ = 1, from_bottom do -- delete bottoms
                    local low = entry:CalcLowestNote(nil)
                    if low then note_entry.delete_note(low) end
                end
            end
        end
    end
end

local function staff_explode()
    configuration.get_user_settings(script_name, config, true)
    local rgn = mixin.FCMMusicRegion()
    rgn:SetCurrentSelection()
    local staff_count = get_note_count(rgn)
    if staff_count <= 0 then return end -- error already informed

    if action == "to_layer" then
        explode_to_layers(rgn)
        return -- all done
    end
    if rgn:CalcStaffSpan() > 1 then
        return show_error("only_one_staff") -- everything else needs single staff
    end
    if action == "from_layer" then
        explode_from_layers(rgn)
        return -- all done
    end
    local start_slot = rgn.StartSlot
    if action ~= "singles" then -- half as many staves needed
        staff_count = math.floor((staff_count / 2) + 0.5) -- allow for odd number of notes
    end
    if not_enough_staves(start_slot, staff_count) then return end

    local destination_is_empty = true
    for slot = 2, staff_count do -- check destination staves
        rgn:SetStartSlot(start_slot + slot - 1):SetEndSlot(start_slot + slot - 1)
        for entry in eachentry(rgn) do
            if entry.Count > 0 then
                destination_is_empty = false
                break
            end
        end
    end

    if destination_is_empty or should_overwrite_existing_music() then
        rgn:SetStartSlot(start_slot):SetEndSlot(start_slot):CopyMusic()
        for slot = 2, staff_count do
            rgn:SetStartSlot(start_slot + slot - 1):SetEndSlot(start_slot + slot - 1)
            rgn:PasteMusic() -- paste the copied source music
            clef.restore_default_clef(rgn.StartMeasure, rgn.EndMeasure, rgn.StartStaff)
            delete_redundant_notes(rgn, slot, staff_count)
        end
        rgn:ReleaseMusic() -- finished with this copy
        -- back to top staff
        rgn:SetStartSlot(start_slot):SetEndSlot(start_slot)
        delete_redundant_notes(rgn, 1, staff_count)
    end
    rgn:SetInDocument() -- return to original selection
end

staff_explode()
