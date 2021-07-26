export const getImport = (line: string): { importedFile: string; isImport: boolean } => {
    const matches = line.match(/require\(["']library\.([A-Z_a-z]+)["']\)/iu)
    if (!matches) return { importedFile: '', isImport: false }
    return { importedFile: matches[1], isImport: true }
}

export const getVariableName = (line: string): string => {
    const matches = line.match(/^(local )?([a-zA-Z_]+)/u)
    if (!matches) return ''
    return matches[2]
}

export const getAllImports = (file: string): Set<string> => {
    const imports: Set<string> = new Set()
    const lines = file.split('\n')
    for (const line of lines) {
        const { isImport, importedFile } = getImport(line)
        if (isImport) imports.add(importedFile)
    }
    return imports
}
