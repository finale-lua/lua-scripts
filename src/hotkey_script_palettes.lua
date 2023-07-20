function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.46"
    finaleplugin.LoadLuaOSUtils = true
    finaleplugin.Date = "2023/07/20"
    finaleplugin.CategoryTags = "Menu, Utilities"
    finaleplugin.MinJWLuaVersion = 0.67
    finaleplugin.Notes = [[This is designed to help navigate the many scripts crowding your RGP Lua menu. 
It provides access to Lua scripts and Finale menu items through a set of 
easily configurable palettes (dialog windows) organised by type of activity 
and triggerd by simple "hotkey" keystrokes.

The "Hotkey Palettes" principle is demonstrated expertly by Nick Mazuk at 
[https://www.youtube.com/@nickmazuk]. 
Scripts are grouped into primary categories like "Intervals", "Layers", 
"Notes & Chords", "Measure Items" and so on as a set of palettes triggered by keystroke. 
Primary palettes call up a second layer of palettes containg scripts in related areas, 
also triggered by keystroke. Reach hundreds of scripts in your collection using 
just two keystrokes with the actual hotkeys presented as a visual reminder. 
Actions you repeat often will link to muscle memory and become easier to recall.

Nick uses Keyboard Maestro [keyboardmaestro.com] on Mac for this, 
but the principle is available free in Finale using RGP Lua. 
It doesn't provide access to every single menu item nor interact with them like KM can, 
but it remembers the last selection in every category and can be set up 
entirely within Finale without external software or configuration files. 
Scripts that use modifier keys (shift, alt/option etc) for "alternative" behaviours 
respond to those keys when called from the palettes.

The script comes loaded with a full set of "demo" palettes containing many of the 
Lua scripts available at https://FinaleLua.com. 
If a script isn't installed on your system you will get an "unidentified" warning on execution. 
Delete those scripts and add new ones in their place. 
Reconfigure each of the "Main" palettes, change their name or hotkey, delete them or add new ones.

You can also add Finale menus to your palettes. 
Not every menu item is available, including Plug-ins that are NOT "RGP Lua", 
but when you use "Add Menu Item" you can try out the menu before saving it to a palette.
    ]]
    return "Hotkey Script Palettes...", "Hotkey Script Palettes", "Trigger RGP Lua scripts by keystroke through a configurable set of dialog windows"
end

local config = { -- this is a DEMO fully-equipped data set. Some of these scripts won't be present on the user's system.
    palettes = [[ [{"key":"A","last":1,"sub":[{"key":"Z","script":"Hairpin Create Crescendo","name":"Hairpin Crescendo"},{"key":"X","script":"Hairpin Create Diminuendo","name":"Hairpin Diminuendo"},{"key":"C","script":"Hairpin Create Swell","name":"Hairpin Swell"},{"key":"V","script":"Hairpin Create Unswell","name":"Hairpin Unswell"},{"key":"H","script":"Harp gliss","name":"Harp gliss"},{"key":"S","script":"Slur Selection","name":"Slur Selection"},{"key":"P","script":"Swap Staves","name":"Swap Staves"}],"name":"Automations"},{"key":"C","last":"1","sub":[{"key":"E","script":"Note Ends Eighths","name":"Note Ends Eighths"},{"key":"Q","script":"Note Ends Quarters","name":"Note Ends Quarters"},{"key":"A","script":"Noteheads Change by Layer...","name":"Noteheads Change"},{"key":"B","script":"Break Secondary Beams","name":"Secondary Beams Break"},{"key":"J","script":"Clear Secondary Beam Breaks","name":"Secondary Beams Clear"},{"key":"T","script":"Tie Notes","name":"Tie Notes"},{"key":"G","script":"Untie Notes","name":"Ties Remove"}],"name":"Chords & Notes"},{"key":"E","last":1,"sub":[{"key":"X","script":"Deletion Chooser...","name":"Deletion Chooser..."},{"key":"P","script":"Expression Set To Parts Only","name":"Expression Set To Parts Only"},{"key":"B","script":"Expression Set To Score and Parts","name":"Expression Set To Score and Parts"},{"key":"S","script":"Swap Staves","name":"Swap Staves"},{"key":"T","script":"Tuplet State Chooser...","name":"Tuplet State Chooser..."}],"name":"Expressions & misc."},{"key":"W","last":"1","sub":[{"key":"5","script":"Enharmonic Transpose Down","name":"Enharmonic Transpose Down"},{"key":"6","script":"Enharmonic Transpose Up","name":"Enharmonic Transpose Up"},{"key":"S","script":"Staff Explode Layers","name":"Explode Layers"},{"key":"W","script":"Staff Explode Pairs","name":"Explode Pairs"},{"key":"Q","script":"Staff Explode Singles","name":"Explode Singles"},{"key":"E","script":"Staff Explode Split Pairs","name":"Explode Split Pairs"},{"key":"C","script":"Transpose Chromatic...","name":"Transpose Chromatic..."}],"name":"Intervals"},{"key":"Q","last":"1","sub":[{"key":"3","script":"Clear Layer Selective","name":"Clear Layer Selective"},{"key":"8","script":"Layer Hide","name":"Layer Hide"},{"key":"5","script":"Layer Mute","name":"Layer Mute"},{"key":"9","script":"Layer Unhide","name":"Layer Unhide"},{"key":"6","script":"Layer Unmute","name":"Layer Unmute"},{"key":"2","script":"Swap Layers Selective","name":"Swap Layers Selective"}],"name":"Layers etc."},{"key":"B","last":1,"sub":[{"key":"D","script":"Barline Set Double","name":"Barline Double"},{"key":"E","script":"Barline Set Final","name":"Barline Final"},{"key":"0","script":"Barline Set None","name":"Barline None"},{"key":"N","script":"Barline Set Normal","name":"Barline Normal"},{"key":"Q","script":"Cue Notes Create...","name":"Cue Notes Create..."},{"key":"H","script":"Measure Span Divide","name":"Measure Span Divide"},{"key":"J","script":"Measure Span Join","name":"Measure Span Join"},{"key":"B","script":"Measure Span Options...","name":"Measure Span Options..."},{"key":"9","script":"Meter Set Numeric","name":"Meter Set Numeric"}],"name":"Measure Items"}] ]],
    last_palette = 1,
    ignore_duplicates = 0,
    -- ... the location of the last added Menu Item ...
    menu_tree = "[ ]", -- JSON-encoded table of submenu titles stacked from top to bottom
    window_pos_x = false,
    window_pos_y = false,
}

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local osutils = require("luaosutils")
local menu = osutils.menu
local utils = require("library.utils")
local cjson = utils.require_embedded("cjson")

local script_array = {} -- assemble all script items from the RGPLua menu
local script_name = "hotkey_script_palettes"

local palettes = {}
--[[ ordered set of "main" palettes encapsulating sub-palettes
-- these are cjson decoded from config.palettes in the main() routine at the bottom
{   {   name = "Macro Palette 1",
        key = "A",
        last = 1, -- number of last script chosen from this palette
        sub = -- { name displayed / hotkey / "real" scriptname returned by finenv.CreateLuaScriptItems()
        {   {   name = "script 1A", key = "A", script = "script_name_1A", (optional) menu = "menu_title_1A" },
            {   name = "script 1B", key = "B", script = "script_name_1B", (optional) menu = "menu_title_1B" },
             ... etc
        }
    },
    {   name = "Macro Palette 2"
        key = "B",
        last = 1,
        sub =
        {   {   name = "script 2A", key = "A", script = "script_name_2A", (optional) menu = "menu_title_2A" },
            {   name = "script 2B", key = "B", script = "script_name_2B", (optional) menu = "menu_title_2B" },
             ... etc
        }
    }, etc etc...
} -- ]]

function clean_key(input) -- return one clean uppercase character
    local key = string.upper(string.sub(input, 1, 1))
    if key == "" then key = "?" end -- non-NULL hotkey
    return key
end

function sort_table(array, match_text, match_type)
    table.sort(array, function(a, b) return string.lower(a.name) < string.lower(b.name) end)
    local index = 1
    for i, v in ipairs(array) do
        if v[match_type] == match_text then
            index = i
            break
        end
    end
    return index
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

function reassign_all_keys(palette_number)
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
    for _, v in ipairs(array) do -- add all options with keycodes
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

function user_enters_text(array, title)
    local x_wide = 220
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(title)
    dialog:CreateStatic(0, 0):SetText("New Name:"):SetWidth(x_wide)
    local answer = dialog:CreateEdit(0, 20):SetText(array.name or ""):SetWidth(x_wide)

    dialog:CreateStatic(0, 46):SetText("Hotkey:"):SetWidth(x_wide)
    local key_edit = dialog:CreateEdit(45, 46 - offset):SetText(array.key or "?"):SetWidth(25)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function() answer:SetKeyboardFocus() end)
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, answer:GetText(), clean_key(key_edit:GetText())
end

function user_chooses_script(index, palette_number, instruction)
    local x_wide = 220
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local sub = palettes[palette_number].sub
    local old_menu = sub[index] or { name = "", script = "", key = "?" }
    local assigned, script_names = {}, {}
    for _, v in ipairs(sub) do
        if v.script then assigned[v.script] = true end
    end
    for k, _ in pairs(script_array) do
        if not assigned[k] or (k == old_menu.script) then
            table.insert(script_names, k)
        end
    end
    table.sort(script_names)
    --
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Choose Script Item")
    dialog:CreateStatic(0, 0):SetText(instruction):SetWidth(x_wide)
    local scripts = dialog:CreatePopup(0, 20):SetWidth(x_wide)
    local selected = 1
    for i, v in ipairs(script_names) do
        scripts:AddString(v)
        if v == old_menu.script then
            scripts:SetSelectedItem(i - 1)
            selected = i
        end
    end
    dialog:CreateStatic(0, 44):SetText("Name for Listing:"):SetWidth(x_wide)
    local list_name = dialog:CreateEdit(0, 66 - offset):SetText(old_menu.name):SetWidth(x_wide)
    dialog:CreateStatic(0, 90):SetText("Hotkey:"):SetWidth(x_wide)
    local key_edit = dialog:CreateEdit(45, 90 - offset):SetText(old_menu.key):SetWidth(25)
    scripts:AddHandleCommand(function()
        local new = scripts:GetSelectedItem() + 1
        if new ~= selected then
            list_name:SetText(script_names[new])
            selected = new
        end
    end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function() scripts:SetKeyboardFocus() end)
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local menu_name = script_names[scripts:GetSelectedItem() + 1]
    return ok, list_name:GetText(), menu_name, clean_key(key_edit:GetText())
end

function fill_list_box(list_box, array, selected)
    list_box:Clear()
    local join = finenv.UI():IsOnMac() and "\t" or ": "
    for _, v in ipairs(array) do
        list_box:AddString(v.key .. join .. v.name)
    end
    if selected and tonumber(selected) > 1 then
        list_box:SetSelectedItem(tonumber(selected) - 1)
    end
end

function load_menu_level(top_menu, old_name, level, match_title)
    local menu_level = { parent = top_menu, members = {} }
    local match_index = 1
    menu_level.pos = (level == 1) and "Menu Bar" or
        old_name .. " > " .. menu.get_title(top_menu, finenv.GetFinaleMainWindow())
    local index = 1
    for i = 1, menu.get_item_count(top_menu) do
        local t = menu.get_item_type(top_menu, i - 1)
        if t == menu.ITEMTYPE_SUBMENU or t == menu.ITEMTYPE_COMMAND then
            local name = menu.get_item_text(top_menu, i - 1)
            if name == match_title then match_index = index end
            if not string.find(name, "Plug.ins") then -- exclude PLUG-INS
                menu_level.members[index] =
                {   text = name,
                    sub = menu.get_item_submenu(top_menu, i - 1), -- handle (or nil)
                    id = menu.get_item_command_id(top_menu, i - 1), -- (or nil)
                }
                index = index + 1
            end
        end
    end
    return menu_level, match_index
end

function user_chooses_menu_item()
    local menu_bar = menu.get_top_level_menu(finenv.GetFinaleMainWindow())
    local y, y_step, list_wide, x_wide =  0, 17, 160, 230
    local mid_x = list_wide + 10
    local box_high = (10 * y_step) + 6
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local selected, level, saved_level = 1, 1, 1
    local menu_levels, menu_tree = {}, {}
    local inputs = {} -- input controls

    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Choose Menu Item")
    local pos_text = dialog:CreateStatic(0, y):SetText("Menu Bar"):SetWidth(330)
    local script_about = [[ RGP Lua isn't able to access every Finale menu item and, 
for instance, the entire "Plug-ins" folder has been hidden from this script because the 
items in it are too unreliable. (Some plug-ins create their own menus and sub-menus on the fly). 
To access RGP Lua script menu items use the "Add Script" facility here under "Configure Scripts".

After you've highlighted an active menu item from the list a "Test Menu Item" button 
will appear to make sure it works before you add it to the current palette. 
Note that many Finale menus do nothing unless part of the score is already selected. ]]
    dialog:CreateButton(mid_x * 2 - 20, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(script_about:gsub(" \n", " "), "Adding Menu Items") end)
    y = y + y_step
    dialog:CreateStatic(0, y):SetText("Choose Menu Item:"):SetWidth(x_wide)
    y = y + y_step + 5
    local up_to_parent = dialog:CreateButton(mid_x, y):SetText("Up to Parent Menu ↑")
        :SetWidth(mid_x)
    up_to_parent:SetEnable(false)
    local menu_list_box = dialog:CreateListBox(0, y):SetWidth(list_wide):SetHeight(box_high)
    y = y + (box_high / 4)
    local open_submenu = dialog:CreateButton(mid_x, y):SetText("Open Submenu →"):SetWidth(mid_x)
    y = y + (y_step * 2)
    inputs[1] = dialog:CreateStatic(mid_x, y):SetText("Name for Listing:"):SetWidth(list_wide)
    y = y + y_step + 3
    inputs[2] = dialog:CreateEdit(mid_x, y - offset):SetText("unnamed"):SetWidth(mid_x)
    y = y + y_step + 5
    inputs[3] = dialog:CreateStatic(mid_x, y):SetText("Hotkey:"):SetWidth(70)
    inputs[4] = dialog:CreateEdit(mid_x + 45, y - offset):SetText("?"):SetWidth(25)
    y = y + y_step + 5
    inputs[5] = dialog:CreateButton(mid_x, y):SetText("Test Menu Item"):SetWidth(mid_x)

    local ok_button = dialog:CreateOkButton():SetText("Select Menu Item"):SetWidth(list_wide)
    dialog:CreateCancelButton()
        --
        local function check_status()
            local i = menu_list_box:GetSelectedItem() + 1
            local is_submenu = (menu_levels[level].members[i].sub ~= nil)
            open_submenu:SetEnable(is_submenu)
            ok_button:SetEnable(not is_submenu)
            up_to_parent:SetEnable(level > 1)
            for j = 1, 5 do
                inputs[j]:SetEnable(not is_submenu)
            end
            if not is_submenu then
                inputs[2]:SetText(menu_levels[level].members[i].text)
            end
            if saved_level ~= level then
                pos_text:SetText(menu_levels[level].pos)
                saved_level = level
            end
        end
        --
        local function fill_menu_list(array, index)
            menu_list_box:Clear()
            for _, v in ipairs(array) do
                local tag = (v.sub ~= nil) and " >" or ""
                menu_list_box:AddString(v.text .. tag)
            end
            if index > 1 then menu_list_box:SetSelectedItem(index - 1) end
            check_status()
        end
        --
    menu_list_box:AddHandleCommand(function() check_status() end)
    inputs[5]:AddHandleCommand(function() -- Test Menu Item BUTTON
        local id = menu_levels[level].members[menu_list_box:GetSelectedItem() + 1].id
        finenv.UI():ExecuteOSMenuCommand(id)
    end)
    open_submenu:AddHandleCommand(function() -- OPEN SUBMENU
        local i = menu_list_box:GetSelectedItem() + 1
        local child = menu_levels[level].members[i].sub
        if child then
            local old_name = menu_levels[level].pos
            menu_tree[level] = menu_levels[level].members[i].text
            level = level + 1
            menu_levels[level], _ = load_menu_level(child, old_name, level, "")
            menu_levels[level].last_selected = i
            fill_menu_list(menu_levels[level].members, 1)
        end
    end)
    up_to_parent:AddHandleCommand(function() -- Up To Parent Menu
        if level > 1 then
            selected = menu_levels[level].last_selected
            table.remove(menu_tree, level)
            level = level - 1
            fill_menu_list(menu_levels[level].members, selected)
        end
    end)
    dialog:RegisterInitWindow(function()
        menu_tree = cjson.decode(config.menu_tree)
        local top_menu = menu_bar
        local level_name = "Menu Bar"
        if menu_tree and #menu_tree > 0 then -- load down to last selected menu level
            for i, v in ipairs(menu_tree) do
                menu_levels[i], selected = load_menu_level(top_menu, level_name, i, v)
                menu_levels[i].last_selected = selected
                level = i
                top_menu = menu_levels[i].members[selected].sub
                level_name = menu_levels[i].pos
            end
        else
            menu_levels[1], _ = load_menu_level(menu_bar, "", 1, "")
        end
        fill_menu_list(menu_levels[level].members, selected)
        menu_list_box:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        menu_tree[level] = menu_levels[level].members[menu_list_box:GetSelectedItem() + 1].text
    end)
    dialog:RegisterCloseWindow(function() config.menu_tree = cjson.encode(menu_tree) end)
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    local menu_id = menu_levels[level].members[menu_list_box:GetSelectedItem() + 1].id
    return ok, inputs[2]:GetText(), menu_id, clean_key(inputs[4]:GetText())
end

function configure_palette(palette_number, index_num)
    local y, y_step, x_wide =  0, 17, 228
    local is_macro = (palette_number == 0)

    local array = is_macro and palettes or palettes[palette_number].sub
    local box_high = (#array > 3) and (#array * y_step + 5) or (4 * y_step)
    local text = is_macro and "Configure Palettes" or "Configure Scripts"
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(text)
    if not is_macro then
        dialog:CreateStatic(0, y):SetWidth(x_wide)
            :SetText("Palette Name: " .. palettes[palette_number].name)
        y = y + y_step
    end
    text = is_macro and "Choose Palette:" or "Choose Script Item:"
    dialog:CreateStatic(0, y):SetText(text):SetWidth(x_wide)
    y = y + y_step + 5
    local list_box = dialog:CreateListBox(0, y):SetWidth(x_wide):SetHeight(box_high)
    fill_list_box(list_box, array, index_num)

    y = y + box_high + 8
    local x_off = x_wide / 20
    local remove_item = dialog:CreateButton(0, y):SetText("Remove"):SetWidth(x_off * 9)
    local rename_item = dialog:CreateButton(x_off * 11, y):SetWidth(x_off * 9):SetText("Change Name")
    y = y + y_step + 5
    text = is_macro and "New Palette" or "Add Script"
    local add_item = dialog:CreateButton(0, y):SetText(text):SetWidth(x_off * 9)
    local reassign_keys, add_menu
    if is_macro then
        reassign_keys = dialog:CreateButton(x_off * 11, y):SetText("Reassign Keys"):SetWidth(x_off * 9)
    else
        add_menu = dialog:CreateButton(x_off * 11, y):SetText("Add Menu Item"):SetWidth(x_off * 9)
        y = y + y_step + 5
        reassign_keys = dialog:CreateButton(x_off * 5, y):SetText("Reassign Keys"):SetWidth(x_off * 10)
    end
    remove_item:AddHandleCommand(function() -- REMOVE PALETTE / SCRIPT / MENU
        local index = list_box:GetSelectedItem() + 1
        table.remove(array, index)
        if (index > 1) then index = index - 1 end
        fill_list_box(list_box, array, index)
    end)
    rename_item:AddHandleCommand(function() -- RENAME PALETTE / SCRIPT / MENU
        local index = list_box:GetSelectedItem() + 1
        local title = is_macro and "Rename Palette" or "Rename Script/Menu"
        local ok, new_name, hotkey = user_enters_text(array[index], title)
        if ok then
            array[index].name = new_name
            array[index].key  = hotkey
            index = sort_table(array, new_name, "name")
            fill_list_box(list_box, array, index)
        end
    end)
    reassign_keys:AddHandleCommand(function() -- REASSIGN KEYS
        local ok, is_duplicate = true, true
        while ok and is_duplicate do -- wait for valid choices in reassign_all_keys()
            ok, is_duplicate = reassign_all_keys(palette_number)
        end
        if ok then
            fill_list_box(list_box, array, 1)
        else -- restore previously saved choices
            configuration.get_user_settings(script_name, config, true)
        end
    end)
    add_item:AddHandleCommand(function() -- ADD PALETTE or SCRIPT
        local new_name, new_script, hotkey
        local new_element, ok = {}, false
        if is_macro then
            new_element = { name = "", key = "?" }
            ok, new_name, hotkey = user_enters_text(new_element, "Create New Palette")
            if ok then
                new_element = {
                    name = new_name, key = hotkey, last = 1,
                    sub = { { name = "(script unassigned)", key = "?", script = "unassigned" } } }
            end
        else -- SCRIPT palette
            ok, new_name, new_script, hotkey = user_chooses_script(0, palette_number, "Add New RGP Lua Script:")
            if ok then
                new_element = { name = new_name, key = hotkey, script = new_script }
            end
        end
        if ok then
            table.insert(array, new_element)
            local index = sort_table(array, new_element.name, "name")
            fill_list_box(list_box, array, index)
        end
    end)
    if not is_macro then
        add_menu:AddHandleCommand(function() -- ADD NEW MENU ITEM
            local new_element = {}
            local ok, new_name, menu_id, trigger = user_chooses_menu_item()
            if ok then
                new_element = { name = new_name, key = trigger, menu = menu_id }
                table.insert(array, new_element)
                local index = sort_table(array, new_name, "name")
                fill_list_box(list_box, array, index)
            end
        end)
    end
    dialog:CreateOkButton():SetText("Save")
    dialog:CreateCancelButton():SetText("Discard")
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function() list_box:SetKeyboardFocus() end)
    dialog:RegisterHandleCancelButtonPressed(function()
        configuration.get_user_settings(script_name, config) -- restore original user values
        palettes = cjson.decode(config.palettes)
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.palettes = cjson.encode(palettes)
        configuration.save_user_settings(script_name, config) -- save new values
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function choose_palette(palette_number)
    local y, y_step = 0, 17
    local is_macro = (palette_number == 0)
    local array = is_macro and palettes or palettes[palette_number].sub
    local box_wide = 228
    local box_high = (#array > 3) and (#array * y_step + 5) or (4 * y_step)
    local selected = is_macro and config.last_palette or palettes[palette_number].last

    local text = "Hotkey Script Palettes"
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(text)
    dialog:CreateButton(box_wide - 20, 0):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() finenv.UI():AlertInfo(finaleplugin.Notes:gsub(" \n", " "), text) end)
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
    local reconfigure = dialog:CreateButton(x_off, y):SetText(text):SetWidth(x_off * 2)
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
        config.palettes = cjson.encode(palettes)
        configuration.save_user_settings(script_name, config) -- save new settings
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:RegisterInitWindow(function() item_list:SetKeyboardFocus() end)
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok, (item_list:GetSelectedItem() + 1)
end

function main()
    local scripts = finenv.CreateLuaScriptItems()
    for i = 1, scripts.Count do
        local script = scripts:GetItemAt(i - 1)
        script_array[script:GetMenuItemText()] = script -- global script_array[]
    end
    configuration.get_user_settings(script_name, config, true)
    palettes = cjson.decode(config.palettes)
    local ok, finished = false, false
    local palette_number, item_number = 1, 1

    while not finished do -- keep circling until user makes a choice or cancels
        ok, palette_number = choose_palette(0) -- main palette
        if ok then
            finished, item_number = choose_palette(palette_number) -- script palette
            if finished then -- successful choice
                local chosen_item = palettes[palette_number].sub[item_number]
                if chosen_item.menu then
                    finenv.UI():ExecuteOSMenuCommand(chosen_item.menu)
                else
                    local script = chosen_item.script or "unknown"
                    if not script_array[script] then
                        finenv.UI():AlertError("Script menu \"" .. script .. "\" could not be identified", "Error")
                    else
                        finenv.ExecuteLuaScriptItem(script_array[script])
                    end
                end
            end -- finished "true" will exit now
        else
            finished = true -- user cancelled and wants to exit
        end
        finenv.UI():ActivateDocumentWindow()
    end
end

main()
