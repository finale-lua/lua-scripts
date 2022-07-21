import { getAllImports, getImport } from './helpers'

describe('detects valid imports', () => {
    const lines: [string, string][] = [
        ['local library = require("library.file_name")', 'library.file_name'],
        ['local library = require("Library.file_name")', 'Library.file_name'],
        ['local library = require("library.articulation")', 'library.articulation'],
        ['local library = require("library.Articulation")', 'library.Articulation'],
        ['local library = require("library.articulation") -- no path, no ""', 'library.articulation'],
        ['library = require("library.articulation")', 'library.articulation'],
        ['articulation = require("library.articulation")', 'library.articulation'],
        ['articulation   =    require("library.file_name")', 'library.file_name'],
        ["articulation   =    require('library.file_name')", 'library.file_name'],
        ['local library = require("not_library.file_name")', 'not_library.file_name'],
        ['local library = import("library.file_name")', ''],
        ['local library = require("library.")', 'library.'],
        ['local library = require("file_name")', 'file_name'],
    ]

    it.each(lines)('line "%s" imports "%s"', (line, importFile) => {
        const { importedFile, isImport } = getImport(line)
        expect(importedFile).toEqual(importFile)
        expect(isImport).toEqual(importFile !== '')
    })
})

describe('checks if file imports anything', () => {
    const lines: [string, string[]][] = [
        ['local library = require("library.file_name")', ['library.file_name']],
        ['this is some random text', []],
        [
            'local library = require("library.expression")\nlocal library = require("library.articulation")',
            ['library.expression', 'library.articulation'],
        ],
    ]

    it.each(lines)('line "%s" imports "%s"', (file, imports) => {
        expect(getAllImports(file)).toEqual(imports)
    })
})
