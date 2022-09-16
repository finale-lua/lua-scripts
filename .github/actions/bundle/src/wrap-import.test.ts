import { wrapImport } from './wrap-import'

const stuff = [
    'local stuff = {}',
    '',
    'function stuff.hello()',
    '    print("hello world")',
    'end',
    '',
    'return stuff',
].join('\n')
const stuff2 = [
    'local stuff = {}',
    '',
    'function stuff.hello()',
    '    print("hello world 2")',
    'end',
    '',
    'return stuff',
].join('\n')

describe('wrapImport', () => {
    it('stuff', () => {
        expect(wrapImport('stuff', stuff)).toBe(
            [
                '__imports["stuff"] = __imports["stuff"] or function()',
                '    local stuff = {}',
                '',
                '    function stuff.hello()',
                '        print("hello world")',
                '    end',
                '',
                '    return stuff',
                'end',
            ].join('\n')
        )
    })

    it('stuff2', () => {
        expect(wrapImport('stuff2', stuff2)).toBe(
            [
                '__imports["stuff2"] = __imports["stuff2"] or function()',
                '    local stuff = {}',
                '',
                '    function stuff.hello()',
                '        print("hello world 2")',
                '    end',
                '',
                '    return stuff',
                'end',
            ].join('\n')
        )
    })

    it('works with a dot in the name', () => {
        expect(wrapImport('my.stuff', stuff)).toBe(
            [
                '__imports["my.stuff"] = __imports["my.stuff"] or function()',
                '    local stuff = {}',
                '',
                '    function stuff.hello()',
                '        print("hello world")',
                '    end',
                '',
                '    return stuff',
                'end',
            ].join('\n')
        )
    })
})
