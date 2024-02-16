function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.65"
    finaleplugin.LoadLuaOSUtils = true
    finaleplugin.Date = "2024/02/08"
    finaleplugin.CategoryTags = "Menu, Utilities"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[ 
        This is designed to help navigate the many scripts crowding your _RGP Lua_ menu. 
        It provides access to Lua scripts and Finale menu items through a set of 
        easily configurable palettes (dialog windows) organised by type of activity 
        and triggered by simple "hotkey" keystrokes.

        The _Hotkey Palette_ principle is demonstrated expertly by 
        Nick Mazuk [on YouTube](https://www.youtube.com/@nickmazuk). 
        Scripts are grouped into primary categories like _Intervals_, _Layers_, 
        _Notes & Chords_, _Measure Items_ and so on as a set of palettes triggered by keystroke. 
        Each primary palette calls up a second palette containing scripts in related areas, 
        also triggered by keystroke. Reach hundreds of scripts in your collection using 
        just two keystrokes with the actual hotkeys presented as a visual reminder. 
        Actions you repeat often will link to muscle memory and become easier to recall.

        Nick uses [Keyboard Maestro](https://keyboardmaestro.com) on Mac for this, 
        but this script makes it free (cross-platform) within Finale 
        using RGP Lua without other software or configuration. 
        Scripts that use modifier keys (shift, alt/option etc) for "alternative" behaviours 
        respond to those keys when called from these palettes.

        This script is loaded with a set of "demo" palettes containing many of the 
        Lua scripts available at [FinaleLua.com](https://FinaleLua.com). 
        If a script isn't installed on your system you will get an "unidentified" warning 
        on execution. Delete those scripts and add new ones in their place. 
        Reconfigure each of the _Main_ palettes, change their name or hotkey, 
        delete them or add new ones.

        You can also add Finale menus to your palettes. 
        Not every menu item is available, including Plug-ins that are NOT added by _RGP Lua_, 
        so when using _Add Menu Item_ try it out before saving to a palette.
    ]]
    return "Hotkey Script Palettes...",
        "Hotkey Script Palettes",
        "Trigger RGP Lua scripts by keystroke through a configurable set of dialog windows"
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
local utils = require("library.utils")
local osutils = require("luaosutils")
local menu = osutils.menu
local cjson = require("cjson")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false

local script_array = {} -- assemble all script items from the RGPLua menu
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

local function show_info(parent)
    utils.show_notes_dialog(parent, "About " .. plugindef():gsub("%.%.%.", ""))
    refocus_document = true
end

local function make_info_button(dialog, x, y)
    dialog:CreateButton(x, y, "q"):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info(dialog) end)
end

local function clean_key(input) -- return one clean uppercase character
    local key = string.upper(string.sub(input, 1, 1))
    if key == "" then key = "?" end -- non-NULL hotkey
    return key
end

local function sort_table(array, match_text, match_type)
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

local function reassign_all_keys(palette_number, index, parent_window)
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
            :AddHandleCommand(function(self)
                local str = self:GetText():upper()
                self:SetText(str:sub(-1)):SetKeyboardFocus()
            end)
        dialog:CreateStatic(30, y):SetText(v.name):SetWidth(x_wide)
        y = y + y_step
    end
    y = y + 7
    local ignore = dialog:CreateCheckbox(0, y):SetWidth(x_wide)
        :SetText("Ignore duplicate assignments"):SetCheck(config.ignore_duplicates or 0)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:GetControl(array[index].name):SetKeyboardFocus()
    end)
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
            dialog:CreateChildUI():AlertError(msg, "Duplicate Key Assignment")
        end
    end)
    local ok = (dialog:ExecuteModal(parent_window) == finale.EXECMODAL_OK)
    return ok, is_duplicate
end

local function user_enters_text(array, title, parent_window)
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
    local ok = (dialog:ExecuteModal(parent_window) == finale.EXECMODAL_OK)
    return ok, answer:GetText(), clean_key(key_edit:GetText())
end

