import { generateLuaRequire, resolveRequiredFile } from './lua-require'

describe('generateLuaRequire', () => {
    it('lua-require', () => {
        expect(generateLuaRequire()).toBe(
            [
                'local __imports = {}',
                'local __import_results = {}',
                '',
                'function require(item)',
                '    if not __imports[item] then',
                '        error("module \'" .. item .. "\' not found")',
                '    end',
                '',
                '    if __import_results[item] == nil then',
                '        __import_results[item] = __imports[item]()',
                '        if __import_results[item] == nil then',
                '            __import_results[item] = true',
                '        end',
                '    end',
                '',
                '    return __import_results[item]',
                'end',
            ].join('\n')
        )
    })
})

describe('resolveRequiredFile', () => {
    const tests: [string, string][] = [
        ['hello', 'hello.lua'],
        ['hello.lua', 'hello.lua'],
        ['library.configuration', 'library/configuration.lua'],
        ['library.configuration.lua', 'library/configuration.lua'],
        ['library.mixin', 'library/mixin.lua'],
        ['mixin.FCMControl', 'mixin/FCMControl.lua'],
        ['im.a.deeply.nested.file', 'im/a/deeply/nested/file.lua'],
        ['hello.', 'hello.lua'],
    ]
    it.each(tests)('%p resolves to %p', (name, file) => {
        expect(resolveRequiredFile(name)).toBe(file)
    })
})
