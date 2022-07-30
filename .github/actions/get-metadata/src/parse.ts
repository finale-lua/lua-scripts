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
    scriptGroupName: string
    scriptGroupDescription: string
    menuItems: string[]
    fileName: string
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
    minJWLuaVersion: string
    maxJWLuaVersion: string
    minFinaleVersion: string
    maxFinaleVersion: string
}

const defaultMetadata: Metadata = {
    name: 'This is the default name that hopefully no one will ever use',
    fileName: '',
    scriptGroupName: '',
    scriptGroupDescription: '',
    undoText: '',
    shortDescription: '',
    menuItems: [],
    requireSelection: false,
    requireScore: false,
    noStore: false,
    author: {
        name: '',
        website: '',
        email: '',
    },
    copyright: '',
    version: '',
    categories: [],
    date: '',
    notes: '',
    revisionNotes: [],
    id: '',
    minJWLuaVersion: '',
    maxJWLuaVersion: '',
    minFinaleVersion: '',
    maxFinaleVersion: '',
}

const deepClone = (metadata: Metadata): Metadata => {
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
                if (clonedMetadata.name === defaultMetadata.name) {
                    clonedMetadata.name =
                        clonedMetadata.menuItems.length > 0 && clonedMetadata.scriptGroupName
                            ? clonedMetadata.scriptGroupName
                            : current
                    clonedMetadata.menuItems.push(current)
                } else if (clonedMetadata.undoText === defaultMetadata.undoText) {
                    clonedMetadata.undoText = current
                } else {
                    clonedMetadata.shortDescription =
                        clonedMetadata.menuItems.length > 1 && clonedMetadata.scriptGroupDescription
                            ? clonedMetadata.scriptGroupDescription
                            : current
                }
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

const getNumberData = (line: string, luaName: string): string => {
    const regex = new RegExp(`^finaleplugin.${luaName} = (.*)`, `u`)
    const matches = line.match(regex)
    if (matches) return matches[1]
    return ''
}

export const parseFile = (file: string, fileName: string): Metadata => {
    let metadata = deepClone(defaultMetadata)
    metadata.fileName = fileName
    const lines = file.split('\n').map(line => line.trimStart())
    let isInReturn = false
    let isInPluginDef = false
    let currentMultilineItem: keyof Metadata | undefined = undefined
    let currentMultilineContents: string[] = []
    for (let line of lines) {
        if (currentMultilineItem !== 'notes') line = line.trimEnd()
        if (!isInPluginDef) {
            if (line.startsWith('function plugindef()')) isInPluginDef = true
        } else if (typeof currentMultilineItem !== 'undefined') {
            if (line.startsWith(']]')) {
                if (currentMultilineItem === 'revisionNotes') metadata.revisionNotes = currentMultilineContents
                else if (currentMultilineItem === 'menuItems') metadata.menuItems = currentMultilineContents
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
        } else if (line.startsWith('finaleplugin.ScriptGroupName')) {
            metadata.scriptGroupName = getStringData(line, 'ScriptGroupName')
        } else if (line.startsWith('finaleplugin.ScriptGroupDescription')) {
            metadata.scriptGroupDescription = getStringData(line, 'ScriptGroupDescription')
        } else if (line.startsWith('finaleplugin.Version')) {
            metadata.version = getStringData(line, 'Version')
        } else if (line.startsWith('finaleplugin.Copyright')) {
            metadata.copyright = getStringData(line, 'Copyright')
        } else if (line.startsWith('finaleplugin.Id')) {
            metadata.id = getStringData(line, 'Id')
        } else if (line.startsWith('finaleplugin.MinJWLuaVersion')) {
            metadata.minJWLuaVersion = getNumberData(line, 'MinJWLuaVersion') || getStringData(line, 'MinJWLuaVersion')
        } else if (line.startsWith('finaleplugin.MaxJWLuaVersion')) {
            metadata.maxJWLuaVersion = getNumberData(line, 'MaxJWLuaVersion') || getStringData(line, 'MaxJWLuaVersion')
        } else if (line.startsWith('finaleplugin.MinFinaleVersion')) {
            metadata.minFinaleVersion =
                getNumberData(line, 'MinFinaleVersion') || getStringData(line, 'MinFinaleVersion')
        } else if (line.startsWith('finaleplugin.MaxFinaleVersion')) {
            metadata.maxFinaleVersion =
                getNumberData(line, 'MaxFinaleVersion') || getStringData(line, 'MaxFinaleVersion')
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
        } else if (line.startsWith('finaleplugin.AdditionalMenuOptions')) {
            currentMultilineItem = 'menuItems'
        }
        if (isInReturn && line.startsWith('end')) break
    }
    metadata.menuItems = metadata.menuItems.sort()
    return metadata
}
import { format } from 'date-fns'
