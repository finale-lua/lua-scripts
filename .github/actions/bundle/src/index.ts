import path from 'path'

import { getInput } from '@actions/core'
import fs from 'fs-extra'

import { bundleFile } from './bundle'

const IS_DEV_ENVIRONMENT = process.env.NODE_ENV === 'development'
const sourcePath = IS_DEV_ENVIRONMENT
    ? path.join('..', '..', '..', 'src')
    : path.join(...getInput('source', { required: true }).split('/'))

const outputPath = IS_DEV_ENVIRONMENT
    ? path.join('..', '..', '..', 'dist')
    : path.join(...getInput('output', { required: true }).split('/'))

/*
   remove old bundled files (if they exist)
    */

fs.ensureDirSync(outputPath)
fs.readdirSync(outputPath).forEach(fileName => fs.removeSync(fileName))

const mixins = fs
    .readdirSync(path.join(sourcePath, 'mixin'))
    .filter(fileName => fileName.endsWith('.lua'))
    .map(file => 'mixin.' + file.replace(/\.lua$/, ''))
if (fs.pathExistsSync(path.join(sourcePath, 'personal_mixin'))) {
    mixins.push(
        ...fs
            .readdirSync(path.join(sourcePath, 'personal_mixin'))
            .filter(fileName => fileName.endsWith('.lua'))
            .map(file => 'personal_mixin.' + file.replace(/\.lua$/, ''))
    )
}

/*
   bundle and save source files
    */

const sourceFiles = fs.readdirSync(sourcePath).filter(fileName => fileName.endsWith('.lua'))

sourceFiles.forEach(file => {
    const bundledFile = bundleFile(file, sourcePath, mixins)
    fs.writeFileSync(path.join(outputPath, file), bundledFile)
})