local function user_chooses_script(index, palette_number, instruction, parent_window)
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
    dialog:CreateStatic(0, 0):SetText(instruction):SetWidth(x_wide - 22)
    make_info_button(dialog, x_wide - 20, 0)
    local script_list = dialog:CreatePopup(0, 20):SetWidth(x_wide)
    local selected = 1
    for i, v in ipairs(script_names) do
        script_list:AddString(v)
        if v == old_menu.script then
            script_list:SetSelectedItem(i - 1)
            selected = i
        end
    end
    dialog:CreateStatic(0, 44):SetText("Name for Listing:"):SetWidth(x_wide)
    local list_name = dialog:CreateEdit(0, 66 - offset):SetText(old_menu.name):SetWidth(x_wide)
    dialog:CreateStatic(0, 90):SetText("Hotkey:"):SetWidth(x_wide)
    local key_edit = dialog:CreateEdit(45, 90 - offset):SetText(old_menu.key):SetWidth(25)
    script_list:AddHandleCommand(function()
        local new = script_list:GetSelectedItem() + 1
        if new ~= selected then
            list_name:SetText(script_names[new])
            selected = new
        end
    end)
    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function() script_list:SetKeyboardFocus() end)
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(parent_window) == finale.EXECMODAL_OK)
    local menu_name = script_names[script_list:GetSelectedItem() + 1]
    return ok, list_name:GetText(), menu_name, clean_key(key_edit:GetText())
end

local function fill_list_box(list_box, array, selected)
    list_box:Clear()
    local join = finenv.UI():IsOnMac() and "\t" or ": "
    for _, v in ipairs(array) do
        list_box:AddString(v.key .. join .. v.name)
    end
    local n = tonumber(selected) or 0
    if n > 1 and n <= #array then
        list_box:SetSelectedItem(n - 1)
    end
end

local function load_menu_level(top_menu, old_name, level, match_title)
    local menu_level = { parent = top_menu, members = {} }
    local index, match_index = 1, 1
    menu_level.pos = (level == 1) and "Menu Bar" or
        old_name .. " > " .. menu.get_title(top_menu, finenv.GetFinaleMainWindow())
    for cnt = 1, menu.get_item_count(top_menu) do
        local i_type = menu.get_item_type(top_menu, cnt - 1)
        if i_type == menu.ITEMTYPE_SUBMENU or i_type == menu.ITEMTYPE_COMMAND then
            local name = menu.get_item_text(top_menu, cnt - 1)
            if name == match_title then match_index = index end
            if not string.find(name, "Plug.ins") then -- exclude PLUG-INS
                menu_level.members[index] =
                {   text = name,
                    sub = menu.get_item_submenu(top_menu, cnt - 1), -- handle (or nil)
                    id = menu.get_item_command_id(top_menu, cnt - 1), -- (or nil)
                }
                index = index + 1
            end
        end
    end
    return menu_level, match_index
end

