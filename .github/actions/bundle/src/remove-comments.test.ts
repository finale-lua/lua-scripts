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
    __imports["library.client"] = function()
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
    __imports["library.client"] = function()

        local client = {}
        local function to_human_string(feature)
            return string.gsub(feature, "_", " ")
        end`,
    ],
]

it.each(tests)(`removeComments(%p)`, (input, expected) => {
    expect(removeComments(input)).toBe(expected)
})
