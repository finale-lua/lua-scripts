function plugindef()
    -- This function and the 'finaleplugin' namespace
    -- are both reserved for the plug-in definition.
    finaleplugin.Author = "Jacob Winkler"
    finaleplugin.Copyright = "2022"
    finaleplugin.Version = "1.0"
    finaleplugin.Date = "2022-09-03"
    finaleplugin.AuthorEmail = "jacob.winkler@mac.com"
    finaleplugin.AdditionalMenuOptions = [[
    Dynamics 2: Position Above Staff
    Dynamics 3: Position Below Staff
    Dynamics 4: Align
    Dynamics 5: Nudge Up
    Dynamics 6: Nudge Down
    ]]
    finaleplugin.AdditionalUndoText = [[
    Dynamics: Position Above Staff
    Dynamics: Position Below Staff
    Dynamics: Align
    Dynamics: Nudge Up
    Dynamics: Nudge Down
    ]]
    finaleplugin.AdditionalDescriptions = [[
    Positions Dynamics Above Staff
    Positions Dynamics Below Staff
    Aligns Dynamics
    Nudges Dynamics Up .75 space
    Nudges Dynamics Down .75 space
    ]]
    finaleplugin.AdditionalPrefixes = [[
    mode = "above"
    mode = "below"
    mode = "align"
    mode = "nudge_up"
    mode = "nudge_down"
    ]]
    return "Dynamics 1: Auto Position", "Dynamics: Auto Position", "Position Dynamics Automatically"
end

mode = mode or "auto"
local nudge_amount = 18

local cushions = {
    staff_below = nil,
    entry_below = nil,
    staff_above = nil,
    entry_above = nil,
    staff_above_add_off = nil,
    entry_above_add_off = nil,
    exp_left = nil,
    exp_right = nil,
    hairpin_vert_off = nil
}

local metrics = require("library.metrics")
local dynamics = require("library.dynamics")

local region = finenv.Region()

if mode == "nudge_up" then
    dynamics.nudge(region, nudge_amount)
elseif  mode == "nudge_down" then
    dynamics.nudge(region, -nudge_amount)
else
    dynamics.set_vertical_pos(region, mode, cushions)
end
