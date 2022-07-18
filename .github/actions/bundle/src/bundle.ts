import { getImport, getVariableName } from './helpers'

export type Library = {
    [name: string]: {
        contents: string
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
