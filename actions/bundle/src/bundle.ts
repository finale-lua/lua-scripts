export const getImport = (line: string): { file: string; isImport: boolean } => {
    const matches = line.match(/require\(["']library\.([A-Z_a-z]+)["']\)/u)
    if (!matches) return { file: '', isImport: false }
    return { file: matches[1], isImport: true }
}

export const getVariableName = (line: string): string => {
    const matches = line.match(/^(local )?([a-zA-Z_]+)/u)
    if (!matches) return ''
    return matches[2]
}
