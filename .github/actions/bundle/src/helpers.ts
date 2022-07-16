export const getImport = (line: string): { importedFile: string; isImport: boolean } => {
    const matches = line.match(/require\(["']([A-Z_a-z.]+)["']\)/iu)
    if (!matches) return { importedFile: '', isImport: false }
    return { importedFile: matches[1], isImport: true }
}

export const getAllImports = (file: string): string[] => {
    const imports: Set<string> = new Set()
    const lines = file.split('\n')
    for (const line of lines) {
        const { isImport, importedFile } = getImport(line)
        if (isImport) imports.add(importedFile)
    }
    return [...imports]
}
