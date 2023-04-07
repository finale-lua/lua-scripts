export const wrapImport = (name: string, contents: string) => {
    const output = [`package.preload["${name}"] = package.preload["${name}"] or function()`]
    for (const line of contents.split('\n')) {
        if (line === '') output.push(line)
        else output.push('    ' + line)
    }
    output.push('end')
    return output.join('\n')
}