local function user_chooses_menu_item(parent_window)
    local menu_bar = menu.get_top_level_menu(finenv.GetFinaleMainWindow())
    local y, y_step, list_wide, x_wide, x2_wide =  0, 17, 160, 230, 160
    local mid_x = list_wide + 10
    local box_high = (10 * y_step) + 6
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local selected, level, saved_level = 1, 1, 1
    local menu_levels, menu_tree = {}, {}
    local chosen_now = {}
    local inputs = {} -- input controls

    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Choose Menu Item")
    local pos_text = dialog:CreateStatic(0, y):SetText("Menu Bar"):SetWidth(330)
    local menu_about = [[
RGP Lua isn't able to access every Finale menu item and,
for instance, the entire "Plug-ins" folder is hidden from this script because the
items in it are unreliable. (Some plug-ins create menus and sub-menus on the fly).
To access RGP Lua script menu items here use the "Add Script" facility under "Configure Scripts".
**
After you've highlighted an active menu item from the list a "Test Menu Item" button
will appear to make sure it works before you add it to the current palette.
Note that many Finale menus do nothing unless part of the score is already selected.
]]
    dialog:CreateButton(mid_x + x2_wide - 20, y):SetText("?"):SetWidth(20)
        :AddHandleCommand(function()
            dialog:CreateChildUI()
            :AlertInfo(menu_about:gsub("%s*\n%s*", " "):gsub("*", "\n"), "Adding Menu Items")
        end)
    y = y + y_step
    dialog:CreateStatic(0, y):SetText("Choose Menu Item:"):SetWidth(x_wide)
    y = y + y_step + 5
    local up_to_parent = dialog:CreateButton(mid_x, y):SetText("Up to Parent Menu ↑")
        :SetWidth(x2_wide)
    up_to_parent:SetEnable(false)
    local menu_list_box = dialog:CreateListBox(0, y):SetWidth(list_wide):SetHeight(box_high)
        :SetAlternatingBackgroundRowColors(true)
    y = y + (box_high / 4)
    local open_submenu = dialog:CreateButton(mid_x, y):SetText("Open Submenu →"):SetWidth(x2_wide)
    y = y + (y_step * 2)
    inputs[1] = dialog:CreateStatic(mid_x, y):SetText("Name for Listing:"):SetWidth(x2_wide)
    y = y + y_step + 3
    inputs[2] = dialog:CreateEdit(mid_x, y - offset):SetText("unnamed"):SetWidth(x2_wide)
    y = y + y_step + 5
    inputs[3] = dialog:CreateStatic(mid_x, y):SetText("Hotkey:"):SetWidth(70)
    inputs[4] = dialog:CreateEdit(mid_x + 45, y - offset):SetText("?"):SetWidth(25)
    y = y + y_step + 5
    inputs[5] = dialog:CreateButton(mid_x, y):SetText("Test Menu Item"):SetWidth(x2_wide)

    local ok_button = dialog:CreateOkButton():SetText("Select Menu Item"):SetWidth(120)
    dialog:CreateCancelButton()
        --
        local function check_status()
            if menu_list_box:GetCount() < 1 then return end
            local index = menu_list_box:GetSelectedItem() + 1
            chosen_now = menu_levels[level].members[index]
            local is_submenu = (chosen_now.sub ~= nil)
            open_submenu:SetEnable(is_submenu)
            ok_button:SetEnable(not is_submenu)
            up_to_parent:SetEnable(level > 1)
            for j = 1, 5 do
                inputs[j]:SetEnable(not is_submenu)
            end
            if not is_submenu then
                inputs[2]:SetText(chosen_now.text)
            end
            if saved_level ~= level then
                pos_text:SetText(menu_levels[level].pos)
                saved_level = level
            end
        end
        --
        local function fill_menu_list(index)
            menu_list_box:Clear()
            for _, v in ipairs(menu_levels[level].members) do
                local tag = (v.sub ~= nil) and " >" or ""
                menu_list_box:AddString(v.text .. tag)
            end
            if index > 0 then menu_list_box:SetSelectedItem(index - 1) end
            check_status()
        end
        --
        local function one_level_down()
            if chosen_now.sub then -- down to SubMenu
                local old_index = menu_list_box:GetSelectedItem() + 1
                local old_name = menu_levels[level].pos
                menu_tree[level] = chosen_now.text
                level = level + 1
                menu_levels[level] = load_menu_level(chosen_now.sub, old_name, level, "")
                menu_levels[level].last_selected = old_index
                selected = 1
                fill_menu_list(1)
            end
        end
    menu_list_box:AddHandleCommand(function() check_status() end)
    inputs[5]:AddHandleCommand(function() -- Test Menu Item BUTTON
        finenv.UI():ExecuteOSMenuCommand(chosen_now.id)
    end)
    open_submenu:AddHandleCommand(function() one_level_down() end)-- Open Submenu
    up_to_parent:AddHandleCommand(function() -- Up To Parent Menu
        if level > 1 then
            selected = menu_levels[level].last_selected
            table.remove(menu_tree, level)
            level = level - 1
            fill_menu_list(selected)
        end
    end)
    dialog:RegisterHandleListDoubleClick(function() one_level_down() end)
    dialog:RegisterInitWindow(function()
        menu_tree = cjson.decode(config.menu_tree)
        selected = 1
        local top_menu = menu_bar
        local level_name, last_selected = "Menu Bar", 1
        if menu_tree and #menu_tree > 0 then -- load down to last selected menu level
            for i, v in ipairs(menu_tree) do
                menu_levels[i], selected = load_menu_level(top_menu, level_name, i, v)
                level = i
                top_menu = menu_levels[i].members[selected].sub
                menu_levels[i].last_selected = last_selected
                last_selected = selected
                level_name = menu_levels[i].pos
            end
        else
            menu_levels[1] = load_menu_level(menu_bar, "", 1, "")
        end
        fill_menu_list(selected)
        menu_list_box:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function() menu_tree[level] = chosen_now.text end)
    dialog:RegisterCloseWindow(function() config.menu_tree = cjson.encode(menu_tree) end)
    dialog_set_position(dialog)
    local ok = (dialog:ExecuteModal(parent_window) == finale.EXECMODAL_OK)
    local menu_id = chosen_now.id
    return ok, inputs[2]:GetText(), menu_id, clean_key(inputs[4]:GetText())
end

