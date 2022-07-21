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

export const bundleFileBase = (
    name: string,
    importedFiles: ImportedFiles,
    mixins: string[],
    fetcher: (name: string) => string
) => {
    const fileContents = fetcher(name)
    const fileStack: string[] = [fileContents]
    const importStack: string[] = getAllImports(fileContents)
    const importedFileNames = new Set<string>()

    while (importStack.length > 0) {
        const nextImport = importStack.pop() ?? ''
        if (importedFileNames.has(nextImport)) continue

        const fileFound = importFileBase(nextImport, importedFiles, fetcher)
        if (fileFound) {
            const file = importedFiles[nextImport]
            importedFileNames.add(nextImport)
            if (file) {
                importStack.push(...file.dependencies)
                fileStack.push(file.wrapped)
            }
            if (resolveRequiredFile(nextImport) === 'library/mixin.lua') importStack.push(...mixins)
        } else {
            console.error(`Unresolvable import in file "${name}": ${nextImport}`)
            process.exitCode = 1
        }
    }

    if (fileStack.length > 1) fileStack.push(generateLuaRequire())
    return fileStack.reverse().join('\n\n')
}

export const bundleFile = (name: string, sourcePath: string, mixins: string[]): string => {
    return bundleFileBase(name, files, mixins, (fileName: string) =>
        fs.readFileSync(path.join(sourcePath, fileName)).toString()
    )
}
