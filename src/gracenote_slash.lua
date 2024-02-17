function plugindef()
    finaleplugin.RequireSelection = false
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "0.84"
    finaleplugin.Date = "2024/02/08"
    finaleplugin.AdditionalMenuOptions = [[
        Gracenote Slash Configuration...
    ]]
    finaleplugin.AdditionalUndoText = [[
        Gracenote Slash Configuration
    ]]
    finaleplugin.AdditionalDescriptions = [[
        Configure Gracenote Slash parameters
    ]]
    finaleplugin.AdditionalPrefixes = [[
        slash_configure = true
    ]]
    finaleplugin.CategoryTags = "Articulation"
    finaleplugin.MinJWLuaVersion = 0.70
    finaleplugin.Notes = [[
        This script adds a diagonal "slash" to the start of 
        every beamed group of grace notes in the current selection. 
        It emulates Jari Williamsson's 2017 
        _JWGraceNoteSlash_ (http://finaletips.nu/index.php/download/) 
        plug-in to work on Macs with non-Intel processors, 
        but also offers customised angle, size and placement options, 
        optional slashing of single grace notes and filtering by layer. 

        Unchecking _Slash Single Grace Notes_ will _remove_ slashes 
        on individual (unbeamed) notes, but only if 
        _Always Slash Flagged Grace Notes_ is __not__ selected 
        at _Document_ → _Document Options..._ → _Grace Notes_.

        To change script parameters use the _Configuration_ menu 
        or hold down [Shift] when opening the script. 

        > __Key Commands:__ 

        > - __g__: toggle "slash single grace notes" 
        > - __z__: restore default values 
        > - __q__: display these notes 
        > - __0-4__: layer number (delete key not needed)  
        > - To change measurement units: 
        > - __e__ - EVPUs; __i__ - Inches; __c__ - Centimeters; 
        > - __o__ - Points; __a__ - Picas; __s__ - Spaces; 
    ]]
    return "Gracenote Slash", "Gracenote Slash",
        "Add a slash to beamed gracenote groups in the current selection"
end

slash_configure = slash_configure or false

local configuration = require("library.configuration")
local mixin = require("library.mixin")
local layer = require("library.layer")
local utils = require("library.utils")
local library = require("library.general_library")
local script_name = library.calc_script_name()
local refocus_document = false -- set to true if utils.show_notes_dialog is used

local config = {
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    slash_single = 0,
    layer_num = 0,
    window_pos_x = false,
    window_pos_y = false,
}

local defaults = { -- + pre-populate config with these values
    upstem_line_width = 2.25, -- EFIX (float) value
    upstem_y_start = 0,
    upstem_line_to_x = 36,
    upstem_line_to_y = 44,
    upstem_slash_x_offset = 4,
    upstem_slash_y_offset = -32,
    downstem_line_width = 2.25, -- EFIX (float) value
    downstem_y_start = 44,
    downstem_line_to_x = 36,
    downstem_line_to_y = -44,
    downstem_slash_x_offset = -8,
    downstem_slash_y_offset = 8
}
for k, v in pairs(defaults) do config[k] = v end -- populate config

-- set "upstem_" and "downstem_" versions of these parameters in this order ...
local dialog_options = { -- key; text description
    { "line_width", "Width of Slash Line" }, -- floating point EFIX
    { "y_start", "Vertical Offset at Start of Slash Shape" },
    { "line_to_x", "Horizontal Length of Slash Line" },
    { "line_to_y", "Vertical Length of Slash Line" },
    { "slash_x_offset", "Slash Horizontal Offset" },
    { "slash_y_offset", "Slash Vertical Offset" }
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

local function make_slash_definition(stem) -- (stem == "upstem_" or "downstem_")
    local shape = finale.FCShapeDef()
    local shape_inst = shape:CreateInstructions()
    shape_inst:AddStartObject(finale.FCPoint(0, 0),
        finale.FCPoint(0, 64),
        finale.FCPoint(64, 0), 1000, 1000, 0)
    shape_inst:AddRMoveTo(0, config[stem .. "y_start"])
    shape_inst:AddLineWidth(config[stem .. "line_width"] * 64)
    shape_inst:AddSetDash(18, 0) -- solid line
    shape_inst:AddRLineTo(config[stem .. "line_to_x"], config[stem .. "line_to_y"])
    shape_inst:AddStroke()
    shape_inst:AddNull()
    shape:RebuildInstructions(shape_inst)
    shape:SaveNewWithType(finale.SHAPEDEFTYPE_ARTICULATION)
    shape_inst:ClearAll()

    local art_def = mixin.FCMArticulationDef()
    art_def:SetMainSymbolIsShape(true)
        :SetMainSymbolShapeID(shape.ItemNo)
        :SetAboveUsesMain(true)
        :SetBelowUsesMain(true)
        :SetAutoPosSide(finale.ARTPOS_ALWAYS_STEM_SIDE)
        :SetCenterHorizontally(false)
        :SetAlwaysPlaceOutsideStaff(false)
        :SaveNew()
    return art_def
end

local function add_slashes()
    local new_slash = { } -- need a different slash shape for upstem and downstem groups
    for entry in eachentrysaved(finenv.Region(), config.layer_num) do
        if entry.GraceNote then
            if entry:CalcUnbeamedNote() then
                if entry.Duration < finale.QUARTER_NOTE then
                    entry.GraceNoteSlash = (config.slash_single == 1)
                end
            elseif (entry:CalcGraceNoteIndex() == 0) then
                local stem = entry.StemUp and "upstem_" or "downstem_"
                if not new_slash[stem] then -- often only need upstem slash
                    new_slash[stem] = make_slash_definition(stem)
                end
                local art = finale.FCArticulation()
                art:SetNoteEntry(entry)
                art:SetArticulationDef(new_slash[stem])
                art.HorizontalPos = config[stem .. "slash_x_offset"]
                art.VerticalPos = config[stem .. "slash_y_offset"]
                art:SaveNew()
            end
        end
    end
end

local function user_sets_parameters()
    local dialog = mixin.FCXCustomLuaWindow():SetTitle(plugindef() .. " Configuration")
    dialog:SetMeasurementUnit(config.measurement_unit)
    local max = layer.max_layers()
    local y_step, y_pos = 18, 0
    local max_wide = 200
    local x_offset = { 0, 50, 130, 200 }
    local answer, saved = {}, {}
        -- local functions
        local function show_info()
            utils.show_notes_dialog(dialog, "About " .. plugindef(), 500, 300)
            refocus_document = true
        end
        local function update_saved()
            for k, _ in pairs(defaults) do
                saved[k] = answer[k]:GetText()
            end
        end
        local function change_measurement_unit(str)
            local units = { -- triggered by keystroke within "[eicoas]"
                e = finale.MEASUREMENTUNIT_EVPUS,       i = finale.MEASUREMENTUNIT_INCHES,
                c = finale.MEASUREMENTUNIT_CENTIMETERS, o = finale.MEASUREMENTUNIT_POINTS,
                a = finale.MEASUREMENTUNIT_PICAS,       s = finale.MEASUREMENTUNIT_SPACES,
            }
            for k, v in pairs(units) do
                if str:find(k) then
                    dialog:SetMeasurementUnit(v)
                    answer.popup:UpdateMeasurementUnit()
                    update_saved()
                    break
                end
            end
        end
        local function restore_defaults()
            for k, v in pairs(defaults) do
                if string.find(k, "width") then answer[k]:SetMeasurement(v)
                else answer[k]:SetMeasurementInteger(v)
                end
                update_saved()
            end
        end
        local function key_check(name)
            local ctl = answer[name]
            local s = ctl:GetText():lower()
            -- any "control" character keys?
            if      (s:find("p") and dialog:GetMeasurementUnit() ~= finale.MEASUREMENTUNIT_PICAS)
                    or s:find("[^-.p0-9]")
                    or (name == "layer_num" and s:find("[^0-" .. max .. "]"))
                    then
                if s:find("z") then restore_defaults()
                elseif s:find("g") then -- toggle "slash singles" checkbox
                    local n = answer.slash_single:GetCheck()
                    answer.slash_single:SetCheck((n + 1) % 2)
                elseif s:find("[?q]") then show_info()
                elseif s:find("[eicoas]") then
                    ctl:SetText(saved[name])
                    change_measurement_unit(s)
                end
                ctl:SetText(saved[name])
            elseif s ~= "" then -- save new "clean" number
                if name == "layer_num" then s = s:sub(-1) -- layer number single digit
                else
                    if s == "." then s = "0." -- leading zero for offset numbers
                    elseif s == "-." then s = "-0."
                    end
                end
                ctl:SetText(s)
                saved[name] = s
            end
        end

    answer.q = dialog:CreateButton(x_offset[4] + max_wide - 27, y_pos):SetText("?"):SetWidth(20)
        :AddHandleCommand(function() show_info() end)
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- vertical offset for Mac Edit
    for _, stem in ipairs{"upstem", "downstem"} do
        answer[stem] = dialog:CreateStatic(x_offset[1], y_pos):SetWidth(max_wide)
            :SetText(stem:upper() .. " VALUES:")
        y_pos = y_pos + y_step
        for i, v in ipairs(dialog_options) do -- run twice through config parameters
            dialog:CreateStatic(x_offset[2], y_pos):SetWidth(80)
                :SetText(v[1]:gsub("_", " ") .. ":")
            dialog:CreateStatic(x_offset[4], y_pos):SetWidth(max_wide)
                :SetText(v[2])
            local name = stem .. "_" .. v[1]
            answer[name] = dialog.CreateMeasurementEdit(dialog, x_offset[3], y_pos - mac_offset)
                :AddHandleCommand(function() key_check(name) end):SetWidth(60)
            if i == 1 then -- item 1 "line_width" is EFIX
                answer[name]:SetTypeMeasurement():SetMeasurement(config[name])
            else -- measurement integers
                answer[name]:SetTypeMeasurementInteger():SetMeasurementInteger(config[name])
            end
            saved[name] = answer[name]:GetText() -- save "measured" values
            y_pos = y_pos + y_step
        end
        y_pos = y_pos + (y_step / 2)
        dialog:CreateHorizontalLine(x_offset[2], y_pos - 5, 345)
    end

    y_pos = y_pos + 4
    saved.layer_num = config.layer_num
    answer.layer_num = dialog:CreateEdit(x_offset[3], y_pos - mac_offset):SetText(config.layer_num)
        :AddHandleCommand(function() key_check("layer_num") end):SetWidth(20)
    dialog:CreateStatic(x_offset[2], y_pos):SetWidth(80):SetText("only on layer:")
    dialog:CreateStatic(x_offset[3] + 25, y_pos):SetWidth(max_wide)
        :SetText("1 - " .. max .. " (0 = all)")
    dialog:CreateButton(x_offset[4] + max_wide - 122, y_pos):SetText("Restore Defaults (z)")
        :AddHandleCommand(function() restore_defaults() end):SetWidth(115)
    y_pos = y_pos + 22
    dialog:CreateStatic(x_offset[3] - 40, y_pos):SetText("Units:")
    answer.popup = dialog:CreateMeasurementUnitPopup(x_offset[3], y_pos):SetWidth(90)
        :AddHandleCommand(function() update_saved() end)
    answer.slash_single = dialog:CreateCheckbox(x_offset[3] + 98, y_pos):SetWidth(165)
        :SetText("Slash Single Grace Notes (g)"):SetCheck(config.slash_single)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function()
        answer.upstem_line_width:SetKeyboardFocus()
        local bold = answer.upstem:CreateFontInfo():SetBold(true)
        answer.upstem:SetFont(bold)
        answer.downstem:SetFont(bold)
        answer.q:SetFont(bold)
    end)
    dialog:RegisterCloseWindow(function(self) dialog_save_position(self) end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        for k, _ in pairs(defaults) do
            local a = answer[k]
            config[k] = k:find("width") and a:GetMeasurement() or a:GetMeasurementInteger()
        end
        config.measurement_unit = self:GetMeasurementUnit()
        config.slash_single = answer.slash_single:GetCheck()
        config.layer_num = answer.layer_num:GetInteger()
    end)
    dialog_set_position(dialog)
    return (dialog:ExecuteModal() == finale.EXECMODAL_OK)
end

local function main()
    configuration.get_user_settings(script_name, config) -- overwrite saved user prefs
    local qim = finenv.QueryInvokedModifierKeys
    local mod_down = qim and (qim(finale.CMDMODKEY_ALT) or qim(finale.CMDMODKEY_SHIFT))

    local ok = true
    if slash_configure or mod_down then
        ok = user_sets_parameters()
    end
    if ok and not slash_configure then
        if finenv.Region():IsEmpty() then
            finenv.UI():AlertError("Please select some music\n"
                .. "before running \"" .. plugindef() .. "\"", "Error")
        else
            add_slashes()
        end
    end
    if refocus_document then finenv.UI():ActivateDocumentWindow() end
end

main()