local function configure_palette(palette_number, index_num, parent_window)
    local y, y_step, x_wide =  0, 17, 228
    local is_macro = (palette_number == 0)

    local array = is_macro and palettes or palettes[palette_number].sub
    local box_high = (#array > 3) and (#array * y_step + 5) or (4 * y_step)
    local dialog = mixin.FCXCustomLuaWindow()
        :SetTitle(is_macro and "Configure Palettes" or "Configure Scripts")
    make_info_button(dialog, x_wide - 20, y)
    if not is_macro then
        dialog:CreateStatic(0, y):SetWidth(x_wide - 25)
            :SetText("Palette Name: " .. palettes[palette_number].name)
        y = y + y_step
    end
    dialog:CreateStatic(0, y):SetWidth(x_wide - 25)
        :SetText(is_macro and "Choose Palette:" or "Choose Script Item:")
    y = y + y_step + 5
    local list_box = dialog:CreateListBox(0, y):SetWidth(x_wide):SetHeight(box_high)
    fill_list_box(list_box, array, index_num)

    y = y + box_high + 8
    local x_off = x_wide / 20
    local remove_item = dialog:CreateButton(0, y):SetText("Remove"):SetWidth(x_off * 9)
    local rename_item = dialog:CreateButton(x_off * 11, y):SetWidth(x_off * 9):SetText("Change Name")
    y = y + y_step + 5
    local add_item = dialog:CreateButton(0, y):SetWidth(x_off * 9)
        :SetText(is_macro and "New Palette" or "Add Script")
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
        local ok, new_name, hotkey = user_enters_text(array[index], title, dialog)
        if ok then
            array[index].name = new_name
            array[index].key  = hotkey
            index = sort_table(array, new_name, "name")
            fill_list_box(list_box, array, index)
        end
    end)
    reassign_keys:AddHandleCommand(function() -- REASSIGN KEYS
        local ok, is_duplicate = true, true
        local idx = list_box:GetSelectedItem() + 1
        while ok and is_duplicate do -- wait for valid choices in reassign_all_keys()
            ok, is_duplicate = reassign_all_keys(palette_number, idx, dialog)
        end
        if ok then
            fill_list_box(list_box, array, 1)
        else -- restore previously saved choices
            configuration.get_user_settings(script_name, config, true)
        end
    end)
    add_item:AddHandleCommand(function() -- ADD PALETTE or SCRIPT
        local ok, new_name, hotkey
        local new_element = {}
        if is_macro then
            new_element = { name = "", key = "?" }
            ok, new_name, hotkey = user_enters_text(new_element, "Create New Palette", dialog)
            if ok then
                new_element = {
                    name = new_name, key = hotkey, last = 1,
                    sub = { { name = "(script unassigned)", key = "?", script = "unassigned" } } }
            end
        else -- SCRIPT palette
            local new_script
            ok, new_name, new_script, hotkey = user_chooses_script(
                0, palette_number, "Add New RGP Lua Script:", dialog
            )
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
            local ok, new_name, menu_id, trigger = user_chooses_menu_item(dialog)
            if ok then
                local new_element = { name = new_name, key = trigger, menu = menu_id }
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
    dialog:RegisterHandleOkButtonPressed(function() config.palettes = cjson.encode(palettes) end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal(parent_window) == finale.EXECMODAL_OK)
end

local function choose_palette(palette_number)
    local y, y_step = 0, 17
    local is_macro = (palette_number == 0)
    local array = is_macro and palettes or palettes[palette_number].sub
    local box_wide = 228
    local box_high = (#array > 3) and (#array * y_step + 5) or (4 * y_step)
    local selected = is_macro and config.last_palette or palettes[palette_number].last

    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef():gsub("%.%.%.", ""))
    make_info_button(dialog, box_wide - 20, 0)
    if not is_macro then
        dialog:CreateStatic(0, y):SetText("Palette: " .. palettes[palette_number].name)
            :SetWidth(box_wide * .9)
        y = y + y_step
    end
    dialog:CreateStatic(0, y):SetWidth(box_wide * .9)
        :SetText(is_macro and "Choose Palette:" or "Activate Script:")
    y = y + y_step + 5
    local item_list = dialog:CreateListBox(0, y):SetWidth(box_wide):SetHeight(box_high)
    fill_list_box(item_list, array, selected)

    local x_off = box_wide / 4
    y = y + box_high + 8
    dialog:CreateButton(x_off, y):SetWidth(x_off * 2)
        :SetText(is_macro and "Configure Palettes" or "Configure Scripts")
        :AddHandleCommand(function()
            local index_num = item_list:GetSelectedItem() + 1
            if configure_palette(palette_number, index_num, dialog) then
                fill_list_box(item_list, array, index_num)
            end
        end)
    dialog:CreateOkButton():SetText(is_macro and "Choose" or "Activate")
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
    local ok = (dialog:ExecuteModal() == finale.EXECMODAL_OK)
    return ok, (item_list:GetSelectedItem() + 1)
end

local function main()
    local scripts = finenv.CreateLuaScriptItems()
    for i = 1, scripts.Count do
        local script = scripts:GetItemAt(i - 1)
        script_array[script:GetMenuItemText()] = script -- global script_array[]
    end
    configuration.get_user_settings(script_name, config, true)
    palettes = cjson.decode(config.palettes)
    local finished = false
    local palette_number, item_number, ok

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
    end
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

main()
