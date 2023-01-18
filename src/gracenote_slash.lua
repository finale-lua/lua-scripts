function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Carl Vine"
    finaleplugin.AuthorURL = "http://carlvine.com/lua/"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "v0.59"
    finaleplugin.Date = "2023/01/18"
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
        This script duplicates Jari Williamsson's original JWGraceNoteSlash plug-in (2017) so it can be 
        incorporated into modern operating systems through RGPLua or similar. 

        An additional `Configuration` menu item is provided to change the script's default settings. 
        They can also be changed by holding down either the `shift` or `alt` (option) key when calling the script.
    ]]
    return "Gracenote Slash", "Gracenote Slash", "Add a slash to beamed gracenote groups in the current selection"
end

slash_configure = slash_configure or false
local configuration = require("library.configuration")
local mixin = require("library.mixin")

local config = { -- in EVPUs
    upstem_line_width = 2.25,
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

    local slash_definition = finale.FCArticulationDef()
    local def_values = {
        MainSymbolIsShape = true,
        MainSymbolShapeID = shape.ItemNo,
        AboveUsesMain = true,
        BelowUsesMain = true,
        AutoPosSide = finale.ARTPOS_ALWAYS_STEM_SIDE,
        CenterHorizontally = false,
        AlwaysPlaceOutsideStaff = false,
    }
    for k, v in pairs(def_values) do
        slash_definition[k] = v
    end
    slash_definition:SaveNew()
    return slash_definition
end

function add_slashes()
    local new_slash = { } -- need a different slash shape for upstems and downstem groups
    for entry in eachentrysaved(finenv.Region()) do
        if entry.GraceNote and entry:Next().GraceNote and entry:CalcGraceNoteIndex() == 0 then
            local stem = entry.StemUp and "upstem_" or "downstem_"
            if not new_slash[stem] then -- normally need only upstem slash
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

function user_sets_parameters()
    -- set "upstem_" and "downstem_" versions of parameters in this order ...
    local dialog_options = { -- key value from config => text description
        {"line_width", "width of slash line"},
        {"y_start", "vertical offset at start of slash shape"},
        {"line_to_x", "horizontal length of slash line"},
        {"line_to_y", "vertical length of slash line"},
        {"artic_x_offset", "articulation horizontal offset"},
        {"artic_y_offset", "articulation vertical offset"},
    }
    local efix_value = { line_width = true }
    
    local dialog = mixin.FCXCustomLuaWindow():SetTitle("Gracenote Slash Configuration")
    dialog:SetMeasurementUnit(config.measurement_unit)
    local y_step, y_current = 20, 0
    local max_width = 200
    local x_offset = {0, 50, 130, 200}
    local mac_offset = finenv.UI():IsOnMac() and 3 or 0 -- vertical offset for Mac Edit boxes

    for _, stem in ipairs({"upstem", "downstem"}) do
        dialog:CreateStatic(x_offset[1], y_current)
            :SetText(string.upper(stem) .. " VALUES:")
            :SetWidth(x_offset[3])
        y_current = y_current + y_step
        for _, v in ipairs(dialog_options) do -- run twice through config parameters
            dialog:CreateStatic(x_offset[2], y_current)
                :SetText(string.gsub(v[1], "_", " ") .. ":")
                :SetWidth(x_offset[3] - x_offset[2])
            dialog:CreateStatic(x_offset[4], y_current)
                :SetText(v[2])
                :SetWidth(max_width)
            local name = stem .. "_" .. v[1]
            local edit = dialog.CreateMeasurementEdit(dialog, x_offset[3], y_current - mac_offset, name)
            if efix_value[v[1]] then
                edit:SetTypeMeasurement() -- EFIX values need decimal precision
            else
                edit:SetTypeMeasurementInteger() -- the rest are integer EVPUs
            end
            edit:SetMeasurement(config[name]):SetWidth(60)
            y_current = y_current + y_step
        end
        y_current = y_current + (y_step / 2)
    end

    -- measurement unit options
    dialog:CreateStatic(x_offset[3] - 40, y_current):SetText("Units:")
    dialog:CreateMeasurementUnitPopup(x_offset[3], y_current)

    dialog:CreateOkButton()
    dialog:CreateCancelButton()
    dialog:RegisterHandleOkButtonPressed(
        function(self)
            for _, stem in ipairs({"upstem_", "downstem_"}) do
                for _, v in ipairs(dialog_options) do
                    local edit = self:GetControl(stem .. v[1])
                    config[stem .. v[1]] = efix_value[v[1]] and edit:GetMeasurement() or edit:GetMeasurementInteger()
                end
            end
            config.measurement_unit = self:GetMeasurementUnit()
            self:StorePosition()
            config.window_pos_x = self.StoredX
            config.window_pos_y = self.StoredY
            configuration.save_user_settings("gracenote_slash", config)
        end
    )
    ------------------
    if config.window_pos_x and config.window_pos_y then
        dialog:StorePosition()
        dialog:SetRestorePositionOnlyData(config.window_pos_x, config.window_pos_y)
        dialog:RestorePosition()
    end
    local ok = (dialog:ExecuteModal(nil) == finale.EXECMODAL_OK)
    return ok
end

function main()
    configuration.get_user_settings("gracenote_slash", config) -- overwrite config with saved user preferences
    local mod_down = finenv.QueryInvokedModifierKeys and (finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_ALT) or finenv.QueryInvokedModifierKeys(finale.CMDMODKEY_SHIFT))
    local ok = true
    if slash_configure or mod_down then
        ok = user_sets_parameters()
    end
    if not slash_configure and ok then
        add_slashes()
    end
end

main()
