function plugindef()
    finaleplugin.RequireSelection = true
    finaleplugin.Author = "Robert Patterson"
    finaleplugin.Copyright = "CC0 https://creativecommons.org/publicdomain/zero/1.0/"
    finaleplugin.Version = "1.1"
    finaleplugin.Date = "March 20, 2021"
    finaleplugin.CategoryTags = "Expression"
    return "Expression Add Opaque Background", "Expression Add Opaque Background", "Add an opaque background to any single-staff text expression in the currenly selected region."
end

local library = require("library.general_library")
local expression = require("library.expression")

-- note: if an expression already has an enclosure, this routine simply makes it opaque

-- As of June 22, 2020 the PDK Framework does not export the constructor for FCEnclosure into JW Lua, so we have to
-- find an existing enclosure to copy. Hopefully we can dispense with this hack at some point,
-- hence it is not in the main routine.

-- RGP Lua v0.60 added the ability to create FCEnclosure instances.

local can_create_enclosures = finenv.MajorVersion > 0 or finenv.MinorVersion >= 60

local found_enclosure = nil
if not can_create_enclosures then
    local text_expression_defs = finale.FCTextExpressionDefs()
    text_expression_defs:LoadAll()
    for text_expression_def in each(text_expression_defs) do
        if text_expression_def.UseEnclosure then
            found_enclosure = text_expression_def:CreateEnclosure()
            if (nil ~= found_enclosure) then
                break
            end
        end
    end
    if (nil == found_enclosure) then
        finenv.UI():AlertNeutral("Please create or modify any text expression to have an enclosure, and then rerun this script.", "Create Enclosure Needed")
        return
    end
end

function expression_add_opaque_background()
    local current_part = library.get_current_part()
    local expression_assignments = finale.FCExpressions()
    expression_assignments:LoadAllForRegion(finenv.Region())
    for expression_assignment in each(expression_assignments) do
        if not expression_assignment:IsShape() and expression_assignment:IsSingleStaffAssigned() then
            if expression.is_for_current_part(expression_assignment, current_part) then
                local expression_def = finale.FCTextExpressionDef()
                if expression_def:Load(expression_assignment.ID) then
                    if not expression_def.UseEnclosure then -- this prevents us from modifying existing enclosures
                        local enclosure = found_enclosure
                        if can_create_enclosures then
                            enclosure = finale.FCEnclosure()
                        end
                        enclosure.FixedSize = false
                        enclosure.HorizontalMargin = 0
                        enclosure.HorizontalOffset = 0
                        enclosure.LineWidth = 0
                        enclosure.Mode = finale.ENCLOSUREMODE_NONE
                        enclosure.Opaque = true
                        enclosure.RoundedCornerRadius = 0
                        enclosure.RoundedCorners = false
                        enclosure.Shape = finale.ENCLOSURE_RECTANGLE
                        enclosure.VerticalMargin = 0
                        enclosure.VerticalOffset = 0
                        if enclosure:SaveAs(expression_def.ItemNo) then
                            expression_def:SetUseEnclosure(true)
                        end
                    else
                        local my_enclosure = expression_def:CreateEnclosure()
                        if (nil ~= my_enclosure) then
                            my_enclosure.Opaque = true
                            my_enclosure:Save()
                        end
                    end
                    expression_def:Save()
                end
            end
        end
    end
end

expression_add_opaque_background()
