import { resolveRequiredFile } from './lua-require'

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
