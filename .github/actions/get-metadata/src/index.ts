import path from 'path'

import { getInput } from '@actions/core'
import fs from 'fs-extra'
import { parseMetadata } from './parse'

const sourcePath = path.join(...getInput('source', { required: true }).split('/'))
const outFile = path.join(...getInput('output', { required: true }).split('/'))

fs.ensureFileSync(outFile)

const sourceFiles = fs.readdirSync(sourcePath).filter((fileName: string) => fileName.endsWith('.lua'))
const allMetadata: any[] = []

sourceFiles.forEach((fileName: string) => {
    const contents = fs.readFileSync(path.join(sourcePath, fileName)).toString()
    const parsed = parseMetadata(contents)
    if (parsed) {
        parsed.fileName = fileName
        allMetadata.push(parsed)
    }
})

fs.writeFileSync(outFile, JSON.stringify(allMetadata.sort((a, b) => a.name.localeCompare(b.name))))
