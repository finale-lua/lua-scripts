-- NOTE: in this info string each " \n" will be replaced with " " in the "?" dialog info button.
local info = [[
This is a keyboard-based alternative to Robert Patterson's "Finale lua menu organizer" script 
to help Finale Lua users navigate the many scripts crowding their RGP Lua menu.

The principle of Hotkey Palettes to enhance Finale productivity is 
demonstrated expertly by Nick Mazuk at [https://www.youtube.com/@nickmazuk]. 
Group script types into primary categories like "Intervals", "Layers", 
"Notes & Chords", "Measure Items" and so on, presented as "palettes" (dialog windows). 
These primary palettes are triggered by single keystrokes which each evoke a second 
palette containg related scripts, also triggered by keystroke. 
Reach hundreds of scripts in your collection using 
two keystrokes with the key codes presented as a visual reminder. 
Actions you repeat often link to muscle memory and become easier to recall.

Nick uses Keyboard Maestro [keyboardmaestro.com] on Mac to achieve this, 
but the principle is available for free in Finale with RGP Lua. 
It doesn't provide access to every single menu item nor interact with them like KM can, 
but it does remember the last selection in each category and can be set up 
within the program without external software or tricky configuration files.

The script comes loaded with a full set of "demo" palettes containing many of the 
scripts available at [https://FinaleLua.com]. 
If a script isn't installed on your system you will get an "unidentified" warning on execution. 
Either delete the palette item or assign a different script in its place. 
Reconfigure each of the "Main" palettes, change their name or hotkey, delete them or add new ones.

Unlike Keyboard Maestro this script can only trigger Lua scripts added to the "RGP Lua" menu. 
Other inbuilt Finale menus need a different mechanism. 
Note that these three characters are reserved and can't be used in hotkey codes 
or names of palettes and scripts:
`    ^    |
]]

function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.30"
    finaleplugin.Date = "2023/06/02"
    finaleplugin.CategoryTags = "Menu, Utilities"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = info
    return "Hotkey Script Palettes...", "Hotkey Script Palettes", "Trigger RGP Lua scripts by keystroke through a configurable set of dialog windows"
end

local config = { -- this is a DEMO fully-equipped data set. Not all of these scripts may be present on the user's system.
    json = [[ [{"key":"A","name":"Automations","last":1,"sub":[{"name":"Hairpin Crescendo","script":"Hairpin Create Crescendo","key":"Z"},{"name":"Hairpin Diminuendo","script":"Hairpin Create Diminuendo","key":"X"},{"name":"Hairpin Swell","script":"Hairpin Create Swell","key":"C"},{"name":"Hairpin Unswell","script":"Hairpin Create Unswell","key":"V"},{"name":"Harp gliss","script":"Harp gliss","key":"H"},{"name":"Slur Selection","script":"Slur Selection","key":"S"},{"name":"Swap Staves","script":"Swap Staves","key":"P"}]},{"key":"C","name":"Chords & Notes","last":"1","sub":[{"name":"Chords - Delete Bottom Note","script":"Chord Line - Delete Bottom Note","key":"5"},{"name":"Chords - Delete Top Note","script":"Chord Line - Delete Top Note","key":"6"},{"name":"Chords - Keep Bottom Note","script":"Chord Line - Keep Bottom Note","key":"8"},{"name":"Chords - Keep Top Note","script":"Chord Line - Keep Top Note","key":"9"},{"name":"CrossStaff Offset","script":"CrossStaff Offset...","key":"1"},{"name":"Cue notes mute","script":"Cue notes mute","key":"M"},{"name":"Gracenote Slash","script":"Gracenote Slash","key":"\/"},{"name":"Gracenote Slash Config","script":"Gracenote Slash Configuration...","key":"."},{"name":"Note Ends Eighths","script":"Note Ends Eighths","key":"E"},{"name":"Note Ends Quarters","script":"Note Ends Quarters","key":"Q"},{"name":"Noteheads Change","script":"Noteheads Change by Layer...","key":"A"},{"name":"Rest Offsets","script":"Rest Offsets","key":"4"},{"name":"Rotate Chord Down","script":"Rotate Chord Down","key":"2"},{"name":"Rotate Chord Up","script":"Rotate Chord Up","key":"3"},{"name":"Secondary Beams Break","script":"Break Secondary Beams","key":"B"},{"name":"Secondary Beams Clear","script":"Clear Secondary Beam Breaks","key":"J"},{"name":"Tie Notes","script":"Tie Notes","key":"T"},{"name":"Ties Remove","script":"Untie Notes","key":"G"},{"name":"Ties: Remove Dangling","script":"Ties: Remove Dangling","key":"K"}]},{"key":"E","name":"Expressions & misc.","last":1,"sub":[{"name":"Cluster - Determinate","script":"Cluster - Determinate","key":"D"},{"name":"Cluster - Indeterminate","script":"Cluster - Indeterminate","key":"I"},{"name":"Deletion Chooser...","script":"Deletion Chooser...","key":"X"},{"name":"Expression Add Opaque Background","script":"Expression Add Opaque Background","key":"O"},{"name":"Expression Set To Parts Only","script":"Expression Set To Parts Only","key":"P"},{"name":"Expression Set To Score and Parts","script":"Expression Set To Score and Parts","key":"B"},{"name":"Swap Staves","script":"Swap Staves","key":"S"},{"name":"Tempo From Beginning","script":"Tempo From Beginning","key":"A"},{"name":"Tuplet State Chooser...","script":"Tuplet State Chooser...","key":"T"}]},{"key":"W","name":"Intervals","last":"1","sub":[{"name":"Double Octave Down","script":"Double Octave Down","key":"8"},{"name":"Double Octave Up","script":"Double Octave Up","key":"9"},{"name":"Double Third Down","script":"Double Third Down","key":"2"},{"name":"Double Third Up","script":"Double Third Up","key":"3"},{"name":"Enharmonic Transpose Down","script":"Enharmonic Transpose Down","key":"5"},{"name":"Enharmonic Transpose Up","script":"Enharmonic Transpose Up","key":"6"},{"name":"Explode Layers","script":"Staff Explode Layers","key":"S"},{"name":"Explode Pairs","script":"Staff Explode Pairs","key":"W"},{"name":"Explode Pairs (Up)","script":"Staff Explode Pairs (Up)","key":"D"},{"name":"Explode Singles","script":"Staff Explode Singles","key":"Q"},{"name":"Explode Split Pairs","script":"Staff Explode Split Pairs","key":"E"},{"name":"String Harmonics 4th - Sounding Pitch","script":"String Harmonics 4th - Sounding Pitch","key":"F"},{"name":"Transpose By Steps...","script":"Transpose By Steps...","key":"B"},{"name":"Transpose Chromatic...","script":"Transpose Chromatic...","key":"C"}]},{"key":"Q","name":"Layers etc.","last":"1","sub":[{"name":"Clear Layer Selective","script":"Clear Layer Selective","key":"3"},{"name":"Layer Hide","script":"Layer Hide","key":"8"},{"name":"Layer Mute","script":"Layer Mute","key":"5"},{"name":"Layer Unhide","script":"Layer Unhide","key":"9"},{"name":"Layer Unmute","script":"Layer Unmute","key":"6"},{"name":"MIDI Note Duration...","script":"MIDI Note Duration...","key":"D"},{"name":"MIDI Note Values...","script":"MIDI Note Values...","key":"W"},{"name":"MIDI Note Velocity...","script":"MIDI Note Velocity...","key":"V"},{"name":"Swap Layers 1-2","script":"Swap Layers 1-2","key":"1"},{"name":"Swap Layers Selective","script":"Swap Layers Selective","key":"2"}]},{"key":"B","name":"Measure Items","last":1,"sub":[{"name":"Barline Dashed","script":"Barline Set Dashed","key":"A"},{"name":"Barline Double","script":"Barline Set Double","key":"D"},{"name":"Barline Final","script":"Barline Set Final","key":"E"},{"name":"Barline None","script":"Barline Set None","key":"0"},{"name":"Barline Normal","script":"Barline Set Normal","key":"N"},{"name":"Cue Notes Create...","script":"Cue Notes Create...","key":"Q"},{"name":"Cue Notes Flip Frozen","script":"Cue Notes Flip Frozen","key":"Z"},{"name":"Measure Span Divide","script":"Measure Span Divide","key":"H"},{"name":"Measure Span Join","script":"Measure Span Join","key":"J"},{"name":"Measure Span Options...","script":"Measure Span Options...","key":"B"},{"name":"Meter Set Numeric","script":"Meter Set Numeric","key":"9"},{"name":"Rename Staves","script":"Rename Staves","key":"R"},{"name":"Widen Staff Spaces","script":"Widen Staff Space","key":"W"}]}] ]],
    last_palette = 1,
    ignore_duplicates = 0,
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local cjson = require("cjson")
local script_array = {} -- assemble all script items from the RGPLua menu
local script_name = "hotkey_script_palettes"

local palettes = {}
--[[ ordered set of "main" palettes encapsulating sub-palettes
{   {   name = "Macro Palette 1",
        key = "A",
        last = 1, -- item number of last script in this palette
        sub =
        {   {   name = "script 1A", key = "A", script = "script_name_1A" },
            {   name = "script 1B", key = "B", script = "script_name_1B" },
             ... etc
        }
    },
    {   name = "Macro Palette 2"
        key = "B",
        last = 1, -- item number of last script chosen within this palette
        sub =
        {   {   name = "script 2A", key = "A", script = "script_name_2A" },
            {   name = "script 2B", key = "B", script = "script_name_2B" },
             ... etc
        }
    }, etc etc...
} -- ]]

function clean_text(input) -- remove reserved "divider" characters from text values
    return string.gsub(input, "[`|^]", "")
end

function clean_key(input) -- return one clean uppercase character
    local key = string.upper(string.sub(clean_text(input), 1, 1))
    if key == "" then key = "?" end -- no NULL key codes
    return key
end

function decode_config_to_palettes()
    palettes = cjson.decode(config.json)
end

function encode_palettes_to_config()
    config.json = cjson.encode(palettes)
    configuration.save_user_settings(script_name, config)
end

function sort_table(array)
    table.sort(array, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
end

function dialog_set_position(dialog)
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
end

function dialog_save_position(dialog)
    dialog:StorePosition()
    config.window_pos_x = dialog.StoredX
    config.window_pos_y = dialog.StoredY
    configuration.save_user_settings(script_name, config)
end

function reassign_keys(palette_number)
    local is_macro = (palette_number == 0)
    local y, y_step, x_wide =  0, 17, 220
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local is_duplicate, errors = false, {}
    local title = is_macro and "Palette" or "Script"
    local array = is_macro and palettes or palettes[palette_number].sub

    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Reassign " .. title .. " Keys")
    if not is_macro then
        dialog:CreateStatic(0, y):SetWidth(x_wide)
            :SetText("Palette Name: " .. palettes[palette_number].name)
        y = y + y_step
    end
    dialog:CreateStatic(0, y):SetText("Key"):SetWidth(x_wide)
    dialog:CreateStatic(30, y):SetText(title):SetWidth(x_wide)
    y = y + y_step + 5
    for i, v in ipairs(array) do -- add all options with keycodes
        dialog:CreateEdit(0, y - offset, v.name):SetText(v.key):SetWidth(20)
        dialog:CreateStatic(30, y):SetText(v.name):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(array) do
            local key = clean_key(self:GetControl(v.name):GetText())
            array[i].key = key -- save for another possible run-through
            config.ignore_duplicates = ignore:GetCheck()
            if config.ignore_duplicates == 0 then -- DON'T IGNORE duplicates
                if assigned[key] then -- previously assigned
                    is_duplicate = true
                    if not errors[key] then errors[key] = { assigned[key] } end
                    table.insert(errors[key], i)
                else
                    assigned[key] = i -- flag new key assigned
                end
            end
        end
        if is_duplicate then -- list reassignment duplication errors
            local msg = ""
            for k, v in pairs(errors) do
                msg = msg .. "Key \"" .. k .. "\" is assigned to: "
                for i, w in ipairs(v) do
                    if i > 1 then msg = msg .. " and " end
                    msg = msg .. "\"" .. array[w].name .. "\""
                end
                msg = msg .. "\n\n"
            end
            finenv.UI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

function user_enters_text(index, title, header)
    local x_wide = 220
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(title)
    dialog:CreateStatic(0, 0):SetText(header):SetWidth(x_wide)
    local text = (index > 0) and palettes[index].name or ""
    local answer = dialog:CreateEdit(0, 20):SetText(text):SetWidth(x_wide)

    dialog:CreateStatic(0, 46):SetText("Trigger Key:"):SetWidth(x_wide)
    text = (index > 0) and palettes[index].key or "A"
    local key_edit = dialog:CreateEdit(68, 46 - offset):SetText(text):SetWidth(25)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, clean_text(answer:GetText()), clean_key(key_edit:GetText())
end

function user_chooses_script(index, palette_number, instruction)
    local x_wide = 220
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local sub = palettes[palette_number].sub
    local old_menu = sub[index] or { name = "", script = "", key = "?" }
    local assigned, script_names = {}, {}
    for _, v in ipairs(sub) do
        assigned[v.script] = true
    end
    for k, _ in pairs(script_array) do
        if not assigned[k] or (old_menu.script == k) then
            table.insert(script_names, k)
        end
    end
    table.sort(script_names)
    --
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Configure Script Item")
    dialog:CreateStatic(0, 0):SetText(instruction):SetWidth(x_wide)
    local menu = dialog:CreatePopup(0, 20):SetWidth(x_wide)
    local selected = 1
    for i, v in ipairs(script_names) do
        menu:AddString(v)
        if v == old_menu.script then
            menu:SetSelectedItem(i - 1)
            selected = i
        end
    end
    dialog:CreateStatic(0, 44):SetText("Name for Listing:"):SetWidth(x_wide)
    local list_name = dialog:CreateEdit(0, 66 - offset):SetText(old_menu.name):SetWidth(x_wide)
    dialog:CreateStatic(0, 90):SetText("Trigger Key:"):SetWidth(x_wide)
    local key_edit = dialog:CreateEdit(70, 90 - offset):SetText(old_menu.key):SetWidth(25)
    menu:AddHandleCommand(function()
        local new = menu:GetSelectedItem() + 1
        if new ~= selected then
            list_name:SetText(script_names[new])
            selected = new
        end
    end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local menu_name = script_names[menu:GetSelectedItem() + 1]
    return ok, clean_text(list_name:GetText()), clean_text(menu_name), clean_key(key_edit:GetText())
end

function fill_list_box(menu, array, selected)
    menu:Clear()
    local join = finenv.UI():IsOnMac() and "\t" or ": "
    for _, v in ipairs(array) do
        menu:AddString(v.key .. join .. v.name)
    end
    menu:SetSelectedItem(selected - 1)
end

function configure_palette(palette_number, index_num)
    local y, y_step, x_wide =  0, 17, 228
    local is_macro = (palette_number == 0)

    local array = is_macro and palettes or palettes[palette_number].sub
    local box_high = (#array * y_step) + 5
    text = is_macro and "Configure Palettes" or "Configure Scripts"
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(text)
    if not is_macro then
        dialog:CreateStatic(0, y):SetWidth(x_wide)
            :SetText("Palette Name: " .. palettes[palette_number].name)
        y = y + y_step
    end
    local text = is_macro and "Choose Palette:" or "Choose Script Item:"
    dialog:CreateStatic(0, y):SetText(text):SetWidth(x_wide)
    y = y + y_step + 5
    local menu = dialog:CreateListBox(0, y):SetWidth(x_wide):SetHeight(box_high)
    fill_list_box(menu, array, index_num)

    y = y + box_high + 8
    local x_off = x_wide / 20
    local remove = dialog:CreateButton(0, y, "remove")
        :SetText("Remove"):SetWidth(x_off * 9) -- half box width
    text = is_macro and "Change Name" or "Change/Rename"
    local rename = dialog:CreateButton(x_off * 11, y, "rename")
        :SetText(text):SetWidth(x_off * 9)

    y = y + y_step + 5
    local reassign = dialog:CreateButton(0, y, "reassign")
        :SetText("Reassign Keys"):SetWidth(x_off * 9)
    text = is_macro and "New Palette" or "Add Script"
    local add = dialog:CreateButton(x_off * 11, y, "add")
        :SetText(text):SetWidth(x_off * 9) -- half box width

    remove:AddHandleCommand(function()
        local index = menu:GetSelectedItem() + 1
        table.remove(array, index)
        fill_list_box(menu, array, 1)
    end)
    rename:AddHandleCommand(function()
        local index = menu:GetSelectedItem() + 1
        local ok, new_name, new_script, trigger
        if is_macro then
            ok, new_name, trigger = user_enters_text(index, "Rename Palette", "New Palette Name:")
        else
            ok, new_name, new_script, trigger = user_chooses_script(index, palette_number, "Change Script To:")
        end
        if ok then
            array[index].name = new_name
            array[index].key  = trigger
            if not is_macro then array[index].script = new_script end
            sort_table(array)
            fill_list_box(menu, array, index)
        end

    end)
    reassign:AddHandleCommand(function()
        local ok, is_duplicate = true, true
        while ok and is_duplicate do -- wait for valid choices in reassign_keys()
            ok, is_duplicate = reassign_keys(palette_number)
        end
        if ok then
            fill_list_box(menu, array, #array)
        else -- restore previously saved choices
            configuration.get_user_settings(script_name, config, true)
        end
    end)
    add:AddHandleCommand(function()
        local new_name, new_script, trigger
        local new_element, ok = {}, false
        if is_macro then
            ok, new_name, trigger = user_enters_text(0, "Create New Palette", "Name the New Palette:")
            if ok then
                new_element = {
                    name = new_name, key = trigger, last = 1,
                    sub = { { name = "(script unassigned)", key = "?", script = "unassigned" } } }
            end
        else -- SCRIPT palette
            ok, new_name, new_script, trigger = user_chooses_script(0, palette_number, "Add New Script:")
            if ok then
                new_element = { name = new_name, key = trigger, script = new_script }
            end
        end
        if ok then
            table.insert(array, new_element)
            sort_table(array)
            fill_list_box(menu, array, #array)
        end
    end)
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleCancelButtonPressed(function()
        configuration.get_user_settings(script_name, config)
        decode_config_to_palettes()
    end)
    dialog:RegisterHandleOkButtonPressed(function() encode_palettes_to_config() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function choose_palette(palette_number)
    local y, y_step = 0, 17
    local is_macro = (palette_number == 0)
    local array = is_macro and palettes or palettes[palette_number].sub
    local box_wide = 228
    local box_high = (#array * y_step) + 5
    local selected = is_macro and config.last_palette or palettes[palette_number].last

    local text = "Hotkey Script Palettes"
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(text)
    dialog:CreateButton(box_wide - 20, 0):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(info:gsub(" \n", " "), "Hotkey Script Palettes") end)
    if not is_macro then
        dialog:CreateStatic(0, y):SetText("Palette: " .. palettes[palette_number].name):SetWidth(box_wide * .9)
        y = y + y_step
    end
    text = is_macro and "Choose Palette:" or "Activate Script:"
    dialog:CreateStatic(0, y):SetText(text):SetWidth(box_wide * .9)
    y = y + y_step + 5
    local item_list = dialog:CreateListBox(0, y):SetWidth(box_wide):SetHeight(box_high)
    fill_list_box(item_list, array, selected)
    item_list:SetKeyboardFocus()

    local x_off = box_wide / 4
    y = y + box_high + 8
    text = is_macro and "Configure Palettes" or "Configure Scripts"
    local reconfigure = dialog:CreateButton(x_off, y, "reconfigure")
        :SetText(text):SetWidth(x_off * 2)
    reconfigure:AddHandleCommand(function()
        local index_num = item_list:GetSelectedItem() + 1
        if configure_palette(palette_number, index_num) then
            fill_list_box(item_list, array, index_num)
        end
    end)
    text = is_macro and "Choose" or "Activate"
    dialog:CreateOkButton():SetText(text)
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        local i = item_list:GetSelectedItem() + 1
        if is_macro then
            config.last_palette = i
        else
            palettes[palette_number].last = i
        end
        encode_palettes_to_config()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, (item_list:GetSelectedItem() + 1)
end

function main()
    local scripts = finenv.CreateLuaScriptItems()
    for i = 1, scripts.Count do
        local script = scripts:GetItemAt(i - 1)
        script_array[script:GetMenuItemText()] = script
    end
    configuration.get_user_settings(script_name, config, true)
    decode_config_to_palettes()
    local ok, finished = false, false
    local palette_number, item_number = 1, 1

    while not finished do -- keep circling until user makes a choice or cancels
        ok, palette_number = choose_palette(0) -- main palette
        if not ok then return end -- user cancelled

        finished, item_number = choose_palette(palette_number) -- script palette
        if finished then -- successful choice
            local script = palettes[palette_number].sub[item_number].script or "unknown"
            if not script_array[script] then
                finenv.UI():AlertError("Script menu \"" .. script .. "\" could not be identified", "Error")
            else
                finenv.ExecuteLuaScriptItem(script_array[script])
            end
            finenv.UI():ActivateDocumentWindow()
        end -- "finished" will exit now
    end
end

main()
