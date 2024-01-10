function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.10"
    finaleplugin.Date = "2024/01/10"
    finaleplugin.AdditionalMenuOptions = [[
        Double Diatonic Repeat
    ]]
    finaleplugin.AdditionalUndoText = [[
        Double Diatonic Repeat
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Repeat the last diatonic doubling (no dialog)
    ]]
    finaleplugin.AdditionalPrefixes = [[
        no_dialog = true
    ]]
    finaleplugin.MinJWLuaVersion = 0.62
    finaleplugin.CategoryTags = "Pitch, Transposition"
    finaleplugin.ScriptGroupName = "Double Diatonic"
    finaleplugin.ScriptGroupDescription = "Double notes and chords up or down by a chosen diatonic interval"
    finaleplugin.Notes = [[
        Notes and chords in the current music selection are doubled 
        either up or down by the chosen diatonic interval. 
        Act on one layer or all four. 
        To repeat the last action without a confirmation dialog use 
        the "Repeat" menu or hold down [shift] when starting the script.
	]]
   return "Double Diatonic...", "Double Diatonic",
        "Double notes and chords up or down by a chosen diatonic interval"
end

no_dialog = no_dialog or false

local info_notes = [[
Notes and chords in the current music selection are doubled
either up or down by the chosen diatonic interval.
Act on one layer or all four.
To repeat the last action without a confirmation dialog use
the "Repeat" menu or hold down [shift] when starting the script.
**
If the "layer number" field is highlighted
*these key commands are available:
**[0]-[4] layer number (delete key not needed)
*[+]/[a]  interval up
*[-]/[z]  interval down
*[q] @t show this script information
*[w] @t up an octave
*[s] @t zero
*[x] @t down an octave
*[e] @t + extra octave
*[d] @t - extra octave
*[c] @t reverse up/down intervals
]]
info_notes = info_notes:gsub("\n%s*", " "):gsub("*", "\n"):gsub("@t", "\t")

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local transposition = require("library.transposition")
local script_name = "diatonic_doubler"

local config = {
    layer_num = 0,
    interval = 0,
    octave = 0,
    window_pos_x = false,
    window_pos_y = false,
}

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

local function user_chooses()
    local offset = finenv.UI():IsOnMac() and 3 or 0
    local y = 0
    local box_wide = 60
    local box_high = (15 * 17) + 4 -- 15-row list
    local function show_info()
        finenv.UI():AlertInfo(info_notes, "About " .. finaleplugin.ScriptGroupName)
    end
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef())
    dialog:CreateStatic(0, 5):SetText("Diatonic Interval:"):SetWidth(box_wide + 40)
    local interval_list = dialog:CreateListBox(0, 22):SetWidth(box_wide):SetHeight(box_high)
    local interval_names = { "2nd", "3rd", "4th", "5th", "6th", "7th", "8ve" }
    for i = 7, -7, -1 do
        local prefix = i > 0 and "↑ " or "↓ "
        if i == 0 then
            interval_list:AddString("- - -")
        else
            interval_list:AddString(prefix .. interval_names[math.abs(i)])
        end
    end
    interval_list:SetSelectedItem(7 - config.interval)
    local function list_increment(add)
        local sel = interval_list:GetSelectedItem()
        if (add > 0 and sel < 14) or (add < 0 and sel > 0) then
            interval_list:SetSelectedItem(sel + add)
        end
    end

    local x_off = box_wide + 10
    dialog:CreateStatic(x_off + 5, 60):SetText("Extra\nOctaves:"):SetWidth(box_wide):SetHeight(30)
    local octave_list = dialog:CreateListBox(x_off + 15, 90):SetWidth(25):SetHeight(4 * 17 + 4)
    for i = 3, 0, -1 do
        octave_list:AddString(i)
    end
    octave_list:SetSelectedItem(3 - config.octave)
    local function octave_increment(add)
        local sel = octave_list:GetSelectedItem()
        if (add > 0 and sel < 3) or (add < 0 and sel > 0) then
            octave_list:SetSelectedItem(sel + add)
        end
    end
    y = 180
    local max = finale.FCLayerPrefs.GetMaxLayers and finale.FCLayerPrefs.GetMaxLayers() or 4
    dialog:CreateStatic(x_off, y):SetText("Layer 1-" .. max .. ":"):SetWidth(box_wide)
    y = y + 20
    local save_layer = config.layer_num
    local layer_num = dialog:CreateEdit(x_off + 20, y - offset):SetWidth(20):SetText(save_layer)
        :AddHandleCommand(function(self) -- key command replacements
            local val = self:GetText():lower()
            if val:find("[^0-" .. max .. "]") then
                if val:find("[+=a]") then list_increment(-1) -- note up
                elseif val:find("[-_z]") then list_increment(1) -- note down
                elseif val:find("w") then interval_list:SetSelectedItem(0)
                elseif val:find("s") then interval_list:SetSelectedItem(7)
                elseif val:find("x") then interval_list:SetSelectedItem(14)
                elseif val:find("[e%[]") then octave_increment(-1) -- octave up
                elseif val:find("[d%]]") then octave_increment(1) -- octave down
                elseif val:find("c") then -- invert interval polarity
                    interval_list:SetSelectedItem(14 - interval_list:GetSelectedItem())
                elseif val:find("[?q]") then show_info()
                end
                self:SetText(save_layer):SetKeyboardFocus()
            elseif val ~= "" then
                val = val:sub(-1)
                self:SetText(val)
                save_layer = val
            end
        end)
    y = y + 20
    dialog:CreateStatic(x_off + 7, y):SetWidth(50):SetText("(0 = all)")
    local q = dialog:CreateButton(x_off + 20, box_high + 3):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    dialog:CreateOkButton():SetText("Select")
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterInitWindow(function()
        q:SetFont(q:CreateFontInfo():SetBold(true))
        layer_num:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function()
        config.interval = 7 - interval_list:GetSelectedItem()
        config.octave = 3 - octave_list:GetSelectedItem()
        config.layer_num = layer_num:GetInteger()
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

function interval_doubler()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    if no_dialog or mod_key or user_chooses() then
        local shift = config.interval
        if shift < 0 then config.octave = -config.octave end
        shift = shift + (config.octave * 7)
        if shift ~= 0 then
            for entry in eachentrysaved(finenv.Region(), config.layer_num) do
                transposition.entry_diatonic_transpose(entry, shift, true)
            end
        end
    end
end

interval_doubler()
