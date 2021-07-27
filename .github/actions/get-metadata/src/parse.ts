export type Parameter = {
    type: string
    description: string
    defaultValue: string
    list: string[]
}
export type Author = {
    name: string
    website: string
    email: string
}
export type Metadata = {
    name: string
    undoText: string
    shortDescription: string
    requireSelection: boolean
    requireScore: boolean
    noStore: boolean
    author: Author
    copyright: string
    version: string
    categories: string[]
    date: string
    notes: string
    revisionNotes: string[]
    id: string
}

const defaultMetadata: Metadata = {
    name: 'This is the default name that hopefully no one will ever use',
    undoText: '',
    shortDescription: '',
    requireSelection: false,
    requireScore: false,
    noStore: false,
    author: {
        name: '',
        website: '',
        email: ''
    },
    copyright: '',
    version: '',
    categories: [],
    date: '',
    notes: '',
    revisionNotes: [],
    id: '',
}

const deepClone = (metadata:Metadata): Metadata => {
    return JSON.parse(JSON.stringify(metadata))
}

const parseReturnData = (line: string, metadata: Metadata): Metadata => {
    const clonedMetadata = deepClone(metadata)

    const trimmedLine = line.replace(/^return /u, '')
        let current = ''
        let isInString = false
        for (const char of trimmedLine) {
            if (char === '"') {
                isInString = !isInString
                if (!isInString) {
                    if (clonedMetadata.name === defaultMetadata.name) clonedMetadata.name = current
                    else if (clonedMetadata.undoText === defaultMetadata.undoText)
                        clonedMetadata.undoText = current
                    else clonedMetadata.shortDescription = current
                    current = ''
                }
            } else if (isInString) {
                current += char
            }
        }

    return clonedMetadata
}

const parseCategories = (line: string): string[] => {
    const data = getStringData(line, 'CategoryTags')
    const categories: string[] = []
    let currentCategory = ''
    for (const char of data) {
        if (char === ' ' || char === ',') {
            if (currentCategory !== '') categories.push(currentCategory)
            currentCategory = ''
            continue
        }
        currentCategory += char
    }
    if (currentCategory !== '') categories.push(currentCategory)
    return categories
}

const getStringData = (line: string, luaName: string): string => {
    const regex = new RegExp(`^finaleplugin.${luaName} = "(.*)"`, `u`)
    const matches = line.match(regex)
    if (matches) return matches[1]
    return ''
}

const getBooleanData = (line: string, luaName: string): boolean => {
    const regex = new RegExp(`^finaleplugin.${luaName} = (.*)`, `u`)
    const matches = line.match(regex)
    if (matches) return matches[1] === 'true'
    return false
}

export const parseFile = (file: string): Metadata => {
    let metadata = deepClone(defaultMetadata)
    const lines = file.split('\n').map((line) => line.trim())
    let isInReturn = false
    let isInPluginDef = false
    let currentMultilineItem: (keyof Metadata) | undefined = undefined
    let currentMultilineContents: string[] = []
    for (const line of lines) {
        if (!isInPluginDef) {
            if (line.startsWith('function plugindef()')) isInPluginDef = true
        } else if (typeof currentMultilineItem !== 'undefined') {
            if (line.startsWith(']]')) {
                if (currentMultilineItem === 'revisionNotes')
                    metadata.revisionNotes = currentMultilineContents
                else metadata[currentMultilineItem] = currentMultilineContents.join('\n')
                currentMultilineItem = undefined
                currentMultilineContents = []
                continue
            }
            currentMultilineContents.push(line)
        } else if (line.startsWith('return ') || isInReturn) {
            isInReturn = true
            metadata = parseReturnData(line, metadata)
        } else if (line.startsWith('finaleplugin.AuthorURL')) {
            metadata.author.website = getStringData(line, 'AuthorURL')
        } else if (line.startsWith('finaleplugin.AuthorEmail')) {
            metadata.author.email = getStringData(line, 'AuthorEmail')
        } else if (line.startsWith('finaleplugin.Author')) {
            metadata.author.name = getStringData(line, 'Author')
        } else if (line.startsWith('finaleplugin.Version')) {
            metadata.version = getStringData(line, 'Version')
        } else if (line.startsWith('finaleplugin.Copyright')) {
            metadata.copyright = getStringData(line, 'Copyright')
        } else if (line.startsWith('finaleplugin.Id')) {
            metadata.id = getStringData(line, 'Id')
        } else if (line.startsWith('finaleplugin.CategoryTags')) {
            metadata.categories = parseCategories(line)
        } else if (line.startsWith('finaleplugin.Date')) {
            metadata.date = format(new Date(getStringData(line, 'Date')), 'yyyy-MM-dd')
        } else if (line.startsWith('finaleplugin.RequireScore')) {
            metadata.requireScore = getBooleanData(line, 'RequireScore')
        } else if (line.startsWith('finaleplugin.RequireSelection')) {
            metadata.requireSelection = getBooleanData(line, 'RequireSelection')
        } else if (line.startsWith('finaleplugin.NoStore')) {
            metadata.noStore = getBooleanData(line, 'NoStore')
        } else if (line.startsWith('finaleplugin.Notes')) {
            currentMultilineItem = 'notes'
        } else if (line.startsWith('finaleplugin.RevisionNotes')) {
            currentMultilineItem = 'revisionNotes'
        }
        if (isInReturn && line.startsWith('end')) break
    }
    return metadata
}
import { format } from 'date-fns';