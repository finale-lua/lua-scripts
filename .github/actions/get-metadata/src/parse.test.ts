/**
 * NOTE: This suite will only run successfully if Lua
 * and lunajson are available. (This is easier to set up
 * on Linux.)
 */

import fs from 'fs-extra'

import { parseMetadata } from './parse'

const testFiles = fs
    .readdirSync('tests')
    .filter((file) => file.endsWith('.lua'))
    .map((file) => file.replace('.lua', ''))

it.each(testFiles)('test "%s" is parsed correctly', (fileName) => {
    const file = fs.readFileSync(`tests/${fileName}.lua`, 'utf8').toString()
    const expected = JSON.parse(fs.readFileSync(`tests/${fileName}.json`, 'utf8').toString())
    const output = parseMetadata(file)
    
    expect(output).not.toBeNull()
    output.fileName = `${fileName}.lua`
    expect(output).toMatchObject(expected)
})
