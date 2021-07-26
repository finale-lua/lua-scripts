import type { Library } from './bundle'
import { bundleFile } from './bundle'
import { getAllImports } from './helpers'

export const LIBRARY_VARIABLE_NAME = 'BUNDLED_LIBRARY_VARIABLE_NAME'

export const prepareLibraryFile = (file: string, fileName: string): { contents: string } => {
    const lines = file.split('\n')
    let internalModuleName = fileName
    if (!internalModuleName.match(new RegExp(`local ${internalModuleName} = \\{\\}`, 'u'))) {
        for (const line of lines) {
            const matches = line.match(/^local ([a-zA-Z+]+) = \{\}/iu)
            if (matches?.[1]) {
                internalModuleName = matches[1]
                break
            }
        }
    }
    const output: string[] = []
    const declarationRegex = new RegExp(`^local ${internalModuleName} = \\{\\}`, 'u')
    const methodRegex = new RegExp(`^function ${internalModuleName}\\.`, 'ug')
    const returnRegex = new RegExp(`^return ${internalModuleName}`, 'ug')

    for (const line of lines) {
        let outputtedLine = line.replace(declarationRegex, `local ${LIBRARY_VARIABLE_NAME} = {}`)
        outputtedLine = outputtedLine.replace(methodRegex, `function ${LIBRARY_VARIABLE_NAME}.`)
        outputtedLine = outputtedLine.replace(returnRegex, ``)
        output.push(outputtedLine)
    }
    return { contents: output.join('\n') }
}

export type LibraryInput = {
    fileName: string
    contents: string
}[]

/* eslint-disable-next-line sonarjs/cognitive-complexity -- fix in the future */
export const prepareLibrary = (inputFiles: LibraryInput): Library => {
    let files = [...inputFiles]
    const library: Library = {}
    let counter = 0

    while (files.length > 0 && counter < 10) {
        const completedFiles: Set<string> = new Set()
        for (const file of files) {
            const imports = getAllImports(file.contents)
            for (const importFile of imports) if (importFile in library) imports.delete(importFile)

            /* eslint-disable-next-line no-continue -- it's just best here */
            if (imports.size > 0) continue

            const preparedFile = prepareLibraryFile(file.contents, file.fileName)
            const bundledFile = bundleFile(preparedFile.contents, library)
            completedFiles.add(file.fileName)
            library[file.fileName] = { contents: bundledFile }
        }
        files = files.filter((file) => !completedFiles.has(file.fileName))
        counter++
    }
    return library
}
