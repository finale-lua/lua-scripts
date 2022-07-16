import fs from 'fs'
import path from 'path'
import { getAllImports } from './helpers'
import { generateLuaRequire, resolveRequiredFile } from './lua-require'
import { wrapImport } from './wrap-import'

export type ImportedFile = {
    dependencies: string[]
    wrapped: string
}

export type ImportedFiles = Record<string, ImportedFile | undefined>
export type Library = {
    [name: string]: {
        contents: string
    }
}

export const files: ImportedFiles = {}

export const importFileBase = (name: string, importedFiles: ImportedFiles, fetcher: (name: string) => string) => {
    try {
        if (name in importedFiles) return true
        const contents = fetcher(resolveRequiredFile(name))
        importedFiles[name] = {
            dependencies: getAllImports(contents),
            wrapped: wrapImport(name, contents),
        }
        return true
    } catch {
        return false
    }
}

export const bundleFileBase = (name: string, importedFiles: ImportedFiles, fetcher: (name: string) => string) => {
    const fileStack: string[] = []
    const fileContents = fetcher(name)
    const importStack: string[] = getAllImports(fileContents)
    const importedFileNames = new Set<string>()

    while (importStack.length > 0) {
        const nextImport = importStack.pop() ?? ''
        if (importedFileNames.has(nextImport)) continue
        try {
            importFileBase(nextImport, importedFiles, fetcher)
            const file = importedFiles[nextImport]
            if (file) {
                importStack.push(...file.dependencies)
                fileStack.push(file.wrapped)
            }
        } catch {
            console.error(`Unresolvable import in file "${name}": ${nextImport}`)
            process.exitCode = 1
        }
    }

    if (fileStack.length > 1) fileStack.push(generateLuaRequire())
    return fileStack.reverse().join('\n\n')
}

export const bundleFile = (name: string, sourcePath: string): string => {
    return bundleFileBase(name, files, (fileName: string) =>
        fs.readFileSync(path.join(sourcePath, fileName)).toString()
    )
}
