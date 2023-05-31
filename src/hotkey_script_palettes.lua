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
This way you can reach hundreds of scripts in your collection using 
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
Reconfigure each of the "Main" palettes, change their name or trigger key, delete them or add new ones.

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
    finaleplugin.Version = "0.27"
    finaleplugin.Date = "2023/06/01"
    finaleplugin.CategoryTags = "Menu, Utilities"
    finaleplugin.MinJWLuaVersion = 0.64
    finaleplugin.Notes = info
    return "Hotkey Script Palettes...", "Hotkey Script Palettes", "Trigger RGP Lua scripts by keystroke through a configurable set of dialog windows"
end

local config = { -- this is a DEMO fully-equipped data set. Not all of these scripts may be present on the user's system.
    main = "Automations`A`1^Chords & Notes`C`1^Expressions & misc.`E`1^Intervals`W`1^Layers etc.`Q`1^Measure Items`B`1^",
    sub = "Hairpin Crescendo`Z`Hairpin Create Crescendo^Hairpin Diminuendo`X`Hairpin Create Diminuendo^Hairpin Swell`C`Hairpin Create Swell^Hairpin Unswell`V`Hairpin Create Unswell^Harp gliss`H`Harp gliss^Slur Selection`S`Slur Selection^Swap Staves`P`Swap Staves^|Chords - Delete Bottom Note`5`Chord Line - Delete Bottom Note^Chords - Delete Top Note`6`Chord Line - Delete Top Note^Chords - Keep Bottom Note`8`Chord Line - Keep Bottom Note^Chords - Keep Top Note`9`Chord Line - Keep Top Note^CrossStaff Offset`1`CrossStaff Offset...^Cue notes mute`M`Cue notes mute^Gracenote Slash`/`Gracenote Slash^Gracenote Slash Config`.`Gracenote Slash Configuration...^Note Ends Eighths`E`Note Ends Eighths^Note Ends Quarters`Q`Note Ends Quarters^Noteheads Change`A`Noteheads Change by Layer...^Rest Offsets`4`Rest Offsets^Rotate Chord Down`2`Rotate Chord Down^Rotate Chord Up`3`Rotate Chord Up^Secondary Beams Break`B`Break Secondary Beams^Secondary Beams Clear`J`Clear Secondary Beam Breaks^Tie Notes`T`Tie Notes^Ties Remove`G`Untie Notes^Ties: Remove Dangling`K`Ties: Remove Dangling^|Cluster - Determinate`D`Cluster - Determinate^Cluster - Indeterminate`I`Cluster - Indeterminate^Deletion Chooser...`X`Deletion Chooser...^Expression Add Opaque Background`O`Expression Add Opaque Background^Expression Set To Parts Only`P`Expression Set To Parts Only^Expression Set To Score and Parts`B`Expression Set To Score and Parts^Swap Staves`S`Swap Staves^Tempo From Beginning`A`Tempo From Beginning^Tuplet State Chooser...`T`Tuplet State Chooser...^|Double Octave Down`8`Double Octave Down^Double Octave Up`9`Double Octave Up^Double Third Down`2`Double Third Down^Double Third Up`3`Double Third Up^Enharmonic Transpose Down`5`Enharmonic Transpose Down^Enharmonic Transpose Up`6`Enharmonic Transpose Up^Explode Layers`S`Staff Explode Layers^Explode Pairs`W`Staff Explode Pairs^Explode Pairs (Up)`D`Staff Explode Pairs (Up)^Explode Singles`Q`Staff Explode Singles^Explode Split Pairs`E`Staff Explode Split Pairs^String Harmonics 4th - Sounding Pitch`F`String Harmonics 4th - Sounding Pitch^Transpose By Steps...`B`Transpose By Steps...^Transpose Chromatic...`C`Transpose Chromatic...^|Clear Layer Selective`3`Clear Layer Selective^Layer Hide`8`Layer Hide^Layer Mute`5`Layer Mute^Layer Unhide`9`Layer Unhide^Layer Unmute`6`Layer Unmute^MIDI Note Duration...`D`MIDI Note Duration...^MIDI Note Values...`W`MIDI Note Values...^MIDI Note Velocity...`V`MIDI Note Velocity...^Swap Layers 1-2`1`Swap Layers 1-2^Swap Layers Selective`2`Swap Layers Selective^|Barline Dashed`A`Barline Set Dashed^Barline Double`D`Barline Set Double^Barline Final`E`Barline Set Final^Barline None`0`Barline Set None^Barline Normal`N`Barline Set Normal^Cue Notes Create...`Q`Cue Notes Create...^Cue Notes Flip Frozen`Z`Cue Notes Flip Frozen^Measure Span Divide`H`Measure Span Divide^Measure Span Join`J`Measure Span Join^Measure Span Options...`B`Measure Span Options...^Meter Set Numeric`9`Meter Set Numeric^Rename Staves`R`Rename Staves^Widen Staff Space`W`Widen Staff Space^|",
    last_palette = 1,
    ignore_duplicates = 0,
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local script_array = {} -- assemble all script items from the RGPLua menu
local script_name = "hotkey_script_palettes"

local palettes = { -- config values decoded into nested tables
--[[ ordered set of "main" palettes encapsulating sub-palettes
    {   name = "Macro Palette 1",
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
    }, etc etc... -- ]]
}

function clean_text(input) -- remove reserved "divider" characters from text values
    return string.gsub(input, "[`|^]", "")
end

function clean_key(input) -- return one clean uppercase character
    local key = string.upper(string.sub(clean_text(input), 1, 1))
    if key == "" then key = "?" end -- no NULL key codes
    return key
end

function split_string(source, char)
    local values = {}
    for split in string.gmatch(source, "([^" .. char .. "]+)") do
        table.insert(values, split)
    end
    return values
end

function split_name_key_from_config(coded_string, is_palette)
    local output = {}
    local key_name = split_string(coded_string, "^")
    for i, v in ipairs(key_name) do
        local split = split_string(v, "`")
        output[i] = is_palette and
            { name = split[1], key = split[2], last = split[3] or 1, sub = {} }
        or  { name = split[1], key = split[2], script = split[3] }
    end
    return output
end

function decode_config_to_palettes()
    palettes = split_name_key_from_config(config.main, true)
    local sub_codes = split_string(config.sub, "|")
    for i, v in ipairs(palettes) do
        v.sub = split_name_key_from_config(sub_codes[i], false)
    end
end

function save_palettes_to_config()
    local main, sub = "", ""
    for _, v in ipairs(palettes) do
        main = main .. v.name .. "`" .. v.key .. "`" .. v.last .. "^"
        for _, w in ipairs(v.sub) do
            sub = sub .. w.name .. "`" .. w.key .. "`" .. w.script .. "^"
        end
        sub = sub .. "|"
    end
    config.main = main
    config.sub = sub
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
    dialog:RegisterHandleOkButtonPressed(function() save_palettes_to_config() end)
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
        save_palettes_to_config()
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
        end -- "finished" will exit now
    end
end

main()
