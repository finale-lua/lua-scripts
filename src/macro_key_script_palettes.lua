local info = [[
This is a keyboard-based alternative to Robert Patterson's "Finale lua menu organizer" script 
to help Finale Lua users navigate the many scripts crowding their RGP Lua menu.

The principle of Macro Key Palettes to enhance Finale productivity is 
demonstrated expertly by Nick Mazuk at [https://www.youtube.com/@nickmazuk]. 
Collate script activity into primary categories like "Intervals", "Layers", 
"Notes & Chords", "Measure Items" and so on, grouped as "palettes" (dialog windows). 
These primary palettes are triggered by single keystrokes which each evoke a second 
palette containg 10 to 20 related scripts, also triggered by keystroke. 
This way you can reach hundreds of scripts in your collection using 
two keystrokes with the key codes presented as a visual reminder. 
Actions you repeat often lock to muscle memory and become easier to recall.

Nick uses Keyboard Maestro [keyboardmaestro.com] on Mac to achieve this, 
but the principle is available for free in Finale with RGP Lua. 
It can't provide access to every single menu item nor interact with them like KM can, 
but it does remember your last selection in each category and can be set up easily 
within the program without external software or creating configuration files.

The script comes loaded with a full set of "demo" palettes containing many of the 
scripts available at [https://FinaleLua.com]. 
If a script isn't installed on your system you will get an "unidentified" warning on execution. 
Either delete the script or assign a different one in its place. 
Reconfigure each of the "Main" palettes, change their name or trigger key, delete them or add new ones.

Unlike Keyboard Maestro this system can only trigger Lua script menu items added to the "RGP Lua" menu. 
Other inbuilt Finale menus require a different mechanism and not all are available to Lua. 
Note that these three characters are reserved and can't be used in key codes, 
palette names or script names:
`    ^    |
]]

function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.23"
    finaleplugin.Date = "2023/05/30"
    finaleplugin.CategoryTags = "Menu, Utilities"
    finaleplugin.MinJWLuaVersion = 0.64
    finaleplugin.Notes = info
    return "Macro Key Script Palettes...", "Macro Key Script Palettes", "Trigger RGP Lua scripts by keystroke through a configurable set of dialog windows"
end

local config = { -- this is a DEMO fully-equipped data set. Not all of these scripts may be present on the user's system.
    main = "Automations`A`1^Chords & Notes`C`1^Expressions & misc.`E`1^Intervals`W`1^Layers etc.4`Q`1^Measure Items`B`1^",
    sub = "Hairpin Create Crescendo`A^Hairpin Create Diminuendo`X^Hairpin Create Swell`C^Hairpin Create Unswell`V^Harp gliss`H^Slur Selection`S^Swap Staves`P^|Break Secondary Beams`B^Chord Line - Delete Bottom Note`5^Chord Line - Delete Top Note`6^Chord Line - Keep Bottom Note`8^Chord Line - Keep Top Note`9^Clear Secondary Beam Breaks`J^CrossStaff Offset...`1^Cue notes mute`M^Gracenote Slash`/^Gracenote Slash Configuration...`.^Note Ends Eighths`E^Note Ends Quarters`Q^Noteheads Change by Layer...`A^Rest Offsets`4^Rotate Chord Down`2^Rotate Chord Up`3^Tie Notes`T^Ties: Remove Dangling`K^Untie Notes`G^|Cluster - Determinate`D^Cluster - Indeterminate`I^Deletion Chooser...`X^Expression Add Opaque Background`O^Expression Set To Parts Only`P^Expression Set To Score and Parts`B^Swap Staves`S^Tempo From Beginning`A^Tuplet State Chooser...`T^|Double Octave Down`8^Double Octave Up`9^Double Third Down`2^Double Third Up`3^Enharmonic Transpose Down`5^Enharmonic Transpose Up`6^Staff Explode Layers`S^Staff Explode Pairs`W^Staff Explode Pairs (Up)`D^Staff Explode Singles`Q^Staff Explode Split Pairs`E^String Harmonics 4th - Sounding Pitch`F^Transpose By Steps...`B^Transpose Chromatic...`C^|Clear Layer Selective`3^Layer Hide`8^Layer Mute`5^Layer Unhide`9^Layer Unmute`6^MIDI Note Duration...`D^MIDI Note Values...`W^MIDI Note Velocity...`V^Swap Layers 1-2`1^Swap Layers Selective`2^|Barline Set Dashed`A^Barline Set Double`D^Barline Set Final`E^Barline Set None`0^Barline Set Normal`N^Cue Notes Create...`Q^Cue Notes Flip Frozen`Z^Measure Span Divide`H^Measure Span Join`J^Measure Span Options...`B^Meter Set Numeric`9^Rename Staves`R^Widen Staff Space`W^|",
    last_palette = 1,
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local script_array = {} -- assemble all script items from the RGPLua menu
local script_name = "macro_key_script_palettes"

local palettes = { -- config values decoded into nested tables
--[[ ordered set of "main" palettes encapsulating sub-palettes
    {   name = "Macro Palette 1",
        key = "A",
        last = 1, -- item number of last script in this palette
        sub =
        {   {   name = "script 1A", key = "A" },
            {   name = "script 1B", key = "B" },
             ... etc
        }
    },
    {   name = "Macro Palette 2"
        key = "B",
        last = 1, -- item number of last script chosen within this palette
        sub =
        {   {   name = "script 2A", key = "A" },
            {   name = "script 2B", key = "B" },
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
        or  { name = split[1], key = split[2]}
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
            sub = sub .. w.name .. "`" .. w.key .. "^"
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
        dialog:CreateStatic(0, y):SetText("Palette Name: " .. palettes[palette_number].name):SetWidth(x_wide)
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
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore or 0)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function(self)
        local assigned = {}
        for i, v in ipairs(array) do
            local key = clean_key(self:GetControl(v.name):GetText())
            array[i].key = key -- save for another possible run-through
            config.ignore = ignore:GetCheck()
            if config.ignore == 0 then -- DON'T IGNORE duplicates
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
    local old_menu, old_menu_name = nil, ""
    if index > 0 then
        old_menu = palettes[palette_number].sub[index] or nil
        if old_menu then old_menu_name = old_menu.name end
    end
    local assigned, script_names = {}, {}
    for _, v in ipairs(palettes[palette_number].sub) do
        assigned[v.name] = true
    end
    for k, _ in pairs(script_array) do
        if not assigned[k] or (old_menu_name == k) then
            table.insert(script_names, k)
        end
    end
    table.sort(script_names)
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Configure Script Item")
    dialog:CreateStatic(0, 0):SetText(instruction):SetWidth(x_wide)
    local menu = dialog:CreatePopup(0, 20, "menu"):SetWidth(x_wide)
    local selected = 0
    for i, v in ipairs(script_names) do
        menu:AddString(v)
        if v == old_menu_name then selected = i end
    end
    if selected > 0 then menu:SetSelectedItem(selected - 1) end
    dialog:CreateStatic(0, 46):SetText("Trigger Key:"):SetWidth(x_wide)
    text = old_menu and old_menu.key or "A"
    local key_edit = dialog:CreateEdit(68, 46 - offset):SetText(text):SetWidth(25)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local menu_name = script_names[menu:GetSelectedItem() + 1]
    return ok, clean_text(menu_name), clean_key(key_edit:GetText())
end

function fill_list_box(menu, array, selected)
    menu:Clear()
    for _, v in ipairs(array) do
        menu:AddString(v.key .. "\t" .. v.name)
    end
    menu:SetSelectedItem(selected - 1)
end

function configure_palette(palette_number)
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
    fill_list_box(menu, array, 1)

    y = y + box_high + 8
    local x_off = x_wide / 20
    local remove = dialog:CreateButton(0, y, "remove")
        :SetText("Remove"):SetWidth(x_off * 9) -- half box width
    text = is_macro and "Change Name" or "Change Script"
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
        local ok, new_name, trigger
        if is_macro then
            ok, new_name, trigger = user_enters_text(index, "Rename Palette", "New Palette Name:")
        else
            ok, new_name, trigger = user_chooses_script(index, palette_number, "Choose New Script:")
        end
        if ok then
            array[index].name = new_name
            array[index].key  = trigger
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
        local ok, new_name, trigger
        if is_macro then
            ok, new_name, trigger = user_enters_text(0, "Create New Palette", "Name the New Palette:")
            if ok then
                table.insert(array,
                {   name = new_name, key = trigger, last = 1,
                    sub = { { name = "(script unassigned)", key = "?" } }
                })
                sort_table(array)
                fill_list_box(menu, array, #array)
            end
        else -- SCRIPT palette
            ok, new_name, trigger = user_chooses_script(palette_number, palette_number, "Add New Script:")
            if ok then
                table.insert(array, { name = new_name, key = trigger } )
                sort_table(array)
                fill_list_box(menu, array, #array)
            end
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

    local text = is_macro and "Palettes" or "Scripts"
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Macro Key " .. text)
    dialog:CreateButton(box_wide - 20, 0):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(info:gsub(" \n", " "), "Macro Key Script Palettes") end)
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
        if configure_palette(palette_number) then
            fill_list_box(item_list, array, selected)
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
            local item_name = palettes[palette_number].sub[item_number].name or "unknown"
            local msg = ""
            if not script_array[item_name] then
                msg = "identified"
            elseif not finenv.ExecuteLuaScriptItem(script_array[item_name]) then
                msg = "opened"
            end
            if msg ~= "" then
                finenv.UI():AlertError("Script menu \"" .. item_name .. "\" could not be " .. msg, "Error")
                finished = false -- try again
            end
        end -- "finished" true will exit now
    end
end

main()
