import { removeComments } from './remove-comments'

const tests: [string, string][] = [
    [`--[[]]`, ``],
    [`--[[hello world]]`, ``],
    [`--[[[[]]]]`, `]]`],
    [`--[[--[[]]]]`, `]]`],
    [`--[[]]--`, ``],
    [`--[[]]--\nhello world`, `\nhello world`],
    [`\n\n`, `\n`],
    [`\n\n\n`, `\n`],
    [`\n\n\n\n`, `\n`],
    [`\n\n\n\n\n`, `\n`],
    [`--[[\nhello\nworld\n]]`, ``],
    [`--[[\n--hello\nworld\n]]`, ``],
    [`hello world --[[\n--hello\nworld\n]]`, `hello world`],
    [`hello world -- this is a comment`, `hello world`],
    [` -- this is a comment\nhello world`, `\nhello world`],
    [
        `finaleplugin.AdditionalMenuOptions = [[  CrossStaff Offset No Dialog  ]] `,
        `finaleplugin.AdditionalMenuOptions = [[  CrossStaff Offset No Dialog  ]]`,
    ],
    [
        `finaleplugin.AdditionalMenuOptions = [[\n    CrossStaff Offset No Dialog\n]]`,
        `finaleplugin.AdditionalMenuOptions = [[\n    CrossStaff Offset No Dialog\n]]`,
    ],
    [
        `
    package.preload["library.client"] = function()
        --[[
        $module Client
        Get information about the current client. For the purposes of Finale Lua, the client is
        the Finale application that's running on someones machine. Therefore, the client has
        details about the user's setup, such as their Finale version, plugin version, and
        operating system.
        One of the main uses of using client details is to check its capabilities. As such,
        the bulk of this library is helper functions to determine what the client supports.
        ]] --
        local client = {}

        local function to_human_string(feature)
            return string.gsub(feature, "_", " ")
        end`,
        `
    package.preload["library.client"] = function()

        local client = {}
        local function to_human_string(feature)
            return string.gsub(feature, "_", " ")
        end`,
    ],
    [
        `

--[[
$module Note Entry
]] --
local note_entry = {}

--[[
% get_music_region
Returns an intance of \`FCMusicRegion\` that corresponds to the metric location of the input note entry.
@ entry (FCNoteEntry)
: (FCMusicRegion)
]]
function note_entry.get_music_region(entry)
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection() -- called to match the selected IU list (e.g., if using Staff Sets)
    exp_region.StartStaff = entry.Staff
    exp_region.EndStaff = entry.Staff
    exp_region.StartMeasure = entry.Measure
    exp_region.EndMeasure = entry.Measure
    exp_region.StartMeasurePos = entry.MeasurePos
    exp_region.EndMeasurePos = entry.MeasurePos
    return exp_region
end

-- entry_metrics can be omitted, in which case they are constructed and released here
-- return entry_metrics, loaded_here
local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
    if entry_metrics then
        return entry_metrics, false
    end
    entry_metrics = finale.FCEntryMetrics()
    if entry_metrics:Load(entry) then
        return entry_metrics, true
    end
    return nil, false
end

--[[
% get_evpu_notehead_height
Returns the calculated height of the notehead rectangle.
@ entry (FCNoteEntry)
: (number) the EVPU height
]]
function note_entry.get_evpu_notehead_height(entry)
    local highest_note = entry:CalcHighestNote(nil)
    local lowest_note = entry:CalcLowestNote(nil)
    local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12 -- 12 evpu per staff step; add 2 staff steps to accommodate for notehead height at top and bottom
    return evpu_height
end`,
        `

local note_entry = {}
function note_entry.get_music_region(entry)
    local exp_region = finale.FCMusicRegion()
    exp_region:SetCurrentSelection()
    exp_region.StartStaff = entry.Staff
    exp_region.EndStaff = entry.Staff
    exp_region.StartMeasure = entry.Measure
    exp_region.EndMeasure = entry.Measure
    exp_region.StartMeasurePos = entry.MeasurePos
    exp_region.EndMeasurePos = entry.MeasurePos
    return exp_region
end
local use_or_get_passed_in_entry_metrics = function(entry, entry_metrics)
    if entry_metrics then
        return entry_metrics, false
    end
    entry_metrics = finale.FCEntryMetrics()
    if entry_metrics:Load(entry) then
        return entry_metrics, true
    end
    return nil, false
end
function note_entry.get_evpu_notehead_height(entry)
    local highest_note = entry:CalcHighestNote(nil)
    local lowest_note = entry:CalcLowestNote(nil)
    local evpu_height = (2 + highest_note:CalcStaffPosition() - lowest_note:CalcStaffPosition()) * 12
    return evpu_height
end`,
    ],
    [
        `--[[
% is_note_side
Uses \`FCArticulation.CalcMetricPos\` to determine if the input articulation is on the note-side.
@ artic (FCArticulation)
@ [curr_pos] (FCPoint) current position of articulation that will be calculated if not supplied
: (boolean) true if on note-side, otherwise false
]]`,
        ''
    ],
    [`local comment_marker = "--"`, `local comment_marker = "--"`],
]

it.each(tests)(`removeComments(%p)`, (input, expected) => {
    expect(removeComments(input, true)).toBe(expected)
})

const dontTrimWhitespaceTests: [string, string][] = [
    [`\n\n`, `\n\n`],
    [`\n\n\n`, `\n\n\n`],
    [`\n\n\n\n`, `\n\n\n\n`],
    [`\n\n\n\n\n`, `\n\n\n\n\n`],
    [`--[[\nhello\nworld\n]]`, ``],
    [`--[[\n--hello\nworld\n]]`, ``],
]

it.each(dontTrimWhitespaceTests)(`removeComments(%p)`, (input, expected) => {
    expect(removeComments(input, false)).toBe(expected)
})