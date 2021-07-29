import fs from 'fs-extra'

import { parseFile } from './parse'

const testFiles = fs
    .readdirSync('tests')
    .filter((file) => file.endsWith('.lua'))
    .map((file) => file.replace('.lua', ''))

it.each(testFiles)('test "%s" is parsed correctly', (fileName) => {
    const file = fs.readFileSync(`tests/${fileName}.lua`, 'utf8').toString()
    const metadata = JSON.parse(fs.readFileSync(`tests/${fileName}.json`, 'utf8').toString())
    expect(parseFile(file, fileName + '.lua')).toStrictEqual(metadata)
})
