import { ImportedFiles, importFileBase, Library } from './bundle'

describe('importFile', () => {
    it('files can be imported', async () => {
        const fetcher = jest.fn(() => Promise.resolve("local hello = require('hello')"))
        let importedFilesMock: ImportedFiles = {}
        await importFileBase('my-lib', importedFilesMock, fetcher)

        expect(importedFilesMock['my-lib']).toEqual({
            importedFrom: new Set(),
            dependencies: new Set(['hello.lua']),
            wrapped: ['__imports["my-lib"] = function()', "    local hello = require('hello')", 'end'].join('\n'),
        })
    })
    it('files are imported only once', async () => {
        const fetcher = jest.fn(() => Promise.resolve("local hello = require('hello')"))
        let importedFilesMock: ImportedFiles = {}
        expect(await importFileBase('my-lib', importedFilesMock, fetcher)).toBe(true)
        expect(await importFileBase('my-lib', importedFilesMock, fetcher)).toBe(true)
        expect(fetcher).toBeCalledTimes(1)
    })
})

const library: Library = {
    articulation: {
        contents: `--[[
$module Articulation
]]
local BUNDLED_LIBRARY_VARIABLE_NAME = {}
function BUNDLED_LIBRARY_VARIABLE_NAME.method()
end`,
    },
    expression: {
        contents: `--[[
$module Articulation
]]
local BUNDLED_LIBRARY_VARIABLE_NAME = {}
function BUNDLED_LIBRARY_VARIABLE_NAME.method()
  -- does something
end`,
    },
}

it('bundles library if library exists', () => {
    const file = `
local library = require("library.articulation")
`

    const output = `
--[[
$module Articulation
]]
local library = {}
function library.method()
end
`
    // expect(bundleFile(file, library)).toEqual(output)
})

it('works with multiple imports', () => {
    const file = `
local articulation = require("library.articulation")
local expression = require("library.expression")
`

    const output = `
--[[
$module Articulation
]]
local articulation = {}
function articulation.method()
end
--[[
$module Articulation
]]
local expression = {}
function expression.method()
  -- does something
end
`
    // expect(bundleFile(file, library)).toEqual(output)
})
