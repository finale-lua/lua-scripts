import path from 'path'

import { getInput } from '@actions/core'
import fs from 'fs-extra'

import { bundleFile } from './bundle'
import type { LibraryInput } from './prepare-library'
import { prepareLibrary } from './prepare-library'

const IS_DEV_ENVIRONMENT = process.env.NODE_ENV === 'development'
const sourcePath = IS_DEV_ENVIRONMENT
    ? path.join('..', '..', '..', 'src')
    : path.join(...getInput('source', { required: true }).split('/'))

const libraryPath = path.join(sourcePath, 'library')

const outputPath = IS_DEV_ENVIRONMENT
    ? path.join('..', '..', '..', 'dist')
    : path.join(...getInput('output', { required: true }).split('/'))

/*
   create bundled library files
    */

const libraryFileNames = fs.readdirSync(libraryPath)
const libraryRawFiles: LibraryInput = []

libraryFileNames.forEach(fileName => {
    const name = fileName.replace('.lua', '')
    const contents = fs.readFileSync(path.join(libraryPath, fileName)).toString()
    libraryRawFiles.push({
        fileName: name,
        contents,
    })
})

const library = prepareLibrary(libraryRawFiles)

/*
   remove old bundled files (if they exist)
    */

fs.ensureDirSync(outputPath)
fs.readdirSync(outputPath).forEach(fileName => fs.removeSync(fileName))

/*
   bundle and save source files
    */

const sourceFiles = fs.readdirSync(sourcePath).filter(fileName => fileName.endsWith('.lua'))

sourceFiles.forEach(file => {
    if (file.startsWith('personal')) return
    const contents = fs.readFileSync(path.join(sourcePath, file)).toString()
    const bundledFile = bundleFile(contents, library)
    fs.writeFileSync(path.join(outputPath, file), bundledFile)
})
