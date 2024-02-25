function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Jacob Winkler, Nick Mazuk & Carl Vine"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.2"
    finaleplugin.Date = "2024-02-19"
    finaleplugin.CategoryTags = "Pitch"
    finaleplugin.Notes = [[
        Using __Pitch Entry Keep-Delete__

        Select a note within each chord to either keep or delete, 
        numbered from either the top or bottom of each chord. 

        - __1__ deletes (or keeps) the top (or bottom) note 
        - __2__ deletes (or keeps) the 2nd note from top (or bottom) 
        - etc. 

        >__Key Commands:__ 

        > - __a__ - keep 
        > - __z__ - delete 
        > - __s__ - from the top 
        > - __x__ - from the bottom 
        > - – 
        > - __q__ - toggle keep/delete 
        > - __w__ - toggle top/bottom 
        > - __e__ - show these notes 
        > - __1-9__ - enter note count (delete key not needed) 
    ]]
    return "Pitch: Chord Notes Keep-Delete...", "Pitch: Chord Notes Keep-Delete",
    "Keep or Delete selected notes from chords"
end

local configuration = require("library.configuration")
local note_entry = require("library.note_entry")
local mixin = require("library.mixin")
local utils = require("library.utils")
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
    local x, y, y_diff = 85, 3, 24
    local y_offset = finenv.UI():IsOnMac() and 3 or 0
    local answer = {}
    local saved = config.number
    local name = plugindef():gsub("%.%.%.", "")
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name)
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 500, 280)
        end
        local function flip_radio(id)
            local n = answer[id]:GetSelectedItem()
            answer[id]:SetSelectedItem((n + 1) % 2)
        end
        local function key_check(ctl)
            local s = ctl:GetText():lower()
            if  s:find("[^1-9]") then
                if     s:find("a") then answer.keep_delete:SetSelectedItem(0)
                elseif s:find("z") then answer.keep_delete:SetSelectedItem(1)
                elseif s:find("q") then flip_radio("keep_delete")
                elseif s:find("s") then answer.direction:SetSelectedItem(0)
                elseif s:find("x") then answer.direction:SetSelectedItem(1)
                elseif s:find("w") then flip_radio("direction")
                elseif s:find("e") then show_info()
                end
                ctl:SetText(saved):SetKeyboardFocus()
            elseif s ~= "" then
                s = s:sub(-1) -- 1-digit note number
                ctl:SetText(s)
                saved = s
            end
        end
        --
    dialog:CreateStatic(0, y):SetText("Note Number:"):SetWidth(x)
    answer.number = dialog:CreateEdit(x, y - y_offset):SetInteger(config.number)
        :AddHandleCommand(function(self) key_check(self) end):SetWidth(25)
    dialog:CreateButton(x + 105 - 20, 0):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    y = y + y_diff

    local titles = { {"Keep (a)", "Delete (z)"}, {"From Top (s)", "From Bottom (x)"}}
    local labels = finale.FCStrings()
    labels:CopyFromStringTable(titles[1])
    answer.keep_delete = dialog:CreateRadioButtonGroup(0, y, 2)
        :SetText(labels):SetWidth(x - 10)
        :SetSelectedItem(config.keep_delete)
    labels:CopyFromStringTable(titles[2])
    answer.direction = dialog:CreateRadioButtonGroup(x, y, 2)
        :SetText(labels):SetWidth(105)
        :SetSelectedItem(config.direction)
    y = y + 31
    dialog:CreateStatic(0 + 14, y):SetText("Toggle (q)")
    dialog:CreateStatic(x + 14, y):SetText("Toggle (w)")
    -- wrap it up
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
    if user_chooses() then
        for entry in eachentrysaved(finenv.Region()) do
            if (entry.Count >= 2) then
                local n = config.number
                local target = (config.direction == 0) and (n - 1) or (entry.Count - n)
                local i = 0
                for note in eachbackwards(entry) do -- scan pitches top to bottom
                    if      (i == target and config.keep_delete == 1)
                        or  (i ~= target and config.keep_delete == 0) then
                        note_entry.delete_note(note)
                    end
                    i = i + 1
                end
            end
        end
    end
    finenv.UI():ActivateDocumentWindow()
end

keep_delete()
