function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "https://carlvine.com/lua/"
    finaleplugin.Copyright = "https://creativecommons.org/licenses/by/4.0/"
    finaleplugin.Version = "v0.67"
    finaleplugin.Date = "2023/06/19"
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
    finaleplugin.Notes = [[
        This script duplicates Jari Williamsson's original 2017 JWGraceNoteSlash plug-in so it can be 
        incorporated into modern operating systems through RGPLua. 

        A `Configuration` menu item is provided to change the script's parameters. 
        They can also be changed by holding down either the SHIFT or ALT (option) key when calling the script.
    ]]
    return "Gracenote Slash", "Gracenote Slash", "Add a slash to beamed gracenote groups in the current selection"
end

slash_configure = slash_configure or false
local configuration = require("library.configuration")
local mixin = require("library.mixin")
local script_name = "gracenote_slash"

local config = { -- in EVPUs
    upstem_line_width = 2.25, -- float value
    upstem_y_start = 0,
    upstem_line_to_x = 36,
    upstem_line_to_y = 44,
    upstem_artic_x_offset = 4,
    upstem_artic_y_offset = -32,
    --
    downstem_line_width = 2.25,
    downstem_y_start = 44,
    downstem_line_to_x = 36,
    downstem_line_to_y = -44,
    downstem_artic_x_offset = -8,
    downstem_artic_y_offset = 8,
    --
    measurement_unit = finale.MEASUREMENTUNIT_DEFAULT,
    window_pos_x = false,
    window_pos_y = false,
}

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

function make_slash_definition(stem) -- (stem == "upstem_" or "downstem_")
    local shape = finale.FCShapeDef()
    local shape_inst = shape:CreateInstructions()
    shape_inst:AddStartObject( finale.FCPoint(0, 0), finale.FCPoint(0, 64), finale.FCPoint(64, 0), 1000, 1000, 0)
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

function add_slashes()
    local new_slash = { } -- need a different slash shape for upstem and downstem groups
    for entry in eachentrysaved(finenv.Region()) do
        if entry.GraceNote then
            if entry:CalcUnbeamedNote() then
                entry.GraceNoteSlash = (entry.Duration < finale.QUARTER_NOTE)
            elseif (entry:CalcGraceNoteIndex() == 0) then
                local stem = entry.StemUp and "upstem_" or "downstem_"
                if not new_slash[stem] then -- often only need upstem slash
                    new_slash[stem] = make_slash_definition(stem)
                end
                local art = finale.FCArticulation()
                art:SetNoteEntry(entry)
                art:SetArticulationDef(new_slash[stem])
                art.HorizontalPos = config[stem .. "artic_x_offset"]
                art.VerticalPos = config[stem .. "artic_y_offset"]
                art:SaveNew()
            end
        end
    end
end

function user_sets_parameters()
    -- set "upstem_" and "downstem_" versions of parameters in this order ...
    local dialog_options = { -- key value from config => text description
        {"line_width", "width of slash line"}, -- FIRST value is floating point EFIX
        {"y_start", "vertical offset at start of slash shape"},
        {"line_to_x", "horizontal length of slash line"},
        {"line_to_y", "vertical length of slash line"},
        {"artic_x_offset", "articulation horizontal offset"},
        {"artic_y_offset", "articulation vertical offset"},
    }

    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Gracenote Slash Configuration")
    dialog:SetMeasurementUnit(config.measurement_unit)
    local y_step, y_pos = 18, 0
    local max_wide = 200
    local x_offset = { 0, 50, 130, 200 }
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- vertical offset for Mac Edit boxes

    for _, stem in ipairs({"upstem", "downstem"}) do
        dialog:CreateStatic(x_offset[1], y_pos):SetWidth(max_wide):SetText(string.upper(stem) .. " VALUES:")
        y_pos = y_pos + y_step
        for i, v in ipairs(dialog_options) do -- run twice through config parameters
            dialog:CreateStatic(x_offset[2], y_pos):SetWidth(80):SetText(string.gsub(v[1], "_", " ") .. ":")
            dialog:CreateStatic(x_offset[4], y_pos):SetWidth(max_wide):SetText(v[2])
            local name = stem .. "_" .. v[1]
            local edit = dialog.CreateMeasurementEdit(dialog, x_offset[3], y_pos - mac_offset, name):SetWidth(60)
            if i == 1 then -- item 1 "line_width" is EFIX
                edit:SetTypeMeasurement():SetMeasurement(config[name])
            else -- EVPU integers
                edit:SetTypeMeasurementInteger():SetMeasurementInteger(config[name])
            end
            y_pos = y_pos + y_step
        end
        y_pos = y_pos + (y_step / 2)
    end

    -- measurement unit options
    dialog:CreateStatic(x_offset[3] - 40, y_pos):SetText("Units:")
    dialog:CreateMeasurementUnitPopup(x_offset[3], y_pos)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterInitWindow(function(self)
        local first_edit = self:GetControl("upstem_" .. dialog_options[1][1])
        first_edit:SetKeyboardFocus()
    end)
    dialog:RegisterHandleOkButtonPressed(function(self)
        for _, stem in ipairs({"upstem_", "downstem_"}) do
            for i, v in ipairs(dialog_options) do
                local edit = self:GetControl(stem .. v[1])
                config[stem .. v[1]] = (i == 1) and edit:GetMeasurement() or edit:GetMeasurementInteger()
            end
        end
        config.measurement_unit = self:GetMeasurementUnit()
        dialog_save_position(self)
    end)
    dialog_set_position(dialog)
    return (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
end

function main()
    configuration.get_user_settings(script_name, config) -- overwrite config with saved user preferences
    local mod_down = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    local ok = true
    if slash_configure or mod_down then
        ok = user_sets_parameters()
    end
    if ok and not slash_configure then
        add_slashes()
    end
end

main()
