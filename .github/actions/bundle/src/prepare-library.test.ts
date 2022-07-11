import type { LibraryInput } from './prepare-library'
import { LIBRARY_VARIABLE_NAME, prepareLibrary, prepareLibraryFile } from './prepare-library'

const articulationFile = `
--[[
$module Articulation
]]
local articulation = {}
--[[
% delete_from_entry_by_char_num(entry, char_num)
Removes any articulation assignment that has the specified character as its above-character.
@ entry (FCNoteEntry)
@ char_num (number) UTF-32 code of character (which is the same as ASCII for ASCII characters)
]]
function articulation.delete_from_entry_by_char_num(entry, char_num)
    local artics = entry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetAboveSymbolChar() == char_num then
            a:DeleteData()
        end
    end
end
return articulation`

const preparedArticulationFile = `
--[[
$module Articulation
]]
local ${LIBRARY_VARIABLE_NAME} = {}
--[[
% delete_from_entry_by_char_num(entry, char_num)
Removes any articulation assignment that has the specified character as its above-character.
@ entry (FCNoteEntry)
@ char_num (number) UTF-32 code of character (which is the same as ASCII for ASCII characters)
]]
function ${LIBRARY_VARIABLE_NAME}.delete_from_entry_by_char_num(entry, char_num)
    local artics = entry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetAboveSymbolChar() == char_num then
            a:DeleteData()
        end
    end
end
`

const bundledArticulationFile = preparedArticulationFile

const expressionFile = `
--[[
$module Articulation
]]
local expression = {}
local articulation = require("library.articulation")
--[[
% delete_from_entry_by_char_num(entry, char_num)
Removes any articulation assignment that has the specified character as its above-character.
@ entry (FCNoteEntry)
@ char_num (number) UTF-32 code of character (which is the same as ASCII for ASCII characters)
]]
function expression.delete_from_entry_by_char_num(entry, char_num)
    local artics = entry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetAboveSymbolChar() == char_num then
            a:DeleteData()
        end
    end
end
return expression`

const bundledExpressionFile = `
--[[
$module Articulation
]]
local ${LIBRARY_VARIABLE_NAME} = {}
${bundledArticulationFile.replace(new RegExp(LIBRARY_VARIABLE_NAME, 'gu'), 'articulation')}
--[[
% delete_from_entry_by_char_num(entry, char_num)
Removes any articulation assignment that has the specified character as its above-character.
@ entry (FCNoteEntry)
@ char_num (number) UTF-32 code of character (which is the same as ASCII for ASCII characters)
]]
function ${LIBRARY_VARIABLE_NAME}.delete_from_entry_by_char_num(entry, char_num)
    local artics = entry:CreateArticulations()
    for a in eachbackwards(artics) do
        local defs = a:CreateArticulationDef()
        if defs:GetAboveSymbolChar() == char_num then
            a:DeleteData()
        end
    end
end
`

it('empty file stays empty', () => {
    const file = ''
    const { contents } = prepareLibraryFile(file, 'articulation')
    expect(contents).toBe('')
})

it('file name is replaced and remove the return statement', () => {
    const file = articulationFile
    const outputContents = preparedArticulationFile
    const { contents } = prepareLibraryFile(file, 'articulation')
    expect(contents).toBe(outputContents)
})

it('if it is not a library file, return the original contents', () => {
    const file = `hello world`

    const outputContents = `hello world`
    const { contents } = prepareLibraryFile(file, 'articulation')
    expect(contents).toBe(outputContents)
})

it('base case -- no library files', () => {
    const files: LibraryInput = []
    expect(prepareLibrary(files)).toStrictEqual({})
})

it('prepares all library files', () => {
    const files: LibraryInput = [
        {
            fileName: 'articulation',
            contents: articulationFile,
        },
        {
            fileName: 'expression',
            contents: expressionFile,
        },
    ]
    expect(prepareLibrary(files)).toStrictEqual({
        articulation: {
            contents: bundledArticulationFile,
        },
        expression: {
            contents: bundledExpressionFile,
        },
    })
})
