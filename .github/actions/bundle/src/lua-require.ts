import path from 'path'

export const generateLuaRequire = () => {
    return [
        '__imports = __imports or {}',
        '__import_results = __import_results or {}',
        '',
        '__aaa_original_require_for_deployment__ = require'
        'function require(item)',
        '    if not __imports[item] then',
        '        __aaa_original_require_for_deployment__(item) -- attempt to require it with the original require, since it may be a C library.',
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
}

export const resolveRequiredFile = (name: string) => {
    const splitName = name.split('.')
    if (splitName[splitName.length - 1] === 'lua') splitName.pop()
    return path.join(...splitName) + '.lua'
}
