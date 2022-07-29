import { bundleFileBase, ImportedFiles, importFileBase } from './bundle'
import { generateLuaRequire } from './lua-require'

describe('importFile', () => {
    it('files can be imported', () => {
        const fetcher = jest.fn(() => "local hello = require('hello')")
        let importedFilesMock: ImportedFiles = {}
        importFileBase('my-lib', importedFilesMock, fetcher)

        expect(importedFilesMock['my-lib']).toEqual({
            dependencies: ['hello'],
            wrapped: ['__imports["my-lib"] = function()', "    local hello = require('hello')", 'end'].join('\n'),
        })
    })
    it('files are imported only once', () => {
        const fetcher = jest.fn(() => "local hello = require('hello')")
        let importedFilesMock: ImportedFiles = {}
        expect(importFileBase('my-lib', importedFilesMock, fetcher)).toBe(true)
        expect(importFileBase('my-lib', importedFilesMock, fetcher)).toBe(true)
        expect(fetcher).toBeCalledTimes(1)
    })
})

describe('bundle', () => {
    const fetcher = (fileName: string) => {
        const files: Record<string, string> = {
            'a.lua': ["local b = require('b')", "local c = require('c')"].join('\n'),
            'b.lua': "local b = require('b')",
            'c.lua': 'return {}',
            'invalid.lua': "local invalid = require('invalid.import')",
            'mixin.lua': "local mixin = require('library.mixin')",
            'library/mixin.lua': 'return {}',
            'mixin/FCMControl.lua': 'return {}',
            'mixin/FCMString.lua': 'return {}',
        }
        return files[fileName]
    }

    it('bundleFile', () => {
        const bundle = bundleFileBase('a.lua', {}, [], fetcher)
        expect(bundle).toBe(
            [
                generateLuaRequire(),
                '',
                '__imports["b"] = function()',
                "    local b = require('b')",
                'end',
                '',
                '__imports["c"] = function()',
                '    return {}',
                'end',
                '',
                "local b = require('b')",
                "local c = require('c')",
            ].join('\n')
        )
    })

    it('bundleFile with no imports', () => {
        const bundle = bundleFileBase('c.lua', {}, [], fetcher)
        expect(bundle).toBe('return {}')
    })

    it('ignore unresolvable imports', () => {
        const bundle = bundleFileBase('invalid.lua', {}, [], fetcher)
        expect(bundle).toBe(["local invalid = require('invalid.import')"].join('\n'))
    })

    it('imports all mixins', () => {
        const bundle = bundleFileBase('mixin.lua', {}, ['mixin.FCMControl', 'mixin.FCMString'], fetcher)
        expect(bundle).toBe(
            [
                generateLuaRequire(),
                '',
                '__imports["mixin.FCMControl"] = function()',
                '    return {}',
                'end',
                '',
                '__imports["mixin.FCMString"] = function()',
                '    return {}',
                'end',
                '',
                '__imports["library.mixin"] = function()',
                '    return {}',
                'end',
                '',
                "local mixin = require('library.mixin')",
            ].join('\n')
        )
    })
})
