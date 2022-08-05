import path from 'path'

export const generateLuaRequire = () => {
    return [
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
}

export const resolveRequiredFile = (name: string) => {
    const splitName = name.split('.')
    if (splitName[splitName.length - 1] === 'lua') splitName.pop()
    return path.join(...splitName) + '.lua'
}
