import { generateLuaRequire, resolveRequiredFile } from './lua-require'

describe('generateLuaRequire', () => {
    it('lua-require', () => {
        expect(generateLuaRequire()).toBe(
            ['local __imports = {}', '', 'function require(item)', '    return __imports[item]()', 'end'].join('\n')
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
