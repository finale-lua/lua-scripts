import { getAllImports, getImport } from './helpers'

describe('detects valid imports', () => {
    const lines: [string, string][] = [
        ['local library = require("library.file_name")', 'library/file_name.lua'],
        ['local library = require("Library.file_name")', 'Library/file_name.lua'],
        ['local library = require("library.articulation")', 'library/articulation.lua'],
        ['local library = require("library.Articulation")', 'library/Articulation.lua'],
        ['local library = require("library.articulation") -- no path, no ".lua"', 'library/articulation.lua'],
        ['library = require("library.articulation")', 'library/articulation.lua'],
        ['articulation = require("library.articulation")', 'library/articulation.lua'],
        ['articulation   =    require("library.file_name")', 'library/file_name.lua'],
        ["articulation   =    require('library.file_name')", 'library/file_name.lua'],
        ['local library = require("not_library.file_name")', 'not_library/file_name.lua'],
        ['local library = import("library.file_name")', ''],
        ['local library = require("library.")', 'library.lua'],
        ['local library = require("file_name")', 'file_name.lua'],
    ]

    it.each(lines)('line "%s" imports "%s"', (line, importFile) => {
        const { importedFile, isImport } = getImport(line)
        expect(importedFile).toEqual(importFile)
        expect(isImport).toEqual(importFile !== '')
    })
})

describe('checks if file imports anything', () => {
    const lines: [string, Set<string>][] = [
        ['local library = require("library.file_name")', new Set(['library/file_name.lua'])],
        ['this is some random text', new Set()],
        [
            'local library = require("library.expression")\nlocal library = require("library.articulation")',
            new Set(['library/expression.lua', 'library/articulation.lua']),
        ],
    ]

    it.each(lines)('line "%s" imports "%s"', (file, imports) => {
        expect(getAllImports(file)).toEqual(imports)
    })
})
