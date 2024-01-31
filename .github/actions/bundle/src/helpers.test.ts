import { getAllImports, getFileParts, getImport } from './helpers'

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
        ['local library = require"library.articulation"', 'library.articulation'],
        ['local library = require\'library.articulation\'', 'library.articulation'],
        ['local library = require "library.articulation"', 'library.articulation'],
        ['local library = require \'library.articulation\'', 'library.articulation'],
        ['local library = __original_require("library.file_name")', 'library.file_name'],
        ['local library = my_require("library.file_name")', ''],
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

describe('splits file into parts', () => {
    it('should split a file with all three parts', () => {
        const contents = `-- some comment at the top of the file
function random_function()
end

function plugindef()
    finaleplugin.RequireSelection = true
end

function another_function()
end

another_function()`;

        const expected = {
            prolog: `-- some comment at the top of the file
function random_function()
end

`,
            plugindef: `function plugindef()
    finaleplugin.RequireSelection = true
end`,
            epilog: `

function another_function()
end

another_function()`
        };

        expect(getFileParts(contents)).toEqual(expected);
    });

    it('should split a file with no prolog', () => {
        const contents = `function plugindef()
    finaleplugin.RequireSelection = true
end

function another_function()
end

another_function()`;

        const expected = {
            prolog: '',
            plugindef: `function plugindef()
    finaleplugin.RequireSelection = true
end`,
            epilog: `

function another_function()
end

another_function()`
        };

        expect(getFileParts(contents)).toEqual(expected);
    });

    it('should split a file with no plugindef', () => {
        const contents = `-- some comment at the top of the file
function random_function()
end

function another_function()
end

another_function()`;

        const expected = {
            prolog: '',
            plugindef: '',
            epilog: `-- some comment at the top of the file
function random_function()
end

function another_function()
end

another_function()`
        };

        expect(getFileParts(contents)).toEqual(expected);
    });

    it('should split a file with no epilog', () => {
        const contents = `-- some comment at the top of the file
function random_function()
end

function plugindef()
    finaleplugin.RequireSelection = true
end`;

        const expected = {
            prolog: `-- some comment at the top of the file
function random_function()
end

`,
            plugindef: `function plugindef()
    finaleplugin.RequireSelection = true
end`,
            epilog: ''
        };

        expect(getFileParts(contents)).toEqual(expected);
    });
});
