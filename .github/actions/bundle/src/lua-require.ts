import path from 'path'

export const resolveRequiredFile = (name: string) => {
    const splitName = name.split('.')
    if (splitName[splitName.length - 1] === 'lua') splitName.pop()
    return path.join(...splitName) + '.lua'
}
