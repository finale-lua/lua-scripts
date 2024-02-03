function plugindef()
  finaleplugin.RequireSelection = true
  finaleplugin.Author = "Jacob Winkler, Nick Mazuk & Carl Vine"
  finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
  finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
  finaleplugin.Version = "1.0"
  finaleplugin.Date = "2024-01-26"
  finaleplugin.CategoryTags = "Pitch"
  finaleplugin.Notes = [[
USING PITCH ENTRY KEEP-DELETE

Select a note within each chord to either keep or delete, 
numbered from either the top or bottom of each chord.  
"1" deletes (or keeps) the top (or bottom) note,  
"2" deletes (or keeps) the 2nd note from top (or from bottom),  
etc.  

== Key Commands ==  
• [a] keep  
• [z] delete  
• [s] from the top  
• [x] from the bottom  
• [q] toggle keep/delete  
• [w] toggle top/bottom  
• [1-9] enter note count (delete key not needed)
]]
  return "Pitch: Chord Notes Keep-Delete...", "Pitch: Chord Notes Keep-Delete",
    "Keep or Delete selected notes from chords"
end

local configuration = require("library.configuration")
local note_entry = require("library.note_entry")
local mixin = require("library.mixin")
local library = require("library.general_library")
local script_name = library.calc_script_name()

local config = { -- retained and over-written by the user's "settings" file
    number       = 1, -- which note to work on
    direction    = 0, -- 0 == from top / 1 == from bottom
    keep_delete  = 0, -- 0 == keep / 1 == delete
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
    local x, y, y_diff = 85, 3, 20
    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    local answer = {}
    local saved = config.number
        --
        local function flip_popup(name)
            local n = answer[name]:GetSelectedItem()
            answer[name]:SetSelectedItem((n + 1) % 2)
        end
        local function key_check(ctl)
            local s = ctl:GetText():lower()
            if  s:find("[^0-9]") then
                if     s:find("a") then answer.keep_delete:SetSelectedItem(0)
                elseif s:find("z") then answer.keep_delete:SetSelectedItem(1)
                elseif s:find("q") then flip_popup("keep_delete")
                elseif s:find("s") then answer.direction:SetSelectedItem(0)
                elseif s:find("x") then answer.direction:SetSelectedItem(1)
                elseif s:find("w") then flip_popup("direction")
                end
                ctl:SetText(saved):SetKeyboardFocus()
            elseif s ~= "" then
                s = s:sub(-1) -- 1-digit note number
                ctl:SetText(s)
                saved = s
            end
        end
        --
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef():gsub("%.%.%.", ""))
    dialog:CreateStatic(0, y):SetText("Note Number:"):SetWidth(x)
    answer.number = dialog:CreateEdit(x, y - y_offset):SetInteger(config.number)
        :AddHandleCommand(function(self) key_check(self) end):SetWidth(25)
    y = y + y_diff
    answer.keep_delete = dialog:CreatePopup(0, y):SetWidth(x - 10)
        :AddStrings("Keep (a)", "Delete (z)")  -- == 0 ... 1
        :SetSelectedItem(config.keep_delete)
    answer.direction = dialog:CreatePopup(x, y):SetWidth(110)
        :AddStrings("From Top (s)", "From Bottom (x)")  -- == 0 ... 1
        :SetSelectedItem(config.direction)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog_set_position(dialog)
    dialog:RegisterHandleOkButtonPressed(function()
        config.number = answer.number:GetInteger()
        config.direction = answer.direction:GetSelectedItem()
        config.keep_delete = answer.keep_delete:GetSelectedItem()
    end)
    dialog:RegisterInitWindow(function() answer.number:SetKeyboardFocus() end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

local function keep_delete()
    configuration.get_user_settings(script_name, config, true)
    if not user_chooses() then return end -- user cancelled

    for entry in eachentrysaved(finenv.Region()) do
        if (entry.Count >= 2) then
            local n = math.max(config.number, 1)
            local target = (config.direction == 0) and (n - 1) or (entry.Count - n)
            local i = 0
            for note in eachbackwards(entry) do
                if      (i == target and config.keep_delete == 1)
                    or  (i ~= target and config.keep_delete == 0) then
                    note_entry.delete_note(note)
                end
                i = i + 1
            end
        end
    end
end

keep_delete()
