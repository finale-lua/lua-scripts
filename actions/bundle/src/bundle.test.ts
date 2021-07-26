import { getImport, getVariableName } from './bundle'

describe('detects valid imports', () => {
    const lines: [string, string][] = [
        ['local library = require("library.file_name")', 'file_name'],
        ['local library = require("library.articulation")', 'articulation'],
        ['local library = require("library.articulation") -- no path, no ".lua"', 'articulation'],
        ['library = require("library.articulation")', 'articulation'],
        ['articulation = require("library.articulation")', 'articulation'],
        ['articulation   =    require("library.file_name")', 'file_name'],
        ["articulation   =    require('library.file_name')", 'file_name'],
        ['local library = require("not_library.file_name")', ''],
        ['local library = import("library.file_name")', ''],
        ['local library = require("library.")', ''],
        ['local library = require("file_name")', ''],
    ]

    it.each(lines)('line "%s" imports "%s"', (line, importFile) => {
        const { file, isImport } = getImport(line)
        expect(file).toEqual(importFile)
        expect(isImport).toEqual(importFile !== '')
    })
})

describe('gets the defined variable name', () => {
    const lines: [string, string][] = [
        ['local library = require("library.file_name")', 'library'],
        ['local library = require("library.articulation") -- no path, no ".lua"', 'library'],
        ['library = require("library.articulation")', 'library'],
        ['articulation = require("library.articulation")', 'articulation'],
        ['articulation   =    require("library.file_name")', 'articulation'],
        ["articulation   =    require('library.file_name')", 'articulation'],
    ]

    it.each(lines)('line "%s" imports "%s"', (line, variableName) => {
        expect(getVariableName(line)).toEqual(variableName)
    })
})
