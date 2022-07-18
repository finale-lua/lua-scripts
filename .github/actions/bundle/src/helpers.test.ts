import { getAllImports, getImport, getVariableName } from './helpers'

describe('detects valid imports', () => {
    const lines: [string, string][] = [
        ['local library = require("library.file_name")', 'file_name'],
        ['local library = require("Library.file_name")', 'file_name'],
        ['local library = require("library.articulation")', 'articulation'],
        ['local library = require("library.Articulation")', 'Articulation'],
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
        const { importedFile, isImport } = getImport(line)
        expect(importedFile).toEqual(importFile)
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

describe('checks if file imports anything', () => {
    const lines: [string, Set<string>][] = [
        ['local library = require("library.file_name")', new Set(['file_name'])],
        ['this is some random text', new Set()],
        [
            'local library = require("library.expression")\nlocal library = require("library.articulation")',
            new Set(['expression', 'articulation']),
        ],
    ]

    it.each(lines)('line "%s" imports "%s"', (file, imports) => {
        expect(getAllImports(file)).toEqual(imports)
    })
})
