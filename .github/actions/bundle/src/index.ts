import path from 'path'

import { getInput } from '@actions/core'
import fs from 'fs-extra'
import luaBundle from 'luabundle'
import luaMinify from 'luamin'

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

/*
   bundle and save source files
    */

const sourceFiles = fs.readdirSync(sourcePath).filter(fileName => fileName.endsWith('.lua'))
const mixins = fs.readdirSync(path.join(sourcePath, 'mixin')).filter(fileName => fileName.endsWith('.lua'))

sourceFiles.forEach(file => {
    if (file.startsWith('personal')) return
    const source = fs.readFileSync(path.join(sourcePath, file), 'utf8')
    let expressionHandlerOutput = source.includes('library.mixin') ? mixins : []
    const bundledFile = luaBundle.bundle(path.join(sourcePath, file), {
        paths: ['?', '?.lua', path.resolve(path.join(sourcePath, 'library', 'general_library.lua'))],
        expressionHandler: (_, __) => expressionHandlerOutput,
    })
    fs.writeFileSync(path.join(outputPath, file), luaMinify.minify(bundledFile))
})
