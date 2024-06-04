function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.HandlesUndo = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "0.07"
    finaleplugin.Date = "2024/06/04"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        Make dynamic marks in the selection louder or softer by stages. 
        This functionality is buried within __JWChange__ but is useful 
        and I thought was worth bringing nearer the surface. 
        This script works similarly but allows jumping up to 9 _levels_ at once. 
        The dynamic range is from __pppppp__ to __ffffff__, though 
        older (non-_SMuFL_) fonts are restricted to the range __pppp__-__ffff__. 

        To repeat the previous level shift without a confirmation dialog 
        hold down [Shift] when starting the script. 
    ]]
    return "Dynamic Levels...",
        "Dynamic Levels",
        "Make dynamic marks in the selection louder or softer by stages"
end

local hotkey = { -- customise hotkeys (lowercase only)
    direction = "z", -- toggle Louder/Softer
    show_info = "q",
}
local config = {
    direction    = 0, -- 0 == "Louder", 1 = "Softer"
    levels       = 1, -- how many "levels" louder or softer
    create_new   = false, -- don't create new dynamics without permission
    timer_id     = 1,
    window_pos_x = false,
    window_pos_y = false,
}
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local expression = require("library.expression")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local name = plugindef():gsub("%.%.%.", "")
local selection
local saved_bounds = {}
local dyn_char = library.is_font_smufl_font() and
    { -- char number for SMuFL dynamics (1-14)
        0xe527, 0xe528, 0xe529, 0xe52a, 0xe52b, 0xe520, 0xe52c, -- pppppp -> mp
        0xe52d, 0xe522, 0xe52f, 0xe530, 0xe531, 0xe532, 0xe533, -- mf -> ffffff
    } or
    { -- char number for non-SMuFL dynamics (1-10)
         175, 184, 185, 112,  80, -- pppp -> mp
          70, 102, 196, 236, 235  -- mf -> ffff
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

local function get_staff_name(staff_num)
    local staff = finale.FCStaff()
    staff:Load(staff_num)
    local str = staff:CreateDisplayAbbreviatedNameString().LuaString
    if not str or str == "" then
        str = "Staff" .. staff_num
    end
    return str
end

local function track_selection()
    local bounds = { -- primary region selection boundaries
        "StartStaff", "StartMeasure", "StartMeasurePos",
        "EndStaff",   "EndMeasure",   "EndMeasurePos",
    }
    local rgn = finenv.Region()
    for _, property in ipairs(bounds) do
        saved_bounds[property] = rgn[property]
    end
    -- update selection
    selection = "no staff, no selection" -- default
    if not rgn:IsEmpty() then
        selection = get_staff_name(rgn.StartStaff)
        if rgn.EndStaff ~= rgn.StartStaff then
            selection = selection .. "-" .. get_staff_name(rgn.EndStaff)
        end
        selection = selection .. " m." .. rgn.StartMeasure
        if rgn.StartMeasure ~= rgn.EndMeasure then
            selection = selection .. "-" .. rgn.EndMeasure
        end
    end
end

local function create_dynamics_alert(dialog)
    local msg = "Do you want this script to create additional dynamic expressions "
    .. "as required? (A positive reply will be saved and used if this question arises again)."
    local ok = dialog and
           dialog:CreateChildUI():AlertYesNo(msg, nil)
        or finenv.UI():AlertYesNo(msg, nil)
    return ok == finale.YESRETURN
end

local function create_exp_def(exp_name)
    local cat_def = finale.FCCategoryDef()
    cat_def:Load(1) -- default "DYNAMIC" category
    local finfo = finale.FCFontInfo()
    cat_def:GetMusicFontInfo(finfo)
    local str = finale.FCString()
    str.LuaString = "^fontMus"
        .. finfo:CreateEnigmaString(finale.FCString()).LuaString
        .. exp_name
    local ted = mixin.FCMTextExpressionDef()
    ted:SaveNewTextBlock(str)
        :AssignToCategory(cat_def)
        :SetUseCategoryPos(true)
        :SetUseCategoryFont(true)
        :SaveNew()
    return ted:GetItemNo() -- save new item number
end

local function change_dynamics(dialog)
    local found = {} -- collate matched dynamic expressions
    local matches = 0 -- count successes
    local shift = config.levels -- how many dynamic levels to move?
    if config.direction == 1 then shift = -shift end -- getting softer not louder
    local dyn_len = library.is_font_smufl_font() and 3 or 2 -- max length of dynamic string
    -- match all target dynamics from existing expressions
    local exp_defs = mixin.FCMTextExpressionDefs()
    exp_defs:LoadAll()
    for exp_def in each(exp_defs) do
        if exp_def.CategoryID == 1 and exp_def.UseCategoryFont then -- "standard" dynamic?
            local str = exp_def:CreateTextString()
            str:TrimEnigmaTags()
            if str.LuaString:len() <= dyn_len then -- dynamic length
                for i, v in ipairs(dyn_char) do -- match all required characters
                    if not found[i] and str.LuaString == utf8.char(v) then
                        found[i] = exp_def.ItemNo -- matched char
                        matches = matches + 1
                    end
                end
            end
            if matches >= #dyn_char then break end
        end
    end
    -- scan the selection for dynamics and change them
    finenv.StartNewUndoBlock(string.format("%s %s%d %s", name,
        (config.direction == 0 and "+" or "-"), config.levels, selection)
    )
    for e in loadallforregion(mixin.FCMExpressions(), finenv.Region()) do
        if expression.is_dynamic(e) then
            local exp_def = e:CreateTextExpressionDef()
            if exp_def and exp_def.UseCategoryFont then -- "standard" dynamic?
                local str = exp_def:CreateTextString()
                str:TrimEnigmaTags()
                if str.LuaString:len() <= dyn_len then -- dynamic length
                    for i, v in ipairs(dyn_char) do -- look for matching dynamic
                        local target = math.min(math.max(1, i + shift), #dyn_char)
                        if str.LuaString == utf8.char(v) then -- dynamic match
                            if found[target] then -- replacement exists
                                e:SetID(found[target]):Save()
                            else -- create new dynamic
                                if not config.create_new then -- ask permission
                                    config.create_new = create_dynamics_alert(dialog)
                                end
                                if config.create_new then -- create missing dynamic exp_def
                                    found[target] = create_exp_def(utf8.char(dyn_char[target]))
                                    e:SetID(found[target]):Save()
                                end
                            end
                            break
                        end
                    end
                end
            end
        end
    end
    finenv.EndUndoBlock(true)
    finenv.Region():Redraw()
end

local function run_the_dialog()
    local y, m_offset = 0, finenv.UI():IsOnMac() and 3 or 0
    local save
    local ctl = {}
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(name:sub(1, 7))
        -- local functions
        local function yd(diff) y = y + (diff or 20) end
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. name, 300, 200)
        end
        local function cstat(horiz, vert, wide, str) -- dialog static text
            return dialog:CreateStatic(horiz, vert):SetWidth(wide):SetText(str)
        end
        local function flip_direction()
            local n = ctl.direction:GetSelectedItem()
            ctl.direction:SetSelectedItem((n + 1) % 2)
        end
        local function key_subs()
            local s = ctl.levels:GetText():lower()
            if s:find("[^1-9]") then
                if     s:find(hotkey.show_info) then show_info()
                elseif s:find(hotkey.direction) then flip_direction()
                end
            else
                save = s:sub(-1)
            end
            ctl.levels:SetText(save)
        end
        local function on_timer() -- track changes in selected region
            for k, v in pairs(saved_bounds) do
                if finenv.Region()[k] ~= v then -- selection changed
                    track_selection() -- update selection tracker
                    break -- all done
                end
            end
        end
    ctl.title = cstat(10, y, 120, name:upper())
    yd()
    -- RadioButtonGroup
    local labels = finale.FCStrings()
    labels:CopyFromStringTable({"Louder", "Softer"})
    ctl.direction = dialog:CreateRadioButtonGroup(0, y + 1, 2)
        :SetText(labels):SetWidth(55):SetSelectedItem(config.direction)
    local softer = ctl.direction:GetItemAt(1) -- 2nd button
    softer:SetTop(y + 24)
    cstat(23, y + 11, 25, "(" .. hotkey.direction .. ")")
    -- levels
    cstat(65, y, 55, "Levels:")
    save = config.levels
    ctl.levels = dialog:CreateEdit(110, y - m_offset):SetText(config.levels):SetWidth(20)
        :AddHandleCommand(function() key_subs() end)
    yd(21)
    ctl.q = dialog:CreateButton(110, y):SetText("?"):SetWidth(20)
       :AddHandleCommand(function() show_info() end)
    -- wrap it up
    dialog:CreateOkButton():SetText("Apply")
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        self:SetTimer(config.timer_id, 125)
        local bold = ctl.q:CreateFontInfo():SetBold(true)
        ctl.q:SetFont(bold)
        ctl.title:SetFont(bold)
    end)
    dialog_set_position(dialog)
    dialog:RegisterHandleTimer(on_timer)
    dialog:RegisterHandleOkButtonPressed(function()
        config.direction = ctl.direction:GetSelectedItem()
        config.levels = ctl.levels:GetInteger()
        change_dynamics(dialog)
    end)
    dialog:RegisterCloseWindow(function(self)
        self:StopTimer(config.timer_id)
        dialog_save_position(self)
    end)
    dialog:RunModeless()
end

local function dynamic_levels()
    configuration.get_user_settings(script_name, config, true)
    local qim = finenv.QueryInvokedModifierKeys
    local mod_key = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))
    track_selection() -- track current selected region
    --
    if mod_key then
        change_dynamics(nil)
    else
        run_the_dialog()
    end
end

dynamic_levels()
