import path from 'path'

import { getInput } from '@actions/core'
import fs from 'fs-extra'
import { Metadata, parseFile } from './parse'

const sourcePath = path.join(...getInput('source', { required: true }).split('/'))

const outFile = path.join(...getInput('output', { required: true }).split('/'))

fs.ensureFileSync(outFile)

const sourceFiles = fs.readdirSync(sourcePath).filter((fileName) => fileName.endsWith('.lua'))

const allMetadata: Metadata[] = []

sourceFiles.forEach((file) => {
    const contents = fs.readFileSync(path.join(sourcePath, file)).toString()
    allMetadata.push(parseFile(contents))
})

fs.writeFileSync(outFile, JSON.stringify(allMetadata.sort((a, b) => a.name.localeCompare(b.name))))
