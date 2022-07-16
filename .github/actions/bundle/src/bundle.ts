import { getAllImports, getImport, getVariableName } from './helpers'
import { wrapImport } from './wrap-import'

export type ImportedFile = {
    importedFrom: Set<string>
    dependencies: Set<string>
    wrapped: string
}

export type ImportedFiles = Record<string, ImportedFile | undefined>
export type Library = {
    [name: string]: {
        contents: string
    }
}

export const files: ImportedFiles = {}

export const importFileBase = async (
    name: string,
    importedFiles: ImportedFiles,
    fetcher: (name: string) => Promise<string>
) => {
    try {
        if (name in importedFiles) return true
        const contents = await fetcher(name)
        importedFiles[name] = {
            importedFrom: new Set(),
            dependencies: getAllImports(contents),
            wrapped: wrapImport(name, contents),
        }
        return true
    } catch {
        return false
    }
}

export const bundleFile = (file: string, library: Library): string => {
    const lines = file.split('\n')
    const output: string[] = []
    lines.forEach(line => {
        const { importedFile, isImport } = getImport(line)
        if (!isImport && !(importedFile in library)) {
            output.push(line)
            return
        }
        const variableName = getVariableName(line)
        if (library[importedFile])
            output.push(library[importedFile].contents.replace(/BUNDLED_LIBRARY_VARIABLE_NAME/gu, variableName))
    })
    return output.join('\n')
}
