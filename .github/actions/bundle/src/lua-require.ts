import path from 'path'

export const generateLuaRequire = () => {
    return [
        'local __imports = {}',
        '',
        'function require(item)',
        '    if __imports[item] then',
        '        return __imports[item]()',
        '    else',
        '        error("module \'" .. item .. "\' not found")',
        '    end',
        'end',
    ].join('\n')
}

export const resolveRequiredFile = (name: string) => {
    const splitName = name.split('.')
    if (splitName[splitName.length - 1] === 'lua') splitName.pop()
    return path.join(...splitName) + '.lua'
}
